# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Pipe do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::Pipe::VERSION).not_to be_nil
    end
  end

  describe 'basic pipeline' do
    it 'transforms value through steps' do
      result = described_class.new(1)
                              .step { |v| v + 1 }
                              .step { |v| v * 3 }
                              .value

      expect(result).to eq(6)
    end

    it 'returns input unchanged with empty pipeline' do
      result = described_class.new(42).value
      expect(result).to eq(42)
    end

    it 'handles a single step pipeline' do
      result = described_class.new(5)
                              .step { |v| v * 10 }
                              .value
      expect(result).to eq(50)
    end

    it 'preserves step ordering' do
      result = described_class.new(2)
                              .step { |v| v + 3 }
                              .step { |v| v * 2 }
                              .step { |v| v - 1 }
                              .value
      expect(result).to eq(9)
    end

    it 'handles nil as initial value' do
      result = described_class.new(nil)
                              .step { |_v| 'recovered' }
                              .value
      expect(result).to eq('recovered')
    end

    it 'passes nil through steps' do
      result = described_class.new(nil).value
      expect(result).to be_nil
    end

    it 'handles string values' do
      result = described_class.new('hello')
                              .step(&:upcase)
                              .step { |v| "#{v}!" }
                              .value
      expect(result).to eq('HELLO!')
    end

    it 'handles array values' do
      result = described_class.new([3, 1, 2])
                              .step(&:sort)
                              .step(&:reverse)
                              .value
      expect(result).to eq([3, 2, 1])
    end

    it 'handles hash values' do
      result = described_class.new({ a: 1 })
                              .step { |v| v.merge(b: 2) }
                              .value
      expect(result).to eq({ a: 1, b: 2 })
    end
  end

  describe 'conditional steps' do
    it 'executes step when guard_if: guard returns true' do
      result = described_class.new(10)
                              .step(guard_if: ->(v) { v > 5 }) { |v| v * 2 }
                              .value

      expect(result).to eq(20)
    end

    it 'skips step when guard_if: guard returns false' do
      result = described_class.new(3)
                              .step(guard_if: ->(v) { v > 5 }) { |v| v * 2 }
                              .value

      expect(result).to eq(3)
    end

    it 'executes step when guard_unless: guard returns false' do
      check = ->(v) { v > 20 }
      result = described_class.new(10)
                              .step(guard_unless: check) { |v| v + 5 }
                              .value

      expect(result).to eq(15)
    end

    it 'skips step when guard_unless: guard returns true' do
      check = ->(v) { v > 20 }
      result = described_class.new(25)
                              .step(guard_unless: check) { |v| v + 5 }
                              .value

      expect(result).to eq(25)
    end

    it 'applies guard_if to intermediate values' do
      result = described_class.new(1)
                              .step { |v| v + 10 }
                              .step(guard_if: ->(v) { v > 5 }) { |v| v * 100 }
                              .value
      expect(result).to eq(1100)
    end

    it 'chains multiple guarded steps' do
      result = described_class.new(10)
                              .step(guard_if: ->(v) { v > 5 }) { |v| v + 1 }
                              .step(guard_if: ->(v) { v > 5 }) { |v| v + 1 }
                              .step(guard_if: ->(v) { v > 100 }) { |v| v * 0 }
                              .value
      expect(result).to eq(12)
    end

    it 'combines guard_if and guard_unless on separate steps' do
      result = described_class.new(10)
                              .step(guard_if: ->(v) { v == 10 }) { |v| v + 5 }
                              .step(guard_unless: ->(v) { v == 15 }) { |v| v * 100 }
                              .value
      expect(result).to eq(15)
    end
  end

  describe '#tee' do
    it 'passes value through unchanged' do
      side_effect = nil

      result = described_class.new(42)
                              .tee { |v| side_effect = v }
                              .step { |v| v + 1 }
                              .value

      expect(result).to eq(43)
      expect(side_effect).to eq(42)
    end

    it 'executes multiple tee steps for side effects' do
      log = []

      result = described_class.new(10)
                              .tee { |v| log << "before: #{v}" }
                              .step { |v| v * 2 }
                              .tee { |v| log << "after: #{v}" }
                              .value

      expect(result).to eq(20)
      expect(log).to eq(['before: 10', 'after: 20'])
    end

    it 'ignores the return value of tee block' do
      result = described_class.new(5)
                              .tee { |_v| 999 }
                              .value
      expect(result).to eq(5)
    end

    it 'can be used between transform steps' do
      collected = nil

      result = described_class.new(1)
                              .step { |v| v + 1 }
                              .tee { |v| collected = v }
                              .step { |v| v + 1 }
                              .value

      expect(result).to eq(3)
      expect(collected).to eq(2)
    end
  end

  describe 'error handling' do
    it 'catches exceptions with error handler' do
      result = described_class.new(1)
                              .step { |_v| raise StandardError, 'boom' }
                              .on_error { |e| "caught: #{e.message}" }
                              .value

      expect(result).to eq('caught: boom')
    end

    it 'short-circuits on error' do
      reached = false

      result = described_class.new(1)
                              .step { |_v| raise StandardError, 'fail' }
                              .step do |v|
        reached = true
        v
      end
        .on_error(&:message)
        .value

      expect(result).to eq('fail')
      expect(reached).to be(false)
    end

    it 'raises when no error handler is set' do
      pipe = described_class.new(1)
                            .step { |_v| raise StandardError, 'unhandled' }

      expect { pipe.value }.to raise_error(Philiprehberger::Pipe::PipeError)
    end

    it 'catches errors raised in later steps' do
      result = described_class.new(1)
                              .step { |v| v + 1 }
                              .step { |_v| raise StandardError, 'late error' }
                              .on_error(&:message)
                              .value

      expect(result).to eq('late error')
    end

    it 'handles RuntimeError subclass' do
      result = described_class.new(1)
                              .step { |_v| raise 'runtime' }
                              .on_error { |e| e.class.name }
                              .value

      expect(result).to eq('Philiprehberger::Pipe::PipeError')
    end

    it 'error handler receives PipeError wrapping the original exception' do
      original = ArgumentError.new('bad arg')
      received = nil

      described_class.new(1)
                     .step { |_v| raise original }
                     .on_error { |e| received = e }
                     .value

      expect(received).to be_a(Philiprehberger::Pipe::PipeError)
      expect(received.original_error).to be(original)
    end

    it 'can set error handler before steps' do
      result = described_class.new(1)
                              .on_error { |e| "handled: #{e.message}" }
                              .step { |_v| raise StandardError, 'oops' }
                              .value

      expect(result).to eq('handled: oops')
    end

    it 'last on_error handler wins' do
      result = described_class.new(1)
                              .on_error { |_e| 'first handler' }
                              .on_error { |_e| 'second handler' }
                              .step { |_v| raise StandardError, 'err' }
                              .value

      expect(result).to eq('second handler')
    end
  end

  describe 'chaining' do
    it 'returns self from step' do
      pipe = described_class.new(1)
      expect(pipe.step { |v| v }).to be(pipe)
    end

    it 'returns self from tee' do
      pipe = described_class.new(1)
      expect(pipe.tee { |v| v }).to be(pipe)
    end

    it 'returns self from on_error' do
      pipe = described_class.new(1)
      expect(pipe.on_error { |e| e }).to be(pipe)
    end

    it 'returns self from tap_value' do
      pipe = described_class.new(1)
      expect(pipe.tap_value(:check) { |v| v }).to be(pipe)
    end
  end

  describe '#compose' do
    it 'chains two pipelines together' do
      pipe1 = described_class.new(5)
                             .step { |v| v + 1 }
      pipe2 = described_class.new(0)
                             .step { |v| v * 10 }

      result = pipe1.compose(pipe2).value
      expect(result).to eq(60)
    end

    it 'preserves step ordering across composed pipelines' do
      pipe1 = described_class.new(1)
                             .step { |v| v + 1 }
                             .step { |v| v * 2 }
      pipe2 = described_class.new(0)
                             .step { |v| v + 10 }

      result = pipe1.compose(pipe2).value
      expect(result).to eq(14)
    end

    it 'returns a new Pipe instance' do
      pipe1 = described_class.new(1).step { |v| v + 1 }
      pipe2 = described_class.new(0).step { |v| v * 2 }

      composed = pipe1.compose(pipe2)
      expect(composed).to be_a(described_class)
      expect(composed).not_to be(pipe1)
      expect(composed).not_to be(pipe2)
    end

    it 'does not modify the original pipelines' do
      pipe1 = described_class.new(5).step { |v| v + 1 }
      pipe2 = described_class.new(0).step { |v| v * 10 }

      pipe1.compose(pipe2)

      expect(pipe1.value).to eq(6)
    end

    it 'supports the >> operator' do
      pipe1 = described_class.new(3)
                             .step { |v| v + 2 }
      pipe2 = described_class.new(0)
                             .step { |v| v * 3 }

      result = (pipe1 >> pipe2).value
      expect(result).to eq(15)
    end

    it 'composes multiple pipelines with >> chaining' do
      pipe1 = described_class.new(1).step { |v| v + 1 }
      pipe2 = described_class.new(0).step { |v| v * 2 }
      pipe3 = described_class.new(0).step { |v| v + 100 }

      result = (pipe1 >> pipe2 >> pipe3).value
      expect(result).to eq(104)
    end

    it 'uses the initial value from the first pipeline' do
      pipe1 = described_class.new(100).step { |v| v + 1 }
      pipe2 = described_class.new(999).step { |v| v + 1 }

      result = pipe1.compose(pipe2).value
      expect(result).to eq(102)
    end

    it 'composes empty pipelines' do
      pipe1 = described_class.new(42)
      pipe2 = described_class.new(0)

      result = pipe1.compose(pipe2).value
      expect(result).to eq(42)
    end
  end

  describe 'step naming' do
    it 'accepts an optional symbol name as first argument' do
      result = described_class.new(5)
                              .step(:double) { |v| v * 2 }
                              .value
      expect(result).to eq(10)
    end

    it 'wraps errors in PipeError with step_name' do
      pipe = described_class.new(1)
                            .step(:validate) { |_v| raise StandardError, 'invalid' }

      expect { pipe.value }.to raise_error(Philiprehberger::Pipe::PipeError) do |e|
        expect(e.step_name).to eq(:validate)
        expect(e.message).to eq('invalid')
      end
    end

    it 'includes the original error in PipeError' do
      original = ArgumentError.new('bad')
      pipe = described_class.new(1)
                            .step(:parse) { |_v| raise original }

      expect { pipe.value }.to raise_error(Philiprehberger::Pipe::PipeError) do |e|
        expect(e.original_error).to be(original)
        expect(e.step_name).to eq(:parse)
      end
    end

    it 'has nil step_name for unnamed steps' do
      pipe = described_class.new(1)
                            .step { |_v| raise StandardError, 'oops' }

      expect { pipe.value }.to raise_error(Philiprehberger::Pipe::PipeError) do |e|
        expect(e.step_name).to be_nil
      end
    end

    it 'works with named steps and guards together' do
      result = described_class.new(10)
                              .step(:double, guard_if: ->(v) { v > 5 }) { |v| v * 2 }
                              .value
      expect(result).to eq(20)
    end

    it 'identifies the correct step on error in a multi-step pipeline' do
      pipe = described_class.new(1)
                            .step(:first) { |v| v + 1 }
                            .step(:second) { |_v| raise StandardError, 'fail here' }
                            .step(:third) { |v| v + 1 }

      expect { pipe.value }.to raise_error(Philiprehberger::Pipe::PipeError) do |e|
        expect(e.step_name).to eq(:second)
      end
    end

    it 'error handler receives PipeError with step_name' do
      received = nil

      described_class.new(1)
                     .step(:transform) { |_v| raise StandardError, 'err' }
                     .on_error { |e| received = e }
                     .value

      expect(received).to be_a(Philiprehberger::Pipe::PipeError)
      expect(received.step_name).to eq(:transform)
    end
  end

  describe '#tap_value' do
    it 'captures the current value without affecting flow' do
      captured = nil

      result = described_class.new(10)
                              .step { |v| v + 5 }
                              .tap_value(:after_add) { |v| captured = v }
                              .step { |v| v * 2 }
                              .value

      expect(result).to eq(30)
      expect(captured).to eq(15)
    end

    it 'ignores the return value of the block' do
      result = described_class.new(10)
                              .tap_value(:check) { |_v| 999 }
                              .value
      expect(result).to eq(10)
    end

    it 'works without a name' do
      captured = nil

      result = described_class.new(7)
                              .tap_value { |v| captured = v }
                              .value

      expect(result).to eq(7)
      expect(captured).to eq(7)
    end

    it 'captures multiple intermediate values' do
      captures = {}

      result = described_class.new(1)
                              .step { |v| v + 1 }
                              .tap_value(:after_first) { |v| captures[:after_first] = v }
                              .step { |v| v * 3 }
                              .tap_value(:after_second) { |v| captures[:after_second] = v }
                              .step { |v| v + 10 }
                              .value

      expect(result).to eq(16)
      expect(captures).to eq({ after_first: 2, after_second: 6 })
    end

    it 'can be used at the start of a pipeline' do
      captured = nil

      result = described_class.new(42)
                              .tap_value(:initial) { |v| captured = v }
                              .step { |v| v + 1 }
                              .value

      expect(result).to eq(43)
      expect(captured).to eq(42)
    end

    it 'can be used at the end of a pipeline' do
      captured = nil

      result = described_class.new(5)
                              .step { |v| v * 4 }
                              .tap_value(:final) { |v| captured = v }
                              .value

      expect(result).to eq(20)
      expect(captured).to eq(20)
    end
  end

  describe Philiprehberger::Pipe::PipeError do
    it 'inherits from Philiprehberger::Pipe::Error' do
      expect(described_class.superclass).to eq(Philiprehberger::Pipe::Error)
    end

    it 'inherits from StandardError' do
      expect(described_class.ancestors).to include(StandardError)
    end

    it 'can be created with a message' do
      error = described_class.new('something went wrong')
      expect(error.message).to eq('something went wrong')
    end

    it 'can be created with step_name and original_error' do
      original = RuntimeError.new('boom')
      error = described_class.new(step_name: :validate, original_error: original)

      expect(error.step_name).to eq(:validate)
      expect(error.original_error).to be(original)
      expect(error.message).to eq('boom')
    end

    it 'has nil step_name by default' do
      error = described_class.new('oops')
      expect(error.step_name).to be_nil
    end
  end
end

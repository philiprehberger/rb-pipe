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

      expect { pipe.value }.to raise_error(StandardError, 'unhandled')
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

      expect(result).to eq('RuntimeError')
    end

    it 'error handler receives the original exception object' do
      original = ArgumentError.new('bad arg')
      received = nil

      described_class.new(1)
                     .step { |_v| raise original }
                     .on_error { |e| received = e }
                     .value

      expect(received).to be(original)
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
  end
end

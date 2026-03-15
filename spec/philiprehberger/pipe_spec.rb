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

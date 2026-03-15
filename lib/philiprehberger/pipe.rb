# frozen_string_literal: true

require_relative 'pipe/version'
require_relative 'pipe/step'
require_relative 'pipe/pipeline'

module Philiprehberger
  class Pipe
    def initialize(initial_value)
      @initial_value = initial_value
      @pipeline = Pipeline.new
      @error_handler = nil
    end

    def step(guard_if: nil, guard_unless: nil, &block)
      @pipeline.add_step(
        Step.new(callable: block, guard_if: guard_if, guard_unless: guard_unless)
      )
      self
    end

    def tee(&block)
      @pipeline.add_step(Step.new(callable: block, type: :tee))
      self
    end

    def on_error(&block)
      @error_handler = block
      self
    end

    def value
      @pipeline.execute(@initial_value, error_handler: @error_handler)
    end
  end
end

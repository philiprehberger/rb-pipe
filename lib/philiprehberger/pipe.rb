# frozen_string_literal: true

require_relative 'pipe/version'
require_relative 'pipe/error'
require_relative 'pipe/step'
require_relative 'pipe/pipeline'

module Philiprehberger
  class Pipe
    # Short-circuit the currently executing pipeline, returning `value` as the
    # final result of `#call` / `#value`. Safe to call from inside any step;
    # does NOT trigger `on_error` handlers.
    #
    # @param value [Object] the value to return as the pipeline result
    # @raise [Halted] always (caught internally by the Pipeline)
    def self.halt!(value)
      raise Halted, value
    end

    def initialize(initial_value = nil, pipeline: nil)
      @initial_value = initial_value
      @pipeline = pipeline || Pipeline.new
      @error_handler = nil
    end

    def step(name = nil, guard_if: nil, guard_unless: nil, &block)
      @pipeline.add_step(
        Step.new(callable: block, name: name, guard_if: guard_if, guard_unless: guard_unless)
      )
      self
    end

    def tee(&block)
      @pipeline.add_step(Step.new(callable: block, type: :tee))
      self
    end

    def tap_value(name = nil, &block)
      @pipeline.add_step(Step.new(callable: block, name: name, type: :tee))
      self
    end

    def on_error(&block)
      @error_handler = block
      self
    end

    def compose(other)
      composed_pipeline = Pipeline.new
      @pipeline.steps.each { |s| composed_pipeline.add_step(s) }
      other.send(:pipeline).steps.each { |s| composed_pipeline.add_step(s) }
      self.class.new(@initial_value, pipeline: composed_pipeline)
    end

    alias >> compose

    def call(value)
      @pipeline.execute(value, error_handler: @error_handler)
    end

    def to_proc
      method(:call).to_proc
    end

    def value
      @pipeline.execute(@initial_value, error_handler: @error_handler)
    end

    protected

    attr_reader :pipeline
  end
end

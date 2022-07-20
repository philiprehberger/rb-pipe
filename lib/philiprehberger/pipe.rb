# frozen_string_literal: true

require_relative 'pipe/version'
require_relative 'pipe/error'
require_relative 'pipe/step'
require_relative 'pipe/pipeline'

module Philiprehberger
  class Pipe
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

    def value
      @pipeline.execute(@initial_value, error_handler: @error_handler)
    end

    protected

    attr_reader :pipeline
  end
end

# frozen_string_literal: true

module Philiprehberger
  class Pipe
    class Error < StandardError; end

    class PipeError < Error
      attr_reader :step_name, :original_error

      def initialize(message = nil, step_name: nil, original_error: nil)
        @step_name = step_name
        @original_error = original_error
        super(message || original_error&.message)
      end
    end

    # Raised internally by `Pipe.halt!(value)` to short-circuit the pipeline
    # and return `value` as the final result. Not treated as an error � it
    # bypasses `on_error` handlers.
    class Halted < Error
      attr_reader :value

      def initialize(value)
        @value = value
        super('pipeline halted')
      end
    end
  end
end

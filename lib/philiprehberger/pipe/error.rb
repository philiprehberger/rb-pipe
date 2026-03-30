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
  end
end

# frozen_string_literal: true

module Philiprehberger
  class Pipe
    class Pipeline
      def initialize
        @steps = []
      end

      def add_step(step)
        @steps << step
      end

      def execute(initial_value, error_handler: nil)
        @steps.reduce(initial_value) do |value, step|
          step.execute(value)
        end
      rescue StandardError => e
        raise unless error_handler

        error_handler.call(e)
      end
    end
  end
end

# frozen_string_literal: true

module Philiprehberger
  class Pipe
    class Step
      attr_reader :callable, :name, :guard_if, :guard_unless, :type

      def initialize(callable:, name: nil, type: :transform, guard_if: nil, guard_unless: nil)
        @callable = callable
        @name = name
        @type = type
        @guard_if = guard_if
        @guard_unless = guard_unless
      end

      def execute(value)
        return value if skipped?(value)

        result = callable.call(value)
        type == :tee ? value : result
      rescue PipeError
        raise
      rescue StandardError => e
        raise PipeError.new(e.message, step_name: name, original_error: e)
      end

      private

      def skipped?(value)
        return true if guard_if && !guard_if.call(value)
        return true if guard_unless&.call(value)

        false
      end
    end
  end
end

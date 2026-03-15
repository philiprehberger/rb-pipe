# frozen_string_literal: true

module Philiprehberger
  class Pipe
    class Step
      attr_reader :callable, :guard_if, :guard_unless, :type

      def initialize(callable:, type: :transform, guard_if: nil, guard_unless: nil)
        @callable = callable
        @type = type
        @guard_if = guard_if
        @guard_unless = guard_unless
      end

      def execute(value)
        return value if skipped?(value)

        result = callable.call(value)
        type == :tee ? value : result
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

# -*- encoding : utf-8 -*-
module MotionSpec
  module Matcher
    class BeFalse
      def matches?(value)
        !value
      end

      def fail!(subject, negated)
        message = FailMessageRenderer.message_for_be_false(negated, subject)
        fail FailedExpectation.new(message)
      end
    end
  end
end

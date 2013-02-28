require 'rspec/expectations'

module NcsNavigator::Mdes::Spec::Matchers
  class ValueDiffMatcher
    attr_reader :left, :right, :actual

    def initialize(left, right)
      @left = left
      @right = right
    end

    def left_matches?(actual)
      left == actual.left
    end

    def right_matches?(actual)
      right == actual.right
    end

    def matches?(actual)
      @actual = actual
      actual && left_matches?(actual) && right_matches?(actual)
    end

    def failure_message_for_should
      if (!actual)
        "expected a difference but got none"
      else
        [
          ("expected left=#{left.inspect} but was #{actual.left.inspect}" unless left_matches?(actual)),
          ("expected right=#{right.inspect} but was #{actual.right.inspect}" unless right_matches?(actual))
        ].compact.join(' and ')
      end
    end
  end

  def be_a_value_diff(left, right)
    ValueDiffMatcher.new(left, right)
  end
end

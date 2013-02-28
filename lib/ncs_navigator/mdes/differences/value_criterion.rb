require 'ncs_navigator/mdes'

module NcsNavigator::Mdes::Differences
  ##
  # @private implementation detail
  class ValueCriterion
    COMPARATORS = {
      :equality => lambda { |a, b| a == b },
      :predicate => lambda { |a, b| !(a ^ b) }
    }

    IDENTITY_VALUE_EXTRACTOR = lambda { |o| o }

    attr_reader :comparator, :value_extractor

    def initialize(options={})
      @comparator = select_comparator(options.delete(:comparator))
      @value_extractor = options.delete(:value_extractor) || IDENTITY_VALUE_EXTRACTOR
    end

    def apply(v1, v2)
      cv1 = value_extractor.call(v1)
      cv2 = value_extractor.call(v2)

      unless comparator.call(cv1, cv2)
        Value.new(cv1, cv2)
      end
    end

    def select_comparator(param)
      case param
      when nil
        COMPARATORS[:equality]
      when Symbol
        COMPARATORS[param] or fail "Unknown comparator #{param.inspect}"
      else
        param
      end
    end
    private :select_comparator
  end
end

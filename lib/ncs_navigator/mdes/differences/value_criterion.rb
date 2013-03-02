require 'ncs_navigator/mdes'

module NcsNavigator::Mdes::Differences
  ##
  # @private implementation detail
  class ValueCriterion
    COMPARATORS = {
      :equality => lambda { |a, b| a == b },
      :predicate => lambda { |a, b| !(a ^ b) }
    }

    VALUE_EXTRACTORS = {
      :identity => lambda { |o| o },
      :word_chars_downcase =>
        lambda { |o| o ? o.downcase.gsub(/[^ \w]+/, ' ').gsub(/\s+/, ' ').strip : o }
    }

    attr_reader :comparator, :value_extractor

    def initialize(options={})
      @comparator = select_comparator(options.delete(:comparator))
      @value_extractor = select_value_extractor(options.delete(:value_extractor))
    end

    def apply(v1, v2, diff_options)
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

    def select_value_extractor(param)
      case param
      when nil
        VALUE_EXTRACTORS[:identity]
      when Symbol
        VALUE_EXTRACTORS[param] or fail "Unknown extractor #{param.inspect}"
      else
        param
      end
    end
    private :select_value_extractor
  end
end

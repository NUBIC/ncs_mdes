require 'ncs_navigator/mdes'

module NcsNavigator::Mdes::Differences
  ##
  # @private implementation detail
  class CollectionCriterion
    ##
    # @return [Symbol] the attribute in the object to which this criterion applies
    attr_reader :attribute

    def initialize(alignment_attribute, options={})
      @alignment_attribute = alignment_attribute
      @attribute = options.delete(:collection)
      @alignment_value_extractor =
        select_value_extractor(options.delete(:value_extractor))
    end

    def apply(c1, c2, diff_options)
      c1_map = map_for_alignment(c1)
      c2_map = map_for_alignment(c2)

      left_only = c1_map.keys - c2_map.keys
      right_only = c2_map.keys - c1_map.keys

      both = c1_map.keys & c2_map.keys
      entry_differences = both.each_with_object({}) do |key, differences|
        diff = c1_map[key].diff(c2_map[key], diff_options)
        differences[key] = diff if diff
      end

      if left_only.empty? && right_only.empty? && entry_differences.empty?
        nil
      else
        Collection.new(left_only, right_only, entry_differences)
      end
    end

    def map_for_alignment(c)
      return {} unless c
      c.each_with_object({}) do |element, map|
        value = @alignment_value_extractor.call(element.send(@alignment_attribute))
        map[value] = element
      end
    end
    private :map_for_alignment

    def select_value_extractor(param)
      case param
      when nil
        ValueCriterion::VALUE_EXTRACTORS[:identity]
      when Symbol
        ValueCriterion::VALUE_EXTRACTORS[param] or fail "Unknown extractor #{param.inspect}"
      else
        param
      end
    end
    private :select_value_extractor
  end
end

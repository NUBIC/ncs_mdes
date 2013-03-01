require 'ncs_navigator/mdes'

module NcsNavigator::Mdes::Differences
  ##
  # @private implementation detail
  class CollectionCriterion
    def initialize(alignment_attribute)
      @alignment_attribute = alignment_attribute
    end

    def apply(c1, c2)
      c1_map = map_for_alignment(c1)
      c2_map = map_for_alignment(c2)

      left_only = c1_map.keys - c2_map.keys
      right_only = c2_map.keys - c1_map.keys

      both = c1_map.keys & c2_map.keys
      entry_differences = both.each_with_object({}) do |key, differences|
        diff = c1_map[key].diff(c2_map[key])
        differences[key] = diff if diff
      end

      if left_only.empty? && right_only.empty? && entry_differences.empty?
        nil
      else
        Collection.new(left_only, right_only, entry_differences)
      end
    end

    def map_for_alignment(c)
      c.each_with_object({}) do |element, map|
        map[element.send(@alignment_attribute)] = element
      end
    end
    private :map_for_alignment
  end
end

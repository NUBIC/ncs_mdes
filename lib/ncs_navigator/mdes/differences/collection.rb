require 'ncs_navigator/mdes'

module NcsNavigator::Mdes::Differences
  ##
  # Captures the differences between two collections.
  class Collection
    def initialize(left_only, right_only, entry_differences)
      @left_only = left_only
      @right_only = right_only
      @entry_differences = entry_differences
    end

    ##
    # A list of those entries which are in the lefthand version of the
    # collection only. Values are the characteristic (alignment) value for each
    # entry.
    #
    # @return [Array<Object>]
    def left_only
      @left_only ||= []
    end

    ##
    # A list of those entries which are in the righthand version of the
    # collection only. Values are the characteristic (alignment) value for each
    # entry.
    #
    # @return [Array<Object>]
    def right_only
      @right_only ||= []
    end

    ##
    # Detailed differences for entries which are present in some form in each
    # collection. Keys are the characteristic (alignment) value for the entry.
    #
    # @return [Hash<Object, Entry>]
    def entry_differences
      @entry_differences ||= {}
    end
  end
end

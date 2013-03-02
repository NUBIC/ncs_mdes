require 'ncs_navigator/mdes'
require 'forwardable'

module NcsNavigator::Mdes::Differences
  ##
  # Captures the differences between two instances of one of the elements that
  # makes up a specification. I.e., {TransmissionTable}, {Variable},
  # {VariableType}, or {CodeListEntry}.
  class Entry
    ##
    # @param [Object] o1 the left object
    # @param [Object] o2 the right object
    # @param [Hash<Symbol, #apply>] attribute_criteria a list of objects which produce difference objects
    # @param [Hash] diff_options options to pass to nested calls to #diff
    # @return [Entry, nil] the differences between o1 and o2 according to the
    #   criteria, or nil if there are no differences.
    def self.compute(o1, o2, attribute_criteria, diff_options)
      differences = attribute_criteria.each_with_object({}) do |(diff_attribute, criterion), diffs|
        o_attribute = (criterion.respond_to?(:attribute) && criterion.attribute) || diff_attribute
        d = criterion.apply(o1.send(o_attribute), o2.send(o_attribute), diff_options)
        diffs[diff_attribute] = d if d
      end

      if differences.empty?
        nil
      else
        Entry.new.tap { |e| e.attribute_differences = differences }
      end
    end

    extend Forwardable

    def_delegators :attribute_differences, :[]

    ##
    # Return the differences for each attribute. Each key is the name of the
    # attribute and each value is an object describing the difference. It might
    # be a {Value} diff, a {Collection} diff, or another {Entry} diff depending
    # on the kind of attribute.
    #
    # @return [Hash<Symbol, Object>]
    def attribute_differences
      @attribute_differences ||= {}
    end

    attr_writer :attribute_differences
  end
end

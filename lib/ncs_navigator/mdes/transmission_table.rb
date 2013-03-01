require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  ##
  # One table in the MDES.
  class TransmissionTable
    ##
    # Creates a new instance from an `xs:element` describing the table.
    #
    # @return [TransmissionTable] the created instance.
    def self.from_element(element, options={})
      log = options[:log] || NcsNavigator::Mdes.default_logger

      new(element['name']).tap do |table|
        table.variables = element.
          xpath('xs:complexType/xs:sequence/xs:element', SourceDocuments.xmlns).
          collect { |col_elt| Variable.from_element(col_elt, options) }
      end
    end

    ##
    # @return [String] the machine name of the table. This is also the name of the XML
    #  element in the VDR export.
    attr_reader :name

    ##
    # @return [Array<Variable>] the variables that make up this
    #  table. (A relational model might call these the columns of this
    #  table.)
    attr_accessor :variables

    def initialize(name)
      @name = name
    end

    def variables
      @variables ||= []
    end

    ##
    # Search for a variable by name.
    #
    # @param variable_name [String] the name of the variable to look for.
    # @return [Variable] the variable with the given name, if any
    def [](variable_name)
      variables.find { |c| c.name == variable_name }
    end

    ##
    # Provides a briefer inspection for cleaner IRB use.
    #
    # @return [String]
    def inspect
      "\#<#{self.class} name=#{name.inspect}>"
    end

    ##
    # Is this a primary instrument table (i.e., is this the table for
    # an instrument that stores all single-valued responses for one
    # execution of that instrument and to which all other instrument
    # tables for that instrument refer [directly or indirectly])?
    #
    # @return [true,false]
    def primary_instrument_table?
      self.name != 'instrument' && variables.any? { |v| v.name == 'instrument_version' }
    end

    ##
    # Is this an instrument table (i.e., a table for storing results
    # from an instrument)? Every table is either an instrument table
    # or an operational table (never both).
    #
    # This is not explicitly derivable from the MDES, so this method
    # (and the related methods {#operational_table?} and
    # {#primary_instrument_table?}) use this heuristic:
    #
    #   * If this table contains a variable named `instrument_version`
    #     and is not the `instrument` table itself, it is a primary
    #     instrument table (and so is an instrument table).
    #   * If this table is not a primary instrument table, but one of
    #     its {#variables} {Variable#table_reference references} a table
    #     that is a primary instrument table, then this is an instrument
    #     table.
    #   * Similarly, if one of this table's variables references a table
    #     which is an instrument table according to the second
    #     definition, then this table is an instrument table as
    #     well. This continues for any depth of reference.
    #
    # If none of these conditions are met, then this table is an
    # operational table.
    #
    # @return [true,false]
    def instrument_table?
      instrument_table_predicate_with_stack([])
    end

    ##
    # @private # exposed for recursion in siblings
    def instrument_table_predicate_with_stack(stack)
      return false if stack.include?(self)
      primary_instrument_table? || variables.any? { |v|
        v.table_reference && v.table_reference.instrument_table_predicate_with_stack(stack + [self])
      }
    end

    ##
    # Is this an operational table (i.e., a table for storing
    # operational data about a participant, household, staff member,
    # or other study management concept)? Every table is either an
    # operational table or an instrument table (never both).
    #
    # @see #instrument_table?
    # @return [true,false]
    def operational_table?
      !instrument_table?
    end

    # @private
    DIFF_CRITERIA = {
      :name => Differences::ValueCriterion.new,
      :variables => Differences::CollectionCriterion.new(:name)
    }

    ##
    # Computes the differences between this table and the other.
    #
    # @return [Differences::Entry,nil]
    def diff(other_table)
      Differences::Entry.compute(self, other_table, DIFF_CRITERIA)
    end
  end
end

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

    ##
    # Search for a variable by name.
    #
    # @param variable_name [String] the name of the variable to look for.
    # @return [Variable] the variable with the given name, if any
    def [](variable_name)
      variables.find { |c| c.name == variable_name }
    end
  end
end

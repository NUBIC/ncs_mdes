require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  class TransmissionTable
    def self.from_element(element, options={})
      log = options[:log] || NcsNavigator::Mdes.default_logger

      new(element['name']).tap do |table|
        table.variables = element.
          xpath('xs:complexType/xs:sequence/xs:element', SourceDocuments.xmlns).
          collect { |col_elt| Variable.from_element(col_elt, options) }
      end
    end

    attr_reader :name
    attr_accessor :variables

    def initialize(name)
      @name = name
    end

    def [](variable_name)
      variables.find { |c| c.name == variable_name }
    end

  end
end

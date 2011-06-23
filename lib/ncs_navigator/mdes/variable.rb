require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  ##
  # A single field in the MDES. A relational model might also call
  # this a column, but "variable" is what it's called in the MDES.
  class Variable
    ##
    # @return [String] the name of the variable
    attr_reader :name

    ##
    # @return [Boolean,:possible,:unknown,String] the PII category
    #   for the variable. `true` if it is definitely PII, `false` if
    #   it definitely is not, `:possible` if it was marked in the MDES
    #   as requiring manual review, `:unknown` if the MDES does not
    #   specify, or a string if the parsed value was not mappable to
    #   one of the above. Note that this value will always be truthy
    #   unless the MDES explicitly says that the variable is not PII.
    attr_accessor :pii

    ##
    # @return [:active,:new,:modified,:retired,String] the status of
    #   the variable in this version of the MDES. A String is returned
    #   if the source value doesn't match any of the expected values
    #   in the MDES.
    attr_accessor :status

    ##
    # @return [VariableType] the type of this variable.
    attr_accessor :type

    ##
    # Is the variable mandatory for a valid submission?
    #
    # @return [Boolean]
    attr_accessor :required
    alias :required? :required

    class << self
      ##
      # Examines the given parsed element and creates a new
      # variable. The resulting variable has all the attributes set
      # which can be set without reference to any other parts of the
      # MDES outside of this one variable definition.
      #
      # @param [Nokogiri::Element] element the source xs:element
      # @return [Variable] a new variable instance
      def from_element(element, options={})
        log = options[:log] || NcsNavigator::Mdes.default_logger

        new(element['name']).tap do |var|
          var.required = (element['nillable'] == 'false')
          var.pii =
            case element['pii']
            when 'Y'; true;
            when 'P'; :possible;
            when nil; :unknown;
            when '';  false;
            else element['pii'];
            end
          var.status =
            case element['status']
            when '1'; :active;
            when '2'; :new;
            when '3'; :modified;
            when '4'; :retired;
            else element['status'];
            end
          var.type =
            if element['type']
              VariableType.reference(element['type'])
            elsif element.elements.collect { |e| e.name } == %w(simpleType)
              VariableType.from_xsd_simple_type(element.elements.first, options)
            else
              log.warn("Could not determine a type for variable #{var.name.inspect} on line #{element.line}")
              nil
            end
        end
      end
    end

    def initialize(name)
      @name = name
    end

    def constraints
      @constraints ||= []
    end
  end
end

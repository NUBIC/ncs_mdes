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
    # If the variable does not have a value, should it be completely
    # omitted when submitting to the VDR?
    #
    # @return [Boolean]
    attr_accessor :omittable
    alias :omittable? :omittable

    ##
    # May the variable be submitted as a null value?
    #
    # @return [Boolean]
    attr_accessor :nillable
    alias :nillable? :nillable

    ##
    # Allows for an override of the default logic. Mostly intended for
    # testing. Set to `nil` to restore default logic.
    #
    # @return [Boolean,nil]
    attr_writer :required

    ##
    # If this variable is a foreign key, this is the {table
    # TransmissionTable} to which it refers.
    #
    # @return [TransmissionTable,nil] the parent table.
    attr_accessor :table_reference

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
          var.nillable = element['nillable'] == 'true'
          var.omittable = element['minOccurs'] == '0'
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
              if element['type'] =~ /^xs:/
                VariableType.xml_schema_type(element['type'].sub(/^xs:/, ''))
              else
                VariableType.reference(element['type'])
              end
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

    ##
    # Is a value for the variable mandatory for a valid submission?
    #
    # @return [Boolean]
    def required?
      if @required.nil?
        !(omittable? || nillable?)
      else
        @required
      end
    end

    ##
    # If the {#type} of this instance is a reference to an NCS type,
    # attempts to replace it with the full version from the given list
    # of types.
    #
    # @param [Array<VariableType>] types
    # @return [void]
    def resolve_type!(types, options={})
      log = options[:log] || NcsNavigator::Mdes.default_logger

      return unless type && type.reference?
      unless type.name =~ /^ncs:/
        log.warn("Unknown reference namespace in type #{type.name.inspect} for #{name}")
      end

      ncs_type_name = type.name.sub(/^ncs:/, '')
      match = types.find { |t| t.name == ncs_type_name }
      if match
        self.type = match
      else
        log.warn("Undefined type #{type.name} for #{name}.") if log
      end
    end

    ##
    # Attempts to resolve this variable as a {reference to another
    # table #table_reference}. There are two mechanisms for performing
    # the resolution:
    #
    # 1. If an `override_name` is provided, that table will be looked
    #    up in the provided table list. If it exists, it will be used,
    #    otherwise nothing will be set.
    # 2. If the type of this variable is one of the NCS FK types and
    #    there exists exactly one table in `tables` whose primary key
    #    has the same name as this variable, that table will be used.
    #
    # Alternatively, to suppress the heuristics without providing a
    # replacement, pass `false` as the `override_name`
    #
    # @param [Array<TransmissionTable>] tables the tables to search
    #   for a parent.
    # @param [String,nil] override_name the name of a table to use as
    #   the parent. Supplying a value in this parameter bypasses the
    #   search heuristic.
    # @return [void]
    def resolve_foreign_key!(tables, override_name=nil, options={})
      log = options[:log] || NcsNavigator::Mdes.default_logger

      case override_name
      when String
        self.table_reference = tables.detect { |t| t.name == override_name }
        unless table_reference
          log.warn("Foreign key #{name.inspect} explicitly mapped " <<
            "to unknown table #{override_name.inspect}.")
        end
      when nil
        return unless (self.type && self.type.name =~ /^foreignKey/)

        candidates = tables.select do |t|
          t.variables.detect { |v| (v.name == name) && (v.type && (v.type.name =~ /^primaryKey/)) }
        end

        case candidates.size
        when 0
          log.warn("Foreign key not resolvable: " <<
            "no tables have a primary key named #{name.inspect}.")
        when 1
          self.table_reference = candidates.first
        else
          log.warn(
            "#{candidates.size} possible parent tables found for foreign key #{name.inspect}: " <<
            "#{candidates.collect { |c| c.name.inspect }.join(', ')}. None used due to ambiguity.")
        end
      end
    end
  end
end

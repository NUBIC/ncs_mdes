require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  class VariableType
    attr_reader :name

    attr_accessor :base_type
    attr_accessor :pattern
    attr_accessor :max_length
    attr_accessor :min_length
    attr_accessor :code_list

    attr_accessor :reference
    alias :reference? :reference

    class << self
      def from_xsd_simple_type(st, options={})
        log = options[:log] || NcsNavigator::Mdes.default_logger

        restriction = st.xpath('xs:restriction[@base="xs:string"]', SourceDocuments.xmlns).first
        unless restriction
          log.warn "Unsupported restriction base in simpleType on line #{st.line}"
          return
        end

        new(st['name']).tap do |vt|
          vt.base_type = :string
          restriction.elements.each do |elt|
            case elt.name
            when 'pattern'
              p = elt['value']
              vt.pattern =
                begin
                  Regexp.new(p)
                rescue RegexpError
                  log.warn("Uncompilable pattern #{p.inspect} in simpleType#{(' ' + vt.name.inspect) if vt.name} on line #{elt.line}")
                  nil
                end
            when 'maxLength'
              vt.max_length = elt['value'].to_i
            when 'minLength'
              vt.min_length = elt['value'].to_i
            when 'enumeration'
              (vt.code_list ||= CodeList.new) << CodeListEntry.from_xsd_enumeration(elt)
              if elt['desc'] =~ /\S/
                if vt.code_list.description.nil?
                  vt.code_list.description = elt['desc']
                elsif vt.code_list.description != elt['desc']
                  log.warn("Code list entry on line #{elt.line} unexpectedly has a different desc from the first entry")
                end
              end
            else
              log.warn "Unsupported restriction element #{elt.name.inspect} on line #{elt.line}"
            end
          end
        end
      end

      ##
      # Creates an instance that represents a reference with the given name.
      def reference(name)
        new(name).tap do |vt|
          vt.reference = true
        end
      end
    end

    def initialize(name=nil)
      @name = name
    end

    ##
    # A collection of {CodeListEntry}s.
    #
    # @see VariableType#code_list
    class CodeList < Array
      ##
      # The description of the code list, derived from ncsdoc:desc.
      attr_accessor :description
    end

    ##
    # A single entry in a code list.
    #
    # @see VariableType#code_list
    class CodeListEntry
      ##
      # @return [String] the local code value for the entry.
      attr_reader :value

      ##
      # @return [String] the human-readable label for the entry.
      attr_accessor :label

      ##
      # @return [String] the MDES's globally-unique identifier for
      #   this coded value.
      attr_accessor :global_value

      ##
      # @return [String] the name of MDES's master code list from
      #   which this value is derived.
      attr_accessor :master_cl

      class << self
        ##
        # Creates a new instance from a `xs:enumeration` simple type
        # restriction subelement.
        #
        # @param [Nokogiri::XML::Element] enum the `xs:enumeration`
        #   element.
        # @param [Hash] options
        # @option :log [#warn] the logger to which to direct warnings
        def from_xsd_enumeration(enum, options={})
          log = options[:log] || NcsNavigator::Mdes.default_logger

          log.warn("Missing value for code list entry on line #{enum.line}") unless enum['value']

          new(enum['value']).tap do |cle|
            cle.label = enum['label']
            cle.global_value = enum['global_value']
            cle.master_cl = enum['master_cl']
          end
        end
      end

      def initialize(value)
        @value = value
      end

      alias :to_s :value
    end
  end
end

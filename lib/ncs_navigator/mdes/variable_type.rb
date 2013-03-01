require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  ##
  # Encapsulates restrictions on the content of a {Variable}.
  class VariableType
    attr_reader :name

    ##
    # @return [Symbol, nil] the XML Schema base type that this
    #   variable type is based on.
    attr_accessor :base_type

    ##
    # @return [Regexp, nil] a regular expression that valid values of this
    #   type must match.
    attr_accessor :pattern

    ##
    # @return [Fixnum, nil] the maximum length of a valid value of
    #   this type.
    attr_accessor :max_length

    ##
    # @return [Fixnum, nil] the minimum length of a valid value of
    #   this type.
    attr_accessor :min_length

    ##
    # @return [CodeList<CodeListEntry>, nil] the fixed list of values
    #   that are valid for this type.
    attr_accessor :code_list

    ##
    # @return [Boolean] whether this is a fully fleshed-out type or
    #   just a reference. If it is a reference, all fields except for
    #   {#name} should be ignored.
    attr_accessor :reference
    alias :reference? :reference

    class << self
      ##
      # @param [Nokogiri::XML::Element] st the `xs:simpleType` element
      #   from which to build the instance
      # @param [Hash] options
      # @option options [#warn] :log the logger to which to direct warnings
      #
      # @return [VariableType] a new instance based on the provided
      #   simple type.
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
                  Regexp.new("^#{p}$")
                rescue RegexpError
                  log.warn("Uncompilable pattern #{p.inspect} in simpleType#{(' ' + vt.name.inspect) if vt.name} on line #{elt.line}")
                  nil
                end
            when 'maxLength'
              vt.max_length = elt['value'].to_i
            when 'minLength'
              vt.min_length = elt['value'].to_i
            when 'enumeration'
              (vt.code_list ||= CodeList.new) << CodeListEntry.from_xsd_enumeration(elt, options)
              if elt['ncsdoc:desc'] =~ /\S/
                if vt.code_list.description.nil?
                  vt.code_list.description = elt['ncsdoc:desc']
                elsif vt.code_list.description != elt['ncsdoc:desc']
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
      # Creates an instance that represents a reference with the given
      # name.
      #
      # @return [VariableType] a new instance
      def reference(name)
        new(name).tap do |vt|
          vt.reference = true
        end
      end

      ##
      # Creates an instance corresponding to the given XML Schema
      # simple base type.
      #
      # @return [VariableType] a new instance
      def xml_schema_type(type_name)
        new.tap do |vt|
          vt.base_type = type_name.to_sym
        end
      end
    end

    def initialize(name=nil)
      @name = name
    end

    def inspect
      attrs = [
        [:name, name.inspect],
        [:base_type, base_type.inspect],
        [:reference, reference.inspect],
        [:code_list, code_list ? "<#{code_list.size} entries>" : nil]
      ].reject { |k, v| v.nil? }.
        collect { |k, v| "#{k}=#{v}" }
      "#<#{self.class} #{attrs.join(' ')}>"
    end

    # @private
    DIFF_CRITERIA = {
      :name       => Differences::ValueCriterion.new,
      :base_type  => Differences::ValueCriterion.new,
      :pattern    => Differences::ValueCriterion.new,
      :max_length => Differences::ValueCriterion.new,
      :min_length => Differences::ValueCriterion.new,
    }

    def diff(other_type)
      Differences::Entry.compute(self, other_type, DIFF_CRITERIA)
    end
  end
end

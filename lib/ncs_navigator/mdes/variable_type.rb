require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  class VariableType
    attr_reader :name

    attr_accessor :base_type
    attr_accessor :pattern
    attr_accessor :max_length
    attr_accessor :min_length

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
  end
end

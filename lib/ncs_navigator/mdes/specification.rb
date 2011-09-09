require 'ncs_navigator/mdes'

require 'forwardable'
require 'logger'
require 'nokogiri'
require 'yaml'

module NcsNavigator::Mdes
  class Specification
    extend Forwardable

    ##
    # @return [SourceDocuments] the source documents this reader is
    #   working from.
    attr_accessor :source_documents

    ##
    # @method version
    # @return [String] the version of the MDES to which this instance refers.
    def_delegator :@source_documents, :version

    ##
    # @param [String,SourceDocuments] version either the string
    #   version of the MDES metadata you would like to read, or a
    #   {SourceDocuments} instance pointing to the appropriate files.
    # @param [Hash] options
    # @option options :log a logger to use while reading the specification. If
    #   not specified, a logger pointing to standard error will be used.
    def initialize(version, options={})
      @source_documents = case version
                          when SourceDocuments
                            version
                          else
                            SourceDocuments.get(version)
                          end
      @log = options[:log] || NcsNavigator::Mdes.default_logger
    end

    ##
    # @return [Nokogiri::XML::Document] the parsed version of the VDR
    #   XML schema for this version of the MDES.
    def xsd
      @xsd ||= Nokogiri::XML(File.read source_documents.schema)
    end

    ##
    # @return [Hash] the loaded heuristic overrides, or a default
    #   (empty) set
    def heuristic_overrides
      @heuristic_overrides ||=
        begin
          if File.exist?(source_documents.heuristic_overrides)
            empty_overrides.merge(YAML.load(File.read source_documents.heuristic_overrides))
          else
            empty_overrides
          end
        end
    end

    def empty_overrides
      {
        'foreign_keys' => { }
      }
    end
    private :empty_overrides

    ##
    # @return [Array<TransmissionTable>] all the transmission tables
    #   in this version of the MDES.
    def transmission_tables
      @transmission_tables ||= read_transmission_tables
    end

    def read_transmission_tables
      xsd.xpath(
        '//xs:element[@name="transmission_tables"]/xs:complexType/xs:sequence/xs:element',
        source_documents.xmlns
      ).collect { |table_elt|
        TransmissionTable.from_element(table_elt, :log => @log)
      }.tap { |tables|
        tables.each { |t| t.variables.each { |v| v.resolve_type!(types, :log => @log) } }
        # All types must be resolved before doing FK resolution or
        # forward refs are missed.
        tables.each { |t|
          fk_overrides = heuristic_overrides['foreign_keys'][t.name] || { }
          t.variables.each { |v|
            v.resolve_foreign_key!(tables, fk_overrides[v.name], :log => @log)
          }
        }
      }
    end
    private :read_transmission_tables

    ##
    # A shortcut for accessing particular {#transmission_tables}.
    #
    # @overload [](table_name)
    #   Retrieves a single table by name.
    #   @param [String] table_name the transmission table to return.
    #   @return [TransmissionTable,nil] the matching table or nothing.
    #
    # @overload [](pattern)
    #   Searches the transmission tables by name.
    #   @param [Regexp] pattern the pattern to match the name against.
    #   @return [Array<TransmissionTable>] the matching tables (or an
    #     empty array).
    def [](criterion)
      case criterion
      when Regexp
        transmission_tables.select { |t| t.name =~ criterion }
      when String
        transmission_tables.detect { |t| t.name == criterion }
      else
        fail "Unexpected criterion #{criterion.inspect}"
      end
    end

    ##
    # @return [Array<VariableType>] all the named types in the
    #   MDES. This includes all the code lists.
    def types
      @types ||= read_types
    end

    def read_types
      xsd.xpath('//xs:simpleType[@name]', source_documents.xmlns).collect do |type_elt|
        VariableType.from_xsd_simple_type(type_elt, :log => @log)
      end
    end
    private :read_types

    ##
    # @return [Array<DispositionCode>] all the named disposition codes in the MDES.
    def disposition_codes
      @disposition_codes ||=
        begin
          if File.exist?(source_documents.disposition_codes)
            YAML.load(File.read source_documents.disposition_codes).collect do |dc|
              DispositionCode.new(dc)
            end
          else
            empty_disposition_codes
          end
        end
    end

    def empty_disposition_codes
      []
    end
    private :empty_disposition_codes

    ##
    # A briefer inspection for nicer IRB sessions.
    #
    # @return [String]
    def inspect
      "#<#{self.class} version=#{version.inspect}>"
    end
  end
end

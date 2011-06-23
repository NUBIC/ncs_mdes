require 'ncs_navigator/mdes'

require 'forwardable'
require 'logger'
require 'nokogiri'

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
    # @return [Array<TransmissionTable>] all the transmission tables
    #   in this version of the MDES.
    def transmission_tables
      @transmission_tables ||= read_transmission_tables
    end

    def read_transmission_tables
      xsd.xpath(
        '//xs:element[@name="transmission_tables"]/xs:complexType/xs:sequence/xs:element',
        source_documents.xmlns
        ).collect do |table_elt|
        TransmissionTable.from_element(table_elt, :log => @log)
      end
    end
    private :read_transmission_tables

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
  end
end

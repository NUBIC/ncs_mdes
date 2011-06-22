require 'ncs_navigator/mdes'

require 'forwardable'
require 'nokogiri'

module NcsNavigator::Mdes
  class Specification
    extend Forwardable

    ##
    # @return [SourceDocuments] the source documents this reader is
    #   working from.
    attr_accessor :source_documents

    def_delegator :@source_documents, :version

    attr_accessor :transmission_tables

    ##
    # @param [String,SourceDocuments] version either the string
    #   version of the MDES metadata you would like to read, or a
    #   {SourceDocuments} instance pointing to the appropriate files.
    def initialize(version)
      @source_documents = case version
                          when SourceDocuments
                            version
                          else
                            SourceDocuments.get(version)
                          end
    end

    ##
    # @return [Nokogiri::XML::Document] the parsed version of the
    #   schema for this reader
    def xsd
      @xsd ||= Nokogiri::XML(File.read source_documents.schema)
    end

    def transmission_tables
      @transmission_tables ||= read_transmission_tables
    end

    def read_transmission_tables
      xsd.xpath(
        '//xs:element[@name="transmission_tables"]/xs:complexType/xs:sequence/xs:element',
        source_documents.xmlns
        ).collect do |table_elt|
        table_elt['name']
      end
    end
    private :read_transmission_tables
  end
end

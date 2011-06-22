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
  end
end

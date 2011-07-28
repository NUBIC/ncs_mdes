require 'ncs_navigator/mdes'

require 'forwardable'

module NcsNavigator::Mdes
  ##
  # Implements the mechanism for determining where the MDES documents
  # are stored on a particular system.
  class SourceDocuments
    BASE_ENV_VAR = 'NCS_MDES_DOCS_DIR'

    extend Forwardable

    ##
    # The base path for all paths that are not explicitly
    # configured. It defaults to `'documents'` within this gem and may
    # be globally overridden by setting `NCS_MDES_DOCS_DIR` in the
    # runtime environment.
    #
    # There's probably no reason to change this in the current version
    # of the gem.
    #
    # @return [String]
    attr_accessor :base

    ##
    # The MDES version this set of documents describes.
    #
    # @return [String]
    attr_accessor :version

    ##
    # Instance-level alias for {.xmlns}.
    # @method xmlns
    # @return [Hash]
    def_delegator self, :xmlns

    class << self
      ##
      # Constructs an appropriate instance for the given version.
      #
      # @return [SourceDocuments]
      def get(version)
        case version
        when '1.2'
          create('1.2', '1.2/Data_Transmission_Schema_V1.2.xsd')
        when '2.0'
          create('2.0', '2.0/NCS_Transmission_Schema_2.0.01.02.xml')
        else
          raise "MDES #{version} is not supported by this version of ncs_mdes"
        end
      end

      def create(version, schema)
        self.new.tap do |sd|
          sd.version = version
          sd.schema = schema
          sd.heuristic_overrides = "#{version}/heuristic_overrides.yml"
          sd.disposition_codes = "#{version}/disposition_codes.yml"
        end
      end
      private :create

      ##
      # A mapping of prefixes to XML namespaces for use with
      # Nokogiri XPath.
      #
      # @return [Hash<String, String>]
      def xmlns
        {
          'xs'     => 'http://www.w3.org/2001/XMLSchema',
          'ncs'    => 'http://www.nationalchildrensstudy.gov',
          'ncsdoc' => 'http://www.nationalchildrensstudy.gov/doc'
        }
      end
    end

    def base
      @base ||= (
        ENV[BASE_ENV_VAR] ||
        File.expand_path(File.join('..', '..', '..', '..', 'documents'), __FILE__)
        )
    end

    ##
    # The absolute path to the XML Schema describing the MDES
    # transmission structure for this instance.
    #
    # @return [String]
    def schema
      absolutize(@schema)
    end

    ##
    # Set the path to the MDES transmission structure XML Schema.
    # If the path is relative (i.e., it does not begin with `/`), it
    # will be interpreted relative to {#base}.
    #
    # @param [String] path
    # @return [String] the provided path
    def schema=(path)
      @schema = path
    end

    ##
    # The absolute path to a YAML-formatted document defining
    # overrides of heuristics this library uses to do mapping when
    # there is insufficient computable information in the other source
    # documents.
    #
    # This is path is optional; if one is not provided no overrides
    # will be attempted.
    #
    # @return [String]
    def heuristic_overrides
      absolutize(@heuristic_overrides)
    end

    ##
    # Set the path to the heuristics override document.
    # If the path is relative (i.e., it does not begin with `/`), it
    # will be interpreted relative to {#base}.
    #
    # @param [String] path
    # @return [String] the provided path
    def heuristic_overrides=(path)
      @heuristic_overrides = path
    end
    
    ##
    # The absolute path to a YAML-formatted document defining
    # the disposition codes as found in the Master Data Element Specifications 
    # spreadsheet.
    #
    # This is path is optional; if one is not provided no disposition 
    # codes will be loaded.
    #
    # @return [String]
    def disposition_codes
      absolutize(@disposition_codes)
    end
    
    ##
    # Set the path to the disposition codes document.
    # If the path is relative (i.e., it does not begin with `/`), it
    # will be interpreted relative to {#base}.
    #
    # @param [String] path
    # @return [String] the provided path
    def disposition_codes=(path)
      @disposition_codes = path
    end

    private

    def absolutize(path)
      return nil unless path
      path[0, 1] == '/' ? path : File.join(base, path)
    end
  end
end

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
    # @return [String] The specification version that these documents
    #   describe, if more specific than the overall version.
    attr_accessor :specification_version

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
          create('2.0', '2.0/NCS_Transmission_Schema_2.0.01.02.xml', '2.0.01.02')
        when '2.1'
          create('2.1', '2.1/NCS_Transmission_Schema_2.1.00.00.xsd', '2.1.00.00')
        when '2.2'
          create('2.2', '2.2/NCS_Transmission_Schema_2.2.01.01.xsd', '2.2.01.01')
        when '3.0'
          create('3.0', '3.0/NCS_Transmission_Schema_3.0.00.09.xsd', '3.0.00.09')
        when '3.1'
          create('3.1', '3.1/NCS_Transmission_Schema_3.1.01.00.xsd', '3.1.01.00')
        when '3.2'
          create('3.2', '3.2/NCS_Transmission_Schema_3.2.00.00.xsd', '3.2.00.00')
        when '3.3'
          create('3.3', '3.3/NCS_Transmission_Schema_3.3.00.00.xsd', '3.3.00.00')
        else
          raise "MDES #{version} is not supported by this version of ncs_mdes"
        end
      end

      def create(version, schema, specification_version=nil)
        self.new.tap do |sd|
          sd.version = version
          sd.schema = schema
          sd.heuristic_overrides = "#{version}/heuristic_overrides.yml"
          sd.disposition_codes = "#{version}/disposition_codes.yml"
          sd.child_or_parent_instrument_tables = "#{version}/child_or_parent_instrument_tables.yml"
          sd.specification_version = specification_version
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

    def specification_version
      @specification_version || self.version
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

    ##
    # The absolute path to a YAML-formatted document defining a hash with two
    # keys: `child_instrument_tables` and `parent_instrument_tables`. The value
    # for each should be a list of MDES table names (lower case) which are in
    # that category.
    #
    # This is path is optional; if one is not provided
    # {TransmissionTable#child_instrument_table?} and
    # {TransmissionTable#parent_instrument_table?} will be nil for all tables.
    #
    # @return [String]
    def child_or_parent_instrument_tables
      absolutize(@child_or_parent_instrument_tables)
    end

    ##
    # Set the path to the child-or-parent instrument tables document.
    # If the path is relative (i.e., it does not begin with `/`), it
    # will be interpreted relative to {#base}.
    #
    # @param [String] path
    # @return [String] the provided path
    def child_or_parent_instrument_tables=(path)
      @child_or_parent_instrument_tables = path
    end

    private

    def absolutize(path)
      return nil unless path
      path[0, 1] == '/' ? path : File.join(base, path)
    end
  end
end

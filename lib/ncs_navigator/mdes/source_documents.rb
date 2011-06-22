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
    # configured. It defaults to `'/etc/nubic/ncs/mdes'` and may be
    # globally overridden by setting `NCS_MDES_DOCS_DIR` in the
    # runtime environment.
    #
    # @return [String]
    attr_accessor :base

    ##
    # The MDES version this set of documents describes.
    #
    # @return [String]
    attr_accessor :version

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
          create('2.0', '2.0/NCS_Transmission_Schema_V2.0.00.00.xsd')
        else
          raise "MDES #{version} is not supported by this version of ncs-mdes"
        end
      end

      def create(version, schema)
        self.new.tap do |sd|
          sd.version = version
          sd.schema = schema
        end
      end
      private :create

      ##
      # A mapping of prefixes to XML namespaces for use with
      # Nokogiri xpath.
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
      @base ||= (ENV[BASE_ENV_VAR] || '/etc/nubic/ncs/mdes')
    end

    ##
    # The absolute path to the XML Schema describing the MDES
    # transmission structure for this instance.
    #
    # @return [String]
    def schema
      @schema[0, 1] == '/' ? @schema : File.join(base, @schema)
    end

    ##
    # Set the path to the MDES transmission structure XML Schema.
    # If the path is relative (i.e., it does not begin with `/`), it
    # will be interpreted relative to {#base}.
    #
    # @param [String] path
    def schema=(path)
      @schema = path
    end
  end
end

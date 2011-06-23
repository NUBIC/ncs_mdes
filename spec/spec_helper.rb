require 'rspec'
require 'nokogiri'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ncs_navigator/mdes'

RSpec.configure do |config|
  config.before(:all) do
    v = NcsNavigator::Mdes::SourceDocuments::BASE_ENV_VAR
    @original_base, ENV[v] = ENV[v], File.expand_path('../doc-base', __FILE__)
  end

  config.after(:all) do
    ENV[NcsNavigator::Mdes::SourceDocuments::BASE_ENV_VAR] = @original_base
  end

  def logger
    @logger ||= NcsNavigator::Mdes::Spec::AccumulatingLogger.new
  end

  ##
  # Returns a parsed XML element whose root ancestor is an appropriate
  # schema root.
  #
  # @param [String] xml_fragment
  def schema_element(xml_fragment)
        Nokogiri::XML(<<-XSD).root.elements.first
<xs:schema xmlns="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ncs="http://www.nationalchildrensstudy.gov" xmlns:ncsdoc="http://www.nationalchildrensstudy.gov/doc" xmlns:xlink="http://www.w3.org/TR/WD-xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="http://www.nationalchildrensstudy.gov" elementFormDefault="unqualified" attributeFormDefault="unqualified">
  #{xml_fragment}
</xs:schema>
XSD
  end
end

module NcsNavigator::Mdes
  module Spec
    ##
    # A logger that holds on to everything that is logged for later examination.
    class AccumulatingLogger
      def messages
        @messages ||= {}
      end

      def [](name)
        messages[name] ||= []
      end

      def method_missing(name, *args)
        self[name] << (args.size == 1 ? args.first : args)
        true # what Logger does
      end
    end
  end
end

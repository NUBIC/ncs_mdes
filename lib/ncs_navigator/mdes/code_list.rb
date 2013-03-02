require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  ##
  # A specialization of `Array` for code lists.
  #
  # @see VariableType#code_list
  # @see CodeListEntry
  class CodeList < Array
    ##
    # @return [String,nil] the description of the code list if any.
    attr_accessor :description
  end

  ##
  # A single entry in a code list.
  #
  # @see VariableType#code_list
  # @see CodeList
  class CodeListEntry
    ##
    # @return [String] the local code value for the entry.
    attr_reader :value

    ##
    # @return [String] the human-readable label for the entry.
    attr_accessor :label

    ##
    # @return [String] the MDES's globally-unique identifier for
    #   this coded value.
    attr_accessor :global_value

    ##
    # @return [String] the name of MDES's master code list from
    #   which this value is derived.
    attr_accessor :master_cl

    class << self
      ##
      # Creates a new instance from a `xs:enumeration` simple type
      # restriction subelement.
      #
      # @param [Nokogiri::XML::Element] enum the `xs:enumeration`
      #   element.
      # @param [Hash] options
      # @option options [#warn] :log the logger to which to direct warnings
      #
      # @return [CodeListEntry]
      def from_xsd_enumeration(enum, options={})
        log = options[:log] || NcsNavigator::Mdes.default_logger

        log.warn("Missing value for code list entry on line #{enum.line}") unless enum['value']

        new(enum['value'] && enum['value'].strip).tap do |cle|
          cle.label = enum['ncsdoc:label']
          cle.global_value = enum['ncsdoc:global_value']
          cle.master_cl = enum['ncsdoc:master_cl']
        end
      end
    end

    def initialize(value)
      @value = value
    end

    alias :to_s :value

    def diff_criteria(diff_options)
      if diff_options[:strict]
        {
          :value        => Differences::ValueCriterion.new,
          :label        => Differences::ValueCriterion.new,
          :global_value => Differences::ValueCriterion.new,
          :master_cl    => Differences::ValueCriterion.new
        }
      else
        {
          :value => Differences::ValueCriterion.new,
          :label => Differences::ValueCriterion.new(:value_extractor => :word_chars_downcase)
        }
      end
    end
    protected :diff_criteria

    ##
    # Computes the differences between this code list entry and the other.
    #
    # @return [Differences::Entry,nil]
    def diff(other, options={})
      Differences::Entry.compute(self, other, diff_criteria(options), options)
    end
  end
end

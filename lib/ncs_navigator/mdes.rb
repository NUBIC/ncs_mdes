require 'logger'

module NcsNavigator
  module Mdes
    autoload :VERSION, 'ncs_navigator/mdes/version'

    autoload :SourceDocuments,   'ncs_navigator/mdes/source_documents'
    autoload :Specification,     'ncs_navigator/mdes/specification'
    autoload :TransmissionTable, 'ncs_navigator/mdes/transmission_table'
    autoload :Variable,          'ncs_navigator/mdes/variable'
    autoload :VariableType,      'ncs_navigator/mdes/variable_type'

    ##
    # @return the default logger for this module when no other one is
    #   specified. It logs to standard error.
    def self.default_logger
      @default_logger ||= Logger.new($stderr)
    end
  end

  ##
  # @return [Mdes::Specification] a new {Mdes::Specification} for the given
  #   version.
  def self.Mdes(version)
    Mdes::Specification.new(version)
  end
end

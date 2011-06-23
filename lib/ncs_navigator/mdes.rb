require 'logger'

module NcsNavigator
  module Mdes
    autoload :VERSION, 'ncs_navigator/mdes/version'

    autoload :SourceDocuments,   'ncs_navigator/mdes/source_documents'
    autoload :Specification,     'ncs_navigator/mdes/specification'
    autoload :TransmissionTable, 'ncs_navigator/mdes/transmission_table'
    autoload :Variable,          'ncs_navigator/mdes/variable'
    autoload :VariableType,      'ncs_navigator/mdes/variable_type'

    def self.default_logger
      @default_logger ||= Logger.new($stderr)
    end
  end

  def self.Mdes(version)
    Mdes::Specification.new(version)
  end
end

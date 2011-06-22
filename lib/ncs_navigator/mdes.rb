module NcsNavigator
  module Mdes
    autoload :VERSION, 'ncs_navigator/mdes/version'

    autoload :SourceDocuments, 'ncs_navigator/mdes/source_documents'
    autoload :Specification,   'ncs_navigator/mdes/specification'
  end

  def self.Mdes(version)
    Mdes::Specification.new(version)
  end
end

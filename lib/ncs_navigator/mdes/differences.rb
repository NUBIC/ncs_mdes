require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  module Differences
    autoload :Entry,      'ncs_navigator/mdes/differences/entry'
    autoload :Collection, 'ncs_navigator/mdes/differences/collection'
    autoload :Value,      'ncs_navigator/mdes/differences/value'

    autoload :CollectionCriterion, 'ncs_navigator/mdes/differences/collection_criterion'
    autoload :ValueCriterion,      'ncs_navigator/mdes/differences/value_criterion'
  end
end

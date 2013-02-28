require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  module Differences
    autoload :Entry, 'ncs_navigator/mdes/differences/entry'
    autoload :Value, 'ncs_navigator/mdes/differences/value'

    autoload :ValueCriterion, 'ncs_navigator/mdes/differences/value_criterion'
  end
end

require 'ncs_navigator/mdes'

module NcsNavigator::Mdes::Differences
  ##
  # Captures the differences between a simple scalar value.
  Value = Struct.new(:left, :right)
end

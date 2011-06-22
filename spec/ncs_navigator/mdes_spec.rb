require File.expand_path('../../spec_helper.rb', __FILE__)

module NcsNavigator
  describe Mdes do
    it 'is both a method and a module' do
      ::NcsNavigator::Mdes('2.0').should be_a(Mdes::Specification)
    end
  end
end

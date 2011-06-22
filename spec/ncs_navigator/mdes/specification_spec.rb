require File.expand_path('../../../spec_helper', __FILE__)

module NcsNavigator::Mdes
  describe Specification do
    describe '#version' do
      it 'delegates to the source documents' do
        Specification.new('1.2').version.should == '1.2'
      end
    end

    describe '#initialize' do
      it 'accepts a string version' do
        Specification.new('2.0').version.should == '2.0'
      end

      it 'accepts a SourceDocuments instance' do
        Specification.new(SourceDocuments.new.tap { |s| s.version = '3.1' }).version.
          should == '3.1'
      end
    end

    describe '#xsd' do
      it 'is parsed' do
        Specification.new('1.2').xsd.root.name.should == 'schema'
      end
    end

    describe '#transmission_tables' do
      it 'has 124 tables in version 1.2' do
        Specification.new('1.2').should have(124).transmission_tables
      end

      it 'has 264 tables in version 2.0' do
        Specification.new('2.0').should have(264).transmission_tables
      end
    end
  end
end

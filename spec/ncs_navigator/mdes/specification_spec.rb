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
        Specification.new('1.2', :log => logger).xsd.root.name.should == 'schema'
      end
    end

    describe '#transmission_tables' do
      it 'is composed of TransmissionTable instances' do
        Specification.new('2.0', :log => logger).transmission_tables.first.
          should be_a TransmissionTable
      end

      context 'in version 1.2' do
        let!(:tables) { Specification.new('1.2', :log => logger).transmission_tables }

        it 'has 124 tables' do
          tables.size.should == 124
        end

        it 'emits no warnings' do
          logger[:warn].size.should == 0
        end
      end

      context 'in version 2.0' do
        let!(:tables) { Specification.new('2.0', :log => logger).transmission_tables }

        it 'has 264 tables' do
          tables.size.should == 264
        end

        it 'emits no warnings' do
          logger[:warn].size.should == 0
        end
      end
    end
  end
end

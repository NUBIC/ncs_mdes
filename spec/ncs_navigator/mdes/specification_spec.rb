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

      shared_examples 'tables fully resolved' do
        it 'emits no warnings' do
          logger[:warn].should == []
        end

        it 'resolves all NCS type references' do
          tables.collect { |table|
            table.variables.collect { |v| v.type }.select { |t| t.reference? }
          }.flatten.collect { |t| t.name }.select { |n| n =~ /^ncs:/ }.should == []
        end
      end

      context 'in version 1.2' do
        let!(:tables) { Specification.new('1.2', :log => logger).transmission_tables }

        it 'has 124 tables' do
          tables.size.should == 124
        end

        include_examples 'tables fully resolved'
      end

      context 'in version 2.0' do
        let!(:tables) { Specification.new('2.0', :log => logger).transmission_tables }

        it 'has 264 tables' do
          tables.size.should == 264
        end

        include_examples 'tables fully resolved'
      end
    end
    
    
    describe '#disposition codes' do
      it 'is composed of DispositionCode instances' do
        Specification.new('2.0', :log => logger).disposition_codes.first.
          should be_a DispositionCode
      end

      context 'in version 1.2' do
        let(:disposition_codes) { Specification.new('1.2', :log => logger).disposition_codes }

        it 'has 0 codes' do
          disposition_codes.size.should == 0
        end
      end

      context 'in version 2.0' do
        let(:disposition_codes) { Specification.new('2.0', :log => logger).disposition_codes }

        it 'has 251 codes' do
          disposition_codes.size.should == 251
        end

        it 'creates valid codes' do
          code = disposition_codes.first
          code.event.should          == "Household Enumeration Event"
          code.final_category.should == "Unknown Eligibility"
          code.sub_category.should   == "Unknown if Dwelling Unit"
          code.disposition.should    == "Not attempted"
          code.interim_code.should   == "010"
          code.final_code.should     == "510"
        end

      end
    end

    describe '#[]' do
      let(:spec) { Specification.new('2.0') }

      describe 'with a string' do
        it 'returns a single table if there is a match by name' do
          spec['listing_unit'].should be_a TransmissionTable
        end

        it 'returns nothing if there is no match' do
          spec['fred'].should be_nil
        end
      end

      describe 'with a regular expression' do
        it 'returns a list of tables whose names match' do
          spec[/^preg_visit_1.*2$/].should have(15).tables
        end
      end
    end

    describe '#types' do
      it 'is composed of VariableType instances' do
        Specification.new('2.0', :log => logger).types.first.
          should be_a VariableType
      end

      context 'in version 1.2' do
        let!(:types) { Specification.new('1.2', :log => logger).types }

        it 'has 281 types' do
          types.size.should == 281
        end

        it 'emits no warnings' do
          logger[:warn].size.should == 0
        end
      end

      context 'in version 2.0' do
        let!(:types) { Specification.new('2.0', :log => logger).types }

        it 'has 423 types' do
          types.size.should == 423
        end

        it 'emits no warnings' do
          logger[:warn].size.should == 0
        end
      end
    end
  end
end

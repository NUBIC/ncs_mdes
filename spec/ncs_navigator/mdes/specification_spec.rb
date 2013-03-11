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
        let!(:tables) { Specification.new(version, :log => logger).transmission_tables }

        it 'has the right number of tables' do
          tables.size.should == expected_table_count
        end

        it 'emits no warnings' do
          logger[:warn].should == []
        end

        it 'resolves all NCS type references' do
          tables.collect { |table|
            table.variables.collect { |v| v.type }.select { |t| t.reference? }
          }.flatten.collect { |t| t.name }.select { |n| n =~ /^ncs:/ }.should == []
        end

        it 'can determine if each table is instrument or operational' do
          tables.each do |table|
            lambda { table.instrument_table? }.should_not raise_error
          end
        end

        it 'knows the mother-childness of all p_id-bearing instrument tables' do
          p_id_instrument_tables = tables.select { |t| t.instrument_table? && t.variables.collect(&:name).include?('p_id') }
          p_id_instrument_tables.
            reject { |t| [true, false].include?(t.child_instrument_table?) }.
            collect { |t| t.name }.should == []
        end

        it 'has some child and some parent instrument data tables' do
          index = tables.each_with_object(Hash.new(0)) { |t, acc| acc[t.child_instrument_table?] += 1 }
          index.keys.sort_by { |k| k.inspect }.should == [false, nil, true]
        end
      end

      context 'in version 1.2' do
        let(:version) { '1.2' }
        let(:expected_table_count) { 124 }

        include_examples 'tables fully resolved'
      end

      context 'in version 2.0' do
        let(:version) { '2.0' }
        let(:expected_table_count) { 264 }

        include_examples 'tables fully resolved'
      end

      context 'in version 2.1' do
        let(:version) { '2.1' }
        let(:expected_table_count) { 270 }

        include_examples 'tables fully resolved'
      end

      context 'in version 2.2' do
        let(:version) { '2.2' }
        let(:expected_table_count) { 329 }

        include_examples 'tables fully resolved'
      end

      context 'in version 3.0' do
        let(:version) { '3.0' }
        let(:expected_table_count) { 407 }

        include_examples 'tables fully resolved'
      end

      context 'in version 3.1' do
        let(:version) { '3.1' }
        let(:expected_table_count) { 553 }

        include_examples 'tables fully resolved'
      end

      context 'in version 3.2' do
        let(:version) { '3.2' }
        let(:expected_table_count) { 576 }

        include_examples 'tables fully resolved'
      end
    end

    describe '#specification_version' do
      it 'is the named version by default' do
        Specification.new('1.2').specification_version.should == '1.2'
      end

      it 'is the read-in version if the source has one' do
        Specification.new('2.0').specification_version.should == '2.0.01.02'
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

      context 'in version 2.1' do
        let(:disposition_codes) { Specification.new('2.1', :log => logger).disposition_codes }

        it 'has 251 codes' do
          disposition_codes.size.should == 251
        end
      end

      context 'in version 2.2' do
        let(:disposition_codes) { Specification.new('2.2', :log => logger).disposition_codes }

        it 'has 251 codes' do
          disposition_codes.size.should == 251
        end
      end

      context 'in version 3.0' do
        let(:disposition_codes) { Specification.new('3.0', :log => logger).disposition_codes }

        it 'has 332 codes' do
          disposition_codes.size.should == 332
        end
      end

      context 'in version 3.1' do
        let(:disposition_codes) { Specification.new('3.1', :log => logger).disposition_codes }

        it 'has 332 codes' do
          disposition_codes.size.should == 332
        end
      end

      context 'in version 3.2' do
        let(:disposition_codes) { Specification.new('3.2', :log => logger).disposition_codes }

        it 'has 332 codes' do
          disposition_codes.size.should == 332
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

      shared_examples 'types fully resolved' do
        let!(:types) { Specification.new(version, :log => logger).types }

        it 'has the expected number of types' do
          types.size.should == expected_type_count
        end

        it 'emits no warnings' do
          logger[:warn].size.should == 0
        end
      end

      context 'in version 1.2' do
        let(:version) { '1.2' }
        let(:expected_type_count) { 281 }

        include_examples 'types fully resolved'
      end

      context 'in version 2.0' do
        let(:version) { '2.0' }
        let(:expected_type_count) { 423 }

        include_examples 'types fully resolved'
      end

      context 'version 2.1' do
        let(:version) { '2.1' }
        let(:expected_type_count) { 433 }

        include_examples 'types fully resolved'
      end

      context 'version 2.2' do
        let(:version) { '2.2' }
        let(:expected_type_count) { 454 }

        include_examples 'types fully resolved'
      end

      context 'version 3.0' do
        let(:version) { '3.0' }
        let(:expected_type_count) { 517 }

        include_examples 'types fully resolved'
      end

      context 'version 3.1' do
        let(:version) { '3.1' }
        let(:expected_type_count) { 646 }

        include_examples 'types fully resolved'
      end

      context 'version 3.2' do
        let(:version) { '3.2' }
        let(:expected_type_count) { 651 }

        include_examples 'types fully resolved'
      end
    end

    describe '#diff' do
      let(:diff) {
        Specification.new('2.0').diff(Specification.new('2.1'))
      }

      it 'finds different spec versions' do
        diff[:specification_version].should be_a_value_diff('2.0.01.02', '2.1.00.00')
      end

      it 'finds different tables' do
        diff[:transmission_tables].right_only.should include('preg_visit_1_saq_3')
      end

      it 'finds different types' do
        diff[:types].right_only.should include('person_partcpnt_reltnshp_cl5')
      end
    end
  end
end

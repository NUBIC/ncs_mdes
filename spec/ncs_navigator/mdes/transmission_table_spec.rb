require File.expand_path('../../../spec_helper', __FILE__)

require 'nokogiri'

module NcsNavigator::Mdes
  describe TransmissionTable do
    describe '.from_element' do
      let(:element) {
        Nokogiri::XML(<<-XSD).root.xpath('//xs:element[@name="study_center"]').first
<xs:schema xmlns="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ncs="http://www.nationalchildrensstudy.gov" xmlns:ncsdoc="http://www.nationalchildrensstudy.gov/doc" xmlns:xlink="http://www.w3.org/TR/WD-xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="http://www.nationalchildrensstudy.gov" elementFormDefault="unqualified" attributeFormDefault="unqualified">
  <xs:element name="transmission_tables">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="study_center" minOccurs="0" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="sc_id" ncsdoc:pii="" ncsdoc:status="1" ncsdoc:key_asso="" nillable="false" type="ncs:study_center_cl1"/>
              <xs:element name="sc_name" ncsdoc:pii="" ncsdoc:status="1" ncsdoc:key_asso="" nillable="true">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:maxLength value="100"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="comments" ncsdoc:pii="P" ncsdoc:status="1" ncsdoc:key_asso="" nillable="true">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:maxLength value="8000"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
              <xs:element name="transaction_type" ncsdoc:pii="" ncsdoc:status="1" ncsdoc:key_asso="" nillable="true">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:maxLength value="36"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
XSD
      }

      subject { TransmissionTable.from_element(element) }

      it 'has the right name' do
        subject.name.should == 'study_center'
      end

      it 'has the right variables' do
        subject.variables.collect(&:name).
          should == %w(sc_id sc_name comments transaction_type)
      end
    end

    describe '#initialize' do
      it 'accepts a name' do
        TransmissionTable.new('study_center').name.should == 'study_center'
      end
    end

    describe '#[]' do
      subject {
        TransmissionTable.new('example').tap do |t|
          t.variables = %w(foo bar baz).collect do |n|
            Variable.new(n)
          end
        end
      }

      it 'gets a variable' do
        subject['bar'].should be_a(Variable)
      end

      it 'gets a variable by name' do
        subject['baz'].name.should == 'baz'
      end

      it 'is nil for an unknown variable' do
        subject['quux'].should be_nil
      end
    end

    describe 'instrument table detection' do
      def table_with_variables(table_name, *variables)
        TransmissionTable.new(table_name).tap { |t|
          t.variables = variables.collect { |vn| Variable.new(vn) }
        }
      end

      let(:event) { table_with_variables('event', 'event_id') }
      let(:instrument) { table_with_variables('instrument', 'instrument_id', 'instrument_version') }

      let(:spec_blood) {
        table_with_variables('spec_blood', 'spec_blood_id',
          'instrument_id', 'instrument_type', 'instrument_version')
      }
      let(:spec_blood_tube) {
        table_with_variables('spec_blood_tube', 'spec_blood_tube_id', 'spec_blood_id').tap do |t|
          t.variables.detect { |v| v.name == 'spec_blood_id' }.table_reference = spec_blood
        end
      }
      let(:spec_blood_tube_comments) {
        table_with_variables(
          'spec_blood_tube_comments',
          'spec_blood_tube_comments_id', 'spec_blood_tube_id'
        ).tap do |t|
          t.variables.detect { |v| v.name == 'spec_blood_tube_id' }.
            table_reference = spec_blood_tube
        end
      }

      describe '#instrument_table?' do
        it 'does not consider tables without instrument_version to be instrument tables' do
          event.should_not be_instrument_table
        end

        it 'does not consider the instrument operational table to be an instrument table' do
          instrument.should_not be_instrument_table
        end

        it 'considers primary instrument tables to be instrument tables' do
          spec_blood.should be_instrument_table
        end

        it 'considers secondary instrument tables to be instrument tables' do
          spec_blood_tube.should be_instrument_table
        end

        it 'considers tertiary instrument tables to be instrument tables' do
          spec_blood_tube_comments.should be_instrument_table
        end

        it 'does not consider circularly referring tables to be instrument tables' do
          person = table_with_variables('person', 'new_address_id')
          address = table_with_variables('address', 'person_id')
          address.variables.first.table_reference = person
          person.variables.first.table_reference = address

          address.should_not be_instrument_table
          person.should_not be_instrument_table
        end
      end

      describe '#primary_instrument_table?' do
        it 'does not consider tables without instrument_version to be a primary instrument table' do
          event.should_not be_primary_instrument_table
        end

        it 'does not consider the instrument operational table to be a primary instrument table' do
          instrument.should_not be_primary_instrument_table
        end

        it 'considers primary instrument tables to be primary instrument tables' do
          spec_blood.should be_primary_instrument_table
        end

        it 'does not consider secondary instrument tables to be primary instrument tables' do
          spec_blood_tube.should_not be_primary_instrument_table
        end

        it 'does not consider tertiary instrument tables to be primary instrument tables' do
          spec_blood_tube_comments.should_not be_primary_instrument_table
        end
      end

      describe '#operational_table?' do
        it 'is the opposite of instrument_table?' do
          [
            event, instrument, spec_blood, spec_blood_tube, spec_blood_tube_comments
          ].each do |table|
            table.instrument_table?.should == !table.operational_table?
          end
        end
      end
    end
  end
end

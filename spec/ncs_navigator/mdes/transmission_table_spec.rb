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
  end
end

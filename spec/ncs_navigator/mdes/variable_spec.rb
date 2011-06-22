require File.expand_path('../../../spec_helper', __FILE__)

require 'nokogiri'

module NcsNavigator::Mdes
  describe Variable do
    describe '.from_element' do
      def variable_element(s)
        Nokogiri::XML(<<-XSD).root.elements.first
<xs:schema xmlns="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ncs="http://www.nationalchildrensstudy.gov" xmlns:ncsdoc="http://www.nationalchildrensstudy.gov/doc" xmlns:xlink="http://www.w3.org/TR/WD-xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="http://www.nationalchildrensstudy.gov" elementFormDefault="unqualified" attributeFormDefault="unqualified">
  #{s}
</xs:schema>
XSD
      end

      def variable(s)
        Variable.from_element(variable_element(s))
      end

      let(:comments) {
        variable(<<-XSD)
<xs:element name="comments" ncsdoc:pii="P" ncsdoc:status="1" ncsdoc:key_asso="" nillable="true">
 <xs:simpleType>
  <xs:restriction base="xs:string">
   <xs:maxLength value="8000"/>
  </xs:restriction>
 </xs:simpleType>
</xs:element>
XSD
      }

      it 'has the correct name' do
        comments.name.should == 'comments'
      end

      describe '#required?' do
        it 'is true when not nillable' do
          variable('<xs:element nillable="false"/>').should be_required
        end

        it 'is false when nillable' do
          comments.should_not be_required
        end
      end

      describe '#pii' do
        it 'is false when blank' do
          variable('<xs:element ncsdoc:pii=""/>').pii.should == false
        end

        it 'is true when "Y"' do
          variable('<xs:element ncsdoc:pii="Y"/>').pii.should == true
        end

        it 'is :possible when "P"' do
          variable('<xs:element ncsdoc:pii="P"/>').pii.should == :possible
        end

        it 'is the literal value when some other value' do
          variable('<xs:element ncsdoc:pii="7"/>').pii.should == '7'
        end

        it 'is :unknown when not set' do
          variable('<xs:element/>').pii.should == :unknown
        end
      end

      describe '#status' do
        it 'is :active for 1' do
          variable('<xs:element ncsdoc:status="1"/>').status.should == :active
        end

        it 'is :new for 2' do
          variable('<xs:element ncsdoc:status="2"/>').status.should == :new
        end

        it 'is :modified for 3' do
          variable('<xs:element ncsdoc:status="3"/>').status.should == :modified
        end

        it 'is :retired for 4' do
          variable('<xs:element ncsdoc:status="4"/>').status.should == :retired
        end

        it 'is the literal value for some other value' do
          variable('<xs:element ncsdoc:status="P4"/>').status.should == 'P4'
        end

        it 'is nil when not set' do
          variable('<xs:element/>').status.should be_nil
        end
      end
    end
  end
end

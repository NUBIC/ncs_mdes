require File.expand_path('../../../spec_helper', __FILE__)

require 'nokogiri'

module NcsNavigator::Mdes
  describe VariableType do
    describe '.from_xsd_simple_type' do
      def vtype(body_s, name=nil)
        VariableType.from_xsd_simple_type(schema_element(<<-XML), :log => logger)
          <xs:simpleType #{name ? "name='#{name}'" : nil}>
            #{body_s}
          </xs:simpleType>
        XML
      end

      def vtype_from_string(restriction_body, name=nil)
        vtype(<<-XML, name)
          <xs:restriction base="xs:string">
            #{restriction_body}
          </xs:restriction>
        XML
      end

      describe 'with an unsupported restriction base' do
        let!(:subject) { vtype('<xs:restriction base="xs:int"/>') }

        it 'is nil' do
          subject.should be_nil
        end

        it 'logs a warning' do
          logger[:warn].first.
            should == 'Unsupported restriction base in simpleType on line 2'
        end
      end

      describe 'with an unsupported restriction subelement' do
        let!(:subject) { vtype_from_string('<xs:color value="red"/>') }

        it 'logs a warning' do
          logger[:warn].first.should == 'Unsupported restriction element "color" on line 4'
        end
      end

      describe '#name' do
        it 'is set if there is one' do
          vtype_from_string(nil, 'foo').name.should == 'foo'
        end

        it 'is nil if there is not one' do
          vtype_from_string(nil, nil).name.should be_nil
        end
      end

      describe '#max_length' do
        it 'is set if present' do
          vtype_from_string('<xs:maxLength value="255"/>').max_length.should == 255
        end
      end

      describe '#min_length' do
        it 'is set if present' do
          vtype_from_string('<xs:minLength value="1"/>').min_length.should == 1
        end
      end

      describe '#pattern' do
        it 'is compiled to a regexp if present' do
          vtype_from_string('<xs:pattern value="([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])?"/>').
            pattern.should == /([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])?/
        end

        describe 'when malformed' do
          let!(:subject) { vtype_from_string('<xs:pattern value="(["/>') }

          it 'is nil if present but malformed' do
            subject.pattern.should be_nil
          end

          it 'logs a warning' do
            logger[:warn].first.should == 'Uncompilable pattern "([" in simpleType on line 4'
          end
        end
      end

      describe '#base_type' do
        it 'is :string' do
          vtype_from_string('<xs:maxLength value="255"/>').base_type.should == :string
        end
      end

      it 'is not a reference' do
        vtype_from_string('<xs:maxLength value="255"/>').should_not be_reference
      end

      describe '#code_list' do
        context 'when there are no enumerated values' do
          it 'is nil' do
            vtype_from_string('<xs:maxLength value="255"/>').code_list.should be_nil
          end
        end

        context 'when there are enumerated values' do
          subject {
            vtype_from_string(<<-XSD)
              <xs:enumeration value="1" ncsdoc:label="Retired" ncsdoc:desc="Eq" ncsdoc:global_value="192-1" ncsdoc:master_cl="equipment_action"/>
              <xs:enumeration value="2" ncsdoc:label="Sent to manufacturer" ncsdoc:desc="Eq" ncsdoc:global_value="192-2" ncsdoc:master_cl="equipment_action"/>
              <xs:enumeration value="3" ncsdoc:label="Conducting Maintenance on Site" ncsdoc:desc="Eq" ncsdoc:global_value="192-3" ncsdoc:master_cl="equipment_action"/>
              <xs:enumeration value="-7" ncsdoc:label="Not applicable" ncsdoc:desc="Eq" ncsdoc:global_value="99-7" ncsdoc:master_cl="missing_data"/>
              <xs:enumeration value="-4" ncsdoc:label="Missing in Error" ncsdoc:desc="Eq" ncsdoc:global_value="99-4" ncsdoc:master_cl="missing_data"/>
            XSD
          }

          it 'has an entry for each value' do
            subject.code_list.collect(&:to_s).should == %w(1 2 3 -7 -4)
          end

          it 'has the description' do
            subject.code_list.description.should == "Eq"
          end
        end
      end
    end

    describe '.reference' do
      subject { VariableType.reference('ncs:bar') }

      it 'has the right name' do
        subject.name.should == 'ncs:bar'
      end

      it 'is a reference' do
        subject.should be_reference
      end
    end

    describe '.xml_schema_type' do
      subject { VariableType.xml_schema_type('int') }

      it 'has no name' do
        subject.name.should be_nil
      end

      it 'has the correct base type' do
        subject.base_type.should == :int
      end

      it 'is not a reference' do
        subject.should_not be_reference
      end
    end
  end

  describe VariableType::CodeListEntry do
    describe '.from_xsd_enumeration' do
      def code_list_entry(xml_s)
        VariableType::CodeListEntry.from_xsd_enumeration(schema_element(xml_s), :log => logger)
      end

      let(:missing) {
        code_list_entry(<<-XSD)
          <xs:enumeration value="-4" ncsdoc:label="Missing in Error" ncsdoc:desc="" ncsdoc:global_value="99-4" ncsdoc:master_cl="missing_data"/>
        XSD
      }

      describe '#value' do
        it 'is set' do
          missing.value.should == "-4"
        end

        it 'warns when missing' do
          code_list_entry('<xs:enumeration ncsdoc:label="Foo"/>')
          logger[:warn].first.should == 'Missing value for code list entry on line 2'
        end
      end

      describe "#label" do
        it 'is set' do
          missing.label.should == "Missing in Error"
        end
      end

      describe '#global_value' do
        it 'is set' do
          missing.global_value.should == '99-4'
        end
      end

      describe '#master_cl' do
        it 'is set' do
          missing.master_cl.should == 'missing_data'
        end
      end
    end

    describe '#to_s' do
      it 'is the value' do
        VariableType::CodeListEntry.new('14').to_s.should == '14'
      end
    end
  end
end

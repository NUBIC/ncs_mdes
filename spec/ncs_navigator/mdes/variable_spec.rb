require File.expand_path('../../../spec_helper', __FILE__)

require 'nokogiri'

module NcsNavigator::Mdes
  describe Variable do
    describe '.from_element' do
      def variable(s)
        Variable.from_element(schema_element(s), :log => logger)
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

      let(:sc_id) {
        variable('<xs:element name="sc_id" ncsdoc:pii="" ncsdoc:status="1" ncsdoc:key_asso="" nillable="false" type="ncs:study_center_cl1"/>')
      }

      it 'has the correct name' do
        comments.name.should == 'comments'
      end

      describe '#type' do
        context 'when embedded' do
          it 'is a VariableType' do
            comments.type.should be_a VariableType
          end

          it 'is parsed from the contents' do
            comments.type.max_length.should == 8000
          end

          it 'is not a reference' do
            comments.type.should_not be_reference
          end
        end

        context 'when a named type' do
          context 'with the XML schema prefix' do
            let!(:subject) { variable('<xs:element type="xs:decimal"/>') }

            it 'is a VariableType' do
              subject.type.should be_a VariableType
            end

            it 'has a matching base type' do
              subject.type.base_type.should == :decimal
            end

            it 'is not a reference' do
              subject.type.should_not be_reference
            end
          end

          context 'with another prefix' do
            it 'is a VariableType' do
              sc_id.type.should be_a VariableType
            end

            it 'has the name' do
              sc_id.type.name.should == 'ncs:study_center_cl1'
            end

            it 'is a reference' do
              sc_id.type.should be_reference
            end
          end
        end

        context 'when none present' do
          let!(:subject) { variable('<xs:element name="bar"/>') }

          it 'is nil' do
            subject.type.should be_nil
          end

          it 'warns' do
            logger[:warn].first.should == 'Could not determine a type for variable "bar" on line 2'
          end
        end
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

    describe '#resolve_type!' do
      let(:reference_type) { VariableType.reference('ncs:color_cl3') }
      let(:actual_type)    { VariableType.new('color_cl3') }

      let(:types) { [ actual_type ] }
      let(:variable) {
        Variable.new('hair_color').tap { |v| v.type = reference_type }
      }

      context 'when the type is available' do
        it 'resolves' do
          variable.resolve_type!(types)
          variable.type.should be actual_type
        end
      end

      context 'when the type is not resolvable' do
        before { variable.resolve_type!([], :log => logger) }

        it 'leaves the reference alone' do
          variable.type.should be reference_type
        end

        it 'warns' do
          logger[:warn].first.should == 'Undefined type ncs:color_cl3 for hair_color.'
        end
      end

      context 'when the reference is of an unknown namespace' do
        let(:unknown_kind_of_ref) { VariableType.reference('foo:bar') }

        before {
          variable.type = unknown_kind_of_ref
          variable.resolve_type!(types, :log => logger)
        }

        it 'leaves it in place' do
          variable.type.should be unknown_kind_of_ref
        end

        it 'warns' do
          logger[:warn].first.
            should == 'Unknown reference namespace in type "foo:bar" for hair_color'
        end
      end

      context 'when the type is an XML Schema type' do
        it 'ignores it' do
          variable.type = VariableType.xml_schema_type('decimal')
          variable.resolve_type!(types, :log => logger)
          logger[:warn].should == []
        end
      end

      context 'when the type is not a reference' do
        let(:not_a_ref) { VariableType.new('ncs:color_cl3') }

        it 'does nothing' do
          variable.type = not_a_ref
          variable.resolve_type!(types)
          variable.type.should be not_a_ref
        end
      end
    end
  end
end

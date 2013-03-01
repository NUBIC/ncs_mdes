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
            pattern.should == /^([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])?$/
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

    describe '#diff' do
      let(:a)      { VariableType.new('A') }
      let(:aprime) { VariableType.new('A') }

      let(:differences) { a.diff(aprime) }

      it 'reports nothing when they are the same' do
        differences.should be_nil
      end

      describe 'name' do
        it 'reports a difference' do
          a.diff(VariableType.new('B'))[:name].should be_a_value_diff('A', 'B')
        end
      end

      describe 'base_type' do
        it 'reports a difference' do
          a.base_type = :int
          aprime.base_type = :decimal

          differences[:base_type].should be_a_value_diff(:int, :decimal)
        end
      end

      describe 'pattern' do
        it 'reports a difference' do
          a.pattern = /^(0-9){4}$/
          aprime.pattern = /^(0-9){5}$/

          differences[:pattern].should be_a_value_diff(/^(0-9){4}$/, /^(0-9){5}$/)
        end
      end

      describe 'max_length' do
        it 'reports a difference' do
          a.max_length = nil
          aprime.max_length = 18

          differences[:max_length].should be_a_value_diff(nil, 18)
        end
      end

      describe 'min_length' do
        it 'reports a difference' do
          a.min_length = 1
          aprime.min_length = nil

          differences[:min_length].should be_a_value_diff(1, nil)
        end
      end

      describe 'code_list' do
        let(:cl) { CodeList.new }
        let(:clprime) { CodeList.new }

        def cle(value, label)
          CodeListEntry.new(value).tap { |e| e.label = label }
        end

        let(:e_one)         { cle( '1', 'Hand grenades')}
        let(:e_five)        { cle( '5', 'Horseshoes') }
        let(:e_other)       { cle('-5', 'Other') }
        let(:e_other_prime) { cle( '5', 'Other') }

        describe 'when only the left has a code list' do
          before do
            a.code_list = cl
            cl << e_one << e_other
          end

          it 'reports all entries as left only by value' do
            differences[:code_list_by_value].left_only.should == %w(1 -5)
          end

          it 'reports all entries as left only by label' do
            differences[:code_list_by_label].left_only.should == ['Hand grenades', 'Other']
          end
        end

        describe 'when only the right has a code list' do
          before do
            aprime.code_list = clprime
            clprime << e_five << e_other
          end

          it 'reports all entries as right only by value' do
            differences[:code_list_by_value].right_only.should == %w(5 -5)
          end

          it 'reports all entries as right only by label' do
            differences[:code_list_by_label].right_only.should == ['Horseshoes', 'Other']
          end
        end

        describe 'when both have code lists' do
          before do
            a.code_list = cl
            aprime.code_list = clprime
          end

          describe 'and they are the same' do
            before do
              cl << e_one << e_five
              clprime << e_one << e_five
            end

            it 'reports no differences' do
              differences.should be_nil
            end
          end

          describe 'and they differ by labels only' do
            before do
              cl << e_one << e_five
              clprime << e_one << e_other_prime
            end

            it 'reports the entry difference in the by-value attribute' do
              differences[:code_list_by_value]['5'][:label].
                should be_a_value_diff('Horseshoes', 'Other')
            end

            it 'reports extra entries in the by-label attribute' do
              differences[:code_list_by_label].left_only.should == ['Horseshoes']
              differences[:code_list_by_label].right_only.should == ['Other']
            end
          end

          describe 'and they differ by values only' do
            before do
              cl << e_other << e_one
              clprime << e_one << e_other_prime
            end

            it 'reports the entry difference in the by-label attribute' do
              differences[:code_list_by_label]['Other'][:value].
                should be_a_value_diff('-5', '5')
            end

            it 'reports extra entries in the by-value attribute' do
              differences[:code_list_by_value].left_only.should == ['-5']
              differences[:code_list_by_value].right_only.should == ['5']
            end
          end
        end
      end
    end
  end
end

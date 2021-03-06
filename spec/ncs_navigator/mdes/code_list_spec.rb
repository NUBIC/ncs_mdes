require File.expand_path('../../../spec_helper', __FILE__)

require 'nokogiri'

module NcsNavigator::Mdes
  describe CodeListEntry do
    describe '.from_xsd_enumeration' do
      def code_list_entry(xml_s)
        CodeListEntry.from_xsd_enumeration(schema_element(xml_s), :log => logger)
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

        describe 'with external whitespace on the value' do
          let(:missing) {
            code_list_entry(<<-XSD)
              <xs:enumeration value="  -4 " ncsdoc:label="Missing in Error" ncsdoc:desc="" ncsdoc:global_value="99-4" ncsdoc:master_cl="missing_data"/>
            XSD
          }

          it 'removes the whitespace' do
            missing.value.should == '-4'
          end
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
        CodeListEntry.new('14').to_s.should == '14'
      end
    end

    describe '#diff' do
      let(:a) { CodeListEntry.new('A') }
      let(:aprime) { CodeListEntry.new('A') }

      let(:diff)        { a.diff(aprime) }
      let(:strict_diff) { a.diff(aprime, :strict => true) }

      it 'reports nothing for no differences' do
        diff.should be_nil
      end

      describe 'value' do
        let(:b) { CodeListEntry.new('B') }

        it 'reports a difference' do
          b.diff(a)[:value].should be_a_value_diff('B', 'A')
        end
      end

      describe 'label' do
        describe 'with a text difference' do
          before do
            a.label = 'Aleph'
            aprime.label = 'Alpha'
          end

          it 'when not strict, it reports the normalized difference' do
            diff[:label].should be_a_value_diff('aleph', 'alpha')
          end

          it 'when strict, it reports the literal difference' do
            strict_diff[:label].should be_a_value_diff('Aleph', 'Alpha')
          end
        end

        describe 'with a whitespace-only difference' do
          before do
            a.label = " a\t\tb   "
            aprime.label = 'a   b'
          end

          it 'reports a difference in strict mode' do
            strict_diff[:label].should be_a_value_diff(a.label, aprime.label)
          end

          it 'does not report a difference when not strict' do
            diff.should be_nil
          end
        end

        describe 'with a case-only difference' do
          before do
            a.label = 'AbcdEf'
            aprime.label = 'aBCDeF'
          end

          it 'reports a difference in strict mode' do
            strict_diff[:label].should be_a_value_diff(a.label, aprime.label)
          end

          it 'does not report a difference when not strict' do
            diff.should be_nil
          end
        end

        describe 'with a punctuation-only difference' do
          before do
            a.label = 'a,b,|c[at+]-'
            aprime.label = 'a!b*&c$#at'
          end

          it 'reports a difference in strict mode' do
            strict_diff[:label].should be_a_value_diff(a.label, aprime.label)
          end

          it 'does not report a difference when not strict' do
            diff.should be_nil
          end
        end
      end

      describe 'global_value' do
        before do
          a.global_value = '0'
          aprime.global_value = '-0'
        end

        it 'reports a difference in strict mode' do
          strict_diff[:global_value].should be_a_value_diff('0', '-0')
        end

        it 'does not report a difference otherwise' do
          diff.should be_nil
        end
      end

      describe 'master_cl' do
        before do
          a.master_cl = 'C'
          aprime.master_cl = 'Cprime'
        end

        it 'reports a difference in strict mode' do
          strict_diff[:master_cl].should be_a_value_diff('C', 'Cprime')
        end

        it 'does not report a difference otherwise' do
          diff.should be_nil
        end
      end
    end
  end
end

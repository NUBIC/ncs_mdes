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
    end

    describe '.reference' do
      subject { VariableType.reference('ncs:bar') }

      it 'should have the right name' do
        subject.name.should == 'ncs:bar'
      end

      it 'should be a reference' do
        subject.should be_reference
      end
    end
  end
end

require File.expand_path('../../../spec_helper', __FILE__)

require 'nokogiri'

module NcsNavigator::Mdes
  describe Variable do
    describe '.from_element' do
      def variable(s, options={})
        Variable.from_element(schema_element(s), { :log => logger }.merge(options))
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

          context 'with an override' do
            let(:options) {
              {
                :heuristic_overrides => {
                  'variable_type_references' => {
                    overridden_table_name => {
                      'not_a_pk' => override_type
                    }
                  }
                },
                :current_table_name => overridden_table_name
              }
            }

            let(:overridden_table_name) { 'link_whatever' }
            let(:type_in_xsd) { 'ncs:primaryKeyType' }
            let(:override_type) { 'ncs:foreignKeyTypeRequired' }

            let(:subject) {
              variable("<xs:element name='not_a_pk' type='#{type_in_xsd}'/>", options)
            }

            it 'uses an override which matches' do
              subject.type.name.should == 'ncs:foreignKeyTypeRequired'
            end

            it 'does not use an override which does not match by table name' do
              options[:current_table_name] = 'another_table'

              subject.type.name.should == type_in_xsd
            end

            it 'does not use an override which does not match by variable name' do
              options[:heuristic_overrides]['variable_type_references']['link_whatever'] = {
                'another_overridden_variable' => 'xs:integer'
              }

              subject.type.name.should == type_in_xsd
            end

            context 'when the override is an schema type' do
              let(:override_type) { 'xs:integer' }

              it 'treats extracts the XSD type' do
                subject.type.base_type.should == :integer
              end
            end

            context 'when the override is an internal reference' do
              it 'is a reference' do
                subject.type.should be_reference
              end
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

        it 'is false when not nillable but minOccurs is 0' do
          variable('<xs:element nillable="false" minOccurs="0"/>').should_not be_required
        end

        it 'is true when nillable omitted but minOccurs is > 0' do
          variable('<xs:element minOccurs="1"/>').should be_required
        end
      end

      describe '#omittable?' do
        it 'is true when minOccurs is 0' do
          variable('<xs:element minOccurs="0"/>').should be_omittable
        end

        it 'is false when minOccurs is not present' do
          comments.should_not be_omittable
        end

        it 'is false when minOccurs is > 0' do
          variable('<xs:element minOccurs="1"/>').should_not be_omittable
        end
      end

      describe '#nillable?' do
        it 'is true when nillable is true' do
          variable('<xs:element nillable="true"/>').should be_nillable
        end

        it 'is false when nillable is not present' do
          variable('<xs:element/>').should_not be_nillable
        end

        it 'is false when nillable is false' do
          variable('<xs:element nillable="false"/>').should_not be_nillable
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

    describe '#required?' do
      subject { Variable.new('foo') }

      it 'is true when not omittable or nillable' do
        subject.should be_required
      end

      it 'is false when omittable only' do
        subject.omittable = true
        subject.should_not be_required
      end

      it 'is false when nillable only' do
        subject.nillable = true
        subject.should_not be_required
      end

      it 'is false both nillable and omittable' do
        subject.nillable = true
        subject.omittable = true
        subject.should_not be_required
      end

      describe 'when explicitly set' do
        it 'preserves trueness even when would be false' do
          subject.nillable = true
          subject.required = true
          subject.should be_required
        end

        it 'preserves falseness even when should be true' do
          subject.required = false
          subject.should_not be_required
        end

        it 'can be cleared by setting to nil' do
          subject.nillable = true
          subject.required = true
          subject.should be_required

          subject.required = nil
          subject.should_not be_required
        end
      end
    end

    describe '#diff' do
      let(:a)      { Variable.new('A') }
      let(:aprime) { Variable.new('A') }

      let(:differences) { a.diff(aprime) }

      describe 'name' do
        it 'reports a difference when they are different' do
          a.diff(Variable.new('B'))[:name].should be_a_value_diff('A', 'B')
        end

        it 'reports nothing when they are the same' do
          differences.should be_nil
        end
      end

      describe 'pii' do
        it 'reports a difference when they are different' do
          a.pii = true
          aprime.pii = :possible

          differences[:pii].should be_a_value_diff(true, :possible)
        end

        it 'reports nothing when they are the same' do
          a.pii = :unknown
          aprime.pii = :unknown

          differences.should be_nil
        end
      end

      describe 'status' do
        let(:diff) { a.diff(aprime) }
        let(:strict_diff) { a.diff(aprime, :strict => true) }

        it 'reports nothing when they are the same' do
          a.status = :active
          aprime.status = :active

          differences.should be_nil
        end

        loose_same =[
          [     :new, :active],
          [     :new, :modified],
          [  :active, :modified],
          [:modified, :active]
        ]

        loose_or_strict_different = [
          [     :new, :retired],
          [  :active, :retired],
          [:modified, :retired],
          ['a thing', :retired],

          [     :new, 'some string'],
          [  :active, 'some string'],
          [:modified, 'some string'],
          [ :retired, 'some string'],

          [  :active, :new],
          [:modified, :new],
          [ :retired, :new],
          ['a thing', :new],

          [ :retired, :active],
          ['a thing', :active],

          [ :retired, :modified],
          ['a thing', :modified],
        ]

        describe 'for a non-strict diff' do
          loose_same.each do |left, right|
            it "reports nothing for #{left.inspect} -> #{right.inspect}" do
              a.status = left
              aprime.status = right

              diff.should be_nil
            end
          end

          loose_or_strict_different.each do |left, right|
            it "reports a difference for #{left.inspect} -> #{right.inspect}" do
              a.status = left
              aprime.status = right

              diff[:status].should be_a_value_diff(left, right)
            end
          end
        end

        describe 'for a strict diff' do
          (loose_same + loose_or_strict_different).each do |left, right|
            it "reports a difference for #{left.inspect} -> #{right.inspect}" do
              a.status = left
              aprime.status = right

              strict_diff[:status].should be_a_value_diff(left, right)
            end
          end
        end
      end

      describe 'type' do
        let(:type) { VariableType.new }
        let(:typeprime) { VariableType.new }

        before do
          a.type = type
          aprime.type = typeprime
        end

        describe 'when both have an anonymous type' do
          it 'reports the differences when they are different' do
            type.base_type = :int
            typeprime.base_type = :string

            differences[:type][:base_type].should be_a_value_diff(:int, :string)
          end

          it 'reports nothing for when they are the same' do
            type.max_length = typeprime.max_length = 15

            differences.should be_nil
          end
        end

        describe 'when both have a named type' do
          describe 'and the names differ' do
            let(:type) { VariableType.new('f_oo').tap { |vt| vt.min_length = 10 } }
            let(:typeprime) { VariableType.new('b_az') }

            it 'reports the name difference' do
              differences[:type][:name].should be_a_value_diff('f_oo', 'b_az')
            end

            it 'reports other differences' do
              differences[:type][:min_length].should be_a_value_diff(10, nil)
            end
          end

          # Motivation: a named type is resolved from the specification types
          # collection. What's important at the point of this variable is that
          # the type has changed; the details will be covered in the diff of
          # the types. No need to repeat them for every variable that used that
          # type
          describe 'and the names are the same' do
            let(:type) { VariableType.new('b_az').tap { |vt| vt.min_length = 10 } }
            let(:typeprime) { VariableType.new('b_az') }

            it 'does not report other differences' do
              differences.should be_nil
            end
          end
        end

        describe 'when the left is named and the right is not' do
          let(:type) { VariableType.new('b_ar').tap { |vt| vt.min_length = 5 } }
          let(:typeprime) { VariableType.new.tap { |vt| vt.min_length = 6 } }

          it 'reports the name difference' do
            differences[:type][:name].should be_a_value_diff('b_ar', nil)
          end

          it 'reports the other differences' do
            differences[:type][:min_length].should be_a_value_diff(5, 6)
          end
        end

        describe 'when the right is named and the left is not' do
          let(:type) { VariableType.new.tap { |vt| vt.min_length = 6 } }
          let(:typeprime) { VariableType.new('b_ar').tap { |vt| vt.min_length = 5 } }

          it 'reports the name difference' do
            differences[:type][:name].should be_a_value_diff(nil, 'b_ar')
          end

          it 'reports the other differences' do
            differences[:type][:min_length].should be_a_value_diff(6, 5)
          end
        end
      end

      describe 'omittable' do
        it 'reports nothing when they are the same' do
          a.omittable = false
          aprime.omittable = nil

          differences.should be_nil
        end

        it 'reports a difference when they are different' do
          a.omittable = false
          aprime.omittable = true

          differences[:omittable?].should be_a_value_diff(false, true)
        end
      end

      describe 'nillable' do
        it 'reports nothing when they are the same' do
          a.nillable = nil
          aprime.nillable = false

          differences.should be_nil
        end

        it 'reports a difference when they are different' do
          a.nillable = true
          aprime.nillable = false

          differences[:nillable?].should be_a_value_diff(true, false)
        end
      end

      describe 'table_reference' do
        it 'reports nothing when they are the same' do
          a.table_reference = TransmissionTable.new('Tb')
          aprime.table_reference = TransmissionTable.new('Tb')

          differences.should be_nil
        end

        it 'reports nothing when they are both nil' do
          differences.should be_nil
        end

        it 'reports a change when one has a ref and the other does not' do
          aprime.table_reference = TransmissionTable.new('Tc')

          differences[:table_reference].should be_a_value_diff(nil, 'Tc')
        end

        it 'reports a change when the referenced table is different' do
          a.table_reference = TransmissionTable.new('Ty')
          aprime.table_reference = TransmissionTable.new('Tx')

          differences[:table_reference].should be_a_value_diff('Ty', 'Tx')
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

    describe '#resolve_foreign_key!' do
      let(:variable) {
        Variable.new('helicopter_id').tap { |v| v.type = variable_type }
      }

      let(:table) {
        TransmissionTable.new('flights').tap do |t|
          t.variables = [ variable ]
        end
      }

      let(:table_with_matching_pk) {
        TransmissionTable.new('helicopters').tap do |t|
          t.variables = [
            Variable.new('helicopter_id').tap do |v|
              v.type = VariableType.new('primaryKeyType')
            end
          ]
        end
      }

      let(:table_with_nonmatching_pk) {
        TransmissionTable.new('frogs').tap do |t|
          t.variables = [
            Variable.new('frog_id').tap do |v|
              v.type = VariableType.new('primaryKeyType')
            end
          ]
        end
      }

      let(:table_with_same_fk) {
        TransmissionTable.new('autorotation_events').tap do |t|
          t.variables = [
            Variable.new('helicopter_id').tap do |v|
              v.type = VariableType.new('foreignKeyTypeRequired')
            end
          ]
        end
      }

      let(:all_tables) {
        [table, table_with_matching_pk, table_with_nonmatching_pk, table_with_same_fk]
      }

      # These are overridden in nested contexts as necessary
      let(:override) { nil }
      let(:tables) { all_tables }

      before do
        variable.resolve_foreign_key!(tables, override,
          :log => logger, :in_table => TransmissionTable.new('kite'))
      end

      shared_examples 'a foreign key' do
        context 'when there is no table matching' do
          context 'and there is no override' do
            let(:tables) {
              [table, table_with_same_fk, table_with_nonmatching_pk]
            }

            it 'does not set a table reference' do
              variable.table_reference.should be_nil
            end

            it 'warns' do
              logger[:warn].first.
                should == 'Foreign key in kite not resolvable: no tables have a primary key named "helicopter_id".'
            end
          end

          include_examples 'for overrides'
        end

        context 'when there is exactly one matching table' do
          let(:tables) { all_tables }

          context 'and there is no override' do
            it 'sets the table_reference to that matching table' do
              variable.table_reference.should be table_with_matching_pk
            end

            it 'does not warn' do
              logger[:warn].should be_empty
            end
          end

          include_examples 'for overrides'
        end

        context 'when there is more than one matching table' do
          let(:other_matches) {
            [
              TransmissionTable.new('helicopters_2').tap { |t|
                t.variables = table_with_matching_pk.variables.dup
              },
              TransmissionTable.new('choppers').tap { |t|
                t.variables = table_with_matching_pk.variables.dup
              }
            ]
          }

          let(:tables) { all_tables + other_matches }

          context 'and there is no override' do
            it 'does not set a table reference' do
              variable.table_reference.should be_nil
            end

            it 'warns' do
              logger[:warn].first.
                should == '3 possible parent tables found for foreign key "helicopter_id" in kite: "helicopters", "helicopters_2", "choppers". None used due to ambiguity.'
            end
          end

          include_examples 'for overrides'
        end
      end

      shared_examples 'for overrides' do
        context 'and there is an override' do
          context 'and the override is to a known table' do
            let(:override) { table_with_same_fk.name }

            it 'sets the table reference to the override' do
              variable.table_reference.should be table_with_same_fk
            end

            it 'does not warn' do
              logger[:warn].should == []
            end
          end

          context 'and the override is to an unknown table' do
            let(:override) { 'aircraft' }

            it 'does not set a table reference' do
              variable.table_reference.should be_nil
            end

            it 'warns' do
              logger[:warn].first.
                should == 'Foreign key "helicopter_id" in kite explicitly mapped to unknown table "aircraft".'
            end
          end

          context 'and the override is false' do
            let(:override) { false }

            it 'does not set a table reference' do
              variable.table_reference.should be_nil
            end

            it 'does not warn' do
              logger[:warn].should == []
            end
          end
        end
      end

      context 'when a nullable FK' do
        let(:variable_type) { VariableType.new('foreignKeyTypeNullable') }

        it_behaves_like 'a foreign key'
      end

      context 'when a required FK' do
        let(:variable_type) { VariableType.new('foreignKeyTypeRequired') }

        it_behaves_like 'a foreign key'
      end

      context 'when not an FK' do
        let(:variable_type) { VariableType.new('confirm_cl7') }

        it 'does nothing' do
          variable.table_reference.should be_nil
        end

        it 'does not warn' do
          logger[:warn].should be_empty
        end

        include_examples 'for overrides'
      end
    end
  end
end

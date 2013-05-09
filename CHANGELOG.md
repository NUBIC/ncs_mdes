NCS Navigator MDES Module history
=================================

0.13.1
------

0.13.0
------

- Introduce MDES 3.3 support using specification version 3.3.00.00. (#29)

- Restore JRuby compatibility. (#5)

- Allow variable types to be overridden using heuristic_overrides during
  VDR schema parsing. (Done with #29)

- Add `TransmissionTable#primary_key_variables`. (Done with #29)

0.12.0
------

- Add `#diff` methods to all levels in the specification tree. They produce
  a computable difference between two instances. (#10)
- Add `TransmissionTable#child_instrument_table?` and
  `TransmissionTable#parent_instrument_table?`. The values they return are
  manually extracted from several sources and stored in files in each version's
  documents directory. (#28)
- Drop support for Ruby 1.8.7.
- Rename `NcsNavigator::Mdes::VariableType::CodeList` to
  `NcsNavigator::Mdes::CodeList` and
  `NcsNavigator::Mdes::VariableType::CodeListEntry` to
  `NcsNavigator::Mdes::CodeListEntry`. In the unlikely event that you had code
  referring directly to either of these classes, you'll need to adjust it.

0.11.0
------

- Introduce MDES 3.2 support using specification version 3.2.00.00. (#24)
- Update MDES 3.1 to specification version 3.1.01.00. (#23)
- Expose DispositionCode attribute list.
- Adapt to backwards-incompatible change in Nokogiri-C 1.5.6. (#26)

0.10.0
------

- Introduce MDES 3.1 support using specification version
  3.1.00.00. (#22)

0.9.0
-----

- Strip external whitespace from code list values. (#20)
- Update MDES 3.0 to 3.0.00.09. (#19)
- Update MDES 2.2 to 2.2.01.01. (#21)

0.8.1
------

- Ensure that options are passed through all constructor methods to the leaves.
  (#17)
- Accept options on the `NcsNavigator::Mdes(version)` shortcut method. (#18)

0.8.0
-----

- Synthesize category codes for MDES 2.0 disposition codes.  (#12)
- Add DispositionCode#category_code for reading category codes.  (#12)
- Add DispositionCode#success? to partition activities into
  successfully and unsuccesfully completed (e.g. canceled) sets.
  (#16)

0.7.0
-----

- Introduce MDES 3.0 support using specification version
  3.0.00.00. (#14)

0.6.1
-----

- Correct foreign key override for `preg_visit_1_heat2_2.pv1_id` in
  MDES 2.1 and 2.2. (#13)

- Add an MDES 2.2 spec to `mdes-console`. (#9)

0.6.0
-----

- Add built-in support for MDES 2.1 (#8).
- Add built-in support for MDES 2.2 (#9).

0.5.0
-----

- Add `instrument_table?` and `operational_table?` to heuristically
  flag tables as one or the other.
- Fix reference definition for `spec_blood.equip_id`. According to the
  corresponding instrument, it is not a reference to `spec_equipment`,
  but rather a manually-filled field (#7).

0.4.2
-----

- Add `specification_version` to distinguish from the short version
  names we use for easy reference. (#6)

0.4.1
-----

- Add separate `omittable?` and `nillable?` subconditions of
  `required?` (#4).

0.4.0
-----

- Consider element `minOccurs` when determining variable
  requiredness (#2).
- Added disposition codes to the specification. Requires a YAML file
  with all the disposition code values for the MDES version (#3).

0.3.1
-----

- Correct pattern compilation. XML Schema patterns implicitly must
  match the entire value, so it's necessary to surround the value with
  `^` and `$` when converting to a ruby regular expression.

0.3.0
-----

- Add foreign key / table reference support, including explicit
  mappings for all ambiguous or unguessable FKs (#1).
- Add Specification#[] for quicker access to a particular table or
  tables.

0.2.0
-----

- Rename gem to ncs_mdes (from ncs-mdes).
- Embed the VDR transmission XSD since we now have permission to
  distribute the MDES structure.
- Update version 2.0 to be based on 2.0.01.02.

0.1.0
-----

- Add mdes-console executable.

0.0.1
-----

- First version. Reads data from VDR transmission schema for MDES 1.2
  and 2.0.

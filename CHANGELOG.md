NCS Navigator MDES Module history
=================================

0.4.1
-----

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

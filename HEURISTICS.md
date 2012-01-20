# Why `ncs_mdes` tells you the things it tells you

`ncs_mdes` derives its view of the NCS Master Data Element
Specification primarily from the the XML Schema defining the Vanguard
Data Repository submission format. However, that file does not contain
the full semantics that the gem exposes. This document discusses how
the remaining attributes are derived.

# Gem overview

`ncs_mdes` exposes data in three major categories:

* Tables
* Types
* Disposition codes

Types are fairly simple, and are mostly interesting insofar as they
are the mechanism whereby you can look up a code list. Disposition
codes are extracted from the Master Data Element Specification
spreadsheet instead of the VDR schema &mdash; unlike the tables and
types, they are pre-processed rather than coming from the source
document at runtime &mdash; but are otherwise simple. This document
is mainly concerned with tables and their children, variables.

# Tables

The table name attribute is taken directly from the VDR schema.

## Instrument or operational?

`ncs_mdes` can also tell you if a table is an operational or
instrument table (this is an XOR relationship) and, if it is an
instrument table, whether it is a "primary" instrument table.

Definitions:

* An operational table is a table that collects study execution
  information.

* An instrument table is a table that contains data collected about a
  study participant.

* A "primary" instrument table is a table for which there is exactly
  one record for each time the instrument is collected for a
  participant. (The MDES is a relational model; non-primary tables
  contain the results of repeating instrument sections or multivalued
  questions and are always associated with a primary table, though
  sometimes the association is indirect.)

These distinctions are derived using the following heuristic:

* If the table contains a variable named `instrument_version` and is
  not the table named `instrument`, it is a primary instrument table
  (and therefore an instrument table). (The table `instrument` is
  itself an operational table since it records the execution of an
  instrument rather than any of the data collected in the instrument.)

* If the table contains a foreign key to a table which is an
  instrument table, then it is an instrument table.

* Otherwise, the table is an operational table.

This heuristic works in all cases for MDES 2.0.

# Variables

The following attributes of a variable are taken directly from the XML
schema:

* name
* pii?
* required?
* omittable?
* nillable?
* status (active, etc.)
* type

## Table references

`ncs_mdes` can also tell you if a variable is a foreign key reference
and if so, to which table it refers. While the XML schema indicates
that a variable is of one of a couple of foreign key types, it does
not indicate the associated table. That information is derived using
the following heuristic:

* If the variable is not of foriegn key type, it's not a foreign key.

* Otherwise, find all the tables in the MDES whose primary key is
  named the same as the foreign key variable.

* If there is exactly one such table, the variable refers to that
  table.

* Otherwise fail.

This heuristic works for 399 of the foreign keys in MDES 2.0. Another
155 are mapped manually for a total of 554.

There are also three variables which are typed as foreign keys in the
XML schema but which for a couple of different reasons are not treated
as foreign keys by ncs_mdes. These are described in comments in
`source_documents/2.0/heuristics_overrides.yml` in the ncs_mdes
source.

# Heuristics not used

## Type coercion

The MDES VDR schema considers nearly all variables to strings; usually
strings of a set length or conforming to a particular
pattern. `ncs_mdes` does not attempt to infer a stronger type for
these.

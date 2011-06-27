NCS Navigator MDES Module
=========================

This gem provides a consistent computable interface to the National
Children's Study Master Data Element Specification. All of the data it
exposes is derived at runtime from the documents provided by the
National Children's Study Program Office, which must be available on
the system where it is running.

Prepare
-------

The documents from the Program Office need to go in a particular
directory structure under a certain base directory.

The base directory defaults to `/etc/nubic/ncs/mdes`. You can override
this default by setting the environment variable
`NCS_MDES_DOCS_DIR`.

The directory structure under the base is
`$MDES_VERSION/$ARTIFACT_FILENAME`. Currently versions `1.2` and `2.0`
are supported. The filename will exactly match the name of the
artifact you download from the NCS Portal. Below are the specific
paths that this gem will read:

<table border>
  <tr><th>File type</th><th>MDES version</th><th>Artifact filename</th></tr>
  <tr>
    <td>VDR Transmission Schema</td>
    <td>1.2</td>
    <td>Data_Transmission_Schema_V1.2.xsd</td>
  </tr>
  <tr>
    <td>VDR Transmission Schema</td>
    <td>2.0</td>
    <td>NCS_Transmission_Schema_V2.0.00.00.xsd</td>
  </tr>
</table>

You only need to supply the files for the version(s) of the MDES you
want to use.

Use
---

    require 'ncs_navigator/mdes'
    require 'pp'

    mdes = NcsNavigator::Mdes('1.2')
    pp mdes.transmission_tables.collect(&:name)

For more details see the API documentation, starting with {NcsNavigator::Mdes::Specification}.

Develop
-------

### Running the specs

The specs depend on both 1.2 and 2.0 documents. They look for them
under `spec/doc-base`.

### Writing API docs

Run `bundle exec yard server --reload` to get a dynamically-refreshing
view of the API docs on localhost:8808.

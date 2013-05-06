NCS Navigator MDES Module
=========================

This gem provides a consistent computable interface to the National
Children's Study Master Data Element Specification. Most of the data
it exposes is derived at runtime from the documents provided by the
National Children's Study Program Office, which are embedded in the
distribution package. The balance of the data is also derived from NCS
PO documentation, but is preprocessed to reduce the footprint of this
library.

Use
---

    require 'ncs_navigator/mdes'
    require 'pp'

    mdes = NcsNavigator::Mdes('3.0')
    pp mdes.transmission_tables.collect(&:name)

For more details see the API documentation, starting with
{NcsNavigator::Mdes::Specification}. (If you're not looking at this
document in the API documentation, try looking at [rubydoc.info][].)

[rubydoc.info]: http://rubydoc.info/github/NUBIC/ncs_mdes/master/frames

As of ncs_mdes 0.12.1, Ruby 1.9.3+ and JRuby 1.7+ are supported. (Ruby 1.8.x is
not supported as of 0.12.0. Use 0.11.0 or earlier for Ruby 1.8.7.)

### Examine

This gem includes a console for interactively analyzing and randomly
poking at the MDES. It is called `mdes-console`:

    $ mdes-console
    Documents are expected to be in the default location.
    $mdesNM is a Specification for N.M.
    Available specifications are $mdes12, $mdes20, $mdes21, $mdes22, and $mdes30.
    :001 >

It is based on ruby's IRB. Use it to examine the loaded MDES data
without a lot of edit-save-run cycles:

    :001 > $mdes20.transmission_tables.first.name
     => "study_center"

E.g., find all the variables of a particular XML schema type:

    :002 > $mdes20.transmission_tables.collect { |t| t.variables }.flatten.select { |v| v.type.base_type == :decimal }.collect(&:name)
      => ["correction_factor_temp", "current_temp", "maximum_temp", "minimum_temp", "precision_term_temp", "trh_temp", "salts_moist", "s_33rh_reading", "s_75rh_reading", "s_33rh_reading_calib", "s_75rh_reading_calib", "precision_term_temp", "rf_temp", "correction_factor_temp", "sample_receipt_temp"]

Or the labels for a particular code list:

    :003 > $mdes20.types.find { |t| t.name == 'confirm_type_cl7' }.code_list.collect(&:label)
     => ["Yes", "No", "Refused", "Don't Know", "Legitimate Skip", "Missing in Error"]

Or the number of code lists that include "Yes" as an option:

    :004 > $mdes20.types.select { |t| t.code_list && t.code_list.collect(&:label).include?('Yes') }.size
     => 23

Or which variables in a table are different between two versions:

    :005 > pp $mdes20['staff'].diff($mdes32['staff'])[:variables]; nil
    #<NcsNavigator::Mdes::Differences::Collection:0x007fdd8bb4dff0
     @entry_differences={},
     @left_only=[],
     @right_only=["ncs_active_date", "ncs_inactive_date"]>

Develop
-------

### Writing API docs

Run `bundle exec yard server --reload` to get a dynamically-refreshing
view of the API docs on localhost:8808.

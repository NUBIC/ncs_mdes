NCS Navigator MDES Module
=========================

This gem provides a consistent computable interface to the National
Children's Study Master Data Element Specification. All of the data it
exposes is derived at runtime from the documents provided by the
National Children's Study Program Office, which must be available on
the system where it is running.

Use
---

    require 'ncs_navigator/mdes'
    require 'pp'

    mdes = NcsNavigator::Mdes('1.2')
    pp mdes.transmission_tables.collect(&:name)

For more details see the API documentation, starting with {NcsNavigator::Mdes}.

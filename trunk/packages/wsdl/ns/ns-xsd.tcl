# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

# Types for XML-Schema namespace="http://www.w3.org/2001/XMLSchema"

# Create xsd namespace
#namespace eval ::wsdb::types::xsd { }
#namespace eval ::wsdb::schema::xsd { }
#::wsdb::schema::appendAliasMap [list xsd "http://www.w3.org/2001/XMLSchema"]
::wsdl::schema::new xsd "http://www.w3.org/2001/XMLSchema"

# anySimpleType
::wsdl::types::primitiveType::new xsd anySimpleType {return 1} {Base type, should return true for every case}
::wsdl::doc::document doc types xsd anySimpleType {Base type, should return true for every case}

# string
::wsdl::types::primitiveType::new xsd string {return 1} {String type. Anything should pass as true}
::wsdl::doc::document doc types xsd string {String type. Anything should pass as true}

# dateTime
::wsdl::types::primitiveType::new xsd dateTime "return \[::wsdb::types::tcl::dateTime::toArray \$value returnArray\]" "xml schema dateTime type"

# duration
::wsdl::types::primitiveType::new xsd duration "return \[::wsdb::types::tcl::dateTime::durationToArray \$value returnArray\]" "xml schema duration type"

proc ::wsdb::types::xsd::duration::validate { duration } {

    return [::wsdb::types::tcl::dateTime::durationToArray $duration returnArray]
}


# boolean
::wsdl::types::simpleType::restrictByEnumeration xsd boolean xsd::string {0 1 true false}

# numeric types
::wsdl::types::primitiveType::new xsd decimal "return \[string is double -strict \$value]" {faked up decimal type}
::wsdl::types::primitiveType::new xsd float "return \[string is double -strict \$value]" {faked up float type}
::wsdl::types::primitiveType::new xsd integer "return \[string is integer -strict \$value]" {integer type}
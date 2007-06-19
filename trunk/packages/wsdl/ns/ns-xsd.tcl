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


proc ::wsdb::types::xsd::dateTime::validate { datetime } {
    return [::wsdb::types::tcl::dateTime::toArray $datetime returnArray]
}

# boolean
::wsdl::types::simpleType::restrictByEnumeration xsd boolean xsd::string {0 1 true false}

# numeric types
#::wsdl::types::primitiveType::new xsd decimal "return \[string is double -strict \$value]" {faked up decimal type}
::wsdl::types::primitiveType::new xsd double "return \[string is double -strict \$value]" {faked up double type}
::wsdl::types::primitiveType::new xsd float "return \[string is double -strict \$value]" {faked up float type}
#::wsdl::types::primitiveType::new xsd integer "return \[string is integer -strict \$value]" {integer type}

# Real Decimal Type using restrict by pattern:
namespace eval ::wsdb::types::xsd::decimal {
    variable validate [namespace code validate]
    variable base xsd::string

    variable pattern {\A([\-+]?)([0-9]*)(?:([\.]?)|([\.])([0-9]+))\Z}
}

proc ::wsdb::types::xsd::decimal::validateWithInfoArray {
    value
    {digitsArrayName dArray}
} {
    variable pattern
    
    upvar $digitsArrayName DA

    return [regexp $pattern $value DA(all) DA(minus) DA(whole) DA(pointInt) DA(pointReal) DA(fraction)]

}

# Main procedure hides upvar'd array containing digit Array
proc ::wsdb::types::xsd::decimal::validate {
    value
} {
    return [validateWithInfoArray $value]
}


::wsdl::types::simpleType::restrictDecimal xsd integer tcl::integer {fractionDigits 0}
::wsdl::types::simpleType::restrictDecimal xsd int tcl::integer {fractionDigits 0} 
::wsdl::types::simpleType::restrictDecimal xsd nonPositiveInteger xsd::integer {maxInclusive 0}
::wsdl::types::simpleType::restrictDecimal xsd negativeInteger  xsd::integer {maxInclusive -1}
::wsdl::types::simpleType::restrictDecimal xsd short xsd::integer {minInclusive -32767 maxInclusive 32767}
::wsdl::types::simpleType::restrictDecimal xsd byte xsd::integer {minInclusive -127 maxInclusive 127}


namespace eval ::wsdb::types::xsd {

    
    variable minusOptional {(-)?}
    variable minusOptionalAnchored {\A(-)?\Z}
    
    variable year {(-)?([0-9]{4}|[1-9]{1}[0-9]{4,})}
    variable yearAnchored {\A(-)?([0-9]{4}|[1-9]{1}[0-9]{4,})\Z}
    
    variable timezone {(Z|(([\+\-]{1}))?((?:(14)(?::)(00))|(?:([0][0-9]|[1][0-3])(?::)([0-5][0-9]))))}
    variable timezoneOptional ${timezone}?
    variable timezoneAnchored "\\A$timezoneOptional\\Z"
    
    variable gYear ${year}${timezoneOptional}
    variable gYearAnchored "\\A${gYear}\\Z"
    
    variable day {([0][0-9]|[12][0-9]|[3][01])}
    
    variable gDay ${day}${timezoneOptional}
    variable gDayAnchored "\\A${gDay}\\Z"
    
    variable month {(?:([0][1-9]|[1][0-2]))}
    
    variable gMonth ${month}${timezoneOptional}
    variable gMonthAnchored "\\A${gMonth}\\Z"
    
    variable gYearMonth ${year}(?:-)${month}
    variable gYearMonthAnchored "\\A${gYearMonth}\\Z"
    
    variable gMonthDay ${month}(?:-)${day}
    variable gMonthDayAnchored "\\A${gMonthDay}\\Z"
    

    ::wsdl::types::simpleType::restrictByPattern \
	xsd minusOptional xsd::string $minusOptionalAnchored;
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd year xsd::integer $yearAnchored
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd timeZone xsd::string $timezoneAnchored
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd gYear xsd::string $gYearAnchored
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd gMonth  xsd::string $gMonthAnchored
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd gDay  xsd::string $gDayAnchored
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd gYearMonth  xsd::string $gYearMonthAnchored
    
    ::wsdl::types::simpleType::restrictByPattern \
	xsd gMonthDay  xsd::string $gMonthDayAnchored

}
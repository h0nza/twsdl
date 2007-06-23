# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

# Types for XML-Schema namespace="http://www.w3.org/2001/XMLSchema"

# Create xsd schema
::wsdl::schema::new xsd "http://www.w3.org/2001/XMLSchema"

# anySimpleType
::wsdl::types::primitiveType::new xsd anySimpleType {return 1} {Base type, should return true for every case}
::wsdl::doc::document doc types xsd anySimpleType {Base type, should return true for every case}

# string
::wsdl::types::primitiveType::new xsd string {return 1} {String type. Anything should pass as true}
::wsdl::doc::document doc types xsd string {String type. Anything should pass as true}

# dateTime
::wsdl::types::primitiveType::new xsd dateTime "return \[::wsdb::types::tcl::dateTime::toArray \$value\]" "xml schema dateTime type"

# duration
::wsdl::types::primitiveType::new xsd duration "return \[::wsdb::types::tcl::dateTime::durationToArray \$value\]" "xml schema duration type"

proc ::wsdb::types::xsd::duration::validate { duration } {

    return [::wsdb::types::tcl::dateTime::durationToArray $duration]
}


proc ::wsdb::types::xsd::dateTime::validate { datetime } {
    return [::wsdb::types::tcl::dateTime::toArray $datetime]
}

# boolean
::wsdl::types::simpleType::restrictByEnumeration xsd boolean xsd::string {0 1 true false}

# numeric types
::wsdl::types::primitiveType::new xsd double "return \[string is double -strict \$value]" {faked up double type}
::wsdl::types::primitiveType::new xsd float "return \[string is double -strict \$value]" {faked up float type}


# Decimal Type is base for many numeric types, so relatively complicated setup
namespace eval ::wsdb::types::xsd::decimal {
    variable base xsd::string
    variable decimalPointCanon .
    variable pattern {\A(?:([\-+]?)([0-9]*)(?:([\.]?)|([\.])([0-9]+))){1}\Z}
    variable validate {::namespace inscope ::wsdb::types::xsd::decimal validate}

}

# Helper Proc
proc ::wsdb::types::xsd::decimal::validateWithInfoArray {
    value
    {digitsArrayName dArray}
} {
    # Protect caller in case input value contains no digits
    if {[regexp {[0-9]+} $value]} {
	variable pattern
	upvar $digitsArrayName DA
	return [regexp $pattern $value DA(all) DA(minus) DA(whole) DA(pointInt) DA(pointReal) DA(fraction)]
    } else {
	return 0
    }
}

# Another Helper Proc
proc ::wsdb::types::xsd::decimal::ifDecimalCanonize {
    value
    {canonListVar canonList}
    {decimalPointCanon .}
    {digitsListVar ""}
} {
    
    # From <http://www.w3.org/TR/xmlschema-2/#rf-totalDigits>:
    # [Definition:]   totalDigits controls the maximum number of values
    # in the ??value space?? of datatypes ??derived?? from decimal, by
    # restricting it to numbers that are expressible as
    # i ?? 10^-n where i and n are integers such that
    # |i| < 10^totalDigits and 0 <= n <= totalDigits.
    # The value of totalDigits ??must?? be a positiveInteger.

    # Example:
    # value must be expressible as i * 10^-n
    # 0 <= n <= 3 =means=> |i| < 1000 (use max of 102):
    # v =  102, n = 0;  102 = 102 * 10^-0
    # v = 10.2, n = 1; 10.2 = 102 * 10^-1 (or 10.2 * 10^-0)
    # v = 1.02, n = 2; 1.02 = 102 * 10^-2
    # v = .102, n = 3; .102 = 102 * 10^-3

    # Identical treatment is given to fractionDigits

    # Result: don't count ANY leading or trailing zeros
    #  in either totalDigits or fractionDigits.

    set collapsedValue [string trim $value]
    # Looks dangerous to use wsdb::types::xsd::decimal, maybe move this proc?
    
    if {![::wsdb::types::xsd::decimal::validateWithInfoArray $collapsedValue dArray]} {
        return 0
    } else {
	upvar $canonListVar canonList
	if {"$digitsListVar" ne ""} {
	    upvar $digitsListVar digitsList
	}
    }
    set plusMinusCanon [string trim $dArray(minus) +]
    set wholeDigitsCanon [string trimleft $dArray(whole) -+0]
    set wholeDigits [string length $wholeDigitsCanon]

    if {$wholeDigits == 0} {
        set wholeDigitsCanon 0
    }
    set foundFractionDigitsCanon [string trimright $dArray(fraction) 0]
    set foundFractionDigits [string length $foundFractionDigitsCanon]
    if {$foundFractionDigits == 0 && "$decimalPointCanon" eq "."} {
        set foundFractionDigitsCanon 0
    }
    set foundDigits [expr $wholeDigits + $foundFractionDigits]

    set canonList  [list $plusMinusCanon $wholeDigitsCanon $decimalPointCanon $foundFractionDigitsCanon]
    set digitsList [list $foundDigits $foundFractionDigits]
    return 1
}


if {0} {
# The following Proc was modified from the auto generated procedure just
# below this proc (commented out). The addition catches 
# input values of empty string or decimal point, and a few other inputs
# which do not have any digits in the input value. Since it isn't likely,
# this check is done last.
# The reason for all the round-about methods is so that you can always 
# produce a canonical value for an input using the following validation
# method, or that of any derived type.
proc ::wsdb::types::xsd::decimal::validate {
    value
    {errorListVar ""}
    {canonListVar ""}
} {
    variable base
    variable decimalPointCanon
    variable pattern

    if {"$errorListVar" ne ""} {
        upvar $errorListVar errorList
    }
    if {"$canonListVar" ne ""} {
        upvar $canonListVar canonList
    }

    set valid 0
    set collapsedValue [string trim $value]
    set errorList [list $collapsedValue]
    set canonList [list]

    if {![::wsdb::types::xsd::decimal::ifDecimalCanonize $value canonList $decimalPointCanon]} {
        lappend errorList "failed decimal test"
        return $valid
    }

    set canonValue [join $canonList ""]

    while {1} {
        if {![::wsdb::types::${base}::validate $canonValue]} {
            lappend errorList "failed base test $base" 
            break
        }
	# Removed pattern check, since it is done in ifDecimalCanonize
	if {![regexp {[0-9]+} $value]} {
	    lappend errorList "failed: no digits found in value (\$value)"
	    break
	}
        set valid 1
        break
    }

    return $valid
}

}


# Decimal Type
::wsdl::types::simpleType::restrictDecimal xsd decimal xsd::string {pattern {\A(?:([\-+]?)([0-9]*)(?:([\.]?)|([\.])([0-9]+))){1}\Z}}

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
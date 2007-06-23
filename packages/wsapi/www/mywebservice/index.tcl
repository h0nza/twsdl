namespace eval ::someothernamespace {
    proc hello { who } {
	return "Hello $who"
    }

    proc helloWorld { } {
	return "Hello World!"
    }
}

# Example  of use:

<ws>namespace init ::mywebservice

<ws>proc ::mywebservice::testit {
    {a:xsd::string}
    {b {default "ooo" minOccurs 0}}
    {c:string {default "xxx" minOccurs 0}}
} {
    return [list $a $b $c]

} returns {A:string B:string C:string}

# Derive a simpleType via enumeration:
<ws>type enumeration mywebservice::symbol {MSFT WMT XOM GM F GE }

<ws>proc ::mywebservice::EchoSymbol {
    {Symbol:mywebservice::symbol}
} {
    return $Symbol
} returns {Symbol:mywebservice::symbol}

# Derive a simpleType via pattern (regular expression):
<ws>type pattern mywebservice::code {[0-9]{4}} xsd::integer

<ws>proc ::mywebservice::EchoCode {
    {Code:mywebservice::code} 
} {

    return $Code

} returns {Code:mywebservice::code}

# Standard Echo Server:
<ws>proc ::mywebservice::Echo { 
    Input 
} {
    return "$Input"

} returns { Output }

<ws>proc ::mywebservice::AddNumbers {
    {FirstNum:integer {default "0" minOccurs 0}}
    {SecondNum:integer {default "0" minOccurs 0}}
} {
    return [expr $FirstNum + $SecondNum]
} returns {Sum:xsd::integer}

<ws>proc ::mywebservice::MultiplyNumbers {
    {FirstDecimal:decimal {default "0.0" minOccurs 0}}
    {SecondDecimal:decimal {default "0.0" minOccurs 0}}
} {
    return [expr $FirstDecimal * $SecondDecimal]
} returns {Product:decimal}

# Use <ws>namespace import to copy an _existing_ proc
# from another namespace. 
# The copied proc must take and return values, no refs.
# This command allows developer to maintain code in one place
# and expose it as a web service here.
# The developer can add a return type as in <ws>proc.
# Probably should allow optional typing, but not naming of input args,
# although it might be possible to replace arg names, but dangerous.


<ws>namespace import ::mywebservice ::someothernamespace::hello returns {Yeah}
<ws>namespace import ::mywebservice ::someothernamespace::helloWorld returns { Say }
# Code above could be moved to library 

# Try out restriction of decimal values
<ws>type decimalRestriction mywebservice::Byte {minInclusive -127 maxInclusive 127} xsd::integer
<ws>type decimalRestriction mywebservice::TestDecimal {minExclusive -321.01 maxInclusive 456.78 totalDigits 5 fractionDigits 2}

<ws>type decimalRestriction mywebservice::TestDecimal2 {pattern {[0-9]{1,4}} minInclusive 4 maxInclusive 9765} xsd::integer
<ws>type decimalRestriction mywebservice::TestDecimal3 {totalDigits 4 fractionDigits 0}
<ws>type decimalRestriction mywebservice::TestDecimal4 {totalDigits 4} mywebservice::TestDecimal

<ws>type decimalRestriction mywebservice::TestInteger {fractionDigits 0 totalDigits 7} xsd::integer

<ws>element sequence mywebservice::TestDecimalValueResponse {
    {StringToTest}
    {IsTestDecimal:boolean}
    {CanonicalValue:mywebservice::TestDecimal {minOccurs 0}}
    {ErrorString}
}

<ws>proc ::mywebservice::EchoByte {
    ByteAsIntegerIn:mywebservice::Byte
} {

    return [list $ByteAsIntegerIn]

} returns {ByteAsIntegerOut:mywebservice::Byte} 


# Example of using decimal validation proc to create canonical form
# and show error messages during validation failure.
<ws>proc ::mywebservice::TestDecimalValue {
    StringToTest
} {

    set IsTestDecimal [::wsdb::types::mywebservice::TestDecimal4::validate $StringToTest errorList canonList]

    if {$IsTestDecimal} {
	set CanonicalValue [join $canonList ""]
	set ErrorString "No Error"
    } else {
	set CanonicalValue ""
	set ErrorString [join $errorList]
    }

    return [list $StringToTest $IsTestDecimal $CanonicalValue $ErrorString]

} returns {TestDecimalValueResponse}



<ws>type stringRestriction mywebservice::myString {length 10}
<ws>type stringRestriction mywebservice::myString2 {minLength 4 maxLength 25}
<ws>type stringRestriction mywebservice::myString3 {pattern {\A[0-7]+\Z} maxLength 8}

<ws>proc ::mywebservice::testString {
    MyString
    MyOtherString
    MyThirdString
} {

    set IsMyString [::wsdb::types::mywebservice::myString::validate $MyString errorList]

    if {$IsMyString} {
	set ErrorForMyString "No Error in MyString"
    } else {
	set ErrorForMyString [join $errorList]
    }

    set IsMyString2 [::wsdb::types::mywebservice::myString2::validate $MyOtherString errorList2]

    if {$IsMyString2} {
	set ErrorForMyString2 "No Error in MyString"
    } else {
	set ErrorForMyString2 [join $errorList2]
    }

    set IsMyString3 [::wsdb::types::mywebservice::myString3::validate $MyThirdString errorList3]

    if {$IsMyString3} {
	set ErrorForMyString3 "No Error in MyString"
    } else {
	set ErrorForMyString3 [join $errorList3]
    }

    return [list $MyString $ErrorForMyString $MyOtherString $ErrorForMyString2 $MyThirdString $ErrorForMyString3]

} returns {
    MyString
    ErrorForMyString
    MyString2
    ErrorForMyString2
    MyString3
    ErrorForMyString3
}
    

# Code below is required to be on this page:
# service address will be url of this page.

# Run final code to setup service:
<ws>namespace finalize ::mywebservice

# Freeze code to prevent changes and speed execution:
<ws>namespace freeze ::mywebservice

# Test procs with one return value
<ws>log Debug "...."

# Returns the correct response:
<ws>return ::mywebservice




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
    {b "ooo"}
    {c:string "xxx"}
} {
    return [list $a $b $c]

} returns {A:string B:string C:string}

# Derive a simpleType via enumeration:
::wsdl::types::simpleType::restrictByEnumeration mywebservice \
    symbol xsd::string {MSFT WMT XOM GM F GE }

<ws>proc ::mywebservice::EchoSymbol {
    {Symbol:mywebservice::symbol}
} {
    return $Symbol
} returns {Symbol:mywebservice::symbol}

# Derive a simpleType via pattern (regular expression):
::wsdl::types::simpleType::restrictByPattern mywebservice \
    code xsd::integer {[0-9]{4}}

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
    {FirstNum:integer 0}
    {SecondNum:integer 0}
} {
    return [expr $FirstNum + $SecondNum]
} returns {Sum:xsd::integer}

<ws>proc ::mywebservice::MultiplyNumbers {
    {FirstDecimal:decimal 0}
    {SecondDecimal:decimal 0}
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

# Code below is required to be on this page:
# service address will be url of this page.

# Run final code to setup service:
<ws>namespace finalize ::mywebservice

# Freeze code to prevent changes and speed execution:
<ws>namespace freeze ::mywebservice

# Returns the correct response:
<ws>return ::mywebservice




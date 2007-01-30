# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



# Really Primitive Types:
# Any Simple Type:
::wsdl::schema::new tcl "urn:tcl"

::wsdl::types::primitiveType::new tcl anySimpleType {return 1} {Base type, should return true for every case}
::wsdl::doc::document doc types tcl anySimpleType {Base type, should return true for every case}

# String type
::wsdl::types::primitiveType::new tcl string {return 1} {String type. Anything should pass as true}
::wsdl::doc::document doc types tcl string {String type. Anything should pass as true}


# NOTE: Tcl Types Will not be primitive types for very long
# Need to pick a namespace for primitive types.
# The namespace for tcl will likely be just 'tcl', or maybe 'tcl:tk' or 'urn:tcl:tk'.
# NOTE TO FUTURE DEVELOPERS: namespace refers to XML namespaces not Tcl namespaces,
# NOTE that XML namespaces have : separator, a legal char in a tcl namespace.


foreach {type descr} {
    
    alnum {Any Unicode alphabet or digit character.} 

    alpha {Any Unicode alphabet character.}

    ascii {Any character with a value less than \u0080 (those that are in the 7-bit ascii range).}

    boolean {Any of the forms allowed to Tcl_GetBoolean.}

    control {Any Unicode control character.}

    digit {Any Unicode digit character. Note that this includes characters outside of the [0-9] range.}

    double {Any of the valid forms for a double in Tcl, with optional surrounding whitespace. 
	In case of under/overflow in the value, 0 is returned and the varname will contain -1.}

    false {Any of the forms allowed to Tcl_GetBoolean where the value is false.}

    graph {Any Unicode printing character, except space.}

    integer {Any of the valid forms for an integer in Tcl, with optional surrounding whitespace. 
	In case of under/overflow in the value, 0 is returned and the varname will contain -1.} 

    lower {Any Unicode lower case alphabet character.} 

    print {Any Unicode printing character, including space.}

    punct {Any Unicode punctuation character.}

    space {Any Unicode space character.} 

    true {Any of the forms allowed to Tcl_GetBoolean where the value is true.}

    upper {Any upper case alphabet character in the Unicode character set.}

    wordchar {Any Unicode word character. That is any alphanumeric character, 
	and any Unicode connector punctuation characters (e.g. underscore).}

    xdigit {Any hexadecimal digit character (\[0-9A-Fa-f]).}
} {
# Note this will change to a simpletype proc.
::wsdl::types::primitiveType::new tcl $type "return \[string is $type -strict \$value]" "$descr"
::wsdl::doc::document doc types tcl $type "$descr"
}


::tws::sourceFile [file join [file dirname [info script]] ns-tcl-dateTime-procs.tcl]

::tws::sourceFile [file join [file dirname [info script]] ns-xsd.tcl]


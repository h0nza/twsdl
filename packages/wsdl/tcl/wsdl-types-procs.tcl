# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



namespace eval ::wsdl::types { }
namespace eval ::wsdl::types::primitiveType { }
namespace eval ::wsdl::types::simpleType { } 
namespace eval ::wsdl::types::complexType { }

# addSimpleType, newPrimitiveType and restrictByEnumeration create types
# and validate method to check validation.
# Enumerated types and simple types are based upon primitive types.

proc ::wsdl::types::simpleType::new {tns typeName {base "tcl::anySimpleType"} } {

    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base "$base"]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace code \{::wsdb::types::${tns}::${typeName}::validate\}\]"
    
    proc ::wsdb::types::${tns}::${typeName}::validate { value } "
       variable base
       if {\[::wsdb::types::\${base}::validate \$value]} { 
           return 1
       } else { 
           return 0
       }"

    ::wsdl::schema::appendSimpleType simple $tns $typeName $base
} 


proc ::wsdl::types::primitiveType::new {tns typeName code description} {

    namespace eval ::wsdb::types::${tns}::$typeName [list variable description "$description"]

    proc ::wsdb::types::${tns}::${typeName}::validate { value } $code
}
    
# creates or restricts a simple type to a series of values
proc ::wsdl::types::simpleType::restrictByEnumeration {tns typeName baseType enumerationList } {

    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base $baseType]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace code \{::wsdb::types::${tns}::${typeName}::validate\}\]"

    proc ::wsdb::types::${tns}::${typeName}::validate { value } "
       variable base
       if {\[::wsdb::types::\${base}::validate \"\$value\"] && \[lsearch -exact \{$enumerationList\} \"\$value\"] > -1} { 
           return 1
       } else { 
           return 0
         }\n"

    ::wsdl::schema::appendSimpleType enumeration $tns $typeName $baseType $enumerationList
}

proc ::wsdl::types::simpleType::restrictByPattern {tns typeName baseType pattern } {

    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base $baseType]
    namespace eval ::wsdb::types::${tns}::${typeName} [list variable pattern $pattern]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace code \{::wsdb::types::${tns}::${typeName}::validate\}\]"

    proc ::wsdb::types::${tns}::${typeName}::validate { value } "
        variable base
        variable pattern
        if {\[::wsdb::types::\${base}::validate \$value] && \[regexp \$pattern \$value]} { 
            return 1
        } else { 
            return 0
     }"

    ::wsdl::schema::appendSimpleType pattern $tns $typeName $baseType $pattern
}


# wsdl Element Procs

namespace eval ::wsdl::elements::modelGroup {}
namespace eval ::wsdl::elements::modelGroup::sequence {}

# Procedure to tag elements which do not validate:

proc ::wsdl::elements::noteFault { namespace dataList } {
    
    namespace eval $namespace {
	variable .META
    }
    # dataList = fault(code, element, value, proc) or other data
    # based upon the fault code.
    lappend ${namespace}::.META(FAULT) $dataList
    return ""
}


proc ::wsdl::elements::modelGroup::sequence::new { 

    schemaAlias 
    typeName
    simpleTypesList
    {conversionList {}}
} {

    set script ""
    set Elements [list]
    # First Element to simpleType validation procs
    append script "
namespace eval ::wsdb::elements::$schemaAlias \{\}
namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{\}"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {
	    lappend Elements $Element
	}
	set TypeTail [namespace tail $Type]
	append script "

namespace eval ::wsdb::elements::${schemaAlias}::${typeName}::$Element \{
    variable validate \[namespace code \{Validate\}\]
    variable validate_$TypeTail \$::wsdb::types::${Type}::validate

    proc Validate \{ namespace \} \{
        variable validate_$TypeTail
        set Valid \[\$validate_$TypeTail \[::xml::instance::getTextValue \$namespace\]\]

        if \{!\$Valid\} \{
            ::wsdl::elements::noteFault \$namespace \[list 1 $Element \[::xml::instance::getTextValue \$namespace\] \$validate_$TypeTail \]
        \}
        return \$Valid
    \}
\}"

    }

 
    # Create Type Tcl Namespace
    append script "
namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{

    variable MinOccurs
    variable MaxOccurs
    variable validate \[namespace code \{Validate${typeName}\}\]"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	append script "
    variable validate_$Element \$\{::wsdb::elements::${schemaAlias}::${typeName}::${Element}::validate\}"
    }

    foreach simpleType $simpleTypesList {

	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}

	if {"$MinOccurs" eq ""} {
	    append script "
    set MinOccurs($Element) 1"
	} else {
	    append script "
    set MinOccurs($Element) $MinOccurs"
	}
	if {"$MaxOccurs" eq ""} {
	    append script "
    set MaxOccurs($Element) 1"
	} else {
	    append script "
    set MaxOccurs($Element) $MaxOccurs"
	}
	
    }

    # Conversion List Used for Invoke procedure
    if {![llength $conversionList]} {
	append script "
    variable conversionList \{$conversionList\}"
    } else {
	append script "
    variable conversionList \{[join $Elements { Value }] Value\}"
    }
    # Foreach with switch, probably change to foreach with loops.

    append script "
    
    proc Validate$typeName \{ namespace \} \{

        variable MinOccurs
        variable MaxOccurs"

    foreach Element $Elements {
	append script "
        variable validate_$Element"
    }

    append script "
        array set COUNT \[array get \$\{namespace\}::.COUNT]
        set COUNT(.INVALID) 0

        set ElementNames \[array names MinOccurs]

        foreach ElementName \$ElementNames \{
            if \{\$MinOccurs(\$ElementName) > 0\} \{
                if \{!\[info exists COUNT(\$ElementName)]\} \{
                    ::wsdl::elements::noteFault \$namespace \[list 4 \$ElementName 0 \$MinOccurs(\$ElementName)]
                    incr COUNT(.INVALID)
                    return 0
                \} elseif \{\$COUNT(\$ElementName) < \$MinOccurs(\$ElementName)\} \{
                    ::wsdl::elements::noteFaunt \$namespace \[list 4 \$ElementName \$COUNT(\$ElementName) \$MinOccurs(\$ElementName)]
                    incr COUNT(.INVALID)
                    return 0
                \}
            \}
            if \{\[info exists COUNT(\$ElementName)] && \$COUNT(\$ElementName) > \$MaxOccurs(\$ElementName)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 5 \$ElementName \$COUNT(\$ElementName) \$MaxOccurs(\$ElementName)]
                incr COUNT(.INVALID)
                return 0
            \}
        \}

        set PARTS \[set \$\{namespace\}::.PARTS]
        ns_log Notice \"PARTS = '\$PARTS'\"
        set COUNT(.ELEMENTS) 0
        foreach PART \$PARTS \{
            ns_log Notice \"Element PART = '\$PART'\"
            incr COUNT(.ELEMENTS)
            foreach \{childName prefix childPart\} \$PART \{\}
            ns_log Notice \"childName prefix childPart = '\$childName' '\$prefix' '\$childPart'\"
            if \{!\[string match ::* \$childPart]\} \{
                set childPart \$\{namespace\}::\$childPart
            \}

            switch -glob -- \$childName \{"

    foreach Element $Elements {
	append script "
                $Element \{
                    if \{!\[\$validate_$Element \$childPart]\} \{  
                        ::wsdl::elements::noteFault \$namespace \[list 2 $Element \$childPart\]
                        incr COUNT(.INVALID)
                        break
                    \}
                \}"

    }
    append script "
                default \{
                    ::wsdl::elements::noteFault \$namespace \[list 3 \$childName \$childPart\]                    
                    incr COUNT(.INVALID)
                \}
            \}
        \}

        if \{\$COUNT(.INVALID)\} \{
            return 0
        \} else \{
            return 1
        \}
    \}
\}"

    append script "
proc ::wsdb::elements::${schemaAlias}::${typeName}::new \{ 

    instanceNamespace 
    childValuesList
\} \{"
    set ElementCount [llength $Elements]
    if {$ElementCount == 1} {
        append script "
    set [lindex $Elements 0] \$childValuesList"
    } elseif {$ElementCount > 1} {
        append script "
    foreach \{$Elements\} \$childValuesList \{ \}"
    }
    append script "

    set typeNS \[::xml::element::create \$\{instanceNamespace\}::$typeName $typeName\]"
        
    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	if {[string is integer -strict $MaxOccurs] && $MaxOccurs > 1} {
	    error "MaxOccurs needs to be 1 to use this API"
	} elseif {"$MinOccurs" eq "0"} {
	    append script "
    if \{\$$Element ne \"\"\} \{
        ::xml::element::appendText \[::xml::element::append \$typeNS $Element] .TEXT \$$Element
    \}"
	} else {
	    append script "
    ::xml::element::appendText \[::xml::element::append \$typeNS $Element] .TEXT \$$Element
"
	}
    }
    append script "
    return \$typeNS
\}"
    
    ::wsdl::schema::addSequence $schemaAlias $typeName $simpleTypesList 0

    return $script 
}


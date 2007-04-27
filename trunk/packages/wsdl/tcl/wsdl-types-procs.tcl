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
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace code \{::wsdb::types::${tns}::${typeName}::validate\}\]"

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

########## Element Validate Procedure  Writers #####

proc ::wsdl::elements::modelGroup::sequence::minMaxList { 
    minOccurs
    maxOccurs
} {
    # minOccurs must be 0 or greater
    if {![string is integer -strict $minOccurs]
	|| $minOccurs < 0
    } {
	set minOccurs 1
    }
    # maxOccurs must be 1 or greater
    if {![string is integer -strict $maxOccurs] 
	|| $maxOccurs < 1 
    } {
	set maxOccurs 1
    }
    # maxOccurs must be greater than or equal to minOccurs
    if {$maxOccurs < $minOccurs} {
	set maxOccurs $minOccurs
    }

    return [list minOccurs $minOccurs maxOccurs $maxOccurs]
}

 
proc ::wsdl::elements::modelGroup::sequence::getElementData {
    Child
    {ArrayName ""}
} {
    set ChildNameType [lindex $Child 0]
    if {[set first [string first ":" $ChildNameType]] > -1} {
	set Element [string range $ChildNameType 0 [expr $first -1 ]]
	set Type [string range $ChildNameType [expr $first + 1] end]
	if {"$Type" eq ""} {
	    set Type "xsd::string"
	} elseif {[string first ":" "$Type"] == -1} {
	    set Type "xsd::$Type"
	} 
    } else {
	set Element $ChildNameType
	set Type "xsd::string"
    }
   
    # Seed facetArray with default values:
    array set facetArray {minOccurs {} maxOccurs {} form Value}
    array set facetArray [lindex $Child 1]
    array set facetArray [minMaxList $facetArray(minOccurs) $facetArray(maxOccurs)]
    
    lappend Elements $Element
    
    # Store information for later use:
    if {"$ArrayName" eq ""} {
	set ArrayName $Element
    }
    upvar $ArrayName ElementArray
    array set ElementArray [list name $Element type $Type minOccurs $facetArray(minOccurs)\
			    maxOccurs $facetArray(maxOccurs) facets [array get facetArray] \
			   form $facetArray(form)]
    
    return $Element
}


proc ::wsdl::elements::modelGroup::sequence::addReference {
    schemaAlias
    parentElement
    elementArray
} {
    upvar $elementArray ElementArray

    set base $ElementArray(type)
    set element $ElementArray(name)

    set ValidateTypeTail [string map {__ _} [string map {: _} $base]]

    return "

namespace eval ::wsdb::elements::${schemaAlias}::${parentElement}::$element \{
    variable base $base
    variable facetList \{[array get ElementArray]\}
    variable validate \[set ::wsdb::\$\{base\}::validate]
    variable new      \[set ::wsdb::\$\{base\}::new]

\}"

}



proc ::wsdl::elements::modelGroup::sequence::writeValidateProc {
    namespace
    typeName
    Elements
} {
    set script ""

    append script "
    
proc ${namespace}::Validate$typeName \{ namespace \} \{

    variable Children
    variable MinOccurs
    variable MaxOccurs"

    foreach Element $Elements {
	append script "
    variable validate_$Element"
    }

    append script "
    array set COUNT \[array get \$\{namespace\}::.COUNT]
    set COUNT(.INVALID) 0

    set ElementNames \$Children

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
    set COUNT(.ELEMENTS) 0

    foreach PART \$PARTS \{
        incr COUNT(.ELEMENTS)
        foreach \{childName prefix childPart\} \$PART \{\}
        set childPart \[::xml::normalizeNamespace \$namespace \$childPart] 

        switch -exact -- \$childName \{"

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
\}"

    return $script
}



########## Element New Procedure Writers #########


namespace eval ::wsdl::elements::modelGroup::simpleContent { }

proc ::wsdl::elements::modelGroup::simpleContent::create {
    schemaAlias
    parentElement
    elementArray
} {
    upvar $elementArray ElementArray

    set base $ElementArray(type)
    set element $ElementArray(name)

    set ValidateTypeTail [string map {__ _} [string map {: _} $base]]

    return "

namespace eval ::wsdb::elements::${schemaAlias}::${parentElement}::$element \{
    variable base $base
    variable facetList \{$ElementArray(facets)\}
    variable minOccurs $ElementArray(minOccurs)
    variable maxOccurs $ElementArray(maxOccurs)
    variable validate \[namespace code \{Validate\}\]
    variable new      \[namespace code \{new\}\]
    variable validate_$ValidateTypeTail \$::wsdb::types::${base}::validate

    proc Validate \{ namespace \} \{
        variable validate_$ValidateTypeTail
        set Valid \[\$validate_$ValidateTypeTail \[::xml::instance::getTextValue \$namespace\]\]

        if \{!\$Valid\} \{
            ::wsdl::elements::noteFault \$namespace \[list 1 $element \[::xml::instance::getTextValue \$namespace\] \$validate_$ValidateTypeTail \]
        \}
        return \$Valid
    \}

    proc new \{ namespace value \} \{
         ::xml::element::appendText \[::xml::element::append \$namespace $element] .TEXT \$value
    \}
\}"

}

namespace eval ::wsdl::elements::modelGroup::sequence {
    # writer_RequiredForeachDefault
    proc writer_000 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        $NewProc \$typeNS \[lindex \$childValuesList $Index\]
    \}"

    }
    proc writer_001 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        $NewProc \$typeNS \[lindex \$childValuesList $Index\]
    \} else \{
        $NewProc \$typeNS [list $Default]
    \}"

    }
    proc writer_010 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        foreach ChildValue \[lindex \$childValuesList $Index\] \{
            $NewProc \$typeNS \$ChildValue
        \}
    \}"

    }
    proc writer_011 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        foreach ChildValue \[lindex \$childValuesList $Index\] \{
            $NewProc \$typeNS \$ChildValue
        \}
    \} else \{
        foreach ChildValue \[list $Default\] \{
            $NewProc \$typeNS \$ChildValue
        \}
    \}"
    }
    proc writer_100 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        $NewProc \$typeNS \[lindex \$childValuesList $Index\]
    \} else \{
        return -code error \"Missing value for required element \[namespace current\] index $Index\"
    \}"

    }
    proc writer_101 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        $NewProc \$typeNS \[lindex \$childValuesList $Index\]
    \} else \{
        $NewProc \$typeNS [list $Default]
    \}"

    }
    proc writer_110 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        foreach ChildValue \[lindex \$childValuesList $Index\] \{
            $NewProc \$typeNS \$ChildValue
        \}
    \} else \{
        return -code error \"Missing value for required element \[namespace current\] index $Index\"
    \}"

    }
    proc writer_111 { NewProc Index Default } {
        return "
    if \{\$ChildLength > $Index\} \{
        foreach ChildValue \[lindex \$childValuesList $Index\] \{
            $NewProc \$typeNS \$ChildValue
        \}
    \} else \{
        foreach ChildValue \[list $Default\] \{
            $NewProc \$typeNS \$ChildValue
        \}
    \}"

    }

}

# writeNewProc writes procedure to create new element
proc ::wsdl::elements::modelGroup::sequence::writeNewProc {
    namespace
  
} {
    set script ""

    if {[info exists ${namespace}::base]} {
	set Base ::wsdb::[set ${namespace}::base]
    } else {
	set Base $namespace
    }

    set Children [set ${Base}::Children]
    set ChildCount [llength $Children]

    array set ParentData [set ${namespace}::facetList]
    array set MinOccurs  [array get ${Base}::MinOccurs]
    array set MaxOccurs  [array get ${Base}::MaxOccurs]

    set ParentName $ParentData(name)

    append script "\nproc ${namespace}::new \{ instanceNamespace childValuesList \} \{

    set typeNS \[::xml::element::append \$\{instanceNamespace\} $ParentName\]
    set ChildLength \[llength \$childValuesList\]"
 
	
    if {$ChildCount == 1} {
	append script "
    set childValuesList \[list \$childValuesList\]"
    }
  
    # Chart to show Expected Actions based upon structures
    # min | max | supplied | default | result   | comment
    #
    #   0     1          +         -   supplied | value taken from supplied
    #   0     1          -         +   default  | default value used
    #   0     1          -         -   not shown| element not included
    #
    #   0     2+         +         -   supplied | foreach supplied
    #   0     2+         -         +   default  | foreach default value
    #   0     2+         -         -   not shown| required element missing
    #
    #   1     1          +         -   supplied | value taken from supplied
    #   1     1          -         +   default  | default value used
    #   1     1          -         -   error    | required element missing
    #
    #   1     2+         +         -   supplied | foreach supplied
    #   1     2+         -         +   default  | foreach default value
    #   1     2+         -         -   error    | required element missing

    for {set i 0} {$i < $ChildCount} {incr i} {
	
	set Child [lindex $Children $i]

	if {[array exists ChildData]} {
	    array unset ChildData
	}

	array set ChildData [set ${Base}::${Child}::facetList]

	set NewProc \$${Base}::${Child}::new

	# If required
	if {$MinOccurs($Child) eq 0} {
	    set Required 0
	} else {
	    set Required 1
	}
	# Foreach 
	if {$MaxOccurs($Child) > 1} {
	    set Foreach 1
	} else {
	    set Foreach 0
	}
	# Default Exists?
	if {[info exists ChildData(default)]} {
	    set Default 1
	} else {
	    set ChildData(default) ""
	    set Default 0
	}
	
	# Name Writer Proc:
	set writer "writer_$Required$Foreach$Default"

	append script [$writer $NewProc $i $ChildData(default)]

    }

    append script "\n    return \$typeNS\n\}"

    return $script
}


proc ::wsdl::elements::modelGroup::sequence::new { 
    schemaAlias 
    typeName
    childList
} {

    set script ""
    set Elements [list]

    foreach Child $childList {
	
	lappend Elements [::wsdl::elements::modelGroup::sequence::getElementData $Child]
	
    }

    foreach Element $Elements {
	if {[string match "elements::*" [set ${Element}(type)]]} {
	    append script [::wsdl::elements::modelGroup::sequence::addReference \
			       $schemaAlias $typeName $Element]
	} else {
	    append script [::wsdl::elements::modelGroup::simpleContent::create \
			       $schemaAlias $typeName $Element]
	}
    }

        append script "

namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{

    variable Children \{$Elements\}
    variable MinOccurs
    variable MaxOccurs
    variable facetList \[list form Value name $typeName\]
    variable validate \[namespace code \{Validate${typeName}\}\]
    variable new      \[namespace code \{new\}]"

    foreach Element $Elements {
	append script "
    variable validate_$Element \$${Element}::validate"

    }

    foreach Element $Elements {
	append script "
    set MinOccurs($Element) [set ${Element}(minOccurs)]
    set MaxOccurs($Element) [set ${Element}(maxOccurs)]"

    }


    # Foreach with switch, probably change to foreach with loops.
    append script "\n\}"
    append script [::wsdl::elements::modelGroup::sequence::writeValidateProc \
		       ::wsdb::elements::${schemaAlias}::$typeName $typeName \
		       $Elements]
		       
    append script "
eval \[::wsdl::elements::modelGroup::sequence::writeNewProc ::wsdb::elements::${schemaAlias}::$typeName\]

::wsdl::schema::addSequence \"$schemaAlias\" \"$typeName\" \{$childList\} 0
"
    return $script
}

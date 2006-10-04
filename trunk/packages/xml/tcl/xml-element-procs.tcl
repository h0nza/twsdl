# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::xml::element {
    namespace import ::tws::log::log
}


proc ::xml::element::append { parent childName {prefix {}} {attributeList {}} } {
    
    # A document will only have one child, with documentElement set
    if {[info exists ${parent}::documentElement] 
	&& [llength [set ${parent}::.PARTS]] > 0 
    } {
	# Should be error
	return ""
    }
    set CurrentChildrenList [set ${parent}::.PARTS]
    
    log Notice "parent = $parent CurrentChildrenList = $CurrentChildrenList"

    # Get list of all similarly named children. 
    set MultiChildList [lsearch -inline -all $CurrentChildrenList ${childName}*]
    if {[llength $MultiChildList] > 0} {
	set ElementNamespaceTail ${childName}::[llength $MultiChildList]
    } else {
	set ElementNamespaceTail $childName
    }

    log Notice "element::append ElementNamespaceTail = $ElementNamespaceTail"
    
    # Create element shell:
    ::xml::element::create ${parent}::$ElementNamespaceTail $prefix

    # Add attributes to child
    array set ${parent}::${ElementNamespaceTail}::.ATTR $attributeList

    # Add child to parent
    lappend ${parent}::.PARTS ${ElementNamespaceTail}

    # Return name of child namespace (Should this be absolute or relative?
    return ${parent}::$ElementNamespaceTail

} 

proc ::xml::element::appendText { elementNamespace textValue } {

    # This creates variable if it doesn't exist
    namespace eval $elementNamespace {
	variable .TEXT
    }

    if {![info exists ${elementNamespace}::.TEXT]} {
	set ${elementNamespace}::.TEXT(0) $textValue
	lappend ${elementNamespace}::.PARTS .TEXT(0)
	return "${elementNamespace}::.TEXT(0)"
    }
    
    set TextPartIndexValues [lsort -integer [array names ${elementNamespace}::.TEXT]]

    set NextTextIndex [expr [lindex $TextPartIndexValues end] + 1]

    set ${elementNamespace}::.TEXT($NextTextIndex) $textValue

    lappend ${elementNamespace}::.PARTS .TEXT($NextTextIndex)

    return "${elementNamespace}::.TEXT($NextTextIndex)"

}

proc ::xml::element::appendRef { elementNamespace referenceNamespace } {

     # This creates variable if it doesn't exist
    namespace eval $elementNamespace {
	variable .REF
    }
   
    if {![info exists ${elementNamespace}::.REF]} {
	set ${elementNamespace}::.REF(0) $referenceNamespace
	lappend ${elementNamespace}::.PARTS .REF(0)
	return "${elementNamespace}::.REF(0)"
    }

    
    set RefPartIndexValues [lsort -integer [array names ${elementNamespace}::.REF]]

    set NextRefIndex [expr [lindex $RefPartIndexValues end] + 1]

    set ${elementNamespace}::.REF($NextRefIndex) $referenceNamespace

    lappend ${elementNamespace}::.PARTS .REF($NextRefIndex)

    return "${elementNamespace}::.REF($NextRefIndex)"

}


# Create xml element shell with full namespace path
proc ::xml::element::create { elementNamespace {prefix {}} } {

    namespace eval $elementNamespace {
	variable .PARTS [list]
	variable .ATTR
	variable .PREFIX
    } 
    set ${elementNamespace}::.PREFIX $prefix
    
    return $elementNamespace
}


proc ::xml::element::createRef { parent childName {prefix {}} {attributeList {}} } {

    ::xml::element::create ${parent}::$childName $prefix

    # Add attributes to child
    array set ${parent}::${childName}::.ATTR $attributeList

    # Return reference namespace 
    return ${parent}::$childName

} 

proc ::xml::element::setAttributes { elementNamespace attributeList } {

    array set ${elementNamespace}::.ATTR $attributeList
}

proc ::xml::element::setAttribute { elementNamespace attributeName attributeValue } {

    set ${elementNamespace}::.ATTR($attributeName) $attributeValue

    return $attributeValue

}

proc ::xml::element::getAttribute { elementNamespace attributeName } {

    return [set ${elementNamespace}::.ATTR($attributeName)]
}
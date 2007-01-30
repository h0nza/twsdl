# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



# ::xml::instance will hold instance data

namespace eval ::xml { }

namespace eval ::xml::instance {

    namespace import ::tws::log::log

}


# Problem: passing in name of current ns, not parentns on foreach.
proc ::xml::instance::new {instanceNS xmlList {isDoc 0} } {

    foreach {element attributes children} $xmlList { }
    
    if {$isDoc} {
	append instanceNS ::$element
    }

    namespace eval $instanceNS {
	if {![info exists .PARTS]} {
	    variable .PARTS [list]
	}
    }


    # Get Child Element Names, and count repeat elements
    foreach child $children { 
	set Name [lindex $child 0]
	set Child_Count($Name) 0
	if {[info exists Child($Name)]} {
	    incr Child($Name)
	} else {
	    set Child($Name) 1
	}
    }


    foreach child $children {

	set Name [lindex $child 0]

	# Text elements from tDOM. 
	if {[string match "\#*" "$Name"]} {
	    set PartName ".[string range "$Name" 1 end]($Child_Count($Name))"
	    set "${instanceNS}::$PartName" [lindex $child 1]
	    incr Child_Count($Name)
	    lappend ${instanceNS}::.PARTS "$PartName"
	    #log Debug "Now ${instanceNS}::.PARTS = [set ${instanceNS}::.PARTS]"
	    continue
	}

	if {$Child($Name) > 1} {
	    set PartName "${Name}::$Child_Count($Name)"
	    ::xml::instance::new "${instanceNS}::$PartName" "$child"
	    incr Child_Count($Name)
	} else {
	    set PartName "${Name}"
	    ::xml::instance::new "${instanceNS}::$PartName" "$child"
	}

	lappend ${instanceNS}::.PARTS "$PartName"
    }
	
    # Element Attributes 
    if {[llength $attributes] > 0} {
	array set "${instanceNS}::.ATTR" $attributes
    }
}


########################
proc ::xml::instance::print { namespace {depth -1} {mixedParent 0} } {

    incr depth
    set indent [string repeat " " $depth]
    
    set elementName [namespace tail $namespace]
    
    if {[regexp {[0-9]+} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 
    
    # If parent element isn't mixed, indent
    if {!$mixedParent} {
	append output "\n$indent"
    }
    
    append output "$namespace"
    
    # NOTE: add code to ensure quoted values
    if {[array exists ${namespace}::.ATTR]} {
	foreach {attr val} [array get ${namespace}::.ATTR] {
	    append output "\n$indent $attr=\"$val\""
	}
    }
    
    if {[llength [set ${namespace}::.PARTS]] == 0} {
	append output "\n"
	incr depth -1
	return $output 
    } else {
	append output "\n"
    }
    
    # Mixed Content Check: handle whitespace exactly
    if {[lsearch -glob [set ${namespace}::.PARTS] ".*"] > -1} {
	set mixedElement 1
    } else {
	set mixedElement 0
    }

    foreach child [set ${namespace}::.PARTS] {
	if {[string match ".*" "$child"]} {
	    append output "\n${indent}([set ${namespace}::$child]${indent})"
	} else {
	    append output "${indent}([::xml::instance::print ${namespace}::$child $depth $mixedElement]${indent})"
	}
    }

    # Avoid appending newline and indent to mixed content
    if {!$mixedParent && !$mixedElement} {
	append output "\n$indent"
    }

    append output "\n"
    incr depth -1
    return "$output"
}


proc ::xml::instance::print2 { namespace {depth -1} {mixedParent 0} } {

    incr depth
    set indent [string repeat " " $depth]
    
    set elementName [namespace tail $namespace]
    
    if {[regexp {[0-9]+} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 
    
    # If parent element isn't mixed, indent
    if {!$mixedParent} {
	append output "\n$indent"
    }
    
    append output "$namespace"
    
    foreach .VAR [lsort [info vars ${namespace}::*]] {
        #puts ".VAR = ${.VAR}"
	if {[array exists ${.VAR}]} {
            #puts "[array names ${.VAR}]"
	    foreach .ELEMENT [lsort [array names ${.VAR}]] {
		append output "\n${indent}${.VAR}(${.ELEMENT}) = '[set ${.VAR}(${.ELEMENT})]'"
	    }
	} else {
	    append output "\n${indent}${.VAR} = '[set ${.VAR}]'"
	}
    }

    if {[llength [set ${namespace}::.PARTS]] == 0} {
	append output "\n"
	incr depth -1
	return $output 
    } else {
	append output "\n"
    }
    
    # Mixed Content Check: handle whitespace exactly
    if {[lsearch -glob [set ${namespace}::.PARTS] ".*"] > -1} {
	set mixedElement 1
    } else {
	set mixedElement 0
    }

    foreach child [set ${namespace}::.PARTS] {
	if {[string match ".*" "$child"]} {
	    #append output "\n${indent}([set ${namespace}::$child]${indent})"
	} else {
	    append output "${indent}([::xml::instance::print2 ${namespace}::$child $depth $mixedElement]${indent})"
	}
    }

    # Avoid appending newline and indent to mixed content
    if {!$mixedParent && !$mixedElement} {
	append output "\n$indent"
    }

    append output "\n"
    incr depth -1
    return "$output"
}

proc ::xml::instance::print3 { namespace {depth -1}} {

    incr depth
    set indent [string repeat "    " $depth]
    set output "$indent$namespace\n"

    if {[array exists ${namespace}::ATTRIBUTES]} {
	foreach {attribute value} [array get ${namespace}::ATTRIBUTES] {
	    append output "$indent attr $attribute = '$value'\n"
	}
    }

    foreach var [info vars ${namespace}::*] {
	if {"[namespace tail $var]" ne "ATTRIBUTES"} {
	    append output "$indent meta $var = '[set $var]'\n"
	}
    }
    
    set ElementNumber [set ${namespace}::elementNumber]
    for {set i 1} {$i <= $ElementNumber} {incr i} {
	append output "\n[::xml::instance::print3 ${namespace}::$i $depth]"
    }

    return $output
}

############################### P R I N T  1 2 3  ###############################


proc ::xml::instance::toXML { namespace {depth -1} {mixedParent 0} } {

    incr depth
    set indent [string repeat " " $depth]
    
    set elementName [namespace tail $namespace]
    
    if {[regexp {[0-9]+} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 
    
    # If parent element isn't mixed, indent
    if {!$mixedParent} {
	append output "\n$indent"
    }
    
    append output "<$elementName"
    #log Debug "toXML namespace = $namespace output = '$output' "
    # NOTE: add code to ensure quoted values
    if {[array exists ${namespace}::.ATTR]} {
	foreach {attr val} [array get ${namespace}::.ATTR] {
	    append output " $attr=\"$val\""
	}
    }
    
    if {[llength [set ${namespace}::.PARTS]] == 0} {
	append output "/>"
	incr depth -1
	return $output 
    } else {
	append output ">"
    }
    
    # Mixed Content Check: handle whitespace exactly
    if {[lsearch -glob [set ${namespace}::.PARTS] ".*"] > -1} {
	set mixedElement 1
    } else {
	set mixedElement 0
    }

    foreach child [set ${namespace}::.PARTS] {
	if {[string match ".*" "$child"]} {
	    append output [set ${namespace}::$child]
	} else {
	    append output "[::xml::instance::toXML ${namespace}::$child $depth $mixedElement]"
	}
    }

    # Avoid appending newline and indent to mixed content
    if {!$mixedParent && !$mixedElement} {
	append output "\n$indent"
    }

    append output "</$elementName>"
    incr depth -1
    return "$output"
}

# TO XML USING NAMESPACE .PRFIX
proc ::xml::instance::toXMLNS { namespace {depth -1} {mixedParent 0} } {

    incr depth
    set indent [string repeat " " $depth]
    
    set elementName [namespace tail $namespace]
    
    if {[regexp {^[0-9]+$} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 
    
    # If parent element isn't mixed, indent
    if {!$mixedParent} {
	append output "\n$indent"
    }
    if {[info exists ${namespace}::.PREFIX] 
	&& [set ${namespace}::.PREFIX] ne ""
    } {
	set prefixElementName [join [list [set ${namespace}::.PREFIX] $elementName] ":"]
	#log Debug "toXMLNS prefixElementName = $prefixElementName"
    } else {
	#log Debug "toXMLNS namespace = $namespace"
	set prefixElementName $elementName
    }
    append output "<$prefixElementName"
    #log Debug "toXML namespace = $namespace output = '$output' "
    # NOTE: add code to ensure quoted values
    if {[array exists ${namespace}::.ATTR]} {
	foreach {attr val} [array get ${namespace}::.ATTR] {
	    append output " $attr=\"$val\""
	}
    }
    
    if {[llength [set ${namespace}::.PARTS]] == 0} {
	append output "/>"
	incr depth -1
	return $output 
    } else {
	append output ">"
    }
    
    # Mixed Content Check: handle whitespace exactly
    if {[lsearch -glob [set ${namespace}::.PARTS] ".TEXT*"] > -1} {
	set mixedElement 1
    } else {
	set mixedElement 0
    }

    foreach child [set ${namespace}::.PARTS] {
	switch -glob -- "$child" {
	    ".TEXT*" {
		append output [set ${namespace}::$child]
	    }
	    ".REF*" {
		append output [::xml::instance::toXMLNS [set ${namespace}::$child] $depth $mixedElement]
	    }
	    default {
		append output "[::xml::instance::toXMLNS ${namespace}::$child $depth $mixedElement]"
	    }
	}
    }

    # Avoid appending newline and indent to mixed content
    if {!$mixedParent && !$mixedElement} {
	append output "\n$indent"
    }

    append output "</$prefixElementName>"
    incr depth -1
    return "$output"
}


# TO XML USING NAMESPACE .PRFIX
proc ::xml::instance::printErrors { namespace {depth -1} } {

    incr depth
    set indent [string repeat " " $depth]
    
    append output "\n$indent"
    set elementName [namespace tail $namespace]
    
    if {[regexp {^[0-9]+$} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 

    if {[info exists ${namespace}::.PREFIX] 
	&& [set ${namespace}::.PREFIX] ne ""
    } {
	set prefixElementName [join [list [set ${namespace}::.PREFIX] $elementName] ":"]
	#log Debug "toXMLNS prefixElementName = $prefixElementName"
    } else {
	#log Debug "toXMLNS namespace = $namespace"
	set prefixElementName $elementName
    }
    append output "$prefixElementName"

    if {![info exists ${namespace}::.META(FAULT)] || [llength [set ${namespace}::.META(FAULT)]] == 0} {
	incr depth -1
	return $output 
    } 
    
    # Additional indent for data:
    set indent2 "    "

    foreach FaultList [set ${namespace}::.META(FAULT)] {
	append output "\n$indent$indent2"
	set FaultCode [lindex $FaultList 0]
	set FaultDescriptionList [list]

	switch -exact -- $FaultCode {
	    "1" {
		lappend FaultDescriptionList "Invalid Value for [lindex $FaultList 1]"
		lappend FaultDescriptionList "Element = [lindex $FaultList 1]"
		lappend FaultDescriptionList "Value = [lindex $FaultList 2]"
		append output [join $FaultDescriptionList "\n$indent$indent2"]
	    }
	    "2" {
		set FaultElementName [lindex $FaultList 1]
		set FaultElementIndex [lindex $FaultList 2]
		if {$FaultElementIndex > 0} {
		    set ChildFaultNamespace ${FaultElementName}::$FaultElementIndex
		} else {
		    set ChildFaultNamespace $FaultElementName
		}
		append output "Invalid Child:"
		append output [::xml::instance::printErrors "${namespace}::$ChildFaultNamespace" $depth]
	    }
	    "3" {
		lappend FaultDescriptionList "Unknown Element"
		lappend FaultDescriptionList "Element = [lindex $FaultList 1]"
		lappend FaultDescriptionList "Child number [lindex $FaultList 2]"

		append output [join $FaultDescriptionList "\n$indent$indent2"]
	    }
	    "4" {
		lappend FaultDescriptionList "Element Count below minOccurs"
		lappend FaultDescriptionList "Element = [lindex $FaultList 1]"
		lappend FaultDescriptionList "Occurances = [lindex $FaultList 2]"
		lappend FaultDescriptionList "minOccurs = [lindex $FaultList 3]"

		append output [join $FaultDescriptionList "\n$indent$indent2"]
	    }
	    "5" {
		lappend FaultDescriptionList "Element Count above maxOccurs"
		lappend FaultDescriptionList "Element = [lindex $FaultList 1]"
		lappend FaultDescriptionList "Occurances = [lindex $FaultList 2]"
		lappend FaultDescriptionList "maxOccurs = [lindex $FaultList 3]"

		append output [join $FaultDescriptionList "\n$indent$indent2"]
	    }
	}
    }

    append output "\n$indent"
    incr depth -1
    return "$output"
}


# Inspection Code: Print everything found, not just what is expected.

proc ::xml::instance::toText { namespace {depth -1} {mixedParent 0} } {

    incr depth
    set indent [string repeat " " $depth]
    
    set elementName [namespace tail $namespace]
    
    if {[regexp {[0-9]+} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 
    
    # If parent element isn't mixed, indent
    if {!$mixedParent} {
	append output "\n$indent"
    }
    
    append output "'''$elementName'"
    
    # NOTE: add code to ensure quoted values
    if {[array exists ${namespace}::.ATTR]} {
	append output "("
	foreach {attr val} [array get ${namespace}::.ATTR] {
	    append output "'$attr=$val'"
	}
	append output ")'"
    }
    
    if {[llength [set ${namespace}::.PARTS]] == 0} {
	append output "/''"
	incr depth -1
	return $output 
    } else {
	append output "'"
    }
    
    # Mixed Content Check: handle whitespace exactly
    if {[lsearch -glob [set ${namespace}::.PARTS] ".*"] > -1} {
	set mixedElement 1
    } else {
	set mixedElement 0
    }

    foreach child [set ${namespace}::.PARTS] {
	if {[string match ".*" "$child"]} {
	    append output [set ${namespace}::$child]
	} else {
	    append output "[::xml::instance::toText ${namespace}::$child $depth $mixedElement]"
	}
    }

    # Avoid appending newline and indent to mixed content
    if {!$mixedParent && !$mixedElement} {
	append output "\n$indent"
    }

    append output "'''"
    incr depth -1
    return "$output"
}

# quickie value getter...rename at some point.
proc ::xml::instance::getTextValue { namespace } {

    set value ""
    foreach part [set ${namespace}::.PARTS] {
	if {[string equal -nocase -length 5 ".TEXT" "$part"]} {
	    append value [set ${namespace}::$part]
	}
    }
    return $value

}

proc ::xml::instance::checkXMLNS {instanceNS namespace} {
    
    if {[info exists ${instanceNS}::.PREFIX]} {
	set attribute "xmlns:[set ${instanceNS}::.PREFIX]"
    } else {
	set attribute "xmlns"
    }
    if {"$namespace" eq "[set ${instanceNS}::.ATTR($attribute)]"} {
	return 1
    } else {
	return 0
    }
    
}

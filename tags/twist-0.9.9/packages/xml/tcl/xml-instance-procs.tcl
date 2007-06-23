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

# Takes tDOM toList
proc ::xml::instance::newXMLNS {tclNamespace xmlList {isDoc 0} } {

    set element [lindex $xmlList 0]
    set attributes [lindex $xmlList 1]
    set children [lindex $xmlList 2]

    foreach {prefix localname} [::xml::element::toPrefixLocalnameList $element] {}

    if {$isDoc} {
	append tclNamespace ::$localname
	::xml::element::create $tclNamespace $localname $prefix $attributes
	set ${tclNamespace}::documentElement $localname
    }
 
    foreach child $children {
	# Text elements from tDOM. 
	if {[string match #* [lindex $child 0]]} {
	     ::xml::element::appendText $tclNamespace [lindex $child 0] [lindex $child 1]
	     continue
	 }
	foreach {childPrefix childLocalname} \
	    [::xml::element::toPrefixLocalnameList [lindex $child 0]] {}


	set childTclNamespace [::xml::element::append $tclNamespace $childLocalname $childPrefix [lindex $child 1]]
	::xml::instance::newXMLNS $childTclNamespace $child

    }	

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
	    set PartName ".[string toupper [string range "$Name" 1 end]]($Child_Count($Name))"
	    set "${instanceNS}::$PartName" [lindex $child 1]
	    incr Child_Count($Name)
	    lappend ${instanceNS}::.PARTS "$PartName"
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
    if {[array exists ${namespace}::.ATTRS]} {
	foreach {attr val} [array get ${namespace}::.ATTRS] {
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
    set indent [string repeat "     " $depth]
    
    set elementName [namespace tail $namespace]
    
    if {[regexp {[0-9]+} $elementName]} {
	set elementName [namespace tail [namespace parent $namespace]]
    } 
    
    # If parent element isn't mixed, indent
    if {0} {
    if {!$mixedParent} {
	append output "\n$indent"
    }
    }
    append output "$namespace"
    
    foreach .VAR [lsort [info vars ${namespace}::*]] {

	if {[array exists ${.VAR}]} {
	    foreach .ELEMENT [lsort [array names ${.VAR}]] {
		append output "\n${indent}[namespace tail ${.VAR}(${.ELEMENT})] = '[set ${.VAR}(${.ELEMENT})]'"
	    }
	} elseif {[info exists ${.VAR}]} {
	    append output "\n${indent}[namespace tail ${.VAR}] = '[set ${.VAR}]'"
	} else {
	    append output "\n${indent}[namespace tail ${.VAR}] is undefined"
        }
    }
    if {0} {
    if {[llength [set ${namespace}::.PARTS]] == 0} {
	append output "\n"
	incr depth -1
	return $output 
    } else {
	append output "\n"
    }
    }
    if {[info exists ${namespace}::.PARTS]} {
	append output "\n"
	# Mixed Content Check: handle whitespace exactly
	if {[lsearch -glob [set ${namespace}::.PARTS] [list .* * *]] > -1} {
	    set mixedElement 1
	} else {
	    set mixedElement 0
	}
	
	
	foreach childList [set ${namespace}::.PARTS] {
	    set child [lindex $childList 2]
	    if {![string match ".*" "$child"]} {
		append output "${indent}([::xml::instance::print2 ${namespace}::$child $depth $mixedElement]${indent})\n"
	    }
	}
    } else {
	set mixedElement 0
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

    # NOTE: add code to ensure quoted values
    if {[array exists ${namespace}::.ATTRS]} {
	foreach {attr val} [array get ${namespace}::.ATTRS] {
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


# TO XML USING NAMESPACE .PREFIX
proc ::xml::instance::toXMLNS { tclNamespace {depth -1} {mixedParent 0} } {

    incr depth
    set indent [string repeat " " $depth]
    
    set elementName [set ${tclNamespace}::.NAME]

    # If parent element isn't mixed, indent
    if {!$mixedParent} {
	append output "\n$indent"
    }
    if {[info exists ${tclNamespace}::.PREFIX] 
	&& [set ${tclNamespace}::.PREFIX] ne ""
    } {
	set prefixElementName [join [list [set ${tclNamespace}::.PREFIX] $elementName] ":"]
    } else {
	set prefixElementName $elementName
    }
    append output "<$prefixElementName"

    # NOTE: add code to ensure quoted values
    if {[array exists ${tclNamespace}::.ATTRS]} {
	foreach {attr val} [array get ${tclNamespace}::.ATTRS] {
	    append output " $attr=\"$val\""
	}
    }
    
    if {[llength [set ${tclNamespace}::.PARTS]] == 0} {
	append output "/>"
	incr depth -1
	return $output 
    } else {
	append output ">"
    }
    
    # Mixed Content Check: handle whitespace exactly
    if {[lsearch -glob [set ${tclNamespace}::.PARTS] [list ".TEXT" * *]] > -1} {
	set mixedElement 1
    } else {
	set mixedElement 0
    }

    foreach part [set ${tclNamespace}::.PARTS] {
	foreach {childName prefix childPart} $part { }
	switch -glob -- "$childPart" {
	    ".TEXT*" {
		append output [set ${tclNamespace}::$childPart]
	    }
	    "::*" {
		append output [::xml::instance::toXMLNS $childPart $depth $mixedElement]
	    }
	    default {
		append output "[::xml::instance::toXMLNS ${tclNamespace}::$childPart $depth $mixedElement]"
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
    #set elementName [namespace tail $namespace]
    set elementName [set ${namespace}::.NAME]

    if {[info exists ${namespace}::.PREFIX] 
	&& [set ${namespace}::.PREFIX] ne ""
    } {
	set prefixElementName [join [list [set ${namespace}::.PREFIX] $elementName] ":"]
    } else {
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
		set FaultChild [lindex $FaultList 2]

		append output "Invalid Child:"
		append output [::xml::instance::printErrors $FaultChild $depth]
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
    if {[array exists ${namespace}::.ATTRS]} {
	append output "("
	foreach {attr val} [array get ${namespace}::.ATTRS] {
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
    foreach textNode [lsearch -inline -all [set ${namespace}::.PARTS] {.TEXT * *}] {
	foreach {childName prefix childVar} $textNode { }
	append value [set ${namespace}::$childVar]
    }
    return $value

}

proc ::xml::instance::checkXMLNS {instanceNS namespace} {
    
    if {[info exists ${instanceNS}::.PREFIX] && "[set ${instanceNS}::.PREFIX]" ne ""} {
	set attribute "xmlns:[set ${instanceNS}::.PREFIX]"
    } else {
	set attribute "xmlns"
    }
    log Debug "Checking $instanceNS for XMLNS = '$namespace' attr='$attribute'"
    if {"$namespace" eq "[set ${instanceNS}::.ATTRS($attribute)]"} {
	return 1
    } else {
	return 0
    }
    
}

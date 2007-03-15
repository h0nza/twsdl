# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::xml {

    namespace import ::tws::log::log
}

proc ::xml::normalizeNamespace {namespace child} {

    if {![string match ::* $child]} {
	return ${namespace}::$child
    } else {
	return $child
    }
}


# Sets text value of children as array element
proc ::xml::childElementsAsArray { 
    
    namespace
    arrayName
} {

    set ChildElements [set ${namespace}::.PARTS]
    upvar $arrayName ChildArray
    foreach ChildElement $ChildElements {
	foreach {ChildType prefix ChildPart} $ChildElement {}
	set ChildPart [::xml::normalizeNamespace $namespace $ChildPart]
	lappend ChildArray($ChildType) [::xml::instance::getTextValue $ChildPart]
    }
}

# Sets text value of children as array element
proc ::xml::childElementsAsNameValueList { 
    
    namespace
    NVListVar
} {

    set ChildElements [set ${namespace}::.PARTS]
    upvar $NVListVar NVList
    foreach ChildElement $ChildElements {
	foreach {ChildType prefix ChildPart} $ChildElement {}
	set ChildPart [::xml::normalizeNamespace $namespace $ChildPart]
	lappend NVList $ChildType [::xml::instance::getTextValue $ChildPart]
    }
}


# Unordered List 
proc ::xml::childElementsAsListWithConversions { 
    
    namespace
    conversionList
} {
    # This should be from .PARTS, 
    # but .PARTS contains relative namespace names
    # When adding MultiName/Value/Namespace,
    # Need to move to ordered processing through .PARTS
    # And use lappend instead of set
    set ChildElementsList [set ${namespace}::.PARTS]
    array set ConversionArray $conversionList

    set ChildTypes [array names ${namespace}::.COUNT]
    array set COUNT [array get ${namespace}::.COUNT]

    foreach ChildType $ChildTypes {
	set ChildElements [lsearch -inline -all $ChildElementsList [list $ChildType * *]]
	set ConversionType $ConversionArray($ChildType)

	switch -exact -- $ConversionType {
	    "Value" {
		upvar $ChildType ${ChildType}.Value
		foreach ChildElement $ChildElements {
		    foreach {ChildType prefix ChildPart} $ChildElement {}
		    set ChildPart [::xml::normalizeNamespace $namespace $ChildPart]
		    set ${ChildType}.Value [::xml::instance::getTextValue $ChildPart]
		}
	    }
	    "List" {
		upvar $ChildType ${ChildType}.Value
		set ${ChildType}.Value [list]
		foreach ChildElement $ChildElements {
		    foreach {ChildType prefix ChildPart} $ChildElement {}
		    set ChildPart [::xml::normalizeNamespace $namespace $ChildPart]
		    lappend ${ChildType}.Value [::xml::instance::getTextValue $ChildPart]
		}
	    }
	    "Element" {
		upvar $ChildType ${ChildType}.Element
		set ${ChildType}.Element [list]
		foreach ChildElement $ChildElements {
		    foreach {ChildType prefix ChildPart} $ChildElement {}
		    set ChildPart [::xml::normalizeNamespace $namespace $ChildPart]
		    lappend ${ChildType}.Element $ChildPart
		}
	    }
	    "Array" {
		upvar $ChildType ${ChildType}.Element
		if {[array exists ${ChildType}.Element]} {
		    array unset ${ChildType}.Element
		}
		# Creates arrays in calling proc. 
		# List of array names is in variable ChildType in calling proc.
		set ArrayIndex 0
		foreach ChildElement $ChildElements {
		    foreach {ChildType prefix ChildPart} $ChildElement {}
		    set ChildPart [::xml::normalizeNamespace $namespace $ChildPart]
		    upvar ${ChildType}.$ArrayIndex ${ChildType}.Array$ArrayIndex 
		    ::xml::childElementsAsArray $ChildPart ${ChildType}.Array$ArrayIndex
		    lappend ${ChildType}.Element ${ChildType}.$ArrayIndex
		    incr ArrayIndex
		}

	    }

	}

    }

}


::tws::sourceFile [file join [file dirname [info script]] xml-instance-procs.tcl]
::tws::sourceFile [file join [file dirname [info script]] xml-element-procs.tcl]
::tws::sourceFile [file join [file dirname [info script]] xml-document-procs.tcl]


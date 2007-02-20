# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::xml { }

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
    set ChildElements [namespace children $namespace]
    array set ConversionArray $conversionList
    
    foreach Child $ChildElements {
	set ChildElement [namespace tail $Child]
	set ConversionType $ConversionArray($ChildElement)
	switch -exact -- "$ConversionType" {
	    "Name" {
		upvar $ChildElement ${ChildElement}.Name
		set ${ChildElement}.Name $ChildElement
	    }
	    "Value" {
		upvar $ChildElement ${ChildElement}.Value
		set ${ChildElement}.Value [::xml::instance::getTextValue $Child]
	    }
	    "Namespace" {
		upvar $ChildElement ${ChildElement}.Namespace
		set ${ChildElement}.Namespace $Child
	    }
	}
    }
}


::tws::sourceFile [file join [file dirname [info script]] xml-instance-procs.tcl]
::tws::sourceFile [file join [file dirname [info script]] xml-element-procs.tcl]
::tws::sourceFile [file join [file dirname [info script]] xml-document-procs.tcl]


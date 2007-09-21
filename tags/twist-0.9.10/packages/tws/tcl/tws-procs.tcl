# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# Tcl Web Services

# Procedure to set named arguments
# Procedure is defined with args
# and called with name of variable and value
# Inside procedure use setArgs to find and
# set passed in variables or set defaults
proc ::tws::setArgs { args } {

    foreach arg $args {
	set __option [lindex $arg 0]
	upvar $__option $__option
	set $__option  [lindex $arg 1]
    }

    uplevel {
	foreach {__option __value} $args {
	    set __option [string trimleft $__option "-"]
	    set $__option $__value
	}
    }
}

proc ::tws::sourceFile { file args } {

    ::tws::log::log Notice "Sourcing '[file normalize [file join [pwd] $file]]' '$args'"
    uplevel ::source "$file"

}

source [file join [file dirname [info script]] util-procs.tcl]
source [file join [file dirname [info script]] nvlist-procs.tcl]

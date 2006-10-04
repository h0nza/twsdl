# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



namespace eval ::inspect {


}

proc ::inspect::showNamespace { {namespace "::"} {depth 1} } {
   
    set namespaceList [list]
    foreach ns [lsort [namespace children "$namespace"]] {
	lappend namespaceList $depth $ns
	if {$depth > 0} {
	    set namespaceList [concat $namespaceList [::inspect::showNamespace "$ns" [expr $depth -1]]]
	}
    }
    return $namespaceList

}

proc ::inspect::findVars { namespace } {

    return [lsort [info vars ${namespace}::*]]

}

proc ::inspect::findProcs { namespace } {

    return [lsort [info procs ${namespace}::*]]

}

proc ::inspect::showProc { proc } {

    set args [info args $proc]
    set arguments [list]
    foreach arg $args {
	if {[info default $proc $arg defaultValue]} {
	    lappend arguments "\{$arg $defaultValue\}"
	} else {
	    lappend arguments [list $arg]
	}
    }
    return "
proc $proc \{\n    [join $arguments "\n    "]\n\} \{[info body $proc]\}"

}

# Appends a substituted string which contains commands and/or variables
# from the listVars with values taken from list.
# Simply hides loop details.
proc ::inspect::formatList { list listVars substString} {
    
    set returnString ""
    foreach $listVars $list {
	append returnString [subst $substString]
    }
    return $returnString

}

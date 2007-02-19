# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



namespace eval ::inspect {

    namespace import ::tws::log::log

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

proc ::inspect::findVars { namespace {pattern *}} {

    return [lsort [info vars ${namespace}::$pattern]]

}

proc ::inspect::findProcs { namespace {pattern *}} {

    return [lsort [namespace eval $namespace "return \[info procs $pattern]"]]
    

}

proc ::inspect::showProc { proc } {

    set args [info args $proc]
    set arguments [list]
    foreach arg $args {
	if {[info default $proc $arg defaultValue]} {
	    lappend arguments "\{[ns_quotehtml $arg] [ns_quotehtml $defaultValue]\}"
	} else {
	    lappend arguments [list $arg]
	}
    }
    return "
proc [ns_quotehtml $proc] \{\n    [join [ns_quotehtml $arguments] "\n    "]\n\} \{[ns_quotehtml [info body $proc]]\}"

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

proc ::inspect::displayVars { {namespace ::} {pattern *} } {

    set vars [::inspect::findVars $namespace $pattern]
    set output "

<h4> Variables in $namespace</h4>
<pre>
"    
  
    foreach var $vars {
	if {[array exists $var]} {
	    set arrayNames [array names $var]
	    append output "Array [ns_quotehtml $var]\n"
	    foreach arrayName $arrayNames {
		append output " [ns_quotehtml ${var}\($arrayName\)] = '[ns_quotehtml [set ${var}($arrayName)]]'\n"
	    }
	} elseif {[info exists $var]} {
	    append output " [ns_quotehtml $var] = '[ns_quotehtml [set $var]]'\n"
	} else {
	    append output " [ns_quotehtml $var] is currently undefined\n"
	}
    }
    
    append output "</pre>\n"  

    return $output
}

proc ::inspect::displayProcs { {namespace ::} {pattern *} } {

    set procs [::inspect::findProcs $namespace $pattern]
    log Notice "Procs = '$procs'"
    set output "</pre>
<h4>Procedures in [ns_quotehtml $namespace]</h4>
<pre>"
    foreach procName $procs {
	append output "\n[::inspect::showProc [string trimright ${namespace} : ]::$procName]\n"
    }
    append output "</pre>\n" 
    
    return $output

}    

proc ::inspect::displayNamespace { {namespace ::} {varPattern *} {procPattern *}} {

    set output "<h3> CONTENTS OF NAMESPACE $namespace </h3>\n"
    append output "[displayVars $namespace $varPattern]\n"
    append output "[displayProcs $namespace $procPattern]"
    return "$output"
    
}

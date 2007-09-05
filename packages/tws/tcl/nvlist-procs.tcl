# Easily add name-value lists allowing bi-directional
# lookup by key or value. Both key and value can occur
# multiple times, although it is more usual to have one
# key with multiple values (one to many mapping).

namespace eval ::tws::nvlist { }

proc ::tws::nvlist::create { nvlistVar args } {
    upvar $nvlistVar nvlist
    set nvlist $args
}

# Enumerations
proc ::tws::nvlist::createEnum {nvlistVar args} {
    upvar $nvlistVar nvlist
    set index 0
    foreach arg $args {
	lappend nvlist [list $index $arg]
	incr index
    }
    return $index
}

proc ::tws::nvlist::copy { nvlistVar nvlistVarTo } {
    upvar $nvlistVar nvlist
    upvar $nvlistVarTo nvlistTo
    set nvlistTo $nvlist
}

proc ::tws::nvlist::search { nvlistVar searchList } {

    upvar $nvlistVar nvlist
    return [lsearch -inline -all $nvlist $searchList]
}

proc ::tws::nvlist::toName { nvlistVar value } {

    upvar $nvlistVar nvlist
    set return [list]
    foreach result [search nvlist [list * $value]] {
	lappend return [lindex $result 0]
    }
    return $return
}

proc ::tws::nvlist::filterIndex { nvlistVar returnIndex searchList } {

    upvar $nvlistVar nvlist
    set return [list]
    foreach result [search nvlist $searchList] {
	lappend return [lindex $result $returnIndex]
    }
    return $return
    
}

proc ::tws::nvlist::toValue { nvlistVar name } {

    upvar $nvlistVar nvlist
    set return [list]
    foreach result [search nvlist [list $name *]] {
	lappend return [lindex $result 1]
    }
    return $return
} 

# Not necessary, but shortens calls
namespace eval ::tws::nvlist {
 namespace export *
}

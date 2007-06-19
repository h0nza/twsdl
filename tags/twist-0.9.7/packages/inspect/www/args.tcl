

proc ::tws::setArgs { args } {
    # Note that these are the args passed in here:	
    foreach arg $args {
	set __option [lindex $arg 0]
	upvar $__option $__option
	set $__option  [lindex $arg 1]
    }
   # This args is what was passed into the caller:
    uplevel {
	foreach {__option __value} $args {
	    set __option [string trimleft $__option "-"]
	    set $__option $__value
	}
    }
}


proc ::tws::setOptions { __optionLists } {

    upvar args args
    foreach __optionList $__optionLists {
	set __option [lindex $__optionList 0]
	upvar $__option $__option
	set $__option [lindex $__optionList 1]
    }
    set GLOBALOPTIONS [list]
    foreach {__option __value} $args { 
	set __option [string trimleft $__option "-"]
	if {[lsearch $__optionLists [list $__option *]] > -1} {
	    uplevel [list set "$__option" "$__value"]
	} else {
	    lappend GLOBALOPTIONS [list "$__option" "$__value"]
	}  
    }
    if {[lsearch $GLOBALOPTIONS {LOGARGS *}] > -1 } {
	log Notice "LOGARGS: '$args'"
    }
}

proc testProc { arg1 arg2 args } {

    ::tws::setArgs {arg3 "val arg 3"} \
	{arg4 "val arg 4"} \
	{arg5 "val arg 5"}

    
    set Vars [info vars]
    foreach Var $Vars {
	append data "  $Var = [set $Var]\n"
    }

    return $data
}

proc testOptions { arg1 arg2 args } {

    ::tws::setOptions {
	{arg3 "val arg 3"}
	{arg4 "val arg 4"} 
	{arg5 "val arg 5"}
    }
    
    set Vars [info vars]
    foreach Var $Vars {
	append data "  $Var = [set $Var]\n"
    }

    return $data
}


#set data [testOptions val1 {[val2]} -arg5 {[ls]} -arg8 "ooo" -LOGARGS "testing data"] 

set arg1 "val1"
set arg2 "val2"
set data [testOptions $arg1 $arg2  -arg5 "ooo" -arg8 "no arg8" -LOGARGS "arg1 = $arg1,  arg2 = $arg2"] 

ns_return 200 text/plain $data
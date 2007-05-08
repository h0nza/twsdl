# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# log package

namespace eval ::tws::log {
    variable Method
    variable Initialized
}

# maybe remove this proc?
proc ::tws::log::init { } {

    variable Inititalized
    variable Method
    variable ::tws::AOLserver

    if {![info exists Initialized]} {
	if {$::tws::AOLserver} {
	    set Method "ns"
	} else {
	    set Method "puts"
	}
    }
    log Notice "tws::log::init Log Method = '$Method'"
    set Initialized 1
}




# log proc should allow testing of some packages
# using tclsh
# If this proves useless, simplify to remove Method.

proc ::tws::log::log { level args } {

    variable Method

    switch -exact -- $Method {
	"puts" {
	    puts stderr "$level TWS:[join $args " "]"
	}
	"ns" {
	    ns_log $level "TWS:[join $args " "]"
	}
    }


}

#initialize logging, Done here because it is needed
tws::log::init	

namespace eval ::tws::log {
    namespace export log
}


# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# Initialization file

namespace eval ::tws {
    variable Initialized 0
    variable AOLserver 0
    variable rootDirectory
    variable packageRoot 
    variable packages [list]
}

set ::tws::rootDirectory [file dirname [info script]]
set ::tws::packageRoot [file join $::tws::rootDirectory packages]

# Determine if using AOLserver or libnsd:

if {!([llength [info commands ns_log]] > 0)} {
    set nsdLibraryFile [file join [file dirname [info library]] libnsd.so]
    if {[file exists $nsdLibraryFile]} {
	load $nsdLibraryFile
	ns_log Notice "TWS:init.tcl: Loaded $nsdLibraryFile"
        # Using AOLserver's libnsd
	namespace eval ::tws {
	    variable AOLserver [ns_info version]
	}
    } else {
	puts "TWS:init.tcl Unable to find libnsd.so at $nsdLibraryFile"
    }
} else {
    ns_log Notice "TWS:init.tcl ns_log already loaded."
    namespace eval ::tws {
	variable AOLserver [ns_info version]
    }
}


# Main Namespace
source [file join $::tws::packageRoot tws tcl tws-procs.tcl]
::tws::sourceFile [file join $::tws::packageRoot tws tcl tws-init.tcl]
::tws::sourceFile [file join $::tws::packageRoot tws tcl tws-local-conf.tcl]



# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# Utility procs will be those which are not normally used by the 
# end user in application programming.

namespace eval ::tws::util {
    # Shell namespace for utilities
}


#rename ::source ::original_source

#proc ::source { file } {
#   ::tws::log::log Notice "Sourcing $file"
#   uplevel ::original_source $file
#}


::source [file join [file dirname [info script]] log-procs.tcl]
::tws::sourceFile [file join [file dirname [info script]] package-procs.tcl]


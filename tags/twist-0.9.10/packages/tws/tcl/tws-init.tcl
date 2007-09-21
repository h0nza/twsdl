# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



# Package Procedures

::tws::sourceFile [file join [file dirname [info script]] util-init.tcl]
::tws::sourceFile [file join [file dirname [info script]] nvlist-init.tcl]

# Import Logging
namespace eval ::tws {
    namespace import ::tws::log::*
}

# Log Progress:
::tws::log Notice "tws-init.tcl finished loading util procs and init"

# Bootstrap Finished!!

::tws::log Notice "tws-init.tcl BOOTSTRAP FINISHED! Reading tws-local-conf.tcl"


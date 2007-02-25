# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::wsdl::bindings { }


# Load Bindings:
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-bindings-soap-procs.tcl"]]

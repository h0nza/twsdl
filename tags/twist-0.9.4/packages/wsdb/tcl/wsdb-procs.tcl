# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::wsdb:: { }
    
namespace eval ::wsdb::globalTypes {}

::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdb-schema-procs.tcl"]]
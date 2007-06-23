# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-doc-init.tcl"]]

foreach typeNamespace {tcl} {
    ::tws::sourceFile [file normalize [file join [file dirname [info script]] "../ns/ns-${typeNamespace}.tcl"]]
}


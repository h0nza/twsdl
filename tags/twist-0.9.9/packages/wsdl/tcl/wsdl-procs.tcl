# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# Transition Code,
# Source this file for testing purposes like this:
# source [file join [file dirname [info script]] wsdl-procs.tcl]


if {[namespace exists ::wsdl]} {
    namespace delete ::wsdl
}

namespace eval ::wsdl {

    variable Version 0.1
    variable Initialized 0
}


namespace eval ::wsdl::definitions {
    

    variable xmlSchemaNS 
    variable wsdlsoapNS
    variable wsdlhttpNS
    variable wsdlNS
    variable wsdlDefinitionsAttributeList
    variable attributeList [list]

    namespace import ::tws::log::log

    set xmlSchemaNS(prefix) xsd
    set xmlSchemaNS(namespace) "http://www.w3.org/2001/XMLSchema"
    set wsdlsoapNS(prefix) wsoap
    set wsdlsoapNS(namespace) "http://schemas.xmlsoap.org/wsdl/soap/"
    set wsdlhttpNS(prefix) whttp
    set wsdlhttpNS(namespace) "http://schemas.xmlsoap.org/wsdl/http/"
    set wsdlNS(prefix) wsdl
    set wsdlNS(namespace) "http://schemas.xmlsoap.org/wsdl/"

    foreach ns {xmlSchemaNS wsdlsoapNS wsdlhttpNS wsdlNS} {
	lappend attributeList xmlns:[set ${ns}(prefix)] [set ${ns}(namespace)]
    }

}


proc ::wsdl::new {targetNamespace {tnsPrefix tns} {attributeList {

    	xmlns:s1 "http://microsoft.com/wsdl/types/" 
	xmlns:http "http://schemas.xmlsoap.org/wsdl/http/" 
	xmlns:soap "http://schemas.xmlsoap.org/wsdl/soap/" 
	xmlns:s "http://www.w3.org/2001/XMLSchema" 
	xmlns:soapenc "http://schemas.xmlsoap.org/soap/encoding/" 
	xmlns:tm "http://microsoft.com/wsdl/mime/textMatching/" 
	xmlns:mime "http://schemas.xmlsoap.org/wsdl/mime/" 
	xmlns:wsdl "http://schemas.xmlsoap.org/wsdl/"
    }} } {

    namespace eval ::wsdl::${targetNamespace} { 

	variable Initialized 0
    }

    if {"$tnsPrefix" ne ""} {
	set tnsQName  [join [list xmlns ${tnsPrefix}] ":"]
    } else {
	set tnsQName  xmlns
    }

    lappend attributeList $tnsQName $targetNamespace
    lappend attributeList targetNamespace $targetNamespace

    namespace eval ::wsdl::${targetNamespace}::definitions \
	"[list variable Attributes $attributeList]"

    namespace eval ::wsdl::${targetNamespace}::definitions::types { }

}

proc ::wsdl::printChildren { { namespace ""} { depth 0} } {

    set result ""
    incr depth 
    foreach child [lsort [namespace children "$namespace"]] {
	append result "[string repeat " " "$depth"]$child\n"
	append result [::wsdl::printChildren "$child" "$depth"]
    }
    incr depth -1
    return $result
}


::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-doc-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-schema-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-types-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-messages-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-operations-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-porttypes-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-bindings-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-ports-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-services-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-server-procs.tcl"]]
::tws::sourceFile [file normalize [file join [file dirname [info script]] "wsdl-definitions-procs.tcl"]]

# Type Definitions Create Procedures:
foreach typeNamespace {tcl} {
    ::tws::sourceFile [file normalize [file join [file dirname [info script]] "../ns/ns-${typeNamespace}.tcl"]]
}

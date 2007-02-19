# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::wsdl::server {

    variable hostHeaderNames [list]
    namespace import ::tws::log::log

}

proc ::wsdl::server::new { 

    serverName 
    targetNamespace 
    args
} {

    namespace eval ::wsdb::servers { }
    namespace eval ::wsdb::servers::${serverName} {
	variable targetNamespace
	variable services 
	variable hostHeaderNames [list]
    }
    set ::wsdb::servers::${serverName}::targetNamespace $targetNamespace
    set ::wsdb::servers::${serverName}::services $args


}

proc ::wsdl::server::listen {

    serverName
} {

    # Find services:
    set services [set ::wsdb::servers::${serverName}::services]
    log Notice "listen services -> $services"

    foreach service "$services" {

	# find service ports
	set ports [set ::wsdb::services::${service}::ports]

	# find port address
	foreach port $ports {
	    set address [set ::wsdb::ports::${port}::address]
	    set binding [set ::wsdb::ports::${port}::binding]
	    ns_register_proc POST "$address" ::wsdl::server::accept [list $serverName $service $port $binding $address]
	    log Notice "::wsdl::server::listen registered [list $serverName $service $port $binding $address]"
	}
    }

}

proc ::wsdl::server::accept { why } {

    log Notice "Accepting Connection with $why"

    foreach {server service port binding address} $why {}

    # 0. Get POSTed Data:
    set headerSet [ns_conn headers]
    set length [ns_set iget $headerSet "Content-length"]
    set tmpFile [ns_tmpnam]
    set fp [ns_openexcl $tmpFile]
    fconfigure $fp -translation binary
    ns_conn copy 0 $length $fp
    close $fp
    
    # 0.1 Package File and Headers:
    set headerLength [ns_set size $headerSet]
    for {set i 0} {$i < $headerLength} {incr i} {
	lappend headers [ns_set key $headerSet $i] [ns_set value $headerSet $i]
    } 

    set requestID [::request::new $headers $tmpFile $why]

    # Note Binding
    log Notice "wsdl::server::accept binding = $binding"
    
    # 2. Let Binding handle the request

    set responseList [[set ::wsdb::bindings::${binding}::handleRequest] $requestID]
  
    ns_return [lindex $responseList 0] [lindex $responseList 1] [lindex $responseList 3]

}
    
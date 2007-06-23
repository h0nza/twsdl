set serverName [ns_queryget s]

set wsdbNamespace ::wsdb

# Check Server Exists:
if {![namespace exists ${wsdbNamespace}::servers::${serverName}]} {
    ns_return 200 text/plain "server $serverName does not exist"
    return -code return
}


# Get Services:
set serviceNames [set ${wsdbNamespace}::servers::${serverName}::services]
set targetNamespace [set ${wsdbNamespace}::servers::${serverName}::targetNamespace]

# Get Ports:
foreach serviceName $serviceNames {
    set ${serviceName}(ports) [set ${wsdbNamespace}::services::${serviceName}::ports]

}

# Since Ports are Abstract, build up the types section here and then handle binding.


# Create an Tcl XML Representation:
if {[namespace exists ::wsdb::definitions]} {
    namespace delete ::wsdb::definitions
}
namespace eval ::wsdb::definitions { }

set wsdlServerNamespace ::wsdb::definitions::${serverName}


namespace eval ${wsdlServerNamespace} { }

set wsdlDefNamespace ${wsdlServerNamespace}::definitions

namespace eval ${wsdlDefNamespace} {
    variable .PREFIX "wsdl"
    variable .ATTR
    variable .PARTS [list binding]
}

array set ${wsdlDefNamespace}::.ATTR [list \
					  xmlns:s "http://www.w3.org/2001/XMLSchema"\
					  xmlns:wsdl "http://schemas.xmlsoap.org/wsdl/"\
					  xmlns:soapenc "http://schemas.xmlsoap.org/soap/encoding/"\
					  xmlns:soap "http://schemas.xmlsoap.org/wsdl/soap/"\
					  xmlns:tns $targetNamespace\
					  targetNamespace $targetNamespace]


# Procedure creates Tcl representation of Port binding in WSDL:
proc ::wsdl::bindings::soap::documentLiteral::bindPort { 

    wsdlDefNamespace
    bindingName 
} {
    variable style
    variable use
    variable transport

    set portTypeName [set ::wsdb::bindings::${bindingName}::portTypeName]
    set portTypeNamespace [set ::wsdb::bindings::${bindingName}::portTypeNamespace]
    set soapActionMap [set ::wsdb::bindings::${bindingName}::soapActionMap]
    
    # wsdl:binding
    set wsdlBindingNamespace ${wsdlDefNamespace}::binding
    namespace eval $wsdlBindingNamespace {
	variable .PREFIX "wsdl"
	variable .ATTR
	variable .PARTS [list binding]

    }
    array set ${wsdlBindingNamespace}::.ATTR [list name $bindingName type tns:$portTypeName]

    # soap:binding
    set soapBindingNamespace ${wsdlBindingNamespace}::binding
    namespace eval ${soapBindingNamespace} {
	variable .PREFIX "soap"
	variable .ATTR
	variable .PARTS [list]
    }
    array set ${soapBindingNamespace}::.ATTR [list transport $transport style $style]

    # wsdl:operation
    set OperationIndex 0
    foreach {soapAction operation} $soapActionMap {
	::wsdl::bindings::soap::documentLiteral::bindOperation $wsdlBindingNamespace $portTypeNamespace $operation $OperationIndex $soapAction
	incr OperationIndex
    }

    
}

proc ::wsdl::bindings::soap::documentLiteral::bindOperation {

    wsdlBindingNamespace
    operationNS
    operationName
    operationIndex
    soapAction
} {
    variable style
    variable use
    variable transport

    set wsdlOperationNamespace ${wsdlBindingNamespace}::operation::$operationIndex
    lappend ${wsdlBindingNamespace}::.PARTS operation::$operationIndex

    # Look into operation
    namespace eval $wsdlOperationNamespace {
	variable .PREFIX "wsdl"
	variable .ATTR
	variable .PARTS [list operation]
    }
    array set ${wsdlOperationNamespace}::.ATTR [list name $operationName]
    
    # operation inputs, outputs and fault messages
    set operationMessages [set ::wsdb::operations::${operationNS}::${operationName}::messages]
    log Debug "bindOperation operationMessages: $operationMessages"
    foreach messageList $operationMessages {
	set message [lindex $messageList 0]
	namespace eval ${wsdlOperationNamespace}::operation {
	    variable .PREFIX "soap"
	    variable .ATTR
	    variable .PARTS [list]
	}
	array set ${wsdlOperationNamespace}::operation::.ATTR [list soapAction $soapAction style $style]
	
	namespace eval ${wsdlOperationNamespace}::$message {
	    variable .PREFIX "wsdl"
	    variable .ATTR
	    variable .PARTS [list body]
	}
	namespace eval ${wsdlOperationNamespace}::${message}::body {
	    variable .PREFIX "soap"
	    variable .ATTR
	    variable .PARTS [list]
	}
	array set ${wsdlOperationNamespace}::${message}::body::.ATTR [list use $use]

	lappend ${wsdlOperationNamespace}::.PARTS ${message}
    }


}


# Add Services:

set ServiceIndex 0
foreach serviceName $serviceNames {
    set wsdlServiceNamespace ${wsdlDefNamespace}::service::${ServiceIndex}
    lappend ${wsdlDefNamespace}::.PARTS service::${ServiceIndex}
    namespace eval  $wsdlServiceNamespace {
	variable .PREFIX "wsdl"
	variable .ATTR
	variable .PARTS [list]
	
    }
    set ${wsdlServiceNamespace}::.ATTR(name) $serviceName
    set PortIndex 0
    namespace eval ${wsdlServiceNamespace}::port { }
    foreach port [set ${wsdbNamespace}::services::${serviceName}::ports] {
	lappend ${wsdlServiceNamespace}::.PARTS port::${PortIndex}
	set wsdlPortNamespace ${wsdlServiceNamespace}::port::${PortIndex}
	ns_log Notice "wsdl.tcl creating ${wsdlPortNamespace} namespace"
	namespace eval ${wsdlPortNamespace} {
	    variable .PREFIX "wsdl"
	    variable .ATTR
	    variable .PARTS [list]
	}
	set ${wsdlPortNamespace}::.ATTR(name) $port
	set binding [set ${wsdbNamespace}::ports::${port}::binding]
	::wsdl::bindings::soap::documentLiteral::bindPort $wsdlDefNamespace $binding
	set ${wsdlPortNamespace}::.ATTR(binding) tns:[set ${wsdbNamespace}::ports::${port}::binding]

	set hostHeaderNames [set ::wsdb::servers::${serverName}::hostHeaderNames]
	set AddressIndex 0
	namespace eval ${wsdlPortNamespace}::address { }
	foreach hostHeaderName $hostHeaderNames {
	    set wsdlAddressNamespace ${wsdlPortNamespace}::address::$AddressIndex
	    lappend ${wsdlPortNamespace}::.PARTS address::$AddressIndex
	    namespace eval $wsdlAddressNamespace {
		variable .PREFIX "soap"
		variable .ATTR
		variable .PARTS [list]
	    }
	    set ${wsdlAddressNamespace}::.ATTR(location) http://${hostHeaderName}[set ${wsdbNamespace}::ports::${port}::address]
	    incr AddressIndex
	}
	incr PortIndex

    }

    incr ServiceIndex
}



ns_log Notice "wsdl.tcl done"
ns_log Notice "[::xml::instance::toXMLNS ${wsdlDefNamespace}]"

# Get Namespace Names as list:

#set namespaces [::inspect::showNamespace :: 9]

#append output "********** NAMESPACES ********"


#append output "[::inspect::formatList $namespaces [list depth ns] {
#<br>[string repeat "&nbsp;" [expr 9 - $depth]]<a href=ns.tcl?ns=$ns>$ns</a>}]"


ns_return 200 text/xml "<?xml version=\"1.0\" encoding=\"utf-8\"?>
[::xml::instance::toXMLNS ${wsdlDefNamespace}]"
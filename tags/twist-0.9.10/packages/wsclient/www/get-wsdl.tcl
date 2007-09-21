# Get wsdl file via network connection, parse into tcl structure



set url [ns_queryget url "http://api.google.com/GoogleSearch.wsdl"]



set result ""

# Cleanup from previous runs:
namespace eval ::wsclient {

    foreach child [namespace children] {
	namespace delete $child
    }
}

namespace delete ::wsclient 


# Define ::wsclient
namespace eval ::wsclient {

    variable services [list]
    variable schemaInitialized 0

}

proc ::wsclient::getWSDL {
    service
    url
} {

    if {[string match "https://*" "$url"]} {
	set result [ns_httpsget $url]
    } else {
	set result [ns_httpget $url]
    }
    
    # to dom doc
    dom parse $result wsdlDoc
    $wsdlDoc documentElement wsdlRoot

    set wsdlNS ::wsclient::${service}::wsdl
    set ::wsclient::${service}::definitions $result
    ::xml::instance::newXMLNS $wsdlNS [$wsdlRoot asList] "1"

    rename $wsdlDoc ""

    set ::wsclient::${service}::wsdlURL $url

    return $wsdlNS
}

proc ::wsclient::addService {
    serviceAlias
} {
    variable services
    if {[lsearch -exact $serviceAlias $services] > -1 } {
	return "1"
    }
    namespace eval ::wsclient::$serviceAlias {
        variable wsdlURL
	variable serviceName
	variable ports [list]
    }
    lappend service $serviceAlias
    
}

namespace eval ::wsclient::wsdl { }

proc ::wsclient::setServiceName {
    service
} {

    return [set ::wsclient::${service}::serviceName \
		[set ::wsclient::${service}::wsdl::definitions::service::.ATTRS(name)]];
}


# Convenience procs to get/set service variables:
proc ::wsclient::setVar {
    service
    variable
    value
} {

    set ::wsclient::${service}::${variable} $value

}

proc ::wsclient::lappendVar {
    service
    variable
    value
} {

    ns_log Notice "Lappending $service $variable $value"
    return [lappend ::wsclient::${service}::${variable} $value]

}



proc ::wsclient::getVar {
    service
    variable
} {

    return [set ::wsclient::${service}::${variable}]

}


proc ::wsclient::setArray {
    service
    arrayName
    NVList
} {

    return [array set ::wsclient::${service}::$arrayName $NVList]

}

# Ensure old values are removed from array
proc ::wsclient::replaceArray {
    service
    arrayName
    NVList
} {
    set arrayFullName ::wsclient::${service}::$arrayName

    if {[array exists $arrayFullName]} {
	array unset $arrayFullName
    }

    return [array set $arrayFullName $NVList]
}

proc ::wsclient::getArray {
    service
    arrayName
} {

    return [array get ::wsclient::${service}::$arrayName]

}



# Convenience proc to split prefix and element name
# tns:MyElement --> {tns MyElement}
proc ::wsclient::splitPrefixName {
    prefixName
} {
    
    set List [split $prefixName ":"]
    set Element [lindex $List end]
    if {[llength $List] == 1} {
	set Prefix ""
    } else {
	set Prefix [lindex $List 0]
    }
    return [list $Prefix $Element]
}

# Get first report (eventually get all?)
proc ::wsclient::setPorts {
    service
} {

    # Only does one port

    set portName [set ::wsclient::${service}::wsdl::definitions::service::port::.ATTRS(name)]

    set bindingType [set ::wsclient::${service}::wsdl::definitions::service::port::.ATTRS(binding)]

    set bindingList [::wsclient::splitPrefixName $bindingType]
    set binding [lindex $bindingList 1]
    set bindingPrefix [lindex $bindingList 0]

    lappendVar ${service} ports $portName

    namespace eval ::wsclient::${service}::ports::$portName {
	variable binding
	variable bindingPrefix
    }

    setVar ${service} ports::${portName}::location \
	[set ::wsclient::${service}::wsdl::definitions::service::port::address::.ATTRS(location)];

    setVar ${service} ports::${portName}::binding $binding
    setVar ${service} ports::${portName}::bindingPrefix $bindingPrefix
    return $portName
}

proc ::wsclient::getPortNames {
    service
} {
    return [getVar $service ports]
}

proc ::wsclient::getPortName {
    service
    {index 0}
} {
    return [lindex [getPortNames $service] $index]
}

proc ::wsclient::getBinding {
    service
    portName
} {
    return [getVar ${service} ports::${portName}::binding]
}

proc ::wsclient::getBindingPrefix {
    service
    portName
} {
    return [getVar ${service} ports::${portName}::bindingPrefix]
}

proc ::wsclient::getPortLocation {
    service
    portName
} {

    return [getVar $service ports::${portName}::location]
}


# Procs return the tclNamespace requested
proc ::xml::getChildElementRefByName {
    parentElement
    childElement
    {prefix *}
} {
    set ChildElementsList [set ${parentElement}::.PARTS]
    return [lsearch -inline -all $ChildElementsList [list $childElement $prefix *]]

}

# childRef = a element list {element prefix tclNamespace}
proc ::xml::normalizeElementRef {
    parentRef
    childRef
} {

    return [normalizeNamespace $parentRef [lindex $childRef 2]]

}

# childRefList = list of childRefs (see above)
proc ::xml::normalizeElementRefs {
    parentRef
    childRefList
} {
    set resultList [list]
    foreach childRef $childRefList {
	lappend resultList [normalizeElementRef $parentRef $childRef]
    }
    return $resultList
}


proc ::xml::getElementRefByAttrValue {
    parentElement
    childElement
    attributeName
    attributeValue
} {
    set resultList [list]
    foreach ChildElement [getChildElementRefByName $parentElement $childElement] {
	set tclPart [lindex $ChildElement 2]
	set fullPart [normalizeNamespace $parentElement ${tclPart}::.ATTRS($attributeName)]
	if {[info exists $fullPart]} {
	    if {"[set $fullPart]" eq "$attributeValue"} {
		lappend resultList [namespace qualifiers $fullPart]
	    }
	}
    }
    return $resultList

}

# Prepeds wsclient and service namespaces to input.
proc ::wsclient::normalizeRef {
    service
    tclPart
} {
    return [::xml::normalizeNamespace ::wsclient::${service} $tclPart]
}


# Get a tcl namespace reference for the WSDL binding element.
proc ::wsclient::findWSDLBindingRef {
    service
    binding
} {

    set parentElement [normalizeRef $service wsdl::definitions]
    return [::xml::getElementRefByAttrValue $parentElement binding name $binding]

}


proc ::wsclient::getSOAPBindingStyle {
    service
    binding
} {

    set parentElement [findWSDLBindingRef $service $binding]
    
    ::printit parentElement parentElement

    set soapBindElementRefList [::xml::getChildElementRefByName $parentElement binding]

    set soapBindElement [::xml::normalizeElementRef $parentElement [lindex $soapBindElementRefList 0]]

    return [set ${soapBindElement}::.ATTRS(style)]

}

proc ::wsclient::getSOAPBindingTransport {
    service
    binding
} {

    set parentElement [findWSDLBindingRef $service $binding]
    
    ::printit parentElement parentElement

    set soapBindElementRefList [::xml::getChildElementRefByName $parentElement binding]

    set soapBindElement [::xml::normalizeElementRef $parentElement [lindex $soapBindElementRefList 0]]

    return [set ${soapBindElement}::.ATTRS(transport)]

}



# Get tcl namespace for WSDL portType element
proc ::wsclient::findWSDLportTypeRef {
    service
    portType
} {
    set parentElement [normalizeRef $service wsdl::definitions]
    return [::xml::getElementRefByAttrValue $parentElement portType name $portType]
}
	    
proc xbasrerk { } {
namespace eval ::wsclient::schema {
    
    variable soapEnvelopeNS
    set soapEnvelopeNS(namespace) http://schemas.xmlsoap.org/soap/envelope/
    set soapEnvelopeNS(prefix) soap-env
    
    variable soapEncodingNS
    set soapEncodingNS(namespace) http://schemas.xmlsoap.org/soap/encoding/
    set soapEncodingNS(prefix) soap-enc
    
    variable wsdlNS
    set wsdlNS(namespace) http://schemas.xmlsoap.org/wsdl/
    set wsdlNS(prefix) wsdl
    
    variable wsdlsoapNS
    set wsdlsoapNS(namespace) http://schemas.xmlsoap.org/wsdl/soap/
    set wsdlsoapNS(prefix) wsoap
    
    variable xmlSchemaInstanceNS
    set xmlSchemaInstanceNS(namespace) http://www.w3.org/2001/XMLSchema-instance
    set xmlSchemaInstanceNS(prefix) xsi
    
    variable xmlSchemaNS
    set xmlSchemaNS(namespace) http://www.w3.org/2001/XMLSchema
    set xmlSchemaNS(prefix) xsd
    
}
    

proc ::wsclient::schema::getNamespace {
    schemaVar
} {

    set currentNS [namespace current]
    if {[array exists ${currentNS}::$schemaVar]} {
	variable $schemaVar
	return [set ${schemaVar}(namespace)]
    } else {
	return ""
    }

}
 
proc ::wsclient::schema::getSchemaAlias {
    schemaVar
} {

    set currentNS [namespace current]
    if {[array exists ${currentNS}::$schemaVar]} {
	variable $schemaVar
	return [set ${schemaVar}(prefix)]
    } else {
	return ""
    }

}
}




source [file join [file dirname [info script]] wsclient-2.tcl]


# Collect some general information about the service
proc ::wsclient::setWSDLDefinitionsAttrs {
    service
} {

    set schemaNS [normalizeRef $service schema]

    # Namespace for service schema map
    namespace eval $schemaNS {
	variable aliasMap [list]
    }

    set wsdlDefAttrArray [normalizeRef $service wsdl::definitions::.ATTRS]
    set wsdlNamespace [normalizeRef $service wsdl]

    

    set wsdlDefAttrs [array get $wsdlDefAttrArray]
    ns_log Debug "schemaNS = $schemaNS wsdlDefAttrArray = $wsdlDefAttrArray wsdlDefAttrs = $wsdlDefAttrs"
    foreach {attr value} $wsdlDefAttrs {
	switch -glob -- $attr {
	    "xmlns" {
		set ${wsdlNamespace}::defaultNamespace $value
	    }
	    "xmlns:*" {
		set prefixNameList [splitPrefixName $attr]
		lappend ${schemaNS}::aliasMap [list [lindex $prefixNameList 1] $value]
	    }
	    "name" {
		set ${wsdlNamespace}::name $value
		
	    }
	    "targetNamespace" {
		
		set ${wsdlNamespace}::targetNamespace $value
		
	    }
	    default {
		set ${wsdlNamespace}::$attr $value
	    }
	}
    }
    
    return 1
}



proc ::wsclient::getTypes {
    service
} {

    # Make array for elementRefs
    set elementRefArray [normalizeRef $service elementRef]

    set parentElement [normalizeRef $service wsdl::definitions]

    set typesChildren [::xml::getChildElementRefByName\
			   $parentElement types];
    set typesElement [::xml::normalizeElementRefs $parentElement $typesChildren]
    
    array set $elementRefArray [list types $typesElement];
    
    set schemaChildren [::xml::getChildElementRefByName\
			    $typesElement schema];
    set schemaElement [::xml::normalizeElementRefs $typesElement $schemaChildren]
 
    array set $elementRefArray [list schema $schemaElement]

    set simpleTypeChildren [::xml::getChildElementRefByName\
			    $schemaElement simpleType];

    set simpleTypeElements [::xml::normalizeElementRefs $schemaElement $simpleTypeChildren]

    array set $elementRefArray [list simpleTypes $simpleTypeElements]
}

set service "adsense"

::wsclient::addService $service

set wsdlNS [::wsclient::getWSDL $service $url]


set printed [::xml::instance::print2 ${wsdlNS}::definitions]

set ${wsdlNS}::definitions $printed

set Service(name) [::wsclient::setServiceName $service]
set PortNameList [::wsclient::setPorts $service]

set portIndex 0
set PortsText ""

######################################## PRINT DEBUGGING INFO #######

proc ::printit {
    varList
    notes
} {

    ns_log Notice "-->notes: $notes"
    foreach var $varList {
	upvar $var $var
	if {[info exists $var]} {
	    ns_log Notice "--> var $var = '[set $var]'"
	} elseif {[array exists $var]} {
	    ns_log Notice "--> Array $var = '[array get $var]'"
	} else {
	    ns_log Notice "--> var $var is not defined"
	}
    }
}

::printit service "WSDL Service Name"

::wsclient::setWSDLDefinitionsAttrs $service



::wsclient::getTypes $service


foreach PortName [::wsclient::getPortNames $service] {

    append PortsText "
 Port Binding $portIndex = '[set binding [::wsclient::getBinding $service $PortName]]'
 Port Location $portIndex = '[::wsclient::getPortLocation $service $PortName]'
 Binding Ref  $portIndex = '[set bindingRef [::wsclient::findWSDLBindingRef $service [::wsclient::getBinding $service $PortName]]]'"
    ::printit bindingRef "BindingRef"


    set wsoapStyle [::wsclient::getSOAPBindingStyle $service $binding]
    set wsoapTransport [::wsclient::getSOAPBindingTransport $service $binding]

    append PortsText "\n  wsoapStyle     = $wsoapStyle"
    append PortsText "\n  wsoapTransport = $wsoapTransport"
    incr portIndex
}












ns_return 200 text/html "
<h3>Namespace Code for ::wsclient::schema</h3>
 [::inspect::displayNamespaceCode ::wsclient::schema]
 [::inspect::displayProcs ::wsclient::schema]

<pre>
Arrays
Service = [array get Service]

PortNameList = '$PortNameList'

PortNamesFromProc = '[::wsclient::getPortNames $service]'

PortsText =
$PortsText

Set data from wsdl definitions attributes = [::wsclient::setWSDLDefinitionsAttrs $service]

</pre>










----------------------------
printed = 

$printed


result = $result
[::inspect::displayNamespaceChildren ::wsclient]
<h3>Namespace Code for ::wsclient</h3>
 [::inspect::displayNamespaceCode ::wsclient]
 [::inspect::displayProcs ::wsclient]
<h3>Namespace Code for ::wsclient::$service</h3>
 [::inspect::displayNamespaceCode ::wsclient::$service]
 [::inspect::displayProcs ::wsclient::$service]


"
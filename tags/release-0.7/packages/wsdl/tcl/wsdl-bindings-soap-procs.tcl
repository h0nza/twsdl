# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::wsdl::bindings::soap {

    variable xmlSchemaNS 
    variable xmlSchemaInstanceNS
    variable soapEnvelopeNS
    variable soapEnvelopeAttributes

    namespace import ::tws::log::log

    set xmlSchemaNS(prefix) xsd
    set xmlSchemaNS(namespace) "http://www.w3.org/2001/XMLSchema"
    set xmlSchemaInstanceNS(prefix) xsi
    set xmlSchemaInstanceNS(namespace) "http://www.w3.org/2001/XMLSchema-instance"
    set soapEnvelopeNS(prefix) soap-env
    set soapEnvelopeNS(namespace) "http://schemas.xmlsoap.org/soap/envelope/"

    set soapEnvelopeAttributes [list \
        xmlns:$xmlSchemaNS(prefix) $xmlSchemaNS(namespace) \
        xmlns:$xmlSchemaInstanceNS(prefix) $xmlSchemaInstanceNS(namespace) \
        xmlns:$soapEnvelopeNS(prefix) $soapEnvelopeNS(namespace)]
}



namespace eval ::wsdl::bindings::soap::documentLiteral {

    variable style "document"
    variable use "literal"
    variable transport "http://schemas.xmlsoap.org/soap/http"
    namespace import ::tws::log::log
}


proc ::wsdl::bindings::soap::documentLiteral::new {

    portTypeNamespace
    portTypeName
    bindingName
    args
} {

    namespace eval ::wsdb::bindings { }
    namespace eval ::wsdb::bindings::${bindingName} {
	variable portTypeNamespace
	variable portTypeName
	variable soapActionArray
	variable soapActionMap
	variable handleRequest
	namespace import ::tws::log::log
    }
    array set ::wsdb::bindings::${bindingName}::soapActionArray $args
    set ::wsdb::bindings::${bindingName}::soapActionMap $args
    set ::wsdb::bindings::${bindingName}::portTypeNamespace $portTypeNamespace
    set ::wsdb::bindings::${bindingName}::portTypeName $portTypeName

    proc ::wsdb::bindings::${bindingName}::HandleRequest {

	requestID
    } {
	variable soapActionArray
	variable portTypeName
	variable portTypeNamespace



	log Notice "HandleRequest Running............."
	# 1. Figure out what operation is being performed
	set requestNamespace ::request::$requestID

	# SOAP Envelope reference
	set soapEnvelope "${requestNamespace}::response::Envelope"

	# Get requestArgs
	foreach {serverName service port binding address} [set ${requestNamespace}::requestArgs] { }
	# Get requestHeaders
	array set requestHeaders [set ${requestNamespace}::requestHeaders]
	# Does SOAPAction Header exist?
	if {[info exists requestHeaders(SOAPAction)]} {
	    set SOAPAction [string trim $requestHeaders(SOAPAction) "\"'"]
	    if {[info exists soapActionArray($SOAPAction)]} {
		set operation  $soapActionArray($SOAPAction)
	    } else {
		set operation "SOAPAction Header doesn't correspond to Operation"
		log Error "HandleRequest SOAPAction = '$SOAPAction' $operation"
		# Should return an error here
	    }
	} else {
	    set operation "No SOAPAction Header Found..."
	}
	
	log Notice "HandleRequest operation = $operation"

	# Actual tcl namespace of operation 
	set operationNamespace "::wsdb::operations::${portTypeNamespace}::${operation}"
	log Notice "HandleRequest operationNamespace = $operationNamespace"
	log Notice "HandleRequest vars in ns: [info vars ${operationNamespace}::*]"


	# Do some XML Stuff:
	set requestFilename [set ${requestNamespace}::postFilename]
	set requestFD [open $requestFilename r]
	set requestXML [read $requestFD]
	close $requestFD
	# to dom doc
	dom parse $requestXML requestDoc
	$requestDoc documentElement requestRoot

	# Info on document:
	######### ENVELOPE ###########
	foreach nodeInfo {nodeName namespaceURI prefix localName childNodes} {
	    set envelope($nodeInfo) [$requestRoot $nodeInfo]
	    	log Debug "domNode $nodeInfo (Envelope) = '$envelope($nodeInfo)'"
	}
	
	# Check that the namespaceURI is correct
	if {"$envelope(namespaceURI)" ne "http://schemas.xmlsoap.org/soap/envelope/"} {
	    # Need to return error 
	    log Error "HandleRequest: VersionMismatch on SOAP Envelope id:$requestID"

	    set soapFault [::wsdl::bindings::soap::createFault ${requestNamespace}::response]

	    ::wsdl::bindings::soap::appendFaultDetails $soapFault VersionMismatch {
   SOAP Envelope Version Mismatch: 
   Correct SOAP Version is http://schemas.xmlsoap.org/soap/envelope/}

	    return [list 400 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]
	} 
	# Check Element localname is Envelope
	if {"$envelope(localName)" ne "Envelope"} {
	    # Need to return error
	    log Error "HandleRequest documentElement not SOAP Envelope for $requestID"

	    set soapFault [::wsdl::bindings::soap::createFault ${requestNamespace}::response]
	    ::wsdl::bindings::soap::appendFaultDetails $soapFault Client {Root element was not Envelope}

	    return [list 400 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]
	}

	########### BODY ############
	# Check Envelope children
	set envelope(childCount) [llength $envelope(childNodes)]

	if {"$envelope(childCount)" > 2 
	    || "$envelope(childCount)" < 1} {
	    # Error
	    log Error "HandleRequest SOAP Envelope $envelope(childCount) children"
	    set soapFault [::wsdl::bindings::soap::createFault ${requestNamespace}::response]
	    ::wsdl::bindings::soap::appendFaultDetails $soapFault Client "Incorrect number of children 
 in SOAP Envelope: $envelope(childCount) children"

	    return [list 400 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]
	    
	}
	if {"$envelope(childCount)" == 2 } {
	    # Handle Header
	}
	if  {"$envelope(childCount)" == 1 } {
	    set BodyNode [lindex $envelope(childNodes) 0]
	    foreach nodeInfo {nodeName namespaceURI prefix localName childNodes} {
		set body($nodeInfo) [$BodyNode $nodeInfo]
	    	log Debug "domNode (Body) $nodeInfo = '$body($nodeInfo)'"
	    }
	}
	
	########### BODY CONTENT ##########
	set body(childCount) [llength $body(childNodes)]
	if {"$body(childCount)" != 1} {
	    # Error
	    log Error "HandleRequest SOAP Body incorrect Child Node Count"
	    set soapFault [::wsdl::bindings::soap::createFault ${requestNamespace}::response]
	    ::wsdl::bindings::soap::appendFaultDetails $soapFault Client "Incorrect number of children 
 in SOAP Body: $body(childCount) children"

	    return [list 400 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]  
	}

	set DocumentNode [lindex $body(childNodes) 0]
	foreach nodeInfo {nodeName namespaceURI prefix localName} {
	    set document($nodeInfo) [$DocumentNode $nodeInfo]
	    log Debug "domNode $nodeInfo (Document) = '$document($nodeInfo)'"
	}
	
	# Convert to internal format:
	set instanceNS "${requestNamespace}::input"

	::xml::instance::newXMLNS $instanceNS [$DocumentNode asList] "1"
	set XMLdocumentElementList [namespace children $instanceNS]

	if {[llength $XMLdocumentElementList] != 1} {
	    # Need to return error here
	} else {
	    set XMLdocumentElement [lindex $XMLdocumentElementList 0]
	}
	
	log Notice "HandleRequest request children: [namespace children $instanceNS]"
	log Notice "HandleRequest XML = [::xml::instance::toXMLNS $XMLdocumentElement]"
	# tDom doc is gone:
	# This may not be necessary:
	rename $requestDoc ""

	# Check document has correct targetNamespace for service
	set targetNamespace [set ::wsdb::servers::${serverName}::targetNamespace]
	if {![::xml::instance::checkXMLNS $XMLdocumentElement $targetNamespace]} {
	    log Error "HandleRequest incorrect request namespace " 
	    set soapFault [::wsdl::bindings::soap::createFault ${requestNamespace}::response]
	    ::wsdl::bindings::soap::appendFaultDetails $soapFault Client "Incorrect targetNamespace
  for WSDL service, should be $targetNamespace"

	    return [list 400 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]
	} else {
	    log Debug "HandleRequest correct request namespace '$targetNamespace'"
	}


	# Check document type is valid
	# Document is input message, so we need to find that signature
	set inputMessageType [::wsdl::operations::getInputMessageType $portTypeNamespace $operation]
	
	if {"$inputMessageType" eq ""} {
	    # Return Error Here...
	    log Error "HandleRequest inputMessageType Not found for $portTypeNamespace $operation"
	}
	log Debug "HandleRequest: validating messageType '${inputMessageType}'"
	log Debug "HandleRequest: validating with '::wsdb::elements::${portTypeNamespace}::${inputMessageType}::validate'"
	if {![[set ::wsdb::elements::${portTypeNamespace}::${inputMessageType}::validate] $XMLdocumentElement]} {
	    log Error "HandleRequest input document invalid"

	    # Return Error for fault...How?
	    set soapFault [::wsdl::bindings::soap::createFault ${requestNamespace}::response]
	    ::wsdl::bindings::soap::appendFaultDetails $soapFault Client "Invalid Document" \
		"[::xml::instance::printErrors $XMLdocumentElement 5]"

	    return [list 400 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]
	}
	log Debug "HandleRequest: invoking '[set ::wsdb::operations::${portTypeNamespace}::${operation}::invoke]'"
	# Document is valid...Invoke command
	set responseMessage [[set ::wsdb::operations::${portTypeNamespace}::${operation}::invoke] \
			       "$XMLdocumentElement" "${requestNamespace}::output"]
	
	# Set default namespace on message
	::xml::element::setAttribute "$responseMessage" "xmlns" "$targetNamespace"

	# Create response document
	set soapBody [::wsdl::bindings::soap::createBody ${requestNamespace}::response ]

	# append a reference to responseMessage to SOAP Body
	::xml::element::appendRef $soapBody $responseMessage

	# Going to return a list {status content-type headersList document}

	# return what?

	return [list 200 "text/xml" {} [::xml::document::print ${requestNamespace}::response]]
    }

    namespace eval ::wsdb::bindings::${bindingName} {
	set handleRequest [namespace code {HandleRequest}]
    }

}

proc ::wsdl::bindings::soap::createBody { 
    tclNamespace
} {
    variable soapEnvelopeAttributes
    variable soapEnvelopeNS
    log Notice "Creating SOAP Body............ "
    set soapPrefix $soapEnvelopeNS(prefix)
    set soapEnvelope [::xml::document::create ${tclNamespace} Envelope \
         $soapPrefix $soapEnvelopeAttributes]

    set soapBody [::xml::element::append $soapEnvelope Body $soapPrefix]
    log Notice "Created SOAP Body..........."
    return $soapBody
    
}


proc ::wsdl::bindings::soap::createFault { 
    tclNamespace
} {
    variable soapEnvelopeNS

    log Notice "Creating SOAP Body with tclNamespace = $tclNamespace"
    set soapBody [::wsdl::bindings::soap::createBody $tclNamespace]
    set soapPrefix $soapEnvelopeNS(prefix)

    set soapFault [::xml::element::append $soapBody Fault $soapPrefix]

    return $soapFault

}

proc ::wsdl::bindings::soap::appendFaultDetails {
    soapFaultNamespace
    faultcode
    faultstring
    {details {}}
} {

    ::xml::element::appendText [::xml::element::append $soapFaultNamespace faultcode] .TEXT $faultcode
    ::xml::element::appendText [::xml::element::append $soapFaultNamespace faultstring] .TEXT $faultstring

    if {$details ne ""} {
	::xml::element::appendText [::xml::element::append $soapFaultNamespace details] .TEXT $details
    }
    return $soapFaultNamespace
}

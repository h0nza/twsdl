
# Tcl Location:
namespace eval ::wsdb::definitions { }

proc ::wsdl::definitions::new {
    serverName
} {
    variable attributeList
    variable wsdlNS
    variable wsdlsoapNS
    variable xmlSchemaNS
    set serviceNames [set ::wsdb::servers::${serverName}::services]
    set targetNamespace [set ::wsdb::servers::${serverName}::targetNamespace]
    set tnsAlias [::wsdb::schema::getAlias $targetNamespace]
    if {"$tnsAlias" eq ""} {
	log Error "tnsAlias not found for targetNamespace = '$targetNamespace'"
    }


    # Get Ports:
    foreach serviceName $serviceNames {
	set ${serviceName}(ports) [set ::wsdb::services::${serviceName}::ports]

    }
 
    # Get beginning attributeList for wsdl:definitions
    set attributes $attributeList
    lappend attributes "targetNamespace" "$targetNamespace"
    lappend attributes "xmlns:tns" "$targetNamespace"

    # WSDL Document is constructed so that information which appears
    # at the bottom of the document determines what appears at the top
    # In addition, the order of child elements of wsdl:definitions is 
    # fixed.
    # The tWSDL API is setup to construct a document from top down.
    # To handle these two opposing issues, the order of elements will
    # be 'fixed' after the wsdl document is complete.
    # In other words: ignore the effects of ::xml::element::append
    # on determining the order elements will appear in the final doc.

    # Create WSDL Definitions Element:
    set wsdlDefElement [::xml::document::create ::wsdb::definitions::$serverName \
			    definitions \
			    $wsdlNS(prefix) \
			    $attributes ]

    # Append Types Element to be filled later on:
    set wsdlTypesElement [::xml::element::append $wsdlDefElement types $wsdlNS(prefix)]

				  
    # Only One Service is Supported:
    set serviceName [lindex $serviceNames 0]

    # Append Service Element:
    set wsdlServiceElementRef [::xml::element::append ${wsdlDefElement} service \
				   $wsdlNS(prefix) \
				   [list name $serviceName]];

 
    # Add ports to service:
    # Create list of portTypeNames
    set portTypeNames [list]
    foreach Port [set ::wsdb::services::${serviceName}::ports] {
	
	set bindingName [set ::wsdb::ports::${Port}::binding]

	set portTypeName [set ::wsdb::bindings::${bindingName}::portTypeName]
	if {[lsearch -exact $portTypeNames $portTypeName] == -1} {
	    lappend portTypeNames $portTypeName
	}

	set wsdlPortElement [::xml::element::append $wsdlServiceElementRef port \
				 $wsdlNS(prefix) \
				 [list name $Port binding "tns:$bindingName"]];

	set hostHeaderNames [set ::wsdb::servers::${serverName}::hostHeaderNames]
	foreach hostHeaderName $hostHeaderNames {
	    set location "http://${hostHeaderName}[set ::wsdb::ports::${Port}::address]"
	    ::xml::element::append $wsdlPortElement address $wsdlsoapNS(prefix) \
		[list location $location];

	}

	# Bind port
	# Needs to be replaced with optional binding:
	
	::wsdl::bindings::soap::documentLiteral::bindPort $wsdlDefElement $bindingName  
    }

    # Add portTypes
    
    # Collect messageTypeNames
    set messageTypeNamesList [list]

    foreach portTypeName [concat $portTypeNames] {
	log Debug "-------- portTypeName = $portTypeName"
	set portTypeElement [::xml::element::append $wsdlDefElement portType $wsdlNS(prefix) \
				 [list name $portTypeName]];

	foreach portOperationName [set ::wsdb::portTypes::${tnsAlias}::${portTypeName}::operations] {
	    log Debug "--------- portOperationName = '$portOperationName'"
	    set wsdlOperationElement [::xml::element::append $portTypeElement operation $wsdlNS(prefix) \
					  [list name $portOperationName]];
	    foreach messageTypeList [set ::wsdb::operations::${tnsAlias}::${portOperationName}::messages] {
		set messageType [lindex $messageTypeList 0]
		set messageTypeName [lindex $messageTypeList 1]
		if {[lsearch -exact $messageTypeNamesList $messageTypeName] == -1} {
		    lappend messageTypeNamesList $messageTypeName
		    log Debug "..........Adding messagetypename = '$messageTypeName' list = '$messageTypeNamesList'"
		}
		log Debug "messageType = $messageType  messageTypeName = $messageTypeName"
		::xml::element::append $wsdlOperationElement $messageType  $wsdlNS(prefix) \
		    [list message "tns:$messageTypeName"];

	    }
	}
    }
    
    # Add Messages:
    log Debug "...>>> messageTypeNamesList = '$messageTypeNamesList'"
    # Keep track of used types (elements)
    set messageTypeElementNames [list]

    foreach messageTypeName $messageTypeNamesList {
	log Debug "..!!!!>>> messageTypeName = '$messageTypeName'"
	set messageTypeElementName [set ::wsdb::messages::${tnsAlias}::${messageTypeName}::Parts]
	set wsdlMessageElement [::xml::element::append $wsdlDefElement message $wsdlNS(prefix) \
				    [list name $messageTypeName]];
	::xml::element::append $wsdlMessageElement part $wsdlNS(prefix) \
	    [list name parameters element "tns:$messageTypeElementName"];

	if {[lsearch -exact $messageTypeElementNames $messageTypeElementName] == -1} {
	    lappend messageTypeElementNames $messageTypeElementName
	}
    }

    # Add Element Types.
    # Use ::wsdb::schema
    
    set typesSchemaElement [::xml::element::append $wsdlTypesElement schema $xmlSchemaNS(prefix) \
				[list elementFormDefault "qualified" targetNamespace "$targetNamespace"]];
    
    foreach schemaItem [set ::wsdb::schema::${tnsAlias}::schemaItems] {
	set schemaItemType [set ::wsdb::schema::${tnsAlias}::${schemaItem}::type] 
	if {"$schemaItemType" ne "sequence"} {
	    set schemaItemBase [set ::wsdb::schema::${tnsAlias}::${schemaItem}::base]
	    
	    set baseAlias [set ::wsdb::schema::${tnsAlias}::${schemaItem}::baseAlias]
	    if {[string match "elements::*" "$baseAlias"]} {
		set baseAlias [namespace tail $baseAlias]
	    }
	    # IS this useful?
	    set baseTargetNamespace [::wsdb::schema::getTargetNamespace $baseAlias]
	    if {"$baseTargetNamespace" eq "http://www.w3.org/2001/XMLSchema"} {
		set xmlSchemaType 1
	    } else {
		set xmlSchemaType 0
	    }
	} else {
	    set baseTargetNamespace $targetNamespace
	}
	
	# At some point, we may import schema items (so that we can keep them in separate
        # namespaces) For now we need to derive them all from xsd. So baseAlias should
        # either be xsd or the alias for the service schema types. 
        # If so, set baseAlias  to the string tns.

	if {"$baseTargetNamespace" eq "$targetNamespace"} {
	    set baseAlias "tns"
        }

	switch -exact "$schemaItemType" {
	    "simple" {
		# stopped here
		set simpleTypeElement [::xml::element::append $typesSchemaElement simpleType \
					   $xmlSchemaNS(prefix) [list name "$schemaItem"]];
		::xml::element::append $simpleTypeElement restriction $xmlSchemaNS(prefix) \
		    [list base "${baseAlias}:${schemaItemBase}"];

	    }
	    "decimal" - "string" {
		set simpleTypeElement [::xml::element::append $typesSchemaElement simpleType \
					   $xmlSchemaNS(prefix) [list name "$schemaItem"]];
		set restrictionElement [::xml::element::append $simpleTypeElement restriction $xmlSchemaNS(prefix) \
					    [list base "${baseAlias}:${schemaItemBase}"]];
		set rData [set ::wsdb::schema::${tnsAlias}::${schemaItem}::data]

		foreach {rElement rValue} $rData {

		    ::xml::element::append $restrictionElement $rElement $xmlSchemaNS(prefix) \
			[list value $rValue];

		}
	    }
	    "enumeration" {
		set simpleTypeElement [::xml::element::append $typesSchemaElement simpleType \
					   $xmlSchemaNS(prefix) [list name "$schemaItem"]];	
		set restrictionElement [::xml::element::append $simpleTypeElement restriction $xmlSchemaNS(prefix) \
					    [list base "${baseAlias}:${schemaItemBase}"]];
		set enumerationData [set ::wsdb::schema::${tnsAlias}::${schemaItem}::data]

		foreach enumerationItem $enumerationData {
		    ::xml::element::append $restrictionElement enumeration $xmlSchemaNS(prefix) \
			[list value "$enumerationItem"];

		}

	    }
	    "pattern" {
		# Not done yet
		set simpleTypeElement [::xml::element::append $typesSchemaElement simpleType \
					   $xmlSchemaNS(prefix) [list name "$schemaItem"]];
		set restrictionElement [::xml::element::append $simpleTypeElement \
					    restriction $xmlSchemaNS(prefix) \
					    [list base "${baseAlias}:${schemaItemBase}"]];
		set patternData [set ::wsdb::schema::${tnsAlias}::${schemaItem}::data]
		::xml::element::append $restrictionElement pattern $xmlSchemaNS(prefix) \
		    [list value $patternData];

	    }
	    "sequence" {
		set complexTypeElement [::xml::element::append $typesSchemaElement complexType \
					    $xmlSchemaNS(prefix) [list name $schemaItem]];
		set sequenceElement [::xml::element::append $complexTypeElement sequence $xmlSchemaNS(prefix)]
		set childList [set ::wsdb::schema::${tnsAlias}::${schemaItem}::childList]
		foreach childItem $childList {
		    set childItemBase [set ::wsdb::schema::${tnsAlias}::${schemaItem}::${childItem}::base]
		    set childItemAlias [set ::wsdb::schema::${tnsAlias}::${schemaItem}::${childItem}::baseAlias]
		    set childAttributes [array get ::wsdb::schema::${tnsAlias}::${schemaItem}::${childItem}::.ATTR]
		    if {[string match "elements::*" "$childItemAlias"]} {
			set childItemAlias [namespace tail $childItemAlias]
		    }
		    # if type is in targetNamespace, change the alias to 'tns'
		    if {"$childItemAlias" eq "$tnsAlias"} {
			set childItemType "tns:${childItemBase}"
		    } else {
			set childItemType "${childItemAlias}:${childItemBase}"
		    }
		    lappend childAttributes name $childItem
		    lappend childAttributes type $childItemType
		    ::xml::element::append $sequenceElement element $xmlSchemaNS(prefix) $childAttributes
		}
	    }
	}

	# End Switch
    }
    # Append Global Elements Corresponding to Messages
    foreach messageTypeElementName $messageTypeElementNames {
	set messageTypeElement [::xml::element::append $typesSchemaElement element $xmlSchemaNS(prefix) \
				    [list name "$messageTypeElementName" type "tns:$messageTypeElementName"]];
    }

    # Do Last:
    # Note that we have to rearrange the order of the elements (very ugly, sorry)
    set allDefChildren [set ${wsdlDefElement}::.PARTS]

    # These elements are not sorted, and don't need to be
    set sortedTypes     [lsearch -all -inline $allDefChildren [list types * *]]
    set sortedMessages  [lsearch -all -inline $allDefChildren [list message * *]]
    set sortedBindings  [lsearch -all -inline $allDefChildren [list binding * *]]
    set sortedPortTypes [lsearch -all -inline $allDefChildren [list portType * *]]
    set sortedServices  [lsearch -all -inline $allDefChildren [list service * *]]

    set ${wsdlDefElement}::.PARTS [concat $sortedTypes $sortedMessages $sortedPortTypes $sortedBindings $sortedServices]

    return $wsdlDefElement
}



# Procedure creates Tcl representation of Port binding in WSDL:
proc ::wsdl::bindings::soap::documentLiteral::bindPort { 

    wsdlDefElement
    bindingName 
} {
    variable style
    variable use
    variable transport


    set portTypeName [set ::wsdb::bindings::${bindingName}::portTypeName]

    set wsdlBindElement [::xml::element::append $wsdlDefElement binding $::wsdl::definitions::wsdlNS(prefix) \
			     [list name $bindingName type "tns:$portTypeName"]];

    ::xml::element::append $wsdlBindElement binding $::wsdl::definitions::wsdlsoapNS(prefix) \
	[list transport $transport style $style];

    ::wsdl::bindings::soap::documentLiteral::bindOperation $wsdlBindElement $bindingName
}

proc ::wsdl::bindings::soap::documentLiteral::bindOperation {
    wsdlBindElement
    bindingName							     
} {
    variable style
    variable use
    variable transport

    set soapActionMap [set ::wsdb::bindings::${bindingName}::soapActionMap]
    set portTypeNamespace [set ::wsdb::bindings::${bindingName}::portTypeNamespace]

    foreach {soapAction operationName} $soapActionMap {
	set wsdlOperationElement [::xml::element::append $wsdlBindElement \
				      operation $::wsdl::definitions::wsdlNS(prefix) \
				      [list name $operationName]];
	::xml::element::append $wsdlOperationElement \
	    operation $::wsdl::definitions::wsdlsoapNS(prefix) \
	    [list soapAction $soapAction style $style];
	
	foreach operationMessageList [set ::wsdb::operations::${portTypeNamespace}::${operationName}::messages] {
	    set messageType [lindex $operationMessageList 0]
	    set wsdlMessageElement [::xml::element::append $wsdlOperationElement \
					$messageType $::wsdl::definitions::wsdlNS(prefix)];
	    ::xml::element::append $wsdlMessageElement body $::wsdl::definitions::wsdlsoapNS(prefix) \
		[list use $use];
	}

    }

}

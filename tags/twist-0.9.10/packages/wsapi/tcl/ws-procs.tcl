# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

# potential webservice interface layer:

proc ::<ws>log { level args } {

    return [::tws::log::log $level [join $args " "]]
}

proc ::<ws>return {tclNamespace} {

    set method [string toupper [ns_conn method]]

    switch -exact -- "$method" {
	"GET" {

	    set query [ns_conn query]
	    set url [<ws>namespace set $tclNamespace url]
	    set operation [ns_queryget op ""]

	    if {"$query" eq "WSDL" } {
		set mode "wsdl"
	    } else {
		set mode [string tolower [ns_queryget mode ""]]
	    }
	    
	    switch -exact -- "$mode" {
		"wsdl" {
                    namespace eval $tclNamespace {
		        set definitions [xml::document::print ::wsdb::definitions::${serverName}] 
		        ns_return 200 text/xml $definitions
		    }
		}
		"display" - "execute" {
		    
		    if {"$operation" eq ""} {
			ns_return 200 text/html "No Operation identified. Try <a href=\"$url\">Service Operations</a><br>
<pre>query = $query</pre> "
		    }
		    # Operation Display Details
		    # POST (Request)
		    # Messages
		    set xmlPrefix [<ws>namespace set $tclNamespace xmlPrefix]
		    set binding [<ws>namespace set $tclNamespace binding]
		    set bindingName [<ws>namespace set $tclNamespace bindingName]

		    <ws>log Debug "xmlPrefix = '$xmlPrefix operation = '$operation'"

		    set messages [set ::wsdb::operations::${xmlPrefix}::${operation}::messages]
		    set inputMessageType [::wsdl::operations::getInputMessageType $xmlPrefix $operation]
		    set inputMessageConv [set ::wsdb::operations::${xmlPrefix}::${operation}::conversionList]
		    set inputMessageSignature [list]
                    set inputFormElements ""
		    set elementIndex 0
		    set missing 0
		    set missingIndexList [list]
		    foreach {element type} $inputMessageConv {
			if {"[set ${inputMessageType}.$element "[ns_queryget ${inputMessageType}.$element ""]"]" eq ""} {

			    lappend inputMessageSignature "$type"
			    if {[set ::wsdb::elements::${xmlPrefix}::${inputMessageType}::MinOccurs($element)] > 0} {

                                <ws>log Debug ".........missing element $element"
				incr missing
			    } else {
				lappend missingIndexList $elementIndex
			    }
			} else {
			    lappend inputMessageSignature [set ${inputMessageType}.$element]
			}
			
			append inputFormElements "
<tr>
<td>${inputMessageType}.$element</td>
<td><input type=\"text\" name=\"${inputMessageType}.$element\" value=\"[set ${inputMessageType}.$element]\" >
</td>
</tr>"
			incr elementIndex
		    }
		    set requestID [::request::new "" "" ""]
		    set requestNamespace ::request::$requestID
		    set soapEnvelope "${requestNamespace}::request::Envelope"
		    set inputXMLNS ${requestNamespace}::input
		    if {[llength $inputMessageSignature] < 2} {
			set inputMessageSignature [lindex $inputMessageSignature 0]
		    }
		    if {$missing == 0 && [llength $missingIndexList] > 0} {
			# Replace missing elements with empty string in case minOccurs = 0 for element
			foreach missingIndex $missingIndexList {
			    lset inputMessageSignature $missingIndex ""
			}
		    }
		    
		    <ws>log Debug "<ws>return inputMessageSignature = '$inputMessageSignature'"
		    set inputElement [::wsdb::elements::${xmlPrefix}::${inputMessageType}::new $inputXMLNS "$inputMessageSignature"]
		    set targetNamespace [<ws>namespace set $tclNamespace targetNamespace]
		    ::xml::element::setAttribute $inputElement "xmlns" $targetNamespace
		    set soapBody [::wsdl::bindings::soap::createBody ${requestNamespace}::request ]
		    ::xml::element::appendRef $soapBody $inputElement

		    set returnBody [::xml::document::print ${requestNamespace}::request]
		    set SOAPActionMap [set ::wsdb::bindings::${bindingName}::soapActionMap]
		    set SOAPAction ""
		    foreach {soapAction opName} $SOAPActionMap  {
			if {"$opName" eq "$operation"} {
			    set SOAPAction $soapAction
			    break
			} 
		    }
		    set length [string length $returnBody]
		    set host [<ws>namespace set $tclNamespace host]
		    set port [<ws>namespace set $tclNamespace port]
		    set protocol [<ws>namespace set $tclNamespace protocol]
		    set hostHeader [<ws>namespace set $tclNamespace hostHeader]
		    # Copy any cookie headers
		    set cookieList [list]
		    set headerSet  [ns_conn headers]
		    set headerSize [ns_set size $headerSet]
		    for {set i 0} {$i < $headerSize} {incr i} {
			set headerName [ns_set key $headerSet $i]
			if {[lsearch -exact {cookie cookie2} [string tolower $headerName]] > -1} {
			    lappend cookieList "${headerName}: [ns_set value $headerSet $i]"
			}
			
		    }
		    if {[llength $cookieList]} {
			set cookies "\n[join $cookieList "\n"]"
		    } else {
			set cookies ""
		    }
		    set Request "POST $url HTTP/1.1
Host: $hostHeader$cookies
Content-Type: text/xml; charset=utf-8
Content-Length: $length
SOAPAction: \"$SOAPAction\"

$returnBody
"

                    if {$missing == 0} {

                        set sock [socket $host $port]
                        fconfigure $sock -translation binary

                        puts $sock $Request

                        flush $sock

                        set result [read $sock]

                        close $sock

                    } else {
                        set result "No Result"
                    }

                    ns_return 200 text/html "<pre>[ns_quotehtml $Request]</pre>
<h3>Result (if any):</h3>
<pre>[ns_quotehtml $result]</pre>
<h3>Send Request Message</h3>
<form action=\"$url\" method=\"get\">
<input type=\"hidden\" name=\"op\" value=\"$operation\">
<input type=\"hidden\" name=\"mode\" value=\"execute\">
<table border=\"1\">
$inputFormElements
<tr>
<th colspan=\"2\"><input type=\"submit\" value=\"Send $inputMessageType\"></th>
</tr>
</table>
</form>	"
	    
                }
	        "" {
		    # Return list of operations
                    set operationLinks ""
		    foreach operation [set ${tclNamespace}::operations] {
		        append operationLinks "<li><a href=\"$url?op=$operation&mode=display\">$operation</a></li><br>\n"
		    }
		    set header "
The following operations are supported. For a formal definition, please review the <a href=\"$url?WSDL\">Service Description</a>.
<br>
<ul>
$operationLinks
</ul>"
		    # Provide documentation for this web service
                    set showDocument [<ws>namespace set $tclNamespace showDocument] 

		    set ns [ns_queryget ns $tclNamespace]
		    set validDocNamespace 0
		    foreach {component docNamespace} [set ${tclNamespace}::documentLinks] {
			if {[string match ${docNamespace}* "$ns"]} {
			    set validDocNamespace 1
			    break
			}
		    }
		    if {$showDocument} {
			set wsAlias [namespace tail $tclNamespace]
			set wsLinks [::inspect::formatList\
					 [set ${wsAlias}::documentLinks] {type ns}\
					 "<li><a href=\"?ws=$wsAlias&ns=\$ns\">\$type</a></li>\n"]

	                ns_return 200 text/html "$header
<h3>Web Service Links</h3>
<ul>
$wsLinks
</ul>
[::inspect::displayNamespaceChildren $ns]
<h3>Namespace Code for $ns</h3>
[::inspect::displayNamespaceCode $ns ]
[::inspect::displayProcs $ns]

"
                        return -code return
                   } else {
                        ns_return 200 text/html $header
                        return -code return
                   }
	        }
            }
	}
	"POST" {
	    namespace eval $tclNamespace {
		::wsdl::server::accept [list $serverName $serviceName $portName $bindingName $url] 
	    }
	}
    }
}


proc ::<ws>namespace {
    subcmd 
    tclNamespace
    args
} {
    # Allow Freezing webservice
    switch -exact -- "$subcmd" {
	"exists" {
	    return [namespace exists $tclNamespace]

	}
	"isFrozen" {
	    if {[info exists ${tclNamespace}::frozen] && [set ${tclNamespace}::frozen] == 1} {
		return 1
	    } else {
		return 0
	    }
	}   
	"freeze" {
	    namespace eval $tclNamespace {
		variable frozen 1
	    }
	    return 1
	}
	"unfreeze" {
	    namespace eval $tclNamespace {
		variable frozen 0
	    }
	    return 0
	}

    }

    # still return values of variables:
    if {"$subcmd" eq "set" && [llength $args] == 1} {
	return [set ${tclNamespace}::[lindex $args 0]]
    }

    if {[<ws>namespace isFrozen $tclNamespace]} {
	return 1
    }

    switch -exact -- "$subcmd" {
	"init" {
	    # eventually must add check to delete prior namespace and wsdb code
	    # also might put in variable to freeze additional changes (better word?)
	    # this 'freeze' would operate in <ws>proc as well to silently abort and log event
	    namespace eval $tclNamespace {
		# re/set initial values
		variable tclNamespace [namespace current] 
		variable targetNamespace [string trimright "urn:tcl[string map {:: :} $tclNamespace]" ":"]
		variable xmlPrefix [namespace tail $tclNamespace]
		variable operations [list]
		variable binding "soap::documentLiteral"
		variable portType ${xmlPrefix}PortType
		variable bindingName ${xmlPrefix}SoapBind
		variable soapActionBase
		variable portName ${xmlPrefix}Port
		variable serviceName ${xmlPrefix}Service
		variable serverName ${xmlPrefix}Server
		variable frozen 0
		variable protocol
		variable hostHeader
		variable host
		variable port
                variable url
		variable schemaIsInitialized 0
		variable types
                variable elements
		variable documentLinks [list]
		variable showDocument 1

		if {[ns_conn isconnected]} {
		    if {"[ns_conn driver]" eq "nssock"} {
			set protocol http
		    } else {
			set protocol https
		    }
		    set hostHeader [ns_set iget [ns_conn headers] host]
		    set hostHeaderList [split $hostHeader ":"]
		    if {[llength $hostHeaderList] == 2} {
			set host [lindex $hostHeaderList 0]
			set port [lindex $hostHeaderList 1]
		    } else {
			set host $hostHeader
			set port 80
		    }
		    set host [lindex [split $hostHeader ":"] 0]
		    
		    set url [ns_conn url]
		    if {[string match "*/index.tcl" "$url"]} {
			set url [string range "$url" 0 end-9]
		    }
		} else {
		    set protocol http
		    set host localhost
		    set port 8080
		    set url /ws/$targetNamespace/
		}
		
	    }
	}
	"finalize" {
	    namespace eval $tclNamespace {
		if {!$schemaIsInitialized} {
		    # Maybe init schema
		    <ws>namespace schema $tclNamespace
		}
		variable soapActionBase ${protocol}://$hostHeader/$xmlPrefix

		# Create PortType
		::wsdl::portTypes::new $tclNamespace $portType $operations
		# Bind
		set bindMap [list]
		foreach operation $operations {
		    lappend bindMap ${soapActionBase}/$operation $operation
		}
		eval [concat ::wsdl::bindings::${binding}::new $tclNamespace $portType $bindingName $bindMap] 

		# Combine Port
		::wsdl::ports::new $portName $bindingName "$url"
		::wsdl::services::new $serviceName [list $portName]
		::wsdl::server::new $serverName $targetNamespace [list $serviceName]
		set ::wsdb::servers::${serverName}::hostHeaderNames $hostHeader
		::wsdl::definitions::new $serverName

		# Add Documentation
		lappend documentLinks config ::${xmlPrefix}
		lappend documentLinks simpleTypes ::wsdb::types::${xmlPrefix}
		lappend documentLinks complexTypes ::wsdb::elements::${xmlPrefix}
		lappend documentLinks messages ::wsdb::messages::${xmlPrefix}
		lappend documentLinks operations ::wsdb::operations::${xmlPrefix}
		lappend documentLinks portTypes ::wsdb::portTypes::${xmlPrefix}
		lappend documentLinks port ::wsdb::ports::[set ::${xmlPrefix}::portName]
		lappend documentLinks binding ::wsdb::bindings::[set ::${xmlPrefix}::bindingName]
		lappend documentLinks service ::wsdb::services::[set ::${xmlPrefix}::serviceName]
		lappend documentLinks server ::wsdb::servers::[set ::${xmlPrefix}::serverName]
 		
	    }

	}
	"lappend" {
	    lappend ${tclNamespace}::[lindex $args 0] [lindex $args 1]
	}
	"set" {
	    set length [llength $args]
	    if {$length == 1} {
		return [set ${tclNamespace}::[lindex $args 0]]
	    } elseif {$length == 2} {
		return [set ${tclNamespace}::[lindex $args 0] [lindex $args 1]]
	    } else {
		return -code error "Call <ws>namespace set with wrong number of args"
	    }
	}
	"eval" {
	    
	    
	    
	}
	"import" {
	    # import an already defined proc to this namespace
	    set procName [lindex $args 0]
	    set procTail [namespace tail $procName]
	    set returns [lindex $args 1]
	    set returnList [lindex $args 2]

	    set procBody [info body $procName]
	    
	    set procArgs [info args $procName]
	    set arguments [list]
	    foreach procArg $procArgs {
		if {[info default $procName $procArg defaultValue]} {
		    lappend arguments [list $procArg [list default [list $defaultValue] minOccurs 0]]
		} else {
		    lappend arguments [list $procArg]
		}
	    }
	    <ws>proc ${tclNamespace}::$procTail $arguments $procBody $returns $returnList
	    
	}
	"schema" {
	    if {![<ws>namespace set $tclNamespace schemaIsInitialized]} {
		set tmpTargetNamespace [lindex $args 0]
		if {"$tmpTargetNamespace" ne  ""} {
		    <ws>namespace set $tclNamespace targetNamespace $tmpTargetNamespace
		} 
		# Create new wsdl schema:
		namespace eval $tclNamespace {
		    ::wsdl::schema::new $xmlPrefix $targetNamespace
		    set schemaIsInitialized 1
		}
	    }

	}
	"delete" {
	    # Use to remove this namespace and all associated wsdb components
	    # usually call by init, although could use in ns_atclose.

	}
	default {
	    
	    
	}
    }
} 

proc ::<ws>proc { 
    procName 
    procArgsList 
    procBody 
    {returns ""} 
    {returnList ""} 
} { 

    # Determine or Create Schema/Namespace
    set tclNamespace [namespace qualifiers $procName] 
    set xmlPrefix [namespace tail $tclNamespace]
    if {[<ws>namespace isFrozen $tclNamespace]} {
	return 1
    }
    <ws>namespace schema $tclNamespace

    set args [list]
    set inputTypeList [list]
    set inputConversionList [list]
    set outputConversionList [list]


    <ws>log Debug "<ws>proc procArgsList = '$procArgsList'"
    
    if {[llength $procArgsList] == 1
	&& [llength [lindex $procArgsList 0]] == 1
    } {
	# See if this is just the name of a complexType
	set argTypeNameList [split [lindex $procArgsList {0 0}] ":"]
	if {[llength $argTypeNameList] == 1} {
	    set argType [lindex $argTypeNameList 0]
	    
	    if {[namespace exists ::wsdb::elements::${xmlPrefix}::${argType}] 
		&& [info exists ${tclNamespace}::elements($argType)]
	    } {
		set procArgsList [lindex [set ${tclNamespace}::elements($argType)] 0]
		set inputElementName $argType
	    }
	}
    }

    foreach argList $procArgsList {
	<ws>log Debug "<ws>proc argList = '$argList'"

	# This Array will remain available procArgsList length = 1;
	if {[array exists elementData]} {
	    array unset elementData
	}

	set argName [::wsdl::elements::modelGroup::sequence::getElementData\
			 $argList elementData];

	lappend inputConversionList $argName

	if {[info exists elementData(default)]} {
	    lappend args [list $argName $elementData(default)]
	} else {
	    lappend args [list $argName]
	}

    }
    

    # Handle return type 
    set returnTypeList [list]
    if {"$returns" eq "" || "$returnList" eq ""} {
	lappend returnList [list ResultString]
	lappend outputConversionList [list ResultString]
    } else {
	# See if returnList is just a return Type:
	if {[llength $returnList] == 1
	    && [llength [lindex $returnList 0]] == 1
	} {
	    # See if this is just the name of a complexType
	    set returnArgTypeNameList [split [lindex $returnList {0 0}] ":"]
	    if {[llength $returnArgTypeNameList] == 1} {
		set returnArgType [lindex $returnArgTypeNameList 0]
		
		if {[namespace exists ::wsdb::elements::${xmlPrefix}::${returnArgType}] 
		    && [info exists ${tclNamespace}::elements($returnArgType)]
		} {
		    set returnList [lindex [set ${tclNamespace}::elements($returnArgType)] 0]
		    set outputElementName $returnArgType
		}
	    }
	}

	foreach returnArg $returnList {
	    # This Array will remain available returnList length = 1;
	    if {[array exists returnData]} {
		array unset returnData
	    }

	    lappend outputConversionList \
		[::wsdl::elements::modelGroup::sequence::getElementData\
		     $returnArg returnData];
	}
    }


    # Create the wrapper procedure:
    proc $procName $args $procBody

    # baseName will be used as a template to name wsdl types:
    set baseName [namespace tail $procName]

    # XML Schema Element Types (complexType):
    # Create input/output element as type to be used for message:
    if {![info exists inputElementName]} {
	set inputElementName ${baseName}Request
    }
    <ws>element sequence ${xmlPrefix}:$inputElementName\
	$procArgsList $inputConversionList;

    if {![info exists outputElementName]} {
	set outputElementName ${baseName}Response
    }
    <ws>element sequence ${xmlPrefix}:$outputElementName\
	$returnList $outputConversionList;
   
    # WSDL Messages
    set inputMessageName ${baseName}RequestMsg
    eval [::wsdl::messages::new $xmlPrefix $inputMessageName $inputElementName]

    set outputMessageName ${baseName}ResponseMsg
    eval [::wsdl::messages::new $xmlPrefix $outputMessageName $outputElementName]

    # WSDL Operation
    set operationName ${baseName}Operation
    eval [::wsdl::operations::new $xmlPrefix $operationName \
	      [list $procName $procArgsList] \
	      [list input $inputMessageName] [list output $outputMessageName]];
    
    <ws>namespace lappend $tclNamespace operations $operationName

    # Debug return, remove when done:
    
}

proc ::<ws>type {
    subcmd
    typeName
    args
} {
    # Convenience hackery:
    set typeParts [split [string trim $typeName :] :]
    set tnsAlias [lindex $typeParts 0]
    set tclNamespace ::$tnsAlias
    set name [lindex $typeParts end]

    if {![<ws>namespace exists $tclNamespace]} {
	<ws>namespace init $tclNamespace
    }
    # Maybe init schema
    <ws>namespace schema $tclNamespace

    switch -exact -- $subcmd {
	"exists" {
	    return [info exists ${tclNamespace}::types($name)]
	}
    }
    switch -glob -- $subcmd {

	"sim*" {
	    if {"[set base [lindex $args 0]]" eq ""} {
		set base "xsd::string"
	    }
	    ::wsdl::types::simpleType::new $tnsAlias $name $base
	    set ${tclNamespace}::types($name) [list base $base]
	}
	"enum*" {
	    # <ws>type enum namespace::name enum {base xsd::string}

	    set enum [lindex $args 0]
	    set base [lindex $args 1]
	    if {"$base" eq ""} {
		set base "xsd::string"
	    }
	    ::wsdl::types::simpleType::restrictByEnumeration $tnsAlias \
		$name $base $enum
	    set ${tclNamespace}::types($name) [list base $base enum $enum]
	}
	"pat*" {
	    set pattern  [lindex $args 0]
	    set base     [lindex $args 1]
	    if {"$base" eq ""} {
		set base "xsd::string"
	    }
	    ::wsdl::types::simpleType::restrictByPattern $tnsAlias \
		$name $base $pattern
	    set ${tclNamespace}::types($name) [list base $base pattern $pattern]
	}
	"decimalRest*" {
	    set restrictionList [lindex $args 0]
	    set base [lindex $args 1]
	    if {"$base" eq ""} {
		set base "xsd::decimal"
	    }
	    ::wsdl::types::simpleType::restrictDecimal $tnsAlias \
		$name $base $restrictionList
	    set ${tclNamespace}::types($name) [list base $base restrictionList $restrictionList]
	}
	"stringRest*" {
	    set restrictionList [lindex $args 0]
	    set base [lindex $args 1]
	    if {"$base" eq ""} {
		set base "xsd::string"
	    }
	    ::wsdl::types::simpleType::restrictString $tnsAlias \
		$name $base $restrictionList
	    set ${tclNamespace}::types($name) [list base $base restrictionList $restrictionList]
	}
	"q*" {
	    if {[<ws>type exists $typeName]} {
		return [set ${tclNamespace}::types($name)]
	    } else {
		return {}
	    }
	}
	"valid*" {

	}
	default {

	}
    }
    # End subcmd switch
}

proc ::<ws>element {
    subcmd
    typeName
    args
} {
    # Convenience hackery:
    set typeParts [split [string trim $typeName :] :]
    set tnsAlias [lindex $typeParts 0]
    set tclNamespace ::$tnsAlias
    set name [lindex $typeParts end]

    if {![<ws>namespace exists $tclNamespace]} {
	<ws>namespace init $tclNamespace
    }

    # Maybe init schema
    <ws>namespace schema $tclNamespace
    
    switch -exact -- $subcmd {
	"exists" {
	    return [info exists ${tclNamespace}::elements($name)]
	}
    }

    #Child Element Spec (list of):
    #{Name typeName attributeList}

    switch -glob -- $subcmd {

	"seq*" {

	    if {![<ws>element exists ${tnsAlias}::$name]} {
		<ws>log Notice "<ws>element making ${tnsAlias}::$name"
		eval [::wsdl::elements::modelGroup::sequence::new \
			  $tnsAlias $name [lindex $args 0] ]
		set ${tclNamespace}::elements($name) $args
	    }

	}
	"global*" {


	}
	"multi*" {


	}
	"append" {


	}
	"q*" {


	}
	"valid*" {


	}
	default {

	}
    }
}



# Note: It might be more efficient to wrap <ws>doc
#  in an isFrozen or showDocument check
proc ::<ws>doc {
    what
    tclNamespace
    name
    docString
} {
    set xmlAlias [namespace tail $tclNamespace]
    set tclNamespace ::$xmlAlias

    while {1} {
	# First check that we have a real web service
	if {![<ws>namespace exists $tclNamespace]
	    || [<ws>namespace isFrozen $tclNamespace]
	} {
	    break
	}
	# Only document certain components
	# Note: eventually get search list from the web service
	if {[lsearch -exact {type element operation} $what] == -1} {
	    break
	} else {
	    set what ${what}s
	}
  
	catch {::wsdl::doc::document doc $what $xmlAlias $name $docString}

	break
    }

    return ""

}

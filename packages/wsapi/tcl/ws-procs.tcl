# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

# potential webservice interface layer:

proc ::<ws>return {tclNamespace} {

    set method [string toupper [ns_conn method]]

    switch -exact -- "$method" {
	"GET" {

	    set query [ns_conn query]
	    set url [ns_conn url]
	    set operation [ns_queryget op ""]

	    if {"$query" eq "WSDL" } {
		set mode "wsdl"
	    } else {
		set mode [string tolower [ns_queryget mode ""]]
	    }
	    
	    switch -exact -- "$mode" {
		"wsdl" {
                    namespace eval $tclNamespace {
		        set definitions [xml::document::print ::wsdb::definitions::${serverName}::definitions] 
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

		    ns_log Notice "xmlPrefix = '$xmlPrefix operation = '$operation'"

		    set messages [set ::wsdb::operations::${xmlPrefix}::${operation}::messages]
		    set inputMessageType [::wsdl::operations::getInputMessageType $xmlPrefix $operation]
		    set inputMessageConv [set ::wsdb::elements::${xmlPrefix}::${inputMessageType}::conversionList]
		    set inputMessageSignature [list]
                    set inputFormElements ""
		    set missing 0
		    foreach {element type} $inputMessageConv {
			if {"[set ${inputMessageType}.$element "[ns_queryget ${inputMessageType}.$element ""]"]" eq ""} {
			    lappend inputMessageSignature $type
			    incr missing
			} else {
			    lappend inputMessageSignature [set ${inputMessageType}.$element]
			}
			
			append inputFormElements "
<tr>
 <td>${inputMessageType}.$element</td>
 <td><input type=\"text\" name=\"${inputMessageType}.$element\" value=\"[set ${inputMessageType}.$element]\" >
 </td>
</tr>"
		    }
		    set requestID [::request::new "" "" ""]
		    set requestNamespace ::request::$requestID
		    set soapEnvelope "${requestNamespace}::request::Envelope"
		    set inputXMLNS ${requestNamespace}::input
		    if {[llength $inputMessageSignature] < 2} {
			set inputMessageSignature [lindex $inputMessageSignature 0]
		    }
		    set inputElement [::wsdb::elements::${xmlPrefix}::${inputMessageType}::new $inputXMLNS "$inputMessageSignature"]
		    set targetNamespace [<ws>namespace set $tclNamespace targetNamespace]
		    ::xml::element::setAttribute $inputElement "xmlns" $targetNamespace
		    set soapBody [::wsdl::bindings::soap::createBody ${requestNamespace}::request ]
		    ::xml::element::appendRef $soapBody $inputElement
		    set returnBody [::xml::document::print $soapEnvelope]

		    set SOAPActionMap [set ::wsdb::bindings::${bindingName}::soapActionMap]
		    set SOAPAction ""
		    foreach {soapAction opName} $SOAPActionMap  {
			if {"$opName" eq "$operation"} {
			    set SOAPAction $soapAction
			    break
			} 
		    }
		    set length [string length $returnBody]
		    set Request "POST $url HTTP/1.1
Host: [ns_set iget [ns_conn headers] host]
Content-Type: text/xml; charset=utf-8
Content-Length: $length
SOAPAction: \"$SOAPAction\"

$returnBody
"

                    if {$missing == 0} {

                        set sock [socket 192.168.1.102 8005]
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

		    foreach operation [set ${tclNamespace}::operations] {
		        append operationLinks "<li><a href=\"$url?op=$operation&mode=display\">$operation</a></li><br>\n"
		    }
		    ns_return 200 text/html "
 The following operations are supported. For a formal definition, please review the <a href=\"$url?WSDL\">Service Description</a>.
<br>
<ul>
$operationLinks
</ul>"
	        }
            }
	}
	"POST" {
	    namespace eval $tclNamespace {
		::wsdl::server::accept [list $serverName $serviceName $portName $bindingName [ns_conn url]] 
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
	"isFrozen" {
	    if {[info exists ${tclNamespace}::frozen] && [set ${tclNamespace}::frozen] == 1} {
		return 1
	    } else {
		return 0
	    }
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
		variable forzen 0
	    }
	    
	}
	"finalize" {
	    namespace eval $tclNamespace {
		variable soapActionBase [ns_conn location]/$xmlPrefix
		# Create PortType
		::wsdl::portTypes::new $tclNamespace $portType $operations
		# Bind
		set bindMap [list]
		foreach operation $operations {
		    lappend bindMap ${soapActionBase}/$operation $operation
		}
		eval [concat ::wsdl::bindings::${binding}::new $tclNamespace $portType $bindingName $bindMap] 

		# Combine Port
		::wsdl::ports::new $portName $bindingName [ns_conn url]
		::wsdl::services::new $serviceName [list $portName]
		::wsdl::server::new $serverName $targetNamespace [list $serviceName]
		set ::wsdb::servers::${serverName}::hostHeaderNames [string range [ns_conn location] 7 end]
		::wsdl::definitions::new $serverName


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
		    lappend arguments [list $procArg $defaultValue]
		} else {
		    lappend arguments [list $procArg]
		}
	    }
	    <ws>proc ${tclNamespace}::$procTail $arguments $procBody $returns $returnList 
	    
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

    if {[<ws>namespace isFrozen $tclNamespace]} {
	return 1
    }

    set targetNamespace [string trimright "urn:tcl[string map {:: :} $tclNamespace]" ":"]
    set xmlPrefix [namespace tail $tclNamespace]

    # Create new wsdl schema:
    ::wsdl::schema::new $xmlPrefix $targetNamespace

    set args [list]
    set inputTypeList [list]
    set inputConversionList [list]

    ::tws::log::log Debug "<ws>proc procArgsList = '$procArgsList'"

    foreach argList $procArgsList {
	::tws::log::log Debug "<ws>proc argList = '$argList'"
        set argNameType [lindex $argList 0]
	if {[set first [string first ":" $argNameType]] > -1} {
	    set argName [string range $argNameType 0 [expr $first -1 ]]
	    set argType [string range $argNameType [expr $first + 1] end]
            if {"$argType" eq ""} {
		set argType "xsd::string"
	    } elseif {[string first ":" "$argType"] == -1} {
		set argType "xsd::$argType"
	    } 
	} else {
	    set argName $argNameType
            set argType "xsd::string"
	}
	
	# Create simpleType in the targetNamespace
	::wsdl::types::simpleType::new $xmlPrefix $argName $argType
	
	# The new type will be used to create the doc child elements:
	set elementType ${xmlPrefix}::$argName


	if {[llength $argList] == 2} {
            # A default value is provided
	    set argDefault [lindex $argList 1]
	    lappend args [list $argName $argDefault]
            lappend inputTypeList [list $argName $elementType 0]
	} else {
	    lappend args [list $argName]
            lappend inputTypeList [list $argName $elementType 1]
	}
	lappend inputConversionList $argName "Value"

    }



    # Handle return type 
    set returnTypeList [list]
    if {"$returns" eq "" || "$returnList" eq ""} {
	# Creating simpleTypes in targetNamespace:
	# This is the default if no returnList is given:
	::wsdl::types::simpleType::new $xmlPrefix ResultString "xsd::string"
	lappend returnTypeList [list ResultString ${xmlPrefix}::ResultString 1]
    } else {
	foreach returnArg $returnList {
	    if {[set first [string first ":" $returnArg]] > -1} {
		set returnArgName [string range $returnArg 0 [expr $first -1 ]]
		set returnArgType [string range $returnArg [expr $first + 1] end]
		if {"$returnArgType" eq ""} {
		    set returnArgrgType "xsd::string"
		} elseif {[string first ":" "$returnArgType"] == -1} {
		    set returnArgType "xsd::$returnArgType"
		}
	    } else {
		set returnArgName $returnArg
		set returnArgType "xsd::string"

	    }
	    # Creating simpleTypes in targetNamespace:
	    ::wsdl::types::simpleType::new $xmlPrefix $returnArgName $returnArgType
	    # New type used for doc child elements:
	    set elementType ${xmlPrefix}::$returnArgName
	    lappend returnTypeList [list $returnArgName $elementType 1]
	} 
    }


    # Create the wrapper procedure:
    proc $procName $args $procBody

    # baseName will be used as a template to name wsdl types:
    set baseName [namespace tail $procName]

    # XML Schema Element Types (complexType):
    # Create input/output element as type to be used for message:
    set inputElementName ${baseName}Request
    set code [::wsdl::elements::modelGroup::sequence::new $xmlPrefix $inputElementName $inputTypeList $inputConversionList] 
    # remove this when done:
    #::tws::log::log Debug "<ws>proc code = '$code'"

    eval $code
    set outputElementName ${baseName}Response
    set returnCode [::wsdl::elements::modelGroup::sequence::new $xmlPrefix $outputElementName $returnTypeList]
    # remove this when done:
    eval $returnCode
    
    # WSDL Messages
    set inputMessageName ${inputElementName}Msg
    set inputMessageCode [::wsdl::messages::new $xmlPrefix $inputMessageName $inputElementName]
    eval $inputMessageCode
    set outputMessageName ${outputElementName}Msg
    set outputMessageCode [::wsdl::messages::new $xmlPrefix $outputMessageName $outputElementName]
    eval $outputMessageCode

    # WSDL Operation
    set operationName ${baseName}Operation
    set operationCode [::wsdl::operations::new $xmlPrefix $operationName [list $procName $inputConversionList] \
			   [list input $inputMessageName] [list output $outputMessageName]]
    eval $operationCode
    
    <ws>namespace lappend $tclNamespace operations $operationName

    # Debug return, remove when done:
    
}

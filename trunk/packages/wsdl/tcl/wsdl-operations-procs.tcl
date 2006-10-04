# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::wsdl::operations { 

    namespace import ::tws::log::log

}


proc ::wsdl::operations::new {

    operationNamespace
    operationName
    operationSignature
    args
} {

    namespace eval ::wsdb::operations::${operationNamespace} { }
    
    namespace eval ::wsdb::operations::${operationNamespace}::${operationName} {
	variable messages 
	variable invoke
	variable operationProc
	variable conversionList
    }

    namespace eval ::wsdb::operations::${operationNamespace}::${operationName} {
	set invoke [namespace code {Invoke}]
    }
    set operationProc [lindex $operationSignature 0]
    set conversionList [lindex $operationSignature 1]
    set ::wsdb::operations::${operationNamespace}::${operationName}::operationProc $operationProc
    set ::wsdb::operations::${operationNamespace}::${operationName}::conversionList $conversionList

    foreach {var conversion} $conversionList {
	lappend procArgs "\$$var"
    }

    set inputCodeBlock ""
    set outputCodeBlock ""
    set faultCodeBlock ""
    foreach arg $args {
	
	if {[lindex $arg 0] eq "input"} {
	    # inputCodeBlock
	    set inputMessage [lindex $arg 1]
	    set inputElement [set ::wsdb::messages::${operationNamespace}::${inputMessage}::Parts]
	} elseif {[lindex $arg 0] eq "output"} {
	    # outputCodeBlock
	    set outputMessage [lindex $arg 1]
	    set outputElement [set ::wsdb::messages::${operationNamespace}::${outputMessage}::Parts]
	} elseif {[lindex $arg 0] eq "fault"} {
	    # faultCodeBlock
	} else {
	    log Error "operations::new  unknown message type '[lindex $arg 0]'"
	    continue
	}

	log Notice "operations::new adding message $arg"
	lappend :::wsdb::operations::${operationNamespace}::${operationName}::messages $arg

    }    

    set script ""
    append script "
proc ::wsdb::operations::${operationNamespace}::${operationName}::Invoke \{ 
    inputXMLNS
    outputXMLNS
\} \{
    variable conversionList
    ::xml::childElementsAsListWithConversions \$inputXMLNS \$conversionList
    
    return \[::wsdb::elements::${operationNamespace}::${outputElement}::new \$outputXMLNS \[$operationProc [join $procArgs " "]\]\]
\}
"

 
    return "$script"
}

proc ::wsdl::operations::getInputMessageType { 
    operationNamespace
    operationName
} {

    set inputOperationList [lsearch -inline -all \
				[set ::wsdb::operations::${operationNamespace}::${operationName}::messages]\
				{input *}]
    log Debug "getInputMessageType: inputOperationList = '$inputOperationList'"

    set inputMessage [lindex $inputOperationList {0 1}]
    log Debug "getInputMessageType: inputMessage = '$inputMessage'"
    set messageParts [set ::wsdb::messages::${operationNamespace}::${inputMessage}::Parts]
    log Debug "getInputMessageType: messageParts = '$messageParts'"
    set messageType [lindex $messageParts 0]
    log Debug "getInputMessageType: messageType = '$messageType'"
    return $messageType
}

proc ::wsdl::operations::getOutputMessageType { 
    operationNamespace
    operationName
} {

    set OperationList [lsearch -inline -all \
				[set ::wsdb::operations::${operationNamespace}::${operationName}::messages]\
				{output *}]
    if {[llength $OperationList] == 1} {
	set message [lindex $inputOperationList {0 1}]
	set messageParts [set ::wsdb::messages::${operationNamespace}::${message}::Parts]
	set messageType [lindex $messageParts 0]
	return $messageType
    } else {
	return ""
    }
}

proc ::wsdl::operations::getFaultMessageType { 
    operationNamespace
    operationName
} {

    set inputOperationList [lsearch -inline -all \
				[set ::wsdb::operations::${operationNamespace}::${operationName}::messages]\
				{fault *}]
    if {[llength $inputOperationList] == 1} {
	return [lindex $inputOperationList 1]
    } else {
	return ""
    }
}

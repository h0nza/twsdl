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

    log Debug "operations::new on = $operationNamespace oName = $operationName oSig = $operationSignature args = $args"
    # Ensure tcl namespace exists:
    namespace eval ::wsdb::operations::${operationNamespace}::$operationName { }

    set operationProc [lindex $operationSignature 0]
    set inputElementData [lindex $operationSignature 1]
    set procSignature [::wsdl::operations::getProcSignature $operationProc]

    set inputConversionList [list]
    set inputDefaultCodeBlock ""
    set procArgs [list]
    set operationArgs [list]
    foreach argList $inputElementData {
	#log Debug "wsdl::operations::new argList = '$argList'"

	# This Array will remain available procArgsList length = 1;
	if {[array exists elementData]} {
	    array unset elementData
	}

	set argName [::wsdl::elements::modelGroup::sequence::getElementData\
			 $argList elementData];

	log Debug "wsdl::operations::new elementData = [array get elementData]"
	# Default Values
	if {$elementData(maxOccurs) > 1} { 
	    lappend inputConversionList $argName List
	} else {
	    lappend inputConversionList $argName Value
	}
	if {"$elementData(minOccurs)" eq "0"} {
	    append inputDefaultCodeBlock "
    set $argName [list $elementData(default)]"
	}

	lappend operationArgs "\$$argName"
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

	log Notice "operations::new adding message $arg to ::wsdb::operations::${operationNamespace}::${operationName}::messages"
	lappend OperationMessages $arg

    }    

    set script "
namespace eval ::wsdb::operations::${operationNamespace}::${operationName} \{
    variable messages [list $OperationMessages]
    variable invoke \[namespace current\]::Invoke
    variable operationProc $operationProc
    variable inputElementData [list $inputElementData]
    variable procSignature $procSignature
    variable conversionList \[list $inputConversionList\]
\}"


    set operationProcArgs [join $operationArgs " "]

    append script "
proc ::wsdb::operations::${operationNamespace}::${operationName}::Invoke \{ 
    inputXMLNS
    outputXMLNS
\} \{
    variable conversionList$inputDefaultCodeBlock
    ::xml::childElementsAsListWithConversions \$inputXMLNS \$conversionList

    return \[::wsdb::elements::${operationNamespace}::${outputElement}::new \$outputXMLNS \[$operationProc $operationProcArgs\]\]
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
	set message [lindex $OperationList {0 1}]
	set messageParts [set ::wsdb::messages::${operationNamespace}::${message}::Parts]
	set messageType [lindex $messageParts 0]
	return $messageType
    } else {
	return ""
    }
}

proc ::wsdl::operations::getInputMessageType { 
    operationNamespace
    operationName
} {

    set OperationList [lsearch -inline -all \
				[set ::wsdb::operations::${operationNamespace}::${operationName}::messages]\
				{input *}]
    if {[llength $OperationList] == 1} {
	set message [lindex $OperationList {0 1}]
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

    set OperationList [lsearch -inline -all \
				[set ::wsdb::operations::${operationNamespace}::${operationName}::messages]\
				{fault *}]
    if {[llength $OperationList] == 1} {
	return [lindex $OperationList 1]
    } else {
	return ""
    }
}



proc ::wsdl::operations::getProcSignature {
    proc
} {
    if {"[info procs $proc]" ne "$proc"} {
	return [list]
    }
    set args [info args $proc]
    set arguments [list]
    foreach arg $args {
	if {[info default $proc $arg defaultValue]} {
	    lappend arguments "[list [list $arg $defaultValue]]"
	} else {
	    lappend arguments "[list $arg]"
	}
    }

    return [list $arguments]
}

# Simple API for defining service quickly:

namespace eval ::wsdl::simple-api { }
	    
proc ::wsdl::simple-api::getOptions { ParameterName OptionsList } {
    # Set Element Name
    if {[set OptionIndex [lsearch -exact $OptionsList "-element"]] == -1} {
	set ParameterNameTrimmed [string trimleft $ParameterName "-"]
	set ParameterElementName "[string toupper [string range $ParameterNameTrimmed 0 0]][string range $ParameterNameTrimmed 1 end]"
    } else {
	set ParameterElementName [lindex $OptionsList [expr $OptionIndex + 1]]
    }
    ns_log Notice "ParameterElementName = '$ParameterElementName'"
    # Set Type
    if {[set OptionIndex [lsearch -exact $OptionsList "-type"]] == -1} {
	set ParameterType "string"
	set ParameterNS "xsd"
    } else {
	set ParameterTypePath    [lindex $OptionsList [expr $OptionIndex + 1]]
	set ParameterType        [namespace tail $ParameterTypePath]
	set ParameterNS          [namespace qualifiers $ParameterTypePath]
	
	if {"$ParameterType" eq ""} {
	    set ParameterType "string"
	}
	if {"$ParameterNS" eq ""} {
	    set ParameterNS "xsd"
	}
    }
    if {[set OptionIndex [lsearch -exact $OptionsList "-conversion"]] == -1} {
	set ParameterConversion "Value"
    } else {
	set ParameterConversion [lindex $OptionsList [expr $OptionIndex + 1]]
    }
    return [list $ParameterElementName $ParameterNS $ParameterType $ParameterConversion] 
}

ns_log Notice "getOptions = [::wsdl::simple-api::getOptions MyFakeElement {}]"

ns_log Notice "About to source simple-api::new"

proc ::wsdl::simple-api::new {
    tnsAlias
    wsdlDefinitionList
} {
    
    set serverName          [lindex $wsdlDefinitionList 0]
    set targetNamespaceBase [lindex $wsdlDefinitionList 1]
    set hostHeaderNames     [lindex $wsdlDefinitionList 2]
    set OperationsList      [lindex $wsdlDefinitionList 3]
    
    # Derived Information:
    set targetNamespace "[string trimright $targetNamespaceBase "/"]/$serverName"
    set apiCallList [list]
    ns_log Notice "setting ElementCalls = ''"
    set ElementCalls ""
    set MessageCalls ""
    set OperationCalls ""

    ns_log Notice "OperationsList = $OperationsList"
    # process OperationsList
    foreach Operation $OperationsList {
	ns_log Notice "Operation = $Operation"
	# used to call apis
	set Parameters            [list]
	set ElementChildList      [list]
	set ConversionList        [list]
	set OperationNameTemplate [lindex $Operation 0]
	set ProcedureType         [lindex $Operation 1]
	set ProcedureName         [lindex $Operation 2]
	set ParameterList         [lindex $Operation 3]
	set ProcedureReturnMap    [lindex $Operation 4]
	
	# try to mesh up ParameterList and ParameterTypeMap
	set ParameterNumber 0
	foreach Parameter $ParameterList {
	    set ParameterName       [lindex $Parameter 0]
	    
	    # If there are an even number of list elements, second is default: 
	    if {!([llength $Parameter] % 2)} {
		# Parameter is optional
		set ParameterDefault [lindex $Parameter 1]
		set ParameterHasDefault 1
		set ParameterMinOccurs 0
		set OptionStart 2
	    } else {
		set ParameterHasDefault 0
		set ParameterMinOccurs 1
		set OptionStart 1
	    }
	    
	    # Cycle through all possible options
	    set OptionsList [lrange $Parameter $OptionStart end]
	    foreach {ParameterElementName ParameterNS ParameterType ParameterConversion} [::wsdl::simple-api::getOptions $ParameterName $OptionsList] { };
	    
	    set ElementChildDef [list $ParameterElementName "${ParameterNS}::${ParameterType}" $ParameterMinOccurs]
	    
	    lappend ElementChildList $ElementChildDef
	    
	    lappend ConversionList [list $ParameterElementName $ParameterName $ParameterConversion $ParameterMinOccurs] 
	    incr ParameterNumber
	}
	set ElementCall "\neval \[::wsdl::elements::modelGroup::sequence::new $tnsAlias ${OperationNameTemplate}Req \{
  \{[join $ElementChildList "\}\n  \{"]\}
\}\]"

	append ElementCall "\neval \[::wsdl::elements::modelGroup::sequence::new $tnsAlias ${OperationNameTemplate}Resp \{
  $ProcedureReturnMap
\}\]"
	append ElementCalls "\n$ElementCall"
  
	append MessageCalls "\neval \[::wsdl::messages::new $tnsAlias ${OperationNameTemplate}ReqMsg ${OperationNameTemplate}Req \]"
	append MessageCalls "\neval \[::wsdl::messages::new $tnsAlias ${OperationNameTemplate}RespMsg ${OperationNameTemplate}Resp \]"
	
	append OperationCalls "\neval \[::wsdl::operations::new $tnsAlias ${OperationNameTemplate}Op \{$ProcedureName
  \{[join $ConversionList "\}\n  \{"]\}\n\} \{input ${OperationNameTemplate}Req\} \{output ${OperationNameTemplate}Resp\}\]"

    }
    
    set vars [info vars]
    set output ""
    foreach var $vars {
	if {[array exists $var]} {
	    set arrayNames [array names $var]
	    append output "Array $var\n"
	    foreach arrayName $arrayNames {
		append output " ${var}\($arrayName\) = '[set ${var}($arrayName)]'\n"
	    }
	} else {
	    append output " $var = '[set $var]'\n"
	}
    }
    
    return "$ElementCalls\n\n$MessageCalls\n\n$OperationCalls"
}

ns_log Notice "Sourced simple-api::new"

set tnsAlias "vs"
set output [::wsdl::simple-api::new $tnsAlias {
    "VSObjects"
    "http://example.com"
    "maria:8080"
    {
	{"GetObjectID"
	    ad_proc ::vs::objects::get_object_id {
		{type_key -type integer}
		{key_value -type integer}
 	    } {
		{ObjectID -type integer}
	    }
	}
	
	{"CanUserAdministerObject"
	    ad_proc ::vs::objects::can_user_administer_object { 
		{-user_id "" -element UserID -type integer}
		{object_id -element ObjectID -type integer}
	    } {
		{CanAdminister -type boolean}
	    }
	}
	
	{"BogusArgParseEg"
	    ad_proc ::vs::objects::testargs {
		{-myArgA "valA"}
		{-myArgB "valB" -type boolean}
		myArgC
		{myArgD -type boolean}
		{myDefaultArgE "some default e val"}
		{myDefaultArgF "1" -type boolean}
	    } {
		{MyResponseArgA}
		{MyResponseArgB -type integer}
		{MyOptionalResponseArgC -type boolean -minOccurs 0} 
	    }
	}
    }
}]


ns_return 200 text/plain $output



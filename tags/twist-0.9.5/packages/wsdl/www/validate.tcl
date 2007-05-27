

set requestNS [::wsdb::elements::stockquoter::StockRequest::new ::xml::instance::[ns_rand 1000000] [list MSFT 1]]

# Note: incorrect element name 'Verbosee' in addition to busting maxOccurs
#set secondVerbose [::xml::element::append $requestNS Verbose]
#::xml::element::appendText $secondVerbose "1" 

#ns_atclose "namespace delete $requestNS"

ns_log Notice "validate.tcl: created requestNS: $requestNS [::inspect::displayNamespace $requestNS]"

# Need a global faultCode manager
# Where would this go?
#set ::wsdb::elements::stockquoter::StockRequest::MaxOccurs(Verbose) 1
if {![set valid [$::wsdb::elements::stockquoter::StockRequest::validate $requestNS]]} {

    set errors [::xml::instance::printErrors $requestNS]
    set result "No Result"
    set resultDoc "No Result Doc"
} else {
    set errors "No errors"
    # Invoke the operation:
    set responseNS [namespace parent $requestNS]::response

    ::xml::instance::newXMLNS $responseNS StockQuotes 1
    set StockQuotesNS ${responseNS}::StockQuotes

    set result [$wsdb::operations::stockquoter::StockQuoteOperation::invoke $requestNS ${responseNS}1]
    set result2 [$wsdb::operations::stockquoter::StockQuoteOperation::invoke $requestNS ${responseNS}2]

    ::xml::element::appendText [::xml::element::append ${result2} myBadElement] .TEXT "Some wedird stuff" 
    

    ::xml::element::appendRef $StockQuotesNS $result
    ::xml::element::appendRef $StockQuotesNS $result2

    set resultDoc [::xml::instance::toXMLNS $StockQuotesNS]
    
}

namespace eval ::wsdb::elements::stockquoter::StockQuotes {
    variable MinOccurs
    variable MaxOccurs
    variable validate [namespace code {ValidateStockQuotes}]
    variable validate_StockQuote $::wsdb::elements::stockquoter::StockQuote::validate
    variable conversionList [list]
    
    set MinOccurs(StockQuote) 1
    set MaxOccurs(StockQuote) 2
}

proc ::wsdb::elements::stockquoter::StockQuotes::ValidateStockQuotes {
    namespace
} {    
    variable MinOccurs
    variable MaxOccurs
    variable validate_StockQuote

    array set COUNT [array get ${namespace}::.COUNT]
    set ElementNames [array names COUNT]

    set COUNT(.INVALID) 0

    foreach ElementName $ElementNames {
	if {$MinOccurs($ElementName) > 0} {
	    if {![info exists COUNT($ElementName)] 
		|| $COUNT($ElementName) < $MinOccurs($ElementName)} {
		::wsdl::elements::noteFault $namespace [list 4 $ElementName $COUNT($ElementName) $MinOccurs($ElementName)]
		incr COUNT(.INVALID)
		return 0
	    }
	}
	if {[info exists COUNT($ElementName)] && $COUNT($ElementName) > $MaxOccurs($ElementName)} {
	    ::wsdl::elements::noteFault $namespace [list 5 $ElementName $COUNT($ElementName) $MaxOccurs($ElementName)]
	    incr COUNT(.INVALID)
	    return 0
	}
    }
    set parts [set ${namespace}::.PARTS]
    
    foreach part $parts {
	foreach {childName prefix childPart} $part { }
	if {![string match "::*" $childPart]} {
	    set childPart ${namespace}::$childPart 
	}
	    
	switch -glob -- "$childName" {
	    StockQuote {
		ns_log Notice "Validating StockQuote in ns $childPart"
		if {![$validate_StockQuote $childPart]} {  
		    ::wsdl::elements::noteFault $namespace [list 2 StockQuote $childPart]
		    incr COUNT(.INVALID)
		    break
		}
	    }

	    default {
		::wsdl::elements::noteFault $namespace [list 3 $childName $childPart]
		incr COUNT(.INVALID)
	    }
	}
    }
    
    if {$COUNT(.INVALID)} {
	return 0
    } else {
	return 1
    }

}
set errorsQuotes ""
set validQuotes ""
if {[info exists StockQuotesNS]} {
    # Try to validate StockQuotes:
    if {![set validQuotes [$::wsdb::elements::stockquoter::StockQuotes::validate $StockQuotesNS]]} {
	
	set errorsQuotes [::xml::instance::printErrors $StockQuotesNS]
    } else {
	set errorsQuotes "No Errors"
	
    }
}


ns_return 200 text/plain "[::xml::instance::toXMLNS $requestNS]


valid = $valid

errors = $errors

result = $result

resultDoc = 
$resultDoc

validQuotes = $validQuotes
errorsQuotes = $errorsQuotes

"


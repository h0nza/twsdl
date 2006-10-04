

set requestNS [::wsdb::elements::stockquoter::StockRequest::new ::xml::instance::[ns_rand 1000000] [list MSFT 0]]

# Note: incorrect element name 'Verbosee' in addition to busting maxOccurs
set secondVerbose [::xml::element::append $requestNS Verbosee]
::xml::element::appendText $secondVerbose "1" 

#ns_atclose "namespace delete $requestNS"

# Need a global faultCode manager
# Where would this go?

$::wsdb::elements::stockquoter::StockRequest::validate $requestNS
    

ns_return 200 text/plain "[::xml::instance::toXMLNS $requestNS]"


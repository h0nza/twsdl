# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



set sqns "stockquoter"

::wsdl::schema::new $sqns "http://stockquoter.com/stockquoter"

# Trade Symbol
::wsdl::types::simpleType::restrictByEnumeration $sqns symbol xsd::string {MSFT WMT XOM GM F GE }

::wsdl::types::simpleType::restrictByPattern $sqns Code xsd::string {[0-9]{4}}

# Verbose
::wsdl::types::simpleType::new $sqns  verbose xsd::boolean

# Quote
::wsdl::types::simpleType::new $sqns quote xsd::float  

# Timestamp
::wsdl::types::simpleType::new $sqns dateOfChange xsd::dateTime 

# Trend
::wsdl::types::simpleType::restrictByEnumeration $sqns trend xsd::integer {-1 0 1}

# DailyMove
::wsdl::types::simpleType::new $sqns dailyMove xsd::float

# LastMove
::wsdl::types::simpleType::new $sqns lastMove xsd::float

# Name 
::wsdl::types::simpleType::new $sqns name xsd::string

# Fault Code
::wsdl::types::simpleType::restrictByEnumeration $sqns faultCode xsd::integer {404 500 301}
# Note that the command returns a script. eval executes it.
eval [::wsdl::elements::modelGroup::sequence::new $sqns StockRequest {
    {Symbol:stockquoter::symbol}
    {Verbose:stockquoter::verbose {minOccurs 0 default "1"}}
}]
	  


eval [::wsdl::elements::modelGroup::sequence::new $sqns StockQuote {
    {Symbol:stockquoter::symbol          }
    {Quote:stockquoter::quote           }
    {DateOfChange:stockquoter::dateOfChange {minOccurs 0}  }
    {Name:stockquoter::name         {minOccurs 0 nillable no}}
    {Trend:stockquoter::trend        {minOccurs 0}}
    {DailyMove:stockquoter::dailyMove    {minOccurs 0}  }
    {LastMove:stockquoter::lastMove     {minOccurs 0}  }
}]

eval [::wsdl::elements::modelGroup::sequence::new $sqns StockQuoteFault {
    {FaultCode:stockquoter::faultCode        }
}]


eval [::wsdl::messages::new $sqns StockRequest StockRequest]
eval [::wsdl::messages::new $sqns StockQuote StockQuote]
eval [::wsdl::messages::new $sqns StockQuoteFault StockQuoteFault]

# tmp operations:
eval [::wsdl::operations::new $sqns StockQuoteOperation {::sq::mystockquote {Symbol Value Verbose Value}} \
	  {input StockRequest} {output StockQuote} {fault StockQuoteFault}]

::wsdl::portTypes::new $sqns StockQuotePortType {StockQuoteOperation}


::wsdl::bindings::soap::documentLiteral::new $sqns StockQuotePortType \
    StockQuoteSoapBind \
    http://stockquoter.com/StockQuote StockQuoteOperation

::wsdl::ports::new StockQuotePort StockQuoteSoapBind "/StockQuote"

::wsdl::services::new StockQuoteService {StockQuotePort}



namespace eval ::sq { }


proc ::sq::mystockquote { symbol {verbose 1} } {

    set StockValue [format %0.2f [expr 25.00 + [ns_rand 4].[format %0.2d [ns_rand 99]]]]
    if {$verbose} {
	return [list $symbol $StockValue 2006-04-11T00:00:00Z "Microsoft Corp." 1 0.75 0.10]
    } else {
	return [list $symbol $StockValue]
    }
}


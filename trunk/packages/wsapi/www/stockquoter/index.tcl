
<ws>namespace init ::stock

<ws>namespace schema ::stock "http://junom.com/stockquoter"


<ws>type enum stock::symbol {MSFT WMT XOM GM F GE}
<ws>type pattern stock::Code {[0-9]{4}} xsd::integer
<ws>type simple stock::verbose xsd::boolean
<ws>type simple stock::quote xsd::float
<ws>type enum stock::trend {-1 0 1} xsd::integer
<ws>type simple stock::dailyMove xsd::float
<ws>type simple stock::lastMove xsd::float
<ws>type simple stock::name
<ws>type simple stock::dateOfChange xsd::dateTime

# Example use of documentation proc

<ws>doc type ::stock symbol "NYSE Trading Symbol"


<ws>element sequence stock::StockResponse {  
    {Symbol:stock::symbol          }
    {Quote:stock::quote           }
    {DateOfChange:stock::dateOfChange {minOccurs 0}}
    {Name:stock::name         {minOccurs 0 nillable true}}
    {Trend:stock::trend        {minOccurs 0}}
    {DailyMove:stock::dailyMove    {minOccurs 0}}
    {LastMove:stock::lastMove     {minOccurs 0}}
}


<ws>element sequence stock::StockRequest {
    {Symbol:stock::symbol}
    {Verbose:stock::verbose {minOccurs 0 default "1"}}
}

<ws>doc element stock StockRequest {Defines StockRequest type.
    User supplies NYSE symbol and a verbose flag for additional data.}

<ws>element sequence stock::StocksToQuote {
    {Symbol:stockquoter::symbol {maxOccurs 8 default "MSFT"}}
    {Verbose:stockquoter::verbose {minOccurs 0 default "1"}}
}

<ws>doc element stock StocksRequest {Multiple StockRequest in one document.}

<ws>element sequence stock::StocksQuoted {
    {StockResponse:elements::stock::StockResponse {maxOccurs 8}}
}

# This form just restates the inputs by name
# This relies on the fact that the default input type is named StockRequest
# This form is for testing, and will likely go away for a shorter easier format.
<ws>proc ::stock::Stock {
    Symbol
    {Verbose {default 0 minOccurs 0} }
} {
    
    set StockValue [format %0.2f [expr 25.00 + [ns_rand 4].[format %0.2d [ns_rand 99]]]]
    if {$Verbose} {
	return [list $Symbol $StockValue 2006-04-11T00:00:00Z "SomeName Corp. " 1 0.75 0.10]
    } else {
	return [list $Symbol $StockValue]
    }
    
} returns { }

# Example does same as ::stock::Stocks below
# Note that the return type name 'QuotesDummy' is unused,
#  as the name is 'QuotesResponse', named after proc name.
<ws>proc ::stock::Quotes {
    {Symbol:stock::symbol {maxOccurs 3}}
    {Verbose:stock::verbose {minOccurs 0 default 0}}
} {
    set resultList [list]
    foreach symbol $Symbol {
	lappend resultList [Stock $symbol $Verbose]
    }
    return $resultList
} returns {
    {QuotesDummy:elements::stock::StockResponse {maxOccurs 8}}
}

# Example of using just the complexType name as proc args:
<ws>proc ::stock::Stocks {
    StocksToQuote
} {

    set resultList [list]
    foreach symbol $Symbol {
	lappend resultList [Stock $symbol $Verbose]
    }
    return $resultList
} returns StocksQuoted


<ws>namespace set ::stock showDocument 1

<ws>namespace finalize ::stock

#<ws>namespace freeze ::stock

<ws>return ::stock
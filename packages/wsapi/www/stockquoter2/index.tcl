
<ws>namespace init ::stock2

<ws>namespace schema ::stock2 "http://junom.com/ws/stockquoter2"

# simpleTypes for stock2:
<ws>type enum stock2::symbol {MSFT WMT XOM GM F GE}
<ws>type simple stock2::verbose xsd::boolean
<ws>type simple stock2::quote xsd::float
<ws>type enum stock2::trend {-1 0 1} xsd::integer
<ws>type simple stock2::dailyMove xsd::float
<ws>type simple stock2::lastMove xsd::float
<ws>type simple stock2::name
<ws>type simple stock2::dateOfChange xsd::dateTime

# Documentation for simpleType stock2::symbol:
<ws>doc type stock2 symbol "NYSE Trading Symbol"


<ws>proc ::stock2::Stock {
    {Symbol:stock2::symbol}
    {Verbose:stock2::verbose {minOccurs 0 default "1"}}
} {
    
    set StockValue [format %0.2f [expr 25.00 + [ns_rand 4].[format %0.2d [ns_rand 99]]]]
    if {$Verbose} {
	return [list $Symbol $StockValue 2006-04-11T00:00:00Z "SomeName Corp. " 1 0.75 0.10]
    } else {
	return [list $Symbol $StockValue]
    }
    
} returns {  
    {Symbol:stock2::symbol          }
    {Quote:stock2::quote           }
    {DateOfChange:stock2::dateOfChange {minOccurs 0}}
    {Name:stock2::name         {minOccurs 0 nillable true}}
    {Trend:stock2::trend        {minOccurs 0}}
    {DailyMove:stock2::dailyMove    {minOccurs 0}}
    {LastMove:stock2::lastMove     {minOccurs 0}} 
}

# <ws>proc creates StockRequest and StockResponse elements.
# Once they are created, documentation can be added:
<ws>doc element stock2 StockRequest {Defines StockRequest type.
    User supplies NYSE symbol and a verbose flag for additional data.}
<ws>doc element stock2 StockResponse "Current data for the requested
 NYSE Stock is returned"

# Procedure to request quotes on several stocks at one time
# Notice that the return is the complexType StocksResponse which contains
# multiple children of complexType 'StockResponse', created above:
<ws>proc ::stock2::Stocks {
    {Symbol:stock2::symbol {maxOccurs 8 default "MSFT"}}
    {Verbose:stock2::verbose {minOccurs 0 default "1"}}
} {

    set resultList [list]
    foreach symbol $Symbol {
	lappend resultList [Stock $symbol $Verbose]
    }
    return $resultList
} returns {
    {StockResponse:elements::stock2::StockResponse {maxOccurs 8}} 
}


# Documentation for Element StocksRequest
<ws>doc element stock2 StocksRequest {Multiple Stock Symbols in one document.}
<ws>doc element stock2 StocksResponse "Contains multiple StockResponse child
elements, one for each symbol requested"

<ws>namespace set ::stock2 showDocument 1


<ws>namespace finalize ::stock2

#<ws>namespace freeze ::stock2

<ws>return ::stock2
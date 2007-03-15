
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


<ws>element sequence stock::StockResponse {  
    {Symbol       stock::symbol          }
    {Quote        stock::quote           }
    {DateOfChange stock::dateOfChange {minOccurs 0}}
    {Name         stock::name         {minOccurs 0 nillable no}}
    {Trend        stock::trend        {minOccurs 0}}
    {DailyMove    stock::dailyMove    {minOccurs 0}}
    {LastMove     stock::lastMove     {minOccurs 0}}
}


<ws>element sequence stock::StockRequest {
    {Symbol       stock::symbol}
    {Verbose      stock::verbose {minOccurs 0}}
}

<ws>proc ::stock::Stock {Symbol:stock::symbol {Verbose:stock::verbose 0} } {

    set StockValue [format %0.2f [expr 25.00 + [ns_rand 4].[format %0.2d [ns_rand 99]]]]
    if {$Verbose} {
	return [list $Symbol $StockValue 2006-04-11T00:00:00Z "SomeName Corp. " 1 0.75 0.10]
    } else {
	return [list $Symbol $StockValue]
    }

} returns {
    Symbol:stock::symbol
    Quote:stock::quote 
    DateOfChange:stock:dateOfChange
    Name:stock::name
    Trend:stock::trend
    DailyMove:stock::dailyMove
    LastMove:stock::lastMove
}




<ws>namespace finalize ::stock

<ws>namespace freeze ::stock

<ws>return ::stock
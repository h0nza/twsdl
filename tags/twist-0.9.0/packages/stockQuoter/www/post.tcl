set SOAP {<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<StockRequest xmlns="http://stockquoter.com/stockquoter">
 <Symbol>MSFT</Symbol>
 <Verbose>1</Verbose>
</StockRequest>
</soap:Body>
</soap:Envelope>}

set length [string length $SOAP]

set fds [ns_sockopen 192.168.1.102 8005]
set rid [lindex $fds 0]
set wid [lindex $fds 1]
puts $wid "POST /StockQuote HTTP/1.0
Host: maria:8080
Content-Type: text/xml; charset=utf-8
Content-Length: $length
SOAPAction: \"http://stockquoter.com/StockQuote\"

$SOAP"

flush $wid
while {[set line [string trim [gets $rid]]] != ""} {
    lappend headers $line
}
set page [read $rid]
close $rid
close $wid



ns_return 200 text/plain "
Sent:
POST /StockQuote HTTP/1.0
Host: 192.168.1.102:8005
Content-Type: text/xml; charset=utf-8
Content-Length: $length
SOAPAction: \"http://stockquoter.com/StockQuote\"

$SOAP

Received:

[join $headers "\n"]\n\n$page"

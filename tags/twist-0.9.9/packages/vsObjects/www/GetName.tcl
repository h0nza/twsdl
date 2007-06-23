set port 8080
set host maria
set path /VSObject
set soapAction "http://volunteersolutions.org/GetName"
set tns "http://volunteersolutions.org/VSObject"
set bodyElement GetNameRequest

set SOAP {<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">}

set vars [list]
set xmlVarsList [list]

foreach {var default} {ObjectId 224417} {
    set $var [ns_queryget $var $default]
    lappend xmlVarsList "<$var>[set $var]</$var>"
}

append SOAP "
<soap:Body>
<$bodyElement xmlns=\"$tns\">
 [join $xmlVarsList "\n "]
</$bodyElement>
</soap:Body>
</soap:Envelope>"

set length [string length "$SOAP"]

set fds [ns_sockopen maria 8080]
set rid [lindex $fds 0]
set wid [lindex $fds 1]
puts $wid "POST ${path} HTTP/1.0
Host: ${host}:${port}
Content-Type: text/xml; charset=utf-8
Content-Length: $length
SOAPAction: \"$soapAction\"

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
POST ${path} HTTP/1.0
Host: ${host}:${port}
Content-Type: text/xml; charset=utf-8
Content-Length: $length
SOAPAction: \"$soapAction\"

$SOAP

Received:

[join $headers "\n"]\n\n$page"

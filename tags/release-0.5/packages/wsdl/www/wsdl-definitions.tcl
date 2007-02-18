set serverName [ns_queryget s]

set defElement "::wsdb::definitions::${serverName}::definitions"

ns_return 200 text/html "<xmp>[::xml::document::print $defElement]</xmp>

<a href=\"wsdl-to-api.tcl?ns=$defElement\">Create Tcl API with XSLT</a><br>
<a href=\"wsdl-to-api.xsl\">Show XSL Stylesheet</a>
"
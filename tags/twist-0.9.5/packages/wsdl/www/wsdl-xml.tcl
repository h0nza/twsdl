set serverName [ns_queryget s]

set wsdbNamespace ::wsdb

# Check Server Exists:
if {![namespace exists ${wsdbNamespace}::servers::${serverName}]} {
    ns_return 200 text/plain "server $serverName does not exist"
    return -code return
}


# Get Services:
set serviceNames [set ${wsdbNamespace}::servers::${serverName}::services]
set targetNamespace [set ${wsdbNamespace}::servers::${serverName}::targetNamespace]

proc ::wsdl::definitions::new { serverName targetNamespace


# Create WSDL Document:

set docElement [::xml::document::create \
		    ::wsdb::${serverName}::wsdlFile \
		    definitions \
		    wsdl \
		    [list 
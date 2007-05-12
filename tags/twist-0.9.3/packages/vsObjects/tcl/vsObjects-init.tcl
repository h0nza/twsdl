set serverName VSObject

::wsdl::server::new ${serverName} "http://volunteersolutions.org/${serverName}" {VSObjectService}
::wsdl::definitions::new $serverName

set ::wsdb::servers::${serverName}::hostHeaderNames [list  "maria:8080" "192.168.111.108:8080"]

::wsdl::server::listen ${serverName}


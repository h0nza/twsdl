# extra procs for wsclient api

namespace eval ::wsclient::schema {
    
    variable schemaKeyEnum 

    ::tws::nvlist::createEnum schemaKeyEnum schemaAlias schemaNamespace schemaVar

    variable schemaMap {
	{soap-env http://schemas.xmlsoap.org/soap/envelope/ soapEnvelopeNS}
	{soap-enc http://schemas.xmlsoap.org/soap/encoding/ soapEncodingNS}
	{wsdl http://schemas.xmlsoap.org/wsdl/ wsdlNS}
	{wsoap http://schemas.xmlsoap.org/wsdl/soap/ wsdlsoapNS}
	{xsi http://www.w3.org/2001/XMLSchema-instance xmlSchemaInstanceNS}
	{xsd http://www.w3.org/2001/XMLSchema xmlSchemaNS}
    }
    
}

proc ::wsclient::schema::getNamespace {
    schemaVar
} {
    variable schemaMap
    return [::tws::nvlist::filterIndex schemaMap 1 [list * * $schemaVar]]
}
  
proc ::wsclient::schema::getSchemaAlias {
    schemaVar
} {
    variable schemaMap
    return [::tws::nvlist::filterIndex schemaMap 0 [list * * $schemaVar]]
}

proc ::wsclient::schema::namespaceFromAlias { schemaAlias } {
    variable schemaMap
    return [::tws::nvlist::filterIndex schemaMap 1 [list $schemaAlias * *]]
}

proc ::wsclient::schema::aliasFromNamespace { schemaNamespace } {
    variable schemaMap
    return [::tws::nvlist::filterIndex schemaMap 0 [list * $schemaNamespace *]
}

ns_log Notice "xsd = '[::wsclient::schema::namespaceFromAlias xsd]'"
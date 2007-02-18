# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::wsdl::portTypes { 

    namespace import ::tws::log::log

}


proc ::wsdl::portTypes::new {

    portTypeNamespace
    portTypeName
    operationList
} {

    namespace eval ::wsdb::portTypes::${portTypeNamespace} { }
    
    namespace eval ::wsdb::portTypes::${portTypeNamespace}::${portTypeName} {
	variable operations 
    }
    
    set ::wsdb::portTypes::${portTypeNamespace}::${portTypeName}::operations $operationList
}


# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



namespace eval ::wsdl::ports {

    namespace import ::tws::log::log

}

proc ::wsdl::ports::new {
    
    portName
    bindingName
    portAddress
} {

    namespace eval ::wsdb::ports { }
    namespace eval ::wsdb::ports::$portName {
	variable binding
	variable address
    }
    set ::wsdb::ports::${portName}::binding $bindingName
    set ::wsdb::ports::${portName}::address $portAddress

}
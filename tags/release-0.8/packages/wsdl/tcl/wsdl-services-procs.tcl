# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



namespace eval ::wsdl::services {

    namespace import ::tws::log::log

}

proc ::wsdl::services::new {

    serviceName
    args
} {

    namespace eval ::wsdb::services { }
    namespace eval ::wsdb::services::${serviceName} {
	variable ports
    }

    set ::wsdb::services::${serviceName}::ports $args
}
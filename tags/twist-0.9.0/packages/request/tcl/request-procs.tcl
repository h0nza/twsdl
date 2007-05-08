# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::request {

    variable requestID 0
    namespace import ::tws::log::log
    

}


proc ::request::cleanup { requestID } {

    file delete [set ::request::${requestID}::postFilename]
    namespace delete ::request::$requestID
    log Notice "::request::cleanup removed request $requestID"

}

proc ::request::new { 
    
    requestHeaders 
    postFilename 
    requestArgs
} {
    
    variable requestID
    set requestID [incr requestID]
    namespace eval ::request::$requestID {
	variable requestHeaders
	variable postFilename
	variable requestArgs
    }
    
    set ::request::${requestID}::requestHeaders $requestHeaders
    set ::request::${requestID}::postFilename $postFilename
    set ::request::${requestID}::requestArgs $requestArgs
    ns_atclose "::request::cleanup $requestID"
    return $requestID
}
# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::xml::document {

}


# Used to initialize an xml document
proc ::xml::document::create { 
    tclNamespace 
    documentElement 
    {prefix {}} 
    {attributeList {}}
} {


    namespace eval $tclNamespace {
	variable documentElement
    }

    ::xml::element::create ${tclNamespace}::$documentElement $prefix

    array set ${tclNamespace}::${documentElement}::.ATTR $attributeList

    set ${tclNamespace}::documentElement $documentElement

    return ${tclNamespace}::$documentElement

}

proc ::xml::document::print { documentNamespace {printer "toXMLNS"} } {

    return "<?xml version=\"1.0\" encoding=\"utf-8\"?>[::xml::instance::$printer $documentNamespace]"

}
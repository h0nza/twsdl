# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::xml::document {
    namespace import ::tws::log::log
}


# Used to initialize an xml document
proc ::xml::document::create { 
    tclNamespace 
    documentElement 
    {prefix {}} 
    {attributeList {}}
} {

    log Debug "Creating XML Document in tclns $tclNamespace with de = $documentElement p = $prefix a = $attributeList"

    namespace eval $tclNamespace {
	variable documentElement
    }

    ::xml::element::create ${tclNamespace}::$documentElement $documentElement $prefix $attributeList

    set ${tclNamespace}::documentElement $documentElement

    return ${tclNamespace}::$documentElement

}

proc ::xml::document::print { documentNamespace {printer "toXMLNS"} } {
    set documentElement [set ${documentNamespace}::documentElement]
    log Debug "documentNamespace = $documentNamespace"
    return "<?xml version=\"1.0\" encoding=\"utf-8\"?>[::xml::instance::$printer ${documentNamespace}::$documentElement]"

}
# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::wsdl::schema {

    variable initialized 0
    namespace import ::tws::log::log
    
}

proc ::wsdl::schema::initDatabase { } {

    variable initialized

    if {!$initialized} {
	set initialized [::wsdb::schema::init]
    }
    if {!$initialized} {
	log Error "initDatabase unable to initialize schema database"
    }
    return $initialized
}


proc ::wsdl::schema::new { schemaAlias targetNamespace} {

    variable initialized

    if {!$initialized} {
	initDatabase
    }
    ::wsdb::schema::appendAliasMap [list $schemaAlias $targetNamespace]
    namespace eval ::wsdb::schema::$schemaAlias {
	variable schemaItems [list]
	variable targetNamespace
    }
    set ::wsdb::schema::${schemaAlias}::targetNamespace $targetNamespace

}
	

proc ::wsdl::schema::appendSimpleType {
    type
    schemaAlias
    name
    {base xsd::string}
    {data ""}
} {
    lappend ::wsdb::schema::${schemaAlias}::schemaItems $name
    set typeNS ::wsdb::schema::${schemaAlias}::${name}

    namespace eval $typeNS {
        variable type
        variable base
	variable baseAlias
        variable data
    }
    set ${typeNS}::type $type
    set ${typeNS}::base [namespace tail $base]
    set ${typeNS}::baseAlias [namespace qualifiers $base]
    set ${typeNS}::data $data
    
}

# Assumes all restrictions have been done on the base type,
# This creates an element out of a type.
proc ::wsdl::schema::addElement {
    schemaAlias
    name
    {base xsd::string} 
} {

    lappend ::wsdb::schema::${schemaAlias}::schemaItems $name
    set typeNS ::wsdb::schema::${schemaAlias}::${name}

    namespace eval $typeNS {
        variable type element
        variable base
	variable baseAlias
    }

    set ${typeNS}::base [namespace tail $base]
    set ${typeNS}::baseAlias [namespace qualifiers $base]
}

# addChildElements creates element with base type and parent sequence
# then uses the child element type
proc ::wsdl::schema::addSequence {
    schemaAlias
    name
    elementList
    {makeChildGlobalType 0}
} {


    set typeNS ::wsdb::schema::${schemaAlias}::${name}

    namespace eval $typeNS {
        variable type sequence
	variable childList [list]
    }

    foreach elementData $elementList {
	foreach {elementName base minOccurs maxOccurs facetList} $elementData { }
	lappend ${typeNS}::childList $elementName
	set elementNS ${typeNS}::$elementName

	namespace eval $elementNS {
	    variable .ATTR
	}

	if {$makeChildGlobalType} {
	    if {[lsearch -exact [set ::wsdb::schema::${schemaAlias}::schemaItems] $elementName ] == -1} {
		::wsdl::schema::addElement $schemaAlias $elementName $base
		set base ${schemaAlias}::$elementName
	    } else {
		ns_log Notice "schemaItems: '[set ::wsdb::schema::${schemaAlias}::schemaItems]' elem = '$elementName'"
	    }
	}
	set ${elementNS}::base [namespace tail $base]
	set ${elementNS}::baseAlias [namespace qualifiers $base]

	if {"$minOccurs" eq ""} {
	    set minOccurs 1
	}
	if {"$maxOccurs" eq ""} {
	    set maxOccurs 1
	}

	set ${elementNS}::.ATTR(minOccurs) $minOccurs
	set ${elementNS}::.ATTR(maxOccurs) $maxOccurs

	foreach {facet value} $facetList {
	    set ${elementNS}::.ATTR($facet) "$value"
        }
    }

    lappend ::wsdb::schema::${schemaAlias}::schemaItems $name 

}

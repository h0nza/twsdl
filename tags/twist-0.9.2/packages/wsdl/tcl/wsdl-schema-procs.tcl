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

    set schemaAlias [string trim $schemaAlias :]

    if {[::wsdb::schema::aliasExists $schemaAlias]} {
	if {[::wsdb::schema::getTargetNamespace $schemaAlias] ne "$targetNamespace"} {
	    log Error "wsdl::schema::new attempt to use $schemaAlias for new targetNamespace '$targetNamespace'"
	    return -code error
	} 
	log Debug "wsdl::schema::new alias $schemaAlias already exists"
	return
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

    ::wsdb::schema::addSchemaItem $schemaAlias $name
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

    ::wsdb::schema::addSchemaItem $schemaAlias $name

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

    foreach element $elementList {
	if {[array exists elementData]} {
	    array unset elementData
	}
	set elementName [::wsdl::elements::modelGroup::sequence::getElementData $element elementData]
	set base $elementData(type)
	set minOccurs $elementData(minOccurs)
	set maxOccurs $elementData(maxOccurs)
	set facetList $elementData(facets)
	
	lappend ${typeNS}::childList $elementName
	set elementNS ${typeNS}::$elementName

	namespace eval $elementNS {
	    variable .ATTR
	}

	if {$makeChildGlobalType} {
	    if {![::wsdb::schema::schemaItemExists $schemaAlias $elementName]} {
		::wsdl::schema::addElement $schemaAlias $elementName $base
		set base ${schemaAlias}::$elementName
	    } else {
		log Notice "schemaItems: '[set ::wsdb::schema::${schemaAlias}::schemaItems]' elem = '$elementName'"
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

    ::wsdb::schema::addSchemaItem $schemaAlias $name

    return $typeNS
}

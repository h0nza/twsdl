set sqns "stockquoter"



namespace eval ::wsdl::schema {

    variable initialized 0
    
}

namespace eval ::wsdb::schema {

    variable aliasMap
    variable initialized 0

}

proc ::wsdb::schema::init { } {

    variable aliasMap
    variable initialized

    set aliasMap [list]
    set initialized 1

    return $initialized
}

proc ::wsdb::schema::appendAliasMap { mapping } {

    variable aliasMap
    lappend aliasMap $mapping
}

proc ::wsdb::schema::getAlias { targetNamespace } {

    variable aliasMap
    set aliasMapping [lsearch -inline $aliasMap [list "*" "$targetNamespace"]]
    return [lindex $aliasMapping 0]
}
proc ::wsdb::schema::getTargetNamespace { alias } {

    variable aliasMap
    set aliasMapping [lsearch -inline $aliasMap [list "$alias" "*"]]
    return [lindex $aliasMapping 1]
}
				     

proc ::wsdl::schema::initDatabase { } {

    variable initialized

    if {!$initialized} {
	set initialized [::wsdb::schema::init]
    }
}


proc ::wsdl::schema::new { schemaAlias targetNamespace} {

    variable initialized

    if {!$initialized} {
	initDatabase
    }
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
    {base tcl::string}
    {data ""}
} {
    lappend ::wsdb::schema::${schemaAlias}::schemaItems $name
    set typeNS ::wsdb::schema::${schemaAlias}::${name}

    namespace eval $typeNS {
        variable type
        variable base
        variable data
    }
    set ${typeNS}::type $type
    set ${typeNS}::base $base
    set ${typeNS}::data $data
    
}

# Assumes all restrictions have been done on the base type,
# This creates an element out of a type.
proc ::wsdl::schema::addElement {
    schemaAlias
    name
    {base tcl::string} 
} {

    lappend ::wsdb::schema::${schemaAlias}::schemaItems $name
    set typeNS ::wsdb::schema::${schemaAlias}::${name}

    namespace eval $typeNS {
        variable type element
        variable base
    }

    set ${typeNS}::base $base
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
	    variable base
	    variable minOccurs
	    variable maxOccurs
	}

	if {$makeChildGlobalType} {
	    if {[lsearch -exact [set ::wsdb::schema::${schemaAlias}::schemaItems] $elementName ] == -1} {
		::wsdl::schema::addElement $schemaAlias $elementName $base
		set base ${schemaAlias}::$elementName
	    } else {
		ns_log Notice "schemaItems: '[set ::wsdb::schema::${schemaAlias}::schemaItems]' elem = '$elementName'"
	    }
	}
	set ${elementNS}::base $base
	set ${elementNS}::minOccurs $minOccurs
	set ${elementNS}::maxOccurs $maxOccurs

	foreach {facet value} $facetList {
	    namespace eval $elementNS [list variable $facet $value]
        }
    }

    lappend ::wsdb::schema::${schemaAlias}::schemaItems $name 

}




set schemaPath ::wsdb::schema::$sqns


::wsdl::schema::new "$sqns" "http://www.united-e-way.org"
::wsdl::schema::appendSimpleType enumeration $sqns symbol tcl::string {MSFT WMT XOM GM F GE}
::wsdl::schema::appendSimpleType simple $sqns verbose tcl::boolean 
::wsdl::schema::appendSimpleType simple $sqns quote tcl::double
::wsdl::schema::appendSimpleType simple $sqns dateOfChange tcl::dateTime
::wsdl::schema::appendSimpleType enumeration $sqns trend tcl::integer {-1 0 1}
::wsdl::schema::appendSimpleType simple $sqns dailyMove tcl::double
::wsdl::schema::appendSimpleType simple $sqns lastMove tcl::double
::wsdl::schema::appendSimpleType simple $sqns name tcl::string
::wsdl::schema::appendSimpleType enumeration $sqns faultCode tcl::integer {404 500 301}

::wsdl::schema::addSequence $sqns StockQuote {
  {Symbol       stockquoter::symbol          }
  {Quote        stockquoter::quote           }
  {DateOfChange stockquoter::dateOfChange 0  }
  {Name         stockquoter::name         0  1 {nillable no}}
  {Trend        stockquoter::trend        0  }
  {DailyMove    stockquoter::dailyMove    0  }
  {LastMove     stockquoter::lastMove     0  }
} 0


### Convert schema to XML:







ns_return 200 text/plain "[set ${schemaPath}::schemaItems]"


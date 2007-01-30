# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::wsdb::schema {

    variable aliasMap
    variable initialized 0

}

proc ::wsdb::schema::init { } {

    variable aliasMap
    variable initialized

    if {!$initialized} {
	set aliasMap [list]
	set initialized 1
    }
    return $initialized
}

proc ::wsdb::schema::appendAliasMap { mapping } {

    variable aliasMap
    variable initialized

    if {!$initialized} {
	init
    }
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

proc ::wsdb::schema::aliasExists { alias } {

    variable aliasMap
    if {[lsearch $aliasMap [list "$alias" "*"]] > -1} {
	return 1
    } else {
	return 0
    }
}

proc ::wsdb::schema::schemaItemExists { schema item } {

    if {[lsearch [set ::wsdb::schema::${schema}::schemaItems] $item] > -1} {
	return 1
    } else {
	return 0
    }
}

proc ::wsdb::schema::addSchemaItem { schema item } {

    if {[schemaItemExists $schema $item]} {
	return 0
    } else {
	lappend ::wsdb::schema::${schema}::schemaItems $item
	return 1
    }
}
				     

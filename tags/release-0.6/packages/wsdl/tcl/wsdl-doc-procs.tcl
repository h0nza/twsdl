# Procedures to help document procedures, elements and types used
# in wsdl.
# Also procedures to add valid and invalid examples of types, elements, docs
# Note that valid and invalid values can be used to perform tests
namespace eval ::wsdl::doc {
    variable docVars [list doc valid invalid]
    variable load
    variable docNamespace "::wsdb"
    variable docAllowed [list types elements messages operations porttypes services]
    # Global method of turning off documentation
    variable DoDocument 1
    foreach Var $docVars {
	set load($Var) 0
    }
    
    namespace import ::tws::log::log

}

proc ::wsdl::doc::document { var what namespace name docString } {

    variable docVars
    variable docAllowed
    variable docNamespace
    variable DoDocument

    # check that var is in docVars
    if {[lsearch $docVars "$var"] < 0} {
	log Error "::wsdl::doc::document attempt to document $var for $what $namespace $name"
    }

    # check that what is in docAllowed
    if {[lsearch $docAllowed $what] < 0} {
	log Error "::wsdl::doc::document attempt to document $what for $namespace $name limited to $docAllowed"
    }

    if {$DoDocument} {
	lappend ${docNamespace}::${what}::${namespace}::${name}::${var} $docString
	log Notice "documented '${docNamespace}::${what}::${namespace}::${name}::${var}'"
    }

}
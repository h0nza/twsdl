

# This sets all documentation on:
namespace eval ::wsdl::doc {
    
    variable DoDocument 
    variable docVars

    set DoDocument 1
    foreach var $docVars {
	set load($var) 1
    }
}


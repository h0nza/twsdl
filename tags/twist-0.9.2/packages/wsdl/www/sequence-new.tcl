

# Purpose of new2 (temp name) is to work around potential
# name collision of element names which only appear within
# a global element.

set sqns "stockquoter"



proc ::wsdl::elements::modelGroup::sequence::new-old { 

    schemaAlias 
    typeName
    simpleTypesList
} {

    set script ""
    set Elements [list]
    # First Element to simpleType validation procs
    append script "
namespace eval ::wsdb::elements::$schemaAlias \{\}
namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{\}"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {
	    lappend Elements $Element
	}
	set TypeTail [namespace tail $Type]
	append script "

namespace eval ::wsdb::elements::${schemaAlias}::${typeName}::$Element \{
    variable validate \[namespace code \{Validate\}\]
    variable validate_$TypeTail \$::wsdb::types::${Type}::validate

    proc Validate \{ namespace \} \{
        variable validate_$TypeTail
        set Valid \[\$validate_$TypeTail \[::xml::instance::getTextValue \$namespace\]\]

        if \{!\$Valid\} \{
            ::wsdl::elements::noteFault \$namespace \[list 1 $Element \[::xml::instance::getTextValue \$namespace\] \$validate_$TypeTail \]
        \}
        return \$Valid
    \}
\}"

    }

 
    # Create Type Tcl Namespace
    append script "
namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{

    variable MinOccurs
    variable MaxOccurs
    variable validate \[namespace code \{Validate${typeName}\}\]"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	append script "
    variable validate_$Element \$\{::wsdb::elements::${schemaAlias}::${typeName}::${Element}::validate\}"
    }

    foreach simpleType $simpleTypesList {

	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}

	if {"$MinOccurs" eq ""} {
	    append script "
    set MinOccurs($Element) 1"
	} else {
	    append script "
    set MinOccurs($Element) $MinOccurs"
	}
	if {"$MaxOccurs" eq ""} {
	    append script "
    set MaxOccurs($Element) 1"
	} else {
	    append script "
    set MaxOccurs($Element) $MaxOccurs"
	}
	
    }

    # Conversion List Used for Invoke procedure
    append script "
    variable conversionList \{[join $Elements { Value }] Value\}"

    # Foreach with switch, probably change to foreach with loops.

    append script "
    
    proc Validate$typeName \{ namespace \} \{

        variable MinOccurs
        variable MaxOccurs"

    foreach Element $Elements {
	append script "
        variable validate_$Element"
    }

    foreach Element $Elements {
	append script "
        set Count($Element) 0"
    }

    append script "
        set Count(.INVALID) 0

        set parts \[set \$\{namespace\}::.PARTS\]

        foreach part \$parts \{
            switch -glob -- \"\$part\" \{"

    foreach Element $Elements {
	append script "
                $Element - ${Element}::* \{
                    if \{!\[\$validate_$Element \$\{namespace\}::$Element\]\} \{  
                        ::wsdl::elements::noteFault \$namespace \[list 2 $Element \$Count($Element)\]
                        incr Count(.INVALID)
                        break
                    \} else \{
                        incr Count($Element)
                    \}
                \}"

    }
    append script "
                default \{
                    ::wsdl::elements::noteFault \$namespace \[list 3 \$part \[lsearch -exact \$parts \$part\]\]                    
                    incr Count(.INVALID)
                \}
            \}
        \}

        if \{\$Count(.INVALID)\} \{
            return 0
        \}
        foreach element \{$Elements\} \{
            if \{\$Count(\$element) < \$MinOccurs(\$element)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 4 \$element \$Count(\$element) \$MinOccurs(\$element)\]
                incr Count(.INVALID)
                continue
            \}
            if \{\$Count(\$element) > \$MaxOccurs(\$element)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 5 \$element \$Count(\$element) \$MaxOccurs(\$element)\]
                incr Count(.INVALID)
                continue
            \}
        \}
        if \{\$Count(.INVALID)\} \{
            return 0
        \} else \{
            return 1
        \}
    \}
\}"

    append script "
proc ::wsdb::elements::${schemaAlias}::${typeName}::new \{ 

    instanceNamespace 
    args
\} \{"
    set ElementCount [llength $Elements]
    for {set ElementIndex 0} {$ElementIndex < $ElementCount} {incr ElementIndex} {
           append script "
    set [lindex $Elements $ElementIndex] \[lindex \$args $ElementIndex\]"
    }
    append script "
    namespace eval \$\{instanceNamespace\} \{ \}
    namespace eval \$\{instanceNamespace\}::$typeName \{
    
        set .PARTS \[list\]
    \}"
        
    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	if {[string is integer -strict $MaxOccurs] && $MaxOccurs > 1} {
	    error "MaxOccurs needs to be 1 to use this API"
	} elseif {"$MinOccurs" eq "0"} {
	    append script "
    if \{\$$Element ne \"\"\} \{
            namespace eval \$\{instanceNamespace\}::${typeName}::$Element \{
            set .PARTS \{.TEXT(0)\}

        \}
        set \$\{instanceNamespace\}::${typeName}::${Element}::.TEXT(0) \"\$$Element\"
        lappend \$\{instanceNamespace\}::${typeName}::.PARTS $Element
    \}"
	} else {
	    append script "
    namespace eval \$\{instanceNamespace\}::${typeName}::$Element \{
        set .PARTS \{.TEXT(0)\}

    \}
    set \$\{instanceNamespace\}::${typeName}::${Element}::.TEXT(0) \"\$$Element\"
    lappend \$\{instanceNamespace\}::${typeName}::.PARTS $Element"
	}
    }
    append script "
    return \$\{instanceNamespace\}::${typeName}
\}"
    
    return $script 
}



proc ::wsdl::elements::modelGroup::sequence::new2 { 

    namespace 
    typeName
    simpleTypesList
} {
    # Creates a script and executes it????
    set script ""
    set Elements [list]
    # First Element to simpleType validation procs
    append script "
namespace eval ::wsdb::elements::$namespace \{\}"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {
	    lappend Elements $Element
	}
	set TypeTail [namespace tail $Type]
	append script "

namespace eval ::wsdb::elements::${namespace}::$Element \{
    variable validate \[namespace code \{Validate\}\]
    variable validate_$TypeTail \$::wsdb::types::${Type}::validate

    proc Validate \{ namespace \} \{
        variable validate_$TypeTail
        set Valid \[\$validate_$TypeTail \[::xml::instance::getTextValue \$namespace\]\]

        if \{!\$Valid\} \{
            ::wsdl::elements::noteFault \$namespace \[list 1 $Element \[::xml::instance::getTextValue \$namespace\] \$validate_$TypeTail \]
        \}
        return \$Valid
    \}
\}"

    }

 
    # Create Type Tcl Namespace
    append script "
namespace eval ::wsdb::elements::${namespace}::$typeName \{

    variable MinOccurs
    variable MaxOccurs
    variable validate \[namespace code \{Validate${typeName}\}\]"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	append script "
    variable validate_$Element \$\{::wsdb::elements::${namespace}::${Element}::validate\}"
    }

    foreach simpleType $simpleTypesList {

	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}

	if {"$MinOccurs" eq ""} {
	    append script "
    set MinOccurs($Element) 1"
	} else {
	    append script "
    set MinOccurs($Element) $MinOccurs"
	}
	if {"$MaxOccurs" eq ""} {
	    append script "
    set MaxOccurs($Element) 1"
	} else {
	    append script "
    set MaxOccurs($Element) $MaxOccurs"
	}
	
    }

    # Conversion List Used for Invoke procedure
    append script "
    variable conversionList \{[join $Elements { Value }] Value\}"

    # Foreach with switch, probably change to foreach with loops.

    append script "
    
    proc Validate$typeName \{ namespace \} \{

        variable MinOccurs
        variable MaxOccurs"

    foreach Element $Elements {
	append script "
        variable validate_$Element"
    }

    foreach Element $Elements {
	append script "
        set Count($Element) 0"
    }

    append script "
        set Count(.INVALID) 0

        set parts \[set \$\{namespace\}::.PARTS\]

        foreach part \$parts \{
            switch -glob -- \"\$part\" \{"

    foreach Element $Elements {
	append script "
                $Element - ${Element}::* \{
                    if \{!\[\$validate_$Element \$\{namespace\}::$Element\]\} \{  
                        ::wsdl::elements::noteFault \$namespace \[list 2 $Element \$Count($Element)\]
                        incr Count(.INVALID)
                        break
                    \} else \{
                        incr Count($Element)
                    \}
                \}"

    }
    append script "
                default \{
                    ::wsdl::elements::noteFault \$namespace \[list 3 \$part \[lsearch -exact \$parts \$part\]\]                    
                    incr Count(.INVALID)
                \}
            \}
        \}

        if \{\$Count(.INVALID)\} \{
            return 0
        \}
        foreach element \{$Elements\} \{
            if \{\$Count(\$element) < \$MinOccurs(\$element)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 4 \$element \$Count(\$element) \$MinOccurs(\$element)\]
                incr Count(.INVALID)
                continue
            \}
            if \{\$Count(\$element) > \$MaxOccurs(\$element)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 5 \$element \$Count(\$element) \$MaxOccurs(\$element)\]
                incr Count(.INVALID)
                continue
            \}
        \}
        if \{\$Count(.INVALID)\} \{
            return 0
        \} else \{
            return 1
        \}
    \}
\}"

    append script "
proc ::wsdb::elements::${namespace}::${typeName}::new \{ 

    instanceNamespace 
    childElementValues
\} \{

    foreach \{[join $Elements { }]\} \$childElementValues \{\}

    namespace eval \$\{instanceNamespace\} \{ \}
    namespace eval \$\{instanceNamespace\}::$typeName \{
    
        set .PARTS \[list\]
    \}"
        
    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	if {[string is integer -strict $MaxOccurs] && $MaxOccurs > 1} {
	    error "MaxOccurs needs to be 1 to use this API"
	} elseif {"$MinOccurs" eq "0"} {
	    append script "
    if \{\$$Element ne \"\"\} \{
            namespace eval \$\{instanceNamespace\}::${typeName}::$Element \{
            set .PARTS \{.TEXT(0)\}

        \}
        set \$\{instanceNamespace\}::${typeName}::${Element}::.TEXT(0) \"\$$Element\"
        lappend \$\{instanceNamespace\}::${typeName}::.PARTS $Element
    \}"
	} else {
	    append script "
    namespace eval \$\{instanceNamespace\}::${typeName}::$Element \{
        set .PARTS \{.TEXT(0)\}

    \}
    set \$\{instanceNamespace\}::${typeName}::${Element}::.TEXT(0) \"\$$Element\"
    lappend \$\{instanceNamespace\}::${typeName}::.PARTS $Element"
	}
    }
    append script "
    return \$\{instanceNamespace\}::${typeName}
\}"
    
    return $script 
}



proc ::wsdl::elements::modelGroup::sequence::new { 

    schemaAlias 
    typeName
    simpleTypesList
} {

    set script ""
    set Elements [list]
    # First Element to simpleType validation procs
    append script "
namespace eval ::wsdb::elements::$schemaAlias \{\}
namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{\}"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {
	    lappend Elements $Element
	}
	set TypeTail [namespace tail $Type]
	append script "

namespace eval ::wsdb::elements::${schemaAlias}::${typeName}::$Element \{
    variable validate \[namespace code \{Validate\}\]
    variable validate_$TypeTail \$::wsdb::types::${Type}::validate

    proc Validate \{ namespace \} \{
        variable validate_$TypeTail
        set Valid \[\$validate_$TypeTail \[::xml::instance::getTextValue \$namespace\]\]

        if \{!\$Valid\} \{
            ::wsdl::elements::noteFault \$namespace \[list 1 $Element \[::xml::instance::getTextValue \$namespace\] \$validate_$TypeTail \]
        \}
        return \$Valid
    \}
\}"

    }

 
    # Create Type Tcl Namespace
    append script "
namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{

    variable MinOccurs
    variable MaxOccurs
    variable validate \[namespace code \{Validate${typeName}\}\]"

    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	append script "
    variable validate_$Element \$\{::wsdb::elements::${schemaAlias}::${typeName}::${Element}::validate\}"
    }

    foreach simpleType $simpleTypesList {

	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}

	if {"$MinOccurs" eq ""} {
	    append script "
    set MinOccurs($Element) 1"
	} else {
	    append script "
    set MinOccurs($Element) $MinOccurs"
	}
	if {"$MaxOccurs" eq ""} {
	    append script "
    set MaxOccurs($Element) 1"
	} else {
	    append script "
    set MaxOccurs($Element) $MaxOccurs"
	}
	
    }

    # Conversion List Used for Invoke procedure
    append script "
    variable conversionList \{[join $Elements { Value }] Value\}"

    # Foreach with switch, probably change to foreach with loops.

    append script "
    
    proc Validate$typeName \{ namespace \} \{

        variable MinOccurs
        variable MaxOccurs"

    foreach Element $Elements {
	append script "
        variable validate_$Element"
    }

    foreach Element $Elements {
	append script "
        set Count($Element) 0"
    }

    append script "
        set Count(.INVALID) 0

        set parts \[set \$\{namespace\}::.PARTS\]

        foreach part \$parts \{
            switch -glob -- \"\$part\" \{"

    foreach Element $Elements {
	append script "
                $Element - ${Element}::* \{
                    if \{!\[\$validate_$Element \$\{namespace\}::$Element\]\} \{  
                        ::wsdl::elements::noteFault \$namespace \[list 2 $Element \$Count($Element)\]
                        incr Count(.INVALID)
                        break
                    \} else \{
                        incr Count($Element)
                    \}
                \}"

    }
    append script "
                default \{
                    ::wsdl::elements::noteFault \$namespace \[list 3 \$part \[lsearch -exact \$parts \$part\]\]                    
                    incr Count(.INVALID)
                \}
            \}
        \}

        if \{\$Count(.INVALID)\} \{
            return 0
        \}
        foreach element \{$Elements\} \{
            if \{\$Count(\$element) < \$MinOccurs(\$element)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 4 \$element \$Count(\$element) \$MinOccurs(\$element)\]
                incr Count(.INVALID)
                continue
            \}
            if \{\$Count(\$element) > \$MaxOccurs(\$element)\} \{
                ::wsdl::elements::noteFault \$namespace \[list 5 \$element \$Count(\$element) \$MaxOccurs(\$element)\]
                incr Count(.INVALID)
                continue
            \}
        \}
        if \{\$Count(.INVALID)\} \{
            return 0
        \} else \{
            return 1
        \}
    \}
\}"

    append script "
proc ::wsdb::elements::${schemaAlias}::${typeName}::new \{ 

    instanceNamespace 
    childValuesList
\} \{"
    set ElementCount [llength $Elements]
    if {$ElementCount == 1} {
        append script "
    set [lindex $Elements 0] \$childValuesList"
    } elseif {$ElementCount > 1} {
        append script "
    foreach \{$Elements\} \$childValuesList \{ \}"
    }
    append script "
    namespace eval \$\{instanceNamespace\} \{ \}
    namespace eval \$\{instanceNamespace\}::$typeName \{
    
        set .PARTS \[list\]
    \}"
        
    foreach simpleType $simpleTypesList {
	foreach {Element Type MinOccurs MaxOccurs FacetList} $simpleType {}
	if {[string is integer -strict $MaxOccurs] && $MaxOccurs > 1} {
	    error "MaxOccurs needs to be 1 to use this API"
	} elseif {"$MinOccurs" eq "0"} {
	    append script "
    if \{\$$Element ne \"\"\} \{
            namespace eval \$\{instanceNamespace\}::${typeName}::$Element \{
            set .PARTS \{.TEXT(0)\}

        \}
        set \$\{instanceNamespace\}::${typeName}::${Element}::.TEXT(0) \"\$$Element\"
        lappend \$\{instanceNamespace\}::${typeName}::.PARTS $Element
    \}"
	} else {
	    append script "
    namespace eval \$\{instanceNamespace\}::${typeName}::$Element \{
        set .PARTS \{.TEXT(0)\}

    \}
    set \$\{instanceNamespace\}::${typeName}::${Element}::.TEXT(0) \"\$$Element\"
    lappend \$\{instanceNamespace\}::${typeName}::.PARTS $Element"
	}
    }
    append script "
    return \$\{instanceNamespace\}::${typeName}
\}"
    
    return $script 
}



set result [::wsdl::elements::modelGroup::sequence::new $sqns StockQuote {
  {Symbol       stockquoter::symbol          }
  {Quote        stockquoter::quote           }
  {DateOfChange stockquoter::dateOfChange 0  }
  {Name         stockquoter::name         0 1 {nillable no}}
  {Trend        stockquoter::trend        0  }
  {DailyMove    stockquoter::dailyMove    0  }
  {LastMove     stockquoter::lastMove     0  }
}]


ns_return 200 text/plain "$result"


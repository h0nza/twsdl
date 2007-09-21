# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



namespace eval ::wsdl::types { }
namespace eval ::wsdl::types::primitiveType { }

namespace eval ::wsdl::types::simpleType {
    
    namespace import ::tws::log::log
}

namespace eval ::wsdl::types::complexType { }

# addSimpleType, newPrimitiveType and restrictByEnumeration create types
# and validate method to check validation.
# Enumerated types and simple types are based upon primitive types.

proc ::wsdl::types::simpleType::new {tns typeName {base "tcl::anySimpleType"} } {

    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base "$base"]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace current\]::validate"
    
    proc ::wsdb::types::${tns}::${typeName}::validate { value } "
       variable base
       if {\[::wsdb::types::\${base}::validate \$value]} { 
           return 1
       } else { 
           return 0
       }"

    ::wsdl::schema::appendSimpleType simple $tns $typeName $base
} 


proc ::wsdl::types::primitiveType::new {tns typeName code description} {

    namespace eval ::wsdb::types::${tns}::$typeName [list variable description "$description"]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace current\]::validate"

    proc ::wsdb::types::${tns}::${typeName}::validate { value } $code
}



proc ::wsdl::types::simpleType::restrictString {
    tns
    typeName
    baseType
    restrictionList
} {
    
    set allowedRestrictions {
	length
	minLength
	maxLength
	pattern
	whiteSpace
    }
    
    
    array set Restrictions $restrictionList
    
    set restrictionNames [array names Restrictions]
    
    # Check a few structural errors:
    # See <http://www.w3.org/TR/xmlschema-2/#length-coss>
    # In general, users should not use length with either
    # minLength or maxLength, as these must correspond to
    # some prior base type. These will be checked when the
    # input value undergoes base type validation. 
    # Resulting code generated may therefore skip
    # these facets.
    
    # whitespace: apparently XML 1.0 requires preserve,
    # Sooooo... This will be ignored for now, but...
    # NOTE: numeric values apply collapse (string trim)
    
    set baseNamespace ::wsdb::types::${baseType}
    
    foreach restrictionName $restrictionNames {
	if {[lsearch -exact $allowedRestrictions $restrictionName] == -1} {
	    return -code error "unknown restriction $restrictionName your\
 choices are [join $allowedRestrictions ", "]"
	}
	
	
	switch -exact -- $restrictionName {
	    
	    length {
		# TODO: update with more exact integer 
		if {![string is integer -strict $Restrictions(length)]} {
		    return -code error "value for length is not an integer"
		}
		if {[info exists ${baseNamespace}::length]} {
		    if {[set ${baseNamespace}::length] != $Restrictions(length)} {
			return -code error "value for length ($Restrictions(length))\
 must equal base type length ([set ${baseNamespace}::length])"
		    }
		}
	    }
	    maxLength {
		if {![string is integer -strict $Restrictions(maxLength)]} {
		    return -code error "value for maxLength is not an integer"
		}
	    }
	    minLength {
		if {![string is integer -strict $Restrictions(minLength)]} {
		    return -code error "value for minLength is not an integer"
		}
	    }
	    pattern {
		if {[catch {regexp $Restrictions(pattern) abc} errorMsg]} {
		    return -code error "failed pattern test on $tns $typeName $errorMsg"
		}
	    }
	    whitespace {
		if {[lsearch -exact {preserve replace collapse} $Restrictions(whitespace)] == -1} {
		    return -code error "whitespace must be one of preserve, replace or collapse"
		}
	    }
	}
    }
    
    # InterFacet error
    if {[info exists Restrictions(minLength)] && [info exists Restrictions(maxLength)]} {
	if {$Restrictions(minLength) > $Restrictions(maxLength)} {
	    return -code error "minLength ($Restrictions(minLength)) greater\
 than maxLength ($Restrictions(maxLength))"
	}
    }
    
    # All structural requirements are met for restriction of string type...
    log Notice "Looks Okay! Making restricting type $baseType to $tns $typeName"
    
    
    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base $baseType]
    
    set restrictionVarScriptList [list]
    # Add namespace vars for restrictions
    foreach restrictionName $restrictionNames {
	namespace eval ::wsdb::types::${tns}::${typeName} [list variable $restrictionName $Restrictions($restrictionName)]
	lappend restrictionVarScriptList "    variable $restrictionName"
    }
    
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace current\]::validate"
    
    
    set scriptBody "
    variable base
[join $restrictionVarScriptList "\n"]

    if \{\"\$errorListVar\" ne \"\"\} \{
        upvar \$errorListVar errorList
    \}

    set valid 0
    set errorList \[list \$value\]
 
    while \{1\} \{
        if \{!\[::wsdb::types::\$\{base\}::validate \$value\]\} \{
            lappend errorList \"failed base test \$base\" 
            break
        \}
        set valueLength \[string length \$value\]"
    
    if {[info exists Restrictions(length)]} {
        append scriptBody "
        if \{\$valueLength != $Restrictions(length)\} \{
            lappend errorList \"failed length test foundLength (\$valueLength) != length ($Restrictions(length))\"
            break
        \}"
    }
    if {[info exists Restrictions(minLength)]} {
        append scriptBody "
	if \{\$valueLength < $Restrictions(minLength)\} \{
            lappend errorList \"failed minLength test foundLength (\$valueLength) < minLength ($Restrictions(minLength))\"
            break
        \}"
    }
    if {[info exists Restrictions(maxLength)]} {
        append scriptBody "
        if \{\$valueLength > $Restrictions(maxLength)\} \{
            lappend errorList \"failed maxLength test foundLength (\$valueLength) > maxLength ($Restrictions(maxLength))\"
            break
        \}"
    }
     
    # pattern
    if {[info exists Restrictions(pattern)]} {
	append scriptBody "
	if \{!\[regexp \$pattern \$value\]\} \{
lappend errorList \"failed pattern test using \[list \$pattern\]\"
            break
        \}"
    }

    append scriptBody "
        set valid 1
        break
    \}

    return \$valid\n"

    proc ::wsdb::types::${tns}::${typeName}::validate { value {errorListVar ""} } $scriptBody
    ::wsdl::schema::appendSimpleType string $tns $typeName $baseType $restrictionList

}



proc ::wsdl::types::simpleType::restrictDecimal {
    tns
    typeName
    baseType
    restrictionList
} {

    set allowedRestrictions {
	minInclusive
	minExclusive
	maxExclusive
	maxInclusive
	totalDigits
	fractionDigits
	pattern
    }

    array set Restrictions $restrictionList

    set restrictionNames [array names Restrictions]

    # Check a few structural errors:

    # max and min restrictions: only one of each is allowed
    if {[llength [lsearch -inline -all $restrictionNames [list max*]]] > 1} {
	return -code error "cannot specify both maxInclusive and maxExclusive to restrict $tns $typeName"
    }
    if {[llength [lsearch -inline -all $restrictionNames [list min*]]] > 1} {
	return -code error "cannot specify both minInclusive and minExclusive to restrict $tns $typeName"
    }

    # Check:
    # 1. restriction is allowed
    # 2. supplied numeric values are valid 
    # 3. check base type conflicts

    set baseNamespace ::wsdb::types::${baseType}

    foreach restrictionName $restrictionNames {
	if {[lsearch -exact $allowedRestrictions $restrictionName] == -1} {
	    return -code error "unknown restriction $restrictionName your choices are [join $allowedRestrictions ", "]"
	}
	if {[lsearch -exact {pattern totalDigits fractionDigits} $restrictionName] > -1} {
	    continue
	} elseif {![::wsdb::types::xsd::decimal::validate $Restrictions($restrictionName)]} {
	    return -code error "value for $restrictionName is not a decimal number ($Restrictions($restrictionName))"
	}
	    
	if {![info exists ${baseNamespace}::$restrictionName]} {
	    continue
	}

	set baseRestrictionValue [set ${baseNamespace}::$restrictionName]
	
	switch -exact -- $restrictionName {
	    
	    minInclusive - minExclusive {
		if {$baseRestrictionValue > $Restrictions($restrictionName)} {
		    return -code error "value for base $restrictionName\
 ($baseRestrictionValue) > $tns $typeName $restrictionName ($Restrictions($restrictionName)"
		}
	    }

	    maxExclusive - maxInclusive {
		if {$baseRestrictionValue < $Restrictions($restrictionName)} {
		    return -code error "value for base $restrictionName\
 ($baseRestrictionValue) <  $restrictionName ($Restrictions($restrictionName)"
		}
		
	    }

	}

    }

    # check that totalDigits and fractionDigits are integers, if exist
    set hasTotalDigits 0
    set hasFractionDigits 0

    # totalDigits
    if {[info exists Restrictions(totalDigits)]} {
	if {![::wsdb::types::tcl::integer::validate $Restrictions(totalDigits)]} {
	    return -code error "restriction $tns $typeName totalDigits not integer ($Restrictions(totalDigits))"
	}
	set hasTotalDigits 1
	log Notice "restriction of $tns $typeName assumes parent simpleType includes decimal"
    }
    # fractionDigits
    if {[info exists Restrictions(fractionDigits)]} {
	if {![::wsdb::types::tcl::integer::validate $Restrictions(fractionDigits)]} {
	    return -code error "restriction $tns $typeName fractionDigits\
 not integer ($Restrictions(fractionDigits))"
	} elseif {[info exists ${baseNamespace}::fractionDigits]} {
	    set baseRestrictionValue [set ${baseNamespace}::fractionDigits]
	    if {$baseRestrictionValue < $Restrictions(fractionDigits)} {
		return -code error "fractionDigits ($Restrictions(fractionDigits))\
 > base fractionDigits ($baseRestrictionValue)"
	    }
	}
	set hasFractionDigits 1
	set inheritFractionDigits 0

	log Notice "restriction of $tns $typeName assumes parent simpleType includes decimal"
    } elseif {[info exists ${baseNamespace}::fractionDigits]} {
	set Restrictions(fractionDigits) [set ${baseNamespace}::fractionDigits]
	lappend restrictionNames fractionDigits
	set hasFractionDigits 1
	set inheritFractionDigits 1
	
    } elseif {[string match "xsd::int*" $baseType]} {
	set Restriction(fractionDigits) 0
	lappend restrictionNames fractionDigits
	lappend restrictionList fractionDigits 0
	set hasFractionDigits 1
	set inheritFractionDigits 1
    }
    
    # Setup decimalPointCanon
    if {$hasFractionDigits} {
	if {$Restrictions(fractionDigits)} {
	    set decimalPointCanon "."
	} else {
	    set decimalPointCanon ""
	}
    } else {
	set decimalPointCanon "."
    }

    # check fractionDigits <= totalDigits
    if {$hasTotalDigits && $hasFractionDigits
	&& ($Restrictions(totalDigits) < $Restrictions(fractionDigits))
    } {
	return -code error "restriction $tns $typeName totalDigits\
 ($Restrictions(totalDigits)) less than fractionDigits ($Restrictions(fractionDigits))"
    }

    # check minInclusive < maxExclusive
    if {[info exists Restrictions(minInclusive)]
	&& [info exists Restrictions(maxExclusive)]
	&& !($Restrictions(minInclusive) < $Restrictions(maxExclusive))
    } {

	return -code error "restriction in $tns $typeName error minInclusive\
 ($Restrictions(minInclusive))>= maxExclusive ($Restrictions(maxExclusive))"

    }
    
    # Check pattern is valid
    if {[info exists Restrictions(pattern)]} {
	if {[catch {regexp $Restrictions(pattern) abc} errorMsg]} {
	    return -code error "failed pattern test on $tns $typeName $errorMsg"
	}
	
    }

    # All structural requirements are met for restriction of decimal type...
    log Notice "Looks Okay! Making restricting type $baseType to $tns $typeName"

    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base $baseType]

    set restrictionVarScriptList [list]
    # Add namespace vars for restrictions
    foreach restrictionName $restrictionNames {
	namespace eval ::wsdb::types::${tns}::${typeName} [list variable $restrictionName $Restrictions($restrictionName)]
	lappend restrictionVarScriptList "    variable $restrictionName"
    }
    namespace eval ::wsdb::types::${tns}::${typeName} [list variable decimalPointCanon $decimalPointCanon]

    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace current\]::validate"


    # NOTE: the first validity test is against the baseType. Unfortunately,
    # this ends up providing less information, since the exact failure is not
    # available to the validation proc. But! This is okay, because it is likely
    # that the failed facet does not appear in the schema definition for this
    # type, but in the base type. So pointing to the failure in the baseType
    # seems the best solution. 

    # Example TestDecimal  restricts fractionDigits to 2, totalDigits to 5
    #         TestDecimal2, based upon TestDecimal restricts totalDigits to 4.
    # 
    # During restriction, fractionDigits = 2 is copied from TestDecimal, but
    #  it is not added to the schema definition.

    # A value of 3.041 passed to TestDecimal2::validate will fail the base test,
    #  but it looks valid, as having only 4 totalDigits. TestDecimal2 inherits
    #  fractionDigits 2 from TestDecimal. It would fail the 

    set scriptBody "
    variable base
    variable decimalPointCanon
[join $restrictionVarScriptList \n]

    if \{\"\$errorListVar\" ne \"\"\} \{
        upvar \$errorListVar errorList
    \}
    if \{\"\$canonListVar\" ne \"\"\} \{
        upvar \$canonListVar canonList
    \}

    set valid 0
    set collapsedValue \[string trim \$value\]
    set errorList \[list \$collapsedValue\]
    set canonList \[list\]

    if \{!\[::wsdb::types::xsd::decimal::ifDecimalCanonize \$value canonList \$decimalPointCanon decimalList\]\} \{
        lappend errorList \"failed decimal test\"
        return \$valid
    \}
    set foundDigits \[lindex \$decimalList 0\]
    set foundFractionDigits \[lindex \$decimalList 1\]
    set canonValue \[join \$canonList \"\"\]

    while \{1\} \{
        if \{!\[::wsdb::types::\$\{base\}::validate \$canonValue\]\} \{
            lappend errorList \"failed base test \$base\" 
            break
        \}"

    set skipMax 0
    set skipMin 0

    # pattern
    if {[info exists Restrictions(pattern)]} {
	append scriptBody "
	if \{!\[regexp \$pattern \$value\]\} \{
lappend errorList \"failed pattern test using \[list \$pattern\]\"
            break
        \}"
    }

    # minInclusive
    if {[info exists Restrictions(minInclusive)]} {
	append scriptBody "
        if \{\$canonValue < $Restrictions(minInclusive)\} \{
            lappend errorList \"failed minInclusive test ($Restrictions(minInclusive))\"
            break
        \}"
	set skipMin 1
    }
    # minExclusive 
    if {!$skipMin && [info exists Restrictions(minExclusive)]} {
	append scriptBody "
        if \{!(\$canonValue > $Restrictions(minExclusive))\} \{
            lappend errorList \"failed minExclusive test ($Restrictions(minExclusive))\"
            break
        \}"
    }
    # maxExclusive 
    if {[info exists Restrictions(maxExclusive)]} {
	append scriptBody "
        if \{!(\$canonValue < $Restrictions(maxExclusive))\} \{
            lappend errorList \"failed maxExclusive test ($Restrictions(maxExclusive))\"
            break
        \}"
	set skipMax 1
    }
    # maxInclusive
    if {!$skipMax && [info exists Restrictions(maxInclusive)]} {
	append scriptBody "
        if \{\$canonValue > $Restrictions(maxInclusive)\} \{
            lappend errorList \"failed maxInclusive test ($Restrictions(maxInclusive))\"
            break
        \}"
    }
    # totalDigits
    if {$hasTotalDigits || $hasFractionDigits} {
	if {$hasTotalDigits} {
	    append scriptBody "
        if \{\$foundDigits > \$totalDigits\} \{
            lappend errorList \"failed foundDigits (\$foundDigits) > totalDigits ($Restrictions(totalDigits))\"
            break
        \}"

        }
        # if fractionDigits is inherited, there is no need for this test 
	if {$hasFractionDigits && !$inheritFractionDigits} {
            append scriptBody "
        if \{\$foundFractionDigits > \$fractionDigits\} \{
            lappend errorList \"failed foundFractionDigits (\$foundFractionDigits)\
 > fractionDigits ($Restrictions(fractionDigits))\"
            break
        \}"

        }

    }

    append scriptBody "
        set valid 1
        break
    \}

    return \$valid\n"

    proc ::wsdb::types::${tns}::${typeName}::validate { value {errorListVar ""} {canonListVar ""} } $scriptBody

    ::wsdl::schema::appendSimpleType decimal $tns $typeName $baseType $restrictionList
}


# creates or restricts a simple type to a series of values
proc ::wsdl::types::simpleType::restrictByEnumeration {tns typeName baseType enumerationList } {
    set enumIndex 0
    foreach enum $enumerationList {
	if {![::wsdb::types::${baseType}::validate $enum]} {
	    return -code error "failed enumeration item on $tns $typeName at index $enumIndex value = '$enum' not type $baseType"
	}
	incr enumIndex
    }
    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base $baseType]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate \[namespace current\]::validate"

    proc ::wsdb::types::${tns}::${typeName}::validate { value } "
       variable base
       if {\[::wsdb::types::\${base}::validate \"\$value\"] && \[lsearch -exact \{$enumerationList\} \"\$value\"] > -1} { 
           return 1
       } else { 
           return 0
         }\n"

    ::wsdl::schema::appendSimpleType enumeration $tns $typeName $baseType $enumerationList
}

proc ::wsdl::types::simpleType::restrictByPattern {tns typeName baseType pattern } {

    namespace eval ::wsdb::types::${tns}::${typeName} [list variable base $baseType]
    namespace eval ::wsdb::types::${tns}::${typeName} [list variable pattern $pattern]
    namespace eval ::wsdb::types::${tns}::${typeName} "
    variable validate ::wsdb::types::${tns}::${typeName}::validate"

    proc ::wsdb::types::${tns}::${typeName}::validate { value } "
        variable base
        variable pattern
        if {\[::wsdb::types::\${base}::validate \$value] && \[regexp \$pattern \$value]} { 
            return 1
        } else { 
            return 0
     }"

    ::wsdl::schema::appendSimpleType pattern $tns $typeName $baseType $pattern
}


# wsdl Element Procs

namespace eval ::wsdl::elements::modelGroup {}
namespace eval ::wsdl::elements::modelGroup::sequence {}

# Procedure to tag elements which do not validate:

proc ::wsdl::elements::noteFault { namespace dataList } {
    
    namespace eval $namespace {
	variable .META
    }
    # dataList = fault(code, element, value, proc) or other data
    # based upon the fault code.
    lappend ${namespace}::.META(FAULT) $dataList
    return ""
}

########## Element Validate Procedure  Writers #####

proc ::wsdl::elements::modelGroup::sequence::minMaxList { 
    minOccurs
    maxOccurs
} {
    # minOccurs must be 0 or greater
    if {![string is integer -strict $minOccurs]
	|| $minOccurs < 0
    } {
	set minOccurs 1
    }
    # maxOccurs must be 1 or greater
    if {![string is integer -strict $maxOccurs] 
	|| $maxOccurs < 1 
    } {
	set maxOccurs 1
    }
    # maxOccurs must be greater than or equal to minOccurs
    if {$maxOccurs < $minOccurs} {
	set maxOccurs $minOccurs
    }

    return [list minOccurs $minOccurs maxOccurs $maxOccurs]
}

 
proc ::wsdl::elements::modelGroup::sequence::getElementData {
    Child
    {ArrayName ""}
} {
    set ChildNameType [lindex $Child 0]
    if {[set first [string first ":" $ChildNameType]] > -1} {
	set Element [string range $ChildNameType 0 [expr $first -1 ]]
	set Type [string range $ChildNameType [expr $first + 1] end]
	if {"$Type" eq ""} {
	    set Type "xsd::string"
	} elseif {[string first ":" "$Type"] == -1} {
	    set Type "xsd::$Type"
	} 
    } else {
	set Element $ChildNameType
	set Type "xsd::string"
    }
   
    # Seed facetArray with default values:
    array set facetArray {minOccurs {} maxOccurs {} form Value}
    array set facetArray [lindex $Child 1]
    array set facetArray [minMaxList $facetArray(minOccurs) $facetArray(maxOccurs)]
    
    lappend Elements $Element
    
    # Store information for later use:
    if {"$ArrayName" eq ""} {
	set ArrayName $Element
    }
    upvar $ArrayName ElementArray
    array set ElementArray [list name $Element type $Type minOccurs $facetArray(minOccurs)\
			    maxOccurs $facetArray(maxOccurs) facets [array get facetArray] \
			   form $facetArray(form)]
    if {[info exists facetArray(default)]} {
	set ElementArray(default) $facetArray(default)
    }
    return $Element
}


proc ::wsdl::elements::modelGroup::sequence::addReference {
    schemaAlias
    parentElement
    elementArray
} {
    upvar $elementArray ElementArray

    set base $ElementArray(type)
    set element $ElementArray(name)

    set ValidateTypeTail [string map {__ _} [string map {: _} $base]]

    return "

namespace eval ::wsdb::elements::${schemaAlias}::${parentElement}::$element \{
    variable base $base
    variable facetList \{[array get ElementArray]\}
    variable validate \[set ::wsdb::\$\{base\}::validate]
    variable new      \[set ::wsdb::\$\{base\}::new]

\}"

}



proc ::wsdl::elements::modelGroup::sequence::writeValidateProc {
    namespace
    typeName
    Elements
} {
    set script ""

    append script "
    
proc ${namespace}::Validate$typeName \{ namespace \} \{

    variable Children
    variable MinOccurs
    variable MaxOccurs"

    foreach Element $Elements {
	append script "
    variable validate_$Element"
    }

    append script "
    array set COUNT \[array get \$\{namespace\}::.COUNT]
    set COUNT(.INVALID) 0

    set ElementNames \$Children

    foreach ElementName \$ElementNames \{
        if \{\$MinOccurs(\$ElementName) > 0\} \{
            if \{!\[info exists COUNT(\$ElementName)]\} \{
                ::wsdl::elements::noteFault \$namespace \[list 4 \$ElementName 0 \$MinOccurs(\$ElementName)]
                incr COUNT(.INVALID)
                return 0
            \} elseif \{\$COUNT(\$ElementName) < \$MinOccurs(\$ElementName)\} \{
                ::wsdl::elements::noteFaunt \$namespace \[list 4 \$ElementName \$COUNT(\$ElementName) \$MinOccurs(\$ElementName)]
                incr COUNT(.INVALID)
                return 0
            \}
        \}
        if \{\[info exists COUNT(\$ElementName)] && \$COUNT(\$ElementName) > \$MaxOccurs(\$ElementName)\} \{
            ::wsdl::elements::noteFault \$namespace \[list 5 \$ElementName \$COUNT(\$ElementName) \$MaxOccurs(\$ElementName)]
            incr COUNT(.INVALID)
            return 0
        \}
    \}

    set PARTS \[set \$\{namespace\}::.PARTS]
    set COUNT(.ELEMENTS) 0

    foreach PART \$PARTS \{
        incr COUNT(.ELEMENTS)
        foreach \{childName prefix childPart\} \$PART \{\}
        set childPart \[::xml::normalizeNamespace \$namespace \$childPart] 

        switch -exact -- \$childName \{"

    foreach Element $Elements {
	append script "
            $Element \{
                if \{!\[eval \[linsert \$validate_$Element end \$childPart\]\]\} \{  
                    ::wsdl::elements::noteFault \$namespace \[list 2 $Element \$childPart\]
                    incr COUNT(.INVALID)
                    break
                \}
            \}"

    }
    append script "
            default \{
                ::wsdl::elements::noteFault \$namespace \[list 3 \$childName \$childPart\]                    
                incr COUNT(.INVALID)
            \}
        \}
    \}

    if \{\$COUNT(.INVALID)\} \{
        return 0
    \} else \{
        return 1
    \}
\}"

    return $script
}



########## Element New Procedure Writers #########


namespace eval ::wsdl::elements::modelGroup::simpleContent { }

proc ::wsdl::elements::modelGroup::simpleContent::create {
    schemaAlias
    parentElement
    elementArray
} {
    upvar $elementArray ElementArray

    set base $ElementArray(type)
    set element $ElementArray(name)

    set ValidateTypeTail [string map {__ _} [string map {: _} $base]]

    return "

namespace eval ::wsdb::elements::${schemaAlias}::${parentElement}::$element \{
    variable base $base
    variable facetList \{$ElementArray(facets)\}
    variable minOccurs $ElementArray(minOccurs)
    variable maxOccurs $ElementArray(maxOccurs)
    variable validate \[namespace current\]::Validate
    variable new      \[namespace current\]::new
    variable validate_$ValidateTypeTail \$::wsdb::types::${base}::validate

    proc Validate \{ namespace \} \{
        variable validate_$ValidateTypeTail
        set Valid \[\$validate_$ValidateTypeTail \[::xml::instance::getTextValue \$namespace\]\]

        if \{!\$Valid\} \{
            ::wsdl::elements::noteFault \$namespace \[list 1 $element \[::xml::instance::getTextValue \$namespace\] \$validate_$ValidateTypeTail \]
        \}
        return \$Valid
    \}

    proc new \{ namespace value \} \{
         ::xml::element::appendText \[::xml::element::append \$namespace $element] .TEXT \$value
    \}
\}"

}

# Procedures to write part of new element proc
namespace eval ::wsdl::elements::modelGroup::sequence {
    proc writer_maxOccurs1 {NewProc Index} {
	
	return "
    if \{\[lindex \$childValuesList $Index\] ne \"\"\} \{
        $NewProc \$typeNS \[lindex \$childValuesList $Index\]
    \} else \{"
    }
    
    proc writer_maxOccurs1+ {NewProc Index} {
	
	return "
    if \{\[llength \[lindex \$childValuesList $Index\]\]\} \{
        foreach childValue \[lindex \$childValuesList $Index\] \{
            $NewProc \$typeNS \$childValue
        \}
    \} else \{"
    }
    
    proc writer_defaultMinOccurs1+ {NewProc Default} {
	return "
        $NewProc \$typeNS [list $Default]
    \}"
    }
    proc writer_noDefaultMinOccurs1+ {NewProc Child} {
	return "
        return -code error \"Missing value for required Element $Child with no default value calling $NewProc\"
    \}"
    }
    proc writer_nillableMinOccurs0 {ElementName } {
	return "
        ::xml::element::nilElement \$typeNS $ElementName
    \}"
    } 
    
    proc writer_defaultMinOccurs0 {NewProc Default} {
	return [writer_defaultMinOccurs1+ $NewProc $Default]
    }
    
    proc writer_noDefaultMinOccurs0 { Child } {
	return "
        \# skip element $Child
    \}"
    }
    
    
}

set ::wsdl::elements::modelGroup::sequence::doc {
    nil value = "", when input is "", include code to handle nil value
    nillable minOccurs maxOccurs default inValue | do_what?                  | Notes
    +        0         1         none    ""      | <element xsi:nil="true"/> | Ignore minOccurs and default
    +        0         1         none    "abc"   | <element>abc</element>    | normal case 
    +        0         1         "abcd"  ""      | <element xsi:nil="true"/> | ignore default
    +        0         1         ""      ""      | <element xsi:nil="true"/> | ignore default

    +        0         2+        none    ""      | <element xsi:nil="true"/> | Ignore minOccurs and default
    +        0         2+        none    "abc"   | <element>abc</element>    | normal case 
    +        0         2+        "abcd"  ""      | <element xsi:nil="true"/> | ignore default
    +        0         2+        ""      ""      | <element xsi:nil="true"/> | ignore default

    +        1         1         none    ""      | ERROR                     | ERROR (nillable ignored)
    +        1         1         none    "abc"   | <element>abc</element>    | normal case 
    +        1         1         "abcd"  ""      | <element>abcd</element>   | default replaces nil value.
    +        1         1         ""      ""      | <element></element>       | empty string IS default

    +        1         2+        none    ""      | ERROR                     | ERROR (nillable ignored)
    +        1         2+        none    "abc"   | <element>abc</element>    | normal case
    +        1         2+        "abcd"  ""      | <element>abcd</element>   | default replaces nil value.
    +        1         2+        ""      ""      | <element></element>       | empty string IS default

    -        0         1         none    ""      | skip inclusion            | handle nil
    -        0         1         none    "abc"   | <element>abc</element>    | normal case 
    -        0         1         "abcd"  ""      | <element>abcd</element>   | default replaces nil value.
    -        0         1         ""      ""      | <element></element>       | empty string IS default
   
    -        0         2+        none    ""      | skip inclusion            | handle nil
    -        0         2+        none    "abc"   | <element>abc</element>    | normal case 
    -        0         2+        "abcd"  ""      | <element>abcd</element>   | default replaces nil value.
    -        0         2+        ""      ""      | <element></element>       | empty string IS default

    -        1         1         none    ""      | ERROR                     | ERROR
    -        1         1         none    "abc"   | <element>abc</element>    | normal case 
    -        1         1         "abcd"  ""      | <element>abcd</element>   | default replaces nil value.
    -        1         1         ""      ""      | <element></element>       | empty string IS default

    -        1         2+        none    ""      | ERROR                     | ERROR
    -        1         2+        none    "abc"   | <element>abc</element>    | normal case 
    -        1         2+        "abcd"  ""      | <element>abcd</element>   | default replaces nil value.
    -        1         2+        ""      ""      | <element></element>       | empty string IS default

    {
	Notes: 
	0. see <http://www.w3.org/TR/xmlschema-0/\#Nils>
	1. nillable is only in effect if minOccurs = 0 and inValue = ""
	2. if minOccurs = 1+, an inValue = "" triggers use of default, BUT:
	3. if minOccurs = 1+, an inValue of "" and no default forces ERROR
	4. if inValue of "" is valid for a minOccurs = 1+, set default to ""
	
	Notes on difference between maxOccurs = 1 and maxOccurs > 1:
	1. inValue is considered a list if maxOccurs > 1.
	2. inValue is considered a single value if maxOccurs = 1.
	3. list length whitespace is ZERO: "", " ", "   ": all have llength = 0;
	4. list length of {} is ZERO. A default value of "{}" for a maxOccurs > 1
	   will not execute any times inside a foreach.
	5. list length of {{}} is ONE. 

	possible check sequence:
	1. if inValue = "somevalue" --> normal case
	if {[llength $childValuesList $i]} {
           handle_normal_case
	} else {
	}
	2. else if nillable = true && minOccurs = 0 --> handle nillable (This finishes off nillable)
	3. if minOccurs = 0 && default exists --> use default as inValue
        4. if minOccurs = 0 && no default --> skip inclusion
        5. if default exists --> use default as inValue
        6. create element with content = ""


    }

    {
	Algrithm 2:
	Step 1, Line 1-2: formatting if based upon maxOccurs:
	 if maxOccurs = 1 use if {[lindex $childValuesList $i] ne ""} { do foreach [list [lindex $childValuesList $i]] }
	 else (maxOccurs > 1) if {[llength [lindex $childValuesList $i]]} { do foreach [lindex $childValuesList $i] } 
	
	Step 2, line 3: Else do what if null/length=0??
	 Case A: minOccurs > 0:
	  if default exists and maxOccurs = 1+ use {do make element with $default }
	 
	  no default exists and maxOccurs = 1+ use {ERROR}
	
	 Case B: minOccurs = 0:
	  if nillable use {do make xsi:nil element}
	  if not nillable and default exists use {do make element with $default }
          if not nillable and no default use {do skip element}
    }
}

# writeNewProc writes procedure to create new element
proc ::wsdl::elements::modelGroup::sequence::writeNewProc {
    namespace
  
} {
    set script ""

    if {[info exists ${namespace}::base]} {
	set Base ::wsdb::[set ${namespace}::base]
    } else {
	set Base $namespace
    }

    set Children [set ${Base}::Children]
    set ChildCount [llength $Children]

    array set ParentData [set ${namespace}::facetList]
    array set MinOccurs  [array get ${Base}::MinOccurs]
    array set MaxOccurs  [array get ${Base}::MaxOccurs]

    set ParentName $ParentData(name)

    append script "\nproc ${namespace}::new \{ instanceNamespace childValuesList \} \{

    set typeNS \[::xml::element::append \$instanceNamespace $ParentName\]"
    
	
    if {$ChildCount == 1} {
	append script "
    set childValuesList \[list \$childValuesList\]"
    }

    for {set i 0} {$i < $ChildCount} {incr i} {
	
	set Child [lindex $Children $i]

	if {[array exists ChildData]} {
	    array unset ChildData
	}

	array set ChildData [set ${Base}::${Child}::facetList]

	set NewProc \$${Base}::${Child}::new

	# Step 1: handle non empty value based upon maxOccurs
	if {$MaxOccurs($Child) == 1} {
	    append script [writer_maxOccurs1 $NewProc $i]
	} else {
	    append script [writer_maxOccurs1+ $NewProc $i]
	}
	# Step 2: We have a null value what to do?
	# Case A: minOccurs > 0
	if {$MinOccurs($Child) > 0} {
	    # Check if default exists
	    if {[info exists ChildData(default)]} {
		append script [writer_defaultMinOccurs1+ $NewProc $ChildData(default)]
	    } else {
		# stick in passed in null value or whitespace
		append script [writer_noDefaultMinOccurs1+ $NewProc $Child ]
            }
	} elseif {[info exists ChildData(nillable)]
		  && "$ChildData(nillable)" eq "true"} {
	    append script [writer_nillableMinOccurs0 $Child]
	} elseif {[info exists ChildData(default)]} {
	    append script [writer_defaultMinOccurs0 $NewProc $ChildData(default)]
	} else {
	    append script [writer_noDefaultMinOccurs0 $Child]
	}

    }

    append script "\n    return \$typeNS\n\}"

    return $script
}


proc ::wsdl::elements::modelGroup::sequence::new { 
    schemaAlias 
    typeName
    childList
} {

    set script ""
    set Elements [list]

    foreach Child $childList {
	
	lappend Elements [::wsdl::elements::modelGroup::sequence::getElementData $Child]
	
    }

    foreach Element $Elements {
	if {[string match "elements::*" [set ${Element}(type)]]} {
	    append script [::wsdl::elements::modelGroup::sequence::addReference \
			       $schemaAlias $typeName $Element]
	} else {
	    append script [::wsdl::elements::modelGroup::simpleContent::create \
			       $schemaAlias $typeName $Element]
	}
    }

        append script "

namespace eval ::wsdb::elements::${schemaAlias}::$typeName \{

    variable Children \{$Elements\}
    variable MinOccurs
    variable MaxOccurs
    variable facetList \[list form Value name $typeName\]
    variable validate \[namespace current\]::Validate${typeName}
    variable new      \[namespace current\]::new"

    foreach Element $Elements {
	append script "
    variable validate_$Element \$${Element}::validate"

    }

    foreach Element $Elements {
	append script "
    set MinOccurs($Element) [set ${Element}(minOccurs)]
    set MaxOccurs($Element) [set ${Element}(maxOccurs)]"

    }


    # Foreach with switch, probably change to foreach with loops.
    append script "\n\}"
    append script [::wsdl::elements::modelGroup::sequence::writeValidateProc \
		       ::wsdb::elements::${schemaAlias}::$typeName $typeName \
		       $Elements]
		       
    append script "
eval \[::wsdl::elements::modelGroup::sequence::writeNewProc ::wsdb::elements::${schemaAlias}::$typeName\]

::wsdl::schema::addSequence \"$schemaAlias\" \"$typeName\" \{$childList\} 0
"
    return $script
}

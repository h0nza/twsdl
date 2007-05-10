# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::xml::element {
    namespace import ::tws::log::log
}

proc ::xml::element::toPrefixLocalnameList { element } {

    set elementList [split $element ":"]
    if {[llength $elementList] > 1} {
	set prefix [lindex $elementList 0]
	set element [lindex $elementList end]
    } else {
	set prefix ""
    }
    return [list $prefix $element]
}

# Create xml element shell with full namespace path
# Note that this API will be called by ::xml::element::append
proc ::xml::element::create {
    tclNamespace
    childLocalname
    {prefix {}}
    {attributeList {}}
} {

    namespace eval $tclNamespace {
	variable .NAME 
	variable .PARTS [list]
	variable .ATTRS
	variable .XMLNS
	variable .PREFIX
	variable .COUNT
    }

    set ${tclNamespace}::.PREFIX $prefix
    set ${tclNamespace}::.NAME $childLocalname
    if {[llength $attributeList] > 0} {
	array set ${tclNamespace}::.ATTRS $attributeList
    }
    return $tclNamespace
}

# ::xml::element::append
# If tclNamespace is not an initialized XML Element,
# This procedure will call ::xml::element::append
proc ::xml::element::append { 
    tclNamespace 
    childLocalname
    {prefix {}}
    {attributeList {}}
} {
    if {![info exists ${tclNamespace}::.NAME]} {
	return [::xml::element::create ${tclNamespace}::$childLocalname $childLocalname $prefix $attributeList]
    }
    if {![info exists ${tclNamespace}::.COUNT($childLocalname)]} {
	set ${tclNamespace}::.COUNT($childLocalname) 1
	set childLocalNamespace ${childLocalname}
    } else {
	set childLocalNamespace ${childLocalname}::[set ${tclNamespace}::.COUNT($childLocalname)]
	incr ${tclNamespace}::.COUNT($childLocalname)
    }
    ::xml::element::create ${tclNamespace}::$childLocalNamespace $childLocalname $prefix $attributeList

    lappend ${tclNamespace}::.PARTS [list $childLocalname $prefix $childLocalNamespace]

    return ${tclNamespace}::$childLocalNamespace
       
}

# Do I need to distinguish a ref from a regular element?
proc ::xml::element::appendRef { 
    tclNamespace
    refNamespace 
} {
    set childLocalname [set ${refNamespace}::.NAME]
    set prefix [set ${refNamespace}::.PREFIX]

    if {![info exists ${tclNamespace}::.COUNT($childLocalname)]} {
	set ${tclNamespace}::.COUNT($childLocalname) 1
	set childLocalNamespace ${childLocalname}
    } else {
	set childLocalNamespace ${childLocalname}::[set ${tclNamespace}::.COUNT($childLocalname)]
	incr ${tclNamespace}::.COUNT($childLocalname)
    }
    
    lappend ${tclNamespace}::.PARTS [list $childLocalname $prefix $refNamespace]
   
    return $refNamespace
}

proc ::xml::element::appendText { 
    tclNamespace
    partName
    textValue 
} {

    # Text elements from tDOM. 
    if {[string match "\#*" "$partName"]} {
	set partName ".[string toupper [string range "$partName" 1 end]]"
    }

    # This creates variable if it doesn't exist
    namespace eval $tclNamespace [list variable $partName]

    if {![array exists ${tclNamespace}::$partName]} {
	set index 0
	set ${tclNamespace}::${partName}(0) $textValue
	lappend ${tclNamespace}::.PARTS [list $partName "" ${partName}(0)]
	set ${tclNamespace}::.COUNT($partName) 1
    } else {
	set index [set ${tclNamespace}::.COUNT($partName)]
	set ${tclNamespace}::${partName}($index) $textValue
	lappend ${tclNamespace}::.PARTS [list $partName "" ${partName}($index)]
	incr ${tclNamespace}::.COUNT($partName)
    }
    return "${tclNamespace}::${partName}($index)"

}


proc ::xml::element::setAttributes { tclNamespace attributeList } {

    array set ${tclNamespace}::.ATTRS $attributeList
}

proc ::xml::element::setAttribute { tclNamespace attributeName attributeValue } {

    set ${tclNamespace}::.ATTRS($attributeName) $attributeValue

    return $attributeValue

}

proc ::xml::element::getAttribute { tclNamespace attributeName } {

    return [set ${tclNamespace}::.ATTRS($attributeName)]
}

proc ::xml::element::nilElement {
    tclNamespace
    childLocalname
    {prefix {}}
    {attributeList {}}
} {
    return [::xml::element::append $tclNamespace $childLocalname $prefix [concat $attributeList xsi:nil true]]
}



set pattern {\A([\-+]?)([0-9]*)(?:([\.]?)|([\.])([0-9]+))\Z}


set pattern {\A([\-+]?)([0-9]*)(?:([\.]?)|([\.])([0-9]+))\Z}

set result ""

set a(a) ""
array unset a

set format {%16s%10s%10s%5s%10s%4s%4s%10s%12s%4s%4s}
append result [format $format Input Decimal? TclInt? +/- whole ptI ptR fract canonValue Dt Df]\n

foreach num {
    1.002 
    -1.002 
    543.21 
    -543.21
    .234 
    -.234
    0.123 
    -0.123
    890 
    -890 
    890. 
    -890.
    +0.0
    -0.0
    +0
    -0
    +0.
    -0.
    +.0
    -.0
    +1
    -1
    1
    002
    002.
    +01.1
    -01.1
    +001.1
    -001.1
    +100.10
    -100.10
    +100.100
    -100.100
    -00002.100020
    +0002.10002000
    -0001
    +0001
    -001001
    +001001.
    0890
    +0890
    0990
    +0990
    0789
    +0789
    0128
    +0128
    -0128
    ""
    " "
    .
    +.
    -.
    +
    -
    ++
    --
    ++.
    --.
    "0 0"
    "- 0"
    "0 "
    " 0"
    1.a 
    -1.a
    1..2 
    -1..2
    .2.3 
    -.2.3
    0x23.
    x23.
    0x23
    x23
    0x12F5
    12F5
    0x12f5
    x12f5
    12f5
    0xABCDEF
    0xabcdef
    xabcdef
    abcdef
    0x0
    x0
} {

    if {[string is integer -strict $num]} {
	set IsTclInteger Yes
	set decimalCanon ""
    } else {
	set IsTclInteger No
	set decimalCanon .
    }
    if {"$num" eq ""} {
	set decimalCanon ""
    } 
    if {"$num" eq "."} {
	set decimalCanon "."
    }
    if {[array exists a]} {
	array unset a
    }

    if {[::wsdb::types::xsd::decimal::validateWithInfoArray $num a]} {
	if {[info exists canonList]} {
	    unset canonList
	} 
	if {[info exists digitsList]} {
	    unset digitsList
	}
	if {[::wsdb::types::xsd::decimal::ifDecimalCanonize $num canonList $decimalCanon digitsList]} {
	    set canonValue [join $canonList ""]
	    set Dt [lindex $digitsList 0]
	    set Df [lindex $digitsList 1]
	} else {
	    set canonValue ""
	    set Dt ""
	    set Df ""
	}

	append result "[format $format '$num' Yes $IsTclInteger $a(minus) $a(whole) $a(pointInt) $a(pointReal) $a(fraction) $canonValue $Dt $Df]\n"
    } else {
	::wsdb::types::xsd::decimal::validate $num errorList
	append result "[format "%16s%10s%10s%80s" '$num' No! $IsTclInteger ([join $errorList])]\n"
    }
}
    

ns_return 200 text/plain $result
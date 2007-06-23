# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>



# dateTime etc.

# See: <http://www.w3.org/TR/xmlschema-2/datatypes.html#dateTime>
# See: <http://www.cl.cam.ac.uk/~mgk25/iso-time.html>
# See: <http://www.iso.ch/iso/en/CatalogueDetailPage.CatalogueDetail?CSNUMBER=40874>
# See: <http://www.cs.tut.fi/~jkorpela/iso8601.html>
# See: <http://www.twinsun.com/tz/tz-link.htm>

# The following code (regular expression) verifies the dateTime format used in xml schema-2
# Un done is validity of an actual date in the regular expression. for instance  P2001-02-30T23:00:00
# (February 30, 2001 at 11:00 p.m.) will pass the regular expression. 
# The result still needs verification for the existence of the date.
# 
# The regular expression sets variables for positivity, year-month-day, year, month, day, hour-minutes-seconds, 
# hour, minutes, seconds, timezone, timezone sign, timezone hour, timezone minute

namespace eval ::wsdb::types::tcl::dateTime { }

proc ::wsdb::types::tcl::dateTime::toArray { 
    dateTime 
    {arrayName ""} 
} {
 
    if {"$arrayName" ne ""} {
	upvar $arrayName DT
    }

    # Date Parts
    set MinusOptional {([\-])?}
    set Year4DigitsMinusNR {(?:([0-9]{4}|[1-9]{1}[0-9]{4,})(?:-))}
    set Year4Digits {(?:[0-9]{4}|[1-9]{1}[0-9]{4,})}
    set SignedYearMinusNR (?:(${MinusOptional}${Year4Digits})(?:-))

    set Month12MinusNR  {(?:([0][1-9]|[1][0-2])(?:-))}
    set Day31 {([0][0-9]|[12][0-9]|[3][01])}
    
    # Optional Date
    set YMDOptional (${Year4DigitsMinusNR}${Month12MinusNR}${Day31})?
    set YMDRequired (${SignedYearMinusNR}${Month12MinusNR}${Day31}){1}
    
    # Time of Day Parts
    set T {([T]{1})}
    set TNR {(?:[T]{1})}
    set Hours24ColonNR {(?:([0][0-9]|[1][0-9]|[2][0-4])(?::))}
    set Minutes61ColonNR {(?:([0-5][0-9]|[6][01])(?::))}
    set Seconds {([0-5][0-9]|[6][01])}
    set PointFractSecondsOptional {(([\.]{1})([0-9]*[1-9]{1}))?}
    set PointFractSecondsOptionalNR {(?:(?:[\.]{1})([0-9]*[1-9]{1}))?}

    
    # Timezone Parts
    set ZonePlusMinus {([\+\-]{1})}
    set ZoneHoursColonMinutes {((?:(14)(?::)(00))|(?:([0][0-9]|[1][0-3])(?::)([0-5][0-9])))}
    
    
    # Timezone optional
    set ZoneOptional (Z|${ZonePlusMinus}${ZoneHoursColonMinutes})?
    
    # Time with Timezone
    set TimeOptionalNR (?:${TNR}(${Hours24ColonNR}${Minutes61ColonNR}(${Seconds}${PointFractSecondsOptionalNR})))?
    set TimeRequiredNR (?:${T}${Hours24ColonNR}${Minutes61ColonNR}${Seconds}${PointFractSecondsOptional}){1}
    set TimeOptional   (${T}${Hours24ColonNR}${Minutes61ColonNR}${Seconds}${PointFractSecondsOptional})?
    set TimeRequired   (${T}${Hours24ColonNR}${Minutes61ColonNR}(${Seconds}${PointFractSecondsOptional})){1}
    
    
    # Full Datetime Anchored
    set dateTimeRegexp (?:\\A${YMDRequired}${TimeOptionalNR}${ZoneOptional}){1}\\Z
    
    set Valid [regexp $dateTimeRegexp $dateTime DT(all) DT(YMD)  DT(year) \
		   DT(Positivity) DT(month) DT(day) DT(HMS) DT(hour) DT(minute) DT(second)\
		   DT(SecondWhole) DT(SecondFract) DT(Timezone) DT(TZSign)  DT(TZValue) \
		   DT(TZ14Hour) DT(TZ14Min) DT(TZHour) DT(TZMin) ]

    return $Valid

}

# Take this namespace apart so procs are defined at global 
# level and thus easy to find.


proc ::wsdb::types::tcl::dateTime::validate { datetime } {
    return [::wsdb::types::tcl::dateTime::toArray $datetime returnArray]
}

namespace eval ::wsdb::types::tcl::dateTime {


    #  fQuotient(a, b) = the greatest integer less than or equal to a/b 
    proc fQuotient { a b } {
	
	return [expr {int(floor($a * 1.0 / $b))}]
	
    }
    
    proc modulo { a b } {
	
	return [expr $a - [fQuotient $a $b] * $b]
	
    }
    
    proc fQuotient2 { a low high } {
	
	return [fQuotient [expr $a - $low] [expr $high - $low]]
	
    }
    
    proc modulo2 { a low high } {
	
	return [expr [modulo [expr $a - $low] [expr $high - $low]] + $low]
	
    }
    
    proc maximumDayInMonthFor { yearValue monthValue } {
	
	set M [modulo2 $monthValue 1 13]
	set Y [expr $yearValue + [fQuotient2 $monthValue 1 13]]
	
	if {[lsearch -integer -exact -sorted {1 3 5 7 8 10 12} $M] > -1} {
	    return 31
	} elseif {[lsearch -integer -exact -sorted {4 6 9 11} $M] > -1} {
	    return 30
	} elseif {[modulo $Y 400] == "0" || ([modulo $Y 100] != "0" && [modulo $Y 4] == 0)} {
	    return 29
	} else {
	    return 28
	}
	
    }

    proc formatDateTime { dateTimeArray } {

	upvar $dateTimeArray D
	
	#set Positivity $D(Positivity)
	set Year  [format "%.4d" $D(year)]
	set Month [format "%.2d" $D(month)]
	set Day   [format "%.2d" $D(day)]
	
	set YMD   [join [list $Year $Month $Day] -]
	
	set Hour  [format "%.2d" $D(hour)]
	set Minute [format "%.2d" $D(minute)]
	
	set secondList  [split $D(second) .]
	if {"[string trimleft [set SecondWhole [lindex $secondList 0]]]" eq ""} {
	    set SecondWhole 0
	} 
	set SecondWhole [format "%.2d" $SecondWhole]
	if {"[set secondFraction [string trimright [lindex $secondList 1] 0]]" ne ""} {
	    set decimal "."
	} else {
	    set decimal ""
	}
	set Second [join [list $SecondWhole $decimal $secondFraction] ""]
	
	set HMS [join [list $Hour $Minute $Second] :]
	
	set Timezone $D(Timezone)
	
	return [join [list $YMD T $HMS $Timezone] ""]
    }
    
    
    proc durationToArray { duration {arrayName ""} } {

	if {"$arrayName" ne ""} {
	    upvar $arrayName D
	}
	
	set PositivityRequired {(?:(\-)?(P){1})}
	set YMDOptional {((?:([0-9]+)([Y]{1}))?(?:([1-9][0-9]+)([M]{1}))?(?:([0-9]+)([D]{1}))?)?}
	set TRequired {(T){1}}
	set HourHNR {(?:([0-9]+)([H]{1}))?}
	set MinuteMNR {(?:([1-9][0-9]*)(M){1})?}
	set SecondSNR {(?:([0-9]+(?:\.[0-9]+)?)?(S){1})?}
	
	set PYMDOptional ${PositivityRequired}${YMDOptional}
	set THMSOptional (?:${TRequired}(${HourHNR}${MinuteMNR}${SecondSNR}){1})?
	
	set Reg \\A${PYMDOptional}${THMSOptional}\\Z
	
	set Valid [regexp $Reg $duration D(all) D(positivity) D(P) \
		       D(YMD) D(year) D(Y) D(month) D(Mo) D(day) D(D) D(T) D(HMS) \
		       D(hour) D(H) D(minute) D(Mi) D(second) D(S)]
	
	return $Valid
    }
    

   
    # see http://www.w3.org/TR/xmlschema-2/datatypes.html#adding-durations-to-dateTimes
    proc addDuration { startTimeArray durationArray endTimeArray } {
	
	upvar $startTimeArray S
	upvar $durationArray D
	upvar $endTimeArray E

	# Positivity
	set Pos $D(positivity)
	if {"$Pos" eq "-"} {
	    set Neg -1
	} else {
	    set Neg 1
	}

	foreach arrayItem [array names D] {
	    if {"$D($arrayItem)" eq "0"} {
		continue
	    }
	    set D($arrayItem) [string trimleft $D($arrayItem) 0]
	}

	# Months (may be modified additionally below) 
	set Temp [expr $S(month) + ${Pos}$D(month)]
	set E(month) [modulo2 $Temp 1 13]
	set Carry [fQuotient2 $Temp 1 13]

	# Years (may be modified additionally below) 
	set E(year) [expr $S(year) + ${Pos}$D(year) + $Carry]
	
	# Timezone
	#set E(zone) $S(zone)
	set E(Timezone) $S(Timezone)

	# Seconds
	set Temp [expr $S(second) + ${Pos}$D(second)]
	set E(second) [modulo $Temp 60]
	set Carry [fQuotient $Temp 60]
	
	# Minutes
	set Temp [expr $S(minute) + ${Pos}$D(minute) + $Carry]
	set E(minute) [modulo $Temp 60]
	set Carry [fQuotient $Temp 60]
	
	# Hours
	set Temp [expr $S(hour) + ${Pos}$D(hour) + $Carry]
	set E(hour) [modulo $Temp 24]
	set Carry [fQuotient $Temp 24]
	
	# Days
	if {$S(day) > [maximumDayInMonthFor $E(year) $E(month)]} {
	    set TempDays [maximumDayInMonthFor $E(year) $E(month)]
	} elseif {$S(day) < 1} {
	    set TempDays 1
	} else {
	    set TempDays $S(day)
	}
	
	set E(day) [expr $TempDays + ${Pos}$D(day) + $Carry]
	
	# Start Loop
	
	while { 1 } {
	    
	    if {$E(day) < 1} {
		set E(day) [expr $E(day) + [maximumDayInMonthFor $E(year) [expr $E(month) -1]]]
		set Carry  -1
	    } elseif {$E(day) > [maximumDayInMonthFor $E(year) $E(month)]} {
		set E(day) [expr $E(day) - [maximumDayInMonthFor $E(year) $E(month)]]
		set Carry 1
	    } else {
		break
	    }
	    set Temp [expr $E(month) + $Carry]
	    set E(month) [modulo2 $Temp 1 13]
	    set E(year) [expr $E(year) + [fQuotient2 $Temp 1 13]]
	}
	
	return 1
	
    }
 
    
}



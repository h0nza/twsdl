
# Example use of nvlist API:
namespace eval ::tws::nvlist::days {
 variable day_name_list {
 {1 MON}
 {2 TUE}
 {3 WED}
 {4 THU}
 {5 FRI}
 {6 SAT}
 {7 SUN}
 }
 namespace import ::tws::nvlist::*
}
proc ::tws::nvlist::days::toDay { num } {
 variable day_name_list
 return [toValue day_name_list $num]
}
proc ::tws::nvlist::days::toNum { day } {
 variable day_name_list
 return [toName day_name_list $day]
}

# Example using ::tws::nvlist::create
namespace eval ::tws::nvlist::bool {
    variable boolList 
    ::tws::nvlist::create boolList {y true} {n false}\
	{yes true} {no false} {true true} {false false}\
	{1 true} {0 false}
    namespace import ::tws::nvlist::*
}

proc ::tws::nvlist::bool::toStandard { name } {
    variable boolList
    return [toValue boolList $name]
}

proc ::tws::nvlist::bool::trueList { } {
    variable boolList
    return [toName boolList true]
}

proc ::tws::nvlist::bool::falseList { } {
    variable boolList
    return [toName boolList false]
}

namespace eval ::tws::nvlist::weekdays {

    variable dayList 

    namespace import ::tws::nvlist::*
    createEnum dayList "" MON TUE WED THU FRI SAT SUN
}

proc ::tws::nvlist::weekdays::toDay { num } {
    variable dayList
    return [toValue dayList $num]
}

proc ::tws::nvlist::weekdays::toNum { day } {
    variable dayList
    return [toName dayList $day]
}


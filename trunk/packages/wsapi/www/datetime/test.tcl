
set date "2007-01-01T12:00:00Z"

set duration "P1Y"

set dateValid [::wsdb::types::tcl::dateTime::toArray $date inDateArray]

set durationValid [::wsdb::types::tcl::dateTime::durationToArray $duration durationArray]



if {$dateValid && $durationValid} {

    set inDateArray(zone) 0
    set durationArray(zone) 0
    array set tmpDurationArray [array get durationArray]

    foreach {element value} {year 0000 month 00 day 00 hour 00 minute 00 second 00.00} {

	if {"$durationArray($element)" eq ""} {
	    set tmpDurationArray($element) "$value"
	}
    }
											
    ::wsdb::types::tcl::dateTime::addDuration inDateArray tmpDurationArray outDateArray

} else {
    array set outDateArray [list dateValid $dateValid durationValid $durationValid]
}

foreach {name value} [array get inDateArray] {
    append output "inDateArray($name) = '$value'\n"
}

foreach {name value} [array get outDateArray] {
    append output "outDateArray($name) = '$value'\n"
}

foreach {name value} [array get durationArray] {
    append output "durationArray($name) = '$value'\n"
}

ns_return 200 text/plain $output
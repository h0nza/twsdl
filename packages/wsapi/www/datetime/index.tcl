# XML-Schema has many, maybe too many date/time types.
# This Web Service will allow testing of these types.

<ws>namespace init ::datetime

<ws>proc ::datetime::CheckDateTime {

    {DateTime:dateTime}
} {

    return [list $DateTime True]

} returns {DateTime:dateTime IsDateTime:boolean}


<ws>proc ::datetime::AddDurationToDateTime {

    {StartDateTime:dateTime}
    {Duration:duration}
} {
    return [list $StartDateTime $Duration [::wsdb::types::tcl::dateTime::durationToArray $Duration $StartDateTime]]
} returns {StartDateTime:dateTime Duration:duration EndDateTime:dateTime}

set minusOptional {(-)?}
set minusOptionalAnchored {\A(-)?\Z}

set year {(-)?([0-9]{4}|[1-9]{1}[0-9]{4,})}
set yearAnchored {\A(-)?([0-9]{4}|[1-9]{1}[0-9]{4,})\Z}

set timezone {(Z|(([\+\-]{1}))?((?:(14)(?::)(00))|(?:([0][0-9]|[1][0-3])(?::)([0-5][0-9]))))}
set timezoneOptional ${timezone}?
set timezoneAnchored "\\A$timezoneOptional\\Z"

set gYear ${year}${timezoneOptional}
set gYearAnchored "\\A${gYear}\\Z"

set day {([0][0-9]|[12][0-9]|[3][01])}

set gDay ${day}${timezoneOptional}
set gDayAnchored "\\A${gDay}\\Z"

set month {(?:([0][1-9]|[1][0-2]))}

set gMonth ${month}${timezoneOptional}
set gMonthAnchored "\\A${gMonth}\\Z"

set gYearMonth ${year}(?:-)${month}
set gYearMonthAnchored "\\A${gYearMonth}\\Z"

set gMonthDay ${month}(?:-)${day}
set gMonthDayAnchored "\\A${gMonthDay}\\Z"

# minusOptional
::wsdl::types::simpleType::restrictByPattern \
    datetime minusOptional xsd::string $minusOptionalAnchored;

::wsdl::types::simpleType::restrictByPattern \
    datetime year xsd::integer $yearAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime timeZone xsd::string $timezoneAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime gYear xsd::string $gYearAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime gMonth  xsd::string $gMonthAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime gDay  xsd::string $gDayAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime gYearMonth  xsd::string $gYearMonthAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime gMonthDay  xsd::string $gMonthDayAnchored

::wsdl::types::simpleType::restrictByPattern \
    datetime SQL-Year-Month-Interval datetime::duration {P\p{Nd}{4}Y\p{Nd}{2}M}

<ws>namespace finalize ::datetime

<ws>namespace freeze ::datetime

<ws>return ::datetime
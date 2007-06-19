set xml "<data>
<arg1>a</arg1>
<arg2>b</arg2>
</data>"


dom parse $xml doc1

$doc1 documentElement docElement

set list1 [$docElement asList]

::xml::instance::new ::xml::instance::1 $list1 1

ns_log Notice "[::xml::instance::toXMLNS ::xml::instance::1::data]"


namespace eval ::xml::node { }

proc ::xml::node::append { parent nodeName } {


ns_return 200 text/plain $list1
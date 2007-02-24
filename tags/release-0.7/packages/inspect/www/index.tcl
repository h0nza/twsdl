
# Get Namespace Names as list:

set namespaces [::inspect::showNamespace :: 9]


append output "********** NAMESPACES ********"


append output "[::inspect::formatList $namespaces [list depth ns] {
<br>[string repeat "&nbsp;" [expr 9 - $depth]]<a href=ns.tcl?ns=$ns>$ns</a>}]"


ns_return 200 text/html "$output"
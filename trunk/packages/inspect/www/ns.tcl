set ns [ns_queryget ns]


set vars [::inspect::findVars $ns]

set procs [::inspect::findProcs $ns]


set output "
<h3> CONTENTS OF NAMESPACE $ns </h3>
<h4> Variables in $ns</h4>
<pre>
"

foreach var $vars {
    if {[array exists $var]} {
	set arrayNames [array names $var]
	append output "Array $var\n"
	foreach arrayName $arrayNames {
	    append output " ${var}\($arrayName\) = '[set ${var}($arrayName)]'\n"
	}
    } else {
	append output " $var = '[set $var]'\n"
    }
}

append output "</pre>
<h4>Procedures in $ns</h4>
<pre>"
foreach proc $procs {
    append output "\n[::inspect::showProc $proc]\n"
}
append output "</pre>"
ns_return 200 text/html $output
set ns [ns_queryget ns "::wsdb"]


set childLinks ""

foreach child [lsort [namespace children $ns]] {
    append childLinks "
<li><a href=\"wsdb.tcl?ns=$child\">$child</a></li>"
}


ns_return 200 text/html "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
<html>
<head>
 <title>Web Services Database: $ns</title>
 <link rel=\"stylesheet\" href=\"twsdl.css\" type=\"text/css\" >

</head>
<body>
<pre>
<h3>Children of $ns</h3>
<ul>$childLinks
</ul>
</pre>
<pre class=\"code-example\" title=\"$ns\">

[::inspect::displayNamespace $ns]
</pre>

</body>
</html>"


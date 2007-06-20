set ns [namespace qualifiers [ns_queryget ns "::wsdl::xyz"]]


ns_return 200 text/html "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
<html>
<head>
 <title>Web Services Database: $ns</title>
 <link rel=\"stylesheet\" href=\"twsdl.css\" type=\"text/css\" >

</head>
<body>

<pre class=\"code-example\" title=\"procs in $ns\">

[::inspect::displayProcs $ns]
</pre>

</body>
</html>"


::inspect::displayProcs
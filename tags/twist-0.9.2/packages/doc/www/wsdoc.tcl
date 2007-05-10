set namespace [ns_queryget ns "::wsdb"]
set procs     [ns_urldecode [ns_queryget procs "*"]]
set wsAlias   [ns_queryget ws "stock"]

ns_return 200 text/html "
<h3>Web Service Links</h3>
<ul>
[::inspect::displayWebServiceLinks $wsAlias]
</ul>
[::inspect::displayNamespaceChildren $namespace]
<h3>Namespace Code for $namespace</h3>
[::inspect::displayNamespaceCode $namespace ]
[::inspect::displayProcs $namespace $procs]

"
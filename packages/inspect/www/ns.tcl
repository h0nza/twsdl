set ns [ns_queryget ns]


ns_return 200 text/html [::inspect::displayNamespace $ns]
set p [ns_queryget p "ad_proc"]

set procDisplay [::inspect::showProc $p]



ns_return 200 text/plain $procDisplay
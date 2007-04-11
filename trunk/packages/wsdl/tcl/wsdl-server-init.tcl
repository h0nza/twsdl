# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

namespace eval ::wsdl::server {
    variable hostHeaderNames
    foreach option {address hostname name server servers config} {
	log Notice "---->\[ns_info $option\] = '[ns_info $option]'"
    }

    set server [ns_info server]
    set address [ns_info address]
    set hostname [ns_info hostname]
    # what valid ports will this server listen on?
    
    # 1. Look for nssock modules:
    set modules [ns_configsection "ns/modules"]
    
    # 1.1 If ns/modules doesn't exist, probably running AOLserver
    #     without virtual servers.
    if {"$modules" eq ""} {
	log Error "wsdl-server-init: twsdl requires virtual servers"
	return -code ok -errorinfo 
    }
    set modulesSetSize [ns_set size $modules]
    for {set i 0} {$i < $modulesSetSize} {incr i} {
	if {[string match "*nssock*" "[ns_set value $modules $i]"]} {
	    lappend sockModuleNames [ns_set key $modules $i]
	    log Notice "Module [ns_set key $modules $i] = [ns_set value $modules $i]"
	}
    }
    log Notice "---> sockModuleNames: $sockModuleNames"
    # 2. find which hostnames correspond to current server
    foreach sockModule $sockModuleNames {
	set moduleConfigSet [ns_configsection "ns/module/${sockModule}/servers"]
	set moduleConfigSetSize [ns_set size $moduleConfigSet]
	for {set i 0} {$i < $moduleConfigSetSize} {incr i} {
	    if {[ns_set key $moduleConfigSet $i] eq "$server"} {
		lappend hostHeaderNames [ns_set value $moduleConfigSet $i]
	    }
	}
    }
    log Notice "--->hostHeaderNames $hostHeaderNames"
	
    #set configSection [ns_configsection
    #log Notice "---> [ns_server all]"
    #log Notice "[ns_info x]"
}
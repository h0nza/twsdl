set proc_name [ns_queryget p "::wsdl::myproc"]


set argDef {
    {
	-myArgC "C is wee" 
	-myArgD "something here"
    }
    myArgA 
    myArgB
    {myArgE "first optional"}
    {myArgF "second optional"}
}

ad_proc -public ::wsdl::myproc $argDef {

    test procedure for ad_proc and twsdl integration

} {

    
    set Vars [info vars]
    foreach Var $Vars {
	append data "  $Var = [set $Var]\n"
    }

    return $data

}

if { [nsv_exists proc_doc $proc_name] } {
    set backlink_anchor "the documented procedures"
    set proc_info [nsv_get proc_doc $proc_name]
    if { [empty_string_p $proc_info] } {
        set proc_info {No documentation provided}
    }
}
ns_return 200 text/plain $proc_info
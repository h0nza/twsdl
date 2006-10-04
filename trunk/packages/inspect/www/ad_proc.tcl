set procName [ns_queryget p "::wsdl::myproc"]

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


set data "[::wsdl::myproc a b]"

set procDisplay [::inspect::showProc $procName]
set procArgParser "NO procArgParser FOUND"
catch {set procArgParser [::inspect::showProc ${procName}__arg_parser]}



proc ::InvokeMyProc { xmlDoc } {



    return [makereturn [::wsdl::myproc -myArgC "$myArgC" -myArgD "$myArgD" "$myArgA" "$myArgB" "$myArgE" "myArgF"]] 
}


ns_return 200 text/plain "$data 

$procName looks like this:
$procDisplay

argParser looks like this:
$procArgParser
"
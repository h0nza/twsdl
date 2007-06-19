# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


namespace eval ::doc { 
    variable DocRoot
    variable CutDirectory
    namespace import ::tws::log::log
}



proc ::doc::serveDoc { why } {
    
    variable DocRoot
    variable CutDirectory

    set Url [ns_conn url]
    set CutLength [string length $CutDirectory]
    set CutUrl [string range "$Url" "$CutLength" end]

    set file [file normalize [file join $DocRoot $CutUrl]]
    #log Notice "CutUrl: $CutUrl file: $file"
    if {![string match "${DocRoot}*" $file]} {
	ns_returnerror "Invalid URL"
	return filter_return
    }
    if {[file isfile $file]} {
        log Notice " serveDoc $file tail: [file tail $file] type: [ns_guesstype [file tail $file]]"
        if {[string match "text/html*" [ns_guesstype [file tail $file]]]} {
            ns_returnfile 200 text/html $file
        } else {
            ns_returnfile 200 text/plain $file
        }
    } elseif {[file isdirectory $file]} {
        css_dirlist $file
    }
    return filter_return
}


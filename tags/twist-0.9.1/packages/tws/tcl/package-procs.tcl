# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# Procedures for loading packages

namespace eval ::tws::util::package {

    namespace import ::tws::log::*
    namespace export directory
}



# set and return package root directory
# how to generalize to all platforms
proc ::tws::util::package::root { {newRoot ""} } {
    variable ::tws::packageRoot
    if {"$newRoot" ne ""} {
	set newRoot [string trim $newRoot "/"]
	set ::tws::packageRoot "/$newRoot"
    }
    return $::tws::packageRoot
}

# package directory, derived from root directory
proc ::tws::util::package::directory { packageName } {
    variable ::tws::packageRoot
    return [file join $::tws::packageRoot $packageName]
}

# load package procs
proc ::tws::util::package::procs { packageName } {

    log Notice "Package $packageName: Procs loading..."
    ::tws::sourceFile [::tws::util::package::directory [file join $packageName tcl ${packageName}-procs.tcl]]
    log Notice "Package $packageName: Procs loaded."
    
    return 0
    
}

# initialize package 
proc ::tws::util::package::init { packageName } {

    log Notice "Package $packageName: Initializing..."
    ::tws::sourceFile [::tws::util::package::directory [file join $packageName tcl ${packageName}-init.tcl]]
    log Notice "Package $packageName: Initialized."
    
    return 0
}

# configure package
# local configuration is optional per package.
# when configuration is done will depend on the package
# possibly several local configs need to be run.
# If multiple files are involved, naming should be descriptive
# of when loading takes place:
# package-preprocs-local.conf
# package-postprocs-local.conf
# package-postinit-local.conf
proc ::tws::util::package::config { packageName {fileName ""} } {
    
    if {[string eq "" "$fileName"]} {
	set fileName ${packageName}-local-conf.tcl
    } 
    set file [::tws::util::package::directory [file join $packageName tcl $fileName]]
	
    if {[file exists $file]} {
	log Notice "Configuring $packageName with $fileName"
	::tws::sourceFile $file
	log Notice "Package $packageName: Configured."
    }

}


# load a list of packages

# would be nice to be able to abort further package loading
# based on a switch for each package.
proc ::tws::util::package::loadPackages { packageList } {


    foreach package $packageList {

	if {[catch {
	    procs $package
	} err ]} {
	    global errorInfo
	    log Error $errorInfo [list PACKAGE "$package"]
	}
    }

    foreach package $packageList {
	
	if {[catch {
	    config $package
	} err ]} {
	    global errorInfo
	    log Error $errorInfo [list PACKAGE "$package"]
	}
    }

    foreach package $packageList {

	if {[catch {
	    init $package
	} err ]} {
	    global errorInfo
	    log Error $errorInfo [list PACKAGE "$package"]
	}
    }

}



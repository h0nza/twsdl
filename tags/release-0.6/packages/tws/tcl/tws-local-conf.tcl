# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# Potentially set other variable here


# load local packages
set ::tws::packages {
    tdom
    wsdl
    xml
    wsdb
    request
    stockQuoter
    inspect
    doc
    wsapi
}

::tws::util::package::loadPackages $::tws::packages

# one more thing:
::tws::log Notice "tws-local-conf.tcl Finished loading local packages"


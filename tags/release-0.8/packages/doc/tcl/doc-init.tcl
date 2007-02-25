# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


set ::doc::CutDirectory "/tws/"
set ::doc::DocRoot [file dirname "$::tws::rootDirectory"]


ns_register_filter preauth GET ${::doc::CutDirectory}*  ::doc::serveDoc
ns_register_filter preauth HEAD ${::doc::CutDirectory}* ::doc::serveDoc


# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

if {$::tws::AOLserver < 4.5} {
    package require tdom
} else {
    ns_ictl package require tdom
}



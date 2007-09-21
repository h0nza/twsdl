# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


# placeholder

set namespaces [::inspect::showNamespace :: 5]


foreach {depth ns} $namespaces {
    append output "\n[string repeat " " [expr 5 - $depth]]$ns"
}

log Notice $output

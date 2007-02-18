# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

# export AOLSERVER=/path/to/install/dir

include $(AOLSERVER)/include/ns.mak

all:
	$(INSTMAN) wsnamespace.n ../www
	$(INSTMAN) -h wsnamespace.n ../www
	$(INSTMAN) wsproc.n ../www
	$(INSTMAN) -h wsproc.n ../www
	$(INSTMAN) wsreturn.n ../www
	$(INSTMAN) -h wsreturn.n ../www


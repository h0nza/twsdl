# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>


log Notice [::xml::instance::toXMLNS \
		[::wsdb::elements::stockquoter::StockRequest::new ::xml::instance::[ns_rand 1000000] [list MSFT 1]]]

log Notice [::xml::instance::toXMLNS \
		[::wsdb::elements::stockquoter::StockQuote::new ::xml::instance::[ns_rand 1000000] [list MSFT 27.04 2006-04-11T00:00:00Z Microsoft 1 0.75 0.10]]]


set serverName StockQuoter

::wsdl::server::new $serverName "http://stockquoter.com/stockquoter" {StockQuoteService}
::wsdl::definitions::new $serverName

# Hostnames:
set ::wsdb::servers::${serverName}::hostHeaderNames [list "maria:8080" "192.168.111.108:8888"]

::wsdl::server::listen $serverName

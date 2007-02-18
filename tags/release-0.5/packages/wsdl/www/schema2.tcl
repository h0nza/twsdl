set sqns "stockquoter"


set schemaPath ::wsdb::schema::$sqns


::wsdl::schema::new "$sqns" "http://www.united-e-way.org"
::wsdl::schema::appendSimpleType enumeration $sqns symbol tcl::string {MSFT WMT XOM GM F GE}
::wsdl::schema::appendSimpleType simple $sqns verbose tcl::boolean 
::wsdl::schema::appendSimpleType simple $sqns quote tcl::double
::wsdl::schema::appendSimpleType simple $sqns dateOfChange tcl::dateTime
::wsdl::schema::appendSimpleType enumeration $sqns trend tcl::integer {-1 0 1}
::wsdl::schema::appendSimpleType simple $sqns dailyMove tcl::double
::wsdl::schema::appendSimpleType simple $sqns lastMove tcl::double
::wsdl::schema::appendSimpleType simple $sqns name tcl::string
::wsdl::schema::appendSimpleType enumeration $sqns faultCode tcl::integer {404 500 301}

::wsdl::schema::addSequence $sqns StockQuote {
  {Symbol       stockquoter::symbol          }
  {Quote        stockquoter::quote           }
  {DateOfChange stockquoter::dateOfChange 0  }
  {Name         stockquoter::name         0  1 {nillable no}}
  {Trend        stockquoter::trend        0  }
  {DailyMove    stockquoter::dailyMove    0  }
  {LastMove     stockquoter::lastMove     0  }
} 0


### Convert schema to XML:







ns_return 200 text/plain "[set ${schemaPath}::schemaItems]"


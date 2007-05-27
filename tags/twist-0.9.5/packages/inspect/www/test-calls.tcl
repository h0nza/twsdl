
set code [::wsdl::elements::modelGroup::sequence::new vs GetObjectIDResp {
  
		{ObjectID xsd::integer}
	    
}]

append code [::wsdl::elements::modelGroup::sequence::new vs CanUserAdministerObjectReq {
  {UserID xsd::integer 0}
  {ObjectID xsd::integer 1}
}]
append code [::wsdl::elements::modelGroup::sequence::new vs CanUserAdministerObjectResp {
  
		{CanAdminister boolean}
	    
}]

append code [::wsdl::elements::modelGroup::sequence::new vs BogusArgParseEgReq {
  {MyArgA xsd::string 0}
  {MyArgB xsd::boolean 0}
  {MyArgC xsd::string 1}
  {MyArgD xsd::boolean 1}
  {MyDefaultArgE xsd::string 0}
  {MyDefaultArgF xsd::boolean 0}
}]
append code [::wsdl::elements::modelGroup::sequence::new vs BogusArgParseEgResp {
  
		{MyResponseArgA xsd::string}
		{MyResponseArgB xsd::integer}
		{MyOptionalResponseArgC xsd::boolean 0} 
	    
}]


append code [::wsdl::messages::new vs GetObjectIDReqMsg GetObjectIDReq]
append code [::wsdl::messages::new vs GetObjectIDRespMsg GetObjectIDResp]
append code [::wsdl::messages::new vs CanUserAdministerObjectReqMsg CanUserAdministerObjectReq]
append code [::wsdl::messages::new vs CanUserAdministerObjectRespMsg CanUserAdministerObjectResp]
append code [::wsdl::messages::new vs BogusArgParseEgReqMsg BogusArgParseEgReq]
append code [::wsdl::messages::new vs BogusArgParseEgRespMsg BogusArgParseEgResp]


ns_return 200 text/plain $code
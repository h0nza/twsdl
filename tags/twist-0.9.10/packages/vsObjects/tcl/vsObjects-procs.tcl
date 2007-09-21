# (c) 2006 United eWay
# All rights reserved
# Licensed under the New BSD license:
# (http://www.opensource.org/licenses/bsd-license.php)
# Contact: Tom Jackson <tom at junom.com>

set vsns "vs"

# Create space for schema:
::wsdl::schema::new $vsns "http://volunteersolutions.org/VSObject"

# Creates new type vsObjectKey:
namespace eval ::wsdb::types::vs { }

namespace eval ::wsdb::types::vs::vsObjectKey {
    variable validate [namespace current]::Validate
}

proc ::wsdb::types::vs::vsObjectKey::Validate { objectKey } {
    return [::vs::objects::is_type_defined $objectKey]
}


# Return Type is Integer, I think:

::wsdl::types::simpleType::new $vsns objectId xsd::integer
::wsdl::types::simpleType::new $vsns objectName xsd::string

#### Elements
# Object ID From Key 
eval [::wsdl::elements::modelGroup::sequence::new $vsns ObjectIdFromKeyRequest {
    {ObjectKey      vs::vsObjectKey     }
}]
eval [::wsdl::elements::modelGroup::sequence::new $vsns ObjectIdFromKeyResponse {
    {ObjectId       vs::objectId        }
}]

# Get Name (From Object ID)
eval [::wsdl::elements::modelGroup::sequence::new $vsns GetNameRequest {
    {ObjectId       vs::objectId        }
}]
eval [::wsdl::elements::modelGroup::sequence::new $vsns GetNameResponse {
    {ObjectName     vs::objectName      }
}]


#### Messages
eval [::wsdl::messages::new $vsns ObjectIdFromKeyRequestMsg ObjectIdFromKeyRequest]
eval [::wsdl::messages::new $vsns ObjectIdFromKeyResponseMsg ObjectIdFromKeyResponse]
eval [::wsdl::messages::new $vsns GetNameRequestMsg GetNameRequest]
eval [::wsdl::messages::new $vsns GetNameResponseMsg GetNameResponse]


#### Operations
###### Object ID From Key
eval [::::wsdl::operations::new $vsns ObjectIdFromKeyOperation {::vs::objects::get_type_id {ObjectKey Value}} \
	  {input ObjectIdFromKeyRequestMsg} {output ObjectIdFromKeyResponseMsg}]
###### Get Name
eval [::::wsdl::operations::new $vsns GetNameOperation {::vs::objects::get_name {ObjectId Value}} \
	  {input GetNameRequestMsg} {output GetNameResponseMsg}]


#### PortType
::wsdl::portTypes::new $vsns VSObjectPortType [list ObjectIdFromKeyOperation GetNameOperation]


#### SOAP Binding
::wsdl::bindings::soap::documentLiteral::new $vsns VSObjectPortType\
    VSObjectSoapBind \
    http://volunteersolutions.org/VSObjectIdFromkey ObjectIdFromKeyOperation \
    http://volunteersolutions.org/GetName GetNameOperation;


::wsdl::ports::new VSObjectPort VSObjectSoapBind "/VSObject"

::wsdl::services::new VSObjectService {VSObjectPort}



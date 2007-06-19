
# Examples Using OpenACS data types:
# Regular expressions were taken from openacs.org, and
# use is covered by their license.
<ws>namespace init ::openacs

# Initialize Schema
<ws>namespace schema ::openacs "http://junom.com/openacs"

### Simple Types

# Phone
::wsdl::types::simpleType::restrictByPattern \
    openacs phone xsd::string \
    {^\(?([1-9][0-9]{2})\)?(-|\.|\ )?([0-9]{3})(-|\.|\ )?([0-9]{4})};

# Email
::wsdl::types::simpleType::restrictByPattern \
    openacs email xsd::string \
    {^[^@\t ]+@[^@.\t]+(\.[^@.\n ]+)+$};

# NaturalNum
::wsdl::types::simpleType::restrictByPattern \
    openacs naturalNum xsd::integer \
    {^(0*)(([1-9][0-9]*|0))$};


<ws>proc ::openacs::CheckEmail {

    {Email:openacs::email}
} {
    return [list "$Email" "True"]
} returns {Email:openacs::email IsEmail:boolean}


<ws>proc ::openacs::CheckPhone {
    {Phone:openacs::phone}
} {
    return [list $Phone True]
} returns {Phone:openacs::phone IsPhone:boolean}


<ws>proc ::openacs::CheckNaturalNumber {
    {NaturalNumber:openacs::naturalNum}
} {
    return [list $NaturalNumber True]
} returns {NaturalNumber:openacs::naturalNum IsNaturalNum:boolean}

<ws>namespace finalize ::openacs

<ws>namespace freeze ::openacs

<ws>return ::openacs
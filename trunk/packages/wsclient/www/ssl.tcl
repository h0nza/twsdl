
set url "https://www.google.com/api/adsense/v2/AdSenseForContentService?wsdl"

set content [ns_httpsget $url]


ns_return 200 text/xml $content
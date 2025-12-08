xquery version "3.1";

(:~
 : OpenAPI Endpoint
 : 
 : RESTXQ endpoint that serves the auto-generated OpenAPI 3.0 specification
 :)

module namespace openapi-api = "https://api.beethovens-werkstatt.de/rest/openapi";

import module namespace openapi = "https://api.beethovens-werkstatt.de/openapi" at "../openapi.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Get OpenAPI 3.0 specification
 : 
 : @return OpenAPI spec as JSON
 :)
declare
    %rest:GET
    %rest:path("/openapi.json")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
function openapi-api:get-spec() {
    openapi:generate-spec()
};

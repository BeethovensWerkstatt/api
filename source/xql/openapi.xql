xquery version "3.1";

(:~
 : OpenAPI 3.0 Specification Endpoint
 : 
 : Returns the auto-generated OpenAPI specification as JSON
 :)

import module namespace openapi = "https://api.beethovens-werkstatt.de/openapi" at "../xqm/openapi.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

openapi:generate-spec()

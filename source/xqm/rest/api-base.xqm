xquery version "3.1";

(:~
 : Base module for REST API with OpenAPI annotations
 : 
 : This module provides base functions and declarations for the REST API
 : including OpenAPI specification generation from RESTXQ annotations.
 :)

module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Standard CORS headers for all responses
 :)
declare function api-base:cors-headers() {
    (
        <http:header name="Access-Control-Allow-Origin" value="*" xmlns:http="http://expath.org/ns/http-client"/>,
        <http:header name="Access-Control-Allow-Methods" value="GET, POST, OPTIONS" xmlns:http="http://expath.org/ns/http-client"/>,
        <http:header name="Access-Control-Allow-Headers" value="Content-Type" xmlns:http="http://expath.org/ns/http-client"/>
    )
};

(:~
 : Standard JSON response with CORS
 :)
declare function api-base:json-response($data) {
    (
        api-base:cors-headers(),
        $data
    )
};

(:~
 : Standard XML response with CORS
 :)
declare function api-base:xml-response($data) {
    (
        api-base:cors-headers(),
        $data
    )
};

(:~
 : Error response
 :)
declare function api-base:error-response($code as xs:integer, $message as xs:string) {
    (
        <rest:response>
            <http:response status="{$code}" xmlns:http="http://expath.org/ns/http-client">
                {api-base:cors-headers()}
            </http:response>
        </rest:response>,
        map {
            "error": $code,
            "message": $message
        }
    )
};

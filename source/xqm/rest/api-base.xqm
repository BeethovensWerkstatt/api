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
        <rest:response>
            <http:response status="200" xmlns:http="http://expath.org/ns/http-client">
                {api-base:cors-headers()}
                <http:header name="Content-Type" value="application/json" xmlns:http="http://expath.org/ns/http-client"/>
            </http:response>
        </rest:response>,
        $data
    )
};

(:~
 : Standard XML response with CORS
 :)
declare function api-base:xml-response($data) {
    (
        <rest:response>
            <http:response status="200" xmlns:http="http://expath.org/ns/http-client">
                {api-base:cors-headers()}
                <http:header name="Content-Type" value="application/xml" xmlns:http="http://expath.org/ns/http-client"/>
            </http:response>
        </rest:response>,
        $data
    )
};

(:~
 : Error response with JSON body
 : @param $code HTTP status code (404, 500, etc.)
 : @param $message Human-readable error message
 :)
declare function api-base:error-response($code as xs:integer, $message as xs:string) {
    (
        <rest:response>
            <http:response status="{$code}" xmlns:http="http://expath.org/ns/http-client">
                {api-base:cors-headers()}
                <http:header name="Content-Type" value="application/json" xmlns:http="http://expath.org/ns/http-client"/>
            </http:response>
        </rest:response>,
        map {
            "error": $code,
            "message": $message
        }
    )
};

(:~
 : 404 Not Found response
 : @param $resource Description of the resource that wasn't found
 :)
declare function api-base:not-found($resource as xs:string) {
    api-base:error-response(404, "Resource not found: " || $resource)
};

(:~
 : 400 Bad Request response
 : @param $message Description of what's wrong with the request
 :)
declare function api-base:bad-request($message as xs:string) {
    api-base:error-response(400, $message)
};

(:~
 : 500 Internal Server Error response
 : @param $message Error description
 :)
declare function api-base:server-error($message as xs:string) {
    api-base:error-response(500, "Internal server error: " || $message)
};

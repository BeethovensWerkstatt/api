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
(:~
 : Forward request to an XQL script with parameters
 : 
 : This is a migration helper that forwards RESTXQ requests to existing XQL scripts.
 : Use this to gradually migrate legacy endpoints while keeping the same backend logic.
 : 
 : Note: CORS headers are set by the controller.xql before forwarding to RESTXQ,
 : so we don't need to set them here. The legacy scripts may call response:set-header()
 : which will fail in RESTXQ context - this is expected and handled.
 :
 : @param $xql-path Path to the XQL script relative to app root (e.g., "/resources/xql/module1/script.xql")
 : @param $params Map of parameter names to values
 : @return The result of evaluating the XQL script
 :)
declare function api-base:forward-to-xql($xql-path as xs:string, $params as map(*)) {
    (: Build the full path to the XQL script :)
    let $full-path := "/db/apps/api" || $xql-path
    
    (: Read and parse the XQL file :)
    let $xql-content := util:binary-doc($full-path)
    let $xql-text := util:binary-to-string($xql-content)
    
    (: Remove or comment out response:set-header calls - preserve trailing comma/semicolon :)
    let $cleaned-xql := replace($xql-text, 
        'response:set-header\s*\([^)]+\)\s*([,;])',
        '(: CORS handled by RESTXQ :) true()$1',
        '')
    (: Also handle case without trailing punctuation :)
    let $cleaned-xql := replace($cleaned-xql, 
        'response:set-header\s*\([^)]+\)(\s*[^,;])',
        '(: CORS handled by RESTXQ :) true()$1',
        '')
    
    (: Remove response:set-status-code calls - preserve trailing comma/semicolon :)
    let $cleaned-xql2 := replace($cleaned-xql, 
        'response:set-status-code\s*\([^)]+\)\s*([,;])',
        '(: Status handled by RESTXQ :) true()$1',
        '')
    (: Also handle case without trailing punctuation :)
    let $cleaned-xql2 := replace($cleaned-xql2, 
        'response:set-status-code\s*\([^)]+\)(\s*[^,;])',
        '(: Status handled by RESTXQ :) true()$1',
        '')
    
    (: Replace request:get-parameter calls with the actual values from $params :)
    let $final-xql := fold-left(map:keys($params), $cleaned-xql2, function($xql, $key) {
        let $value := $params($key)
        let $pattern := "request:get-parameter\s*\(\s*'" || $key || "'\s*,\s*'[^']*'\s*\)"
        return replace($xql, $pattern, "'" || $value || "'")
    })
    
    (: Convert map to parameter sequence for util:eval - as backup for external variables :)
    let $param-seq := 
        for $key in map:keys($params)
        return (xs:QName($key), $params($key))
    
    return
        if (count($param-seq) > 0) then
            util:eval($final-xql, false(), $param-seq)
        else
            util:eval($final-xql, false())
};
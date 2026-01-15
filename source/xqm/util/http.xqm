xquery version "3.1";

(:~
 : HTTP Utilities
 : 
 : Provides helper functions for HTTP request/response handling,
 : including CORS headers, content negotiation, and caching.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace http = "https://api.beethovens-werkstatt.de/util/http";

import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";

(:~
 : Set CORS headers based on configuration
 : Call this at the beginning of each API endpoint
 :)
declare function http:set-cors-headers() as empty-sequence() {
    (: Always allow CORS for now - can be configured later :)
    response:set-header("Access-Control-Allow-Origin", "*"),
    response:set-header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"),
    response:set-header("Access-Control-Allow-Headers", "Content-Type, Authorization"),
    response:set-header("Access-Control-Max-Age", "86400")
};

(:~
 : Set cache control headers
 :
 : @param $max-age Cache duration in seconds (0 = no cache)
 :)
declare function http:set-cache-headers($max-age as xs:integer) as empty-sequence() {
    if ($max-age > 0) then (
        response:set-header("Cache-Control", "public, max-age=" || $max-age),
        response:set-header("Vary", "Accept")
    ) else (
        response:set-header("Cache-Control", "no-cache, no-store, must-revalidate"),
        response:set-header("Pragma", "no-cache"),
        response:set-header("Expires", "0")
    )
};

(:~
 : Set common API response headers
 : Call this at the start of each API response
 :)
declare function http:set-api-headers() as empty-sequence() {
    http:set-cors-headers(),
    response:set-header("X-Content-Type-Options", "nosniff"),
    response:set-header("X-API-Version", $config:app-version)
};

(:~
 : Handle OPTIONS preflight request for CORS
 : Use this in controller.xql for OPTIONS requests
 :)
declare function http:handle-options() as element() {
    http:set-cors-headers(),
    response:set-status-code(204),
    <empty/>
};

(:~
 : Get the preferred content type from Accept header
 :
 : @param $supported Sequence of supported media types
 : @return The best matching media type or the first supported type
 :)
declare function http:get-preferred-type($supported as xs:string*) as xs:string {
    let $accept := request:get-header("Accept")
    return
        if (empty($accept) or $accept = "*/*") then
            $supported[1]
        else
            let $accepted := tokenize($accept, ",")
            let $match := 
                for $type in $accepted
                let $cleaned := normalize-space(replace($type, ";.*$", ""))
                where $cleaned = $supported
                return $cleaned
            return
                if (exists($match)) then $match[1]
                else $supported[1]
};

(:~
 : Check if client accepts JSON
 :)
declare function http:accepts-json() as xs:boolean {
    let $accept := request:get-header("Accept")
    return empty($accept) or contains($accept, "application/json") or contains($accept, "*/*")
};

(:~
 : Check if client accepts XML
 :)
declare function http:accepts-xml() as xs:boolean {
    let $accept := request:get-header("Accept")
    return contains($accept, "application/xml") or contains($accept, "text/xml")
};

(:~
 : Get a required request parameter
 :
 : @param $name Parameter name
 : @return Parameter value
 : @throws error if parameter is missing
 :)
declare function http:required-param($name as xs:string) as xs:string {
    let $value := request:get-parameter($name, ())
    return
        if (empty($value) or $value = "") then
            error(xs:QName("http:missing-param"), "Required parameter missing: " || $name)
        else
            $value
};

(:~
 : Get an optional request parameter with default
 :
 : @param $name Parameter name
 : @param $default Default value
 : @return Parameter value or default
 :)
declare function http:param($name as xs:string, $default as xs:string) as xs:string {
    let $value := request:get-parameter($name, ())
    return if (exists($value) and $value != "") then $value else $default
};

(:~
 : Get the request path relative to the application
 :)
declare function http:get-path() as xs:string {
    request:get-attribute("exist:path")
};

(:~
 : Get the HTTP method
 :)
declare function http:get-method() as xs:string {
    request:get-method()
};

(:~
 : Set a 201 Created response with Location header
 :
 : @param $location URI of the created resource
 :)
declare function http:created($location as xs:string) as empty-sequence() {
    response:set-status-code(201),
    response:set-header("Location", $location)
};

(:~
 : Set a 204 No Content response
 :)
declare function http:no-content() as empty-sequence() {
    response:set-status-code(204)
};

(:~
 : Set a redirect response
 :
 : @param $location URI to redirect to
 : @param $permanent Whether this is a permanent redirect (301) or temporary (302)
 :)
declare function http:redirect($location as xs:string, $permanent as xs:boolean) as empty-sequence() {
    response:set-status-code(if ($permanent) then 301 else 302),
    response:set-header("Location", $location)
};

(:~
 : Build a paginated response with Link headers
 :
 : @param $items The items for this page
 : @param $page Current page number
 : @param $limit Items per page
 : @param $total Total number of items
 : @param $base-uri Base URI for pagination links
 : @return Map with items and pagination info
 :)
declare function http:paginated-response(
    $items as item()*,
    $page as xs:integer,
    $limit as xs:integer,
    $total as xs:integer,
    $base-uri as xs:string
) as map(*) {
    let $total-pages := ceiling($total div $limit) cast as xs:integer
    let $has-next := $page < $total-pages
    let $has-prev := $page > 1
    
    (: Build Link header :)
    let $links := string-join((
        if ($has-next) then '<' || $base-uri || '?page=' || ($page + 1) || '&amp;limit=' || $limit || '>; rel="next"' else (),
        if ($has-prev) then '<' || $base-uri || '?page=' || ($page - 1) || '&amp;limit=' || $limit || '>; rel="prev"' else (),
        '<' || $base-uri || '?page=1&amp;limit=' || $limit || '>; rel="first"',
        '<' || $base-uri || '?page=' || $total-pages || '&amp;limit=' || $limit || '>; rel="last"'
    ), ", ")
    
    let $_ := if ($links != "") then response:set-header("Link", $links) else ()
    
    return map {
        "data": array { $items },
        "pagination": map {
            "page": $page,
            "limit": $limit,
            "total": $total,
            "totalPages": $total-pages,
            "hasNext": $has-next,
            "hasPrev": $has-prev
        }
    }
};

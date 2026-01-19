xquery version "3.1";

(:~
 : Error Handling Utilities
 : 
 : Provides standardized error responses for the API.
 : All API errors should use these functions to ensure consistent
 : error response format across all endpoints.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace bwerr = "https://api.beethovens-werkstatt.de/util/error";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : HTTP status codes and their descriptions
 :)
declare variable $bwerr:HTTP_BAD_REQUEST := 400;
declare variable $bwerr:HTTP_UNAUTHORIZED := 401;
declare variable $bwerr:HTTP_FORBIDDEN := 403;
declare variable $bwerr:HTTP_NOT_FOUND := 404;
declare variable $bwerr:HTTP_METHOD_NOT_ALLOWED := 405;
declare variable $bwerr:HTTP_CONFLICT := 409;
declare variable $bwerr:HTTP_UNPROCESSABLE_ENTITY := 422;
declare variable $bwerr:HTTP_INTERNAL_ERROR := 500;
declare variable $bwerr:HTTP_SERVICE_UNAVAILABLE := 503;

(:~
 : Create a standardized API error response
 : 
 : @param $status HTTP status code
 : @param $message Human-readable error message
 : @param $details Optional map with additional error details
 : @return A map representing the error response
 :)
declare function bwerr:api-error(
    $status as xs:integer,
    $message as xs:string,
    $details as map(*)?
) as map(*) {
    (: Set the HTTP status code :)
    let $_ := response:set-status-code($status)
    return map {
        "error": map:merge((
            map {
                "status": $status,
                "message": $message,
                "timestamp": format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z")
            },
            if (exists($details)) then map { "details": $details } else ()
        ))
    }
};

(:~
 : Create a 400 Bad Request error
 : 
 : @param $message Error message
 : @param $details Optional error details
 : @return Error response map
 :)
declare function bwerr:bad-request($message as xs:string, $details as map(*)?) as map(*) {
    bwerr:api-error($bwerr:HTTP_BAD_REQUEST, $message, $details)
};

(:~
 : Create a 400 Bad Request error (without details)
 : 
 : @param $message Error message
 : @return Error response map
 :)
declare function bwerr:bad-request($message as xs:string) as map(*) {
    bwerr:bad-request($message, ())
};

(:~
 : Create a 404 Not Found error
 : 
 : @param $resource The resource that was not found
 : @return Error response map
 :)
declare function bwerr:not-found($resource as xs:string) as map(*) {
    bwerr:api-error($bwerr:HTTP_NOT_FOUND, "Resource not found: " || $resource, ())
};

(:~
 : Create a 404 Not Found error with custom message
 : 
 : @param $message Custom error message
 : @param $details Optional error details
 : @return Error response map
 :)
declare function bwerr:not-found-with-message($message as xs:string, $details as map(*)?) as map(*) {
    bwerr:api-error($bwerr:HTTP_NOT_FOUND, $message, $details)
};

(:~
 : Create a 500 Internal Server Error
 : 
 : @param $message Error message
 : @param $details Optional error details (only shown in debug mode)
 : @return Error response map
 :)
declare function bwerr:internal-error($message as xs:string, $details as map(*)?) as map(*) {
    (: In production, hide internal details :)
    let $show-details := environment-variable("BW_DEBUG") = "true"
    return bwerr:api-error($bwerr:HTTP_INTERNAL_ERROR, $message, 
        if ($show-details) then $details else ()
    )
};

(:~
 : Create a 500 Internal Server Error (without details)
 : 
 : @param $message Error message
 : @return Error response map
 :)
declare function bwerr:internal-error($message as xs:string) as map(*) {
    bwerr:internal-error($message, ())
};

(:~
 : Create a 422 Unprocessable Entity error (validation failed)
 : 
 : @param $message Error message
 : @param $validationErrors Map of field names to error messages
 : @return Error response map
 :)
declare function bwerr:validation-error($message as xs:string, $validationErrors as map(*)?) as map(*) {
    bwerr:api-error($bwerr:HTTP_UNPROCESSABLE_ENTITY, $message, $validationErrors)
};

(:~
 : Wrap a function call with error handling
 : Use this to catch XQuery errors and convert them to API errors
 : 
 : @param $fn The function to execute
 : @return Either the function result or an error response
 :)
declare function bwerr:try-catch($fn as function() as item()*) as item()* {
    try {
        $fn()
    } catch * {
        let $details := map {
            "code": $err:code,
            "description": $err:description,
            "module": $err:module,
            "line": $err:line-number
        }
        return bwerr:internal-error("An unexpected error occurred", $details)
    }
};

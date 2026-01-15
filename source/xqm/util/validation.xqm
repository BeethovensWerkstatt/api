xquery version "3.1";

(:~
 : Validation Utilities
 : 
 : Provides input validation functions for API parameters.
 : Use these functions to validate and sanitize user input.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace validate = "https://api.beethovens-werkstatt.de/util/validation";

import module namespace err = "https://api.beethovens-werkstatt.de/util/error" at "./error.xqm";

(:~
 : Regex patterns for common validations
 :)
declare variable $validate:PATTERN_ID := "^[a-zA-Z0-9_\-\.]+$";
declare variable $validate:PATTERN_UUID := "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$";
declare variable $validate:PATTERN_SLUG := "^[a-z0-9]+(?:-[a-z0-9]+)*$";
declare variable $validate:PATTERN_VERSION := "^\d+\.\d+\.\d+$";

(:~
 : Validation result type
 : Returns a map with either "value" (success) or "error" (failure)
 :)

(:~
 : Validate a document/resource ID
 : Allows alphanumeric characters, underscores, hyphens, and dots
 :
 : @param $id The ID to validate
 : @return The validated ID or throws an error
 :)
declare function validate:id($id as xs:string?) as xs:string {
    if (empty($id) or $id = "") then
        error(xs:QName("validate:missing-id"), "ID parameter is required")
    else if (not(matches($id, $validate:PATTERN_ID))) then
        error(xs:QName("validate:invalid-id"), "Invalid ID format. Allowed: alphanumeric, underscore, hyphen, dot")
    else if (string-length($id) > 255) then
        error(xs:QName("validate:id-too-long"), "ID must be at most 255 characters")
    else
        $id
};

(:~
 : Validate a document/resource ID, returning a map result
 : Use this when you want to handle validation errors gracefully
 :
 : @param $id The ID to validate
 : @return map with "valid" boolean and either "value" or "error"
 :)
declare function validate:id-safe($id as xs:string?) as map(*) {
    try {
        map { "valid": true(), "value": validate:id($id) }
    } catch * {
        map { "valid": false(), "error": $err:description }
    }
};

(:~
 : Validate that a value is not empty
 :
 : @param $value The value to check
 : @param $name The parameter name (for error messages)
 : @return The value if not empty
 :)
declare function validate:required($value as item()*, $name as xs:string) as item()+ {
    if (empty($value) or (count($value) = 1 and $value instance of xs:string and $value = "")) then
        error(xs:QName("validate:required"), $name || " is required")
    else
        $value
};

(:~
 : Validate a positive integer
 :
 : @param $value The value to validate
 : @param $name The parameter name (for error messages)
 : @return The validated integer
 :)
declare function validate:positive-integer($value as xs:string?, $name as xs:string) as xs:integer {
    if (empty($value) or $value = "") then
        error(xs:QName("validate:required"), $name || " is required")
    else if (not(matches($value, "^\d+$"))) then
        error(xs:QName("validate:not-integer"), $name || " must be a positive integer")
    else
        let $int := xs:integer($value)
        return
            if ($int < 1) then
                error(xs:QName("validate:not-positive"), $name || " must be greater than 0")
            else
                $int
};

(:~
 : Validate an optional positive integer with default
 :
 : @param $value The value to validate
 : @param $default The default value if empty
 : @return The validated integer or default
 :)
declare function validate:positive-integer-or-default($value as xs:string?, $default as xs:integer) as xs:integer {
    if (empty($value) or $value = "") then
        $default
    else if (not(matches($value, "^\d+$"))) then
        $default
    else
        let $int := xs:integer($value)
        return if ($int < 1) then $default else $int
};

(:~
 : Validate that a string is within length bounds
 :
 : @param $value The string to validate
 : @param $min Minimum length (inclusive)
 : @param $max Maximum length (inclusive)
 : @param $name The parameter name (for error messages)
 : @return The validated string
 :)
declare function validate:string-length($value as xs:string?, $min as xs:integer, $max as xs:integer, $name as xs:string) as xs:string {
    let $len := string-length($value)
    return
        if ($len < $min) then
            error(xs:QName("validate:too-short"), $name || " must be at least " || $min || " characters")
        else if ($len > $max) then
            error(xs:QName("validate:too-long"), $name || " must be at most " || $max || " characters")
        else
            $value
};

(:~
 : Validate a measure range (e.g., "1-10", "5", "1,3,5-8")
 :
 : @param $range The measure range string
 : @return The validated range string
 :)
declare function validate:measure-range($range as xs:string?) as xs:string {
    if (empty($range) or $range = "") then
        error(xs:QName("validate:required"), "Measure range is required")
    else if (not(matches($range, "^(\d+(-\d+)?)(,\d+(-\d+)?)*$"))) then
        error(xs:QName("validate:invalid-range"), "Invalid measure range format. Examples: '1-10', '5', '1,3,5-8'")
    else
        $range
};

(:~
 : Validate a list of comma-separated IDs
 :
 : @param $ids The comma-separated IDs
 : @return Sequence of validated IDs
 :)
declare function validate:id-list($ids as xs:string?) as xs:string* {
    if (empty($ids) or $ids = "") then
        ()
    else
        for $id in tokenize($ids, ",")
        let $trimmed := normalize-space($id)
        where $trimmed != ""
        return validate:id($trimmed)
};

(:~
 : Sanitize a string for safe inclusion in XML
 : Removes or escapes potentially dangerous characters
 :
 : @param $input The string to sanitize
 : @return The sanitized string
 :)
declare function validate:sanitize-string($input as xs:string?) as xs:string {
    if (empty($input)) then
        ""
    else
        (: Remove null bytes and control characters except newline/tab :)
        let $cleaned := replace($input, "[&#x00;-&#x08;&#x0B;&#x0C;&#x0E;-&#x1F;]", "")
        return normalize-space($cleaned)
};

(:~
 : Validate pagination parameters
 :
 : @param $page Page number (1-based)
 : @param $limit Items per page
 : @return Map with validated "page" and "limit"
 :)
declare function validate:pagination($page as xs:string?, $limit as xs:string?) as map(*) {
    map {
        "page": validate:positive-integer-or-default($page, 1),
        "limit": min((validate:positive-integer-or-default($limit, 20), 100))  (: Max 100 per page :)
    }
};

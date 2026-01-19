xquery version "3.1";

(:~
 : Logging Utilities
 : 
 : Provides structured logging for the API with support for different
 : log levels and contextual information.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace log = "https://api.beethovens-werkstatt.de/util/logging";

declare namespace util = "http://exist-db.org/xquery/util";
declare namespace system = "http://exist-db.org/xquery/system";

(:~
 : Log levels (in order of severity)
 :)
declare variable $log:LEVEL_DEBUG := "debug";
declare variable $log:LEVEL_INFO := "info";
declare variable $log:LEVEL_WARN := "warn";
declare variable $log:LEVEL_ERROR := "error";

(:~
 : Get the current log level from environment variable
 : Defaults to "info" if not configured
 :)
declare variable $log:current-level := 
    let $configured := environment-variable("BW_LOG_LEVEL")
    return if ($configured and $configured != "") then $configured else $log:LEVEL_INFO;

(:~
 : Numeric priority for log levels (higher = more severe)
 :)
declare function log:level-priority($level as xs:string) as xs:integer {
    switch ($level)
        case "debug" return 0
        case "info" return 1
        case "warn" return 2
        case "error" return 3
        default return 1
};

(:~
 : Check if a message at the given level should be logged
 :)
declare function log:should-log($level as xs:string) as xs:boolean {
    log:level-priority($level) >= log:level-priority($log:current-level)
};

(:~
 : Format a log message with timestamp and context
 :)
declare function log:format-message($level as xs:string, $message as xs:string, $context as map(*)?) as xs:string {
    let $timestamp := format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]")
    let $context-str := if (exists($context)) 
        then " | " || serialize($context, map{"method": "json", "indent": false()})
        else ""
    return "[" || $timestamp || "] [" || upper-case($level) || "] [BW-API] " || $message || $context-str
};

(:~
 : Log a debug message
 : Only logged when log level is set to debug
 :)
declare function log:debug($message as xs:string) as empty-sequence() {
    log:debug($message, ())
};

(:~
 : Log a debug message with context
 :)
declare function log:debug($message as xs:string, $context as map(*)?) as empty-sequence() {
    if (log:should-log($log:LEVEL_DEBUG)) then
        util:log("debug", log:format-message($log:LEVEL_DEBUG, $message, $context))
    else ()
};

(:~
 : Log an info message
 :)
declare function log:info($message as xs:string) as empty-sequence() {
    log:info($message, ())
};

(:~
 : Log an info message with context
 :)
declare function log:info($message as xs:string, $context as map(*)?) as empty-sequence() {
    if (log:should-log($log:LEVEL_INFO)) then
        util:log("info", log:format-message($log:LEVEL_INFO, $message, $context))
    else ()
};

(:~
 : Log a warning message
 :)
declare function log:warn($message as xs:string) as empty-sequence() {
    log:warn($message, ())
};

(:~
 : Log a warning message with context
 :)
declare function log:warn($message as xs:string, $context as map(*)?) as empty-sequence() {
    if (log:should-log($log:LEVEL_WARN)) then
        util:log("warn", log:format-message($log:LEVEL_WARN, $message, $context))
    else ()
};

(:~
 : Log an error message
 :)
declare function log:error($message as xs:string) as empty-sequence() {
    log:error($message, ())
};

(:~
 : Log an error message with context
 :)
declare function log:error($message as xs:string, $context as map(*)?) as empty-sequence() {
    if (log:should-log($log:LEVEL_ERROR)) then
        util:log("error", log:format-message($log:LEVEL_ERROR, $message, $context))
    else ()
};

(:~
 : Log an API request
 : Call this at the start of each API endpoint for request tracking
 :)
declare function log:request($method as xs:string, $path as xs:string) as empty-sequence() {
    log:info("API Request", map {
        "method": $method,
        "path": $path,
        "remote-addr": request:get-remote-addr()
    })
};

(:~
 : Log an API response
 : Call this before returning from each API endpoint
 :)
declare function log:response($status as xs:integer, $duration-ms as xs:integer?) as empty-sequence() {
    log:info("API Response", map:merge((
        map { "status": $status },
        if (exists($duration-ms)) then map { "duration_ms": $duration-ms } else ()
    )))
};

(:~
 : Log the start of a timed operation
 : Returns the start time for use with log:timed-end
 :)
declare function log:timed-start($operation as xs:string) as xs:dateTime {
    log:debug("Starting operation: " || $operation),
    current-dateTime()
};

(:~
 : Log the end of a timed operation
 :)
declare function log:timed-end($operation as xs:string, $start as xs:dateTime) as empty-sequence() {
    let $duration := (current-dateTime() - $start) div xs:dayTimeDuration("PT0.001S")
    return log:debug("Completed operation: " || $operation, map { "duration_ms": $duration })
};

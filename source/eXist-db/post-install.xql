xquery version "3.1";

(:~
 : Post-installation script for Beethovens Werkstatt API
 : 
 : This script runs after package deployment and:
 : 1. Registers all RESTXQ modules with the RESTXQ registry
 : 2. Sets up any required indexes
 : 3. Initializes configuration
 :
 : @author Beethovens Werkstatt
 : @version 2.0.0
 :)

import module namespace exrest = "http://exquery.org/ns/restxq/exist" at "java:org.exist.extensions.exquery.restxq.impl.xquery.exist.ExistRestXqModule";

(: The following external variables are set by the repo:deploy function :)
declare variable $home external;
declare variable $dir external;
declare variable $target external;

(:~
 : List of RESTXQ modules to register
 : Add new API modules here when created
 :)
let $modules := (
    (: Core API modules :)
    $target || "/resources/xqm/rest/api-base.xqm",
    $target || "/resources/xqm/rest/openapi-api.xqm",
    
    (: IIIF endpoints :)
    $target || "/resources/xqm/rest/iiif-api.xqm",
    
    (: Module endpoints :)
    $target || "/resources/xqm/rest/module1-api.xqm",
    $target || "/resources/xqm/rest/module2-api.xqm",
    $target || "/resources/xqm/rest/module3-api.xqm",
    $target || "/resources/xqm/rest/module4-api.xqm",
    
    (: Edition endpoints :)
    $target || "/resources/xqm/rest/editions-api.xqm",

    (: Document endpoints :)
    $target || "/resources/xqm/rest/documents-api.xqm",
    
    (: Utility endpoints :)
    $target || "/resources/xqm/rest/file-api.xqm",
    $target || "/resources/xqm/rest/tools-api.xqm"
)

let $_ := util:log("info", "[BW-API] Post-install: Starting RESTXQ module registration...")

let $registered :=
    for $module-path in $modules
    return
        try {
            if (util:binary-doc-available($module-path) or doc-available($module-path)) then (
                let $result := exrest:register-module(xs:anyURI($module-path))
                let $_ := util:log("info", "[BW-API] Registered: " || $module-path)
                return true()
            ) else (
                let $_ := util:log("warn", "[BW-API] Module not found: " || $module-path)
                return false()
            )
        } catch * {
            let $_ := util:log("error", "[BW-API] Failed to register " || $module-path || ": " || $err:description)
            return false()
        }

let $success-count := count($registered[. = true()])
let $total := count($modules)

return util:log("info", "[BW-API] Post-install complete: " || $success-count || "/" || $total || " modules registered")

xquery version "3.1";

(:~
 : Post-installation script for Beethovens Werkstatt API
 : Registers RESTXQ modules explicitly after deployment
 :)

import module namespace exrest = "http://exquery.org/ns/restxq/exist" at "java:org.exist.extensions.exquery.restxq.impl.xquery.exist.ExistRestXqModule";

(: The following external variables are set by the repo:deploy function :)
declare variable $home external;
declare variable $dir external;
declare variable $target external;

let $modules := (
    "/db/apps/" || $target || "/resources/xqm/rest/iiif-api.xqm",
    "/db/apps/" || $target || "/resources/xqm/rest/module1-api.xqm",
    "/db/apps/" || $target || "/resources/xqm/rest/module2-api.xqm",
    "/db/apps/" || $target || "/resources/xqm/rest/module3-api.xqm",
    "/db/apps/" || $target || "/resources/xqm/rest/module4-api.xqm",
    "/db/apps/" || $target || "/resources/xqm/rest/services-api.xqm",
    "/db/apps/" || $target || "/resources/xqm/rest/openapi-endpoint.xqm"
)

let $_ := util:log("info", "API post-install: Registering " || count($modules) || " RESTXQ modules...")

for $module-path in $modules
return
    try {
        let $result := exrest:register-module(xs:anyURI($module-path))
        return util:log("info", "API post-install: Registered " || $module-path)
    } catch * {
        util:log("error", "API post-install: Failed to register " || $module-path || ": " || $err:description)
    }

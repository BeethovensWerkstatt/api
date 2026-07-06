xquery version "3.1";

(:~
 : Configuration Module
 : 
 : Provides application-wide configuration settings.
 : Supports environment-based configuration loaded from XML files.
 : 
 : Environment is determined by:
 : 1. BW_ENV system property (development, staging, production)
 : 2. Defaults to "development" if not set
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace config="https://api.beethovens-werkstatt.de";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace cfg="https://api.beethovens-werkstatt.de/config";

(:~
 : Determine the application root collection from the current module load path.
 :)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, 'xmldb:exist://')) then
            if (starts-with($rawPath, 'xmldb:exist://embedded-eXist-server')) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, '/resources/')
;

(:~
 : Current environment (development, staging, production)
 : Reads from BW_ENV environment variable, defaults to "development"
 :)
declare variable $config:environment :=
    let $env := environment-variable("BW_ENV")
    return if ($env and $env != "") then $env else "development";

(:~
 : Environment-specific configuration document
 :)
declare variable $config:env-config :=
    let $config-path := $config:app-root || "/config/" || $config:environment || ".xml"
    return
        if (doc-available($config-path)) then
            doc($config-path)/cfg:config
        else (
            util:log("warn", "[BW-API] Config file not found: " || $config-path || ", using defaults"),
            ()
        );

(:~
 : Get a configuration value with fallback
 :)
declare function config:get($path as xs:string, $default as xs:string) as xs:string {
    let $value := $config:env-config/*[local-name() = $path]/string()
    return if ($value and $value != "") then $value else $default
};

(:~
 : Check if a feature is enabled
 :)
declare function config:is-enabled($feature as xs:string) as xs:boolean {
    let $element := $config:env-config/*[local-name() = $feature]
    return $element/@enabled = "true"
};

(: ============ Core Configuration Variables ============ :)

(:~
 : Public base URI for API endpoints
 : This is replaced at build time with the appropriate URL
 :)
declare variable $config:public-base-uri := '$$deployTarget$$'; (: Set automatically through build.js :)

declare variable $config:data-root := $config:app-root || '/data/data/';

declare variable $config:data-cache-root := $config:app-root || '/data-cache/cache/';

declare variable $config:module1-root := $config:data-root || 'module1/';

declare variable $config:module3-root := $config:data-root || 'module3/';

declare variable $config:iiif-basepath := $config:public-base-uri || '/iiif/';

declare variable $config:file-basepath := $config:public-base-uri || '/file/';

declare variable $config:ema-basepath := $config:public-base-uri || '/ema/';

declare variable $config:module3-basepath := $config:public-base-uri || '/module3/';

(: module 4 onwards :)
declare variable $config:documents-basepath := $config:public-base-uri || '/documents/';

declare variable $config:xslt-basepath := $config:app-root || '/resources/xslt/';

declare variable $config:repo-descriptor := doc(concat($config:app-root, '/repo.xml'))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, '/expath-pkg.xml'))/expath:package;

declare variable $config:app-version := $config:expath-descriptor/@version/string();

declare variable $config:api-url := $config:public-base-uri;

declare variable $config:prerendered-basepath := $config:public-base-uri || '/document/prerendered/';

declare variable $config:svg-shapes-basepath := $config:public-base-uri || '/document/shapes/';

(: ============ Feature Flags ============ :)

(:~
 : Whether CORS is enabled
 :)
declare variable $config:cors-enabled := config:is-enabled("cors");

(:~
 : Whether debug mode is enabled
 :)
declare variable $config:debug-enabled := config:is-enabled("debug");

(:~
 : Whether caching is enabled
 :)
declare variable $config:cache-enabled := config:is-enabled("cache");

(:~
 : Cache TTL in seconds (0 = no cache)
 :)
declare variable $config:cache-ttl := 
    let $ttl := config:get("cache/ttl", "0")
    return xs:integer($ttl);

(: ============ API Paths ============ :)

(:~
 : API prefix (used for RESTXQ routing)
 :)
declare variable $config:api-prefix := config:get("api/prefix", "/api");

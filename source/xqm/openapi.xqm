xquery version "3.1";

(:~
 : OpenAPI 3.0 Generator
 : 
 : Introspects RESTXQ modules and generates OpenAPI 3.0 specification
 :)

module namespace openapi = "https://api.beethovens-werkstatt.de/openapi";

import module namespace config="https://api.beethovens-werkstatt.de" at "./config.xqm";
import module namespace exrest = "http://exquery.org/ns/restxq/exist" at "java:org.exist.extensions.exquery.restxq.impl.xquery.exist.ExistRestXqModule";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Generate complete OpenAPI 3.0 specification
 :)
declare function openapi:generate-spec() as map(*) {
    (: Query the RESTXQ registry for all registered resource functions :)
    let $rest-modules := (
        "/db/apps/api/resources/xqm/rest/iiif-api.xqm",
        "/db/apps/api/resources/xqm/rest/module1-api.xqm",
        "/db/apps/api/resources/xqm/rest/module2-api.xqm",
        "/db/apps/api/resources/xqm/rest/module3-api.xqm",
        "/db/apps/api/resources/xqm/rest/module4-api.xqm",
        "/db/apps/api/resources/xqm/rest/services-api.xqm",
        "/db/apps/api/resources/xqm/rest/openapi-endpoint.xqm"
    )
    
    (: Get registered RESTXQ functions from the registry :)
    let $paths := map:merge(
        for $module in $rest-modules
        return 
            try {
                let $registry-result := exrest:register-module(xs:anyURI($module))
                return openapi:extract-paths-from-registry($registry-result)
            } catch * {
                ()
            }
    )
    
    return map {
        "openapi": "3.0.0",
        "info": map {
            "title": "Beethovens Werkstatt API",
            "description": "API for accessing MEI-encoded music data, genetic editions, IIIF manifests, and comparative analysis",
            "version": $config:app-version,
            "contact": map {
                "name": "Beethovens Werkstatt",
                "url": "https://beethovens-werkstatt.de"
            },
            "license": map {
                "name": "AGPL-3.0",
                "url": "https://www.gnu.org/licenses/agpl-3.0.html"
            }
        },
        "servers": array {
            map {
                "url": $config:api-url,
                "description": "Production server"
            },
            map {
                "url": "http://localhost:8082/exist/apps/api",
                "description": "Local development server"
            }
        },
        "paths": $paths,
        "components": map {
            "schemas": openapi:generate-schemas()
        }
    }
};

(:~
 : Extract paths from RESTXQ registry result
 :)
declare function openapi:extract-paths-from-registry($registry-result as element()*) as map(*)* {
    for $func in $registry-result//rest:resource-function
    let $annotations := $func/rest:annotations
    
    (: Extract HTTP method :)
    let $method-annotation := $annotations/(rest:GET|rest:POST|rest:PUT|rest:DELETE)[1]
    let $method := if (exists($method-annotation)) then lower-case(local-name($method-annotation)) else ()
    
    (: Extract path segments :)
    let $path-segments := $annotations/rest:path/rest:segment/string()
    let $path := if (exists($path-segments)) then "/" || string-join($path-segments, "/") else ()
    
    (: Extract produces media type :)
    let $produces := $annotations/rest:produces/string()
    
    (: Extract consumes media type :)
    let $consumes := $annotations/rest:consumes/string()
    
    (: Extract query parameters :)
    let $query-params := $annotations/rest:query-param
    
    (: Extract function identity :)
    let $func-name := $func/rest:identity/@local-name/string()
    
    where exists($method) and exists($path)
    
    let $normalized-path := replace($path, '\{([^}]+)\}', '{$1}')
    
    (: Extract path parameters from the path itself :)
    let $path-params := analyze-string($path, '\{([^}]+)\}')//fn:group[@nr='1']/string()
    let $parameters := (
        for $param-name in $path-params
        return map {
            "name": $param-name,
            "in": "path",
            "required": true(),
            "schema": map { "type": "string" },
            "description": "The " || $param-name || " identifier"
        },
        for $query-param in $query-params
        let $param-name := $query-param/@name/string()
        return map {
            "name": $param-name,
            "in": "query",
            "required": false(),
            "schema": map { "type": "string" },
            "description": "Query parameter " || $param-name
        }
    )
    
    return map:entry(
        $normalized-path,
        map {
            $method: map:merge((
                map { "summary": "RESTXQ endpoint: " || $func-name },
                if (exists($parameters)) then map { "parameters": array { $parameters } } else (),
                if (exists($consumes)) then map { 
                    "requestBody": map {
                        "content": map {
                            $consumes: map {
                                "schema": map { "type": "object" }
                            }
                        }
                    }
                } else (),
                map {
                    "responses": map {
                        "200": map {
                            "description": "Successful response",
                            "content": map {
                                ($produces, "application/json")[1]: map {
                                    "schema": map { "type": "object" }
                                }
                            }
                        },
                        "404": map {
                            "description": "Resource not found"
                        },
                        "500": map {
                            "description": "Internal server error"
                        }
                    }
                },
                map {
                    "tags": array { openapi:get-tag-from-path($path) }
                }
            ))
        }
    )
};



(:~
 : Get tag name from path for grouping endpoints
 :)
declare function openapi:get-tag-from-path($path as xs:string) as xs:string {
    if (starts-with($path, "/iiif/")) then "IIIF"
    else if (starts-with($path, "/document/")) then "Digital Edition"
    else if (starts-with($path, "/data.json")) then "Digital Edition"
    else if (starts-with($path, "/module2/")) then "Analysis"
    else if (starts-with($path, "/module3/")) then "Sketch Analysis"
    else if (starts-with($path, "/module4/")) then "Engraving Comparison"
    else if (starts-with($path, "/source/")) then "EMA"
    else if (starts-with($path, "/file/") or starts-with($path, "/element/")) then "File Services"
    else if (contains($path, "/context.json")) then "Context"
    else "Other"
};

(:~
 : Generate common schema definitions
 :)
declare function openapi:generate-schemas() as map(*) {
    map {
        "Document": map {
            "type": "object",
            "properties": map {
                "id": map { "type": "string" },
                "title": map { "type": "string" },
                "manifest": map { "type": "string", "format": "uri" }
            }
        },
        "MEIFile": map {
            "type": "object",
            "properties": map {
                "id": map { "type": "string" },
                "title": map { "type": "string" },
                "work": map { "type": "string" },
                "version": map { "type": "string" }
            }
        },
        "Annotation": map {
            "type": "object",
            "properties": map {
                "id": map { "type": "string" },
                "type": map { "type": "string" },
                "target": map { "type": "string" },
                "body": map { "type": "string" }
            }
        },
        "Error": map {
            "type": "object",
            "properties": map {
                "code": map { "type": "integer" },
                "message": map { "type": "string" }
            }
        }
    }
};

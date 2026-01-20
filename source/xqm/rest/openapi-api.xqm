xquery version "3.1";

(:~
 : OpenAPI REST Endpoint Module
 : 
 : Provides OpenAPI 3.0 specification and Swagger UI endpoints.
 : The OpenAPI spec is auto-generated from RESTXQ annotations.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace openapi-api = "https://api.beethovens-werkstatt.de/rest/openapi";

import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace openapi = "https://api.beethovens-werkstatt.de/openapi" at "../openapi.xqm";
import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Get OpenAPI 3.0 specification
 :
 : Returns the complete OpenAPI specification for the API.
 : This is auto-generated from RESTXQ annotations.
 :
 : @return OpenAPI 3.0 specification as JSON
 :
 : @openapi:exclude true
 :)
declare
    %rest:GET
    %rest:path("/openapi.json")
    %rest:produces("application/json")
    %output:method("json")
function openapi-api:get-spec() {
    api-base:json-response(openapi:generate-spec())
};

(:~
 : Swagger UI - Interactive API Documentation
 :
 : Serves an HTML page with Swagger UI for interactive API exploration.
 :
 : @return HTML page with embedded Swagger UI
 :
 : @openapi:exclude true
 :)
declare
    %rest:GET
    %rest:path("/docs")
    %rest:produces("text/html")
    %output:method("html5")
function openapi-api:swagger-ui() {
    <html>
        <head>
            <title>Beethovens Werkstatt API - Documentation</title>
            <meta charset="UTF-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1"/>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css"/>
            <style>
                body {{
                    margin: 0;
                    padding: 0;
                }}
                .swagger-ui .topbar {{
                    background-color: #1e1e1e;
                }}
                .swagger-ui .info .title {{
                    color: #333;
                }}
            </style>
        </head>
        <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"></script>
            <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js"></script>
            <script>
                window.onload = function() {{
                    window.ui = SwaggerUIBundle({{
                        url: "openapi.json",
                        dom_id: '#swagger-ui',
                        deepLinking: true,
                        presets: [
                            SwaggerUIBundle.presets.apis,
                            SwaggerUIStandalonePreset
                        ],
                        plugins: [
                            SwaggerUIBundle.plugins.DownloadUrl
                        ],
                        layout: "StandaloneLayout",
                        validatorUrl: null
                    }});
                }};
            </script>
        </body>
    </html>
};

(:~
 : API Health Check endpoint
 :
 : Returns basic health information about the API.
 :
 : @return Health status JSON
 :)
declare
    %rest:GET
    %rest:path("/api/health")
    %rest:produces("application/json")
    %output:method("json")
function openapi-api:health() {
    api-base:json-response(map {
        "status": "ok",
        "version": $config:app-version,
        "environment": $config:environment,
        "timestamp": format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z")
    })
};

(:~
 : API Info endpoint
 :
 : Returns metadata about the API.
 :
 : @return API info JSON
 :)
declare
    %rest:GET
    %rest:path("/api/info")
    %rest:produces("application/json")
    %output:method("json")
function openapi-api:info() {
    api-base:json-response(map {
        "name": "Beethovens Werkstatt API",
        "version": $config:app-version,
        "description": "API for accessing MEI-encoded music data, genetic editions, IIIF manifests, and comparative analysis",
        "documentation": $config:public-base-uri || "/api/docs",
        "openapi": $config:public-base-uri || "/api/openapi.json",
        "contact": map {
            "name": "Beethovens Werkstatt",
            "url": "https://beethovens-werkstatt.de"
        },
        "endpoints": map {
            "iiif": $config:public-base-uri || "/api/iiif",
            "module1": $config:public-base-uri || "/api/module1",
            "module3": $config:public-base-uri || "/api/module3",
            "documents": $config:public-base-uri || "/api/documents"
        }
    })
};

# REST API Modules

This directory contains RESTXQ modules that define all API endpoints using declarative REST annotations.

## Structure

```
rest/
├── api-base.xqm        # Base module with CORS helpers and response formatters
├── iiif-api.xqm        # IIIF Presentation API (5 endpoints)
├── module1-api.xqm     # Digital Edition (17 endpoints)
├── module2-api.xqm     # Analysis (13 endpoints)
├── module3-api.xqm     # Sketch Analysis (3 endpoints)
├── module4-api.xqm     # Engraving Comparison (2 endpoints)
└── services-api.xqm    # Context, EMA, File services (4 endpoints)
```

**Total:** 44 endpoints across 6 modules

## How RESTXQ Works

RESTXQ uses annotations to declaratively define REST endpoints:

```xquery
declare
    %rest:GET
    %rest:path("/document/{$documentId}/file.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-file($documentId as xs:string) {
    (: Implementation :)
};
```

The eXist-DB RESTXQ dispatcher automatically:
1. Scans modules for REST annotations
2. Builds routing table from `%rest:path()` declarations
3. Matches incoming requests to functions
4. Extracts path parameters (e.g., `{$documentId}`)
5. Returns responses with appropriate content-type

## Adding New Endpoints

### 1. Choose the Appropriate Module

Add endpoints to the module that matches their domain:
- **iiif-api.xqm** - IIIF/manifest-related endpoints
- **module1-api.xqm** - Digital edition features
- **module2-api.xqm** - Analysis features
- **module3-api.xqm** - Sketch analysis
- **module4-api.xqm** - Engraving comparison
- **services-api.xqm** - General services (context, files, etc.)

### 2. Define the Function

```xquery
(:~
 : Clear description of what this endpoint does
 :
 : @param $paramName Description of parameter
 : @return Description of return value
 :)
declare
    %rest:GET                                    (: HTTP method :)
    %rest:path("/your/path/{$paramName}")       (: URL pattern :)
    %rest:produces("application/json")          (: Content-Type :)
    %output:method("json")                      (: Serialization :)
function your-module:your-function($paramName as xs:string) {
    (: Implementation :)
};
```

### 3. Implementation Options

**Option A: Inline implementation**
```xquery
function module1-api:get-data($id as xs:string) {
    let $doc := collection($config:data-root)//mei:mei[@xml:id = $id]
    return api-base:json-response(map { "data": $doc })
}
```

**Option B: Delegate to existing XQL**
```xquery
function module1-api:get-data($id as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get-data.xql"),
        false(),
        (xs:QName("id"), $id)
    )
}
```

### 4. Update Controller (if needed)

If adding a new path pattern, ensure the controller forwards it to RESTXQ.

The controller in `source/eXist-db/controller.xql` already forwards most patterns, but check if your new path needs to be added.

## REST Annotations Reference

### HTTP Methods
```xquery
%rest:GET       (: Read operations :)
%rest:POST      (: Create operations :)
%rest:PUT       (: Update operations :)
%rest:DELETE    (: Delete operations :)
```

### Path Patterns
```xquery
%rest:path("/static/path")              (: Exact match :)
%rest:path("/path/{$param}")            (: Path parameter :)
%rest:path("/path/{$param}/sub")        (: Multiple segments :)
%rest:path("/path/{$param1}/{$param2}") (: Multiple parameters :)
```

### Content Types
```xquery
%rest:produces("application/json")     (: JSON response :)
%rest:produces("application/xml")      (: XML response :)
%rest:produces("text/html")            (: HTML response :)
%rest:produces("image/svg+xml")        (: SVG response :)
```

### Query Parameters
```xquery
%rest:query-param("name", "{$var}")    (: Optional query param :)
%rest:query-param("name", "{$var}", "default")  (: With default :)
```

### Output Serialization
```xquery
%output:method("json")     (: Serialize as JSON :)
%output:method("xml")      (: Serialize as XML :)
%output:method("html")     (: Serialize as HTML :)
%output:method("text")     (: Plain text :)
```

## Helper Functions (api-base.xqm)

The base module provides common utilities:

```xquery
(: Add CORS headers :)
api-base:cors-headers()

(: Return JSON response with CORS :)
api-base:json-response($data)

(: Return XML response with CORS :)
api-base:xml-response($xml)

(: Return error response :)
api-base:error-response($code, $message)
```

## Endpoint Categories

Endpoints are organized into these categories for OpenAPI documentation:

| Path Pattern | Category | Tag |
|--------------|----------|-----|
| `/iiif/*` | IIIF Presentation API | IIIF |
| `/document/*`, `/data.json` | Digital Edition | Digital Edition |
| `/module2/*` | Analysis | Analysis |
| `/module3/*` | Sketch Analysis | Sketch Analysis |
| `/module4/*` | Engraving Comparison | Engraving Comparison |
| `/source/*` | EMA | EMA |
| `/file/*`, `/element/*` | File Services | File Services |
| `/{version}/context.json` | JSON-LD Context | Context |

## OpenAPI Integration

All RESTXQ endpoints are automatically documented via OpenAPI introspection.

The XQDoc comment (first line) becomes the endpoint summary in the OpenAPI spec:

```xquery
(:~
 : Get full MEI file    ← This becomes the OpenAPI summary
 : 
 : Additional details here are currently not used but could be
 : integrated for extended descriptions.
 :)
```

**View documentation:**
- Interactive UI: http://localhost:8080/exist/apps/api/docs
- OpenAPI spec: http://localhost:8080/exist/apps/api/openapi.json

See `OPENAPI.md` for details on the documentation system.

## Testing Endpoints

### During Development

Use the watch mode to auto-deploy changes:
```bash
npm run watch
```

### Manual Testing

```bash
# Test endpoint
curl http://localhost:8080/exist/apps/api/your/endpoint

# Test with parameters
curl http://localhost:8080/exist/apps/api/document/doc123/file.xml

# Test with query params
curl "http://localhost:8080/exist/apps/api/module2/getAnalysis.xql?analysis=abc"
```

### Using Swagger UI

1. Open http://localhost:8080/exist/apps/api/docs
2. Find your endpoint
3. Click "Try it out"
4. Fill in parameters
5. Click "Execute"

## Best Practices

### 1. Use Descriptive Function Names
```xquery
(: Good :)
function module1-api:get-genetic-states($documentId) { ... }

(: Less clear :)
function module1-api:get-gs($id) { ... }
```

### 2. Add XQDoc Comments
```xquery
(:~
 : Brief description of what this does
 : 
 : @param $documentId The document identifier
 : @return JSON array of genetic states
 :)
```

### 3. Use Type Declarations
```xquery
(: Good :)
function module1-api:get-data($id as xs:string) as map(*) { ... }

(: Acceptable (type inference) :)
function module1-api:get-data($id as xs:string) { ... }
```

### 4. Handle Errors Gracefully
```xquery
function module1-api:get-file($documentId as xs:string) {
    let $doc := collection($config:data-root)//mei:mei[@xml:id = $documentId]
    return
        if (exists($doc)) then
            $doc
        else
            api-base:error-response(404, "Document not found: " || $documentId)
}
```

### 5. Keep Functions Focused
Each function should do one thing. If delegating to existing XQL files, keep the RESTXQ function simple:

```xquery
function module1-api:get-data($id as xs:string) {
    util:eval(xs:anyURI("../xql/module1/get-data.xql"), false(), (xs:QName("id"), $id))
}
```

## Common Patterns

### Path with Multiple Parameters
```xquery
declare
    %rest:GET
    %rest:path("/document/{$docId}/element/{$elemId}/description.json")
function module1-api:get-element-description($docId as xs:string, $elemId as xs:string) {
    (: Implementation :)
}
```

### Optional Query Parameters
```xquery
declare
    %rest:GET
    %rest:path("/module2/getAnalysis.xql")
    %rest:query-param("analysis", "{$analysisId}")
function module2-api:get-analysis($analysisId as xs:string*) {
    (: $analysisId can be empty sequence :)
}
```

### Multiple Content Types
```xquery
(: Separate functions for different formats :)
declare
    %rest:GET
    %rest:path("/document/{$id}/manifest.json")
    %rest:path("/document/{$id}/manifest")
function iiif-api:get-manifest($id as xs:string) { ... }
```

## Troubleshooting

### Endpoint returns 404

**Check:**
1. Function has `%rest:path()` annotation
2. Path pattern matches your URL exactly
3. Module is in `/db/apps/api/resources/xqm/rest/`
4. No XQuery syntax errors (check eXist-DB logs)
5. Restart eXist-DB to reload RESTXQ annotations

### Parameters not extracted

**Ensure:**
1. Path uses `{$paramName}` syntax
2. Function parameter matches: `$paramName as xs:string`
3. Parameter names are identical (case-sensitive)

### CORS errors

**Add CORS headers:**
```xquery
response:set-header("Access-Control-Allow-Origin", "*")
```

Or use the helper:
```xquery
api-base:cors-headers()
```

### Wrong content-type

**Add annotations:**
```xquery
%rest:produces("application/json")
%output:method("json")
```

## Further Reading

- **Top-level README.md** - Project setup and commands
- **OPENAPI.md** - OpenAPI documentation system details
- [eXist-DB RESTXQ Documentation](https://exist-db.org/exist/apps/doc/restxq)
- [OpenAPI 3.0 Specification](https://swagger.io/specification/)

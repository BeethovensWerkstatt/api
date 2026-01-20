xquery version "3.0";

(:~
 : URL Rewriting Controller
 : 
 : This controller handles URL routing for the Beethovens Werkstatt API.
 : All module routes are forwarded to RESTXQ.
 : 
 : Routing Strategy:
 : - /api/* routes → RESTXQ servlet (for new prefixed endpoints)
 : - /iiif/*, /module[1-4]/*, /file/*, /desc/*, /documents/*, /docs, /openapi.json 
 :   → RESTXQ via /restxq path forwarding
 : - Static resources are served directly
 :
 : @author Beethovens Werkstatt
 : @version 3.0.0
 :)

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: ============================================================
   RESTXQ API ROUTES
   All API endpoints use RESTXQ for cleaner, annotated routing
   ============================================================ :)

(: Forward /api/* requests to RESTXQ servlet :)
if (starts-with($exist:path, '/api/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward servlet="RestXqServlet"/>
    </dispatch>

) else

(: Handle CORS preflight requests :)
if (request:get-method() = 'OPTIONS') then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    response:set-header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"),
    response:set-header("Access-Control-Allow-Headers", "Content-Type, Authorization"),
    response:set-header("Access-Control-Max-Age", "86400"),
    response:set-status-code(204),
    <empty/>

) else

(: ============================================================
   LEGACY ROUTE (kept for backwards compatibility)
   ============================================================ :)

(: JSON-LD context definitions :)
if(matches($exist:path,'/\d/context.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/context.xql">
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else

(: ============================================================
   RESTXQ ROUTES - Forwarded to RestXqServlet
   These routes are handled by RESTXQ modules in xqm/rest/
   ============================================================ :)

(: OpenAPI Documentation - via RESTXQ :)
if($exist:path = '/docs') then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq/docs" absolute="yes"/>
    </dispatch>

) else if($exist:path = '/openapi.json') then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq/openapi.json" absolute="yes"/>
    </dispatch>

) else

(: IIIF Routes - iiif-api.xqm :)
if(starts-with($exist:path, '/iiif/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: Module 1 Routes - module1-api.xqm :)
if(starts-with(lower-case($exist:path), '/module1/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: Module 2 Routes - module2-api.xqm :)
if(starts-with(lower-case($exist:path), '/module2/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: Module 3 Routes - module3-api.xqm :)
if(starts-with(lower-case($exist:path), '/module3/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: Module 4 Routes - module4-api.xqm :)
if(starts-with(lower-case($exist:path), '/module4/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: File Routes - file-api.xqm :)
if(starts-with(lower-case($exist:path), '/file/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: Description Routes - tools-api.xqm :)
if(starts-with(lower-case($exist:path), '/desc/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: Documents Routes - tools-api.xqm :)
if(starts-with(lower-case($exist:path), '/documents/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>

) else

(: ============================================================
   STATIC FILES AND FALLBACK
   ============================================================ :)

(: Serve index.html :)
if ($exist:path eq "/index.html") then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>

) else (
    (: All other requests redirect to index.html :)
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
)

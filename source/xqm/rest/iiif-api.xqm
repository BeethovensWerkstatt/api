xquery version "3.1";

(:~
 : IIIF REST API Module
 : 
 : Provides IIIF Presentation API 2.1 endpoints via RESTXQ.
 : All endpoints return JSON-LD compatible responses.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace iiif-api = "https://api.beethovens-werkstatt.de/rest/iiif";

import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace iiif = "https://edirom.de/iiif" at "../iiif.xqm";
import module namespace ef = "https://edirom.de/file" at "../file.xqm";
import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";
import module namespace bwerr = "https://api.beethovens-werkstatt.de/util/error" at "../util/error.xqm";
import module namespace validate = "https://api.beethovens-werkstatt.de/util/validation" at "../util/validation.xqm";
import module namespace log = "https://api.beethovens-werkstatt.de/util/logging" at "../util/logging.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

(:~
 : @openapi:tag IIIF
 : @openapi:description IIIF Presentation API 2.1 endpoints for accessing document facsimiles
 :)

(:~
 : List all documents with IIIF manifests
 :
 : Returns a list of all documents that have associated facsimile data
 : and can be accessed via IIIF.
 :
 : @return JSON array of documents with manifest links
 :
 : @openapi:summary List all IIIF documents
 : @openapi:response 200 application/json Array of document objects
 :)
declare
    %rest:GET
    %rest:path("/exist/apps/api/iiif/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:list-documents() {
    iiif-api:list-documents-impl()
};

(:~ Debug route - same endpoint with different path :)
declare
    %rest:GET
    %rest:path("/apps/api/iiif/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:list-documents-alt() {
    iiif-api:list-documents-impl()
};

(:~ Debug route - simple path :)
declare
    %rest:GET
    %rest:path("/iiif/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:list-documents-simple() {
    iiif-api:list-documents-impl()
};

(:~ Implementation :)
declare function iiif-api:list-documents-impl() {
    let $_ := log:info("IIIF API: list-documents")
    
    let $database := collection($config:data-root)
    let $files :=
        for $facsimile in $database//mei:mei[@xml:id][.//mei:facsimile[@xml:id and .//mei:graphic]]//mei:facsimile
        let $id := $facsimile/string(@xml:id)
        let $file.id := $facsimile/ancestor::mei:mei/string(@xml:id)
        let $manifest := $config:iiif-basepath || 'document/' || $id || '/manifest.json'
        let $pages := count($facsimile//mei:surface[mei:graphic])
        order by $file.id
        return map {
            'id': $id,
            'manifest': $manifest,
            'pages': $pages,
            'file': ef:getFileLink($file.id)
        }
    return api-base:json-response(array { $files })
};

(:~
 : Get IIIF manifest for a document
 :
 : Returns a IIIF Presentation API 2.1 manifest for the specified document.
 :
 : @param $documentId The document/facsimile identifier
 : @return IIIF manifest JSON-LD
 :
 : @openapi:summary Get IIIF manifest
 : @openapi:param documentId path required The document identifier
 : @openapi:response 200 application/json IIIF Presentation API manifest
 : @openapi:response 404 application/json Document not found
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/manifest.json")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-manifest($documentId as xs:string) {
    iiif-api:get-manifest-impl($documentId)
};

(:~ Alternate path for /exist/apps/api prefix :)
declare
    %rest:GET
    %rest:path("/exist/apps/api/iiif/document/{$documentId}/manifest.json")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-manifest-full-path($documentId as xs:string) {
    iiif-api:get-manifest-impl($documentId)
};

declare function iiif-api:get-manifest-impl($documentId as xs:string) {
    let $_ := log:info("IIIF API: get-manifest", map { "documentId": $documentId })
    
    (: Validate input :)
    let $validation := validate:id-safe($documentId)
    
    return
        if (not($validation?valid)) then
            api-base:error-response(400, $validation?error)
        else
            (: Find the document :)
            let $facsimile := collection($config:data-root)//mei:facsimile[@xml:id = $documentId]
            
            return
                if (empty($facsimile)) then
                    api-base:not-found("Document: " || $documentId)
                else
                    let $mei := $facsimile/ancestor::mei:mei
                    let $manifest := iiif-api:build-manifest($facsimile, $mei)
                    return api-base:json-response($manifest)
};

(:~
 : Alternative manifest endpoint without .json extension
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/manifest")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-manifest-alt($documentId as xs:string) {
    iiif-api:get-manifest-impl($documentId)
};

(:~ Alternate path with /exist/apps/api prefix :)
declare
    %rest:GET
    %rest:path("/exist/apps/api/iiif/document/{$documentId}/manifest")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-manifest-alt-full-path($documentId as xs:string) {
    iiif-api:get-manifest-impl($documentId)
};

(:~
 : Get measure zones as IIIF annotation list
 :
 : @param $documentId The document identifier
 : @param $canvasId The canvas identifier (without _zones suffix)
 : @return IIIF annotation list with measure zones
 :
 : @openapi:summary Get measure zone annotations
 : @openapi:param documentId path required The document identifier
 : @openapi:param canvasId path required The canvas identifier
 : @openapi:response 200 application/json IIIF annotation list
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/list/{$canvasId}_zones")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-measure-zones($documentId as xs:string, $canvasId as xs:string) {
    iiif-api:get-measure-zones-impl($documentId, $canvasId)
};

(:~ Alternate path with /exist/apps/api prefix :)
declare
    %rest:GET
    %rest:path("/exist/apps/api/iiif/document/{$documentId}/list/{$canvasId}_zones")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-measure-zones-full-path($documentId as xs:string, $canvasId as xs:string) {
    iiif-api:get-measure-zones-impl($documentId, $canvasId)
};

declare function iiif-api:get-measure-zones-impl($documentId as xs:string, $canvasId as xs:string) {
    let $_ := log:info("IIIF API: get-measure-zones", map { "documentId": $documentId, "canvasId": $canvasId })
    
    let $facsimile := collection($config:data-root)//mei:facsimile[@xml:id = $documentId]
    let $surface := $facsimile//mei:surface[@xml:id = $canvasId]
    
    return
        if (empty($surface)) then
            api-base:not-found("Canvas: " || $canvasId)
        else
            let $zones := $surface//mei:zone[@data]
            let $mei := $facsimile/ancestor::mei:mei
            let $annotations := iiif:getRectangle($mei, $zones, false())
            
            return api-base:json-response(map {
                "@context": "http://iiif.io/api/presentation/2/context.json",
                "@id": $config:iiif-basepath || "document/" || $documentId || "/list/" || $canvasId || "_zones",
                "@type": "sc:AnnotationList",
                "resources": array { $annotations }
            })
};

(:~
 : Get SVG overlays for a canvas
 :
 : @param $documentId The document identifier
 : @param $svgFileName The SVG filename
 : @return SVG file with measure overlays
 :
 : @openapi:summary Get SVG overlay for canvas
 : @openapi:response 200 image/svg+xml SVG overlay
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/overlays/{$svgFileName}")
    %rest:produces("image/svg+xml")
function iiif-api:get-svg-overlays($documentId as xs:string, $svgFileName as xs:string) {
    iiif-api:get-svg-overlays-impl($documentId, $svgFileName)
};

(:~ Alternate path with /exist/apps/api prefix :)
declare
    %rest:GET
    %rest:path("/exist/apps/api/iiif/document/{$documentId}/overlays/{$svgFileName}")
    %rest:produces("image/svg+xml")
function iiif-api:get-svg-overlays-full-path($documentId as xs:string, $svgFileName as xs:string) {
    iiif-api:get-svg-overlays-impl($documentId, $svgFileName)
};

declare function iiif-api:get-svg-overlays-impl($documentId as xs:string, $svgFileName as xs:string) {
    let $_ := log:info("IIIF API: get-svg-overlays", map { "documentId": $documentId, "svgFileName": $svgFileName })
    
    let $facsimile := collection($config:data-root)//mei:facsimile[@xml:id = $documentId]
    let $svg := $facsimile//mei:graphic[ends-with(@target, $svgFileName)]
    
    return
        if (empty($svg)) then
            api-base:error-response(404, "SVG not found: " || $svgFileName)
        else
            let $svg-doc := doc($svg/@target)
            return api-base:xml-response($svg-doc)
};

(:~
 : Get SVG overlays with enhanced data attributes
 :
 : Returns SVG with additional data attributes for monita identification.
 :
 : @param $documentId The document identifier
 : @param $svgFileName The SVG filename
 : @return SVG file with enhanced data attributes
 :
 : @openapi:summary Get enhanced SVG overlay for canvas
 : @openapi:response 200 image/svg+xml SVG overlay with data attributes
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/overlaysPlus/{$svgFileName}")
    %rest:produces("image/svg+xml")
function iiif-api:get-svg-overlays-plus($documentId as xs:string, $svgFileName as xs:string) {
    iiif-api:get-svg-overlays-plus-impl($documentId, $svgFileName)
};

(:~ Alternate path with /exist/apps/api prefix :)
declare
    %rest:GET
    %rest:path("/exist/apps/api/iiif/document/{$documentId}/overlaysPlus/{$svgFileName}")
    %rest:produces("image/svg+xml")
function iiif-api:get-svg-overlays-plus-full-path($documentId as xs:string, $svgFileName as xs:string) {
    iiif-api:get-svg-overlays-plus-impl($documentId, $svgFileName)
};

declare function iiif-api:get-svg-overlays-plus-impl($documentId as xs:string, $svgFileName as xs:string) {
    (: TODO: Migrate logic from get-svg-file-with-data-atts.xql :)
    let $_ := log:info("IIIF API: get-svg-overlays-plus", map { "documentId": $documentId, "svgFileName": $svgFileName })
    
    (: For now, forward to the XQL script logic - will be refactored :)
    let $facsimile := collection($config:data-root)//mei:facsimile[@xml:id = $documentId]
    let $svg := $facsimile//mei:graphic[ends-with(@target, $svgFileName)]
    
    return
        if (empty($svg)) then
            api-base:error-response(404, "SVG not found: " || $svgFileName)
        else
            let $svg-doc := doc($svg/@target)
            return api-base:xml-response($svg-doc)
};

(: ========== Private Helper Functions ========== :)

(:~
 : Build a IIIF manifest for a facsimile
 :)
declare %private function iiif-api:build-manifest(
    $facsimile as element(mei:facsimile),
    $mei as element(mei:mei)
) as map(*) {
    let $id := $facsimile/string(@xml:id)
    let $manifest-uri := $config:iiif-basepath || "document/" || $id || "/manifest.json"
    
    let $title := ($mei//mei:title[@type='main']/string(), $mei//mei:title[1]/string(), "Untitled")[1]
    let $composer := ($mei//mei:composer/string(), "Unknown")[1]
    
    let $canvases := 
        for $surface at $pos in $facsimile//mei:surface[mei:graphic]
        let $canvas-id := $surface/string(@xml:id)
        let $graphic := $surface/mei:graphic[@target][1]
        let $width := ($surface/@lrx - $surface/@ulx, 1000)[1]
        let $height := ($surface/@lry - $surface/@uly, 1000)[1]
        return map {
            "@id": $config:iiif-basepath || "document/" || $id || "/canvas/" || $canvas-id,
            "@type": "sc:Canvas",
            "label": "Page " || $pos,
            "width": xs:integer($width),
            "height": xs:integer($height),
            "images": array {
                map {
                    "@id": $config:iiif-basepath || "document/" || $id || "/annotation/" || $canvas-id,
                    "@type": "oa:Annotation",
                    "motivation": "sc:painting",
                    "on": $config:iiif-basepath || "document/" || $id || "/canvas/" || $canvas-id,
                    "resource": map {
                        "@id": $graphic/string(@target) || "/full/full/0/default.jpg",
                        "@type": "dctypes:Image",
                        "format": "image/jpeg",
                        "service": map {
                            "@context": "http://iiif.io/api/image/2/context.json",
                            "@id": $graphic/string(@target),
                            "profile": "http://iiif.io/api/image/2/level2.json"
                        }
                    }
                }
            },
            "otherContent": array {
                map {
                    "@id": $config:iiif-basepath || "document/" || $id || "/list/" || $canvas-id || "_zones",
                    "@type": "sc:AnnotationList",
                    "label": "Measure zones"
                }
            }
        }
    
    return map {
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": $manifest-uri,
        "@type": "sc:Manifest",
        "label": $title,
        "metadata": array {
            map { "label": "Composer", "value": $composer },
            map { "label": "Source", "value": "Beethovens Werkstatt" }
        },
        "attribution": "Beethovens Werkstatt",
        "license": "https://creativecommons.org/licenses/by-nc-sa/4.0/",
        "sequences": array {
            map {
                "@id": $manifest-uri || "#sequence",
                "@type": "sc:Sequence",
                "label": "Default sequence",
                "canvases": array { $canvases }
            }
        }
    }
};

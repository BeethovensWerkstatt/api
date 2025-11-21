xquery version "3.1";

(:~
 : IIIF REST API Module
 : 
 : Provides IIIF Presentation API endpoints with REST annotations
 :)

module namespace iiif-api = "https://api.beethovens-werkstatt.de/rest/iiif";

import module namespace config="https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace ef="https://edirom.de/file" at "../file.xqm";
import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

(:~
 : List all documents with IIIF manifests
 :
 : @return JSON array of documents with manifest links
 :)
declare
    %rest:GET
    %rest:path("/iiif/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:list-documents() {
    let $database := collection($config:data-root)
    let $files :=
        for $facsimile in $database//mei:mei[@xml:id][.//mei:facsimile[@xml:id and .//mei:graphic]]//mei:facsimile
        let $id := $facsimile/string(@xml:id)
        let $file.id := $facsimile/ancestor::mei:mei/string(@xml:id)
        let $manifest := $config:iiif-basepath || 'document/' || $id || '/manifest.json'
        let $pages := count($facsimile//mei:surface[mei:graphic])
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
 : @param $documentId The document identifier
 : @return IIIF Presentation API manifest
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/manifest.json")
    %rest:path("/iiif/document/{$documentId}/manifest")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-manifest($documentId as xs:string) {
    (: Delegate to existing XQuery logic :)
    let $result := util:eval(xs:anyURI("../xql/iiif/get-manifest.json.xql"), false(), (xs:QName("documentId"), $documentId))
    return api-base:json-response($result)
};

(:~
 : Get measure zones as IIIF annotation list
 :
 : @param $documentId The document identifier
 : @param $canvasId The canvas identifier
 : @return IIIF annotation list with measure zones
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/list/{$canvasId}_zones")
    %rest:produces("application/json")
    %output:method("json")
function iiif-api:get-measure-zones($documentId as xs:string, $canvasId as xs:string) {
    (: Delegate to existing XQuery :)
    let $result := util:eval(
        xs:anyURI("../xql/iiif/get-measure-positions-on-page.xql"), 
        false(), 
        (xs:QName("documentId"), $documentId, xs:QName("canvasId"), $canvasId)
    )
    return api-base:json-response($result)
};

(:~
 : Get SVG overlays for a page
 :
 : @param $documentId The document identifier
 : @param $svgFileName The SVG filename
 : @return SVG file with measure overlays
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/overlays/{$svgFileName}")
    %rest:produces("image/svg+xml")
function iiif-api:get-svg-overlays($documentId as xs:string, $svgFileName as xs:string) {
    (: Delegate to existing XQuery :)
    let $result := util:eval(
        xs:anyURI("../xql/file/get-svg-file.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("svgFileName"), $svgFileName)
    )
    return api-base:xml-response($result)
};

(:~
 : Get enriched SVG overlays with data attributes
 :
 : @param $documentId The document identifier  
 : @param $svgFileName The SVG filename
 : @return SVG file with measure overlays and data attributes
 :)
declare
    %rest:GET
    %rest:path("/iiif/document/{$documentId}/overlaysPlus/{$svgFileName}")
    %rest:produces("image/svg+xml")
function iiif-api:get-svg-overlays-plus($documentId as xs:string, $svgFileName as xs:string) {
    (: Delegate to existing XQuery :)
    let $result := util:eval(
        xs:anyURI("../xql/svg/get-svg-file-with-data-atts.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("svgFileName"), $svgFileName)
    )
    return api-base:xml-response($result)
};

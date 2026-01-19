xquery version "3.1";

(:~
 : File REST API
 : 
 : Provides RESTXQ endpoints for accessing raw MEI file data
 : and specific elements within files.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace file-api = "https://api.beethovens-werkstatt.de/rest/file";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : @openapi:tag Files
 : @openapi:description Access to raw MEI files and elements
 :)

(: ============================================================
   FILE ENDPOINTS
   ============================================================ :)

(:~
 : Get complete MEI file as XML
 :
 : @param $documentId The document identifier
 : @return Complete MEI XML document
 :
 : @openapi:summary Get MEI file as XML
 : @openapi:response 200 application/xml Complete MEI document
 :)
declare
    %rest:GET
    %rest:path("/file/{$documentId}.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function file-api:get-file($documentId as xs:string) {
    api-base:forward-to-xql("/resources/xql/file/get-file.xql", map {
        "document.id": $documentId
    })
};

(:~
 : Get specific element from MEI file
 :
 : @param $documentId The document identifier
 : @param $elementId The element identifier
 : @return MEI XML element
 :)
declare
    %rest:GET
    %rest:path("/file/{$documentId}/element/{$elementId}")
    %rest:produces("application/xml")
    %output:method("xml")
function file-api:get-element($documentId as xs:string, $elementId as xs:string) {
    api-base:forward-to-xql("/resources/xql/file/get-element.xql", map {
        "document.id": $documentId,
        "element.id": $elementId
    })
};

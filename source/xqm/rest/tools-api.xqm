xquery version "3.1";

(:~
 : Tools REST API
 : 
 : Provides RESTXQ endpoints for utility functions like
 : element descriptions and document retrieval.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace tools-api = "https://api.beethovens-werkstatt.de/rest/tools";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : @openapi:tag Tools
 : @openapi:description Utility endpoints for element descriptions and document access
 :)

(: ============================================================
   DESCRIPTION ENDPOINTS
   ============================================================ :)

(:~
 : Get description of an MEI element
 :
 : @param $elementId The element identifier
 : @return JSON object with element description
 :
 : @openapi:summary Get element description
 : @openapi:response 200 application/json Element description object
 :)
declare
    %rest:GET
    %rest:path("/desc/{$elementId}.json")
    %rest:produces("application/json")
    %output:method("json")
function tools-api:get-description($elementId as xs:string) {
    api-base:forward-to-xql("/resources/xql/tools/get_element_description_as_JSON.xql", map {
        "element.id": $elementId,
        "lang": "de"
    })
};

(: ============================================================
   DOCUMENTS ENDPOINTS
   ============================================================ :)

(:~
 : Get document details (Module 4 onwards)
 :
 : @param $documentId The document identifier
 : @return JSON document object
 :)
declare
    %rest:GET
    %rest:path("/documents/{$documentId}.json")
    %rest:produces("application/json")
    %output:method("json")
function tools-api:get-document($documentId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module4/get-document.xql", map {
        "document.id": $documentId
    })
};

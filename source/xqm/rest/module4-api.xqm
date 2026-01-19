xquery version "3.1";

(:~
 : Module 4 REST API - Documents
 : 
 : Provides RESTXQ endpoints for accessing Module 4 documents
 : (revision analysis and genetic editing).
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace module4-api = "https://api.beethovens-werkstatt.de/rest/module4";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : @openapi:tag Module4
 : @openapi:description Revision analysis and genetic editing documents
 :)

(: ============================================================
   DOCUMENT LISTING
   ============================================================ :)

(:~
 : List all Module 4 documents
 :
 : @return JSON array of document objects
 :
 : @openapi:summary List all Module 4 documents
 : @openapi:response 200 application/json Array of document objects
 :)
declare
    %rest:GET
    %rest:path("/module4/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function module4-api:list-documents() {
    api-base:forward-to-xql("/resources/xql/module4/module4-get-documents.xql", map {})
};

(:~
 : Get specific document details
 :
 : @param $documentId The document identifier
 : @return JSON document object with details
 :)
declare
    %rest:GET
    %rest:path("/module4/{$documentId}.json")
    %rest:produces("application/json")
    %output:method("json")
function module4-api:get-document($documentId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module4/get-document.xql", map {
        "document.id": $documentId
    })
};

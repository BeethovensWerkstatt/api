xquery version "3.1";

(:~
 : Documents REST API - Documents
 : 
 : Provides RESTXQ endpoints for handling documents
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace documents-api = "https://api.beethovens-werkstatt.de/rest/documents";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";
import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace ef = "https://edirom.de/file" at "../file.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

(:~
 : @openapi:tag Documents
 : @openapi:description Endpoints dealing with Documents
 :)

(: ============================================================
   DOCUMENT LISTING
   ============================================================ :)

(:~
 : List all Documents
 :
 : @return JSON array of document objects
 :
 : @openapi:summary List all Documents
 : @openapi:response 200 application/json Array of document objects
 :)
declare
    %rest:GET
    %rest:path("/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function documents-api:list-documents() {
    api-base:forward-to-xql("/resources/xql/documents/get-documents-list.xql", map {})
};

(:~
 : Get specific document details
 :
 : @param $documentId The document identifier
 : @return JSON document object with details
 :)
 declare
    %rest:GET
    %rest:path("/document/{$documentId}/overview.json")
    %rest:produces("application/json")
    %output:method("json")
function documents-api:get-document($documentId as xs:string) {
    api-base:forward-to-xql("/resources/xql/documents/get-document-overview.xql", map { "documentId": $documentId })
};
xquery version "3.1";

(:~
 : Editions REST API - Documents
 : 
 : Provides RESTXQ endpoints for handling editions
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace editions-api = "https://api.beethovens-werkstatt.de/rest/editions";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";
import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace ef = "https://edirom.de/file" at "../file.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

(:~
 : @openapi:tag Editions
 : @openapi:description Endpoints dealing with Editions
 :)

(: ============================================================
   EDITIONS LISTING
   ============================================================ :)

(:~
 : List all Editions documents
 :
 : @return JSON array of document objects
 :
 : @openapi:summary List all Editions documents
 : @openapi:response 200 application/json Array of document objects
 :)
declare
    %rest:GET
    %rest:path("/editions.json")
    %rest:produces("application/json")
    %output:method("json")
function editions-api:list-documents() {
    api-base:forward-to-xql("/resources/xql/editions/get-editions-list.xql", map {})
};
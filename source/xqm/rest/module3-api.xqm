xquery version "3.1";

(:~
 : Module 3 REST API - Monita/Complaints
 : 
 : Provides RESTXQ endpoints for accessing works, manifestations, complaints,
 : and related data for the Monita (editorial criticism) interface.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace module3-api = "https://api.beethovens-werkstatt.de/rest/module3";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";

(:~
 : @openapi:tag Module3
 : @openapi:description Monita - Editorial criticism and complaint documentation
 :)

(: ============================================================
   WORKS LISTING
   ============================================================ :)

(:~
 : List all works
 :
 : @return JSON array of work objects
 :
 : @openapi:summary List all works
 : @openapi:response 200 application/json Array of work objects
 :)
declare
    %rest:GET
    %rest:path("/module3/works.json")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:list-works() {
    api-base:forward-to-xql("/resources/xql/module3/module3-get-works.xql", map {})
};

(:~
 : Get specific work details
 :
 : @param $documentId The document/work identifier
 : @return JSON work object with details
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}.json")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:get-work($documentId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-work.xql", map {
        "document.id": $documentId
    })
};

(: ============================================================
   MANIFESTATION ENDPOINTS
   ============================================================ :)

(:~
 : Get manifestation/source details
 :
 : @param $documentId The document identifier
 : @param $manifestationId The manifestation identifier
 : @return JSON manifestation object
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/manifestation/{$manifestationId}.json")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:get-manifestation($documentId as xs:string, $manifestationId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-manifestation.xql", map {
        "document.id": $documentId,
        "manifestation.id": $manifestationId
    })
};

(:~
 : Get measures in a manifestation
 :
 : @param $documentId The document identifier
 : @param $manifestationId The manifestation identifier
 : @return JSON array of measures
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/manifestation/{$manifestationId}/measures.json")
    %rest:query-param("scope", "{$scope}", "")
    %rest:query-param("mdivId", "{$mdivId}", "")
    %rest:query-param("part", "{$part}", "")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:get-measures($documentId as xs:string, $manifestationId as xs:string, $scope as xs:string, $mdivId as xs:string, $part as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-measures-in-mdiv.xql", map {
        "document.id": $documentId,
        "manifestation.id": $manifestationId,
        "scope": $scope,
        "mdiv.id": $mdivId,
        "part.n": $part
    })
};

(: ============================================================
   MDIV ENDPOINTS
   ============================================================ :)

(:~
 : Get mdiv (musical division) details
 :
 : @param $documentId The document identifier
 : @param $mdivId The mdiv identifier
 : @return JSON mdiv object
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/mdiv/{$mdivId}.json")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:get-mdiv($documentId as xs:string, $mdivId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-mdiv.xql", map {
        "document.id": $documentId,
        "mdiv.id": $mdivId
    })
};

(: ============================================================
   MEASURE ENDPOINTS
   ============================================================ :)

(:~
 : Get measure details
 :
 : @param $documentId The document identifier
 : @param $measureId The measure identifier
 : @return JSON measure object
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/measure/{$measureId}.json")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:get-measure($documentId as xs:string, $measureId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-measure.xql", map {
        "document.id": $documentId,
        "measure.id": $measureId
    })
};

(: ============================================================
   COMPLAINT ENDPOINTS
   ============================================================ :)

(:~
 : Get specific complaint details
 :
 : @param $documentId The document identifier
 : @param $complaintId The complaint identifier
 : @return JSON complaint object
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/complaints/{$complaintId}.json")
    %rest:produces("application/json")
    %output:method("json")
function module3-api:get-complaint($documentId as xs:string, $complaintId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-complaint.xql", map {
        "document.id": $documentId,
        "complaint.id": $complaintId
    })
};

(: ============================================================
   SNIPPET ENDPOINTS
   ============================================================ :)

(:~
 : Get MEI snippet for complaint text
 :
 : @param $documentId The document identifier
 : @param $contextId The context/annotation identifier
 : @return MEI XML snippet
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/snippet/{$contextId}.mei")
    %rest:query-param("source", "{$source}", "")
    %rest:query-param("state", "{$state}", "")
    %rest:query-param("focus", "{$focus}", "")
    %rest:produces("application/xml")
    %output:method("xml")
function module3-api:get-mei-snippet($documentId as xs:string, $contextId as xs:string, $source as xs:string, $state as xs:string, $focus as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-complaint-text-by-annot.xql", map {
        "document.id": $documentId,
        "context.id": $contextId,
        "source.id": $source,
        "state.id": $state,
        "focus.id": $focus
    })
};

(:~
 : Get TEI snippet for complaint text
 :
 : @param $documentId The document identifier
 : @param $contextId The context/annotation identifier
 : @return TEI XML snippet
 :)
declare
    %rest:GET
    %rest:path("/module3/{$documentId}/snippet/{$contextId}.tei")
    %rest:query-param("source", "{$source}", "")
    %rest:query-param("state", "{$state}", "")
    %rest:produces("application/xml")
    %output:method("xml")
function module3-api:get-tei-snippet($documentId as xs:string, $contextId as xs:string, $source as xs:string, $state as xs:string) {
    api-base:forward-to-xql("/resources/xql/module3/get-complaint-TEI-text-by-annot.xql", map {
        "document.id": $documentId,
        "context.id": $contextId,
        "source.id": $source,
        "state.id": $state
    })
};

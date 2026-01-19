xquery version "3.1";

(:~
 : Module 2 REST API - Comparison/Textual Variance
 : 
 : Provides RESTXQ endpoints for accessing comparison data between different
 : sources and versions of musical works.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace module2-api = "https://api.beethovens-werkstatt.de/rest/module2";

import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";

(:~
 : @openapi:tag Module2
 : @openapi:description Textual variance analysis and comparison tools
 :)

(: ============================================================
   COMPARISON LISTING
   ============================================================ :)

(:~
 : List all available comparisons
 :
 : @return JSON array of comparison objects
 :
 : @openapi:summary List all comparisons
 : @openapi:response 200 application/json Array of comparison objects
 :)
declare
    %rest:GET
    %rest:path("/module2/comparisons.json")
    %rest:produces("application/json")
    %output:method("json")
function module2-api:list-comparisons() {
    api-base:forward-to-xql("/resources/xql/module2/getComparisonListing.xql", map {})
};

(: ============================================================
   ANALYSIS ENDPOINTS
   ============================================================ :)

(:~
 : Get basic comparison analysis
 :
 : @param $comparisonId The comparison identifier
 : @param $mdiv The movement/division number
 : @param $transpose The transposition setting
 : @return MEI XML comparison analysis
 :)
declare
    %rest:GET
    %rest:path("/module2/data/{$comparisonId}/mdiv/{$mdiv}/transpose/{$transpose}/basic.xml")
    %rest:query-param("hideStaves", "{$hideStaves}", "")
    %rest:produces("application/xml")
    %output:method("xml")
function module2-api:get-basic-analysis($comparisonId as xs:string, $mdiv as xs:string, $transpose as xs:string, $hideStaves as xs:string) {
    api-base:forward-to-xql("/resources/xql/module2/getAnalysis.xql", map {
        "comparisonId": $comparisonId,
        "method": "comparison",
        "mdiv": $mdiv,
        "transpose": $transpose,
        "hiddenStaves": $hideStaves
    })
};

(:~
 : Get event density comparison analysis
 :
 : @param $comparisonId The comparison identifier
 : @param $mdiv The movement/division number
 : @param $transpose The transposition setting
 : @return MEI XML with event density analysis
 :)
declare
    %rest:GET
    %rest:path("/module2/data/{$comparisonId}/mdiv/{$mdiv}/transpose/{$transpose}/eventDensity.xml")
    %rest:query-param("hideStaves", "{$hideStaves}", "")
    %rest:produces("application/xml")
    %output:method("xml")
function module2-api:get-event-density($comparisonId as xs:string, $mdiv as xs:string, $transpose as xs:string, $hideStaves as xs:string) {
    api-base:forward-to-xql("/resources/xql/module2/getAnalysis.xql", map {
        "comparisonId": $comparisonId,
        "method": "eventDensity",
        "mdiv": $mdiv,
        "transpose": $transpose,
        "hiddenStaves": $hideStaves
    })
};

(:~
 : Get melodic contour comparison analysis
 :
 : @param $comparisonId The comparison identifier
 : @param $mdiv The movement/division number
 : @param $transpose The transposition setting
 : @return MEI XML with melodic comparison
 :)
declare
    %rest:GET
    %rest:path("/module2/data/{$comparisonId}/mdiv/{$mdiv}/transpose/{$transpose}/melodicComparison.xml")
    %rest:query-param("hideStaves", "{$hideStaves}", "")
    %rest:produces("application/xml")
    %output:method("xml")
function module2-api:get-melodic-comparison($comparisonId as xs:string, $mdiv as xs:string, $transpose as xs:string, $hideStaves as xs:string) {
    api-base:forward-to-xql("/resources/xql/module2/getAnalysis.xql", map {
        "comparisonId": $comparisonId,
        "method": "melodicComparison",
        "mdiv": $mdiv,
        "transpose": $transpose,
        "hiddenStaves": $hideStaves
    })
};

(:~
 : Get harmonic comparison analysis
 :
 : @param $comparisonId The comparison identifier
 : @param $mdiv The movement/division number
 : @param $transpose The transposition setting
 : @return MEI XML with harmonic comparison
 :)
declare
    %rest:GET
    %rest:path("/module2/data/{$comparisonId}/mdiv/{$mdiv}/transpose/{$transpose}/harmonicComparison.xml")
    %rest:query-param("hideStaves", "{$hideStaves}", "")
    %rest:produces("application/xml")
    %output:method("xml")
function module2-api:get-harmonic-comparison($comparisonId as xs:string, $mdiv as xs:string, $transpose as xs:string, $hideStaves as xs:string) {
    api-base:forward-to-xql("/resources/xql/module2/getAnalysis.xql", map {
        "comparisonId": $comparisonId,
        "method": "harmonicComparison",
        "mdiv": $mdiv,
        "transpose": $transpose,
        "hiddenStaves": $hideStaves
    })
};

(: ============================================================
   INTRODUCTION
   ============================================================ :)

(:~
 : Get introduction HTML for a comparison
 :
 : @param $comparisonId The comparison identifier
 : @return HTML introduction text
 :)
declare
    %rest:GET
    %rest:path("/module2/{$comparisonId}/intro.html")
    %rest:produces("text/html")
    %output:method("html5")
function module2-api:get-introduction($comparisonId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module2/getTextIntroduction.xql", map {
        "comparisonId": $comparisonId
    })
};

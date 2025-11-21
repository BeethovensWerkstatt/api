xquery version "3.1";

(:~
 : Module 4 REST API - Engraving Comparison
 : 
 : Provides access to engraving comparison data
 :)

module namespace module4-api = "https://api.beethovens-werkstatt.de/rest/module4";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Get source summary as JSON
 :)
declare
    %rest:GET
    %rest:path("/module4/get_source_summary_as_json.xql")
function module4-api:get-source-summary-json() {
    util:eval(xs:anyURI("../xql/module4/get_source_summary_as_json.xql"), false())
};

(:~
 : Get source summary (alternate endpoint)
 :)
declare
    %rest:GET
    %rest:path("/module4/getSourceSummary.xql")
function module4-api:get-source-summary() {
    util:eval(xs:anyURI("../xql/module4/getSourceSummary.xql"), false())
};

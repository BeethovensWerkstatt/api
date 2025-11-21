xquery version "3.1";

(:~
 : Module 3 REST API - Sketch Analysis
 : 
 : Provides access to sketch analyses and work lists
 :)

module namespace module3-api = "https://api.beethovens-werkstatt.de/rest/module3";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Get available works
 :)
declare
    %rest:GET
    %rest:path("/module3/available-works.xql")
function module3-api:available-works() {
    util:eval(xs:anyURI("../xql/module3/available-works.xql"), false())
};

(:~
 : Convert MEI to JSON
 :)
declare
    %rest:GET
    %rest:path("/module3/mei2json.xql")
function module3-api:mei-to-json() {
    util:eval(xs:anyURI("../xql/module3/mei2json.xql"), false())
};

(:~
 : Get work list
 :)
declare
    %rest:GET
    %rest:path("/module3/work-list.xql")
function module3-api:work-list() {
    util:eval(xs:anyURI("../xql/module3/work-list.xql"), false())
};

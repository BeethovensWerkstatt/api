xquery version "3.1";

(:~
 : Module 2 REST API - Analysis
 : 
 : Provides access to analyses, comparisons, and fragments
 :)

module namespace module2-api = "https://api.beethovens-werkstatt.de/rest/module2";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Get analysis by ID
 :)
declare
    %rest:GET
    %rest:path("/module2/getAnalysis.xql")
    %rest:query-param("analysis", "{$analysisId}")
function module2-api:get-analysis($analysisId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getAnalysis.xql"), false())
};

(:~
 : Get analysis by MEI file
 :)
declare
    %rest:GET
    %rest:path("/module2/getAnalysisByMei.xql")
    %rest:query-param("mei", "{$meiId}")
function module2-api:get-analysis-by-mei($meiId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getAnalysisByMei.xql"), false())
};

(:~
 : Get analyses dashboard
 :)
declare
    %rest:GET
    %rest:path("/module2/getAnalysesDashboard.xql")
function module2-api:get-analyses-dashboard() {
    util:eval(xs:anyURI("../xql/module2/getAnalysesDashboard.xql"), false())
};

(:~
 : Get comparison fragments
 :)
declare
    %rest:GET
    %rest:path("/module2/getComparisonFragments.xql")
    %rest:query-param("comparison", "{$comparisonId}")
function module2-api:get-comparison-fragments($comparisonId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getComparisonFragments.xql"), false())
};

(:~
 : Get comparison
 :)
declare
    %rest:GET
    %rest:path("/module2/getComparison.xql")
    %rest:query-param("comparison", "{$comparisonId}")
function module2-api:get-comparison($comparisonId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getComparison.xql"), false())
};

(:~
 : Get fragment
 :)
declare
    %rest:GET
    %rest:path("/module2/getFragment.xql")
    %rest:query-param("fragment", "{$fragmentId}")
function module2-api:get-fragment($fragmentId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getFragment.xql"), false())
};

(:~
 : Get MEI file
 :)
declare
    %rest:GET
    %rest:path("/module2/getMei.xql")
    %rest:query-param("mei", "{$meiId}")
function module2-api:get-mei($meiId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getMei.xql"), false())
};

(:~
 : Get work by ID
 :)
declare
    %rest:GET
    %rest:path("/module2/getWork.xql")
    %rest:query-param("work", "{$workId}")
function module2-api:get-work($workId as xs:string*) {
    util:eval(xs:anyURI("../xql/module2/getWork.xql"), false())
};

(:~
 : Get all works
 :)
declare
    %rest:GET
    %rest:path("/module2/getWorks.xql")
function module2-api:get-works() {
    util:eval(xs:anyURI("../xql/module2/getWorks.xql"), false())
};

(:~
 : List all analyses
 :)
declare
    %rest:GET
    %rest:path("/module2/listAnalyses.xql")
function module2-api:list-analyses() {
    util:eval(xs:anyURI("../xql/module2/listAnalyses.xql"), false())
};

(:~
 : List combinations
 :)
declare
    %rest:GET
    %rest:path("/module2/listCombinations.xql")
function module2-api:list-combinations() {
    util:eval(xs:anyURI("../xql/module2/listCombinations.xql"), false())
};

(:~
 : List comparisons
 :)
declare
    %rest:GET
    %rest:path("/module2/listComparisons.xql")
function module2-api:list-comparisons() {
    util:eval(xs:anyURI("../xql/module2/listComparisons.xql"), false())
};

(:~
 : List works with analyses
 :)
declare
    %rest:GET
    %rest:path("/module2/listWorksWithAnalyses.xql")
function module2-api:list-works-with-analyses() {
    util:eval(xs:anyURI("../xql/module2/listWorksWithAnalyses.xql"), false())
};

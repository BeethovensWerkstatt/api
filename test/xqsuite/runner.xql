xquery version "3.1";

(:~
 : XQSuite Test Runner
 : 
 : This module runs all unit tests and returns results in a structured format.
 : Deploy this to eXist-db and access via REST or eXide.
 :
 : Usage:
 :   - Via REST: GET /exist/apps/api/test/run
 :   - Via eXide: Open and run this file
 :   - Via xst: xst run test/xqsuite/runner.xql
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

import module namespace test = "http://exist-db.org/xquery/xqsuite" 
    at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

(: Import test modules :)
import module namespace test-config = "https://api.beethovens-werkstatt.de/test/config" 
    at "config-tests.xqm";
import module namespace test-validation = "https://api.beethovens-werkstatt.de/test/validation"
    at "validation-tests.xqm";
import module namespace test-iiif = "https://api.beethovens-werkstatt.de/test/iiif"
    at "iiif-tests.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "xml";
declare option output:indent "yes";

(:~
 : Run all tests and return results
 :)
let $results := test:suite((
    (: Configuration tests :)
    inspect:module-functions(xs:anyURI("config-tests.xqm")),
    
    (: Validation utility tests :)
    inspect:module-functions(xs:anyURI("validation-tests.xqm")),
    
    (: IIIF module tests :)
    inspect:module-functions(xs:anyURI("iiif-tests.xqm"))
))

return $results

xquery version "3.1";

(:~
 : Other Services REST API
 : 
 : Provides context, EMA, and file service endpoints
 :)

module namespace services-api = "https://api.beethovens-werkstatt.de/rest/services";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : Get JSON-LD context definition
 :
 : @param $version The context version
 : @return JSON-LD context
 :)
declare
    %rest:GET
    %rest:path("/{$version}/context.json")
    %rest:produces("application/json")
    %output:method("json")
function services-api:get-context($version as xs:string) {
    util:eval(
        xs:anyURI("../xql/context.xql"),
        false(),
        (xs:QName("version"), $version)
    )
};

(:~
 : Get EMA (Encoded Musical Analysis) data
 :
 : @param $identifier The source identifier
 : @param $measureRanges The measure ranges
 : @return JSON with EMA data
 :)
declare
    %rest:GET
    %rest:path("/source/{$identifier}/{$measureRanges}/measures.json")
    %rest:produces("application/json")
    %output:method("json")
function services-api:get-ema($identifier as xs:string, $measureRanges as xs:string) {
    util:eval(
        xs:anyURI("../xql/ema/get-ema.xql"),
        false(),
        (xs:QName("identifier"), $identifier, xs:QName("measureRanges"), $measureRanges)
    )
};

(:~
 : Get file by ID
 :
 : @param $fileId The file identifier
 : @return File content
 :)
declare
    %rest:GET
    %rest:path("/file/{$fileId}")
function services-api:get-file($fileId as xs:string) {
    util:eval(
        xs:anyURI("../xql/file/get-file.xql"),
        false(),
        (xs:QName("fileId"), $fileId)
    )
};

(:~
 : Get element by ID
 :
 : @param $elementId The element identifier
 : @return Element content
 :)
declare
    %rest:GET
    %rest:path("/element/{$elementId}")
function services-api:get-element($elementId as xs:string) {
    util:eval(
        xs:anyURI("../xql/file/get-element.xql"),
        false(),
        (xs:QName("elementId"), $elementId)
    )
};

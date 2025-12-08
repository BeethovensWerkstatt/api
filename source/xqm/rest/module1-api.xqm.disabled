xquery version "3.1";

(:~
 : Module 1 REST API - Digital Edition
 : 
 : Provides access to MEI files, genetic states, annotations, and related data
 :)

module namespace module1-api = "https://api.beethovens-werkstatt.de/rest/module1";

import module namespace config="https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace request = "http://exist-db.org/xquery/request";

(:~
 : List all MEI files in the database
 :
 : @return JSON array of available editions
 :)
declare
    %rest:GET
    %rest:path("/data.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:list-all-files() {
    util:eval(xs:anyURI("../xql/module1/get_all_MEI_files_from_DB_as_JSON.xql"), false())
};

(:~
 : Get introduction HTML for a document
 :
 : @param $documentId The document identifier
 : @return HTML introduction
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/introduction.html")
    %rest:produces("text/html")
    %output:method("xml")
function module1-api:get-introduction($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_introduction_as_HTML.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get full MEI file
 :
 : @param $documentId The document identifier
 : @return MEI XML file
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/file.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-file($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_MEI_file_as_XML.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get pages in edition
 :
 : @param $documentId The document identifier
 : @return JSON array of pages
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/pages.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-pages($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_pages_in_edition_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get list of genetic states
 :
 : @param $documentId The document identifier
 : @return JSON array of genetic states
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/geneticStates.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-genetic-states($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_geneticStatesList_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get specific genetic state as XML
 :
 : @param $documentId The document identifier
 : @param $stateId The genetic state identifier
 : @return MEI XML of genetic state
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/geneticState/{$stateId}.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-genetic-state($documentId as xs:string, $stateId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_geneticState_as_XML.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("stateId"), $stateId)
    )
};

(:~
 : Get final state as XML
 :
 : @param $documentId The document identifier
 : @return MEI XML of final state
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/finalState.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-final-state($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_final_state_as_XML.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get all annotations for a document
 :
 : @param $documentId The document identifier
 : @return JSON array of annotations
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/annotations.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-annotations($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_annotations_as_json.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get annotations for a specific page
 :
 : @param $documentId The document identifier
 : @param $pageId The page identifier
 : @return JSON array of annotations for the page
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/page/{$pageId}/annotations.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-page-annotations($documentId as xs:string, $pageId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_annotations_on_page_as_json.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("pageId"), $pageId)
    )
};

(:~
 : Get note positions for a document
 :
 : @param $documentId The document identifier
 : @return JSON with note position data
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/notePositions.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-note-positions($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_note_positions_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get measure overview
 :
 : @param $documentId The document identifier
 : @return JSON with measure overview data
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/measures.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-measures($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_measure_overview_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get invariance relations
 :
 : @param $documentId The document identifier
 : @return JSON with invariance relations data
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/invariances.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-invariances($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_invariance_relations_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get reconstruction setup data
 :
 : @param $documentId The document identifier
 : @return JSON with reconstruction setup
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/reconstructionSetup.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-reconstruction-setup($documentId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_reconstruction_setup_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId)
    )
};

(:~
 : Get facsimile information for an element
 :
 : @param $documentId The document identifier
 : @param $elementId The element identifier
 : @return JSON with facsimile data
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/element/{$elementId}/facsimile.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-element-facsimile($documentId as xs:string, $elementId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_facsimile_info_for_element_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("elementId"), $elementId)
    )
};

(:~
 : Get element description
 :
 : @param $documentId The document identifier
 : @param $elementId The element identifier
 : @return JSON with element description
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/element/{$elementId}/description.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-element-description($documentId as xs:string, $elementId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_element_description_as_JSON.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("elementId"), $elementId)
    )
};

(:~
 : Get element preview as XML
 :
 : @param $documentId The document identifier
 : @param $elementId The element identifier
 : @return MEI XML preview of element
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/element/{$elementId}/preview.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-element-preview($documentId as xs:string, $elementId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_element_preview_as_XML.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("elementId"), $elementId)
    )
};

(:~
 : Get MEI snippet for an element
 :
 : @param $documentId The document identifier
 : @param $elementId The element identifier
 : @return MEI XML snippet
 :)
declare
    %rest:GET
    %rest:path("/document/{$documentId}/snippet/{$elementId}.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-snippet($documentId as xs:string, $elementId as xs:string) {
    util:eval(
        xs:anyURI("../xql/module1/get_MEI_snippet_as_XML.xql"),
        false(),
        (xs:QName("documentId"), $documentId, xs:QName("elementId"), $elementId)
    )
};

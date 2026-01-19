xquery version "3.1";

(:~
 : Module 1 REST API - VideApp Digital Edition
 : 
 : Provides RESTXQ endpoints for accessing MEI files, genetic states, 
 : annotations, and related data for the VideApp digital edition interface.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace module1-api = "https://api.beethovens-werkstatt.de/rest/module1";

import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace request = "http://exist-db.org/xquery/request";

(:~
 : @openapi:tag Module1
 : @openapi:description VideApp - Digital critical edition with genetic analysis
 :)

(: ============================================================
   LIST ALL EDITIONS
   ============================================================ :)

(:~
 : List all MEI files/editions in the database
 :
 : @return JSON array of available editions
 :
 : @openapi:summary List all editions
 : @openapi:response 200 application/json Array of edition objects
 :)
declare
    %rest:GET
    %rest:path("/module1/listAll.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:list-all() {
    api-base:forward-to-xql("/resources/xql/module1/get_all_MEI_files_from_DB_as_JSON.xql", map {})
};

(: ============================================================
   FILE ENDPOINTS
   ============================================================ :)

(:~
 : Get MEI file as XML
 :
 : @param $fileId The file identifier
 : @return MEI XML document
 :)
declare
    %rest:GET
    %rest:path("/module1/file/{$fileId}.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-file-xml($fileId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_MEI_file_as_XML.xql", map {
        "file.id": $fileId
    })
};

(:~
 : Get SVG file
 :
 : @param $fileId The file identifier
 : @return SVG document
 :)
declare
    %rest:GET
    %rest:path("/module1/file/{$fileId}.svg")
    %rest:produces("image/svg+xml")
    %output:method("xml")
function module1-api:get-file-svg($fileId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_SVG_file_as_XML.xql", map {
        "file.id": $fileId
    })
};

(: ============================================================
   EDITION ENDPOINTS
   ============================================================ :)

(:~
 : Get final state of an edition as XML
 :
 : @param $editionId The edition identifier
 : @return MEI XML of final state
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/finalState.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-final-state($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_final_state_as_XML.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get genetic states overview for navigation
 :
 : @param $editionId The edition identifier
 : @return JSON array of genetic states
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/states/overview.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-states-overview($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_geneticStatesList_as_JSON.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get annotations for an edition
 :
 : @param $editionId The edition identifier
 : @return JSON array of annotations
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/annotations.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-annotations($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_annotations_as_json.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get scar categories for an edition
 :
 : @param $editionId The edition identifier
 : @return JSON array of scar categories
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/scars/categories.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-scar-categories($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_scar_categories_as_JSON.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get reconstruction setup for an edition
 :
 : @param $editionId The edition identifier
 : @return JSON reconstruction setup
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/reconstructionSetup.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-reconstruction-setup($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_reconstruction_setup_as_JSON.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get invariance relations for an edition
 :
 : @param $editionId The edition identifier
 : @return JSON invariance relations
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/invarianceRelations.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-invariance-relations($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_invariance_relations_as_JSON.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get introduction HTML for an edition
 :
 : @param $editionId The edition identifier
 : @return HTML introduction
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/introduction.html")
    %rest:produces("text/html")
    %output:method("html5")
function module1-api:get-introduction($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_introduction_as_HTML.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get pages in an edition
 :
 : @param $editionId The edition identifier
 : @return JSON array of pages
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/pages.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-pages($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_pages_in_edition_as_JSON.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get measure overview for an edition
 :
 : @param $editionId The edition identifier
 : @return JSON array of measures
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/measures.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-measures($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_measure_overview_as_JSON.xql", map {
        "edition.id": $editionId
    })
};

(:~
 : Get first state MEI snippet for an edition
 :
 : @param $editionId The edition identifier
 : @return MEI XML snippet
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/firstState/meiSnippet.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-first-state($editionId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_geneticState_as_XML.xql", map {
        "edition.id": $editionId,
        "state.id": "''"
    })
};

(: ============================================================
   PAGE ENDPOINTS
   ============================================================ :)

(:~
 : Get annotations on a specific page
 :
 : @param $editionId The edition identifier
 : @param $pageId The page identifier
 : @return JSON array of annotations on page
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/page/{$pageId}/annotations.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-page-annotations($editionId as xs:string, $pageId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_annotations_on_page_as_json.xql", map {
        "edition.id": $editionId,
        "page.id": $pageId
    })
};

(: ============================================================
   ELEMENT ENDPOINTS
   ============================================================ :)

(:~
 : Get element as XML snippet
 :
 : @param $editionId The edition identifier
 : @param $elementId The element identifier
 : @return MEI XML element
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/element/{$elementId}.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-element($editionId as xs:string, $elementId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_MEI_snippet_as_XML.xql", map {
        "edition.id": $editionId,
        "element.id": $elementId
    })
};

(:~
 : Get element description in specified language
 :
 : @param $editionId The edition identifier
 : @param $elementId The element identifier
 : @param $lang Language code (en or de)
 : @return JSON element description
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/element/{$elementId}/{$lang}/description.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-element-description($editionId as xs:string, $elementId as xs:string, $lang as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_element_description_as_JSON.xql", map {
        "edition.id": $editionId,
        "element.id": $elementId,
        "lang": $lang
    })
};

(:~
 : Get element preview with states
 :
 : @param $editionId The edition identifier
 : @param $elementId The element identifier
 : @param $states Comma-separated state IDs
 : @return MEI XML preview
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/element/{$elementId}/states/{$states}/preview.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-element-preview($editionId as xs:string, $elementId as xs:string, $states as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_element_preview_as_XML.xql", map {
        "edition.id": $editionId,
        "element.id": $elementId,
        "states": $states
    })
};

(:~
 : Get facsimile info for an element
 :
 : @param $editionId The edition identifier
 : @param $elementId The element identifier
 : @param $dimensions Width,Height dimensions
 : @return JSON facsimile info
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/element/{$elementId}/{$dimensions}/facsimileInfo.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-facsimile-info($editionId as xs:string, $elementId as xs:string, $dimensions as xs:string) {
    let $parts := tokenize($dimensions, ',')
    return api-base:forward-to-xql("/resources/xql/module1/get_facsimile_info_for_element_as_JSON.xql", map {
        "edition.id": $editionId,
        "element.id": $elementId,
        "w": $parts[1],
        "h": $parts[2]
    })
};

(: ============================================================
   STATE ENDPOINTS
   ============================================================ :)

(:~
 : Get genetic state as MEI snippet
 :
 : @param $editionId The edition identifier
 : @param $stateId The state identifier
 : @param $otherStates Other states to include
 : @return MEI XML snippet
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/state/{$stateId}/otherStates/{$otherStates}/meiSnippet.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-state-snippet($editionId as xs:string, $stateId as xs:string, $otherStates as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_geneticState_as_XML.xql", map {
        "edition.id": $editionId,
        "state.id": $stateId,
        "other.states": $otherStates
    })
};

(: ============================================================
   SHAPE ENDPOINTS
   ============================================================ :)

(:~
 : Get shape info
 :
 : @param $editionId The edition identifier
 : @param $shapeId The shape identifier
 : @return JSON shape info
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/shape/{$shapeId}/info.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-shape-info($editionId as xs:string, $shapeId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_shape_info_as_JSON.xql", map {
        "edition.id": $editionId,
        "shape.id": $shapeId
    })
};

(:~
 : Get shapes for an object
 :
 : @param $editionId The edition identifier
 : @param $objectId The object identifier
 : @return JSON array of shapes
 :)
declare
    %rest:GET
    %rest:path("/module1/edition/{$editionId}/object/{$objectId}/shapes.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-object-shapes($editionId as xs:string, $objectId as xs:string) {
    api-base:forward-to-xql("/resources/xql/module1/get_shapes_for_object_as_JSON.xql", map {
        "edition.id": $editionId,
        "object.id": $objectId
    })
};

xquery version "3.1";

(:~
 : Documents REST API - Documents
 : 
 : Provides RESTXQ endpoints for handling documents
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace documents-api = "https://api.beethovens-werkstatt.de/rest/documents";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";
import module namespace config = "https://api.beethovens-werkstatt.de" at "../config.xqm";
import module namespace ef = "https://edirom.de/file" at "../file.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace util = "http://exist-db.org/xquery/util";

(:~
 : @openapi:tag Documents
 : @openapi:description Endpoints dealing with Documents
 :)

(: ============================================================
   DOCUMENT LISTING
   ============================================================ :)

(:~
 : List all Documents
 :
 : @return JSON array of document objects
 :
 : @openapi:summary List all Documents
 : @openapi:response 200 application/json Array of document objects
 :)
declare
    %rest:GET
    %rest:path("/documents.json")
    %rest:produces("application/json")
    %output:method("json")
function documents-api:list-documents() {
    api-base:forward-to-xql("/resources/xql/documents/get-documents-list.xql", map {})
};

(:~
 : Get specific document details
 :
 : @param $documentId The document identifier
 : @return JSON document object with details
 :)
 declare
    %rest:GET
    %rest:path("/document/{$documentId}/overview.json")
    %rest:produces("application/json")
    %output:method("json")
function documents-api:get-document($documentId as xs:string) {
    api-base:forward-to-xql("/resources/xql/documents/get-document-overview.xql", map { "documentId": $documentId })
};

(:~
 : Get transcription details for a specific genetic description
 :
 : @param $genDescId The genetic description identifier
 : @return JSON object with transcription details
 :
 : @openapi:summary Get transcription details for a genDesc
 : @openapi:response 200 application/json Transcription details object
 :)
declare
    %rest:GET
    %rest:path("/document/genDesc/{$genDescId}.json")
    %rest:produces("application/json")
    %output:method("json")
function documents-api:get-transcription-details($genDescId as xs:string) {
    api-base:forward-to-xql("/resources/xql/documents/get-transcription-details.xql", map { "genDescId": $genDescId })
};

(:~
 : Get prerendered transcription SVG for a specific genetic description
 :
 : @param $fileName The file name of the prerendered SVG
 : @return SVG object with transcription details
 :
 : @openapi:summary Get prerendered transcription SVG for a genDesc
 : @openapi:response 200 image/svg+xml Transcription details object
 :)
declare
    %rest:GET
    %rest:path("/document/prerendered/{$fileName}.svg")
    %rest:produces("image/svg+xml")
    %output:method("xml")
function documents-api:get-prerendered-transcription-svg($fileName as xs:string) {
    let $fullName   := $fileName || '.svg'
    let $paddedPage := fn:analyze-string($fullName, 'p(\d{3})')/fn:match/string()
    let $paddedWz   := fn:analyze-string($fullName, 'wz(\d{2})')/fn:match/string()
    let $docType    :=
        if      (ends-with($fullName, '_at.svg')) then '/annotatedTranscripts/'
        else if (ends-with($fullName, '_dt.svg')) then '/diplomaticTranscripts/'
        else if (ends-with($fullName, '_ft.svg')) then '/fluidTranscripts/'
        else ''
    let $docName := substring-before($fullName, '_' || $paddedPage || '_' || $paddedWz)
    let $path    := $config:data-cache-root || 'sources/' || $docName || $docType || $paddedPage || '/' || $fullName
    return ef:getDocByPath($path)
};

(:~
 : Get prerendered transcription SVG for a specific genetic description
 :
 : @param $fileName The file name of the prerendered SVG
 : @return SVG object with transcription details
 :
 : @openapi:summary Get prerendered transcription SVG for a genDesc
 : @openapi:response 200 image/svg+xml Transcription details object
 :)
declare
    %rest:GET
    %rest:path("/document/shapes/{$fileName}.svg")
    %rest:produces("image/svg+xml")
    %output:method("xml")
function documents-api:get-svg-shapes($fileName as xs:string) {
    let $fullName   := $fileName || '.svg'
    let $paddedPage := fn:analyze-string($fullName, 'p(\d{3})')/fn:match/string()
    let $docName := substring-before($fullName, '_' || $paddedPage || '.svg')
    let $path    := $config:data-root || 'sources/' || $docName || '/svg/' || $fullName
    return ef:getDocByPath($path)
};

(:~
 : Get MIDI file for a specific writing zone
 :
 : @param $fileName The file name of the MIDI file
 : @return MIDI file object
 :
 : @openapi:summary Get MIDI file for a writing zone
 : @openapi:response 200 audio/midi MIDI file object
 :)
declare
    %rest:GET
    %rest:path("/document/midi/{$fileName}.mid")
    %rest:produces("audio/midi")
    %output:method("binary")
function documents-api:get-midi-file($fileName as xs:string) {
    let $fullName   := $fileName || '.mid'
    let $paddedPage := fn:analyze-string($fullName, 'p(\d{3})')/fn:match/string()
    let $docName := substring-before($fullName, '_' || $paddedPage || '_wz')
    let $path    := $config:data-cache-root || 'sources/' || $docName || '/annotatedMidi/' || $paddedPage || '/' || $fullName
    let $midi := util:binary-doc($path)
    return
        if (exists($midi)) then $midi
        else api-base:not-found($path)
};

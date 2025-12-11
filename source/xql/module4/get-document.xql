xquery version "3.1";

(:
    get-document.xql

    This xQuery retrieves a given document
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace ef="https://edirom.de/file" at "../../xqm/file.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

let $document.id := request:get-parameter('document.id','')
let $document.external.id := ef:getDocumentLink($document.id)

let $file := $database//id($document.id)

let $manifestation := ($file//mei:manifestation)[1]
let $manifestation.id := $manifestation/string(@xml:id)
let $facsimile := ($file//mei:facsimile)[1]

let $manifestation.label := $manifestation/mei:physLoc/mei:repository/mei:identifier[@auth = 'RISM']/text() || ' ' || $manifestation/mei:physLoc/mei:identifier/text()

let $iiif.manifest := $config:iiif-basepath || 'document/' || $manifestation.id || '/manifest.json'

let $output := map {
    '@id': $document.external.id,
    'label': $manifestation.label,
    'frbr': map {
        'level': 'manifestation'
    },
    'iiif': map {
        'manifest': $iiif.manifest
    }
}


return $output
xquery version "3.1";

(:
    get-documents.xql

    This xQuery retrieves a list of all documents for which a IIIF manifest can be provided
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

(: get all files that have both an ID and some operable graphic elements :)
let $files :=
  for $facsimile in $database//mei:mei[@xml:id][.//mei:facsimile[@xml:id and .//mei:graphic]]//mei:facsimile
  let $id := $facsimile/string(@xml:id)
  let $file.id := $facsimile/ancestor::mei:mei/string(@xml:id)
  let $manifest := $config:iiif-basepath || 'document/' || $id || '/manifest.json'
  let $pages := count($facsimile//mei:surface[mei:graphic])
  return map {
    'id': $id,              (: the ID of the file :)
    'manifest': $manifest,  (: link to the IIIF manifest :)
    'pages': $pages,        (: the number of pages :)
    'file': ef:getFileLink($file.id)
  }



return array { $files }

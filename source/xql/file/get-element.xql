xquery version "3.1";

(:
    get-element.xql

    This xQuery retrieves a complete file and outputs it as XML
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "xml";
declare option output:media-type "application/xml";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the ID of the requested element, as passed by the controller :)
let $element.id := request:get-parameter('element.id','')

let $document.uri := $config:file-basepath || $document.id || '.xml'

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

let $element := $file/root()/id($element.id)

return $element
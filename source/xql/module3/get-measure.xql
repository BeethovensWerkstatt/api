xquery version "3.1";

(:
    get-work.xql

    This xQuery retrieves relevant information about a work from the third module of Beethovens Werkstatt
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
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace xi = "http://www.w3.org/2001/XInclude";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the ID of the requested mdiv, as passed by the controller :)
let $measure.id := request:get-parameter('measure.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: build mdiv json :)
let $measure := $database//mei:measure[@xml:id = $measure.id]

let $measure.link := ef:getMeasureLink($document.id, $measure/string(@xml:id))

let $mdiv := $measure/ancestor::mei:mdiv[@xml:id][1]
let $mdiv.id := $mdiv/string(@xml:id)
let $mdiv.link := ef:getMdivLink($document.id, $mdiv.id)

let $measure.label := 
    if($measure/@label)
    then($measure/string(@label))
    else if($measure/@n)
    then($measure/string(@n))
    else('(' || string(count($mdiv//mei:measure[following::mei:measure[@xml:id = $measure.id]]) + 1) || ')')
    
let $staves := 
    for $staff in distinct-values($measure//mei:staff/xs:integer(@n))
    order by $staff ascending
    return $staff

(: check validity :)

(: get file from database :)
let $corpus.file := $database//mei:meiCorpus[@xml:id = $document.id]
let $inclusion.base.uri := string-join(tokenize(document-uri($corpus.file/root()),'/')[position() lt last()],'/')
let $included.file.uris := 
    for $link in $corpus.file//xi:include/string(@href)
    return replace($inclusion.base.uri || '/' || $link,'/\./','/')

let $measure.file := $measure/root()
let $proper.textfile := exists($measure.file//mei:encodingDesc[@class='#bw_module3_textFile'])
let $correctly.loaded := document-uri($measure.file) = $included.file.uris

let $output := 
    if($proper.textfile and $correctly.loaded or 1 eq 1)
    then(
        map {
        '@id': $measure.link,
        'mdiv': $mdiv.link,
        'label': $measure.label,
        'staves': array { $staves },
        'work': $document.uri
    }
    ) else (
        (: TODO: add RESSOURCE NOT FOUND:)
        map {
            
        }
    )

return $output

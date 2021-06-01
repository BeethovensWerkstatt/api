xquery version "3.1";

(:
    get-manifestation.xql

    This xQuery retrieves relevant information about a manifestation from the third module of Beethovens Werkstatt
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
let $manifestation.id := request:get-parameter('manifestation.id','')

let $manifestation.external.id := ef:getManifestationLink($document.id, $manifestation.id)
let $document.uri := $config:module3-basepath || $document.id || '.json'

let $scope := request:get-parameter('scope','')
let $mdiv.id := request:get-parameter('mdiv.id','')
let $mdiv.uri := ef:getMdivLink($document.id, $mdiv.id)
let $part.n := request:get-parameter('part.n','')


let $mdiv := $database//mei:mdiv[@xml:id = $mdiv.id]
let $measures := 
    if($scope = 'score')
    then(
        for $measure in $mdiv/mei:score//mei:measure/string(@xml:id)
        return ef:getMeasureLink($document.id, $measure)
    )
    else if($scope = 'part')
    then(
        for $measure in $mdiv/mei:parts/mei:part[@n = $part.n]//mei:measure/string(@xml:id)
        return ef:getMeasureLink($document.id, $measure)
    )
    else if($scope = '')
    then(
        let $mei.file := $database//mei:manifestation[@xml:id = $manifestation.id]/ancestor::mei:mei
        for $measure in $mei.file//mei:measure/string(@xml:id)
        return ef:getMeasureLink($document.id, $measure)
    )
    else()
    
let $output :=
    if($scope = 'score')
    then(
        map {
            'document': $document.uri,
            'mdiv': $mdiv.uri,
            'manifestation': $manifestation.external.id,
            'scope': 'score',
            'measures': array { $measures } 
        }
    )
    else if($scope = 'part')
    then(
        map {
            'document': $document.uri,
            'mdiv': $mdiv.uri,
            'manifestation': $manifestation.external.id,
            'scope': 'part',
            'part': $part.n,
            'measures': array { $measures } 
        }
    )
    else if($scope = '')
    then(
        map {
            'document': $document.uri,
            'manifestation': $manifestation.external.id,
            'scope': 'manifestation',
            'measures': array { $measures } 
        }
    )
    else ((:TODO: 404 einbauen:))

return $output
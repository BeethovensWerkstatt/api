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
let $mdiv.id := request:get-parameter('mdiv.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: build mdiv json :)
let $mdiv := $database//mei:mdiv[@xml:id = $mdiv.id]
let $mdiv.n := 
    if($mdiv/@n)
    then($mdiv/xs:integer(@n))
    else(xs:integer(count($mdiv/preceding::mei:mdiv) + 1))
let $mdiv.label :=
    if($mdiv/@label)
    then($mdiv/string(@label))
    else if($mdiv/@n)
    then($mdiv/string(@n))
    else('(' || string(count($mdiv/preceding::mei:mdiv) + 1) || ')')
let $staves := 
    for $staff in distinct-values($mdiv//mei:staffDef/xs:integer(@n))
    let $staff.label := ($mdiv//mei:staffDef[@n = $staff and ./mei:label], $mdiv//mei:staffGrp[.//mei:staffDef[@n = $staff] and ./mei:label])[1]/mei:label/string(text())
    let $staff.labelAbbr := ($mdiv//mei:staffDef[@n = $staff and ./mei:labelAbbr], $mdiv//mei:staffGrp[.//mei:staffDef[@n = $staff] and ./mei:labelAbbr])[1]/mei:labelAbbr/string(text())
    order by $staff ascending
    return map {
        'n': $staff,
        'label': $staff.label,
        'abbr': $staff.labelAbbr
    }

(: check validity :)

(: get file from database :)
let $corpus.file := $database//mei:meiCorpus[@xml:id = $document.id]
let $inclusion.base.uri := string-join(tokenize(document-uri($corpus.file/root()),'/')[position() lt last()],'/')
let $included.file.uris := 
    for $link in $corpus.file//xi:include/string(@href)
    return replace($inclusion.base.uri || '/' || $link,'/\./','/')

let $mdiv.file := $mdiv/root()
let $proper.textfile := exists($mdiv.file//mei:encodingDesc[@class='#bw_module3_textFile'])
let $correctly.loaded := document-uri($mdiv.file) = $included.file.uris

let $output := 
    if($proper.textfile and $correctly.loaded)
    then(
        map {
        '@id': ef:getMdivLink($document.id, $mdiv.id),
        'label': $mdiv.label,
        'n': $mdiv.n,
        'staves': array { $staves },
        'work': $document.uri
    }
    ) else (
        (: TODO: add RESSOURCE NOT FOUND:)
        map {
            
        }
    )

return $output

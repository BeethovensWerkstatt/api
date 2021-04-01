xquery version "3.1";

(:
    get-complaint.xql

    This xQuery retrieves relevant information about a single complaint ("Monitum") from the third module of Beethovens Werkstatt
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace iiif="https://edirom.de/iiif" at "../../xqm/iiif.xqm";
import module namespace ef="https://edirom.de/file" at "../../xqm/file.xqm";
import module namespace ema="https://github.com/music-addressability/ema/blob/master/docs/api.md" at "../../xqm/ema.xqm";
import module namespace module3="https://beethovens-werkstatt/ns/module3" at "../../xqm/module3.xqm";


declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";
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
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the ID of the requested complaint, as passed by the controller :)
let $complaint.id := request:get-parameter('complaint.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

let $complaint := $file//mei:body//mei:metaMark[@xml:id = $complaint.id]

let $public.complaint.id := $config:module3-basepath || $document.id || '/complaints/' || $complaint.id || '.json'
let $mdiv := $complaint/ancestor::mei:mdiv[@xml:id][1]
let $mdiv.id := $mdiv/string(@xml:id)
let $mdiv.uri := ef:getMdivLink($document.id, $mdiv/string(@xml:id))
let $mdiv.n :=
    if($mdiv/@n)
    then($mdiv/string(@n))
    else(string(count($mdiv/preceding::mei:mdiv) + 1))
let $mdiv.label :=
    if($mdiv/@label)
    then($mdiv/string(@label))
    else if($mdiv/@n)
    then($mdiv/string(@n))
    else('(' || string(count($mdiv/preceding::mei:mdiv) + 1) || ')')

let $dependent.complaints := $file//mei:annot[@xml:id][@corresp = '#' || $complaint.id]

let $annot.ids := distinct-values(($complaint.id, $dependent.complaints/string(@xml:id)))[string-length(.) gt 0]

let $affected.measures :=
    for $complaint in ($complaint, $dependent.complaints)

    let $first.measure := $complaint/ancestor::mei:measure

    (:how many additional measures do I need to pull?:)
    let $range :=
        if($complaint/@tstamp2 and matches($complaint/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($complaint/@tstamp2,'m')) gt 0)
        then(xs:integer(substring-before($complaint/@tstamp2,'m')))
        else(0)
    let $subsequent.measures :=
        if($range gt 0)
        then($first.measure/following::mei:measure[position() le $range])
        else()

    return ($first.measure | $subsequent.measures)

let $affected.staves := tokenize($complaint/normalize-space(@staff),' ')

let $revisionDoc.ids := $complaint/tokenize(replace(normalize-space(@source),'#',''),' ')
let $revisionDocs :=
    for $source.id in $revisionDoc.ids
    return module3:getEmbodiment($document.id, $complaint, $source.id, 'revision', $affected.measures, $affected.staves)

let $anteDoc.ids := distinct-values($complaint/mei:relation[@rel = 'isRevisionOf']/tokenize(replace(normalize-space(@target),'#',''),' '))
let $anteDocs :=
    for $source.id in $anteDoc.ids
    return module3:getEmbodiment($document.id, $complaint, $source.id, 'ante', $affected.measures, $affected.staves)

let $postDoc.ids := distinct-values($complaint/mei:relation[@rel = 'hasRevision']/tokenize(replace(normalize-space(@target),'#',''),' '))
let $postDocs :=
    for $source.id in $postDoc.ids
    return module3:getEmbodiment($document.id, $complaint, $source.id, 'post', $affected.measures, $affected.staves)

let $measures :=
    for $measure.id in $affected.measures/string(@xml:id)
    let $measure := $file/root()/id($measure.id)
    let $measure.label :=
        if($measure/@label)
        then($measure/string(@label))
        else if($measure/@n)
        then($measure/string(@n))
        else('(' || string(count($measure/preceding::mei:measure) + 1) || ')')
    (: let $facs.refs := tokenize(normalize-space(replace($measure/@facs,'#','')),' ') :)

    return map {
        'id': $measure.id,
        'uri': ef:getElementLink($document.id,$measure.id),
        'label': $measure.label
    }

return map {
    '@id': $public.complaint.id,
    'label': $complaint/string(@label),
    '@work': $document.uri,
    'annots': array { for $annot in $annot.ids return ef:getElementLink($document.id,$annot)},
    'movement': map {
        'id': $mdiv.id,
        'uri': ef:getElementLink($document.id,$mdiv.id),
        'n': $mdiv.n,
        'label': $mdiv.label
    },
    'measures': array { $measures },
    'staves': array { $affected.staves },
    'revisionDocs': array { $revisionDocs },
    'anteDocs': array { $anteDocs },
    'postDocs': array { $postDocs }
}

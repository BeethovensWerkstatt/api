xquery version "3.1";

(:
    get-manifest.json.xql

    This xQuery retrieves a IIIF annotation list with the measure zones on the given page
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace iiif="https://edirom.de/iiif" at "../../xqm/iiif.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace f = "http://local.link";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

declare function f:addConditionally($map, $key, $data) as map(*) {
  if (exists($data)) then map:put($map, $key, $data) else $map
};

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')
(: get the ID of the canvas, on which the zones are located :)
let $canvas.id := request:get-parameter('canvas.id','')

(: get file from database :)
let $file := ($database//mei:mei[@xml:id = $document.id] | $database//mei:facsimile[@xml:id = $document.id]/ancestor::mei:mei)
(: is this a link to a facsimile only, or to a document :)
let $is.facsimile.id := not($file/@xml:id = $document.id)

let $canvas := $file//mei:surface[@xml:id = $canvas.id]

let $annotation.uri.base := $config:iiif-basepath || 'document/' || $document.id || '/annotation/'
let $document.uri := $config:iiif-basepath || 'document/' || $document.id || '/list/' || $canvas.id || '_zones'
let $canvas.uri := $config:iiif-basepath || 'document/' || $document.id || '/canvas/' || $canvas.id
let $manifest.uri := $config:iiif-basepath || 'document/' || $document.id || '/manifest.json'

(: build variable for file:)
let $file.context := 'http://www.shared-canvas.org/ns/context.json' (:'http://iiif.io/api/presentation/2/context.json':)
let $file.type := 'sc:AnnotationList'
let $canvas.label := 
    if($canvas/@label)
    then($canvas/string(@label))
    else if($canvas/@n)
    then($canvas/string(@n))
    else(string(count($canvas/preceding::mei:surface) + 1))
let $file.label := 'measure positions on page ' || $canvas.label || ' of ' || normalize-space(string-join($file//mei:fileDesc/mei:titleStmt/mei:composer//text(),' ')) || ': ' ||  string-join($file//mei:fileDesc/mei:titleStmt/mei:title//normalize-space(text()),' / ')

let $zone.ids := for $zone.id in $canvas//mei:zone/@xml:id return '#' || $zone.id
let $referencing.elements := $file//mei:*[@facs][@facs = $zone.ids or (contains(@facs,' ') and (some $ref in tokenize(normalize-space(@facs),' ') satisfies $ref = $zone.ids))]
let $references := distinct-values($canvas//mei:zone/tokenize(replace(normalize-space(@data),'#',''),' '))
let $referenced.elements := for $reference in $references return $file/root()/id($reference)

let $zones := 
    for $zone in $canvas//mei:zone[@xml:id]
    let $zone.targets :=
        if($zone/@data)
        then($referenced.elements[@xml:id = tokenize(replace(normalize-space($zone/@data),'#',''))])
        else if($referencing.elements[some $facs in tokenize(replace(normalize-space(./@facs),'#','')) satisfies $facs = $zone/@xml:id])
        then($referencing.elements[some $facs in tokenize(replace(normalize-space(./@facs),'#','')) satisfies $facs = $zone/@xml:id])
        else()
        
    (: when there are no elements connected to this zone, stop processing for this particular zone :)
    where exists($zone.targets) and (every $zone in $zone.targets satisfies $zone/@xml:id)
    
    (: retrieve labels for each element connected to the zone :)
    let $individual.labels :=
        for $target in $zone.targets
        return iiif:getLabel($target,true())
    (: and join them into a comma-separated list :)
    let $zone.target.label := string-join($individual.labels,', ')
    
    let $region := iiif:getRegion($zone)
    let $xywh := iiif:getXywh($region)
    
    let $graphic := $canvas/mei:graphic[@target and starts-with(@target,'http')]
    let $graphic.target := $graphic/string(@target)
    let $graphic.target.id := $graphic.target || '/' || $region || '/full/0/default.jpg'
    let $graphic.target.full := $graphic.target || '/full/full/0/default.jpg'
    
    let $annotation := iiif:getIiifAnnotation($document.id, $zone/@xml:id, $canvas.uri, $xywh, $manifest.uri, $zone.target.label, $graphic.target.id)
    
    return $annotation
    
return map {
    '@context': $file.context,
    '@type': $file.type,
    '@id': $document.uri,
    'resources': array {
        $zones
    }
}

xquery version "3.1";

(:
    get-manifest.json.xql

    This xQuery retrieves a IIIF annotation list with the measure zones on the given page
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
let $file := $database//mei:mei[@xml:id = $document.id]
let $canvas := $file//mei:surface[@xml:id = $canvas.id]

let $annotation.uri.base := $config:iiif-basepath || '/document/' || $document.id || '/annotation/'
let $document.uri := $config:iiif-basepath || '/document/' || $document.id || '/list/' || $canvas.id || '_zones'
let $canvas.uri := $config:iiif-basepath || '/document/' || $document.id || '/canvas/' || $canvas.id
let $manifest.uri := $config:iiif-basepath || '/document/' || $document.id || '/manifest.json'

(: build variable for file:)
let $file.context := 'http://iiif.io/api/presentation/2/context.json'
let $file.type := 'sc:AnnotationList'
let $canvas.label := 
    if($canvas/@label)
    then($canvas/string(@label))
    else if($canvas/@n)
    then($canvas/string(@n))
    else(string(count($canvas/preceding::mei:surface) + 1))
let $file.label := 'measure positions on page ' || $canvas.label || ' of ' || normalize-space(string-join($file//mei:fileDesc/mei:titleStmt/mei:composer//text(),' ')) || ': ' ||  string-join($file//mei:fileDesc/mei:titleStmt/mei:title//normalize-space(text()),' / ')

let $zone.ids := for $zone.id in $canvas//mei:zone/@xml:id return '#' || $zone.id
let $referencing.elements := $file//mei:*[@facs][@facs = $zone.ids]
let $references := $canvas//mei:zone/substring-after(@data,'#')
let $referenced.elements := for $reference in $references return $file/root()/id($reference)

let $zones := 
    for $zone in $canvas//mei:zone[@xml:id]
    let $zone.target :=
        if($zone/@data)
        then($referenced.elements[@xml:id = substring-after($zone/@data,'#')])
        else if($referencing.elements[@facs = '#' || $zone/@xml:id])
        then($referencing.elements[@facs = '#' || $zone/@xml:id])
        else()
    where exists($zone.target) and $zone.target/@xml:id
    let $zone.target.label := 
        if($zone.target/@label)
        then(local-name($zone.target) || ' ' || $zone.target/string(@label))
        else if($zone.target/@n)
        then(local-name($zone.target) || ' ' || $zone.target/string(@n))
        else(local-name($zone.target) || ' ' || string($zone.target/@xml:id))
    
    let $x := xs:integer($zone/@ulx)
    let $y := xs:integer($zone/@uly)
    let $w := xs:integer($zone/@lrx) - $x
    let $h := xs:integer($zone/@lry) - $y
    
    let $xywh := '#xywh=' || $x || ',' || $y || ',' || $w ||',' || $h
    let $region := $x || ',' || $y || ',' || $w || ',' || $h 
    
    let $graphic := $canvas/mei:graphic[@target and starts-with(@target,'http')]
    let $graphic.target := $graphic/string(@target)
    let $graphic.target.id := $graphic.target || '/' || $region || '/full/0/default.jpg'
    let $graphic.target.full := $graphic.target || '/full/full/0/default.jpg'
    
    return map {
        '@id': $annotation.uri.base || $zone/@xml:id,
        '@type': 'oa:Annotation',
        'motivation': 'oa:commenting',
        'on': map {
            '@type': 'oa:SpecificResource',
            'full': $canvas.uri,
            'selector': map {
                '@type': 'oa:FragmentSelector',
                'value': substring($xywh,2)
            },
            'within': map {
                '@id': $manifest.uri,
                '@type': 'sc:Manifest'
            }
        },
        'resource': map {
            '@type': 'dytypes:Text',
            'chars': $zone.target.label,
            'format': 'text/html'
        }
    }  
    
    (:{
            "@context": "http://iiif.io/api/presentation/2/context.json",
            "@id": "https://iiif.harvardartmuseums.org/annotations/76409",
            "@type": "oa:Annotation",
            "motivation": [
                "oa:commenting"
            ],
            "on": {
                "@type": "oa:SpecificResource",
                "full": "https://iiif.harvardartmuseums.org/manifests/object/299843/canvas/canvas-47174896",
                "selector": {
                    "@type": "oa:FragmentSelector",
                    "value": "xywh=451,421,1018,1187"
                },
                "within": {
                    "@id": "https://iiif.harvardartmuseums.org/manifests/object/299843",
                    "@type": "sc:Manifest"
                }
            },
            "resource": [
                {
                    "@type": "dctypes:Text",
                    "chars": "<p>surprise: VERY_UNLIKELY<br/>anger: VERY_UNLIKELY<br/>sorrow: VERY_UNLIKELY<br/>joy: VERY_UNLIKELY<br/>headwear: VERY_UNLIKELY<br/>blurred: VERY_UNLIKELY</p><p>Generated by Google Vision</p>",
                    "format": "text/html"
                }
            ]
        }:)

return map {
    '@context': $file.context,
    '@type': $file.type,
    '@id': $document.uri,
    'resources': array {
        $zones
    }
}

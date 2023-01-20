xquery version "3.1";

(:
    get_shapes_for_object_as_JSON.xql
    
    This xQuery …
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
       
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

let $edition.id := request:get-parameter('edition.id','')
let $object.id := request:get-parameter('object.id','')

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]
let $object := $doc/id($object.id)
let $hasFacs := (exists($object) and $object/@facs)
let $facsTokens := tokenize(replace($object/@facs,'#',''),' ')
let $zoneIDs := $doc//mei:zone/string(@xml:id)
let $shapes := 
    if($hasFacs)
    then(
        for $shape in $facsTokens
        where not($shape = $zoneIDs)
        return $shape
    ) else() 
    
let $zones := $doc//mei:zone[@xml:id = $facsTokens]
let $dimensions := 
    if(count($zones) gt 0)
    then(
        let $ulx := min($zones/number(@ulx))
        let $uly := min($zones/number(@uly))
        let $lrx := max($zones/number(@lrx))
        let $lry := max($zones/number(@lry))
        return map {
            'ulx': $ulx,
            'uly': $uly,
            'lrx': $lrx,
            'lry': $lry,
            'width': $lrx - $ulx,
            'height': $lry - $uly
        }
    )
    else()
    
let $map := 
    if (count($zones) gt 0) 
    then (
        map {
            'shapes': array { $shapes },
            'dimensions': $dimensions
        }
    )
    else ( 
        map {
            'shapes': array { $shapes }
        }
    )

return $map
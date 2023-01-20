xquery version "3.1";

(:
    get_geneticStatesList_as_JSON.xql
    
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

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]

let $sources :=
    for $facsimile in $doc//mei:facsimile
    let $source.id := replace($facsimile/@source,'#','')
    let $source.label := $doc/id($source.id)//mei:title[@type = 'siglum']/normalize-space(text())
    let $pages := 
        for $surface in $facsimile/mei:surface
        let $surface.id := $surface/string(@xml:id)
        let $label := $surface/string(@label)
        let $n := $surface/string(@n)
        let $width := $surface/mei:graphic[@type = 'iiif']/xs:integer(@width)
        let $height := $surface/mei:graphic[@type = 'iiif']/xs:integer(@height)
        let $folium := ($doc/id($source.id)//mei:folium[(@recto = '#' || $surface.id) or (@verso = '#' || $surface.id)])[1]
        let $mmWidth := $folium/xs:integer(@width)
        let $mmHeight := $folium/xs:integer(@height)
        let $position := if($folium/@verso = '#' || $surface.id) then('v') else('r')
        let $uri := $surface/mei:graphic[@type = 'iiif']/string(@target)
        let $type := 'iiif'
        let $shapes.id := 
            if(contains($surface/mei:graphic[@type = 'shapes']/@target,'#')) 
            then(substring-after($surface/mei:graphic[@type = 'shapes']/@target,'#')) 
            else($surface/mei:graphic[@type = 'shapes']/string(@target))
            
        let $page.id := 
            if(contains($surface/mei:graphic[@type = 'page']/@target,'#')) 
            then(substring-after($surface/mei:graphic[@type = 'page']/@target,'#')) 
            else($surface/mei:graphic[@type = 'page']/string(@target))
            
        let $measures := 
            for $measure.zone in $surface/mei:zone[@type = 'measure']
            let $zone.id := $measure.zone/string(@xml:id)
            let $x := $measure.zone/xs:integer(@ulx)
            let $y := $measure.zone/xs:integer(@uly)
            let $width := number($measure.zone/@lrx) - number($measure.zone/@ulx)
            let $height := number($measure.zone/@lry) - number($measure.zone/@uly)
            let $measure := ($doc//mei:measure[$zone.id = tokenize(replace(@facs,'#',''),' ')] | $doc/id($measure.zone/replace(@data,'#','')))
            let $measure.id := $measure/string(@xml:id)
            let $measure.label := $measure/string(@label)
            let $measure.n := $measure/string(@n)
            return map {
                'id': $measure.id,
                'label': $measure.label,
                'exists': exists($measure),
                'n': $n,
                'x': $x,
                'y': $y,
                'width': $width,
                'height': $height,
                'zone': $zone.id
            }
        return map {
            'id': $surface.id,
            'label': $label,
            'n': $n,
            'width': $width,
            'height': $height,
            'mmWidth': $mmWidth,
            'mmHeight': $mmHeight,
            'pos': $position,
            'uri': $uri,
            'type': $type,
            'shapes': $shapes.id,
            'page': $page.id,
            'measures': array { $measures }
        }
    return map {
        'id': $source.id,
        'label': $source.label,
        'pages': array { $pages }
    }

let $maxMmWidth := max($doc//mei:folium/number(@width))
let $maxMmHeight := max($doc//mei:folium/number(@height))

return map {
    'edition': $edition.id,
    'maxDimensions': map {
        'width': $maxMmWidth,
        'height': $maxMmHeight
    },
    'sources': array { $sources }
}
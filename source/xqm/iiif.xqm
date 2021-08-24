xquery version "3.1";

module namespace iiif="https://edirom.de/iiif";

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "./config.xqm";


declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace tools="http://edirom.de/ns/tools";
declare namespace ft="http://exist-db.org/xquery/lucene";

declare function iiif:getRectangle($file as node(),$elements as node()*,$boundingRect as xs:boolean) as map(*)* {

    (: todo: this needs to move down – some files have more than one facsimile… :)
    let $document.id := $file/@xml:id
    let $manifest.uri := $config:iiif-basepath || 'document/' || $document.id || '/manifest.json'

    let $maps :=
        if(count($elements) = 0)
        then()
        (: all requested elements are mei:zones :)
        else if (every $element in $elements satisfies local-name($element) = 'zone')
        then (
            let $zones := $elements[@xml:id]
            let $zone.ids := for $zone in $elements return '#' || $zone/@xml:id

            (: these are notes / measures / etc., which reference the current set of zones, i.e. a connection through @facs :)
            (:let $referencing.elements := $file//mei:*[@facs][some $facs in tokenize(normalize-space(@facs),' ') satisfies $facs = $zone.ids]:)

            let $referencing.elements :=
                for $zone.id in $zone.ids
                let $measures := $file//mei:measure/@facs[ft:query(.,$zone.id)]/parent::node()
                let $staves := $file//mei:staff/@facs[ft:query(.,$zone.id)]/parent::node()
                return ($measures, $staves)

            let $references := for $zone in $zones return tokenize(normalize-space(replace($zone/@data,'#','')),' ')
            (: these are notes / measures / etc., which are references from the current set of zones, i.e. a connection through @data :)
            let $referenced.elements := for $reference in $references return $file/root()/id($reference)

            let $rects :=
                (: a single bounding box (per page) shall be returned :)
                if ($boundingRect = true())
                then(
                    let $canvas.ids := distinct-values($zones/ancestor::mei:surface/@xml:id)
                    let $canvases :=
                        for $canvas.id in $canvas.ids
                        let $canvas.uri := $config:iiif-basepath || 'document/' || $document.id || '/canvas/' || $canvas.id
                        let $canvas := $file//mei:surface[@xml:id = $canvas.id]
                        let $relevant.zones := $zones[ancestor::mei:surface/@xml:id = $canvas.id]
                        let $relevant.zone.ids := for $zone in $relevant.zones return '#' || $zone/@xml:id
                        let $relevant.referencing.elements := $referencing.elements[some $facs in tokenize(normalize-space(@facs),' ') satisfies $facs = $relevant.zone.ids]
                        let $relevant.references := for $zone in $relevant.zones return tokenize(normalize-space(replace($zone/@data,'#','')),' ')
                        let $relevant.referenced.elements := for $reference in $relevant.references return $file/root()/id($reference)

                        let $group.label := 'zones on p.' || $canvas/@n

                        let $region := iiif:getRegion($relevant.zones)
                        let $xywh := iiif:getXywh($region)

                        let $graphic := $canvas/mei:graphic[@target and starts-with(@target,'http')]
                        let $graphic.target := $graphic/string(@target)
                        let $graphic.target.id := $graphic.target || '/' || $region || '/full/0/default.jpg'
                        let $graphic.target.full := $graphic.target || '/full/full/0/default.jpg'

                        return iiif:getIiifAnnotation($file/string(@xml:id), $elements[1]/string(@xml:id), $canvas.uri, $xywh, $manifest.uri, $group.label, $graphic.target.id)

                    return $canvases
                )
                (: individual boxes are returned :)
                else(
                    for $zone in $zones
                    let $canvas.uri := $config:iiif-basepath || 'document/' || $document.id || '/canvas/' || $zone/ancestor::mei:surface/@xml:id
                    let $zone.target :=
                        if($zone/@data)
                        then($referenced.elements[@xml:id = substring-after($zone/@data,'#')])
                        else if($referencing.elements[@facs = '#' || $zone/@xml:id])
                        then($referencing.elements[@facs = '#' || $zone/@xml:id])
                        else()
                    where exists($zone.target) and $zone.target/@xml:id
                    let $zone.target.label := iiif:getLabel($zone, true())

                    let $region := iiif:getRegion($zone)
                    let $xywh := iiif:getXywh($region)

                    let $graphic := $zone/ancestor::mei:surface/mei:graphic[@target and starts-with(@target,'http')]
                    let $graphic.target := $graphic/string(@target)
                    let $graphic.target.id := $graphic.target || '/' || $region || '/full/0/default.jpg'
                    let $graphic.target.full := $graphic.target || '/full/full/0/default.jpg'

                    return iiif:getIiifAnnotation($file/string(@xml:id), $zone/string(@xml:id), $canvas.uri, $xywh, $manifest.uri, $zone.target.label, $graphic.target.id)

                )
            return $rects

        )
        else if (every $element in $elements satisfies local-name($element) = 'measure')
        then (

            let $measures := $elements[@xml:id]
            let $measure.ids := for $measure in $measures return '#' || $measure/string(@xml:id)

            (: these are zones which reference the current set of measures, i.e. a connection through @data :)
            let $referencing.zones := $file//mei:zone[@data][some $data in tokenize(normalize-space(@data),' ') satisfies $data = $measure.ids]
            let $references := for $measure in $measures return tokenize(normalize-space(replace($measure/@facs,'#','')),' ')
            (: these are zones which are referenced from the current set of measures, i.e. a connection through @facs :)
            let $referenced.zones := for $reference in $references return $file/root()/id($reference)

            let $zones := ($referenced.zones | $referencing.zones)

            let $rects :=
                (: a single bounding box (per page) shall be returned :)
                if ($boundingRect = true())
                then(
                    let $canvas.ids := distinct-values($zones/ancestor::mei:surface/@xml:id)
                    let $canvases :=
                        for $canvas.id in $canvas.ids
                        let $canvas.uri := $config:iiif-basepath || 'document/' || $document.id || '/canvas/' || $canvas.id
                        let $canvas := $file//mei:surface[@xml:id = $canvas.id]
                        let $relevant.zones := $zones[ancestor::mei:surface/@xml:id = $canvas.id]
                        (:let $relevant.zone.ids := for $zone in $relevant.zones return '#' || $zone/@xml:id
                        let $relevant.referencing.zones := $referencing.zones[some $data in tokenize(normalize-space(@data),' ') satisfies $data = $relevant.zone.ids]
                        let $relevant.references := for $zone in $relevant.zones return tokenize(normalize-space(replace($zone/@data,'#','')),' ')
                        let $relevant.referencing.elements := for $reference in $relevant.references return $file/root()/id($reference)
                        :)
                        let $group.label := 'zones on p.' || $canvas/@n

                        let $region := iiif:getRegion($relevant.zones)
                        let $xywh := iiif:getXywh($region)

                        let $graphic := $canvas/mei:graphic[@target and starts-with(@target,'http')]
                        let $graphic.target := $graphic/string(@target)
                        let $graphic.target.id := $graphic.target || '/' || $region || '/full/0/default.jpg'
                        let $graphic.target.full := $graphic.target || '/full/full/0/default.jpg'

                        return iiif:getIiifAnnotation($file/string(@xml:id), $elements[1]/string(@xml:id), $canvas.uri, $xywh, $manifest.uri, $group.label, $graphic.target.id)

                    return $canvases
                )
                (: individual boxes are returned :)
                else(
                    for $zone in $zones
                    let $canvas.uri := $config:iiif-basepath || 'document/' || $document.id || '/canvas/' || $zone/ancestor::mei:surface/@xml:id
                    let $zone.target :=
                        if($zone/@data)
                        then($measures[@xml:id = substring-after($zone/@data,'#')])
                        else if($measures[some $token in tokenize(normalize-space(replace(@facs,'#','')),' ') satisfies $token = $zones/@xml:id])
                        then($measures[some $token in tokenize(normalize-space(replace(@facs,'#','')),' ') satisfies $token = $zones/@xml:id])
                        else()
                    where exists($zone.target) and $zone.target/@xml:id
                    let $zone.target.label := iiif:getLabel($zone, true())

                    let $region := iiif:getRegion($zone)
                    let $xywh := iiif:getXywh($region)

                    let $graphic := $zone/ancestor::mei:surface/mei:graphic[@target and starts-with(@target,'http')]
                    let $graphic.target := $graphic/string(@target)
                    let $graphic.target.id := $graphic.target || '/' || $region || '/full/0/default.jpg'
                    let $graphic.target.full := $graphic.target || '/full/full/0/default.jpg'

                    return iiif:getIiifAnnotation($file/string(@xml:id), $zone/string(@xml:id), $canvas.uri, $xywh, $manifest.uri, $zone.target.label, $graphic.target.id)

                )
            return $rects
        )
        else if (every $element in $elements satisfies local-name($element) = 'staff')
        then (

        )
        else (
        )

    return $maps
};

declare function iiif:getIiifAnnotation($file.id as xs:string, $annot.id as xs:string, $canvas.uri as xs:string, $xywh as xs:string, $manifest.uri as xs:string, $label as xs:string, $preview.uri as xs:string) as map(*) {

    let $annotation.uri.base := $config:iiif-basepath || 'document/' || $file.id || '/annotation/'

    return map {
        '@context': 'http://iiif.io/api/presentation/2/context.json',
        '@id': $annotation.uri.base || $annot.id,
        '@type': 'oa:Annotation',
        'motivation': array { 'oa:commenting' },
        'on': map {
            '@type': 'oa:SpecificResource',
            'full': $canvas.uri,
            'selector': map {
                '@type': 'oa:FragmentSelector',
                'value': $xywh
            },
            'within': map {
                '@id': $manifest.uri,
                '@type': 'sc:Manifest'
            }
        },
        'resource': map {
            '@type': 'dctypes:Text',
            'chars': $label,
            'format': 'text/html'
        },
        'target': map {
            'source' : $canvas.uri,
            'type' : 'dctypes:Image',
            'selector' : array {
                map {
                   'type' : 'ImageSelector',
                   '@id' : $preview.uri
                }
            }
        }
    }
};

declare function iiif:getImageResource($width as xs:integer, $height as xs:integer, $url as xs:string) as map(*) {
    map {
        '@id': $url || '/full/full/0/default.jpg',
        '@type': 'dctypes:Image',
        'service': map {
          '@context': 'http://iiif.io/api/image/2/context.json',
          '@id': $url,
          'profile': 'http://iiif.io/api/image/2/level2.json'
        },
        'format': 'image/jpeg',
        'width': $width,
        'height': $height
    }
};

declare function iiif:getLabel($elem as element(), $withLocalName as xs:boolean) as xs:string {
    let $label :=
        if($withLocalName and $elem/@label)
        then(local-name($elem) || ' ' || $elem/string(@label))
        else if(not($withLocalName) and $elem/@label)
        then($elem/string(@label))
        else if($withLocalName and $elem/@n)
        then(local-name($elem) || ' ' || $elem/string(@n))
        else if(not($withLocalName) and $elem/@n)
        then($elem/string(@n))
        else if($withLocalName)
        then(local-name($elem) || ' ' || string($elem/@xml:id))
        else(string($elem/@xml:id))
    return $label
};

declare function iiif:getRegion($zones as element()+) as xs:string {
    let $x := min($zones/xs:integer(@ulx))
    let $y := min($zones/xs:integer(@uly))
    let $x2 := max($zones/xs:integer(@lrx))
    let $y2 := max($zones/xs:integer(@lry))
    let $w := $x2 - $x
    let $h := $y2 - $y

    return $x || ',' || $y || ',' || $w || ',' || $h
};

declare function iiif:getXywh($region as xs:string) as xs:string {
    let $xywh := 'xywh=' || $region
    return $xywh
};

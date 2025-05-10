xquery version "3.1";

import module namespace bw="http://www.beethovens-werkstatt.de/ns/xqm" at "../../xqm/bw_main.xqm";

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

declare function mei:getPages($pageRef as attribute(), $doc as node()) as map(*) {
    let $folium := $pageRef/parent::mei:*
    let $enterState := $folium/parent::mei:add/replace(@changeState,'#','')
    let $exitState := $folium/parent::mei:del/replace(@changeState,'#','')
    let $page.added := if(exists($enterState)) then($enterState) else('')
    let $page.removed := if(exists($exitState)) then($exitState) else('')
    let $page.visible := if($pageRef/ancestor::mei:add) then('false') else('true')
    let $surface := $doc/id(replace($pageRef,'#','')) 
    let $facs.elem := $surface//mei:graphic[@type = 'iiif']
    
    let $page.id := $surface/string(@xml:id)
    let $page.label := $surface/string(@label)
    let $page.n := $surface/string(@n)
    let $page.type := if(contains(local-name($pageRef),'recto')) then('recto') else('verso')
    let $page.width.px := $facs.elem/xs:integer(@width)
    let $page.height.px := $facs.elem/xs:integer(@height)
    
    let $page.width.mm := $folium/xs:integer(@width)
    let $page.height.mm := $folium/xs:integer(@height)
    
    let $dpm := number($page.width.px) div number($page.width.mm) 
    
    let $page.facsRef := $facs.elem/string(@target)
    let $page.pageRef := $surface/mei:graphic[@type = 'page']/string(@target)
    let $page.shapesRef := $surface/mei:graphic[@type = 'shapes']/string(@target)
    
    let $measures := 
        for $zone in $surface//mei:zone[@type = 'measure' and @data and string-length(@data) gt 1]
        let $measure := $doc/id($zone/replace(@data,'#',''))
        return map {
            'id': $measure/string(@xml:id),
            'zone': $zone/string(@xml:id),
            'n': $measure/string(@n),
            'label': $measure/string(@label),
            'ulx': $zone/xs:integer(@ulx),
            'uly': $zone/xs:integer(@uly),
            'lrx': $zone/xs:integer(@lrx),
            'lry': $zone/xs:integer(@lry),
            'width': $zone/number(@lrx) - $zone/number(@ulx),
            'height': $zone/number(@lry) - $zone/number(@uly)
        }
    
    let $patches :=
        for $patch in $folium//mei:patch
        let $patch.id := $patch/string(@xml:id)
        let $attached.to := $patch/string(@attached.to)
        let $attached.by := $patch/string(@attached.by)
        let $enterState := $patch/parent::mei:add/replace(@changeState,'#','')
        let $isAdded := exists($enterState)
        let $offX := $patch/xs:integer(@x)
        let $offY := $patch/xs:integer(@y)
        let $child.pages := 
            for $subPage in $patch//@*[local-name() = ('recto','verso','inner.recto','inner.verso','outer.recto','outer.verso')(: and ancestor::mei:patch[1]/@xml:id = $patch.id:)]
            return mei:getPages($subPage, $doc)(: '"' || string($subPage) || '"':)
        
        return map {
            'id': $patch.id,
            'attachedTo': $attached.to,
            'attachedBy': $attached.by,
            'isAdded': $isAdded,
            'enterState': $enterState,
            'offsetX': $offX,
            'offsetY': $offY,
            'pages': array { $child.pages }
        }
    
    return map {
        'id': $page.id,
        'dpm': $dpm,
        'label': $page.label,
        'visible': $page.visible,
        'added': $page.added,
        'removed': $page.removed,
        'type': $page.type,
        'width_px': $page.width.px,
        'height_px': $page.height.px,
        'width_mm': $page.width.mm,
        'height_mm': $page.height.mm,
        'facsRef': $page.facsRef,
        'pageRef': $page.pageRef,
        'shapesRef': $page.shapesRef,
        'measures': array { $measures },
        'patches': array { $patches }
    }
};

(:START OF PROCESSING:)

let $edition.id := request:get-parameter('edition.id','')
let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]

let $scars := 
    for $scar in $doc//mei:genDesc[@type = 'textualScar']
    let $scar.id := $scar/string(@xml:id)
    let $scar.label := $scar/string(@label)
    let $scar.ordered := if($scar/@ordered = 'true') then(true()) else(false())
    let $state.ids := $scar//mei:state/concat('#',@xml:id)
    
    let $affected.staves := distinct-values($doc//mei:staff[.//mei:*[@changeState = $state.ids]]/string(@n))
    let $is.complete := count($affected.staves) = 0 or $doc//mei:*[@changeState = $state.ids]//mei:measure
    
    let $all.elements.in.scar := bw:getElementsWithinScar($doc,$scar.id)
    
    let $enriched.doc := bw:getEnrichedFile($doc)
    
    let $states := bw:getStatesJson($scar, $enriched.doc)
        
    return map {
        'id': $scar.id,
        'label': $scar.label,
        'ordered': $scar.ordered,
        'complete': $is.complete,
        'staves': array { $affected.staves },
        'states': array { $states }
    }

let $sources := 
    for $source in $doc//mei:source
    let $source.id := $source/string(@xml:id)
    let $source.label := normalize-space($source/mei:titleStmt/mei:title[@type = 'siglum']/text())
    let $source.desc := normalize-space($source/mei:titleStmt/mei:title[2]/text())
    let $pages := 
        for $pageRef in $source//mei:foliumSetup//@*[local-name() = ('recto','verso','inner.recto','inner.verso','outer.recto','outer.verso') and not(ancestor::mei:patch)]
        return mei:getPages($pageRef, $doc)
        
    return map {
        'id': $source.id,
        'label': $source.label,
        'desc': $source.desc,
        'pages': array { $pages }
    }

let $maxMmWidth := max($doc//mei:folium/number(@width))
let $maxMmHeight := max($doc//mei:folium/number(@height))

return map {
    'id': $edition.id,
    'scars': array { $scars },
    'sources': array { $sources },
    'maxDimensions': map {
        'width': $maxMmWidth,
        'height': $maxMmHeight
    }
}
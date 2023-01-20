xquery version "3.1";

(:
    get_geneticStatesList_as_JSON.xql
    
    This xQuery …
:)

import module namespace bw="http://www.beethovens-werkstatt.de/ns/xqm" at "../../xqm/bw_main.xqm";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace svg = "http://www.w3.org/2000/svg";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace transform = "http://exist-db.org/xquery/transform";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
       
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

let $edition.id := request:get-parameter('edition.id', '')

(:PROCESSING STARTS HERE:)

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]

let $final.measures := $doc//mei:score//mei:measure[not(ancestor::mei:del) or (count(ancestor::mei:restore) ge count(ancestor::mei:del))]

let $scars :=
    for $scar in $doc//mei:genDesc[@type = 'textualScar']
    let $scar.id := $scar/string(@xml:id)
    
    let $affected.measures :=
        for $state in $scar/mei:state
        let $state.ref := '#' || $state/string(@xml:id)
        let $mods := $doc//mei:*[@changeState = $state.ref]
        let $measure.ids := ($mods/ancestor::mei:measure/@xml:id | $mods/descendant::mei:measure/@xml:id)
        let $measures :=
            for $measure.id in distinct-values($measure.ids)
            return
                $doc/id($measure.id)
        return
            $measures
            
    
    
    let $scar.label := 
        if(count($affected.measures/descendant-or-self::mei:measure) gt 1)
        then(concat(($affected.measures)[1]/@label,' – ',($affected.measures)[last()]/@label))
        else(($affected.measures)[1]/@label)
    let $scar.ordered := 
        if ($scar/@ordered) 
        then($scar/xs:boolean(@ordered))
        else(false())
    
    let $state.ids := $scar//mei:state/concat('#',@xml:id)
        
    let $affected.staves := $doc//mei:staff[.//mei:*[@changeState = $state.ids]]/string(@n)
    let $is.complete := if(count($affected.staves) = 0 or $doc//mei:*[@changeState = $state.ids]//mei:measure) then('true') else('false')
    
    let $first.measure :=
        if (some $measure in $affected.measures satisfies ($measure/@xml:id = $final.measures/@xml:id))
        then (($affected.measures[@xml:id = $final.measures/@xml:id])[1]/string(@xml:id))
        else ($final.measures[replace(@n,'[a-zA-Z]+','') = $affected.measures/replace(@n,'[a-zA-Z]+','')][1]/string(@xml:id))
        
    let $order.index := number($doc/id($first.measure)/replace(@n,'[a-zA-Z]+','')) 
    
    let $categories := tokenize(replace($scar/@decls, '#', ''), ' ')
    
    let $enriched.doc := bw:getEnrichedFile($doc)
    
    let $all.elements.in.scar := $enriched.doc//mei:*[@facs][@add = $scar//mei:state/@xml:id]
    
    let $affected.elems := 
        for $elem in $all.elements.in.scar[@xml:id][not(local-name() = 'measure')](:[not(ancestor::mei:*[@xml:id = $all.elements.in.scar/@xml:id])]:)
        let $note := 
            if ($elem/ancestor::mei:note)
            then
                ($elem/ancestor::mei:note)
            else
                ($elem)
        return
            $note/string(@xml:id)
   
    
    let $states := bw:getStatesJson($scar, $enriched.doc)
        
    order by number($order.index)
        
    return map {
        'id': $scar.id,
        'label': $scar.label,
        'ordered': $scar.ordered,
        'firstMeasure': $first.measure,
        'complete': $is.complete,
        'staves': array { $affected.staves },
        'affectedMeasures': array { distinct-values($affected.measures/string(@xml:id)) },
        'affectedNotes': array { $affected.elems },
        'states': array { $states },
        'categories': array { $categories }
    }
    
return array { $scars }
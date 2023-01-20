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

let $staves := 
    for $staff in ($doc//mei:scoreDef)[1]//mei:staffDef
    let $n := $staff/string(@n)
    let $label := if($staff/@label) then($staff/string(@label)) else($staff/ancestor::mei:staffGrp[@label][1]/string(@label))
    return map {
        'n': $n,
        'label': $label
    }

let $all.scars := 
    for $scar in $doc//mei:genDesc[@type = 'textualScar']
    let $state.ids := $scar//mei:state/concat('#',@xml:id)
    let $changed.above.measures := $doc//mei:*[@changeState = $state.ids]//mei:measure
    let $measure.xml := 
        for $measure in $changed.above.measures
        let $measure.id := $measure/string(@xml:id)
        return
            <measure scar.id="{$scar/@xml:id}" complete="true" measure.id="{$measure.id}" staves=""/>
    let $changed.inside.measures := $doc//mei:measure[.//mei:*[@changeState = $state.ids]]
    let $staff.xml :=
        for $measure in $changed.inside.measures
        let $measure.id := $measure/string(@xml:id)
        let $aff.staves := distinct-values($measure/mei:staff[.//mei:*[@changeState = $state.ids]]/string(@n))
        let $complete := count($staves) = count($aff.staves)
        return
            <measure scar.id="{$scar/@xml:id}" complete="{$complete}" measure.id="{$measure.id}" staves="{string-join($aff.staves,',')}"/>
    
    let $combined.xml := ($measure.xml | $staff.xml)
    let $distinct.scars := distinct-values($combined.xml/descendant-or-self::measure/string(@scar.id))
    let $output :=
        for $scar.id in $doc//mei:genDesc[@type = 'textualScar']/string(@xml:id)
        let $ref := $combined.xml/descendant-or-self::measure[@scar.id = $scar.id][1]
        return $ref
        
    return
        $output
    
    
let $measures := 
    for $measure in ($doc//mei:score//mei:measure[count(ancestor::mei:del) le count(ancestor::mei:restore)])
    let $measure.id := $measure/string(@xml:id)
    let $measure.label := $measure/string(@label)
    let $measure.n := $measure/string(@n)
    let $refs.from.scars := $all.scars/descendant-or-self::measure[@measure.id = $measure.id]
    let $distinct.scars := distinct-values($refs.from.scars/descendant-or-self::measure/string(@scar.id))
    
    let $order.num :=
        if(string-length($measure.n) gt 0)
        then(number(replace($measure.n,'[a-zA-Z ]+','')))
        else(number(replace($measure.label,'[a-zA-Z ]+','')))
    
    let $first.refs := 
        for $ref in $distinct.scars
        let $first.refs := $refs.from.scars/descendant-or-self::measure[@scar.id = $ref]
        return $first.refs[1]
        
    let $refs := 
        for $scar in $first.refs
        let $complete := $scar/@complete ="true"
        return map {
            'scar': $scar/@scar.id,
            'complete': $complete,
            'staves': array { $scar/@staves }
        }
    
    order by $order.num
    return map {
        'id': $measure.id,
        'label': $measure.label,
        'n': $measure.n,
        'scars': array { $refs }
    }

let $scars :=
    for $scar in $doc//mei:genDesc[@type = 'textualScar']
    let $scar.id := $scar/string(@xml:id)
    let $categories :=$scar/tokenize(replace(@decls,'#',''),' ')
    let $state.ids := $scar//mei:state/concat('#',@xml:id)
    let $affected.staves := distinct-values($doc//mei:staff[.//mei:*[@changeState = $state.ids]]/string(@n))
    let $is.complete := count($affected.staves) = 0 or $doc//mei:*[@changeState = $state.ids]//mei:measure
    
    return map {
        'id': $scar.id,
        'complete': $is.complete,
        'staves': array { $affected.staves },
        'categories': array { $categories } 
    }
return map {
    'edition': $edition.id,
    'staves': array { $staves },
    'measures': array { $measures },
    'scars': array { $scars }
}
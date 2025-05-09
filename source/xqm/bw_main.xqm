xquery version "3.1";

module namespace bw = "http://www.beethovens-werkstatt.de/ns/xqm";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace svg = "http://www.w3.org/2000/svg";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace transform = "http://exist-db.org/xquery/transform";

declare function bw:getPosition($states as node()+, $follows as xs:string*, $prev as xs:string*, $position as xs:integer, $scar.ordered as xs:boolean) as xs:integer {
    let $preceding.states := $states[@xml:id = ($follows, $prev)]
    let $positions :=
        for $state in $preceding.states
        let $state.follows :=
            for $otherState in $states[@xml:id != $state/@xml:id]
            where ($otherState/@xml:id = tokenize($state/replace(@follows, '#', ''), ' ')
                or $state/@xml:id = tokenize($otherState/replace(@precedes, '#', ''), ' '))
            return
                $otherState/@xml:id
        
        let $state.prev :=
            for $otherState in $states[@xml:id != $state/@xml:id]
            where ($otherState/@xml:id = tokenize($state/replace(@prev, '#', ''), ' ')
                or $state/@xml:id = tokenize($otherState/replace(@next, '#', ''), ' ')
                or $scar.ordered = true() and $otherState/following-sibling::mei:state[1]/@xml:id = $state/@xml:id)
            return
                $otherState/@xml:id
        
        let $state.position := bw:getPosition($states, $state.follows, $state.prev, $position + 1, $scar.ordered)
        return $state.position
        
    let $result :=
        if(count($positions) gt 0)
        then(max($positions))
        else($position)
        
    return
        $result
};

declare function bw:getStatesJson($scar as node(), $enriched.doc as node()) as map(*)* {
    
    let $scar.ordered := 
        if ($scar/@ordered) 
        then($scar/@ordered)
        else(false())
    
    for $state in $scar/mei:state
    let $state.id := $state/string(@xml:id)
    let $state.label := $state/string(@label)
    let $open := '#bwTerm_openVariant' = tokenize($state/@decls, ' ')
    let $isDeletionOnly := '#bwTerm_deletion' = tokenize($state/@decls, ' ')
        
    let $index := count($state/preceding-sibling::mei:state) + 1

    let $precedes :=
        for $otherState in $scar/mei:state[@xml:id != $state.id]
        where ($otherState/@xml:id = tokenize($state/replace(@precedes, '#', ''), ' ')
            or $state.id = tokenize($otherState/replace(@follows, '#', ''), ' '))
        return
            $otherState/string(@xml:id)

    let $follows :=
        for $otherState in $scar/mei:state[@xml:id != $state.id]
        where ($otherState/@xml:id = tokenize($state/replace(@follows, '#', ''), ' ')
            or $state.id = tokenize($otherState/replace(@precedes, '#', ''), ' '))
        return
            $otherState/string(@xml:id)

    let $next :=
        for $otherState in $scar/mei:state[@xml:id != $state.id]
        where ($otherState/@xml:id = tokenize($state/replace(@next, '#', ''), ' ')
            or $state.id = tokenize($otherState/replace(@prev, '#', ''), ' ')
            or $scar.ordered = true() and $otherState/preceding-sibling::mei:state[1]/@xml:id = $state.id)
        return
            $otherState/string(@xml:id)

    let $prev :=
        for $otherState in $scar/mei:state[@xml:id != $state.id]
        where ($otherState/@xml:id = tokenize($state/replace(@prev, '#', ''), ' ')
            or $state.id = tokenize($otherState/replace(@next, '#', ''), ' ')
            or $scar.ordered = true() and $otherState/following-sibling::mei:state[1]/@xml:id = $state.id)
        return
            $otherState/string(@xml:id)

    
    let $elements := $enriched.doc//mei:*[@add = $state.id]
    let $element.shapes := distinct-values($elements/tokenize(normalize-space(replace(@facs,'#','')),' '))
    
    let $dels := $enriched.doc//mei:del[@changeState = concat('#',$state.id)]
    let $del.shapes := distinct-values($dels/tokenize(normalize-space(replace(@facs,'#','')),' '))
    
    let $adds := $enriched.doc//mei:add[@changeState = concat('#',$state.id)]
    let $add.shapes := distinct-values($adds/tokenize(normalize-space(replace(@facs,'#','')),' '))
    
    let $shapes := distinct-values(($element.shapes,$del.shapes,$add.shapes))
    
    let $transfers.add := 
        for $add in $enriched.doc//mei:foliumSetup//mei:add[@changeState = '#' || $state.id]
        let $target.source.id := $add/ancestor::mei:source/@xml:id
        let $del := if($add//@sameas) then($enriched.doc//mei:*[@xml:id = replace(($add//@sameas)[1],'#','')]) else()
        let $origin.source.id := if($del) then($del/ancestor::mei:source/@xml:id) else()
        let $transfered.surfaces := 
            for $surface in $add//@*[local-name() =('recto','verso','inner.recto','inner.verso','outer.recto','outer.verso')]
            return
                replace($surface,'#','')
        return map {
            'surfaces': array {$transfered.surfaces},
            'targetSource': $target.source.id,
            'originSource': $origin.source.id
        }
    
    let $position := bw:getPosition($scar/mei:state, $follows, $prev, 1, $scar.ordered)
    
    order by $position ascending

    return map {
        'id': $state.id,
        'label': $state.label,
        'open': $open,
        'deletion': $isDeletionOnly,
        'index': $index,
        'position': $position,
        'next': array { $next },
        'prev': array { $prev },
        'follows': array { $follows },
        'precedes': array { $precedes },
        'shapes': array { $shapes },
        'transfers': array { $transfers.add }
    }
};

declare function bw:getElementsWithinScar($doc as node(), $scar.id as xs:string) as node()* {
    
    let $scar := $doc/id($scar.id)
    let $state.ids := $scar//mei:state/concat('#',@xml:id)
    
    let $adds := $doc//mei:add[@changeState = $state.ids]
    
    let $elements :=
        for $add in $adds 
        let $add.id := $add/@xml:id
        let $added.elements := $add//mei:*[@facs and ancestor::mei:*[@changeState][1]/@xml:id = $add.id and not(@changeState)]
        
        return
            $added.elements
    
    return $elements
};

declare function bw:getEnrichedFile($doc as node()) as node() {
    let $xslPath := '../xslt/module1/' 

    let $xml := transform:transform($doc,
                   doc(concat($xslPath,'addStateInfo.xsl')), <parameters/>)
    return $xml
};
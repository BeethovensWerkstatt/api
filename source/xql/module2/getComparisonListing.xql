xquery version "3.1";

(:
    getComparisonListing.xql
    
    This xQuery …
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response"; 
declare namespace local="no:link";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:getStaves($mdiv as node()) as array(map(*)) {
    let $staves := 
        if($mdiv/mei:score)
        then(
            for $staffDef at $i in ($mdiv/mei:score/mei:scoreDef)[1]//mei:staffDef
            let $label := 
                if($staffDef/mei:label)
                then($staffDef/mei:label/text()) 
                else if($staffDef/parent::mei:staffGrp/mei:label)
                then($staffDef/parent::mei:staffGrp/mei:label/text())
                else($staffDef/string(@label))
            return map {
                'n': $i, 
                'label': normalize-space($label)
            }
            
        )
        else(
            for $staffDef at $i in $mdiv/mei:parts/mei:part/mei:scoreDef[1]//mei:staffDef
            let $label := 
                if($staffDef/mei:label)
                then($staffDef/mei:label/text())
                else if($staffDef/parent::mei:staffGrp/mei:label)
                then($staffDef/parent::mei:staffGrp/mei:label/text())
                else($staffDef/string(@label))
            return map {
                'n': $i,
                'label': normalize-space($label)
            }
        )
    return array { $staves }
};

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $data.basePath := '/db/apps/api/data/module2/'

let $comparisons := 
    for $comparison in collection($data.basePath)//mei:meiCorpus
    order by $comparison//mei:fileDesc/number(@n)
    let $comparison.id := $comparison/string(@xml:id)
    let $comparison.title := $comparison//mei:fileDesc/mei:titleStmt/mei:title[@type='main']/text()
    let $comparison.target := $comparison//mei:fileDesc/mei:titleStmt/mei:title[@type='target']/text()
    let $source1 := doc(document-uri($comparison/root()) || '/../' || $comparison//mei:source[1]/string(@target))
    let $source2 := doc(document-uri($comparison/root()) || '/../' || $comparison//mei:source[2]/string(@target))
    
    
    let $movements := 
        for $mdiv at $pos in $source1//mei:mdiv
        let $n := if($mdiv/@n) then($mdiv/string(@n)) else($pos)
        let $label := $mdiv/string(@label)
        let $new.label := $source2//mei:mdiv[@n = $n]/string(@label)
        let $old.staves := local:getStaves($mdiv)
        let $new.staves := local:getStaves($source2//mei:mdiv[@n = string($n)])
            (:string-join($source2//mei:mdiv[1]/@*/concat(local-name(),':',string(.)), ', '):)
            (:'"' || count($source2//mei:mdiv[@n = $n]) || ' at ' || $n || '"':)
        return map {
            'n': $n, 
            'label': $label, 
            'newLabel': $new.label,
            'staves': $old.staves, 
            'newStaves': $new.staves
        }
    
    return map {
        'id': $comparison.id,
        'title': $comparison.title,
        'target': $comparison.target,
        'movements': array { $movements }
    }

return array { $comparisons }

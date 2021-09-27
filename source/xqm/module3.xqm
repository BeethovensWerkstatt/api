xquery version "3.1";

module namespace module3="https://beethovens-werkstatt/ns/module3";

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "./config.xqm";
import module namespace ef="https://edirom.de/file" at "./file.xqm";
import module namespace iiif="https://edirom.de/iiif" at "./iiif.xqm";

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

declare function module3:getComplaintLink($file.id as xs:string, $complaint.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/complaints/' || $complaint.id || '.json'
    return $link
};

declare function module3:getMeasureLabel($measure as element(mei:measure)) as xs:string {
    let $label := if(count($measure//mei:mNum) = 1)
                  then(normalize-space(string-join($measure//mei:mNum//text(),' ')))
                  else if($measure/@label)
                  then($measure/string(@label))
                  else if($measure/@n)
                  then($measure/string(@n))
                  else(string(count($measure/preceding::mei:measure) + 1))
    return $label
};

declare function module3:getPageLabelBySurface($file as node(), $surfaceId as xs:string) as xs:string {
    
    let $surface := $file//mei:surface[@xml:id = $surfaceId]
    
    let $all.folia := $file//mei:folium
    let $all.bifolia := $file//mei:bifolium
    
    let $label := if($all.folia[@recto = '#' || $surface/@xml:id])
                  then($all.folia[@recto = '#' || $surface/@xml:id]/string(@n) || 'r')
                  else if($all.folia[@verso = '#' || $surface/@xml:id])
                  then($all.folia[@verso = '#' || $surface/@xml:id]/string(@n) || 'v')
                  else ($surface/string(@n))
    return string($label)
};

declare function module3:getEmbodiment($file.id as xs:string, $complaint as node(), $source.id as xs:string, $role as xs:string, $affected.measures as node()+, $affected.staves as xs:string*, $text.file as node(), $document.file as node(), $text.annot as node(), $doc.annot as node()) as map(*) {
    (: 
        allowed values for $role: 
        - 'ante'
        - 'post'
        - 'revision'
    :)
    let $work.uri := $config:module3-basepath || $file.id || '.json'
    
    let $file := $text.file/root()
    
    let $facsimile := $document.file//mei:facsimile
    let $data.targets := ($affected.measures/concat('#',@xml:id), $affected.measures/mei:staff[@n = $affected.staves]/concat('#',@xml:id))
    let $referencing.zones :=
        for $data.target in $data.targets
        return $facsimile//mei:zone/@data[ft:query(.,$data.target)]/parent::node()

    let $refs := ($affected.measures/tokenize(replace(normalize-space(@facs),'#',''),' '), $affected.measures/mei:staff/tokenize(replace(normalize-space(@facs),'#',''),' '))
    let $root := $document.file/root()
    let $referenced.zones := for $ref in $refs return $root/id($ref)[local-name() = 'zone']

    let $zones := ($referencing.zones,  $referenced.zones)
    
    let $state.id :=
        if ($role = 'ante')
        then (
            let $provided.state.id := $complaint/replace(normalize-space(@state),'#','')
            let $provided.state := $file/id($provided.state.id)

            (: TODO: the following needs to be more elaborate:)
            let $previous.state.id := $provided.state/preceding-sibling::mei:genState[1]/@xml:id
            return $previous.state.id
        )
        else (
            $complaint/replace(normalize-space(@state),'#','')
        )
    
    let $focus.link := 
        if($role = 'revision')
        then($complaint/string(@xml:id))
        else('')
    
    let $context := ef:getMeiByContextLink($file.id, $doc.annot/string(@xml:id), $focus.link, $source.id, $state.id)

    let $iiif := iiif:getRectangle($document.file, $zones, true()) (:map {
            'zones': count($zones),
            'dataTargets': count($data.targets),
            'refs': string-join($refs,' - '),
            'referencedZones': count($referenced.zones),
            'fileId': $file.id
        }:)

    let $measureLabels := array { for $measure in $affected.measures return module3:getMeasureLabel($measure) }
    
    let $all.pages.ids := distinct-values(for $zone in $zones return ($zone/ancestor::mei:surface/@xml:id))
    let $pageLabels := array { for $page.id in $all.pages.ids return module3:getPageLabelBySurface($document.file, $page.id) }
    
        
    return map {
        'work': $work.uri,
        'role': $role,
        'mei': $context,
        'iiif': array { $iiif },
        (:'test': map {
            'fileId': string($file.id),
            'focusLink': string($focus.link),
            'sourceId': string($source.id),
            'stateId': string($state.id),
            'hasFacs': count($file//mei:facsimile),
            'measures': string-join($affected.measures/string(@xml:id),', '),
            'complaintId': local-name($complaint) || ' - ' || $complaint/string(@xml:id),
            'textAnnotId': $text.annot/string(@xml:id),
            'docAnnotId': $doc.annot/string(@xml:id)
        },:)
        'labels': map {
            'source': replace($source.id,'_',' '),
            'measures': $measureLabels,
            'pages': $pageLabels
        }
    }
};

xquery version "3.1";

(:
    get-complaint.xql

    This xQuery retrieves relevant information about a single complaint ("Monitum") from the third module of Beethovens Werkstatt
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace iiif="https://edirom.de/iiif" at "../../xqm/iiif.xqm";
import module namespace ef="https://edirom.de/file" at "../../xqm/file.xqm";
import module namespace ema="https://github.com/music-addressability/ema/blob/master/docs/api.md" at "../../xqm/ema.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the ID of the requested complaint, as passed by the controller :)
let $complaint.id := request:get-parameter('complaint.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

let $annot := $file//mei:body//mei:annot[@xml:id = $complaint.id]
    
let $public.complaint.id := $config:module3-basepath || $document.id || '/complaints/' || $complaint.id || '.json'
let $mdiv := $annot/ancestor::mei:mdiv[@xml:id][1]
let $mdiv.id := $mdiv/string(@xml:id)
let $mdiv.n := 
    if($mdiv/@n)
    then($mdiv/string(@n))
    else(string(count($mdiv/preceding::mei:mdiv) + 1))
let $mdiv.label :=
    if($mdiv/@label)
    then($mdiv/string(@label))
    else if($mdiv/@n)
    then($mdiv/string(@n))
    else('(' || string(count($mdiv/preceding::mei:mdiv) + 1) || ')')
    
let $dependent.complaints := $file//mei:annot[@xml:id][@corresp = '#' || $complaint.id]

let $annot.ids := distinct-values(($complaint.id, $dependent.complaints/string(@xml:id)))[string-length(.) gt 0]

let $embodiments := 
    
    let $embodied.annots := $database//mei:annot[mei:relation[@rel = 'isEmbodimentOf'][some $annot.id in $annot.ids satisfies contains(@target,'#' || $annot.id)]]
    let $embodied.annot.ids := distinct-values($embodied.annots/string(@xml:id))
    let $manifestation.ids := distinct-values($embodied.annots/ancestor::*[local-name() = ('mei','TEI')]/@xml:id)
    for $manifestation.id in $manifestation.ids
        let $manifestation := ($database//mei:mei[@xml:id = $manifestation.id] | $database//tei:TEI[@xml:id = $manifestation.id])
        let $manifestation.namespace := namespace-uri($manifestation)
        let $manifestation.filename := tokenize(document-uri($manifestation/root()),'/')[last()] 
        let $manifestationRef := $file//mei:manifestation[@sameas ='./' || $manifestation.filename]
        let $label := $manifestationRef/string(@label)
        
        let $manifestation.classes := tokenize(normalize-space($manifestationRef/@class),' ')
        let $text.status := 
            if('#initialVersion' = $manifestation.classes)
            then('initialVersion')
            else if('#revisedVersion' = $manifestation.classes)
            then('revisedVersion')
            else if('#revisionList' = $manifestation.classes)
            then('revisionInstruction')
            else('unknown')
        
        let $relevant.annots := $embodied.annots[ancestor::*[local-name() = ('mei','TEI')][@xml:id = $manifestation.id]]
        
        
        let $affected.measures :=
            for $complaint in ($relevant.annots)
            
            let $first.measure := $complaint/ancestor::mei:measure
            
            (:how many additional measures do I need to pull?:)
            let $range := 
                if($complaint/@tstamp2 and matches($complaint/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($complaint/@tstamp2,'m')) gt 0)
                then(xs:integer(substring-before($complaint/@tstamp2,'m')))
                else(0)
            let $subsequent.measures :=
                if($range gt 0)
                then($first.measure/following::mei:measure[position() le $range])
                else()
                
            return ($first.measure | $subsequent.measures)
        
        let $doc.zones := $manifestation//mei:zone
        
        let $measures := 
            for $measure in $manifestation//mei:measure[@xml:id = $affected.measures/@xml:id]
            let $measure.id := $measure/string(@xml:id)
            let $measure.label := 
                if($measure/@label)
                then($measure/string(@label))
                else if($measure/@n)
                then($measure/string(@n))
                else('(' || string(count($measure/preceding::mei:measure) + 1) || ')')
            let $facs.refs := tokenize(normalize-space(replace($measure/@facs,'#','')),' ')
            let $iiif := 
                
                let $zones := 
                    (:measure is referencing a zone:)
                    if($measure/@facs and $doc.zones[@xml:id = $facs.refs])
                    then(
                        $doc.zones[@xml:id = $facs.refs]
                    )
                    (:a zone is referencing the measure:)
                    else if($doc.zones[$measure.id = tokenize(normalize-space(replace(@data,'#','')),' ')])
                    then(
                        $doc.zones[$measure.id = tokenize(normalize-space(replace(@data,'#','')),' ')]
                    )
                    else()
                let $annots := 
                    if(count($zones) gt 0)
                    then(
                        iiif:getRectangle($manifestation, $zones, true())
                    )
                    else()
                
                return $annots
            
            return map {
                'id': $measure.id,
                'uri': ef:getElementLink($manifestation.id,$measure.id),
                'label': $measure.label
            }
            
        let $iiif := iiif:getRectangle($manifestation, $manifestation//mei:measure[@xml:id = $affected.measures/@xml:id], true())
        let $ema := ema:buildLinkFromAnnots($manifestation, $affected.measures, $relevant.annots)
        
        return map {
            '@id': $manifestation.id,
            'label': $label,
            'file': map {
                'uri': $config:file-basepath || $manifestation.id || '.xml',
                '@ns': $manifestation.namespace,
                'name': $manifestation.filename
            },
            'textStatus': $text.status,
            'ema': $ema,
            'annots': array {
                for $annot in distinct-values($relevant.annots/string(@xml:id)) return ef:getElementLink($manifestation.id, $annot)
            },
            'measures': array {
                $measures
            },
            'iiif': array {
                $iiif
            }
            
        }
    
    (:return map {
        'id': array { $embodied.annot.ids },
        'uris': array { $documents }
    }:)
    
let $affected.measures :=
    for $complaint in ($annot, $dependent.complaints)
    
    let $first.measure := $complaint/ancestor::mei:measure
    
    (:how many additional measures do I need to pull?:)
    let $range := 
        if($annot/@tstamp2 and matches($annot/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($annot/@tstamp2,'m')) gt 0)
        then(xs:integer(substring-before($annot/@tstamp2,'m')))
        else(0)
    let $subsequent.measures :=
        if($range gt 0)
        then($first.measure/following::mei:measure[position() le $range])
        else()
        
    return ($first.measure | $subsequent.measures)

let $doc.zones := $file//mei:zone

let $measures := 
    for $measure in $file//mei:measure[@xml:id = $affected.measures/@xml:id]
    let $measure.id := $measure/string(@xml:id)
    let $measure.label := 
        if($measure/@label)
        then($measure/string(@label))
        else if($measure/@n)
        then($measure/string(@n))
        else('(' || string(count($measure/preceding::mei:measure) + 1) || ')')
    let $facs.refs := tokenize(normalize-space(replace($measure/@facs,'#','')),' ')
    let $iiif := 
        
        let $zones := 
            (:measure is referencing a zone:)
            if($measure/@facs and $doc.zones[@xml:id = $facs.refs])
            then(
                $doc.zones[@xml:id = $facs.refs]
            )
            (:a zone is referencing the measure:)
            else if($doc.zones[$measure.id = tokenize(normalize-space(replace(@data,'#','')),' ')])
            then(
                $doc.zones[$measure.id = tokenize(normalize-space(replace(@data,'#','')),' ')]
            )
            else()
        let $annots := 
            if(count($zones) gt 0)
            then(
                iiif:getRectangle($file, $zones, true())
            )
            else()
        
        return count($zones) (:$annots:)
    
    return map {
        'id': $measure.id,
        'uri': ef:getElementLink($document.id,$measure.id),
        'label': $measure.label,
        'iiif': array {
            $iiif
        }
    }



let $staves := 
    for $staff in tokenize($annot/normalize-space(@staff),' ')
    let $staff.label := $mdiv//mei:*[(local-name() = 'staffDef' and @n = $staff and ./mei:label) or (local-name() = 'staffGrp' and .//mei:staffDef[@n = $staff] and ./mei:label)][1]/mei:label/string(text())
    let $staff.labelAbbr := $mdiv//mei:*[(local-name() = 'staffDef' and @n = $staff and ./mei:labelAbbr) or (local-name() = 'staffGrp' and .//mei:staffDef[@n = $staff] and ./mei:labelAbbr)][1]/mei:labelAbbr/string(text())
    return map {
        'n': $staff,
        'label': $staff.label,
        'abbr': $staff.labelAbbr
    }
    (:return xs:integer($staff):)
    

    
return map {
    '@id': $public.complaint.id,
    '@work': $document.uri,
    'annots': array { for $annot in $annot.ids return ef:getElementLink($document.id,$annot)},
    'embodiments': array { $embodiments },
    'movement': map {
        'id': $mdiv.id,
        'uri': ef:getElementLink($document.id,$mdiv.id),
        'n': $mdiv.n,
        'label': $mdiv.label
    },
    'measures': array { $measures },
    'staves': array { $staves }
}


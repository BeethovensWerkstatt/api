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
import module namespace module3="https://beethovens-werkstatt/ns/module3" at "../../xqm/module3.xqm";


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

let $complaint := $file//mei:body//mei:metaMark[@xml:id = $complaint.id]
    
let $public.complaint.id := $config:module3-basepath || $document.id || '/complaints/' || $complaint.id || '.json'
let $mdiv := $complaint/ancestor::mei:mdiv[@xml:id][1]
let $mdiv.id := $mdiv/string(@xml:id)
let $mdiv.uri := ef:getMdivLink($document.id, $mdiv/string(@xml:id))
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

let $affected.measures :=
    for $complaint in ($complaint, $dependent.complaints)
    
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

let $affected.staves := tokenize($complaint/normalize-space(@staff),' ')

(: used for performance reasons :)
let $doc.zones := $file//mei:zone

let $revisionDoc.ids := $complaint/tokenize(replace(normalize-space(@source),'#',''),' ')
let $revisionDocs := 
    for $source.id in $revisionDoc.ids
    return module3:getEmbodiment($document.id, $complaint, $source.id, 'revision', $affected.measures, $affected.staves)
    
let $anteDoc.ids := distinct-values($complaint/mei:relation[@rel = 'isRevisionOf']/tokenize(replace(normalize-space(@target),'#',''),' '))
let $anteDocs := 
    for $source.id in $anteDoc.ids
    return module3:getEmbodiment($document.id, $complaint, $source.id, 'ante', $affected.measures, $affected.staves)

let $postDoc.ids := distinct-values($complaint/mei:relation[@rel = 'hasRevision']/tokenize(replace(normalize-space(@target),'#',''),' '))
let $postDocs := 
    for $source.id in $postDoc.ids
    return module3:getEmbodiment($document.id, $complaint, $source.id, 'post', $affected.measures, $affected.staves)

let $embodiments :=

    


    let $measure.facs := $affected.measures/tokenize(replace(normalize-space(@facs),'#',''),' ')
    let $relevant.staves := $affected.measures/mei:staff[@n = $affected.staves]
    let $staff.facs := $relevant.staves/tokenize(replace(normalize-space(@facs),'#',''),' ')
    
    (:let $measure.zones.by.zone := $doc.zones[some $ref in tokenize(replace(normalize-space(@data),'#',''),' ') satisfies $ref = $affected.measures/@xml:id]
    let $measure.zones.by.facs := $doc.zones[@xml:id = $measure.facs]
    let $staff.zones.by.zone := $doc.zones[some $ref in tokenize(replace(normalize-space(@data),'#',''),' ') satisfies $ref = $affected.measures/mei:staff[@n = $affected.staves]/@xml:id]
    let $staff.zones.by.facs := $doc.zones[@xml:id = $staff.facs]
    
    let $relevant.zones := ($measure.zones.by.zone, $measure.zones.by.facs, $staff.zones.by.zone, $staff.zones.by.facs)
    let $relevant.zones.ids := distinct-values($relevant.zones/@xml:id):)
    
    let $measure.zones.by.zone := $doc.zones[@data = $affected.measures/concat('#',@xml:id)]
    let $measure.zones.by.facs := $doc.zones[@xml:id = $measure.facs]
    let $staff.ids := $affected.measures/mei:staff[@n = $affected.staves]/concat('#',@xml:id)
    let $staff.zones.by.zone := $doc.zones[@data = $staff.ids]
    let $staff.zones.by.facs := $doc.zones[@xml:id = $staff.facs]
    
    let $relevant.zones := ($measure.zones.by.zone, $measure.zones.by.facs, $staff.zones.by.zone, $staff.zones.by.facs)
    let $relevant.zones.ids := distinct-values($relevant.zones/@xml:id)
    
    let $facsimile.ids := distinct-values($relevant.zones/ancestor::mei:facsimile/@xml:id)
    let $facsimiles := $file//mei:facsimile[@xml:id = $facsimile.ids]
    
    for $facsimile in $facsimiles
        let $manifestation := $file//mei:manifestation[@xml:id = $facsimile/replace(normalize-space(@decls),'#','')]
        let $label := $manifestation/string(@label)
        
        let $manifestation.classes := tokenize(normalize-space($manifestation/@class),' ')
        let $text.status := 
            if('#initialVersion' = $manifestation.classes)
            then('initialVersion')
            else if('#revisedVersion' = $manifestation.classes)
            then('revisedVersion')
            else if('#revisionList' = $manifestation.classes)
            then('revisionInstruction')
            else('unknown')
            
        let $current.zones := $facsimile//mei:zone[@xml:id = $relevant.zones.ids]
        
        let $iiif := iiif:getRectangle($file, $current.zones, true())
        (:let $ema := ema:buildLinkFromAnnots($manifestation, $affected.measures, $relevant.annots)
        let $mei := ef:getMeiByAnnotsLink($manifestation.id, $relevant.annots/@xml:id):)
        
        let $iiif.manifest := $config:iiif-basepath || 'document/' || $facsimile/@xml:id || '/manifest.json'
        (:'measures': array {
                $measures
            },:)
        return map {
            'id': string($facsimile/@xml:id),
            'label': $label,
            'textStatus': $text.status,
            'annots': array {
                for $annot in distinct-values($annot.ids) return ef:getElementLink($document.id, $annot)
            },
            'iiif': map {
                'manifest': $iiif.manifest,
                'rects': array { $iiif }
            }
        }
        
(:        
        
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
        let $mei := ef:getMeiByAnnotsLink($manifestation.id, $relevant.annots/@xml:id)
        
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
            'mei': $mei,
            'annots': array {
                for $annot in distinct-values($relevant.annots/string(@xml:id)) return ef:getElementLink($manifestation.id, $annot)
            },
            'measures': array {
                $measures
            },
            'iiif': array {
                $iiif
            }
            
        }:)
    
    (:return map {
        'id': array { $embodied.annot.ids },
        'uris': array { $documents }
    }:)
    



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
    
    return map {
        'id': $measure.id,
        'uri': ef:getElementLink($document.id,$measure.id),
        'label': $measure.label
    }
    
return map {
    '@id': $public.complaint.id,
    'label': $complaint/string(@label),
    '@work': $document.uri,
    'annots': array { for $annot in $annot.ids return ef:getElementLink($document.id,$annot)},
    (:'embodiments': array { $embodiments },:)
    'movement': map {
        'id': $mdiv.id,
        'uri': ef:getElementLink($document.id,$mdiv.id),
        'n': $mdiv.n,
        'label': $mdiv.label
    },
    'measures': array { $measures },
    'staves': array { $affected.staves },
    'revisionDocs': array { $revisionDocs },
    'anteDocs': array { $anteDocs },
    'postDocs': array { $postDocs }
}


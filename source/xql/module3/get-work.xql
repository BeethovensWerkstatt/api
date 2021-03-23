xquery version "3.1";

(:
    get-work.xql

    This xQuery retrieves relevant information about a work from the third module of Beethovens Werkstatt
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace ef="https://edirom.de/file" at "../../xqm/file.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

let $title := 
    for $title in $file//mei:fileDesc/mei:titleStmt/mei:title
    return map {
      'title': $title/text(),
      '@lang': $title/string(@xml:lang)
    }
    
let $composer.elem := $file//mei:fileDesc/mei:titleStmt/mei:composer/mei:persName
let $composer := map {
    'name': $composer.elem/text(),
    '@id': $composer.elem/string(@auth.uri) || $composer.elem/string(@codedval),
    'internalId': $composer.elem/string(@xml:id)
}

(:
let $manifestation.files := 
    for $manifestationRef in $file//mei:manifestation
    let $manifestation.filename := 
        if(contains($manifestationRef/@sameas,'/')) 
        then(tokenize($manifestationRef/@sameas,'/')[last()]) 
        else($manifestationRef/string(@sameas))
    let $manifestation.file := $database/element()[tokenize(document-uri(./root()),'/')[last()] = $manifestation.filename]
    where exists($manifestation.file) and exists($manifestation.file/@xml:id)
    return $manifestation.file
    
let $manifestations := 
    for $manifestationRef in $file//mei:manifestation
    let $manifestation.filename := 
        if(contains($manifestationRef/@sameas,'/')) 
        then(tokenize($manifestationRef/@sameas,'/')[last()]) 
        else($manifestationRef/string(@sameas))
    let $manifestation.file := $manifestation.files[tokenize(document-uri(./root()),'/')[last()] = $manifestation.filename]
    where exists($manifestation.file) and exists($manifestation.file/@xml:id)
    let $label := $manifestationRef/string(@label)
    let $manifestation.id := $manifestation.file/string(@xml:id)
    let $manifestation.namespace := namespace-uri($manifestation.file)
    let $manifestation.external.id := $config:module3-basepath || $document.id || '/manifestation/' || $manifestation.id || '.json'
    
    let $iiif.manifest := $config:iiif-basepath || 'document/' || $manifestation.id || '/manifest.json'
    
    return map {
      '@id': $manifestation.id,
      'label': $label,
      'file': map {
        'uri': $config:file-basepath || $manifestation.id || '.xml',
        '@ns':  $manifestation.namespace,
        'name': $manifestation.filename
      },
      'frbr': map {
        'level': 'manifestation'
      },
      'iiif': map {
        'manifest': $iiif.manifest
      }
    }    
    
:)

let $mdivs := 
    map:merge(for $mdiv in $file//mei:mdiv[@xml:id]
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
        
    let $staves := 
        for $staff in distinct-values($mdiv//mei:staffDef/@n)
        let $staff.label := ($mdiv//mei:staffDef[@n = $staff and ./mei:label], $mdiv//mei:staffGrp[.//mei:staffDef[@n = $staff] and ./mei:label])[1]/mei:label/string(text())
        let $staff.labelAbbr := ($mdiv//mei:staffDef[@n = $staff and ./mei:labelAbbr], $mdiv//mei:staffGrp[.//mei:staffDef[@n = $staff] and ./mei:labelAbbr])[1]/mei:labelAbbr/string(text())
        order by xs:integer($staff)
        return map {
            'n': $staff,
            'label': $staff.label,
            'abbr': $staff.labelAbbr
        }
        
    
    return map:entry(
        $mdiv.id, map {
            '@id': ef:getMdivLink($document.id, $mdiv.id),
            'label': $mdiv.label,
            'n': $mdiv.n,
            'staves': array { $staves }
        }
    ))
    
    
let $manifestations := 
    for $manifestation in $file//mei:manifestation
    let $facsimile := $file//mei:facsimile[@decls = concat('#',$manifestation/@xml:id)]
    
    where exists($facsimile) (:TODO: Decide how to deal with TEI files… :)
    
    let $label := $manifestation/string(@label)
    let $facsimile.id := $facsimile/string(@xml:id)
    
    (:let $manifestation.namespace := namespace-uri($manifestation.file):)
    let $manifestation.external.id := $config:module3-basepath || $document.id || '/manifestation/' || $facsimile.id || '.json'
    
    let $iiif.manifest := $config:iiif-basepath || 'document/' || $facsimile.id || '/manifest.json'
    
    return map {
      'id': $facsimile.id,
      'label': $label,
      'frbr': map {
        'level': 'manifestation'
      },
      'iiif': map {
        'manifest': $iiif.manifest
      }
    }
    
let $complaints := 
    for $annot in $file//mei:body//mei:annot[@xml:id] (:TODO: add in some @class:)
    (: get only those annots that are the first occurence of something :)
    where not(replace($annot/@corresp,'#','') = $file//mei:annot/@xml:id)
    let $complaint.id := $annot/string(@xml:id)
    let $public.complaint.id := $config:module3-basepath || $document.id || '/complaints/' || $complaint.id || '.json'
    let $mdiv := $annot/ancestor::mei:mdiv[@xml:id][1]
    let $mdiv.id := $mdiv/string(@xml:id)
    
    let $dependent.complaints := $file//mei:annot[@xml:id][@corresp = '#' || $complaint.id]
    
    let $annot.ids := distinct-values(($complaint.id, $dependent.complaints/string(@xml:id)))[string-length(.) gt 0]
    
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
    
    let $measures := 
        for $measure in $file//mei:measure[@xml:id = $affected.measures/@xml:id]
        let $measure.id := $measure/string(@xml:id)
        let $measure.label := 
            if($measure/@label)
            then($measure/string(@label))
            else if($measure/@n)
            then($measure/string(@n))
            else('(' || string(count($measure/preceding::mei:measure) + 1) || ')')
        return map {
            'id': $measure.id,
            'label': $measure.label
        }
        
    return map {
        '@id': $public.complaint.id,
        'annots': array { $annot.ids },
        'mdiv': $mdiv.id,
        'measures': array { $measures }
    }


return map {
    '@id': $document.uri,
    'title': array { $title },
    'composer': $composer,
    'manifestations': array { $manifestations },
    'complaints': array { $complaints },
    'movements': $mdivs
}



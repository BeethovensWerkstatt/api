xquery version "3.1";

(:
    get-work.xql

    This xQuery retrieves relevant information about a work from the third module of Beethovens Werkstatt
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace ef="https://edirom.de/file" at "../../xqm/file.xqm";
import module namespace module3="https://beethovens-werkstatt/ns/module3" at "../../xqm/module3.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace xi = "http://www.w3.org/2001/XInclude";

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
let $complete.file := $database//mei:meiCorpus[@xml:id = $document.id]

let $inclusion.base.uri := string-join(tokenize(document-uri($complete.file/root()),'/')[position() lt last()],'/')

let $corpus.head := $complete.file/mei:meiHead

let $mei.files := 
    for $link in $complete.file/xi:include/string(@href)
    return doc($inclusion.base.uri || '/' || $link)//mei:mei

let $text.file := ($mei.files[.//mei:encodingDesc['#bw_module3_textFile' = tokenize(normalize-space(@class),' ')]])[1]
let $document.files := $mei.files[.//mei:encodingDesc['#bw_module3_documentFile' = tokenize(normalize-space(@class),' ')]]

let $title := 
    for $title in $text.file//mei:fileDesc/mei:titleStmt/mei:title
    return map {
      'title': $title/text(),
      '@lang': $title/string(@xml:lang)
    }
    
let $composer.elem := $text.file//mei:fileDesc/mei:titleStmt/mei:composer/mei:persName
let $composer := map {
    'name': $composer.elem/normalize-space(text()),
    '@id': $composer.elem/string(@auth.uri) || $composer.elem/string(@codedval),
    'internalId': $composer.elem/string(@xml:id)
}

let $mdivs := 
    for $mdiv in $text.file//mei:mdiv[@xml:id]
    let $mdiv.id := $mdiv/string(@xml:id)
    let $mdiv.n := 
        if($mdiv/@n)
        then($mdiv/string(@n))
        else(string(count($mdiv/preceding::mei:mdiv) + 1))
    order by xs:integer($mdiv.n) ascending
    
    return ef:getMdivLink($document.id, $mdiv.id)
    
    
    
let $manifestations := 
    for $manifestation in $document.files//mei:manifestation
    let $source.id := $manifestation/string(@xml:id)
    
    let $manifestation.external.id := ef:getManifestationLink($document.id, $source.id)
    return $manifestation.external.id
    
let $complaints := 
    for $complaint in $document.files//mei:metaMark['#bw_monitum' = tokenize(normalize-space(@class),' ')]
    let $complaint.id := $complaint/string(@xml:id)
    (: let $complaint.classes := tokenize(normalize-space($complaint/@class),' ') :)
    let $public.complaint.id := module3:getComplaintLink($document.id, $complaint.id)
    
    let $complaint.document.id := $complaint/ancestor::mei:mei//mei:manifestation/string(@xml:id)
    let $text.file.annots := $text.file//mei:annot[mei:relation[@rel = 'constituent'][substring-after(@target,'#') = $complaint.id]]
    let $post.annots := 
        for $annot in $text.file.annots
        let $rel.target := $annot/mei:relation[@rel = 'preceding']/substring(@target,2)
        let $target := $document.files/root()/id($rel.target)
        return $target
    
    let $affects :=
        for $annot in $text.file.annots
        let $mdiv := $annot/ancestor::mei:mdiv[@xml:id][1]
        let $mdiv.id := $mdiv/string(@xml:id)
        let $mdiv.link := ef:getMdivLink($document.id, $mdiv.id)
        
        let $first.measure := $annot/ancestor::mei:measure
    
        (:how many additional measures do I need to pull?:)
        let $range := 
            if($annot/@tstamp2 and matches($annot/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($annot/@tstamp2,'m')) gt 0)
            then(xs:integer(substring-before($annot/@tstamp2,'m')))
            else(0)
        let $subsequent.measures :=
            if($range gt 0)
            then(
                (:$first.measure/following-sibling::mei:measure[position() le $range]:)
                ($first.measure/parent::mei:*/mei:measure[preceding-sibling::mei:measure[@xml:id = $first.measure/@xml:id]])[position() le $range]
            )
            else()
            
        let $affected.measures := ($first.measure | $subsequent.measures)
        
        let $measure.refs := 
            for $measure in $affected.measures
            return ef:getMeasureLink($document.id, $measure/string(@xml:id))
            
        let $measure.summary :=
            let $base.labels :=
                for $measure in $affected.measures
                let $measure.id := $measure/string(@xml:id)
                let $measure.label := 
                    if($measure/@label)
                    then($measure/string(@label))
                    else if($measure/@n)
                    then($measure/string(@n))
                    else('(' || string(count($mdiv//mei:measure[following::mei:measure[@xml:id = $measure.id]]) + 1) || ')')
                order by xs:double(replace($measure.label,'[a-zA-Z]+','')) ascending
                return $measure.label
            
            let $summary := 
                if(count($base.labels) gt 2)
                then($base.labels[1] || '–' || $base.labels[last()])
                else if(count($base.labels) eq 2)
                then($base.labels[1] || ', ' || $base.labels[last()])
                else($base.labels[1])
            return $summary
            
        let $staves := 
            for $staff in tokenize(normalize-space($annot/@staff),' ')
            let $value := xs:integer($staff)
            order by $value ascending
            return $value
        
        return map {
            'mdiv': ef:getMdivLink($document.id, $mdiv.id),
            'measures': map {
                'refs': array { $measure.refs },
                'label': $measure.summary
            },
            'staves': array { $staves }
        }
        
    let $tags := 
        let $all.categories :=
            for $cat in distinct-values(($complaint/tokenize(normalize-space(@class),' '),$post.annots//tokenize(normalize-space(@class),' ')))
            let $id := substring($cat,2)
            where $id ne 'bw_monitum' and $id ne 'bw_monitum_comment' (: todo: where to store the fully implemented?:)
            return $corpus.head/id($id)
            
        let $objects := 
            for $object in $all.categories/self::mei:category[@class = '#bw_monitum_object']
            return $object/string(@xml:id)
        
        let $operations := 
            for $operation in $all.categories/self::mei:category[@class = '#bw_monitum_textoperation']
            return $operation/string(@xml:id)
            
        let $classes := 
            for $class in $all.categories/self::mei:category[@class = '#bw_monitum_classification']
            return $class/string(@xml:id)
        
        let $context.correct := 
            for $context in $all.categories/self::mei:category[@class = '#bw_monitum_kontext']
            return $context/string(@xml:id)
            
        let $implementation := 
            for $class in $all.categories/self::mei:category[@class = '#bw_implementation_completeness']
            return $class/string(@xml:id)
        
        return map {
            'objects': array { $objects },
            'operation': array { $operations },
            'classes': array { $classes },
            'context': array { $context.correct },
            'implementation': array { $implementation }
        }
        
    let $staticExample := '#bw_module3_staticExample' = distinct-values($text.file//mei:encodingDesc/tokenize(normalize-space(@class),' ')) 
    let $externalUri := 
        if($staticExample and $text.file.annots/@data)
        then(array { $text.file.annots/string(@data)} )
        else( array { $text.file.annots/@nonExistent })
    
    return map {
        '@id': $public.complaint.id,
        'affects': array { $affects },
        'tags': $tags,
        'revisionDoc': $complaint.document.id,
        'staticExample': $staticExample,
        'externalUri': $externalUri
    }

let $output := map {
    '@id': $document.uri,
    'title': array { $title },
    'composer': $composer,
    'manifestations': array { $manifestations },
    'complaints': array { $complaints },
    'movements': $mdivs
}
return $output
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

(: get the ID of the requested complaint, as passed by the controller :)
let $complaint.id := request:get-parameter('complaint.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: get file from database :)
let $complete.file := $database//mei:meiCorpus[@xml:id = $document.id]

let $inclusion.base.uri := string-join(tokenize(document-uri($complete.file/root()),'/')[position() lt last()],'/')

let $corpus.head := $complete.file/mei:meiHead

let $mei.files :=
    for $link in $complete.file/xi:include/string(@href)
    return doc($inclusion.base.uri || '/' || $link)//mei:mei

let $text.file := ($mei.files[.//mei:encodingDesc[@class='#bw_module3_textFile']])[1]
let $document.files := $mei.files[.//mei:encodingDesc[@class='#bw_module3_documentFile']]


let $complaint.metamark := $database//mei:metaMark[@xml:id = $complaint.id]

let $public.complaint.id := module3:getComplaintLink($document.id, $complaint.id)

let $complaint.document.id := $complaint.metamark/ancestor::mei:mei//mei:manifestation/string(@xml:id)
let $text.file.annots := $text.file//mei:relation[substring-after(@target,'#') = $complaint.id][@rel = 'constituent']/parent::mei:annot

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
        then($first.measure/following::mei:measure[position() le $range])
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

let $revDoc.contextAnnots := $document.files//mei:annot[@xml:id = $text.file.annots/mei:relation[@rel = 'original']/replace(normalize-space(@target),'#','')]

let $revisionDocs :=
    for $context in $revDoc.contextAnnots
    let $source.id := $context/ancestor::mei:mei//mei:manifestation/string(@xml:id)
    
    let $embodiment := 
        if(not($context/ancestor::tei:*))
        then(
        (:a regular music document:)
        
            let $mdiv := $context/ancestor::mei:mdiv[@xml:id][1]
            let $mdiv.id := $mdiv/string(@xml:id)
            let $mdiv.link := ef:getMdivLink($document.id, $mdiv.id)
        
            let $first.measure := $context/ancestor::mei:measure
        
            (:how many additional measures do I need to pull?:)
            let $range :=
                if($context/@tstamp2 and matches($context/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($context/@tstamp2,'m')) gt 0)
                then(xs:integer(substring-before($context/@tstamp2,'m')))
                else(0)
            let $subsequent.measures :=
                if($range gt 0)
                then($first.measure/following::mei:measure[position() le $range])
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
                for $staff in tokenize(normalize-space($context/@staff),' ')
                let $value := xs:integer($staff)
                order by $value ascending
                return $value
                
            let $text.annot := $text.file.annots[mei:relation[@rel = 'original'][@target = '#' || $context/@xml:id]]    
        
            return module3:getEmbodiment($document.id, $complaint.metamark, $source.id, 'revision', $affected.measures, $staves, $text.file, $context/ancestor::mei:mei, $text.annot, $context)
        )
        else(
        (:a letter requiring slightly different treatment:)
            
            let $revision.doc := $context/root()
            
            let $start.id := replace($context/@startid,'#','')
            let $end.id := replace($context/@endid,'#','')
            let $start.elem := $revision.doc/id($start.id)
            let $snippet := (:$start.elem/following::node():)(:[./following::tei:anchor[@xml:id = $end.id]]:)
                (:for tumbling window $w in $start.elem/parent::node()
                    start $s when $s/@xml:id = $start.id
                    end $e when head($e/following-sibling::node())/@xml:id = $end.id
                return element group { tail($w) }:)
                
                let $end.elem := $revision.doc/id($end.id)
                return $start.elem/following-sibling::node()[. << $end.elem]
            
            (:let $mdiv := $context/ancestor::mei:mdiv[@xml:id][1]
            let $mdiv.id := $mdiv/string(@xml:id)
            let $mdiv.link := ef:getMdivLink($document.id, $mdiv.id)
        :)
            (:let $first.measure := $context/ancestor::mei:measure
        
            (\:how many additional measures do I need to pull?:\)
            let $range :=
                if($context/@tstamp2 and matches($context/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($context/@tstamp2,'m')) gt 0)
                then(xs:integer(substring-before($context/@tstamp2,'m')))
                else(0)
            let $subsequent.measures :=
                if($range gt 0)
                then($first.measure/following::mei:measure[position() le $range])
                else()
        :)
            let $affected.measures := $snippet//mei:measure
        
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
                        else('(' || string(count($snippet//mei:measure[following::mei:measure[@xml:id = $measure.id]]) + 1) || ')')
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
                for $staff in distinct-values($snippet//mei:staff/@n)
                let $value := xs:integer($staff)
                order by $value ascending
                return $value
                
            let $text.annot := $text.file.annots[mei:relation[@rel = 'original'][@target = '#' || $context/@xml:id]]    
        
            return module3:getEmbodiment($document.id, $complaint.metamark, $source.id, 'revision', $affected.measures, $staves, $text.file, $context/ancestor::mei:mei, $text.annot, $context)
                (:map {
                'documentId': $document.id,
                'complaintMetaMark': serialize($complaint.metamark),
                'sourceId': $source.id,
                'revision': 'revision',
                'affectedMeasures': serialize($affected.measures),
                'staves': serialize($staves),
                'textFile': exists($text.file),
                'meiFile': exists($context/ancestor::mei:mei), 
                'textAnnot': serialize($text.annot), 
                'context': serialize($context),
                'snippet': serialize($snippet)
            }:)
        
        )
    
    return $embodiment    

let $anteDoc.contextAnnots := $document.files//mei:annot[@xml:id = $text.file.annots/mei:relation[@rel = 'succeeding']/replace(normalize-space(@target),'#','')]

let $anteDocs :=
    for $context in $anteDoc.contextAnnots
    let $source.id := $context/ancestor::mei:mei//mei:manifestation/string(@xml:id)

    let $mdiv := $context/ancestor::mei:mdiv[@xml:id][1]
    let $mdiv.id := $mdiv/string(@xml:id)
    let $mdiv.link := ef:getMdivLink($document.id, $mdiv.id)

    let $first.measure := $context/ancestor::mei:measure

    (:how many additional measures do I need to pull?:)
    let $range :=
        if($context/@tstamp2 and matches($context/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($context/@tstamp2,'m')) gt 0)
        then(xs:integer(substring-before($context/@tstamp2,'m')))
        else(0)
    let $subsequent.measures :=
        if($range gt 0)
        then($first.measure/following::mei:measure[position() le $range])
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
        for $staff in tokenize(normalize-space($context/@staff),' ')
        let $value := xs:integer($staff)
        order by $value ascending
        return $value
        
    let $text.annot := $text.file.annots[mei:relation[@rel = 'succeeding'][@target = '#' || $context/@xml:id]]

    return module3:getEmbodiment($document.id, $complaint.metamark, $source.id, 'ante', $affected.measures, $staves, $text.file, $context/ancestor::mei:mei, $text.annot, $context)

let $postDoc.contextAnnots := $document.files//mei:annot[@xml:id = $text.file.annots/mei:relation[@rel = 'preceding']/replace(normalize-space(@target),'#','')]

let $postDocs :=
    for $context in $postDoc.contextAnnots
    let $source.id := $context/ancestor::mei:mei//mei:manifestation/string(@xml:id)

    let $mdiv := $context/ancestor::mei:mdiv[@xml:id][1]
    let $mdiv.id := $mdiv/string(@xml:id)
    let $mdiv.link := ef:getMdivLink($document.id, $mdiv.id)

    let $first.measure := $context/ancestor::mei:measure

    (:how many additional measures do I need to pull?:)
    let $range :=
        if($context/@tstamp2 and matches($context/@tstamp2, '(\d)+m\+(\d)+(\.\d+)?') and xs:integer(substring-before($context/@tstamp2,'m')) gt 0)
        then(xs:integer(substring-before($context/@tstamp2,'m')))
        else(0)
    let $subsequent.measures :=
        if($range gt 0)
        then($first.measure/following::mei:measure[position() le $range])
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
        for $staff in tokenize(normalize-space($context/@staff),' ')
        let $value := xs:integer($staff)
        order by $value ascending
        return $value
    
    let $text.annot := $text.file.annots[mei:relation[@rel = 'preceding'][@target = '#' || $context/@xml:id]]
    
    return module3:getEmbodiment($document.id, $complaint.metamark, $source.id, 'post', $affected.measures, $staves, $text.file, $context/ancestor::mei:mei, $text.annot, $context)

let $post.state.id := ($complaint.metamark/substring-after(@state,'#'))[1]
let $ante.state.id := ($database/id($post.state.id)/preceding::mei:genState[1]/string(@xml:id))[1]

let $ante.text := ef:getMeiByContextLink($document.id, $text.file.annots[1]/string(@xml:id), '', '', $ante.state.id)
let $post.text := ef:getMeiByContextLink($document.id, $text.file.annots[1]/string(@xml:id), '', '', $post.state.id)

let $tags := 
    let $all.categories :=
        for $cat in distinct-values(($complaint.metamark/tokenize(normalize-space(@class),' '),$postDoc.contextAnnots//tokenize(normalize-space(@class),' ')))
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

return map {
    '@id': $public.complaint.id,
    'label': $complaint.metamark/string(@label),
    '@work': $document.uri,
    'affects': $affects,
    'revisionDocs': array { $revisionDocs },
    'anteDocs': array { $anteDocs },
    'postDocs': array { $postDocs },
    'text': map {
        'ante': $ante.text,
        'post': $post.text
    },
    'tags': $tags
}

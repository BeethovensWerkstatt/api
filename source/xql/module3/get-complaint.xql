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

let $ante.text := ef:getMeiByContextLink($document.id, $text.file.annots[1]/string(@xml:id), '', '', 'anteRevision')
let $post.text := ef:getMeiByContextLink($document.id, $text.file.annots[1]/string(@xml:id), '', '', 'postRevision')

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
    }
}

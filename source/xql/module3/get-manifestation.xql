xquery version "3.1";

(:
    get-manifestation.xql

    This xQuery retrieves relevant information about a manifestation from the third module of Beethovens Werkstatt
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

(: get the ID of the requested mdiv, as passed by the controller :)
let $manifestation.id := request:get-parameter('manifestation.id','')

let $manifestation.external.id := ef:getManifestationLink($document.id, $manifestation.id)
let $document.uri := $config:module3-basepath || $document.id || '.json'

(: build mdiv json :)

let $manifestation := $database//mei:manifestation[@xml:id = $manifestation.id]
let $mei.file := $manifestation/ancestor::mei:mei
let $facsimile := $mei.file//mei:facsimile

(: TODO: Hier was aus dem Header nehmen?:)
let $manifestation.label := $manifestation/string(@label)

let $iiif.manifest := $config:iiif-basepath || 'document/' || $manifestation.id || '/manifest.json'

let $mdivs := 
    for $mdiv in $mei.file//mei:mdiv
    let $mdiv.id := $mdiv/string(@xml:id)
    let $mdiv.n := 
        if($mdiv/@n)
        then($mdiv/string(@n))
        else(string(count($mdiv/preceding::mei:mdiv) + 1))
    order by xs:integer($mdiv.n) ascending
    
    let $mdiv.label :=
        if($mdiv/@label)
        then($mdiv/string(@label))
        else if($mdiv/@n)
        then($mdiv/string(@n))
        else('(' || string(count($mdiv/preceding::mei:mdiv) + 1) || ')')
       
    let $score.staves := 
        for $staff in distinct-values($mdiv/mei:score//mei:staffDef/@n)
        let $staff.label := ($mdiv/mei:score//mei:staffDef[@n = $staff and ./mei:label], $mdiv/mei:score//mei:staffGrp[.//mei:staffDef[@n = $staff] and ./mei:label])[1]/mei:label/string(text())
        let $staff.labelAbbr := ($mdiv/mei:score//mei:staffDef[@n = $staff and ./mei:labelAbbr], $mdiv/mei:score//mei:staffGrp[.//mei:staffDef[@n = $staff] and ./mei:labelAbbr])[1]/mei:labelAbbr/string(text())
        order by xs:integer($staff)
        return map {
            'n': $staff,
            'label': $staff.label,
            'abbr': $staff.labelAbbr            
        }
    let $score.measures := ef:getMeasuresInScoreLink($document.id, $manifestation.id, $mdiv.id)
            
    let $score := 
        if($mdiv/mei:score)
        then(
            map { 
                'staves': $score.staves,
                'measures': $score.measures
            }
        )
        else ($mdiv/mei:score)
    
    let $part.staves :=
        for $part in $mdiv/mei:parts/mei:part
        let $part.n := 
            if($part/@n)
            then(xs:integer($part/@n))
            else(count($part/preceding-sibling::mei:part) + 1)
            order by $part.n
        let $part.label := 
            if($part/@label)
            then($part/string(@label))
            else if($part/mei:scoreDef//mei:label/text())
            then(normalize-space(string-join(($part/mei:scoreDef//mei:label[./text()])[1]/text(),' ')))
            else('')
        let $staves := 
            for $staff in distinct-values($part//mei:staffDef/xs:integer(@n))
            order by $staff
            let $staff.label := ($part//mei:staffDef[xs:integer(@n) = $staff and ./mei:label], $part//mei:staffGrp[.//mei:staffDef[xs:integer(@n) = $staff] and ./mei:label])[1]/mei:label/string(text())
            let $staff.labelAbbr := ($part//mei:staffDef[xs:integer(@n) = $staff and ./mei:labelAbbr], $part//mei:staffGrp[.//mei:staffDef[xs:integer(@n) = $staff] and ./mei:labelAbbr])[1]/mei:labelAbbr/string(text())
            order by xs:integer($staff)
            return map {
                'n': $staff,
                'label': $staff.label,
                'abbr': $staff.labelAbbr
            }
        let $measures := ef:getMeasuresInPartLink($document.id, $manifestation.id, $mdiv.id, $part.n)
        return map {
            'part': $part.n,
            'label': $part.label,
            'staves': array { $staves },
            'measures': $measures
        }
    
    let $parts := 
        if($mdiv/mei:parts)
        then(
            array { $part.staves }
        )
        else ($mdiv/mei:parts)
    
    return map {
        'id': $mdiv.id,
        'n': $mdiv.n,
        'label': $mdiv.label,
        'score': $score,
        'parts': $parts
    }
    
let $all.measures.link := ef:getManifestationMeasuresLink($document.id,$manifestation.id)

(: check validity :)

(: get file from database :)
let $corpus.file := $database//mei:meiCorpus[@xml:id = $document.id]
let $inclusion.base.uri := string-join(tokenize(document-uri($corpus.file/root()),'/')[position() lt last()],'/')
let $included.file.uris := 
    for $link in $corpus.file//xi:include/string(@href)
    return replace($inclusion.base.uri || '/' || $link,'/\./','/')

let $measure.file := $mei.file/root()
let $proper.textfile := exists($mei.file//mei:encodingDesc[@class='#bw_module3_textFile'])
let $correctly.loaded := document-uri($measure.file) = $included.file.uris

let $output := 
    if($proper.textfile and $correctly.loaded or 1 eq 1)
    then(
        map {
        '@id': $manifestation.external.id,
        'work': $document.uri,
        'label': $manifestation.label,
        'frbr': map {
            'level': 'manifestation'
        },
        'iiif': map {
            'manifest': $iiif.manifest
        },
        'mdivs': array { $mdivs },
        'measures': $all.measures.link
    }
    ) else (
        (: TODO: add RESSOURCE NOT FOUND:)
        map {
            
        }
    )

return $output
    
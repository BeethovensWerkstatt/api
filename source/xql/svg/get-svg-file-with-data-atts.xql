xquery version "3.1";

(:
    get-file.xql

    This xQuery retrieves a complete file and outputs it as XML
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace uuid = "java:java.util.UUID";

(: set output to JSON:)
declare option output:method "xml";
declare option output:media-type "text/xml";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

let $svg.file.name := request:get-parameter('svg.file.name','')

let $document.uri := $config:file-basepath || $document.id || '.xml'

(: get file from database :)
let $svg.file := $database//svg:svg[tokenize(document-uri(root()),'/')[last()] = $svg.file.name]
let $svg.shape.IDs := $svg.file//svg:path/@id

let $manifestation.file := $database/id($document.id)/ancestor-or-self::mei:mei
let $manifestation.file.name := $manifestation.file/tokenize(document-uri(root()),'/')[last()]
let $corpus.file := $database//mei:meiCorpus[xi:include[@href = 'manifestations/' ||$manifestation.file.name]]
let $all.text.files := $database//mei:mei[.//mei:encodingDesc[@class = '#bw_module3_textFile']]

(: let $monita.contexts := :) 


let $xslt := $config:xslt-basepath || '../xslt/module3/get-stateless-complaint-text-by-annot.xsl'

let $monita := 
    for $context.annot in $manifestation.file//@class[ft:query(.,'#bw_monitum_context')]/parent::node() 
    let $monitum.effect := $all.text.files//@target[ft:query(.,'#' || $context.annot/@xml:id)]/parent::mei:relation/parent::mei:annot
    let $monitum.id := $monitum.effect/mei:relation[@rel = 'constituent']/substring(normalize-space(@target),2)
    let $source.id := $manifestation.file//mei:manifestation/@xml:id
    
    let $measure.count := 
        let $raw := $context.annot/string(@tstamp2)
        let $count := 
            if(contains($raw,'m+'))
            then(xs:integer(substring-before($raw,'m+')))
            else(0)
        return $count    
    let $relevant.measures := ($context.annot/ancestor::mei:measure, $context.annot/ancestor::mei:measure/following::mei:measure[position() le $measure.count])
    
    where some $shape.ID in $svg.shape.IDs satisfies exists($relevant.measures//@facs[ft:query(.,'#' || $shape.ID)])
    
    let $text.file := serialize($monitum.effect/ancestor::mei:mei)
    let $excerpt := transform:transform($manifestation.file,
               doc($xslt), <parameters>
                   <param name="context.id" value="{$context.annot/string(@xml:id)}"/>
                   <param name="source.id" value="{$source.id}"/>
                   <param name="state.id" value="''"/>
                   <param name="focus.id" value="''"/>
                   <param name="text.file" value="{$text.file}"/>
               </parameters>)
    return 
        <snippet monitum.id="{$monitum.id}" monitum.effect="{$monitum.effect/@xml:id}">{$excerpt}</snippet>

let $links := 
    for $shape.ID in $svg.shape.IDs
    let $query := '#' || $shape.ID
    (:let $item := $manifestation.file//@facs[ft:query(.,$query)]/parent::node():)
    let $item := $monita//@facs[contains(.,$query)]/parent::node()
    
    return 
    <link shape="{$shape.ID}" item="{string-join($item/@xml:id,' ')}" monitum="{string-join($item/ancestor::snippet/@monitum.id,' ')}"/>

let $groups := 
    for $monitumGroup in distinct-values($links//@monitum)
    let $monita := 
        for $monitum in tokenize($monitumGroup,' ')
        let $att.title := 'data-mon-' || $monitum
        return attribute {$att.title} {''}
        
    let $emptyFlag := 
        if($monitumGroup = '')
        then( attribute data-unused {''} )
        else()
        
    let $relevant.links := $links//self::link[@monitum = $monitumGroup]
    let $relevant.paths := 
        for $path in $svg.file//svg:path[@id = $relevant.links/self::link/@shape]
        let $id := $path/@id
        let $link := $relevant.links/self::link[@shape = $id]
            
        let $data-mei := $link/string(@item)
        return 
            <path xmlns="http://www.w3.org/2000/svg">
                { for $att in $path/@* return $att }
                { attribute data-mei {$data-mei} }
            </path>
    
    
    return
        <g xmlns="http://www.w3.org/2000/svg">
            { for $monitum in $monita return $monitum }
            { $emptyFlag }
            { $relevant.paths }
        </g>

(:let $enriched.paths :=
    for $path in $svg.file//svg:path
    let $id := $path/@id
    let $link := $links/self::link[@shape = $id]
    let $monita := 
        for $monitum in tokenize($link/@monitum,' ')
        let $att.title := 'data-mon-' || $monitum
        return attribute {$att.title} {''}
        
    let $data-mei := $link/string(@item)
    return 
        <path xmlns="http://www.w3.org/2000/svg">
            { for $att in $path/@* return $att }
            { attribute data-mei {$data-mei} }
            { for $monitum in $monita return $monitum }
        </path>:)

let $enriched.svg := 
    <svg xmlns="http://www.w3.org/2000/svg">
        { for $att in $svg.file/@* return $att }
        { $groups }
    </svg>

(:

{ attribute data-mei { $data-mei } }
{ for $monitum in $monita 
let $att-title := 'data-' || $monitum
return
    attribute $att-title {} 
}

:)
return 
$enriched.svg
(:<root 
    corpus="{$corpus.file/@xml:id}" 
    man.fil.name="{$manifestation.file.name}">
    notes: {count($manifestation.file//@class)}
    {$links}
    {$monita}
</root>:)
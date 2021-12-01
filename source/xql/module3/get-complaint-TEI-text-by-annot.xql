xquery version "3.1";

(:
    get-complaint-TEI-text-by-annot.xql

    This xQuery retrieves the text of a given emodiment (or the text itself) from a given document
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
declare namespace xi = "http://www.w3.org/2001/XInclude";

(: set output to JSON:)
declare option output:method "xml";
declare option output:media-type "text/xml";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the ID of the requested complaint, as passed by the controller :)
let $context.id := request:get-parameter('context.id','')

let $source.id := request:get-parameter('source.id','')
let $state.id := request:get-parameter('state.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: get file from database :)
(:let $file := ($database//mei:*[@xml:id = $document.id]/ancestor-or-self::mei:mei)[1]:)
let $file := ($database//mei:mei/root()/id($document.id)/ancestor-or-self::mei:mei)[1]

let $complete.file := $database//mei:meiCorpus[@xml:id = $document.id]

let $inclusion.base.uri := string-join(tokenize(document-uri($complete.file/root()),'/')[position() lt last()],'/')

let $corpus.head := $complete.file/mei:meiHead

let $mei.files :=
    for $link in $complete.file/xi:include/string(@href)
    return doc($inclusion.base.uri || '/' || $link)

let $text.file := ($mei.files[.//mei:encodingDesc[@class='#bw_module3_textFile']])[1]
let $document.files := $mei.files[.//mei:encodingDesc[@class='#bw_module3_documentFile']]

let $relevant.context := ($text.file, $document.files)/id($context.id)
let $relevant.file := $relevant.context/ancestor::mei:mei

let $xslt := $config:xslt-basepath || '../xslt/module3/get-complaint-TEI-text-by-annot.xsl' 

let $text.file.string := serialize($text.file)

let $extract := transform:transform($relevant.file,
               doc($xslt), <parameters>
                   <param name="context.id" value="{$relevant.context/string(@xml:id)}"/>
                   <param name="source.id" value="{$source.id}"/>
                   <param name="state.id" value="{$state.id}"/>
                   <param name="text.file" value="{$text.file.string}"/>
               </parameters>)

return $extract

(:return
    <params>
        <document>{$document.id}</document>
        <context>{$context.id}</context>
        <hasContext>{exists($file/root()/id($context.id))}</hasContext>
        <focus>{$focus.id}</focus>
        <hasFocus>{exists($file/root()/id($focus.id))}</hasFocus>
        <source>{$source.id}</source>
        <state>{$state.id}</state>
        <file>{exists($file)}</file>
        <rightFile>{local-name($relevant.context)}</rightFile>
        <context>{$relevant.context}</context>
    </params>:)
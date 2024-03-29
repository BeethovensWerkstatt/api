xquery version "3.1";

(:
    getAnalysis.xql
    param $comparison.id
    param $method
    param $mdiv
    param $transpose.mode
    param $hidden.staves.param
    
    This xQuery …
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response"; 

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $data.basePath := '/db/apps/api/data/module2/'
let $xslPath := '../../xslt/module2/' 

let $comparison.id := request:get-parameter('comparisonId','')
let $method := request:get-parameter('method','')
let $mdiv := request:get-parameter('mdiv','')
let $transpose.mode := request:get-parameter('transpose','')
let $hidden.staves.param := request:get-parameter('hiddenStaves','')
let $doc1.hidden.staves := if(contains($hidden.staves.param,'-')) then(substring-before($hidden.staves.param,'-')) else('')
let $doc2.hidden.staves := if(contains($hidden.staves.param,'-')) then(substring-after($hidden.staves.param,'-')) else('')

let $comparison := (collection($data.basePath)//mei:meiCorpus[@xml:id = $comparison.id])[1]

let $comparison.path.tokens := tokenize(document-uri($comparison/root()),'/')
let $comparison.path := string-join($comparison.path.tokens[position() lt count($comparison.path.tokens)],'/')

let $doc1.path := ($comparison//mei:source)[1]/data(@target)
let $doc2.path := ($comparison//mei:source)[2]/data(@target)

let $doc1 := doc(concat($comparison.path, '/', $doc1.path))
let $doc2 := doc(concat($comparison.path, '/', $doc2.path))

let $doc1.analyzed := transform:transform($doc1,
               doc(concat($xslPath,'analyze.file.xsl')), <parameters>
                   <param name="mode" value="{$method}"/>
                   <param name="mdiv" value="{$mdiv}"/>
                   <param name="transpose.mode" value="{$transpose.mode}"/>
                   <param name="hidden.staves" value="{$doc1.hidden.staves}"/>
               </parameters>)
               
let $doc2.analyzed := transform:transform($doc2,
               doc(concat($xslPath,'analyze.file.xsl')), <parameters>
                   <param name="mode" value="{$method}"/>
                   <param name="mdiv" value="{$mdiv}"/>
                   <param name="transpose.mode" value="{$transpose.mode}"/>
                   <param name="hidden.staves" value="{$doc2.hidden.staves}"/>
               </parameters>)               

let $merged.files := transform:transform(<root>{$doc1.analyzed}{$doc2.analyzed}{$comparison}</root>,
               doc(concat($xslPath,'combine.files.xsl')), <parameters>
                   <param name="method" value="{$method}"/>
                   <param name="transpose.mode" value="{$transpose.mode}"/>
               </parameters>)

return 
    $merged.files
    (:<root>{$doc1.analyzed}{$doc2.analyzed}{$comparison}</root>:)
    

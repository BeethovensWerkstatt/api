xquery version "3.1";

(:
    get_MEI_file_as_XML.xql
    
    This xQuery …
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
       
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to XML:)
declare option output:method "xml";
declare option output:media-type "text/plain";

let $edition.id := request:get-parameter('edition.id','')
let $state.raw := request:get-parameter('state.id','')
let $other.states.raw := request:get-parameter('other.states','')

let $xslPath := '../../xslt/module1/' 

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]

let $state.id := 
    if(string-length($state.raw) gt 0 and $doc//mei:state[@xml:id = $state.raw])
    then($state.raw)
    else(($doc//mei:state[1])/string(@xml:id))
    
let $other.states.ids :=
    if(string-length($other.states.raw) gt 1)
    then(
        for $token in tokenize($other.states.raw,'___') 
        (:where $token eq $doc//mei:state/@xml:id:)
        return
            $token
    )
    else(
        $state.id
    )

let $snippet := transform:transform($doc,
               doc(concat($xslPath,'getState.xsl')), <parameters><param name="active.states.string" value="{string-join($other.states.ids,'___')}"/><param name="main.state.id" value="{$state.id}"/></parameters>)

return 
    $snippet
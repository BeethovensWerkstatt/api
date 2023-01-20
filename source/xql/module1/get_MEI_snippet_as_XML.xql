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
let $element.id := request:get-parameter('element.id','')

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]
let $elem := $doc/id($element.id)

return 
    $elem
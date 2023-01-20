xquery version "3.1";

(:
    get_geneticStatesList_as_JSON.xql
    
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

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

let $edition.id := request:get-parameter('edition.id','')

let $doc := collection($config:module1-root)
let $categories := distinct-values($doc//mei:genDesc/tokenize(replace(@decls,'#',''),' '))
    

return array { $categories }
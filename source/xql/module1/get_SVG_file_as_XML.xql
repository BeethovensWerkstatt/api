xquery version "3.1";

(:
    get_SVG_file_as_XML.xql
    
    This xQuery …
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace local="no:where";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
       
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to XML:)
declare option output:method "xml";
declare option output:media-type "text/plain";

(: return a deep copy of the elements and attributes without ANY namespaces :)
declare function local:remove-namespaces($element as element()) as element() {
     element { local-name($element) } {
         for $att in $element/@*
         return
             attribute {local-name($att)} {$att},
         for $child in $element/node()
         return
             if ($child instance of element())
             then local:remove-namespaces($child)
             else $child
         }
};

let $file.id := request:get-parameter('file.id','')

let $svg := collection($config:module1-root)//svg:svg[@id = replace($file.id,'.svg','')]

return 
    local:remove-namespaces($svg)
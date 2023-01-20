xquery version "3.1";

(:
    get_introduction_as_HTML.xql
    
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

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]
let $notes := $doc//mei:fileDesc/mei:notesStmt

let $xslPath := '../../xslt/module1/' 

let $text := transform:transform($notes,
               doc(concat($xslPath,'mei2html.xsl')), <parameters><param name="purpose" value="getIntroduction"/></parameters>)


return 
    <div class="meiTextView">
        <h1>{$doc//mei:fileDesc//mei:title[@type = 'editionTitle']//text()}</h1>
        {$text}
    </div>
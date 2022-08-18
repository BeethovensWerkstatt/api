xquery version "3.1";

(:
    module4-get-documents.xql

    This xQuery retrieves a list of all documents for which a IIIF manifest can be provided
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

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get all files that 
    - have an xml:id
    - have an identifier that assigns them with module 3
    - have no facsimiles in them (TODO: find a better way to identify work files, maybe using @class)
:)
let $files :=
  for $file in $database//mei:encodingDesc[every $class in ('#bw_module4','#bw_document_file') satisfies ($class = tokenize(normalize-space(@class), ' '))]/root()/mei:mei
  
  let $document.id := $file/string(@xml:id)
  let $external.id := ef:getDocumentLink($document.id)
  
  let $title := 
    for $title in $file/mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title[@type = 'main']
    return map {
      'title': $title/text(),
      '@lang': $title/string(@xml:lang)
    }
    
  let $composer.elem := $file//mei:fileDesc/mei:titleStmt/mei:composer/mei:persName
  let $composer := map {
    'name': $composer.elem/text(),
    '@id': $composer.elem/string(@auth.uri) || $composer.elem/string(@codedval),
    'internalId': $composer.elem/string(@xml:id)
  }
  
  let $staticExample := '#bw_module3_staticExample' = distinct-values($file//mei:encodingDesc/tokenize(normalize-space(@class),' '))
  let $level := 
    if($staticExample)
    then('external')
    else('videapp')
  
  return map {
    '@id': $external.id,
    'title': array { $title },
    'composer': $composer,
    'level': $level
  }



return array { $files }

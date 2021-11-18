xquery version "3.1";

(:
    module3-get-works.xql

    This xQuery retrieves a list of all documents for which a IIIF manifest can be provided
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

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:module3-root)

(: get all files that 
    - have an xml:id
    - have an identifier that assigns them with module 3
    - have no facsimiles in them (TODO: find a better way to identify work files, maybe using @class)
:)
let $files :=
  for $file in $database//mei:meiCorpus[@xml:id]
  let $rawTitle := $file/mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title[@type = 'main']/text()
  let $opusNum := 
    if(contains($rawTitle,'Op.'))
    then(xs:integer(normalize-space(substring-after($rawTitle,'Op.'))))
    else if(contains($rawTitle,'WoO'))
    then(xs:integer(normalize-space(substring-after($rawTitle,'WoO'))) + 1000)
    else(5000)    
  
  order by $opusNum ascending
  
  let $workCorpus.id := $file/string(@xml:id)
  let $external.id := $config:module3-basepath || $workCorpus.id || '.json'
  let $title := 
    for $title in $file/mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title[@type = 'main']
    return map {
      'title': $title/text() || ' (corpus file)',
      '@lang': $title/string(@xml:lang)
    }
    
  let $composer.elem := $file//mei:fileDesc/mei:titleStmt/mei:composer/mei:persName
  let $composer := map {
    'name': $composer.elem/text(),
    '@id': $composer.elem/string(@auth.uri) || $composer.elem/string(@codedval),
    'internalId': $composer.elem/string(@xml:id)
  }
  
  return map {
    '@id': $external.id,
    'title': array { $title },
    'composer': $composer
  }



return array { $files }

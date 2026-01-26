xquery version "3.1";

(:
    get-editions.xql

    This xQuery retrieves a list of all editions available
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

let $files :=
  for $file in $database//mei:encodingDesc[every $class in ('#bw_edition_file') satisfies ($class = tokenize(normalize-space(@class), ' '))]/root()/mei:meiCorpus
  
  let $document.id := $file/string(@xml:id)
  let $external.id := ef:getDocumentLink($document.id)
  
  let $title := 
    for $title in $file/mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title
    return map {
      'title': normalize-space($title/text()),
      '@lang': if ($title/@xml:lang) then($title/string(@xml:lang)) else('de')
    }

  let $classes := $file//mei:encodingDesc/tokenize(normalize-space(string(@class)), ' ')
  let $modules := $classes[starts-with(., '#bw_module')]

  let $sources := 
    for $source in $file/mei:meiHead/mei:fileDesc/mei:sourceDesc/mei:source
    let $basePath := document-uri($file/root())
    let $relPath := normalize-space($source/string(@target))
    let $uri := resolve-uri($relPath, $basePath)
    let $available := doc-available($uri)
    let $doc := doc($uri)
    let $docId := $doc//mei:mei/string(@xml:id)
    return map {
      'editionId': normalize-space($source/string(@xml:id)),
      'label': normalize-space($source/string(@label)),
      'sourceId': if ($available) then($docId) else('')
    }

  return map {
    '@id': $document.id,
    'title': array { $title },
    'sources': array { $sources },
    'modules': array { $modules }
  }

return array { $files }

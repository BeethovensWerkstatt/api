xquery version "3.1";

(:
    get-work.xql

    This xQuery retrieves relevant information about a work from the third module of Beethovens Werkstatt
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

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

let $document.uri := $config:module3-basepath || $document.id || '.json'

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

let $title := 
    for $title in $file//mei:fileDesc/mei:titleStmt/mei:title
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
  
let $manifestations := 
    for $manifestationRef in $file//mei:manifestation
    let $label := $manifestationRef/string(@label)
    let $manifestation.filename := 
        if(contains($manifestationRef/@sameas,'/')) 
        then(tokenize($manifestationRef/@sameas,'/')[last()]) 
        else($manifestationRef/string(@sameas))
    let $manifestation.file := $database/element()[tokenize(document-uri(./root()),'/')[last()] = $manifestation.filename]
    where exists($manifestation.file) and exists($manifestation.file/@xml:id)
    let $manifestation.id := $manifestation.file/string(@xml:id)
    let $manifestation.namespace := namespace-uri($manifestation.file)
    let $manifestation.external.id := $config:module3-basepath || $document.id || '/manifestation/' || $manifestation.id || '.json'
    
    let $iiif.manifest := $config:iiif-basepath || 'document/' || $manifestation.id || '/manifest.json'
    
    return map {
      '@id': $manifestation.id,
      'label': $label,
      'file': map {
        'uri': $config:file-basepath || $manifestation.id || '.xml',
        '@ns':  $manifestation.namespace,
        'name': $manifestation.filename
      },
      'frbr': map {
        'level': 'manifestation'
      },
      'iiif': map {
        'manifest': $iiif.manifest
      }
    }
return map {
    '@id': $document.uri,
    'title': array { $title },
    'composer': $composer,
    'manifestations': $manifestations
}



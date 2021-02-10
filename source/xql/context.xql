xquery version "3.1";

(:
    context.xql

    This xQuery generates a (static) list of JSON-LD context definitions
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "../xqm/config.xqm";

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

(: get the ID of the requested document, as passed by the controller :)
let $version := request:get-parameter('version','')

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $definitions := 

if($version = '1')
then(
    map {
      'iiif': 'http://iiif.io/api/image/2#',
      'frbr': 'http://purl.org/vocab/frbr/core#',
      
      
      'manifestation': map {
        '@type': '@id',
        '@id': 'frbr:Manifestation'
      },
      'manifestations': map {
        '@type': '@id',
        '@id': 'frbr:Manifestation',
        '@container': '@list'
      }
    }
)
else ('')

return map {
  '@context': array {
    $definitions   
  }
}

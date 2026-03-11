xquery version "3.1";

(:
    get-transcription-details.xql

    This xQuery retrieves details for a specific genetic description (genDesc),
    including transcription information.
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
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace range="http://exist-db.org/xquery/range";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace local="http://www.beethovens-werkstatt.de";

(: set output to JSON :)
declare option output:method "xml";
declare option output:media-type "image/svg+xml";

let $fileName := request:get-parameter('fileName', '')

let $paddedPage := fn:analyze-string($fileName, 'p(\d{3})')/fn:match/string()
let $paddedWz   := fn:analyze-string($fileName, 'wz(\d{2})')/fn:match/string()

let $docType := 
  if (ends-with($fileName, '_at.svg')) 
  then '/annotatedTranscripts/' 
  else if (ends-with($fileName, '_dt.svg')) 
  then '/diplomaticTranscripts/' 
  else if (ends-with($fileName, '_ft.svg'))
  then '/fluidTranscripts/' 
  else ''

let $docName := substring-before($fileName, '_' || $paddedPage || '_' || $paddedWz)

let $path := $config:data-cache-root || 'sources/' || $docName || $docType || $paddedPage || '/' || $fileName

let $doc := doc($path)
return
    $doc
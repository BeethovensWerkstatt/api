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
declare option output:method "json";
declare option output:media-type "application/json";

let $genDescId := request:get-parameter('genDescId', '')

let $genDesc := collection($config:data-root)//id($genDescId)[1]
let $sourceDoc := $genDesc/root()
let $docNameTokens := $sourceDoc => document-uri() => tokenize('/')
let $docName := $docNameTokens[last()] => substring-before('.xml')

let $wzN := $genDesc/string(@label)
let $paddedWzN := string-join(('wz', substring('00' || $wzN, string-length($wzN) + 1)), '')

let $pageGenDesc := $genDesc/parent::mei:genDesc

let $pageN := $pageGenDesc/string(@n)
let $paddedPageN := string-join(('p', substring('000' || $pageN, string-length($pageN) + 1)), '')

let $baseName := $docName || '_' || $paddedPageN || '_' || $paddedWzN

let $atMeiName := $baseName || '_at.xml'
let $atSymlinkName := $baseName || '_symlink.xml'
let $atSvgName := $baseName || '_at.svg'
let $dtMeiName := $baseName || '_dt.xml'
let $dtSvgName := $baseName || '_dt.svg'

let $atInternalSvgPath := $config:data-cache-root || 'sources/' || $docName || '/annotatedTranscripts/' || $paddedPageN || '/' || $atSvgName
let $atApiSvgPath := $config:prerendered-basepath || $atSvgName

let $dtInternalMeiPath := $config:data-root || 'sources/' || $docName || '/diplomaticTranscripts/' || $dtMeiName
let $dt := if (doc-available($dtInternalMeiPath)) then doc($dtInternalMeiPath) else ()

let $atInternalMeiPath := $config:data-root || 'sources/' || $docName || '/annotatedTranscripts/' || $atMeiName
let $atInternalSymlinkPath := $config:data-root || 'sources/' || $docName || '/annotatedTranscripts/' || $atSymlinkName

let $rightAtPath := 
  if (doc-available($atInternalMeiPath)) then $atInternalMeiPath
  else if (doc-available($atInternalSymlinkPath)) then 
  (
    let $symlinkDoc := doc($atInternalSymlinkPath)
    let $target := $symlinkDoc//@target/string()
    let $fileName := tokenize($target, '/')[last()]
    let $targetPath := resolve-uri($target, base-uri($symlinkDoc))
    let $symlinkedAtDoc := if (doc-available($targetPath)) then ($targetPath) else ()
    return $symlinkedAtDoc
  )
  else ()

let $at := 
  if (doc-available($rightAtPath)) 
  then doc($rightAtPath) 
  else ()

let $systems := 
  for $system in $at//mei:sb
  let $doc := tokenize($system/@corresp,'/')[last()] => substring-before('#')
  let $id := substring-after($system/@corresp,'#')
  return map {
    'id': $id,
    'dt': $config:prerendered-basepath || replace($doc, '_dt.xml', '_sys' || $id || '_dt.svg'),
    'at': $config:prerendered-basepath || replace($doc, '_dt.xml', '_sys' || $id || '_at.svg')
  }

let $dtSvgPath := $config:prerendered-basepath || $dtSvgName

return
    if ($genDescId = '') then
        map {
            'error': 'Missing required parameter: genDescId'
        }
    else
        map {
            'id': $genDescId,
            'doc': map {
              'source': $docName,
              'page': $pageN,
              'wz': $wzN
            },
            'at': map {
              'name': tokenize($rightAtPath, '/')[last()],
              'symlinked': tokenize($rightAtPath, '/')[last()] ne $atMeiName,
              'uri': $config:prerendered-basepath || tokenize($rightAtPath, '/')[last()]
            },
            'dt': map {
              'name': $dtMeiName,
              'uri': $config:prerendered-basepath || $dtMeiName
            },
            'systems': array { $systems }
        }

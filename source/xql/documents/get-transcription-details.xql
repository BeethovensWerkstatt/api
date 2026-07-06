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

let $atDtLinks := map:merge(
  for $elem in $at//mei:*[@corresp][ancestor::mei:scoreDef or ancestor-or-self::mei:measure]
  return map:entry(
    $elem/@xml:id/string(),
    array { for $corresp in ($elem/@corresp => normalize-space() => tokenize(' ')) return substring-after($corresp, '#') }
  )
)

let $writingZones := 
  for $wz in $at//mei:annot[@class = '#bw_writingZoneBegin']
  let $wzId := $wz/@xml:id/string()
  let $genDescId := substring-after($wz/@corresp, '#')
  let $genDescFilePath := resolve-uri(substring-before($wz/@corresp, '#'), base-uri($at))
  let $genDesc := if (doc-available($genDescFilePath)) then doc($genDescFilePath)/id($genDescId) else ()
  let $zone := doc($genDescFilePath)/range:field-eq("zone-data", '#' || $genDescId)[1]
  let $surface := $zone/ancestor::mei:surface[1]
  let $surfaceId := $surface/@xml:id/string()
  let $graphic := $surface/mei:graphic[@type = 'facsimile'][1]
  let $shapesGraphic := $surface/mei:graphic[@type = 'shapes'][1]
  let $allFoliumLike := doc($genDescFilePath)//mei:foliaDesc//mei:*
  let $foliumLike := $allFoliumLike[some $att in @* satisfies ($att eq ('#' || $surfaceId))][1]
  let $shapesGroupId := substring-after($genDesc/@corresp,'#')
  let $prerenderedDtAllSystems := $config:prerendered-basepath || $dtSvgName

  let $dtFileLink := substring-before($wz/following::mei:sb[1]/@corresp/string(),'#')
  let $dtFileUri := resolve-uri($dtFileLink, base-uri($at))
  let $dtFile := if (doc-available($dtFileUri)) then doc($dtFileUri) else ()
  let $dtShapeLinks := map:merge(
    for $elem in $dtFile//mei:*[@facs]
    return map:entry(
      $elem/@xml:id/string(),
      array { for $facs in ($elem/@facs => normalize-space() => tokenize(' ')) return substring-after($facs, '#') }
    )
  )
  let $systems := 
    for $system in $wz/following::mei:sb[preceding::mei:annot[@class = '#bw_writingZoneBegin'][1]/@xml:id/string() = $wzId]
    let $docName := tokenize($system/@corresp,'/')[last()] => substring-before('#')
    let $id := substring-after($system/@corresp,'#')
    let $dtSystem := $dtFile/id($id)
    let $firstRastrumId := ($dtSystem//mei:staffDef)[1]/@decls => substring-after('#')
    let $rastrum := $sourceDoc/id($firstRastrumId)
    let $rotation := if ($rastrum) then $rastrum/@rotate/number() else 0
    return map {
      'id': $id,
      'dt': $config:prerendered-basepath || replace($docName, '_dt.xml', '_sys' || $id || '_dt.svg'),
      'at': $config:prerendered-basepath || replace($docName, '_dt.xml', '_sys' || $id || '_at.svg'),
      'ft': $config:prerendered-basepath || replace($docName, '_dt.xml', '_sys' || $id || '_ft.svg'),
      'rotation': map {
        'pivot': map {
          'x': $rastrum/@system.leftmar/number(),
          'y': $rastrum/@system.topmar/number()
        },
        'angle': $rotation
      }
    }

  return map {
    'id': $genDescId,
    'doc': substring-before(tokenize(substring-before(normalize-space($wz/@corresp), '#'),'/')[last()],'.xml'),
    'n': $genDesc/@label/string(),
    'page': map {
      'label' : $surface/@label/string(),
      'id' : $surface/@xml:id/string(),
      'image': $graphic/@target/string(),
      'shapes': $config:svg-shapes-basepath || tokenize($shapesGraphic/@target/string(), '/')[last()],
      'shapesGroupId': $shapesGroupId,
      'px': map {
        'height': $graphic/@height/number(),
        'width': $graphic/@width/number()
      },
      'mm': map {
        'height': $foliumLike/@height/number(),
        'width': $foliumLike/@width/number()
      }
    },
    'rect': map {
      'x': $zone/@ulx/number(),
      'y': $zone/@uly/number(),
      'w': $zone/@lrx/number() - $zone/@ulx/number(),
      'h': $zone/@lry/number() - $zone/@uly/number()
    },
    'renderedWz': $prerenderedDtAllSystems,
    'shapeLinks': $dtShapeLinks,
    'systems': array { $systems }
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
              'uri': $config:prerendered-basepath || tokenize($rightAtPath, '/')[last()],
              'renderedSvg': $config:prerendered-basepath || tokenize($rightAtPath, '/')[last()] => replace('_at.xml', '_at.svg'),
              'dtLinks': $atDtLinks
            },
            'ft': map {
              'uri': $config:prerendered-basepath || replace($dtSvgName, '_dt.svg', '_ft.svg')
            },
            'dt': map {
              'name': $dtMeiName,
              'uri': $config:prerendered-basepath || $dtMeiName
            },
            'writingZones': array { $writingZones }
        }

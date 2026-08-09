xquery version "3.1";

(:
    get-document-overview.xql

    This xQuery retrieves an overview of a specific document, including page info, writing zones etc.
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

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(:~
 : Get pixel dimensions and cropping info from a graphic element
 :
 : @param $graphicFacs The mei:graphic element
 : @return Map with width, height, xywh and rotation
 :)
declare function local:getPx($graphicFacs as element(mei:graphic)) as map(*) {
  let $width := number($graphicFacs/@width)
  let $height := number($graphicFacs/@height)
  let $params := if ($graphicFacs/string(@target) => contains('#xywh=')) then ($graphicFacs/string(@target) => substring-after('#xywh=')) else ('')
  let $amp := '&amp;amp;'
  let $xywhString := 
    if ($params != '' and contains($params, 'rotate=')) 
    then (
      let $tooMuch := substring-before($params, 'rotate=')
      let $justRight := substring($tooMuch, 1, string-length($tooMuch) - 1)
      return $justRight
    )
    else if ($params != '')
    then ($params)
    else ('')
  let $xywhArray := tokenize($xywhString, ',')
  let $x := if ($xywhString != '') then (number($xywhArray[1])) else (0)
  let $y := if ($xywhString != '') then (number($xywhArray[2])) else (0)
  let $w := if ($xywhString != '') then (number($xywhArray[3])) else ($width)
  let $h := if ($xywhString != '') then (number($xywhArray[4])) else ($height)
  let $rotation := 
    if (contains($params, 'rotate=')) 
    then (number(substring-after($params, 'rotate='))) 
    else (0)
  return map {
    'width': $width,
    'height': $height,
    'xywh': map {
      'x': $x,
      'y': $y,
      'w': $w,
      'h': $h
    },
    'rotation': $rotation
  }
};

(:~
  : Get properties of the diplomatic transcription of a writing zone
  :
  : @param $dt The diplomatic transcription document
  : @param $surface The surface element containing the writing zone
  : @param $genDescWz The genDesc element for the writing zone
  : @param $genDescId The id of the genDesc element
  : @return Map of diplo properties
  :)
declare function local:getDiploProperties($dt, $surface as element(mei:surface), $genDescWz as element(mei:genDesc), $genDescId as xs:string) as map(*) {
  let $metaClarification := exists($dt//mei:metaMark[@function = 'clarification'])
  let $metaNavigation := exists($dt//mei:metaMark[@function = 'navigation'])
  let $otherMeta := exists($dt//mei:metaMark[@function and not(@function = ('clarification', 'navigation'))])
  let $layers := 
    if ($genDescWz/mei:genState['#bw_textStufe' = tokenize(normalize-space(@class), ' ')])
    then (
      array { 
        for $layer in $genDescWz/mei:genState['#bw_textStufe' = tokenize(normalize-space(@class), ' ')]
        let $layerId := $layer/string(@xml:id)
        return $layerId
      }
    )
    else (
      array { 
        for $layer in $genDescWz/mei:genState
        let $layerId := $layer/string(@xml:id)
        return $layerId
      }
    )
  
  let $staves := count(distinct-values($dt//mei:staffDef[string(@n)]))
  let $pos := 
    let $zone := $surface//mei:zone[@data = '#' || $genDescId]
    let $x := number($zone/@ulx)
    let $y := number($zone/@uly)
    let $w := round(number($zone/@lrx) - $x)
    let $h := round(number($zone/@lry) - $y)
    let $rotate := if ($zone/@rotate) then (number($zone/@rotate)) else (0)
    return map {
      'x': $x,
      'y': $y,
      'w': $w,
      'h': $h,
      'rotate': $rotate
    }
  return map {
    'metaClarification': $metaClarification,
    'metaNavigation': $metaNavigation,
    'otherMeta': $otherMeta,
    'layers': $layers,
    'staves': $staves,
    'pos': $pos
  }
};

(:~
 : Get properties of the annotated transcript of a writing zone
 :
 : @param $at The sketch transcription document
 : @return Map of sketch properties
 :)
declare function local:getSketchProperties($at) as map(*) {
  let $tempo := (: $at/child::node()[1]/local-name() :)
    let $val := if ($at//mei:tempo) then (($at//mei:tempo)[1]/string-join(text(), ' ') => normalize-space()) else ('')
    let $supplied := not(exists($at//mei:tempo/@corresp)) and not($val eq '')
    return map {
      'val': $val,
      'supplied': $supplied
    }
  let $meterSig := 
    let $val := if ($at//mei:meterSig) then (($at//mei:meterSig)[1]/string(@count) || '/' || ($at//mei:meterSig)[1]/string(@unit)) else ('')
    let $supplied := not(exists(($at//mei:meterSig)[1]/@corresp))
    return map {
      'val': $val,
      'supplied': $supplied
    }
  let $keySig :=
    let $val := if ($at//mei:staffDef[1]//mei:keyAccid) then(($at//mei:staffDef)[1]/count(descendant::mei:keyAccid) || ($at//mei:staffDef)[1]//mei:keyAccid[1]/string(@accid)) else('0')
    let $supplied := exists(($at//mei:scoreDef)[1]//mei:keyAccid[not(@corresp)])
    return map {
      'val': $val,
      'supplied': $supplied
    }
  let $atMeasures := count($at//mei:measure)
  let $staves := count(distinct-values($at//mei:staffDef[string(@n)]))
  let $writingZones := array {
    for $annot in $at//mei:annot['#bw_writingZoneBegin' = tokenize(normalize-space(@class), ' ')]
    return $annot/substring-after(@corresp, '#')
  }
  return map {
    'tempo': $tempo,
    'meterSig': $meterSig,
    'keySig': $keySig,
    'atMeasures': $atMeasures,
    'writingZones': $writingZones,
    'staves': $staves
  }
};

(:~
 : Get work relations for a given annotated transcript
 :
 : @param $at The sketch transcription document
 : @return Array of work relation maps
 :)
declare function local:getWorkRelations($at) as map(*)* {
  let $ref := string(tokenize(document-uri($at), '/')[last()])
  let $allRelations := 
    if ($ref and $ref != '') then
      collection($config:data-root || 'links')/range:field-ends-with("relation-plist", string($ref)) (:/*[ends-with(@rel, $ref)]:)
    else ()
  let $relations := 
    for $relation in $allRelations
    let $relationId := $relation/string(@xml:id)
    let $type := $relation/string(@rel)
    let $targetRaw := $relation/string(@target)
    let $opus := tokenize(substring-before($targetRaw, '#'),'/')[last() -1]
    let $workFile := doc(resolve-uri(substring-before($targetRaw, '#'), document-uri($relation/root())))
    let $work := ($workFile//mei:title)[1]/normalize-space(text())
    let $targetRef := substring-after($targetRaw, '#')
    let $target := 
      if ($targetRef => contains('range('))
      then (
        let $startId := substring-before(substring-after($targetRef, "range('"), "','")
        let $endId := substring-before(substring-after($targetRef, "','"), "')")
        let $start := 
          let $startElem := $workFile/id($startId)
          let $name := $startElem/local-name()
          let $id := $startId
          let $mdiv := $startElem/ancestor::mei:mdiv[1]
          let $label := 
            if ($startElem/@label) 
            then ($startElem/string(@label)) 
            else if ($startElem/@n) 
            then ($startElem/string(@n)) 
            else (string((count($startElem/preceding-sibling::*) + 1)))
          let $mdivPos := $mdiv/count(preceding::mei:mdiv) + 1
          let $mdivLabel := 
            if ($mdiv/@label) 
            then ($mdiv/string(@label)) 
            else if ($mdiv/@n) 
            then ($mdiv/string(@n))
            else (string($mdivPos))
          return map {
            'name': $name,
            'id': $id,
            'mdivPos': $mdivPos,
            'mdivLabel': $mdivLabel,
            'label': $label
          }
        let $end := 
          let $endElem := $workFile/id($endId)
          let $name := $endElem/local-name()
          let $id := $endId
          let $mdiv := $endElem/ancestor::mei:mdiv[1]
          let $label := 
            if ($endElem/@label) 
            then ($endElem/string(@label)) 
            else if ($endElem/@n) 
            then ($endElem/string(@n)) 
            else (string((count($endElem/preceding-sibling::*) + 1)))
          let $mdivPos := $mdiv/count(preceding::mei:mdiv) + 1
          let $mdivLabel := 
            if ($mdiv/@label) 
            then ($mdiv/string(@label)) 
            else if ($mdiv/@n) 
            then ($mdiv/string(@n))
            else (string($mdivPos))
          return map {
            'name': $name,
            'id': $id,
            'mdivPos': $mdivPos,
            'mdivLabel': $mdivLabel,
            'label': $label
          }
        return map {
          'start': $start,
          'end': $end
        }
      )
      else (
        let $targetElem := $workFile/id($targetRef)
        let $name := $targetElem/local-name()
        let $id := $targetRef
        let $mdiv := $targetElem/ancestor::mei:mdiv[1]
        let $label := 
          if ($targetElem/@label) 
          then ($targetElem/string(@label)) 
          else if ($targetElem/@n) 
          then ($targetElem/string(@n)) 
          else (string((count($targetElem/preceding-sibling::*) + 1)))
        let $mdivPos := $mdiv/count(preceding::mei:mdiv) + 1
        let $mdivLabel := 
          if ($mdiv/@label) 
          then ($mdiv/string(@label)) 
          else if ($mdiv/@n) 
          then ($mdiv/string(@n))
          else (string($mdivPos))
        return map {
          'name': $name,
          'id': $id,
          'mdivPos': $mdivPos,
          'mdivLabel': $mdivLabel,
          'label': $label
        }
      )
    
    return map {
      'relationId': $relationId,
      'type': $type,
      'work': $work,
      'opus': $opus,
      'target': $target
    }
  return $relations (: map { 'allRelations': count($allRelations), 'dataRoot': $config:data-root || 'links/' } :) (:  :)
};

(:~
 : Get details of a writing zone
 :
 : @param $genDescWz The genDesc element for the writing zone
 : @param $surface The surface element containing the writing zone
 : @param $database The database collection
 : @return Map with writing zone details
 :)
declare function local:getWritingZoneDetails($genDescWz as element(mei:genDesc), $surface as element(mei:surface), $database) as map(*) {
  let $label := $genDescWz/string(@label)
  let $sourceRef := '#' || $genDescWz/string(@xml:id)
  let $sources := $database//mei:source[contains(@target, $sourceRef)]
  
  let $at := 
    for $source in $sources
    let $doc := $source/root()
    let $uri := document-uri($doc)
    where ends-with($uri, '_at.xml')
    return $doc
  let $dt := 
    for $source in $sources
    let $doc := $source/root()
    let $uri := document-uri($doc)
    where ends-with($uri, '_dt.xml')
    return $doc

  let $genDescId := $genDescWz/string(@xml:id)
  let $identifier :=
    let $svgId := $genDescWz/substring-after(@corresp,'#')
    let $zoneId := $surface//mei:zone[@data = '#' || $genDescId]/string(@xml:id)
    let $atFilename := tokenize(document-uri($at),'/')[last()]
    let $dtFilename := tokenize(document-uri($dt), '/')[last()]
    return map {
      'svgId': $svgId,
      'genDescId': $genDescId,
      'zoneId': $zoneId,
      'atFilename': $atFilename,
      'dtFilename': $dtFilename
    }
  let $wzProps := local:getDiploProperties($dt, $surface, $genDescWz, $genDescId)
  
  let $sketchProps := local:getSketchProperties($at)
  
  let $workRelations := local:getWorkRelations($at)
  
  return map {
    'label': $label,
    'identifier': $identifier,
    'wzProps': $wzProps,
    'sketchProps': $sketchProps,
    'workRelations': array { $workRelations }
  }
};

declare function local:parsePage ($elem as element(), $foliumType as xs:string, $whichFolioSide as xs:string, $geneticOperations as array(*), $mm as map(*), $database) as map(*) {
  let $foliumId := $elem/string(@xml:id)
  
  let $position := $whichFolioSide
  let $surfaceRef := $elem/string(@*[local-name() = $position])
  let $sourceDoc := tokenize($surfaceRef, '/')[last()] => substring-before('#') => replace('_', ' ')
  
  let $surfaceId := substring-after($surfaceRef, '#')
  let $surface := $database/id($surfaceId)
      
  let $graphicFacs := $surface/mei:graphic[@type = 'facsimile']
  let $layoutId := $surface/substring-after(@decls,'#')
  let $surfaceLabel := 
    if ($surface/@label) 
    then ($surface/string(@label)) 
    else if ($surface/@n) 
    then ($surface/string(@n)) 
    else (string((count($surface/preceding-sibling::mei:surface) + 1)))

  let $target := $graphicFacs/string(@target) => substring-before('#')
  let $px := local:getPx($graphicFacs)
    
  let $genDesc := $surface/root()//mei:genDesc[@corresp = '#' || $surface/@xml:id][1]
      
  let $writingZones := 
    for $genDescWz in $genDesc/mei:genDesc['#geneticOrder_writingZoneLevel' = tokenize(normalize-space(@class),' ')]
    return local:getWritingZoneDetails($genDescWz, $surface, $database)
  
  return map {
    "position": $position,
    "target": $target,
    "surfaceDoc": $sourceDoc,
    "sourceId": $surface/ancestor::mei:mei/string(@xml:id),
    "px": $px,
    "layoutId": $layoutId,
    "foliumId": $foliumId,
    "writingZones": array { $writingZones },
    "surfaceLabel": $surfaceLabel,
    "mm": $mm,
    "surfaceId": $surfaceId,
    "shapesLink": if ($surface/mei:graphic[@type = 'shapes']) then ($config:svg-shapes-basepath || tokenize($surface/mei:graphic[@type = 'shapes']/@target/string(), '/')[last()]) else ('')
  }

};

declare function local:parseFoliumLike ($elem as element(), $database) as map(*)* {
    let $foliumType := $elem/local-name()
    let $mm := map { 'width': number($elem/@width), 'height': number($elem/@height) }
    
    let $geneticOperations := 
      let $allAncestors := $elem/ancestor::mei:*
      let $stopAncestors := $elem/ancestor::mei:*[local-name() = ('bifolium', 'foliaDesc')]
      let $ancestors := 
        for $ancestor in $allAncestors[ancestor::mei:*[. = $stopAncestors[1]]]
        return map { 
          'edit': $ancestor/local-name(),
          'id': $ancestor/string(@xml:id),
          'state': if ($ancestor/@state) then ($ancestor/string(@state)) else(())
        }
      return array { for $a in $ancestors return $a }

    let $pages := 
      if ($foliumType = 'bifolium') then (
        let $or := local:parsePage($elem, $foliumType, 'outer.recto', $geneticOperations, $mm, $database)
        let $iv := local:parsePage($elem, $foliumType, 'inner.verso', $geneticOperations, $mm, $database)
        let $children := for $child in $elem/child::mei:* return local:iterateFoliumLike($child, $database)
        let $ir := local:parsePage($elem, $foliumType, 'inner.recto', $geneticOperations, $mm, $database)
        let $ov := local:parsePage($elem, $foliumType, 'outer.verso', $geneticOperations, $mm, $database)
        return ($or, $iv, $children, $ir, $ov)
      ) else (
        (: single folium :)
        let $r := local:parsePage($elem, $foliumType, 'recto', $geneticOperations, $mm, $database)
        let $v := local:parsePage($elem, $foliumType, 'verso', $geneticOperations, $mm, $database)
        return ($r, $v)
      )

    return $pages
};

declare function local:iterateFoliumLike ($elem as element(), $database) as map(*)* { 
    let $name := $elem/local-name()
    let $result := 
      if (not($elem instance of element(mei:bifolium) or $elem instance of element(mei:folium) or $elem instance of element(mei:unknownFoliation)))
      then (
          for $child in $elem/child::mei:*
          return local:iterateFoliumLike($child, $database)
      )
      else ( local:parseFoliumLike($elem, $database) )
    return $result
};


(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)
let $documentId := request:get-parameter('documentId','')

let $sourceDoc := $database//id($documentId)

let $manifestationId := $sourceDoc//mei:manifestation/string(@xml:id)
let $manifestLink := $config:iiif-basepath ||  'document/' || $manifestationId || '/manifest.json'

let $mainTitle := if ($sourceDoc//mei:title[@type = 'main'] and ($sourceDoc//mei:title[@type = 'main'])[1]/normalize-space(text()) ne '')
  then (($sourceDoc//mei:title[@type = 'main'])[1]/normalize-space(text()))
  else ('unknown')
let $abbrevTitle := if ($sourceDoc//mei:title[@type = 'abbreviated'] and ($sourceDoc//mei:title[@type = 'abbreviated'])[1]/normalize-space(text()) ne '')
  then (($sourceDoc//mei:title[@type = 'abbreviated'])[1]/normalize-space(text()))
  else ('unknown')

(: if document not found, return error :)
let $output :=
    if(not(exists($sourceDoc)))
    then(
      response:set-status-code(404),
      map {
        'error': 404,
        'message': 'Document not found',
        'requestedDocument': $documentId
      }
    )
    else(
      let $folia := 
        for $foliumLike in $sourceDoc//mei:foliaDesc/mei:*
        return local:iterateFoliumLike($foliumLike, $database)
      return map {
        'source': map {
          'pages': array { $folia },
          'manifest': $manifestLink,
          'label': $abbrevTitle
        },
        'id': $documentId,
        'title': $mainTitle
      }
    )

return array { $output }

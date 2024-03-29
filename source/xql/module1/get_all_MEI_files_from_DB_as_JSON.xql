xquery version "3.1";

(:
    get_all_MEI_files_from_DB_as_JSON.xql
    
    This xQuery …
:)

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(:
    $preview.width and .height are used to specify the dimensions 
    of a preview image of the edition, which can be displayed as
    "appetizer" for the edition. Dimensions are actually doubled 
    (to prepare for for retina displays)
:)
let $preview.width := 240
let $preview.height := 180

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $all.docs := collection($config:module1-root)//mei:mei[mei:meiHead/mei:altId[@type = 'VideApp']]
let $works := distinct-values($all.docs//mei:altId[@type = 'VideApp' and @subtype = 'work']/@label)
let $docs := 
    for $work in $works
    let $files := $all.docs[.//mei:altId[@type = 'VideApp' and @subtype = 'work' and @label = $work]]
    let $versions := distinct-values($files//mei:altId[@type = 'VideApp' and @subtype = 'version']/@n)
    let $max.level1 := max(for $version in $versions return number(tokenize($version,'\.')[1]))
    let $versions.max1 := $versions[number(tokenize(.,'\.')[1]) = $max.level1]
    let $max.level2 := max(for $version in $versions.max1 return number(tokenize($version,'\.')[2]))
    let $versions.max2 := $versions.max1[number(tokenize(.,'\.')[2]) = $max.level2]
    let $max.level3 := max(for $version in $versions.max2 return number(tokenize($version,'\.')[3]))
    let $current.version := $versions.max2[number(tokenize(.,'\.')[3]) = $max.level3]
    return
        $files[.//mei:altId[@type = 'VideApp' and @subtype = 'version']/@n = $current.version]

let $entries := 
    
    map:merge(
        for $doc in $docs
        let $filename := tokenize(document-uri($doc/root()),'/')[last()]
        let $edition.id := $doc/string(@xml:id)
        let $edition.title := normalize-space($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'editionTitle'][1]/string-join(text(),' '))
        let $videApp.workId := normalize-space($doc//mei:altId[@type = 'VideApp' and @subtype = 'work']/@label)
        let $videApp.main := normalize-space($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'videApp.main'][1]/string-join(text(),' '))
        let $videApp.sub := normalize-space($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'videApp.sub'][1]/string-join(text(),' '))
        let $edition.desc := normalize-space(string-join($doc//mei:fileDesc/mei:notesStmt/mei:annot[@type = 'editionDesc']/mei:p/normalize-space(string-join(text(),' ')),' '))
        let $preview.zone := //$doc/id($doc//mei:fileDesc/mei:notesStmt/mei:annot[@type = 'editionDesc']/replace(@plist,'#',''))
        let $preview.baseURI := $preview.zone/parent::mei:surface/mei:graphic[@type = 'iiif']/@target
        let $preview.zone.width := number($preview.zone/@lrx) - number($preview.zone/@ulx)
        let $preview.zone.height := number($preview.zone/@lry) - number($preview.zone/@uly)
        let $preview.region := $preview.zone/@ulx || ',' || $preview.zone/@uly || ',' || $preview.zone.width || ',' || $preview.zone.height || '/'
        let $preview.size := string($preview.width * 2) || ',' || string($preview.height * 2) || '/'
        let $supportedViews :=
            for $app in $doc//mei:application[@type = 'videApp']
            let $map := map {
                'id': $app/string(@xml:id),
                'version': $app/string(@version)
            }
            let $output :=
                if ($app/@subtype) 
                then map:put($map, 'feature', $app/string(@subtype)) 
                else $map
            return  $output
            
        let $revisions := 
            for $version in $all.docs[.//mei:altId[@type = 'VideApp' and @subtype = 'work' and @label = $videApp.workId]]/normalize-space(.//mei:altId[@type = 'VideApp' and @subtype = 'version']/string(@n))
            return $version
        
        return
            map:entry($edition.id, map {
                'id': $edition.id,
                'title': $videApp.main,
                'opus': $videApp.sub,
                'fullTitle': $edition.title,
                'desc': $edition.desc,
                'revisions': array { $revisions },
                'previewUri': $preview.baseURI || $preview.region || $preview.size || '0/default.jpg',
                'supportedViews': array { $supportedViews}
            })
            (: '"' || $edition.id || '":{' ||
                '"id":"' || $edition.id || '",' ||
                '"title":"' || $videApp.main || '",' ||
                '"opus":"' || $videApp.sub || '",' ||
                '"fullTitle":"' || $edition.title || '",' ||
                '"desc":"' || $edition.desc || '",' ||
                '"revisions":[' || string-join($revisions,',') || '],' ||
                '"previewUri":"' || $preview.baseURI || $preview.region || $preview.size || '0/default.jpg' || '",' ||
                '"supportedViews":[' || string-join($supportedViews,',') || ']' ||
            '}' :)
        )
            


return $entries
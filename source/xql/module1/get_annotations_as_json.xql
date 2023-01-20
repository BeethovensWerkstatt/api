xquery version "3.1";

(:
    get_annotations_as_JSON.xql
    
    This xQuery seeks to extract the exact positions of all notes, rests and similar, 
    trying to provide Verovio with all the information it needs to render a 
    diplomatic transcript 
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace vide="http://beethovens-werkstatt.de/ns/vide";
declare namespace functx="http://www.functx.com";
                           
import module namespace console="http://exist-db.org/xquery/console";
import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
       
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

let $edition.id := request:get-parameter('edition.id','')

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]

let $annotations := 
    for $annot in $doc//mei:annot[@type = 'editorialComment']
    let $id := $annot/string(@xml:id)
    let $title := $annot/mei:title/text()
    let $plist :=
        for $p in $annot/tokenize(replace(@plist,'#',''),' ')
        return $p
    let $plist.strings :=
        for $p in $plist
        return '"' || $p || '"'
    let $elements := 
        for $p in $plist
        return $doc/id($p)
    let $facs :=
        for $facs.ref in $elements//@facs/tokenize(normalize-space(replace(.,'#','')),' ')
        return $facs.ref
    let $pageMap := map {}
    
    let $pages :=
        map:merge( 
        for $page in $doc//mei:graphic[@type = 'shapes']
        where (some $shape in $facs satisfies collection($config:module1-root)//svg:svg[@id = $page/@target]//svg:path[@id = $shape])
        let $shapes := 
            for $shape in $facs
            where collection($config:module1-root)//svg:svg[@id = $page/@target]//svg:path[@id = $shape]
            return $shape
            
        return
            map:entry($page/parent::mei:surface/string(@xml:id), array { $shapes })
        )
        
    return map {
        'id': $id,
        'title': $title,
        'plist': array { $plist.strings },
        'facs': $pages
    }
    
return array { $annotations }
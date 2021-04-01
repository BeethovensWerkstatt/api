xquery version "3.1";

module namespace module3="https://beethovens-werkstatt/ns/module3";

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "./config.xqm";
import module namespace ef="https://edirom.de/file" at "./file.xqm";
import module namespace iiif="https://edirom.de/iiif" at "./iiif.xqm";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace tools="http://edirom.de/ns/tools";
declare namespace ft="http://exist-db.org/xquery/lucene";

declare function module3:getEmbodiment($file.id as xs:string, $complaint as node(), $source.id as xs:string, $role as xs:string, $affected.measures as node()+, $affected.staves as xs:string*) as map(*) {

    let $file := $complaint/root()

    let $context.id :=
        if ($role =  'revision')
        then (
            $complaint/@xml:id
        )
        else (
            $complaint/mei:relation[@rel = 'hasContext']/replace(normalize-space(@target),'#','')
        )

    let $state.id :=
        if ($role = 'ante')
        then (
            let $provided.state.id := $complaint/replace(normalize-space(@state),'#','')
            let $provided.state := $file/id($provided.state.id)

            (: TODO: the following needs to be more elaborate:)
            let $previous.state.id := $provided.state/preceding-sibling::mei:genState[1]/@xml:id
            return $previous.state.id
        )
        else (
            $complaint/replace(normalize-space(@state),'#','')
        )

    let $context := ef:getMeiByContextLink($file.id, $context.id, $source.id, $state.id)

    let $iiif :=
        let $facsimile := $file//mei:facsimile[replace(normalize-space(@decls),'#','') = $source.id]

        let $data.targets := ($affected.measures/concat('#',@xml:id), $affected.measures/mei:staff[@n = $affected.staves]/concat('#',@xml:id))
        let $referencing.zones :=
            for $data.target in $data.targets
            return $facsimile//mei:zone/@data[ft:query(.,$data.target)]/parent::node()

        let $refs := ($affected.measures/tokenize(replace(normalize-space(@facs),'#',''),' '), $affected.measures/mei:staff/tokenize(replace(normalize-space(@facs),'#',''),' '))
        let $root := $file/root()
        let $referenced.zones := for $ref in $refs return $root/id($ref)[local-name() = 'zone']

        let $zones := ($referencing.zones,  $referenced.zones)
        return iiif:getRectangle($file/mei:mei, $zones, true())

    return map {
        'document': $source.id,
        'role': $role,
        'mei': $context,
        'iiif': array { $iiif }
    }
};

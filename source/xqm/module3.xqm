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

declare function module3:getComplaintLink($file.id as xs:string, $complaint.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/complaints/' || $complaint.id || '.json'
    return $link
};

declare function module3:getEmbodiment($file.id as xs:string, $complaint as node(), $source.id as xs:string, $role as xs:string, $affected.measures as node()+, $affected.staves as xs:string*, $text.file as node(), $document.file as node()) as map(*) {
    (: 
        allowed values for $role: 
        - 'ante'
        - 'post'
        - 'revision'
    :)
    let $work.uri := $config:module3-basepath || $file.id || '.json'
    
    let $file := $text.file/root()
    
    
    (: all this needs to come from elsewhere now :)
    let $context.id := $complaint/mei:relation[@rel = 'hasContext']/replace(normalize-space(@target),'#','')

    let $focus.id := $complaint/@xml:id

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

    (:let $context := ef:getMeiByContextLink($file.id, $context.id, $focus.id, $source.id, $state.id):)

    let $iiif :=
        let $facsimile := $document.file//mei:facsimile

        let $data.targets := ($affected.measures/concat('#',@xml:id), $affected.measures/mei:staff[@n = $affected.staves]/concat('#',@xml:id))
        let $referencing.zones :=
            for $data.target in $data.targets
            return $facsimile//mei:zone/@data[ft:query(.,$data.target)]/parent::node()

        let $refs := ($affected.measures/tokenize(replace(normalize-space(@facs),'#',''),' '), $affected.measures/mei:staff/tokenize(replace(normalize-space(@facs),'#',''),' '))
        let $root := $document.file/root()
        let $referenced.zones := for $ref in $refs return $root/id($ref)[local-name() = 'zone']

        let $zones := ($referencing.zones,  $referenced.zones)
        return iiif:getRectangle($document.file, $zones, true()) (:map {
            'zones': count($zones),
            'dataTargets': count($data.targets),
            'refs': string-join($refs,' - '),
            'referencedZones': count($referenced.zones),
            'fileId': $file.id
        }:)

    return map {
        'work': $work.uri,
        'role': $role,
        'mei': '--$context',
        'iiif': array { $iiif }(:,
        'test': map {
            'fileId': string($file.id),
            'contextId': string($context.id),
            'focusId': string($focus.id),
            'sourceId': string($source.id),
            'stateId': string($state.id),
            'hasFacs': count($file//mei:facsimile),
            'measures': string-join($affected.measures/string(@xml:id),', ')
        }:)
    }
};

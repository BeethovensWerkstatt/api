xquery version "3.1";

(:
    get_shape_info_as_JSON.xql
    
    This xQuery …
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
       
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

let $edition.id := request:get-parameter('edition.id','')
let $shape.id := request:get-parameter('shape.id','')

let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]
let $objects := $doc//mei:body//mei:*[./@facs][concat('#',$shape.id) = tokenize(normalize-space(./@facs),' ')]
let $all.states := $doc//mei:state
let $elems := 
    for $elem in $objects 
    let $elem.name := local-name($elem)
    let $elem.id := $elem/string(@xml:id)
    let $elem.type := 
        if($elem.name = 'syl') then('VIDE_PROTOCOL_OBJECT_LYRICS')
        else if($elem.name = 'metaMark') then('VIDE_PROTOCOL_OBJECT_METAMARK')
        else if($elem.name = 'dir') then('VIDE_PROTOCOL_OBJECT_DIR')
        else if($elem.name = 'del') then('VIDE_PROTOCOL_OBJECT_DEL')
        else if($elem.name = 'add') then('VIDE_PROTOCOL_OBJECT_ADD')
        else if($elem.name = 'note') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'rest') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'chord') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'beam') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'beamSpan') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'slur') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'tie') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'dynam') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'mRpt') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'mRest') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'beatRpt') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else if($elem.name = 'halfmRpt') then('VIDE_PROTOCOL_OBJECT_NOTATION')
        else($elem.name)
    
    let $states := 
        for $modification in $elem/ancestor::mei:*[@changeState]
        let $state.id := replace($modification/@changeState,'#','')
        let $state := $all.states[@xml:id = $state.id]
        let $state.label := $state/string(@label) 
        let $mod.type := local-name($modification)
        where not($mod.type = 'del') (:this restriction was added later:)
        return map {
            'id': $state.id,
            'label': $state.label,
            'type': $mod.type 
        }
    
    return map {
        'name': $elem.name,
        'id': $elem.id,
        'type': $elem.type,
        'states': array { $states }
    }
return array { $elems }
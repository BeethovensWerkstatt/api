xquery version "3.1";

(:
    get_invariance_relations_as_JSON.xql
    
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
let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]


let $state.ids := $doc//mei:state/string(@xml:id)

let $relations := 
    for $rel in $doc//mei:state//mei:relation[@rel = 'isReconfigurationOf']
    let $rel.id := $rel/string(@xml:id)    
    let $target.id := $rel/replace(@target,'#','')
    let $origin.id := $rel/replace(@origin,'#','')
    let $origin.elem := $doc/id($origin.id)
    let $origin.added := 
         if($origin.elem/ancestor::mei:add)
         then($origin.elem/ancestor::mei:add[1]/replace(@changeState,'#',''))
         else($doc//mei:state['#bwTerm_firstDraft' = tokenize(@decls,' ')]/string(@xml:id))
    let $target.added := $rel/ancestor::mei:state[1]/string(@xml:id)
    
    return map:put( map {}, $target.id, map {
            'relationID': $rel.id,
            'originID': $origin.id,
            'targetState': $target.added,
            'originState': $origin.added
        })
    

let $baseStates :=

    for $elem in $doc//mei:*[@facs and not(local-name() = 'measure') and ancestor-or-self::mei:*[@changeState] and @xml:id]
    let $addedState := 
        if($elem/ancestor::mei:add) 
        then($elem/ancestor::mei:add[1]/replace(@changeState,'#',''))
        else($doc//mei:state['#bwTerm_firstDraft' = tokenize(@decls,' ')]/string(@xml:id))
    let $elem.id := $elem/string(@xml:id)
    return map:put(map {}, $elem.id, $addedState)
    
    

let $suppliedIDs := $doc//mei:supplied//mei:*[@xml:id]/string(@xml:id)
    
return map {
    'states': array { $state.ids },
    'relations': map:merge($relations),
    'baseStates': map:merge($baseStates),
    'suppliedIDs': array { $suppliedIDs }
}
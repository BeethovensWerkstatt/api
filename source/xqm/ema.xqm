xquery version "3.1";

module namespace ema="https://github.com/music-addressability/ema/blob/master/docs/api.md";

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://api.beethovens-werkstatt.de" at "./config.xqm";


declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace tools="http://edirom.de/ns/tools";

declare function ema:buildLinkFromAnnots($document as node(), $measures as node()+, $annots as xs:string+) as xs:string {
    let $identifier := $config:ema-basepath || $document/string(@xml:id) || '/'
    let $measure.indizes := 
        for $measure in $measures
        return count($measure/preceding::mei:measure) + 1
    return $identifier || string-join($measure.indizes,',') || '/all/all'    
};
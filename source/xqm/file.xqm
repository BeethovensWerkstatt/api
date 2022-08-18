xquery version "3.1";

module namespace ef="https://edirom.de/file";

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

declare function ef:getFileLink($file.id as xs:string) as xs:string {
    let $link := $config:file-basepath || $file.id || '.xml'
    return $link
};

declare function ef:getMdivLink($file.id as xs:string, $mdiv.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/mdiv/' || $mdiv.id || '.json'
    return $link
};

declare function ef:getManifestationLink($file.id as xs:string, $source.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/manifestation/' || $source.id || '.json'
    return $link
};

declare function ef:getManifestationMeasuresLink($file.id as xs:string, $source.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/manifestation/' || $source.id || '/measures.json'
    return $link
};

declare function ef:getMeasuresInPartLink($file.id as xs:string, $source.id as xs:string, $mdiv.id as xs:string, $part.n as xs:integer) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/manifestation/' || $source.id || '/measures.json?scope=part&amp;mdivId=' || $mdiv.id || '&amp;part=' || xs:string($part.n) 
    return $link
};

declare function ef:getMeasuresInScoreLink($file.id as xs:string, $source.id as xs:string, $mdiv.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/manifestation/' || $source.id || '/measures.json?scope=scores&amp;mdivId=' || $mdiv.id
    return $link
};

declare function ef:getMeasureLink($file.id as xs:string, $measure.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/measure/' || $measure.id || '.json'
    return $link
};

declare function ef:getElementLink($file.id as xs:string, $element.id as xs:string) as xs:string {
    let $link := $config:file-basepath || $file.id || '/element/' || $element.id || '.xml'
    return $link
};

declare function ef:getMeiByAnnotsLink($file.id as xs:string, $annot.ids as xs:string*) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/annots/' || string-join($annot.ids,',') || '.mei'
    return $link
};

declare function ef:getMeiByContextLink($file.id as xs:string, $context.id as xs:string, $focus.link as xs:string, $source.id as xs:string, $state.id as xs:string) as xs:string {
    let $focus :=
        if($focus.link != '')
        then('&amp;focus=' || $focus.link)
        else()
    let $link := $config:module3-basepath || $file.id || '/snippet/' || $context.id || '.mei?source=' || $source.id || '&amp;state=' || $state.id || $focus
    return $link
};

declare function ef:getTeiByContextLink($file.id as xs:string, $context.id as xs:string, $source.id as xs:string, $state.id as xs:string) as xs:string {
    let $link := $config:module3-basepath || $file.id || '/snippet/' || $context.id || '.tei?source=' || $source.id || '&amp;state=' || $state.id
    return $link
};

declare function ef:getDocumentLink($document.id as xs:string) as xs:string {
    let $link := $config:documents-basepath || $document.id || '.json'
    return $link
};

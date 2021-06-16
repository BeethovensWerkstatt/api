xquery version "3.0";

(:declare namespace exist="http://exist-db.org/xquery/response";
:)
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: 
EMA =
GET /{identifier}/{measureRanges}/{stavesToMeasures}/{beatsToMeasures}/{completeness} 
For now:
/source/filename/measure-range/measures.json
:)

(: get a JSON-LD compatible definitions of contexts :)
if(matches($exist:path,'/\d/context.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/context.xql">
        <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else

(: LIST all documents in the database - documents.json = get-documents.xql :)
if(ends-with($exist:path,'/iiif/documents.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-documents.xql"/>
    </dispatch>

) else


(: retrieves a IIIF MANIFEST for a given document - manifest.json = get-manifest.json.xql :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/manifest(\.json)?')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else

(: retrieves a IIIF MANIFEST for a given canvas :)
(:if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/canvas/[\da-zA-Z-_\.]+')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else:)

(: retrieves a IIIF annotation list for the zones on a given page :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/list/[\da-zA-Z-_\.]+_zones$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-measure-positions-on-page.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="canvas.id" value="{substring-before(tokenize($exist:path,'/')[last()],'_zones')}"/>
        </forward>
    </dispatch>

) else

(: retrieves an SVG file with the overlays for a given page :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/overlays/[\da-zA-Z-_\.]+\.svg$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-svg-file.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="svg.file.name" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>

) else

(: endpoint for works from module 3 :)
if(matches($exist:path,'/module3/works\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/module3-get-works.xql"/>
    </dispatch>

) else

(: get specific work:)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-work.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.json')}"/>
        </forward>
    </dispatch>
) else

(: get info about manifestation / source :)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+/manifestation/[\da-zA-Z-_\.]+\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-manifestation.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="manifestation.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.json')}"/>
        </forward>
    </dispatch>
) else

(: get info about mdiv :)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+/mdiv/[\da-zA-Z-_\.]+\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-mdiv.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="mdiv.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.json')}"/>
        </forward>
    </dispatch>
) else

(: get measures in an mdiv :)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+/manifestation/[\da-zA-Z-_\.]+/measures\.json$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    let $scope := request:get-parameter('scope', '')
    let $mdiv.id := request:get-parameter('mdivId', '')
    let $part.n := request:get-parameter('part', '')
    
    return

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-measures-in-mdiv.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
          <add-parameter name="manifestation.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
          <add-parameter name="scope" value="{$scope}"/>
          <add-parameter name="mdiv.id" value="{$mdiv.id}"/>
          <add-parameter name="part.n" value="{$part.n}"/>
        </forward>
    </dispatch>
) else

(: get info about measure :)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+/measure/[\da-zA-Z-_\.]+\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-measure.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="measure.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.json')}"/>
        </forward>
    </dispatch>
) else

(: get specific complaint:)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+/complaints/[\da-zA-Z-_\.]+\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-complaint.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="complaint.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.json')}"/>
        </forward>
    </dispatch>
) else

(: get MEI element:)
if(matches($exist:path,'/file/[\da-zA-Z-_\.]+/element/[\da-zA-Z-_\.]+')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-element.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(: get MEI file:)
if(matches($exist:path,'/file/[\da-zA-Z-_\.]+.xml$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-file.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.xml')}"/>          
        </forward>
    </dispatch>
) else

(: get MEI extract for showing a single complaint's text :)
if(matches($exist:path,'/module3/[\da-zA-Z-_\.]+/snippet/[\da-zA-Z-_\.,]+.mei$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    let $document.id := tokenize($exist:path,'/')[last() - 2]
    let $last.section := tokenize($exist:path,'/')[last()]
    let $context.id := substring(tokenize($exist:path,'/')[last()],1,string-length(tokenize($exist:path,'/')[last()]) - 4)
    let $source.id := request:get-parameter('source', '')
    let $state.id := request:get-parameter('state', '')
    let $focus.id := request:get-parameter('focus', '')

    return
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-complaint-text-by-annot.xql">
          (: pass in the UUID of the document passed in the URI :)
            <add-parameter name="document.id" value="{$document.id}"/>
            <add-parameter name="context.id" value="{$context.id}"/>
            <add-parameter name="source.id" value="{$source.id}"/>
            <add-parameter name="state.id" value="{$state.id}"/>
            <add-parameter name="focus.id" value="{$focus.id}"/>
        </forward>
    </dispatch>
) else

(: endpoint for index.html :)
if ($exist:path eq "/index.html") then (
    (: forward root path to index.xql :)
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
)

(: all other requests are forwarded to index.html, which will inform about the available endpoints :)
else (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
)

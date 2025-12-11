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
if(matches($exist:path,'/iiif/document/[\da-zA-Z_\.\-]+/manifest(\.json)?')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else

(: retrieves a IIIF MANIFEST for a given canvas :)
(:if(matches($exist:path,'/iiif/document/[\da-zA-Z_\.\-]+/canvas/[\da-zA-Z_\.\-]+')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else:)

(: retrieves a IIIF annotation list for the zones on a given page :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z_\.\-]+/list/[\da-zA-Z_\.\-]+_zones$')) then (
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
if(matches($exist:path,'/iiif/document/[\da-zA-Z_\.\-]+/overlays/[\da-zA-Z_\.\-]+\.svg$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-svg-file.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="svg.file.name" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>

) else

(: retrieves an SVG file with the overlays for a given page, enriched with additional data attributes identifying monita and some such :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z_\.\-]+/overlaysPlus/[\da-zA-Z_\.\-]+\.svg$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/svg/get-svg-file-with-data-atts.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="svg.file.name" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>

) else

(: endpoints for module 1 VideApp:)
if (starts-with(lower-case($exist:path), '/module1/')) then (
    
    if (contains(lower-case($exist:path),'/module1/listall.json')) then
        (: forward to xql :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_all_MEI_files_from_DB_as_JSON.xql"/>
        </dispatch>
        )
        
    else if (matches(lower-case($exist:path),'/module1/file/[\da-zA-Z_\.\-]+.xml$')) then
        (: request a complete edition as one XML file :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_MEI_file_as_XML.xql">
                <add-parameter name="file.id" value="{replace(tokenize($exist:path,'/')[last()],'.xml','')}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches(lower-case($exist:path),'/module1/edition/[\da-zA-Z_\.\-]+/finalstate.xml$')) then
        (: request a complete edition as one XML file :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_final_state_as_XML.xql">
                <add-parameter name="edition.id" value="{replace(tokenize($exist:path,'/')[last() - 1],'.xml','')}"/>
            </forward>
        </dispatch>
        )    
    
    else if (matches(lower-case($exist:path),'/module1/edition/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+.xml$')) then
        (: request an element as XML snippet :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_MEI_snippet_as_XML.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
                <add-parameter name="element.id" value="{replace(tokenize($exist:path,'/')[last()],'.xml','')}"/>
            </forward>
        </dispatch>
        )
    
    else if (matches(lower-case($exist:path),'/module1/edition/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+/[\d\.]+,[\d\.]+/facsimileinfo.json$')) then
        (: get information about an element for displaying it as facsimile :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_facsimile_info_for_element_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 4]}"/>
                <add-parameter name="element.id" value="{replace(tokenize($exist:path,'/')[last() - 2],'.xml','')}"/>
                <add-parameter name="w" value="{substring-before(tokenize($exist:path,'/')[last() - 1],',')}"/>
                <add-parameter name="h" value="{substring-after(tokenize($exist:path,'/')[last() - 1],',')}"/>
            </forward>
        </dispatch>
        )
    
    else if (matches(lower-case($exist:path),'/module1/file/[\da-zA-Z_\.\-]+.svg$')) then
        (: request a complete edition as one XML file :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_SVG_file_as_XML.xql">
                <add-parameter name="file.id" value="{replace(tokenize($exist:path,'/')[last()],'.xml','')}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/states/overview.json$')) then
        (: request a list of states for navigation :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_geneticStatesList_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/annotations.json$')) then
        (: request a list of annotations with their metadata, excluding their content :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_annotations_as_json.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/page/[\da-zA-Z_\.\-]+/annotations.json$')) then
        (: request a list of annotations on a page :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_annotations_on_page_as_json.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="page.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )    
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/scars/categories.json$')) then
        (: request a list of scar categories :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_scar_categories_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            </forward>
        </dispatch>
        )    
    
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/state/[\da-zA-Z_\.\-]+/otherStates/[\da-zA-Z_\.\-]+/meiSnippet.xml$')) then
        (: forward to xql :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_geneticState_as_XML.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 5]}"/>
                <add-parameter name="state.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="other.states" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+/states/[\da-zA-Z_\.\-]+/preview.xml$')) then
        (: request preview rendering of an item within a staff, relative to a given set of states :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_element_preview_as_XML.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 5]}"/>
                <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="states" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+/(en|de)/description.json$')) then
        (: request a summary of any given element :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_element_description_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 4]}"/>
                <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
                <add-parameter name="lang" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        
        )
    
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/firstState/meiSnippet.xml$')) then
        (: request the first state of an edition as MEI snippet (which can be rendered with Verovio) :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_geneticState_as_XML.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
                <add-parameter name="state.id" value="''"/>
            </forward>
        </dispatch>
        )
    
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/reconstructionSetup.json$')) then
        (: request a list of states for navigation :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_reconstruction_setup_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
    
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/invarianceRelations.json$')) then
        (: request a list of states for navigation :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_invariance_relations_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
    
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/shape/[\da-zA-Z_\.\-]+/info.json$')) then
        (: request the MEI information related to a specified shape :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_shape_info_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="shape.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
    
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/object/[\da-zA-Z_\.\-]+/shapes.json$')) then
        (: request the shapes belonging to a given object :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_shapes_for_object_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="object.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/introduction.html$')) then
        (: request the introductory text of an edition :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_introduction_as_HTML.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/pages.json$')) then
        (: request a list of all pages in an edition :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_pages_in_edition_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
        
    else if (matches($exist:path,'/module1/edition/[\da-zA-Z_\.\-]+/measures.json$')) then
        (: request a list of all pages in an edition :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_measure_overview_as_JSON.xql">
                <add-parameter name="edition.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
        )
        
    (: <temp>
    else if (matches($exist:path,'/module1/notePositions.json$')) then
        (: request a list of all pages in an edition :)
        (
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module1/get_note_positions_as_JSON.xql"/>
        </dispatch>
        )
    </temp> :)
    
    (: all other requests are forwarded to index.html, which will inform about the available endpoints :)
    else (
        response:set-header("Access-Control-Allow-Origin", "*"),
    
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="index.html"/>
        </dispatch>
    )

) else 


(: endpoints for module 2:)
if (starts-with(lower-case($exist:path), '/module2/')) then (

    if(matches($exist:path,'/module2/comparisons\.json')) then (
        response:set-header("Access-Control-Allow-Origin", "*"),
    
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module2/getComparisonListing.xql"/>
        </dispatch>
        
        ) else if(matches($exist:path,'/data/[\da-zA-Z_\.\-]+/mdiv/[\d]+/transpose/[\da-zA-Z_\.\-]+/basic.xml')) then (
        
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        let $hiddenStaves := request:get-parameter('hideStaves', '')
        return
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module2/getAnalysis.xql">
                <add-parameter name="comparisonId" value="{tokenize($exist:path,'/')[last() - 5]}"/>
                <add-parameter name="method" value="comparison"/>
                <add-parameter name="mdiv" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="transpose" value="{tokenize($exist:path,'/')[last() - 1]}"/>
                <add-parameter name="hiddenStaves" value="{$hiddenStaves}"/>
            </forward>
        </dispatch>
    
    (: retrieves the MEI for an event density comparison :)
    ) else if(matches($exist:path,'/module2/data/[\da-zA-Z_\.\-]+/mdiv/[\d]+/transpose/[\da-zA-Z_\.\-]+/eventDensity.xml$')) then (
        
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        let $hiddenStaves := request:get-parameter('hideStaves', '')
        return
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module2/getAnalysis.xql">
                <add-parameter name="comparisonId" value="{tokenize($exist:path,'/')[last() - 5]}"/>
                <add-parameter name="method" value="eventDensity"/>
                <add-parameter name="mdiv" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="transpose" value="{tokenize($exist:path,'/')[last() - 1]}"/>
                <add-parameter name="hiddenStaves" value="{$hiddenStaves}"/>
            </forward>
        </dispatch>
    
    (: retrieves the MEI for a melodic contour comparison :)
    ) else if(matches($exist:path,'/module2/data/[\da-zA-Z_\.\-]+/mdiv/[\d]+/transpose/[\da-zA-Z_\.\-]+/melodicComparison.xml$')) then (
        
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        let $hiddenStaves := request:get-parameter('hideStaves', '')
        return
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module2/getAnalysis.xql">
                <add-parameter name="comparisonId" value="{tokenize($exist:path,'/')[last() - 5]}"/>
                <add-parameter name="method" value="melodicComparison"/>
                <add-parameter name="mdiv" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="transpose" value="{tokenize($exist:path,'/')[last() - 1]}"/>
                <add-parameter name="hiddenStaves" value="{$hiddenStaves}"/>
            </forward>
        </dispatch>
    
    (: retrieves the MEI for a harmonic comparison :)
    ) else if(matches($exist:path,'/module2/data/[\da-zA-Z_\.\-]+/mdiv/[\d]+/transpose/[\da-zA-Z_\.\-]+/harmonicComparison.xml$')) then (
        
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        let $hiddenStaves := request:get-parameter('hideStaves', '')
        return
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module2/getAnalysis.xql">
                <add-parameter name="comparisonId" value="{tokenize($exist:path,'/')[last() - 5]}"/>
                <add-parameter name="method" value="harmonicComparison"/>
                <add-parameter name="mdiv" value="{tokenize($exist:path,'/')[last() - 3]}"/>
                <add-parameter name="transpose" value="{tokenize($exist:path,'/')[last() - 1]}"/>
                <add-parameter name="hiddenStaves" value="{$hiddenStaves}"/>
            </forward>
        </dispatch>
        
    (: retrieves the HTML introduction for a comparison :)    
    ) else if(matches($exist:path,'/module2/[\da-zA-Z_\.\-]+/intro.html')) then (
        
        response:set-header("Access-Control-Allow-Origin", "*"),
        
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/xql/module2/getTextIntroduction.xql">
                <add-parameter name="comparisonId" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            </forward>
        </dispatch>
    )
    
    (: all other requests are forwarded to index.html, which will inform about the available endpoints :)
    else (
        response:set-header("Access-Control-Allow-Origin", "*"),
    
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="index.html"/>
        </dispatch>
    )

) else

(: endpoint for works from module 3 :)
if(matches($exist:path,'/module3/works\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/module3-get-works.xql"/>
    </dispatch>

) else

(: get specific work:)
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-work.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.json')}"/>
        </forward>
    </dispatch>
) else

(: get info about manifestation / source :)
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/manifestation/[\da-zA-Z_\.\-]+\.json')) then (
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
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/mdiv/[\da-zA-Z_\.\-]+\.json')) then (
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
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/manifestation/[\da-zA-Z_\.\-]+/measures\.json$')) then (
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
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/measure/[\da-zA-Z_\.\-]+\.json')) then (
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
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/complaints/[\da-zA-Z_\.\-]+\.json')) then (
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
if(matches($exist:path,'/file/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+')) then (
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
if(matches($exist:path,'/file/[\da-zA-Z_\.\-]+.xml$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-file.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.xml')}"/>          
        </forward>
    </dispatch>
) else

(: get MEI extract for showing a single complaint's text :)
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/snippet/[\da-zA-Z_\.,\-]+.mei$')) then (
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

(: get TEI extract for showing a single complaint's text :)
if(matches($exist:path,'/module3/[\da-zA-Z_\.\-]+/snippet/[\da-zA-Z_\.,\-]+.tei$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    let $document.id := tokenize($exist:path,'/')[last() - 2]
    let $last.section := tokenize($exist:path,'/')[last()]
    let $context.id := substring(tokenize($exist:path,'/')[last()],1,string-length(tokenize($exist:path,'/')[last()]) - 4)
    let $source.id := request:get-parameter('source', '')
    let $state.id := request:get-parameter('state', '')

    return
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/get-complaint-TEI-text-by-annot.xql">
          (: pass in the UUID of the document passed in the URI :)
            <add-parameter name="document.id" value="{$document.id}"/>
            <add-parameter name="context.id" value="{$context.id}"/>
            <add-parameter name="source.id" value="{$source.id}"/>
            <add-parameter name="state.id" value="{$state.id}"/>
        </forward>
    </dispatch>
) else

(: get Info about an element :)
if(matches($exist:path,'/desc/[\da-zA-Z_\.,\-]+.json$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    let $element.id := substring-before(tokenize($exist:path,'/')[last()],'.json')
    let $lang := 'de'

    return
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/tools/get_element_description_as_JSON.xql">
          (: pass in the UUID of the document passed in the URI :)
            <add-parameter name="element.id" value="{$element.id}"/>
            <add-parameter name="lang" value="{$lang}"/>
        </forward>
    </dispatch>
) else

(: endpoints for module 4 :)
if(matches($exist:path,'/module4/documents\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module4/module4-get-documents.xql"/>
    </dispatch>

) else

(: endpoints for module 4 onwards :)
if(matches($exist:path,'/documents/[\da-zA-Z_\.,\-]+\.json$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    let $document.id := substring-before(tokenize($exist:path,'/')[last()],'.json')
    
    return
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module4/get-document.xql">
          (: pass in the UUID of the document passed in the URI :)
            <add-parameter name="document.id" value="{$document.id}"/>
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

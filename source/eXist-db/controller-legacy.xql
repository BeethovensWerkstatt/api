xquery version "3.1";

(:~
 : Controller for Beethovens Werkstatt API
 : 
 : Classic controller-based routing for all endpoints
 :)

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(:~
 : API ENDPOINTS
 :)

(: OpenAPI documentation endpoint :)
if ($exist:path eq '/openapi.json') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/openapi.xql"/>
    </dispatch>
) else

(: Swagger UI documentation :)
if ($exist:path eq '/docs' or $exist:path eq '/docs/') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="docs.html"/>
    </dispatch>
) else

(:~
 : IIIF ENDPOINTS
 :)

(: IIIF documents listing :)
if ($exist:path eq '/iiif/documents.json') then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-documents.xql"/>
    </dispatch>
) else

(: IIIF manifest :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/manifest\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: IIIF manifest (alternative path without .json) :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/manifest$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: IIIF measure zones annotation list :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/list/[\da-zA-Z_\.\-]+_zones')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-measure-positions-on-page.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="canvas.id" value="{substring-before(tokenize($exist:path,'/')[last()],'_zones')}"/>
        </forward>
    </dispatch>
) else

(: IIIF SVG overlays :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/overlays/[\da-zA-Z_\.\-]+\.svg')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-svg-file.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="svg.file.name" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(: IIIF SVG overlays with data attributes :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/overlaysPlus/[\da-zA-Z_\.\-]+\.svg')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/svg/get-svg-file-with-data-atts.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="svg.file.name" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(:~
 : OTHER API ENDPOINTS
 :)

(: Context API :)
if (matches($exist:path, '/\d/context.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/context.xql">
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: Module 1 - Digital Edition endpoints :)
if (ends-with($exist:path, '/data.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_all_MEI_files_from_DB_as_JSON.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/introduction.html')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_introduction_as_HTML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/file.xml')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_MEI_file_as_XML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/pages.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_pages_in_edition_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/geneticStates.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_geneticStatesList_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/geneticState/[\da-zA-Z_\.\-]+\.xml')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_geneticState_as_XML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="state.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.xml')}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/finalState.xml')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_final_state_as_XML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/annotations.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_annotations_as_json.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/page/[\da-zA-Z_\.\-]+/annotations.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_annotations_on_page_as_json.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="page.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/notePositions.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_note_positions_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/measures.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_measure_overview_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/invariances.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_invariance_relations_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/reconstructionSetup.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_reconstruction_setup_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+/facsimile.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_facsimile_info_for_element_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+/description.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_element_description_as_JSON.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/element/[\da-zA-Z_\.\-]+/preview.xml')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_element_preview_as_XML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/snippet/[\da-zA-Z_\.\-]+\.xml')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_MEI_snippet_as_XML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="element.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.xml')}"/>
        </forward>
    </dispatch>
) else

(: Module 2 - Analysis endpoints :)
if (matches($exist:path, '/module2/getAnalysis\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getAnalysis.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getAnalysisByMei\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getAnalysisByMei.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getAnalysesDashboard\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getAnalysesDashboard.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getComparisonFragments\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getComparisonFragments.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getComparison\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getComparison.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getFragment\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http:// exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getFragment.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getMei\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getMei.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getWork\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getWork.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/getWorks\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/getWorks.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/listAnalyses\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/listAnalyses.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/listCombinations\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/listCombinations.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/listComparisons\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/listComparisons.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module2/listWorksWithAnalyses\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module2/listWorksWithAnalyses.xql"/>
    </dispatch>
) else

(: Module 3 - Sketch analysis endpoints :)
if (matches($exist:path, '/module3/available-works\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/available-works.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module3/mei2json\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/mei2json.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module3/work-list\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module3/work-list.xql"/>
    </dispatch>
) else

(: Module 4 - Engraving comparison endpoints :)
if (matches($exist:path, '/module4/get_source_summary_as_json\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module4/get_source_summary_as_json.xql"/>
    </dispatch>
) else

if (matches($exist:path, '/module4/getSourceSummary\.xql')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module4/getSourceSummary.xql"/>
    </dispatch>
) else

(: EMA (Encoded Musical Analysis) endpoints :)
if (matches($exist:path, '/source/[\da-zA-Z_\.\-]+/[\da-zA-Z_\.\-,]+/measures\.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/ema/get-ema.xql">
            <add-parameter name="identifier" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="measureRanges" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: File service endpoints :)
if (matches($exist:path, '/file/[\da-zA-Z_\.\-]+')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-file.xql">
            <add-parameter name="file.id" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

if (matches($exist:path, '/element/[\da-zA-Z_\.\-]+')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-element.xql">
            <add-parameter name="element.id" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(: Default - serve static files or return 404 :)
if ($exist:path eq '/') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
) else if ($exist:resource eq '') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat($exist:path, '/index.html')}"/>
    </dispatch>
) else (
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </ignore>
)

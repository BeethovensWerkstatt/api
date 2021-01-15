xquery version "3.0";

(:declare namespace exist="http://exist-db.org/xquery/response";
:)
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(:
documents.json
manifest.json
measures.json
annotlist.json
annotations.json
range.json
filelist.json
all-egs.json
:)



(: 
EMA =
GET /{identifier}/{measureRanges}/{stavesToMeasures}/{beatsToMeasures}/{completeness} 
For now:
/source/filename/measure-range/measures.json
:)


(: LIST all documents in the database - documents.json = get-documents.xql :)
if(ends-with($exist:path,'/iiif/documents.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-documents.xql"/>
    </dispatch>

) else


(: retrieves a IIIF MANIFEST for a given document - manifest.json = get-manifest.json.xql :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/manifest.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-manifest.json.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else

(: endpoint for MEASURES .../measures.json   - get-measures.xql :)
(: NB If this has range, then it is duplicating get-measure-range.xql :)
(: MAKE SURE this regex works for all possibilites (e.g. umlauts?) :)

if(matches($exist:path,'/[\da-zA-Z-_\.]+/measures.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measures.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

        </forward>
    </dispatch>

) else


(: endpoint for ANNOTATION LIST - annotlist.json = get-annotation-list.xql :)
if(matches($exist:path,'/annotlist.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-annotation-list.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

         </forward>
    </dispatch>

) else

(: endpoint for TEST  - test.json = test.xql :)

if(matches($exist:path,'/test.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/test.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

         </forward>
    </dispatch>

) else

(: endpoint for GET-RANGE (page#s separated by hyphen)
   .../<range>/<filename>/range.json = get.measure-range.xql :)

if(matches($exist:path,'/range.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measure-range.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

         </forward>
    </dispatch>

) else

(: temporary endpoint to check xquery solution using 'position()' :)

if(matches($exist:path,'/range2.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measure-range2.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

         </forward>
    </dispatch>

) else


(: endpoint for FILE LIST ...<foldername>/filelist.json = get-folder-documents.xql :)

if(matches($exist:path,'/filelist.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-folder-documents.xql">
  
         (\:   pass in the Directory name :\)
  
            <add-parameter name="folder" value="{tokenize($exist:path,'/')[last() - 1]}"/>

         </forward>
    </dispatch>

) else

(: endpoint for annotationS .../annotations.json = annotations.xql
   EDIT xql to retrieve an annotation list for each file in the directory :)

if(matches($exist:path,'/annotations.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-annotations.xql">
  
         (\:   pass in the Directory name :\)
  
            <add-parameter name="folder" value="{tokenize($exist:path,'/')[last() - 1]}"/>

         </forward>
    </dispatch>

) else

(: endpoint for Measures from files in a folder ...<range>/<foldername>/all-egs.json = get-measures-all-docs.xql :)

if(matches($exist:path,'/all-egs.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measures-all-docs.xql">
  
         (\:   pass in the Directory name and the Measure Range :\)
         
            <add-parameter name="folder" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>


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

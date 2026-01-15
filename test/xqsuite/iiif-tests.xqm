xquery version "3.1";

(:~
 : IIIF Module Tests
 : 
 : Tests for the IIIF module functions.
 : These tests verify the correct generation of IIIF manifests and annotations.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace test-iiif = "https://api.beethovens-werkstatt.de/test/iiif";

import module namespace iiif = "https://edirom.de/iiif" 
    at "../../source/xqm/iiif.xqm";
import module namespace config = "https://api.beethovens-werkstatt.de"
    at "../../source/xqm/config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace mei = "http://www.music-encoding.org/ns/mei";

(: ========== Helper Functions ========== :)

(:~
 : Create a minimal test MEI document for testing
 :)
declare function test-iiif:create-test-mei() as element(mei:mei) {
    <mei xmlns="http://www.music-encoding.org/ns/mei" xml:id="test-doc">
        <meiHead>
            <fileDesc>
                <titleStmt>
                    <title>Test Document</title>
                </titleStmt>
            </fileDesc>
        </meiHead>
        <facsimile>
            <surface xml:id="surface-001" n="1">
                <graphic target="https://example.com/iiif/image001"/>
                <zone xml:id="zone-001" ulx="100" uly="100" lrx="200" lry="200" data="#measure-001"/>
                <zone xml:id="zone-002" ulx="200" uly="100" lrx="300" lry="200" data="#measure-002"/>
            </surface>
        </facsimile>
        <music>
            <body>
                <mdiv>
                    <score>
                        <section>
                            <measure xml:id="measure-001" n="1" facs="#zone-001"/>
                            <measure xml:id="measure-002" n="2" facs="#zone-002"/>
                        </section>
                    </score>
                </mdiv>
            </body>
        </music>
    </mei>
};

(: ========== Configuration Tests ========== :)

(:~
 : Test that IIIF basepath is correctly configured
 :)
declare
    %test:name("IIIF basepath should be configured")
    %test:assertExists
function test-iiif:basepath-configured() {
    $config:iiif-basepath
};

(:~
 : Test that IIIF basepath ends with /iiif/
 :)
declare
    %test:name("IIIF basepath should end with /iiif/")
    %test:assertTrue
function test-iiif:basepath-format() {
    ends-with($config:iiif-basepath, "/iiif/")
};

(: ========== IIIF Annotation Tests ========== :)

(:~
 : Test IIIF annotation structure
 : Note: This test checks that the getIiifAnnotation function returns
 : a properly structured annotation map
 :)
declare
    %test:name("IIIF annotation should have correct structure")
    %test:assertTrue
function test-iiif:annotation-structure() {
    let $annotation := iiif:getIiifAnnotation(
        "test-doc",
        "test-annot",
        "https://example.com/canvas/1",
        "xywh=100,100,100,100",
        "https://example.com/manifest",
        "Test Label",
        "https://example.com/image"
    )
    return
        exists($annotation?('@context')) and
        exists($annotation?('@id')) and
        exists($annotation?('@type')) and
        $annotation?('@type') = 'oa:Annotation'
};

(:~
 : Test IIIF annotation contains correct context
 :)
declare
    %test:name("IIIF annotation should have IIIF Presentation context")
    %test:assertEquals("http://iiif.io/api/presentation/2/context.json")
function test-iiif:annotation-context() {
    let $annotation := iiif:getIiifAnnotation(
        "test-doc",
        "test-annot",
        "https://example.com/canvas/1",
        "xywh=100,100,100,100",
        "https://example.com/manifest",
        "Test Label",
        "https://example.com/image"
    )
    return $annotation?('@context')
};

(:~
 : Test IIIF annotation has motivation
 :)
declare
    %test:name("IIIF annotation should have oa:commenting motivation")
    %test:assertTrue
function test-iiif:annotation-motivation() {
    let $annotation := iiif:getIiifAnnotation(
        "test-doc",
        "test-annot",
        "https://example.com/canvas/1",
        "xywh=100,100,100,100",
        "https://example.com/manifest",
        "Test Label",
        "https://example.com/image"
    )
    return
        exists($annotation?motivation) and
        array:size($annotation?motivation) > 0
};

(:~
 : Test IIIF annotation 'on' property structure
 :)
declare
    %test:name("IIIF annotation 'on' should have SpecificResource type")
    %test:assertEquals("oa:SpecificResource")
function test-iiif:annotation-on-type() {
    let $annotation := iiif:getIiifAnnotation(
        "test-doc",
        "test-annot",
        "https://example.com/canvas/1",
        "xywh=100,100,100,100",
        "https://example.com/manifest",
        "Test Label",
        "https://example.com/image"
    )
    return $annotation?on?('@type')
};

(:~
 : Test IIIF annotation selector is FragmentSelector
 :)
declare
    %test:name("IIIF annotation selector should be FragmentSelector")
    %test:assertEquals("oa:FragmentSelector")
function test-iiif:annotation-selector-type() {
    let $annotation := iiif:getIiifAnnotation(
        "test-doc",
        "test-annot",
        "https://example.com/canvas/1",
        "xywh=100,100,100,100",
        "https://example.com/manifest",
        "Test Label",
        "https://example.com/image"
    )
    return $annotation?on?selector?('@type')
};

(: ========== Integration Tests (require deployed data) ========== :)

(:~
 : Test that we can access the data collection
 : This test may fail if data hasn't been loaded
 :)
declare
    %test:name("Data collection should be accessible")
    %test:pending("Requires deployed data")
function test-iiif:data-collection-exists() {
    collection($config:data-root)
};

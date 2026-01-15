xquery version "3.1";

(:~
 : Configuration Module Tests
 : 
 : Tests for the config.xqm module to ensure correct initialization
 : and environment-based configuration loading.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace test-config = "https://api.beethovens-werkstatt.de/test/config";

import module namespace config = "https://api.beethovens-werkstatt.de" 
    at "../../source/xqm/config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

(:~
 : Test that app-root is correctly determined
 :)
declare
    %test:name("app-root should be defined")
    %test:assertExists
function test-config:app-root-exists() {
    $config:app-root
};

(:~
 : Test that app-root does not contain 'embedded-eXist-server'
 :)
declare
    %test:name("app-root should not contain embedded server path")
    %test:assertFalse
function test-config:app-root-not-embedded() {
    contains($config:app-root, "embedded-eXist-server")
};

(:~
 : Test that data-root is correctly set
 :)
declare
    %test:name("data-root should be under app-root")
    %test:assertTrue
function test-config:data-root-under-app() {
    starts-with($config:data-root, $config:app-root)
};

(:~
 : Test that public-base-uri is set
 :)
declare
    %test:name("public-base-uri should be defined")
    %test:assertExists
function test-config:public-base-uri-exists() {
    $config:public-base-uri
};

(:~
 : Test that public-base-uri starts with http
 :)
declare
    %test:name("public-base-uri should be a valid URL")
    %test:assertTrue
function test-config:public-base-uri-is-url() {
    starts-with($config:public-base-uri, "http://") or 
    starts-with($config:public-base-uri, "https://")
};

(:~
 : Test that app-version is defined
 :)
declare
    %test:name("app-version should be defined")
    %test:assertExists
function test-config:app-version-exists() {
    $config:app-version
};

(:~
 : Test that app-version matches semver pattern
 :)
declare
    %test:name("app-version should match semantic versioning")
    %test:assertTrue
function test-config:app-version-is-semver() {
    matches($config:app-version, "^\d+\.\d+\.\d+")
};

(:~
 : Test that IIIF basepath is correctly derived
 :)
declare
    %test:name("IIIF basepath should include /iiif/")
    %test:assertTrue
function test-config:iiif-basepath-correct() {
    ends-with($config:iiif-basepath, "/iiif/")
};

(:~
 : Test that file basepath is correctly derived
 :)
declare
    %test:name("file basepath should include /file/")
    %test:assertTrue
function test-config:file-basepath-correct() {
    ends-with($config:file-basepath, "/file/")
};

(:~
 : Test that XSLT basepath points to resources
 :)
declare
    %test:name("XSLT basepath should be under resources")
    %test:assertTrue
function test-config:xslt-basepath-under-resources() {
    contains($config:xslt-basepath, "/resources/xslt/")
};

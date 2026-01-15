xquery version "3.1";

(:~
 : Validation Module Tests
 : 
 : Tests for the validation utility functions.
 :
 : @author Beethovens Werkstatt
 : @version 1.0.0
 :)

module namespace test-validation = "https://api.beethovens-werkstatt.de/test/validation";

import module namespace validate = "https://api.beethovens-werkstatt.de/util/validation" 
    at "../../source/xqm/util/validation.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

(: ========== ID Validation Tests ========== :)

(:~
 : Test valid ID with alphanumeric characters
 :)
declare
    %test:name("Valid alphanumeric ID should pass")
    %test:args("abc123")
    %test:assertEquals("abc123")
function test-validation:valid-alphanumeric-id($id as xs:string) {
    validate:id($id)
};

(:~
 : Test valid ID with hyphens and underscores
 :)
declare
    %test:name("Valid ID with special chars should pass")
    %test:args("document_v1-final.mei")
    %test:assertEquals("document_v1-final.mei")
function test-validation:valid-id-with-special-chars($id as xs:string) {
    validate:id($id)
};

(:~
 : Test empty ID should throw error
 :)
declare
    %test:name("Empty ID should throw error")
    %test:args("")
    %test:assertError("validate:missing-id")
function test-validation:empty-id-throws($id as xs:string) {
    validate:id($id)
};

(:~
 : Test ID with invalid characters should throw error
 :)
declare
    %test:name("ID with spaces should throw error")
    %test:args("invalid id")
    %test:assertError("validate:invalid-id")
function test-validation:id-with-spaces-throws($id as xs:string) {
    validate:id($id)
};

(:~
 : Test ID with special characters should throw error
 :)
declare
    %test:name("ID with special chars should throw error")
    %test:args("id<script>")
    %test:assertError("validate:invalid-id")
function test-validation:id-with-script-throws($id as xs:string) {
    validate:id($id)
};

(: ========== ID Safe Validation Tests ========== :)

(:~
 : Test id-safe returns valid for good ID
 :)
declare
    %test:name("id-safe should return valid for good ID")
    %test:assertTrue
function test-validation:id-safe-valid() {
    validate:id-safe("valid-id")?valid
};

(:~
 : Test id-safe returns invalid for bad ID
 :)
declare
    %test:name("id-safe should return invalid for bad ID")
    %test:assertFalse
function test-validation:id-safe-invalid() {
    validate:id-safe("")?valid
};

(: ========== Positive Integer Tests ========== :)

(:~
 : Test valid positive integer
 :)
declare
    %test:name("Valid positive integer should pass")
    %test:args("42", "page")
    %test:assertEquals(42)
function test-validation:valid-positive-integer($value as xs:string, $name as xs:string) {
    validate:positive-integer($value, $name)
};

(:~
 : Test zero should throw error
 :)
declare
    %test:name("Zero should throw error")
    %test:args("0", "page")
    %test:assertError("validate:not-positive")
function test-validation:zero-throws($value as xs:string, $name as xs:string) {
    validate:positive-integer($value, $name)
};

(:~
 : Test negative number should throw error
 :)
declare
    %test:name("Non-numeric string should throw error")
    %test:args("abc", "page")
    %test:assertError("validate:not-integer")
function test-validation:non-numeric-throws($value as xs:string, $name as xs:string) {
    validate:positive-integer($value, $name)
};

(: ========== Positive Integer with Default Tests ========== :)

(:~
 : Test default is used for empty value
 :)
declare
    %test:name("Default should be used for empty value")
    %test:assertEquals(10)
function test-validation:default-for-empty() {
    validate:positive-integer-or-default("", 10)
};

(:~
 : Test default is used for invalid value
 :)
declare
    %test:name("Default should be used for invalid value")
    %test:assertEquals(10)
function test-validation:default-for-invalid() {
    validate:positive-integer-or-default("abc", 10)
};

(:~
 : Test valid value overrides default
 :)
declare
    %test:name("Valid value should override default")
    %test:assertEquals(5)
function test-validation:value-overrides-default() {
    validate:positive-integer-or-default("5", 10)
};

(: ========== Measure Range Tests ========== :)

(:~
 : Test single measure
 :)
declare
    %test:name("Single measure should pass")
    %test:args("5")
    %test:assertEquals("5")
function test-validation:single-measure($range as xs:string) {
    validate:measure-range($range)
};

(:~
 : Test measure range
 :)
declare
    %test:name("Measure range should pass")
    %test:args("1-10")
    %test:assertEquals("1-10")
function test-validation:measure-range-simple($range as xs:string) {
    validate:measure-range($range)
};

(:~
 : Test complex measure range
 :)
declare
    %test:name("Complex measure range should pass")
    %test:args("1,3,5-8,10")
    %test:assertEquals("1,3,5-8,10")
function test-validation:measure-range-complex($range as xs:string) {
    validate:measure-range($range)
};

(:~
 : Test invalid measure range
 :)
declare
    %test:name("Invalid measure range should throw error")
    %test:args("1-a")
    %test:assertError("validate:invalid-range")
function test-validation:invalid-measure-range-throws($range as xs:string) {
    validate:measure-range($range)
};

(: ========== Pagination Tests ========== :)

(:~
 : Test default pagination
 :)
declare
    %test:name("Default pagination should use page 1 and limit 20")
    %test:assertTrue
function test-validation:default-pagination() {
    let $p := validate:pagination("", "")
    return $p?page = 1 and $p?limit = 20
};

(:~
 : Test pagination limit is capped at 100
 :)
declare
    %test:name("Pagination limit should be capped at 100")
    %test:assertEquals(100)
function test-validation:pagination-limit-capped() {
    validate:pagination("1", "500")?limit
};

(: ========== Sanitize String Tests ========== :)

(:~
 : Test sanitize removes control characters
 :)
declare
    %test:name("Sanitize should remove control characters")
    %test:assertEquals("hello world")
function test-validation:sanitize-removes-control-chars() {
    validate:sanitize-string("hello" || codepoints-to-string(0) || " world")
};

(:~
 : Test sanitize normalizes whitespace
 :)
declare
    %test:name("Sanitize should normalize whitespace")
    %test:assertEquals("hello world")
function test-validation:sanitize-normalizes-whitespace() {
    validate:sanitize-string("  hello   world  ")
};

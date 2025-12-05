# RESTXQ Migration Guide

## Übersicht

Diese Dokumentation beschreibt alle notwendigen Änderungen, um die existierenden XQL-Endpunkte von der Controller-basierten Architektur zu RESTXQ zu migrieren.

## Architektur-Änderungen

### Aktueller Zustand
- **Controller**: `source/eXist-db/controller.xql` routet alle Anfragen
- **XQL-Dateien**: Einzelne `.xql` Dateien in `source/xql/` verwenden `request:get-parameter()` und `response:set-header()`
- **CORS-Header**: Werden in jedem XQL-File separat mit `response:set-header()` gesetzt

### Ziel-Zustand
- **RESTXQ-Module**: XQM-Dateien in `source/xqm/rest/` mit RESTXQ-Annotationen
- **Keine Controller-Routes**: Nur noch RESTXQ-Endpunkte und Fallback für statische Dateien
- **Zentrale CORS-Behandlung**: Über `api-base.xqm` Funktionen

## Grundlegende Änderungsmuster

### 1. Parameter-Behandlung

**Vorher (XQL):**
```xquery
let $edition.id := request:get-parameter('edition.id','')
let $element.id := request:get-parameter('element.id','')
```

**Nachher (RESTXQ):**
```xquery
declare
    %rest:GET
    %rest:path("/document/{$documentId}/element/{$elementId}")
function module1-api:get-element($documentId as xs:string, $elementId as xs:string) {
    (: $documentId und $elementId sind direkte Funktionsparameter :)
}
```

**Query-Parameter:**
```xquery
declare
    %rest:GET
    %rest:path("/search")
    %rest:query-param("q", "{$query}", "")
    %rest:query-param("limit", "{$limit}", "10")
function api:search($query as xs:string, $limit as xs:string) {
    (: ... :)
}
```

### 2. Response-Header

**Vorher (XQL):**
```xquery
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

declare option output:method "json";
declare option output:media-type "application/json";
```

**Nachher (RESTXQ):**
```xquery
declare
    %rest:GET
    %rest:path("/data.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-data() {
    api-base:json-response(
        (: Daten :)
    )
};
```

Die `api-base:json-response()` Funktion setzt automatisch:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type`
- `Content-Type: application/json`

### 3. Error-Handling

**Vorher (XQL):**
```xquery
if(not(exists($doc)))
then(
    response:set-status-code(404),
    <error>
        <code>404</code>
        <message>Document not found</message>
    </error>
)
```

**Nachher (RESTXQ):**
```xquery
if(not(exists($doc)))
then api-base:not-found("Document " || $documentId)
else api-base:json-response($data)
```

Verfügbare Error-Funktionen in `api-base.xqm`:
- `api-base:not-found($resource)` - 404
- `api-base:bad-request($message)` - 400
- `api-base:server-error($message)` - 500
- `api-base:error-response($code, $message)` - Custom

## Zu migrierende Endpunkte

### Context API (1 Endpunkt)

#### `/{version}/context.json`
- **Datei**: `source/xql/context.xql`
- **Ziel-Modul**: Neues `context-api.xqm` oder in `services-api.xqm`
- **Parameter**: `version` (aus URL-Path)
- **Änderungen**:
  - Path-Parameter `{$version}` statt `request:get-parameter('version','')`
  - `api-base:json-response()` verwenden

---

### Module 1: Digital Edition (15 Endpunkte)

#### 1. `/data.json` - Liste aller MEI-Dateien
- **Datei**: `source/xql/module1/get_all_MEI_files_from_DB_as_JSON.xql`
- **Status**: ✅ Bereits in `module1-api.xqm` (Zeile 28)
- **Änderungen**: 
  - XQL-Datei: `response:set-header()` entfernen
  - Umwandeln in wiederverwendbare Funktion

#### 2. `/document/{documentId}/introduction.html`
- **Datei**: `source/xql/module1/get_introduction_as_HTML.xql`
- **Status**: ✅ Bereits in `module1-api.xqm` (Zeile 44)
- **Parameter**: `document.id` → `$documentId`

#### 3. `/document/{documentId}/file.xml`
- **Datei**: `source/xql/module1/get_MEI_file_as_XML.xql`
- **Status**: ✅ Bereits in `module1-api.xqm` (Zeile 59)
- **Parameter**: `document.id` → `$documentId`
- **Response**: `api-base:xml-response()` verwenden

#### 4. `/document/{documentId}/pages.json`
- **Datei**: `source/xql/module1/get_pages_in_edition_as_JSON.xql`
- **Status**: ✅ Bereits in `module1-api.xqm` (Zeile 75)
- **Parameter**: `document.id` → `$documentId`

#### 5. `/document/{documentId}/geneticStates.json`
- **Datei**: `source/xql/module1/get_geneticStatesList_as_JSON.xql`
- **Status**: ✅ Bereits in `module1-api.xqm` (Zeile 91)
- **Parameter**: `edition.id` → `$documentId`

#### 6. `/document/{documentId}/geneticState/{stateId}.xml`
- **Datei**: `source/xql/module1/get_geneticState_as_XML.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: 
  - `document.id` → `$documentId`
  - `state.id` → `$stateId`
  - Optional: `other.states` (Query-Parameter)
- **Response**: `api-base:xml-response()`

#### 7. `/document/{documentId}/finalState.xml`
- **Datei**: `source/xql/module1/get_final_state_as_XML.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: `document.id` → `$documentId`
- **Response**: `api-base:xml-response()`

#### 8. `/document/{documentId}/annotations.json`
- **Datei**: `source/xql/module1/get_annotations_as_json.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: `edition.id` → `$documentId`

#### 9. `/document/{documentId}/page/{pageId}/annotations.json`
- **Datei**: `source/xql/module1/get_annotations_on_page_as_json.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: 
  - `document.id` → `$documentId`
  - `page.id` → `$pageId`

#### 10. `/document/{documentId}/notePositions.json`
- **Datei**: `source/xql/module1/get_note_positions_as_JSON.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: `document.id` → `$documentId`

#### 11. `/document/{documentId}/measures.json`
- **Datei**: `source/xql/module1/get_measure_overview_as_JSON.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: `document.id` → `$documentId`

#### 12. `/document/{documentId}/invariances.json`
- **Datei**: `source/xql/module1/get_invariance_relations_as_JSON.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: `edition.id` → `$documentId`

#### 13. `/document/{documentId}/reconstructionSetup.json`
- **Datei**: `source/xql/module1/get_reconstruction_setup_as_JSON.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: `document.id` → `$documentId`

#### 14. `/document/{documentId}/element/{elementId}/facsimile.json`
- **Datei**: `source/xql/module1/get_facsimile_info_for_element_as_JSON.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: 
  - `edition.id` → `$documentId`
  - `element.id` → `$elementId`
  - Optional: `w`, `h` (Query-Parameter)

#### 15. `/document/{documentId}/element/{elementId}/description.json`
- **Datei**: `source/xql/module1/get_element_description_as_JSON.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: 
  - `document.id` → `$documentId`
  - `element.id` → `$elementId`

#### 16. `/document/{documentId}/element/{elementId}/preview.xml`
- **Datei**: `source/xql/module1/get_element_preview_as_XML.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: 
  - `document.id` → `$documentId`
  - `element.id` → `$elementId`
- **Response**: `api-base:xml-response()`

#### 17. `/document/{documentId}/snippet/{elementId}.xml`
- **Datei**: `source/xql/module1/get_MEI_snippet_as_XML.xql`
- **Ziel**: `module1-api.xqm`
- **Parameter**: 
  - `document.id` → `$documentId`
  - `element.id` → `$elementId` (aus Dateiname extrahiert)
- **Response**: `api-base:xml-response()`

---

### Module 2: Analysis (14 Endpunkte)

Alle Module 2 Endpunkte verwenden derzeit `.xql` Suffix im Path. Diese sollten zu sauberen REST-Paths migriert werden.

#### 1. `/module2/analysis` (statt `getAnalysis.xql`)
- **Datei**: `source/xql/module2/getAnalysis.xql`
- **Status**: Teilweise in `module2-api.xqm`
- **Parameter** (Query-String):
  - `comparisonId`
  - `method`
  - `mdiv`
  - `transpose`
  - `hiddenStaves`
- **Response**: XML (MEI)
- **Änderungen**: 
  - Alle Parameter als `%rest:query-param`
  - `api-base:xml-response()` für Erfolg
  - `api-base:not-found()` für 404

#### 2. `/module2/analysisByMei` (statt `getAnalysisByMei.xql`)
- **Datei**: `source/xql/module2/getAnalysisByMei.xql`
- **Ziel**: `module2-api.xqm`
- **Parameter**: Query-Parameter (POST Body möglich)

#### 3. `/module2/analyses/dashboard` (statt `getAnalysesDashboard.xql`)
- **Datei**: `source/xql/module2/getAnalysesDashboard.xql`
- **Ziel**: `module2-api.xqm`

#### 4. `/module2/comparison/fragments` (statt `getComparisonFragments.xql`)
- **Datei**: `source/xql/module2/getComparisonFragments.xql`
- **Ziel**: `module2-api.xqm`

#### 5. `/module2/comparison` (statt `getComparison.xql`)
- **Datei**: `source/xql/module2/getComparison.xql`
- **Ziel**: `module2-api.xqm`

#### 6. `/module2/fragment` (statt `getFragment.xql`)
- **Datei**: `source/xql/module2/getFragment.xql`
- **Ziel**: `module2-api.xqm`

#### 7. `/module2/mei` (statt `getMei.xql`)
- **Datei**: `source/xql/module2/getMei.xql`
- **Ziel**: `module2-api.xqm`

#### 8. `/module2/work/{workId}` (statt `getWork.xql`)
- **Datei**: `source/xql/module2/getWork.xql`
- **Ziel**: `module2-api.xqm`
- **Parameter**: `workId` als Path-Parameter

#### 9. `/module2/works` (statt `getWorks.xql`)
- **Datei**: `source/xql/module2/getWorks.xql`
- **Ziel**: `module2-api.xqm`

#### 10. `/module2/analyses` (statt `listAnalyses.xql`)
- **Datei**: `source/xql/module2/listAnalyses.xql`
- **Ziel**: `module2-api.xqm`

#### 11. `/module2/combinations` (statt `listCombinations.xql`)
- **Datei**: `source/xql/module2/listCombinations.xql`
- **Ziel**: `module2-api.xqm`

#### 12. `/module2/comparisons` (statt `listComparisons.xql`)
- **Datei**: `source/xql/module2/listComparisons.xql`
- **Ziel**: `module2-api.xqm`

#### 13. `/module2/works/with-analyses` (statt `listWorksWithAnalyses.xql`)
- **Datei**: `source/xql/module2/listWorksWithAnalyses.xql`
- **Ziel**: `module2-api.xqm`

#### 14. `/module2/comparison/{comparisonId}/listing`
- **Datei**: `source/xql/module2/getComparisonListing.xql`
- **Ziel**: `module2-api.xqm`

#### 15. `/module2/text/introduction`
- **Datei**: `source/xql/module2/getTextIntroduction.xql`
- **Ziel**: `module2-api.xqm`

---

### Module 3: Sketch Analysis (3 Endpunkte)

#### 1. `/module3/works/available` (statt `available-works.xql`)
- **Datei**: `source/xql/module3/available-works.xql`
- **Ziel**: `module3-api.xqm`

#### 2. `/module3/mei2json` (statt `mei2json.xql`)
- **Datei**: `source/xql/module3/mei2json.xql`
- **Ziel**: `module3-api.xqm`

#### 3. `/module3/works` (statt `work-list.xql`)
- **Datei**: `source/xql/module3/work-list.xql`
- **Ziel**: `module3-api.xqm`

---

### Module 4: Engraving Comparison (2 Endpunkte)

#### 1. `/module4/source/summary`
- **Datei**: `source/xql/module4/get_source_summary_as_json.xql`
- **Ziel**: `module4-api.xqm`

#### 2. `/module4/source/summary` (alt)
- **Datei**: `source/xql/module4/getSourceSummary.xql`
- **Ziel**: `module4-api.xqm`
- **Hinweis**: Scheint Duplikat zu sein, konsolidieren

---

### EMA (Encoded Musical Analysis) (1 Endpunkt)

#### `/source/{identifier}/{measureRanges}/measures.json`
- **Datei**: `source/xql/ema/get-ema.xql`
- **Status**: Möglicherweise bereits migriert
- **Parameter**: 
  - `identifier` (Path)
  - `measureRanges` (Path, komma-separiert)
- **Ziel**: `services-api.xqm` oder eigenes `ema-api.xqm`

---

### File Services (2 Endpunkte)

#### 1. `/file/{fileId}`
- **Datei**: `source/xql/file/get-file.xql`
- **Ziel**: `services-api.xqm`
- **Parameter**: `file.id` → `$fileId`

#### 2. `/element/{elementId}`
- **Datei**: `source/xql/file/get-element.xql`
- **Ziel**: `services-api.xqm`
- **Parameter**: `element.id` → `$elementId`

---

### SVG Services

#### `/svg/...`
- **Dateien**: `source/xql/svg/*.xql`
- **Ziel**: `services-api.xqm` oder eigenes `svg-api.xqm`

---

## Migrations-Schritte pro Endpunkt

Für jeden zu migrierenden Endpunkt:

### 1. XQL-Datei analysieren
```xquery
(: Finden: :)
- request:get-parameter() Aufrufe → Path- oder Query-Parameter
- response:set-header() Aufrufe → Entfernen (wird durch api-base ersetzt)
- output:method / output:media-type → %rest:produces Annotation
- Hauptlogik → In Funktion extrahieren
```

### 2. RESTXQ-Funktion erstellen

```xquery
declare
    %rest:GET
    %rest:path("/document/{$documentId}/data.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-document-data($documentId as xs:string) {
    let $doc := collection($config:module1-root)//mei:mei[@xml:id = $documentId]
    return
        if (not(exists($doc)))
        then api-base:not-found("Document " || $documentId)
        else api-base:json-response(
            (: Datenlogik hier :)
        )
};
```

### 3. XQL-Datei refactoring (Optional)

**Option A**: XQL-Datei behalten, aber in wiederverwendbare Funktion umwandeln:
```xquery
(: In XQL-Datei :)
declare function local:get-data($documentId as xs:string) {
    (: Haupt-Logik :)
};

(: Von RESTXQ aufrufen :)
let $edition.id := request:get-parameter('edition.id','')
return local:get-data($edition.id)
```

**Option B**: Logik komplett in XQM-Modul verschieben und XQL löschen

### 4. Controller.xql aufräumen

Route aus `controller.xql` entfernen, sobald RESTXQ-Endpunkt funktioniert.

---

## Code-Transformations-Beispiele

### Beispiel 1: Einfacher GET-Endpunkt

**Vorher** (`get_pages_in_edition_as_JSON.xql`):
```xquery
xquery version "3.1";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $edition.id := request:get-parameter('edition.id','')
let $doc := collection($config:module1-root)//mei:mei[@xml:id = $edition.id]

return
    (: Daten-Logik :)
```

**Nachher** (in `module1-api.xqm`):
```xquery
declare
    %rest:GET
    %rest:path("/document/{$documentId}/pages.json")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-pages($documentId as xs:string) {
    let $doc := collection($config:module1-root)//mei:mei[@xml:id = $documentId]
    return
        if (not(exists($doc)))
        then api-base:not-found("Document " || $documentId)
        else api-base:json-response(
            (: Daten-Logik :)
        )
};
```

### Beispiel 2: Endpunkt mit mehreren Parametern

**Vorher** (`get_facsimile_info_for_element_as_JSON.xql`):
```xquery
let $edition.id := request:get-parameter('edition.id','')
let $element.id := request:get-parameter('element.id','')
let $target.w := number(request:get-parameter('w',0))
let $target.h := number(request:get-parameter('h',0))
```

**Nachher**:
```xquery
declare
    %rest:GET
    %rest:path("/document/{$documentId}/element/{$elementId}/facsimile.json")
    %rest:query-param("w", "{$width}", "0")
    %rest:query-param("h", "{$height}", "0")
    %rest:produces("application/json")
    %output:method("json")
function module1-api:get-element-facsimile(
    $documentId as xs:string,
    $elementId as xs:string,
    $width as xs:string,
    $height as xs:string
) {
    let $target.w := number($width)
    let $target.h := number($height)
    let $doc := collection($config:module1-root)//mei:mei[@xml:id = $documentId]
    
    return
        if (not(exists($doc)))
        then api-base:not-found("Document " || $documentId)
        else api-base:json-response(
            (: Logik :)
        )
};
```

### Beispiel 3: XML-Response

**Vorher** (`get_geneticState_as_XML.xql`):
```xquery
declare option exist:serialize "method=xml media-type=application/xml";

let $edition.id := request:get-parameter('edition.id','')
let $state.id := request:get-parameter('state.id','')

return $state.xml
```

**Nachher**:
```xquery
declare
    %rest:GET
    %rest:path("/document/{$documentId}/geneticState/{$stateId}.xml")
    %rest:produces("application/xml")
    %output:method("xml")
function module1-api:get-genetic-state(
    $documentId as xs:string,
    $stateId as xs:string
) {
    let $doc := collection($config:module1-root)//mei:mei[@xml:id = $documentId]
    let $state := $doc//mei:genDesc[@xml:id = $stateId]
    
    return
        if (not(exists($state)))
        then api-base:not-found("Genetic state " || $stateId)
        else api-base:xml-response($state)
};
```

---

## Datei-Übersicht: Zu ändernde Dateien

### XQM-Module (zu erweitern)

1. ✅ `source/xqm/rest/api-base.xqm` - Bereits aktualisiert
2. 🔄 `source/xqm/rest/module1-api.xqm` - Teilweise migriert, 12 Endpunkte fehlen
3. 🔄 `source/xqm/rest/module2-api.xqm` - Zu erweitern (14 Endpunkte)
4. 🔄 `source/xqm/rest/module3-api.xqm` - Zu erweitern (3 Endpunkte)
5. 🔄 `source/xqm/rest/module4-api.xqm` - Zu erweitern (2 Endpunkte)
6. 🔄 `source/xqm/rest/services-api.xqm` - Zu erweitern (File, Element, EMA)
7. ➕ `source/xqm/rest/context-api.xqm` - Neu erstellen (1 Endpunkt)

### XQL-Dateien (zu refactoren oder löschen)

**Module 1** (17 Dateien):
- `source/xql/module1/get_all_MEI_files_from_DB_as_JSON.xql`
- `source/xql/module1/get_introduction_as_HTML.xql`
- `source/xql/module1/get_MEI_file_as_XML.xql`
- `source/xql/module1/get_pages_in_edition_as_JSON.xql`
- `source/xql/module1/get_geneticStatesList_as_JSON.xql`
- `source/xql/module1/get_geneticState_as_XML.xql`
- `source/xql/module1/get_final_state_as_XML.xql`
- `source/xql/module1/get_annotations_as_json.xql`
- `source/xql/module1/get_annotations_on_page_as_json.xql`
- `source/xql/module1/get_note_positions_as_JSON.xql`
- `source/xql/module1/get_measure_overview_as_JSON.xql`
- `source/xql/module1/get_invariance_relations_as_JSON.xql`
- `source/xql/module1/get_reconstruction_setup_as_JSON.xql`
- `source/xql/module1/get_facsimile_info_for_element_as_JSON.xql`
- `source/xql/module1/get_element_description_as_JSON.xql`
- `source/xql/module1/get_element_preview_as_XML.xql`
- `source/xql/module1/get_MEI_snippet_as_XML.xql`

**Module 2** (15 Dateien):
- `source/xql/module2/getAnalysis.xql`
- `source/xql/module2/getAnalysisByMei.xql`
- `source/xql/module2/getAnalysesDashboard.xql`
- `source/xql/module2/getComparisonFragments.xql`
- `source/xql/module2/getComparison.xql`
- `source/xql/module2/getFragment.xql`
- `source/xql/module2/getMei.xql`
- `source/xql/module2/getWork.xql`
- `source/xql/module2/getWorks.xql`
- `source/xql/module2/listAnalyses.xql`
- `source/xql/module2/listCombinations.xql`
- `source/xql/module2/listComparisons.xql`
- `source/xql/module2/listWorksWithAnalyses.xql`
- `source/xql/module2/getComparisonListing.xql`
- `source/xql/module2/getTextIntroduction.xql`

**Module 3** (3 Dateien):
- `source/xql/module3/available-works.xql`
- `source/xql/module3/mei2json.xql`
- `source/xql/module3/work-list.xql`

**Module 4** (2 Dateien):
- `source/xql/module4/get_source_summary_as_json.xql`
- `source/xql/module4/getSourceSummary.xql`

**Services** (4 Dateien):
- `source/xql/context.xql`
- `source/xql/ema/get-ema.xql`
- `source/xql/file/get-file.xql`
- `source/xql/file/get-element.xql`

**Total**: ~42 XQL-Dateien zu migrieren

### Controller (zu vereinfachen)

- `source/eXist-db/controller.xql` - Alle Legacy-Routes entfernen, nur behalten:
  - RESTXQ-Delegation
  - Statische Dateien
  - Index-Redirects

---

## Prioritäten für Migration

### Phase 1: Kritische Endpunkte (Hohe Priorität)
1. **Module 1 Core**: `/data.json`, `/document/*/file.xml`, `/document/*/pages.json`
2. **Module 2 Core**: Analysis-Endpunkte
3. **File Services**: `/file/*`, `/element/*`

### Phase 2: Erweiterte Features (Mittlere Priorität)
1. **Module 1 Genetic States**: Genetic State Endpunkte
2. **Module 1 Annotations**: Annotations-Endpunkte
3. **Module 3**: Sketch analysis

### Phase 3: Spezialisierte Features (Niedrige Priorität)
1. **Module 4**: Engraving comparison
2. **Context API**
3. **Cleanup**: Alte XQL-Dateien löschen

---

## Testing nach Migration

Für jeden migrierten Endpunkt:

1. **Funktionalität**: Gleiche Response wie vorher?
2. **CORS-Header**: Werden korrekt gesetzt?
3. **Error-Handling**: 404, 400, 500 funktionieren?
4. **Performance**: Keine Verschlechterung?
5. **Dokumentation**: OpenAPI-Spec aktualisiert?

### Test-Checklist pro Endpunkt

```bash
# 1. Response-Format testen
curl http://localhost:8080/document/DOCUMENT_ID/pages.json

# 2. CORS-Header prüfen
curl -I http://localhost:8080/document/DOCUMENT_ID/pages.json | grep -i "access-control"

# 3. 404-Handling testen
curl http://localhost:8080/document/INVALID_ID/pages.json

# 4. OPTIONS-Request (CORS preflight)
curl -X OPTIONS http://localhost:8080/document/DOCUMENT_ID/pages.json
```

---

## Vorteile nach Migration

1. **Klarere Struktur**: RESTXQ-Annotationen dokumentieren API direkt im Code
2. **Weniger Code**: Kein wiederholtes CORS-Header-Setzen
3. **Besseres Error-Handling**: Zentrale Error-Funktionen
4. **OpenAPI-Integration**: Automatische API-Dokumentation
5. **Type Safety**: Typisierte Funktionsparameter
6. **Testbarkeit**: Funktionen können direkt getestet werden
7. **Performance**: Weniger Controller-Overhead

---

## Automatisierungs-Möglichkeiten

Ein Skript könnte folgende Transformationen automatisieren:

1. **Parameter-Extraktion**: `request:get-parameter('x','')` → Funktionsparameter
2. **CORS-Entfernung**: `response:set-header("Access-Control-Allow-Origin","*")` → Löschen
3. **Response-Wrapping**: Return-Wert → `api-base:json-response(...)`
4. **RESTXQ-Annotation**: URL-Pattern aus Controller → `%rest:path(...)`

---

## Nächste Schritte

1. ✅ `api-base.xqm` aktualisieren - **Erledigt**
2. Module 1 vervollständigen (12 fehlende Endpunkte)
3. Module 2 migrieren (14 Endpunkte)
4. Module 3 migrieren (3 Endpunkte)
5. Module 4 migrieren (2 Endpunkte)
6. Services migrieren (4 Endpunkte)
7. Controller.xql aufräumen
8. Testing
9. Alte XQL-Dateien entfernen oder archivieren
10. Dokumentation aktualisieren

---

## Ressourcen

- [eXist-db RESTXQ Documentation](http://exist-db.org/exist/apps/doc/restxq)
- [RESTXQ Specification](https://github.com/adamretter/RESTXQ-Specification)
- `source/xqm/rest/README.md` - Projekt-spezifische RESTXQ-Doku

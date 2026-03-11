# RESTXQ Rollback Guide

## Übersicht

Diese Dokumentation beschreibt die Schritte zur **Rückabwicklung der RESTXQ-Migration**, um alle Endpunkte wieder in die klassische `controller.xql`-basierte Architektur zu integrieren.

## Aktueller Zustand

### RESTXQ-Endpunkte (46 Endpunkte in XQM-Modulen)

**OpenAPI (1)**
- `GET /openapi.json`

**IIIF (6)**
- `GET /iiif/documents.json`
- `GET /iiif/document/{documentId}/manifest.json`
- `GET /iiif/document/{documentId}/manifest`
- `GET /iiif/document/{documentId}/list/{canvasId}_zones`
- `GET /iiif/document/{documentId}/overlays/{svgFileName}`
- `GET /iiif/document/{documentId}/overlaysPlus/{svgFileName}`

**Module 1 (14)**
- `GET /data.json`
- `GET /document/{documentId}/introduction.html`
- `GET /document/{documentId}/file.xml`
- `GET /document/{documentId}/pages.json`
- `GET /document/{documentId}/geneticStates.json`
- `GET /document/{documentId}/geneticState/{stateId}.xml`
- `GET /document/{documentId}/finalState.xml`
- `GET /document/{documentId}/annotations.json`
- `GET /document/{documentId}/page/{pageId}/annotations.json`
- `GET /document/{documentId}/notePositions.json`
- `GET /document/{documentId}/measures.json`
- `GET /document/{documentId}/invariances.json`
- `GET /document/{documentId}/reconstructionSetup.json`
- `GET /document/{documentId}/element/{elementId}/facsimile.json`
- `GET /document/{documentId}/element/{elementId}/description.json`
- `GET /document/{documentId}/element/{elementId}/preview.xml`
- `GET /document/{documentId}/snippet/{elementId}.xml`

**Module 2 (11)**
- `GET /module2/getAnalysis.xql`
- `GET /module2/getAnalysisByMei.xql`
- `GET /module2/getAnalysesDashboard.xql`
- `GET /module2/getComparisonFragments.xql`
- `GET /module2/getComparison.xql`
- `GET /module2/getFragment.xql`
- `GET /module2/getMei.xql`
- `GET /module2/getWork.xql`
- `GET /module2/getWorks.xql`
- `GET /module2/listAnalyses.xql`
- `GET /module2/listCombinations.xql`
- `GET /module2/listComparisons.xql`
- `GET /module2/listWorksWithAnalyses.xql`

**Module 3 (3)**
- `GET /module3/available-works.xql`
- `GET /module3/mei2json.xql`
- `GET /module3/work-list.xql`

**Module 4 (2)**
- `GET /module4/get_source_summary_as_json.xql`
- `GET /module4/getSourceSummary.xql`

**Services (4)**
- `GET /{version}/context.json`
- `GET /source/{identifier}/{measureRanges}/measures.json`
- `GET /file/{fileId}`
- `GET /element/{elementId}`

---

## Rückabwicklungs-Strategie

### Ziel
Alle RESTXQ-Endpunkte wieder in `controller.xql` integrieren, sodass:
1. Alle Anfragen über `controller.xql` geroutet werden
2. Die XQL-Dateien direkt verwendet werden (ohne RESTXQ-Wrapper)
3. RESTXQ-Module deaktiviert oder entfernt werden können

---

## Schritt-für-Schritt-Anleitung

### Schritt 1: Controller.xql analysieren

**Aktuelle Controller-Struktur:**
```xquery
(: OpenAPI documentation endpoint :)
if ($exist:path eq '/openapi.json') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/openapi.xql"/>
    </dispatch>
) else

(: IIIF endpoints - migrated to RESTXQ :)
if (starts-with($exist:path, '/iiif/')) then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}"/>
    </dispatch>
) else
```

Der Controller delegiert derzeit IIIF-Anfragen an RESTXQ. Diese Delegation muss entfernt werden.

---

### Schritt 2: IIIF-Endpunkte zurück in Controller integrieren

**Zu ersetzen:**
```xquery
(: IIIF endpoints - migrated to RESTXQ :)
if (starts-with($exist:path, '/iiif/')) then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}"/>
    </dispatch>
) else
```

**Durch:**
```xquery
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
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: IIIF manifest (alternative path without .json) :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/manifest$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: IIIF measure zones annotation list :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/list/[\da-zA-Z_\.\-]+_zones')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-measure-positions-on-page.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="canvasId" value="{substring-before(tokenize($exist:path,'/')[last()],'_zones')}"/>
        </forward>
    </dispatch>
) else

(: IIIF SVG overlays :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/overlays/[\da-zA-Z_\.\-]+\.svg')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-svg-file.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="svgFileName" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(: IIIF SVG overlays with data attributes :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/overlaysPlus/[\da-zA-Z_\.\-]+\.svg')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/svg/get-svg-file-with-data-atts.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="svgFileName" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else
```

---

### Schritt 3: OpenAPI-Endpunkt zurück in Controller

**Zu ersetzen:**
```xquery
if ($exist:path eq '/openapi.json') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/openapi.xql"/>
    </dispatch>
) else
```

**Bleibt unverändert** (bereits im Controller), ODER falls es über RESTXQ läuft:

**Durch:**
```xquery
if ($exist:path eq '/openapi.json') then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/openapi.xql"/>
    </dispatch>
) else
```

---

### Schritt 4: Module 1 Endpunkte im Controller prüfen

Die meisten Module 1 Endpunkte sind **bereits im Controller vorhanden** (siehe Zeilen 60-245 in `controller.xql`). 

**Zu prüfen:** Sind alle 17 Module 1 Endpunkte vorhanden?

**Fehlende Endpunkte hinzufügen:**

Falls `snippet` fehlt:
```xquery
if (matches($exist:path, '/document/[\da-zA-Z_\.\-]+/snippet/[\da-zA-Z_\.\-]+\.xml')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/module1/get_MEI_snippet_as_XML.xql">
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="element.id" value="{substring-before(tokenize($exist:path,'/')[last()],'.xml')}"/>
        </forward>
    </dispatch>
) else
```

---

### Schritt 5: Services-Endpunkte im Controller prüfen

**Context API:**
```xquery
(: Context API :)
if (matches($exist:path, '/\d+/context.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/context.xql">
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else
```

**EMA:**
```xquery
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
```

**File Services:**
```xquery
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
```

Diese Endpunkte sind **bereits im Controller vorhanden** (siehe Zeilen 360-377).

---

### Schritt 6: Module 2, 3, 4 Endpunkte sind bereits im Controller

**Module 2** (Zeilen 248-324): Alle Endpunkte vorhanden  
**Module 3** (Zeilen 327-344): Alle Endpunkte vorhanden  
**Module 4** (Zeilen 347-357): Alle Endpunkte vorhanden

✅ **Keine Änderungen nötig**

---

### Schritt 7: XQL-Dateien auf klassische Struktur zurücksetzen

Einige XQL-Dateien wurden möglicherweise für RESTXQ angepasst. Prüfen und ggf. zurücksetzen:

**IIIF XQL-Dateien erstellen/prüfen:**

#### `/source/xql/iiif/get-documents.xql` (NEU ERSTELLEN)

```xquery
xquery version "3.1";

(:
    get-documents.xql
    
    Returns list of all documents with IIIF manifests
:)

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";
import module namespace ef="https://edirom.de/file" at "../../xqm/file.xqm";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $database := collection($config:data-root)
let $files :=
    for $facsimile in $database//mei:mei[@xml:id][.//mei:facsimile[@xml:id and .//mei:graphic]]//mei:facsimile
    let $id := $facsimile/string(@xml:id)
    let $file.id := $facsimile/ancestor::mei:mei/string(@xml:id)
    let $manifest := $config:iiif-basepath || 'document/' || $id || '/manifest.json'
    let $pages := count($facsimile//mei:surface[mei:graphic])
    return map {
        'id': $id,
        'manifest': $manifest,
        'pages': $pages,
        'file': ef:getFileLink($file.id)
    }

return array { $files }
```

#### Andere IIIF-XQL-Dateien anpassen

Die Dateien sollten bereits existieren:
- `source/xql/iiif/get-manifest.json.xql` ✅
- `source/xql/iiif/get-measure-positions-on-page.xql` ✅

Prüfen, ob sie `request:get-parameter()` verwenden:

```xquery
let $documentId := request:get-parameter('documentId','')
let $canvasId := request:get-parameter('canvasId','')
```

Falls nicht, Parameter-Handling hinzufügen.

#### `/source/xql/file/get-svg-file.xql` prüfen/erstellen

```xquery
xquery version "3.1";

import module namespace config="https://api.beethovens-werkstatt.de" at "../../xqm/config.xqm";

declare namespace mei="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=xml media-type=image/svg+xml";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $document.id := request:get-parameter('documentId','')
let $svg.file.name := request:get-parameter('svgFileName','')

let $doc := collection($config:data-root)//mei:mei[@xml:id = $document.id]
let $svg := $doc//mei:graphic[@target = $svg.file.name]/ancestor::mei:surface[1]//mei:zone[@type = 'measure']

(: SVG generieren oder abrufen :)
return $svg
```

---

### Schritt 8: Parameter-Namen angleichen

**Wichtig:** Controller verwendet oft andere Parameter-Namen als RESTXQ!

**RESTXQ:** `$documentId`, `$elementId`, `$stateId` (camelCase)  
**Controller:** `document.id`, `element.id`, `state.id` (dot notation)

**XQL-Dateien prüfen:**
```xquery
(: Sollte sein: :)
let $document.id := request:get-parameter('document.id','')
let $element.id := request:get-parameter('element.id','')

(: NICHT: :)
let $documentId := request:get-parameter('documentId','')
```

Falls XQL-Dateien für RESTXQ geändert wurden, Parameter-Namen zurückändern.

---

### Schritt 9: RESTXQ deaktivieren

#### Option A: RESTXQ-Module umbenennen (temporär deaktivieren)

```bash
cd source/xqm/rest/
mv iiif-api.xqm iiif-api.xqm.disabled
mv module1-api.xqm module1-api.xqm.disabled
mv module2-api.xqm module2-api.xqm.disabled
mv module3-api.xqm module3-api.xqm.disabled
mv module4-api.xqm module4-api.xqm.disabled
mv services-api.xqm services-api.xqm.disabled
mv openapi-endpoint.xqm openapi-endpoint.xqm.disabled
```

#### Option B: RESTXQ-Module löschen

```bash
cd source/xqm/rest/
rm -f iiif-api.xqm module1-api.xqm module2-api.xqm module3-api.xqm module4-api.xqm services-api.xqm openapi-endpoint.xqm
```

**Behalten:** `api-base.xqm` und `README.md` (für zukünftige Nutzung)

---

### Schritt 10: Controller.xql RESTXQ-Delegation entfernen

**Zu entfernen:**
```xquery
(: IIIF endpoints - migrated to RESTXQ :)
if (starts-with($exist:path, '/iiif/')) then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}"/>
    </dispatch>
) else
```

**Falls andere RESTXQ-Delegationen existieren, auch diese entfernen.**

---

### Schritt 11: Build und Deploy

```bash
# Build neu erstellen
npm run build

# Package neu erstellen
npm run package

# Deploy in eXist-db
# Option 1: Docker
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d

# Option 2: Manuell via Package Manager
# Upload dist/api-0.3.0.xar
```

---

### Schritt 12: Testing

**Test-Checklist:**

```bash
# 1. IIIF-Endpunkte testen
curl http://localhost:8080/exist/apps/api/iiif/documents.json
curl http://localhost:8080/exist/apps/api/iiif/document/DOCUMENT_ID/manifest.json

# 2. Module 1
curl http://localhost:8080/exist/apps/api/data.json
curl http://localhost:8080/exist/apps/api/document/DOCUMENT_ID/pages.json

# 3. Module 2
curl http://localhost:8080/exist/apps/api/module2/getWorks.xql

# 4. Services
curl http://localhost:8080/exist/apps/api/file/FILE_ID
curl http://localhost:8080/exist/apps/api/1/context.json

# 5. CORS-Header prüfen
curl -I http://localhost:8080/exist/apps/api/data.json | grep -i "access-control"
```

---

## Zusammenfassung der Änderungen

### Dateien zu ändern

1. **`source/eXist-db/controller.xql`**
   - IIIF-RESTXQ-Delegation durch klassische Routes ersetzen
   - OpenAPI-Route prüfen
   - Alle anderen Routes sind bereits vorhanden

2. **XQL-Dateien erstellen/anpassen:**
   - `source/xql/iiif/get-documents.xql` (NEU)
   - `source/xql/file/get-svg-file.xql` (prüfen/erstellen)
   - Andere IIIF-XQL-Dateien auf Parameter-Handling prüfen

3. **RESTXQ-Module deaktivieren/löschen:**
   - `source/xqm/rest/iiif-api.xqm`
   - `source/xqm/rest/module1-api.xqm`
   - `source/xqm/rest/module2-api.xqm`
   - `source/xqm/rest/module3-api.xqm`
   - `source/xqm/rest/module4-api.xqm`
   - `source/xqm/rest/services-api.xqm`
   - `source/xqm/rest/openapi-endpoint.xqm`

### Dateien zu behalten

- `source/xqm/rest/api-base.xqm` (für zukünftige Nutzung)
- `source/xqm/rest/README.md`
- Alle XQL-Dateien in `source/xql/`

---

## Vor- und Nachteile des Rollbacks

### Vorteile
1. **Einfachere Architektur**: Nur ein Routing-Mechanismus (Controller)
2. **Weniger Abstraktionsebenen**: Direkter Zugriff auf XQL-Dateien
3. **Bewährte Lösung**: Controller-Ansatz ist seit Jahren stabil
4. **Kein RESTXQ-Setup nötig**: Weniger Konfiguration in eXist-db

### Nachteile
1. **Weniger moderne API-Struktur**: RESTXQ ist der eXist-db Standard für REST APIs
2. **Keine Auto-Dokumentation**: OpenAPI-Integration schwieriger
3. **Redundanter CORS-Code**: Jede XQL-Datei muss Header setzen
4. **Schwerer zu testen**: Funktionen sind nicht isoliert testbar
5. **Längerer Controller**: Alle Routes im Controller = unübersichtlicher

---

## Rollback im Detail: Controller.xql Änderungen

### Vollständige Controller.xql nach Rollback

```xquery
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
    response:set-header("Access-Control-Allow-Origin", "*"),
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
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: IIIF manifest (alternative path without .json) :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/manifest$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-manifest.json.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
) else

(: IIIF measure zones annotation list :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/list/[\da-zA-Z_\.\-]+_zones')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-measure-positions-on-page.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="canvasId" value="{substring-before(tokenize($exist:path,'/')[last()],'_zones')}"/>
        </forward>
    </dispatch>
) else

(: IIIF SVG overlays :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/overlays/[\da-zA-Z_\.\-]+\.svg')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/file/get-svg-file.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="svgFileName" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(: IIIF SVG overlays with data attributes :)
if (matches($exist:path, '/iiif/document/[\da-zA-Z_\.\-]+/overlaysPlus/[\da-zA-Z_\.\-]+\.svg')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/svg/get-svg-file-with-data-atts.xql">
            <add-parameter name="documentId" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="svgFileName" value="{tokenize($exist:path,'/')[last()]}"/>
        </forward>
    </dispatch>
) else

(:~
 : Context API, Module 1-4, Services
 : (bereits vorhanden im Controller - siehe controller.xql)
 :)
 
(: ... Rest des Controllers bleibt unverändert ... :)

```

---

## Alternative: Hybrid-Ansatz beibehalten

Falls Sie **nicht alle** RESTXQ-Endpunkte zurückbauen möchten:

### Variante 1: Nur IIIF zurückbauen
- IIIF-Endpunkte in Controller integrieren
- Module 1-4 bleiben in RESTXQ
- Begründung: IIIF ist relativ isoliert

### Variante 2: Schrittweiser Rollback
1. IIIF zurückbauen
2. Module 3 & 4 zurückbauen (wenige Endpunkte)
3. Module 2 zurückbauen
4. Module 1 zurückbauen
5. Services zurückbauen

---

## Nächste Schritte für vollständigen Rollback

1. ✅ Dokumentation lesen und verstehen
2. Controller.xql IIIF-Delegation durch klassische Routes ersetzen
3. Fehlende XQL-Dateien erstellen (`get-documents.xql`, `get-svg-file.xql`)
4. RESTXQ-Module deaktivieren/löschen
5. Build & Deploy
6. Testing aller Endpunkte
7. Commit der Änderungen

---

## Ressourcen

- Aktuelle `controller.xql`: `source/eXist-db/controller.xql`
- XQL-Dateien: `source/xql/`
- RESTXQ-Module: `source/xqm/rest/`

---

## Anhang: Endpunkt-Vergleich controller-legacy.xql vs. controller.xql

Diese Analyse vergleicht die Endpunkte in `controller-legacy.xql` (ältere RESTful-Implementierung) mit denen in `controller.xql` (aktuelle Controller-basierte Implementierung nach RESTXQ-Rollback).

### URL-Pattern-Unterschiede

**Hauptunterschied in der Architektur:**
- **controller-legacy.xql**: Verwendet RESTful URLs mit Modul-Präfixen: `/module1/edition/{id}/...`
- **controller.xql**: Verwendet flachere URLs für Module 1: `/document/{id}/...` und `.xql`-Suffixe für Module 2-4

### In controller-legacy.xql vorhandene, aber in controller.xql fehlende Endpunkte

#### Context API (1 Endpunkt)
```
✅ GET /{version}/context.json
```
- **Legacy**: `/\d/context.json` → `context.xql`
- **Current**: Vorhanden mit gleichem Muster
- **Status**: ✅ Identisch implementiert

---

#### IIIF Endpunkte (6 Endpunkte)
```
✅ GET /iiif/documents.json
✅ GET /iiif/document/{documentId}/manifest.json
✅ GET /iiif/document/{documentId}/manifest
✅ GET /iiif/document/{documentId}/list/{canvasId}_zones
✅ GET /iiif/document/{documentId}/overlays/{svgFileName}
✅ GET /iiif/document/{documentId}/overlaysPlus/{svgFileName}
```
- **Status**: ✅ Alle 6 IIIF-Endpunkte in beiden Controllern vorhanden
- **Unterschied**: Parameter-Namen unterschiedlich (`document.id` vs. `documentId`)

---

#### Module 1 VideApp (28 Endpunkte in Legacy)

**URL-Muster-Unterschied:**
- **Legacy**: `/module1/edition/{editionId}/...` oder `/module1/file/{fileId}...`
- **Current**: `/document/{documentId}/...`

##### In Legacy vorhanden, in Current **fehlend** oder **anders**:

1. **❌ GET /module1/listall.json**
   - Legacy: `get_all_MEI_files_from_DB_as_JSON.xql`
   - Current: ✅ Umbenannt zu `/data.json`
   - Status: ⚠️ URL geändert

2. **❌ GET /module1/file/{fileId}.xml**
   - Legacy: `get_MEI_file_as_XML.xql`
   - Current: ✅ Neu: `/document/{documentId}/file.xml`
   - Status: ⚠️ URL-Struktur geändert

3. **❌ GET /module1/edition/{editionId}/finalstate.xml**
   - Legacy: `get_final_state_as_XML.xql`
   - Current: ✅ Neu: `/document/{documentId}/finalState.xml`
   - Status: ⚠️ URL-Struktur geändert

4. **❌ GET /module1/edition/{editionId}/element/{elementId}.xml**
   - Legacy: `get_MEI_snippet_as_XML.xql`
   - Current: ✅ Neu: `/document/{documentId}/snippet/{elementId}.xml`
   - Status: ⚠️ URL-Struktur geändert

5. **❌ GET /module1/edition/{editionId}/element/{elementId}/{w},{h}/facsimileinfo.json**
   - Legacy: `get_facsimile_info_for_element_as_JSON.xql` mit Breite/Höhe-Parametern
   - Current: ✅ Neu: `/document/{documentId}/element/{elementId}/facsimile.json` (w/h als Query-Parameter)
   - Status: ⚠️ URL-Struktur geändert

6. **❌ GET /module1/file/{fileId}.svg**
   - Legacy: `get_SVG_file_as_XML.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

7. **❌ GET /module1/edition/{editionId}/states/overview.json**
   - Legacy: `get_geneticStatesList_as_JSON.xql`
   - Current: ✅ Neu: `/document/{documentId}/geneticStates.json`
   - Status: ⚠️ URL-Struktur geändert

8. **❌ GET /module1/edition/{editionId}/annotations.json**
   - Legacy: `get_annotations_as_json.xql`
   - Current: ✅ Neu: `/document/{documentId}/annotations.json`
   - Status: ⚠️ URL-Struktur geändert

9. **❌ GET /module1/edition/{editionId}/page/{pageId}/annotations.json**
   - Legacy: `get_annotations_on_page_as_json.xql`
   - Current: ✅ Neu: `/document/{documentId}/page/{pageId}/annotations.json`
   - Status: ⚠️ URL-Struktur geändert

10. **❌ GET /module1/edition/{editionId}/scars/categories.json**
    - Legacy: `get_scar_categories_as_JSON.xql`
    - Current: ❌ **Fehlt komplett**
    - Status: ❌ Nicht implementiert

11. **❌ GET /module1/edition/{editionId}/state/{stateId}/otherStates/{otherStates}/meiSnippet.xml**
    - Legacy: `get_geneticState_as_XML.xql` mit anderen States
    - Current: ✅ Neu: `/document/{documentId}/geneticState/{stateId}.xml` (ohne otherStates-Parameter)
    - Status: ⚠️ Vereinfacht, otherStates fehlt

12. **❌ GET /module1/edition/{editionId}/element/{elementId}/states/{states}/preview.xml**
    - Legacy: `get_element_preview_as_XML.xql`
    - Current: ✅ Neu: `/document/{documentId}/element/{elementId}/preview.xml` (states als Query-Parameter)
    - Status: ⚠️ URL-Struktur geändert

13. **❌ GET /module1/edition/{editionId}/element/{elementId}/{lang}/description.json**
    - Legacy: `get_element_description_as_JSON.xql` mit Sprache im Pfad
    - Current: ✅ Neu: `/document/{documentId}/element/{elementId}/description.json` (lang als Query-Parameter)
    - Status: ⚠️ URL-Struktur geändert

14. **❌ GET /module1/edition/{editionId}/firstState/meiSnippet.xml**
    - Legacy: `get_geneticState_as_XML.xql` mit leerem stateId
    - Current: ❌ **Fehlt komplett** (nur `/geneticState/{stateId}.xml`)
    - Status: ❌ Nicht implementiert

15. **❌ GET /module1/edition/{editionId}/reconstructionSetup.json**
    - Legacy: `get_reconstruction_setup_as_JSON.xql`
    - Current: ✅ Neu: `/document/{documentId}/reconstructionSetup.json`
    - Status: ⚠️ URL-Struktur geändert

16. **❌ GET /module1/edition/{editionId}/invarianceRelations.json**
    - Legacy: `get_invariance_relations_as_JSON.xql`
    - Current: ✅ Neu: `/document/{documentId}/invariances.json`
    - Status: ⚠️ URL-Struktur geändert

17. **❌ GET /module1/edition/{editionId}/shape/{shapeId}/info.json**
    - Legacy: `get_shape_info_as_JSON.xql`
    - Current: ❌ **Fehlt komplett**
    - Status: ❌ Nicht implementiert

18. **❌ GET /module1/edition/{editionId}/object/{objectId}/shapes.json**
    - Legacy: `get_shapes_for_object_as_JSON.xql`
    - Current: ❌ **Fehlt komplett**
    - Status: ❌ Nicht implementiert

19. **❌ GET /module1/edition/{editionId}/introduction.html**
    - Legacy: `get_introduction_as_HTML.xql`
    - Current: ✅ Neu: `/document/{documentId}/introduction.html`
    - Status: ⚠️ URL-Struktur geändert

20. **❌ GET /module1/edition/{editionId}/pages.json**
    - Legacy: `get_pages_in_edition_as_JSON.xql`
    - Current: ✅ Neu: `/document/{documentId}/pages.json`
    - Status: ⚠️ URL-Struktur geändert

21. **❌ GET /module1/edition/{editionId}/measures.json**
    - Legacy: `get_measure_overview_as_JSON.xql`
    - Current: ✅ Neu: `/document/{documentId}/measures.json`
    - Status: ⚠️ URL-Struktur geändert

**Module 1 Zusammenfassung:**
- **Legacy hat**: 28 Endpunkte mit `/module1/edition/{id}/...` Pattern
- **Current hat**: 17 Endpunkte mit `/document/{id}/...` Pattern
- **Komplett fehlend**: 4 Endpunkte (scars/categories, shapes/info, firstState, SVG-Dateien)
- **URL-Struktur geändert**: 14 Endpunkte (funktional äquivalent, aber andere URL)

---

#### Module 2 Analyse-Endpunkte (6 Legacy vs. 13 Current)

**URL-Muster-Unterschied:**
- **Legacy**: `/module2/data/{comparisonId}/mdiv/{mdivId}/transpose/{transpose}/...`
- **Current**: `/module2/*.xql` (direkte XQL-Aufrufe mit Query-Parametern)

##### In Legacy vorhanden:

1. **❌ GET /module2/comparisons.json**
   - Legacy: `getComparisonListing.xql`
   - Current: ✅ Neu: `/module2/listComparisons.xql`
   - Status: ⚠️ URL geändert

2. **❌ GET /module2/data/{comparisonId}/mdiv/{mdivId}/transpose/{transpose}/basic.xml**
   - Legacy: `getAnalysis.xql?method=comparison`
   - Current: ✅ Neu: `/module2/getAnalysis.xql` (mit Query-Parametern)
   - Status: ⚠️ URL-Struktur geändert (RESTful → Query-Parameter)

3. **❌ GET /module2/data/{comparisonId}/mdiv/{mdivId}/transpose/{transpose}/eventDensity.xml**
   - Legacy: `getAnalysis.xql?method=eventDensity`
   - Current: ✅ Neu: `/module2/getAnalysis.xql` (mit method=eventDensity)
   - Status: ⚠️ URL-Struktur geändert

4. **❌ GET /module2/data/{comparisonId}/mdiv/{mdivId}/transpose/{transpose}/melodicComparison.xml**
   - Legacy: `getAnalysis.xql?method=melodicComparison`
   - Current: ✅ Neu: `/module2/getAnalysis.xql` (mit method=melodicComparison)
   - Status: ⚠️ URL-Struktur geändert

5. **❌ GET /module2/data/{comparisonId}/mdiv/{mdivId}/transpose/{transpose}/harmonicComparison.xml**
   - Legacy: `getAnalysis.xql?method=harmonicComparison`
   - Current: ✅ Neu: `/module2/getAnalysis.xql` (mit method=harmonicComparison)
   - Status: ⚠️ URL-Struktur geändert

6. **❌ GET /module2/{comparisonId}/intro.html**
   - Legacy: `getTextIntroduction.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

**Module 2 hat zusätzlich in Current:**
- `/module2/getAnalysisByMei.xql`
- `/module2/getAnalysesDashboard.xql`
- `/module2/getComparisonFragments.xql`
- `/module2/getComparison.xql`
- `/module2/getFragment.xql`
- `/module2/getMei.xql`
- `/module2/getWork.xql`
- `/module2/getWorks.xql`
- `/module2/listAnalyses.xql`
- `/module2/listCombinations.xql`
- `/module2/listWorksWithAnalyses.xql`

**Module 2 Zusammenfassung:**
- **Legacy hat**: 6 Analyse-Endpunkte mit RESTful URL-Struktur
- **Current hat**: 13 XQL-Endpunkte mit direkten Dateinamen
- **Fehlend**: 1 Endpunkt (`intro.html`)
- **Current hat mehr Funktionalität**: 7 zusätzliche Endpunkte für erweiterte Analysen

---

#### Module 3 Werk-Endpunkte (9 Legacy vs. 3 Current)

**URL-Muster-Unterschied:**
- **Legacy**: `/module3/{workId}/...` (RESTful mit verschachtelten Ressourcen)
- **Current**: `/module3/*.xql` (3 XQL-Dateien)

##### In Legacy vorhanden, in Current fehlend:

1. **❌ GET /module3/works.json**
   - Legacy: `module3-get-works.xql`
   - Current: ✅ Neu: `/module3/work-list.xql`
   - Status: ⚠️ URL geändert

2. **❌ GET /module3/{workId}.json**
   - Legacy: `get-work.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

3. **❌ GET /module3/{workId}/manifestation/{manifestationId}.json**
   - Legacy: `get-manifestation.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

4. **❌ GET /module3/{workId}/mdiv/{mdivId}.json**
   - Legacy: `get-mdiv.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

5. **❌ GET /module3/{workId}/manifestation/{manifestationId}/measures.json**
   - Legacy: `get-measures-in-mdiv.xql` (mit scope, mdivId, part Query-Parametern)
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

6. **❌ GET /module3/{workId}/measure/{measureId}.json**
   - Legacy: `get-measure.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

7. **❌ GET /module3/{workId}/complaints/{complaintId}.json**
   - Legacy: `get-complaint.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

8. **❌ GET /module3/{workId}/snippet/{contextId}.mei**
   - Legacy: `get-complaint-text-by-annot.xql` (mit source, state, focus Query-Parametern)
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

9. **❌ GET /module3/{workId}/snippet/{contextId}.tei**
   - Legacy: `get-complaint-TEI-text-by-annot.xql` (mit source, state Query-Parametern)
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

**Module 3 Zusammenfassung:**
- **Legacy hat**: 9 Endpunkte mit verschachtelter RESTful-Struktur
- **Current hat**: 3 XQL-Endpunkte (`available-works.xql`, `mei2json.xql`, `work-list.xql`)
- **Komplett fehlend**: 8 von 9 Legacy-Endpunkten
- **Status**: ❌ Massive Funktionsreduzierung in Module 3

---

#### Module 4 Dokument-Endpunkte (2 Legacy vs. 2 Current)

1. **❌ GET /module4/documents.json**
   - Legacy: `module4-get-documents.xql`
   - Current: ✅ Neu: `/module4/getSourceSummary.xql` oder `/module4/get_source_summary_as_json.xql`
   - Status: ⚠️ Unterschiedliche URLs

2. **❌ GET /documents/{documentId}.json**
   - Legacy: `get-document.xql`
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert

**Module 4 Zusammenfassung:**
- **Legacy**: 2 Endpunkte mit `/module4/` und `/documents/` Präfixen
- **Current**: 2 XQL-Endpunkte mit unterschiedlichen Namen
- **Fehlend**: 1 Endpunkt (`/documents/{documentId}.json`)

---

#### File & Element Service Endpunkte (3 Legacy vs. 2 Current)

1. **✅ GET /file/{documentId}/element/{elementId}**
   - Legacy: `file/get-element.xql`
   - Current: ✅ `/element/{elementId}` → `file/get-element.xql`
   - Status: ⚠️ URL-Struktur vereinfacht

2. **✅ GET /file/{documentId}.xml**
   - Legacy: `file/get-file.xql`
   - Current: ✅ `/file/{fileId}` → `file/get-file.xql`
   - Status: ⚠️ URL-Struktur vereinfacht

3. **❌ GET /desc/{elementId}.json**
   - Legacy: `tools/get_element_description_as_JSON.xql` (mit lang='de')
   - Current: ❌ **Fehlt komplett**
   - Status: ❌ Nicht implementiert (sollte in Module 1 sein: `/document/{documentId}/element/{elementId}/description.json`)

---

### Gesamtübersicht: Fehlende Endpunkte

#### Komplett fehlende Endpunkte (15):

**Module 1 (4):**
1. `/module1/edition/{editionId}/scars/categories.json`
2. `/module1/edition/{editionId}/shape/{shapeId}/info.json`
3. `/module1/edition/{editionId}/object/{objectId}/shapes.json`
4. `/module1/edition/{editionId}/firstState/meiSnippet.xml`

**Module 2 (1):**
5. `/module2/{comparisonId}/intro.html`

**Module 3 (8):**
6. `/module3/{workId}.json`
7. `/module3/{workId}/manifestation/{manifestationId}.json`
8. `/module3/{workId}/mdiv/{mdivId}.json`
9. `/module3/{workId}/manifestation/{manifestationId}/measures.json`
10. `/module3/{workId}/measure/{measureId}.json`
11. `/module3/{workId}/complaints/{complaintId}.json`
12. `/module3/{workId}/snippet/{contextId}.mei`
13. `/module3/{workId}/snippet/{contextId}.tei`

**Module 4 (1):**
14. `/documents/{documentId}.json`

**Tools (1):**
15. `/desc/{elementId}.json`

#### URL-Struktur geändert, aber funktional äquivalent (23):

**Module 1 (14):** `/module1/edition/{id}/...` → `/document/{id}/...`
**Module 2 (6):** RESTful Pfad-Parameter → Query-Parameter in `/module2/getAnalysis.xql`
**Module 3 (1):** `/module3/works.json` → `/module3/work-list.xql`
**Module 4 (1):** `/module4/documents.json` → verschiedene Namen
**Services (1):** Pfad vereinfacht

---

### Empfehlungen

#### Für vollständige Abwärtskompatibilität:

1. **Module 1**: Fügen Sie URL-Rewrite-Regeln hinzu oder duplizieren Sie Routen:
   ```xquery
   (: Legacy URL support :)
   if (matches($exist:path, '/module1/edition/([\da-zA-Z_\.\-]+)/(.*)')) then (
       let $documentId := tokenize($exist:path,'/')[3]
       let $rest := substring-after($exist:path, concat('/module1/edition/', $documentId, '/'))
       return
       <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
           <forward url="/document/{$documentId}/{$rest}"/>
       </dispatch>
   )
   ```

2. **Module 3**: Implementieren Sie die 8 fehlenden Endpunkte aus Legacy, da diese wichtige Werk-/Manifestations-/Measures-Funktionalität bieten.

3. **Fehlende Funktionalität**: Priorisieren Sie:
   - **Hoch**: Module 3 Endpunkte (für Werk-Navigation essentiell)
   - **Mittel**: Module 1 Shapes/Scars (für Annotations-Features)
   - **Niedrig**: `/desc/{elementId}.json` (redundant zu Module 1 description)

#### Für Migration auf neue URLs:

- Dokumentieren Sie alle URL-Änderungen in einem Migrations-Guide
- Bieten Sie eine Übergangsphase mit beiden URL-Schemas
- Aktualisieren Sie Frontend-Anwendungen auf neue URL-Struktur

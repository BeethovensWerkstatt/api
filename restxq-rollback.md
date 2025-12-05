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
curl http://localhost:8082/exist/apps/api/iiif/documents.json
curl http://localhost:8082/exist/apps/api/iiif/document/DOCUMENT_ID/manifest.json

# 2. Module 1
curl http://localhost:8082/exist/apps/api/data.json
curl http://localhost:8082/exist/apps/api/document/DOCUMENT_ID/pages.json

# 3. Module 2
curl http://localhost:8082/exist/apps/api/module2/getWorks.xql

# 4. Services
curl http://localhost:8082/exist/apps/api/file/FILE_ID
curl http://localhost:8082/exist/apps/api/1/context.json

# 5. CORS-Header prüfen
curl -I http://localhost:8082/exist/apps/api/data.json | grep -i "access-control"
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

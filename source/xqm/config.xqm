xquery version "3.1";

module namespace config="https://api.beethovens-werkstatt.de";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/resources/")
;

declare variable $config:data-root := $config:app-root || "/data/";

declare variable $config:module3-root := $config:data-root || "/module3/";

declare variable $config:iiif-basepath := 'https://api.beethovens-werkstatt.de/iiif/';

declare variable $config:file-basepath := 'https://api.beethovens-werkstatt.de/file/';

declare variable $config:module3-basepath := 'https://api.beethovens-werkstatt.de/module3/';

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

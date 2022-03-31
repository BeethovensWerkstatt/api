<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs math xd tei mei"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 24, 2021</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:include href="./../tools/addid.xsl"/>
    <xsl:include href="./../tools/addtstamps.xsl"/>
    
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>The ID of the element that's indicating the snippet to be shown.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="context.id" as="xs:string"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The ID of the source for which the text is to be shown.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="source.id" as="xs:string"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The ID of the genetic state which is to be shown.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="state.id" as="xs:string"/>
    
    <xsl:param name="text.file" as="xs:string"/>
    
    <xsl:variable name="text.doc" select="parse-xml($text.file)" as="node()"/>

    <xd:doc>
        <xd:desc>
            <xd:p>The annot / metaMark element which delimit the content that is to be retrieved</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="context" select="id($context.id)" as="node()"/>
    <!--<xsl:variable name="start.measures" select="for $annot in $annots return ancestor::mei:measure" as="node()*"/>-->
    
    <xsl:variable name="active.state" select="$text.doc/id($state.id)" as="node()"/>
    <xsl:variable name="activated.states" select="$active.state | $active.state/preceding::mei:genState" as="node()*"/>
    <xsl:variable name="activated.states.ids" select="$activated.states/@xml:id" as="xs:string*"/>
    
    <xsl:variable name="excerpt" as="node()*">
        <xsl:variable name="start.id" select="replace($context/@startid,'#','')" as="xs:string"/>
        <xsl:variable name="end.id" select="replace($context/@endid,'#','')" as="xs:string"/>
        <xsl:variable name="start.elem" select="id($start.id)" as="element(tei:anchor)"/>
        <xsl:variable name="end.elem" select="id($end.id)" as="element(tei:anchor)"/>
        <xsl:sequence select="$start.elem/following-sibling::node()[. &lt;&lt; $end.elem]"/>
    </xsl:variable>
    
    <xsl:variable name="grouped.lines" as="node()*">
        <xsl:for-each-group select="$excerpt" group-starting-with="tei:lb">
            <!-- the following condition helps to avoid empty blank lines -->
            <xsl:if test="some $node in current-group() satisfies ($node instance of element() or normalize-space($node) != '')">
                <div class="line">
                    <xsl:sequence select="current-group()" xml:space="preserve"/>
                </div>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:variable>
    
    <xsl:variable name="cleaned.source" as="node()*">
        <xsl:apply-templates select="$grouped.lines" mode="getSource"/>
    </xsl:variable>
    
    <xsl:variable name="cleaned.state" as="node()*">
        <xsl:apply-templates select="$cleaned.source" mode="getState"/>
    </xsl:variable>
    
    <xsl:variable name="translated.tei" as="node()*">
        <xsl:apply-templates select="$cleaned.state" mode="tei2html" xml:space="preserve"/>
    </xsl:variable>
    
    <xsl:variable name="final.fixes" as="node()*">
        <xsl:choose>
            <xsl:when test="$state.id = ''">
                <xsl:comment select="'kept TEI'"/>
                <xsl:sequence select="$cleaned.source"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment select="'processed to HTML ' || $state.id"/>
                <xsl:apply-templates select="$translated.tei" mode="finalFixes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/" mode="#unnamed">
        <div>
            <xsl:apply-templates select="$final.fixes"/>
        </div>
    </xsl:template>
    
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>resolves mei:app elements</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:app" mode="getSource">
        <xsl:apply-templates select="child::mei:*['#' || $source.id = tokenize(normalize-space(@source),' ')]/node()" mode="#current"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>resolves elements that apply to a given source only</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:*[@source]" mode="getSource">
        <xsl:if test="'#' || $source.id = tokenize(normalize-space(@source),' ')">
            <xsl:next-match/>
        </xsl:if>
        
        <!-- this is probably coming from the text -->
        <xsl:if test="$source.id = '' and local-name() = 'corr' and parent::mei:choice">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>drop source attribute – not needed anymore </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@source" mode="getSource"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>gets choices out of the way</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:choice[every $child in child::mei:* satisfies $child/@source]" mode="getSource">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>resolves states</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:*[@state]" mode="getState">
        <xsl:variable name="name" select="local-name()" as="xs:string"/>
        <xsl:variable name="local.state" select="replace(@state,'#','')" as="xs:string"/>
        
        <xsl:choose>
            <xsl:when test="$name = ('add','supplied','corr','sic') and $local.state = $state.id">
                <!-- this is the very state which is looked at right now. It is kept for highlighting purposes. -->
                <xsl:copy>
                    <xsl:attribute name="type" select="normalize-space(@type || ' currentAction ' || local-name())"/>
                    <xsl:apply-templates select="node() | @* except @type" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="$name = 'add' and $local.state = $activated.states.ids">
                <xsl:apply-templates select="child::node()" mode="#current"/>
            </xsl:when>
            <xsl:when test="$name = 'add' and not($local.state = $activated.states.ids)"/>
            <xsl:when test="$name = 'del' and $local.state = $activated.states.ids">
                <xsl:apply-templates select=".//mei:restore[replace(@changeState,'#','') = $activated.states.ids]/child::node()" mode="#current"/>
            </xsl:when>
            <xsl:when test="$name = 'del' and not($local.state = $activated.states.ids)">
                <xsl:apply-templates select="child::node()" mode="#current"/>
            </xsl:when>
            <xsl:when test="$name = 'restore' and $local.state = $activated.states.ids">
                <xsl:comment>******Restore starts*******</xsl:comment>
                <xsl:apply-templates select="child::node()" mode="#current"/>
                <xsl:comment>******Restore ends******</xsl:comment>
            </xsl:when>
            <xsl:when test="$name = 'restore' and not($state.id = $activated.states.ids)"/>
            <xsl:when test="$name = 'metaMark' and $local.state = $activated.states.ids">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="$name = 'metaMark' and not($local.state = $activated.states.ids)"/>
            <xsl:otherwise>
                <xsl:apply-templates select="child::node()" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Drop all facs attributes</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@facs" mode="#all">
        <xsl:if test="$state.id = ''">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>If there are metaMarks with @place=rightmar, this will render them</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure[not(following::mei:measure)]" mode="finalFixes" priority="1">
        <xsl:next-match/>
        <xsl:variable name="metaMarks" select="(preceding::mei:measure//mei:metaMark[@place='rightmar'] | .//mei:metaMark[@place='rightmar'])" as="element(mei:metaMark)*"/>
        
        <xsl:if test="exists($metaMarks)">
            <measure xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="type" select="'invis'"/>
                <xsl:for-each select="./mei:staff">
                    <staff n="{position()}">
                        <layer n="1">
                            <mSpace/>
                        </layer>
                    </staff>
                </xsl:for-each>
                <xsl:for-each select="$metaMarks">
                    <dir xml:id="{@xml:id}" place="below" staff="1" tstamp="1" type="metaMark rightmar">
                        <xsl:apply-templates select="node()" mode="#current"/>
                    </dir> 
                </xsl:for-each>
            </measure>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="mei:measure[@label]" mode="finalFixes">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="not(exists(preceding::mei:measure))">
                <mNum xmlns="http://www.music-encoding.org/ns/mei" type="supplied">
                    <xsl:value-of select="string(@label)"/>
                </mNum>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Make metaMarks render with Verovio</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:metaMark['translate_dir' = tokenize(@class)]" mode="finalFixes">
        <dir xmlns="http://www.music-encoding.org/ns/mei" type="metaMark">
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="'place_above' = tokenize(@class)">
                <xsl:attribute name="place" select="'above'"/>
                <xsl:attribute name="staff" select="'1'"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </dir>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Get regular staff out of ossia, as Verovio doesn't do ossia yet</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:ossia" mode="finalFixes">
        <xsl:apply-templates select="child::mei:staff" mode="#current"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Translate dot elements to attributes</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:*[local-name() = ('note', 'rest', 'chord', 'space') and .//mei:dot]" mode="finalFixes">
        <xsl:copy>
            <xsl:attribute name="dots" select="count(.//mei:dot)"/>
            <xsl:if test="@facs or .//mei:dots/@facs">
                <xsl:attribute name="facs" select="string-join((@facs, .//mei:dots/@facs), ' ')"/>    
            </xsl:if>
            <xsl:apply-templates select="node() | @* except @facs" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:lb" mode="tei2html"/>
    
    <xsl:template match="tei:supplied" mode="tei2html"><span class="supplied"><xsl:apply-templates select="node()" mode="#current"/></span></xsl:template>
    
    <xsl:template match="*[@rend]" mode="tei2html" xml:space="preserve"><span class="rend {string(@rend)}"><xsl:apply-templates select="node()" mode="#current"/></span></xsl:template>
    
    <xsl:template match="tei:ref[starts-with(@target,'#')]" mode="tei2html">
        <span class="ref"><xsl:apply-templates select="node()" mode="#current"/></span>
    </xsl:template>
    
    <xsl:template match="tei:*" mode="tei2html" xml:space="preserve"><span class="tei {local-name()}"><xsl:for-each select="@*"><xsl:attribute name="data-{local-name(.)}" select="."/></xsl:for-each><xsl:apply-templates select="node()" mode="#current"/></span></xsl:template>
    
    <xsl:template match="tei:figure[./tei:notatedMusic]" mode="tei2html">
        <xsl:variable name="music" as="element(mei:music)">
            <music xmlns="http://www.music-encoding.org/ns/mei">
                <body>
                    <mdiv>
                        <score>
                            <xsl:apply-templates select="tei:notatedMusic/mei:section/mei:scoreDef[1]" mode="translateNotatedMusic"/>
                            <section>
                                <xsl:apply-templates select="tei:notatedMusic/mei:section/element()[position() gt 1]" mode="translateNotatedMusic"/>
                            </section>
                        </score>
                    </mdiv>
                </body>
            </music>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="tei:notatedMusic/@place = 'inline'">
                <xsl:variable name="small" select="if($music//mei:staffDef[@lines ne '0']) then('') else(' small')" as="xs:string"/>
                <span class="notatedMusic inline{$small}"><xsl:sequence select="$music"/></span>
            </xsl:when>
            <xsl:otherwise>
                <div class="notatedMusic block"><xsl:sequence select="$music"/></div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>A simple, mode-sensitive copy-template</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>
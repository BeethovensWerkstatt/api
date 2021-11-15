<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs math xd mei"
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
    
    <xsl:param name="text.file" as="xs:string"/>
    <xsl:variable name="text.doc" select="parse-xml($text.file)" as="node()"/>

    <xd:doc>
        <xd:desc>
            <xd:p>The annot / metaMark element which delimit the content that is to be retrieved</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="context" select="id($context.id)" as="node()"/>
    <!--<xsl:variable name="start.measures" select="for $annot in $annots return ancestor::mei:measure" as="node()*"/>-->
    
    <!-- this was happening in a loop formerly -->
    <xsl:variable name="ranges" as="node()">
        <xsl:variable name="annot" select="$context" as="node()"/>
        <xsl:variable name="first.measure" select="$annot/ancestor::mei:measure" as="node()"/>
        
        <xsl:variable name="subsequent.measures" select="if(starts-with($annot/@tstamp2,'0m+') or not(contains($annot/@tstamp2,'m+'))) then() else(($first.measure/following::mei:measure)[position() le xs:integer(substring-before($annot/@tstamp2,'m+'))])" as="node()*"/>
        <xsl:variable name="affected.measures" select="$first.measure | $subsequent.measures" as="node()+"/>
        <xsl:variable name="staves.n" select="if($annot/@staff) then(tokenize(normalize-space($annot/@staff),' ')) else(distinct-values($first.measure/mei:staff/@n))" as="xs:string*"/>
        
        <!-- delimit the area in which relevant features can be found -->
        <xsl:variable name="search.space" as="node()">
            
            <xsl:variable name="file.region" as="node()">
                <xsl:apply-templates select="$first.measure/ancestor::mei:*[local-name() = ('score','part')]" mode="getSearchSpace">
                    <xsl:with-param name="measure.id" select="$first.measure/@xml:id" tunnel="yes"/>
                    <xsl:with-param name="measure.n" select="$first.measure/@n" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:variable name="source.resolved" as="node()">
                <xsl:apply-templates select="$file.region" mode="getSource"/>
            </xsl:variable>
            <xsl:sequence select="$source.resolved"/>
        </xsl:variable>
        
        <!-- collect general information -->
        <xsl:variable name="meter.elem" select="($search.space//mei:meterSig[@count and @unit] | $search.space//mei:scoreDef[@meter.count and @meter.unit] | $search.space//mei:staffDef[@meter.count and @meter.unit])[last()]" as="node()"/>
        <xsl:variable name="meter.count" select="$meter.elem/@count | $meter.elem/@meter.count" as="xs:string"/>
        <xsl:variable name="meter.unit" select="$meter.elem/@unit | $meter.elem/@meter.unit" as="xs:string"/>
        <xsl:variable name="meter.sym" select="$meter.elem/@sym | $meter.elem/@meter.sym" as="xs:string?"/>
        <xsl:variable name="general.key.elem" select="($search.space//mei:scoreDef[@key.sig] | $search.space//mei:scoreDef/mei:keySig[@sig])[last()]" as="node()"/>
        <xsl:variable name="general.key.sig" select="$general.key.elem/@key.sig | $general.key.elem/@sig" as="xs:string"/>
        
        <xsl:variable name="is.score" select="exists($first.measure/ancestor::mei:score)" as="xs:boolean"/>
        
        <xsl:variable name="generated.scoreDef" as="node()">
            <scoreDef xmlns="http://www.music-encoding.org/ns/mei" type="supplied">
                <xsl:attribute name="meter.count" select="$meter.count"/>
                <xsl:attribute name="meter.unit" select="$meter.unit"/>
                <xsl:if test="$meter.sym">
                    <xsl:attribute name="meter.sym" select="$meter.sym"/>
                </xsl:if>
                <xsl:attribute name="key.sig" select="$general.key.sig"/>
                
                <xsl:variable name="relevant.staffGrp" select="$search.space//mei:scoreDef//mei:staffGrp[(every $n in $staves.n satisfies ./mei:staffDef[@n = $n]) and @symbol]" as="node()*"/>
                
                <xsl:variable name="staffGrp.symbol" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="count($staves.n) = 1">
                            <xsl:value-of select="'none'"/>
                        </xsl:when>
                        <xsl:when test="exists($relevant.staffGrp)">
                            <xsl:value-of select="$relevant.staffGrp[last()]/string(@symbol)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'none'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="staffGrp.label" as="element()?">
                    <xsl:choose>
                        <xsl:when test="count($staves.n) = 1"/>
                        <xsl:when test="exists($relevant.staffGrp/(mei:labelAbbr | mei:label))">
                            <xsl:variable name="labels" select="$relevant.staffGrp[mei:labelAbbr or mei:label][last()]/(mei:labelAbbr | mei:label)" as="node()+"/>
                            
                            <xsl:choose>
                                <xsl:when test="$labels/self::mei:labelAbbr">
                                    <label type="supplied" xmlns="http://www.music-encoding.org/ns/mei">
                                        <xsl:apply-templates select="$labels/self::mei:labelAbbr/(node() | @*)" mode="#unnamed"/>
                                    </label>
                                </xsl:when>
                                <xsl:otherwise>
                                    <label type="supplied" xmlns="http://www.music-encoding.org/ns/mei">
                                        <xsl:apply-templates select="$labels/self::mei:label/(node() | @*)" mode="#unnamed"/>
                                    </label>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:comment select="'search.space measures:' || count($search.space//mei:measure)"/>
                <xsl:comment select="'$search.space/@xml:id: ' || $search.space/@xml:id"/>
                <xsl:comment select="'$first.measure/@xml:id: ' || $first.measure/@xml:id"/>
                <xsl:comment select="'measures: ' || count($search.space//mei:measure[following::mei:measure[@xml:id = $first.measure/@xml:id]])"/>
                
                <!--<test>
                    <xsl:apply-templates select="$first.measure/ancestor::mei:*[local-name() = ('score','part')]" mode="getSearchSpace">
                        <xsl:with-param name="measure.id" select="$first.measure/@xml:id" tunnel="yes"/>
                        <xsl:with-param name="measure.n" select="$first.measure/@n" tunnel="yes"/>
                    </xsl:apply-templates>
                </test>-->
                
                
                <staffGrp bar.thru="{if($is.score) then('true') else('false')}" symbol="{$staffGrp.symbol}">
                    <xsl:if test="$relevant.staffGrp">
                        <xsl:attribute name="xml:id" select="$relevant.staffGrp[last()]/string(@xml:id)"/>
                    </xsl:if>
                    <xsl:sequence select="$staffGrp.label"/>
                    <xsl:for-each select="$staves.n">
                        <xsl:variable name="current.staff.n" select="." as="xs:string"/>
                        
                        <xsl:variable name="staff.key.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@key.sig] | $search.space//mei:staffDef[@n = $current.staff.n]/mei:keySig[@sig])[last()]" as="node()?"/>
                        <xsl:variable name="staff.key.sig" select="if(exists($staff.key.elem)) then($staff.key.elem/@key.sig | $staff.key.elem/@sig) else()" as="xs:string?"/>
                        
                        <xsl:variable name="is.multi.staff" select="exists($search.space//mei:staffDef[@n = $current.staff.n][not(mei:label or @label) and parent::mei:staffGrp[mei:label or @label][parent::mei:staffGrp]])" as="xs:boolean"/>
                        <xsl:choose>
                            <xsl:when test="not($is.multi.staff)">
                                
                                <xsl:variable name="staff.label" select="($search.space//mei:staffDef[@n = $current.staff.n]/@label | $search.space//mei:staffDef[@n = $current.staff.n]/mei:label/text() | $search.space/self::mei:part/@label)[last()]" as="xs:string"/>
                                
                                <xsl:variable name="clef.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@clef.shape and @clef.line] | $search.space//mei:staff[@n = $current.staff.n]//mei:clef)[last()]" as="node()"/>
                                <xsl:variable name="clef.shape" select="$clef.elem/@clef.shape | $clef.elem/@shape" as="xs:string"/>
                                <xsl:variable name="clef.line" select="$clef.elem/@clef.line | $clef.elem/@line" as="xs:string"/>
                                
                                <xsl:variable name="trans.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@trans.semi and @trans.diat])[last()]" as="node()?"/>
                                <xsl:variable name="trans.semi" select="if($trans.elem) then($trans.elem/@trans.semi) else()" as="xs:string?"/>
                                <xsl:variable name="trans.diat" select="if($trans.elem) then($trans.elem/@trans.diat) else()" as="xs:string?"/>
                                
                                <staffDef n="{$current.staff.n}" lines="5">
                                    <xsl:if test="not($staffGrp.symbol)">
                                        <xsl:attribute name="label" select="$staff.label"/>    
                                    </xsl:if>
                                    <xsl:attribute name="clef.shape" select="$clef.shape"/>
                                    <xsl:attribute name="clef.line" select="$clef.line"/>
                                    <xsl:if test="exists($staff.key.sig)">
                                        <xsl:attribute name="key.sig" select="$staff.key.sig"/>
                                    </xsl:if>
                                    <xsl:if test="exists($trans.elem)">
                                        <xsl:attribute name="trans.semi" select="$trans.semi"/>
                                        <xsl:attribute name="trans.diat" select="$trans.diat"/>
                                    </xsl:if>
                                    <xsl:comment select="'clef: ' || $clef.elem/@xml:id || ', measure ' || $clef.elem/ancestor::mei:measure/@label || ', staff ' || $clef.elem/ancestor::mei:staff/@n"/>
                                </staffDef>
                            </xsl:when>
                            <xsl:when test="$is.multi.staff">
                                <!-- when first in group, render full group (piano right hand takes everything…) -->
                                <xsl:variable name="initial.staffDef" select="($search.space//mei:staffDef[@n = $current.staff.n])[1]" as="node()"/>
                                <xsl:variable name="pos.in.group" select="count($initial.staffDef/preceding-sibling::mei:staffDef) + 1" as="xs:integer"/>
                                
                                <xsl:if test="$pos.in.group = 1 or not($initial.staffDef/preceding-sibling::mei:staffDef/string(@n) = $staves.n)">
                                    <xsl:variable name="following.staffDefs" select="$initial.staffDef/following-sibling::mei:staffDef[@n = $staves.n]" as="node()*"/>
                                    
                                    <xsl:variable name="staffDefs" as="node()+">
                                        <xsl:for-each select="$current.staff.n, $following.staffDefs/@n">
                                            <xsl:sort select="." data-type="number"/>
                                            <xsl:variable name="current.staff.n.in.group" select="." as="xs:string"/>
                                            
                                            <xsl:variable name="staff.label" select="($search.space//mei:staffDef[@n = $current.staff.n.in.group]/@label | $search.space//mei:staffDef[@n = $current.staff.n]/mei:label/text())[1]" as="xs:string?"/>
                                            
                                            <xsl:variable name="clef.elem" select="($search.space//mei:staffDef[@n = $current.staff.n.in.group][@clef.shape and @clef.line] | $search.space//mei:staff[@n = $current.staff.n.in.group]//mei:clef)[last()]" as="node()"/>
                                            <xsl:variable name="clef.shape" select="$clef.elem/@clef.shape | $clef.elem/@shape" as="xs:string"/>
                                            <xsl:variable name="clef.line" select="$clef.elem/@clef.line | $clef.elem/@line" as="xs:string"/>
                                            
                                            <xsl:variable name="trans.elem" select="($search.space//mei:staffDef[@n = $current.staff.n.in.group][@trans.semi and @trans.diat])[last()]" as="node()?"/>
                                            <xsl:variable name="trans.semi" select="if($trans.elem) then($trans.elem/@trans.semi) else()" as="xs:string?"/>
                                            <xsl:variable name="trans.diat" select="if($trans.elem) then($trans.elem/@trans.diat) else()" as="xs:string?"/>
                                            
                                            
                                            <staffDef n="{$current.staff.n.in.group}" lines="5">
                                                <xsl:if test="exists($staff.label) and not($staffGrp.symbol)">
                                                    <xsl:attribute name="label" select="$staff.label"/>
                                                </xsl:if>
                                                <xsl:attribute name="clef.shape" select="$clef.shape"/>
                                                <xsl:attribute name="clef.line" select="$clef.line"/>
                                                <xsl:if test="exists($staff.key.sig)">
                                                    <xsl:attribute name="key.sig" select="$staff.key.sig"/>
                                                </xsl:if>
                                                <xsl:if test="exists($trans.elem)">
                                                    <xsl:attribute name="trans.semi" select="$trans.semi"/>
                                                    <xsl:attribute name="trans.diat" select="$trans.diat"/>
                                                </xsl:if>
                                                <xsl:comment select="'clef: ' || $clef.elem/@xml:id || ', measure ' || $clef.elem/ancestor::mei:measure/@label || ', staff ' || $clef.elem/ancestor::mei:staff/@n"/>
                                            </staffDef>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    <xsl:sequence select="$staffDefs"/>
                                    
                                </xsl:if>
                                
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </staffGrp>
            </scoreDef>
        </xsl:variable>
        <xsl:variable name="generated.section" as="node()">
            <section xmlns="http://www.music-encoding.org/ns/mei">
                <!-- debug attributes:
                    measures="{count($search.space//mei:measure)}" 
                    elements="{string-join(distinct-values($search.space/descendant-or-self::mei:*/local-name()), ', ')}" 
                    meter.counts="{count($search.space//@meter.count) || ': ' || string-join(distinct-values($search.space//string(@meter.count)),', ')}"
                    scoreDefs="{string-join(distinct-values($search.space//mei:scoreDef/string(@xml:id)),', ')}"
                -->
                <xsl:variable name="region" as="node()*">
                    <xsl:apply-templates select="$affected.measures" mode="getSelectedStaves">
                        <xsl:with-param name="staves" select="$staves.n" tunnel="yes" as="xs:string*"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:variable name="source.resolved" as="node()*">
                    <xsl:apply-templates select="$region" mode="getSource"/>
                </xsl:variable>
                <xsl:sequence select="$source.resolved"/>
            </section>
        </xsl:variable>
        <range 
            first.measure="{normalize-space($first.measure/string(@label))}" 
            all.measures="{normalize-space(string-join($affected.measures/@label,' '))}" 
            is.score="{string($is.score)}"
            all.staves="{normalize-space(string-join($staves.n,' '))}">
            <xsl:sequence select="$generated.scoreDef"/>
            <xsl:sequence select="$generated.section"/>
        </range>
    </xsl:variable>
        
    <!-- merge multiple excerpts from different annots into one single score element. staff/@n are offset by 100 per movement -->
    <xsl:variable name="excerpted.score" as="node()">
        <score xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:choose>
                <!-- only one range is requested, so nothing to be merged -->
                <xsl:when test="count($ranges) = 1">
                    <xsl:sequence select="$ranges[1]/mei:scoreDef | $ranges[1]/mei:section"/>                    
                </xsl:when>
                <!-- all ranges start with the same measure, and they're coming from parts -->
                <xsl:when test="count(distinct-values($ranges/@first.measure)) = 1 and (every $is.score in $ranges/@is.score satisfies $is.score = 'false')">
                    <scoreDef>
                        <xsl:apply-templates select="$ranges[1]/mei:scoreDef/@*" mode="#unnamed"/>
                        <staffGrp bar.thru="false">
                            <xsl:for-each select="$ranges">
                                <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                <xsl:variable name="offset" select="$pos * 100" as="xs:integer"/>
                                <xsl:variable name="current.range" select="$ranges[$pos]" as="node()"/>
                                <xsl:apply-templates select="$current.range/mei:scoreDef/mei:staffGrp/(node() | @*)" mode="offsetStaves">
                                    <xsl:with-param name="offset" select="$offset" as="xs:integer" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </staffGrp>
                    </scoreDef>
                    <section>
                        <xsl:for-each select="$ranges[1]/mei:section/mei:measure">
                            <xsl:variable name="measure.pos" select="position()" as="xs:integer"/>
                            <xsl:copy>
                                <!-- get attributes on measure from first range -->
                                <xsl:apply-templates select="@*" mode="#unnamed"/>
                                <xsl:for-each select="$ranges">
                                    <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                    <xsl:variable name="offset" select="$pos * 100" as="xs:integer"/>
                                    <xsl:variable name="current.range" select="$ranges[$pos]" as="node()"/>
                                    <xsl:variable name="current.measure" select="($current.range//mei:measure)[$measure.pos]" as="node()"/>
                                    <xsl:apply-templates select="$current.measure/mei:staff" mode="offsetStaves">
                                        <xsl:with-param name="offset" select="$offset" as="xs:integer" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:for-each>
                                <xsl:if test="$measure.pos = 1">
                                    <mNum><xsl:value-of select="$ranges[1]/@first.measure"/></mNum>
                                </xsl:if>
                                <xsl:for-each select="$ranges">
                                    <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                    <xsl:variable name="offset" select="$pos * 100" as="xs:integer"/>
                                    <xsl:variable name="current.range" select="$ranges[$pos]" as="node()"/>
                                    <xsl:variable name="current.measure" select="($current.range//mei:measure)[$measure.pos]" as="node()"/>
                                    <xsl:apply-templates select="$current.measure/mei:*[not(local-name() = 'staff')]" mode="offsetStaves">
                                        <xsl:with-param name="offset" select="$offset" as="xs:integer" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:for-each>
                            </xsl:copy>
                        </xsl:for-each>
                    </section>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>TODO: Unable to correctly align multiple ranges. Using only the first range.</xsl:comment>
                    <xsl:sequence select="$ranges[1]/mei:scoreDef | $ranges[1]/mei:section"/>
                </xsl:otherwise>
            </xsl:choose>
        </score>
    </xsl:variable>
    
    <xsl:variable name="condensed.score" as="node()">
        <xsl:variable name="mappings" as="node()+">
            <xsl:for-each select="distinct-values($excerpted.score//mei:staffDef/@n)">
                <xsl:sort select="." data-type="number" order="ascending"/>
                <xsl:variable name="new" select="position()" as="xs:integer"/>
                <mapping old="{.}" new="{$new}"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:apply-templates select="$excerpted.score" mode="condenseScore">
            <xsl:with-param name="mappings" select="$mappings" tunnel="yes" as="node()+"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <!-- this is used to take care of measure numbers etc. -->
    <xsl:variable name="final.text" as="node()">
        <xsl:apply-templates select="$condensed.score" mode="finalFixes"/>
    </xsl:variable>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/" mode="#unnamed">
        <music xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:comment select="'context: ' || local-name($context) || ' '  || $context.id"/>
            <xsl:comment select="'stateless representation'"/>
            <xsl:comment select="'source: ' || $source.id"/>
            <body>
                <mdiv>
                    <xsl:comment select="'context.id: ' || $context.id"/>
                    <xsl:sequence select="$final.text"/>
                    <!--<xsl:sequence select="$ranges"/>-->
                </mdiv>
            </body>
        </music>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template is used to delimit the search room for features relevant for a given music snippet</xd:p>
        </xd:desc>
        <xd:param name="measure.id"></xd:param>
        <xd:param name="measure.n"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure" mode="getSearchSpace">
        <xsl:param name="measure.id" tunnel="yes" as="xs:string"/>
        <xsl:param name="measure.n" tunnel="yes" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="following::mei:measure[@xml:id = $measure.id] and xs:integer(@n) lt xs:integer($measure.n)">
                <!--<xsl:comment select="'measure ' || @label || ' passed test'"/>-->
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
                <!--<xsl:comment select="'skipping measure ' || @label"/>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template is used to delimit the search room for features relevant for a given music snippet</xd:p>
        </xd:desc>
        <xd:param name="measure.id"></xd:param>
    </xd:doc>
    <xsl:template match="mei:section" mode="getSearchSpace">
        <xsl:param name="measure.id" tunnel="yes" as="xs:string"/>
        <xsl:if test="following::mei:measure[@xml:id = $measure.id] or descendant::mei:measure[@xml:id = $measure.id]">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template filters out staves which aren't required for the current range</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:staff" mode="getSelectedStaves">
        <xsl:param name="staves" tunnel="yes" as="xs:string*"/>
        <xsl:if test="@n = $staves">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template preserves metaMarks, which are considered to be always relevant. TODO: See if we should add a @class for this.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:metaMark[@place]" mode="getSelectedStaves" priority="1">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template filters out control events on staves which aren't required for the current range</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure/mei:*[@staff]" mode="getSelectedStaves">
        <xsl:param name="staves" tunnel="yes" as="xs:string*"/>
        <xsl:if test="some $n in tokenize(normalize-space(@staff),' ') satisfies $n = $staves">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template restricts staves references from control events to only those which are to be kept</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure/mei:*/@staff" mode="getSelectedStaves">
        <xsl:param  name="staves" tunnel="yes" as="xs:string*"/>
        <xsl:variable name="relevant.staves" select="for $n in tokenize(normalize-space(.),' ') return (if($n = $staves) then($n) else())" as="xs:string*"/>
        <xsl:attribute name="staff" select="string-join($relevant.staves,' ')"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template filters out control events which affect other staves only and are using @startid / @plist only, but not @staff. 
                It assumes that the starting element is encoded in the same measure, and that it affects only the staff on which the starting 
                element is located. It looks for the first element referenced in @plist.</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure/mei:*[not(local-name() = 'staff')][not(@staff)][@startid or @plist]" mode="getSelectedStaves">
        <xsl:param  name="staves" tunnel="yes" as="xs:string*"/>
        <xsl:variable name="ref" select="if(@startid) then(replace(@startid,'#','')) else(replace(tokenize(normalize-space(@plist),' ')[1],'#',''))" as="xs:string"/>
        <xsl:variable name="staff.n" select="ancestor::mei:measure//mei:*[@xml:id = $ref]/ancestor::mei:staff/@n" as="xs:string?"/>
        <xsl:if test="exists($staff.n) and $staff.n = $staves">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Spreads out staves</xd:p>
        </xd:desc>
        <xd:param name="offset"></xd:param>
    </xd:doc>
    <xsl:template match="mei:staff/@n | mei:staffDef/@n" mode="offsetStaves">
        <xsl:param name="offset" tunnel="yes" as="xs:integer"/>
        <xsl:attribute name="n" select="xs:integer(normalize-space(.)) + $offset"/>
    </xsl:template>
        
    <xd:doc>
        <xd:desc>
            <xd:p>Spreads out staves</xd:p>
        </xd:desc>
        <xd:param name="offset"></xd:param>
    </xd:doc>
    <xsl:template match="@staff" mode="offsetStaves">
        <xsl:param name="offset" tunnel="yes" as="xs:integer"/>
        <xsl:variable name="old.tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
        <xsl:variable name="new.tokens" select="for $token in $old.tokens return string(xs:integer($token) + $offset)" as="xs:string*"/>
        <xsl:attribute name="staff" select="string-join($new.tokens,' ')"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Condenses staff numbers</xd:p>
        </xd:desc>
        <xd:param name="mappings"></xd:param>
    </xd:doc>
    <xsl:template match="mei:staff/@n | mei:staffDef/@n" mode="condenseScore">
        <xsl:param name="mappings" tunnel="yes" as="node()+"/>
        <xsl:variable name="old" select="." as="xs:string"/>
        <xsl:variable name="new" select="$mappings[@old = $old]/@new" as="xs:string"/>
        <xsl:attribute name="n" select="$new"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Condenses staff numbers</xd:p>
        </xd:desc>
        <xd:param name="mappings"></xd:param>
    </xd:doc>
    <xsl:template match="@staff" mode="condenseScore">
        <xsl:param name="mappings" tunnel="yes" as="node()+"/>
        <xsl:variable name="old.tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
        <xsl:variable name="new.tokens" select="for $old in $old.tokens return $mappings[@old = $old]/@new" as="xs:string*"/>
        <xsl:attribute name="staff" select="string-join($new.tokens,' ')"/>
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
            <xd:p>This takes care of measure numbers</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure" mode="finalFixes">
        <xsl:choose>
            <xsl:when test="preceding::mei:measure">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <mNum type="supplied" xmlns="http://www.music-encoding.org/ns/mei"><xsl:value-of select="if(@label) then(@label) else(@n)"/></mNum>
                    <xsl:apply-templates select="node()" mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:staffDef[ancestor::mei:scoreDef/@type='supplied']" mode="finalFixes">
        <xsl:copy>
            <xsl:apply-templates select="@* except (@meter.sig, @key.sig, @clef.line, @clef.shape, @label, @label)" mode="#current"/>
            <meterSig type="supplied" xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="count" select="ancestor-or-self::mei:*[@meter.count][1]/@meter.count"/>
                <xsl:attribute name="unit" select="ancestor-or-self::mei:*[@meter.unit][1]/@meter.unit"/>
                <xsl:if test="ancestor-or-self::mei:*[@meter.sym]">
                    <xsl:attribute name="sym" select="ancestor-or-self::mei:*[@meter.sym][1]/@meter.sym"/>
                </xsl:if>
            </meterSig>
            <xsl:if test="ancestor-or-self::mei:*/@key.sig">
                <keySig type="supplied" xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="sig" select="ancestor-or-self::mei:*[@key.sig][1]/@key.sig"/>
                </keySig>
            </xsl:if>
            <xsl:if test="@clef.line">
                <clef type="supplied" xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="line" select="ancestor-or-self::mei:*[@clef.line][1]/@clef.line"/>
                    <xsl:attribute name="shape" select="ancestor-or-self::mei:*[@clef.shape][1]/@clef.shape"/>
                </clef>
            </xsl:if>
            <xsl:if test="@label">
                <label type="supplied" xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:value-of select="@label"/>
                </label>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>If there are metaMarks with @place=rightmar, this will render them</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure[not(following::mei:measure)]" mode="finalFixes">
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
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
            <xd:p>The ID of the element that hhas information of what to focus, if wanted. Everything out of focus will be "blurred".</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="focus.id" as="xs:string"/>
    
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
                <xsl:apply-templates select="$first.measure/ancestor::mei:*[local-name() = ('score','part')]" mode="get.search.space">
                    <xsl:with-param name="measure.id" select="$first.measure/@xml:id" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:variable name="source.resolved" as="node()">
                <xsl:apply-templates select="$file.region" mode="get.source"/>
            </xsl:variable>
            <xsl:variable name="state.resolved" as="node()">
                <xsl:apply-templates select="$source.resolved" mode="get.state"/>
            </xsl:variable>
            <xsl:sequence select="$state.resolved"/>
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
            <scoreDef xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="meter.count" select="$meter.count"/>
                <xsl:attribute name="meter.unit" select="$meter.unit"/>
                <xsl:if test="$meter.sym">
                    <xsl:attribute name="meter.sym" select="$meter.sym"/>
                </xsl:if>
                <xsl:attribute name="key.sig" select="$general.key.sig"/>
                <staffGrp bar.thru="{if($is.score) then('true') else('false')}">
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
                                    <xsl:attribute name="label" select="$staff.label"/>
                                    <xsl:attribute name="clef.shape" select="$clef.shape"/>
                                    <xsl:attribute name="clef.line" select="$clef.line"/>
                                    <xsl:if test="exists($staff.key.sig)">
                                        <xsl:attribute name="key.sig" select="$staff.key.sig"/>
                                    </xsl:if>
                                    <xsl:if test="exists($trans.elem)">
                                        <xsl:attribute name="trans.semi" select="$trans.semi"/>
                                        <xsl:attribute name="trans.diat" select="$trans.diat"/>
                                    </xsl:if>
                                </staffDef>
                            </xsl:when>
                            <xsl:when test="$is.multi.staff">
                                <!-- when first in group, render full group (piano right hand takes everything…) -->
                                <xsl:variable name="initial.staffDef" select="($search.space//mei:staffDef[@n = $current.staff.n])[1]" as="node()"/>
                                <xsl:variable name="pos.in.group" select="count($initial.staffDef/preceding-sibling::mei:staffDef) + 1" as="xs:integer"/>
                                
                                <xsl:if test="$pos.in.group = 1">
                                    <xsl:variable name="following.staffDefs" select="$initial.staffDef/following-sibling::mei:staffDef[@n = $staves.n]" as="node()*"/>
                                    
                                    <xsl:choose>
                                        <!-- a staffGrp is necessary for the excerpt -->
                                        <xsl:when test="count($following.staffDefs) gt 0">
                                            <staffGrp>
                                                <xsl:apply-templates select="$initial.staffDef/parent::mei:staffGrp/@*"  mode="#unnamed"/>
                                                <xsl:apply-templates select="$initial.staffDef/parent::mei:staffGrp/mei:label" mode="#unnamed"/>
                                                
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
                                                        <xsl:if test="exists($staff.label)">
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
                                                    </staffDef>
                                                </xsl:for-each>
                                            </staffGrp>
                                        </xsl:when>
                                        <!-- just one staff of the staffGrp is required -->
                                        <xsl:otherwise>
                                            <xsl:variable name="staff.label" select="($search.space//mei:staffDef[@n = $current.staff.n]/@label | $search.space//mei:staffDef[@n = $current.staff.n]/mei:label/text())[1]" as="xs:string?"/>
                                            
                                            <xsl:variable name="clef.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@clef.shape and @clef.line] | $search.space//mei:staff[@n = $current.staff.n]//mei:clef)[last()]" as="node()"/>
                                            <xsl:variable name="clef.shape" select="$clef.elem/@clef.shape | $clef.elem/@shape" as="xs:string"/>
                                            <xsl:variable name="clef.line" select="$clef.elem/@clef.line | $clef.elem/@line" as="xs:string"/>
                                            
                                            <xsl:variable name="trans.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@trans.semi and @trans.diat])[last()]" as="node()?"/>
                                            <xsl:variable name="trans.semi" select="if($trans.elem) then($trans.elem/@trans.semi) else()" as="xs:string?"/>
                                            <xsl:variable name="trans.diat" select="if($trans.elem) then($trans.elem/@trans.diat) else()" as="xs:string?"/>
                                            
                                            
                                            <staffDef n="{$current.staff.n}" lines="5">
                                                <xsl:if test="exists($staff.label)">
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
                                            </staffDef>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    
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
                    <xsl:apply-templates select="$affected.measures" mode="get.selected.staves">
                        <xsl:with-param name="staves" select="$staves.n" tunnel="yes" as="xs:string*"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:variable name="source.resolved" as="node()*">
                    <xsl:apply-templates select="$region" mode="get.source"/>
                </xsl:variable>
                <xsl:variable name="state.resolved" as="node()*">
                    <xsl:apply-templates select="$source.resolved" mode="get.state"/>
                </xsl:variable>
                <xsl:sequence select="$state.resolved"/>
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
                                <xsl:apply-templates select="$current.range/mei:scoreDef/mei:staffGrp/node()" mode="offset.staves">
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
                                    <xsl:apply-templates select="$current.measure/mei:staff" mode="offset.staves">
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
                                    <xsl:apply-templates select="$current.measure/mei:*[not(local-name() = 'staff')]" mode="offset.staves">
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
        <xsl:apply-templates select="$excerpted.score" mode="condense.score">
            <xsl:with-param name="mappings" select="$mappings" tunnel="yes" as="node()+"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:variable name="context.highlighted" as="node()">
        <xsl:variable name="added.id" as="node()*">
            <xsl:apply-templates select="$condensed.score" mode="add.id"/>
        </xsl:variable>
        <xsl:variable name="added.tstamps" as="node()*">
            <xsl:apply-templates select="$added.id" mode="add.tstamps"/>
        </xsl:variable>
        
        <!-- get context and focus elements – those restrict what shall be shown -->
        <xsl:variable name="context.elem" select="id($context.id)" as="node()"/>
        <!-- retrieve timestamps for selecting snippets -->
        <xsl:variable name="context.tstamp" select="number($context.elem/@tstamp)" as="xs:double"/>
        <xsl:variable name="context.tstamp2" select="if(not(contains($context.elem/@tstamp2,'m+'))) then(number($context.elem/@tstamp2)) else(number(substring-after($context.elem/@tstamp2,'m+')))" as="xs:double"/>
        
        <!-- see if a focus is requested independent from the context (may only happen for rev lists) -->
        <xsl:variable name="focus.elem" select="if($focus.id ne '') then(id($focus.id)) else()" as="node()?"/>
        
        <xsl:variable name="highlighted.context" as="node()*">
            <xsl:choose>
                <xsl:when test="exists($focus.elem)">
                    <xsl:variable name="focus.tstamp" select="number($focus.elem/@tstamp)" as="xs:double"/>
                    <xsl:variable name="focus.tstamp2" select="if(not(contains($focus.elem/@tstamp2,'m+'))) then(number($focus.elem/@tstamp2)) else(number(substring-after($focus.elem/@tstamp2,'m+')))" as="xs:double"/>
                    <xsl:variable name="focus.first.measure.id" select="$focus.elem/ancestor::mei:measure/@xml:id" as="xs:string"/>
                    <xsl:variable name="focus.measures.after.first" select="
                        if(not(contains($focus.elem/@tstamp2,'m+'))) 
                        then(0) 
                        else(xs:integer(substring-before($focus.elem/@tstamp2,'m+')))" as="xs:integer"/>
                    <xsl:variable name="focus.last.measure.id" select="
                        if($focus.measures.after.first = 0) 
                        then($focus.first.measure.id) 
                        else($focus.elem/ancestor::mei:measure/following::mei:measure[$focus.measures.after.first]/@xml:id)" as="xs:string"/>
                    <xsl:variable name="focus.middle.measures.ids" select="
                        if($focus.measures.after.first gt 1)
                        then($added.tstamps//mei:measure[@xml:id = $focus.first.measure.id]/following::mei:measure[$focus.last.measure.id = following::mei:measure/@xml:id]/@xml:id)
                        else()" as="xs:string*"/>
                    <!-- aufteilen: 1. focus, letzter focus, mittlere focus -->
                    
                    
                    <xsl:apply-templates select="$added.tstamps" mode="highlight.context">
                        <xsl:with-param name="context.tstamp" select="$context.tstamp" tunnel="yes" as="xs:double"/>
                        <xsl:with-param name="context.tstamp2" select="$context.tstamp2" tunnel="yes" as="xs:double"/>
                        <xsl:with-param name="focus.tstamp" select="$focus.tstamp" tunnel="yes" as="xs:double"/>
                        <xsl:with-param name="focus.tstamp2" select="$focus.tstamp2" tunnel="yes" as="xs:double"/>
                        <xsl:with-param name="focus.first.measure.id" select="$focus.first.measure.id" tunnel="yes" as="xs:string"/>
                        <xsl:with-param name="focus.last.measure.id" select="$focus.last.measure.id" tunnel="yes" as="xs:string"/>
                        <xsl:with-param name="focus.middle.measures.ids" select="$focus.middle.measures.ids" tunnel="yes" as="xs:string*"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$added.tstamps" mode="highlight.context">
                        <xsl:with-param name="context.tstamp" select="$context.tstamp" tunnel="yes" as="xs:double"/>
                        <xsl:with-param name="context.tstamp2" select="$context.tstamp2" tunnel="yes" as="xs:double"/>                        
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:variable>
        
        <xsl:sequence select="$highlighted.context"/>
    </xsl:variable>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/" mode="#unnamed">
        <music xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:comment select="'context: ' || local-name($context) || ' '  || $context.id"/>
            <xsl:comment select="'focus: ' || $focus.id"/>
            <xsl:comment select="'state: ' || $state.id || ' (' || string-join($activated.states.ids,', ') || ')'"/>
            <xsl:comment select="'source: ' || $source.id"/>
            <body>
                <mdiv>
                    <xsl:comment select="'focus.id: ' || $focus.id"/>
                    <xsl:comment select="'context.id: ' || $context.id"/>
                    <xsl:sequence select="$context.highlighted"/>
                </mdiv>
            </body>
        </music>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template is used to delimit the search room for features relevant for a given music snippet</xd:p>
        </xd:desc>
        <xd:param name="measure.id"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure" mode="get.search.space">
        <xsl:param name="measure.id" tunnel="yes" as="xs:string"/>
        <xsl:if test="following::mei:measure[@xml:id = $measure.id]">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template is used to delimit the search room for features relevant for a given music snippet</xd:p>
        </xd:desc>
        <xd:param name="measure.id"></xd:param>
    </xd:doc>
    <xsl:template match="mei:section" mode="get.search.space">
        <xsl:param name="measure.id" tunnel="yes" as="xs:string"/>
        <xsl:if test="following::mei:measure[@xml:id = $measure.id] or descendant::mei:measure[@xml:id = $measure.id]">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template filters out staves which aren't required for the current range</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:staff" mode="get.selected.staves">
        <xsl:param name="staves" tunnel="yes" as="xs:string*"/>
        <xsl:if test="@n = $staves">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This template filters out control events on staves which aren't required for the current range</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure/mei:*[@staff]" mode="get.selected.staves">
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
    <xsl:template match="mei:measure/mei:*/@staff" mode="get.selected.staves">
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
    <xsl:template match="mei:measure/mei:*[not(local-name() = 'staff')][not(@staff)][@startid or @plist]" mode="get.selected.staves">
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
    <xsl:template match="mei:staff/@n | mei:staffDef/@n" mode="offset.staves">
        <xsl:param name="offset" tunnel="yes" as="xs:integer"/>
        <xsl:attribute name="n" select="xs:integer(normalize-space(.)) + $offset"/>
    </xsl:template>
        
    <xd:doc>
        <xd:desc>
            <xd:p>Spreads out staves</xd:p>
        </xd:desc>
        <xd:param name="offset"></xd:param>
    </xd:doc>
    <xsl:template match="@staff" mode="offset.staves">
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
    <xsl:template match="mei:staff/@n | mei:staffDef/@n" mode="condense.score">
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
    <xsl:template match="@staff" mode="condense.score">
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
    <xsl:template match="mei:app" mode="get.source">
        <xsl:apply-templates select="child::mei:*['#' || $source.id = tokenize(normalize-space(@source),' ')]/node()" mode="#current"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>resolves elements that apply to a given source only</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:*[@source]" mode="get.source">
        <xsl:if test="'#' || $source.id = tokenize(normalize-space(@source),' ')">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>drop source attribute – not needed anymore </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@source" mode="get.source"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>gets choices out of the way</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:choice[every $child in child::mei:* satisfies $child/@source]" mode="get.source">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>resolves states</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:*[@state]" mode="get.state">
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
    <xsl:template match="@facs" mode="#all"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Decides if a measure needs to be cut down to context / focus</xd:p>
        </xd:desc>
        <xd:param name="context.tstamp"></xd:param>
        <xd:param name="context.tstamp2"></xd:param>
        <xd:param name="focus.tstamp"></xd:param>
        <xd:param name="focus.tstamp2"></xd:param>
        <xd:param name="focus.measures.ids"></xd:param>
    </xd:doc>
    <xsl:template match="mei:measure" mode="highlight.context">
        <xsl:param name="context.tstamp" tunnel="yes" as="xs:double"/>
        <xsl:param name="context.tstamp2" tunnel="yes" as="xs:double"/>
        <xsl:param name="focus.tstamp" tunnel="yes" as="xs:double?"/>
        <xsl:param name="focus.tstamp2" tunnel="yes" as="xs:double?"/>
        <xsl:param name="focus.first.measure.id" tunnel="yes" as="xs:string?"/>
        <xsl:param name="focus.last.measure.id" tunnel="yes" as="xs:string?"/>
        <xsl:param name="focus.middle.measures.ids" tunnel="yes" as="xs:string*"/>
        
        <!--<xsl:comment>
            <xsl:value-of select="'$context.tstamp=' || $context.tstamp"/><xsl:text>
</xsl:text>
            <xsl:value-of select="'$context.tstamp2=' || $context.tstamp2"/><xsl:text>
</xsl:text>
            <xsl:value-of select="'$focus.tstamp=' || $focus.tstamp"/><xsl:text>
</xsl:text>
            <xsl:value-of select="'$focus.tstamp2=' || $focus.tstamp2"/><xsl:text>
</xsl:text>
            <xsl:value-of select="'$focus.first.measure.id=' || $focus.first.measure.id"/><xsl:text>
</xsl:text>
            <xsl:value-of select="'$focus.last.measure.id=' || $focus.last.measure.id"/><xsl:text>
</xsl:text>
            <xsl:value-of select="'$focus.middle.measures.ids=' || string-join($focus.middle.measures.ids,' ')"/>
        </xsl:comment>-->
        
        <xsl:choose>
            <xsl:when test="not(preceding::mei:measure) and not(following::mei:measure) and @xml:id = $focus.first.measure.id and @xml:id = $focus.last.measure.id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="true()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="not(preceding::mei:measure) and following::mei:measure and @xml:id = $focus.first.measure.id and @xml:id = $focus.last.measure.id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="not(preceding::mei:measure) and following::mei:measure and @xml:id = $focus.first.measure.id and not(@xml:id = $focus.last.measure.id)">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="not(preceding::mei:measure) and following::mei:measure and not(@xml:id = $focus.first.measure.id)">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="preceding::mei:measure and $focus.first.measure.id = following::mei:measure/@xml:id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="preceding::mei:measure and not(following::mei:measure) and @xml:id = $focus.first.measure.id and @xml:id = $focus.last.measure.id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="true()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="preceding::mei:measure and following::mei:measure and @xml:id = $focus.first.measure.id and @xml:id = $focus.last.measure.id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="preceding::mei:measure and following::mei:measure and @xml:id = $focus.first.measure.id and not(@xml:id = $focus.last.measure.id)">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="@xml:id = $focus.middle.measures.ids">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="not(following::mei:measure) and @xml:id = $focus.last.measure.id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="true()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="following::mei:measure and @xml:id = $focus.last.measure.id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="following::mei:measure and $focus.last.measure.id = preceding::mei:measure/@xml:id">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="not(following::mei:measure) and not(@xml:id = $focus.last.measure.id)">
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="true()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:when test="preceding::mei:measure and following::mei:measure and not($focus.first.measure.id) and not($focus.last.measure.id)">
                <!-- this is necessary when no focus-id is handed over -->
                <xsl:next-match>
                    <xsl:with-param name="context.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.complete" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.start" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.complete" select="true()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="focus.end" select="false()" tunnel="yes" as="xs:boolean"/>
                    <xsl:with-param name="context.end" select="false()" tunnel="yes" as="xs:boolean"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment select="'Problem!!!'"/>
                <!--<xsl:comment>HIER LIEGT DER HUND IM PFEFFER</xsl:comment>-->
                <xsl:copy-of select="."></xsl:copy-of>
                <!--<xsl:comment>UND HIER KOMMT ER WIEDER RAUS</xsl:comment>-->
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>resolve events for context highlighting</xd:p>
        </xd:desc>
        <xd:param name="context.start"></xd:param>
        <xd:param name="context.complete"></xd:param>
        <xd:param name="focus.start"></xd:param>
        <xd:param name="focus.complete"></xd:param>
        <xd:param name="focus.end"></xd:param>
        <xd:param name="context.end"></xd:param>
        <xd:param name="context.tstamp"></xd:param>
        <xd:param name="context.tstamp2"></xd:param>
        <xd:param name="focus.tstamp"></xd:param>
        <xd:param name="focus.tstamp2"></xd:param>
    </xd:doc>
    <xsl:template match="mei:staff//mei:*[@tstamp]" mode="highlight.context">
        <xsl:param name="context.start" tunnel="yes" as="xs:boolean"/>
        <xsl:param name="context.complete" tunnel="yes" as="xs:boolean"/>
        <xsl:param name="focus.start" tunnel="yes" as="xs:boolean?"/>
        <xsl:param name="focus.complete" tunnel="yes" as="xs:boolean?"/>
        <xsl:param name="focus.end" tunnel="yes" as="xs:boolean?"/>
        <xsl:param name="context.end" tunnel="yes" as="xs:boolean?"/>
        
        <xsl:param name="context.tstamp" tunnel="yes" as="xs:double"/>
        <xsl:param name="context.tstamp2" tunnel="yes" as="xs:double"/>
        <xsl:param name="focus.tstamp" tunnel="yes" as="xs:double?"/>
        <xsl:param name="focus.tstamp2" tunnel="yes" as="xs:double?"/>
        
        <xsl:variable name="tstamp" select="number(@tstamp)" as="xs:double"/>
        
        <xsl:variable name="existing.type" select="string(@type)" as="xs:string?"/>
        <xsl:variable name="new.type" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$focus.complete"/>
                <xsl:when test="$focus.start and $focus.end and $tstamp ge $focus.tstamp and $tstamp lt $focus.tstamp2"/>
                <xsl:when test="$focus.start and $tstamp ge $focus.tstamp"/>
                <xsl:when test="$focus.end and $tstamp lt $focus.tstamp2"/>
                <xsl:when test="$context.complete">out-focus</xsl:when>
                <xsl:when test="not($context.start) and $focus.start and $tstamp lt $focus.tstamp">out-focus</xsl:when>
                <xsl:when test="$context.start and $focus.start and $tstamp ge $context.tstamp and $tstamp lt $focus.tstamp">out-focus</xsl:when>
                <xsl:when test="$context.start and not($focus.start) and $tstamp ge $context.tstamp">out-focus</xsl:when>
                <xsl:when test="not($context.end) and $focus.end and $tstamp gt $focus.tstamp2">out-focus</xsl:when>
                <xsl:when test="$context.end and $focus.end and $tstamp ge $focus.tstamp2 and $tstamp lt $context.tstamp2">out-focus</xsl:when>
                <xsl:when test="$context.end and not($focus.end) and $tstamp lt $context.tstamp2">out-focus</xsl:when>
                <xsl:when test="$context.start and $tstamp lt $context.tstamp">out-context</xsl:when>
                <xsl:when test="$context.end and $tstamp gt $context.tstamp2">out-context</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="type" select="normalize-space(string-join(($existing.type, $new.type), ' '))" as="xs:string?"/>
        <xsl:copy>
            <xsl:apply-templates select="@* except @type" mode="#current"/>
            <xsl:if test="$type">
                <xsl:attribute name="type" select="$type"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
        
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
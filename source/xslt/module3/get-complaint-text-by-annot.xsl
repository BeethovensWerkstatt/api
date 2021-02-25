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
    
    <xd:doc>
        <xd:desc>
            <xd:p>The IDs of the annots, as passed to the XQuery, i.e. separated by commata</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="annot.ids.joined" as="xs:string"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>The  IDs of the relevant annots</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="annot.ids" select="tokenize($annot.ids.joined,',')" as="xs:string*"/>
    <xd:doc>
        <xd:desc>
            <xd:p>The annot elements which delimit the content that is to be retrieved</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="annots" select="for $annot.id in $annot.ids  return /id($annot.id)" as="node()*"/>
    <!--<xsl:variable name="start.measures" select="for $annot in $annots return ancestor::mei:measure" as="node()*"/>-->
    
    <!-- extract a single excerpt for each annotation, irrespective of other annots (if any) -->
    <xsl:variable name="ranges" as="node()*">
        <xsl:for-each select="$annots">
            <xsl:variable name="annot" select="." as="node()"/>
            <xsl:variable name="first.measure" select="ancestor::mei:measure" as="node()"/>
            <xsl:variable name="tstamp" select="number($annot/@tstamp)" as="xs:double"/>
            <xsl:variable name="end.tstamp" select="if(not(contains($annot/@tstamp2,'m+'))) then(number($annot/@tstamp2)) else(number(substring-after($annot/@tstamp2,'m+')))" as="xs:double"/>
            <xsl:variable name="subsequent.measures" select="if(starts-with($annot/@tstamp2,'0m+') or not(contains($annot/@tstamp2,'m+'))) then() else($first.measure/following::measure[position() le xs:integer(substring-before($annot/@tstamp2,'m+'))])" as="node()*"/>
            <xsl:variable name="affected.measures" select="$first.measure | $subsequent.measures" as="node()+"/>
            <xsl:variable name="staves.n" select="if($annot/@staff) then(tokenize(normalize-space($annot/@sstaff),' ')) else(distinct-values($first.measure/mei:staff/@n))" as="xs:string*"/>
            
            <!-- delimit the area in which relevant features can be found -->
            <xsl:variable name="search.space" as="node()">
                <xsl:apply-templates select="$first.measure/ancestor::mei:mdiv[1]" mode="get.search.space">
                    <xsl:with-param name="measure.id" select="$first.measure/@xml:id" tunnel="yes"/>
                </xsl:apply-templates>
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
                                    
                                    <xsl:variable name="staff.label" select="($search.space//mei:staffDef[@n = $current.staff.n]/@label | $search.space//mei:staffDef[@n = $current.staff.n]/mei:label/text())[1]" as="xs:string"/>
                                    
                                    <xsl:variable name="clef.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@clef.shape and @clef.line] | $search.space//mei:staff[@n = $current.staff.n]//mei:clef)[last()]" as="node()"/>
                                    <xsl:variable name="clef.shape" select="$clef.elem/@clef.shape | $clef.elem/@shape" as="xs:string"/>
                                    <xsl:variable name="clef.line" select="$clef.elem/@clef.line | $clef.elem/@line" as="xs:string"/>
                                    
                                    <xsl:variable name="trans.elem" select="($search.space//mei:staffDef[@n = $current.staff.n][@trans.semi and @trans.diat])[last()]" as="node()?"/>
                                    <xsl:variable name="trans.semi" select="if($trans.elem) then($trans.elem/@trans.semi) else()" as="xs:string?"/>
                                    <xsl:variable name="trans.diat" select="if($trans.elem) then($trans.elem/@trans.diat) else()" as="xs:string?"/>
                                    
                                    
                                    <staffDef n="{$current.staff.n}">
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
                                                        
                                                        
                                                        <staffDef n="{$current.staff.n.in.group}">
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
                                                
                                                
                                                <staffDef n="{$current.staff.n}">
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
                    <xsl:apply-templates select="$affected.measures" mode="get.selected.staves">
                        <xsl:with-param name="staves" select="$staves.n" tunnel="yes" as="xs:string*"/>
                    </xsl:apply-templates>
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
        </xsl:for-each>
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
                    <xsl:comment>TODO: Unable to correctly align  multiple ranges. Using only the first range.</xsl:comment>
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
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/" mode="#unnamed">
        <music xmlns="http://www.music-encoding.org/ns/mei">
            <body>
                <mdiv>
                    <xsl:sequence select="$condensed.score"/>
                </mdiv>
            </body>
        </music>
        <xsl:apply-templates select="node()"/>
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
            <xd:p>This template filters out staves which aren't required for the current range</xd:p>
        </xd:desc>
        <xd:param name="staves"></xd:param>
    </xd:doc>
    <xsl:template match="mei:staff" mode="get.selected.staves">
        <xsl:param  name="staves" tunnel="yes" as="xs:string*"/>
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
        <xsl:param  name="staves" tunnel="yes" as="xs:string*"/>
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
            <xd:p>A simple, mode-sensitive copy-template</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>
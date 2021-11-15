<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Sep 12, 2016</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output indent="no" method="html"/>
    <xsl:param name="purpose" as="xs:string"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$purpose = 'getIntroduction'">
                <div class="workIntroduction">
                    <xsl:for-each select="//mei:annot[@type = 'introduction']">
                        <xsl:sort select="@n" data-type="number"/>
                        <xsl:apply-templates select="."/>
                    </xsl:for-each>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div>
                    <xsl:apply-templates/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:annot">
        <div>
            <xsl:apply-templates select="node()"/>
        </div>
    </xsl:template>
    <xsl:template match="mei:annot/mei:title">
        <h2>
            <xsl:apply-templates select="node()"/>
        </h2>
    </xsl:template>
    <xsl:template match="mei:p">
        <p>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>
    <xsl:template match="mei:ref">
        <xsl:choose>
            <xsl:when test="@target and starts-with(@target,'http://')">
                <a href="{@target}" target="_blank" class="externalLink">
                    <xsl:apply-templates select="node()"/>
                </a>
            </xsl:when>
            <xsl:when test="@target and starts-with(@target,'#')">
                <span class="internalLink" data-target="{@target}">
                    <xsl:apply-templates select="node()"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="brokenLink">
                    <xsl:apply-templates select="node()"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:persName">
        <xsl:choose>
            <xsl:when test="@authURI and @dbkey">
                <span class="persName">
                    <a href="{@authURI}{@dbkey}" target="_blank">
                        <xsl:apply-templates select="node()"/>
                    </a>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="persName">
                    <xsl:apply-templates select="node()"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:fig">
        <xsl:choose>
            <xsl:when test="mei:avFile">
                <div class="videoContainer">
                    <div id="{./mei:avFile/@xml:id}" class="video" data-videourl="{./mei:avFile/@target}">
                        <div class="spacer">no content</div>
                    </div>
                    <xsl:if test="./mei:caption">
                        <label class="videoLabel">
                            <xsl:apply-templates select="./mei:caption/node()"/>
                        </label>
                    </xsl:if>
                </div>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- dealing with tables -->
    <xsl:template match="mei:table">
        <table>
            <xsl:apply-templates select="node()"/>
        </table>
    </xsl:template>
    <xsl:template match="mei:tr">
        <tr>
            <xsl:apply-templates select="node()"/>
        </tr>
    </xsl:template>
    <xsl:template match="mei:th">
        <th>
            <xsl:apply-templates select="node()"/>
        </th>
    </xsl:template>
    <xsl:template match="mei:td">
        <td>
            <xsl:apply-templates select="node()"/>
        </td>
    </xsl:template>
    <!-- 
    
    
    <div class="videoContainer">
            <div id="video1" class="video" data-videoURL="http://localhost:32107/resources/demoVideo.mp4"><div class="spacer">no content</div></div>
            <label class="video">Video Caption: This video illustrates this and that…</label>            
        </div>
    
    
    -->
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs dtb" version="2.0"
    xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns="http://www.daisy.org/z3986/2005/dtbook/">

  <xsl:output indent="yes"/>

  <xsl:param name="contraction-grade" select="'0'"/>
  <xsl:param name="volumes" select="1" as="xs:integer"/>

  <xsl:template match="dtb:frontmatter/dtb:docauthor">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:call-template name="add-information-based-from-metadata"/>
  </xsl:template>

  <xsl:template match="node()" mode="#all" priority="-5">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="add-information-based-from-metadata">
    <level1 class="first-page" style="text-align: center; page-break-inside:avoid ; ">

      <!-- Authors -->
      <xsl:variable name="author" select="//meta[@name = 'dc:Creator']/@content"/>
      <xsl:for-each select="$author[position() &lt;= 3]">
        <xsl:choose>
          <xsl:when test="position() = 1">
            <p class="author" style="display: block;  margin-top: 4; ">
              <xsl:value-of select="."/>
            </p>
          </xsl:when>
          <xsl:otherwise>
            <p class="author" style="display: block;">
              <xsl:value-of select="."/>
            </p>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

      <!-- Title -->
      <p class="title" style="display: block; margin-top: 1;">
        <xsl:value-of select="//meta[@name = 'dc:Title']/@content"/>
      </p>

      <!-- Volumes -->
      <xsl:variable name="volumes-count"
		    select="if ($volumes lt 13) then
			    ('einem','zwei','drei','vier','fünf','sechs','sieben','acht','neun','zehn','elf','zwölf')[$volumes]
			    else string($volumes)"/>
      <xsl:variable name="volume-name"
		    select="if ($volumes lt 13) then
			    ('Erster','Zweiter','Dritter','Vierter','Fünfter','Sechster','Siebter','Achter','Neunter','Zehnter','Elfter','Zwölfter')[$volumes]
			    else string($volumes)"/>
      <p style="display: block; margin-top: 4;">
	<xsl:value-of select="concat('In ', $volumes-count, ' ', if
			      ($volumes eq 1) then 'Brailleband' else
			      'Braillebänden')"/>
      </p>
      
      <p style="display: block; margin-top: 4;">
	<!-- FIXME: if there are more than 12 volumes we want just the -->
	<!-- number but downshifted as with ordinals -->
	<xsl:value-of select="concat(if ($volumes lt 13) then $volume-name else string($volumes), ' Band')"/>
      </p>
      
      <!-- Publisher -->
      <p style="display: block;">SBS Schweiz. Bibliothek Für Blinde, Seh- und Lesebehinderte</p>
    </level1>
    <level1 class="second-page">
      <p>Dieses Braillebuch ist die ausschliesslich für die Nutzung
      durch Seh- und Lesebehinderte Menschen bestimmte zugängliche
      Version eines urheberrechtlich geschützten Werks. Sie können es
      im Rahmen des Urheberrechts persönlich nutzen, dürfen es aber
      nicht weiter verbreiten oder öffentlich zugänglich machen</p>

      <p>Verlag, Satz und Druck<br/>
      SBS Schweiz. Bibliothek für Blinde, Seh- und Lesebehinderte, Zürich<br/>
      www.sbs.ch</p>

      <p class="year" style="display: block; margin-bottom: 2;">
	<xsl:value-of select="concat('SBS ', format-dateTime(current-dateTime(), '[Y]'))"/>
      </p>
      <p>SBS</p>
   </level1>
   <level1 class="third-page">
     <xsl:apply-templates select="//level1[@class='titlepage']/*"/>
   </level1>
   <level1 class="fourth-page">
     <xsl:apply-templates select="//level1[not(@class='titlepage' or @class='toc')]/*"/>
   </level1>
  </xsl:template>

</xsl:stylesheet>

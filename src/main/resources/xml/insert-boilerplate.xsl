<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns="http://www.daisy.org/z3986/2005/dtbook/">

  <xsl:output indent="yes"/>

  <xsl:param name="contraction-grade" select="'0'"/>
  <xsl:param name="volumes" select="1" as="xs:integer"/>

  <xsl:template match="frontmatter/docauthor">
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
    <level1 id="cover-recto" style="text-align: center; page-break-inside:avoid ; ">

      <!-- Authors -->
      <p class="author" style="display: block;  margin-top: 4; ">
        <xsl:value-of select="//docauthor"/>
      </p>

      <!-- Title -->
      <p class="title" style="display: block; margin-top: 1; border-bottom: ⠤; ">
        <xsl:value-of select="//doctitle"/>
      </p>

      <!-- Volumes -->
      <p class="how-many-volumes" style="display: block; margin-top: 4;">In <span style="text-transform:volume; "/> Braillebänden</p>

      <!-- <frees> 1. (if (> $volumes 1) "Volume " "In one volume") -->
      <!-- <frees> 2. (if (> $volumes 1) $volume) => put style "text-transform:volume" on this part -->
      <!-- <frees> 3. (if (> $volumes 1) " of ") -->
      <!-- <frees> 4. (if (> $volumes 1) $volumes) => put style "text-transform:volumes" on this part -->
      
      <p class="which-volume" style="display: block; margin-top: 4;">
	<!-- FIXME: if there are more than 12 volumes we want just the -->
	<!-- number but downshifted as with ordinals -->
	<span style="text-transform:volumes; "/> Band
      </p>
      
      <!-- Publisher -->
      <p style="display: block;">SBS Schweiz. Bibliothek Für Blinde, Seh- und Lesebehinderte</p>
    </level1>
    <level1 class="cover-verso">
      <p id="copyright-blurb">Dieses Braillebuch ist die ausschliesslich für die Nutzung
      durch Seh- und Lesebehinderte Menschen bestimmte zugängliche
      Version eines urheberrechtlich geschützten Werks. Sie können es
      im Rahmen des Urheberrechts persönlich nutzen, dürfen es aber
      nicht weiter verbreiten oder öffentlich zugänglich machen</p>

      <p id="publisher-blurb">Verlag, Satz und Druck<br/>
      SBS Schweiz. Bibliothek für Blinde, Seh- und Lesebehinderte, Zürich<br/>
      www.sbs.ch</p>

      <xsl:variable name="date" select="//meta[@name = 'dc:Date']/@content"/>
      <p id="cover-year" style="display: block; margin-bottom: 2;">SBS <xsl:value-of select="format-date($date, '[Y]')"/>
      </p>
   </level1>
  </xsl:template>

</xsl:stylesheet>

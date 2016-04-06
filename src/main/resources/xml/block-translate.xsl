<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:html="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/transform/block-translator-template.xsl"/>
	<xsl:import href="functions.xsl"/>
	<xsl:import href="select-braille-table.xsl"/>
	
	<xsl:param name="contraction-grade" required="yes"/>
	<xsl:param name="use_local_dictionary" required="yes"/>
	<xsl:param name="document-identifier" required="yes"/>
	<xsl:param name="hyphenation" required="yes"/>
	<xsl:param name="accented-letters" required="yes"/>
	<xsl:param name="enable_capitalization" required="yes"/>

	<xsl:param name="text-transform" required="yes"/>

	<xsl:param name="TABLE_BASE_URI" select="''"/>
	
	<xsl:template match="css:block" mode="#default before after">
		<xsl:variable name="text" as="text()*" select="//text()"/>
		<xsl:variable name="style" as="xs:string*">
			<xsl:for-each select="$text">
				<xsl:variable name="inline-style" as="element()*"
				              select="css:computed-properties($inline-properties, true(), parent::*)"/>
				<xsl:variable name="transform" as="xs:string?"
				              select="if (ancestor::html:strong) then 'louis-bold' else
				                      if (ancestor::html:em) then 'louis-ital' else ()"/>
				<xsl:variable name="inline-style" as="element()*"
				              select="if ($transform) then ($inline-style,css:property('transform',$transform)) else $inline-style"/>
				<xsl:sequence select="css:serialize-declaration-list($inline-style[not(@value=css:initial-value(@name))])"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:apply-templates select="node()">
		  <xsl:with-param name="new-text-nodes"
				  select="pf:text-transform($text-transform,$text,$style)"/>
		  <!-- (table:table-path, i.e tables+hyphenator) -->
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="css:property[@name=('font-style','font-weight','text-decoration','color')]"
	              mode="translate-declaration-list"/>
	
	<xsl:template match="css:property[@name='hyphens' and @value='auto']" mode="translate-declaration-list">
		<xsl:sequence select="css:property('hyphens','manual')"/>
	</xsl:template>
	
</xsl:stylesheet>

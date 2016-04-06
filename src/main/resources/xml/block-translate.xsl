<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:my="http://my-functions"
                exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/transform/block-translator-template.xsl"/>
	<xsl:import href="functions.xsl"/>
	<xsl:import href="select-braille-table.xsl"/>
	<xsl:import href="handle-elements.xsl"/>
	
	<xsl:param name="virtual.dis-uri" select="resolve-uri('../liblouis/virtual.dis')"/> <!-- must be file URI -->
	<xsl:param name="hyphenator" required="yes"/>
	
	<xsl:variable name="TABLE_BASE_URI"
	              select="concat($virtual.dis-uri,',http://www.sbs.ch/pipeline/liblouis/tables/')"/>
	
	<xsl:template match="css:block" mode="#default before after">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:function name="my:louis-translate" as="xs:string">
		<xsl:param name="context" as="node()"/>
		<xsl:param name="table" as="xs:string"/>
		<xsl:param name="text" as="xs:string"/>
		<xsl:sequence select="pf:text-transform(
		                        concat('(liblouis-table:&quot;',$table,'&quot;)',$hyphenator),
		                        $text,
		                        my:get-style($context))"/>
	</xsl:function>
	
	<xsl:function name="my:get-style" as="xs:string">
		<xsl:param name="context" as="node()"/>
		<xsl:variable name="inline-style" as="element()*"
		              select="css:computed-properties($inline-properties, true(),
		                        if ($context/self::*) then $context else $context/parent::*)"/>
		<xsl:variable name="inline-style" as="element()*">
			<xsl:apply-templates select="$inline-style" mode="property"/>
		</xsl:variable>
		<xsl:sequence select="css:serialize-declaration-list($inline-style)"/>
	</xsl:function>
	
	<xsl:template match="css:property" mode="property">
		<xsl:if test="not(@value=css:initial-value(@name))">
			<xsl:sequence select="."/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="css:property[@name='word-spacing']" mode="property"/>
	
	<xsl:template match="@style">
		<xsl:variable name="translated-rules" as="element()*">
			<xsl:apply-templates select="css:parse-stylesheet(.)" mode="translate-rule-list">
				<xsl:with-param name="context" select="parent::*" tunnel="yes"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:sequence select="css:style-attribute(css:serialize-stylesheet($translated-rules))"/>
	</xsl:template>
	
	<xsl:template mode="translate-declaration-list"
	              match="css:property[@name='hyphens' and @value='auto']">
		<xsl:sequence select="css:property('hyphens','manual')"/>
	</xsl:template>
	
	<xsl:template mode="translate-declaration-list"
	              match="css:property[@name=('letter-spacing',
	                                         'font-style',
	                                         'font-weight',
	                                         'text-decoration',
	                                         'color')]"/>
	
</xsl:stylesheet>

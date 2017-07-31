<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline type="pxi:block-translate" version="1.0"
            xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
            xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
            exclude-inline-prefixes="#all">

	<p:option name="contraction-grade" required="true"/>
	<p:option name="text-transform-query-base" required="true"/>

	<p:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/library.xpl"/>

	<css:parse-properties properties="display text-transform"/>
	
	<!-- ================== -->
	<!-- HANDLE DOWNGRADING -->
	<!-- ================== -->

	<p:xslt>
          <p:input port="stylesheet">
            <p:document href="handle-downgrading.xsl"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
	</p:xslt>

	<!-- =============== -->
	<!-- HANDLE PRODNOTE -->
	<!-- =============== -->

	<p:xslt>
          <p:input port="stylesheet">
            <p:document href="handle-prodnote.xsl"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
	</p:xslt>

	<!-- ========= -->
	<!-- TRANSLATE -->
	<!-- ========= -->

	<p:xslt initial-mode="identify-blocks">
		<p:input port="stylesheet">
			<p:document href="block-translate.xsl"/>
		</p:input>
		<p:with-param name="contraction-grade" select="$contraction-grade"/>
		<p:with-param name="text-transform-query-base" select="$text-transform-query-base"/>
		<p:with-param name="hyphenation" select="'true'"/>
	</p:xslt>
	
</p:pipeline>

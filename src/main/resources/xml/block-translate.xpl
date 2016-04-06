<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline type="pxi:block-translate" version="1.0"
            xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
            exclude-inline-prefixes="#all">
	
	<p:option name="text-transform" required="true"/>
        <p:option name="contraction-grade" required="true"/>
	
        <p:xslt>
                <p:input port="stylesheet">
                        <p:document href="insert-boilerplate.xsl"/>
                </p:input>
                <p:with-param name="contraction-grade" select="$contraction-grade"/>
        </p:xslt>

	<p:xslt>
		<p:input port="stylesheet">
			<p:document href="block-translate.xsl"/>
		</p:input>
		<p:with-param name="text-transform" select="$text-transform"/>
	</p:xslt>
	
</p:pipeline>

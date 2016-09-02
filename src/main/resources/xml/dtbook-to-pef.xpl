<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="sbs:dtbook-to-pef" version="1.0"
                xmlns:sbs="http://www.sbs.ch"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pef="http://www.daisy.org/ns/2008/pef"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                exclude-inline-prefixes="#all"
                name="main">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">DTBook to PEF (SBS)</h1>
        <p px:role="desc">Transforms a DTBook (DAISY 3 XML) document into a PEF.</p>
    </p:documentation>

    <p:input port="source"/>
    <p:option name="pef-output-dir"/>
    <p:option name="brf-output-dir"/>
    <p:option name="preview-output-dir"/>
    <p:option name="temp-dir"/>

    <p:option name="stylesheet" select="'http://www.sbs.ch/pipeline/modules/braille/default.scss'"/>

    <p:option name="contraction-grade" required="false" select="'2'">
      <p:pipeinfo>
        <px:data-type>
          <choice>
            <documentation xmlns="http://relaxng.org/ns/compatibility/annotations/1.0" xml:lang="de">
              <value>Basisschrift</value>
              <value>Vollschrift</value>
              <value>Kurzschrift</value>
            </documentation>
            <value>0</value>
            <value>1</value>
            <value>2</value>
          </choice>
        </px:data-type>
      </p:pipeinfo>
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h2 px:role="name">Translation/formatting of text: Contraction grade</h2>
        <p px:role="desc">`Basisschrift` (uncontracted), `Vollschrift` (partly contracted) or `Kurzschrift` (fully contracted)</p>
      </p:documentation>
    </p:option>

    <p:option name="ascii-table" select="'(liblouis-table:&quot;http://www.sbs.ch/pipeline/liblouis/tables/sbs.dis&quot;)'"/>
    <p:option name="include-preview" select="'true'"/>
    <p:option name="include-brf" select="'true'"/>
    <p:option name="page-width" select="'28'"/>
    <p:option name="page-height" select="'28'"/>
    <p:option name="duplex" select="'true'"/>
    <p:option name="levels-in-footer" select="'0'"/>
    <p:option name="hyphenation" select="'false'"/>
    <p:option name="line-spacing" select="'single'"/>
    <p:option name="enable-capitalization" px:type="boolean" select="'false'">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h2 px:role="name">Translation/formatting of text: Capital letters</h2>
        <p px:role="desc" xml:space="preserve">When enabled, will indicate capital letters.</p>
      </p:documentation>
    </p:option>
    <p:option name="accented-letters" select="'de-accents-ch'">
      <p:pipeinfo>
        <px:data-type>
          <choice>
            <documentation xmlns="http://relaxng.org/ns/compatibility/annotations/1.0" xml:lang="en">
              <value>All Accents Detailed</value>
              <value>All Accents Reduced</value>
              <value>Only Swiss Accents Detailed</value>
            </documentation>
            <value>de-accents</value>
            <value>de-accents-reduced</value>
            <value>de-accents-ch</value>
          </choice>
        </px:data-type>
      </p:pipeinfo>
    </p:option>
    <p:option name="polite-forms" select="'true'"/>
    <p:option name="downshift-ordinal-numbers" select="'true'"/>
    <p:option name="include-production-notes" select="'true'"/>
    <p:option name="show-braille-page-numbers" select="'true'"/>
    <p:option name="show-print-page-numbers" select="'true'"/>
    <p:option name="toc-depth" select="'0'"/>
    <p:option name="footnotes-placement" select="'standard'">
      <p:pipeinfo>
        <px:data-type>
          <choice>
            <documentation xmlns="http://relaxng.org/ns/compatibility/annotations/1.0" xml:lang="en">
              <value>Standard</value>
              <value>At end of volume</value>
              <value>At end of level1</value>
              <value>At end of level2</value>
              <value>At end of level3</value>
              <value>At end of level4</value>
           </documentation>
            <value>standard</value>
            <value>end_vol</value>
            <value>level1</value>
            <value>level2</value>
            <value>level3</value>
            <value>level4</value>
          </choice>
        </px:data-type>
      </p:pipeinfo>
    </p:option>
    <p:option name="document-identifier"/>

    <p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/xml-to-pef/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl"/>
    
    <p:in-scope-names name="in-scope-names"/>
    <px:merge-parameters>
        <p:input port="source">
            <p:pipe port="result" step="in-scope-names"/>
        </p:input>
    </px:merge-parameters>
    <px:delete-parameters parameter-names="stylesheet
                                           ascii-table
                                           include-brf
                                           include-preview
                                           pef-output-dir
                                           brf-output-dir
                                           preview-output-dir
                                           temp-dir"/>
    <px:add-parameters>
        <p:with-param name="skip-margin-top-of-page" select="'true'"/>
        <p:with-param name="enable-capitalization" select="'true'"/>
    </px:add-parameters>
    <p:identity name="input-options"/>
    <p:sink/>
    
    <!-- =============== -->
    <!-- CREATE TEMP DIR -->
    <!-- =============== -->
    <px:tempdir name="temp-dir">
        <p:with-option name="href" select="if ($temp-dir!='') then $temp-dir else $pef-output-dir"/>
    </px:tempdir>
    <p:sink/>
    
    <!-- ============= -->
    <!-- DTBOOK TO PEF -->
    <!-- ============= -->
    <px:dtbook-to-pef.convert default-stylesheet="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/css/default.css">
        <p:input port="source">
            <p:pipe step="main" port="source"/>
        </p:input>
        <p:with-option name="temp-dir" select="string(/c:result)">
            <p:pipe step="temp-dir" port="result"/>
        </p:with-option>
        <p:with-option name="stylesheet" select="string-join((
                                                 'http://www.sbs.ch/pipeline/modules/braille/internal/handle-precedingseparator.xsl',
						 'http://www.sbs.ch/pipeline/modules/braille/internal/insert-boilerplate.xsl',
                                                 $stylesheet),' ')"/>
        <p:with-option name="transform" select="concat('(formatter:dotify)(translator:sbs)(grade:',$contraction-grade,')')"/>
        <p:input port="parameters">
            <p:pipe port="result" step="input-options"/>
        </p:input>
    </px:dtbook-to-pef.convert>
    
    <!-- ========= -->
    <!-- STORE PEF -->
    <!-- ========= -->
    <px:xml-to-pef.store>
        <p:input port="obfl">
            <p:empty/>
        </p:input>
        <p:with-option name="name" select="replace(p:base-uri(/),'^.*/([^/]*)\.[^/\.]*$','$1')">
            <p:pipe step="main" port="source"/>
        </p:with-option>
        <p:with-option name="include-brf" select="$include-brf"/>
        <p:with-option name="include-preview" select="$include-preview"/>
        <p:with-option name="ascii-table" select="$ascii-table"/>
        <p:with-option name="pef-output-dir" select="$pef-output-dir"/>
        <p:with-option name="brf-output-dir" select="$brf-output-dir"/>
        <p:with-option name="preview-output-dir" select="$preview-output-dir"/>
    </px:xml-to-pef.store>
    
</p:declare-step>


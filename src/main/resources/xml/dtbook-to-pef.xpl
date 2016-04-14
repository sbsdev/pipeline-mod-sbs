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

    <p:option name="contraction-grade" required="false" select="'0'">
      <p:pipeinfo>
        <px:data-type>
          <choice>
            <documentation xmlns="http://relaxng.org/ns/compatibility/annotations/1.0" xml:lang="de">
              <value>Vollschrift</value>
              <value>Basisschrift</value>
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
        <p px:role="desc">`Vollschrift` (uncontracted), `Basisschrift` (partly contracted) or `Kurzschrift` (fully contracted)</p>
      </p:documentation>
    </p:option>

    <p:option name="ascii-table" select="'(liblouis-table:&quot;http://www.sbs.ch/pipeline/liblouis/tables/sbs.dis&quot;)'"/>
    <p:option name="include-preview"/>
    <p:option name="include-brf"/>

    <p:option name="page-width" select="'28'"/>
    <p:option name="page-height" select="'28'"/>
    <p:option name="left-margin"/>
    <p:option name="duplex"/>
    <p:option name="levels-in-footer"/>
    <p:option name="main-document-language"/>
    <p:option name="hyphenation"/>
    <p:option name="line-spacing"/>
    <p:option name="tab-width"/>
    <p:option name="capital-letters"/>
    <p:option name="accented-letters"/>
    <p:option name="polite-forms"/>
    <p:option name="downshift-ordinal-numbers"/>
    <p:option name="include-captions"/>
    <p:option name="include-images"/>
    <p:option name="include-image-groups"/>
    <p:option name="include-line-groups"/>
    <p:option name="text-level-formatting"/>
    <p:option name="include-note-references"/>
    <p:option name="include-production-notes"/>
    <p:option name="show-braille-page-numbers"/>
    <p:option name="show-print-page-numbers"/>
    <p:option name="force-braille-page-break"/>
    <p:option name="toc-depth"/>
    <p:option name="ignore-document-title"/>
    <p:option name="include-symbols-list"/>
    <p:option name="choice-of-colophon"/>
    <p:option name="footnotes-placement"/>
    <p:option name="colophon-metadata-placement"/>
    <p:option name="rear-cover-placement"/>
    <p:option name="number-of-sheets"/>
    <p:option name="maximum-number-of-sheets"/>
    <p:option name="minimum-number-of-sheets"/>
    <p:option name="document-identifier"/>

    <p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl"/>
    
    <p:in-scope-names name="in-scope-names"/>
    <p:identity>
        <p:input port="source">
            <p:pipe port="result" step="in-scope-names"/>
        </p:input>
    </p:identity>
    <p:delete match="c:param[@name=('stylesheet',
                                    'contraction-grade',
                                    'ascii-table',
                                    'include-brf',
                                    'include-preview',
                                    'pef-output-dir',
                                    'brf-output-dir',
                                    'preview-output-dir',
                                    'temp-dir')]"/>
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
        <p:with-option name="stylesheet" select="$stylesheet"/>
        <p:with-option name="transform" select="concat('(formatter:dotify)(translator:sbs)(grade:',$contraction-grade,')')"/>
        <p:input port="parameters">
            <p:pipe port="result" step="input-options"/>
        </p:input>
    </px:dtbook-to-pef.convert>
    
    <!-- ========= -->
    <!-- STORE PEF -->
    <!-- ========= -->
    <p:group>
        <p:variable name="name" select="replace(p:base-uri(/),'^.*/([^/]*)\.[^/\.]*$','$1')">
            <p:pipe step="main" port="source"/>
        </p:variable>
        <pef:store>
            <p:with-option name="href" select="concat($pef-output-dir,'/',$name,'.pef')"/>
            <p:with-option name="preview-href" select="if ($include-preview='true' and $preview-output-dir!='')
                                                       then concat($preview-output-dir,'/',$name,'.pef.html')
                                                       else ''"/>
            <p:with-option name="brf-href" select="if ($include-brf='true' and $brf-output-dir!='')
                                                   then concat($brf-output-dir,'/',$name,'.brf')
                                                   else ''"/>
            <p:with-option name="brf-table" select="if ($ascii-table!='') then $ascii-table
                                                    else concat('(locale:',(/*/@xml:lang,'und')[1],')')"/>
        </pef:store>
    </p:group>
    
</p:declare-step>


<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns:brl="http://www.daisy.org/z3986/2009/braille/"
    xmlns:my="http://my-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
    exclude-result-prefixes="dtb pf my" extension-element-prefixes="my">

  <xsl:param name="contraction">2</xsl:param>
  <xsl:param name="hyphenation" select="'false'"/>
  <xsl:param name="show_v_forms" select="true()"/>
  <xsl:param name="downshift_ordinals" select="true()"/>
  <xsl:param name="enable_capitalization" select="false()"/>
  <xsl:param name="accented-letters">de-accents-ch</xsl:param>
  <xsl:param name="use_local_dictionary" select="false()"/>
  <xsl:param name="document-identifier"></xsl:param>
  <xsl:param name="ascii_encoding" select="false()"></xsl:param>

  <xsl:variable name="GROSS_FUER_BUCHSTABENFOLGE">╦</xsl:variable>
  <xsl:variable name="GROSS_FUER_EINZELBUCHSTABE">╤</xsl:variable>
  <xsl:variable name="KLEINBUCHSTABE">╩</xsl:variable>
  
  <!-- Tables for computer braille -->
  <xsl:variable name="computer_braille_tables" select="'sbs.dis,sbs-special.cti,sbs-code.cti'"/>

  <!-- ======================= -->
  <!-- Main translate function -->
  <!-- ======================= -->

  <!--
      Implement the function my:louis-translate with the following signature
  -->
  <!--
  <xsl:function name="my:louis-translate" as="xs:string">
    <xsl:param name="context" as="node()"/>
    <xsl:param name="table" as="xs:string"/>
    <xsl:param name="text" as="xs:string"/>
    ...
  </xsl:function>
  -->
  
  <!--
      Use the following to produce ASCII braille (SBSForm, no CSS support)
  -->
  <!--
  <xsl:function name="my:louis-translate" as="xs:string">
    <xsl:param name="table" as="xs:string"/>
    <xsl:param name="text" as="xs:string"/>
    <xsl:param name="content" as="element()?"/>
    <xsl:variable name="unicode-braille"
                  select="pf:text-transform(
                            concat('(liblouis-table:&quot;',$table,'&quot;)'),
                            replace($text, '(\p{Z}|\s)+', ' '))"/>
    <xsl:variable name="ascii-braille" as="xs:string*">
      <xsl:analyze-string regex="[\s&#x00A0;&#x00AD;&#x200B;]+" select="$unicode-braille">
        <xsl:matching-substring>
          <xsl:sequence select="translate(.,'&#x00AD;&#x200B;','tm')"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="pef:encode('(liblouis-table:&quot;sbs.dis&quot;)', .)"/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($ascii-braille,'')"/>
  </xsl:function>
  -->
  
  <!-- ======= -->
  <!-- SUB/SUP -->
  <!-- ======= -->

  <!-- bei brl:select wird kein Zeichen gesetzt -->
  <xsl:template match="dtb:sup[descendant::brl:select]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Ziffern bekommen das Exponentzeichen und werden tiefgestellt -->
  <xsl:template match="dtb:sup[matches(., '^[-]*\d+$')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of
	  select="my:louis-translate(.,my:get-tables(.,'index'),concat('&#x257E;',string()))" />
    </xsl:copy>
  </xsl:template>

  <!-- alles andere bekommt das Zeichen für den oberen Index -->
  <xsl:template match="dtb:sup">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of
	  select="my:louis-translate(.,my:get-tables(.,local-name()),'&#x2580;')" />
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- bei brl:select wird kein Zeichen gesetzt -->
  <xsl:template match="dtb:sub[descendant::brl:select]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Ziffern bekommen das Zeichen für den unteren Index und werden tiefgestellt -->
  <xsl:template match="dtb:sub[matches(., '^[-]*\d+$')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of
	  select="my:louis-translate(.,my:get-tables(.,'index'),concat('&#x2581;',string()))" />
    </xsl:copy>
  </xsl:template>

  <!-- alles andere bekommt das Zeichen für den unteren Index -->
  <xsl:template match="dtb:sub">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of
	  select="my:louis-translate(.,my:get-tables(.,local-name()),'&#x2581;')" />
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ==== -->
  <!-- CODE -->
  <!-- ==== -->

  <xsl:template match="dtb:code[matches(.,'\s')]">
    <!-- Multi-word code -->
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of
	  select="my:louis-translate(.,'sbs.dis,sbs-special.cti,sbs-code.cti',concat('&#x2588;',string(),'&#x2589;'))"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dtb:code">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="my:louis-translate(.,'sbs.dis,sbs-special.cti,sbs-code.cti', concat('&#x257C;',string()))"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================ -->
  <!-- Computer Braille -->
  <!-- ================ -->

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:computer">
    <xsl:value-of select="my:louis-translate(.,string($computer_braille_tables), '&#x257C;')"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="brl:computer/text()">
    <xsl:value-of select="my:louis-translate(.,string($computer_braille_tables), string())"/>
  </xsl:template>

  <!-- ======= -->
  <!-- Abbrevs -->
  <!-- ======= -->

  <!-- don't call handle_abbr from a for-each! As it will redefine the context and getTable will fail when calling local-name() -->
  <xsl:template name="handle_abbr">
    <xsl:param name="context" select="local-name()"/>
    <xsl:param name="content" select="."/>
    <xsl:variable name="braille_tables" select="my:get-tables(.,$context)"/>
    <xsl:variable name="temp">
      <xsl:choose>
        <xsl:when test="my:containsDot($content)">
          <!-- drop all whitespace -->
          <xsl:for-each select="tokenize(string($content), '\s+')">
            <xsl:value-of select="."/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="outerTokens" select="my:tokenizeForAbbr(normalize-space($content))"/>
          <xsl:for-each select="$outerTokens">
            <xsl:choose>
              <xsl:when test="not(my:isLetter(substring(.,1,1)))">
                <xsl:value-of select="."/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="innerTokens" select="my:tokenizeByCase(.)"/>
                <xsl:for-each select="$innerTokens">
                  <xsl:variable name="i" select="position()"/>
                  <xsl:choose>
                    <xsl:when test="my:isUpper(substring(.,1,1))">
                      <xsl:choose>
                        <xsl:when test="string-length(.) &gt; 1"><xsl:value-of select="$GROSS_FUER_BUCHSTABENFOLGE"/></xsl:when>
                        <xsl:otherwise>
                          <!-- string-length(.) == 1 -->
                          <xsl:choose>
                            <xsl:when test="position()=last()"><xsl:value-of select="$GROSS_FUER_BUCHSTABENFOLGE"/></xsl:when>
                            <xsl:otherwise><xsl:value-of select="$GROSS_FUER_EINZELBUCHSTABE"/></xsl:otherwise>
                          </xsl:choose>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <!-- lowercase letters -->
                      <xsl:if test="position()=1 or (string-length($innerTokens[$i - 1]) &gt; 1 and my:isUpper(substring($innerTokens[$i - 1],1,1)))"><xsl:value-of select="$KLEINBUCHSTABE"/></xsl:if>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:value-of select="."/>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      <!-- If the last letter was a capital and the following letter is small, insert a KLEINBUCHSTABE -->
      <xsl:if test="matches(string($content), '.*\p{Lu}$') and
                    $content/following-sibling::node()[1][self::text()] and
                    matches(string($content/following-sibling::node()[1]), '^\p{Ll}.*')">
        <xsl:value-of select="$KLEINBUCHSTABE"/>
      </xsl:if>
    </xsl:variable>
    <xsl:value-of select="my:louis-translate(.,string($braille_tables), string($temp))"/>
  </xsl:template>
  
  <xsl:template match="dtb:abbr">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="handle_abbr"/>
    </xsl:copy>
  </xsl:template>

  <!-- ========================= -->
  <!-- STRONG, EM, BRL:EMPH, DFN -->
  <!-- ========================= -->

  <xsl:template match="dtb:strong|dtb:em|brl:emph|dtb:dfn">
    <xsl:variable name="braille_tables" select="my:get-tables(.,local-name())"/>
    <xsl:variable name="isFirst" as="xs:boolean"
      select="not(some $id in @id satisfies preceding::*[@brl:continuation and index-of(tokenize(@brl:continuation, '\s+'), $id)])"/>
    <xsl:variable name="isLast" as="xs:boolean">
      <xsl:choose>
        <xsl:when test="not($isFirst)">
          <xsl:variable name="id" select="@id"/>
          <xsl:variable name="continuation" select="preceding::*[@brl:continuation and index-of(tokenize(@brl:continuation, '\s+'), $id)]/@brl:continuation"/>
          <xsl:sequence select="not(following::*[@id and index-of(tokenize($continuation, '\s+'), @id)])"/>
        </xsl:when>
        <xsl:when test="some $id in tokenize(@brl:continuation, '\s+') satisfies following::*[@id eq $id]">
          <xsl:sequence select="false()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="true()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
	<xsl:when test="@brl:render = 'singlequote'">
          <!-- render the emphasis using singlequotes -->
          <xsl:if test="$isFirst">
            <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#8250;')"/>
          </xsl:if>
          <xsl:apply-templates/>
          <xsl:if test="$isLast">
            <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#8249;')"/>
          </xsl:if>
	</xsl:when>
	<xsl:when test="@brl:render = 'quote'">
          <!-- render the emphasis using quotes -->
          <xsl:if test="$isFirst">
            <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x00BB;')"/>
          </xsl:if>
          <xsl:apply-templates/>
          <xsl:if test="$isLast">
            <xsl:variable name="last_text_node" select="string((.//text())[position()=last()])"/>
            <xsl:choose>
              <xsl:when test="my:isNumberLike(substring($last_text_node, string-length($last_text_node), 1))">
		<xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x2039;')"/>
              </xsl:when>
              <xsl:otherwise>
		<xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x00AB;')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
	</xsl:when>
	<xsl:when test="@brl:render = 'ignore'">
          <!-- ignore the emphasis for braille -->
          <xsl:apply-templates/>
	</xsl:when>
	<xsl:otherwise>
          <!-- render the emphasis using emphasis annotation -->
          <!-- Since we send every (text) node to liblouis separately, it
	       has no means to know when an empasis starts and when it ends.
	       For that reason we do the announcing here in xslt. This also
	       neatly works around a bug where liblouis doesn't correctly
	       announce multi-word emphasis -->
          <xsl:choose>
            <xsl:when test="not($isFirst) or not($isLast) or (count(tokenize(string(.), '(\s|/|-)+')[string(.) ne '']) > 1)">
              <!-- There are multiple words. -->
              <xsl:if test="$isFirst">
		<!-- Insert a multiple word announcement -->
		<xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x2560;')"/>
              </xsl:if>
              <xsl:apply-templates/>
              <xsl:if test="$isLast">
		<!-- Announce the end of emphasis -->
		<xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x2563;')"/>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <!-- Its a single word. Insert a single word announcement unless it is within a word -->
              <xsl:choose>
		<!-- emph is at the beginning of the word -->
		<xsl:when
                    test="my:ends-with-non-word(preceding-sibling::text()[1]) and my:starts-with-word(following-sibling::text()[1])">
                  <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x255F;')"/>
                  <xsl:apply-templates/>
                  <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x2561;')"/>
		</xsl:when>
		<!-- emph is at the end of the word -->
		<xsl:when
                    test="my:ends-with-word(preceding-sibling::text()[1]) and my:starts-with-non-word(following-sibling::text()[1])">
                  <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x255E;')"/>
                  <xsl:apply-templates/>
		</xsl:when>
		<!-- emph is inside the word -->
		<xsl:when
                    test="my:ends-with-word(preceding-sibling::text()[1]) and my:starts-with-word(following-sibling::text()[1])">
                  <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x255E;')"/>
                  <xsl:apply-templates/>
                  <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x2561;')"/>
		</xsl:when>
		<xsl:otherwise>
                  <xsl:value-of select="my:louis-translate(.,$braille_tables, '&#x255F;')"/>
                  <xsl:apply-templates/>
		</xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- ====== -->
  <!-- IMAGES -->
  <!-- ====== -->

  <xsl:template match="dtb:imggroup">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dtb:img">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string(@alt))"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dtb:caption">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string())"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================= -->
  <!-- Contraction hints -->
  <!-- ================= -->

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='ordinal']">
    <xsl:choose>
      <xsl:when test="$downshift_ordinals = true()">
        <xsl:value-of select="my:louis-translate(.,my:get-tables(.,'num_ordinal'), string(translate(.,'.','')))"
        />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='roman']">
    <xsl:variable name="braille_tables" select="my:get-tables(.,'num_roman')"/>
    <xsl:choose>
      <xsl:when test="my:isUpper(substring(.,1,1))">
        <!-- we assume that if the first char is uppercase the rest is also uppercase -->
        <xsl:value-of select="my:louis-translate(.,$braille_tables,concat('&#x2566;',string()))"
        />
      </xsl:when>
      <xsl:otherwise>
        <!-- presumably the roman number is in lower case -->
        <xsl:value-of select="my:louis-translate(.,$braille_tables,concat('&#x2569;',string()))"
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='phone']">
    <!-- Replace ' ' and '/' with '.' -->
    <xsl:variable name="clean_number">
      <xsl:for-each select="tokenize(string(.), '(\s|/)+')">
        <xsl:value-of select="."/>
        <xsl:if test="not(position() = last())">.</xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()),string($clean_number))"/>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='fraction']">
    <xsl:variable name="numerator" select="(tokenize(string(.), '(\s|/)+'))[position()=1]"/>
    <xsl:variable name="denominator" select="(tokenize(string(.), '(\s|/)+'))[position()=2]"/>
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string($numerator))"/>
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,'denominator'), string($denominator))"
    />
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='mixed']">
    <xsl:variable name="braille_tables" select="my:get-tables(.,local-name())"/>
    <xsl:variable name="number" select="(tokenize(string(.), '(\s|/)+'))[position()=1]"/>
    <xsl:variable name="numerator" select="(tokenize(string(.), '(\s|/)+'))[position()=2]"/>
    <xsl:variable name="denominator" select="(tokenize(string(.), '(\s|/)+'))[position()=3]"/>
    <xsl:value-of select="my:louis-translate(.,$braille_tables, string($number))"/>
    <xsl:value-of select="my:louis-translate(.,$braille_tables, string($numerator))"/>
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,'denominator'), string($denominator))"
    />
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='measure']">
    <!-- For all number-unit combinations, e.g. 1 kg, 10 km, etc. drop the space -->
    <xsl:variable name="tokens" select="tokenize(normalize-space(string(.)), '\s+')"/>
    <xsl:variable name="number" select="$tokens[1]"/>
    <xsl:variable name="measure" select="$tokens[position()=last()]"/>

    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string($number))"/>
    <xsl:call-template name="handle_abbr">
      <xsl:with-param name="context" select="'abbr'"/>
      <xsl:with-param name="content" as="text()">
        <xsl:value-of select="$measure"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:num[@role='isbn']">
    <xsl:variable name="braille_tables" select="my:get-tables(.,local-name())"/>
    <xsl:variable name="lastChar" select="substring(.,string-length(.),1)"/>
    <xsl:variable name="secondToLastChar" select="substring(.,string-length(.)-1,1)"/>
    <xsl:choose>
      <!-- If the isbn number ends in a capital letter then keep the
           dash, mark the letter with &#x2566; and translate the
           letter with abbr -->
      <xsl:when
        test="$secondToLastChar='-' and string(number($lastChar))='NaN' and my:isUpper($lastChar)">
        <xsl:variable name="clean_number">
          <xsl:for-each select="tokenize(substring(.,1,string-length(.)-2), '(\s|-)+')">
            <xsl:value-of select="string(.)"/>
            <xsl:if test="not(position() = last())">.</xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="my:louis-translate(.,$braille_tables,string($clean_number))"/>
        <xsl:value-of select="my:louis-translate(.,$braille_tables,$secondToLastChar)"/>
        <xsl:value-of
          select="my:louis-translate(.,my:get-tables(.,'abbr'),concat('&#x2566;',$lastChar))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="clean_number">
          <xsl:for-each select="tokenize(string(.), '(\s|-)+')">
            <xsl:value-of select="string(.)"/>
            <xsl:if test="not(position() = last())">.</xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="my:louis-translate(.,$braille_tables,string($clean_number))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:name">
    <xsl:variable name="braille_tables"
		  select="if (matches(., '\p{Ll}&#x00AD;?\p{Lu}'))
			  then my:get-tables(.,'name_capitalized')
			  else my:get-tables(.,local-name())"/>
    <xsl:value-of select="my:louis-translate(.,$braille_tables, string())"/>
  </xsl:template>
  
  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:place">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()),string())"/>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:v-form">
    <xsl:choose>
      <xsl:when test="$show_v_forms = true()">
        <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat(upper-case(substring(string(),1,1)),lower-case(substring(string(),2))))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
      FIXME: also copy?
  -->
  <xsl:template match="brl:separator">
    <!-- ignore -->
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:homograph">
    <!-- Join all text elements with a special marker and send the
         whole string to liblouis -->
    <xsl:variable name="text">
      <xsl:for-each select="text()">
        <!-- simply ignore the separator elements -->
        <xsl:value-of select="string(.)"/>
        <xsl:if test="not(position() = last())">&#x250A;</xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string($text))"/>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:date">
    <xsl:variable name="this" select="."/>
    <xsl:variable name="braille_tables" select="my:get-tables(.,local-name())"/>
    <xsl:variable name="day_braille_tables" select="my:get-tables(.,'date_day')"/>
    <xsl:variable name="month_braille_tables" select="my:get-tables(.,'date_month')"/>
    <xsl:for-each select="tokenize(string(@value), '-')">
      <!-- reverse the order, so we have day, month, year -->
      <xsl:sort select="position()" order="descending" data-type="number"/>
      <xsl:choose>
        <xsl:when test="position() = 1">
          <xsl:value-of
            select="my:louis-translate($this,$day_braille_tables, format-number(. cast as xs:integer,'#'))"
          />
        </xsl:when>
        <xsl:when test="position() = 2">
          <xsl:value-of
            select="my:louis-translate($this,$month_braille_tables, format-number(. cast as xs:integer,'#'))"
          />
        </xsl:when>
        <xsl:otherwise>
	  <xsl:if test="matches(string(.), '\d+')">
	    <xsl:value-of
		select="my:louis-translate($this,$braille_tables, format-number(. cast as xs:integer,'#'))"/>
	  </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!--
      FIXME: also copy
  -->
  <xsl:template match="brl:time">
    <xsl:variable name="time">
      <xsl:for-each select="tokenize(string(@value), ':')">
	<xsl:choose>
	  <!-- Drop the leading zero for the hours and append a dot -->
	  <xsl:when test="not(position() = last())">
	    <xsl:value-of select="format-number(. cast as xs:integer,'#')"/>
	    <xsl:text>.</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="."/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string($time))"/>
  </xsl:template>

  <!-- ================= -->
  <!-- Content selection -->
  <!-- ================= -->
  
  <!--
      FIXME: also copy? or at least warn that style is ignored
  -->
  <xsl:template match="brl:select">
    <xsl:apply-templates select="brl:when-braille"/>
    <!-- Ignore the brl:otherwise element -->
  </xsl:template>

  <!--
      FIXME: also copy? or at least warn that style is ignored
  -->
  <xsl:template match="brl:when-braille">
    <xsl:apply-templates />
    <!-- Ignore the brl:otherwise element -->
  </xsl:template>

  <!--
      FIXME: also copy? or at least warn that style is ignored
      FIXME: make sure this produces Unicode braille
  -->
  <xsl:template match="brl:literal">
    <xsl:if test="not(exists(@brl:grade)) or (exists(@brl:grade) and @brl:grade  = $contraction)">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <!-- ======================================= -->
  <!-- Text nodes are translated with liblouis -->
  <!-- ======================================= -->

  <!-- ========================================== -->
  <!-- Comma after ordinals, fraction and sub/sup -->
  <!-- ========================================== -->
  <xsl:template
    match="text()[(preceding::* intersect my:preceding-textnode-within-block(.)/(ancestor::brl:num[@role=('ordinal','fraction','mixed')]|ancestor::dtb:sub|ancestor::dtb:sup)) and matches(string(), '^,')]" priority="100">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat('&#x256C;',string()))"/>
  </xsl:template>

  <!-- ============================================= -->
  <!-- Punctuation after a number and after ordinals -->
  <!-- ============================================= -->
  <xsl:template
    match="text()[my:starts-with-punctuation(string()) and not(preceding::* intersect my:preceding-textnode-within-block(.)/ancestor::*[@brl:render=('quote','singlequote')])
    and (my:ends-with-number(string(my:preceding-textnode-within-block(.))) or (preceding::* intersect my:preceding-textnode-within-block(.)/(ancestor::brl:num[@role='ordinal']|ancestor::brl:date)))]">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat('&#x250B;',string()))"/>
  </xsl:template>

  <!-- ========================================== -->
  <!-- Apostrophe after v-form or after homograph -->
  <!-- ========================================== -->
  <xsl:template
    match="text()[(preceding::* intersect my:preceding-textnode-within-block(.)/(ancestor::brl:v-form|ancestor::brl:homograph)) and matches(string(), '^''')]" priority="100">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat('&#x250A;',string()))"/>
  </xsl:template>

  <!-- ================================================= -->
  <!-- Single word mixed emphasis, mixed emphasis before-->
  <!-- ================================================= -->
  <xsl:template
    match="text()[my:starts-with-word(string()) and my:ends-with-word(string(my:preceding-textnode-within-block(.)[ancestor::dtb:em]))]">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat('&#x250A;',string()))"/>
  </xsl:template>

  <!-- ================================================ -->
  <!-- Single word mixed emphasis, mixed emphasis after -->
  <!-- ================================================ -->
  <xsl:template
    match="text()[my:ends-with-word(string()) and my:starts-with-word(string(my:following-textnode-within-block(.)[ancestor::dtb:em]))]">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat(string(),'&#x250A;'))"/>
  </xsl:template>
  
  <!-- ====================== -->
  <!-- Single word mixed abbr -->
  <!-- ====================== -->
  <xsl:template
    match="text()[my:starts-with-word(string()) and not(my:starts-with-number(string())) and my:ends-with-word(string(my:preceding-textnode-within-block(.)[ancestor::dtb:abbr]))]">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat('&#x250A;',string()))"/>
  </xsl:template>

  <!-- ============================================================================= -->
  <!-- 'ich' inside text node followed by chars that could be interpreted as numbers -->
  <!-- ============================================================================= -->
  <xsl:template
    match="text()[(matches(string(), '^ich$', 'i') or matches(string(), '\Wich$', 'i')) and matches(string(following::text()[1]), '^[,;:?!)&#x00bb;&#x00ab;]')]" priority="100">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), concat(string(),'&#x250A;'))"/>
  </xsl:template>

  <xsl:template match="text()" priority="50">
    <xsl:value-of select="my:louis-translate(.,my:get-tables(.,local-name()), string())"/>
  </xsl:template>

  <!-- Copy all the rest -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

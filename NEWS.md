pipeline-mod-sbs v1.4.0
=======================

Includes
--------
- SBS-specific DTBook to PEF script with:
  - an SBS-specific default CSS style sheet
  - automatic insertion of title pages (https://github.com/snaekobbi/pipeline-mod-sbs/issues/7)
  - an SBS-compatible default ASCII-table
- Improved support for text-level semantics (`strong`, `em`, `dfn`, `sub`, `sup`, `code`, `abbr`,
  `brl:computer`, `brl:emph`, `brl:num`, `brl:name`, `brl:place`, `brl:v-form`, `brl:homograph`,
  `brl:date`, `brl:time`, ...) (https://github.com/snaekobbi/pipeline-mod-sbs/issues/2)
- Support for `text-transform: volume` and `text-transform: volumes`

pipeline-mod-sbs v1.3.1
=======================
Bugfix release

pipeline-mod-sbs v1.3.0
=======================
Compatibility update

pipeline-mod-sbs v1.2.0
=======================

Includes
--------
- Support for `text-transform: print-page`

pipeline-mod-sbs v1.1.0
=======================

Includes
--------
- Support for grade 0
- Bugfixes

pipeline-mod-sbs v1.0.0
=======================

Includes
--------
- Custom Liblouis table from sbs-braille-tables [2.0](https://github.com/sbsdev/sbs-braille-tables/releases/tag/v2.0)
  (https://github.com/snaekobbi/liblouis/issues/5, https://github.com/snaekobbi/issues/issues/13)
- Custom hyphenation table from sbs-hyphenation-tables
  [1.17](https://github.com/sbsdev/sbs-hyphenation-tables/releases/tag/v1.17)
- Custom Liblouis based translator that handles `html:strong` and `html:em`
  (https://github.com/snaekobbi/issues/issues/14, https://github.com/snaekobbi/pipeline-mod-braille/issues/37)

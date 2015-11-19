package ch.sbs.pipeline.braille.impl;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URI;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.xml.namespace.QName;

import com.google.common.base.Objects;
import com.google.common.base.Optional;
import com.google.common.base.Splitter;
import com.google.common.collect.ImmutableMap;
import static com.google.common.collect.Lists.newArrayList;

import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.common.util.Files.unpack;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.AbstractTransform;
import org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Function;
import org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables.concat;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables.transform;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.logCreate;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.logSelect;
import org.daisy.pipeline.braille.common.BrailleTranslator;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.CSSStyledTextTransform;
import org.daisy.pipeline.braille.common.TextTransform;
import org.daisy.pipeline.braille.common.Transform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.memoize;
import static org.daisy.pipeline.braille.common.util.Locales.parseLocale;
import org.daisy.pipeline.braille.common.XProcTransform;
import org.daisy.pipeline.braille.libhyphen.LibhyphenHyphenator;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

public interface SBSTranslator extends BrailleTranslator, CSSStyledTextTransform, CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "ch.sbs.pipeline.braille.impl.SBSTranslator.Provider",
		service = {
			BrailleTranslator.Provider.class,
			TextTransform.Provider.class,
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider extends AbstractTransform.Provider<SBSTranslator>
	                      implements BrailleTranslator.Provider<SBSTranslator>,
	                                 TextTransform.Provider<SBSTranslator>,
	                                 XProcTransform.Provider<SBSTranslator>,
	                                 CSSBlockTransform.Provider<SBSTranslator> {
		
		private URI href;
		private URI displayTable;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
			File f = new File(makeUnpackDir(context), "virtual.dis");
			unpack(context.getBundleContext().getBundle().getEntry("/liblouis/virtual.dis"), f);
			displayTable = asURI(f);
		}
			
		private final static String grade0Table = "http://www.sbs.ch/pipeline/liblouis/tables/" +
			"sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-whitespace.mod,sbs-numsign.mod," +
			"sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g0-core.mod,sbs-de-hyph-none.mod,sbs-de-accents-ch.mod," +
			"sbs-special.mod";
		private final static String grade1Table = "http://www.sbs.ch/pipeline/liblouis/tables/" +
			"sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-whitespace.mod,sbs-numsign.mod," +
			"sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g0-core.mod,sbs-de-g1-white.mod,sbs-de-g1-core.mod," +
			"sbs-de-hyph-none.mod,sbs-de-accents-ch.mod,sbs-special.mod";
		private final static String grade2Table = "http://www.sbs.ch/pipeline/liblouis/tables/" +
			"sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-whitespace.mod,sbs-de-letsign.mod," +
			"sbs-numsign.mod,sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g2-white.mod,sbs-de-g2-core.mod," +
			"sbs-de-hyph-none.mod,sbs-de-accents-ch.mod,sbs-special.mod";
		private final static String hyphenationTable = "(libhyphen-table:'http://www.sbs.ch/pipeline/hyphen/hyph_de_DE.dic')";
		
		private final static Iterable<SBSTranslator> empty = Iterables.<SBSTranslator>empty();
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `sbs'.
		 * - locale: Will only match if the language subtag is 'de'.
		 * - grade: `0', `1' or `2'.
		 *
		 */
		protected final Iterable<SBSTranslator> _get(String query) {
			Map<String,Optional<String>> q = new HashMap<String,Optional<String>>(parseQuery(query));
			Optional<String> o;
			if ((o = q.remove("locale")) != null)
				if (!"de".equals(parseLocale(o.get()).getLanguage()))
					return empty;
			if ((o = q.remove("translator")) != null)
				if (o.get().equals("sbs"))
					if ((o = q.remove("grade")) != null) {
						final int grade;
						if (o.get().equals("0"))
							grade = 0;
						else if (o.get().equals("1"))
							grade = 1;
						else if (o.get().equals("2"))
							grade = 2;
						else
							return empty;
						if (q.size() == 0) {
							Iterable<LibhyphenHyphenator> hyphenators = logSelect(hyphenationTable, libhyphenHyphenatorProvider);
							final String liblouisTable = "(liblouis-table:'" + displayTable
								+ "," + ( grade == 2 ? grade2Table : ( grade == 1 ? grade1Table : grade0Table )) + "')";
							return concat(
								Iterables.transform(
									hyphenators,
									new Function<LibhyphenHyphenator,Iterable<SBSTranslator>>() {
										public Iterable<SBSTranslator> _apply(LibhyphenHyphenator h) {
											return Iterables.transform(
												logSelect(liblouisTable + "(hyphenator:" + h.getIdentifier() + ")", liblouisTranslatorProvider),
												new Function<LiblouisTranslator,SBSTranslator>() {
													public SBSTranslator _apply(LiblouisTranslator translator) {
														return __apply(logCreate(new TransformImpl(grade, translator))); }}); }})); }}
			return empty;
		}
		
		private final static Splitter.MapSplitter CSS_PARSER
		= Splitter.on(';').omitEmptyStrings().withKeyValueSeparator(Splitter.on(':').limit(2).trimResults());
		private final static Splitter TEXT_TRANSFORM_PARSER = Splitter.on(' ').omitEmptyStrings().trimResults();
		private final static Pattern PRINT_PAGE_NUMBER = Pattern.compile("(?<first>[0-9]+)?(?:/(?<last>[0-9]+))?");
		private final static String PRINT_PAGE_NUMBER_SIGN = "\u2838\u283c";
		private final static String[] UPPER_DIGIT_TABLE = new String[]{
			"\u281a","\u2801","\u2803","\u2809","\u2819","\u2811","\u280b","\u281b","\u2813","\u280a"};
		private final static String[] LOWER_DIGIT_TABLE = new String[]{
			"\u2834","\u2802","\u2806","\u2812","\u2832","\u2822","\u2816","\u2836","\u2826","\u2814"};

		private class TransformImpl extends AbstractTransform implements SBSTranslator {
			
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			private final int grade;
			private final LiblouisTranslator translator;
			
			private TransformImpl(int grade, LiblouisTranslator translator) {
				Map<String,String> options = ImmutableMap.of("text-transform", "(id:" + this.getIdentifier() + ")");
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
				this.grade = grade;
				this.translator = translator;
			}
			
			public TextTransform asTextTransform() {
				return this;
			}
			
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
			
			public boolean isHyphenating() {
				return translator.isHyphenating();
			}
			
			public String transform(String text) {
				return translator.transform(text);
			}
			
			public String[] transform(String[] text) {
				return translator.transform(text);
			}
			
			public String[] transform(String[] text, String[] cssStyle) {
				if (text.length == 1)
					return new String[]{transform(text[0], cssStyle[0])};
				return translator.transform(text, cssStyle);
			}
			
			public String transform(String text, String cssStyle) {
				if (cssStyle != null) {
					Map<String,String> style = new HashMap<String,String>(CSS_PARSER.split(cssStyle));
					String t = style.remove("text-transform");
					if (t != null) {
						if (!style.isEmpty())
							throw new RuntimeException("Translator does not support '" + cssStyle +"'");
						List<String> textTransform = newArrayList(TEXT_TRANSFORM_PARSER.split(t));
						boolean isPrintPage = textTransform.remove("print-page");
						if (!textTransform.isEmpty())
							throw new RuntimeException("Translator does not support '" + cssStyle +"'");
						if (isPrintPage)
							return translatePrintPageNumber(text); }}
				return translator.transform(text, cssStyle);
			}
			
			private String translatePrintPageNumber(String number) {
				Matcher m = PRINT_PAGE_NUMBER.matcher(number);
				if (!m.matches())
					throw new RuntimeException("'" + number + "' is not a valid print page number or print page number range");
				StringBuilder b = new StringBuilder();
				b.append(PRINT_PAGE_NUMBER_SIGN);
				String first = m.group("first");
				String last = m.group("last");
				// TODO: warning if first == null
				if (first != null)
					b.append(translateNaturalNumber(Integer.parseInt(first)));
				if (last != null)
					b.append(translateNaturalNumber(Integer.parseInt(last), true));
				return b.toString();
			}
			
			private String translateNaturalNumber(int number) {
				return translateNaturalNumber(number, false);
			}
			
			private String translateNaturalNumber(int number, boolean downshift) {
				StringBuilder b = new StringBuilder();
				String[] table = downshift ? LOWER_DIGIT_TABLE : UPPER_DIGIT_TABLE;
				if (number == 0)
					b.append(table[0]);
				while (number > 0) {
					b.insert(0, table[number % 10]);
					number = number / 10; }
				return b.toString();
			}
			
			@Override
			public String toString() {
				return Objects.toStringHelper(SBSTranslator.class.getSimpleName())
					.add("grade", grade)
					.toString();
			}
		}
		
		@Reference(
			name = "LiblouisTranslatorProvider",
			unbind = "unbindLiblouisTranslatorProvider",
			service = LiblouisTranslator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		protected void bindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.add(provider);
		}
	
		protected void unbindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.remove(provider);
			liblouisTranslatorProvider.invalidateCache();
		}
	
		private List<Transform.Provider<LiblouisTranslator>> liblouisTranslatorProviders
		= new ArrayList<Transform.Provider<LiblouisTranslator>>();
		private Transform.Provider.MemoizingProvider<LiblouisTranslator> liblouisTranslatorProvider
		= memoize(dispatch(liblouisTranslatorProviders));
		
		@Reference(
			name = "LibhyphenHyphenatorProvider",
			unbind = "unbindLibhyphenHyphenatorProvider",
			service = LibhyphenHyphenator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		protected void bindLibhyphenHyphenatorProvider(LibhyphenHyphenator.Provider provider) {
			libhyphenHyphenatorProviders.add(provider);
		}
	
		protected void unbindLibhyphenHyphenatorProvider(LibhyphenHyphenator.Provider provider) {
			libhyphenHyphenatorProviders.remove(provider);
			libhyphenHyphenatorProvider.invalidateCache();
		}
	
		private List<Transform.Provider<LibhyphenHyphenator>> libhyphenHyphenatorProviders
		= new ArrayList<Transform.Provider<LibhyphenHyphenator>>();
		private Transform.Provider.MemoizingProvider<LibhyphenHyphenator> libhyphenHyphenatorProvider
		= memoize(dispatch(libhyphenHyphenatorProviders));
		
		private static File makeUnpackDir(ComponentContext context) {
			File directory;
			for (int i = 0; true; i++) {
				directory = context.getBundleContext().getDataFile("resources" + i);
				if (!directory.exists()) break; }
			directory.mkdirs();
			return directory;
		}
	}
}

package ch.sbs.pipeline.braille.impl;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URI;
import javax.xml.namespace.QName;

import com.google.common.base.Objects;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

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
import org.daisy.pipeline.braille.common.CSSBlockTransform;
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

public interface SBSCSSBlockTransform extends CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "ch.sbs.pipeline.braille.impl.SBSCSSBlockTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider extends AbstractTransform.Provider<SBSCSSBlockTransform>
		                  implements XProcTransform.Provider<SBSCSSBlockTransform>, CSSBlockTransform.Provider<SBSCSSBlockTransform> {
		
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
		
		private final static Iterable<SBSCSSBlockTransform> empty = Iterables.<SBSCSSBlockTransform>empty();
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `sbs'.
		 * - locale: Will only match if the language subtag is 'de'.
		 * - grade: `0', `1' or `2'.
		 *
		 */
		protected final Iterable<SBSCSSBlockTransform> _get(String query) {
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
								transform(
									hyphenators,
									new Function<LibhyphenHyphenator,Iterable<SBSCSSBlockTransform>>() {
										public Iterable<SBSCSSBlockTransform> _apply(LibhyphenHyphenator h) {
											final String translatorQuery = liblouisTable + "(hyphenator:" + h.getIdentifier() + ")";
											return transform(
												logSelect(translatorQuery, liblouisTranslatorProvider),
												new Function<LiblouisTranslator,SBSCSSBlockTransform>() {
													public SBSCSSBlockTransform _apply(LiblouisTranslator translator) {
														return __apply(logCreate(new TransformImpl(grade, translatorQuery, translator))); }}); }})); }}
			return empty;
		}
		
		private class TransformImpl extends AbstractTransform implements SBSCSSBlockTransform {
			
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			private final int grade;
			private final LiblouisTranslator translator;
			
			private TransformImpl(int grade, String translatorQuery, LiblouisTranslator translator) {
				Map<String,String> options = ImmutableMap.of("query", translatorQuery);
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
				this.grade = grade;
				this.translator = translator;
			}
			
			public TextTransform asTextTransform() {
				return translator;
			}
			
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
			
			@Override
			public String toString() {
				return Objects.toStringHelper(SBSCSSBlockTransform.class.getSimpleName())
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

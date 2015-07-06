package ch.sbs.pipeline.braille.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.net.URI;
import javax.xml.namespace.QName;

import static com.google.common.base.Objects.toStringHelper;
import static com.google.common.collect.Iterables.concat;
import static com.google.common.collect.Iterables.transform;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.Transform;
import org.daisy.pipeline.braille.common.Transform.AbstractTransform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.logCreate;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.logSelect;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.memoize;
import org.daisy.pipeline.braille.common.WithSideEffect;
import org.daisy.pipeline.braille.common.XProcTransform;
import org.daisy.pipeline.braille.libhyphen.LibhyphenHyphenator;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

import org.slf4j.Logger;

public interface SBSCSSBlockTransform extends CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "ch.sbs.pipeline.braille.impl.SBSCSSBlockTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider implements XProcTransform.Provider<SBSCSSBlockTransform>, CSSBlockTransform.Provider<SBSCSSBlockTransform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
		}
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `sbs'.
		 * - grade: `1' or `2'.
		 *
		 */
		public Iterable<SBSCSSBlockTransform> get(String query) {
			 return impl.get(query);
		 }
	
		public Transform.Provider<SBSCSSBlockTransform> withContext(Logger context) {
			return impl.withContext(context);
		}
	
		private Transform.Provider.MemoizingProvider<SBSCSSBlockTransform> impl = new ProviderImpl(null);
	
		private class ProviderImpl extends AbstractProvider<SBSCSSBlockTransform> {
			
			private final static String grade1Table = "(liblouis-table:'http://www.sbs.ch/pipeline/liblouis/tables/" +
				"sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-whitespace.mod,sbs-numsign.mod," +
				"sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g0-core.mod,sbs-de-g1-white.mod,sbs-de-g1-core.mod," +
				"sbs-de-hyph-none.mod,sbs-de-accents-ch.mod,sbs-special.mod')";
			private final static String grade2Table = "(liblouis-table:'http://www.sbs.ch/pipeline/liblouis/tables/" +
				"sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-whitespace.mod,sbs-de-letsign.mod," +
				"sbs-numsign.mod,sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g2-white.mod,sbs-de-g2-core.mod," +
				"sbs-de-hyph-none.mod,sbs-de-accents-ch.mod,sbs-special.mod')";
			private final static String hyphenationTable = "(libhyphen-table:'http://www.sbs.ch/pipeline/hyphen/hyph_de_DE.dic')";
		
			private ProviderImpl(Logger context) {
				super(context);
			}
		
			protected Transform.Provider.MemoizingProvider<SBSCSSBlockTransform> _withContext(Logger context) {
				return new ProviderImpl(context);
			}
		
			protected final Iterable<WithSideEffect<SBSCSSBlockTransform,Logger>> __get(String query) {
				Map<String,Optional<String>> q = new HashMap<String,Optional<String>>(parseQuery(query));
				Optional<String> o;
				if ((o = q.remove("translator")) != null)
					if (o.get().equals("sbs"))
						if ((o = q.remove("grade")) != null) {
							final int grade;
							if (o.get().equals("1"))
								grade = 1;
							else if (o.get().equals("2"))
								grade = 2;
							else
								return empty;
							if (q.size() == 0) {
								Iterable<WithSideEffect<LibhyphenHyphenator,Logger>> hyphenators
									= logSelect(hyphenationTable, libhyphenHyphenatorProvider.get(hyphenationTable));
								final String liblouisTable = grade == 1 ? grade1Table : grade2Table;
								return transform(
									hyphenators,
									new WithSideEffect.Function<LibhyphenHyphenator,SBSCSSBlockTransform,Logger>() {
										public SBSCSSBlockTransform _apply(LibhyphenHyphenator h) {
											String translatorQuery = liblouisTable + "(hyphenator:" + h.getIdentifier() + ")";
											try {
												applyWithSideEffect(
													logSelect(
														translatorQuery,
														liblouisTranslatorProvider.get(translatorQuery)).iterator().next()); }
											catch (NoSuchElementException e) {
												throw new NoSuchElementException(); }
											return applyWithSideEffect(
												logCreate(
													(SBSCSSBlockTransform)new TransformImpl(grade, translatorQuery))); }}); }}
				return empty;
			}
		}
	
		private final static Iterable<WithSideEffect<SBSCSSBlockTransform,Logger>> empty
		= Optional.<WithSideEffect<SBSCSSBlockTransform,Logger>>absent().asSet();
		
		private class TransformImpl extends AbstractTransform implements SBSCSSBlockTransform {
			
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			private final int grade;
			
			private TransformImpl(int grade, String translatorQuery) {
				Map<String,String> options = ImmutableMap.of("query", translatorQuery);
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
				this.grade = grade;
			}
	
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
	
			@Override
			public String toString() {
				return toStringHelper(SBSCSSBlockTransform.class.getSimpleName())
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
		
	}
}

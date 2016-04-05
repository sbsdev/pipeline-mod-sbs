import javax.inject.Inject;

import java.io.File;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.daisy.maven.xproc.xprocspec.XProcSpecRunner;

import org.daisy.pipeline.braille.common.BrailleTranslator.CSSStyledText;
import org.daisy.pipeline.braille.common.BrailleTranslator.FromStyledTextToBraille;
import static org.daisy.pipeline.braille.common.Query.util.query;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import static org.daisy.pipeline.pax.exam.Options.brailleModule;
import static org.daisy.pipeline.pax.exam.Options.calabashConfigFile;
import static org.daisy.pipeline.pax.exam.Options.domTraversalPackage;
import static org.daisy.pipeline.pax.exam.Options.felixDeclarativeServices;
import static org.daisy.pipeline.pax.exam.Options.logbackClassic;
import static org.daisy.pipeline.pax.exam.Options.logbackConfigFile;
import static org.daisy.pipeline.pax.exam.Options.mavenBundle;
import static org.daisy.pipeline.pax.exam.Options.mavenBundlesWithDependencies;
import static org.daisy.pipeline.pax.exam.Options.pipelineModule;
import static org.daisy.pipeline.pax.exam.Options.thisBundle;
import static org.daisy.pipeline.pax.exam.Options.xprocspec;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import org.junit.Test;
import org.junit.runner.RunWith;

import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerClass;
import org.ops4j.pax.exam.util.PathUtils;

import static org.ops4j.pax.exam.CoreOptions.junitBundles;
import static org.ops4j.pax.exam.CoreOptions.options;
import static org.ops4j.pax.exam.CoreOptions.systemPackage;

@RunWith(PaxExam.class)
@ExamReactorStrategy(PerClass.class)
public class SBSTest {
	
	@Inject
	private LiblouisTranslator.Provider provider;
	
	@Test(expected = AssertionError.class) // XFAIL
	public void testWhiteSpaceSegmentsLost() {
		FromStyledTextToBraille translator = provider
			.get(query("(liblouis-table:'http://www.sbs.ch/pipeline/liblouis/tables/" +
			           "sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-whitespace.mod,sbs-numsign.mod," +
			           "sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g0-core.mod,sbs-de-hyph-none.mod,sbs-de-accents-ch.mod," +
			           "sbs-special.mod')"))
			.iterator().next()
			.fromStyledTextToBraille();
		
		// with sbs-whitespace.mod included, fails when "foo" and "bar" have 5 or more white space segments in between them
		assertEquals(braille("⠋⠕⠕"," ","","","","","⠃⠁⠗"),
		             translator.transform(text("foo"," "," "," "," "," ","bar")));
	}
	
	@Test
	public void testWhiteSpaceSegmentsPreserved() {
		FromStyledTextToBraille translator = provider
			.get(query("(liblouis-table:'http://www.sbs.ch/pipeline/liblouis/tables/" +
			           "sbs.dis,sbs-de-core6.cti,sbs-de-accents.cti,sbs-special.cti,sbs-numsign.mod," +
			           "sbs-litdigit-upper.mod,sbs-de-core.mod,sbs-de-g0-core.mod,sbs-de-hyph-none.mod,sbs-de-accents-ch.mod," +
			           "sbs-special.mod')"))
			.iterator().next()
			.fromStyledTextToBraille();
		
		// without sbs-whitespace.mod included, works fine
		assertEquals(braille("⠋⠕⠕"," "," "," "," "," ","⠃⠁⠗"),
		             translator.transform(text("foo"," "," "," "," "," ","bar")));
	}
	
	@Inject
	private XProcSpecRunner xprocspecRunner;
	
	@Test
	public void runXProcSpec() throws Exception {
		File baseDir = new File(PathUtils.getBaseDir());
		Map<String,File> tests = new HashMap<String,File>();
		for (String test : new String[]{
				"test_translator",
				"test_tables",
				"test_pagination",
				"test_titlepage"
			})
			tests.put(test, new File(baseDir, "src/test/xprocspec/" + test + ".xprocspec"));
		boolean success = xprocspecRunner.run(tests,
		                                      new File(baseDir, "target/xprocspec-reports"),
		                                      new File(baseDir, "target/surefire-reports"),
		                                      new File(baseDir, "target/xprocspec"),
		                                      null,
		                                      new XProcSpecRunner.Reporter.DefaultReporter());
		assertTrue("XProcSpec tests should run with success", success);
	}
	
	@Configuration
	public Option[] config() {
		return options(
			logbackConfigFile(),
			calabashConfigFile(),
			domTraversalPackage(),
			felixDeclarativeServices(),
			systemPackage("javax.xml.stream;version=\"1.0.1\""),
			thisBundle(),
			junitBundles(),
			mavenBundlesWithDependencies(
				brailleModule("common-utils"),
				brailleModule("css-utils"),
				brailleModule("pef-utils"),
				brailleModule("liblouis-utils"),
				brailleModule("liblouis-native").forThisPlatform(),
				brailleModule("libhyphen-core"),
				brailleModule("libhyphen-native").forThisPlatform(),
				mavenBundle("ch.sbs.pipeline:sbs-braille-tables:?"),
				mavenBundle("ch.sbs.pipeline:sbs-hyphenation-tables:?"),
				brailleModule("dotify-utils"),
				brailleModule("dotify-formatter"),
				brailleModule("dtbook-to-pef"),
				// because of bug in lou_indexTables we need to include liblouis-tables even though
				// we're not using it (needed for include-brf)
				brailleModule("liblouis-tables"),
				// logging
				logbackClassic(),
				// xprocspec
				xprocspec(),
				mavenBundle("org.daisy.maven:xproc-engine-daisy-pipeline:?"))
		);
	}
	
	private Iterable<CSSStyledText> styledText(String... textAndStyle) {
		List<CSSStyledText> styledText = new ArrayList<CSSStyledText>();
		String text = null;
		boolean textSet = false;
		for (String s : textAndStyle) {
			if (textSet)
				styledText.add(new CSSStyledText(text, s));
			else
				text = s;
			textSet = !textSet; }
		if (textSet)
			throw new RuntimeException();
		return styledText;
	}
	
	private Iterable<CSSStyledText> text(String... text) {
		List<CSSStyledText> styledText = new ArrayList<CSSStyledText>();
		for (String t : text)
			styledText.add(new CSSStyledText(t, ""));
		return styledText;
	}
	
	private Iterable<String> braille(String... text) {
		return Arrays.asList(text);
	}
}

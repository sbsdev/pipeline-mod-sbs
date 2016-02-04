import javax.inject.Inject;

import java.io.File;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;

import org.daisy.maven.xproc.xprocspec.XProcSpecRunner;

import org.daisy.pipeline.braille.common.BrailleTranslator.CSSStyledText;
import org.daisy.pipeline.braille.common.BrailleTranslator.FromStyledTextToBraille;
import static org.daisy.pipeline.braille.common.Query.util.query;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import static org.daisy.pipeline.pax.exam.Options.brailleModule;
import static org.daisy.pipeline.pax.exam.Options.calabashConfigFile;
import static org.daisy.pipeline.pax.exam.Options.domTraversalPackage;
import static org.daisy.pipeline.pax.exam.Options.felixDeclarativeServices;
import static org.daisy.pipeline.pax.exam.Options.forThisPlatform;
import static org.daisy.pipeline.pax.exam.Options.logbackBundles;
import static org.daisy.pipeline.pax.exam.Options.logbackConfigFile;
import static org.daisy.pipeline.pax.exam.Options.pipelineModule;
import static org.daisy.pipeline.pax.exam.Options.thisBundle;
import static org.daisy.pipeline.pax.exam.Options.xprocspecBundles;

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
import static org.ops4j.pax.exam.CoreOptions.mavenBundle;
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
		boolean success = xprocspecRunner.run(new File(baseDir, "src/test/xprocspec"),
		                                      new File(baseDir, "target/xprocspec-reports"),
		                                      new File(baseDir, "target/surefire-reports"),
		                                      new File(baseDir, "target/xprocspec"),
		                                      new XProcSpecRunner.Reporter.DefaultReporter());
		assertTrue("XProcSpec tests should run with success", success);
	}
	
	@Configuration
	public Option[] config() {
		return options(
			logbackConfigFile(),
			logbackBundles(),
			calabashConfigFile(),
			domTraversalPackage(),
			felixDeclarativeServices(),
			systemPackage("javax.xml.stream;version=\"1.0.1\""),
			mavenBundle().groupId("com.google.guava").artifactId("guava").versionAsInProject(),
			mavenBundle().groupId("net.java.dev.jna").artifactId("jna").versionAsInProject(),
			mavenBundle().groupId("org.daisy.bindings").artifactId("jhyphen").versionAsInProject(),
			mavenBundle().groupId("org.liblouis").artifactId("liblouis-java").versionAsInProject(),
			mavenBundle().groupId("org.daisy.braille").artifactId("braille-utils.api").versionAsInProject(),
			mavenBundle().groupId("org.daisy.libs").artifactId("jstyleparser").versionAsInProject(),
			mavenBundle().groupId("org.unbescape").artifactId("unbescape").versionAsInProject(),
			mavenBundle().groupId("org.daisy.braille").artifactId("braille-css").versionAsInProject(),
			mavenBundle().groupId("org.apache.servicemix.bundles").artifactId("org.apache.servicemix.bundles.antlr-runtime").versionAsInProject(),
			mavenBundle().groupId("org.daisy.braille").artifactId("braille-utils.api").versionAsInProject(),
			mavenBundle().groupId("org.daisy.braille").artifactId("braille-utils.pef-tools").versionAsInProject(),
			mavenBundle().groupId("org.daisy.braille").artifactId("braille-utils.impl").versionAsInProject(),
			mavenBundle().groupId("org.daisy.libs").artifactId("jing").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.api").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.common").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.translator.impl").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.formatter.impl").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.text.impl").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.task-api").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.task.impl").versionAsInProject(),
			brailleModule("common-utils"),
			brailleModule("css-core"),
			brailleModule("css-calabash"),
			brailleModule("css-utils"),
			brailleModule("pef-core"),
			brailleModule("pef-calabash"),
			brailleModule("pef-saxon"),
			brailleModule("pef-utils"),
			brailleModule("liblouis-core"),
			brailleModule("liblouis-saxon"),
			brailleModule("liblouis-calabash"),
			brailleModule("liblouis-utils"),
			forThisPlatform(brailleModule("liblouis-native")),
			brailleModule("libhyphen-core"),
			forThisPlatform(brailleModule("libhyphen-native")),
			mavenBundle().groupId("ch.sbs.pipeline").artifactId("sbs-braille-tables").versionAsInProject(),
			mavenBundle().groupId("ch.sbs.pipeline").artifactId("sbs-hyphenation-tables").versionAsInProject(),
			brailleModule("dotify-core"),
			brailleModule("dotify-saxon"),
			brailleModule("dotify-calabash"),
			brailleModule("dotify-utils"),
			brailleModule("dotify-formatter"),
			brailleModule("dtbook-to-pef"),
			pipelineModule("file-utils"),
			pipelineModule("common-utils"),
			pipelineModule("html-utils"),
			pipelineModule("zip-utils"),
			pipelineModule("mediatype-utils"),
			pipelineModule("fileset-utils"),
			pipelineModule("metadata-utils"),
			pipelineModule("validation-utils"),
			pipelineModule("dtbook-utils"),
			pipelineModule("dtbook-validator"),
			thisBundle(),
			xprocspecBundles(),
			junitBundles()
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

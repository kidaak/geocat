package org.fao.geonet.services.main;

import com.google.common.base.Function;
import com.google.common.collect.Lists;

import jeeves.server.ServiceConfig;
import jeeves.server.context.ServiceContext;

import org.fao.geonet.domain.MetadataType;
import org.fao.geonet.kernel.mef.MEFLibIntegrationTest;
import org.fao.geonet.repository.MetadataRepository;
import org.fao.geonet.repository.specification.MetadataSpecs;
import org.fao.geonet.services.AbstractServiceIntegrationTest;
import org.fao.geonet.utils.IO;
import org.jdom.Element;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Test;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.annotation.DirtiesContext;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import javax.annotation.Nonnull;

import javax.annotation.Nullable;

import static org.fao.geonet.domain.Pair.read;
import static org.fao.geonet.services.main.SearchSuggestion.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

/**
 * Test the SearchSuggestion Service
 * Created by Jesse on 2/4/14.
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@ContextConfiguration(inheritLocations = true, locations = "classpath:suggestions-context.xml")
public class SearchSuggestionIntegrationTest extends AbstractServiceIntegrationTest {
    private static final SearchSuggestion searchSuggestionService = new SearchSuggestion();
    private ServiceContext context;

    @BeforeClass
    public static void initService() throws Exception {
        searchSuggestionService.init(IO.toPath("."), new ServiceConfig(Lists.newArrayList(
                createServiceConfigParam(CONFIG_PARAM_DEFAULT_SEARCH_FIELD, "any"),
                createServiceConfigParam(CONFIG_PARAM_MAX_NUMBER_OF_TERMS, "10000000"),
                createServiceConfigParam(CONFIG_PARAM_THRESHOLD, "1000")
        )));

    }

    @Before
    public void importSampleMetadata() throws Exception {
        this.context = createServiceContext();
        loginAsAdmin(context);

        final MEFLibIntegrationTest.ImportMetadata importMetadata = new MEFLibIntegrationTest.ImportMetadata(this, context);
        importMetadata.getMefFilesToLoad().add("mef1-example.mef");
        importMetadata.getMefFilesToLoad().add("mef2-example-2md.zip");
        importMetadata.invoke();

        assertEquals(4, context.getBean(MetadataRepository.class).count(MetadataSpecs.hasType(MetadataType.METADATA)));
    }

    @Test @Ignore
    public void testExec_INDEX_TERM_VALUES_sortBy_Frequency() throws Exception {
        final Element params = createParams(
                read(PARAM_FIELD, "any"),
                read(PARAM_Q, "Aus"),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, INDEX_TERM_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.FREQUENCY)
        );


        // GEOCAT changed expected number.  they values are not critical as they
        // are not currently the idea, but they are sufficient
        // Compared to geonetwork/develop it seems that a couple values might be missing
        List<Element> items = performQuery(params);
        assertEquals(Lists.transform(items, new Function<Element, Object>() {
            @Nullable
            @Override
            public Object apply(@Nonnull Element input) {
                return "'" + input.getAttributeValue(ATT_TERM) + "': (" + input.getAttributeValue(ATT_FREQ) + ")";
            }
        }).toString() + "Has different values than expected", 3, items.size());
        assertDecreasingFrequency(items);

        params.getChild(PARAM_Q).setText("vic");
        items = performQuery(params);
        assertEquals(6, items.size());
        // end GEOCAT

        params.getChild(PARAM_Q).setText("vic*");
        items = performQuery(params);
        assertEquals(4, items.size());
        for (Element item : items) {
            assertTrue(item.getAttributeValue(ATT_TERM).startsWith("vic"));
        }
    }

    @Test
    public void testExec_INDEX_TERM_VALUES_sortBy_STARTSWITHFIRST() throws Exception {
        final Element params = createParams(
                read(PARAM_FIELD, "any"),
                read(PARAM_Q, "Aus"),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, INDEX_TERM_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.STARTSWITHFIRST)
        );

        final String searchTerm = "vic";
        params.getChild(PARAM_Q).setText(searchTerm);
        List<Element> items = performQuery(params);
        assertEquals(6, items.size());

        boolean startsWith = true;
        for (Element item : items) {
            String term = item.getAttributeValue(ATT_TERM);
            if (!startsWith) {
                assertFalse(term.startsWith(searchTerm));
            } else {
                startsWith = term.startsWith(searchTerm);
            }
        }
    }

    @Test
    public void testExec_INDEX_TERM_VALUES_sortBy_ALPHA() throws Exception {
        final Element params = createParams(
                read(PARAM_FIELD, "any"),
                read(PARAM_Q, "Aus"),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, INDEX_TERM_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.ALPHA)
        );

        final String searchTerm = "vic";
        params.getChild(PARAM_Q).setText(searchTerm);
        List<Element> items = performQuery(params);
        assertEquals(6, items.size());

        String lastTerm = null;
        for (Element item : items) {
            String term = item.getAttributeValue(ATT_TERM);
            if (lastTerm != null) {
                assertTrue(lastTerm.compareTo(term) < 1);
            }
            lastTerm = term;
        }
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_sortBy_FREQUENCY() throws Exception {
        final String searchTerm = "*a*";
        final Element params = createParams(
                read(PARAM_FIELD, "title"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.FREQUENCY)
        );

        List<Element> items = performQuery(params);
        assertEquals(3, items.size());
        assertDecreasingFrequency(items);
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_sortBy_ALPHA() throws Exception {
        final String searchTerm = "*a*";
        final Element params = createParams(
                read(PARAM_FIELD, "title"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.ALPHA)
        );

        List<Element> items = performQuery(params);

        assertEquals(3, items.size());
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_sortBy_STARTSWITHFIRST() throws Exception {
        final String searchTerm = "*wa*";
        final Element params = createParams(
                read(PARAM_FIELD, "keyword"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.STARTSWITHFIRST)
        );

        List<Element> items = performQuery(params);

        assertEquals(3, items.size());
        final String item = items.get(0).getAttributeValue(ATT_TERM).toLowerCase();
        final String item2 = items.get(1).getAttributeValue(ATT_TERM).toLowerCase();
        final String item3 = items.get(2).getAttributeValue(ATT_TERM).toLowerCase();
        assertTrue(item.startsWith("wa"));
        assertTrue(item2.startsWith("wa"));
        assertFalse(item3.startsWith("wa"));
        assertTrue(item3.contains("wa"));
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_Any() throws Exception {
        final String searchTerm = "*00*";
        final Element params = createParams(
                read(PARAM_FIELD, "any"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.STARTSWITHFIRST)
        );

        List<Element> items = performQuery(params);
        for (Element item : items) {
            assertTrue(item.getAttributeValue(ATT_TERM).contains("00"));
        }
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_No_duplicates() throws Exception {
        final String searchTerm = "*";
        final Element params = createParams(
                read(PARAM_FIELD, "any"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.STARTSWITHFIRST)
        );

        List<Element> items = performQuery(params);

        Set<String> encountered  = new HashSet<String>();
        for (Element el : items) {
            String value = el.getAttributeValue(ATT_TERM);
            assertFalse (value + " is a duplicate", encountered.contains(value));
            encountered.add(value);
        }
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_sortBy_FREQUENCY_NoFilter() throws Exception {
        final String searchTerm = "*";
        final Element params = createParams(
                read(PARAM_FIELD, "keyword"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 1),
                read(PARAM_SORT_BY, SORT_BY_OPTION.FREQUENCY)
        );

        List<Element> items = performQuery(params);
//        for (Element item : items) {
//            System.out.println(item.getAttributeValue(SearchSuggestion.ATT_TERM));
//        }
        assertEquals(10, items.size());
        assertDecreasingFrequency(items);
    }

    @Test
    public void testExec_RECORDS_FIELD_VALUES_THRESHHOLD() throws Exception {
        final String searchTerm = "*";
        final Element params = createParams(
                read(PARAM_FIELD, "keyword"),
                read(PARAM_Q, searchTerm),
                read(PARAM_MAX_NUMBER_OF_TERMS, 100000),
                read(PARAM_ORIGIN, RECORDS_FIELD_VALUES),
                read(PARAM_THRESHOLD, 2),
                read(PARAM_SORT_BY, SORT_BY_OPTION.FREQUENCY)
        );

        List<Element> items = performQuery(params);
        assertEquals(1, items.size());
        assertEquals("test", items.get(0).getAttributeValue(ATT_TERM));
    }

    private List<Element> performQuery(Element params) throws Exception {
        Element result;
        List<Element> items;
        result = searchSuggestionService.exec(params, context);

        items = result.getChildren(ELEM_ITEM);
        return items;
    }

    private void assertDecreasingFrequency(List<Element> items) {
        int lastFrequency = Integer.MAX_VALUE;

        boolean hasMoreThanOneFrequency = false;

        for (Element item : items) {
            int frequency = Integer.parseInt(item.getAttributeValue(ATT_FREQ));
            String term = item.getAttributeValue(ATT_TERM);
//            System.out.println(term +" -> "+frequency);
            hasMoreThanOneFrequency |= lastFrequency != Integer.MAX_VALUE && frequency != lastFrequency;

            assertTrue(frequency <= lastFrequency);
            assertNotNull(term);
            lastFrequency = frequency;
        }

        assertTrue(hasMoreThanOneFrequency);
    }
}

//=============================================================================
//===	Copyright (C) 2001-2014 Food and Agriculture Organization of the
//===	United Nations (FAO-UN), United Nations World Food Programme (WFP)
//===	and United Nations Environment Programme (UNEP)
//===
//===	This program is free software; you can redistribute it and/or modify
//===	it under the terms of the GNU General Public License as published by
//===	the Free Software Foundation; either version 2 of the License, or (at
//===	your option) any later version.
//===
//===	This program is distributed in the hope that it will be useful, but
//===	WITHOUT ANY WARRANTY; without even the implied warranty of
//===	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//===	General Public License for more details.
//===
//===	You should have received a copy of the GNU General Public License
//===	along with this program; if not, write to the Free Software
//===	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
//===
//===	Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
//===	Rome - Italy. email: geonetwork@osgeo.org
//==============================================================================

package org.fao.geonet.kernel.search.index;

import jeeves.transaction.TransactionManager;
import jeeves.transaction.TransactionTask;
import org.fao.geonet.ApplicationContextHolder;
import org.fao.geonet.constants.Geonet;
import org.fao.geonet.kernel.DataManager;
import org.fao.geonet.kernel.search.SearchManager;
import org.fao.geonet.utils.Log;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.scheduling.quartz.QuartzJobBean;
import org.springframework.transaction.TransactionStatus;

import java.io.IOException;
import java.util.Date;
import java.util.Set;

/**
 * A task which runs every X sec in order to reindex
 * a set of metadata records which have been modified and
 * that indexing could be done a bit later (eg. when popularity
 * is updated, immediate indexing is not required).
 * <p/>
 * See configuration in config-spring-geonetwork.xml for interval.
 * <p/>
 * Created by francois on 7/29/14.
 */
public class IndexingTask extends QuartzJobBean {

    @Autowired
    private ConfigurableApplicationContext applicationContext;
    @Autowired
    private DataManager _dataManager;


    private void indexRecords() {
        ApplicationContextHolder.set(applicationContext);
        TransactionManager.runInTransaction("IndexingTask", applicationContext,
                TransactionManager.TransactionRequirement.CREATE_NEW,
                TransactionManager.CommitBehavior.ALWAYS_COMMIT, false, new TransactionTask<Void>() {
                    @Override
                    public Void doInTransaction(TransactionStatus transaction) throws Throwable {
                        IndexingList list = applicationContext.getBean(IndexingList.class);
                        Set<Integer> metadataIdentifiers = list.getIdentifiers();
                        if (metadataIdentifiers.size() > 0) {
                            if (Log.isDebugEnabled(Geonet.INDEX_ENGINE)) {
                                Log.debug(Geonet.INDEX_ENGINE, "Indexing task / List of records to index: "
                                                               + metadataIdentifiers.toString() + ".");
                            }

                            for (Integer metadataIdentifier : metadataIdentifiers) {
                                try {
                                    _dataManager.indexMetadata(String.valueOf(metadataIdentifier), false);
                                } catch (Exception e) {
                                    Log.error(Geonet.INDEX_ENGINE, "Indexing task / An error happens indexing the metadata "
                                                                   + metadataIdentifier + ". Error: " + e.getMessage(), e);
                                }
                            }

                            try {
                                applicationContext.getBean(SearchManager.class).forceIndexChanges();
                            } catch (IOException e) {
                                Log.error(Geonet.INDEX_ENGINE, "Error forcing index changes", e);
                            }
                        }
                        return null;
                    }
                });
    }

    @Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
        if (Log.isDebugEnabled(Geonet.INDEX_ENGINE)) {
            Log.debug(Geonet.INDEX_ENGINE, "Indexing task / Start at: "
                    + new Date() + ". Checking if any records need to be indexed ...");
        }
        indexRecords();
    }
}

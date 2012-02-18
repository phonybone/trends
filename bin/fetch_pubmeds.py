'''
get all geo objects that have a pubmed id
fetch the info from NCBI using a Pubmed object
store the info
'''
import sys, os, time
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from GEO.pubmed import Pubmed
from GEO.Series import Series
from GEO.Dataset import Dataset
from warn import *

for cls in [Series, Dataset]:
    cursor=cls.mongo().find({'pubmed_id': {'$ne':'null'}})
    warn("%s: %d records" % (cls.__name__, cursor.count()))
    n=0
    for record in cursor:
        if 'pubmed_id' not in record: continue
        pmids=record['pubmed_id']
        if type(pmids) != type([]):
            pmids=[pmids]
        for pmid in [int(x) for x in pmids]:
            warn("%s -> %d" % (record['geo_id'], pmid))
            pubmed=Pubmed(pmid)
            try: 
                pubmed.store()      # does the fetching automatically
                n+=1
            except Exception as e:
                warn("caught %s" % (e))
#        time.sleep(2)
                
        warn("%s: %d records with pubmed ids" % (cls.__name__, n))

'''
get all geo objects that have a pubmed id
fetch the info from NCBI using a Pubmed object
store the info

usage: python fetch_pubmeds.py [-f <id_file>] [-n] [-fuse <n>]
'''

import sys, os, time, re
from optparse import OptionParser

sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))
from GEO.pubmed import Pubmed
from GEO.Series import Series
from GEO.Dataset import Dataset
from GEO.Factory import Factory
from warn import *

def main(options):
    warn("getting pmid list..." % ())
    idlist=get_pmidlist(options)
    warn("processing %d ids: %s" % (len(idlist), idlist))
    if options.dry_run: exit(0)

    fuse=options.fuse
    for pmid in idlist:
        pubmed=Pubmed(pmid)
        warn("pmid is %s" % (pmid))
        continue
        try: 
            pubmed.store()      # does the fetching automatically
        except Exception as e:
            warn("%d: caught %s" % (pmid, e))

        fuse-=1
        if (fuse==0): break
                
    exit(0)


def get_pmidlist(options):
    if len(options.idlist) > 0:
        pmidlist=_getlist2pmidlist(options.idlist)
    else:                       
        pmidlist=_all_geo_pmids()
    return pmidlist


def _geolist2pmidlist(geo_ids):
    ''' converts a list of mixed pmids and geo_ids to all pmids by doing the lookups on the geo objects '''
    pmidlist=[]
    for id in geo_ids:
        if re.match('^\d+$', id):
            pmidlist.append(id)
        else:
            try:
                geo=Factory().newGEO(id)
                pmids=geo.pubmed_id # might be single value or list, so:
            except Exception as e: 
                warn("caught %s" % (e))
                continue    # id not a geo id, or geo didn't have any pubmed_id
            
            try: pmidlist.append(pmids)
            except: pmidlist.extend(pmids)
    return pmidlist

def _all_geo_pmids():
    ''' gets pmids from all geo objects in the db: '''
    pmidlist=[]
    for cls in [Series, Dataset]:
        cursor=cls.mongo().find({'pubmed_id': {'$ne':'null'}})
        for record in cursor:
            if 'pubmed_id' in record: 
                pmids=record['pubmed_id']
                if type(pmids)==type([]):
                    pmidlist.extend([int(x) for x in pmids])
                else:
                    pmidlist.append[int(pmids)]
                warn("pmids are %s" % (pmids))

    return pmidlist



if __name__ == '__main__':
    def id_file_callback(option, opt, value, parser, *args, **kwargs):
        warn("options is %s" % (option))
        warn("opt is %s" % (opt))
        warn("value is %s" % (value))
        warn("args are %s" % (args))
        warn("kwargs are %s" % (kwargs))

        f=open(value)
        idlist=[x for x in f if type(x) == int]
        f.close()
        parser.values.idlist.extend(idlist)



    parser=OptionParser()
    parser.add_option('-f', '--id_file', action='callback', callback=id_file_callback, help='file containing list of ids')
    parser.add_option('-n', '--dry-run', dest='dry_run', action='store_true', default=False, help='do not actually store/fetch any ids')
    parser.add_option('--fuse', dest='fuse', type='int', default=-1, help='debugging fuse (limits iterations in main loop)')
    
    (options, args)=parser.parse_args()
    warn("options are %s" % (options))
    warn("args are %s" % (args))
    if hasattr(options, 'idlist'):
        options.idlist.extend(args)
    else:
        options.idlist=args

    
    main(options)

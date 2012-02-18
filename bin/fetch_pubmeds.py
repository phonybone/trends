'''
get all geo objects that have a pubmed id
fetch the info from NCBI using a Pubmed object
store the info
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

    idlist=get_pmidlist(options)
    warn("processing %d ids: %s" % (len(idlist), idlist))
    if options.dry_run: exit(0)

    fuse=options.fuse
    for pmid in idlist:
        pubmed=Pubmed(pmid)
        try: 
            pubmed.store()      # does the fetching automatically
        except Exception as e:
            warn("caught %s" % (e))

        fuse-=1
        if (fuse==0): break
                
    exit(0)


def get_pmidlist(options):
    pmidlist=[]

    warn("options.idlist is %s" % (options.idlist))
    if len(options.idlist) > 0:
        for id in options.idlist:
            if re.match('^\d+$', id):
                pmidlist.append(id)
            else:
                try:
                    geo=Factory().newGEO(id)
                    pmids=geo.pubmed_id # might be single value or list, so:
                except Exception as e: 
                    warn("caught %s" % (e))
                    continue    # id not a geo id, or geo didn't have any pubmed_id

                warn("adding to pmidlist: %s" % (pmids))
                try: pmidlist.append(pmids)
                except: pmidlist.extend(pmids)


    else:                       # grab everything from the db:
        for cls in [Series, Dataset]:
            cursor=cls.mongo().find({'pubmed_id': {'$ne':'null'}})
            for record in cursor:
                if 'pubmed_id' in record: 
                    pmids=record['pubmed_id']
                    try: pmidlist.extend(pmids)
                    except: pmidlist.append(pmids)

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
    if hasattr(options, 'ids'):
        options.idlist.extend(args)
    else:
        options.idlist=args

    
    main(options)

import sys, os
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO
from GEO.word2geo import Word2Geo
from warn import *
from GEO.Factory import Factory

def main():
    options=get_options()
    geo_ids=get_geo_ids(options)
    f=Factory()

    fuse=options.fuse
    for geo_id in geo_ids:
        geo=f.newGEO(geo_id)
        warn("inserting %s" % (geo.geo_id))
        stats=Word2Geo.insert_geo(geo)
        warn("%s: %s" % (geo_id, stats))
        fuse-=1
        if (fuse==0): break

    return 0

def get_options():
    from optparse import OptionParser
    def set_debug(option, opt, value, parser):
        os.environ['DEBUG']='True'
        return                  # indent fixer

    parser=OptionParser()
    parser.add_option('--fuse', dest='fuse', type='int', default=-1, help='debugging fuse (limits iterations in main loop)')
    parser.add_option('-d', '--debug', action='callback', callback=set_debug)

    (options, args)=parser.parse_args()
    try:    options.idlist.extend(args) # this will never happen as yet
    except: options.idlist=args
    return options
    

def get_geo_ids(options):
    if len(options.idlist): return options.idlist

    geo_ids=[]
    for cls in [GEO.Series.Series, GEO.Dataset.Dataset, GEO.DatasetSubset.DatasetSubset]:
        cursor=cls.mongo().find({}, {'_id':0, 'geo_id':1})
        warn("got %d %s records" % (cursor.count(), cls.__name__))
        for record in cursor:
            geo_ids.append(record['geo_id'])
    return geo_ids


main()


    

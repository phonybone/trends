import sys, os
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO
from GEO.word2geo import Word2Geo
from warn import *

for cls in [GEO.Series.Series, GEO.Dataset.Dataset, GEO.DatasetSubset.DatasetSubset]:
    cursor=cls.mongo().find()
    warn("got %d %s records" % (cursor.count(), cls.__name__))
    for record in cursor:
        geo=cls(record)
        warn("inserting %s" % (geo.geo_id))
        Word2Geo.insert_geo(geo)

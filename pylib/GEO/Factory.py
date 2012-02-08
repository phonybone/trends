from warn import *

import Sample
import Dataset
import Series
import Platform

class Factory(object):
    prefix2class={'GSM' : Sample.Sample, 'GDS': Dataset.Dataset, 'GSE' : Series.Series, 'GPL' : Platform.Platform}
    
    def id2class(self, geo_id):
        prefix=geo_id[0:3]
        try: klass=self.prefix2class[prefix]
        except KeyError: raise Exception("No class for prefix '%s'" % prefix)
        return klass

    def newGEO(self, geo_id):
        warn("newGEO: geo_id=%s" % (geo_id))
        return self.id2class(geo_id)(geo_id).populate()
        

#warn("%s checking in" % __file__)

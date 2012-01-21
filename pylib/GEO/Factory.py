from Series import Series
from Sample import Sample
from Dataset import Dataset
from Platform import Platform
from warn import *

class Factory(object):
    prefix2class={'GSM' : Sample, 'GDS': Dataset, 'GSE' : Series, 'GPL' : Platform}
    
    def id2class(self, geo_id):
        prefix=geo_id[0:3]
        try: klass=self.prefix2class[prefix]
        except KeyError: raise Exception("No class for prefix '%s'" % prefix)
        return klass

    def newGEO(self, geo_id):
        return self.id2class(geo_id)(geo_id).populate()
        


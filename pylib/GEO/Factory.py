import re
from Series import Series
from Sample import Sample
from Dataset import Dataset
from Platform import Platform
from warn import *

class Factory(object):
    prefix2class={'GSM' : Sample, 'GDS': Dataset, 'GSE' : Series, 'GPL' : Platform}
    
    def newGEO(self, geo_id):
        prefix=geo_id[0:3]
        try: klass=self.prefix2class[prefix]
        except KeyError: raise Exception("No class for prefix '%s'" % prefix)
        return klass(geo_id)

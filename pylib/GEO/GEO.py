from Mongoid import Mongoid
from warn import *

# from Series import Series       # this finds the right file...
# from GEO.Dataset import Dataset
# from GEO.Sample import Sample
# from GEO.Platform import Platform

import re

class GEO(Mongoid):
    db_name='geo'
    data_dir='/mnt/price1/vcassen/trends/data/GEO'

    def __init__(self,geo_id):
        ''' can initialize a geo object with either a geo_id or a dict '''
        record=None
        if isinstance(geo_id, dict):
            record=geo_id
            if 'geo_id' not in record:
                raise ProgrammerGoof('no geo_id')
            geo_id=record['geo_id']

        self.geo_id=geo_id
        if isinstance(record, dict):
            for (k,v) in record.items():
                setattr(self,k,v)

    def populate(self):
        ''' populate a geo object from the database '''
        record=self.mongo().find_one({'geo_id':self.geo_id})
        if isinstance(record, dict):
            for (k,v) in record.items():
                setattr(self,k,v)
        return self
        

    def id2class(self, geo_id=None):
        if geo_id == none: geo_id=self.geo_id
        mg=re.search('^G\w\w', geo_id)
        if not mg: raise Exception("Unknown geo_id: %s" % geo_id)
        prefix=mg.groups(0)
        try: return self.prefix2class(prefix)
        except KeyError: raise Exception("no class for prefix '%s'" % prefix)

    

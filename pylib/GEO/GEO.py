import os
from Mongoid import Mongoid
from warn import *

# from Series import Series       # this finds the right file...
# from GEO.Dataset import Dataset
# from GEO.Sample import Sample
# from GEO.Platform import Platform

import re

class GEO(Mongoid):
    db_name='geo'
    data_dir=os.path.join(os.environ['TRENDS_HOME'], 'data', 'GEO')

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

    def populate(self, record=None):
        ''' populate a geo object from a dict or the database '''
        if record==None:
            record=self.mongo().find_one({'geo_id':self.geo_id})
        if isinstance(record, dict):
            for (k,v) in record.items():
                setattr(self,k,v)
        return self
        
    

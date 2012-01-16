from Mongoid import Mongoid
from warn import *

class GEO(Mongoid):
    db_name='geo'
    data_dir='/mnt/price1/vcassen/trends/data/GEO'

    def __init__(self,geo_id):
        ''' can initialize a geo object with either a geo_id or a dict'''
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
        record=self.mongo().find_one({'geo_id':self.geo_id})
        if isinstance(record, dict):
            for (k,v) in record.items():
                setattr(self,k,v)
        return self
        

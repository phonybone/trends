import os, re
from GEO import GEO
from warn import *

class Dataset(GEO):
    subdir='datasets'
    collection_name='datasets'

    def soft_file(self):
        return os.path.join(self.data_dir, self.subdir, '.'.join([self.geo_id, 'soft']))

        

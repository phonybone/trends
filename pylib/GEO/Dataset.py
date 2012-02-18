import os
import GEOBase

class Dataset(GEOBase.GEOBase):
    subdir='datasets'
    collection_name='datasets'

    def soft_file(self):
        return os.path.join(self.data_dir, self.subdir, '.'.join([self.geo_id, 'soft']))

        
#print "%s checking in" % __file__

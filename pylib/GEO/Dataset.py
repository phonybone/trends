import os
import GEOBase
from DatasetSubset import DatasetSubset
from warn import *

class Dataset(GEOBase.GEOBase):
    subdir='datasets'
    collection_name='datasets'

    def soft_file(self):
        return os.path.join(self.data_dir, self.subdir, '.'.join([self.geo_id, 'soft']))

    def subsets(self):
        if not hasattr(self, 'n_subsets'):
            if 'DEBUG' in os.environ: warn("%s: no subsets?" % (self.geo_id))
            return []

        subsets=[]
        for i in range(1,int(self.n_subsets)+1):
            subset_id="%s_%d" % (self.geo_id, i)
            subsets.append(DatasetSubset(subset_id).populate())
        return subsets

    def samples(self):
        samples=[]
        for ss in self.subsets():
            samples.extend(ss.samples())
        return samples
        
#print "%s checking in" % __file__

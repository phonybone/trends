import GEOBase
from Sample import Sample

class DatasetSubset(GEOBase.GEOBase):
    collection_name='dataset_subsets'

    def samples(self):
        samples=[]
        if hasattr(self, 'sample_ids'):
            for sample_id in self.sample_ids:
                samples.append(Sample(sample_id).populate())
        return samples

#print "%s checking in" % __file__

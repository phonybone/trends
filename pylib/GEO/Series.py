import GEOBase
from Sample import Sample
from Dataset import Dataset

class Series(GEOBase.GEOBase):
    collection_name='series'
    subdir='series'

    def samples(self):
        samples=[]
        if hasattr(self, 'sample_id'):
            for geo_id in self.sample_id:
                samples.append(Sample(geo_id).populate())

        elif hasattr(self, 'dataset_ids'):
            for ds in self.datasets():
                samples.extend(ds.samples())

        return samples
            

    def datasets(self):
        datasets=[]
        for geo_id in self.dataset_ids:
            datasets.append(Dataset(geo_id).populate())
        return datasets


        
    

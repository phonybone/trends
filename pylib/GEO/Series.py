import GEOBase
from Sample import Sample

class Series(GEOBase.GEOBase):
    collection_name='series'
    subdir='series'

    def samples(self):
        samples=[]
        for geo_id in self.sample_id:
            samples.append(Sample(geo_id))
        return samples



        
    

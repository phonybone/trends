import os, re
from GEO import GEO
from warn import *

class Sample(GEO):
    id_types2suffix={'probe':'table.data', 'gene':'data'}
    subdir='sample_data'
    collection_name='samples'


    @classmethod
    def all_ids_with_data(self, **kwargs):
        ''' 
        Return a list of Sample objects for which data (of a type) has been downloaded 
        Faster just to look through filesystem?
        '''
        try: id_type=kwargs['id_type']
        except KeyError: id_type='probe'
        
        try: suffix=self.id_types2suffix[id_type]
        except KeyError: raise ProgrammerGoof("'%s' unknown id_type" % id_type)

        sample_ids=[]
        cursor=self.mongo().find({}, {'geo_id':1})
#        warn("all_with_data: got %d total records" % cursor.count())
        while (True):
            try: record=cursor.next()
            except StopIteration: break
            kwargs['geo_id']=record['geo_id']
            if os.access(Sample.data_path_of(**kwargs), os.R_OK):
                sample_ids.append(record['geo_id'])

        return sample_ids

    @classmethod
    def all_ids_with_pheno(self, pheno):
        cursor=self.mongo().find({'phenotype':pheno}, {'geo_id':1})
        ids=[x['geo_id'] for x in cursor]
        return ids

    @classmethod
    def data_path_of(self, **kwargs):
        try: geo_id=kwargs['geo_id']
        except KeyError:
            if isinstance(self, Sample): geo_id=self.geo_id                
            else: raise ProgrammerGoof("no geo_id")
        
        mg=re.match("GSM\d\d?\d?", geo_id)
        prefix=mg.group(0)
        if not prefix: raise Exception("invalid gsm id: '%s'" % geo_id)
        
        try: suffix=self.id_types2suffix[kwargs['id_type']]
        except KeyError: suffix=self.id_types2suffix['probe']

        return os.path.join(self.data_dir, self.subdir, prefix, '.'.join([geo_id, suffix]))

    def data_path(self, **kwargs):
        kwargs['geo_id']=self.geo_id
        return self.__class__.data_path_of(**kwargs)


    ########################################################################
    # Return a matrix (would be best to return a DataTable from AUREA) such that
    # 

    @classmethod
    def one_vs_all(self, **kwargs):
        pass

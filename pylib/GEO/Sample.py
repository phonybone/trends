import os, re

from warn import *
import Factory                  # imports the module
import GEOBase

class Sample(GEOBase.GEOBase):
    id_types2suffix={'probe':'table.data', 'gene':'data'}
    subdir='sample_data'
    collection_name='samples'

    def __init__(self, geo_id):
        super(Sample, self).__init__(geo_id)
        self.data={'probe':None, 'gene':None}


    # this one starts by looking in the db...
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
            except StopIteration: break # god python can be irritating (unless I'm doing this wrong?)
            if os.access(Sample.data_path_of(geo_id=record['geo_id']), os.R_OK):
                sample_ids.append(record['geo_id'])

        return sample_ids

    # ...and this one starts by looking in the file system.
    @classmethod
    def all_with_data(self, **kwargs):
        '''
        Return a list of sample objects that have the given id_type stored on disk.
        Doesn't populate the sample objects unless requested.
        Can also return a list of ids:
        '''
        try: id_type=kwargs['id_type']
        except KeyError: id_type='probe'
        suffix=self.id_types2suffix[id_type]
        samples=[]

        sample_dir=os.path.join(self.data_dir(), self.subdir)
        for root, dirs, files in os.walk(sample_dir):
            for file in files:
                if file.endswith(suffix):
                    sample_id=file.split('.')[0]
                    if 'ids_only' in kwargs:
                        samples.append(sample_id)
                    else:
                        sample=Sample(sample_id)
                        if 'populate' in kwargs: sample.populate()
                        samples.append(sample)
        return samples

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
        if not mg: raise Exception("invalid gsm id: '%s'" % geo_id)
        prefix=mg.group(0)
        if not prefix: raise Exception("invalid gsm id: '%s'" % geo_id)
        
        try: suffix=self.id_types2suffix[kwargs['id_type']]
        except KeyError: suffix=self.id_types2suffix['probe']

        filename=os.path.join(self.data_dir(), self.subdir, prefix, '.'.join([geo_id, suffix]))
        return filename

    def data_path(self, **kwargs):
        kwargs['geo_id']=self.geo_id
        return self.__class__.data_path_of(**kwargs)


    ########################################################################
    
    def expression_data(self, id_type='gene'):
        ''' 
        if id_type == None, choose one based on which data exists
        return (id_type, data) where data is a dict: k=id, v=expression value
        raises exceptions on errors, so be careful
        '''

        # determine id_type if necessary, checking for existance as well:
        if id_type == None:
            id_type=self._get_id_type()
        if not re.search('^gene|probe$', id_type):
            raise Exception('id_type must be one of "gene" or "probe"')


        # open data file:
        data_file=open(self.data_path(id_type=id_type), 'r')
        if id_type == 'probe': 
            burn_line=data_file.readline()
            burn_line=data_file.readline()

        # read data and store to dict:
        data={}
        for line in data_file:
            l=re.split('[,\s]+', line)
            if l[0] in data:
                warn("Sample.expression_data: overwriting %s %f->%f" % (l[0], data[l[0]], l[1]))
            data[l[0]]=float(l[1])
        data_file.close()

        return (id_type, data)

    def _get_id_type(self):
        if os.access(self.data_path(id_type='gene'), os.R_OK):
            id_type='gene'
        elif os.access(self.data_path(id_type='probe'), os.R_OK):
            id_type='probe'
        else:
            raise Exception("No data for sample %s" % self.geo_id)


    ########################################################################
    def descriptions(self):
        ''' return a dictionary containing all related descriptions to the sample. '''
        descs={}
        if hasattr(self, 'description'):
            if type(self.description) == type([]):
                descs[self.geo_id]=', '.join(self.description)
            else:
                descs[self.geo_id]=self.description # assume str

#        warn("Sample.py: Factory is %s" % Factory)
        f=Factory.Factory()
#        f=Factory()
        for attr in ['series_ids', 'dataset_ids', 'subset_ids']:
            if hasattr(self, attr):
                for geo_id in getattr(self, attr):
                    geo=f.newGEO(geo_id)
                    try: descs[geo_id]=geo.description
                    except AttributeError: pass
        return descs

        

    ########################################################################
    @classmethod
    def with_pheno(self, pheno):
        samples=[]
        for record in self.mongo().find({'phenotype':pheno}):
            samples.append(self(record['geo_id']).populate(record=record))
        return samples


#print "%s checking in" % __file__

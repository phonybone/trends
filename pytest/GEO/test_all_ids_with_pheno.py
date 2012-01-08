import unittest, sys, os
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../..")
sys.path.append(os.path.join(dir+'/pylib'))

from warn import *
from GEO.Sample import Sample

class TestAllIdsWithPheno(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_all_ids_with_pheno(self):
        pheno='normal'
        ids=Sample.all_ids_with_pheno(pheno)
        self.assertIsInstance(ids, list)
        warn("got %d '%s' samples" % (len(ids), pheno))

        ids_with_data=[x for x in ids if os.access(Sample.data_path_of(geo_id=x), os.R_OK)]
        warn("got %d '%s' samples with data" % (len(ids_with_data), pheno))


suite = unittest.TestLoader().loadTestsFromTestCase(TestAllIdsWithPheno)
unittest.TextTestRunner(verbosity=2).run(suite)


        


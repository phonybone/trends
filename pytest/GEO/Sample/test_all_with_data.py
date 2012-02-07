import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.Sample import Sample

class TestAllWithData(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_all_with_data_probe(self):
        samples=Sample.all_with_data(id_type='probe')
        warn("got %d 'probe' samples" % (len(samples)))
        self.assertTrue(len(samples)>1)

    def test_all_with_data_gene(self):
        samples=Sample.all_with_data(id_type='gene')
        warn("got %d 'gene' samples" % (len(samples)))
        self.assertTrue(len(samples)>1)



suite = unittest.TestLoader().loadTestsFromTestCase(TestAllWithData)
unittest.TextTestRunner(verbosity=2).run(suite)


        


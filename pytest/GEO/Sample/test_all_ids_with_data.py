import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.Sample import Sample

class TestAllIdsWithData(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_all_ids_with_data(self):
        ids=Sample.all_ids_with_data(id_type='probe')
        warn("len(ids)=%d" % (len(ids)))
        self.assertTrue(len(ids) > 1000)


suite = unittest.TestLoader().loadTestsFromTestCase(TestAllIdsWithData)
unittest.TextTestRunner(verbosity=2).run(suite)


        


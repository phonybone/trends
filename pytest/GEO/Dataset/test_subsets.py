import unittest, sys, os

sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from GEO.Dataset import Dataset
from warn import *

class TestStub(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_something(self):
        geo_id='GDS3257'
        ds=Dataset(geo_id).populate()
        self.assertTrue(int(ds.n_subsets) == 9)
        
        subsets=ds.subsets()
        for ss in subsets:
            self.assertRegexpMatches(ss.geo_id, '%s_\d' % geo_id)



suite = unittest.TestLoader().loadTestsFromTestCase(TestStub)
unittest.TextTestRunner(verbosity=2).run(suite)


        


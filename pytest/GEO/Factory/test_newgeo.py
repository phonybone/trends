import unittest, sys, os, re
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))


from warn import *
from GEO import Factory
from GEO.Series import Series
from GEO.Sample import Sample
from GEO.Dataset import Dataset
from GEO.Platform import Platform

class TestNewGEO(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_new_geo(self):
        f=Factory.Factory()
        geo_id='GSE00001'
        s=f.newGEO(geo_id)
        self.assertIsInstance(s, Series)



suite = unittest.TestLoader().loadTestsFromTestCase(TestNewGEO)
unittest.TextTestRunner(verbosity=2).run(suite)


        


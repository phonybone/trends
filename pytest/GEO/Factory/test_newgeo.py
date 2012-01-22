import unittest, sys, os, yaml
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.Factory import Factory
from GEO.Series import Series
from GEO.Sample import Sample
from GEO.Dataset import Dataset
from GEO.Platform import Platform

class TestNewGEO(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_new_geo(self):
        f=Factory()
        pairs={'GSE10072':Series,
               'GSM15718':Sample,
               'GDS994':Dataset,
               'GPL96':Platform
               }

        for geo_id, geo_class in pairs.items():
            geo=f.newGEO(geo_id)
            self.assertIsInstance(geo, geo_class)
            self.assertEqual(geo.geo_id, geo_id)

        


suite = unittest.TestLoader().loadTestsFromTestCase(TestNewGEO)
unittest.TextTestRunner(verbosity=2).run(suite)


        


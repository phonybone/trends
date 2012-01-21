import unittest, sys, os, yaml
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.Factory import Factory
from GEO.Series import Series

class TestNewGEO(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_new_geo(self):
        f=Factory()
        geo_id='GSE10072'
        s=f.newGEO(geo_id)
        self.assertIsInstance(s, Series)
        self.assertEqual(s.geo_id, 'GSE10072')
#        warn("series is %s" % yaml.dump(s))


suite = unittest.TestLoader().loadTestsFromTestCase(TestNewGEO)
unittest.TextTestRunner(verbosity=2).run(suite)


        


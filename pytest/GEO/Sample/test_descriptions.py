import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO
from warn import *
from GEO.Factory import Factory
from GEO.Sample import Sample

class TestDescriptions(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_descs(self):
        geo_id='GSM32100'
        f=Factory()
        sample=f.newGEO(geo_id)
        self.assertIsInstance(sample, Sample)
        self.assertEqual(sample.geo_id, geo_id)

        descs=sample.descriptions()
        self.assertIsInstance(descs, dict)
#        import yaml
#        print "sample is %s" % yaml.dump(sample)



suite = unittest.TestLoader().loadTestsFromTestCase(TestDescriptions)
unittest.TextTestRunner(verbosity=2).run(suite)


        


import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO.Series import Series
from GEO.Sample import Sample

class TestSamples(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_samples(self):
        series=Series('GSE10072').populate()
        samples=series.samples()
        self.assertEqual(len(samples), 107)
        


suite = unittest.TestLoader().loadTestsFromTestCase(TestSamples)
unittest.TextTestRunner(verbosity=2).run(suite)


        


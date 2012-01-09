import unittest, sys, os
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../..")
sys.path.append(os.path.join(dir+'/pylib'))

from warn import *
from GEO import GEO
from GEO.Sample import Sample

class TestStub(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_something(self):
        geo_id='GSM254636'
        sample=Sample(geo_id)
        self.assertIsInstance(sample, Sample)

        dv=sample.data_vector(id_type='probe')
        self.assertIs(dv['1255_g_at'], 5.154619664)
        self.assertIs(dv['1320_at'], 6.135287036)




suite = unittest.TestLoader().loadTestsFromTestCase(TestStub)
unittest.TextTestRunner(verbosity=2).run(suite)


        


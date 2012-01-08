import unittest, sys, os
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../..")
sys.path.append(os.path.join(dir+'/pylib'))

from warn import *
from GEO import GEO
from GEO.Sample import Sample

class TestOneVsAll(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_bad_id_type(self):
        self.assertRaises(ProgrammerGoof, Sample.all_ids_with_data, id_type='monkey')

    def test_all_ids_with_data(self):
        for id_type in ['probe', 'gene']:
            warn("calling Sample.all_ids_with_data(id_type='%s'...)" % id_type)
            all_samples=Sample.all_ids_with_data(id_type='probe')

            self.assertIsInstance(all_samples, list)
            self.assertIn('GSM32106', all_samples) # it's in both lists
            self.assertNotIn('GSM1', all_samples)

suite = unittest.TestLoader().loadTestsFromTestCase(TestOneVsAll)
unittest.TextTestRunner(verbosity=2).run(suite)


        


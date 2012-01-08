import unittest, sys, os
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../../..")
sys.path.append(os.path.join(dir+'/pylib'))

from warn import *
from GEO.Sample import Sample

class TestInit(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_init_geo_id(self):
        geo_id='GSM30429'
        s1=Sample(geo_id);
        self.assertIs(s1.geo_id, geo_id)
        self.assertFalse(hasattr(s1, 'dataset_ids'))
        self.assertFalse(hasattr(s1, 'subset_ids'))
        self.assertFalse(hasattr(s1, 'series_ids'))

        s1.populate()
        self.assertTrue(hasattr(s1, 'dataset_ids'))
        self.assertTrue(hasattr(s1, 'subset_ids'))
        self.assertTrue(hasattr(s1, 'series_ids'))

    def test_init_dict(self):
        geo_id='GSM30429'
        s1=Sample({'geo_id':geo_id, 'name': 'fred'})
        self.assertEqual(s1.geo_id, geo_id)
        self.assertEqual(s1.name, 'fred')

    def test_init_dict_no_geo_id(self):
        self.assertRaises(ProgrammerGoof, Sample, {})
        self.assertRaises(ProgrammerGoof, Sample, {'name': 'fred'})



suite = unittest.TestLoader().loadTestsFromTestCase(TestInit)
unittest.TextTestRunner(verbosity=2).run(suite)


        


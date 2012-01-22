import unittest, sys, os
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO.Sample
Sample=GEO.Sample.Sample
from warn import *

class TestPath(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_missing_param(self):
        self.assertRaises(ProgrammerGoof, Sample.data_path_of)

    def test_path_classmethod(self):
        path=Sample.data_path_of(geo_id='GSM8382')
        self.assertRegexpMatches(path, os.path.join(Sample.subdir,"GSM838","GSM8382.table.data"))
        path=Sample.data_path_of(geo_id='GSM8382', id_type='probe')
        self.assertRegexpMatches(path, os.path.join(Sample.subdir,"GSM838","GSM8382.table.data"))

        path=Sample.data_path_of(geo_id='GSM8382', id_type='gene')
        self.assertRegexpMatches(path, os.path.join(Sample.subdir,"GSM838","GSM8382.data"))

    def test_path_instance(self):
        geo_id='GSM8328'
        sample=Sample(geo_id=geo_id)
        self.assertIs(sample.geo_id, geo_id)
        self.assertRegexpMatches(sample.data_path(), 
                                 os.path.join(Sample.subdir,"GSM832","%s.table.data"%geo_id))

        self.assertRegexpMatches(sample.data_path(id_type='gene'), 
                                 os.path.join(Sample.subdir,"GSM832","%s.data" % geo_id))

suite = unittest.TestLoader().loadTestsFromTestCase(TestPath)
unittest.TextTestRunner(verbosity=2).run(suite)


        


import unittest, sys, os, yaml
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../../..")
sys.path.append(os.path.join(dir+'/pylib'))

from warn import *
from GEO import GEO
from GEO.Sample import Sample

class TestRecordInit(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_record_init(self):
        records=Sample.mongo().find()
        self.assertIsInstance(records, list)
        warn("got %d records", len(records))
        sample=Sample.from_record(record[0])
        self.assertIsInstance(sample, Sample)
        warn(yaml.dump(sample))



suite = unittest.TestLoader().loadTestsFromTestCase(TestRecordInit)
unittest.TextTestRunner(verbosity=2).run(suite)


        


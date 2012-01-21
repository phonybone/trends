import unittest, sys, os, yaml
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *
from GEO import GEO
from GEO.Sample import Sample
import pymongo

class TestRecordInit(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_record_init(self):
        geo_id='GSM15718'
        cursor=Sample.mongo().find({'geo_id':geo_id})
        self.assertIsInstance(cursor, pymongo.cursor.Cursor)
        self.assertEqual(cursor.count(), 1)
        sample=Sample(cursor[0])
        self.assertIsInstance(sample, Sample)
        self.assertEqual(sample.geo_id, geo_id)




suite = unittest.TestLoader().loadTestsFromTestCase(TestRecordInit)
unittest.TextTestRunner(verbosity=2).run(suite)


        


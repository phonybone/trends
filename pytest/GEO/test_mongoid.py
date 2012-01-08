import unittest, sys, os, yaml
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../..")
sys.path.append(os.path.join(dir,'pylib'))

from warn import *
from GEO import GEO
from GEO.Sample import Sample
import pymongo

class TestMongoid(unittest.TestCase):
    ''' tests Mongoid.connect(), Mongoid.db(), and Mongoid.mongo() '''

    def setUp(self):
        pass
        
    def test_mongo(self):
        self.assertIsInstance(Sample.mongo(), pymongo.collection.Collection)
        cursor=Sample.mongo().find()
        warn("cursor: got %d records" % cursor.count())
        self.assertTrue(cursor.count() > 1)

        record=cursor.next()
        self.assertTrue('geo_id' in record)
        self.assertTrue('_id' in record)
        


suite = unittest.TestLoader().loadTestsFromTestCase(TestMongoid)
unittest.TextTestRunner(verbosity=2).run(suite)


        


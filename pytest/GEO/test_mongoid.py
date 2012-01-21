import unittest, sys, os, yaml, pymongo
sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))


from warn import *
from GEO.Factory import Factory # GEO.Factory has to imported before Sample
from GEO.Sample import Sample

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


        


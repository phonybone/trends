import unittest, sys, os
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../..")
sys.path.append(os.path.join(dir,'pylib'))

#from Rnaseq import *
from warn import *
import pymongo

class TestGeoConnection(unittest.TestCase):
    
    def setUp(self):
        pass

    def test_connection(self):
        warn(sys._getframe().f_code.co_name) # testing framework does this anyway...
        connection=pymongo.Connection()
        self.assertIsInstance(connection, pymongo.Connection)
        self.connection=connection
        
    def test_geo_db(self):
        geo_db=pymongo.Connection().geo
        self.assertIsInstance(geo_db, pymongo.database.Database)

    def test_geo_series(self):
        geo_db=pymongo.Connection().geo
        series_table=geo_db.series
        cursor=series_table.find({'geo_id':'GSE1000'})
        self.assertIsInstance(cursor, pymongo.cursor.Cursor)
        self.assertIs(cursor.count(), 1)


suite = unittest.TestLoader().loadTestsFromTestCase(TestGeoConnection)
unittest.TextTestRunner(verbosity=2).run(suite)


        


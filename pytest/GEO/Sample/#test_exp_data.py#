import unittest, os, sys
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO
from warn import *
from GEO.Sample import Sample

class TestData(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_exp_data(self):
        sample=Sample('GSM15718').populate() # GSM15718 comes from GSE994
        (id_type,data)=sample.expression_data('probe')
        self.assertEqual(id_type, 'probe')
        self.assertEqual(len(data), 22215)
        self.assertEqual(data['200003_s_at'], 2483.300)
        self.assertEqual(data['1438_at'], 78.500)
        self.assertEqual(data['200707_at'], 159.800)
        self.assertEqual(data['200773_x_at'], 2505.100)
        self.assertEqual(data['200981_x_at'], 2842.700)
        self.assertEqual(data['91682_at'], 65.000)




suite = unittest.TestLoader().loadTestsFromTestCase(TestData)
unittest.TextTestRunner(verbosity=2).run(suite)


        


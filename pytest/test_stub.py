import unittest, sys, os

sys.path.append(os.environ['AUREA_SRC'])
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from warn import *

class TestStub(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_something(self):
        pass



suite = unittest.TestLoader().loadTestsFromTestCase(TestStub)
unittest.TextTestRunner(verbosity=2).run(suite)


        


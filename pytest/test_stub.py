import unittest, sys, os
dir=os.path.normpath(os.path.dirname(os.path.abspath(__file__))+"/../..")
sys.path.append(os.path.join(dir+'/pylib'))

from warn import *

class TestStub(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_something(self):
        pass



suite = unittest.TestLoader().loadTestsFromTestCase(TestStub)
unittest.TextTestRunner(verbosity=2).run(suite)


        


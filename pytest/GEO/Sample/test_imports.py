import unittest, sys, os

sys.path.append(os.path.join(os.environ['AUREA_HOME'], 'src'))
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO

class TestImports(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_imports(self):
        pass



suite = unittest.TestLoader().loadTestsFromTestCase(TestImports)
unittest.TextTestRunner(verbosity=2).run(suite)


        


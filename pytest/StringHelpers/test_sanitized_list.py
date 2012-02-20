import unittest, sys, os

sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

from string_helpers import sanitized_list
from warn import *

class TestSanitizedList(unittest.TestCase):
    
    def setUp(self):
        pass
        
    def test_remove_nasties(self):
        nasty_string="This string! has 9 (&#$# all \n 'sudo rm -rf /*' nasty stuff"
        sanitized=['this', 'string', 'has', '9', 'all', 'sudo', 'rm', '-rf', 'nasty', 'stuff']
        self.assertEqual(sanitized_list(nasty_string), sanitized)
        self.assertEqual(sanitized_list(nasty_string, '[^a]'), ['a', 'a', 'a'])

    def test_unicode(self):
        s=u'this is a unicode string'
        self.assertEqual(sanitized_list(s), ['this', 'is', 'a', 'unicode', 'string'])
        

suite = unittest.TestLoader().loadTestsFromTestCase(TestSanitizedList)
unittest.TextTestRunner(verbosity=2).run(suite)


        


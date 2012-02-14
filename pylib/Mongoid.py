import pymongo, yaml
from warn import *

class Mongoid(object):

    '''
    Mixin class providing mongo connectivity.  inheriting classes must
    define (as class attributes): db_name, collection_name
    (default=class name)

    For now, only one connection to a mongod server per program (sorry).
    '''

    _connection_args=None
    _connection=None
    _db=None
    db_name=None
    collection=None

    @classmethod
    def connect(self,*args):
        if len(args):
            self._connection=pymongo.Connection(args)
        else:
            self._connection=pymongo.Connection()
        return self._connection


        
    @classmethod
    def db(self, db_name=None, *connect_args):
        if self._db: return self._db 

        conn=self._connection        
        if not conn:
            self._connection=self.connect(*connect_args) # obviously this can throw exceptions
            conn=self._connection
                      
        if not db_name: db_name=self.db_name
        assert(db_name)
        self._db=conn[db_name]
        return self._db
        
    @classmethod
    def mongo(self):
        db=self.db()

        try: collection_name=self.collection_name
        except AttributeError: collection_name=self.__class__.__name__
#        warn("mongo(%s): collection_name=%s, db[%s]=%s" % (self, collection_name, collection_name, db[collection_name]))
        return db[collection_name]



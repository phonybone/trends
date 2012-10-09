import sys, os, datetime
sys.path.append(os.path.join(os.environ['TRENDS_HOME'], 'pylib'))

import GEO
from GEO.word2geo import Word2Geo
from warn import *
from GEO.Factory import Factory
from GEO.Series import Series
from GEO.Dataset import Dataset
from GEO.DatasetSubset import DatasetSubset
from GEO.pubmed import Pubmed
from string_helpers import str_windows

seen_dataset=dict()             # k=GDS, v=bool
seen_pubmed=dict()              # k=pmid, v=bool

def main():
    options=get_options()
    geo_ids=get_geo_ids(options)
    f=Factory()
    warn("insert_geo_words starting: %s" % (datetime.datetime.now().__str__()))

    fuse=options.fuse
    for geo_id in geo_ids:
        geo=f.newGEO(geo_id)
        warn("inserting %s" % (geo.geo_id))
        stats=insert_series(geo)
        warn("%s: %s" % (geo_id, stats))
        fuse-=1
        if (fuse==0): break

    warn("insert_geo_words done: %s" % (datetime.datetime.now().__str__()))
    return 0

########################################################################

def dump_words(words, msg):
    for tag,l in words.items():
        warn("%s: %s: %d items" % (msg, tag, len(l)))
    warn("\n")

def insert_series(series):
    global seen_dataset;
    global seen_pubmed;
    seen_pubmed={}
    debug='DEBUG' in os.environ

    # gather ALL the words!
    words=gather_words(series)

    totals=insert_words(series, words)
    if debug: warn("series %s: %s" % (series.geo_id, totals))
    if type(series) != Series: return

    # build up words from datasets and subsets, and insert words as we go:
    # (but only insert dataset/subset words once)
    datasets=series.datasets()
    warn("%s: %d datasets" % (series.geo_id, len(datasets)))
    for dataset in datasets:
        warn("  %s: inserting %s" % (series.geo_id, dataset.geo_id))
        ds_words=gather_words(dataset)
        add_words(words, ds_words)
        if dataset.geo_id not in seen_dataset: 
            ds_totals=insert_words(dataset, ds_words)
            if debug: warn("dataset %s: %s" % (dataset.geo_id, totals))
            add_totals(totals, ds_totals)

        try: warn("%s: %d subsets" % (dataset.geo_id, dataset.n_subsets))
        except AttributeError: warn("%s: subsets not defined???" % (dataset.geo_id))

        for subset in dataset.subsets():
            warn("  %s: inserting %s" % (series.geo_id, subset.geo_id))
            ss_words=gather_words(subset)
            add_words(words, ss_words)
            if dataset.geo_id not in seen_dataset:
                ss_totals=insert_words(subset, ss_words)
                if debug: warn("subset %s: %s" % (subset.geo_id, totals))
                add_totals(totals,ss_totals)
        seen_dataset[dataset.geo_id]=True

    # add the sum of words from all objects to every sample in the series:
    samples=series.samples()
    warn("%d samples for %s" % (len(samples), series.geo_id))
    for sample in samples:
        warn("  %s: inserting %s" % (series.geo_id, sample.geo_id))
        s_totals=insert_words(sample, words)
        if debug: warn("sample %s: %s" % (sample.geo_id, totals))
        add_totals(totals, s_totals)

    return totals

#-----------------------------------------------------------------------
def add_words(dst, src):
    '''
    dst & src: k=tag, v=list of words (w/ dups) (as per gather_words())
    '''
    for tag, wordlist in src.items():
        dst[tag].extend(wordlist)
    return                  # indent fixer

def add_totals(dst, src):       # k=source, v=count
    for source, count in src.items():
        if source in dst:
            dst[source]+=count
        else:
            dst[source]=count


#-----------------------------------------------------------------------

def gather_words(geo):
    ''' gather words: k=tag, v=list of sanitized words (may have dups) '''
    words=get_field_words(geo)
    if hasattr(geo, 'pubmed_id'):
        pubmed_ids=geo.pubmed_id
        if type(pubmed_ids)!=type([]):
            pubmed_ids=[pubmed_ids]

        for pmid in [int(x) for x in pubmed_ids]:
            if pmid not in seen_pubmed:
                words.update(get_pubmed_words(pmid))
                seen_pubmed[pmid]=True

    if 'DEBUG' in os.environ: dump_words(words, geo.geo_id)
    return words


#-----------------------------------------------------------------------

def insert_words(geo, words):
    '''
    geo: GEO object
    words: dict [k=source (aka 'tag'); v=list of words (maybe with dups)]
    Creates records with keys [geo_id, word, source, count], adds to db
    '''
    mongo=Word2Geo.mongo()
    mongo.remove({'geo_id': geo.geo_id}) # remove the record for this geo

    totals=dict()           # k=source, v=count
    for source, words in words.items():
        for word in words:
            query={'geo_id':geo.geo_id, 'word':word, 'source':source}
            record=mongo.find_one(query)
            if record:
                if 'count' in record: record['count']+=1
                else: record['count']=1
            else:           # record not found, construct it from query:
                record=query
                record['count']=1
            mongo.save(record)

            try: totals[source]+=1
            except: totals[source]=1

    return totals
    
#-----------------------------------------------------------------------

def get_field_words(geo):
    '''
    collect words from certain fields in the record:
    '''
    debug='DEBUG' in os.environ
    words={}                # k=field, v=[w1, w2, w3, ...] (w's can be "windows")
    word_fields=['title', 'description', 'summary']
    for field in word_fields:
        words[field]=[]     
        if hasattr(geo, field):
            field_words=getattr(geo, field) # can be a string, a list of single words, or a list of paragraphs
            if type(field_words) != list:
                field_words=[field_words]

            if len(field_words)==0:
                if debug: warn("does this ever happen?" % ())
                continue

            i=0
            for wl in field_words:
#                if debug: warn("\n%s[%d]: wl(%s, %d) is %s" % (field, i, type(wl), len(wl), wl))
                i+=1
                # wrap this in a loop n=(1..3)
                # replace sanitized_list() with str_windows(wl, n)
                for n in range(1,4): # gives 1,2,3
                    if len(wl)>=n:
                        windows=str_windows(wl, n, '[-_\s]+')
#                        if debug: warn("%s(%d): %d windows " % (field, n, len(windows)))
                        for w in windows:
                            words[field].append(w)
                    else:
                        if debug: warn("skipping %s(%d): len(wl)=%d" % (field, n, len(wl)))
                            
    return words

#-----------------------------------------------------------------------

def get_pubmed_words(pubmed_id):
    ''' 
    return a dict in the same format as get_field_words: k=field, v=sanitized list of words
    '''
    words=dict()
    pubmed=Pubmed(pubmed_id).populate()
    for tag in Pubmed.text_tags:
        try: 
            words[tag]=getattr(pubmed, tag)
#            warn("fu %d: %s -> %s" % (pubmed_id, tag, words[tag]))
        except AttributeError as ae:
            pass

    return words

########################################################################


def get_options():
    from optparse import OptionParser
    def set_debug(option, opt, value, parser):
        os.environ['DEBUG']='True'
        return                  # indent fixer

    parser=OptionParser()
    parser.add_option('--fuse', dest='fuse', type='int', default=-1, help='debugging fuse (limits iterations in main loop)')
    parser.add_option('-d', '--debug', action='callback', callback=set_debug)

    (options, args)=parser.parse_args()
    try:    options.idlist.extend(args) # this will never happen as yet
    except: options.idlist=args
    return options
    

def get_geo_ids(options):
    if len(options.idlist): return options.idlist

    geo_ids=[]
#    for cls in [GEO.Series.Series, GEO.Dataset.Dataset, GEO.DatasetSubset.DatasetSubset]:
# only doing series now, and everything else goes through series
    for cls in [GEO.Series.Series]:
        cursor=cls.mongo().find({}, {'_id':0, 'geo_id':1})
        warn("got %d %s records" % (cursor.count(), cls.__name__))
        for record in cursor:
            geo_ids.append(record['geo_id'])
    return geo_ids


main()


    

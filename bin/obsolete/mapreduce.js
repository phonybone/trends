# 'this' is one element (row) of the starting collection
var mapper=function() { 
  for (var key in this) { 
    emit(key,1)
  }
}


# values is an array of whatever the mapper function returns
# reducer() must return one of the same element
var reducer=function(key, values) {
  var result = { 'key':key, 'count':0}
  values.forEach(function(value) { result['count']+=value })
  return result
}

mr=db.runCommand({
  mapreduce:"datasets",
  map:mapper,
  reduce: reducer,
  out:"mr_results"
});

db.mr_results.find()

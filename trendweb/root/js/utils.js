if(!Object.keys) Object.keys = function(o){
   if (o !== Object(o))
      throw new TypeError('Object.keys called on non-object');
   var ret=[],p;
   for(p in o) if(Object.prototype.hasOwnProperty.call(o,p)) ret.push(p);
   return ret;
}

function toggle_more(id, vis) { 
  if (vis) {
    $('#'+id+'_'+'long').show();
    $('#'+id+'_'+'short').hide();
  } else {
    $('#'+id+'_'+'long').hide();
    $('#'+id+'_'+'short').show();
  }
  return false;
}


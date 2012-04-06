Object.prototype.to_string=function() {
  var ar=new Array();
  for (var k in this) {
    var value=this[k];
    if (typeof value == "function") continue;
    if (typeof value == "undefined") value='<undefined>';
    ar.push(k + ': ' + value);
  }
  return ar.join('\n');
}
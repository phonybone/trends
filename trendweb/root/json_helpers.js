function json2html(json, id) {
  alert('json2html('+id+') called');
  $("#"+id).append(display_object(json));
}

function display_object(o) {
  var content=new Array();
  content.push('<ul>\n');
  for (k in o) {
    content.push('<li>'+k+': ');
    var v=o[k];
    var v_type=RealTypeOf(v);
    switch(v_type) {
      case 'array':
        content.push(display_list(v));
        break;
      case 'object':
        content.push(display_object(v));
        break;
      default:
        content.push(v);
        break;
    }
    content.push('</li>\n');
  }
  content.push('</ul>\n');
  return content.join("\n");
}

function display_list(l, id) {
  var content=new Array();
  content.push('<ul>\n');
  for (i in l) {
    content.push('<li>');
    var v=l[i];
    var v_type=RealTypeOf(v);
    switch(v_type) {
      case 'array':
        content.push(display_list(v));
        break;
      case 'object':
        content.push(display_object(v));
        break;
      default:
        content.push(v);
        break;
    }
    content.push('</li>\n');
  }
  content.push('</ul>\n');
  return content.join("\n");
}

function RealTypeOf(v) {
  if (typeof(v) == "object") {
    if (v === null) return "null";
    if (v.constructor == (new Array).constructor) return "array";
    if (v.constructor == (new Date).constructor) return "date";
    if (v.constructor == (new RegExp).constructor) return "regex";
    return "object";
  }
  return typeof(v);
}

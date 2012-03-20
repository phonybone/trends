// Append the HTML representation of json to a DOM element:
function json2html(json, id) {
  $("#"+id).empty().append(display_object(json));
}

// Recursive function (along with display_list) to convert
// a JSON object to HTML (in <ul> list format)
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

function display_list(l) {
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

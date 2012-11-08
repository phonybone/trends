DatasetEditor=function(form_id) {
  this.form_id=form_id;
  this.pheno2gsms=new Object();
  this.cache=new Object();	// gets overwritten
  this.user_phenos=new Object(); // keep track of user-added phenotypes for this element
}

DatasetEditor.prototype={

  get_cached_gsm : function(geo_id) {
    var gsms=this.cache.samples;	// array of gsms
    for (idx in gsms) {
      if (gsms[idx].geo_id==geo_id) {
        return gsms[idx];
      }
    }
    return null;
  },

  toggle : function(desc) {
    $("input:checkbox.gsm_pheno").filter(function(idx) {
      return this.value == desc;
    }).each(function(idx,e) {
      e.checked=!e.checked;
    })
  },

  load_geo : function(geo_id) {
    var uri='/geo/'+geo_id;
    var settings={
      type: 'GET',
      accepts: 'application/json',
      contentType: 'application/json',
      error: function(jqXHR, msg, excp) { alert('load_geo error status: '+jqXHR.status); },
      success: function(data, status, jqXHR) { document.editor.cache_data(data); },
    };
    $.ajax(uri,settings);
  }, 

  // Store the data returned from load_geo in a cache:
  cache_data : function(data) {
    this.cache=data;
    var n_items=Object.keys(data).length;
    console.log('data cached: '+n_items+' items');
  },

  edit_geo_tb : function(event) {
    console.log('edit_geo_tb entered');
    console.log("event: target.id=%s, type=%s",event.target.id, event.type);
    event.preventDefault();
    var geo_id=event.target.value;
    document.editor.edit_geo(geo_id);
    return false;
  },

  edit_geo_button : function(event) {
    console.log('edit_geo_button entered');
    console.log('event: target.id=%s, type=%s',event.target.id, event.type);
    event.preventDefault();
    var geo_id=$("#loader_tb")[0].value;
    document.editor.edit_geo(geo_id);
    return false;
  },

  edit_geo : function(geo_id) {
    if (geo_id == null || geo_id=='') { console.log('no geo_id, quitting'); return }
    var url="/geo/"+geo_id+"/edit";
    window.location.replace(url);
    return false;
  },

  save_phenos : function(event) {
    console.log('save_phenos entered');
    console.log('event: target.id=%s, type=%s',event.target.id, event.type);
    event.preventDefault();
    var ed=document.editor;

    // Iterate over pheno checkboxes, update sample if cb is checked
    // or remove pheno if cb isn't checked
    $("input:checkbox.gsm_pheno").each(function() {
      var pheno=this.value;
      var geo_id=this.name;			  // this==checkbox
      if (geo_id==null) {
        console.log('missing geo_id/name in checkbox'+this);
	return;
      }
      
      var sample=ed.get_cached_gsm(geo_id);
      if (sample==null) {
        console.log("can't find sample for "+geo_id);
	return;
      }
      if (sample.phenotypes==null) sample.phenotypes=new Array();

      // add or remove pheno as necessary:
      var idx=sample.phenotypes.indexOf(pheno);
      if (this.checked && idx==-1) {
        sample.phenotypes.push(pheno);
      } else if (!this.checked && idx != -1) {
        sample.phenotypes.splice(idx,1);
      }

      // put back in cache:
      ed.cache.samples[geo_id]=sample;
    });

    // ajax call to geo/bulk:
    var uri='/geo/bulk';
    var settings={
      type: 'POST',
      accepts: 'application/json',
      contentType: 'application/json',
      data: JSON.stringify(ed.cache.samples),
      error: function(jqXHR, msg, excp) { alert('Unable to save phenotypes: error='+jqXHR.status); },
      success: function(data, status, jqXHR) { $(window).off('beforeunload'); },
    };
    $.ajax(uri,settings);
    return false;
  },

  add_user_pheno : function(event) {
    event.preventDefault();
    var pheno=$('#user_pheno_tb').val();
    if (pheno==null || pheno=='') return;
    if (this.user_phenos[pheno] != null) return;	// already added
    this.user_phenos[pheno]=pheno;
    $('#samples_table tr').append(this.add_user_pheno_hook1);

    // also have to add a tr to the table of "possible" phenotypes
    $('#table_subsets').append(this.add_user_pheno_hook2)
    return false;
  },

  // add a <td>...</td> to each row of the samples_table
  add_user_pheno_hook1 : function(idx, html) {		// html unused
    // this is the tr element in question
    var pheno=$('#user_pheno_tb').val();
    var geo_id=this.children[0].innerHTML;	// happens to be stored in the first <td>
    var inner="<td><input type='checkbox' class='gsm_pheno' name='"+geo_id+"' value='"+pheno+"'";
    if ($('#apply_to_all').attr('checked')) { inner+=" checked='1'"; }
    inner+="' />";
    inner+="<span>" + pheno + "</span></td>";
    return inner;
  },

  // Add a single row to the subsets table:
  add_user_pheno_hook2 : function(idx, html) {		// html unused
    // this is the table element
    var pheno=$('#user_pheno_tb').val();
    var tr_html='<tr>';
    tr_html+='<td>'+pheno+'</td>';
    tr_html+="<td><button onclick='editor.toggle(\""+pheno+"\")'>Toggle samples</button></td>";
    tr_html+='</tr>';
    return tr_html;
  },
}



$(document).ready(function() {
  var editor=new DatasetEditor(document.form_id);
  this.editor=editor;	// this==document

  // Attempt to keep user on page if changes have not been saved:
  // register a handler when the gsm checkboxes are clicked:
  $('.gsm_pheno').on('change', function(event) { 
    $(window).on('beforeunload', function(event) { return 'Changes have not been saved'; });
  });

  // Various initialization tasks:
  // Are these being set wrong?  Don't want to actually call these functions, but they are...
  $("#loader_tb").on('change',function(event) { 
    console.log('loader_tb.change called, calling edit_geo_tb');
    editor.edit_geo_tb(event)
  });
  $("#loader_button").on('click', function(event) { 
    console.log('loader_button.change called, calling edit_geo_tb');
    editor.edit_geo_button(event)
  });
  $("#save_button").on('click', function(event) {editor.save_phenos(event)});

  $("#user_pheno_tb").on('change',function(event) {editor.add_user_pheno(event)});
  $("#user_pheno_button").on('click',function(event) {editor.add_user_pheno(event)});

  // Set the value of the loader_tb if possible:
  if (document.geo_id != null) {
    console.log('ready: loading '+document.geo_id);
    $("#loader_tb").value=document.geo_id;
    editor.load_geo(document.geo_id);
  } else {
    console.log('document.geo_id is undefined');
  }

  console.log('ready() finished');
});
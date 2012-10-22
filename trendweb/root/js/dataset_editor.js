DatasetEditor=function(form_id) {
  this.form_id=form_id;
  this.pheno2gsms=new Object();
  this.cache=new Object();	// gets overwritten
}

DatasetEditor.prototype={

  sanify_gsm_pheno_cb_id : function(geo_id, subset_desc) {
    var id=geo_id+'_'+subset_desc;
    id.replace(/\w/g, '_');	// replace anything that's not a regular char with '_'
    return id;
  },

  set_gsm_pheno_cbs : function() {
    var i=0;
    var editor=this;
    $("input:checkbox.gsm_pheno").each(function(idx, e) { 
      var geo_id=e.name;
      var pheno=e.value;
      e.id=document.editor.sanify_gsm_pheno_cb_id(geo_id, pheno);
      var gsm=editor.get_cached_gsm(geo_id);
      if (gsm==null) {
        alert('missing gsm!?!?: '+geo_id);
        return;
      }
      
    });
  },

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
      error: function(jqXHR, msg, excp) { alert('error status: '+jqXHR.status); },
      success: function(data, status, jqXHR) { document.editor.cache_data(data); },
    };
    $.ajax(uri,settings);
  }, 

  cache_data : function(data) {
    this.cache=data;
    console.log('data cached');
  },

  edit_geo_tb : function(event) {
    event.preventDefault();
    var geo_id=event.target.value;
    document.editor.edit_geo(geo_id);
    return false;
  },

  edit_geo_button : function(event) {
    event.preventDefault();
    var geo_id=$("#loader_tb")[0].value;
    document.editor.edit_geo(geo_id);
    return false;
  },

  edit_geo : function(geo_id) {
    var url="/geo/"+geo_id+"/view";
    alert("These edits have not been saved; going to "+url)
    window.location.replace(url);
  },

  save_phenos : function(event) {
    event.preventDefault();
    var ed=document.editor;

    // Iterate over pheno checkboxes, update sample if cb is checked
    // or remove pheno if cb isn't checked
    $("input:checkbox.gsm_pheno").each(function() {
      var pheno=this.value;
      var geo_id=this.name;			  // this==checkbox
      var sample=ed.get_cached_gsm(geo_id);
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
      error: function(jqXHR, msg, excp) { alert('error status: '+jqXHR.status); },
      success: function(data, status, jqXHR) { },
    };
    $.ajax(uri,settings);

  },
}

$(document).ready(function() {
  var editor=new DatasetEditor(document.form_id);
  this.editor=editor;	// this==document
//  editor.set_gsm_pheno_cbs();

  // Various initialization tasks:
  $("#loader_tb").on('change',function(event) {editor.edit_geo_tb(event)});
  $("#loader_button").on('click', function(event) {editor.edit_geo_button(event)});
  $("#save_button").on('click', function(event) {editor.save_phenos(event)});

  $("#search_tb").on('change', function(event) {editor.search(event)});
  $("#search_button").on('click', function(event) {editor.search(event)});

  // Set the value of the loader_tb if possible:
  if (document.geo_id != null) {
    $("#loader_tb").value=document.geo_id;
    editor.load_geo(document.geo_id);
  }

});
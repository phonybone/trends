DatasetEditor=function() {
  this.pheno2gsms=new Object();
}

DatasetEditor.prototype={

  sanify_gsm_pheno_cb_id : function(geo_id, subset_desc) {
    var id=geo_id+'_'+subset_desc;
    id.replace(/\w/g, '_');	// replace anything that's not a regular char with '_'
    return id;
  },

  set_gsm_pheno_cb_ids : function() {
    var i=0;
    $("input:checkbox.gsm_pheno").each(function(idx, e) { 
      var geo_id=e.name;
      var pheno=e.value;
      e.id=document.editor.sanify_gsm_pheno_cb_id(geo_id, pheno);
    });
  },

  toggle : function(desc) {
    $("input:checkbox.gsm_pheno").filter(function(idx) {
          return this.value == desc;
    }).each(function(idx,e) {
      e.checked=!e.checked;
    })
  },

  load_geo : function(event) {
    event.preventDefault();
    var geo_id=$('#loader_tb')[0].value;
    var uri='/geo/'+geo_id;
    console.log('about to hit '+uri);
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
    console.log('caching data '+data);
    this.cache=eval(data);
  },
}

$(document).ready(function() {
  var editor=new DatasetEditor();
  this.editor=editor;	// this==document
  editor.set_gsm_pheno_cb_ids();

  // Various initialization tasks:
  $("#loader_tb").on('change',function(event) {editor.load_geo(event)});
  $("#loader_tb").each(function(i,e){ e.placeholder='wink'; });
  $("#loader_button").on('click', function(event){editor.load_geo(event)});
});
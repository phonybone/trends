  sanify_gsm_pheno_cb_id : function(geo_id, subset_desc) {
    var id=geo_id+'_'+subset_desc;
    id.replace(/\w/g, '_');	// replace anything that's not a regular char with '_'
    return id;
  },

  // sets ids for gsm checkboxes
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



  search : function(event) {
    event.preventDefault();
    var search_term=$('#search_tb')[0].value;
//    console.log('event: target.id=%s, type=%s',event.target.id, event.type);

    var uri='/geo/search';
    var settings={
      type: 'POST',
      accepts: 'application/json',
      contentType: 'application/json',
      data: JSON.stringify({search_term : search_term}),
      error: function(jqXHR, msg, excp) { alert('search: error status: '+jqXHR.status) },
      success: function(data, status, jqXHR) { document.editor.display_search(data) },
    };
    $.ajax(uri,settings);
    return false;
  },

  display_search : function(data) {
    console.log('search entered');
    var n_results=0;
    for (var k in data) { n_results++ }
    alert('displaying '+n_results+' search results');
    return false;
  },


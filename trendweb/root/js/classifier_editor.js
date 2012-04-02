ClassifierEditor=function() { };

ClassifierEditor.prototype = {
  constructor: ClassifierEditor,

  load_classifier: function(name_field) {
  var classifier_name=$('#'+name_field)[0].value;
  if (classifier_name == null || classifier_name.length == 0) {
    alert('No classifier name specified');
    $('#cef_name').focus();
    return false;
  }

  var ret=$.ajax({url: 'http://localhost:3000/classifier/'+classifier_name,
          data: {},
          dataType: 'json',
          success: function(data) { document.CE.load_classifier_form(new Classifier(data), '#cef') },
          error: function(jqXHR, textStatus, errorThrown) { alert('error: '+textStatus+'\nthrown: '+errorThrown) },
         });

  return false;
},

/*
  Load an editing form with a classifier.  Form has name, type, timestamp
  numbers of samples, results genes
  RB's correspond to the sample being in the '+' set, the '-' set, or
  the null set.
*/
  load_classifier_form: function(classifier, form_id) {
  $(form_id+'_name')[0].value=classifier.name;
  $(form_id+'_n_pos_samples')[0].textContent=classifier.samples_pos.length;
  $(form_id+'_n_neg_samples')[0].textContent=classifier.samples_neg.length;
  
  // gene_pos and gene_neg, timestamp:
  $(form_id+'_gene_pos')[0].textContent=classifier.results.gene_pos;
  $(form_id+'_gene_neg')[0].textContent=classifier.results.gene_neg;
  $(form_id+'_last_run')[0].textContent=classifier.timestamp;

  var sample_elems=new Array();
  for (idx in classifier.samples_pos) {
    sample_elems.push("<tr>");
    var name=form_id.substring(1) + "_rb_" + classifier.samples_pos[idx];
    sample_elems.push("<td><label for='" + name + "'>" + classifier.samples_pos[idx] + "</label></td>");
    sample_elems.push("<td><input type='radio' name='" + name + "' value='1' checked='1' />");
    sample_elems.push("<input type='radio' name='" + name + "' value='-1' />");
    sample_elems.push("<input type='radio' name='" + name + "' value='0' /></td>");
    sample_elems.push("</tr");
  }
	
  for (idx in classifier.samples_neg) {
    var name=form_id.substring(1) + "_rb_" + classifier.samples_neg[idx];
    sample_elems.push("<tr>");
    sample_elems.push("<td><label for='" + name + "'>" + classifier.samples_neg[idx] + "</label></td>");
    sample_elems.push("<td><input type='radio' name='" + name + "' value='1' />");
    sample_elems.push("<input type='radio' name='" + name + "' value='-1' checked='1' />");
    sample_elems.push("<input type='radio' name='" + name + "' value='0' /></td>");
    sample_elems.push("</tr>");
  }
  $(form_id+'_samples').empty().append(sample_elems.join('\n'));

}

};

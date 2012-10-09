var Classifier=function(argHash) {
    var attr_names=['id', 'name', 'type', 'results', 'samples_pos', 'samples_neg', 'timestamp'];
    for (i in attr_names) {
        attr=attr_names[i];
	this[attr]=typeof argHash[attr] == "undefined"? null : argHash[attr];
    }
}

Classifier.prototype = {
    constructor: Classifier,

    as_html_table: function() {
        var html=new Array();
	html.push('<table>');
	html.push('<tr><td>Name:</td><td>'+this.name+'</td></tr>');

	return html.join("\n");
    },

    uri: function() {
        return '/classifier/'+this.id;
    },

    link: function() {
        return "<a href='" + this.uri() + "'>" + this.name + "</a>";
    },

    to_string2: function() {
       var str=new Array();
       str.push('name: '+this.name);
       str.push('id: '+this.id);
       str.push('type: '+this.type);
       str.push('+gene: '+this.results.gene_pos+', -gene: '+this.results.gene_neg);
       str.push('more to come...');
       return str.join('\n');
    },

    load_edit_form: function(form_id) {

    },

};



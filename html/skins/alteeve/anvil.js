$.ajaxSetup({
    cache: false
});
$(function() { 

});


$( window ).on( "load", function()
{
	// NOTE: Disabled for now. Breaks viewing the source.
	//  Clears the URL to remove everything off after '?'.
	//var newURL = location.href.split("?")[0];
	//window.history.pushState('object', document.title, newURL);
	//console.log('onload fired.');
	
	// Walk through the network.json file and use it to pre-fill the form.
	$.getJSON('/status/network.json', { get_param: 'value' }, function(data) {
		$.each(data.ips, function(index, element) {
			//console.log('- entry: ['+index+'], on: ['+element.on+'], address: ['+element.address+'], subnet_mask: ['+element.subnet_mask+'].');
			//console.log('- gateway: ['+element.gateway+'], dns: ['+element.dns+'], default gateway: ['+element.default_gateway+'].');
		});
	});
})

$.ajaxSetup({
    cache: false
});
$(function() { 
});

$( window ).on( "load", function()
{
	// This resizes the peer access field to the placeholder width to better handle translations.
	$("#new_peer_access").each(function () {
		//var npa_width = $(this).attr('placeholder').length;
		//console.log('resize new_peer_access to: ['+npa_width+'].');
		$(this).attr('size', $(this).attr('placeholder').length);
	});
	
})


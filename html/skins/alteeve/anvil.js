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
	
	// Toggle the table with the list of hosts that can be configured.
	$("#toggle_unconfigured_icon").click(function(){
		$("#unconfigured_hosts").toggle();
	});
	$("#toggle_unconfigured_text").click(function(){
		$("#unconfigured_hosts").toggle();
	});
	
	// Walk through the network.json file and use it to pre-fill the form.
	$.getJSON('/status/all_status.json', { get_param: 'value' }, function(data) {
		//console.log('read /status/all_status.json');
		var show_none        = 1;
		var say_none         = $('#unconfigured_hosts').data('none');
		var say_yes          = $('#unconfigured_hosts').data('yes');
		var say_no           = $('#unconfigured_hosts').data('no');
		var say_unconfigured = $('#unconfigured_hosts').data('unconfigured');
		var say_configured   = $('#unconfigured_hosts').data('configured');
		var say_type         = $('#unconfigured_hosts').data('type');
		var say_accessible   = $('#unconfigured_hosts').data('accessible');
		var say_at_ip        = $('#unconfigured_hosts').data('at-ip');
		
		// Open the table
		var body =  '<table id="unconfigured_hosts_table" class="data_table_nowrap">';
		    body += '<tr class="data_row">';
		    body += '<td class="column_header">'+say_unconfigured+'</td>';
		    body += '<td class="column_header"> &nbsp; </td>';
		    body += '<td class="column_header">'+say_type+'</td>';
		    body += '<td class="column_header"> &nbsp; </td>';
		    body += '<td class="column_header">'+say_accessible+'</td>';
		    body += '<td class="column_header"> &nbsp; </td>';
		    body += '<td class="column_header">'+say_at_ip+'</td>';
		    body += '</tr>';
		$.each(data.hosts, function(index, element) {
			if (element.type === 'dashboard') { 
				// Skip
				return true;
			};
			if (element.configured != 1) {
				show_none = 0;
				if (element.matched_ip_address) {
					//console.log('Show: ['+element.short_name+'], connect via: ['+element.matched_ip_address+']');
					body += '<tr class="data_row">';
					body += '<td class="column_row_value_fixed"><a class="available" href="?anvil=true&task=prep-network&host='+element.host_uuid+'">'+element.short_name+'</a></td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">'+element.type+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="available">'+say_yes+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">'+element.matched_ip_address+'</td>';
					body += '</tr>';
				} else {
					//console.log('Show: ['+element.short_name+'], not accessible from here');
					body += '<tr class="data_row">';
					body += '<td class="column_row_value_fixed">'+element.short_name+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">'+element.type+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="unavailable">'+say_no+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">--</td>';
					body += '</tr>';
				}
			}
		});
		if (show_none) {
			body += '<tr class="data_row">';
			body += '<td class="subtle_text" colspan="7">&lt;'+say_none+'&gt;</td>';
			body += '</tr>' ;
		}
		
		// Now show configured ones (in case the user wants to reconfigure a host)
		show_none = 1;
		body += '<tr class="data_row">';
		body += '<td class="column_header" style="padding-top: 0.5em;">'+say_configured+'</td>';
		body += '<td class="column_header"> &nbsp; </td>';
		body += '<td class="column_header" style="padding-top: 0.5em;">'+say_type+'</td>';
		body += '<td class="column_header"> &nbsp; </td>';
		body += '<td class="column_header" style="padding-top: 0.5em;">'+say_accessible+'</td>';
		body += '<td class="column_header"> &nbsp; </td>';
		body += '<td class="column_header" style="padding-top: 0.5em;">'+say_at_ip+'</td>';
		body += '</tr>';
		$.each(data.hosts, function(index, element) {
			if (element.type === 'dashboard') { 
				// Skip
				return true;
			};
			if (element.configured == 1) {
				show_none = 0;
				if (element.matched_ip_address) {
					//console.log('Show: ['+element.short_name+'], connect via: ['+element.matched_ip_address+']');
					body += '<tr class="data_row">';
					body += '<td class="column_row_value_fixed"><a class="available" href="?anvil=true&task=prep-network&host='+element.host_uuid+'">'+element.short_name+'</a></td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">'+element.type+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="available">'+say_yes+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">'+element.matched_ip_address+'</td>';
					body += '</tr>';
				} else {
					//console.log('Show: ['+element.short_name+'], not accessible from here');
					body += '<tr class="data_row">';
					body += '<td class="column_row_value_fixed">'+element.short_name+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">'+element.type+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="unavailable">'+say_no+'</td>';
					body += '<td class="column_header"> &nbsp; </td>';
					body += '<td class="column_row_value_fixed">--</td>';
					body += '</tr>';
				}
			}
		});
		if (show_none) {
			body += '<tr class="data_row">';
			body += '<td class="subtle_text" style="text-align: center;" colspan="7">&lt;'+say_none+'&gt;</td>';
			body += '</tr>' ;
		}
		// Close the table
		body += '</table>';
		$( "#unconfigured_hosts" ).append(body);
	});
})

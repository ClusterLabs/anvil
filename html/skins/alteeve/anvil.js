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
	
	// Show the list of unconfigured (and configured) hosts on the main page.
	if ($('#unconfigured_hosts').length) {
		// Toggle the table with the list of hosts that can be configured.
		$("#toggle_unconfigured_icon").click(function(){
			$("#unconfigured_hosts").toggle();
		});
		$("#toggle_unconfigured_text").click(function(){
			$("#unconfigured_hosts").toggle();
		});
		
		// Walk through the network.json file and use it to pre-fill the form.
		setInterval(function() {
			$.getJSON('/status/all_status.json', function(data) {
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
							body += '<td class="column_row_value_fixed"><a class="available" href="?anvil=true&task=prep-network&host_uuid='+element.host_uuid+'">'+element.short_name+'</a></td>';
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
							body += '<td class="column_row_value_fixed"><a class="available" href="?anvil=true&task=prep-network&host_uuid='+element.host_uuid+'">'+element.short_name+'</a></td>';
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
				
				// clear + append can't be the best way to do this... 
				$("#unconfigured_hosts").empty();
				$("#unconfigured_hosts").append(body);
			});
		}, 1000);
	};
	
	// Run in we're showing a specific hosts' network.
	if ($('#network_interface_table').length) {
		var host_name       = $('#network_interface_table').data('host-name');
		var say_title       = $('#network_interface_table').data('title');
		var say_mac_address = $('#network_interface_table').data('mac-address');
		var say_name        = $('#network_interface_table').data('name');
		var say_state       = $('#network_interface_table').data('state');
		var say_speed       = $('#network_interface_table').data('speed');
		var say_up_order    = $('#network_interface_table').data('up-order');
		var say_up          = $('#network_interface_table').data('up');
		var say_down        = $('#network_interface_table').data('down');
		//console.log('showing network info for: ['+host_name+']');
		setInterval(function() {
			$.getJSON('/status/all_status.json', function(data) {
				//console.log('read all_status.json: ['+data+']');
				// Build the HTML
				var body =  '<table id="network_interface_table" class="data_table_nowrap">';
				    body += '<tr>';
				    body += '<td colspan="5" class="column_header">'+say_title+'</td>';
				    body += '</tr>';
				    body += '<tr class="data_row">';
				    body += '<td class="column_row_name">'+say_mac_address+'</td>';
				    body += '<td class="column_row_name">'+say_name+'</td>';
				    body += '<td class="column_row_name">'+say_state+'</td>';
				    body += '<td class="column_row_name">'+say_speed+'</td>';
				    body += '<td class="column_row_name">'+say_up_order+'</td>';
				    body += '</tr>';
				$.each(data.hosts, function(i, host) {
					//console.log('This is: ['+host.name+']');
					if (host.name != host_name) { 
						// Skip
						return true;
					};
					//console.log('Found it!');
					$.each(host.network_interfaces, function(j, nic) {
						// Only real interfaces have a 'changed_order' value.
						if (nic.changed_order) {
							var say_link_state = say_down;
							if (nic.link_state == 1) {
								say_link_state = say_up;
							}
							body += '<tr class="data_row">';
							body += '<td class="column_row_value_fixed">'+nic.mac_address+'</td>';
							body += '<td class="column_row_value_fixed_centered">'+nic.name+'</td>';
							body += '<td class="column_row_value_fixed_centered">'+say_link_state+'</td>';
							body += '<td class="column_row_value_fixed_centered">'+nic.say_speed+'</td>';
							body += '<td class="column_row_value_fixed_centered">'+nic.changed_order+'</td>';
							body += '</tr>';
						}
					});
				});
				body += '</table>';
				
				// clear + append can't be the best way to do this... 
				$("#network_interface_table").empty();
				$("#network_interface_table").append(body);
			});
		}, 1000);
	};

})

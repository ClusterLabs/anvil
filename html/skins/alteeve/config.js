$.ajaxSetup({
    cache: false
});
$(function() { 
	var say_up           = $('#network_link_state').data('up');
	var say_down         = $('#network_link_state').data('down');
	var say_speed_suffix = $('#network_link_speed').data('mbps');
	//console.log('say_up: ['+say_up+'], say_down: ['+say_down+'], say_speed_suffix: ['+say_speed_suffix+']');
	if($("#network_status").length) {
		//console.log('network.json status file exists.');
		setInterval(function() {
			$.getJSON('/status/network.json', { get_param: 'value' }, function(data) {
				$.each(data.networks, function(index, element) {
					
					//console.log('entry: ['+index+'], name: ['+element.name+'], mac: ['+element.mac+'], link: ['+element.link+'], up order: ['+element.order+']');
					
					var link = say_up;
					if (element.link == 0) {
						link = say_down;
					}
					$("#"+element.name+"_mac").text(element.mac);
					$("#"+element.name+"_link").text(link);
					$("#"+element.name+"_speed").text(element.speed+' '+say_speed_suffix);
					$("#"+element.name+"_order").text(element.order);
				});
			});
		}, 1000);
	}
	else
	{
		//alert('network status strings not loaded.');
	}
	if($("#disk_status").length) {
		//alert('disk status exists.');
		//$("#bar").text('B');
	}
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
			//console.log('- entry: ['+index+'], on: ['+element.on+'], address: ['+element.address+'], subnet: ['+element.subnet+'].');
			//console.log('- gateway: ['+element.gateway+'], dns: ['+element.dns+'], default gateway: ['+element.default_gateway+'].');
			
			// If this is the default gateway, see about setting the Gateway IP and DNS.
			if (element.default_gateway == '1') {
				//console.log('This is the default gateway interface.');
				//console.log('- Form value for gateway......: ['+$("#gateway").val()+'] and dns: ['+$("#dns").val()+'].');
				//console.log('- Default values for gateway..: ['+$("#gateway_default").val()+'] and dns: ['+$("#dns_default").val()+'].');
				//console.log('- Interface values for gateway: ['+element.gateway+'] and dns: ['+element.dns+'].');
				if (($("#gateway").val() == '') && (element.gateway)) {
					$("#gateway").val(element.gateway);
				}
				if (($("#dns").val() == '') && (element.dns)) {
					$("#dns").val(element.dns);
				}
			}
			
			// Does this IP match any of the fields?
			if(element.on.match(new RegExp('_'))) {
				var network_prefix     = element.on.match(/^(.*)_/).pop();
				var network_ip_key     = network_prefix+'_ip'
				var network_subnet_key = network_prefix+'_subnet'
				//console.log('Matching: ['+network_ip_key+'] and: ['+network_subnet_key+'].');
				
				if ($("#"+network_ip_key).val() == '')
				{
					$("#"+network_ip_key).val(element.address);
				}
				if ($("#"+network_subnet_key).val() == '')
				{
					$("#"+network_subnet_key).val(element.subnet);
				}
			}
		});
		
		// If DNS or gateway are blank still and we have default values, set them.
		//console.log('Form value for gateway......: ['+$("#gateway").val()+'] and dns: ['+$("#dns").val()+'].');
		//console.log('Interface values for gateway: ['+$("#gateway_default").val()+'] and dns: ['+$("#dns_default").val()+'].');
		if (($("#gateway").val() == '') && ($("#gateway_default").val())) {
			$("#gateway").val($("#gateway_default").val());
		}
		if (($("#dns").val() == '') && ($("#dns_default").val())) {
			$("#dns").val($("#dns_default").val());
		}
		
		// Now set any other default IP/subnets
		jQuery.each("bcn sn ifn".split(" "), function(index, network) {
			//console.log('Network: ['+network+'].');
			if($("#"+network+"_count").val()) {
				var count = $("#"+network+"_count").val();
				//console.log(network+' count: ['+count+'].');
				for (var i = 1; i <= count; i++) {
					var network_name = network+i;
					//console.log('Network: ['+network_name+'], IP set: ['+$("#"+network_name+"_ip").val()+'/'+$("#"+network_name+"_subnet").val()+'].');
					//console.log('- default: ['+$("#"+network_name+"_ip_default").val()+'/'+$("#"+network_name+"_subnet_default").val()+'].');
					
					if ($("#"+network_name+"_ip").val() == '')
					{
						var ip = $("#"+network_name+"_ip_default").val();
						$("#"+network_name+"_ip").val(ip);
					}
					if ($("#"+network_name+"_subnet").val() == '')
					{
						var subnet = $("#"+network_name+"_subnet_default").val();
						$("#"+network_name+"_subnet").val(subnet);
					}
				};
			};
			
		});
		
		// Look for interfaces with names we recognize and use them to select interfaces from the 
		// select lists.
		$.each(data.networks, function(index, element) {
			//console.log('Entry: ['+index+'], name: ['+element.name+'], mac: ['+element.mac+'].');
			var mac_key = element.name+'_mac_to_set';
			if ($("#"+mac_key).length) {
				var select_value = $('#'+mac_key).find(":selected").text();
				//console.log('- Field exists, current value: ['+select_value+'].');
				if (select_value == '') {
					//console.log('- Setting to: ['+element.mac+'].');
					$("#"+mac_key).val(element.mac);
				}
			}
		});
	});
	
	$.getJSON('/status/jobs.json', { get_param: 'value' }, function(data) {
		$.each(data.ips, function(index, element) {
			//console.log('- entry: ['+index+'], on: ['+element.on+'], address: ['+element.address+'], subnet: ['+element.subnet+'].');
			//console.log('- gateway: ['+element.gateway+'], dns: ['+element.dns+'], default gateway: ['+element.default_gateway+'].');
		});
	});
})

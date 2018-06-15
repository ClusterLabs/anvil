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
	console.log('onload fired.');
	
	/*
	if($("#interface_list").val()) {
		var interface_list = $('#interface_list').val();
		console.log('Interface list: ['+interface_list+'].');
		jQuery.each(interface_list.split(","), function(index, item) {
			console.log('Interface: ['+item+'].');
		});
	}
	*/
	
	jQuery.each("bcn sn ifn".split(" "), function(index, network) {
		console.log('Network: ['+network+'].');
		if($("#"+network+"_count").val()) {
			var count = $("#"+network+"_count").val();
			console.log(network+' count: ['+count+'].');
			for (var i = 1; i <= count; i++) {
				var network_name = network+i;
				console.log('Network: ['+network_name+'], BCN IP set: ['+$("#"+network_name+"_ip").val()+'], default: ['+$("#"+network_name+"_ip_default").val()+'].');
				if ($("#"+network_name+"_ip").val() == '') {
					var set_ip      = '';
					var set_subnet  = '';
					var set_gateway = '';
					var set_dns     = '';
					$.getJSON('/status/network.json', { get_param: 'value' }, function(data) {
						$.each(data.ips, function(index, element) {
							var on_interface = element.on;
							if(on_interface.match(new RegExp(network_name))) {
								console.log('entry: ['+index+'], on: ['+element.on+'], address: ['+element.address+'], subnet: ['+element.subnet+'].');
								console.log('- gateway: ['+element.gateway+'], dns: ['+element.dns+'], default gateway: ['+element.default_gateway+'].');
								
								if (element.default_gateway == '1') {
									if ($("#gateway").val() == '') {
										$("#gateway").val(element.gateway);
									};
									if ($("#dns").val() == '') {
										$("#dns").var(element.dns);
									};
								};
							};
						});
					});
					var default_ip = $("#"+network_name+"_ip_default").val();
					console.log(network+' IP not set. Setting to: ['+default_ip+']');
					$("#"+network_name+"_ip").val(default_ip);
				};
			};
		};
	});
})

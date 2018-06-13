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
	
	if($("#bcn_count").val()) {
		var bcn_count = $("#bcn_count").val();
		console.log('BCN Count: ['+bcn_count+'].');
		for (var i = 1; i <= bcn_count; i++) {
			console.log('BCN IP set: ['+$("#bcn"+i+"_ip").val()+'], default: ['+$("#bcn"+i+"_ip_default").val()+'].');
			if ($("#bcn"+i+"_ip").val() == '') {
				var default_ip = $("#bcn"+i+"_ip_default").val();
				console.log('BCN IP not set. Setting to: ['+default_ip+']');
				$("#bcn"+i+"_ip").val(default_ip)
			}
		};
	}
})

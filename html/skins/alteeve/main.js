$(function() { 
	var say_up           = $("#say_up").text();
	var say_down         = $("#say_down").text();
	var say_speed_suffix = $("#say_speed_suffix").text();
	console.log('say_up: ['+say_up+'], say_down: ['+say_down+'], say_speed_suffix: ['+say_speed_suffix+']');
	if($("#network_status").length) {
		//alert('network status exists.');
		$.getJSON('/status/network.json', { get_param: 'value' }, function(data) {
			$.each(data.networks, function(index, element) {
				console.log('entry: ['+index+'], name: ['+element.name+'], mac: ['+element.mac+'], link: ['+element.link+']');
				var link = say_up;
				if (element.link == 0) {
					link = say_down;
				}
				$("#"+element.name+"_mac").text(element.mac);
				$("#"+element.name+"_link").text(link);
				$("#"+element.name+"_speed").text(element.speed+' '+say_speed_suffix);
			});
		});    
	}
	if($("#disk_status").length) {
		//alert('disk status exists.');
		//$("#bar").text('B');
	}
});

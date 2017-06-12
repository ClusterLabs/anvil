$(function() { 
	var say_up   = "Up";
	var say_down = "Down";
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
			});
		});    
	}
	if($("#disk_status").length) {
		//alert('disk status exists.');
		//$("#bar").text('B');
	}
});

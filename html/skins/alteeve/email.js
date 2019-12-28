$.ajaxSetup({
    cache: false
});
$(function() { 
	//console.log('Load');
	if ($('#connection_security').length) {
		//console.log('connection_security select exists');
		$("#connection_security").change(function(){
			var connection_security_value = $("#connection_security").val();
			var port_value                = $("#port").val();
			//console.log('connection_security changed: ['+connection_security_value+'], port was: ['+port_value+']');
			if (connection_security_value == 'ssl_tls') {
				if (port_value != '993') {
					$("#port").val('993');
					//console.log('port changed to: ['+$("#port").val()+']');
				}
			}
			else {
				if (port_value != '143') {
					$("#port").val('143');
					//console.log('port changed to: ['+$("#port").val()+']');
				}
			}
		});
	}
});

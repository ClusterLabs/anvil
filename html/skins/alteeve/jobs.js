$.ajaxSetup({
    cache: false
});
// TODO: Loop through jobs found on HTML and hide and divs that aren't found in jobs.json.
$(function() { 
	var say_status_waiting = $('input#status_waiting').val();
	//console.log('say_status_waiting: ['+say_status_waiting+']');
	if($("#running_jobs").length) {
		//console.log('Looking for running jobs.');
		setInterval(function() {
			$.getJSON('/status/jobs.json', { get_param: 'value' }, function(data) {
				//console.log('"/status/jobs.json" read.');
				$.each(data.jobs, function(index, element) {
					
					var progress      = element.job_progress;
					var status        = element.job_status;
					var status_length = status.length;
					//console.log('entry: ['+index+'], uuid: ['+element.job_uuid+'], progress: ['+progress+']');
					
					// Show the status, if there is any yet.
					if (!status.length)
					{
						$("#job_status_"+element.job_uuid).removeClass('job_output');
						$("#job_status_"+element.job_uuid).addClass('subtle_text');
						$("#job_status_"+element.job_uuid).html('&lt;'+say_status_waiting+'&gt;');
						//console.log('status is waiting');
					}
					else
					{
						$("#job_status_"+element.job_uuid).removeClass('subtle_text');
						$("#job_status_"+element.job_uuid).addClass('job_output');
						$("#job_status_"+element.job_uuid).html(status);
						//console.log('status: ['+status+']');
					}
					
					// Push data
					$("#job_progress_"+element.job_uuid).progressbar({value: parseInt(element.job_progress)});
					$("#job_progress_percent_"+element.job_uuid).html(element.job_progress+'%');
				});
			});
		}, 1000);
	}
	else
	{
		//console.log('"running_jobs" div not found.');
	}
});

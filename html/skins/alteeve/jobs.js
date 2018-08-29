$.ajaxSetup({
    cache: false
});
$(function() { 
	if($("#running_jobs").length) {
		console.log('Looking for running jobs.');
		setInterval(function() {
			$.getJSON('/status/jobs.json', { get_param: 'value' }, function(data) {
				$.each(data.jobs, function(index, element) {
					
					var progress = element.job_progress
					console.log('entry: ['+index+'], uuid: ['+element.job_uuid+'], progress: ['+progress+']');
					//console.log('status: ['+element.job_status+']');
					
					// Initialize
					$("#job_progress_"+element.job_uuid).progressbar({value: parseInt(element.job_progress)});
					$("#job_status_"+element.job_uuid).html(element.job_status);
				});
			});
		}, 1000);
	}
	else
	{
		alert('Jobs status not loaded.');
	}
});

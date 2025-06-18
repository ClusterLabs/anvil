package Anvil::Tools::Job;
# 
# This module contains methods used in job handling
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Job.pm";

### Methods;
# bump_progress
# clear
# get_job_details
# get_job_uuid
# html_list
# running
# update_progress

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Job

Provides methods related to (background) job handling.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # ...

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		JOB	=>	{
			LANGUAGE	=>	"",
		},
	};
	
	bless $self, $class;
	
	return ($self);
}

# Get a handle on the Anvil::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	# Defend against memory leads. See Scalar::Util'.
	if (not isweak($self->{HANDLE}{TOOLS}))
	{
		weaken($self->{HANDLE}{TOOLS});
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 bump_progress

This method is meant to make it easier to bump the progress of a jump by some number of steps when a job doesn't run in a linear fashion. 

It does this by storing the progress in the C<< sys::job_progress >> hash and incrementing it by the C<< steps >> parameter value (setting it to C<< 0 >> if it doesn't exist or exists with a non-digit value). If the progress goes over C<< 99 >>, it will return C<< 99 >>. 

If you want to set the progress to C<< 0 >> or C<< 100 >>, use the C<< set >> parameter.

Parameters;

=head3 set (optional)

If you want to set the progress to a specific value, use this parameter. 

B<< NOTE >>: If the set value is less than the current value, the current progress + 1 will be returns. This is meant to prevent progress bars from backing up.

=head3 steps (default '1')

This takes an integer and it will increase the job progress by that value. If this is not specified, or if it is set to a non-integer value, C<< 1 >> will be used.

=cut
sub bump_progress
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->bump_progress()" }});
	
	my $set   = defined $parameter->{set}   ? $parameter->{set}   : "";
	my $steps = defined $parameter->{steps} ? $parameter->{steps} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		set   => $set,
		steps => $steps, 
	}});
	
	if ((not exists $anvil->data->{sys}{job_progress}) or ($anvil->data->{sys}{job_progress} !~ /^\d+$/))
	{
		$anvil->data->{sys}{job_progress} = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::job_progress" => $anvil->data->{sys}{job_progress},
		}});
	}
	
	if ($set =~ /^\d+$/)
	{
		if ($set > 100)
		{
			$anvil->data->{sys}{job_progress} = 100;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::job_progress" => $anvil->data->{sys}{job_progress},
			}});
		}
		elsif ($set > $anvil->data->{sys}{job_progress})
		{
			$anvil->data->{sys}{job_progress}++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::job_progress" => $anvil->data->{sys}{job_progress},
			}});
		}
	}
	
	$anvil->data->{sys}{job_progress} += $steps;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::job_progress" => $anvil->data->{sys}{job_progress},
	}});
	if ($anvil->data->{sys}{job_progress} > 99)
	{
		$anvil->data->{sys}{job_progress} = 99;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::job_progress" => $anvil->data->{sys}{job_progress},
		}});
	}
	
	return($anvil->data->{sys}{job_progress});
}


=head2 clear

This clears the C<< job_picked_up_by >> value for the given job.

Parameters;

=head3 job_uuid (required)

This is the C<< job_uuid >> of the job to clear.

=cut
sub clear
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->clear()" }});

	my $job_uuid = defined $parameter->{job_uuid} ? $parameter->{job_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	
	if ((not $job_uuid) && ($anvil->data->{switches}{'job-uuid'}))
	{
		$job_uuid = $anvil->data->{switches}{'job-uuid'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	}
	
	# Return if we don't have a program name.
	if ($job_uuid eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Job->clear()", parameter => "job_uuid" }});
		return(1);
	}
	
	$job_uuid = $anvil->Job->update_progress({
		debug    => $debug,
		file     => $THIS_FILE, 
		line     => __LINE__, 
		progress => 0, 
		message  => "clear",
		job_uuid => $job_uuid,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { job_uuid => $job_uuid }});
	
	return(0);
}

=head2 get_job_details

This takes a C<< job_uuid >> and returns the job's details. If the job is found, C<< 0 >> is returned. If it isn't found, C<< 1 >> is returned. If it is found, but C<< check >> was set and the process is still alive, C<< 2 >> is returned.

When successful, the job details will be stored in;

* C<< jobs::job_uuid >>
* C<< jobs::job_host_uuid >>
* C<< jobs::job_command >>
* C<< jobs::job_data >>
* C<< jobs::job_updated >>
* C<< jobs::job_picked_up_by >>
* C<< jobs::job_picked_up_at >>
* C<< jobs::job_name >>
* C<< jobs::job_progress >>
* C<< jobs::job_title >>
* C<< jobs::job_description >>
* C<< jobs::job_status >>
* C<< jobs::modified_date >>  (unix time)
* C<< jobs::job_age >>        (seconds)

B<< Note >>; This is how long ago the job was requested (or last updated) in seconds.

Parameters;

=head3 check (optional, default '1')

This checks to see if the job was picked up by a program that is still running. If set to C<< 1 >> and that process is running, this method will return C<< 2 >>. If set to C<< 0 >>, the job data will be loaded (if found) and C<< 0 >> will be returned.

=head3 job_uuid (optional)

This is the job UUID to pull up. If not passed, first a check is made to see if C<< --job-uuid >> was passed. If not, a check is made in the database for any pending jobs assigned to this host and whose C<< job_command >> matches the calling program.

=cut
sub get_job_details
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->get_job_details()" }});

	my $check    = defined $parameter->{check}    ? $parameter->{check}    : "";
	my $job_uuid = defined $parameter->{job_uuid} ? $parameter->{job_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		check    => $check,
		job_uuid => $job_uuid,
	}});
	
	if ((not $job_uuid) && ($anvil->data->{switches}{'job-uuid'}))
	{
		$job_uuid = $anvil->data->{switches}{'job-uuid'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	}
	
	# Were we passed a job uuid?
	if (not $job_uuid)
	{
		# Try to find a job in the database.
		my $command = $0."%";
		my $query = "
SELECT 
    job_uuid
FROM 
    jobs 
WHERE 
    job_host_uuid =  ".$anvil->Database->quote($anvil->Get->host_uuid)."
AND 
    job_progress  != 100
AND 
    job_command LIKE ".$anvil->Database->quote($command)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$job_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
		}
		
		if (not $job_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, secure => 0, key => "error_0032", variables => { switch => '--job-uuid' } });
			return(1);
		}
	}
	
	if (not $anvil->Validate->uuid({uuid => $job_uuid}))
	{
		# It's not a UUID.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, secure => 0, key => "error_0033", variables => { uuid => $job_uuid } });
		return(1);
	}
	
	if (not $anvil->data->{switches}{'job-uuid'})
	{
		# Set the switch variable.
		$anvil->data->{switches}{'job-uuid'} = $job_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'switches::job-uuid' => $anvil->data->{switches}{'job-uuid'} }});
	}
	
	# If I'm here, see if we can read the job details.
	my $query = "
SELECT 
    job_host_uuid, 
    job_command, 
    job_data, 
    job_picked_up_by, 
    job_picked_up_at, 
    job_updated, 
    job_name,
    job_progress, 
    job_title, 
    job_description, 
    job_status, 
    round(extract(epoch from modified_date)) AS unix_modified_date 
FROM 
    jobs 
WHERE 
    job_uuid = ".$anvil->Database->quote($job_uuid)." 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count < 1)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, secure => 0, key => "error_0034", variables => { uuid => $job_uuid } });
		$anvil->nice_exit({exit_code => 2});
	}
	
	# If we're here, we're good. Load the details
	$anvil->data->{jobs}{job_uuid}         = $job_uuid;
	$anvil->data->{jobs}{job_host_uuid}    = defined $results->[0]->[0]  ? $results->[0]->[0]  : "";
	$anvil->data->{jobs}{job_command}      = defined $results->[0]->[1]  ? $results->[0]->[1]  : "";
	$anvil->data->{jobs}{job_data}         = defined $results->[0]->[2]  ? $results->[0]->[2]  : "";
	$anvil->data->{jobs}{job_picked_up_by} = defined $results->[0]->[3]  ? $results->[0]->[3]  : "";
	$anvil->data->{jobs}{job_picked_up_at} = defined $results->[0]->[4]  ? $results->[0]->[4]  : "";
	$anvil->data->{jobs}{job_updated}      = defined $results->[0]->[5]  ? $results->[0]->[5]  : "";
	$anvil->data->{jobs}{job_name}         = defined $results->[0]->[6]  ? $results->[0]->[6]  : "";
	$anvil->data->{jobs}{job_progress}     = defined $results->[0]->[7]  ? $results->[0]->[7]  : "";
	$anvil->data->{jobs}{job_title}        = defined $results->[0]->[8]  ? $results->[0]->[8]  : "";
	$anvil->data->{jobs}{job_description}  = defined $results->[0]->[9]  ? $results->[0]->[9]  : "";
	$anvil->data->{jobs}{job_status}       = defined $results->[0]->[10] ? $results->[0]->[10] : "";
	$anvil->data->{jobs}{modified_date}    =         $results->[0]->[11];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"jobs::job_uuid"         => $anvil->data->{jobs}{job_uuid}, 
		"jobs::job_host_uuid"    => $anvil->data->{jobs}{job_host_uuid},
		"jobs::job_command"      => $anvil->data->{jobs}{job_command},
		"jobs::job_data"         => $anvil->data->{jobs}{job_data}, 
		"jobs::job_picked_up_by" => $anvil->data->{jobs}{job_picked_up_by}, 
		"jobs::job_picked_up_at" => $anvil->data->{jobs}{job_picked_up_at}, 
		"jobs::job_updated"      => $anvil->data->{jobs}{job_updated}, 
		"jobs::job_name"         => $anvil->data->{jobs}{job_name}, 
		"jobs::job_progress"     => $anvil->data->{jobs}{job_progress}, 
		"jobs::job_title"        => $anvil->data->{jobs}{job_title}, 
		"jobs::job_description"  => $anvil->data->{jobs}{job_description}, 
		"jobs::job_status"       => $anvil->data->{jobs}{job_status}, 
		"jobs::modified_date"    => $anvil->data->{jobs}{modified_date}, 
	}});
	
	$anvil->data->{jobs}{job_age} = 0;
	if ($anvil->data->{jobs}{modified_date})
	{
		my $current_time                 = time;
		   $anvil->data->{jobs}{job_age} = $current_time - $anvil->data->{jobs}{modified_date};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			current_time    => $current_time, 
			"jobs::job_age" => $anvil->data->{jobs}{job_age}, 
		}});
	}
	
	# See if the job was picked up by another running instance.
	my $job_picked_up_by = $anvil->data->{jobs}{job_picked_up_by};
	if (($check) && ($job_picked_up_by))
	{
		# Check if the PID is still active.
		$anvil->System->pids({ignore_me => 1});
		
		# Is the PID that picked up the job still alive?
		if (exists $anvil->data->{pids}{$job_picked_up_by})
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0146", variables => { pid => $job_picked_up_by }});
			return(2);
		}
	}
	
	return(0);
}

=head2 get_job_uuid

This takes the name of a program and looks in jobs for a pending job with the same command. If it is found, C<< jobs::job_uuid >> is set and the C<< job_uuid >> is returned. If no job is found, and empty string is returned.

Parameters;

=head3 host_uuid (optional, default Get->host_uuid())

If set, this will search for the job on a specific host.

=head3 incomplete (optional, default '0')

If set to C<< 1 >>, any job that is incomplete (C<< job_progress < 100 >>) is searched. If set to C<< 0 >>, only job that have not started (C<< job_progress = 0 >>) are searched.

=head3 program (required)

This is the program name to look for. Specifically, this string is used to search C<< job_command >> (anchored to the start of the column and a wild-card end, ie: C<< program => foo >> would find C<< foobar >> or C<< foo --bar >>). Be as specific as possible. If two or more results are found, no C<< job_uuid >> will be returned. There must be only one match for this method to work properly.

=cut
sub get_job_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->get_job_uuid()" }});
	
	my $job_uuid   = "";
	my $host_uuid  = defined $parameter->{host_uuid}  ? $parameter->{host_uuid}  : $anvil->Get->host_uuid;
	my $incomplete = defined $parameter->{incomplete} ? $parameter->{incomplete} : 0;
	my $program    = defined $parameter->{program}    ? $parameter->{program}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid  => $host_uuid, 
		incomplete => $incomplete, 
		program    => $program,
	}});
	
	# Return if we don't have a program name.
	if ($program eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Job->get_job_uuid()", parameter => "program" }});
		return(1);
	}
	
	my $say_progress = $incomplete ? "< 100" : "= 0";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_progress => $say_progress }});
	
	my $query = "
SELECT 
    job_uuid 
FROM 
    jobs 
WHERE 
    job_command LIKE ".$anvil->Database->quote("%".$program."%")." 
AND 
    job_progress  ".$say_progress."
AND 
    job_host_uuid = ".$anvil->Database->quote($host_uuid)." 
LIMIT 1
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count == 1)
	{
		# Found it
		$job_uuid                        = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$anvil->data->{jobs}{'job-uuid'} = $job_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			job_uuid         => $job_uuid, 
			"jobs::job-uuid" => $anvil->data->{jobs}{'job-uuid'},
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { job_uuid => $job_uuid }});
	return($job_uuid);
}

=head2 running

This simple returns C<< 1 >> if one or more jobs are pending or running on this host. If none are (or all are at 100%), it returns C<< 0 >>.

This method takes no parameters

=cut
sub running
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->running()" }});

	my $query        = "
SELECT 
    COUNT(*) 
FROM 
    jobs 
WHERE 
    job_progress != '100'
AND 
    job_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)." 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results   = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $job_count = $results->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results   => $results, 
		job_count => $job_count, 
	}});
	
	my $jobs_running = $job_count ? 1 : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { jobs_running => $jobs_running }});
	return($jobs_running);
}

=head2 html_list

This returns an html form list of jobs that are running or recently ended.

Parameters;

=head3 ended_within (optional, default '300')

This gets a list of all jobs that are running, or that have ended within this number of seconds.

=cut
sub html_list
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->html_list()" }});

	my $ended_within = defined $parameter->{ended_within} ? $parameter->{ended_within} : 300;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ended_within => $ended_within, 
	}});
	
	my $jobs_list = "#!string!striker_0097!#";
	my $return = $anvil->Database->get_jobs({ended_within => 300});
	my $count  = @{$return};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
	if ($count)
	{
		$jobs_list = "";
		foreach my $hash_ref (@{$return})
		{
			my $job_uuid            = $hash_ref->{job_uuid};
			my $job_command         = $hash_ref->{job_command};
			my $job_data            = $hash_ref->{job_data};
			my $job_picked_up_by    = $hash_ref->{job_picked_up_by};
			my $job_picked_up_at    = $hash_ref->{job_picked_up_at};
			my $job_updated         = $hash_ref->{job_updated};
			my $job_name            = $hash_ref->{job_name};
			my $job_progress        = $hash_ref->{job_progress};
			my $job_title           = $hash_ref->{job_title};
			my $job_description     = $hash_ref->{job_description};
			my $job_status          = $hash_ref->{job_status};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				job_uuid            => $job_uuid,
				job_command         => $job_command,
				job_data            => $job_data,
				job_picked_up_by    => $job_picked_up_by,
				job_picked_up_at    => $job_picked_up_at,
				job_updated         => $job_updated,
				job_name            => $job_name, 
				job_progress        => $job_progress,
				job_title           => $job_title, 
			}});
			
			# Skip jobs that finished more than five minutes ago.
			my $job_finished = time - $job_updated;
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:time'         => time,
				's2:job_updated'  => $job_updated,
				's3:job_finished' => $job_finished,
			}});
			if (($job_progress eq "100") && ($job_finished > 600))
			{
				# Skip it
				next;
			}
			
			# Convert the double-banged strings into a proper message.
			my $say_title       = $job_title       ? $anvil->Words->parse_banged_string({debug => $debug, key_string => $job_title})       : "";
			my $say_description = $job_description ? $anvil->Words->parse_banged_string({debug => $debug, key_string => $job_description}) : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				job_title       => $job_title, 
				say_description => $say_description, 
			}});
			
			### TODO: left off here
			my $job_template = $anvil->Template->get({file => "striker.html", name => "job-details", variables => {
				div_id           => "job_".$job_uuid, 
				title            => $say_title, 
				description      => $say_description, 
				progress_bar     => "job_progress_".$job_uuid, 
				progress_percent => "job_progress_percent_".$job_uuid, 
				status           => "job_status_".$job_uuid,
			}});
			
			$jobs_list .= $job_template."\n";
		}
	}
	
	return($jobs_list);
}

=head2 update_progress

This updates the progress if we were called with a job UUID.

This also sets C<< sys::last_update >>, allowing you to see how long it's been since the progress was last updated and trigger an update on a time based counter.

Returns C<< 0 >> on success, C<< 1 >> on failure.

B<< Note >>: Some special C<< job_status >> processing is done to support some specific callers. These should not impact generic calls of this method.

Parameters;

=head3 file (optional)

When logging as well, this is the file causing the update. Use with C<< line >>. Ignored if C<< log_level >> is not set, or such that it wouldn't be logged anyway.

=head3 job_uuid (optional, default 'jobs::job_uuid')

This is the UUID of the job to update. If it isn't set, but C<< jobs::job_uuid >> is set, it will be used. If that is also not set, 

=head3 line (optional)

When logging as well, this is the line the update came from. Use with C<< file >>. Ignored if C<< log_level >> is not set, or such that it wouldn't be logged anyway.

=head3 log_level (optional)

If set to a numeric level, the job's message will also be logged. This is designed to simplify code as most job progress messages will also want to be logged.

=head3 message (optional)

If set, this message will be appended to C<< job_status >>. If set to 'C<< clear >>', previous records will be removed.

NOTE: This is in the format C<< <key>[,!!<variable_name1>!<variable_value1>[,...,!!<variable_nameN>!<variable_valueN>!!]] >>. Example; C<< foo_0001 >> or C<< foo_0002,!!bar!baz!! >>.

=head3 picked_up_by (optional, default '$$' (caller's PID))

If set, this is used for the C<< job_picked_up_by >> column. If it isn't set, the process ID of the caller is used.

=head3 print (optional, default '1')

If C<< log_level >> is set, this can be set to C<< 1 >> to print the log entry to STDOUT, or C<< 0 >> to not.

=head3 priority (optional)

If C<< log_level >> is set, this can be set to the priority to use when logging (see C<< Alert->entry >>).

=head3 progress (required)

This is a number to set the current progress to. 

=head3 secure (optional, default '0')

If C<< log_level >> is set, this can be set to C<< 1 >> to indicate that it contains sensitive data, like a password.

=head3 variables (optional)

This can be set as a hash reference containing key / variable pairs to inject into the message key. the C<< variable => value >> pairs will be appended to the C<< message >> key automatically. This is meant to simplify when an alert is also being longed, or when a large number of variables are being injected into the string.

=cut
sub update_progress
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Job->update_progress()" }});

	my $file         = defined $parameter->{file}         ? $parameter->{file}         : $THIS_FILE;
	my $job_uuid     = defined $parameter->{job_uuid}     ? $parameter->{job_uuid}     : "";
	my $line         = defined $parameter->{line}         ? $parameter->{line}         : __LINE__;
	my $log_level    = defined $parameter->{log_level}    ? $parameter->{log_level}    : "";
	my $message      = defined $parameter->{message}      ? $parameter->{message}      : "";
	my $picked_up_by = defined $parameter->{picked_up_by} ? $parameter->{picked_up_by} : "";
	my $print        = defined $parameter->{'print'}      ? $parameter->{'print'}      : 1;
	my $priority     = defined $parameter->{priority}     ? $parameter->{priority}     : "";
	my $progress     = defined $parameter->{progress}     ? $parameter->{progress}     : "";
	my $secure       = defined $parameter->{secure}       ? $parameter->{secure}       : "";
	my $variables    = defined $parameter->{variables}    ? $parameter->{variables}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file         => $file, 
		job_uuid     => $job_uuid, 
		line         => $line, 
		log_level    => $log_level, 
		picked_up_by => $picked_up_by, 
		'print'      => $print, 
		progress     => $progress,
		message      => $message, 
		variables    => $variables, 
		secure       => $secure, 
	}});
	
	# Log before anything else, in case we abort the job update.
	if (($message ne "clear") && ($log_level =~ /^\d+$/))
	{
		# Log this message.
		$anvil->Log->entry({source => $file, line => $line, level => $log_level, 'print' => $print, secure => $secure, priority => $priority, key => $message, variables => $variables});
	}
	
	if ($picked_up_by eq "")
	{
		$picked_up_by = $$;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { picked_up_by => $picked_up_by }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	if ((not $job_uuid) && ($anvil->data->{jobs}{job_uuid}))
	{
		$job_uuid = $anvil->data->{jobs}{job_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	}
	if ((not $job_uuid) && ($anvil->data->{switches}{'job-uuid'}))
	{
		$job_uuid = $anvil->data->{switches}{'job-uuid'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	}
	
	# Return if we still don't have a job_uuid. This isn't unexpected as some programs can run with or 
	# without a job_uuid.
	if (not $job_uuid)
	{
		# Nothing we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0207"});
		return(1);
	}
	
	# Return if we don't have a progress.
	if ($progress eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Job->update_progress()", parameter => "progress" }});
		return(1);
	}
	
	# Is the progress valid?
	if (($progress =~ /\D/) or ($progress < 0) or ($progress > 100))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0209", variables => { progress => $progress }});
		return(1);
	}
	
	# If 'sys::last_update' isn't set, set it now.
	if (not defined $anvil->data->{sys}{last_update})
	{
		$anvil->data->{sys}{last_update} = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::last_update" => $anvil->data->{sys}{last_update} }});
	}
	
	# If we don't have a database connection, we're done.
	if (not $anvil->data->{sys}{database}{connections})
	{
		return(0);
	}
	
	# Add variables to the message, if required
	if (ref($variables) eq "HASH")
	{
		foreach my $variable (sort {$a cmp $b} keys %{$variables})
		{
			my $value   =  defined $variables->{$variable} ? $variables->{$variable} : "undefined:".$variable;
			   $message .= ",!!".$variable."!".$value."!!";
		}
	}
	
	# Get the current job_status and append this new one.
	my $job_picked_up_at = 0;
	my $job_status       = "";
	my $clear_status     = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { message => $message, picked_up_by => $picked_up_by }});
	if ($message eq "clear")
	{
		$picked_up_by = $$;
		$clear_status = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			picked_up_by => $picked_up_by,
			clear_status => $clear_status, 
		}});
	}
	else
	{
		my $query = "
SELECT 
    job_status, 
    job_picked_up_at
FROM 
    jobs 
WHERE 
    job_uuid = ".$anvil->Database->quote($job_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		if (not $count)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0208", variables => {job_uuid => $job_uuid}});
			return(1);
		}
		
		$job_status       = $results->[0]->[0];
		$job_picked_up_at = $results->[0]->[1];
		$job_status       = "" if not defined $job_status;
		$job_picked_up_at = 0  if not defined $job_picked_up_at;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			job_status       => $job_status,
			job_picked_up_at => $job_picked_up_at,
		}});
		
		# Set that the job is now picked up if the progress is '1' or it 'job_picked_up_at' 
		# is not set yet.
		if ((not $job_picked_up_at) or ($progress eq "1"))
		{
			$job_picked_up_at = time;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_picked_up_at => $job_picked_up_at }});
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { message => $message }});
		if (($message) && ($job_status))
		{
			$job_status .= "\n";
		}
		if ($message)
		{
			$job_status .= $message;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_status => $job_status }});
		}
	}
	
	### NOTE: This is used by 'anvil-update-system'. It should be moved back over to it later.
	# Insert counts
	if ($job_status =~ /message_0058/gs)
	{
		my $downloaded = $anvil->data->{counts}{downloaded} ? $anvil->Convert->add_commas({number => $anvil->data->{counts}{downloaded}}) : 0;
		my $installed  = $anvil->data->{counts}{installed}  ? $anvil->Convert->add_commas({number => $anvil->data->{counts}{installed}})  : 0;
		my $verified   = $anvil->data->{counts}{verified}   ? $anvil->Convert->add_commas({number => $anvil->data->{counts}{verified}})   : 0;
		my $lines      = $anvil->data->{counts}{lines}      ? $anvil->Convert->add_commas({number => $anvil->data->{counts}{lines}})      : 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:counts::downloaded" => $anvil->data->{counts}{downloaded},
			"s2:downloaded"         => $downloaded, 
			"s3:counts::installed"  => $anvil->data->{counts}{installed},
			"s4:installed"          => $installed, 
			"s5:counts::verified"   => $anvil->data->{counts}{verified},
			"s6:verified"           => $verified, 
			"s7:counts::lines"      => $anvil->data->{counts}{lines},
			"s8:lines"              => $lines, 
		}});
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ">> job_status" => $job_status }});
		$job_status =~ s/message_0058,!!downloaded!.*?!!,!!installed!.*?!!,!!verified!.*?!!,!!lines!.*?!!/message_0058,!!downloaded!$downloaded!!,!!installed!$installed!!,!!verified!$verified!!,!!lines!$lines!!/sm;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "<< job_status" => $job_status }});
	}
	
	$job_uuid = $anvil->Database->insert_or_update_jobs({
		file                 => $THIS_FILE, 
		line                 => __LINE__, 
		debug                => 2,	### TODO: Put this back to '$debug'
		update_progress_only => 1,
		clear_status         => $clear_status, 
		job_uuid             => $job_uuid, 
		job_picked_up_by     => $picked_up_by, 
		job_picked_up_at     => $job_picked_up_at,
		job_progress         => $progress, 
		job_status           => $job_status, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	
	# Note this update time
	$anvil->data->{sys}{last_update} = time;
	
	return(0);
}


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

1;

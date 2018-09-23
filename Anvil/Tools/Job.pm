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
# clear
# get_job_uuid
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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

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

	my $job_uuid = defined $parameter->{job_uuid} ? $parameter->{job_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	
	# Return if we don't have a program name.
	if ($job_uuid eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Job->clear()", parameter => "job_uuid" }});
		return(1);
	}
	
	my $query = "
UPDATE 
    jobs 
SET 
    job_picked_up_by = '0', 
    change_date    = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    job_uuid         = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)." 
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
	$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	
	return(0);
}

=head2 get_job_uuid

This takes the name of a program and looks in jobs for a pending job with the same command. If it is found, C<< jobs::job_uuid >> is set and the C<< job_uuid >> is returned. If no job is found, and empty string is returned.

Parameters;

=head3 host_uuid (optional, default Get->host_uuid())

If set, this will search for the job on a specific host.

=head3 program (required)

This is the program name to look for. Specifically, this string is used to search C<< job_command >> (anchored to the start of the column and a wild-card end, ie: C<< program => foo >> would find C<< foobar >> or C<< foo --bar >>). Be as specific as possible. If two or more results are found, no C<< job_uuid >> will be returned. There must be only one match for this method to work properly.

=cut
sub get_job_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;

	my $job_uuid  = "";
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	my $program   = defined $parameter->{program}   ? $parameter->{program}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid => $host_uuid, 
		program   => $program,
	}});
	
	# Return if we don't have a program name.
	if ($program eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Job->get_job_uuid()", parameter => "program" }});
		return(1);
	}
	
	my $query = "
SELECT 
    job_uuid 
FROM 
    jobs 
WHERE 
    job_command LIKE ".$anvil->data->{sys}{database}{use_handle}->quote($program."%")." 
AND 
    job_progress != '100'
AND 
    job_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($host_uuid)." 
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
		$job_uuid                      = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$anvil->data->{jobs}{job_uuid} = $job_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			job_uuid         => $job_uuid, 
			"jobs::job-uuid" => $anvil->data->{jobs}{'job-uuid'},
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { job_uuid => $job_uuid }});
	return($job_uuid);
}

=head2 update_progress

This updates the progress if we were called with a job UUID.

This also sets C<< sys::last_update >>, allowing you to see how long it's been since the progress was last updated and trigger an update on a time based counter.

Returns C<< 0 >> on success, C<< 1 >> on failure.

B<< Note >>: Some special C<< job_status >> processing is done to support some specific callers. These should not impact generic calls of this method.

Parameters;

=head3 job_uuid (optional, default 'jobs::job_uuid')

This is the UUID of the job to update. If it isn't set, but C<< jobs::job_uuid >> is set, it will be used. If that is also not set, 

=head3 message (optional)

If set, this message will be appended to C<< job_status >>. If set to 'C<< clear >>', previous records will be removed.

=head3 progress (required)

This is a number to set the current progress to. 

=cut
sub update_progress
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;

	my $job_uuid = defined $parameter->{job_uuid} ? $parameter->{job_uuid} : "";
	my $message  = defined $parameter->{message}  ? $parameter->{message}  : "";
	my $progress = defined $parameter->{progress} ? $parameter->{progress} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		progress         => $progress,
		message          => $message, 
		job_uuid         => $job_uuid, 
		"jobs::job_uuid" => $anvil->data->{jobs}{job_uuid}, 
	}});
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	if ((not $job_uuid) && ($anvil->data->{jobs}{job_uuid}))
	{
		$job_uuid = $anvil->data->{jobs}{job_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	}
	
	# Return if we still don't have a job_uuid
	if (not $job_uuid)
	{
		# Nothing we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0207"});
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
	
	# Get the current job_status and append this new one.
	my $job_picked_up_by = $$;
	my $job_picked_up_at = 0;
	my $job_status       = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { message => $message, job_picked_up_by => $job_picked_up_by }});
	if ($message eq "clear")
	{
		$job_picked_up_by = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_picked_up_by => $job_picked_up_by }});
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
    job_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)."
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
	
	### NOTE: This is used by 'anvil-update-system'.
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
	
	my $query = "
UPDATE 
    jobs 
SET 
    job_picked_up_by = ".$anvil->data->{sys}{database}{use_handle}->quote($job_picked_up_by).", 
    job_picked_up_at = ".$anvil->data->{sys}{database}{use_handle}->quote($job_picked_up_at).",
    job_updated      = ".$anvil->data->{sys}{database}{use_handle}->quote(time).",
    job_progress     = ".$anvil->data->{sys}{database}{use_handle}->quote($progress).", 
    job_status       = ".$anvil->data->{sys}{database}{use_handle}->quote($job_status).", 
    change_date    = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    job_uuid         = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)." 
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	
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

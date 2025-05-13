package Anvil::Tools::ScanCore;
# 
# This module contains methods used to handle message processing related to support of multi-lingual use.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use Text::Diff;

our $VERSION  = "3.0.0";
my $THIS_FILE = "ScanCore.pm";

### Methods;
# agent_shutdown
# agent_startup
# call_scan_agents
# check_health
# check_power
# check_temperature
# check_temperature_direct
# count_servers
# post_scan_analysis
# post_scan_analysis_dr
# post_scan_analysis_node
# post_scan_analysis_striker
# _scan_directory

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::ScanCore

Provides all methods related to ScanCore and scan agents.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->ScanCore->X'. 
 # 
 # Example using 'agent_startup()';
 my $foo_path = $anvil->ScanCore->read({file => $anvil->data->{path}{words}{'anvil.xml'}});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {};
	
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


=head2 agent_shutdown

This method handles recording run data to the agent's data file.

Parameters;

=head3 agent (required)

This is the name of the scan agent. Usually this can be set as C<< $THIS_FILE >>.

=cut
sub agent_shutdown
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->agent_shutdown()" }});
	
	my $agent = defined $parameter->{agent} ? $parameter->{agent} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		agent => $agent, 
	}});
	
	# Setting this will prepend messages coming grom the agent with the agent's name
	$anvil->data->{'log'}{scan_agent} = $agent;
	
	# If this agent ran before, it should have recorded how many databases it last connected to. Read 
	# that, if so.
	my $data_file = $anvil->data->{path}{directories}{temp}."/".$agent.".data";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { data_file => $data_file }});
	
	my $file_body  = "last_run:".time."\n";
	   $file_body .= "last_db_count:".$anvil->data->{sys}{database}{connections}."\n";
	my $error = $anvil->Storage->write_file({
		debug     => $debug,
		file      => $data_file, 
		body      => $file_body,
		overwrite => 1, 
		backup    => 0,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
	
	# Mark that we ran.
	$anvil->Database->insert_or_update_updated({updated_by => $agent});

	$anvil->nice_exit({exit_code => 0});
	
	return(0);
}

=head2 agent_startup

This method handles connecting to the databases, loading the agent's schema, resync'ing database tables if needed and reading in the words files.

If there is a problem, this method exits with C<< 1 >>. Otherwise, it exits with C<< 0 >>.

Parameters;

=head3 agent (required)

This is the name of the scan agent. Usually this can be set as C<< $THIS_FILE >>.

=head3 no_db_ok (optional, default 0)

If set to C<< 1 >>, if no database connections are available but otherwise the startup is OK, C<< 0 >> (no problem) is returned.

=head3 tables (required)

This is an array reference of database tables to check when resync'ing. It is important that the tables are sorted in the order they need to be resync'ed in. (tables with primary keys before their foreign key tables).

=cut
sub agent_startup
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->agent_startup()" }});
	
	my $agent    = defined $parameter->{agent}    ? $parameter->{agent}    : "";
	my $no_db_ok = defined $parameter->{no_db_ok} ? $parameter->{no_db_ok} : "";
	my $tables   = defined $parameter->{tables}   ? $parameter->{tables}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		agent    => $agent, 
		no_db_ok => $no_db_ok, 
		tables   => $tables, 
	}});
	
	# Adjust the log level, if required.
	if ((exists $anvil->data->{scancore}{$agent}{log_level}) && ($anvil->data->{scancore}{$agent}{log_level} =~ /^\d+$/))
	{
		$anvil->Log->level({set => $anvil->data->{scancore}{$agent}{log_level}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"scancore::${agent}::log_level" => $anvil->data->{scan_agent}{$agent}{log_level},
		}});
	}
	if ((exists $anvil->data->{scancore}{$agent}{log_secure}) && ($anvil->data->{scancore}{$agent}{log_secure} =~ /^\d+$/))
	{
		$anvil->Log->secure({set => $anvil->data->{scancore}{$agent}{log_secure}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"scancore::${agent}::log_level" => $anvil->data->{scan_agent}{$agent}{log_secure},
		}});
	}
	
	# If we're disabled and '--force' wasn't used, exit.
	if (($anvil->data->{scancore}{$agent}{disable}) && (not $anvil->data->{switches}{force}))
	{
		# Exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, 'print' => 1, key => "log_0646", variables => { program => $agent }});
		$anvil->nice_exit({exit_code => 0});
	}
	
	# Setting this will prepend messages coming grom the agent with the agent's name
	$anvil->data->{'log'}{scan_agent} = $agent;
	
	# If this agent ran before, it should have recorded how many databases it last connected to. Read 
	# that, if so.
	my $data_file = $anvil->data->{path}{directories}{temp}."/".$agent.".data";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { data_file => $data_file }});
	
	$anvil->data->{scan_agent}{$agent}{last_run}      = "";
	$anvil->data->{scan_agent}{$agent}{last_db_count} = 0;
	if (-f $data_file)
	{
		my $file_body = $anvil->Storage->read_file({
			debug       => $debug,
			file        => $data_file, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
		foreach my $line (split/\n/, $file_body)
		{
			if ($line =~ /^last_run:(\d+)/)
			{
				$anvil->data->{scan_agent}{$agent}{last_run}            = $1;
				$anvil->data->{scan_agent}{$agent}{time_since_last_run} = time - $anvil->data->{scan_agent}{$agent}{last_run};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"scan_agent::${agent}::last_run"            => $anvil->data->{scan_agent}{$agent}{last_run},
					"scan_agent::${agent}::time_since_last_run" => $anvil->data->{scan_agent}{$agent}{time_since_last_run},
				}});
			}
			if ($line =~ /^last_db_count:(\d+)/)
			{
				$anvil->data->{scan_agent}{$agent}{last_db_count} = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"scan_agent::${agent}::last_db_count" => $anvil->data->{scan_agent}{$agent}{last_db_count},
				}});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { tables => $tables }});
	if ((not $tables) or (ref($tables) ne "ARRAY"))
	{
		my $schema_file = $anvil->data->{path}{directories}{scan_agents}."/".$agent."/".$agent.".sql";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { schema_file => $schema_file }});
		if (-e $schema_file)
		{
			$tables = $anvil->Database->get_tables_from_schema({debug => $debug, schema_file => $schema_file});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { tables => $tables }});
			if (($tables eq "!!error!!") or (ref($tables) ne "ARRAY"))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "ScanCore->agent_startup()", parameter => "tables" }});
				return("!!error!!");
			}
			else
			{
				foreach my $table (@{$tables})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
				}
			}
		}
		else
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { schema_file => $schema_file }});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "ScanCore->agent_startup()", parameter => "tables" }});
			return("!!error!!");
		}
	}
	
	# Connect to DBs.
	$anvil->Database->connect({debug => $debug});
	$anvil->Log->entry({source => $agent, line => __LINE__, level => $debug, secure => 0, key => "log_0132"});
	if (not $anvil->data->{sys}{database}{connections})
	{
		# No databases, exit.
		$anvil->Log->entry({source => $agent, line => __LINE__, 'print' => 1, level => 0, secure => 0, key => "error_0003"});
		if ($no_db_ok)
		{
			return(0);
		}
		else
		{
			return(1);
		}
	}
	
	my $table_count = @{$tables};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table_count => $table_count }});
	
	# It's possible that some agents don't have a database (or use core database tables only)
	if (@{$tables} > 0)
	{
		# Make sure our schema is loaded.
		$anvil->Database->check_agent_data({
			debug  => $debug,
			agent  => $agent,
			tables => $tables, 
		});
	}

	# Read in our word strings.
	my $words_file = $anvil->data->{path}{directories}{scan_agents}."/".$agent."/".$agent.".xml";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { words_file => $words_file }});
	
	my $problem = $anvil->Words->read({
		debug => $debug, 
		file  => $words_file,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	
	if ($problem)
	{
		# Something went wrong loading the file.
		return(1);
	}
	
	return(0);
}


=head2 call_scan_agents

This method calls all scan agents found on this system. It looks under the C<< path::directories::scan_agents >> directory (and subdirectories) for scan agents.

Parameters;

=head3 agent (optional, default "")

If set, only the specific agent will be run. 

=cut
sub call_scan_agents
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->call_scan_agents()" }});
	
	my $agent = defined $parameter->{agent} ? $parameter->{agent} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		agent => $agent, 
	}});
	
	# Get the current list of scan agents on this system.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"path::directories::scan_agents" => $anvil->data->{path}{directories}{scan_agents},
	}});
	$anvil->ScanCore->_scan_directory({directory => $anvil->data->{path}{directories}{scan_agents}});
	
	# Now loop through the agents I found and call them.
	my $timeout = 30;
	if ((exists $anvil->data->{scancore}{timing}{agent_runtime}) && ($anvil->data->{scancore}{timing}{agent_runtime} =~ /^\d+$/))
	{
		$timeout = $anvil->data->{scancore}{timing}{agent_runtime};
	}
	foreach my $agent_name (sort {$a cmp $b} keys %{$anvil->data->{scancore}{agent}})
	{
		next if (($agent) && ($agent ne $agent_name));
		my $agent_path  = $anvil->data->{scancore}{agent}{$agent_name};
		my $agent_words = $agent_path.".xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			agent_name  => $agent_name,
			agent_path  => $agent_path, 
			agent_words => $agent_words, 
		}});
		
		if ((-e $agent_words) && (-r $agent_words))
		{
			# Read the words file so that we can generate alerts later.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0251", variables => {
				agent_name => $agent_name,
				file       => $agent_words,
			}});
			$anvil->Words->read({file => $agent_words});
		}
		
		# Set the timeout.
		if (not defined $anvil->data->{scancore}{$agent_name}{timeout})
		{
			$anvil->data->{scancore}{$agent_name}{timeout} = $timeout;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::${agent_name}::timeout" => $anvil->data->{scancore}{$agent_name}{timeout},
			}});
		}
		else
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::${agent_name}::timeout" => $anvil->data->{scancore}{$agent_name}{timeout},
			}});
		}
		
		# Now call the agent.
		my $start_time = time;
		if (($anvil->data->{scancore}{$agent_name}{timeout}) && ($anvil->data->{scancore}{$agent_name}{timeout} =~ /^\d+$/))
		{
			$timeout = $anvil->data->{scancore}{$agent_name}{timeout};
		}
		my $shell_call = $agent_path;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::log::level' => $anvil->data->{sys}{'log'}{level} }});
		if ($anvil->data->{sys}{'log'}{level})
		{
			$shell_call .= " ".$anvil->data->{sys}{'log'}{level};
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		if ($anvil->data->{switches}{purge})
		{
			$shell_call .= " --purge";
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		# Tell the user this agent is about to run...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $debug, key => "log_0252", variables => {
			agent_name => $agent_name,
			timeout    => $timeout,
		}});
#		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $debug, key => "log_0701", variables => { agent_name => $agent_name }});
		my ($output, $return_code) = $anvil->System->call({timeout => $timeout, shell_call => $shell_call});
#		my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		}
		
		# If an agent takes a while to run, log it with higher verbosity
		my $runtime    = (time - $start_time);
		my $log_level  = $debug;
		my $string_key = "log_0557";
		if ($runtime > 15)
		{
			$log_level  = 1;
			$string_key = "log_0621";
		}
		if ($return_code eq "124")
		{
			# Timed out
			$log_level  = 1;
			$string_key = "message_0180";
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, runtime => $runtime }});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $log_level, key => $string_key, variables => {
			agent_name  => $agent_name,
			runtime     => $runtime,
			return_code => $return_code,
			timeout     => $timeout,
		}});
		
		# If the return code is '124', timeout popped.
		if ($return_code eq "124")
		{
			### TODO: Check if this alert was set so it only goes out once.
			# Register an alert...
			$anvil->Alert->register({set_by => $THIS_FILE, alert_level => "notice", message => "message_0180,!!agent_name!".$agent_name."!!,!!timeout!".$timeout."!!"});
		}
	}
	
	return(0);
}


=head2 check_health

This returns the current health score against a machine. The higher the score, the worse the health of the machine is. Generally, this is used by nodes to compare their relative health and to decide when a preventative live migration is required.

A score of C<< 0 >> means that a node has no known health issues. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 host_uuid (Optional, default Get->host_uuid)

This is the host whose health is being checked.

=cut
sub check_health
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->check_health()" }});
	
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid  => $host_uuid,
	}});
	
	if (not $host_uuid)
	{
		$host_uuid = $anvil->Get->host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid  => $host_uuid }});
	}
	
	my $health_score = 0;
	my $query        = "
SELECT 
    health_agent_name, 
    health_source_name, 
    health_source_weight 
FROM 
    health 
WHERE 
    health_host_uuid = ".$anvil->Database->quote($host_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	
	foreach my $row (@{$results})
	{
		my $health_agent_name    = $row->[0];
		my $health_source_name   = $row->[1];
		my $health_source_weight = $row->[2];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			's1:health_agent_name'    => $health_agent_name, 
			's2:health_source_name'   => $health_source_name, 
			's3:health_source_weight' => $health_source_weight, 
		}});
		
		if ($health_source_weight)
		{
			$health_score += $health_source_weight;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { health_score => $health_score }});
		}
	}
	
	return($health_score);
}


=head2 check_power

This method checks the health of the UPSes powering a node. 

The power health, the shortest "time on batteries", the highest charge percentage and etimated hold-up time are returned. 

Power health values;
* '!!error!!' - There was a missing input variable.
* 0 - No UPSes found for the host
* 1 - One or more UPSes found and at least one has input power from mains.
* 2 - One or more UPSes found, all are running on battery.

If the health is C<< 0 >>, all other values will also be C<< 0 >>.

If the health is C<< 1 >>, the "time on batteries" and "estimated hold up time" will be C<< 0 >> and the highest charge percentage will be set.

If the health is C<< 2 >>, the "time on batteries" will be the number of seconds since the last UPS to lose power was found to be running on batteries, The estimated hold up time of the strongest UPS is also returned in seconds.

If no UPSes were found, health of '0' is returned (unknown). If  If both/all UPSes are 

Parameters;

=head3 anvil_uuid (Optional, if 'host_uuid' is in an Anvil!)

This is the Anvil! UUID that the machine belongs to. This is required to find the manifest that shows which UPSes power the host.

=head3 anvil_name (Optional, if 'host_uuid' is in an Anvil!)

This is the Anvil! name that the machine is a member of. This is used for logging.

=head3 host_uuid (Optional, default Get->host_uuid)

This is the host's UUID that we're checking the UPSes powering it.

=cut
sub check_power
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->check_power()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	my $anvil_name = defined $parameter->{anvil_name} ? $parameter->{anvil_name} : "";
	my $host_uuid  = defined $parameter->{host_uuid}  ? $parameter->{host_uuid}  : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid,
		anvil_name => $anvil_name,
		host_uuid  => $host_uuid,
	}});
	
	# Try to divine missing data. If the 'host_uuid' wasn't passed, use the caller's host UUID.
	if (not $host_uuid)
	{
		$host_uuid = $anvil->Get->host_uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	}
	
	if (not $anvil_uuid)
	{
		# Can we read an Anvil! UUID for this host?
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({
			debug     => $debug, 
			host_uuid => $host_uuid, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		if (not $anvil_uuid)
		{
			# Nope.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "ScanCore->check_power()", parameter => "anvil_uuid" }});
			return("!!error!!");
		}
	}
	
	if (not $anvil_name)
	{
		$anvil_name = $anvil->Cluster->get_anvil_name({debug => $debug, anvil_uuid => $anvil_uuid});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
	}
	
	my $host_name = $anvil->Database->get_host_from_uuid({debug => $debug, host_uuid => $host_uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
	
	# We'll need the UPS data
	$anvil->Database->get_upses({debug => $debug});
	
	my $power_health               = 0;
	my $shortest_time_on_batteries = 99999;
	my $highest_charge_percentage  = 0;
	my $estimated_hold_up_time     = 0;
	
	my $query = "SELECT manifest_uuid FROM manifests WHERE manifest_name = ".$anvil->Database->quote($anvil_name).";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if (not $count)
	{
		# Nothing we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0569", variables => { 
			anvil_name => $anvil_name, 
			host_name  => $host_name, 
		}});
		return($power_health, $shortest_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time)
	}
	
	my $manifest_uuid = $results->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
	
	# Try to parse the manifest now.
	if (not exists $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid})
	{
		my $problem = $anvil->Striker->load_manifest({
			debug         => $debug, 
			manifest_uuid => $manifest_uuid,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		
		if ($problem)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0569", variables => { 
				manifest_uuid => $manifest_uuid, 
				anvil_name    => $anvil_name, 
				host_name     => $host_name, 
			}});
			return($power_health, $shortest_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time)
		}
	}
	
	# If we're here, we can now look for the PDUs powering this host.
	my $ups_count            = 0;
	my $ups_with_mains_found = 0;
	foreach my $machine_type (sort {$a cmp $b} keys %{$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}})
	{
		my $machine_name = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine_type}{name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			machine_type => $machine_type,
			machine_name => $machine_name, 
		}});
		next if $host_name !~ /$machine_name/;
		
		foreach my $ups_name (sort {$a cmp $b} keys %{$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine_type}{ups}})
		{
			my $ups_uuid   = $anvil->data->{upses}{ups_name}{$ups_name}{ups_uuid};
			my $ups_used   = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine_type}{ups}{$ups_name}{used};
			my $power_uuid = $anvil->data->{upses}{ups_name}{$ups_name}{power_uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				ups_name   => $ups_name,
				ups_uuid   => $ups_uuid, 
				power_uuid => $power_uuid, 
			}});
			
			if (($ups_used) && ($power_uuid))
			{
				### TODO: The power 'modified_time' is in unixtime. So we can see when the 
				###       UPS was last scanned. Later, we should think about how valid we 
				###       consider data over a certain age.
				# What state is the UPS in?
				   $ups_count++;
				my $power_on_battery        = $anvil->data->{power}{power_uuid}{$power_uuid}{power_on_battery};
				my $power_seconds_left      = $anvil->data->{power}{power_uuid}{$power_uuid}{power_seconds_left};
				my $power_charge_percentage = $anvil->data->{power}{power_uuid}{$power_uuid}{power_charge_percentage};
				my $modified_date_unix      = $anvil->data->{power}{power_uuid}{$power_uuid}{modified_date_unix};
				my $time_now                = time;
				my $last_updated            = $time_now - $modified_date_unix;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					ups_count               => $ups_count,
					power_on_battery        => $power_on_battery, 
					power_seconds_left      => $power_seconds_left." (".$anvil->Convert->time({'time' => $power_seconds_left, long => 1, translate => 1}).")", 
					power_charge_percentage => $power_charge_percentage."%", 
					modified_date_unix      => $modified_date_unix, 
					time_now                => $time_now, 
					last_updated            => $last_updated." (".$anvil->Convert->time({'time' => $last_updated, long => 1, translate => 1}).")", 
				}});
				
				if ($power_charge_percentage > $highest_charge_percentage)
				{
					$highest_charge_percentage = $power_charge_percentage;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { highest_charge_percentage => $highest_charge_percentage }});
				}
				
				if ($power_on_battery)
				{
					# We're on battery, so see what the hold up time is.
					if (not $power_health)
					{
						# Set this to '2', if another UPS is on mains, it will change it to 1.
						$power_health = 2;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { power_health => $power_health }});
					}
					if ($power_seconds_left > $estimated_hold_up_time)
					{
						$estimated_hold_up_time = $power_seconds_left;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { estimated_hold_up_time => $estimated_hold_up_time }});
					}
					
					# How long has it been on batteries?
					my $query = "
SELECT 
    round(extract(epoch from modified_date)) 
FROM 
    history.power 
WHERE 
    power_uuid = ".$anvil->Database->quote($power_uuid)." 
AND 
    power_on_battery IS FALSE 
ORDER BY 
    modified_date DESC 
LIMIT 1
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
						# The only way this could happen is if we've never seen the UPS on mains...
						$shortest_time_on_batteries = 0;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0571", variables => { 
							power_uuid => $power_uuid, 
							host_name  => $host_name, 
						}});
					}
					else
					{
						my $last_on_batteries = $results->[0]->[0];
						my $time_on_batteries = (time - $last_on_batteries);
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							last_on_batteries => $last_on_batteries." (".$anvil->Get->date_and_time({use_time => $last_on_batteries}).")", 
							time_on_batteries => $time_on_batteries." (".$anvil->Convert->time({'time' => $time_on_batteries, long => 1, translate => 1}).")",
						}});
						
						if ($time_on_batteries < $shortest_time_on_batteries)
						{
							$shortest_time_on_batteries = $time_on_batteries;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								shortest_time_on_batteries => $shortest_time_on_batteries." (".$anvil->Convert->time({'time' => $shortest_time_on_batteries, long => 1, translate => 1}).")",
							}});
						}
					}
				}
				else
				{
					# See how charged up this UPS is. 
					$power_health               = 1;
					$ups_with_mains_found       = 1;
					$shortest_time_on_batteries = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						ups_with_mains_found       => $ups_with_mains_found,
						shortest_time_on_batteries => $shortest_time_on_batteries, 
					}});
				}
			}
		}
	}
	
	if (not $ups_count)
	{
		# No UPSes found.
		$shortest_time_on_batteries = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shortest_time_on_batteries => $shortest_time_on_batteries }});
	}
	
	return($power_health, $shortest_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time);
}


=head2 check_temperature

This pulls in the list of temperatures for the given host and checks to see if they are healthy, in warning or critical. If the host is in a warning or critical state, the how long those states have been active for are also returned. If all is good, those return C<< 0 >>.

B<< Note >>: This method does NOT check the age of the temperature data. When checking the temperature state on another machine, the caller needs to decide if the data is fresh or stale.

Returned values are;

 1 = Temperature is OK
 2 = Temperature is not OK
 3 = Temperature is in a warning state; evaluate load shed
 4 = Temperature is critical; Shut down regardless of peer state

These values are determined this way;

* If all temperature sensors are nominal, '1' is returned.
* If any temperature sensors warning or critical, '2' is the minimum value returned.
* If the sum of all non-nominal temperature sensor weights are >= 5, then '3' is returned.
* If the sum of all critical temperatire sensors is >= 5, then '4' is returned.

B<< Note >>: Temperature sensors that are in the "high" state are summed separately from sensors in the "low" state. 

Parameters;

=head3 host_uuid (Optional, default Get->host_uuid)

This is the host whose temperature data is being collected. Usually this is the local machine, the peer in an assembled cluster, or a DR host when migrating out of an over-heating DC.

=cut
sub check_temperature
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->check_temperature()" }});
	
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid => $host_uuid, 
	}});
	
	# This will get set to '2' or higher if the temperature is not OK.
	my $temperature_health = 1;
	my $warning_age        = 0;
	my $critical_age       = 0;
	
	# These will store the temperature scores
	$anvil->data->{temperature}{high}{warning}  = 0;
	$anvil->data->{temperature}{high}{critical} = 0;
	$anvil->data->{temperature}{low}{warning}   = 0;
	$anvil->data->{temperature}{low}{critical}  = 0;
	
	# Read in all of the temperature entries for this node 
	my $query = "
SELECT 
    temperature_agent_name, 
    temperature_sensor_name, 
    temperature_state, 
    temperature_is, 
    temperature_weight 
FROM 
    temperature 
WHERE 
    temperature_host_uuid = ".$anvil->Database->quote($host_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	
	foreach my $row (@{$results})
	{
		my $temperature_agent_name  = $row->[0];
		my $temperature_sensor_name = $row->[1];
		my $temperature_state       = $row->[2];
		my $temperature_is          = $row->[3];
		my $temperature_weight      = $row->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:temperature_agent_name'  => $temperature_agent_name, 
			's2:temperature_sensor_name' => $temperature_sensor_name, 
			's3:temperature_state'       => $temperature_state, 
			's4:temperature_is'          => $temperature_is, 
			's5:temperature_weight'      => $temperature_weight, 
		}});
		
		# If this is OK, we can ignore it
		next if $temperature_is eq "nominal";
		
		# If we're here, a temperature variable is out of spec. Determine how and add the scores.
		if ($temperature_health)
		{
			$temperature_health = 2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temperature_health => $temperature_health }});
		}
		
		# Record the score
		if ($temperature_state eq "critical")
		{
			# Add the weight to the warning and the critical values.
			$anvil->data->{temperature}{$temperature_is}{warning}  += $temperature_weight ? $temperature_weight : 1;
			$anvil->data->{temperature}{$temperature_is}{critical} += $temperature_weight ? $temperature_weight : 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"temperature::${temperature_is}::warning"  => $anvil->data->{temperature}{$temperature_is}{warning},
				"temperature::${temperature_is}::critical" => $anvil->data->{temperature}{$temperature_is}{critical},
			}});
		}
		elsif ($temperature_state eq "warning")
		{
			# Add the weight to the warning value
			$anvil->data->{temperature}{$temperature_is}{warning} += $temperature_weight ? $temperature_weight : 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"temperature::${temperature_is}::warning" => $anvil->data->{temperature}{$temperature_is}{warning},
			}});
		}
	}
	
	# If we're not the host, and the temperatures look OK, see how often the target as shut off for 
	# thermal reasons.
	if (($host_uuid ne $anvil->Get->host_uuid) && ($temperature_health eq "1"))
	{
		# When a node has gone into emergency stop because of an over-temperature event, we want to 
		# give it time to cool down before we boot it back up.
		# 
		# Likewise, if we rebooted it and it went back down quickly, give it more time before 
		# starting it back up. We do this by reading in how many times the node went into thermal 
		# shutdown over the last six hours. The number of returned shut-downs will determine how long
		# I wait before booting the node back up.
		# 
		# The default schedule is:
		# Reboots | Wait until boot
		# --------+-----------------
		#  1      | 10m
		#  2      | 30m
		#  3      | 60m
		#  4      | 120m
		#  >4     | 6h
		# --------+-----------------
		# 
		# To determine the number or reboots, do the following query:
		my $last_shutdown = 0;
		my $query         = "
SELECT 
    round(extract(epoch from modified_date)) 
FROM 
    history.variables 
WHERE 
    variable_source_uuid  = ".$anvil->Database->quote($host_uuid)."
AND
    variable_source_table = 'hosts'
AND 
    variable_name         = 'system::stop_reason' 
AND 
    variable_value        = 'thermal'
AND 
    modified_date > (now() - interval '6h') 
ORDER BY 
    modified_date ASC
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results        = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $shutdown_count = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results        => $results, 
			shutdown_count => $shutdown_count, 
		}});
		foreach my $row (@{$results})
		{
			my $this_shutdown = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_shutdown => $this_shutdown }});
			if ($this_shutdown > $last_shutdown)
			{
				$last_shutdown = $this_shutdown;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_shutdown => $last_shutdown }});
			}
		}
		
		### TODO: Let this be set by 'variables' table
		# Set default delays, if not already set.
		if ((not exists $anvil->data->{scancore}{thermal_reboot_delay}{more}) or ($anvil->data->{scancore}{thermal_reboot_delay}{more} !~ /^\d+$/))
		{
			$anvil->data->{scancore}{thermal_reboot_delay}{more} = 21600;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::thermal_reboot_delay::more" => $anvil->data->{scancore}{thermal_reboot_delay}{more},
			}});
		}
		if ((not exists $anvil->data->{scancore}{thermal_reboot_delay}{'4'}) or ($anvil->data->{scancore}{thermal_reboot_delay}{'4'} !~ /^\d+$/))
		{
			$anvil->data->{scancore}{thermal_reboot_delay}{'4'} = 7200;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::thermal_reboot_delay::4" => $anvil->data->{scancore}{thermal_reboot_delay}{'4'},
			}});
		}
		if ((not exists $anvil->data->{scancore}{thermal_reboot_delay}{'3'}) or ($anvil->data->{scancore}{thermal_reboot_delay}{'3'} !~ /^\d+$/))
		{
			$anvil->data->{scancore}{thermal_reboot_delay}{'3'} = 3600;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::thermal_reboot_delay::3" => $anvil->data->{scancore}{thermal_reboot_delay}{'3'},
			}});
		}
		if ((not exists $anvil->data->{scancore}{thermal_reboot_delay}{'2'}) or ($anvil->data->{scancore}{thermal_reboot_delay}{'2'} !~ /^\d+$/))
		{
			$anvil->data->{scancore}{thermal_reboot_delay}{'2'} = 1800;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::thermal_reboot_delay::2" => $anvil->data->{scancore}{thermal_reboot_delay}{'2'},
			}});
		}
		if ((not exists $anvil->data->{scancore}{thermal_reboot_delay}{'1'}) or ($anvil->data->{scancore}{thermal_reboot_delay}{'1'} !~ /^\d+$/))
		{
			$anvil->data->{scancore}{thermal_reboot_delay}{'1'} = 600;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::thermal_reboot_delay::1" => $anvil->data->{scancore}{thermal_reboot_delay}{'1'},
			}});
		}
		
		# Now that we know when the host last shut down, and how many times it shut down in the last 
		# 6 hours, How long should we wait until we mark the temperature as "ok"?
		my $delay = 0;
		if ($shutdown_count > 4)
		{
			# 6 hours
			$delay = $anvil->data->{scancore}{thermal_reboot_delay}{more};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
		}
		elsif ($shutdown_count == 4)
		{
			# 2 hours
			$delay = $anvil->data->{scancore}{thermal_reboot_delay}{'4'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
		}
		elsif ($shutdown_count == 3)
		{
			# 1 hour
			$delay = $anvil->data->{scancore}{thermal_reboot_delay}{'3'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
		}
		elsif ($shutdown_count == 2)
		{
			# 30 minutes
			$delay = $anvil->data->{scancore}{thermal_reboot_delay}{'2'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
		}
		elsif ($shutdown_count == 1)
		{
			# 10 minutes
			$delay = $anvil->data->{scancore}{thermal_reboot_delay}{'1'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
		}
		else
		{
			# No delay
			$delay = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
		}
		
		# Now, see if the last reboot time is more than delay time ago.
		if ($delay)
		{
			my $now_time          = time;
			my $last_shutdown_was = ($now_time - $last_shutdown);
			my $wait_for          = $delay - $last_shutdown_was;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				now_time          => $now_time, 
				last_shutdown_was => $last_shutdown_was, 
				delay             => $delay, 
				wait_for          => $wait_for, 
			}});
			if ($last_shutdown_was < $delay)
			{
				# Wait longer.
				   $temperature_health = 2;
				my $say_wait_for        = $anvil->Convert->time({debug => $debug, 'time' => $wait_for});
				my $host_name           = $anvil->Database->get_host_from_uuid({debug => $debug});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					temperature_health => $temperature_health,
					say_wait_for        => $say_wait_for,
					host_name           => $host_name, 
				}});
				
				# Log that we're waiting because of the shutdown delay being in effect.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0619", variables => { 
					wait_for  => $say_wait_for,
					host_name => $host_name, 
					count     => $shutdown_count, 
				}});
			}
		}
	}
	
	# If the temperature is not safe, see if it's warning or critical.
	#  1 = Temperature is OK
	#  2 = Temperature is not OK
	#  3 = Temperature is in a warning state; evaluate load shed
	#  4 = Temperature is critical; Shut down regardless of peer state
	if ($temperature_health == 2)
	{
		# This doesn't fully separate high scores from low scores, but the chances of enough sensors 
		# being high while others are low at the same time isn't very realistic.
		if (($anvil->data->{temperature}{high}{critical} >= 5) or ($anvil->data->{temperature}{low}{critical} >= 5))
		{
			# We're critical
			$temperature_health = 4;
			$critical_age       = $anvil->Alert->check_condition_age({
				debug     => $debug,
				name      => "scancore::temperature-critical",
				host_uuid => $host_uuid,
			});
			$warning_age = $anvil->Alert->check_condition_age({
				debug     => $debug,
				name      => "scancore::temperature-warning",
				host_uuid => $host_uuid,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:temperature_health' => $temperature_health,
				's2:warning_age'        => $warning_age, 
				's3:critical_age'       => $critical_age, 
			}});
			
		}
		elsif (($anvil->data->{temperature}{high}{warning} >= 5) or ($anvil->data->{temperature}{low}{warning} >= 5))
		{
			# We're in a warning
			$temperature_health = 3;
			$warning_age        = $anvil->Alert->check_condition_age({
				debug     => $debug,
				name      => "scancore::temperature-warning",
				host_uuid => $host_uuid,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:temperature_health' => $temperature_health,
				's2:warning_age'        => $warning_age, 
				's3:critical_age'       => $critical_age, 
			}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temperature_health => $temperature_health }});
			
			# Clear critical, in case it was set and we're returning to normal
			$anvil->Alert->check_condition_age({
				debug     => $debug,
				clear     => 1,
				name      => "scancore::temperature-critical",
				host_uuid => $host_uuid,
			});
		}
		else
		{
			# We're OK, make sure alerts are cleared.
			$anvil->Alert->check_condition_age({
				debug     => $debug,
				clear     => 1,
				name      => "scancore::temperature-critical",
				host_uuid => $host_uuid,
			});
			$anvil->Alert->check_condition_age({
				debug     => $debug,
				clear     => 1,
				name      => "scancore::temperature-warning",
				host_uuid => $host_uuid,
			});
		}
	}
	
	return($temperature_health, $warning_age, $critical_age);
}


=head2 check_temperature_direct

This calls a target's IPMI interface to check the temperature sensors that are available. The status is returns as;

 0 = Failed to read temperature sensors / IPMI unavailable
 1 = All available temperatures are nominal.
 2 = One of more sensors are in warning or critical.

Parameters;

=head3 host_uuid (Optional, default Get->host_uuid() )

This is the host's UUID to look at. 

=cut
sub check_temperature_direct
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->check_temperature_direct()" }});
	
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid => $host_uuid, 
	}});
	
	#  * 0 - Failed to read temperature sensors / IPMI unavailable
	#  * 1 - All available temperatures are nominal
	#  * 2 - One of more sensors are in warning or critical.
	my $status = 0;
	if ((not defined $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi}) or (not $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi}))
	{
		$anvil->Database->get_hosts_info({debug => $debug});
	}
	my $host_ipmi = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi};
	my $host_name = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_ipmi => $host_ipmi,
		host_name => $host_name, 
	}});
	
	my ($ipmitool_command, $ipmi_password) = $anvil->Convert->fence_ipmilan_to_ipmitool({
		debug                 => 2,
		fence_ipmilan_command => $host_ipmi,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ipmitool_command => $ipmitool_command,
		ipmi_password    => $anvil->Log->is_secure($ipmi_password), 
	}});
	
	if ((not $ipmitool_command) or ($ipmitool_command eq "!!error!!"))
	{
		# No IPMI tool to call.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0573", variables => { host_name => $host_name }});
		return($status);
	}
	
	$anvil->System->collect_ipmi_data({
		debug            => $debug, 
		host_name        => $host_name, 
		ipmitool_command => $ipmitool_command, 
		ipmi_password    => $ipmi_password, 
	});
	
	# Now look for thermal values.
	foreach my $sensor_name (sort {$a cmp $b} keys %{$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}})
	{
		my $current_value = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_value_sensor_value};
		my $units         = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_units};
		my $sensor_status = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_status};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			current_value => $current_value, 
			sensor_name   => $sensor_name, 
			units         => $units, 
			sensor_status => $sensor_status, 
		}});
		
		# If this is a temperature, check to see if it is outside its nominal range and, if
		# so, record it into a hash for loading into ScanCore's 'temperature' table.
		if ($units eq "C")
		{
			if ($sensor_status eq "ok")
			{
				# We've found at least one temperature sensor. Set status to '1' if not previously set
				$status = 1 if not $status;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { status => $status }});
			}
			else
			{
				# Sensor isn't OK yet.
				$status = 2 if not $status;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { status => $status }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { status => $status }});
	return($status);
}


=head2 count_servers

This returns the number of servers running on a given host, as reported by ScanCore (specifically, by counting the number of servers running on the host from the C<< servers >> table). It also counts the total amount of RAM in use by hosted servers. 

Lastly, if all servers have at least one record of a past migration, an estimated time to migrate is returned. If any given server has 5 more more historical migrations, only the last five are averaged. 

B<< Note >>: If any server has no historical migration value, then the migration estimate will return C<< -- >>.

B<< Note >>: This does not yet count servers that could be migrating to the target host.

 my ($server_count, $ram_in_use, $estimated_migation_time) = $anvil->ScanCore->count_servers({host_uuid => '4c4c4544-004b-3210-8053-c2c04f303333'});

Parameters;

=head3 host_uuid (Optional, default Get->host_uuid)

This is the host whose number of servers we're counting.

=cut
sub count_servers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->count_servers()" }});
	
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid  => $host_uuid,
	}});

	### TODO: Once we are tracking CPU load, Active RAM in use and migration network bandwitdh, calculate
	###       a better predicted time.
	my $servers            = 0;
	my $ram_used           = 0;
	my $migration_estimate = 0;
	my $use_migration_time = 1;
	my $query    = "
SELECT 
    server_uuid, 
    server_name, 
    server_state, 
    server_ram_in_use 
FROM 
    servers  
WHERE 
    server_host_uuid = ".$anvil->Database->quote($host_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	
	foreach my $row (@{$results})
	{
		my $server_uuid       = $row->[0];
		my $server_name       = $row->[1];
		my $server_state      = $row->[2];
		my $server_ram_in_use = $row->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:server_uuid'       => $server_uuid, 
			's2:server_name'       => $server_name, 
			's3:server_state '     => $server_state, 
			's4:server_ram_in_use' => $anvil->Convert->add_commas({number => $server_ram_in_use})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $server_ram_in_use}).")", 
		}});
		
		if ($server_state ne "shut off")
		{
			$servers++;
			$ram_used += $server_ram_in_use; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				servers  => $servers,
				ram_used => $anvil->Convert->add_commas({number => $ram_used})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $ram_used}).")",
			}});
			
			# Average the last five migrations, if we've seen five migrations. 
			my $query = "
SELECT 
    variable_value 
FROM 
    history.variables 
WHERE 
    variable_name         = 'server::migration_duration'
AND 
    variable_source_uuid  = ".$anvil->Database->quote($server_uuid)." 
AND 
    variable_source_table = 'servers' 
LIMIT 5
;";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
			my $results    = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
			my $migrations = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results    => $results, 
				migrations => $migrations,
			}});
			if (not $migrations)
			{
				# We can't use migration time
				$use_migration_time = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { use_migration_time => $use_migration_time }});
			}
			else
			{
				my $all_time = 0;
				foreach my $row (@{$results})
				{
					my $this_migration_time = $row->[0];
					   $all_time            += $this_migration_time;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						this_migration_time => $this_migration_time, 
						all_time            => $all_time,
					}});
				}
				my $average_migration_time =  $anvil->Convert->round({number => ($all_time / $migrations)});
				   $migration_estimate     += $average_migration_time;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					average_migration_time => $average_migration_time." (".$anvil->Convert->time({'time' => $average_migration_time}).")",
					migration_estimate     => $migration_estimate." (".$anvil->Convert->time({'time' => $migration_estimate}).")",
				}});
			}
		}
	}
	
	if (not $use_migration_time)
	{
		# Wipe out our migration time, one or more servers have no history.
		$migration_estimate = "--";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { migration_estimate => $migration_estimate }});
	}
	
	return($servers, $ram_used, $migration_estimate);
}


=head2 post_scan_analysis

This method contains the logic for the ScanCore "decision engine". The logic applied depends on the host type.

This method takes no parameters.

=cut
sub post_scan_analysis
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->post_scan_analysis()" }});
	
	my $host_type = $anvil->Get->host_type;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type eq "striker")
	{
		$anvil->ScanCore->post_scan_analysis_striker({debug => $debug})
	}
	elsif ($host_type eq "node")
	{
		$anvil->ScanCore->post_scan_analysis_node({debug => $debug})
	}
	elsif ($host_type eq "dr")
	{
		$anvil->ScanCore->post_scan_analysis_dr({debug => $debug})
	}
	
	return(0);
}


=head2 post_scan_analysis_dr

This runs through ScanCore post-scan analysis on DR hosts.

This method takes no parameters;

=cut
sub post_scan_analysis_dr
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->post_scan_analysis_dr()" }});
	
	# Now that DR hosts are outside of specific Anvil! systems, auto-configuring their IPMI is more 
	# tricky. If there's no 'host_ipmi' set, and if there is a BCN1 IP, we'll configure using the BCN's
	# third octet, plus 1. We'll use the password used for the database password. Later, if the IPMI
	# is changed in the DB, we'll reconfigure to match.
	$anvil->System->configure_ipmi({debug => $debug, dr => 1});
	
	return(0);
}


=head2 post_scan_analysis_node

This runs through ScanCore post-scan analysis on Anvil! nodes.

Logic flow;

 * We're not in the cluster
   - If we're in maintenance mode, do nothing.
   - If we're not in maintenance mode, and thermal is warning or power is out to our UPSes for 2+ minutes, shut down.
 * Peer not available
   - Thermal is critical, gracefully shut down.
  - Power is strongest UPS below ten minutes and time on batteries is over 2 minutes, graceful shut down
  * Peer available
   - If one node is healthier than the other;
     - If we're sicker, do nothing until we have no servers
     - If we're healthier, after two minutes, pull
   - If health is equal;
     - Both nodes have servers;
       - Determine if one node is SyncSource, if so, it lives.
       - Else decide who can be evacuated fastest, in case load shed needed.
       - Both nodes on batteries or in warning temp for more than 2 minutes; 
         - If we're the designated survivor, pull servers.
         - If we're the sacrifice, wait for the servers to be taken off of us, then shut down.
     - Peer has servers, we don't
       - If thermal warning or both/all UPSes on batter for two minutes+, shut down 
     - We have servers, peer doesn't.
       - Keep running

This method takes no parameters;

=cut
sub post_scan_analysis_node
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->post_scan_analysis_node()" }});
	
	my $host_name       = $anvil->Get->host_name;
	my $short_host_name = $anvil->Get->short_host_name;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_name       => $host_name,
		short_host_name => $short_host_name, 
	}});
	
	# If we're in maintenance mode, do nothing.
	my $maintenance_mode = $anvil->System->maintenance_mode({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { maintenance_mode => $maintenance_mode }});
	if ($maintenance_mode)
	{
		# Do nothing
		return(0);
	}
	
	# What is our peer's host UUID?
	$anvil->Cluster->get_peers({debug => $debug});
	my $peer_is        = $anvil->data->{sys}{anvil}{peer_is};
	my $peer_host_name = $anvil->data->{sys}{anvil}{$peer_is}{host_name};
	my $peer_host_uuid = $anvil->data->{sys}{anvil}{$peer_is}{host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:peer_is'        => $peer_is,
		's2:peer_host_name' => $peer_host_name, 
		's3:peer_host_uuid' => $peer_host_uuid, 
	}});
	
	### The higher this number, the sicker a node is.
	# Get health data
	my $local_health = $anvil->ScanCore->check_health({debug => $debug});
	my $peer_health  = $anvil->ScanCore->check_health({
		debug     => $debug, 
		host_uuid => $peer_host_uuid, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		local_health => $local_health,
		peer_health  => $peer_health, 
	}});
	
	### TODO: Let a use set a flag on a single VM where, if set, it's host always is the one that stays 
	###       up in a load-shed condition.
	# The power health, the shortest "time on batteries", the highest charge percentage and etimated hold-up time are returned. 
	#
	# Power health values;
	#  0 = No UPSes found for the host
	#  1 = One or more UPSes found and at least one has input power from mains.
	#  2 = One or more UPSes found, all are running on battery.
	# 
	# If the health is '0', all other values will also be '0'.
	# If the health is '1', the "time on batteries" and "estimated hold up time" will be '0' and the highest charge percentage will be set.
	# If the health is '2', the "time on batteries" will be the number of seconds since the last UPS to lose power was found to be running on batteries, The estimated hold up time of the strongest UPS is also returned in seconds.
	# If no UPSes were found, health of '0' is returned (unknown). If  If both/all UPSes are 
	my ($local_power_health, $local_shortest_time_on_batteries, $local_highest_charge_percentage, $local_estimated_hold_up_time) = $anvil->ScanCore->check_power({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:local_power_health'               => $local_power_health,
		's2:local_shortest_time_on_batteries' => $local_shortest_time_on_batteries, 
		's3:local_highest_charge_percentage'  => $local_highest_charge_percentage, 
		's4:local_estimated_hold_up_time'     => $local_estimated_hold_up_time, 
	}});
	my ($peer_power_health, $peer_shortest_time_on_batteries, $peer_highest_charge_percentage, $peer_estimated_hold_up_time) = $anvil->ScanCore->check_power({
		debug     => $debug,
		host_uuid => $peer_host_uuid, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:peer_power_health'               => $peer_power_health,
		's2:peer_shortest_time_on_batteries' => $peer_shortest_time_on_batteries, 
		's3:peer_highest_charge_percentage'  => $peer_highest_charge_percentage, 
		's4:peer_estimated_hold_up_time'     => $peer_estimated_hold_up_time, 
	}});
	
	# Check the temperature status.
	# 1 = Temperature is OK
	# 2 = Temperature is not OK (at least one sensor is anomolous)
	# 3 = Temperature is in a warning state; evaluate load shed
	# 4 = Temperature is critical; Shut down regardless of peer state
	my ($local_temperature_health, $local_warning_age, $local_critical_age) = $anvil->ScanCore->check_temperature({debug => $debug});
	my ($peer_temperature_health, $peer_warning_age, $peer_critical_age)    = $anvil->ScanCore->check_temperature({
		debug     => $debug,
		host_uuid => $peer_host_uuid, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:local_temperature_health' => $local_temperature_health, 
		's2:local_warning_age'        => $local_warning_age, 
		's3:local_critical_age'       => $local_critical_age, 
		's4:peer_temperature_health'  => $peer_temperature_health,
		's5:peer_warning_age'         => $peer_warning_age, 
		's6:peer_critical_age'        => $peer_critical_age, 
	}});
	
	my $pull_servers = 0;	# Set if we should take servers from our peer.
	my $load_shed    = "";	# Set to 'power' or 'thermal' it one of the nodes should go down, but we don't care which yet.
	my $critical     = 0;	# Set if we have to shut down, even with servers.
	my $power_off    = "";	# Set to 'power' or 'thermal' if we need to shut down. If not critical, will ignore if we have servers.
	
	# If we're still here, at least one issue exists. Any kind of load-shed or preventative live 
	# migration decision now depends on our peer's state. So see if we're both in the cluster or not.
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if (not $problem)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::local::ready" => $anvil->data->{cib}{parsed}{'local'}{ready},
			"cib::parsed::peer::ready"  => $anvil->data->{cib}{parsed}{peer}{ready},
		}});
	}
	
	if (($problem) or (not $anvil->data->{cib}{parsed}{'local'}{ready}))
	{
		# We're not in the cluster. Are any servers running here? If so, wtf and do nothing.
		my $host_name = $anvil->Get->host_name;
		my $skip      = 0;
		$anvil->Server->find({debug => $debug});
		foreach my $server_name (sort {$a cmp $b} keys %{$anvil->data->{server}{location}})
		{
			my $status = $anvil->data->{server}{location}{$server_name}{status};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:server_name' => $server_name,
				's2:status'      => $status,
			}});
			if ($status ne "shut off")
			{
				# A server is running here even though we're out of the cluster, so do nothing.
				$skip = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0086", variables => {
					server_name => $server_name,
					status      => $status,
				}});
			}
		}
		if ($skip)
		{
			return(0);
		}
		
		### if we're still here, evaluate shutting down.
		# Power?
		if ($local_power_health eq "2")
		{
			my $variables = {
				time_on_batteries => $local_shortest_time_on_batteries, 
			};
			if ($local_shortest_time_on_batteries > 120)
			{
				# Register an alert, set our stop-reason, and power off.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0082", variables => $variables});
				$anvil->Alert->register({alert_level => "warning", message => "warning_0082", set_by => "ScanCore", variables => $variables});
				$anvil->Email->send_alerts();
				
				# Shutdown using 'anvil-safe-stop' and set the reason to 'power'
				my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason power --power-off".$anvil->Log->switches;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
				$anvil->System->call({shell_call => $shell_call});
				
				# We should never live to this point, but just in case...
				return(1);
			}
			else
			{
				# Log that we're on batteries but aren't ready to shut down yet.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0089", variables => $variables});
			}
		}
		
		# Thermal?
		if ($local_temperature_health >= 3)
		{
			# How long has this been the case?
			my $age = $anvil->Alert->check_condition_age({
				debug     => $debug,
				name      => "scancore::temperature-warning",
				host_uuid => $anvil->Get->host_uuid,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
			
			if ($age > 120)
			{
				# Register an alert, and power off.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0083"});
				$anvil->Alert->register({alert_level => "warning", message => "warning_0083", set_by => "ScanCore"});
				$anvil->Email->send_alerts();
				
				# Shutdown using 'anvil-safe-stop' and set the reason to 'thermal'
				my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason thermal --power-off".$anvil->Log->switches;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
				$anvil->System->call({shell_call => $shell_call});
				
				# We should never live to this point, but just in case...
				return(1);
			}
			else
			{
				# Log that we're anomolous, but haven't been for long enough to shut down yet.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0090", variables => { age => $age }});
			}
		}
	}
	else
	{
		# We're in the cluster. Is our peer?
		if (not $anvil->data->{cib}{parsed}{peer}{ready})
		{
			### TODO: If we're into warning, turn off any servers marked as non-critical now.
			# We're alone. If we're critical, shut down the servers.
			if ($local_temperature_health eq "4")
			{
				# We're going critical, shut down.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0087"});
				$anvil->Alert->register({alert_level => "notice", message => "warning_0087", set_by => "ScanCore"});
				$anvil->Email->send_alerts();
				
				my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason thermal --power-off".$anvil->Log->switches;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
				$anvil->System->call({shell_call => $shell_call});
				
				# We should not get to this point, but just in case...
				return(1);
			}
			elsif (($local_power_health eq "2") && ($local_shortest_time_on_batteries > 120) && ($local_estimated_hold_up_time < 600))
			{
				# We're running on batteries, have been so for 2+ minutes, and we have less 
				# than ten minutes of power left. Shut down.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0088"});
				$anvil->Alert->register({alert_level => "notice", message => "warning_0088", set_by => "ScanCore"});
				$anvil->Email->send_alerts();
				
				my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason power --power-off".$anvil->Log->switches;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
				$anvil->System->call({shell_call => $shell_call});
				
				# We should not get to this point, but just in case...
				return(1);
			}
			else
			{
				# Nothing to do
				return(0);
			}
		}
		else
		{
			### Our peer is up as well! This is where we have the most flexibility in decision 
			### making.
			# Are there any migrations in progress? If so, do nothing for now.
			my $active_migrations = $anvil->Server->active_migrations({debug => $debug});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_migrations => $active_migrations }});
			if ($active_migrations)
			{
				# We don't do anything while active migrations are under way.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0237"});
				return(0);
			}
			
			# Check to see which node can be evacuated fastest.
			my ($local_server_count, $local_ram_use, $estimated_migrate_off_time) = $anvil->ScanCore->count_servers({debug => $debug});
			my ($peer_server_count, $peer_ram_use, $estimate_migration_pull_time) = $anvil->ScanCore->count_servers({
				debug     => $debug, 
				host_uuid => $anvil->data->{cib}{parsed}{peer}{host_uuid},
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:local_server_count'           => $local_server_count,
				's2:local_ram_use'                => $anvil->Convert->add_commas({number => $local_ram_use})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $local_ram_use}).")",
				's3:estimated_migrate_off_time'   => $anvil->Convert->add_commas({number => $estimated_migrate_off_time})." (".$anvil->Convert->time({'time' => $estimated_migrate_off_time}).")", 
				's4:peer_server_count'            => $peer_server_count, 
				's5:peer_ram_use'                 => $anvil->Convert->add_commas({number => $peer_ram_use})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $peer_ram_use}).")",
				's6:estimate_migration_pull_time' => $anvil->Convert->add_commas({number => $estimate_migration_pull_time})." (".$anvil->Convert->time({'time' => $estimate_migration_pull_time}).")", 
			}});
			
			# If we're sync source, we won't shut down, period
			my $am_syncsource = $anvil->DRBD->check_if_syncsource({debug => $debug});
			my $am_synctarget = $anvil->DRBD->check_if_synctarget({debug => $debug});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				am_syncsource => $am_syncsource,
				am_synctarget => $am_synctarget,
			}});
			
			# If we're SyncSource, we can't withdraw, but we can pull servers.
			if ($am_syncsource)
			{
				# Log that we won't shutdown
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0105"});
			}
			
			# Lets check power.
			if (($local_power_health eq "2") && ($peer_power_health eq "2"))
			{
				# We're both on batteries, load shed?
				if (($local_shortest_time_on_batteries >= 120) && ($peer_shortest_time_on_batteries >= 120))
				{
					# Are we withing 600 seconds from losing power?
					if (($local_estimated_hold_up_time < 600) && (not $am_syncsource))
					{
						# We need to shut down, regardless of if we have servers.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0091"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0091", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						# Shutdown using 'anvil-safe-stop' and set the reason to 'power_off'
						my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason ".$power_off." --power-off".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# We should never live to this point, but just in case...
						return(1);
					}
					else
					{
						# Time to load shed. If we're pulling, do so. If we're not, check to
						# see if our servers are gone yet. If they are, shut down. If not, 
						# return (we'll check each scan until either our servers are gone or
						# the power is back). We'll figure out which we are later.
						$load_shed = "power";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { load_shed => $load_shed }});
						
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0092"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0092", set_by => "ScanCore"});
					}
				}
				else
				{
					# Not time yet
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0093"});
				}
			}
			elsif ($peer_power_health eq "2")
			{
				# We're not on batteries, but our peer is. If it's been two minutes, pull the servers.
				my $variables = {
					host_name => $peer_host_name,
				};
				if ($peer_shortest_time_on_batteries >= 120)
				{
					# Pull 'em
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0094", variables => $variables});
					$anvil->Alert->register({alert_level => "notice", message => "warning_0094", set_by => "ScanCore", variables => $variables});
					$anvil->Email->send_alerts();
					
					# Pull the server.
					my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
					$anvil->System->call({shell_call => $shell_call});
					
					# Alert that we're done.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
					$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
					$anvil->Email->send_alerts();
					
					return(0);
				}
				else
				{
					# Not time yet
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "warning_0095", variables => $variables});
				}
			}
			elsif ($local_power_health eq "2")
			{
				# We're on batteries, but our peer isn't. If this has been the case for two 
				# minutes, and we have no servers, shut down.
				if ($local_shortest_time_on_batteries >= 120)
				{
					# Do we have any servers?
					if ((not $local_server_count) && (not $am_syncsource))
					{
						# Shut down.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0097"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0097", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason power --power-off".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# We should not get to this point, but just in case...
						return(1);
					}
					# Is the strongest UPS under 10 minutes hold up left?
					elsif (($local_estimated_hold_up_time < 600) && (not $am_syncsource))
					{
						# We're critical. Shut down whether we have servers or not.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0096"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0096", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason power --power-off".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# We should not get to this point, but just in case...
						return(1);
					}
				}
				else
				{
					# Not time yet.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "warning_0098"});
				}
			}
			
			# Now check thermal.
			if (($local_temperature_health >= 3) && ($peer_temperature_health >= 3))
			{
				# We're both hot. Have both nodes been warm for over two minutes?
				if (($local_warning_age > 120) && ($peer_warning_age > 120))
				{
					if ((not $local_server_count) && (not $am_syncsource))
					{
						# Shut down.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0099"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0099", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason thermal --power-off".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# We should not get to this point, but just in case...
						return(1);
					}
					# Load shed or shut down?
					elsif (($local_critical_age > 120) && (not $am_syncsource))
					{
						# We've been critical for two minutes, shut down.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0100"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0100", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason thermal --power-off".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# We should not get to this point, but just in case...
						return(1);
					}
					else 
					{
						# Load shed
						$load_shed = "thermal";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { load_shed => $load_shed }});
					}
				}
				else
				{
					# We're both hot, but we haven't both been so for 2 minutes yet, so 
					# wait.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "warning_0101"});
				}
			}
			elsif ($peer_temperature_health >= 3)
			{
				# Our peer is hot, we're OK. Pull after two minutes.
				my $variables = {
					host_name => $peer_host_name,
				};
				if (($peer_warning_age > 120) or ($peer_critical_age > 120))
				{
					# Pull the servers.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0102", variables => $variables});
					$anvil->Alert->register({alert_level => "notice", message => "warning_0102", set_by => "ScanCore", variables => $variables});
					$anvil->Email->send_alerts();
					
					# Pull the server.
					my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
					$anvil->System->call({shell_call => $shell_call});
					
					# Alert that we're done.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
					$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
					$anvil->Email->send_alerts();
				}
				else
				{
					# Not yet.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "warning_0103", variables => $variables});
				}
			}
			elsif ($local_temperature_health >= 3)
			{
				# How long have we been hot for?
				if (($local_critical_age > 120) && (not $am_syncsource))
				{
					# Shut down, regardless.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0106"});
					$anvil->Alert->register({alert_level => "notice", message => "warning_0106", set_by => "ScanCore"});
					$anvil->Email->send_alerts();
					
					my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason thermal --power-off".$anvil->Log->switches;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
					$anvil->System->call({shell_call => $shell_call});
					
					# We should not get to this point, but just in case...
					return(1);
				}
				elsif ($local_warning_age > 120)
				{
					# Power off if we don't have servers.
					if ((not $local_server_count) && (not $am_syncsource))
					{
						# No servers, shut down
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0104"});
						$anvil->Alert->register({alert_level => "notice", message => "warning_0104", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason thermal --power-off".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# We should not get to this point, but just in case...
						return(1);
					}
				}
			}
			
			# Last, evaluate health if we're otherwise OK
			if ($peer_health > $local_health)
			{
				# The user may have set a migration threashold. 
				my $difference = $peer_health - $local_health;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { difference => $difference }});
				
				if (not $anvil->data->{feature}{scancore}{threshold}{'preventative-live-migration'})
				{
					$anvil->data->{feature}{scancore}{threshold}{'preventative-live-migration'} = 2;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						'feature::scancore::threshold::preventative-live-migration' => $anvil->data->{feature}{scancore}{threshold}{'preventative-live-migration'},
					}});
				}
				
				# A user may disable health-based preventative live migrations. 
				if ($anvil->data->{feature}{scancore}{disable}{'preventative-live-migration'})
				{
					# Do nothing.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0239"});
				}
				elsif ($difference >= $anvil->data->{feature}{scancore}{threshold}{'preventative-live-migration'})
				{
					# How long has this been the case?
					my $age = $anvil->Alert->check_condition_age({
						debug     => $debug,
						name      => "scancore::healthier-than-peer",
						host_uuid => $anvil->Get->host_uuid,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
					
					# Now that we've started counting, are there even any servers on the peer?
					if ($peer_server_count)
					{
						my $variables = {
							local_health => $local_health, 
							peer_health  => $peer_health, 
							peer_name    => $anvil->data->{cib}{parsed}{peer}{name}, 
							age          => $age, 
						};
						if ($age > 120)
						{
							# Time to migrate,.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0085", variables => $variables});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0085", set_by => "ScanCore", variables => $variables});
							$anvil->Email->send_alerts();
							
							my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
							$anvil->System->call({shell_call => $shell_call});
							
							# Alert that we're done.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
							$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
							$anvil->Email->send_alerts();
						}
						else
						{
							# Not time yet
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0084", variables => $variables});
							$anvil->Alert->register({alert_level => "notice", message => "warning_0084", set_by => "ScanCore", variables => $variables});
						}
					}
				}
			}
			else
			{
				# Make sure that, if there was a healthier-than-peer alert, it's cleared.
				$anvil->Alert->check_condition_age({
					debug     => $debug,
					clear     => 1,
					name      => "scancore::healthier-than-peer",
					host_uuid => $anvil->Get->host_uuid,
				});
			}
			
			### TODO: Allow users to mark servers as "non-critical". If we go into load shed, 
			###       shut down non-critical servers to speed up migrations and possibly allow
			###       entire Anvil! systems to go offline (ie: Dev/QA clusters). Do this using
			###       the 'servers::non-critical' variable.
			# If we're here, and we're asked to load shed, decide if we're pulling or shutting down.
			if ($load_shed)
			{
				### If we're here, we want to load shed, but haven't decided who should shut
				### down and who should stay up. Choose now.
				# Check if we're sync source/target
				if ($am_syncsource)
				{
					# We have the good data, pull servers
					if ($load_shed eq "power")
					{
						# Power
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0107"});
						$anvil->Alert->register({alert_level => "warning", message => "warning_0107", set_by => "ScanCore"});
					}
					else
					{
						# Thermal
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0108"});
						$anvil->Alert->register({alert_level => "warning", message => "warning_0108", set_by => "ScanCore"});
					}
					$anvil->Email->send_alerts();
					
					my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
					$anvil->System->call({shell_call => $shell_call});
					
					# Alert that we're done.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
					$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
					$anvil->Email->send_alerts();
					
					return(0);
				}
				
				### NOTE: If 'load_shed' is set and there are no servers on either host, both
				###       will go down. That's fine, faster recharge later / less thermal 
				###       loading.
				# If we're here, and we have no servers, we'll shut down.
				if (not $local_server_count)
				{
					# Shut down.
					if ($load_shed eq "power")
					{
						# Power
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0109"});
						$anvil->Alert->register({alert_level => "warning", message => "warning_0109", set_by => "ScanCore"});
					}
					else
					{
						# Thermal
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0110"});
						$anvil->Alert->register({alert_level => "warning", message => "warning_0110", set_by => "ScanCore"});
					}
					$anvil->Email->send_alerts();
					
					my $shell_call = $anvil->data->{path}{exe}{'anvil-safe-stop'}." --stop-reason ".$load_shed." --power-off".$anvil->Log->switches;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
					$anvil->System->call({shell_call => $shell_call});
					
					# We should never live to this point, but just in case...
					return(1);
				}
				
				# Still here? Can we pull the servers off the peer faster?
				if (($estimate_migration_pull_time eq "--") or ($estimated_migrate_off_time eq "--"))
				{
					# We can't use migration estimate time, so we'll use RAM.
					if ($local_ram_use > $peer_ram_use)
					{
						# We have more ram used by servers than our peer, so take 
						# their servers.
						if ($load_shed eq "power")
						{
							# Power
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0111"});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0111", set_by => "ScanCore"});
						}
						else
						{
							# Thermal
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0112"});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0112", set_by => "ScanCore"});
						}
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# Alert that we're done.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
						$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						return(0);
					}
					# if we're here, we have less RAM allocated to servers and our peer 
					# should take our servers. If so, once they're gone, we'll shut down 
					# above.
				}
				else
				{
					# We can use the migation estimate.
					if ($estimate_migration_pull_time < $estimated_migrate_off_time)
					{
						# We can pull quicker than our peer, take the servers.
						if ($load_shed eq "power")
						{
							# Power
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0113"});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0113", set_by => "ScanCore"});
						}
						else
						{
							# Thermal
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0114"});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0114", set_by => "ScanCore"});
						}
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# Alert that we're done.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
						$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						return(0);
					}
					# Our peer can take faster than us. We'll shut down if/when  we have no servers.
				}
				
				# In the unlikely event that the RAM allocated is equal on both nodes, that 
				# there is no estimated migration time (or they match), and we're not 
				# SyncSource, we'll pull if we're node 1.
				if ($anvil->data->{sys}{anvil}{i_am} eq "node1")
				{
					my $pull_servers = 0;
					if (not $am_syncsource)
					{
						if (($estimate_migration_pull_time eq "--") or ($estimated_migrate_off_time eq "--"))
						{
							if ($local_ram_use == $peer_ram_use)
							{
								$pull_servers = 1;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pull_servers => $pull_servers }});
							}
						}
						elsif ($local_ram_use == $peer_ram_use)
						{
							$pull_servers = 1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pull_servers => $pull_servers }});
						}
					}
					if ($pull_servers)
					{
						if ($load_shed eq "power")
						{
							# Power
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0115"});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0115", set_by => "ScanCore"});
						}
						else
						{
							# Thermal
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0116"});
							$anvil->Alert->register({alert_level => "warning", message => "warning_0116", set_by => "ScanCore"});
						}
						$anvil->Email->send_alerts();
						
						my $shell_call = $anvil->data->{path}{exe}{'anvil-migrate-server'}." --target local --server all".$anvil->Log->switches;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0011", variables => { shell_call => $shell_call }});
						$anvil->System->call({shell_call => $shell_call});
						
						# Alert that we're done.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "message_0238"});
						$anvil->Alert->register({alert_level => "notice", message => "message_0238", set_by => "ScanCore"});
						$anvil->Email->send_alerts();
						
						return(0);
					}
				}
			}
			
			### TODO: If we're here, we're healthy. Boot any servers that are non-critical and 
			###       off, if we've been OK for at least ten minutes.
		}
	}
	
	return(0);
}


=head2 post_scan_analysis_striker

This runs through ScanCore post-scan analysis on Striker dashboards.

This method takes no parameters;

=cut
sub post_scan_analysis_striker
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->post_scan_analysis_striker()" }});
	
	# We only boot nodes and DR hosts. Nodes get booted if 'variable_name = 'system::shutdown_reason' is 
	# set, or when a DR host is scheduled to boot.
	$anvil->Database->get_hosts_info({debug => $debug});
	
	# Load our IP information.
	my $short_host_name = $anvil->Get->short_host_name;
	$anvil->Network->load_ips({
		debug     => 2,
		clear     => 1, 
		host_uuid => $anvil->Get->host_uuid, 
	});
	
	# Get a look at all nodes and DR hosts. For each, check if they're up.
	foreach my $host_uuid (keys %{$anvil->data->{machine}{host_uuid}})
	{
		# Skip outself
		next if $host_uuid eq $anvil->Get->host_uuid();
		
		# Compile host's data.
		my $host_name       = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name};
		my $short_host_name = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{short_host_name};
		my $host_type       = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_type};
		my $host_key        = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_key};
		my $host_ipmi       = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi};
		my $host_status     = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_status};
		my $password        = $anvil->data->{machine}{host_uuid}{$host_uuid}{password};
		my $anvil_name      = $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{name};
		my $anvil_uuid      = $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{uuid};
		my $anvil_role      = $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{role};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_name       => $host_name, 
			short_host_name => $short_host_name, 
			host_type       => $host_type, 
			host_key        => $host_key, 
			host_ipmi       => $anvil->Log->is_secure($host_ipmi), 
			host_status     => $host_status, 
			password        => $anvil->Log->is_secure($password), 
			anvil_name      => $anvil_name, 
			anvil_uuid      => $anvil_uuid, 
			anvil_role      => $anvil_role, 
		}});
		
		# Check to see when the last 'updated' entry was from, and it if was less than 60 seconds 
		# ago, skip this machine as it's likely on.
		my $query = "
SELECT 
    round(extract(epoch from modified_date)) 
FROM 
    updated 
WHERE 
    updated_host_uuid = ".$anvil->Database->quote($host_uuid)." 
ORDER BY 
    modified_date DESC 
LIMIT 1;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $last_update = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		   $last_update = 0 if not defined $last_update;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_update => $last_update }});
		if (not $last_update)
		{
			# This machine isn't running ScanCore yet, skip it.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0597", variables => { host_name => $host_name }});
			next;
		}
		else
		{
			my $last_update_age = time - $last_update;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_update_age => $last_update_age }});
			
			if ($last_update_age < 120)
			{
				# It was alive less than two minutes ago, we don't need to check anything.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0596", variables => { 
					host_name  => $host_name,
					difference => $last_update_age, 
				}});
				next;
			}
		}
		
		# Read in the unified fence data, if it's not already loaded.
		my $update_fence_data = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::fence_data_updated" => $anvil->data->{sys}{fence_data_updated},
		}});
		if ($anvil->data->{sys}{fence_data_updated}) 
		{
			my $age = time - $anvil->data->{sys}{fence_data_updated};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
			if ($age < 86400)
			{
				# Only refresh daily.
				$update_fence_data = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_fence_data => $update_fence_data }});
			}
		}
		if ($update_fence_data)
		{
			$anvil->Striker->get_fence_data({debug => $debug});
		}
		
		# Check this target's power state.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0561", variables => { host_name => $host_name }});
		
		# Do we share a network with this system?
		$anvil->Network->load_ips({
			debug     => 2,
			clear     => 1, 
			host_uuid => $host_uuid, 
		});
		my $check_power = 1;
		my $match       = $anvil->Network->find_matches({
			debug  => $debug, 
			first  => $anvil->Get->host_uuid,
			second => $host_uuid, 
			source => $THIS_FILE, 
			line   => __LINE__,
		});
		my $matched_ips = keys %{$match};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { matched_ips => $matched_ips }});
		if (not $matched_ips)
		{
			# nothing we can do with this host.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0558", variables => { host_name => $host_name }});
			next;
		}
		foreach my $interface (sort {$a cmp $b} keys %{$match->{$host_uuid}})
		{
			my $ip_address = $match->{$host_uuid}{$interface}{ip};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:interface'  => $interface, 
				's2:ip_address' => $ip_address, 
			}});
			
			# Can we access the machine?
			my ($pinged, $average_time) = $anvil->Network->ping({
				debug => $debug,
				count => 3, 
				ping  => $ip_address,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				pinged       => $pinged,
				average_time => $average_time, 
			}});
			if ($pinged)
			{
				my $access = $anvil->Remote->test_access({
					debug    => $debug, 
					target   => $ip_address, 
					user     => "root",
					password => $password, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { access => $access }});
				if ($access)
				{
					# It's up.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0562", variables => { host_name => $host_name }});
					
					$check_power = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						check_power => $check_power,
						host_status => $host_status, 
					}});
					
					# If the host_status is 'booting' or 'unknown', change it to online.
					if (($host_status eq "booting") or ($host_status eq "unknown"))
					{
						$anvil->Database->update_host_status({
							debug       => $debug,
							host_uuid   => $host_uuid,
							host_status => "online",
						});
					}
					last;
				}
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			check_power     => $check_power,
			short_host_name => $short_host_name, 
			host_ipmi       => $host_ipmi, 
			host_status     => $host_status, 
		}});
		if (not $check_power)
		{
			next;
		}

		# Do we have IPMI info?
		if ((not $host_ipmi) && ($host_type eq "node") && ($anvil_uuid))
		{
			
			# No host IPMI (that we know of). Can we check using another (non PDU) fence method?
			my $query = "SELECT scan_cluster_cib FROM scan_cluster WHERE scan_cluster_anvil_uuid = ".$anvil->Database->quote($anvil_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			my $scan_cluster_cib = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			   $scan_cluster_cib = "" if not defined $scan_cluster_cib; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { scan_cluster_cib => $scan_cluster_cib }});
			if ($scan_cluster_cib)
			{
				# Parse out the fence methods for this host. 
				my $problem = $anvil->Cluster->parse_cib({
					debug => $debug,
					cib   => $scan_cluster_cib, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
				if (not $problem)
				{
					# Parsed! Do we have a fence method we can trust to check the power 
					# state of this node?
					my $node_name = exists $anvil->data->{cib}{parsed}{data}{node}{$short_host_name} ? $short_host_name : $host_name;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_name => $node_name }});
					foreach my $order (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}})
					{
						my $method = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$order}{devices};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:order'  => $order,
							's2:method' => $method, 
						}});
						my $agent = $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$method}{agent};
						if ((not defined $agent) && ($method =~ /,/))
						{
							# Break up the method name to find the agent.
							$agent = "";
							foreach my $sub_method (split/,/, $method)
							{
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sub_method => $sub_method }});
								if ((exists $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$sub_method}) && 
								    (defined $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$sub_method}{agent}))
								{
									$agent = $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$sub_method}{agent};
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { agent => $agent }});
									last;
								}
							}
						}
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { agent => $agent }});
						
						# We can't trust a PDU's output, so skip them. We also can't use the fake 'fence_delay' agent.
						next if $agent =~ /pdu/;
						next if $agent eq "fence_delay";
						
						my $shell_call = $agent." ";
						foreach my $stdin_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$method}{argument}})
						{
							next if $stdin_name =~ /pcmk_o\w+_action/;
							my $switch = "";
							my $value  = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$method}{argument}{$stdin_name}{value};
							
							foreach my $this_switch (sort {$a cmp $b} keys %{$anvil->data->{fence_data}{$agent}{switch}})
							{
								next if not defined $anvil->data->{fence_data}{$agent}{switch}{$this_switch}{name};
								my $this_name = $anvil->data->{fence_data}{$agent}{switch}{$this_switch}{name};
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
									this_switch => $this_switch,
									this_name   => $this_name, 
								}});
								if ($stdin_name eq $this_name)
								{
									   $switch  =  $this_switch;
									my $dashes  =  (length($switch) > 1) ? "--" : "-";
									$shell_call .= $dashes.$switch." \"".$value."\" ";
									last;
								}
							}
							if (not $switch)
							{
								if ($anvil->data->{fence_data}{$agent}{switch}{$stdin_name}{name})
								{
									my $dashes  =  (length($stdin_name) > 1) ? "--" : "-";
									$shell_call .= $dashes.$stdin_name." \"".$value."\" ";
								}
							}
						}
						$shell_call .= "--action status";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
						
						my ($output, $return_code) = $anvil->System->call({debug => $debug, timeout => 30, shell_call => $shell_call});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							output      => $output, 
							return_code => $return_code,
						}});
						foreach my $line (split/\n/, $output)
						{
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
						}
						
						if ($return_code eq "2")
						{
							# Node is off.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0564", variables => { host_name => $host_name }});
							$anvil->Database->update_host_status({
								debug       => $debug,
								host_uuid   => $host_uuid,
								host_status => "powered off",
							});
						}
						elsif ($return_code eq "0")
						{
							# Node is on.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0563", variables => { host_name => $host_name }});
							next;
						}
					}
				}
			}
			
			### TODO: Add support for power-cycling a target using PDUs.
			# Nothing we can do (for now)
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0559", variables => { host_name => $host_name }});
			next;
		}
		
		# If we're here and there's no host IPMI information, there's nothing we can do.
		if (not $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi})
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0560", variables => { host_name => $host_name }});
			next;
		}
		
		# Check the power state.
		my $shell_call =  $host_ipmi;
		   $shell_call =~ s/--action status//;
		   $shell_call =~ s/-o status//;
		   $shell_call .= " --action status";
		   $shell_call =~ s/  --action/ --action/;
		my ($output, $return_code) = $anvil->System->call({debug => $debug, timeout => 30, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		}
		
		if ($return_code eq "2")
		{
			# Node is off.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0564", variables => { host_name => $host_name }});
			$anvil->Database->update_host_status({
				debug       => $debug,
				host_uuid   => $host_uuid,
				host_status => "powered off",
			});
		}
		elsif ($return_code eq "0")
		{
			# Node is on.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0563", variables => { host_name => $host_name }});
			next;
		}
		
		# Still here? See if we know why the node is off.
		my ($stop_reason, $variable_uuid, $modified_date) = $anvil->Database->read_variable({
			variable_name         => "system::stop_reason",
			variable_source_table => "hosts",
			variable_source_uuid  => $host_uuid, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			stop_reason   => $stop_reason, 
			variable_uuid => $variable_uuid, 
			modified_date => $modified_date, 
		}});
		
		if (not $stop_reason)
		{
			$stop_reason = "unknown";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0565", variables => { host_name => $host_name }});
		}
		
		if ($stop_reason eq "user")
		{
			# Nothing to do.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0566", variables => { host_name => $host_name }});
			next;
		}
		elsif ($stop_reason eq "unknown")
		{
			# Check both power and temp.
			if ((not defined $anvil->data->{feature}{scancore}{disable}{'boot-unknown-stop'}) or (not exists $anvil->data->{feature}{scancore}{disable}{'boot-unknown-stop'}) or ($anvil->data->{feature}{scancore}{disable}{'boot-unknown-stop'} eq ""))
			{
				$anvil->data->{feature}{scancore}{disable}{'boot-unknown-stop'} = 1;
			}
			if (not $anvil->data->{feature}{scancore}{disable}{'boot-unknown-stop'})
			{
				# Ignore. 
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0671", variables => { host_name => $host_name }});
			}
			else
			{
				# Evaluate for boot.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0672", variables => { host_name => $host_name }});
				
				# Check power 
				my ($power_health, $shortest_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time) = $anvil->ScanCore->check_power({
					debug      => $debug,
					anvil_uuid => $anvil_uuid,
					anvil_name => $anvil_name,
					host_uuid  => $host_uuid,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					power_health               => $power_health,
					shortest_time_on_batteries => $shortest_time_on_batteries, 
					highest_charge_percentage  => $highest_charge_percentage, 
					estimated_hold_up_time     => $estimated_hold_up_time, 
				}});
				
				# Check temp.
				my ($temp_health) = $anvil->ScanCore->check_temperature_direct({
					debug     => $debug,
					host_uuid => $host_uuid, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temp_health => $temp_health }});
				
				### Temp
				# * 0 = Failed to read temperature sensors / IPMI unavailable
				# * 1 = All available temperatures are nominal.
				# * 2 = One of more sensors are in warning or critical.
				### Power
				# * 0 = No UPSes found for the host
				# * 1 = One or more UPSes found and at least one has input power from mains.
				# * 2 = One or more UPSes found, all are running on battery.
				if (($temp_health ne "2") && ($power_health ne "2"))
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0673", variables => { host_name => $host_name }});
					
					$shell_call =~ s/--action status/ --action on/;
					my ($output, $return_code) = $anvil->System->call({debug => 1, timeout => 30, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
					
					if ($return_code)
					{
						# Failed to boot.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0170", variables => { 
							host_name   => $host_name,
							return_code => $return_code, 
							output      => $output, 
						}});
					}
					else
					{
						# Mark it as booting.
						$anvil->Database->update_host_status({
							debug       => $debug,
							host_uuid   => $host_uuid,
							host_status => "booting",
						});
					}
				}
			}
		}
		elsif ($stop_reason eq "power")
		{
			# Check now if the power is OK
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0567", variables => { host_name => $host_name }});
			my ($power_health, $shortest_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time) = $anvil->ScanCore->check_power({
				debug      => $debug,
				anvil_uuid => $anvil_uuid,
				anvil_name => $anvil_name,
				host_uuid  => $host_uuid,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				power_health               => $power_health,
				shortest_time_on_batteries => $shortest_time_on_batteries, 
				highest_charge_percentage  => $highest_charge_percentage, 
				estimated_hold_up_time     => $estimated_hold_up_time, 
			}});
			# * 0 - No UPSes found for the host
			# * 1 - One or more UPSes found and at least one has input power from mains.
			# * 2 - One or more UPSes found, all are running on battery.
			if ($power_health eq "1")
			{
				# Power is (at least partially) back. What's the charge percent?
				if ((not $anvil->data->{scancore}{power}{safe_boot_percentage}) or ($anvil->data->{scancore}{power}{safe_boot_percentage} =~ /\D/))
				{
					$anvil->data->{scancore}{power}{safe_boot_percentage} = 35;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 
						"scancore::power::safe_boot_percentage" => $anvil->data->{scancore}{power}{safe_boot_percentage}, 
					}});
				}
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					highest_charge_percentage               => $highest_charge_percentage, 
					"scancore::power::safe_boot_percentage" => $anvil->data->{scancore}{power}{safe_boot_percentage}, 
				}});
				if ($highest_charge_percentage >= $anvil->data->{scancore}{power}{safe_boot_percentage})
				{
					# Safe to boot!
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0574", variables => { host_name => $host_name }});
					$shell_call =~ s/--action status/ --action on/;
					my ($output, $return_code) = $anvil->System->call({debug => $debug, timeout => 30, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
					
					# Mark it as booting.
					$anvil->Database->update_host_status({
						debug       => $debug,
						host_uuid   => $host_uuid,
						host_status => "booting",
					});
				}
			}
		}
		elsif ($stop_reason eq "thermal")
		{
			# Check now if the temperature is OK.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0568", variables => { host_name => $host_name }});
			my ($temp_health) = $anvil->ScanCore->check_temperature_direct({
				debug     => $debug,
				host_uuid => $host_uuid, 
			});
			
			### Temp
			# * 0 = Failed to read temperature sensors / IPMI unavailable
			# * 1 = All available temperatures are nominal.
			# * 2 = One of more sensors are in warning or critical.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temp_health => $temp_health }});
			
			if ($temp_health eq "1")
			{
				### TODO: We'll want to revisit M2's restart cooldown logic. It never 
				###       actually proved useful in M2, but it doesn't mean it wouldn't help
				###       in the right situation.
				# Safe to boot!
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0575", variables => { host_name => $host_name }});
				$shell_call =~ s/--action status/ --action on/;
				my ($output, $return_code) = $anvil->System->call({debug => $debug, timeout => 30, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				
				# Mark it as booting.
				$anvil->Database->update_host_status({
					debug       => $debug,
					host_uuid   => $host_uuid,
					host_status => "booting",
				});
			}
		}
	}
	
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

# This looks in the passed-in directory for scan agents or sub-directories (which will in turn be scanned).
sub _scan_directory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->_scan_directory()" }});
	
	my $directory = defined $parameter->{directory} ? $parameter->{directory} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		directory => $directory, 
	}});
	
	if (not $directory)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "ScanCore->_scan_directory()", parameter => "directory" }});
		return("!!error!!");
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { directory => $directory }});
	local(*DIRECTORY);
	opendir(DIRECTORY, $directory);
	while(my $file = readdir(DIRECTORY))
	{
		next if $file eq ".";
		next if $file eq "..";
		my $full_path = $directory."/".$file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file      => $file,
			full_path => $full_path,
		}});
		# If we're looking at a directory, scan it. Otherwise, see if it's an executable and that it
		# starts with 'scan-*'.
		if (-d $full_path)
		{
			# This is a directory, dive into it.
			$anvil->ScanCore->_scan_directory({directory => $full_path});
		}
		elsif (-x $full_path)
		{
			# Now I only want to know if the file starts with 'scan-'
			next if $file !~ /^scan-/;
			
			# If I am still alive, I am looking at a scan agent!
			$anvil->data->{scancore}{agent}{$file} = $full_path;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scancore::agent::${file}" => $anvil->data->{scancore}{agent}{$file},
			}});
		}
	}
	closedir(DIRECTORY);
	
	return(0);
}


1;

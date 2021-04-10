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
# agent_startup
# call_scan_agents
# check_power
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


=head2 agent_startup

This method handles connecting to the databases, loading the agent's schema, resync'ing database tables if needed and reading in the words files.

If there is a problem, this method exits with C<< 1 >>. Otherwise, it exits with C<< 0 >>.

Parameters;

=head3 agent (required)

This is the name of the scan agent. Usually this can be set as C<< $THIS_FILE >>.

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
	
	my $agent  = defined $parameter->{agent}  ? $parameter->{agent}  : "";
	my $tables = defined $parameter->{tables} ? $parameter->{tables} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		agent  => $agent, 
		tables => $tables, 
	}});
	
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
		return(1);
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

This method takes no parameters.

=cut
sub call_scan_agents
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->call_scan_agents()" }});
	
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
		
		# Tell the user this agent is about to run...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, key => "log_0252", variables => {
			agent_name => $agent_name,
			timeout    => $timeout,
		}});
		my ($output, $return_code) = $anvil->System->call({timeout => $timeout, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		}
		
		# If an agent takes a while to run, log it with higher verbosity
		my $runtime   = (time - $start_time);
		my $log_level = $runtime > 10 ? 1 : $debug;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, runtime => $runtime }});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $log_level, key => "log_0557", variables => {
			agent_name  => $agent_name,
			runtime     => $runtime,
			return_code => $return_code,
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

=head3 anvil_uuid (required)

This is the Anvil! UUID that the machine belongs to. This is required to find the manifest that shows which UPSes power the host.

=head3 anvil_name (required)

This is the Anvil! name that the machine is a member of. This is used for logging.

=head3 host_uuid (required)

This is the host's UUID that we're checking the UPSes powering it.

=head3 host_name (required)

This is the host's name that we're checking. This is used for logging.

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
	my $host_name  = defined $parameter->{host_name}  ? $parameter->{host_name}  : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid,
		anvil_name => $anvil_name,
		host_uuid  => $host_uuid,
		host_name  => $host_name,
	}});
	
	if ((not $anvil_uuid) or (not $anvil_name) or (not $host_uuid) or (not $host_name))
	{
		# Woops
		return("!!error!!");
	}
	
	# We'll need the UPS data
	$anvil->Database->get_upses({debug => $debug});
	
	my $power_health              = 0;
	my $shorted_time_on_batteries = 99999;
	my $highest_charge_percentage = 0;
	my $estimated_hold_up_time    = 0;
	
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
		return($power_health, $shorted_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time)
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
			return($power_health, $shorted_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time)
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
					my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
					my $count   = @{$results};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						results => $results, 
						count   => $count, 
					}});
					if (not $count)
					{
						# The only way this could happen is if we've never seen the UPS on mains...
						$shorted_time_on_batteries = 0;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0571", variables => { 
							power_uuid => $power_uuid, 
							host_name  => $host_name, 
						}});
					}
					else
					{
						my $time_on_batteries = $results->[0]->[0];
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							time_on_batteries => $time_on_batteries." (".$anvil->Convert->time({'time' => $time_on_batteries, long => 1, translate => 1}).")",
						}});
						
						if ($time_on_batteries < $shorted_time_on_batteries)
						{
							$shorted_time_on_batteries = $shorted_time_on_batteries;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								shorted_time_on_batteries => $shorted_time_on_batteries." (".$anvil->Convert->time({'time' => $shorted_time_on_batteries, long => 1, translate => 1}).")",
							}});
						}
					}
				}
				else
				{
					# See how charged up this UPS is. 
					$power_health              = 1;
					$ups_with_mains_found      = 1;
					$shorted_time_on_batteries = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						ups_with_mains_found      => $ups_with_mains_found,
						shorted_time_on_batteries => $shorted_time_on_batteries, 
					}});
						
					if ($power_charge_percentage > $highest_charge_percentage)
					{
						$highest_charge_percentage = $power_charge_percentage;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { highest_charge_percentage => $highest_charge_percentage }});
					}
				}
			}
		}
	}
	
	if ($ups_count)
	{
		# No UPSes found.
		$shorted_time_on_batteries = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shorted_time_on_batteries => $shorted_time_on_batteries }});
	}
	
	return($power_health, $shorted_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time);
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
	
	
	
	return(0);
}


=head2 post_scan_analysis_node

This runs through ScanCore post-scan analysis on Anvil! nodes.

This method takes no parameters;

=cut
sub post_scan_analysis_node
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->post_scan_analysis_node()" }});
	
	
	
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
		my $short_host_name = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name};
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
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0596", variables => { 
					host_name  => $host_name,
					difference => $last_update_age, 
				}});
				next;
			}
		}
		
		# Read in the unified fence data, if it's not already loaded.
		my $update_fence_data = 1;
		if ($anvil->data->{fence_data}{updated}) 
		{
			my $age = time - $anvil->data->{fence_data}{updated};
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
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0561", variables => { host_name => $host_name }});
		
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
		});
		my $matched_ips = keys %{$match};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { matched_ips => $matched_ips }});
		if (not $matched_ips)
		{
			# nothing we can do with this host.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0558", variables => { host_name => $host_name }});
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
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0562", variables => { host_name => $host_name }});
					
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
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_power => $check_power }});
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
						my $agent  = $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$method}{agent};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:order'  => $order,
							's2:method' => $method, 
							's3:agent'  => $agent 
						}});
						
						# We can't trust a PDU's output, so skip them.
						next if $agent =~ /pdu/;
						
						my $shell_call = $agent." ";
						foreach my $stdin_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$method}{argument}})
						{
							next if $stdin_name =~ /pcmk_o\w+_action/;
							my $switch = "";
							my $value  = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$method}{argument}{$stdin_name}{value};
							
							foreach my $this_switch (sort {$a cmp $b} keys %{$anvil->data->{fence_data}{$agent}{switch}})
							{
								my $this_name = $anvil->data->{fence_data}{$agent}{switch}{$this_switch}{name};
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
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
						
						my ($output, $return_code) = $anvil->System->call({debug => $debug, timeout => 30, shell_call => $shell_call});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
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
			
			### TODO: Add support for power-cycling a target using PDUs. Until this, this
			###       will never be hit as we next on no host_ipmi, but will be useful 
			###       when PDU support is added.
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
		my $boot_target = 0;
		my $stop_reason = "unknown";
		   $query       = "
SELECT 
    variable_value 
FROM 
    variables 
WHERE 
    variable_name         = 'system::stop_reason' 
AND 
    variable_source_table = 'hosts' 
AND 
    variable_source_uuid  = ".$anvil->Database->quote($host_uuid)."
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
			$stop_reason = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { stop_reason => $stop_reason }});
		}
		
		if (not $stop_reason)
		{
			# Nothing to do.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0565", variables => { host_name => $host_name }});
			next;
		}
		elsif ($stop_reason eq "user")
		{
			# Nothing to do.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0566", variables => { host_name => $host_name }});
			next;
		}
		elsif ($stop_reason eq "power")
		{
			# Check now if the power is OK
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0567", variables => { host_name => $host_name }});
			my ($power_health, $shorted_time_on_batteries, $highest_charge_percentage, $estimated_hold_up_time) = $anvil->ScanCore->check_power({
				debug      => $debug,
				anvil_uuid => $anvil_uuid,
				anvil_name => $anvil_name,
				host_uuid  => $host_uuid,
				host_name  => $host_name,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				power_health              => $power_health,
				shorted_time_on_batteries => $shorted_time_on_batteries, 
				highest_charge_percentage => $highest_charge_percentage, 
				estimated_hold_up_time    => $estimated_hold_up_time, 
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
				next;
			}
			
			$anvil->System->collect_ipmi_data({
				host_name        => $host_name, 
				ipmitool_command => $ipmitool_command, 
				ipmi_password    => $ipmi_password, 
			});
			
			# Now look for thermal values.
			my $sensor_found    = 0;
			my $temperatures_ok = 1;
			foreach my $sensor_name (sort {$a cmp $b} keys %{$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}})
			{
				my $current_value = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_value_sensor_value};
				my $units         = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_units};
				my $status        = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_status};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					current_value => $current_value, 
					sensor_name   => $sensor_name, 
					units         => $units, 
					status        => $status, 
				}});
				
				# If this is a temperature, check to see if it is outside its nominal range and, if
				# so, record it into a hash for loading into ScanCore's 'temperature' table.
				if ($units eq "C")
				{
					if (not $sensor_found)
					{
						# We've found at least one temperature sensor.
						$sensor_found = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sensor_found => $sensor_found }});
					}
					
					if ($status ne "ok")
					{
						# Sensor isn't OK yet.
						$temperatures_ok = 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temperatures_ok => $temperatures_ok }});
					}
				}
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				sensor_found    => $sensor_found,
				temperatures_ok => $temperatures_ok, 
			}});
			if (($sensor_found) && ($temperatures_ok))
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

package Anvil::Tools::Database;
# 
# This module contains methods related to databases.
# 

use strict;
use warnings;
use DBI;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Text::Diff;
use Time::HiRes qw(gettimeofday tv_interval);
use XML::LibXML;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Database.pm";

### Methods;
# archive_database
# backup_database
# check_file_locations
# check_hosts
# check_lock_age
# check_for_schema
# configure_pgsql
# connect
# disconnect
# find_host_uuid_columns
# get_alert_overrides
# get_anvil_uuid_from_string
# get_alerts
# get_anvils
# get_bridges
# get_dr_links
# get_drbd_data
# get_fences
# get_file_locations
# get_files
# get_host_from_uuid
# get_host_uuid_from_string
# get_hosts
# get_hosts_info
# get_ip_addresses
# get_job_details
# get_jobs
# get_local_uuid
# get_lvm_data
# get_mac_to_ip
# get_mail_servers
# get_manifests
# get_recipients
# get_server_uuid_from_string
# get_servers
# get_storage_group_data
# get_ssh_keys
# get_tables_from_schema
# get_power
# get_upses
# get_variables
# initialize
# insert_or_update_alert_overrides
# insert_or_update_anvils
# insert_or_update_bridges
# insert_or_update_bonds
# insert_or_update_dr_links
# insert_or_update_fences
# insert_or_update_file_locations
# insert_or_update_files
# insert_or_update_health
# insert_or_update_hosts
# insert_or_update_ip_addresses
# insert_or_update_jobs
# insert_or_update_mail_servers
# insert_or_update_manifests
# insert_or_update_network_interfaces
# insert_or_update_mac_to_ip
# insert_or_update_oui
# insert_or_update_power
# insert_or_update_recipients
# insert_or_update_servers
# insert_or_update_server_definitions
# insert_or_update_sessions
# insert_or_update_ssh_keys
# insert_or_update_states
# insert_or_update_storage_groups
# insert_or_update_storage_group_members
# insert_or_update_temperature
# insert_or_update_updated
# insert_or_update_upses
# insert_or_update_users
# insert_or_update_variables
# load_database
# lock_file
# locking
# manage_anvil_conf
# mark_active
# purge_data
# query
# quote
# read
# read_variable
# refresh_timestamp
# resync_databases
# shutdown
# track_files
# update_host_status
# write
# _add_to_local_config
# _age_out_data
# _archive_table
# _check_for_duplicates
# _find_column
# _find_behind_database
# _mark_database_as_behind
# _test_access

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Database

Provides all methods related to managing and accessing databases.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Database->X'. 
 # 
 # Example using 'get_local_uuid()';
 my $local_id = $anvil->Database->get_local_uuid;

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


=head2 archive_database

This method takes an array reference of database tables and check each to see if their history schema version needs to be archived or not.

Parameters;

=head3 tables (required, hash reference)

This is an B<< array reference >> of tables to archive. 

B<< NOTE >>: The array is processed in B<< reverse >> order! This is done to allow the same array used to create/sync tables to be used without modification (foreign keys will be archived/removed before primary keys)

=cut
sub archive_database
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->archive_database()" }});
	
	my $tables = defined $parameter->{tables} ? $parameter->{tables} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { tables => $tables }});
	
	# If not given tables, use the system tables.
	if (not $tables)
	{
		$tables = $anvil->Database->get_tables_from_schema({debug => $debug, schema_file => "all"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { tables => $tables }});
	}
	
	# If this isn't a dashboard, exit. 
	my $host_type = $anvil->Get->host_type();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "striker")
	{
		# Not a dashboard, don't archive
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0452"});
		return(1);
	}
	
	# If the 'tables' parameter is an array reference, add it to 'sys::database::check_tables' (creating
	# it, if needed).
	if (ref($tables) ne "ARRAY")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0432"});
		return(1);
	}
	
	# Only the root user can archive the database so that the archived files can be properly secured.
	if (($< != 0) && ($> != 0))
	{
		# Not root
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0188"});
		return(1);
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0451"});
	
	# Make sure I have sane values.
	$anvil->data->{sys}{database}{archive}{compress}     = 1      if not defined $anvil->data->{sys}{database}{archive}{compress};
	$anvil->data->{sys}{database}{archive}{count}        = 100000 if not defined $anvil->data->{sys}{database}{archive}{count};
	$anvil->data->{sys}{database}{archive}{division}     = 125000 if not defined $anvil->data->{sys}{database}{archive}{division};
	$anvil->data->{sys}{database}{archive}{trigger}      = 500000 if not defined $anvil->data->{sys}{database}{archive}{trigger};
	$anvil->data->{sys}{database}{archive}{save_to_disk} = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::archive::compress" => $anvil->data->{sys}{database}{archive}{compress},
		"sys::database::archive::count"    => $anvil->data->{sys}{database}{archive}{count},
		"sys::database::archive::division" => $anvil->data->{sys}{database}{archive}{division},
		"sys::database::archive::trigger"  => $anvil->data->{sys}{database}{archive}{trigger},
	}});
	
	# Make sure the archive directory is sane.
	if ((not defined $anvil->data->{sys}{database}{archive}{directory}) or ($anvil->data->{sys}{database}{archive}{directory} !~ /^\//))
	{
		$anvil->data->{sys}{database}{archive}{directory} = "/usr/local/anvil/archives/";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::archive::directory" => $anvil->data->{sys}{database}{archive}{directory},
		}});
	}
	
	# Make sure the numerical values are sane
	if ($anvil->data->{sys}{database}{archive}{count} !~ /^\d+$/)
	{
		# Use the set value if it just has commas.
		$anvil->data->{sys}{database}{archive}{count} =~ s/,//g;
		$anvil->data->{sys}{database}{archive}{count} =~ s/\.\d+$//g;
		if ($anvil->data->{sys}{database}{archive}{count} !~ /^\d+$/)
		{
			$anvil->data->{sys}{database}{archive}{count} = 10000;
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::archive::count" => $anvil->data->{sys}{database}{archive}{count},
		}});
	}
	if ($anvil->data->{sys}{database}{archive}{division} !~ /^\d+$/)
	{
		# Use the set value if it just has commas.
		$anvil->data->{sys}{database}{archive}{division} =~ s/,//g;
		$anvil->data->{sys}{database}{archive}{division} =~ s/\.\d+$//g;
		if ($anvil->data->{sys}{database}{archive}{division} !~ /^\d+$/)
		{
			$anvil->data->{sys}{database}{archive}{division} = 25000;
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::archive::division" => $anvil->data->{sys}{database}{archive}{division},
		}});
	}
	if ($anvil->data->{sys}{database}{archive}{trigger} !~ /^\d+$/)
	{
		# Use the set value if it just has commas.
		$anvil->data->{sys}{database}{archive}{trigger} =~ s/,//g;
		$anvil->data->{sys}{database}{archive}{trigger} =~ s/\.\d+$//g;
		if ($anvil->data->{sys}{database}{archive}{trigger} !~ /^\d+$/)
		{
			$anvil->data->{sys}{database}{archive}{trigger} = 20000;
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::archive::trigger" => $anvil->data->{sys}{database}{archive}{trigger},
		}});
	}
	
	# Is archiving disabled?
	if (not $anvil->data->{sys}{database}{archive}{trigger})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0189"});
		return(1);
	}
	
	# We'll use the list of tables created for _find_behind_databases()'s 'sys::database::check_tables' 
	# array, but in reverse so that tables with primary keys (first in the array) are archived last.
	foreach my $table (reverse(@{$tables}))
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
		$anvil->Database->_archive_table({debug => $debug, table => $table});
	}
	
	return(0);
}


=head2 backup_database

This backs up the database to the C<< path::directories::pgsql >> directory as the file name C<< anvil_pg_dump.<host_uuid>.out >>.

If the backup is successful, the full path to the backup file is returned. If there is a problem, C<< !!error!! >> is returned.

B<< Note >>: This method must be called by the root user.

B<< Note >>: If C<< sys::database::name >> has been changed, the dump file name will match. 

This method takes no parameters.

=cut
sub backup_database
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->backup_database()" }});
	
	# Only the root user can do this
	if (($< != 0) && ($> != 0))
	{
		# Not root
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0352"});
		return('!!error!!');
	}
	
	my $start_time =  time;
	my $dump_file  =  $anvil->data->{path}{directories}{pgsql}."/anvil_db_dump.".$anvil->Get->host_uuid().".sql";
	   $dump_file  =~ s/\/\//\//g;
	my $dump_call  =  $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{pg_dump}." anvil > ".$dump_file."\"";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		dump_file => $dump_file, 
		dump_call => $dump_call, 
	}});
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $dump_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	
	if ($return_code)
	{
		# Dump failed. 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0351", variables => {
			shell_call  => $dump_call, 
			return_code => $return_code, 
			output      => $output, 
		}});
		
		# Clear the out file.
		if (-e $dump_file)
		{
			unlink $dump_file;
		}
		return('!!error!!');
	}
	
	# Record the stats
	$anvil->Storage->get_file_stats({debug => $debug, file_path => $dump_file});
	my $dump_time  = time - $start_time;
	my $size       = $anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{file_stat}{$dump_file}{size}}); 
	my $size_bytes = $anvil->Convert->add_commas({number => $anvil->data->{file_stat}{$dump_file}{size}}); 
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0654", variables => {
		file       => $dump_file, 
		took       => $dump_time, 
		size       => $size, 
		size_bytes => $size_bytes, 
	}});
	
	return($dump_file);
}

=head2 check_file_locations

This method checks to see that there is a corresponding entry in C<< file_locations >> for all hosts and files in the database. Any that are found to be missing will be set to C<< file_location_active >> -> c<< true >>.

This method takes no parameters.

=cut
sub check_file_locations
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->check_file_locations()" }});
	
	# Get all the Anvil! systems we know of.
	$anvil->Database->get_hosts({debug => $debug});
	
	foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{hosts}{host_name}})
	{
		my $host_uuid = $anvil->data->{hosts}{host_name}{$host_name}{host_uuid};
		
		foreach my $file_name (sort {$a cmp $b} keys %{$anvil->data->{files}{file_name}})
		{
			my $file_uuid = $anvil->data->{files}{file_name}{$file_name}{file_uuid};
			
			# Does this file exist for this Anvil! system?
			if (not exists $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}{file_location_uuid})
			{
				# Add this entry.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0613", variables => { 
					host_name => $host_name,
					file_name => $file_name, 
				}});
				
				my $file_location_uuid = $anvil->Database->insert_or_update_file_locations({
					debug                   => $debug, 
					file_location_file_uuid => $file_uuid, 
					file_location_host_uuid => $host_uuid, 
					file_location_active    => 1, 
					file_location_ready     => "same",
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
			}
		}
	}
	
	return(0);
}

=head2 check_hosts

This checks to see if there's an entry in the C<< hosts >> table on each database. This is meant to avoid an INSERT on a table with a record already, wich can happen when programs start before initial sync.

This method takes no parameters.

=cut
sub check_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->check_hosts()" }});

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::connections" => $anvil->data->{sys}{database}{connections},
	}});
	if ($anvil->data->{sys}{database}{connections} < 1)
	{
		# Nothing to do.
		return(0);
	}
	
	# If we're starting with a new database, which is not yet in the hosts table, we can hit a case where
	# this tries to insert into both DBs when it's only missing from one. So to habdle that, we'll 
	# manually check each DB to see if all hosts are there and, if not, INSERT only into the needed DB.
	foreach my $db_uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		# Are we connected?
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"db_status::${db_uuid}::access" => $anvil->data->{db_status}{$db_uuid}{access},
		}});
		next if not $anvil->data->{db_status}{$db_uuid}{access};
		
		# Get the host information from the host.
		my $query = "
SELECT 
    host_ipmi, 
    host_name, 
    host_type, 
    host_key, 
    host_status 
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->Database->quote($db_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $db_uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		next if not $count;
		my $db_host_ipmi   = $results->[0]->[0];
		my $db_host_name   = $results->[0]->[1];
		my $db_host_type   = $results->[0]->[2];
		my $db_host_key    = $results->[0]->[3];
		my $db_host_status = $results->[0]->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			db_host_ipmi   => $db_host_ipmi =~ /passw/ ? $anvil->Log->is_secure($db_host_ipmi) : $db_host_ipmi,
			db_host_name   => $db_host_name, 
			db_host_type   => $db_host_type, 
			db_host_key    => $db_host_key, 
			db_host_status => $db_host_status, 
		}});
		
		# Is this host in all DBs?
		foreach my $check_uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
		{
			# Are we connected?
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"db_status::${check_uuid}::access" => $anvil->data->{db_status}{$check_uuid}{access},
			}});
			next if not $anvil->data->{db_status}{$check_uuid}{access};
			
			my $query = "SELECT COUNT(*) FROM hosts WHERE host_uuid = ".$anvil->Database->quote($check_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $check_uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count,
			}});
			
			if (not $count)
			{
				# INSERT it!
				$anvil->Database->insert_or_update_hosts({
					debug       => 2,
					uuid        => $check_uuid, 
					host_ipmi   => $db_host_ipmi, 
					host_key    => $db_host_key, 
					host_name   => $db_host_name, 
					host_type   => $db_host_type, 
					host_uuid   => $db_uuid, 
					host_status => $db_host_status, 
				});
			}
		}
	}
	
	return(0);
}


=head2 check_lock_age

This checks to see if 'sys::database::local_lock_active' is set. If it is, its age is checked and if the age is >50% of sys::database::locking_reap_age, it will renew the lock.

This method takes no parameters.

=cut
sub check_lock_age
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->check_lock_age()" }});
	
	# Make sure we've got the 'sys::database::local_lock_active' and 'reap_age' variables set.
	if ((not defined $anvil->data->{sys}{database}{local_lock_active}) or ($anvil->data->{sys}{database}{local_lock_active} =~ /\D/))
	{
		$anvil->data->{sys}{database}{local_lock_active} = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active} }});
	}
	if ((not $anvil->data->{sys}{database}{locking_reap_age}) or ($anvil->data->{sys}{database}{locking_reap_age} =~ /\D/))
	{
		$anvil->data->{sys}{database}{locking_reap_age} = 300;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active} }});
	}
	
	# If I have an active lock, check its age and also update the Anvil! lock file.
	my $renewed = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active} }});
	if ($anvil->data->{sys}{database}{local_lock_active})
	{
		my $current_time  = time;
		my $lock_age      = $current_time - $anvil->data->{sys}{database}{local_lock_active};
		my $half_reap_age = int($anvil->data->{sys}{database}{locking_reap_age} / 2);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			current_time  => $current_time,
			lock_age      => $lock_age,
			half_reap_age => $half_reap_age, 
		}});
		
		if ($lock_age > $half_reap_age)
		{
			# Renew the lock.
			#$anvil->Database->locking({renew => 1});
			$renewed = 1;
			
			# Update the lock age
			$anvil->data->{sys}{database}{local_lock_active} = time;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active} }});
			
			# Update the lock file
			my $lock_file_age = $anvil->Database->lock_file({'do' => "set"});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lock_file_age => $lock_file_age }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { renewed => $renewed }});
	return($renewed);
}


=head2 check_agent_data

This method is designed to be used by ScanCore scan agents. It does two main tasks; Verifies that the agent's SQL schema is loaded in all databases and handles resync'ing their data when necessary.

B<< Note >>: This method calls C<< Database->check_for_schema >>, so calling it before this method is generally not required.

Parameters; 

=head3 agent (required) 

This is the name of the calling scan agent. The name is used to find the schema file under C<< <path::directories::scan_agents>/<agent>/<agent>.sql >>. 

=head3 tables (required)

This is the array reference of tables used to check if any databases are behind and need a resync.

=cut
sub check_agent_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->check_agent_data()" }});
	
	my $agent  = defined $parameter->{agent}  ? $parameter->{agent}  : "";
	my $tables = defined $parameter->{tables} ? $parameter->{tables} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		agent  => $agent, 
		tables => $tables, 
	}});
	
	if (not $agent)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->check_agent_data()", parameter => "agent" }});
		return("!!error!!");
	}
	if (ref($tables) ne "ARRAY")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->check_agent_data()", parameter => "tables" }});
		return("!!error!!");
	}
	
	my $schema_file = $anvil->data->{path}{directories}{scan_agents}."/".$agent."/".$agent.".sql";
	my $loaded      = $anvil->Database->check_for_schema({
		debug => $debug, 
		file  => $schema_file,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		loaded      => $loaded,
		schema_file => $schema_file, 
	}});
	if ($loaded)
	{
		if ($loaded eq "!!error!!")
		{
			# Something went wrong.
			my $changed = $anvil->Alert->check_alert_sent({
				debug          => $debug,
				record_locator => "schema_load_failure",
				set_by         => $agent,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changed => $changed }});
			if ($changed)
			{
				# Log and register an alert. This should never happen, so we set it as a 
				# warning level alert.
				my $variables = {
					agent_name => $agent,
					file       => $schema_file,
				};
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "message_0181", variables => $variables});
				$anvil->Alert->register({
					debug       => $debug,
					alert_level => "warning",
					message     => "message_0181",
					variables   => $variables, 
					set_by      => $agent,
				});
			}
		}
		elsif (ref($loaded) eq "ARRAY")
		{
			# If there was an alert, clear it.
			my $changed = $anvil->Alert->check_alert_sent({
				debug          => $debug,
				record_locator => "schema_load_failure",
				set_by         => $agent,
				clear          => 1,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changed => $changed }});
			if ($changed)
			{
				# Register an alert cleared message.
				my $variables = {
					agent_name => $agent,
					file       => $schema_file,
				};
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "message_0182", variables => $variables});
				$anvil->Alert->register({
					debug       => $debug,
					alert_level => "warning",
					clear_alert => 1,
					message     => "message_0182",
					variables   => $variables, 
					set_by      => $agent,
				});
			}

			# Log which databses we loaded our schema into.
			foreach my $uuid (@{$loaded})
			{
				my $host_name = $anvil->Database->get_host_from_uuid({short => 1, host_uuid => $uuid});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $debug, key => "message_0183", variables => {
					agent_name => $agent,
					host_name  => $host_name,
					
				}});
			}
		}
	}
	
	# Hold if a lock has been requested.
	#$anvil->Database->locking({debug => $debug});
	
	# Mark that we're now active.
	#$anvil->Database->mark_active({debug => $debug, set => 1});
	
	return(0);
}


=head2 check_for_schema

This reads in a SQL schema file and checks if the first table seen exists in the database. If it isn't, the schema file is loaded into the database main.

If the table exists (and loading isn't needed), C<< 0 >> is returned. If the schema is loaded, an array reference of the host UUIDs that were loaded is returned. If there is any problem, C<< !!error!! >> is returned.

B<< Note >>: This does not check for schema changes! 

This method is meant to be used by ScanCore scan agents to see if they're running for the first time.

Parameters;

=head3 file (required)

This is the file to be read in.

=cut
sub check_for_schema
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->check_for_schema()" }});
	
	my $loaded = 0;
	my $file   = defined $parameter->{file} ? $parameter->{file} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file => $file, 
	}});
	
	# We only test that a file was passed in. Storage->read will catch errors with the file not existing,
	# permission issues, etc.
	if (not $file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->check_for_schema()", parameter => "file" }});
		return("!!error!!");
	}
	
	my $table  = "";
	my $schema = "public";
	my $body   = $anvil->Storage->read_file({debug => $debug, file => $file});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
	foreach my $line (split/\n/, $body)
	{
		$line =~ s/--.*$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /CREATE TABLE (.*?) \(/i)
		{
			$table = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
			
			if ($table =~ /^(.*?)\.(.*)$/)
			{
				$schema = $1;
				$table  = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
					table  => $table, 
					schema => $schema,
				}});
			}
			last;
		}
	}
	
	# Did we find a table?
	if (not $table)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0097", variables => { file => $file}});
		return("!!error!!");
	}
	
	my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->Database->quote($table)." AND schemaname=".$anvil->Database->quote($schema).";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	# We have to query each DB individually.
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
	{
		my $host_name = $anvil->Database->get_host_from_uuid({debug => $debug, short => 1, host_uuid => $uuid});
		my $count     = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:count'     => $count,
			's2:host_name' => $host_name,
		}});
		
		if ($count)
		{
			# No need to add.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0544", variables => { 
				table => $schema.".".$table,
				host  => $host_name,
			}});
		}
		else
		{
			# Load the schema.
			if ($loaded eq "0")
			{
				$loaded = [];
			}
			push @{$loaded}, $uuid;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0545", variables => { 
				table => $schema.".".$table,
				host  => $host_name,
				file  => $file,
			}});
			
			# Write out the schema now.
			$anvil->Database->write({
				debug       => $debug,
				uuid        => $uuid, 
				transaction => 1, 
				query       => $body, 
				source      => $THIS_FILE, 
				line        => __LINE__,
			});
		}
	}
	
	return($loaded);
}


=head2 configure_pgsql

This configures the local database server. Specifically, it checks to make sure the daemon is running and starts it if not. It also checks the C<< pg_hba.conf >> configuration to make sure it is set properly to listen on this machine's IP addresses and interfaces.

If the system is already configured, this method will do nothing, so it is safe to call it at any time.

If the method completes, C<< 0 >> is returned. If this method is called without C<< root >> access, it returns C<< 1 >> without doing anything. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 check_db_exists (optional, default 0)

If set, the database will be checked to see if the schema exists. This is normally not needed, but can be triggered if the database was DROP'ed by a user.

=cut
sub configure_pgsql
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->configure_pgsql()" }});

	my $check_db_exists = defined $parameter->{check_db_exists} ? $parameter->{check_db_exists} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		check_db_exists => $check_db_exists, 
	}});
	
	# The local host_uuid is the ID of the local database, so get that.
	my $uuid = $anvil->Get->host_uuid();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
	# If we're not running with root access, return.
	if (($< != 0) && ($> != 0))
	{
		# This is a minor error as it will be hit by every unpriviledged program that connects to the
		# database(s).
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "warning_0191", priority => "alert", variables => { 
			real_uid      => $<,
			effective_uid => $>,
		}});
		return(1);
	}

	# Make sure we have an entry in our own anvil.conf.
	my $local_uuid = $anvil->Database->get_local_uuid();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});

	# If we didn't get the $local_uuid, then there is no entry for this system in anvil.conf yet, so we'll add it.
	if (not $local_uuid)
	{
		$local_uuid = $anvil->Database->_add_to_local_config({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
		
		if ($local_uuid eq "!!error!!")
		{
			# Already logged the error, return.
			return('!!error!!');
		}
	}
	
	# First, is it running and is it initialized?
	my $initialized = 0;
	my $running     = $anvil->System->check_daemon({debug => $debug, daemon => $anvil->data->{sys}{daemon}{postgresql}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
	if (not -e $anvil->data->{path}{configs}{'pg_hba.conf'})
	{
		# Initialize. Record that we did so, so that we know to start the daemon.
		my ($output, $return_code) = $anvil->System->call({debug => 1, shell_call => $anvil->data->{path}{exe}{'postgresql-setup'}." --initdb --unit postgresql", source => $THIS_FILE, line => __LINE__});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { output => $output, return_code => $return_code }});
		
		# Did it succeed?
		if (not -e $anvil->data->{path}{configs}{'pg_hba.conf'})
		{
			# Failed... 
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0050"});
			return("!!error!!");
		}
		else
		{
			# Initialized!
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0055"});
			
			$initialized = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { initialized => $initialized }});
			
			### NOTE: We no longer enable postgres on boot. When the first call is made to 
			###       Database->connect on a striker, and no databases are available, it will 
			###       start up the local daemon then.
		}
	}
	
	# Setup postgresql.conf, if needed
	my $postgresql_conf        = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{configs}{'postgresql.conf'}});
	my $update_postgresql_file = 1;
	my $new_postgresql_conf    = "";
	foreach my $line (split/\n/, $postgresql_conf)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^listen_addresses = '\*'/)
		{
			# No need to update.
			$update_postgresql_file = 0;
			last;
		}
		elsif ($line =~ /^#listen_addresses = 'localhost'/)
		{
			# Inject the new listen_addresses
			$new_postgresql_conf .= "# This has been changed by Anvil::Tools::Database->configure_pgsql() to enable\n";
			$new_postgresql_conf .= "# listening on all interfaces.\n";
			$new_postgresql_conf .= "#listen_addresses = 'localhost'\n";
			$new_postgresql_conf .= "listen_addresses = '*'\n";
		}
		$new_postgresql_conf .= $line."\n";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_postgresql_file => $update_postgresql_file }});
	if ($update_postgresql_file)
	{
		# Back up the existing one, if needed.
		my $postgresql_backup = $anvil->data->{path}{directories}{backups}."/pgsql/postgresql.conf";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { postgresql_backup => $postgresql_backup }});
		if (not -e $postgresql_backup)
		{
			$anvil->Storage->copy_file({
				debug       => $debug, 
				source_file => $anvil->data->{path}{configs}{'postgresql.conf'}, 
				target_file => $postgresql_backup,
			});
		}
		
		# Write the updated one.
		$anvil->Storage->write_file({
			debug     => $debug, 
			file      => $anvil->data->{path}{configs}{'postgresql.conf'}, 
			body      => $new_postgresql_conf,
			user      => "postgres", 
			group     => "postgres",
			mode      => "0600",
			overwrite => 1,
		});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0056", variables => { file => $anvil->data->{path}{configs}{'postgresql.conf'} }});
	}
	
	# Setup pg_hba.conf now, if needed.
	my $pg_hba_conf        = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{configs}{'pg_hba.conf'}});
	my $update_pg_hba_file = 1;
	my $new_pg_hba_conf    = "";
	foreach my $line (split/\n/, $pg_hba_conf)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^host\s+all\s+all\s+all\s+md5$/)
		{
			# No need to update.
			$update_pg_hba_file = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_pg_hba_file => $update_pg_hba_file }});
			last;
		}
		elsif ($line =~ /^# TYPE\s+DATABASE/)
		{
			# Inject the new listen_addresses
			$new_pg_hba_conf .= $line."\n";
			$new_pg_hba_conf .= "host\tall\t\tall\t\tall\t\t\tmd5\n";
		}
		else
		{
			$new_pg_hba_conf .= $line."\n";
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_pg_hba_file => $update_pg_hba_file }});
	if ($update_pg_hba_file)
	{
		# Back up the existing one, if needed.
		my $pg_hba_backup = $anvil->data->{path}{directories}{backups}."/pgsql/pg_hba.conf";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { pg_hba_backup => $pg_hba_backup }});
		if (not -e $pg_hba_backup)
		{
			$anvil->Storage->copy_file({
				source_file => $anvil->data->{path}{configs}{'pg_hba.conf'}, 
				target_file => $pg_hba_backup,
			});
		}
		
		# Write the new one.
		$anvil->Storage->write_file({
			file      => $anvil->data->{path}{configs}{'pg_hba.conf'}, 
			body      => $new_pg_hba_conf,
			user      => "postgres", 
			group     => "postgres",
			mode      => "0600",
			overwrite => 1,
		});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0057", variables => { file => $anvil->data->{path}{configs}{'postgresql.conf'} }});
	}
	
	# Start or restart the daemon?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:running'                => $running,
		's2:update_postgresql_file' => $update_postgresql_file, 
		's3:update_pg_hba_file'     => $update_pg_hba_file, 
	}});
	if (not $running)
	{
		# Did we initialize?
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { initialized => $initialized }});
		if (($initialized) or (not $running))
		{
			# Start the daemon.
			my $return_code = $anvil->System->start_daemon({daemon => $anvil->data->{sys}{daemon}{postgresql}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
			if ($return_code eq "0")
			{
				# Started the daemon.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0059"});
			}
			else
			{
				# Failed to start
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0094"});
				return("!!error!!");
			}
		}
	}
	elsif (($update_postgresql_file) or ($update_pg_hba_file))
	{
		# Reload
		my $return_code = $anvil->System->start_daemon({daemon => $anvil->data->{sys}{daemon}{postgresql}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
		if ($return_code eq "0")
		{
			# Reloaded the daemon.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0112"});
		}
		else
		{
			# Failed to reload
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0111"});
		}
	}
	
	# Do user and DB checks only if we've made a change above.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:initialized'            => $initialized,
		's2:update_postgresql_file' => $update_postgresql_file, 
		's3:update_pg_hba_file'     => $update_pg_hba_file, 
	}});
	if (($initialized) or ($update_postgresql_file) or ($update_pg_hba_file) or ($check_db_exists))
	{
		# Create the .pgpass file, if needed.
		my $created_pgpass = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
			'path::secure::postgres_pgpass' => $anvil->data->{path}{secure}{postgres_pgpass},
			"database::${uuid}::password"   => $anvil->Log->is_secure($anvil->data->{database}{$uuid}{password}), 
		}});
		if ((not -e $anvil->data->{path}{secure}{postgres_pgpass}) && ($anvil->data->{database}{$uuid}{password}))
		{
			my $body = "*:*:*:postgres:".$anvil->data->{database}{$uuid}{password};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { body => $body }});
			$anvil->Storage->write_file({
				file      => $anvil->data->{path}{secure}{postgres_pgpass},  
				body      => $body,
				user      => "postgres", 
				group     => "postgres",
				mode      => "0600",
				overwrite => 1,
				secure    => 1,
			});
			if (-e $anvil->data->{path}{secure}{postgres_pgpass})
			{
				$created_pgpass = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { created_pgpass => $created_pgpass }});
			}
		}
		
		# Does the database user exist?
		my $create_user   = 1;
		my $database_user = $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : "admin";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_user => $database_user }});
		if (not $database_user)
		{
			# No database user defined
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0099", variables => { uuid => $uuid }});
			return("!!error!!");
		}
		my ($user_list, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT usename, usesysid FROM pg_catalog.pg_user;'\"", source => $THIS_FILE, line => __LINE__});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_list => $user_list, return_code => $return_code }});
		foreach my $line (split/\n/, $user_list)
		{
			if ($line =~ /^ $database_user\s+\|\s+(\d+)/)
			{
				# User exists already
				my $uuid = $1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0060", variables => { user => $database_user, uuid => $uuid }});
				$create_user = 0;
				last;
			}
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_user => $create_user }});
		if ($create_user)
		{
			# Create the user
			my ($create_output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{createuser}." --no-superuser --createdb --no-createrole $database_user\"", source => $THIS_FILE, line => __LINE__});
			(my $user_list, $return_code)     = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT usename, usesysid FROM pg_catalog.pg_user;'\"", source => $THIS_FILE, line => __LINE__});
			my $user_exists   = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_output => $create_output, user_list => $user_list }});
			foreach my $line (split/\n/, $user_list)
			{
				if ($line =~ /^ $database_user\s+\|\s+(\d+)/)
				{
					# Success!
					my $uuid = $1;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0095", variables => { user => $database_user, uuid => $uuid }});
					$user_exists = 1;
					last;
				}
			}
			if (not $user_exists)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0096", variables => { user => $database_user }});
				return("!!error!!");
			}
			
			# Update/set the passwords.
			if ($anvil->data->{database}{$uuid}{password})
			{
				foreach my $user ("postgres", $database_user)
				{
					my ($update_output, $return_code) = $anvil->System->call({secure => 1, shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c \\\"ALTER ROLE $user WITH PASSWORD '".$anvil->data->{database}{$uuid}{password}."';\\\"\"", source => $THIS_FILE, line => __LINE__});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { update_output => $update_output, return_code => $return_code }});
					foreach my $line (split/\n/, $user_list)
					{
						if ($line =~ /ALTER ROLE/)
						{
							# Password set
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0100", variables => { user => $user }});
						}
					}
				}
			}
		}
		
		# Create the database, if needed.
		my $create_database = 1;
		my $database_name   = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "anvil";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_name => $database_name }});
		
		(my $database_list, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT datname FROM pg_catalog.pg_database;'\"", source => $THIS_FILE, line => __LINE__});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_list => $database_list, return_code => $return_code }});
		foreach my $line (split/\n/, $database_list)
		{
			if ($line =~ /^ $database_name$/)
			{
				# Database already exists.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0105", variables => { database => $database_name }});
				$create_database = 0;
				last;
			}
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_database => $create_database }});
		if ($create_database)
		{
			my ($create_output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{createdb}."  --owner $database_user $database_name\"", source => $THIS_FILE, line => __LINE__});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_output => $create_output, return_code => $return_code }});
			
			my $database_exists               = 0;
			(my $database_list, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT datname FROM pg_catalog.pg_database;'\"", source => $THIS_FILE, line => __LINE__});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_list => $database_list, return_code => $return_code }});
			foreach my $line (split/\n/, $database_list)
			{
				if ($line =~ /^ $database_name$/)
				{
					# Database created
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0110", variables => { database => $database_name }});
					$database_exists = 1;
					last;
				}
			}
			if (not $database_exists)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0109", variables => { database => $database_name }});
				return("!!error!!");
			}
		}
		
		# Remove the temporary password file.
		if (($created_pgpass) && (-e $anvil->data->{path}{secure}{postgres_pgpass}))
		{
			unlink $anvil->data->{path}{secure}{postgres_pgpass};
			if (-e $anvil->data->{path}{secure}{postgres_pgpass})
			{
				# Failed to unlink the file.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0107"});
			}
		}
	}
	
	# Make sure the psql TCP port is open.
	$anvil->Network->manage_firewall({debug => $debug});
	
	return(0);
}


=head2 connect_to_databases

This method tries to connect to all databases it knows of. To define databases for a machine to connect to, load a configuration file with the following parameters;

 database::1::host		=	an-striker01.alteeve.com
 database::1::port		=	5432
 database::1::password		=	Initial1
 database::1::ping		=	0.25
 
 database::2::host		=	an-striker02.alteeve.com
 database::2::port		=	5432
 database::2::password		=	Initial1
 database::2::ping		=	0.25

Please see the comments in /etc/anvil/anvil.conf for more information on how to use the above variables.
 
The C<< 1 >> and C<< 2 >> are the IDs of the given databases. They can be any number and do not need to be sequential, they just need to be unique. 

This module will return the number of databases that were successfully connected to. This makes it convenient to check and exit if no databases are available using a check like;

 my $database_count = $anvil->Database->connect({file => $THIS_FILE});
 if($database_count)
 {
 	# Connected to: [$database_count] database(s)!
 }
 else
 {
 	# No databases available, exiting.
 }

Parameters;

=head3 check_for_resync (optional, default 0)

If set to C<< 1 >>, and there are 2 or more databases available, a check will be make to see if the databases need to be resync'ed or not. This is also set if the command line switch C<< --resync-db >> is used.

B<< Note >>: For daemons like C<< anvil-daemon >> and C<< scancore >>, when a loop starts the current number of available databases is checked against the last number. If the new number is greater, a DB resync check is triggered.

This can be expensive so should not be used in cases where responsiveness is important. It should be used if differences in data could cause issues.

=head3 check_if_configured (optional, default '0')

If set to C<< 1 >>, and if this is a locally hosted database, a check will be made to see if the database is configured. If it isn't, it will be configured.

B<< Note >>: This is expensive, so should only be called periodically. This will do nothing if not called with C<< root >> access, or if the database is not local.

=head3 db_uuid (optional)

If set, the connection will be made only to the database server matching the UUID.

=head3 no_ping (optional, default '0')

If set to C<< 1 >>, no attempt to ping a target before connection will happen, even if C<< database::<uuid>::ping = 1 >> is set.

=head3 retry (optional, default '0')

This method will try to recall itself if this is a Striker and it found no available databases, and so became primary. If this is set, it won't try to become primary a second time.

=head3 sensitive (optional, default '0')

If set to C<< 1 >>, the caller is considered time sensitive and most checks are skipped. This is used when a call must respond as quickly as possible.

=head3 source (optional)

The C<< source >> parameter is used to check the special C<< updated >> table on all connected databases to see when that source (program name, usually) last updated a given database. If the date stamp is the same on all connected databases, nothing further happens. If one of the databases differ, however, a resync will be requested.

If not defined, the core database will be checked.

If this is not set, no attempt to resync the database will be made.

=head3 sql_file (optional)

This is the SQL schema file that will be used to initialize the database, if the C<< test_table >> isn't found in a given database that is connected to. By default, this is C<< path::sql::anvil.sql >> (C<< /usr/share/perl/AN/Tools.sql >> by default). 

=head3 tables (optional)

This is an optional array reference of of tables to specifically check when connecting to databases. Each entry is treated as a table name, and that table's most recent C<< modified_date >> time stamp will be read. If a column name in the table ends in C<< _host_uuid >>, then the check and resync will be restricted to entries in that column matching the current host's C<< sys::host_uuid >>. If the table does not have a corresponding table in the C<< history >> schema, then only the public table will be synced. 

Note; The array order is used to allow you to ensure tables with primary keys are synchronyzed before tables with foreign keys. As such, please be aware of the order the table hash references are put into the array reference.

Example use;

 $anvil->Database->connect({
	tables => ["upses", "ups_batteries"],
 });

If you want to specify a table that is not linked to a host, set the hash variable's value as an empty string.

 $anvil->Database->connect({
	tables => {
		servers => "",
	},
 });

=head3 test_table (optional)

Once connected to the database, a query is made to see if the database needs to be initialized. Usually this is C<< defaults::sql::test_table >> (C<< hosts>> by default). 

If you set this table manually, it will be checked and if the table doesn't exist on a connected database, the database will be initialized with the C<< sql_file >> parameter's file.

=cut
### TODO: Have anvil-daemon look up all IPs available for a database (SELECT ip_address_address, 
###       ip_address_subnet_mask FROM ip_addresses WHERE ip_address_host_uuid = '<host_uuid>' AND 
###       ip_address_note != 'DELETED';) and append any found IPs to the anvil.conf entry. Then, in the order
###       they're found in the anvil.conf, try to connect. This should speed up showing link state changes 
###       when mapping the network of a node or DR host as the client can fairly quickly cycle through 
###       networks to find and update the database). On connect, move the host/IP that worked to the front of
###       the list.
sub connect
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->connect()" }});
	
	my $check_if_configured = defined $parameter->{check_if_configured} ? $parameter->{check_if_configured} : 0;
	my $db_uuid             = defined $parameter->{db_uuid}             ? $parameter->{db_uuid}             : "";
	my $check_for_resync    = defined $parameter->{check_for_resync}    ? $parameter->{check_for_resync}    : 0;
	my $no_ping             = defined $parameter->{no_ping}             ? $parameter->{no_ping}             : 0;
	my $retry               = defined $parameter->{retry}               ? $parameter->{retry}               : 0;
	my $sensitive           = defined $parameter->{sensitive}           ? $parameter->{sensitive}           : 0;
	my $source              = defined $parameter->{source}              ? $parameter->{source}              : "core";
	my $sql_file            = defined $parameter->{sql_file}            ? $parameter->{sql_file}            : $anvil->data->{path}{sql}{'anvil.sql'};
	my $tables              = defined $parameter->{tables}              ? $parameter->{tables}              : "";
	my $test_table          = defined $parameter->{test_table}          ? $parameter->{test_table}          : $anvil->data->{sys}{database}{test_table};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		check_if_configured => $check_if_configured, 
		db_uuid             => $db_uuid,
		check_for_resync    => $check_for_resync, 
		no_ping             => $no_ping,
		retry               => $retry, 
		sensitive           => $sensitive, 
		source              => $source, 
		sql_file            => $sql_file, 
		tables              => $tables, 
		test_table          => $test_table, 
	}});
	
	# If I wasn't passed an array reference of tables, load them from file(s).
	if (not $tables)
	{
		$tables = $anvil->Database->get_tables_from_schema({debug => 3, schema_file => "all"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { tables => $tables }});
	}
	
	$anvil->data->{switches}{'resync-db'} = "" if not defined $anvil->data->{switches}{'resync-db'};
	if ($anvil->data->{switches}{'resync-db'})
	{
		$check_for_resync = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_for_resync => $check_for_resync }});
	}
	
	my $start_time = [gettimeofday];
	#print "Start time: [".$start_time->[0].".".$start_time->[1]."]\n";
	
	$anvil->data->{sys}{database}{timestamp} = "" if not defined $anvil->data->{sys}{database}{timestamp};
	
	# We need the host_uuid before we connect.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	if (not $anvil->data->{sys}{host_uuid})
	{
		$anvil->data->{sys}{host_uuid} = $anvil->Get->host_uuid({debug => 2});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	}
	
	# This will be set to '1' if either DB needs to be initialized or if the last_updated differs on any node.
	$anvil->data->{sys}{database}{resync_needed} = 0;
	
	# In case this is called when connections already exist, clear the identifiers.
	if (exists $anvil->data->{sys}{database}{identifier})
	{
		delete $anvil->data->{sys}{database}{identifier};
	}
	
	if ($sensitive)
	{
		$check_for_resync = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_for_resync => $check_for_resync }});
	}
	
	# If we're a Striker, see if we're configured.
	my $local_host_type = $anvil->Get->host_type({debug => $debug});
	my $local_host_uuid = $anvil->Get->host_uuid({debug => $debug});
	my $db_count        = keys %{$anvil->data->{database}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		local_host_type     => $local_host_type, 
		local_host_uuid     => $local_host_uuid, 
		check_if_configured => $check_if_configured,
		real_uid            => $<,
		effective_uid       => $>,
		db_count            => $db_count, 
	}});
	# If requested, and if running with root access, set it up (or update it) if needed. 
	# This method just returns if nothing is needed.
	if (($local_host_type eq "striker") && ($check_if_configured))
	{
		$anvil->Database->configure_pgsql({
			debug           => 2, 
			uuid            => $local_host_uuid,
			check_db_exists => $check_if_configured,
		});
	}
	
	# Now setup or however-many connections
	my $seen_connections       = [];
	my $failed_connections     = [];
	my $successful_connections = [];
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		# Periodically, autovivication causes and empty key to appear.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		next if ((not $uuid) or (not $anvil->Validate->uuid({uuid => $uuid})));
		
		# Have we been asked to connect to a specific DB? If so, and if this isn't the requested 
		# UUID, skip it.
		if (($db_uuid) && ($db_uuid ne $uuid))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0191", variables => { 
				db_uuid => $db_uuid, 
				uuid    => $uuid,
			}});
			next;
		}
		
		# Make sure values are set.
		$anvil->data->{database}{$uuid}{port}     = 5432    if not defined $anvil->data->{database}{$uuid}{port};
		$anvil->data->{database}{$uuid}{name}     = "anvil" if not         $anvil->data->{database}{$uuid}{name};
		$anvil->data->{database}{$uuid}{user}     = "admin" if not         $anvil->data->{database}{$uuid}{user};
		$anvil->data->{database}{$uuid}{password} = ""      if not defined $anvil->data->{database}{$uuid}{password}; 
		
		my $driver   = "DBI:Pg";
		my $host     = $anvil->data->{database}{$uuid}{host}; # This should fail if not set
		my $port     = $anvil->data->{database}{$uuid}{port};
		my $name     = $anvil->data->{database}{$uuid}{name};
		my $user     = $anvil->data->{database}{$uuid}{user};
		my $password = $anvil->data->{database}{$uuid}{password};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host     => $host,
			port     => $port,
			name     => $name,
			user     => $user, 
			password => $anvil->Log->is_secure($password), 
		}});
		
		my $is_local = $anvil->Network->is_local({debug => $debug, host => $host});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
		
		# If there's no password, skip.
		if (not $password)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0668", variables => { uuid => $uuid }});
			next;
		}
		
		# Some places will want to pull up the database user, so in case it isn't set (which is 
		# usual), set it as if we had read it from the config file using the default.
		if (not $anvil->data->{database}{$uuid}{name})
		{
			$anvil->data->{database}{$uuid}{name} = "anvil";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "database::${uuid}::name" => $anvil->data->{database}{$uuid}{name} }});
		}
		
		# If not set, we will always ping before connecting.
		if ((not exists $anvil->data->{database}{$uuid}{ping}) or (not defined $anvil->data->{database}{$uuid}{ping}))
		{
			$anvil->data->{database}{$uuid}{ping} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "database::${uuid}::ping" => $anvil->data->{database}{$uuid}{ping} }});
		}
		
		# Make sure the user didn't specify the same target twice.
		my $target_host = $host.":".$port;
		my $duplicate   = 0;
		foreach my $existing_host (sort {$a cmp $b} @{$seen_connections})
		{
			if ($existing_host eq $target_host)
			{
				# User is connecting to the same target twice.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0053", variables => { target => $target_host }});
				$duplicate = 1;
			}
		}
		if (not $duplicate)
		{
			push @{$seen_connections}, $target_host;
		}
		next if $duplicate;
		
		# Log what we're doing.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0054", variables => { 
			uuid     => $uuid,
			driver   => $driver,
			host     => $host,
			port     => $port,
			name     => $name,
			user     => $user,
			password => $anvil->Log->is_secure($password),
		}});
		
		### TODO: Can we do a telnet port ping with a short timeout instead of a shell ping call?
		# Assemble my connection string
		my $db_connect_string = $driver.":dbname=".$name.";host=".$host.";port=".$port;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			db_connect_string         => $db_connect_string, 
			"database::${uuid}::ping" => $anvil->data->{database}{$uuid}{ping},
		}});
		if ((not $no_ping) && ($anvil->data->{database}{$uuid}{ping}))
		{
			# Can I ping?
			my ($pinged, $average_time) = $anvil->Network->ping({
				debug   => $debug, 
				ping    => $host, 
				count   => 1,
				timeout => $anvil->data->{database}{$uuid}{ping},
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				pinged       => $pinged,
				average_time => $average_time, 
			}});
			
			#my $ping_time = tv_interval ($start_time, [gettimeofday]);
			#print "[".$ping_time."] - Pinged: [$host:$port:$name:$user]\n";
			
			if (not $pinged)
			{
				# Didn't ping and 'database::<uuid>::ping' not set. Record this 
				# in the failed connections array.
				my $debug_level = $anvil->data->{sys}{database}{failed_connection_log_level} ? $anvil->data->{sys}{database}{failed_connection_log_level} : 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug_level, priority => "alert", key => "log_0063", variables => { 
					host => $port ? $host.":".$port : $host,
					name => $name, 
					uuid => $uuid,
				}});
				push @{$failed_connections}, $uuid;
				next;
			}
		}
		
		# This stores data used by striker-db-status
		$anvil->data->{db_status}{$uuid}{access}  = 0;
		$anvil->data->{db_status}{$uuid}{active}  = 0;
		$anvil->data->{db_status}{$uuid}{details} = "";
		
		# Connect!
		my $dbh = "";
		### NOTE: The Database->write() method, when passed an array, will automatically disable 
		###       autocommit, do the bulk write, then commit when done.
		# We connect with fatal errors, autocommit and UTF8 enabled.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			db_connect_string => $db_connect_string, 
			user              => $user, 
			password          => $anvil->Log->is_secure($password),
		}});
		local $@;
		my $test = eval { $dbh = DBI->connect($db_connect_string, $user, $password, {
			RaiseError     => 1,
			AutoCommit     => 1,
			pg_enable_utf8 => 1
		}); };
		$test = "" if not defined $test;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:test' => $test,
			's2:$@'   => $@,
		}});
		if (not $test)
		{
			# Either the Striker hosting this is down, or it's not primary and stopped its 
			# database.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0064", variables => { 
				uuid => $uuid,
				host => $host,
				name => $name,
			}});
			
			$anvil->data->{db_status}{$uuid}{details} = "error=".$@;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"db_status::${uuid}::details" => $anvil->data->{db_status}{$uuid}{details},
			}});
			
			push @{$failed_connections}, $uuid;
			my $message_key = "log_0065";
			my $variables   = { dbi_error => $DBI::errstr };
			if (not defined $DBI::errstr)
			{
				# General error
				$variables = { dbi_error => $@ };
			}
			elsif ($DBI::errstr =~ /No route to host/)
			{
				$message_key = "log_0066";
				$variables   = { target => $host, port => $port };
			}
			elsif ($DBI::errstr =~ /no password supplied/)
			{
				$message_key = "log_0067";
				$variables   = { uuid => $uuid };
			}
			elsif ($DBI::errstr =~ /password authentication failed for user/)
			{
				$message_key = "log_0068";
				$variables   = { 
					uuid => $uuid,
					name => $name,
					host => $host,
					user => $user,
				};
			}
			elsif ($DBI::errstr =~ /Connection refused/)
			{
				$message_key = "log_0069";
				$variables   = { 
					name => $name,
					host => $host,
					port => $port,
				};
			}
			elsif ($DBI::errstr =~ /Temporary failure in name resolution/i)
			{
				$message_key = "log_0070";
				$variables   = { 
					name => $name,
					host => $host,
					port => $port,
				};
			}
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => $message_key, variables => $variables });
			
			next;
		}
		elsif ($dbh =~ /^DBI::db=HASH/)
		{
			# Woot!
			$anvil->data->{cache}{database_handle}{$uuid} = $dbh;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				dbh                               => $dbh,
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid},
			}});
			
			$anvil->data->{db_status}{$uuid}{access} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"db_status::${uuid}::access" => $anvil->data->{db_status}{$uuid}{access},
			}});
			
			# Record this as successful
			$anvil->data->{sys}{database}{connections}++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::connections" => $anvil->data->{sys}{database}{connections},
			}});
			push @{$successful_connections}, $uuid;
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0071", variables => { 
				host => $host,
				port => $port,
				name => $name,
				uuid => $uuid,
			}});

			# Only the first database to connect will be "Active". This is the database used for
			# reads and the DB that will deal with resyncs
			if (not $anvil->data->{sys}{database}{primary_db})
			{
				$anvil->data->{sys}{database}{primary_db} = $uuid;
				$anvil->data->{sys}{database}{read_uuid}  = $uuid;
				$anvil->Database->read({set => $dbh});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
					"sys::database::primary_db" => $anvil->data->{sys}{database}{primary_db},
					"sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid},
					'anvil->Database->read'    => $anvil->Database->read,
				}});
			}

			# Read the DB identifier and then check that we've not already connected to this DB.
			my $query      = "SELECT system_identifier FROM pg_control_system();";
			my $identifier = $anvil->Database->query({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				query      => $query,
				identifier => $identifier,
			}});
			if (not exists $anvil->data->{sys}{database}{identifier}{$identifier})
			{
				$anvil->data->{sys}{database}{identifier}{$identifier} = $db_connect_string;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::identifier::${identifier}" => $anvil->data->{sys}{database}{identifier}{$identifier} }});
			}
			else
			{
				# Fail out.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0477", variables => { 
					db1   => $anvil->data->{sys}{database}{identifier}{$identifier}, 
					db2   => $db_connect_string, 
					query => $query,
				}});
				
				$anvil->data->{sys}{database}{connections}--;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::connections" => $anvil->data->{sys}{database}{connections},
				}});
				$anvil->nice_exit({exit_code => 1});
			}
			
			# Check to see if the schema needs to be loaded.
			if ($test_table ne $anvil->data->{sys}{database}{test_table})
			{
				my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->Database->quote($anvil->data->{defaults}{sql}{test_table})." AND schemaname='public';";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				my $count = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
				
				if ($count < 1)
				{
					### TODO: Create a version file/flag and don't sync with peers unless
					###       they are the same version. Back-port this to v2.
					# Need to load the database.
					$anvil->Database->initialize({debug => $debug, uuid => $uuid, sql_file => $anvil->data->{path}{sql}{'anvil.sql'}});
				}
			}
			
			# Now that I have connected, see if the 'test_table' exists.
			$query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->Database->quote($test_table)." AND schemaname='public';";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $count = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
			if ($count < 1)
			{
				# Need to load the database.
				$anvil->Database->initialize({debug => $debug, uuid => $uuid, sql_file => $sql_file});
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
			}});
			
			# Before I continue, see if this database is inactive.
			my ($active_value, undef, undef) = $anvil->Database->read_variable({
				debug         => $debug,
				uuid          => $uuid,
				variable_name => "database::".$uuid."::active",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_value  => $active_value }});
			if ($active_value eq "0")
			{
				# If we're "retry", we just started up.
				if (($retry) && ($is_local))
				{
					# Set the variable saying we're active.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0698"});
					my $variable_uuid = $anvil->Database->insert_or_update_variables({
						uuid                  => $uuid, 
						variable_name         => "database::".$uuid."::active",
						variable_value        => "1",
						variable_default      => "0", 
						variable_description  => "striker_0294", 
						variable_section      => "database", 
						variable_source_uuid  => "NULL", 
						variable_source_table => "", 
					});
					
					$anvil->data->{db_status}{$uuid}{active} = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"db_status::${uuid}::active" => $anvil->data->{db_status}{$uuid}{active},
					}});
				}
				else
				{
					# Don't use this database.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0699", variables => { host => $uuid }});
					$anvil->data->{cache}{database_handle}{$uuid}->disconnect;
					delete $anvil->data->{cache}{database_handle}{$uuid};
					
					if ($anvil->data->{sys}{database}{read_uuid} eq $uuid)
					{
						$anvil->data->{sys}{database}{read_uuid} = "";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid},
						}});
					}
					if ($anvil->data->{sys}{database}{primary_db} eq $uuid)
					{
						$anvil->data->{sys}{database}{primary_db} = "";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"sys::database::primary_db" => $anvil->data->{sys}{database}{primary_db},
						}});
					}
					next;
				}
			}
			
			# Still here? We're active
			$anvil->data->{db_status}{$uuid}{active} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"db_status::${uuid}::active" => $anvil->data->{db_status}{$uuid}{active},
			}});

			# Get a time stamp for this run, if not yet gotten.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
				"sys::database::timestamp"        => $anvil->data->{sys}{database}{timestamp},
			}});
			
			# Pick a timestamp for this run, if we haven't yet.
			if (not $anvil->data->{sys}{database}{timestamp})
			{
				$anvil->Database->refresh_timestamp({debug => $debug});
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::timestamp" => $anvil->data->{sys}{database}{timestamp},
			}});
		}
		
		# Before we try to connect, see if this is a local database and, if so, make sure it's setup.
		if ($is_local)
		{
			# If we're a striker, set the variable saying we're active if we need to.
			my ($active_value, undef, undef) = $anvil->Database->read_variable({
				debug         => $debug,
				uuid          => $uuid,
				variable_name => "database::".$uuid."::active",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_value  => $active_value }});
			if (not $active_value)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0698"});
				my $variable_uuid = $anvil->Database->insert_or_update_variables({
					variable_name         => "database::".$uuid."::active",
					variable_value        => "1",
					variable_default      => "0", 
					variable_description  => "striker_0294", 
					variable_section      => "database", 
					variable_source_uuid  => "NULL", 
					variable_source_table => "", 
				});
			}
		}
		# If this isn't a local database, read the target's Anvil! version (if available) and make 
		# sure it matches ours. If it doesn't, skip this database.
		else
		{
			my ($local_anvil_version, $local_schema_version)   = $anvil->_anvil_version({debug => $debug});
			my ($remote_anvil_version, $remote_schema_version) = $anvil->Get->anvil_version({
				debug    => $debug, 
				target   => $host,
				password => $password,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:host'                  => $host, 
				's2:local_anvil_version'   => $local_anvil_version, 
				's3:remote_anvil_version'  => $remote_anvil_version,
				's4:local_schema_version'  => $local_schema_version, 
				's5:remote_schema_version' => $remote_schema_version, 
			}});
			# TODO: Periodically, we fail to get the remote version. For now, we proceed if 
			#       everything else is OK. Might be better to pause a re-try... To be determined.
			if (($remote_schema_version) && ($remote_schema_version ne $local_schema_version))
			{
				# Version doesn't match, 
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0145", variables => { 
					host           => $host,
					local_version  => $local_schema_version, 
					target_version => $remote_schema_version,
				}});
				
				# Delete the information about this database. We'll try again on next
				# ->connect().
				$anvil->data->{sys}{database}{primary_db} = "" if $anvil->data->{sys}{database}{read_active} eq $uuid;
				$anvil->data->{sys}{database}{read_uuid}  = "" if $anvil->data->{sys}{database}{read_uuid}   eq $uuid;
				$anvil->data->{sys}{database}{connections}--;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::connections" => $anvil->data->{sys}{database}{connections},
				}});
				delete $anvil->data->{database}{$uuid};
				next;
			}
		}
	}
	
	# If we're a striker, no connections were found, and we have peers, start our database.
	my $configured_databases = keys %{$anvil->data->{database}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		local_host_type              => $local_host_type,
		"sys::database::connections" => $anvil->data->{sys}{database}{connections},
		configured_databases         => $configured_databases,
	}});
	if (($local_host_type eq "striker") && (not $anvil->data->{sys}{database}{connections}) && ($configured_databases > 2))
	{
		# Tell the user we're going to try to load and start.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0650"});
		
		# Look for pgdumps. "Youngest" is the one with the highest mtime.
		my $use_dump      = "";
		my $backup_age    = 0;
		my $youngest_dump = 0;
		my $directory     = $anvil->data->{path}{directories}{pgsql};
		my $db_name       = "anvil";
		my $dump_files    = [];
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { directory => $directory }});
		local(*DIRECTORY);
		opendir(DIRECTORY, $directory);
		while(my $file = readdir(DIRECTORY))
		{
			next if $file eq ".";
			next if $file eq "..";
			my $db_dump_uuid =  "";
			my $full_path    =  $directory."/".$file;
			   $full_path    =~ s/\/\//\//g;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				file      => $file,
				full_path => $full_path,
			}});
			if ($file =~ /\Q$db_name\E_db_dump\.(.*).sql/)
			{
				$db_dump_uuid = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { directory => $directory }});
				
				# Is this one of our own dumps?
				if ($db_dump_uuid eq $local_host_uuid)
				{
					# How recent is it? 
					$anvil->Storage->get_file_stats({debug => $debug, file_path => $full_path});
					my $mtime = $anvil->data->{file_stat}{$full_path}{modified_time};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { mtime => $mtime }});
					
					if ($mtime > $backup_age)
					{
						$backup_age = $mtime;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { backup_age => $backup_age }});
					}
					
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0653", variables => { full_path => $full_path }});
					next;
				}
				
				# Record this dump file for later purging.
				push @{$dump_files}, $full_path;
				
				# Is this a database we're configured to use?
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0651", variables => { full_path => $full_path }});
				if ((not exists $anvil->data->{database}{$db_dump_uuid}) or (not $anvil->data->{database}{$db_dump_uuid}{host}))
				{
					# Not a database we're peered with anymore, ignore it.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0652", variables => { 
						full_path => $full_path,
						host_uuid => $db_dump_uuid,
					}});
					next;
				}
				
				# Still here? This is a candidate for loading. What's the mtime on this file?
				$anvil->Storage->get_file_stats({debug => $debug, file_path => $full_path});
				my $mtime = $anvil->data->{file_stat}{$full_path}{modified_time};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { directory => $directory }});
				
				if ($mtime > $youngest_dump)
				{
					# This is the youngest, so far.
					$youngest_dump = $mtime;
					$use_dump      = $full_path;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
						youngest_dump => $youngest_dump,
						full_path     => $full_path, 
					}});
				}
			}
			else
			{
				# Not a dump file, ignore it.
				next;
			}
		}
		closedir(DIRECTORY);
		
		# Did I find a dump to load that's newer than my most recent backup?
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { use_dump => $use_dump }});
		if ($use_dump)
		{
			# Is one of our dumps newer? If so, don't load.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				youngest_dump => $youngest_dump,
				backup_age    => $backup_age, 
			}});
			if ($backup_age > $youngest_dump)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0661"});
			}
			else
			{
				# Yup! This will start the database, if needed.
				my $file_size       = $anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{file_stat}{$use_dump}{size}});
				my $file_size_bytes = $anvil->Convert->add_commas({number => $anvil->data->{file_stat}{$use_dump}{size}});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0656", variables => {
					file       => $use_dump, 
					size       => $file_size, 
					size_bytes => $file_size_bytes, 
				}});
				
				my $problem = $anvil->Database->load_database({
					debug     => 2, 
					backup    => 0,
					load_file => $use_dump,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { problem => $problem }});
				if ($problem)
				{
					# Failed, delete the file we tried to load. 
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0355", variables => { file => $use_dump }});
					unlink $use_dump;
				}
				else
				{
					# Success! Delete all backups we found from other hosts so we don't
					# reload them in the future.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0657"});
					foreach my $full_path (@{$dump_files})
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0589", variables => { file => $full_path }});
						unlink $full_path;
					}
				}
			}
		}
		
		# Check if the dameon is running
		my $running = $anvil->System->check_daemon({daemon => $anvil->data->{sys}{daemon}{postgresql}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
		if (not $running)
		{
			my $return_code = $anvil->System->start_daemon({daemon => $anvil->data->{sys}{daemon}{postgresql}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
			if ($return_code eq "0")
			{
				# Started the daemon.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0059"});
			}
		}
		
		# Reconnect
		if (not $retry)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0662"});
			$anvil->Database->connect({debug => $debug, retry => 1});
		}
	}
	
	# Do I have any connections? Don't die, if not, just return.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
	if (not $anvil->data->{sys}{database}{connections})
	{
		# Failed to connect to any database. Log this, print to the caller and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0091"});
		return($anvil->data->{sys}{database}{connections});
	}
	
	# Report any failed DB connections
	foreach my $uuid (@{$failed_connections})
	{
		my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "#!string!log_0185!#";
		my $database_user = defined $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : "#!string!log_0185!#";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"database::${uuid}::host"     => $anvil->data->{database}{$uuid}{host},
			"database::${uuid}::port"     => $anvil->data->{database}{$uuid}{port},
			"database::${uuid}::name"     => $database_name,
			"database::${uuid}::user"     => $database_user, 
			"database::${uuid}::password" => $anvil->Log->is_secure($anvil->data->{database}{$uuid}{password}), 
		}});
		
		# Delete this DB so that we don't try to use it later. This is a quiet alert because the 
		# original connection error was likely logged.
		my $say_server = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0092", variables => { server => $say_server, uuid => $uuid }});
		
		# If I've not sent an alert about this DB loss before, send one now.
# 		my $set = $anvil->Alert->check_alert_sent({
# 			debug          => $debug, 
# 			set_by         => $THIS_FILE,
# 			record_locator => $uuid,
# 			name           => "connect_to_db",
# 			modified_date  => $anvil->Database->refresh_timestamp,
# 		});
# 		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
# 		
# 		if ($set)
# 		{
# 			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error_array => $error_array }});
# 			foreach my $hash (@{$error_array})
# 			{
# 				my $message = $hash->{message_key};
# 				my $variable_count = keys 
# 				my $message_key       = $hash->{message_key};
# 				my $message_variables = $hash->{message_variables};
# 				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 					hash              => $hash, 
# 					message_key       => $message_key, 
# 					message_variables => $message_variables, 
# 				}});
# 				
# 				# These are warning level alerts.
# 				$anvil->Alert->register({
# 					debug       => $debug, 
# 					alert_level => "warning", 
# 					set_by      => $THIS_FILE,
# 					message     => $message,
# 				});
# 			}
# 		}
	}
	
	# Send an 'all clear' message if a now-connected DB previously wasn't.
	foreach my $uuid (@{$successful_connections})
	{
		my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "#!string!log_0185!#";
		my $database_user = defined $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : "#!string!log_0185!#";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"database::${uuid}::host"     => $anvil->data->{database}{$uuid}{host},
			"database::${uuid}::port"     => $anvil->data->{database}{$uuid}{port},
			"database::${uuid}::name"     => $database_name,
			"database::${uuid}::user"     => $database_user, 
			"database::${uuid}::password" => $anvil->Log->is_secure($anvil->data->{database}{$uuid}{password}), 
		}});
	}
	
	# Make sure my host UUID is valid
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	if ($anvil->data->{sys}{host_uuid} !~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/)
	{
		# derp. bad UUID
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0103", variables => { host_uuid => $anvil->data->{sys}{host_uuid} }});
		
		# Disconnect and set the connection count to '0'.
		$anvil->Database->disconnect({debug => $debug});
	}
	
	if (($anvil->data->{sys}{database}{connections}) && ($local_host_type eq "striker"))
	{
		# More sure any configured databases are in the hosts file.
		$anvil->Database->check_hosts({debug => $debug});
	}
	
	# If this is a time sensitive call, end here.
	if ($sensitive)
	{
		# Return here.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::connections" => $anvil->data->{sys}{database}{connections}, 
		}});
		return($anvil->data->{sys}{database}{connections});
	}
	
	# If 'check_for_resync' is set to '2', and the uptime is over two hours, only check if we're primary.
	my $uptime = $anvil->Get->uptime();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		"sys::database::primary_db" => $anvil->data->{sys}{database}{primary_db},
		"sys::host_uuid"            => $anvil->data->{sys}{host_uuid},
		check_for_resync            => $check_for_resync, 
		uptime                      => $uptime,
	}});
	if ($check_for_resync == 2)
	{
		if (($uptime < 7200) or ($anvil->data->{sys}{database}{primary_db} eq $anvil->data->{sys}{host_uuid}))
		{
			# We're primary or the uptime is low.
			$check_for_resync = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_for_resync => $check_for_resync }});
		}
		else
		{
			# We're not primary
			$check_for_resync = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_for_resync => $check_for_resync }});
		}
	}
	
	# Check for behind databases only if there are 2+ DBs, we're the active DB, and we're set to do so.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		"sys::database::connections" => $anvil->data->{sys}{database}{connections},
		check_for_resync             => $check_for_resync, 
	}});
	if (($anvil->data->{sys}{database}{connections} > 1) && ($check_for_resync))
	{
		$anvil->Database->_find_behind_databases({
			debug  => $debug, 
			source => $source, 
			tables => $tables,
		});
	}
	
	$anvil->data->{sys}{database}{last_db_count} = $anvil->data->{sys}{database}{connections};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::last_db_count" => $anvil->data->{sys}{database}{last_db_count} }});
	
	### TODO: Locking needs to be heavily reworked.
	# Hold if a lock has been requested.
	#$anvil->Database->locking({debug => $debug});
	
	# Mark that we're now active.
	#$anvil->Database->mark_active({debug => $debug, set => 1});
	
	# Sync the database, if needed.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::resync_needed" => $anvil->data->{sys}{database}{resync_needed},
		check_for_resync               => $check_for_resync, 
	}});
	if (($check_for_resync) && ($anvil->data->{sys}{database}{resync_needed}))
	{
		$anvil->Database->resync_databases({debug => $debug});
	}
	
	# Add ourselves to the database, if needed.
	$anvil->Database->insert_or_update_hosts({debug => $debug});
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
	return($anvil->data->{sys}{database}{connections});
}


=head2

This cleanly closes any open file handles to all connected databases and clears some internal database related variables.

Parameters;

=head3 cleanup (optional, default '1')

If set to C<< 1 >> (default), the disconnect will be cleaned up (marked inactive, clear locking, etc). If the DB handle was lost unexpectedly, this is not possible. Set this to C<< 0 >> to prevent this.

=cut
sub disconnect
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->disconnect()" }});
	
	my $cleanup = defined $parameter->{cleanup} ? $parameter->{cleanup} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		cleanup => $cleanup,
	}});
	
	my $marked_inactive = 0;
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		# Don't do anything if there isn't an active file handle for this DB.
		next if ((not $anvil->data->{cache}{database_handle}{$uuid}) or ($anvil->data->{cache}{database_handle}{$uuid} !~ /^DBI::db=HASH/));
		
		# Clear locks and mark that we're done running.
		if ((not $marked_inactive) && ($cleanup))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0857", variables => { uuid => $uuid }});
			#$anvil->Database->mark_active({debug => $debug, set => 0});
			#$anvil->Database->locking({debug => $debug, release => 1});
			$marked_inactive = 1;
		}
		
		if ($cleanup)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0858", variables => { uuid => $uuid }});
			$anvil->data->{cache}{database_handle}{$uuid}->disconnect;
		}
		delete $anvil->data->{cache}{database_handle}{$uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	}
	
	# Delete the stored DB-related values.
	delete $anvil->data->{sys}{database}{timestamp};
	delete $anvil->data->{sys}{database}{read_uuid};
	delete $anvil->data->{sys}{database}{identifier};
	$anvil->Database->read({debug => $debug, set => "delete"});
	
	# Delete any database information (reconnects should re-read anvil.conf anyway).
	delete $anvil->data->{database};
	
	# Set the connection count to 0.
	$anvil->data->{sys}{database}{connections} = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
	
	return(0);
}


=head2 find_host_uuid_columns

This looks through all ScanCore agent schemas, then all core tables and looks for tables with columns that end in C<< X_host_uuid >>. These are stored in an array, ordered such that you can delete records for a given host without deleting primary keys before all foreign keys are gone.

The array is stored in C<< sys::database::uuid_tables >>. Each array entry will be hash references with C<< table >> and C<< host_uuid_column >> keys containing the table name, and the C<< X_host_uuid >> column.

 ### NOTE: Don't sort the array! It's ordered for safe deletions.
 $anvil->Database->find_host_uuid_columns();
 foreach my $hash_ref (@{$anvil->data->{sys}{database}{uuid_tables}})
 {
 	my $table            = $hash_ref->{table};
 	my $host_uuid_column = $hash_ref->{host_uuid_column};
	print "Table: [".$table."], host UUID column: [".$host_uuid_column."]\n";
 }

The array reference is returned.

Parameters;

=head3 main_table (optional, default 'hosts')

This is the "parent" table, generally the top table with no further foreign keys above it.

=head3 search_column (optional, default 'host_uuid')

This is the UUID column used as a suffix in the parent table to search for.

=cut
sub find_host_uuid_columns
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->find_host_uuid_columns()" }});
	
	my $main_table    = defined $parameter->{main_table}    ? $parameter->{main_table}    : "hosts";
	my $search_column = defined $parameter->{search_column} ? $parameter->{search_column} : "host_uuid";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		main_table    => $main_table, 
		search_column => $search_column,
	}});
	
	$anvil->data->{sys}{database}{uuid_tables} = [];
	
	$anvil->ScanCore->_scan_directory({
		debug     => $debug, 
		directory => $anvil->data->{path}{directories}{scan_agents},
	});
	foreach my $agent_name (sort {$a cmp $b} keys %{$anvil->data->{scancore}{agent}})
	{
		my $sql_path = $anvil->data->{scancore}{agent}{$agent_name}.".sql";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			agent_name => $agent_name, 
			sql_path   => $sql_path,
		}});
		if (not -e $sql_path)
		{
			next;
		}
		my $tables = $anvil->Database->get_tables_from_schema({
			debug       => $debug, 
			schema_file => $sql_path,
		});
		foreach my $table (reverse @{$tables})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
			$anvil->Database->_find_column({
				debug         => $debug, 
				table         => $table,
				search_column => $search_column,
			});
		}
	}

	my $tables = $anvil->Database->get_tables_from_schema({debug => $debug, schema_file => $anvil->data->{path}{sql}{'anvil.sql'}});
	foreach my $table (reverse @{$tables})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
		$anvil->Database->_find_column({
			debug         => $debug, 
			table         => $table,
			search_column => $search_column,
		});
	}
	
	# Manually push 'hosts'
	push @{$anvil->data->{sys}{database}{uuid_tables}}, {
		table            => $main_table, 
		host_uuid_column => $search_column,
	};

	return($anvil->data->{sys}{database}{uuid_tables});
}


=head2 get_anvil_uuid_from_string

This takes a string and uses it to look for an Anvil! node. This string can being either a UUID or the name of the Anvil!. The matched C<< anvil_uuid >> is returned, if found. If no match is found, and empty string is returned.

This is meant to handle '--anvil' switches.

Parameters;

=head3 string

This is the string to search for.

=cut
sub get_anvil_uuid_from_string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_anvil_uuid_from_string()" }});

	my $string = defined $parameter->{string} ? $parameter->{string} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		string => $string,
	}});

	# Nothing to do unless we were called with a string.
	if (not $string)
	{
		return("");
	}

	$anvil->Database->get_anvils({debug => $debug});
	foreach my $anvil_name (sort {$a cmp $b} keys %{$anvil->data->{anvils}{anvil_name}})
	{
		my $anvil_uuid = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			anvil_name => $anvil_name,
			anvil_uuid => $anvil_uuid,
		}});

		if (($string eq $anvil_uuid) or
		    ($string eq $anvil_name))
		{
			return($anvil_uuid);
		}
	}

	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0466", variables => { string => $anvil }});
	return("");
}


=head2 get_alerts

This reads in alerts from the C<< alerts >> table.

Data is stored as:

 alerts::alert_uuid::<alert_uuid>::alert_host_uuid
 alerts::alert_uuid::<alert_uuid>::alert_set_by
 alerts::alert_uuid::<alert_uuid>::alert_level
 alerts::alert_uuid::<alert_uuid>::alert_title
 alerts::alert_uuid::<alert_uuid>::alert_message
 alerts::alert_uuid::<alert_uuid>::alert_sort_position
 alerts::alert_uuid::<alert_uuid>::alert_show_header
 alerts::alert_uuid::<alert_uuid>::alert_processed
 alerts::alert_uuid::<alert_uuid>::unix_modified_date
 alerts::alert_uuid::<alert_uuid>::modified_date

The C<< unix_modified_date >> is the unix timestamp to facilitate sorting by alert age.

Parameters;

=head3 include_processed (Optional, default 0)

By default, only unprocessed alerts are loaded. If this is set to C<< 1 >>, alerts that have already been processed will also be loaded.

=head3 all_hosts (Optional, default 0)

By default, only alerts registered on the load host are loaded. If this is set to C<< 1 >>, alerts from all hosts are loaded. 

=cut
sub get_alerts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_alerts()" }});
	
	my $all_hosts         = defined $parameter->{all_hosts}         ? $parameter->{all_hosts}         : 0;
	my $include_processed = defined $parameter->{include_processed} ? $parameter->{include_processed} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		all_hosts         => $all_hosts, 
		include_processed => $include_processed, 
	}});
	
	if (exists $anvil->data->{alerts})
	{
		delete $anvil->data->{alerts};
	}
	
	my $query = "
SELECT 
    alert_uuid, 
    alert_host_uuid, 
    alert_set_by, 
    alert_level, 
    alert_title, 
    alert_message, 
    alert_sort_position, 
    alert_show_header, 
    alert_processed, 
    round(extract(epoch from modified_date)) AS unix_modified_date, 
    modified_date 
FROM 
    alerts ";
	if ((not $include_processed) && (not $all_hosts))
	{
		$query .= "
WHERE 
    alert_processed = '0' 
AND 
    alert_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)." ";
	}
	elsif (not $include_processed)
	{
		$query .= "
WHERE 
    alert_processed = '0' ";
	}
	elsif (not $all_hosts)
	{
		$query .= "
WHERE 
    alert_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)." "
	}
	$query .= "
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
		my $alert_uuid          = $row->[0];
		my $alert_host_uuid     = $row->[1];
		my $alert_set_by        = $row->[2];
		my $alert_level         = $row->[3]; 
		my $alert_title         = $row->[4]; 
		my $alert_message       = $row->[5]; 
		my $alert_sort_position = $row->[6]; 
		my $alert_show_header   = $row->[7];
		my $alert_processed     = $row->[8];
		my $unix_modified_date  = $row->[9];
		my $modified_date       = $row->[10];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			alert_uuid          => $alert_uuid, 
			alert_host_uuid     => $alert_host_uuid, 
			alert_set_by        => $alert_set_by, 
			alert_level         => $anvil->Log->is_secure($alert_level), 
			alert_title         => $alert_title, 
			alert_message       => $alert_message, 
			alert_sort_position => $alert_sort_position, 
			alert_show_header   => $alert_show_header, 
			alert_processed     => $alert_processed, 
			unix_modified_date  => $unix_modified_date, 
			modified_date       => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_host_uuid}     = $alert_host_uuid;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_set_by}        = $alert_set_by;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_level}         = $alert_level;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_title}         = $alert_title;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_message}       = $alert_message;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_sort_position} = $alert_sort_position;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_show_header}   = $alert_show_header;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_processed}     = $alert_processed;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{unix_modified_date}  = $unix_modified_date;
		$anvil->data->{alerts}{alert_uuid}{$alert_uuid}{modified_date}       = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"alerts::alert_uuid::${alert_uuid}::alert_host_uuid"     => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_host_uuid}, 
			"alerts::alert_uuid::${alert_uuid}::alert_set_by"        => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_set_by}, 
			"alerts::alert_uuid::${alert_uuid}::alert_level"         => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_level}, 
			"alerts::alert_uuid::${alert_uuid}::alert_title"         => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_title}, 
			"alerts::alert_uuid::${alert_uuid}::alert_message"       => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_message}, 
			"alerts::alert_uuid::${alert_uuid}::alert_sort_position" => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_sort_position}, 
			"alerts::alert_uuid::${alert_uuid}::alert_show_header"   => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_show_header}, 
			"alerts::alert_uuid::${alert_uuid}::alert_processed"     => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{alert_processed}, 
			"alerts::alert_uuid::${alert_uuid}::unix_modified_date"  => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{unix_modified_date}, 
			"alerts::alert_uuid::${alert_uuid}::modified_date"       => $anvil->data->{alerts}{alert_uuid}{$alert_uuid}{modified_date}, 
		}});
	}

	return(0);
}


=head2 get_alert_overrides

By default, any machine generating an alert will go to recipients at their default level. Entries in this table allow for "overrides", either by Striker, or by Anvil! node / dr host set.

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted overrides are included when loading the data. When C<< 0 >> is set, the default, any manifest last_ran with C<< manifest_note >> set to C<< DELETED >> is ignored.

=cut
sub get_alert_overrides
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_alert_overrides()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	my $query = "
SELECT 
    alert_override_uuid, 
    alert_override_recipient_uuid, 
    alert_override_host_uuid, 
    alert_override_alert_level
FROM 
    alert_overrides
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
		my $alert_override_uuid           = $row->[0];
		my $alert_override_recipient_uuid = $row->[1];
		my $alert_override_host_uuid      = $row->[2];
		my $alert_override_alert_level    = $row->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			alert_override_uuid           => $alert_override_uuid, 
			alert_override_recipient_uuid => $alert_override_recipient_uuid, 
			alert_override_host_uuid      => $alert_override_host_uuid, 
			alert_override_alert_level    => $alert_override_alert_level,
		}});
		
		if (($alert_override_alert_level == -1) && (not $include_deleted))
		{
			next;
		}
		
		# Store the data
		$anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_recipient_uuid} = $alert_override_recipient_uuid;
		$anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_host_uuid}      = $alert_override_host_uuid;
		$anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_alert_level}    = $alert_override_alert_level;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"alert_overrides::alert_override_uuid::${alert_override_uuid}::alert_override_recipient_uuid" => $anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_recipient_uuid}, 
			"alert_overrides::alert_override_uuid::${alert_override_uuid}::alert_override_host_uuid"      => $anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_host_uuid}, 
			"alert_overrides::alert_override_uuid::${alert_override_uuid}::alert_override_alert_level"    => $anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_alert_level}, 
		}});
	}
	
	return(0);
}


=head2 get_anvils

This loads information about all known Anvil! systems as recorded in the C<< anvils >> table. 

Data is stored in two hashes, one sorted by C<< anvil_uuid >> and one by C<< anvil_name >>. While loading, any referenced nodes and DR hosts are stored for quick reference as well. Data is stored as:

 anvils::anvil_uuid::<anvil_uuid>::anvil_name
 anvils::anvil_uuid::<anvil_uuid>::anvil_description
 anvils::anvil_uuid::<anvil_uuid>::anvil_password
 anvils::anvil_uuid::<anvil_uuid>::anvil_node1_host_uuid
 anvils::anvil_uuid::<anvil_uuid>::anvil_node2_host_uuid
 anvils::anvil_uuid::<anvil_uuid>::modified_date

 anvils::anvil_name::<anvil_name>::anvil_uuid
 anvils::anvil_name::<anvil_name>::anvil_description
 anvils::anvil_name::<anvil_name>::anvil_password
 anvils::anvil_name::<anvil_name>::anvil_node1_host_uuid
 anvils::anvil_name::<anvil_name>::anvil_node2_host_uuid
 anvils::anvil_name::<anvil_name>::modified_date

When a host UUID is stored for either node or the DR host, it will be stored at:

 anvils::host_uuid::<host_uuid>::anvil_name

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted last_rans are included when loading the data. When C<< 0 >> is set, the default, any C<< anvil_description >> set to C<< DELETED >> are ignored.

=cut
sub get_anvils
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_anvils()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	if (exists $anvil->data->{anvils})
	{
		delete $anvil->data->{anvils};
	}
	
	# Get the list of files so we can track what's on each Anvil!.
	$anvil->Database->get_files({debug => $debug});
	$anvil->Database->get_file_locations({debug => $debug});

	my $query = "
SELECT 
    anvil_uuid, 
    anvil_name, 
    anvil_description, 
    anvil_password, 
    anvil_node1_host_uuid, 
    anvil_node2_host_uuid, 
    modified_date  
FROM 
    anvils ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    anvil_description != 'DELETED'";
	}
	$query .= "
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
		my $anvil_uuid            =         $row->[0];
		my $anvil_name            =         $row->[1];
		my $anvil_description     =         $row->[2];
		my $anvil_password        =         $row->[3]; 
		my $anvil_node1_host_uuid = defined $row->[4] ? $row->[4] : ""; 
		my $anvil_node2_host_uuid = defined $row->[5] ? $row->[5] : ""; 
		my $modified_date         =         $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_uuid            => $anvil_uuid, 
			anvil_name            => $anvil_name, 
			anvil_description     => $anvil_description, 
			anvil_password        => $anvil->Log->is_secure($anvil_password), 
			anvil_node1_host_uuid => $anvil_node1_host_uuid, 
			anvil_node2_host_uuid => $anvil_node2_host_uuid, 
			modified_date         => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name}            = $anvil_name;
		$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_description}     = $anvil_description;
		$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password}        = $anvil_password;
		$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid} = $anvil_node1_host_uuid;
		$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid} = $anvil_node2_host_uuid;
		$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{modified_date}         = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvils::anvil_uuid::${anvil_uuid}::anvil_name"            => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name}, 
			"anvils::anvil_uuid::${anvil_uuid}::anvil_description"     => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_description}, 
			"anvils::anvil_uuid::${anvil_uuid}::anvil_password"        => $anvil->Log->is_secure($anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password}), 
			"anvils::anvil_uuid::${anvil_uuid}::anvil_node1_host_uuid" => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid}, 
			"anvils::anvil_uuid::${anvil_uuid}::anvil_node2_host_uuid" => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid}, 
			"anvils::anvil_uuid::${anvil_uuid}::modified_date"         => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{modified_date}, 
		}});
		
		### NOTE: This is used in the 'get_anvils' CGI so we store the query time to allow the client
		###       side to know that the data is fresh.
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_uuid}            = $anvil_uuid;
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_description}     = $anvil_description;
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_password}        = $anvil_password;
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node1_host_uuid} = $anvil_node1_host_uuid;
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node2_host_uuid} = $anvil_node2_host_uuid;
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{modified_date}         = $modified_date;
		$anvil->data->{anvils}{anvil_name}{$anvil_name}{query_time}            = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvils::anvil_name::${anvil_name}::anvil_uuid"            => $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_uuid}, 
			"anvils::anvil_name::${anvil_name}::anvil_description"     => $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_description}, 
			"anvils::anvil_name::${anvil_name}::anvil_password"        => $anvil->Log->is_secure($anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_password}), 
			"anvils::anvil_name::${anvil_name}::anvil_node1_host_uuid" => $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node1_host_uuid}, 
			"anvils::anvil_name::${anvil_name}::anvil_node2_host_uuid" => $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node2_host_uuid}, 
			"anvils::anvil_name::${anvil_name}::modified_date"         => $anvil->data->{anvils}{anvil_name}{$anvil_name}{modified_date}, 
			"anvils::anvil_name::${anvil_name}::query_time"            => $anvil->data->{anvils}{anvil_name}{$anvil_name}{query_time}, 
		}});
		
		if ($anvil_node1_host_uuid)
		{
			$anvil->data->{anvils}{host_uuid}{$anvil_node1_host_uuid}{anvil_name} = $anvil_name;
			$anvil->data->{anvils}{host_uuid}{$anvil_node1_host_uuid}{anvil_uuid} = $anvil_uuid;
			$anvil->data->{anvils}{host_uuid}{$anvil_node1_host_uuid}{role}       = "node1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvils::host_uuid::${anvil_node1_host_uuid}::anvil_name" => $anvil->data->{anvils}{host_uuid}{$anvil_node1_host_uuid}{anvil_name}, 
				"anvils::host_uuid::${anvil_node1_host_uuid}::anvil_uuid" => $anvil->data->{anvils}{host_uuid}{$anvil_node1_host_uuid}{anvil_uuid}, 
				"anvils::host_uuid::${anvil_node1_host_uuid}::role"       => $anvil->data->{anvils}{host_uuid}{$anvil_node1_host_uuid}{role}, 
			}});
		}
		if ($anvil_node2_host_uuid)
		{
			$anvil->data->{anvils}{host_uuid}{$anvil_node2_host_uuid}{anvil_name} = $anvil_name;
			$anvil->data->{anvils}{host_uuid}{$anvil_node2_host_uuid}{anvil_uuid} = $anvil_uuid;
			$anvil->data->{anvils}{host_uuid}{$anvil_node2_host_uuid}{role}       = "node2";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvils::host_uuid::${anvil_node2_host_uuid}::anvil_name" => $anvil->data->{anvils}{host_uuid}{$anvil_node2_host_uuid}{anvil_name}, 
				"anvils::host_uuid::${anvil_node2_host_uuid}::anvil_uuid" => $anvil->data->{anvils}{host_uuid}{$anvil_node2_host_uuid}{anvil_uuid}, 
				"anvils::host_uuid::${anvil_node2_host_uuid}::role"       => $anvil->data->{anvils}{host_uuid}{$anvil_node2_host_uuid}{role}, 
			}});
		}
		
		# Process DR hosts this Anvil! is allowed to use.
		if (exists $anvil->data->{dr_links}{by_anvil_uuid}{$anvil_uuid})
		{
			foreach my $dr_link_host_uuid (sort {$a cmp $b} keys %{$anvil->data->{dr_links}{by_anvil_uuid}{$anvil_uuid}{dr_link_host_uuid}})
			{
				my $dr_link_uuid            = $anvil->data->{dr_links}{by_anvil_uuid}{$anvil_uuid}{dr_link_host_uuid}{$dr_link_host_uuid}{dr_link_uuid};
				my $dr_link_note            = $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note};
				my $dr_link_short_host_name = $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{short_host_name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:dr_link_host_uuid"       => $dr_link_host_uuid, 
					"s2:dr_link_uuid"            => $dr_link_uuid, 
					"s3:dr_link_note"            => $dr_link_note, 
					"s4:dr_link_short_host_name" => $dr_link_short_host_name, 
				}});
				
				next if $dr_link_note eq "DELETED";
				
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host}{$dr_link_host_uuid}{dr_link_uuid}    = $dr_link_uuid;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host}{$dr_link_host_uuid}{short_host_name} = $dr_link_short_host_name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:anvils::anvil_uuid::${anvil_uuid}::dr_host::${dr_link_host_uuid}::dr_link_uuid"    => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host}{$dr_link_host_uuid}{dr_link_uuid}, 
					"s2:anvils::anvil_uuid::${anvil_uuid}::dr_host::${dr_link_host_uuid}::short_host_name" => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host}{$dr_link_host_uuid}{short_host_name}, 
				}});
			}
		}
	}

	return(0);
}


=head2 get_bridges

This loads the known bridge devices into the C<< anvil::data >> hash at:

* bridges::bridge_host_uuid::<host_uuid>::bridge_uuid::<bridge_uuid>::bridge_name
* bridges::bridge_host_uuid::<host_uuid>::bridge_uuid::<bridge_uuid>::bridge_id
* bridges::bridge_host_uuid::<host_uuid>::bridge_uuid::<bridge_uuid>::bridge_mac_address
* bridges::bridge_host_uuid::<host_uuid>::bridge_uuid::<bridge_uuid>::bridge_mtu
* bridges::bridge_host_uuid::<host_uuid>::bridge_uuid::<bridge_uuid>::bridge_stp_enabled
* bridges::bridge_host_uuid::<host_uuid>::bridge_uuid::<bridge_uuid>::modified_date

And, to allow for lookup by name;

* bridges::bridge_host_uuid::<host_uuid>::bridge_name::<bridge_name>::bridge_uuid

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

B<<Note>>: Deleted bridges (ones where C<< bridge_id >> is set to C<< DELETED >>) are ignored. See the C<< include_deleted >> parameter to include them.

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted bridges are included when loading the data. When C<< 0 >> is set, the default, any bridges with C<< bridge_id >> set to C<< DELETED >> are ignored.

=cut
sub get_bridges
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_bridges()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	if (exists $anvil->data->{bridges})
	{
		delete $anvil->data->{bridges};
	}
	
	my $query = "
SELECT 
    bridge_uuid, 
    bridge_host_uuid, 
    bridge_name, 
    bridge_id, 
    bridge_mac_address, 
    bridge_mtu,  
    bridge_stp_enabled, 
    modified_date 
FROM 
    bridges ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    bridge_id != 'DELETED'";
	}
	$query .= "
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
		my $bridge_uuid        = $row->[0];
		my $bridge_host_uuid   = $row->[1];
		my $bridge_name        = $row->[2];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			bridge_uuid      => $bridge_uuid, 
			bridge_host_uuid => $bridge_host_uuid, 
			bridge_name      => $bridge_name, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_name}        = $bridge_name;
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_id}          = $row->[3];
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_mac_address} = $row->[4];
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_mtu}         = $row->[5];
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_stp_enabled} = $row->[6];
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{modified_date}      = $row->[7];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_uuid::${bridge_uuid}::bridge_name"        => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_name}, 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_uuid::${bridge_uuid}::bridge_id"          => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_id}, 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_uuid::${bridge_uuid}::bridge_mac_address" => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_mac_address}, 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_uuid::${bridge_uuid}::bridge_mtu"         => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_mtu}, 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_uuid::${bridge_uuid}::bridge_stp_enabled" => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{bridge_stp_enabled}, 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_uuid::${bridge_uuid}::modified_date"      => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_uuid}{$bridge_uuid}{modified_date}, 
		}});
		
		# Make it easier to look up by bridge name.
		$anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_name}{$bridge_name}{bridge_uuid} = $bridge_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"bridges::bridge_host_uuid::${bridge_host_uuid}::bridge_name::${bridge_name}::bridge_uuid" => $anvil->data->{bridges}{bridge_host_uuid}{$bridge_host_uuid}{bridge_name}{$bridge_name}{bridge_uuid}, 
		}});
	}

	return(0);
}


=head2 get_dr_links

This loads the known dr_link devices into the C<< anvil::data >> hash at:

* dr_links::dr_link_uuid::<dr_link_uuid>::dr_link_host_uuid
* dr_links::dr_link_uuid::<dr_link_uuid>::dr_link_anvil_uuid
* dr_links::dr_link_uuid::<dr_link_uuid>::dr_link_note
* dr_links::dr_link_uuid::<dr_link_uuid>::modified_date

To simplify finding links by host or Anvil! UUID, links to C<< dr_link_uuid >> are stored in these hashes;

* dr_links::by_anvil_uuid::<dr_link_anvil_uuid>::dr_link_host_uuid::<dr_link_host_uuid>::dr_link_uuid
* dr_links::by_host_uuid::<dr_link_host_uuid>::dr_link_anvil_uuid::<dr_link_anvil_uuid>::dr_link_uuid

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

B<<Note>>: Deleted links (ones where C<< dr_link_note >> is set to C<< DELETED >>) are ignored. See the C<< include_deleted >> parameter to include them.

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted links are included when loading the data. When C<< 0 >> is set, the default, any dr_link agent with C<< dr_link_note >> set to C<< DELETED >> is ignored.

=cut
sub get_dr_links
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_dr_links()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});

	# Hosts loads anvils.
	$anvil->Database->get_hosts({debug => $debug});

	my $query = "
SELECT 
    dr_link_uuid, 
    dr_link_host_uuid, 
    dr_link_anvil_uuid, 
    dr_link_note, 
    modified_date 
FROM 
    dr_links ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    dr_link_note != 'DELETED'";
	}
	$query .= "
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
		my $dr_link_uuid       =         $row->[0];
		my $dr_link_host_uuid  =         $row->[1];
		my $dr_link_anvil_uuid =         $row->[2];
		my $dr_link_note       = defined $row->[3] ? $row->[3] : ""; 
		my $modified_date      =         $row->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			dr_link_uuid       => $dr_link_uuid, 
			dr_link_host_uuid  => $dr_link_host_uuid, 
			dr_link_anvil_uuid => $dr_link_anvil_uuid, 
			dr_link_note       => $dr_link_note, 
			modified_date      => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_host_uuid}  = $dr_link_host_uuid;
		$anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_anvil_uuid} = $dr_link_anvil_uuid;
		$anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note}       = $dr_link_note;
		$anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{modified_date}      = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"dr_links::dr_link_uuid::${dr_link_uuid}::dr_link_host_uuid"  => $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_host_uuid}, 
			"dr_links::dr_link_uuid::${dr_link_uuid}::dr_link_anvil_uuid" => $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_anvil_uuid}, 
			"dr_links::dr_link_uuid::${dr_link_uuid}::dr_link_note"       => $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note}, 
			"dr_links::dr_link_uuid::${dr_link_uuid}::modified_date"      => $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{modified_date}, 
		}});
		
		my $dr_link_host_name  = $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{short_host_name};
		my $dr_link_anvil_name = $anvil->data->{anvils}{anvil_uuid}{$dr_link_anvil_uuid}{anvil_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			dr_link_host_name  => $dr_link_host_name,
			dr_link_anvil_name => $dr_link_anvil_name,
		}});

		$anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_host_uuid}{$dr_link_host_uuid}{dr_link_uuid} = $dr_link_uuid;
		$anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_host_name}{$dr_link_host_name}{dr_link_uuid} = $dr_link_uuid;
		$anvil->data->{dr_links}{by_host_uuid}{$dr_link_host_uuid}{dr_link_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_uuid} = $dr_link_uuid;
		$anvil->data->{dr_links}{by_host_uuid}{$dr_link_host_uuid}{dr_link_anvil_name}{$dr_link_anvil_name}{dr_link_uuid} = $dr_link_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			"s1:dr_links::by_anvil_uuid::${dr_link_anvil_uuid}::dr_link_host_uuid::${dr_link_host_uuid}::dr_link_uuid" => $anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_host_uuid}{$dr_link_host_uuid}{dr_link_uuid},
			"s2:dr_links::by_anvil_uuid::${dr_link_anvil_uuid}::dr_link_host_name::${dr_link_host_name}::dr_link_uuid" => $anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_host_name}{$dr_link_host_name}{dr_link_uuid},
			"s3:dr_links::by_host_uuid::${dr_link_host_uuid}::dr_link_anvil_uuid::${dr_link_anvil_uuid}::dr_link_uuid" => $anvil->data->{dr_links}{by_host_uuid}{$dr_link_host_uuid}{dr_link_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_uuid},
			"s4:dr_links::by_host_uuid::${dr_link_host_uuid}::dr_link_anvil_name::${dr_link_anvil_name}::dr_link_uuid" => $anvil->data->{dr_links}{by_host_uuid}{$dr_link_host_uuid}{dr_link_anvil_name}{$dr_link_anvil_name}{dr_link_uuid},
		}});
	}

	return(0);
}


=head2 get_drbd_data

This loads all of the LVM data into the following hashes;

* drbd::host_name::<short_host_name>::scan_drbd_uuid::<scan_drbd_uuid>::scan_drbd_common_xml
* drbd::host_name::<short_host_name>::scan_drbd_uuid::<scan_drbd_uuid>::scan_drbd_flush_disk
* drbd::host_name::<short_host_name>::scan_drbd_uuid::<scan_drbd_uuid>::scan_drbd_flush_md
* drbd::host_name::<short_host_name>::scan_drbd_uuid::<scan_drbd_uuid>::scan_drbd_timeout
* drbd::host_name::<short_host_name>::scan_drbd_uuid::<scan_drbd_uuid>::scan_drbd_total_sync_speed

* drbd::host_name::<short_host_name>::resource_name::<resource_name>::resource_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::up
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::xml

* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::volume_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::resource_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::device_path
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::device_minor
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::volume_size
* drbd::volume_uuid::<volume_uuid>::volume_number
* drbd::volume_uuid::<volume_uuid>::resource_name
* drbd::volume_uuid::<volume_uuid>::resource_uuid

* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::peer_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::peer_host_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::volume_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::resource_uuid
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::connection_state
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::local_disk_state
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::peer_disk_state
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::local_role
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::peer_role
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::out_of_sync_size
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::replication_speed
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::estimated_time_to_sync
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::peer_ip_address
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::peer_tcp_port
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::protocol
* drbd::host_name::<short_host_name>::resource_name::<resource_name>::volume::<volume_number>::peer_name::<peer_host_name>::fencing

For more information on what the data is that is stored in these hashes, please see C<< scan-drbd >>.

This method takes no parameters.

=cut
sub get_drbd_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_drbd_data()" }});
	
	if (not ref($anvil->data->{hosts}{host_uuid}) eq "HASH")
	{
		$anvil->Database->get_hosts({debug => $debug});
	}
	
	# This calls up the entry for this host. There will only be one.
	my $query = "
SELECT 
    scan_drbd_uuid, 
    scan_drbd_host_uuid, 
    scan_drbd_common_xml, 
    scan_drbd_flush_disk, 
    scan_drbd_flush_md, 
    scan_drbd_timeout, 
    scan_drbd_total_sync_speed 
FROM 
    scan_drbd 
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
		# We've got an entry in the 'scan_drbd' table, so now we'll look for data in the node and 
		# services tables.
		my $scan_drbd_uuid      = $row->[0]; 
		my $scan_drbd_host_uuid = $row->[1];
		my $short_host_name     = $anvil->data->{hosts}{host_uuid}{$scan_drbd_host_uuid}{short_host_name};
		
		# Store the old data now.
		$anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_common_xml}       = $row->[2];
		$anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_flush_disk}       = $row->[3];
		$anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_flush_md}         = $row->[4];
		$anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_timeout}          = $row->[5];
		$anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_total_sync_speed} = $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
			"drbd::host_name::${short_host_name}::scan_drbd_uuid::${scan_drbd_uuid}::scan_drbd_common_xml"       => $anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_common_xml},
			"drbd::host_name::${short_host_name}::scan_drbd_uuid::${scan_drbd_uuid}::scan_drbd_flush_disk"       => $anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_flush_disk},
			"drbd::host_name::${short_host_name}::scan_drbd_uuid::${scan_drbd_uuid}::scan_drbd_flush_md"         => $anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_flush_md},
			"drbd::host_name::${short_host_name}::scan_drbd_uuid::${scan_drbd_uuid}::scan_drbd_timeout"          => $anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_timeout},
			"drbd::host_name::${short_host_name}::scan_drbd_uuid::${scan_drbd_uuid}::scan_drbd_total_sync_speed" => $anvil->data->{drbd}{host_name}{$short_host_name}{scan_drbd_uuid}{$scan_drbd_uuid}{scan_drbd_total_sync_speed},
		}});
	}
	undef $count;
	undef $results;

	# Read in the RAM module data.
	$query = "
SELECT 
    scan_drbd_resource_uuid, 
    scan_drbd_resource_host_uuid, 
    scan_drbd_resource_name, 
    scan_drbd_resource_up, 
    scan_drbd_resource_xml
FROM 
    scan_drbd_resources 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		# We've got an entry in the 'scan_drbd_resources' table, so now we'll look for data in the node and 
		# services tables.
		my $resource_uuid                = $row->[0]; 
		my $scan_drbd_resource_host_uuid = $row->[1];
		my $scan_drbd_resource_name      = $row->[2]; 
		my $short_host_name              = $anvil->data->{hosts}{host_uuid}{$scan_drbd_resource_host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			resource_uuid                => $resource_uuid, 
			scan_drbd_resource_host_uuid => $scan_drbd_resource_host_uuid, 
			scan_drbd_resource_name      => $scan_drbd_resource_name,
			short_host_name              => $short_host_name, 
		}});
		
		# Store the old data now.
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$scan_drbd_resource_name}{resource_uuid} = $row->[0]; 
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$scan_drbd_resource_name}{up}            = $row->[3]; 
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$scan_drbd_resource_name}{xml}           = $row->[4]; 
		$anvil->data->{drbd}{resource_uuid}{$resource_uuid}{resource_name}                                        = $scan_drbd_resource_name; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:drbd::host_name::${short_host_name}::resource_name::${scan_drbd_resource_name}::resource_uuid" => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$scan_drbd_resource_name}{resource_uuid}, 
			"s2:drbd::host_name::${short_host_name}::resource_name::${scan_drbd_resource_name}::up"            => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$scan_drbd_resource_name}{up}, 
			"s3:drbd::host_name::${short_host_name}::resource_name::${scan_drbd_resource_name}::xml"           => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$scan_drbd_resource_name}{xml}, 
			"s4:drbd::resource_uuid::${resource_uuid}::resource_name"                                          => $anvil->data->{drbd}{resource_uuid}{$resource_uuid}{resource_name}, 
		}});
	}
	undef $count;
	undef $results;
	
	# Read in the RAM module data.
	$query = "
SELECT 
    scan_drbd_volume_uuid, 
    scan_drbd_volume_host_uuid, 
    scan_drbd_volume_scan_drbd_resource_uuid, 
    scan_drbd_volume_number, 
    scan_drbd_volume_device_path, 
    scan_drbd_volume_device_minor, 
    scan_drbd_volume_size
FROM 
    scan_drbd_volumes 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		# We've got an entry in the 'scan_drbd_volumes' table, so now we'll look for data in the node and 
		# services tables.
		my $scan_drbd_volume_uuid                    = $row->[0];
		my $scan_drbd_volume_host_uuid               = $row->[1]; 
		my $scan_drbd_volume_scan_drbd_resource_uuid = $row->[2]; 
		my $scan_drbd_volume_number                  = $row->[3];
		my $resource_name                            = $anvil->data->{drbd}{resource_uuid}{$scan_drbd_volume_scan_drbd_resource_uuid}{resource_name};
		my $short_host_name                          = $anvil->data->{hosts}{host_uuid}{$scan_drbd_volume_host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_drbd_volume_host_uuid               => $scan_drbd_volume_host_uuid, 
			scan_drbd_volume_scan_drbd_resource_uuid => $scan_drbd_volume_scan_drbd_resource_uuid,
			scan_drbd_volume_number                  => $scan_drbd_volume_number, 
			short_host_name                          => $short_host_name, 
		}});
		
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{volume_uuid}   = $row->[0]; 
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{resource_uuid} = $scan_drbd_volume_scan_drbd_resource_uuid; 
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{device_path}   = $row->[4];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{device_minor}  = $row->[5]; 
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{volume_size}   = $row->[6]; 
		$anvil->data->{drbd}{volume_uuid}{$scan_drbd_volume_uuid}{volume_number}                                                          = $scan_drbd_volume_number;
		$anvil->data->{drbd}{volume_uuid}{$scan_drbd_volume_uuid}{resource_name}                                                          = $resource_name;
		$anvil->data->{drbd}{volume_uuid}{$scan_drbd_volume_uuid}{resource_uuid}                                                          = $scan_drbd_volume_scan_drbd_resource_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${scan_drbd_volume_number}::volume_uuid"   => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{volume_uuid},
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${scan_drbd_volume_number}::resource_uuid" => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{resource_uuid},
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${scan_drbd_volume_number}::device_path"   => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{device_path},
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${scan_drbd_volume_number}::device_minor"  => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{device_minor},
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${scan_drbd_volume_number}::volume_size"   => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{volume_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$scan_drbd_volume_number}{volume_size}}).")",
			"drbd::volume_uuid::${scan_drbd_volume_uuid}::volume_number"                                                              => $anvil->data->{drbd}{volume_uuid}{$scan_drbd_volume_uuid}{volume_number}, 
			"drbd::volume_uuid::${scan_drbd_volume_uuid}::resource_name"                                                              => $anvil->data->{drbd}{volume_uuid}{$scan_drbd_volume_uuid}{resource_name}, 
			"drbd::volume_uuid::${scan_drbd_volume_uuid}::resource_uuid"                                                              => $anvil->data->{drbd}{volume_uuid}{$scan_drbd_volume_uuid}{resource_uuid}, 
		}});
	}
	undef $count;
	undef $results;
	
	# Read in the RAM module data.
	$query = "
SELECT 
    scan_drbd_peer_uuid, 
    scan_drbd_peer_host_uuid, 
    scan_drbd_peer_scan_drbd_volume_uuid, 
    scan_drbd_peer_host_name, 
    scan_drbd_peer_connection_state, 
    scan_drbd_peer_local_disk_state, 
    scan_drbd_peer_disk_state, 
    scan_drbd_peer_local_role, 
    scan_drbd_peer_role, 
    scan_drbd_peer_out_of_sync_size, 
    scan_drbd_peer_replication_speed, 
    scan_drbd_peer_estimated_time_to_sync, 
    scan_drbd_peer_ip_address, 
    scan_drbd_peer_tcp_port, 
    scan_drbd_peer_protocol, 
    scan_drbd_peer_fencing 
FROM 
    scan_drbd_peers 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		# We've got an entry in the 'scan_drbd_peers' table, so now we'll look for data in the node and 
		# services tables.
		my $scan_drbd_peer_host_uuid             = $row->[1];
		my $scan_drbd_peer_scan_drbd_volume_uuid = $row->[2]; 
		my $scan_drbd_peer_host_name             = $row->[3];
		my $short_host_name                      = $anvil->data->{hosts}{host_uuid}{$scan_drbd_peer_host_uuid}{short_host_name};
		my $resource_uuid                        = $anvil->data->{drbd}{volume_uuid}{$scan_drbd_peer_scan_drbd_volume_uuid}{resource_uuid};
		my $resource_name                        = $anvil->data->{drbd}{volume_uuid}{$scan_drbd_peer_scan_drbd_volume_uuid}{resource_name}; 
		my $volume_number                        = $anvil->data->{drbd}{volume_uuid}{$scan_drbd_peer_scan_drbd_volume_uuid}{volume_number};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_drbd_peer_host_uuid             => $scan_drbd_peer_host_uuid, 
			scan_drbd_peer_scan_drbd_volume_uuid => $scan_drbd_peer_scan_drbd_volume_uuid,
			scan_drbd_peer_host_name             => $scan_drbd_peer_host_name, 
			short_host_name                      => $short_host_name, 
			resource_uuid                        => $resource_uuid, 
			resource_name                        => $resource_name, 
			volume_number                        => $volume_number, 
		}});
		
		# Store
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_uuid}              = $row->[0];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_host_uuid}         = $anvil->Database->get_host_uuid_from_string({debug => $debug, string => $scan_drbd_peer_host_name});
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{volume_uuid}            = $scan_drbd_peer_scan_drbd_volume_uuid;
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{resource_uuid}          = $resource_uuid;
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{connection_state}       = $row->[4];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{local_disk_state}       = $row->[5];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_disk_state}        = $row->[6];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{local_role}             = $row->[7];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_role}              = $row->[8];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{out_of_sync_size}       = $row->[9];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{replication_speed}      = $row->[10];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{estimated_time_to_sync} = $row->[11];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_ip_address}        = $row->[12];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_tcp_port}          = $row->[13];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{protocol}               = $row->[14];
		$anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{fencing}                = $row->[15];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::peer_uuid"              => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_uuid}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::peer_host_uuid"         => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_host_uuid}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::volume_uuid"            => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{volume_uuid}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::resource_uuid"          => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{resource_uuid}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::connection_state"       => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{connection_state}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::local_disk_state"       => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{local_disk_state}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::peer_disk_state"        => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_disk_state}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::local_role"             => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{local_role}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::peer_role"              => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_role}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::out_of_sync_size"       => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{out_of_sync_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{out_of_sync_size}}).")", 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::replication_speed"      => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{replication_speed}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{replication_speed}}).")", 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::estimated_time_to_sync" => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{estimated_time_to_sync}." (".$anvil->Convert->time({'time' => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{estimated_time_to_sync}, long => 1, translate => 1}).")",
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::peer_ip_address"        => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_ip_address}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::peer_tcp_port"          => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{peer_tcp_port}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::protocol"               => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{protocol}, 
			"drbd::host_name::${short_host_name}::resource_name::${resource_name}::volume::${volume_number}::peer_name::${scan_drbd_peer_host_name}::fencing"                => $anvil->data->{drbd}{host_name}{$short_host_name}{resource_name}{$resource_name}{volume}{$volume_number}{peer_name}{$scan_drbd_peer_host_name}{fencing}, 
		}});
	}
	
	
	return(0);
}



=head2 get_fences

This loads the known fence devices into the C<< anvil::data >> hash at:

* fences::fence_uuid::<fence_uuid>::fence_name
* fences::fence_uuid::<fence_uuid>::fence_agent
* fences::fence_uuid::<fence_uuid>::fence_arguments
* fences::fence_uuid::<fence_uuid>::modified_date

And, to allow for lookup by name;

* fences::fence_name::<fence_name>::fence_uuid
* fences::fence_name::<fence_name>::fence_agent
* fences::fence_name::<fence_name>::fence_arguments
* fences::fence_name::<fence_name>::modified_date

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

B<<Note>>: Deleted devices (ones where C<< fence_arguments >> is set to C<< DELETED >>) are ignored. See the C<< include_deleted >> parameter to include them.

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted agents are included when loading the data. When C<< 0 >> is set, the default, any fence agent with C<< fence_arguments >> set to C<< DELETED >> is ignored.

=cut
sub get_fences
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_fences()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	if (exists $anvil->data->{fences})
	{
		delete $anvil->data->{fences};
	}
	
	my $query = "
SELECT 
    fence_uuid, 
    fence_name, 
    fence_agent, 
    fence_arguments, 
    modified_date 
FROM 
    fences ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    fence_arguments != 'DELETED'";
	}
	$query .= "
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
		my $fence_uuid      = $row->[0];
		my $fence_name      = $row->[1];
		my $fence_agent     = $row->[2];
		my $fence_arguments = $row->[3]; 
		my $modified_date   = $row->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			fence_uuid      => $fence_uuid, 
			fence_name      => $fence_name, 
			fence_agent     => $fence_agent, 
			fence_arguments => $fence_arguments =~ /passw=/ ? $anvil->Log->is_secure($fence_arguments) : $fence_arguments, 
			modified_date   => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_name}      = $fence_name;
		$anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_agent}     = $fence_agent;
		$anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_arguments} = $fence_arguments;
		$anvil->data->{fences}{fence_uuid}{$fence_uuid}{modified_date}   = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"fences::fence_uuid::${fence_uuid}::fence_name"      => $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_name}, 
			"fences::fence_uuid::${fence_uuid}::fence_agent"     => $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_agent}, 
			"fences::fence_uuid::${fence_uuid}::fence_arguments" => $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_arguments} =~ /passw=/ ? $anvil->Log->is_secure($anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_arguments}) : $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_arguments}, 
			"fences::fence_uuid::${fence_uuid}::modified_date"   => $anvil->data->{fences}{fence_uuid}{$fence_uuid}{modified_date}, 
		}});
		
		$anvil->data->{fences}{fence_name}{$fence_name}{fence_uuid}      = $fence_uuid;
		$anvil->data->{fences}{fence_name}{$fence_name}{fence_agent}     = $fence_agent;
		$anvil->data->{fences}{fence_name}{$fence_name}{fence_arguments} = $fence_arguments;
		$anvil->data->{fences}{fence_name}{$fence_name}{modified_date}   = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"fences::fence_name::${fence_name}::fence_uuid"      => $anvil->data->{fences}{fence_name}{$fence_name}{fence_uuid}, 
			"fences::fence_name::${fence_name}::fence_agent"     => $anvil->data->{fences}{fence_name}{$fence_name}{fence_agent}, 
			"fences::fence_name::${fence_name}::fence_arguments" => $anvil->data->{fences}{fence_name}{$fence_name}{fence_arguments} =~ /passw=/ ? $anvil->Log->is_secure($anvil->data->{fences}{fence_name}{$fence_name}{fence_arguments}) : $anvil->data->{fences}{fence_name}{$fence_name}{fence_arguments}, 
			"fences::fence_name::${fence_name}::modified_date"   => $anvil->data->{fences}{fence_name}{$fence_name}{modified_date}, 
		}});
	}

	return(0);
}


=head2 get_file_locations

This loads the known install file_locations into the C<< anvil::data >> hash at:

* file_locations::file_location_uuid::<file_location_uuid>::file_location_file_uuid
* file_locations::file_location_uuid::<file_location_uuid>::file_location_host_uuid
* file_locations::file_location_uuid::<file_location_uuid>::file_location_active
* file_locations::file_location_uuid::<file_location_uuid>::file_location_ready
* file_locations::file_location_uuid::<file_location_uuid>::modified_date

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

This method takes no parameters.

=cut
sub get_file_locations
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_file_locations()" }});
	
	if (exists $anvil->data->{file_locations})
	{
		delete $anvil->data->{file_locations};
	}
	
	my $query = "
SELECT 
    file_location_uuid, 
    file_location_file_uuid, 
    file_location_host_uuid, 
    file_location_active, 
    file_location_ready, 
    modified_date 
FROM 
    file_locations 
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
		my $file_location_uuid      = $row->[0];
		my $file_location_file_uuid = $row->[1];
		my $file_location_host_uuid = $row->[2];
		my $file_location_active    = $row->[3]; 
		my $file_location_ready     = $row->[4]; 
		my $modified_date           = $row->[5];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file_location_uuid      => $file_location_uuid, 
			file_location_file_uuid => $file_location_file_uuid, 
			file_location_host_uuid => $file_location_host_uuid, 
			file_location_active    => $file_location_active, 
			file_location_ready     => $file_location_ready, 
			modified_date           => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_file_uuid} = $file_location_file_uuid;
		$anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_host_uuid} = $file_location_host_uuid;
		$anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_active}    = $file_location_active;
		$anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_ready}     = $file_location_ready;
		$anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{modified_date}           = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"file_locations::file_location_uuid::${file_location_uuid}::file_location_file_uuid" => $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_file_uuid}, 
			"file_locations::file_location_uuid::${file_location_uuid}::file_location_host_uuid" => $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_host_uuid}, 
			"file_locations::file_location_uuid::${file_location_uuid}::file_location_active"    => $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_active}, 
			"file_locations::file_location_uuid::${file_location_uuid}::file_location_ready"     => $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_ready}, 
			"file_locations::file_location_uuid::${file_location_uuid}::modified_date"           => $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{modified_date}, 
		}});
		
		my $file_name      = "";
		my $file_directory = "";
		my $file_size      = "";
		my $file_md5sum    = "";
		my $file_type      = "";
		my $file_mtime     = "";
		if (exists $anvil->data->{files}{file_uuid}{$file_location_file_uuid})
		{
			$file_name      = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_name};
			$file_directory = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_directory};
			$file_size      = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_size}; 
			$file_md5sum    = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_md5sum};
			$file_type      = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_type};
			$file_mtime     = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_mtime};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				file_name      => $file_name, 
				file_directory => $file_directory, 
				file_size      => $file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}).")", 
				file_md5sum    => $file_md5sum, 
				file_type      => $file_type, 
				file_mtime     => $file_mtime,
			}});
		}
		
		# If this host is an Anvil! subnode, set the old 'file_location_anvil_uuid' to maintain 
		# backwards compatibility.
		if ((exists $anvil->data->{hosts}{host_uuid}{$file_location_host_uuid}) && 
		    ($anvil->data->{hosts}{host_uuid}{$file_location_host_uuid}{anvil_uuid}))
		{
			my $anvil_uuid = $anvil->data->{hosts}{host_uuid}{$file_location_host_uuid}{anvil_uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
			
			$anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_anvil_uuid} = $anvil_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"file_locations::file_location_uuid::${file_location_uuid}::file_location_anvil_uuid" => $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_anvil_uuid}, 
			}});
			
			if ($file_name)
			{
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_name}{$file_name}{file_uuid}                        = $file_location_file_uuid;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_name}          = $file_name;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_directory}     = $file_directory;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_size}          = $file_size;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_md5sum}        = $file_md5sum;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_type}          = $file_type;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_mtime}         = $file_mtime;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_location_uuid} = $file_location_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"anvils::anvil_uuid::${anvil_uuid}::file_name::${file_name}::file_uuid"                        => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_name}{$file_name}{file_uuid}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_name"          => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_name}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_directory"     => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_directory}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_size"          => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_size}}).")", 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_md5sum"        => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_md5sum}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_type"          => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_type}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_mtime"         => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_mtime}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_location_file_uuid}::file_location_uuid" => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_location_file_uuid}{file_location_uuid}, 
				}});
			}
		}
		
		# Make it easy to find files by anvil and file UUID.
		$anvil->data->{file_locations}{host_uuid}{$file_location_host_uuid}{file_uuid}{$file_location_file_uuid}{file_location_uuid} = $file_location_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"file_locations::host_uuid::${file_location_host_uuid}::file_uuid::${file_location_file_uuid}::file_location_uuid" => $anvil->data->{file_locations}{host_uuid}{$file_location_host_uuid}{file_uuid}{$file_location_file_uuid}{file_location_uuid},
		}});
	}

	return(0);
}


=head2 get_files

This loads all know files into the following hashes;

* files::file_uuid::<file_uuid>::file_name
* files::file_uuid::<file_uuid>::file_directory
* files::file_uuid::<file_uuid>::file_size
* files::file_uuid::<file_uuid>::file_md5sum
* files::file_uuid::<file_uuid>::file_type
* files::file_uuid::<file_uuid>::file_mtime
* files::file_uuid::<file_uuid>::modified_date

And;

* files::file_name::<file_name>::file_uuid
* files::file_name::<file_name>::file_directory
* files::file_name::<file_name>::file_size
* files::file_name::<file_name>::file_md5sum
* files::file_name::<file_name>::file_type
* files::file_name::<file_name>::file_mtime
* files::file_name::<file_name>::modified_date

Parameters;

=head3 include_deleted (optional, default '0')

Normally, files with C<< file_type >> set to C<< DELETED >> are ignored. Setting this to C<< 1 >> will include them.

=cut
sub get_files
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_files()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	if (exists $anvil->data->{files})
	{
		delete $anvil->data->{files};
	}
	
	my $query = "
SELECT 
    file_uuid, 
    file_name, 
    file_directory, 
    file_size, 
    file_md5sum, 
    file_type, 
    file_mtime,    
    modified_date 
FROM 
    files ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    file_type != 'DELETED'";
	}
	$query .= "
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = ref($results) eq "ARRAY" ? @{$results} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $file_uuid      =  $row->[0];
		my $file_name      =  $row->[1];
		my $file_directory =  $row->[2];
		my $file_size      =  $row->[3]; 
		my $file_md5sum    =  $row->[4]; 
		my $file_type      =  $row->[5]; 
		my $file_mtime     =  $row->[6];
		my $modified_date  =  $row->[7];
		my $full_path      =  $file_directory."/".$file_name;
		   $full_path      =~ s/\/\//\//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file_uuid      => $file_uuid, 
			file_name      => $file_name, 
			file_directory => $file_directory, 
			file_size      => $file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}).")", 
			file_md5sum    => $file_md5sum, 
			file_type      => $file_type,
			file_mtime     => $file_mtime,
			modified_date  => $modified_date, 
			full_path      => $full_path, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{files}{file_uuid}{$file_uuid}{file_name}      = $file_name;
		$anvil->data->{files}{file_uuid}{$file_uuid}{file_directory} = $file_directory;
		$anvil->data->{files}{file_uuid}{$file_uuid}{file_size}      = $file_size;
		$anvil->data->{files}{file_uuid}{$file_uuid}{file_md5sum}    = $file_md5sum;
		$anvil->data->{files}{file_uuid}{$file_uuid}{file_type}      = $file_type;
		$anvil->data->{files}{file_uuid}{$file_uuid}{file_mtime}     = $file_mtime;
		$anvil->data->{files}{file_uuid}{$file_uuid}{modified_date}  = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"files::file_uuid::${file_uuid}::file_name"      => $anvil->data->{files}{file_uuid}{$file_uuid}{file_name}, 
			"files::file_uuid::${file_uuid}::file_directory" => $anvil->data->{files}{file_uuid}{$file_uuid}{file_directory}, 
			"files::file_uuid::${file_uuid}::file_size"      => $anvil->data->{files}{file_uuid}{$file_uuid}{file_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{files}{file_uuid}{$file_uuid}{file_size}}).")", 
			"files::file_uuid::${file_uuid}::file_md5sum"    => $anvil->data->{files}{file_uuid}{$file_uuid}{file_md5sum}, 
			"files::file_uuid::${file_uuid}::file_type"      => $anvil->data->{files}{file_uuid}{$file_uuid}{file_type}, 
			"files::file_uuid::${file_uuid}::file_mtime"     => $anvil->data->{files}{file_uuid}{$file_uuid}{file_mtime}, 
			"files::file_uuid::${file_uuid}::modified_date"  => $anvil->data->{files}{file_uuid}{$file_uuid}{modified_date}, 
		}});
		
		# Is this a duplicate?
		if (exists $anvil->data->{files}{full_path}{$full_path})
		{
			# Duplicate! How many file_locations are linked to the duplicates?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0812", variables => { full_path => $full_path }});
			
			$anvil->Database->get_file_locations({debug => $debug});
			my $other_file_uuid   = $anvil->data->{files}{full_path}{$full_path}{file_uuid};
			my $other_file_size   = $anvil->data->{files}{file_uuid}{$other_file_uuid}{file_size};
			my $other_file_md5sum = $anvil->data->{files}{file_uuid}{$file_uuid}{file_md5sum};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				other_file_uuid   => $other_file_uuid, 
				other_file_size   => $other_file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $other_file_size}).")", 
				other_file_md5sum => $other_file_md5sum, 
			}});
			
			my $delete_file_uuid = "";
			
			# How many linked file_locations are there?
			my $query = "SELECT COUNT(*) FROM file_locations WHERE file_location_file_uuid = ".$anvil->Database->quote($file_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $file_location_count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_count => $file_location_count }});
			
			$query = "SELECT COUNT(*) FROM file_locations WHERE file_location_file_uuid = ".$anvil->Database->quote($other_file_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $other_file_location_count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { other_file_location_count => $other_file_location_count }});
			
			# This could happen just after peering a striker, so both could have no 
			# file_locations yet. If so, delete this one.
			if (not $file_location_count)
			{
				$delete_file_uuid = $file_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
			}
			elsif (not $other_file_location_count)
			{
				# Choose the other
				$delete_file_uuid = $other_file_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
			}
			else
			{
				# Pick the one with the largest file, if there's a difference.
				if ($file_size != $other_file_size)
				{
					if ($file_size > $other_file_size)
					{
						# This one is bigger, delete the other
						$delete_file_uuid = $other_file_uuid;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
					}
					else
					{
						# The other is bigger, delete this one.
						$delete_file_uuid = $file_uuid;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
					}
				}
				else
				{
					# Sizes are the same. Does one have more file_location references?
					if ($file_location_count != $other_file_location_count)
					{
						if ($file_location_count > $other_file_location_count)
						{
							# This one has more references
							$delete_file_uuid = $other_file_uuid;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
						}
						else
						{
							# The other one has more references.
							$delete_file_uuid = $file_uuid;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
						}
					}
					else
					{
						# No difference, delete this one.
						$delete_file_uuid = $file_uuid;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_file_uuid => $delete_file_uuid }});
					}
				}
			}
			
			if ($delete_file_uuid)
			{
				# Log which we're deleting 
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0813", variables => { file_uuid => $delete_file_uuid }});
				
				# As we delete file_locations, we need to make sure that there are 
				# file_location_file_uuid entries for the other file.
				my $keep_file_uuid = $file_uuid eq $delete_file_uuid ? $other_file_uuid : $file_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { keep_file_uuid => $keep_file_uuid }});
				
				my $query = "DELETE FROM history.file_locations WHERE file_location_file_uuid = ".$anvil->Database->quote($delete_file_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
				$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
				
				$query = "DELETE FROM file_locations WHERE file_location_file_uuid = ".$anvil->Database->quote($delete_file_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
				$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
				
				$query = "DELETE FROM history.files WHERE file_uuid = ".$anvil->Database->quote($delete_file_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
				$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
				
				$query = "DELETE FROM files WHERE file_uuid = ".$anvil->Database->quote($delete_file_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
				$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
				
				delete $anvil->data->{files}{file_uuid}{$delete_file_uuid};
				next;
			}
		}
		else
		{
			$anvil->data->{files}{full_path}{$full_path}{file_uuid}      = $file_uuid;
			$anvil->data->{files}{full_path}{$full_path}{file_name}      = $file_name;
			$anvil->data->{files}{full_path}{$full_path}{file_directory} = $file_directory;
			$anvil->data->{files}{full_path}{$full_path}{file_size}      = $file_size;
			$anvil->data->{files}{full_path}{$full_path}{file_md5sum}    = $file_md5sum;
			$anvil->data->{files}{full_path}{$full_path}{file_type}      = $file_type;
			$anvil->data->{files}{full_path}{$full_path}{file_mtime}     = $file_mtime;
			$anvil->data->{files}{full_path}{$full_path}{modified_date}  = $modified_date;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"files::full_path::${full_path}::file_uuid"      => $anvil->data->{files}{full_path}{$full_path}{file_uuid}, 
				"files::full_path::${full_path}::file_name"      => $anvil->data->{files}{full_path}{$full_path}{file_name}, 
				"files::full_path::${full_path}::file_directory" => $anvil->data->{files}{full_path}{$full_path}{file_directory}, 
				"files::full_path::${full_path}::file_size"      => $anvil->data->{files}{full_path}{$full_path}{file_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{files}{full_path}{$full_path}{file_size}}).")", 
				"files::full_path::${full_path}::file_md5sum"    => $anvil->data->{files}{full_path}{$full_path}{file_md5sum}, 
				"files::full_path::${full_path}::file_type"      => $anvil->data->{files}{full_path}{$full_path}{file_type}, 
				"files::full_path::${full_path}::file_mtime"     => $anvil->data->{files}{full_path}{$full_path}{file_mtime}, 
				"files::full_path::${full_path}::modified_date"  => $anvil->data->{files}{full_path}{$full_path}{modified_date}, 
			}});
		}
		
		### NOTE: This is the old way, which didn't allow two files with the same name in different 
		###       directories. This needs to be retired.
		$anvil->data->{files}{file_name}{$file_name}{file_uuid}      = $file_uuid;
		$anvil->data->{files}{file_name}{$file_name}{file_directory} = $file_directory;
		$anvil->data->{files}{file_name}{$file_name}{file_size}      = $file_size;
		$anvil->data->{files}{file_name}{$file_name}{file_md5sum}    = $file_md5sum;
		$anvil->data->{files}{file_name}{$file_name}{file_type}      = $file_type;
		$anvil->data->{files}{file_name}{$file_name}{file_mtime}     = $file_mtime;
		$anvil->data->{files}{file_name}{$file_name}{modified_date}  = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"files::file_name::${file_name}::file_uuid"      => $anvil->data->{files}{file_name}{$file_name}{file_uuid}, 
			"files::file_name::${file_name}::file_directory" => $anvil->data->{files}{file_name}{$file_name}{file_directory}, 
			"files::file_name::${file_name}::file_size"      => $anvil->data->{files}{file_name}{$file_name}{file_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{files}{file_name}{$file_name}{file_size}}).")", 
			"files::file_name::${file_name}::file_md5sum"    => $anvil->data->{files}{file_name}{$file_name}{file_md5sum}, 
			"files::file_name::${file_name}::file_type"      => $anvil->data->{files}{file_name}{$file_name}{file_type}, 
			"files::file_name::${file_name}::file_mtime"     => $anvil->data->{files}{file_name}{$file_name}{file_mtime}, 
			"files::file_name::${file_name}::modified_date"  => $anvil->data->{files}{file_name}{$file_name}{modified_date}, 
		}});
	}

	return(0);
}


=head2 get_host_from_uuid

This takes a host UUID and returns the host's name. If there is a problem, or if the host UUID isn't found, an empty string is returned.

Parameters;

=head3 host_uuid (required)

This is the host UUID we're querying the name of.

=head3 include_deleted (optional, default '0')

If set to C<< 1 >>, hosts that are deleted are included. If you use this, and a machine was replaced, then watch for multiple host UUIDs.

=head3 short (optional, default '0')

If set to C<< 1 >>, the short host name is returned. When set to C<< 0 >>, the full host name is returned.

=cut
sub get_host_from_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_host_from_uuid()" }});
	
	my $host_name       = "";
	my $short_host_name = "";
	my $host_uuid       = defined $parameter->{host_uuid}       ? $parameter->{host_uuid}       : "";
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	my $short           = defined $parameter->{short}           ? $parameter->{short}           : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid       => $host_uuid, 
		include_deleted => $include_deleted, 
		short           => $short,
	}});
	
	if (not $host_uuid)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->get_host_from_uuid()", parameter => "host_uuid" }});
		return($host_name);
	}
	
	# If we queried this before, return the cached value.
	if (exists $anvil->data->{host_from_uuid}{$host_uuid})
	{
		if ($short)
		{
			return($anvil->data->{host_from_uuid}{$host_uuid}{short});
		}
		else
		{
			return($anvil->data->{host_from_uuid}{$host_uuid}{full});
		}
	}
	
	my $query = "
SELECT 
    host_name 
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->Database->quote($host_uuid);
	if (not $include_deleted)
	{
		$query .= "
AND 
    host_key  != 'DELETED'";
	}
	$query .= "
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
		$host_name       = $results->[0]->[0];
		$short_host_name = ($host_name =~ /^(.*?)\..*$/)[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_name       => $host_name,
			short_host_name => $short_host_name, 
		}});
		
		$anvil->data->{host_from_uuid}{$host_uuid}{full}  = $host_name;
		$anvil->data->{host_from_uuid}{$host_uuid}{short} = $short_host_name ? $short_host_name : $host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"host_from_uuid::${host_uuid}::full"  => $anvil->data->{host_from_uuid}{$host_uuid}{full},
			"host_from_uuid::${host_uuid}::short" => $anvil->data->{host_from_uuid}{$host_uuid}{short},
		}});
	}
	
	if ($short)
	{
		return($anvil->data->{host_from_uuid}{$host_uuid}{short});
	}
	else
	{
		return($anvil->data->{host_from_uuid}{$host_uuid}{full});
	}
}


=head2 get_host_uuid_from_string

This takes a string and uses it to look for a host UUID. This string can being either a UUID, short or full host name. The matched C<< host_uuid >> is returned, if found. If no match is found, and empty string is returned.

This is meant to handle '--host' switches.

Parameters;

=head3 string

This is the string to search for.

=cut
sub get_host_uuid_from_string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_host_uuid_from_string()" }});

	my $string = defined $parameter->{string} ? $parameter->{string} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		string => $string,
	}});

	# Nothing to do unless we were called with a string.
	if (not $string)
	{
		return("");
	}

	$anvil->Database->get_hosts({debug => $debug});
	foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{sys}{hosts}{by_name}})
	{
		my $host_uuid       = $anvil->data->{sys}{hosts}{by_name}{$host_name};
		my $short_host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			host_uuid       => $host_uuid,
			host_name       => $host_name,
			short_host_name => $short_host_name,
		}});
		if (($string eq $host_uuid) or
		    ($string eq $host_name) or
		    ($string eq $short_host_name))
		{
			# Found it.
			return($host_uuid);
		}
	}

	return("");
}


=head2 get_hosts

Get a list of hosts from the c<< hosts >> table, returned as an array of hash references.

Each anonymous hash is structured as:

 host_uuid       => $host_uuid, 
 host_name       => $host_name, 
 short_host_name => $short_host_name, 
 host_type       => $host_type, 
 host_key        => $host_key, 
 host_ipmi       => $host_ipmi, 
 host_status     => $host_status,
 modified_date   => $modified_date, 

It also sets the variables;

 hosts::host_uuid::<host_uuid>::host_name       = <host_name>;
 hosts::host_uuid::<host_uuid>::short_host_name = <short_host_name>;
 hosts::host_uuid::<host_uuid>::host_type       = <host_type; node, dr or dashboard>
 hosts::host_uuid::<host_uuid>::host_key        = <Machine's public key / fingerprint, set to DELETED when the host is no longer used>
 hosts::host_uuid::<host_uuid>::host_ipmi       = <If equiped, this is how to log into the host's IPMI BMC, including the password!>
 hosts::host_uuid::<host_uuid>::host_status     = <This is the power state of the host. Default is 'unknown', and can be "powered off", "online", "stopping" and "booting.>
 hosts::host_uuid::<host_uuid>::anvil_name      = <anvil_name if associated with an anvil>
 hosts::host_uuid::<host_uuid>::anvil_uuid      = <anvil_uuid if associated with an anvil>

And to simplify look-ups by UUID or name;

 sys::hosts::by_uuid::<host_uuid> = <host_name>
 sys::hosts::by_name::<host_name> = <host_uuid>

To prevent some cases of recursion, C<< hosts::loaded >> is set on successful load, and if this is set, this method immediately returns with C<< 0 >>. 

Parameters;

=head3 include_deleted (optional, default '0')

By default, hosts that have been deleted (C<< host_key >> set to C<< DELETED >>) are not returned. If this is set to C<< 1 >>, those deleted hosts are included.

B<< Note >>: Be careful when using this. If a machine was replaced, then there could be two (or more) host UUIDs for a given host name.

=cut
sub get_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_hosts()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	# Delete any data from past scans.
	delete $anvil->data->{hosts}{host_uuid};
	delete $anvil->data->{sys}{hosts}{by_uuid};
	delete $anvil->data->{sys}{hosts}{by_name};
	
	# Load anvils. If a host is registered with an Anvil!, we'll note it.
	$anvil->Database->get_anvils({debug => $debug});
	
	my $query = "
SELECT 
    host_uuid, 
    host_name, 
    host_type, 
    host_key, 
    host_ipmi, 
    host_status, 
    modified_date 
FROM 
    hosts ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    host_key  != 'DELETED'";
	}
	$query .= "
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $return  = [];
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $host_uuid     =         $row->[0];
		my $host_name     =         $row->[1];
		my $host_type     = defined $row->[2] ? $row->[2] : "";
		my $host_key      = defined $row->[3] ? $row->[3] : "";
		my $host_ipmi     =         $row->[4];
		my $host_status   =         $row->[5];
		my $modified_date =         $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_uuid     => $host_uuid, 
			host_name     => $host_name, 
			host_type     => $host_type, 
			host_key      => $host_key, 
			host_ipmi     => $host_ipmi =~ /passw/ ? $anvil->Log->is_secure($host_ipmi) : $host_ipmi, 
			host_status   => $host_status, 
			modified_date => $modified_date, 
		}});
		
		my $anvil_name = "";
		my $anvil_uuid = "";
		if ((exists $anvil->data->{anvils}{host_uuid}{$host_uuid}) && ($anvil->data->{anvils}{host_uuid}{$host_uuid}{anvil_name}))
		{
			$anvil_name = $anvil->data->{anvils}{host_uuid}{$host_uuid}{anvil_name};
			$anvil_uuid = $anvil->data->{anvils}{host_uuid}{$host_uuid}{anvil_uuid};
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
		
		push @{$return}, {
			host_uuid     => $host_uuid,
			host_name     => $host_name, 
			host_type     => $host_type, 
			host_key      => $host_key, 
			host_ipmi     => $host_ipmi, 
			host_status   => $host_status, 
			modified_date => $modified_date, 
		};
		
		my $short_host_name =  $host_name;
		   $short_host_name =~ s/\..*$//;

		# Record the data in the hash, too.
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}       = $host_name;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name} = $short_host_name;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}       = $host_type;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}        = $host_key;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{host_ipmi}       = $host_ipmi;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{host_status}     = $host_status;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_name}      = $anvil_name;
		$anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_uuid}      = $anvil_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"hosts::host_uuid::${host_uuid}::host_name"       => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}, 
			"hosts::host_uuid::${host_uuid}::short_host_name" => $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name}, 
			"hosts::host_uuid::${host_uuid}::host_type"       => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}, 
			"hosts::host_uuid::${host_uuid}::host_key"        => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}, 
			"hosts::host_uuid::${host_uuid}::host_ipmi"       => $host_ipmi =~ /passw/ ? $anvil->Log->is_secure($anvil->data->{hosts}{host_uuid}{$host_uuid}{host_ipmi}) : $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_ipmi}, 
			"hosts::host_uuid::${host_uuid}::host_status"     => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_status}, 
			"hosts::host_uuid::${host_uuid}::anvil_name"      => $anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_name}, 
			"hosts::host_uuid::${host_uuid}::anvil_uuid"      => $anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_uuid}, 
		}});
		
		# Record the host_uuid in a hash so that the name can be easily retrieved.
		$anvil->data->{sys}{hosts}{by_uuid}{$host_uuid} = $host_name;
		$anvil->data->{sys}{hosts}{by_name}{$host_name} = $host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::hosts::by_uuid::${host_uuid}" => $anvil->data->{sys}{hosts}{by_uuid}{$host_uuid}, 
			"sys::hosts::by_name::${host_name}" => $anvil->data->{sys}{hosts}{by_name}{$host_name}, 
		}});
		
		# Record hosts by type.
		$anvil->data->{sys}{hosts}{by_type}{$host_type}{host_name}{$host_name}{host_uuid}       = $host_uuid;
		$anvil->data->{sys}{hosts}{by_type}{$host_type}{host_name}{$host_name}{short_host_name} = $short_host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::hosts::by_type::${host_type}::host_name::${host_name}::host_uuid"       => $anvil->data->{sys}{hosts}{by_type}{$host_type}{host_name}{$host_name}{host_uuid}, 
			"sys::hosts::by_type::${host_type}::host_name::${host_name}::short_host_name" => $anvil->data->{sys}{hosts}{by_type}{$host_type}{host_name}{$host_name}{short_host_name}, 
		}});
	}
	
	my $return_count = @{$return};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_count => $return_count }});
	return($return);
}


=head2 get_hosts_info

This gathers up all the known information about all known hosts, inlcuding information from the C<< variables >> table linked to each host.

This method takes no parameters.

=cut
sub get_hosts_info
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_hosts_info()" }});
	
	# Load anvil data so we can find passwords.
	$anvil->Database->get_anvils({debug => $debug});
	
	my $query = "
SELECT 
    host_uuid, 
    host_name, 
    host_type, 
    host_key, 
    host_ipmi, 
    host_status 
FROM 
    hosts
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
		my $host_uuid   = $row->[0];
		my $host_name   = $row->[1];
		my $host_type   = $row->[2];
		my $host_key    = $row->[3];
		my $host_ipmi   = $row->[4];
		my $host_status = $row->[5];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_uuid   => $host_uuid, 
			host_name   => $host_name, 
			host_type   => $host_type, 
			host_key    => $host_key, 
			host_ipmi   => $anvil->Log->is_secure($host_ipmi), 
			host_status => $host_status, 
		}});
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name}       =  $host_name;
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{short_host_name} =  $host_name;
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{short_host_name} =~ s/\..*$//;
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_type}       =  $host_type;
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_key}        =  $host_key;
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi}       =  $host_ipmi;
		$anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_status}     =  $host_status;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"machine::host_uuid::${host_uuid}::hosts::host_name"       => $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name}, 
			"machine::host_uuid::${host_uuid}::hosts::short_host_name" => $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{short_host_name}, 
			"machine::host_uuid::${host_uuid}::hosts::host_type"       => $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_type}, 
			"machine::host_uuid::${host_uuid}::hosts::host_key"        => $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_key}, 
			"machine::host_uuid::${host_uuid}::hosts::host_ipmi"       => $anvil->Log->is_secure($anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_ipmi}), 
			"machine::host_uuid::${host_uuid}::hosts::host_status"     => $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_status}, 
		}});
		
		# If this is an Anvil! member, pull it's IP.
		$anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{name} = "";
		$anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{uuid} = "";
		$anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{role} = "";
		$anvil->data->{machine}{host_uuid}{$host_uuid}{password}    = "";
		if (exists $anvil->data->{anvils}{host_uuid}{$host_uuid})
		{
			my $anvil_uuid                                                 = $anvil->data->{anvils}{host_uuid}{$host_uuid}{anvil_uuid};
			   $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{name} = $anvil->data->{anvils}{host_uuid}{$host_uuid}{anvil_name};
			   $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{uuid} = $anvil_uuid;
			   $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{role} = $anvil->data->{anvils}{host_uuid}{$host_uuid}{role};
			   $anvil->data->{machine}{host_uuid}{$host_uuid}{password}    = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"machine::host_uuid::${host_uuid}::anvil::name" => $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{name}, 
				"machine::host_uuid::${host_uuid}::anvil::uuid" => $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{uuid}, 
				"machine::host_uuid::${host_uuid}::anvil::role" => $anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{role}, 
				"machine::host_uuid::${host_uuid}::password"    => $anvil->Log->is_secure($anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{password}), 
			}});
		}
		elsif (exists $anvil->data->{database}{$host_uuid})
		{
			$anvil->data->{machine}{host_uuid}{$host_uuid}{password} = $anvil->data->{database}{$host_uuid}{password};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"machine::host_uuid::${host_uuid}::password"    => $anvil->Log->is_secure($anvil->data->{machine}{host_uuid}{$host_uuid}{anvil}{password}), 
			}});
		}
		
		# Read in the variables.
		my $query = "
SELECT 
    variable_name, 
    variable_value 
FROM 
    variables 
WHERE 
    variable_source_uuid  = ".$anvil->Database->quote($host_uuid)." 
AND 
    variable_source_table = 'hosts'
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
			my $variable_name  = $row->[0];
			my $variable_value = $row->[1];
			$anvil->data->{machine}{host_uuid}{$host_uuid}{variables}{$variable_name} = $variable_value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"machine::host_uuid::${host_uuid}::hosts::variables::${variable_name}"  => $anvil->data->{machine}{host_uuid}{$host_uuid}{variables}{$variable_name}, 
			}});
		}
		
		# Read in the IP addresses and network information. Data is loaded under 
		# 'network::host_uuid::x'.
		$anvil->Network->load_interfaces({debug => $debug, host_uuid => $host_uuid});
	}
	
	return(0);
}


=head2 get_ip_addresses

This loads all know IP addresses from the C<< ip_addresses >> table and stores them in a hash that simplifies knowing what host and network an IP belongs to.

The data will be stored in two hashes, one referenced by the network the IPs are on and the other referenced by the IP address.

 hosts::host_uuid::<host_uuid>::network::<on_network>::ip_address   = <ip_address>
 hosts::host_uuid::<host_uuid>::network::<on_network>::subnet_mask  = <subnet mask>
 hosts::host_uuid::<host_uuid>::network::<on_network>::on_interface = <interface name>

 hosts::host_uuid::<host_uuid>::ip_address::<ip_address>::subnet_mask  = <subnet mask>
 hosts::host_uuid::<host_uuid>::ip_address::<ip_address>::on_interface = <interface name>
 hosts::host_uuid::<host_uuid>::ip_address::<ip_address>::on_network   = <on_network>

This method takes no parameters.

=cut
sub get_ip_addresses
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_ip_addresses()" }});
	
	# Make sure we've loaded host data.
	$anvil->Database->get_hosts({debug => $debug});
	
	# Purge any previously known data.
	if (exists $anvil->data->{ip_addresses})
	{
		delete $anvil->data->{ip_addresses};
	}
	
	foreach my $host_uuid (keys %{$anvil->data->{hosts}{host_uuid}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
		
		# Load any bridges.
		my $query = "
SELECT 
    bridge_uuid, 
    bridge_name 
FROM 
    bridges 
WHERE 
    bridge_host_uuid =  ".$anvil->Database->quote($host_uuid)."
AND 
    bridge_id        != 'DELETED'
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
			my $bridge_uuid = $row->[0];
			my $bridge_name = $row->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				bridge_uuid => $bridge_uuid, 
				bridge_name => $bridge_name,
			}});
			
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{bridges}{bridge_uuid}{$bridge_uuid}{bridge_name} = $bridge_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hosts::host_uuid::${host_uuid}::bridges::bridge_uuid::${bridge_uuid}::bridge_name" => $anvil->data->{hosts}{host_uuid}{$host_uuid}{bridges}{bridge_uuid}{$bridge_uuid}{bridge_name},
			}});
		}
		undef $results;
		undef $count;
		
		# Read in bonds.
		$query = "
SELECT 
    bond_uuid, 
    bond_name 
FROM 
    bonds 
WHERE 
    bond_host_uuid = ".$anvil->Database->quote($host_uuid)." 
AND 
    bond_operational != 'DELETED'
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		$count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $bond_uuid = $row->[0];
			my $bond_name = $row->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				bond_uuid => $bond_uuid, 
				bond_name => $bond_name,
			}});
			
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{bonds}{bond_uuid}{$bond_uuid}{bond_name} = $bond_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hosts::host_uuid::${host_uuid}::bonds::bond_uuid::${bond_uuid}::bond_name" => $anvil->data->{hosts}{host_uuid}{$host_uuid}{bonds}{bond_uuid}{$bond_uuid}{bond_name},
			}});
		}
		undef $results;
		undef $count;
		
		# Now load interfaces.
		$query = "
SELECT 
    network_interface_uuid, 
    network_interface_name, 
    network_interface_device 
FROM 
    network_interfaces 
WHERE 
    network_interface_host_uuid   =  ".$anvil->Database->quote($host_uuid)." 
AND 
    network_interface_operational != 'DELETED'
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		$count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $network_interface_uuid   = $row->[0];
			my $network_interface_name   = $row->[1];
			my $network_interface_device = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				network_interface_uuid   => $network_interface_uuid, 
				network_interface_name   => $network_interface_name, 
				network_interface_device => $network_interface_device, 
			}});
			
			# The interface_device is the name used by 'ip addr list', and the name is the 'enX' 
			# biosdevname device. So we only use the name now if there is no device.
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{network_interfaces}{network_interface_uuid}{$network_interface_uuid}{network_interface_name} = $network_interface_device ? $network_interface_device : $network_interface_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hosts::host_uuid::${host_uuid}::network_interfaces::network_interface_uuid::${network_interface_uuid}::network_interface_name" => $anvil->data->{hosts}{host_uuid}{$host_uuid}{network_interfaces}{network_interface_uuid}{$network_interface_uuid}{network_interface_name},
			}});
		}
		undef $results;
		undef $count;
		
		# Finally, load IP addresses.
		$query = "
SELECT 
    ip_address_uuid, 
    ip_address_on_type, 
    ip_address_on_uuid, 
    ip_address_address, 
    ip_address_subnet_mask 
FROM 
    ip_addresses 
WHERE 
    ip_address_host_uuid = ".$anvil->Database->quote($host_uuid)." 
AND 
    ip_address_note != 'DELETED'
ORDER BY 
    modified_date DESC
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		$count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $ip_address_uuid        = $row->[0];
			my $ip_address_on_type     = $row->[1];
			my $ip_address_on_uuid     = $row->[2];
			my $ip_address_address     = $row->[3];
			my $ip_address_subnet_mask = $row->[4];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				ip_address_uuid        => $ip_address_uuid, 
				ip_address_on_type     => $ip_address_on_type, 
				ip_address_on_uuid     => $ip_address_on_uuid,
				ip_address_address     => $ip_address_address, 
				ip_address_subnet_mask => $ip_address_subnet_mask, 
			}});
			
			# There can be multiple entries for the same IP, which is a bug of course. However, 
			# until the root cause is found, this will detect/cleanup the dupes. By sorting by 
			# the modified_date, we'll preserve the newest one.
			if (exists $anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address})
			{
				# Duplicate, delete it.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, 'print' => 1, priority => "alert", key => "warning_0001", variables => { 
					host_uuid       => $host_uuid." (".$anvil->Get->host_name_from_uuid({host_uuid => $uuid}).")", 
					ip_address      => $ip_address_address, 
					subnet_mask     => $ip_address_subnet_mask, 
					on_type         => $ip_address_on_type, 
					on_uuid         => $ip_address_on_uuid, 
					ip_address_uuid => $ip_address_uuid, 
				}});
				
				my $query = "DELETE FROM history.ip_addresses WHERE ip_address_uuid = ".$anvil->Database->quote($ip_address_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
				
				$query = "DELETE FROM ip_addresses WHERE ip_address_uuid = ".$anvil->Database->quote($ip_address_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
				next;
			}
			
			# Which device is it on?
			my $on_interface = "";
			if (($ip_address_on_type eq "bridge") && (defined $anvil->data->{hosts}{host_uuid}{$host_uuid}{bridges}{bridge_uuid}{$ip_address_on_uuid}{bridge_name}))
			{
				$on_interface = $anvil->data->{hosts}{host_uuid}{$host_uuid}{bridges}{bridge_uuid}{$ip_address_on_uuid}{bridge_name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { on_interface => $on_interface }});
			}
			elsif (($ip_address_on_type eq "bond") && (defined $anvil->data->{hosts}{host_uuid}{$host_uuid}{bonds}{bond_uuid}{$ip_address_on_uuid}{bond_name}))
			{
				$on_interface = $anvil->data->{hosts}{host_uuid}{$host_uuid}{bonds}{bond_uuid}{$ip_address_on_uuid}{bond_name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { on_interface => $on_interface }});
			}
			elsif (($ip_address_on_type eq "interface") && (defined $anvil->data->{hosts}{host_uuid}{$host_uuid}{network_interfaces}{network_interface_uuid}{$ip_address_on_uuid}{network_interface_name}))
			{
				$on_interface = $anvil->data->{hosts}{host_uuid}{$host_uuid}{network_interfaces}{network_interface_uuid}{$ip_address_on_uuid}{network_interface_name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { on_interface => $on_interface }});
			}
			
			# We want to be able to map IPs to hosts.
			$anvil->data->{ip_addresses}{$ip_address_address}{host_uuid}       = $host_uuid;
			$anvil->data->{ip_addresses}{$ip_address_address}{ip_address_uuid} = $ip_address_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"ip_addresses::${ip_address_address}::host_uuid"       => $anvil->data->{ip_addresses}{$ip_address_address}{host_uuid}, 
				"ip_addresses::${ip_address_address}::ip_address_uuid" => $anvil->data->{ip_addresses}{$ip_address_address}{ip_address_uuid}, 
			}});
			
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address}{subnet_mask}  = $ip_address_subnet_mask;
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address}{on_interface} = $on_interface;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hosts::host_uuid::${host_uuid}::ip_address::${ip_address_address}::subnet_mask"  => $anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address}{subnet_mask}, 
				"hosts::host_uuid::${host_uuid}::ip_address::${ip_address_address}::on_interface" => $anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address}{on_interface}, 
			}});
			
			# If this is an interface that doesn't belong to us, we're done.
			my $on_network = ($on_interface =~ /^(.*?)_/)[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { on_network => $on_network }});
			next if not $on_network;
			
			# Store it by network.
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{ip_address}            = $ip_address_address;
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{subnet_mask}           = $ip_address_subnet_mask;
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{on_interface}          = $on_interface;
			$anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address}{on_network} = $on_network;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hosts::host_uuid::${host_uuid}::network::${on_network}::ip_address"            => $anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{ip_address}, 
				"hosts::host_uuid::${host_uuid}::network::${on_network}::subnet_mask"           => $anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{subnet_mask}, 
				"hosts::host_uuid::${host_uuid}::network::${on_network}::on_interface"          => $anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{on_interface}, 
				"hosts::host_uuid::${host_uuid}::ip_address::${ip_address_address}::on_network" => $anvil->data->{hosts}{host_uuid}{$host_uuid}{ip_address}{$ip_address_address}{on_network}, 
			}});
		}
		
	}
	
	return(0);
}


### TODO: Delete this and convert over to Jobs->get_job_details()
=head2 get_job_details

This gets the details for a given job. If the job is found, a hash reference is returned containing the tables that were read in.

Parameters;

=head3 job_uuid (default switches::job-uuid)

This is the C<< job_uuid >> of the job being retrieved. 

This method takes no parameters.

=cut
sub get_job_details
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_job_details()" }});
	
	my $return   = "";
	my $job_uuid = defined $parameter->{job_uuid} ? $parameter->{job_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		job_uuid => $job_uuid, 
	}});
	
	# If we didn't get a job_uuid, see if 'swtiches::job-uuid' is set.
	if ((not $job_uuid) && ($anvil->data->{switches}{'job-uuid'}))
	{
		$job_uuid = $anvil->data->{switches}{'job-uuid'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	}
	
	if (not $job_uuid)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->get_job_details()", parameter => "job_uuid" }});
		return($return);
	}
	
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
    modified_date
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
		# Job wasn't found.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0438", variables => { job_uuid => $job_uuid }});
		return($return);
	}
	
	my $job_host_uuid       =         $results->[0]->[0];
	my $job_command         =         $results->[0]->[1];
	my $job_data            = defined $results->[0]->[2] ? $results->[0]->[2] : "";
	my $job_picked_up_by    =         $results->[0]->[3];
	my $job_picked_up_at    =         $results->[0]->[4]; 
	my $job_updated         =         $results->[0]->[5];
	my $job_name            =         $results->[0]->[6];
	my $job_progress        =         $results->[0]->[7];
	my $job_title           =         $results->[0]->[8];
	my $job_description     =         $results->[0]->[9];
	my $job_status          =         $results->[0]->[10];
	my $modified_date       =         $results->[0]->[11];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		job_host_uuid    => $job_host_uuid,
		job_command      => $job_command,
		job_data         => $job_data,
		job_picked_up_by => $job_picked_up_by,
		job_picked_up_at => $job_picked_up_at,
		job_updated      => $job_updated,
		job_name         => $job_name, 
		job_progress     => $job_progress,
		job_title        => $job_title, 
		job_description  => $job_description,
		job_status       => $job_status, 
		modified_date    => $modified_date, 
	}});
	
	$return = {
		job_host_uuid    => $job_host_uuid,
		job_command      => $job_command,
		job_data         => $job_data,
		job_picked_up_by => $job_picked_up_by,
		job_picked_up_at => $job_picked_up_at,
		job_updated      => $job_updated,
		job_name         => $job_name, 
		job_progress     => $job_progress,
		job_title        => $job_title, 
		job_description  => $job_description,
		job_status       => $job_status, 
		modified_date    => $modified_date, 
	};
	
	return($return);
}


=head2 get_jobs

This gets the list of running jobs.

Parameters;

=head3 ended_within (optional, default 300)

Jobs that reached 100% within this number of seconds ago will be included. If this is set to C<< 0 >>, only in-progress and not-yet-picked-up jobs will be included.

=head3 job_host_uuid (default $anvil->Get->host_uuid)

This is the host that we're getting a list of jobs from. If this is set to C<< all >>, all jobs are loaded from all hosts.

This method takes no parameters.

=cut
sub get_jobs
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $return        = [];
	my $ended_within  = defined $parameter->{ended_within}  ? $parameter->{ended_within}  : 0;
	my $job_host_uuid = defined $parameter->{job_host_uuid} ? $parameter->{job_host_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ended_within  => $ended_within, 
		job_host_uuid => $job_host_uuid, 
	}});
	
	if ($ended_within !~ /^\d+$/)
	{
		$ended_within = 300;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ended_within => $ended_within }});
	}
	
	if (not $job_host_uuid)
	{
		$job_host_uuid = $anvil->Get->host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_host_uuid => $job_host_uuid }});
	}
	
	if (exists $anvil->data->{jobs}{running})
	{
		delete $anvil->data->{jobs}{running};
	}
	if (exists $anvil->data->{jobs}{modified_date})
	{
		delete $anvil->data->{jobs}{modified_date};
	}
	
	my $query = "
SELECT 
    job_uuid, 
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
    job_host_uuid, 
    modified_date, 
    round(extract(epoch from modified_date)) 
FROM 
    jobs ";
	if ($job_host_uuid ne "all")
	{
		$query .= "
WHERE 
    job_host_uuid = ".$anvil->Database->quote($job_host_uuid);
	}
	$query .= "
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
		my $job_uuid            =         $row->[0];
		my $job_command         =         $row->[1];
		my $job_data            = defined $row->[2] ? $row->[2] : "";
		my $job_picked_up_by    =         $row->[3];
		my $job_picked_up_at    =         $row->[4]; 
		my $job_updated         =         $row->[5];
		my $job_name            =         $row->[6];
		my $job_progress        =         $row->[7];
		my $job_title           =         $row->[8];
		my $job_description     =         $row->[9];
		my $job_status          =         $row->[10];
		my $job_host_uuid       =         $row->[11];
		my $modified_date       =         $row->[12];
		my $modified_date_unix  =         $row->[13];
		my $now_time            = time;
		my $started_seconds_ago = $job_picked_up_at ? ($now_time - $job_picked_up_at) : 0;
		my $updated_seconds_ago = $job_updated      ? ($now_time - $job_updated)      : 0;
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
			job_description     => $job_description,
			job_host_uuid       => $job_host_uuid, 
			job_status          => $job_status, 
			modified_date       => $modified_date, 
			modified_date_unix  => $modified_date_unix, 
			now_time            => $now_time, 
			started_seconds_ago => $started_seconds_ago, 
			updated_seconds_ago => $updated_seconds_ago, 
		}});
		
		# If the job is done, see if it was recently enough to care about it.
		if (($job_progress eq "100") && (($updated_seconds_ago == 0) or ($updated_seconds_ago > $ended_within)))
		{
			# Skip it
			next;
		}
		
		push @{$return}, {
			job_uuid           => $job_uuid,
			job_command        => $job_command,
			job_data           => $job_data,
			job_picked_up_by   => $job_picked_up_by,
			job_picked_up_at   => $job_picked_up_at,
			job_updated        => $job_updated,
			job_name           => $job_name, 
			job_progress       => $job_progress,
			job_title          => $job_title, 
			job_description    => $job_description,
			job_status         => $job_status, 
			job_host_uuid      => $job_host_uuid, 
			modified_date      => $modified_date, 
			modified_date_unix => $modified_date_unix, 
		};
		
		$anvil->data->{jobs}{running}{$job_uuid}{job_command}        = $job_command;
		$anvil->data->{jobs}{running}{$job_uuid}{job_data}           = $job_data;
		$anvil->data->{jobs}{running}{$job_uuid}{job_picked_up_by}   = $job_picked_up_by;
		$anvil->data->{jobs}{running}{$job_uuid}{job_picked_up_at}   = $job_picked_up_at;
		$anvil->data->{jobs}{running}{$job_uuid}{job_updated}        = $job_updated;
		$anvil->data->{jobs}{running}{$job_uuid}{job_name}           = $job_name;
		$anvil->data->{jobs}{running}{$job_uuid}{job_progress}       = $job_progress;
		$anvil->data->{jobs}{running}{$job_uuid}{job_title}          = $job_title;
		$anvil->data->{jobs}{running}{$job_uuid}{job_description}    = $job_description;
		$anvil->data->{jobs}{running}{$job_uuid}{job_status}         = $job_status;
		$anvil->data->{jobs}{running}{$job_uuid}{job_host_uuid}      = $job_host_uuid;
		$anvil->data->{jobs}{running}{$job_uuid}{modified_date}      = $modified_date;
		$anvil->data->{jobs}{running}{$job_uuid}{modified_date_unix} = $modified_date_unix;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"jobs::running::${job_uuid}::job_command"        => $anvil->data->{jobs}{running}{$job_uuid}{job_command}, 
			"jobs::running::${job_uuid}::job_data"           => $anvil->data->{jobs}{running}{$job_uuid}{job_data}, 
			"jobs::running::${job_uuid}::job_picked_up_by"   => $anvil->data->{jobs}{running}{$job_uuid}{job_picked_up_by}, 
			"jobs::running::${job_uuid}::job_picked_up_at"   => $anvil->data->{jobs}{running}{$job_uuid}{job_picked_up_at}, 
			"jobs::running::${job_uuid}::job_updated"        => $anvil->data->{jobs}{running}{$job_uuid}{job_updated}, 
			"jobs::running::${job_uuid}::job_name"           => $anvil->data->{jobs}{running}{$job_uuid}{job_name}, 
			"jobs::running::${job_uuid}::job_progress"       => $anvil->data->{jobs}{running}{$job_uuid}{job_progress}, 
			"jobs::running::${job_uuid}::job_title"          => $anvil->data->{jobs}{running}{$job_uuid}{job_title}, 
			"jobs::running::${job_uuid}::job_description"    => $anvil->data->{jobs}{running}{$job_uuid}{job_description}, 
			"jobs::running::${job_uuid}::job_status"         => $anvil->data->{jobs}{running}{$job_uuid}{job_status}, 
			"jobs::running::${job_uuid}::job_host_uuid"      => $anvil->data->{jobs}{running}{$job_uuid}{job_host_uuid}, 
			"jobs::running::${job_uuid}::modified_date"      => $anvil->data->{jobs}{running}{$job_uuid}{modified_date}, 
			"jobs::running::${job_uuid}::modified_date_unix" => $anvil->data->{jobs}{running}{$job_uuid}{modified_date}, 
		}});
		
		# Make it possible to sort by modified date for serial execution of similar jobs.
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_command}        = $job_command;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_data}           = $job_data;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_picked_up_by}   = $job_picked_up_by;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_picked_up_at}   = $job_picked_up_at;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_updated}        = $job_updated;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_name}           = $job_name;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_progress}       = $job_progress;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_title}          = $job_title;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_description}    = $job_description;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_status}         = $job_status;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_host_uuid}      = $job_host_uuid;
		$anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{modified_date_unix} = $modified_date_unix;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_command"        => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_command}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_data"           => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_data}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_picked_up_by"   => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_picked_up_by}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_picked_up_at"   => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_picked_up_at}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_updated"        => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_updated}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_name"           => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_name}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_progress"       => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_progress}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_title"          => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_title}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_description"    => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_description}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_status"         => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_status}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::job_host_uuid"      => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{job_host_uuid}, 
			"jobs::modified_date::${modified_date}::job_uuid::${job_uuid}::modified_date_unix" => $anvil->data->{jobs}{modified_date}{$modified_date}{job_uuid}{$job_uuid}{modified_date_unix}, 
		}});
	}
	
	my $return_count = @{$return};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_count => $return_count }});
	
	if ($return_count)
	{
		foreach my $hash_ref (@{$return})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				job_uuid           => $hash_ref->{job_uuid},
				job_command        => $hash_ref->{job_command},
				job_data           => $hash_ref->{job_data},
				job_picked_up_by   => $hash_ref->{job_picked_up_by},
				job_picked_up_at   => $hash_ref->{job_picked_up_at},
				job_updated        => $hash_ref->{job_updated},
				job_name           => $hash_ref->{job_name}, 
				job_progress       => $hash_ref->{job_progress},
				job_title          => $hash_ref->{job_title}, 
				job_description    => $hash_ref->{job_description},
				job_status         => $hash_ref->{job_status}, 
				job_host_uuid      => $hash_ref->{job_host_uuid}, 
				modified_date      => $hash_ref->{modified_date}, 
				modified_date_unix => $hash_ref->{modified_date_unix}, 
			}});
		}
	}
	
	return($return);
}


=head2 get_local_uuid

This returns the database UUID (usually the host's UUID) from C<< anvil.conf >> based on matching the C<< database::<uuid>::host >> to the local machine's host name or one of the active IP addresses on the host.

NOTE: This returns nothing if the local machine is not found as a configured database in C<< anvil.conf >>. This is a good way to check if the system has been setup yet.

 # Get the local UUID
 my $local_uuid = $anvil->Database->get_local_uuid;

This method takes no parameters.

=cut
sub get_local_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_local_uuid()" }});
	
	my $local_uuid = "";
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		my $db_host = $anvil->data->{database}{$uuid}{host};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { db_host => $db_host }});
		
		# If the uuid matches our host_uuid or if the host name matches ours (or is localhost), return
		# that UUID.
		if ($uuid eq $anvil->Get->host_uuid)
		{
			$local_uuid = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
			last;
		}
		elsif ($anvil->Network->is_local({host => $db_host}))
		{
			$local_uuid = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
			last;
		}
	}
	
	# Get out IPs.
	$anvil->Network->get_ips({debug => $debug});
	
	# Look for matches
	my $host = $anvil->Get->short_host_name();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
	if (not $local_uuid)
	{
		foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$host}{interface}})
		{
			my $ip_address  = $anvil->data->{network}{$host}{interface}{$interface}{ip};
			my $subnet_mask = $anvil->data->{network}{$host}{interface}{$interface}{subnet_mask};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				ip_address  => $ip_address,
				subnet_mask => $subnet_mask,
			}});
			foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					ip_address                => $ip_address,
					"database::${uuid}::host" => $anvil->data->{database}{$uuid}{host},
				}});
				if ($ip_address eq $anvil->data->{database}{$uuid}{host})
				{
					$local_uuid = $uuid;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
					last;
				}
			}
		}
	}
	
	return($local_uuid);
}


=head2 get_lvm_data

This loads all of the LVM data into the following hashes;

* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_uuid
* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_internal_uuid
* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_used_by_vg
* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_attributes
* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_size
* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_free
* lvm::host_name::<short_host_name>::pv::<scan_lvm_pv_name>::scan_lvm_pv_sector_size
* 
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::scan_lvm_vg_uuid
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::scan_lvm_vg_internal_uuid
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::scan_lvm_vg_attributes
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::scan_lvm_vg_extent_size
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::scan_lvm_vg_size
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::scan_lvm_vg_free
* lvm::host_name::<short_host_name>::vg::<scan_lvm_vg_name>::storage_group_uuid
* 
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_uuid
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_internal_uuid
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_attributes
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_on_vg
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_size
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_path
* lvm::host_name::<short_host_name>::lv::<scan_lvm_lv_name>::scan_lvm_lv_on_pvs

This method takes no parameters.

=cut
sub get_lvm_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_lvm_data()" }});
	
	# Load Storage Group data
	$anvil->Database->get_storage_group_data({debug => $debug});
	
	# Load PVs
	my $query = "
SELECT 
    scan_lvm_pv_uuid, 
    scan_lvm_pv_host_uuid, 
    scan_lvm_pv_internal_uuid, 
    scan_lvm_pv_name, 
    scan_lvm_pv_used_by_vg, 
    scan_lvm_pv_attributes, 
    scan_lvm_pv_size, 
    scan_lvm_pv_free, 
    scan_lvm_pv_sector_size 
FROM 
    scan_lvm_pvs
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
		my $scan_lvm_pv_uuid          = $row->[0]; 
		my $scan_lvm_pv_host_uuid     = $row->[1]; 
		my $scan_lvm_pv_internal_uuid = $row->[2]; 
		my $scan_lvm_pv_name          = $row->[3]; 
		my $scan_lvm_pv_used_by_vg    = $row->[4]; 
		my $scan_lvm_pv_attributes    = $row->[5]; 
		my $scan_lvm_pv_size          = $row->[6]; 
		my $scan_lvm_pv_free          = $row->[7]; 
		my $scan_lvm_pv_sector_size   = $row->[8]; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_lvm_pv_uuid          => $scan_lvm_pv_uuid, 
			scan_lvm_pv_host_uuid     => $scan_lvm_pv_host_uuid, 
			scan_lvm_pv_internal_uuid => $scan_lvm_pv_internal_uuid, 
			scan_lvm_pv_name          => $scan_lvm_pv_name, 
			scan_lvm_pv_used_by_vg    => $scan_lvm_pv_used_by_vg, 
			scan_lvm_pv_attributes    => $scan_lvm_pv_attributes, 
			scan_lvm_pv_size          => $scan_lvm_pv_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_pv_size}).")", 
			scan_lvm_pv_free          => $scan_lvm_pv_free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_pv_free}).")", 
			scan_lvm_pv_sector_size   => $scan_lvm_pv_sector_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_pv_sector_size}).")", 
		}});
		
		if (not exists $anvil->data->{hosts}{host_uuid}{$scan_lvm_pv_host_uuid})
		{
			$anvil->Database->get_hosts({
				debug           => $debug,
				include_deleted => 1,
			});
		}
		my $short_host_name = $anvil->data->{hosts}{host_uuid}{$scan_lvm_pv_host_uuid}{short_host_name};
		my $host_key        = $anvil->data->{hosts}{host_uuid}{$scan_lvm_pv_host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			short_host_name => $short_host_name,
			host_key        => $host_key, 
		}});
		next if $host_key eq "DELETED";
		
		# If the PV is deleted, appeand to pv_uuid to the key to make sure two or more DELETED 
		# entries don't clobber each other.
		if ($scan_lvm_pv_name eq "DELETED")
		{
			$scan_lvm_pv_name .= ":pv_uuid=".$scan_lvm_pv_uuid;
		}
		
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_uuid}          = $scan_lvm_pv_uuid;
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_internal_uuid} = $scan_lvm_pv_internal_uuid;
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_used_by_vg}    = $scan_lvm_pv_used_by_vg;
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_attributes}    = $scan_lvm_pv_attributes;
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_size}          = $scan_lvm_pv_size;
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_free}          = $scan_lvm_pv_free;
		$anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_sector_size}   = $scan_lvm_pv_sector_size;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_uuid"          => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_uuid},
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_internal_uuid" => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_internal_uuid},
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_used_by_vg"    => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_used_by_vg},
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_attributes"    => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_attributes},
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_size"          => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_size}}).")",
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_free"          => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_free}}).")",
			"lvm::host_name::${short_host_name}::pv::${scan_lvm_pv_name}::scan_lvm_pv_sector_size"   => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_sector_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{pv}{$scan_lvm_pv_name}{scan_lvm_pv_sector_size}}).")",
		}});
	}
	
	# Load VGs
	$query = "
SELECT 
    scan_lvm_vg_uuid, 
    scan_lvm_vg_host_uuid, 
    scan_lvm_vg_internal_uuid, 
    scan_lvm_vg_name, 
    scan_lvm_vg_attributes, 
    scan_lvm_vg_extent_size,
    scan_lvm_vg_size,
    scan_lvm_vg_free 
FROM 
    scan_lvm_vgs
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $scan_lvm_vg_uuid          = $row->[0]; 
		my $scan_lvm_vg_host_uuid     = $row->[1]; 
		my $scan_lvm_vg_internal_uuid = $row->[2]; 
		my $scan_lvm_vg_name          = $row->[3]; 
		my $scan_lvm_vg_attributes    = $row->[4]; 
		my $scan_lvm_vg_extent_size   = $row->[5]; 
		my $scan_lvm_vg_size          = $row->[6]; 
		my $scan_lvm_vg_free          = $row->[7]; 
		my $short_host_name           = $anvil->data->{hosts}{host_uuid}{$scan_lvm_vg_host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_lvm_vg_uuid          => $scan_lvm_vg_uuid, 
			scan_lvm_vg_host_uuid     => $scan_lvm_vg_host_uuid, 
			scan_lvm_vg_internal_uuid => $scan_lvm_vg_internal_uuid, 
			scan_lvm_vg_name          => $scan_lvm_vg_name, 
			scan_lvm_vg_attributes    => $scan_lvm_vg_attributes, 
			scan_lvm_vg_extent_size   => $scan_lvm_vg_extent_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_extent_size}).")", 
			scan_lvm_vg_size          => $scan_lvm_vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_size}).")", 
			scan_lvm_vg_free          => $scan_lvm_vg_free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_free}).")", 
			short_host_name           => $short_host_name,
		}});
		
		my $storage_group_uuid = "";
		if (exists $anvil->data->{storage_groups}{vg_uuid}{$scan_lvm_vg_internal_uuid})
		{
			$storage_group_uuid = $anvil->data->{storage_groups}{vg_uuid}{$scan_lvm_vg_internal_uuid}{storage_group_uuid};
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_uuid => $storage_group_uuid }});
		
		# If the VG is deleted, appeand to vg_uuid to the key to make sure two or more DELETED 
		# entries don't clobber each other.
		if ($scan_lvm_vg_name eq "DELETED")
		{
			$scan_lvm_vg_name .= ":vg_uuid=".$scan_lvm_vg_uuid;
		}
		
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_uuid}          = $scan_lvm_vg_uuid;
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_internal_uuid} = $scan_lvm_vg_internal_uuid;
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_attributes}    = $scan_lvm_vg_attributes;
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_extent_size}   = $scan_lvm_vg_extent_size;
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_size}          = $scan_lvm_vg_size;
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_free}          = $scan_lvm_vg_free;
		$anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{storage_group_uuid}        = $storage_group_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::scan_lvm_vg_uuid"          => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_uuid}, 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::scan_lvm_vg_internal_uuid" => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_internal_uuid}, 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::scan_lvm_vg_attributes"    => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_attributes}, 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::scan_lvm_vg_extent_size"   => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_extent_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_extent_size}}).")", 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::scan_lvm_vg_size"          => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_size}}).")", 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::scan_lvm_vg_free"          => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{scan_lvm_vg_free}}).")", 
			"lvm::host_name::${short_host_name}::vg::${scan_lvm_vg_name}::storage_group_uuid"        => $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$scan_lvm_vg_name}{storage_group_uuid}, 
		}});
		
		# Make it easier to look up by internal UUID
		$anvil->data->{lvm}{vg_internal_uuid}{$scan_lvm_vg_internal_uuid}{scan_lvm_vg_name} = $scan_lvm_vg_name;
		$anvil->data->{lvm}{vg_internal_uuid}{$scan_lvm_vg_internal_uuid}{scan_lvm_vg_uuid} = $scan_lvm_vg_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::vg_internal_uuid::${scan_lvm_vg_internal_uuid}::scan_lvm_vg_name" => $anvil->data->{lvm}{vg_internal_uuid}{$scan_lvm_vg_internal_uuid}{scan_lvm_vg_name}, 
			"lvm::vg_internal_uuid::${scan_lvm_vg_internal_uuid}::scan_lvm_vg_uuid" => $anvil->data->{lvm}{vg_internal_uuid}{$scan_lvm_vg_internal_uuid}{scan_lvm_vg_uuid}, 
		}});
	}
	
	# LVs
	$query = "
SELECT 
    scan_lvm_lv_uuid, 
    scan_lvm_lv_host_uuid, 
    scan_lvm_lv_internal_uuid, 
    scan_lvm_lv_name, 
    scan_lvm_lv_attributes, 
    scan_lvm_lv_on_vg,
    scan_lvm_lv_size,
    scan_lvm_lv_path,
    scan_lvm_lv_on_pvs
FROM 
    scan_lvm_lvs
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $scan_lvm_lv_uuid          = $row->[0]; 
		my $scan_lvm_lv_host_uuid     = $row->[1]; 
		my $scan_lvm_lv_internal_uuid = $row->[2]; 
		my $scan_lvm_lv_name          = $row->[3]; 
		my $scan_lvm_lv_attributes    = $row->[4]; 
		my $scan_lvm_lv_on_vg         = $row->[5]; 
		my $scan_lvm_lv_size          = $row->[6]; 
		my $scan_lvm_lv_path          = $row->[7]; 
		my $scan_lvm_lv_on_pvs        = $row->[8]; 
		my $short_host_name           = $anvil->data->{hosts}{host_uuid}{$scan_lvm_lv_host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_lvm_lv_uuid          => $scan_lvm_lv_uuid, 
			scan_lvm_lv_host_uuid     => $scan_lvm_lv_host_uuid, 
			scan_lvm_lv_internal_uuid => $scan_lvm_lv_internal_uuid, 
			scan_lvm_lv_name          => $scan_lvm_lv_name, 
			scan_lvm_lv_attributes    => $scan_lvm_lv_attributes, 
			scan_lvm_lv_on_vg         => $scan_lvm_lv_on_vg, 
			scan_lvm_lv_size          => $scan_lvm_lv_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_lv_size}).")",  
			scan_lvm_lv_path          => $scan_lvm_lv_path,
			scan_lvm_lv_on_pvs        => $scan_lvm_lv_on_pvs, 
			short_host_name           => $short_host_name,
		}});
		
		# If the LV is deleted, appeand to lv_uuid to the key to make sure two or more DELETED 
		# entries don't clobber each other.
		if ($scan_lvm_lv_name eq "DELETED")
		{
			$scan_lvm_lv_name .= ":lv_uuid=".$scan_lvm_lv_uuid;
		}
		
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_uuid}          = $scan_lvm_lv_uuid;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_internal_uuid} = $scan_lvm_lv_internal_uuid;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_attributes}    = $scan_lvm_lv_attributes;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_on_vg}         = $scan_lvm_lv_on_vg;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_size}          = $scan_lvm_lv_size;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_path}          = $scan_lvm_lv_path;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_on_pvs}        = $scan_lvm_lv_on_pvs;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$scan_lvm_lv_path}{scan_lvm_lv_name}     = $scan_lvm_lv_name;
		$anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$scan_lvm_lv_path}{scan_lvm_lv_uuid}     = $scan_lvm_lv_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_uuid"          => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_uuid}, 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_internal_uuid" => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_internal_uuid}, 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_attributes"    => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_attributes}, 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_on_vg"         => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_on_vg}, 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_size"          => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_size}}).")", 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_path"          => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_path}, 
			"lvm::host_name::${short_host_name}::lv::${scan_lvm_lv_name}::scan_lvm_lv_on_pvs"        => $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$scan_lvm_lv_name}{scan_lvm_lv_on_pvs}, 
			"lvm::host_name::${short_host_name}::lv_path::${scan_lvm_lv_path}::scan_lvm_lv_name"     => $anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$scan_lvm_lv_path}{scan_lvm_lv_name},
			"lvm::host_name::${short_host_name}::lv_path::${scan_lvm_lv_path}::scan_lvm_lv_uuid"     => $anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$scan_lvm_lv_path}{scan_lvm_lv_uuid},
		}});
	}
	
	return(0);
}


=head2 get_mac_to_ip

This loads the C<< mac_to_ip >> data. 

This method takes no parameters.

=cut
sub get_mac_to_ip
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_mac_to_ip()" }});
	
	if (exists $anvil->data->{mac_to_ip})
	{
		delete $anvil->data->{mac_to_ip};
	}
	
	my $query = "
SELECT 
    mac_to_ip_uuid, 
    mac_to_ip_mac_address, 
    mac_to_ip_ip_address, 
    mac_to_ip_note, 
    modified_date 
FROM 
    mac_to_ip
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
		my $mac_to_ip_uuid        = $row->[0]; 
		my $mac_to_ip_mac_address = $row->[1]; 
		my $mac_to_ip_ip_address  = $row->[2]; 
		my $mac_to_ip_note        = $row->[3];
		my $modified_date         = $row->[4]; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			mac_to_ip_uuid        => $mac_to_ip_uuid, 
			mac_to_ip_mac_address => $mac_to_ip_mac_address, 
			mac_to_ip_ip_address  => $mac_to_ip_ip_address, 
			mac_to_ip_note        => $mac_to_ip_note, 
			modified_date         => $modified_date, 
		}});
		
		$anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{mac_to_ip_mac_address} = $mac_to_ip_mac_address;
		$anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{mac_to_ip_ip_address}  = $mac_to_ip_ip_address;
		$anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{mac_to_ip_note}        = $mac_to_ip_note;
		$anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{modified_date}         = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:mac_to_ip::mac_to_ip_uuid::${mac_to_ip_uuid}::mac_to_ip_mac_address" => $anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{mac_to_ip_mac_address}, 
			"s2:mac_to_ip::mac_to_ip_uuid::${mac_to_ip_uuid}::mac_to_ip_ip_address"  => $anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{mac_to_ip_ip_address}, 
			"s3:mac_to_ip::mac_to_ip_uuid::${mac_to_ip_uuid}::mac_to_ip_note"        => $anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{mac_to_ip_note}, 
			"s4:mac_to_ip::mac_to_ip_uuid::${mac_to_ip_uuid}::modified_date"         => $anvil->data->{mac_to_ip}{mac_to_ip_uuid}{$mac_to_ip_uuid}{modified_date}, 
		}});
		
		# Make it easier to look things up.
		$anvil->data->{mac_to_ip}{mac_to_ip_mac_address}{$mac_to_ip_mac_address}{mac_to_ip_uuid} = $mac_to_ip_uuid;
		$anvil->data->{mac_to_ip}{mac_to_ip_ip_address}{$mac_to_ip_ip_address}{mac_to_ip_uuid}   = $mac_to_ip_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:mac_to_ip::mac_to_ip_mac_address::${mac_to_ip_mac_address}::mac_to_ip_uuid" => $anvil->data->{mac_to_ip}{mac_to_ip_mac_address}{$mac_to_ip_mac_address}{mac_to_ip_uuid}, 
			"s2:mac_to_ip::mac_to_ip_ip_address::${mac_to_ip_ip_address}::mac_to_ip_uuid"   => $anvil->data->{mac_to_ip}{mac_to_ip_ip_address}{$mac_to_ip_ip_address}{mac_to_ip_uuid}, 
		}});
	}
	
	return(0);
}


=head2 get_mail_servers

This gets the list of configured mail servers.

This method takes no parameters.

=cut
sub get_mail_servers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_mail_servers()" }});
	
	if (exists $anvil->data->{mail_servers})
	{
		delete $anvil->data->{mail_servers};
	}
	
	my $query = "
SELECT 
    mail_server_uuid, 
    mail_server_address, 
    mail_server_port, 
    mail_server_username, 
    mail_server_password, 
    mail_server_security, 
    mail_server_authentication, 
    mail_server_helo_domain 
FROM 
    mail_servers
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
		my $mail_server_uuid           = $row->[0]; 
		my $mail_server_address        = $row->[1]; 
		my $mail_server_port           = $row->[2]; 
		my $mail_server_username       = $row->[3]; 
		my $mail_server_password       = $row->[4]; 
		my $mail_server_security       = $row->[5]; 
		my $mail_server_authentication = $row->[6]; 
		my $mail_server_helo_domain    = $row->[7]; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			mail_server_uuid           => $mail_server_uuid, 
			mail_server_address        => $mail_server_address, 
			mail_server_port           => $mail_server_port, 
			mail_server_username       => $mail_server_username, 
			mail_server_password       => $anvil->Log->is_secure($mail_server_password), 
			mail_server_security       => $mail_server_security,  
			mail_server_authentication => $mail_server_authentication, 
			mail_server_helo_domain    => $mail_server_helo_domain,
		}});
		
		# Store the data
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_address}        = $mail_server_address;
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_port}           = $mail_server_port;
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_username}       = $mail_server_username;
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_password}       = $mail_server_password;
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_security}       = $mail_server_security;
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_authentication} = $mail_server_authentication;
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_helo_domain}    = $mail_server_helo_domain;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_address"        => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_address}, 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_port"           => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_port}, 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_username"       => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_username}, 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_password"       => $anvil->Log->is_secure($anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_password}), 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_security"       => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_security}, 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_authentication" => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_authentication}, 
			"mail_servers::mail_server::${mail_server_uuid}::mail_server_helo_domain"    => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_helo_domain}, 
		}});
		
		# Make it easy to look up the mail server's UUID from the server address.
		$anvil->data->{mail_servers}{address_to_uuid}{$mail_server_address} = $mail_server_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"mail_servers::address_to_uuid::${mail_server_address}" => $anvil->data->{mail_servers}{address_to_uuid}{$mail_server_address}, 
		}});
		
		# Set a default 'last_used' of 0 for this host.
		$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{last_used} = 0;
	}
	
	# Look up variables for this server.
	$query = "
SELECT 
    variable_name, 
    variable_value 
FROM 
    variables 
WHERE 
    variable_name LIKE 'mail_server::last_used::%'
AND
    variable_source_uuid  = ".$anvil->Database->quote($anvil->Get->host_uuid)." 
AND 
    variable_source_table = 'hosts'
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $local_host = $anvil->Get->short_host_name;
	   $results    = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	   $count      = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results    => $results, 
		count      => $count, 
		local_host => $local_host, 
	}});
	foreach my $row (@{$results})
	{
		my $variable_name  = $row->[0];
		my $variable_value = $row->[1];
		$anvil->data->{mail_servers}{use_order}{$local_host}{variables}{$variable_name} = $variable_value;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"mail_servers::use_order::${local_host}::variables::${variable_name}"  => $anvil->data->{mail_servers}{use_order}{$local_host}{variables}{$variable_name}, 
		}});
		
		if ($variable_name =~ /mail_server::last_used::(.*)$/)
		{
			my $mail_server_uuid = $1;
			$anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{last_used} = $variable_value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"mail_servers::mail_server::${mail_server_uuid}::last_used" => $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{last_used}, 
			}});
		}
	}
	
	return(0);
}


=head2 get_manifests

This loads the known install manifests into the C<< anvil::data >> hash at:

* manifests::manifest_uuid::<manifest_uuid>::manifest_name
* manifests::manifest_uuid::<manifest_uuid>::manifest_last_ran
* manifests::manifest_uuid::<manifest_uuid>::manifest_xml
* manifests::manifest_uuid::<manifest_uuid>::manifest_note
* manifests::manifest_uuid::<manifest_uuid>::modified_date

And, to allow for lookup by name;

* manifests::manifest_name::<manifest_name>::manifest_uuid
* manifests::manifest_name::<manifest_name>::manifest_last_ran
* manifests::manifest_name::<manifest_name>::manifest_xml
* manifests::manifest_name::<manifest_name>::manifest_note
* manifests::manifest_name::<manifest_name>::modified_date

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

B<<Note>>: Deleted devices (ones where C<< manifest_note >> is set to C<< DELETED >>) are ignored. See the C<< include_deleted >> parameter to include them.

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted last_rans are included when loading the data. When C<< 0 >> is set, the default, any manifest last_ran with C<< manifest_note >> set to C<< DELETED >> is ignored.

=cut
sub get_manifests
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_manifests()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	if (exists $anvil->data->{manifests})
	{
		delete $anvil->data->{manifests};
	}
	
	my $query = "
SELECT 
    manifest_uuid, 
    manifest_name, 
    manifest_last_ran, 
    manifest_xml, 
    manifest_note, 
    modified_date 
FROM 
    manifests ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    manifest_note != 'DELETED'";
	}
	$query .= "
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
		my $manifest_uuid     = $row->[0];
		my $manifest_name     = $row->[1];
		my $manifest_last_ran = $row->[2];
		my $manifest_xml      = $row->[3]; 
		my $manifest_note     = $row->[4]; 
		my $modified_date     = $row->[5];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			manifest_uuid     => $manifest_uuid, 
			manifest_name     => $manifest_name, 
			manifest_last_ran => $manifest_last_ran, 
			manifest_note     => $manifest_note, 
			manifest_xml      => $manifest_xml, 
			modified_date     => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_name}     = $manifest_name;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_last_ran} = $manifest_last_ran;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_xml}      = $manifest_xml;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_note}     = $manifest_note;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{modified_date}     = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::manifest_uuid::${manifest_uuid}::manifest_name"     => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_name}, 
			"manifests::manifest_uuid::${manifest_uuid}::manifest_last_ran" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_last_ran}, 
			"manifests::manifest_uuid::${manifest_uuid}::manifest_xml"      => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_xml}, 
			"manifests::manifest_uuid::${manifest_uuid}::manifest_note"     => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{manifest_note}, 
			"manifests::manifest_uuid::${manifest_uuid}::modified_date"     => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{modified_date}, 
		}});
		
		$anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_uuid}     = $manifest_uuid;
		$anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_last_ran} = $manifest_last_ran;
		$anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_xml}      = $manifest_xml;
		$anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_note}     = $manifest_note;
		$anvil->data->{manifests}{manifest_name}{$manifest_name}{modified_date}     = $modified_date;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::manifest_name::${manifest_name}::manifest_uuid"     => $anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_uuid}, 
			"manifests::manifest_name::${manifest_name}::manifest_last_ran" => $anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_last_ran}, 
			"manifests::manifest_name::${manifest_name}::manifest_xml"      => $anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_xml}, 
			"manifests::manifest_name::${manifest_name}::manifest_note"     => $anvil->data->{manifests}{manifest_name}{$manifest_name}{manifest_note}, 
			"manifests::manifest_name::${manifest_name}::modified_date"     => $anvil->data->{manifests}{manifest_name}{$manifest_name}{modified_date}, 
		}});
	}

	return(0);
}


=head2 get_recipients

This returns a list of users listening to alerts for a given host, along with their alert level. 

Parameters;

=head3 include_deleted (optional, default '0')

When a recipient is deleted, the C<< recipient_name >> is set to C<< DELETED >>. If you want these to be loaded as well, set this to C<< 1 >>

=cut
sub get_recipients
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_recipients()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	# We're going to include the alert levels for this host based on overrides that might exist in the 
	# 'alert_overrides' table. If the data hasn't already been loaded, we'll load it now.
	if (not $anvil->data->{alert_overrides}{alert_override_uuid})
	{
		$anvil->Database->get_alert_overrides({debug => $debug});
	}
	
	my $host_uuid = $anvil->Get->host_uuid();
	my $query     = "
SELECT 
    recipient_uuid,
    recipient_name,
    recipient_email,
    recipient_language,
    recipient_level 
FROM 
    recipients";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    recipient_name != 'DELETED'";
	}
	$query .= "
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
		my $recipient_uuid     = $row->[0];
		my $recipient_name     = $row->[1];
		my $recipient_email    = $row->[2];
		my $recipient_language = $row->[3];
		my $recipient_level    = $row->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			recipient_uuid     => $recipient_uuid, 
			recipient_name     => $recipient_name, 
			recipient_email    => $recipient_email, 
			recipient_language => $recipient_language, 
			recipient_level    => $recipient_level, 
		}});
		
		# Store the data
		$anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_name}     = $recipient_name;
		$anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_email}    = $recipient_email;
		$anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_language} = $recipient_language;
		$anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_level}    = $recipient_level;
		$anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{level_on_host}      = $recipient_level;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"recipients::recipient_uuid::${recipient_uuid}::recipient_name"     => $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_name}, 
			"recipients::recipient_uuid::${recipient_uuid}::recipient_email"    => $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_email}, 
			"recipients::recipient_uuid::${recipient_uuid}::recipient_language" => $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_language}, 
			"recipients::recipient_uuid::${recipient_uuid}::recipient_level"    => $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_level}, 
			"recipients::recipient_uuid::${recipient_uuid}::level_on_host"      => $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{level_on_host}, 
		}});
		
		# Make it easy to look up the mail server's UUID from the server address.
		$anvil->data->{recipients}{email_to_uuid}{$recipient_email} = $recipient_uuid;
		$anvil->data->{recipients}{name_to_uuid}{$recipient_name}   = $recipient_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"recipients::email_to_uuid::${recipient_email}" => $anvil->data->{recipients}{email_to_uuid}{$recipient_email}, 
			"recipients::name_to_uuid::${recipient_name}"   => $anvil->data->{recipients}{email_to_uuid}{$recipient_name}, 
		}});
		
		# If there is an override for a given recipient on this host, mark it as such.
		foreach my $alert_override_uuid (keys %{$anvil->data->{alert_overrides}{alert_override_uuid}})
		{
			my $alert_override_recipient_uuid = $anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_recipient_uuid};
			my $alert_override_host_uuid      = $anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_host_uuid};
			my $alert_override_alert_level    = $anvil->data->{alert_overrides}{alert_override_uuid}{$alert_override_uuid}{alert_override_alert_level};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				alert_override_recipient_uuid => $alert_override_recipient_uuid, 
				alert_override_host_uuid      => $alert_override_host_uuid, 
				alert_override_alert_level    => $alert_override_alert_level, 
			}});
			if (($alert_override_host_uuid eq $host_uuid) && ($alert_override_recipient_uuid eq $recipient_uuid))
			{
				$anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{level_on_host} = $alert_override_alert_level;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"recipients::recipient_uuid::${recipient_uuid}::level_on_host" => $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{level_on_host}, 
				}});
				last;
			}
		}
	}
	
	return(0);
}


=head2 get_server_uuid_from_string

This takes a string and uses it to look for an server UUID. This string can being either a UUID or the server's name. The matched C<< server_uuid >> is returned, if found. If no match is found, and empty string is returned.

This is meant to handle '--server' switches.

Parameters;

=head3 string

This is the string to search for.

=cut
sub get_server_uuid_from_string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_server_uuid_from_string()" }});

	my $string = defined $parameter->{string} ? $parameter->{string} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		string => $string,
	}});

	# Nothing to do unless we were called with a string.
	if (not $string)
	{
		return("");
	}

	$anvil->Database->get_servers({debug => $debug});
	foreach my $server_uuid (sort {$a cmp $b} keys %{$anvil->data->{servers}{server_uuid}})
	{
		my $server_name = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			server_uuid => $server_uuid,
			server_name => $server_name,
		}});

		if (($string eq $server_uuid) or
		    ($string eq $server_name))
		{
			return($server_uuid);
		}
	}

	return("");
}


=head2 get_servers

This loads all known servers from the database, including the corresponding C<< server_definition_xml >> from the C<< server_definitions >> table. 

 servers::server_uuid::<server_uuid>::server_name
 servers::server_uuid::<server_uuid>::server_anvil_uuid
 servers::server_uuid::<server_uuid>::server_user_stop
 servers::server_uuid::<server_uuid>::server_start_after_server_uuid
 servers::server_uuid::<server_uuid>::server_start_delay
 servers::server_uuid::<server_uuid>::server_host_uuid
 servers::server_uuid::<server_uuid>::server_state                    NOTE: This is set to 'DELETED' for deleted servers
 servers::server_uuid::<server_uuid>::server_live_migration
 servers::server_uuid::<server_uuid>::server_pre_migration_file_uuid
 servers::server_uuid::<server_uuid>::server_pre_migration_arguments
 servers::server_uuid::<server_uuid>::server_post_migration_file_uuid
 servers::server_uuid::<server_uuid>::server_post_migration_arguments
 servers::server_uuid::<server_uuid>::server_ram_in_use
 servers::server_uuid::<server_uuid>::server_configured_ram
 servers::server_uuid::<server_uuid>::server_updated_by_user
 servers::server_uuid::<server_uuid>::server_boot_time
 servers::server_uuid::<server_uuid>::server_definition_uuid
 servers::server_uuid::<server_uuid>::server_definition_xml
 
To simplify lookup of server UUIDs by server names, this hash is also set;

 servers::anvil_uuid::<anvil_uuid>::server_name::<server_name>::server_uuid

This method takes no parameters.

=cut
sub get_servers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_servers()" }});
	
	# Delete any data from past scans.
	delete $anvil->data->{servers}{server_uuid};
	delete $anvil->data->{sys}{servers}{by_uuid};
	delete $anvil->data->{sys}{servers}{by_name};
	
	my $query = "
SELECT 
    a.server_uuid, 
    a.server_name, 
    a.server_anvil_uuid, 
    a.server_user_stop, 
    a.server_start_after_server_uuid, 
    a.server_start_delay, 
    a.server_host_uuid, 
    a.server_state, 
    a.server_live_migration, 
    a.server_pre_migration_file_uuid, 
    a.server_pre_migration_arguments, 
    a.server_post_migration_file_uuid, 
    a.server_post_migration_arguments, 
    a.server_ram_in_use, 
    a.server_configured_ram, 
    a.server_updated_by_user, 
    a.server_boot_time, 
    b.server_definition_uuid, 
    b.server_definition_xml 
FROM 
    servers a,
    server_definitions b 
WHERE 
    a.server_uuid = b.server_definition_server_uuid
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
		my $server_uuid                     =         $row->[0];
		my $server_name                     =         $row->[1];
		my $server_anvil_uuid               =         $row->[2]; 
		my $server_user_stop                =         $row->[3]; 
		my $server_start_after_server_uuid  = defined $row->[4]  ? $row->[4]  : 'NULL'; 
		my $server_start_delay              =         $row->[5]; 
		my $server_host_uuid                = defined $row->[6]  ? $row->[6]  : 'NULL'; 
		my $server_state                    =         $row->[7]; 
		my $server_live_migration           =         $row->[8]; 
		my $server_pre_migration_file_uuid  = defined $row->[9]  ? $row->[9]  : 'NULL'; 
		my $server_pre_migration_arguments  =         $row->[10]; 
		my $server_post_migration_file_uuid = defined $row->[11] ? $row->[11] : 'NULL'; 
		my $server_post_migration_arguments =         $row->[12]; 
		my $server_ram_in_use               =         $row->[13];
		my $server_configured_ram           =         $row->[14];
		my $server_updated_by_user          =         $row->[15];
		my $server_boot_time                =         $row->[16];
		my $server_definition_uuid          =         $row->[17];
		my $server_definition_xml           =         $row->[18];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's01:server_uuid'                     => $server_uuid,
			's02:server_name'                     => $server_name, 
			's03:server_anvil_uuid'               => $server_anvil_uuid, 
			's04:server_user_stop'                => $server_user_stop, 
			's05:server_start_after_server_uuid'  => $server_start_after_server_uuid, 
			's06:server_start_delay'              => $server_start_delay, 
			's07:server_host_uuid'                => $server_host_uuid, 
			's08:server_state'                    => $server_state, 
			's09:server_live_migration'           => $server_live_migration, 
			's10:server_pre_migration_file_uuid'  => $server_pre_migration_file_uuid, 
			's11:server_pre_migration_arguments'  => $server_pre_migration_arguments, 
			's12:server_post_migration_file_uuid' => $server_post_migration_file_uuid, 
			's13:server_post_migration_arguments' => $server_post_migration_arguments, 
			's14:server_ram_in_use'               => $server_ram_in_use,
			's15:server_configured_ram'           => $server_configured_ram, 
			's16:server_updated_by_user'          => $server_updated_by_user, 
			's17:server_boot_time'                => $server_boot_time, 
			's18:server_definition_uuid'          => $server_definition_uuid, 
			's19:server_definition_xml'           => $server_definition_xml, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_name}                     = $server_name;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_anvil_uuid}               = $server_anvil_uuid;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_user_stop}                = $server_user_stop;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_after_server_uuid}  = $server_start_after_server_uuid;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_delay}              = $server_start_delay;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_host_uuid}                = $server_host_uuid;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_state}                    = $server_state;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration}           = $server_live_migration;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_file_uuid}  = $server_pre_migration_file_uuid;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_arguments}  = $server_pre_migration_arguments;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_file_uuid} = $server_post_migration_file_uuid;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_arguments} = $server_post_migration_arguments;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_ram_in_use}               = $server_ram_in_use;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_configured_ram}           = $server_configured_ram;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_updated_by_user}          = $server_updated_by_user;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_boot_time}                = $server_boot_time;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_definition_uuid}          = $server_definition_uuid;
		$anvil->data->{servers}{server_uuid}{$server_uuid}{server_definition_xml}           = $server_definition_xml;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"servers::server_uuid::${server_uuid}::server_anvil_uuid"               => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_anvil_uuid}, 
			"servers::server_uuid::${server_uuid}::server_user_stop"                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_user_stop}, 
			"servers::server_uuid::${server_uuid}::server_start_after_server_uuid"  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_after_server_uuid}, 
			"servers::server_uuid::${server_uuid}::server_start_delay"              => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_delay}, 
			"servers::server_uuid::${server_uuid}::server_host_uuid"                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_host_uuid}, 
			"servers::server_uuid::${server_uuid}::server_state"                    => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state}, 
			"servers::server_uuid::${server_uuid}::server_live_migration"           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration}, 
			"servers::server_uuid::${server_uuid}::server_pre_migration_file_uuid"  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_file_uuid}, 
			"servers::server_uuid::${server_uuid}::server_pre_migration_arguments"  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_arguments}, 
			"servers::server_uuid::${server_uuid}::server_post_migration_file_uuid" => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_file_uuid}, 
			"servers::server_uuid::${server_uuid}::server_post_migration_arguments" => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_arguments}, 
			"servers::server_uuid::${server_uuid}::server_ram_in_use"               => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_ram_in_use}, 
			"servers::server_uuid::${server_uuid}::server_configured_ram"           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_configured_ram}, 
			"servers::server_uuid::${server_uuid}::server_updated_by_user"          => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_updated_by_user}, 
			"servers::server_uuid::${server_uuid}::server_boot_time"                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_boot_time}, 
			"servers::server_uuid::${server_uuid}::server_definition_uuid"          => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_definition_uuid}, 
			"servers::server_uuid::${server_uuid}::server_definition_xml"           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_definition_xml}, 
		}});
		
		# Store the servers in a hash by name and under each Anvil!, sortable.
		$anvil->data->{servers}{anvil_uuid}{$server_anvil_uuid}{server_name}{$server_name}{server_uuid} = $server_uuid;
		$anvil->data->{servers}{server_name}{$server_name}{server_uuid}                                 = $server_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"servers::anvil_uuid::${server_anvil_uuid}::server_name::${server_name}::server_uuid" => $anvil->data->{servers}{anvil_uuid}{$server_anvil_uuid}{server_name}{$server_name}{server_uuid}, 
			"servers::server_name::${server_name}::server_uuid"                                   => $anvil->data->{servers}{server_name}{$server_name}{server_uuid}, 
		}});
	}
	
	return(0);
}


=head2 get_server_definitions

This loads all known server definition records from the database.

Data is stored in two formats;

 server_definitions::server_definition_uuid::<server_definition_uuid>::server_definition_server_uuid
 server_definitions::server_definition_uuid::<server_definition_uuid>::server_definition_xml
 server_definitions::server_definition_uuid::<server_definition_uuid>::unix_modified_time

And;

 server_definitions::server_definition_server_uuid::<server_definition_server_uuid>::$server_definition_uuid
 server_definitions::server_definition_server_uuid::<server_definition_server_uuid>::server_definition_xml
 server_definitions::server_definition_server_uuid::<server_definition_server_uuid>::unix_modified_time

Parameters;

=head3 server_uuid (optional)

If passed, the definition for the specific server is loaded. Without this, all are loaded.

=cut
sub get_server_definitions
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_server_definitions()" }});
	
	my $server_uuid = defined $parameter->{server_uuid} ? $parameter->{server_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server_uuid => $server_uuid, 
	}});
	
	if (exists $anvil->data->{server_definitions})
	{
		delete $anvil->data->{server_definitions};
	}
	
	my $host_uuid = $anvil->Get->host_uuid();
	my $query     = "
SELECT 
    server_definition_uuid,
    server_definition_server_uuid,
    server_definition_xml,
    round(extract(epoch from modified_date)) AS mtime 
FROM 
    server_definitions
";
	if ($server_uuid)
	{
		$query .= "WHERE 
    server_definition_server_uuid = ".$anvil->Database->quote($server_uuid)." ";
	}
	$query .= "
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
		my $server_definition_uuid        = $row->[0];
		my $server_definition_server_uuid = $row->[1];
		my $server_definition_xml         = $row->[2];
		my $unix_modified_time            = $row->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			server_definition_uuid        => $server_definition_uuid, 
			server_definition_server_uuid => $server_definition_server_uuid, 
			server_definition_xml         => $server_definition_xml, 
			unix_modified_time            => $unix_modified_time, 
		}});
		
		# Store the data
		$anvil->data->{server_definitions}{server_definition_uuid}{$server_definition_uuid}{server_definition_server_uuid} = $server_definition_server_uuid;
		$anvil->data->{server_definitions}{server_definition_uuid}{$server_definition_uuid}{server_definition_xml}         = $server_definition_xml;
		$anvil->data->{server_definitions}{server_definition_uuid}{$server_definition_uuid}{unix_modified_time}            = $unix_modified_time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server_definitions::server_definition_uuid::${server_definition_uuid}::server_definition_server_uuid" => $anvil->data->{server_definitions}{server_definition_uuid}{$server_definition_uuid}{server_definition_server_uuid}, 
			"server_definitions::server_definition_uuid::${server_definition_uuid}::server_definition_xml"         => $anvil->data->{server_definitions}{server_definition_uuid}{$server_definition_uuid}{server_definition_xml}, 
			"server_definitions::server_definition_uuid::${server_definition_uuid}::unix_modified_time"            => $anvil->data->{server_definitions}{server_definition_uuid}{$server_definition_uuid}{unix_modified_time}, 
		}});
		
		# Make it easy to locate records by 'server_uuid' as well.
		$anvil->data->{server_definitions}{server_definition_server_uuid}{$server_definition_server_uuid}{server_definition_uuid} = $server_definition_uuid;
		$anvil->data->{server_definitions}{server_definition_server_uuid}{$server_definition_server_uuid}{server_definition_xml}  = $server_definition_xml;
		$anvil->data->{server_definitions}{server_definition_server_uuid}{$server_definition_server_uuid}{unix_modified_time}     = $unix_modified_time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server_definitions::server_definition_server_uuid::${server_definition_server_uuid}::$server_definition_uuid" => $anvil->data->{server_definitions}{server_definition_server_uuid}{$server_definition_server_uuid}{server_definition_uuid}, 
			"server_definitions::server_definition_server_uuid::${server_definition_server_uuid}::server_definition_xml"   => $anvil->data->{server_definitions}{server_definition_server_uuid}{$server_definition_server_uuid}{server_definition_xml}, 
			"server_definitions::server_definition_server_uuid::${server_definition_server_uuid}::unix_modified_time"      => $anvil->data->{server_definitions}{server_definition_server_uuid}{$server_definition_server_uuid}{unix_modified_time}, 
		}});
	}
	
	return(0);
}


=head2 get_storage_group_data

This loads the C<< storage_groups >> and C<< storage_group_members >> data. 

The group name is stored as:

* storage_groups::anvil_uuid::<anvil_uuid>::storage_group_uuid::<storage_group_uuid>::group_name

And group members are stored as:

* storage_groups::anvil_uuid::<anvil_uuid>::storage_group_uuid::<storage_group_uuid>::host_uuid::<host_uuid>::vg_uuid::<vg_uuid>::storage_group_member_uuid

B<< Note >>: The C<< vg_uuid >> is the UUID stored in the volume group itself. This is called a 'UUID', but it is not a valid UUID format string. So be sure to treat it as a unique text string, and not a UUID proper.

To simplify finding if a VG is in a group, the following hash is also set;

* storage_groups::vg_uuid::<vg_uuid>::storage_group_uuid

This method takes no parameters.

=cut
sub get_storage_group_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->storage_group_data()" }});
	
	my $scan_lvm_exists = 0;
	my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename='scan_lvm_vgs' AND schemaname='public';";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
	
	if ($count)
	{
		$scan_lvm_exists = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { scan_lvm_exists => $scan_lvm_exists }});
	}
	
	# Loads hosts, if it hasn't been before.
	if (not exists $anvil->data->{hosts}{host_uuid})
	{
		$anvil->Database->get_hosts({debug => $debug});
	}

	$query = "
SELECT 
    a.storage_group_uuid, 
    a.storage_group_anvil_uuid,
    a.storage_group_name,  
    b.storage_group_member_uuid, 
    b.storage_group_member_host_uuid, 
    b.storage_group_member_vg_uuid,
    b.storage_group_member_note
FROM 
    storage_groups a, 
    storage_group_members b 
WHERE 
    a.storage_group_uuid = b.storage_group_member_storage_group_uuid 
ORDER BY 
    a.storage_group_anvil_uuid ASC
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	   $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $storage_group_uuid             = $row->[0];
		my $storage_group_anvil_uuid       = $row->[1];
		my $storage_group_name             = $row->[2];
		my $storage_group_member_uuid      = $row->[3];
		my $storage_group_member_host_uuid = $row->[4];
		my $storage_group_member_vg_uuid   = $row->[5];		# This is the VG's internal UUID
		my $storage_group_member_note      = $row->[6];		# If this is 'DELETED', the link isn't used anymore
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			storage_group_uuid             => $storage_group_uuid, 
			storage_group_anvil_uuid       => $storage_group_anvil_uuid, 
			storage_group_name             => $storage_group_name, 
			storage_group_member_uuid      => $storage_group_member_uuid, 
			storage_group_member_host_uuid => $storage_group_member_host_uuid, 
			storage_group_member_vg_uuid   => $storage_group_member_vg_uuid, 
			storage_group_member_note      => $storage_group_member_note,
		}});
		
		if (not exists $anvil->data->{hosts}{host_uuid}{$storage_group_member_host_uuid})
		{
			$anvil->Database->get_hosts({debug => $debug});
		}
		my $storage_group_member_host_name = $anvil->data->{hosts}{host_uuid}{$storage_group_member_host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			storage_group_member_host_name => $storage_group_member_host_name,
		}});
		
		# Store the data
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name}                                                            = $storage_group_name;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{short_host_name}{$storage_group_member_host_name}{host_uuid}           = $storage_group_member_host_uuid;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{storage_group_member_uuid} = $storage_group_member_uuid;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_internal_uuid}          = $storage_group_member_vg_uuid;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_size}                   = 0;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free}                   = 0;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{storage_group_member_note} = $storage_group_member_note;
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space}                                                            = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::group_name"                                                              => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name}, 
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::short_host_name::${storage_group_member_host_name}::host_uuid"           => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{short_host_name}{$storage_group_member_host_name}{host_uuid},
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::storage_group_member_uuid" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{storage_group_member_uuid},
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::vg_size"                   => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_size}}).")",
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::vg_free"                   => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free}}).")",
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::storage_group_member_note" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{storage_group_member_note},
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::free_space"                                                              => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space}, 
		}});

		# Make it easier to use the VG UUID to find the storage_group_uuid.
		$anvil->data->{storage_groups}{vg_uuid}{$storage_group_member_vg_uuid}{storage_group_uuid} = $storage_group_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"storage_groups::vg_uuid::${storage_group_member_vg_uuid}::storage_group_uuid" => $anvil->data->{storage_groups}{vg_uuid}{$storage_group_member_vg_uuid}{storage_group_uuid},
		}});
		
		# Make it possible to sort the storage groups by name.
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_name}{$storage_group_name}{storage_group_uuid} = $storage_group_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_name::${storage_group_name}::storage_group_uuid}" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_name}{$storage_group_name}{storage_group_uuid},
		}});
		
		# If scan_lvm has been run, read is the free space on the VG
		if ($scan_lvm_exists)
		{
			my $query = "
SELECT 
    scan_lvm_vg_name, 
    scan_lvm_vg_size, 
    scan_lvm_vg_free 
FROM 
    scan_lvm_vgs 
WHERE 
    scan_lvm_vg_internal_uuid = ".$anvil->Database->quote($storage_group_member_vg_uuid)."
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
				$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_name} = $results->[0]->[0];
				$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_size} = $results->[0]->[1];
				$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free} = $results->[0]->[2];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::vg_name" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_name},
					"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::vg_size" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_size}}).")",
					"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::host_uuid::${storage_group_member_host_uuid}::vg_free" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free}}).")",
				}});
				
				if (($anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space} == 0) or 
				    ($anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free} < $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space}))
				{
					$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space} = $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$storage_group_member_host_uuid}{vg_free};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::free_space" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{free_space}}).")", 
					}});
				}
			}
		}
		
		# Also load the Storage group extended data.
		$anvil->Storage->get_storage_group_details({
			debug              => $debug, 
			storage_group_uuid => $storage_group_uuid, 
		});
	}
	
	# If the Anvil! members have changed, we'll need to update the storage groups. This checks for that.
	$anvil->Database->get_anvils({debug => $debug});
	foreach my $anvil_uuid (keys %{$anvil->data->{storage_groups}{anvil_uuid}})
	{
		my $anvil_name      = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name}; 
		my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_name      => $anvil_name, 
			node1_host_uuid => $node1_host_uuid, 
			node2_host_uuid => $node2_host_uuid, 
		}});
		foreach my $storage_group_uuid (keys %{$anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}})
		{
			my $group_name = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				storage_group_uuid => $storage_group_uuid, 
				group_name         => $group_name, 
			}});
			
			my $size_to_match = 0;
			my $node1_seen    = 0;
			my $node2_seen    = 0;
			foreach my $this_host_uuid (keys %{$anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}})
			{
				my $storage_group_member_uuid = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$this_host_uuid}{storage_group_member_uuid};
				my $internal_vg_uuid          = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$this_host_uuid}{vg_internal_uuid};
				my $vg_size                   = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$this_host_uuid}{vg_size};
				my $vg_name                   = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$this_host_uuid}{vg_name};
				my $host_type                 = $anvil->data->{hosts}{host_uuid}{$this_host_uuid}{host_type};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					this_host_uuid            => $this_host_uuid, 
					storage_group_member_uuid => $storage_group_member_uuid, 
					internal_vg_uuid          => $internal_vg_uuid, 
					vg_size                   => $anvil->Convert->add_commas({number => $vg_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $vg_size}).")", 
					vg_name                   => $vg_name, 
					host_type                 => $host_type, 
				}});
				
				if ($vg_name eq "DELETED")
				{
					# The volume group is gone. It could be a lost node being rebuilt. In
					# any case, can can't use it.
					next;
				}
				
				if ($vg_size > $size_to_match)
				{
					$size_to_match = $vg_size;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						size_to_match => $anvil->Convert->add_commas({number => $size_to_match})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size_to_match}).")", 
					}});
				}
				
				if ($this_host_uuid eq $node1_host_uuid)
				{
					$node1_seen = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node1_seen => $node1_seen }});
				}
				elsif ($this_host_uuid eq $node2_host_uuid)
				{
					$node2_seen = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node2_seen => $node2_seen }});
				}
				elsif ($host_type eq "node")
				{
					# This host is a node that isn't in the Anvil!, so it doesn't belong 
					# in this group anymore. Delete it.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0130", variables => { 
						storage_group_name => $group_name,
						host_name          => $anvil->Get->host_name_from_uuid({host_uuid => $this_host_uuid}),
						anvil_name         => $anvil_name, 
					}});
					
					my $query = "DELETE FROM history.storage_group_members WHERE storage_group_member_uuid = ".$anvil->Database->quote($storage_group_member_uuid).";";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
					$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
					
					$query = "DELETE FROM storage_group_members WHERE storage_group_member_uuid = ".$anvil->Database->quote($storage_group_member_uuid).";";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
					$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
				}
			}
			
			if ((not $node1_seen) or 
			    (not $node2_seen))
			{
				my $hosts  = [$node1_host_uuid, $node2_host_uuid];
				my $reload = 0;
				foreach my $this_host_uuid (@{$hosts})
				{
					# If we didn't see a host, look for a compatible VG to add.
					my $minimum_size = $size_to_match - (2**30);
					my $maximum_size = $size_to_match + (2**30);
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						minimum_size => $anvil->Convert->add_commas({number => $minimum_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $minimum_size}).")", 
						maximum_size => $anvil->Convert->add_commas({number => $maximum_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $maximum_size}).")", 
					}});
					
					my $smallest_difference      =  (2**30);
					my $closest_internal_uuid    =  "";
					my $closest_scan_lvm_vg_uuid =  "";
					my $quoted_minimum_size      =  $anvil->Database->quote($minimum_size);
					   $quoted_minimum_size      =~ s/^'(.*)'$/$1/;
					my $quoted_maximum_size      =  $anvil->Database->quote($maximum_size);
					   $quoted_maximum_size      =~ s/^'(.*)'$/$1/;
					my $query                    =  "
SELECT 
    scan_lvm_vg_uuid, 
    scan_lvm_vg_internal_uuid, 
    scan_lvm_vg_size 
FROM 
    scan_lvm_vgs 
WHERE 
    scan_lvm_vg_size      > ".$quoted_minimum_size." 
AND 
    scan_lvm_vg_size      < ".$quoted_maximum_size." 
AND 
    scan_lvm_vg_host_uuid = ".$anvil->Database->quote($this_host_uuid)."
ORDER BY 
    scan_lvm_vg_size ASC
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
						my $scan_lvm_vg_uuid          = $row->[0];
						my $scan_lvm_vg_internal_uuid = $row->[1];
						my $scan_lvm_vg_size          = $row->[2];
						my $difference                = abs($scan_lvm_vg_size - $size_to_match);
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							scan_lvm_vg_uuid          => $scan_lvm_vg_uuid, 
							scan_lvm_vg_internal_uuid => $scan_lvm_vg_internal_uuid, 
							scan_lvm_vg_size          => $anvil->Convert->add_commas({number => $scan_lvm_vg_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_size}).")", 
							difference                => $anvil->Convert->add_commas({number => $difference})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $difference}).")", 
						}});
						
						# Is this Internal UUID already in a storage group?
						my $query = "SELECT COUNT(*) FROM storage_group_members WHERE storage_group_member_vg_uuid = ".$anvil->Database->quote($scan_lvm_vg_internal_uuid).";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
						
						my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
						if (not $count)
						{
							# This VG isn't in a storage group. Is this the closest in size yet?
							if ($difference < $smallest_difference)
							{
								# Closest yet!
								$smallest_difference      = $difference;
								$closest_scan_lvm_vg_uuid = $scan_lvm_vg_internal_uuid;
								$closest_internal_uuid    = $scan_lvm_vg_uuid;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									smallest_difference      => $anvil->Convert->add_commas({number => $smallest_difference})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $smallest_difference}).")", 
									closest_internal_uuid    => $closest_internal_uuid, 
									closest_scan_lvm_vg_uuid => $closest_scan_lvm_vg_uuid, 
								}});
							}
						}
					}
					
					# Did we find a matching VG?
					if ($closest_scan_lvm_vg_uuid)
					{
						# Yup, add it!
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0649", variables => { 
							anvil_name       => $anvil_name, 
							storage_group    => $group_name,
							host_name        => $anvil->Get->host_name_from_uuid({host_uuid => $this_host_uuid}),
							vg_internal_uuid => $closest_scan_lvm_vg_uuid, 
						}});
						
						my $storage_group_member_uuid = $anvil->Get->uuid();
						my $query                     = "
INSERT INTO 
    storage_group_members 
(
    storage_group_member_uuid, 
    storage_group_member_storage_group_uuid, 
    storage_group_member_host_uuid, 
    storage_group_member_vg_uuid, 
    storage_group_member_note, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($storage_group_member_uuid).", 
    ".$anvil->Database->quote($storage_group_uuid).", 
    ".$anvil->Database->quote($this_host_uuid).", 
    ".$anvil->Database->quote($closest_scan_lvm_vg_uuid).", 
    'auto-created',
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
						$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
						
						# Reload 
						$reload = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
					}
				}
				if ($reload)
				{
					$anvil->Database->get_storage_group_data({debug => $debug});
				}
			}
		}
	}
	
	return(0);
}


=head2 get_ssh_keys

This loads all known user's SSH public keys and all known machine's public keys into the data hash. On success, this method returns C<< 0 >>. If any problems occur, C<< 1 >> is returned.

 ssh_keys::ssh_key_uuid::<ssh_key_uuid>::ssh_key_host_uuid  = <Host UUID the user is from>
 ssh_keys::ssh_key_uuid::<ssh_key_uuid>::ssh_key_user_name  = <The user's name>
 ssh_keys::ssh_key_uuid::<ssh_key_uuid>::ssh_key_public_key = <The SSH public key>

And:

 ssh_keys::host_uuid::<ssh_key_host_uuid>::ssh_key_user_name::<ssh_key_user_name>::ssh_key_uuid       = <ssh_key_uuid entry value>
 ssh_keys::host_uuid::<ssh_key_host_uuid>::ssh_key_user_name::<ssh_key_user_name>::ssh_key_public_key = <The SSH public key>

This method takes no parameters.

=cut
sub get_ssh_keys
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_ssh_keys()" }});
	
	# Delete any data from past scans.
	delete $anvil->data->{ssh_keys}{ssh_key_uuid};
	delete $anvil->data->{sys}{ssh_keys}{by_uuid};
	delete $anvil->data->{sys}{ssh_keys}{by_name};
	
	my $query = "
SELECT 
    ssh_key_uuid, 
    ssh_key_host_uuid, 
    ssh_key_user_name, 
    ssh_key_public_key, 
    modified_date 
FROM 
    ssh_keys
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
		my $ssh_key_uuid       = $row->[0];
		my $ssh_key_host_uuid  = $row->[1];
		my $ssh_key_user_name  = $row->[2];
		my $ssh_key_public_key = $row->[3];
		my $modified_date      = $row->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			ssh_key_uuid       => $ssh_key_uuid, 
			ssh_key_host_uuid  => $ssh_key_host_uuid, 
			ssh_key_user_name  => $ssh_key_user_name, 
			ssh_key_public_key => $ssh_key_public_key, 
			modified_date      => $modified_date, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{ssh_keys}{ssh_key_uuid}{$ssh_key_uuid}{ssh_key_host_uuid}  = $ssh_key_host_uuid;
		$anvil->data->{ssh_keys}{ssh_key_uuid}{$ssh_key_uuid}{ssh_key_user_name}  = $ssh_key_user_name;
		$anvil->data->{ssh_keys}{ssh_key_uuid}{$ssh_key_uuid}{ssh_key_public_key} = $ssh_key_public_key;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"ssh_keys::ssh_key_uuid::${ssh_key_uuid}::ssh_key_host_uuid"  => $anvil->data->{ssh_keys}{ssh_key_uuid}{$ssh_key_uuid}{ssh_key_host_uuid}, 
			"ssh_keys::ssh_key_uuid::${ssh_key_uuid}::ssh_key_user_name"  => $anvil->data->{ssh_keys}{ssh_key_uuid}{$ssh_key_uuid}{ssh_key_user_name}, 
			"ssh_keys::ssh_key_uuid::${ssh_key_uuid}::ssh_key_public_key" => $anvil->data->{ssh_keys}{ssh_key_uuid}{$ssh_key_uuid}{ssh_key_public_key}, 
		}});
		
		$anvil->data->{ssh_keys}{host_uuid}{$ssh_key_host_uuid}{ssh_key_user_name}{$ssh_key_user_name}{ssh_key_uuid}       = $ssh_key_uuid;
		$anvil->data->{ssh_keys}{host_uuid}{$ssh_key_host_uuid}{ssh_key_user_name}{$ssh_key_user_name}{ssh_key_public_key} = $ssh_key_public_key;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"ssh_keys::host_uuid::${ssh_key_host_uuid}::ssh_key_user_name::${ssh_key_user_name}::ssh_key_uuid"       => $anvil->data->{ssh_keys}{host_uuid}{$ssh_key_host_uuid}{ssh_key_user_name}{$ssh_key_user_name}{ssh_key_uuid}, 
			"ssh_keys::host_uuid::${ssh_key_host_uuid}::ssh_key_user_name::${ssh_key_user_name}::ssh_key_public_key" => $anvil->data->{ssh_keys}{host_uuid}{$ssh_key_host_uuid}{ssh_key_user_name}{$ssh_key_user_name}{ssh_key_public_key}, 
		}});
	}
	
	return(0);
}


=head2 get_tables_from_schema

This reads in a schema file and generates an array of tables. The array contains the tables in the order they are found in the schema. If there is a problem, C<< !!error!! >> is returned. On success, an array reference is returned.

Parameters;

=head3 schema_file (required)

This is the full path to a SQL schema file to look for tables in. If set to C<< all >>, then C<< path::sql::anvil.sql >> will be used, as well schema for all scan agents.

=cut
sub get_tables_from_schema
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_tables_from_schema()" }});
	
	my $tables      = [];
	my $schema_file = defined $parameter->{schema_file} ? $parameter->{schema_file} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		schema_file => $schema_file, 
	}});
	
	if (not $schema_file)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->get_tables_from_schema()", parameter => "schema_file" }});
		return("!!error!!");
	}
	
	my $schema = "";
	if ($schema_file eq "all")
	{
		# We're loading all schema files. Main first
		$schema = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{sql}{'anvil.sql'}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { schema => $schema }});
		
		$anvil->ScanCore->_scan_directory({
			debug     => $debug, 
			directory => $anvil->data->{path}{directories}{scan_agents},
		});
		
		# Now all agents
		foreach my $agent_name (sort {$a cmp $b} keys %{$anvil->data->{scancore}{agent}})
		{
			my $sql_path = $anvil->data->{scancore}{agent}{$agent_name}.".sql";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				agent_name => $agent_name, 
				sql_path   => $sql_path,
			}});
			if (not -e $sql_path)
			{
				next;
			}
			$schema .= $anvil->Storage->read_file({debug => $debug, file => $sql_path});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { schema => $schema }});
		}
	}
	else
	{
		$schema = $anvil->Storage->read_file({debug => $debug, file => $schema_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { schema => $schema }});
	}
	
	if ($schema eq "!!error!!")
	{
		return("!!error!!");
	}
	
	foreach my $line (split/\n/, $schema)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		$line =~ s/--.*$//;
		
		if ($line =~ /CREATE TABLE history\.(.*?) \(/)
		{
			my $table = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
			
			$anvil->data->{sys}{database}{history_table}{$table} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::history_table::${table}" => $anvil->data->{sys}{database}{history_table}{$table},
			}});
		}
		elsif ($line =~ /CREATE TABLE (.*?) \(/i)
		{
			my $table = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
			push @{$tables}, $table;
			
			if (not exists $anvil->data->{sys}{database}{history_table}{$table})
			{
				$anvil->data->{sys}{database}{history_table}{$table} = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::history_table::${table}" => $anvil->data->{sys}{database}{history_table}{$table},
				}});
			}
		}
	}
	
	# Store the tables in 'sys::database::check_tables'
	$anvil->data->{sys}{database}{check_tables} = $tables;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		tables                        => $tables,
		'sys::database::check_tables' => $anvil->data->{sys}{database}{check_tables}, 
	}});
	
	my $table_count = @{$tables};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table_count => $table_count }});
	
	return($tables);
}


=head2 get_power

This loads the special C<< power >> table, which complements the C<< upses >> table. This helps ScanCore determine when nodes need to shut down or can be power back up during power events.

* power::power_uuid::<power_uuid>::power_ups_uuid
* power::power_uuid::<power_uuid>::power_on_battery
* power::power_uuid::<power_uuid>::power_seconds_left
* power::power_uuid::<power_uuid>::power_charge_percentage
* power::power_uuid::<power_uuid>::modified_date_unix

And, to allow for lookup by name;

* power::power_ups_uuid::<power_ups_uuid>::power_uuid
* power::power_ups_uuid::<power_ups_uuid>::power_on_battery
* power::power_ups_uuid::<power_ups_uuid>::power_seconds_left
* power::power_ups_uuid::<power_ups_uuid>::power_charge_percentage
* power::power_ups_uuid::<power_ups_uuid>::modified_date_unix

B<< Note >>: The C<< modified_date >> is cast as a unix time stamp.

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

This method takes no parameters.

=cut
sub get_power
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_power()" }});
	
	if (exists $anvil->data->{power})
	{
		delete $anvil->data->{power};
	}
	
	my $query = "
SELECT 
    power_uuid, 
    power_ups_uuid, 
    power_on_battery, 
    power_seconds_left, 
    power_charge_percentage, 
    modified_date, 
    round(extract(epoch from modified_date)) 
FROM 
    power 
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
		my $power_uuid              = $row->[0];
		my $power_ups_uuid          = $row->[1];
		my $power_on_battery        = $row->[2];
		my $power_seconds_left      = $row->[3]; 
		my $power_charge_percentage = $row->[4];
		my $modified_date           = $row->[5];
		my $modified_date_unix      = $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			power_uuid              => $power_uuid, 
			power_ups_uuid          => $power_ups_uuid, 
			power_on_battery        => $power_on_battery, 
			power_seconds_left      => $power_seconds_left, 
			power_charge_percentage => $power_charge_percentage, 
			modified_date           => $modified_date, 
			modified_date_unix      => $modified_date_unix, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{power}{power_uuid}{$power_uuid}{power_ups_uuid}          = $power_ups_uuid;
		$anvil->data->{power}{power_uuid}{$power_uuid}{power_on_battery}        = $power_on_battery;
		$anvil->data->{power}{power_uuid}{$power_uuid}{power_seconds_left}      = $power_seconds_left;
		$anvil->data->{power}{power_uuid}{$power_uuid}{power_charge_percentage} = $power_charge_percentage;
		$anvil->data->{power}{power_uuid}{$power_uuid}{modified_date}           = $modified_date;
		$anvil->data->{power}{power_uuid}{$power_uuid}{modified_date_unix}      = $modified_date_unix;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"power::power_uuid::${power_uuid}::power_ups_uuid"          => $anvil->data->{power}{power_uuid}{$power_uuid}{power_ups_uuid}, 
			"power::power_uuid::${power_uuid}::power_on_battery"        => $anvil->data->{power}{power_uuid}{$power_uuid}{power_on_battery}, 
			"power::power_uuid::${power_uuid}::power_seconds_left"      => $anvil->data->{power}{power_uuid}{$power_uuid}{power_seconds_left}, 
			"power::power_uuid::${power_uuid}::power_charge_percentage" => $anvil->data->{power}{power_uuid}{$power_uuid}{power_charge_percentage}, 
			"power::power_uuid::${power_uuid}::modified_date"           => $anvil->data->{power}{power_uuid}{$power_uuid}{modified_date}, 
			"power::power_uuid::${power_uuid}::modified_date_unix"      => $anvil->data->{power}{power_uuid}{$power_uuid}{modified_date_unix}, 
		}});
		
		$anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_uuid}              = $power_uuid;
		$anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_on_battery}        = $power_on_battery;
		$anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_seconds_left}      = $power_seconds_left;
		$anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_charge_percentage} = $power_charge_percentage;
		$anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{modified_date}           = $modified_date;
		$anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{modified_date_unix}      = $modified_date_unix;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"power::power_ups_uuid::${power_ups_uuid}::power_uuid"              => $anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_uuid}, 
			"power::power_ups_uuid::${power_ups_uuid}::power_on_battery"        => $anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_on_battery}, 
			"power::power_ups_uuid::${power_ups_uuid}::power_seconds_left"      => $anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_seconds_left}, 
			"power::power_ups_uuid::${power_ups_uuid}::power_charge_percentage" => $anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{power_charge_percentage}, 
			"power::power_ups_uuid::${power_ups_uuid}::modified_date"           => $anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{modified_date}, 
			"power::power_ups_uuid::${power_ups_uuid}::modified_date_unix"      => $anvil->data->{power}{power_ups_uuid}{$power_ups_uuid}{modified_date_unix}, 
		}});
	}

	return(0);
}


=head2 get_upses

This loads the known UPSes (uninterruptible power supplies) into the C<< anvil::data >> hash at:

* upses::ups_uuid::<ups_uuid>::ups_name
* upses::ups_uuid::<ups_uuid>::ups_agent
* upses::ups_uuid::<ups_uuid>::ups_ip_address
* upses::ups_uuid::<ups_uuid>::modified_date
* upses::ups_uuid::<ups_uuid>::power_uuid

And, to allow for lookup by name;

* upses::ups_name::<ups_name>::ups_uuid
* upses::ups_name::<ups_name>::ups_agent
* upses::ups_name::<ups_name>::ups_ip_address
* upses::ups_name::<ups_name>::modified_date
* upses::ups_name::<ups_name>::power_uuid

If the hash was already populated, it is cleared before repopulating to ensure no stale data remains. 

B<<Note>>: Deleted devices (ones where C<< ups_ip_address >> is set to C<< DELETED >>) are ignored. See the C<< include_deleted >> parameter to include them.

B<< Note>>: If a scan agent has scanned this UPS, it's power state information will be stored in the C<< power >> table. If a matching record is found, the C<< power_uuid >> will be stored in the C<< ...::power_uuid >> hash references. For this linking to work, this method will call C<< Database->get_power >>.

Parameters;

=head3 include_deleted (Optional, default 0)

If set to C<< 1 >>, deleted agents are included when loading the data. When C<< 0 >> is set, the default, any ups agent with C<< ups_ip_address >> set to C<< DELETED >> is ignored.

=cut
sub get_upses
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_upses()" }});
	
	my $include_deleted = defined $parameter->{include_deleted} ? $parameter->{include_deleted} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		include_deleted => $include_deleted, 
	}});
	
	if (exists $anvil->data->{upses})
	{
		delete $anvil->data->{upses};
	}
	
	# Load the power data.
	$anvil->Database->get_power({debug => $debug});
	
	my $query = "
SELECT 
    ups_uuid, 
    ups_name, 
    ups_agent, 
    ups_ip_address, 
    modified_date, 
    round(extract(epoch from modified_date)) 
FROM 
    upses ";
	if (not $include_deleted)
	{
		$query .= "
WHERE 
    ups_ip_address != 'DELETED'";
	}
	$query .= "
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
		my $ups_uuid           = $row->[0];
		my $ups_name           = $row->[1];
		my $ups_agent          = $row->[2];
		my $ups_ip_address     = $row->[3]; 
		my $modified_date      = $row->[4];
		my $modified_date_unix = $row->[5];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			ups_uuid           => $ups_uuid, 
			ups_name           => $ups_name, 
			ups_agent          => $ups_agent, 
			ups_ip_address     => $ups_ip_address, 
			modified_date      => $modified_date, 
			modified_date_unix => $modified_date_unix, 
		}});
		
		# Record the data in the hash, too.
		$anvil->data->{upses}{ups_uuid}{$ups_uuid}{ups_name}           = $ups_name;
		$anvil->data->{upses}{ups_uuid}{$ups_uuid}{ups_agent}          = $ups_agent;
		$anvil->data->{upses}{ups_uuid}{$ups_uuid}{ups_ip_address}     = $ups_ip_address;
		$anvil->data->{upses}{ups_uuid}{$ups_uuid}{modified_date}      = $modified_date;
		$anvil->data->{upses}{ups_uuid}{$ups_uuid}{modified_date_unix} = $modified_date_unix;
		$anvil->data->{upses}{ups_uuid}{$ups_uuid}{power_uuid}         = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"upses::ups_uuid::${ups_uuid}::ups_name"           => $anvil->data->{upses}{ups_uuid}{$ups_uuid}{ups_name}, 
			"upses::ups_uuid::${ups_uuid}::ups_agent"          => $anvil->data->{upses}{ups_uuid}{$ups_uuid}{ups_agent}, 
			"upses::ups_uuid::${ups_uuid}::ups_ip_address"     => $anvil->data->{upses}{ups_uuid}{$ups_uuid}{ups_ip_address}, 
			"upses::ups_uuid::${ups_uuid}::modified_date"      => $anvil->data->{upses}{ups_uuid}{$ups_uuid}{modified_date}, 
			"upses::ups_uuid::${ups_uuid}::modified_date_unix" => $anvil->data->{upses}{ups_uuid}{$ups_uuid}{modified_date_unix}, 
		}});
		
		$anvil->data->{upses}{ups_name}{$ups_name}{ups_uuid}           = $ups_uuid;
		$anvil->data->{upses}{ups_name}{$ups_name}{ups_agent}          = $ups_agent;
		$anvil->data->{upses}{ups_name}{$ups_name}{ups_ip_address}     = $ups_ip_address;
		$anvil->data->{upses}{ups_name}{$ups_name}{modified_date}      = $modified_date;
		$anvil->data->{upses}{ups_name}{$ups_name}{modified_date_unix} = $modified_date;
		$anvil->data->{upses}{ups_name}{$ups_name}{power_uuid}         = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"upses::ups_name::${ups_name}::ups_uuid"           => $anvil->data->{upses}{ups_name}{$ups_name}{ups_uuid}, 
			"upses::ups_name::${ups_name}::ups_agent"          => $anvil->data->{upses}{ups_name}{$ups_name}{ups_agent}, 
			"upses::ups_name::${ups_name}::ups_ip_address"     => $anvil->data->{upses}{ups_name}{$ups_name}{ups_ip_address}, 
			"upses::ups_name::${ups_name}::modified_date"      => $anvil->data->{upses}{ups_name}{$ups_name}{modified_date}, 
			"upses::ups_name::${ups_name}::modified_date_unix" => $anvil->data->{upses}{ups_name}{$ups_name}{modified_date_unix}, 
		}});
		
		# Collect power information from 'power'.
		if (exists $anvil->data->{power}{power_ups_uuid}{$ups_uuid})
		{
			my $power_uuid = $anvil->data->{power}{power_ups_uuid}{$ups_uuid}{power_uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { power_uuid => $power_uuid }});
			
			$anvil->data->{upses}{ups_uuid}{$ups_uuid}{power_uuid} = $power_uuid;
			$anvil->data->{upses}{ups_name}{$ups_name}{power_uuid} = $power_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"upses::ups_uuid::${ups_uuid}::power_ups_uuid" => $anvil->data->{upses}{ups_uuid}{$ups_uuid}{power_ups_uuid}, 
				"upses::ups_name::${ups_name}::power_ups_uuid" => $anvil->data->{upses}{ups_name}{$ups_name}{power_ups_uuid}, 
			}});
		}
	}

	return(0);
}


=head2 get_variables

This method loads the C<< variables >> table data into memory.

If the record does NOT have a C<< variable_source_table >>, the data will be stored in the hash;

* variables::variable_uuid::<variable_uuid>::global::variable_name        = <variable_name>
* variables::variable_uuid::<variable_uuid>::global::variable_value       = <variable_value>
* variables::variable_uuid::<variable_uuid>::global::variable_default     = <variable_default>
* variables::variable_uuid::<variable_uuid>::global::variable_description = <variable_description> (this is a string key)
* variables::variable_uuid::<variable_uuid>::global::modified_date        = <modified_date>        (this is a plain text english date and time)
* variables::variable_uuid::<variable_uuid>::global::modified_date_unix   = <modified_date_unix>   (this is the unix time stamp)

If there is a source table, then the data is stored in the hash;

* variables::source_table::<source_table>::source_uuid::<source_uuid>::variable_uuid::<variable_uuid>::variable_name        = <variable_name>
* variables::source_table::<source_table>::source_uuid::<source_uuid>::variable_uuid::<variable_uuid>::variable_value       = <variable_value>
* variables::source_table::<source_table>::source_uuid::<source_uuid>::variable_uuid::<variable_uuid>::variable_default     = <variable_default>
* variables::source_table::<source_table>::source_uuid::<source_uuid>::variable_uuid::<variable_uuid>::variable_description = <variable_description> (this is a string key)
* variables::source_table::<source_table>::source_uuid::<source_uuid>::variable_uuid::<variable_uuid>::modified_date        = <modified_date>        (this is a plain text english date and time)
* variables::source_table::<source_table>::source_uuid::<source_uuid>::variable_uuid::<variable_uuid>::modified_date_unix   = <modified_date_unix>   (this is the unix time stamp)

This method takes no parameters.

=cut
sub get_variables
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_variables()" }});
	
	
	if (exists $anvil->data->{variables})
	{
		delete $anvil->data->{variables};
	}
	
	# Load the power data.
	$anvil->Database->get_hosts({debug => $debug});
	
	my $query = "
SELECT 
    variable_uuid, 
    variable_name, 
    variable_value, 
    variable_default, 
    variable_description, 
    variable_section, 
    variable_source_uuid, 
    variable_source_table, 
    modified_date, 
    round(extract(epoch from modified_date)) 
FROM 
    variables 
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
		my $variable_uuid         =         $row->[0];
		my $variable_name         =         $row->[1];
		my $variable_value        =         $row->[2];
		my $variable_default      =         $row->[3];
		my $variable_description  =         $row->[4];
		my $variable_section      =         $row->[5];
		my $variable_source_uuid  = defined $row->[6] ? $row->[6] : "";
		my $variable_source_table =         $row->[7]; 
		my $modified_date         =         $row->[8];
		my $modified_date_unix    =         $row->[9];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			variable_uuid         => $variable_uuid, 
			variable_name         => $variable_name, 
			variable_value        => $variable_value, 
			variable_default      => $variable_default, 
			variable_description  => $variable_description, 
			variable_section      => $variable_section, 
			variable_source_uuid  => $variable_source_uuid, 
			variable_source_table => $variable_source_table, 
			modified_date         => $modified_date, 
			modified_date_unix    => $modified_date_unix, 
		}});
		
		if ($variable_source_table)
		{
			# Store it under the associated table
			$variable_source_uuid = "--" if not $variable_source_uuid;	# This should never be needed, but just in case...
			$anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_name}        = $variable_name;
			$anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_value}       = $variable_value;
			$anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_default}     = $variable_default;
			$anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_description} = $variable_description;
			$anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{modified_date}        = $modified_date;
			$anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{modified_date_unix}   = $modified_date_unix;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"variables::source_table::${variable_source_table}::source_uuid::${variable_source_uuid}::variable_uuid::${variable_uuid}::variable_name"        => $anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_name}, 
				"variables::source_table::${variable_source_table}::source_uuid::${variable_source_uuid}::variable_uuid::${variable_uuid}::variable_value"       => $anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_value}, 
				"variables::source_table::${variable_source_table}::source_uuid::${variable_source_uuid}::variable_uuid::${variable_uuid}::variable_default"     => $anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_default}, 
				"variables::source_table::${variable_source_table}::source_uuid::${variable_source_uuid}::variable_uuid::${variable_uuid}::variable_description" => $anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{variable_description}, 
				"variables::source_table::${variable_source_table}::source_uuid::${variable_source_uuid}::variable_uuid::${variable_uuid}::modified_date"        => $anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{modified_date}, 
				"variables::source_table::${variable_source_table}::source_uuid::${variable_source_uuid}::variable_uuid::${variable_uuid}::modified_date_unix"   => $anvil->data->{variables}{source_table}{$variable_source_table}{source_uuid}{$variable_source_uuid}{variable_uuid}{$variable_uuid}{modified_date_unix}, 
			}});
		}
		else
		{
			# Global variable
			$anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_name}        = $variable_name;
			$anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_value}       = $variable_value;
			$anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_default}     = $variable_default;
			$anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_description} = $variable_description;
			$anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{modified_date}        = $modified_date;
			$anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{modified_date_unix}   = $modified_date_unix;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"variables::variable_uuid::${variable_uuid}::global::variable_name"        => $anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_name}, 
				"variables::variable_uuid::${variable_uuid}::global::variable_value"       => $anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_value}, 
				"variables::variable_uuid::${variable_uuid}::global::variable_default"     => $anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_default}, 
				"variables::variable_uuid::${variable_uuid}::global::variable_description" => $anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{variable_description}, 
				"variables::variable_uuid::${variable_uuid}::global::modified_date"        => $anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{modified_date}, 
				"variables::variable_uuid::${variable_uuid}::global::modified_date_unix"   => $anvil->data->{variables}{variable_uuid}{$variable_uuid}{global}{modified_date_unix}, 
			}});
		}
	}
	
	return(0);
}


=head2 initialize

This will initialize a database using a given file.

Parameters;

=head3 sql_file (required)

This is the full (or relative) path and file nane to use when initializing the database. 

=cut
sub initialize
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->initialize()" }});
	
	my $uuid     = $anvil->Get->host_uuid;
	my $sql_file = $parameter->{sql_file} ? $parameter->{sql_file} : $anvil->data->{path}{sql}{'anvil.sql'};
	my $success  = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid     => $uuid, 
		sql_file => $sql_file, 
	}});
	
	# This just makes some logging cleaner below.
	my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "anvil";
	my $say_server    = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_server => $say_server }});
	
	if (not defined $anvil->data->{cache}{database_handle}{$uuid})
	{
		# Database handle is gone.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0078", variables => { uuid => $uuid }});
		return(0);
	}
	if (not $sql_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0079", variables => { 
			server => $say_server,
			uuid   => $uuid, 
		}});
		return(0);
	}
	elsif (not -e $sql_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0080", variables => { 
			server   => $say_server,
			uuid     => $uuid, 
			sql_file => $sql_file, 
		}});
		return(0);
	}
	elsif (not -r $sql_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0081", variables => { 
			server   => $say_server,
			uuid     => $uuid, 
			sql_file => $sql_file, 
		}});
		return(0);
	}
	
	# Tell the user we need to initialize
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0082", variables => { 
		server   => $say_server,
		uuid     => $uuid, 
		sql_file => $sql_file, 
	}});
	
	# Read in the SQL file and replace #!variable!name!# with the database owner name.
	my $user = $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : "admin";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	
	my $sql = $anvil->Storage->read_file({file => $sql_file});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sql => $sql }});
	
	# In the off chance that the database user isn't 'admin', update the SQL file.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	if ($user ne "admin")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0253", variables => { database_user => $user }});
		my $new_file = "";
		foreach my $line (split/\n/, $sql)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /OWNER TO admin;/)
			{
				$line =~ s/ admin;/ $user;/;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "<< line" => $line }});
			}
			$new_file .= $line."\n";
		}
		$sql = $new_file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "<< sql" => $sql }});
	}
	
	# Now that I am ready, disable autocommit, write and commit.
	$anvil->Database->write({
		debug        => $debug,
		uuid         => $uuid, 
		query        => $sql, 
		initializing => 1,
		source       => $THIS_FILE, 
		line         => __LINE__,
	});
	
	$anvil->data->{sys}{db_initialized}{$uuid} = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::db_initialized::${uuid}" => $anvil->data->{sys}{db_initialized}{$uuid} }});
	
	# Mark that we need to update the DB.
	$anvil->data->{sys}{database}{resync_needed} = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::resync_needed" => $anvil->data->{sys}{database}{resync_needed} }});
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { success => $success }});
	return($success);
};


=head2 insert_or_update_alert_overrides

This updates (or inserts) a record in the C<< alert_overrides >> table used for configuring what recipients get what alerts for a given host.

If there is an error, an empty string is returned.

B<< NOTE >>: The information is this table IS NOT AUTHORITATIVE! It's generally updated daily, so the information here could be stale.

Parameters;

=head3 delete (optional, default '0')

If set to C<< 1 >>, the associated alert_override override will be deleted. Specifically, the C<< alert_override_alert_level >> is set to C<< -1 >>.

When this is set, either C<< recipient_uuid >> or C<< recipient_email >> is required.

=head3 alert_override_uuid (optional)

If set, this is the specific entry that will be updated. 

=head3 alert_override_recipient_uuid (required)

This is the C<< recipients >> -> C<< recipient_uuid >> of the alert recipient.

=head3 alert_override_host_uuid (required)

This is the C<< hosts >> -> C<< host_uuid >> of the machine generating alerts.

=head3 alert_override_alert_level (required)

This is the alert level that the recipient is interested in. Any alert of equal or higher level will be sent to the associated recipient.

Valid values;

=head4 0 (ignore)

No alerts from the associated system will be sent to this recipient.

=head4 1 (critical)

Critical alerts. These are alerts that almost certainly indicate an issue with the system that has are likely will cause a service interruption. (ie: node was fenced, emergency shut down, etc)

=head4 2 (warning)

Warning alerts. These are alerts that likely require the attention of an administrator, but have not caused a service interruption. (ie: power loss/load shed, over/under voltage, fan failure, network link failure, etc)

=head4 3 (notice)

Notice alerts. These are generally low priority alerts that do not need attention, but might be indicators of developing problems. (ie: UPSes transfering to batteries, server migration/shut down/boot up, etc)

=head4 4 (info)

Info alerts. These are generally for debugging, and will generating a staggering number of alerts. Not recommended for most cases.

=cut
sub insert_or_update_alert_overrides
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_alert_overrides()" }});
	
	my $delete                        = defined $parameter->{'delete'}                      ? $parameter->{'delete'}                      : 0;
	my $uuid                          = defined $parameter->{uuid}                          ? $parameter->{uuid}                          : "";
	my $file                          = defined $parameter->{file}                          ? $parameter->{file}                          : "";
	my $line                          = defined $parameter->{line}                          ? $parameter->{line}                          : "";
	my $alert_override_uuid           = defined $parameter->{alert_override_uuid}           ? $parameter->{alert_override_uuid}           : "";
	my $alert_override_recipient_uuid = defined $parameter->{alert_override_recipient_uuid} ? $parameter->{alert_override_recipient_uuid} : "";
	my $alert_override_host_uuid      = defined $parameter->{alert_override_host_uuid}      ? $parameter->{alert_override_host_uuid}      : "";
	my $alert_override_alert_level    = defined $parameter->{alert_override_alert_level}    ? $parameter->{alert_override_alert_level}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'delete'                      => $delete, 
		alert_override_uuid           => $alert_override_uuid, 
		alert_override_recipient_uuid => $alert_override_recipient_uuid, 
		alert_override_host_uuid      => $alert_override_host_uuid, 
		alert_override_alert_level    => $alert_override_alert_level, 
	}});
	
	if (not $delete)
	{
		if (not $alert_override_recipient_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_alert_overrides()", parameter => "alert_override_recipient_uuid" }});
			return("");
		}
		if (not $alert_override_host_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_alert_overrides()", parameter => "alert_override_host_uuid" }});
			return("");
		}
		if ($alert_override_alert_level eq "")
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_alert_overrides()", parameter => "alert_override_alert_level" }});
			return("");
		}
		elsif (($alert_override_alert_level =~ /\D/) or ($alert_override_alert_level < 0) or ($alert_override_alert_level > 4))
		{
			# Not an integer
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0109", variables => { alert_override_alert_level => $alert_override_alert_level }});
			return("");
		}
	}
	
	# If we're deleting, we need a alert_override_uuid
	if (($parameter->{'delete'}) && (not $alert_override_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0389"});
		return("");
	}
	
	# If deleting, set the alert_override level to '-1'
	if ($parameter->{'delete'})
	{
		$alert_override_alert_level = -1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_override_alert_level => $alert_override_alert_level }});
	}
	
	# If we don't have the alert_override_uuid, see if we can look it up.
	if (not $alert_override_uuid)
	{
		my $query = "
SELECT 
    alert_override_uuid 
FROM 
    alert_overrides 
WHERE 
    alert_override_recipient_uuid = ".$anvil->Database->quote($alert_override_recipient_uuid)." 
AND 
    alert_override_host_uuid      = ".$anvil->Database->quote($alert_override_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$alert_override_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_override_uuid => $alert_override_uuid }});
		}
	}
	
	# Do we have an existing entry?
	if ($alert_override_uuid)
	{
		# Yes, look up the previous alert_override_alert_level.
		my $query = "
SELECT 
    alert_override_alert_level 
FROM 
    alert_overrides 
WHERE 
    alert_override_uuid = ".$anvil->Database->quote($alert_override_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		# If this doesn't return anything, the passed in UUID was invalid.
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# Error out.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0110", variables => { alert_override_uuid => $alert_override_uuid }});
			return("");
		}
		my $old_alert_override_alert_level = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_alert_override_alert_level => $old_alert_override_alert_level }});
		
		# Did the level change?
		if ($alert_override_alert_level ne $old_alert_override_alert_level)
		{
			# UPDATE
			my $query = "
UPDATE 
    alert_overrides 
SET 
    alert_override_alert_level = ".$anvil->Database->quote($alert_override_alert_level).", 
    modified_date              = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    alert_override_uuid        = ".$anvil->Database->quote($alert_override_uuid)." 
";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	else
	{
		# Nope, INSERT
		$alert_override_uuid = $anvil->Get->uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_override_uuid => $alert_override_uuid }});
		
		my $query = "
INSERT INTO 
    alert_overrides 
(
    alert_override_uuid, 
    alert_override_recipient_uuid, 
    alert_override_host_uuid, 
    alert_override_alert_level, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($alert_override_uuid).",  
    ".$anvil->Database->quote($alert_override_recipient_uuid).",  
    ".$anvil->Database->quote($alert_override_host_uuid).",  
    ".$anvil->Database->quote($alert_override_alert_level).",  
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($alert_override_uuid)
}


=head2 insert_or_update_anvils

This updates (or inserts) a record in the C<< anvils >> table. The C<< anvil_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 anvil_description (optional)

This is a free-form description for this Anvil! system. If this is set to C<< DELETED >>, the Anvil! will be considered to be deleted and no longer used.

=head3 anvil_name (required)

This is the anvil's name. It is usually in the format C<< <prefix>-anvil-<zero-padded-sequence> >>.

=head3 anvil_password (required)

This is the password used for this Anvil! system. Specifically, it is used to set the IPMI BMC user and for C<< hacluster >> and C<< root >> system users.

=head3 anvil_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< anvil_name >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head3 anvil_node1_host_uuid (optional)

This is the C<< hosts >> -> C<< host_uuid >> of the machine that is used as node 1.

B<< Note >>: If set, there must be a matching C<< hosts >> -> C<< host_uuid >> in the database.

=head3 anvil_node2_host_uuid (optional)

This is the C<< hosts >> -> C<< host_uuid >> of the machine that is used as node 2.

B<< Note >>: If set, there must be a matching C<< hosts >> -> C<< host_uuid >> in the database.

=head3 delete (optional, default '0')

If set to C<< 1 >>, C<< anvil_description >> will be set to C<< DELETED >>, indicating that the anvil has been deleted from the system. If set, only C<< anvil_uuid >> or C<< anvil_name >> is needed.

=cut
sub insert_or_update_anvils
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_anvils()" }});
	
	my $uuid                  = defined $parameter->{uuid}                  ? $parameter->{uuid}                  : "";
	my $file                  = defined $parameter->{file}                  ? $parameter->{file}                  : "";
	my $line                  = defined $parameter->{line}                  ? $parameter->{line}                  : "";
	my $delete                = defined $parameter->{'delete'}              ? $parameter->{'delete'}              : "";
	my $anvil_uuid            = defined $parameter->{anvil_uuid}            ? $parameter->{anvil_uuid}            : "";
	my $anvil_description     = defined $parameter->{anvil_description}     ? $parameter->{anvil_description}     : $anvil->data->{sys}{host_uuid};
	my $anvil_name            = defined $parameter->{anvil_name}            ? $parameter->{anvil_name}            : "";
	my $anvil_password        = defined $parameter->{anvil_password}        ? $parameter->{anvil_password}        : "";
	my $anvil_node1_host_uuid = defined $parameter->{anvil_node1_host_uuid} ? $parameter->{anvil_node1_host_uuid} : "NULL";
	my $anvil_node2_host_uuid = defined $parameter->{anvil_node2_host_uuid} ? $parameter->{anvil_node2_host_uuid} : "NULL";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                  => $uuid, 
		file                  => $file, 
		line                  => $line, 
		'delete'              => $delete, 
		anvil_uuid            => $anvil_uuid, 
		anvil_description     => $anvil_description, 
		anvil_name            => $anvil_name, 
		anvil_password        => $anvil->Log->is_secure($anvil_password), 
		anvil_node1_host_uuid => $anvil_node1_host_uuid, 
		anvil_node2_host_uuid => $anvil_node2_host_uuid, 
	}});
	
	if (not $delete)
	{
		if (not $anvil_name)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_anvils()", parameter => "anvil_name" }});
			return("");
		}
		if (not $anvil_password)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_anvils()", parameter => "anvil_password" }});
			return("");
		}
	}
	elsif ((not $anvil_name) && (not $anvil_uuid))
	{
		# Can we find the anvil_uuid?
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		
		if (not $anvil_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0127", variables => { table => "anvils" }});
			return("");
		}
	}
	
	# If we don't have a UUID, see if we can find one for the given anvil name.
	if (not $anvil_uuid)
	{
		my $query = "
SELECT 
    anvil_uuid 
FROM 
    anvils 
WHERE 
    anvil_name = ".$anvil->Database->quote($anvil_name)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$anvil_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		}
	}
	
	# Make sure that, if any host_uuid's are passed, that they're valid.
	$anvil->Database->get_hosts({debug => $debug}) if ref($anvil->data->{hosts}{host_uuid}) ne "HASH";
	if (($anvil_node1_host_uuid) && (not $anvil->data->{hosts}{host_uuid}{$anvil_node1_host_uuid}{host_name}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0128", variables => { uuid => $anvil_node1_host_uuid, column => "anvil_node1_host_uuid" }});
		return("");
	}
	if (($anvil_node2_host_uuid) && (not $anvil->data->{hosts}{host_uuid}{$anvil_node2_host_uuid}{host_name}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0128", variables => { uuid => $anvil_node2_host_uuid, column => "anvil_node2_host_uuid" }});
		return("");
	}
	
	if ($delete)
	{
		if (not $anvil_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_anvils()", parameter => "anvil_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT anvil_description FROM anvils WHERE anvil_uuid = ".$anvil->Database->quote($anvil_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_anvil_description = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_anvil_description => $old_anvil_description }});
				
				if ($old_anvil_description ne "DELETED")
				{
					my $query = "
UPDATE 
    anvils 
SET 
    anvil_description = 'DELETED', 
    modified_date     = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    anvil_uuid        = ".$anvil->Database->quote($anvil_uuid)."
;";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($anvil_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# NULL values can't be quoted
	my $say_anvil_node1_host_uuid = $anvil_node1_host_uuid eq "" ? "NULL" : $anvil->Database->quote($anvil_node1_host_uuid);
	my $say_anvil_node2_host_uuid = $anvil_node2_host_uuid eq "" ? "NULL" : $anvil->Database->quote($anvil_node2_host_uuid);
	
	# If I still don't have an anvil_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
	if (not $anvil_uuid)
	{
		# INSERT
		$anvil_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		
		my $query = "
INSERT INTO 
    anvils 
(
    anvil_uuid, 
    anvil_name, 
    anvil_description, 
    anvil_password, 
    anvil_node1_host_uuid, 
    anvil_node2_host_uuid, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($anvil_uuid).", 
    ".$anvil->Database->quote($anvil_name).", 
    ".$anvil->Database->quote($anvil_description).", 
    ".$anvil->Database->quote($anvil_password).", 
    ".$say_anvil_node1_host_uuid.", 
    ".$say_anvil_node2_host_uuid.", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    anvil_name, 
    anvil_description, 
    anvil_password, 
    anvil_node1_host_uuid, 
    anvil_node2_host_uuid 
FROM 
    anvils 
WHERE 
    anvil_uuid = ".$anvil->Database->quote($anvil_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a anvil_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "anvil_uuid", uuid => $anvil_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_anvil_name            =         $row->[0];
			my $old_anvil_description     =         $row->[1];
			my $old_anvil_password        =         $row->[2];
			my $old_anvil_node1_host_uuid = defined $row->[3] ? $row->[3] : "NULL";
			my $old_anvil_node2_host_uuid = defined $row->[4] ? $row->[4] : "NULL";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_anvil_name            => $old_anvil_name, 
				old_anvil_description     => $old_anvil_description, 
				old_anvil_password        => $anvil->Log->is_secure($old_anvil_password),
				old_anvil_node1_host_uuid => $old_anvil_node1_host_uuid, 
				old_anvil_node2_host_uuid => $old_anvil_node2_host_uuid,  
			}});
			
			# Anything change?
			if (($old_anvil_name            ne $anvil_name)            or 
			    ($old_anvil_description     ne $anvil_description)     or 
			    ($old_anvil_password        ne $anvil_password)        or 
			    ($old_anvil_node1_host_uuid ne $anvil_node1_host_uuid) or 
			    ($old_anvil_node2_host_uuid ne $anvil_node2_host_uuid))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    anvils 
SET 
    anvil_name            = ".$anvil->Database->quote($anvil_name).", 
    anvil_description     = ".$anvil->Database->quote($anvil_description).",  
    anvil_password        = ".$anvil->Database->quote($anvil_password).", 
    anvil_node1_host_uuid = ".$say_anvil_node1_host_uuid.", 
    anvil_node2_host_uuid = ".$say_anvil_node2_host_uuid.", 
    modified_date         = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    anvil_uuid            = ".$anvil->Database->quote($anvil_uuid)." 
";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($anvil_uuid);
}

=head2 insert_or_update_bridges

This updates (or inserts) a record in the 'bridges' table. The C<< bridge_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 bridge_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< bridge_name >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head3 bridge_host_uuid (optional)

This is the host that the IP address is on. If not passed, the local C<< sys::host_uuid >> will be used (indicating it is a local IP address).

=head3 bridge_name (required)

This is the bridge's device name.

=head3 bridge_nm_uuid (optional)

This is the network manager UUID for the bridge.

=head3 bridge_id (optional)

This is the unique identifier for the bridge.

=head3 bridge_mac_address (optional)

This is the MAC address of the bridge.

=head3 bridge_mtu (optional)

This is the MTU (maximum transfer unit, size in bytes) of the bridge.

=head3 bridge_stp_enabled (optional)

This is set to C<< yes >> or C<< no >> to indicate if spanning tree protocol is enabled on the switch.

=head3 delete (optional, default '0')

If set to C<< 1 >>, C<< bridge_id >> will be set to C<< DELETED >>, indicating that the bridge has been deleted from the system. If set, only C<< bridge_uuid >> or C<< bridge_name >> is needed.

=cut
sub insert_or_update_bridges
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_bridges()" }});
	
	my $uuid               = defined $parameter->{uuid}               ? $parameter->{uuid}               : "";
	my $file               = defined $parameter->{file}               ? $parameter->{file}               : "";
	my $line               = defined $parameter->{line}               ? $parameter->{line}               : "";
	my $delete             = defined $parameter->{'delete'}           ? $parameter->{'delete'}           : "";
	my $bridge_uuid        = defined $parameter->{bridge_uuid}        ? $parameter->{bridge_uuid}        : "";
	my $bridge_host_uuid   = defined $parameter->{bridge_host_uuid}   ? $parameter->{bridge_host_uuid}   : $anvil->data->{sys}{host_uuid};
	my $bridge_name        = defined $parameter->{bridge_name}        ? $parameter->{bridge_name}        : "";
	my $bridge_nm_uuid     =         $parameter->{bridge_nm_uuid}     ? $parameter->{bridge_nm_uuid}     : 'NULL';
	my $bridge_id          = defined $parameter->{bridge_id}          ? $parameter->{bridge_id}          : "";
	my $bridge_mac_address = defined $parameter->{bridge_mac_address} ? $parameter->{bridge_mac_address} : "";
	my $bridge_mtu         = defined $parameter->{bridge_mtu}         ? $parameter->{bridge_mtu}         : "";
	my $bridge_stp_enabled = defined $parameter->{bridge_stp_enabled} ? $parameter->{bridge_stp_enabled} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid               => $uuid, 
		file               => $file, 
		line               => $line, 
		'delete'           => $delete, 
		bridge_uuid        => $bridge_uuid, 
		bridge_host_uuid   => $bridge_host_uuid, 
		bridge_name        => $bridge_name, 
		bridge_nm_uuid     => $bridge_nm_uuid, 
		bridge_id          => $bridge_id, 
		bridge_mac_address => $bridge_mac_address, 
		bridge_mtu         => $bridge_mtu, 
		bridge_stp_enabled => $bridge_stp_enabled, 
	}});
	
	if (not $delete)
	{
		if (not $bridge_name)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_bridges()", parameter => "bridge_name" }});
			return("");
		}
	}
	elsif ((not $bridge_name) && (not $bridge_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0127", variables => { table => "bridges" }});
		return("");
	}
	
	# If we don't have a UUID, see if we can find one for the given bridge server name.
	if (not $bridge_uuid)
	{
		my $query = "
SELECT 
    bridge_uuid 
FROM 
    bridges 
WHERE 
    bridge_name      = ".$anvil->Database->quote($bridge_name)." 
AND 
    bridge_host_uuid = ".$anvil->Database->quote($bridge_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$bridge_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_uuid => $bridge_uuid }});
		}
	}
	
	if ($delete)
	{
		if (not $bridge_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_bridges()", parameter => "bridge_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT bridge_id FROM bridges WHERE bridge_uuid = ".$anvil->Database->quote($bridge_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_bridge_id = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_bridge_id => $old_bridge_id }});
				
				if ($old_bridge_id ne "DELETED")
				{
					my $query = "
UPDATE 
    bridges 
SET 
    bridge_id      = 'DELETED', 
    modified_date  = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    bridge_uuid    = ".$anvil->Database->quote($bridge_uuid)."
;";
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($bridge_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# If I still don't have an bridge_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_uuid => $bridge_uuid }});
	if (not $bridge_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts({debug => $debug});
		my $found = 0;
		foreach my $hash_ref (@{$hosts})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hash_ref->{host_uuid}" => $hash_ref->{host_uuid}, 
				"sys::host_uuid"        => $anvil->data->{sys}{host_uuid}, 
			}});
			if ($hash_ref->{host_uuid} eq $anvil->data->{sys}{host_uuid})
			{
				$found = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
			}
		}
		if (not $found)
		{
			# We're out.
			return("");
		}
		
		# INSERT
		$bridge_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_uuid => $bridge_uuid }});
		
		my $query = "
INSERT INTO 
    bridges 
(
    bridge_uuid, 
    bridge_host_uuid, 
    bridge_nm_uuid, 
    bridge_name, 
    bridge_id, 
    bridge_mac_address, 
    bridge_mtu, 
    bridge_stp_enabled, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($bridge_uuid).", 
    ".$anvil->Database->quote($bridge_host_uuid).", 
    ".$anvil->Database->quote($bridge_nm_uuid).", 
    ".$anvil->Database->quote($bridge_name).", 
    ".$anvil->Database->quote($bridge_id).", 
    ".$anvil->Database->quote($bridge_mac_address).", 
    ".$anvil->Database->quote($bridge_mtu).", 
    ".$anvil->Database->quote($bridge_stp_enabled).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    bridge_host_uuid, 
    bridge_nm_uuid, 
    bridge_name, 
    bridge_id, 
    bridge_mac_address, 
    bridge_mtu, 
    bridge_stp_enabled 
FROM 
    bridges 
WHERE 
    bridge_uuid = ".$anvil->Database->quote($bridge_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a bridge_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "bridge_uuid", uuid => $bridge_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_bridge_host_uuid   =         $row->[0];
			my $old_bridge_nm_uuid     = defined $row->[1] ? $row->[1] : 'NULL';
			my $old_bridge_name        =         $row->[2];
			my $old_bridge_id          =         $row->[3];
			my $old_bridge_mac_address =         $row->[4];
			my $old_bridge_mtu         =         $row->[5];
			my $old_bridge_stp_enabled =         $row->[6];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_bridge_host_uuid   => $old_bridge_host_uuid, 
				old_bridge_nm_uuid     => $old_bridge_nm_uuid, 
				old_bridge_name        => $old_bridge_name, 
				old_bridge_id          => $old_bridge_id,
				old_bridge_mac_address => $old_bridge_mac_address, 
				old_bridge_mtu         => $old_bridge_mtu,  
				old_bridge_stp_enabled => $old_bridge_stp_enabled,  
			}});
			
			# Anything change?
			if (($old_bridge_host_uuid   ne $bridge_host_uuid)   or 
			    ($old_bridge_nm_uuid     ne $bridge_nm_uuid)     or 
			    ($old_bridge_name        ne $bridge_name)        or 
			    ($old_bridge_id          ne $bridge_id)          or 
			    ($old_bridge_mac_address ne $bridge_mac_address) or 
			    ($old_bridge_mtu         ne $bridge_mtu)         or 
			    ($old_bridge_stp_enabled ne $bridge_stp_enabled))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    bridges 
SET 
    bridge_host_uuid   = ".$anvil->Database->quote($bridge_host_uuid).",  
    bridge_nm_uuid     = ".$anvil->Database->quote($bridge_nm_uuid).",  
    bridge_name        = ".$anvil->Database->quote($bridge_name).", 
    bridge_id          = ".$anvil->Database->quote($bridge_id).", 
    bridge_mac_address = ".$anvil->Database->quote($bridge_mac_address).", 
    bridge_mtu         = ".$anvil->Database->quote($bridge_mtu).", 
    bridge_stp_enabled = ".$anvil->Database->quote($bridge_stp_enabled).", 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    bridge_uuid        = ".$anvil->Database->quote($bridge_uuid)." 
";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($bridge_uuid);
}


=head2 insert_or_update_bonds

This updates (or inserts) a record in the 'bonds' table. The C<< bond_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 delete (optional, default '0')

If set to C<< 1 >>, C<< bond_operational >> gets set to C<< DELETED >>. In this case, either C<< bond_uuid >> or C<< bond_name >> is required, and nothing else is.

=head3 bond_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< bond_name >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head3 bond_host_uuid (optional)

This is the host that the IP address is on. If not passed, the local C<< sys::host_uuid >> will be used (indicating it is a local IP address).

=head3 bond_name (required)

This is the bond's device name.

=head3 bond_nm_uuid (optional)

This is the network manager UUID for this bond.

=head3 bond_mode (required)

This is the bonding mode used for this bond. 

=head3 bond_mtu (optional)

This is the MTU for the bonded interface.

=head3 bond_operational (optional)

This is set to C<< up >>, C<< down >> or C<< unknown >>. It indicates whether the bond has a working slaved interface or not.

=head3 bond_primary_interface (optional)

This is the primary interface name in the bond.

=head3 bond_primary_reselect (optional)

This is the primary interface reselect policy.

=head3 bond_active_interface (optional)

This is the interface currently being used by the bond.

=head3 bond_mac_address (optional)

This is the current / active MAC address in use by the bond interface.

=head3 bond_mii_polling_interval (optional)

This is how often, in milliseconds, that the link (mii) status is manually checked.

=head3 bond_up_delay (optional)

This is how long the bond waits, in millisecinds, after an interfaces comes up before considering it for use.

=head3 bond_down_delay (optional)

This is how long the bond waits, in millisecinds, after an interfaces goes down before considering it failed.

head3 bond_bridge_uuid (optional)

This is the C<< briges >> -> C<< bridge_uuid >> of the bridge this bond is connected to, if any.

=cut
sub insert_or_update_bonds
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_bonds()" }});
	
	my $uuid                      = defined $parameter->{uuid}                      ? $parameter->{uuid}                      : "";
	my $file                      = defined $parameter->{file}                      ? $parameter->{file}                      : "";
	my $line                      = defined $parameter->{line}                      ? $parameter->{line}                      : "";
	my $delete                    = defined $parameter->{'delete'}                  ? $parameter->{'delete'}                  : "";
	my $bond_uuid                 = defined $parameter->{bond_uuid}                 ? $parameter->{bond_uuid}                 : "";
	my $bond_host_uuid            = defined $parameter->{bond_host_uuid}            ? $parameter->{bond_host_uuid}            : $anvil->data->{sys}{host_uuid};
	my $bond_name                 = defined $parameter->{bond_name}                 ? $parameter->{bond_name}                 : "";
	my $bond_nm_uuid              =         $parameter->{bond_nm_uuid}              ? $parameter->{bond_nm_uuid}              : 'NULL';
	my $bond_mode                 = defined $parameter->{bond_mode}                 ? $parameter->{bond_mode}                 : "";
	my $bond_mtu                  = defined $parameter->{bond_mtu}                  ? $parameter->{bond_mtu}                  : "";
	my $bond_primary_interface    = defined $parameter->{bond_primary_interface}    ? $parameter->{bond_primary_interface}    : "";
	my $bond_primary_reselect     = defined $parameter->{bond_primary_reselect}     ? $parameter->{bond_primary_reselect}     : "";
	my $bond_active_interface     = defined $parameter->{bond_active_interface}     ? $parameter->{bond_active_interface}     : "";
	my $bond_mii_polling_interval = defined $parameter->{bond_mii_polling_interval} ? $parameter->{bond_mii_polling_interval} : "";
	my $bond_up_delay             = defined $parameter->{bond_up_delay}             ? $parameter->{bond_up_delay}             : "";
	my $bond_down_delay           = defined $parameter->{bond_down_delay}           ? $parameter->{bond_down_delay}           : "";
	my $bond_mac_address          = defined $parameter->{bond_mac_address}          ? $parameter->{bond_mac_address}          : "";
	my $bond_operational          = defined $parameter->{bond_operational}          ? $parameter->{bond_operational}          : "";
	my $bond_bridge_uuid          =         $parameter->{bond_bridge_uuid}          ? $parameter->{bond_bridge_uuid}          : 'NULL';
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                      => $uuid, 
		file                      => $file, 
		line                      => $line, 
		'delete'                  => $delete, 
		bond_uuid                 => $bond_uuid, 
		bond_host_uuid            => $bond_host_uuid, 
		bond_name                 => $bond_name, 
		bond_nm_uuid              => $bond_nm_uuid, 
		bond_mode                 => $bond_mode, 
		bond_mtu                  => $bond_mtu, 
		bond_primary_interface    => $bond_primary_interface, 
		bond_primary_reselect     => $bond_primary_reselect, 
		bond_active_interface     => $bond_active_interface, 
		bond_mii_polling_interval => $bond_mii_polling_interval, 
		bond_up_delay             => $bond_up_delay, 
		bond_down_delay           => $bond_down_delay, 
		bond_mac_address          => $bond_mac_address, 
		bond_operational          => $bond_operational, 
		bond_bridge_uuid          => $bond_bridge_uuid, 
	}});
	
	if (not $delete)
	{
		if (not $bond_name)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_bonds()", parameter => "bond_name" }});
			return("");
		}
		if (not $bond_mode)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_bonds()", parameter => "bond_mode" }});
			return("");
		}
		if (not $bond_bridge_uuid)
		{
			# This has to be 'NULL' if not defined.
			$bond_bridge_uuid = 'NULL';
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bond_bridge_uuid => $bond_bridge_uuid }});
		}
	}
	elsif ((not $bond_name) && (not $bond_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0127", variables => { table => "bonds" }});
		return("");
	}
	
	# If we don't have a UUID, see if we can find one for the given bond server name.
	if (not $bond_uuid)
	{
		my $query = "
SELECT 
    bond_uuid 
FROM 
    bonds 
WHERE 
    bond_name      = ".$anvil->Database->quote($bond_name)." 
AND 
    bond_host_uuid = ".$anvil->Database->quote($bond_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$bond_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bond_uuid => $bond_uuid }});
		}
	}
	
	if ($delete)
	{
		if (not $bond_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_bonds()", parameter => "bond_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT bond_operational FROM bonds WHERE bond_uuid = ".$anvil->Database->quote($bond_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_bond_operational = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_bond_operational => $old_bond_operational }});
				
				if ($old_bond_operational ne "DELETED")
				{
					my $query = "
UPDATE 
    bonds 
SET 
    bond_operational = 'DELETED', 
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    bond_uuid = ".$anvil->Database->quote($bond_uuid)."
;";
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($bond_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# If I still don't have an bond_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bond_uuid => $bond_uuid }});
	if (not $bond_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts({debug => $debug});
		my $found = 0;
		foreach my $hash_ref (@{$hosts})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hash_ref->{host_uuid}" => $hash_ref->{host_uuid}, 
				"sys::host_uuid"        => $anvil->data->{sys}{host_uuid}, 
			}});
			if ($hash_ref->{host_uuid} eq $anvil->data->{sys}{host_uuid})
			{
				$found = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
			}
		}
		if (not $found)
		{
			# We're out.
			return("");
		}
		
		# INSERT
		$bond_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bond_uuid => $bond_uuid }});
		
		my $query = "
INSERT INTO 
    bonds 
(
    bond_uuid, 
    bond_host_uuid, 
    bond_nm_uuid, 
    bond_name, 
    bond_mode, 
    bond_mtu, 
    bond_primary_interface, 
    bond_primary_reselect, 
    bond_active_interface, 
    bond_mii_polling_interval, 
    bond_up_delay, 
    bond_down_delay, 
    bond_mac_address, 
    bond_operational, 
    bond_bridge_uuid, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($bond_uuid).", 
    ".$anvil->Database->quote($bond_host_uuid).", 
    ".$anvil->Database->quote($bond_nm_uuid).", 
    ".$anvil->Database->quote($bond_name).", 
    ".$anvil->Database->quote($bond_mode).", 
    ".$anvil->Database->quote($bond_mtu).", 
    ".$anvil->Database->quote($bond_primary_interface).", 
    ".$anvil->Database->quote($bond_primary_reselect).", 
    ".$anvil->Database->quote($bond_active_interface).", 
    ".$anvil->Database->quote($bond_mii_polling_interval).", 
    ".$anvil->Database->quote($bond_up_delay).", 
    ".$anvil->Database->quote($bond_down_delay).", 
    ".$anvil->Database->quote($bond_mac_address).", 
    ".$anvil->Database->quote($bond_operational).", 
    ".$anvil->Database->quote($bond_bridge_uuid).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    bond_host_uuid, 
    bond_nm_uuid, 
    bond_name, 
    bond_mode, 
    bond_mtu, 
    bond_primary_interface, 
    bond_primary_reselect, 
    bond_active_interface, 
    bond_mii_polling_interval, 
    bond_up_delay, 
    bond_down_delay, 
    bond_mac_address, 
    bond_operational, 
    bond_bridge_uuid 
FROM 
    bonds 
WHERE 
    bond_uuid = ".$anvil->Database->quote($bond_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a bond_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "bond_uuid", uuid => $bond_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_bond_host_uuid            =         $row->[0];
			my $old_bond_nm_uuid              = defined $row->[1]  ? $row->[1] : 'NULL';
			my $old_bond_name                 =         $row->[2];
			my $old_bond_mode                 =         $row->[3];
			my $old_bond_mtu                  =         $row->[4];
			my $old_bond_primary_interface    =         $row->[5];
			my $old_bond_primary_reselect     =         $row->[6];
			my $old_bond_active_interface     =         $row->[7];
			my $old_bond_mii_polling_interval =         $row->[8];
			my $old_bond_up_delay             =         $row->[9];
			my $old_bond_down_delay           =         $row->[10];
			my $old_bond_mac_address          =         $row->[11];
			my $old_bond_operational          =         $row->[12];
			my $old_bond_bridge_uuid          = defined $row->[13] ? $row->[12] : 'NULL';
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_bond_host_uuid            => $old_bond_host_uuid, 
				old_bond_nm_uuid              => $old_bond_nm_uuid, 
				old_bond_name                 => $old_bond_name, 
				old_bond_mode                 => $old_bond_mode, 
				old_bond_mtu                  => $old_bond_mtu, 
				old_bond_primary_interface    => $old_bond_primary_interface, 
				old_bond_primary_reselect     => $old_bond_primary_reselect, 
				old_bond_active_interface     => $old_bond_active_interface, 
				old_bond_mii_polling_interval => $old_bond_mii_polling_interval, 
				old_bond_up_delay             => $old_bond_up_delay, 
				old_bond_down_delay           => $old_bond_down_delay, 
				old_bond_mac_address          => $old_bond_mac_address, 
				old_bond_operational          => $old_bond_operational, 
				old_bond_bridge_uuid          => $old_bond_bridge_uuid, 
			}});
			
			# Anything change?
			if (($old_bond_host_uuid            ne $bond_host_uuid)            or 
			    ($old_bond_nm_uuid              ne $bond_nm_uuid)              or 
			    ($old_bond_name                 ne $bond_name)                 or 
			    ($old_bond_mode                 ne $bond_mode)                 or 
			    ($old_bond_mtu                  ne $bond_mtu)                  or 
			    ($old_bond_primary_interface    ne $bond_primary_interface)    or 
			    ($old_bond_primary_reselect     ne $bond_primary_reselect)     or 
			    ($old_bond_active_interface     ne $bond_active_interface)     or 
			    ($old_bond_mii_polling_interval ne $bond_mii_polling_interval) or 
			    ($old_bond_up_delay             ne $bond_up_delay)             or 
			    ($old_bond_down_delay           ne $bond_down_delay)           or 
			    ($old_bond_mac_address          ne $bond_mac_address)          or 
			    ($old_bond_bridge_uuid          ne $bond_bridge_uuid)          or 
			    ($old_bond_operational          ne $bond_operational))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    bonds 
SET 
    bond_host_uuid            = ".$anvil->Database->quote($bond_host_uuid).",  
    bond_nm_uuid              = ".$anvil->Database->quote($bond_nm_uuid).",  
    bond_name                 = ".$anvil->Database->quote($bond_name).", 
    bond_mode                 = ".$anvil->Database->quote($bond_mode).", 
    bond_mtu                  = ".$anvil->Database->quote($bond_mtu).", 
    bond_primary_interface    = ".$anvil->Database->quote($bond_primary_interface).", 
    bond_primary_reselect     = ".$anvil->Database->quote($bond_primary_reselect).", 
    bond_active_interface     = ".$anvil->Database->quote($bond_active_interface).", 
    bond_mii_polling_interval = ".$anvil->Database->quote($bond_mii_polling_interval).", 
    bond_up_delay             = ".$anvil->Database->quote($bond_up_delay).", 
    bond_down_delay           = ".$anvil->Database->quote($bond_down_delay).", 
    bond_mac_address          = ".$anvil->Database->quote($bond_mac_address).", 
    bond_operational          = ".$anvil->Database->quote($bond_operational).", 
    bond_bridge_uuid          = ".$anvil->Database->quote($bond_bridge_uuid).", 
    modified_date             = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    bond_uuid                 = ".$anvil->Database->quote($bond_uuid)." 
";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($bond_uuid);
}


=head2 insert_or_update_dr_links

This updates (or inserts) a record in the 'dr_links' table. The C<< dr_link_uuid >> UUID will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 delete (optional)

If this is set to C<< 1 >>, the record will be deleted. Specifiically, C<< dr_link_note >> is set to C<< DELETED >>.

=head3 dr_link_uuid (optional, usually)

This is the specific record to update. If C<< delete >> is set, then either this OR both C<< dr_link_host_uuid >> and C<< dr_link_anvil_uuid >> are required.

=head3 dr_link_host_uuid (required, must by a host_type -> dr)

This is the DR host's c<< hosts >> -> C<< host_uuid >>. The host_type is checked and only hosts with C<< host_type >> = C<< dr >> are allowed.

=head3 dr_link_anvil_uuid (required)

This is the C<< anvils >> -> C<< anvil_uuid >> that will be allowed to use this DR host.

=head3 dr_link_note (optional)

This is an optional note that can be used to store anything. If this is set to C<< DELETED >>, the DR to Anvil! link is severed. 

=cut
sub insert_or_update_dr_links
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_dr_links()" }});
	
	my $uuid               = defined $parameter->{uuid}               ? $parameter->{uuid}               : "";
	my $file               = defined $parameter->{file}               ? $parameter->{file}               : "";
	my $line               = defined $parameter->{line}               ? $parameter->{line}               : "";
	my $delete             = defined $parameter->{'delete'}           ? $parameter->{'delete'}           : "";
	my $dr_link_uuid       = defined $parameter->{dr_link_uuid}       ? $parameter->{dr_link_uuid}       : "";
	my $dr_link_host_uuid  = defined $parameter->{dr_link_host_uuid}  ? $parameter->{dr_link_host_uuid}  : "";
	my $dr_link_anvil_uuid = defined $parameter->{dr_link_anvil_uuid} ? $parameter->{dr_link_anvil_uuid} : "";
	my $dr_link_note       = defined $parameter->{dr_link_note}       ? $parameter->{dr_link_note}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid               => $uuid, 
		file               => $file, 
		line               => $line, 
		dr_link_uuid       => $dr_link_uuid,
		dr_link_host_uuid  => $dr_link_host_uuid, 
		dr_link_anvil_uuid => $dr_link_anvil_uuid, 
		dr_link_note       => $dr_link_note, 
	}});
	
	# Make sure that the UUIDs are valid.
	$anvil->Database->get_hosts({deubg => $debug});
	$anvil->Database->get_dr_links({
		debug           => $debug,
		include_deleted => 1,
	});
	
	# If deleting, and if we have a valid 'dr_link_uuid' UUID, delete now and be done, 
	if ($delete)
	{
		# Do we have a valid dr_link_uuid?
		if ($dr_link_uuid)
		{
			# 
			if (not exists $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid})
			{
				# Invalid, can't delete.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0397", variables => { uuid => $dr_link_uuid }});
				return("");
			}
			
			# If we're here, delete it if it isn't already.
			if ($anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note} ne "DELETED")
			{
				my $query = "
UPDATE 
    dr_links 
SET 
    dr_link_note  = 'DELETED',
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    dr_link_uuid  = ".$anvil->Database->quote($dr_link_uuid)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
			return($dr_link_uuid)
		}
	}

	# Still here? Make sure we've got sane parameters
	if (not $dr_link_host_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_dr_links()", parameter => "dr_link_host_uuid" }});
		return("");
	}
	if (not $dr_link_anvil_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_dr_links()", parameter => "dr_link_anvil_uuid" }});
		return("");
	}
	
	# We've got UUIDs, but are they valid?
	if (not exists $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0394", variables => { uuid => $dr_link_host_uuid }});
		return("");
	}
	elsif ($anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{host_type} ne "dr")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0395", variables => { 
			uuid => $dr_link_host_uuid,
			name => $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{host_name},
			type => $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{host_type},
		}});
		return("");
	}
	if (not exists $anvil->data->{anvils}{anvil_uuid}{$dr_link_anvil_uuid})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0396", variables => { uuid => $dr_link_anvil_uuid }});
		return("");
	}
	
	my $dr_host_name = $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{host_name};
	my $anvil_name   = $anvil->data->{anvils}{anvil_uuid}{$dr_link_anvil_uuid}{anvil_name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		dr_host_name => $dr_host_name, 
		anvil_name   => $anvil_name, 
	}});
	
	# Get the dr_link_uuid, if one exists.
	if (not $dr_link_uuid)
	{
		if ((exists $anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}) && 
		    (exists $anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_host_uuid}{$dr_link_host_uuid}))
		{
			$dr_link_uuid = $anvil->data->{dr_links}{by_anvil_uuid}{$dr_link_anvil_uuid}{dr_link_host_uuid}{$dr_link_host_uuid}{dr_link_uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { dr_link_uuid => $dr_link_uuid }});
		}
	}
	
	# If we're deleting and we found a dr_link_uuid, DELETE now and return.
	if ($delete)
	{
		if (($dr_link_uuid) && ($anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note} ne "DELETED"))
		{
			my $query = "
UPDATE 
    dr_links 
SET 
    dr_link_node  = 'DELETED', 
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    dr_link_uuid  = ".$anvil->Database->quote($dr_link_uuid)." 
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
		return($dr_link_uuid)
	}
	
	# Do we have a UUID?
	if ($dr_link_uuid)
	{
		# Yup. Has something changed?
		my $old_dr_link_anvil_uuid = $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_anvil_uuid};
		my $old_dr_link_host_uuid  = $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_host_uuid};
		my $old_dr_link_note       = $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			old_dr_link_anvil_uuid => $old_dr_link_anvil_uuid, 
			old_dr_link_host_uuid  => $old_dr_link_host_uuid, 
			old_dr_link_note       => $old_dr_link_note, 
		}});
		if (($old_dr_link_anvil_uuid ne $dr_link_anvil_uuid) or 
		    ($old_dr_link_host_uuid  ne $dr_link_host_uuid)  or 
		    ($old_dr_link_note       ne $dr_link_note))
		{
			# Clear the stop data.
			my $query = "
UPDATE 
    dr_links
SET 
    dr_link_host_uuid  = ".$anvil->Database->quote($dr_link_host_uuid).", 
    dr_link_anvil_uuid = ".$anvil->Database->quote($dr_link_anvil_uuid).", 
    dr_link_note       = ".$anvil->Database->quote($dr_link_note).", 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    dr_link_uuid       = ".$anvil->Database->quote($dr_link_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	else
	{
		# No, INSERT.
		   $dr_link_uuid = $anvil->Get->uuid();
		my $query        = "
INSERT INTO 
    dr_links 
(
    dr_link_uuid, 
    dr_link_host_uuid, 
    dr_link_anvil_uuid, 
    dr_link_note, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($dr_link_uuid).", 
    ".$anvil->Database->quote($dr_link_host_uuid).", 
    ".$anvil->Database->quote($dr_link_anvil_uuid).", 
    ".$anvil->Database->quote($dr_link_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($dr_link_uuid);
}


=head2 insert_or_update_fences

This updates (or inserts) a record in the 'fences' table. The C<< fence_uuid >> UUID will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 fence_agent (required)

This is the name of the fence agent to use when communicating with this fence device. The agent must be installed on any machine that may need to fence (or check the fence/power state of) a node.

=head3 fence_arguments (optional, but generally required in practice)

This is the string that tells machines how to communicate / control the the fence device. This is used when configuring pacemaker's stonith (fencing). 

The exact formatting needs to match the STDIN parameters supported by C<< fence_agent >>. Please see C<< STDIN PARAMETERS >> section of the fence agent man page for this device.

For example, this can be set to:

* C<< ip="10.201.11.1" lanplus="1" username="admin" password="super secret password" 

B<< NOTES >>: 
* If C<< password_script >> is used, it is required that the user has copied the script to the nodes.
* Do not use C<< action="..." >> or the fence agent name. If either is found in the string, they will be ignored.
* Do not use C<< delay >>. It will be determined automatically based on which node has the most servers running on it.
* If this is set to C<< DELETED >>, the fence device is considered no longer used and it will be ignored by C<< Database->get_fences() >>.

=head3 fence_name (required)

This is the name of the fence device. Genreally, this is the short host name of the device.

=head3 fence_uuid (required)

The default value is the fence's UUID. When passed, the specific record is updated.

=cut
sub insert_or_update_fences
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_fences()" }});
	
	my $uuid            = defined $parameter->{uuid}            ? $parameter->{uuid}            : "";
	my $file            = defined $parameter->{file}            ? $parameter->{file}            : "";
	my $line            = defined $parameter->{line}            ? $parameter->{line}            : "";
	my $fence_agent     = defined $parameter->{fence_agent}     ? $parameter->{fence_agent}     : "";
	my $fence_arguments = defined $parameter->{fence_arguments} ? $parameter->{fence_arguments} : "";
	my $fence_name      = defined $parameter->{fence_name}      ? $parameter->{fence_name}      : "";
	my $fence_uuid      = defined $parameter->{fence_uuid}      ? $parameter->{fence_uuid}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid            => $uuid, 
		file            => $file, 
		line            => $line, 
		fence_agent     => $fence_agent, 
		fence_arguments => $fence_arguments =~ /passwork=/ ? $anvil->Log->is_secure($fence_arguments) : $fence_arguments, 
		fence_name      => $fence_name, 
		fence_uuid      => $fence_uuid, 
	}});
	
	# I can't imagine why you'd ever use no arguments, but it's not impossible. This doesn't include the
	# "port", which could be all that 's needed I suppose.
	if (not $fence_agent)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_fences()", parameter => "fence_agent" }});
		return("");
	}
	if (not $fence_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_fences()", parameter => "fence_name" }});
		return("");
	}
	
	# Do we have a UUID?
	if (not $fence_uuid)
	{
		my $query = "
SELECT 
    fence_uuid 
FROM 
    fences 
WHERE 
    fence_name = ".$anvil->Database->quote($fence_name)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$fence_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { fence_uuid => $fence_uuid }});
		}
	}
	
	# Do we have a UUID?
	if ($fence_uuid)
	{
		# Yup. Has something changed?
		my $query = "
SELECT 
    fence_agent, 
    fence_name, 
    fence_arguments  
FROM 
    fences 
WHERE 
    fence_uuid = ".$anvil->Database->quote($fence_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $old_fence_agent     = $row->[0];
			my $old_fence_name      = $row->[1];
			my $old_fence_arguments = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
				old_fence_agent     => $old_fence_agent,
				old_fence_name      => $old_fence_name =~ /passw/ ? $anvil->Log->is_secure($old_fence_name) : $old_fence_name, 
				old_fence_arguments => $old_fence_arguments, 
			}});
			if (($old_fence_agent     ne $fence_agent) or 
			    ($old_fence_name      ne $fence_name)  or 
			    ($old_fence_arguments ne $fence_arguments))
			{
				# Clear the stop data.
				my $query = "
UPDATE 
    fences
SET 
    fence_name      = ".$anvil->Database->quote($fence_name).", 
    fence_arguments = ".$anvil->Database->quote($fence_arguments).", 
    fence_agent     = ".$anvil->Database->quote($fence_agent).", 
    modified_date   = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    fence_uuid      = ".$anvil->Database->quote($fence_uuid)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# No, INSERT.
		   $fence_uuid = $anvil->Get->uuid();
		my $query      = "
INSERT INTO 
    fences 
(
    fence_uuid, 
    fence_name, 
    fence_arguments, 
    fence_agent, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($fence_uuid).", 
    ".$anvil->Database->quote($fence_name).",
    ".$anvil->Database->quote($fence_arguments).",
    ".$anvil->Database->quote($fence_agent).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($fence_uuid);
}


=head2 insert_or_update_file_locations

This updates (or inserts) a record in the 'file_locations' table. The C<< file_location_uuid >> referencing the database row will be returned.

This table is used to track which files on Striker dashboards need to be on given Anvil! members and DR hosts.

If there is an error, an empty string is returned.

Parameters;

=head3 file_location_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< file_location_file_uuid >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head3 file_location_anvil_uuid (required)

This is the C<< anvils >> -> C<< anvil_uuid >> being referenced. This works by figuring out which hosts are a member of the Anvil! node, and which DR hosts are linked, and makes a recursive call to this method for each of their C<< hosts >> -> C<< host_uuid >>. 

B<< Note >>: When this is used, a comma-separated list of C<< host_uuid=file_location_uuid >> is returned.

=head3 file_location_file_uuid (required)

This is the C<< files >> -> C<< file_uuid >> being referenced.

=head3 file_location_host_uuid (required)

This is the C<< hosts >> -> C<< host_uuid >> being referenced.

=head3 file_location_active (required)

This is set to C<< 1 >> or C<< 0 >>, and indicates if the file should be on the Anvil! member machines or not. 

When set to C<< 1 >>, the file will be copied by the Anvil! member machines (by the member machines, they pull the files using rsync). If set to C<< 0 >>, the file is marked as inactive. If the file exists on the Anvil! members, it will be deleted.

=head3 file_location_ready (optional, default '0')

This is set to C<< 1 >> or C<< 0 >>, and indicates if the file is on the system and ready to be used. 

B<< Note >>: This can also be set to C<< same >>. If set, and the file exists in the database, the existing value is retained. If the entry is inserted, this is set to C<< 0 >>.

When set to C<< 1 >>, the file's size and md5sum have been confirmed to match on disk what is recorded in the database. When set to C<< 0 >>, the file _may_ be ready, but it probably isn't yet. Any process needing the file should check that it's ready before using it.

=cut
sub insert_or_update_file_locations
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_file_locations()" }});

	my $uuid                     = defined $parameter->{uuid}                     ? $parameter->{uuid}                     : "";
	my $file                     = defined $parameter->{file}                     ? $parameter->{file}                     : "";
	my $line                     = defined $parameter->{line}                     ? $parameter->{line}                     : "";
	my $file_location_uuid       = defined $parameter->{file_location_uuid}       ? $parameter->{file_location_uuid}       : "";
	my $file_location_anvil_uuid = defined $parameter->{file_location_anvil_uuid} ? $parameter->{file_location_anvil_uuid} : "";
	my $file_location_file_uuid  = defined $parameter->{file_location_file_uuid}  ? $parameter->{file_location_file_uuid}  : "";
	my $file_location_host_uuid  = defined $parameter->{file_location_host_uuid}  ? $parameter->{file_location_host_uuid}  : "";
	my $file_location_active     = defined $parameter->{file_location_active}     ? $parameter->{file_location_active}     : 0;
	my $file_location_ready      = defined $parameter->{file_location_ready}      ? $parameter->{file_location_ready}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                     => $uuid, 
		file                     => $file,
		line                     => $line,
		file_location_uuid       => $file_location_uuid, 
		file_location_anvil_uuid => $file_location_anvil_uuid, 
		file_location_file_uuid  => $file_location_file_uuid, 
		file_location_host_uuid  => $file_location_host_uuid, 
		file_location_active     => $file_location_active, 
		file_location_ready      => $file_location_ready, 
	}});
	
	if (not $file_location_file_uuid)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_file_locations()", parameter => "file_location_file_uuid" }});
		return("");
	}
	if (not $file_location_host_uuid)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_file_locations()", parameter => "file_location_host_uuid" }});
		return("");
	}
	if (($file_location_active ne "0") && ($file_location_active ne "1"))
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_file_locations()", parameter => "file_location_active" }});
		return("");
	}
	if (($file_location_ready ne "0") && ($file_location_ready ne "1") && ($file_location_ready ne "same"))
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_file_locations()", parameter => "file_location_ready" }});
		return("");
	}
	
	# If we've got an Anvil! uuid, find out the hosts and DR links connected to the Anvil! are found and 
	# this method is recursively called for each host.
	if ($file_location_anvil_uuid)
	{
		$anvil->Database->get_anvils({debug => $debug});
		if (not exists $anvil->data->{anvils}{anvil_uuid}{$file_location_anvil_uuid})
		{
			# Bad Anvil! UUID.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0169", variables => { anvil_uuid => $file_location_anvil_uuid }});
			return("");
		}
		my $hosts = ();
		push @{$hosts}, $anvil->data->{anvils}{anvil_uuid}{$file_location_anvil_uuid}{anvil_node1_host_uuid};
		push @{$hosts}, $anvil->data->{anvils}{anvil_uuid}{$file_location_anvil_uuid}{anvil_node2_host_uuid};
		if (exists $anvil->data->{dr_links}{by_anvil_uuid}{$file_location_anvil_uuid})
		{
			foreach my $dr_link_host_uuid (sort {$a cmp $b} keys %{$anvil->data->{dr_links}{by_anvil_uuid}{$file_location_anvil_uuid}{dr_link_host_uuid}})
			{
				my $dr_link_uuid            = $anvil->data->{dr_links}{by_anvil_uuid}{$file_location_anvil_uuid}{dr_link_host_uuid}{$dr_link_host_uuid}{dr_link_uuid};
				my $dr_link_note            = $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_note};
				my $dr_link_short_host_name = $anvil->data->{hosts}{host_uuid}{$dr_link_host_uuid}{short_host_name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:dr_link_host_uuid"       => $dr_link_host_uuid, 
					"s2:dr_link_uuid"            => $dr_link_uuid, 
					"s3:dr_link_note"            => $dr_link_note, 
					"s4:dr_link_short_host_name" => $dr_link_short_host_name, 
				}});
				
				next if $dr_link_note eq "DELETED";
				push @{$hosts}, $dr_link_host_uuid; 
			}
		}
		my $file_location_uuids = "";
		foreach my $host_uuid (@{$hosts})
		{
			my $file_location_uuid = $anvil->Database->insert_or_update_file_locations({
				debug                    => $debug, 
				file_location_file_uuid  => $file_location_file_uuid, 
				file_location_host_uuid  => $host_uuid, 
				file_location_active     => $file_location_active, 
				file_location_ready      => $file_location_ready, 
			});
			$file_location_uuids .= $host_uuid."=".$file_location_uuid.",";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				file_location_uuid  => $file_location_uuid,
				file_location_uuids => $file_location_uuids, 
			}});
		}
		$file_location_uuids =~ s/,$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuids => $file_location_uuids }});
		
		return($file_location_uuids);
	}
	
	# If we don't have a UUID, see if we can find one for the given md5sum.
	if (not $file_location_uuid)
	{
		my $query = "
SELECT 
    file_location_uuid 
FROM 
    file_locations 
WHERE 
    file_location_file_uuid = ".$anvil->Database->quote($file_location_file_uuid)." 
AND 
    file_location_host_uuid = ".$anvil->Database->quote($file_location_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$file_location_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
		}
	}
	
	# If I still don't have an file_location_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
	if (not $file_location_uuid)
	{
		# INSERT
		$file_location_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
		
		if ($file_location_ready eq "same")
		{
			$file_location_ready = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_ready => $file_location_ready }});
		}
		
		my $query = "
INSERT INTO 
    file_locations 
(
    file_location_uuid, 
    file_location_file_uuid, 
    file_location_host_uuid, 
    file_location_active, 
    file_location_ready, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($file_location_uuid).", 
    ".$anvil->Database->quote($file_location_file_uuid).", 
    ".$anvil->Database->quote($file_location_host_uuid).", 
    ".$anvil->Database->quote($file_location_active).", 
    ".$anvil->Database->quote($file_location_ready).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    file_location_file_uuid, 
    file_location_host_uuid, 
    file_location_active, 
    file_location_ready 
FROM 
    file_locations 
WHERE 
    file_location_uuid = ".$anvil->Database->quote($file_location_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a file_location_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "file_location_uuid", uuid => $file_location_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_file_location_file_uuid = $row->[0];
			my $old_file_location_host_uuid = $row->[1];
			my $old_file_location_active    = $row->[2];
			my $old_file_location_ready     = $row->[3];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_file_location_file_uuid => $old_file_location_file_uuid, 
				old_file_location_host_uuid => $old_file_location_host_uuid, 
				old_file_location_active    => $old_file_location_active, 
				old_file_location_ready     => $old_file_location_ready, 
			}});
			
			if ($file_location_ready eq "same")
			{
				$file_location_ready = $old_file_location_ready;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_ready => $file_location_ready }});
			}
			
			# Anything change?
			if (($old_file_location_file_uuid ne $file_location_file_uuid) or 
			    ($old_file_location_host_uuid ne $file_location_host_uuid) or 
			    ($old_file_location_active    ne $file_location_active)    or
			    ($old_file_location_ready     ne $file_location_ready))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    file_locations 
SET 
    file_location_file_uuid = ".$anvil->Database->quote($file_location_file_uuid).", 
    file_location_host_uuid = ".$anvil->Database->quote($file_location_host_uuid).", 
    file_location_active    = ".$anvil->Database->quote($file_location_active).", 
    file_location_ready     = ".$anvil->Database->quote($file_location_ready).", 
    modified_date           = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    file_location_uuid      = ".$anvil->Database->quote($file_location_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($file_location_uuid);
}


=head2 insert_or_update_files

This updates (or inserts) a record in the 'files' table. The C<< file_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 file_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< file_name >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head3 file_name (required)

This is the file's name.

=head3 file_directory (required)

This is the directory that the file is in. This is used to avoid conflict if two files of the same name exist in two places but are otherwise different.

=head3 file_size (required)

This is the file's size in bytes. It is recorded as a quick way to determine if the file has changed on disk.

=head3 file_md5sum (requred)

This is the sum as calculated when the file is first uploaded. Once recorded, it can't change.

=head3 file_type (required)

This is the file's type/purpose. The expected values are 'iso' (disc image a new server can be installed from or mounted in a virtual optical drive),  'rpm' (a package to install on a guest that provides access to Anvil! RPM software), 'script' (pre or post migration scripts), 'image' (images to use for newly created servers, instead of installing from an ISO or PXE), or 'other'. 

=head3 file_mtime (required)

This is the file's C<< mtime >> (modification time as a unix timestamp). This is used in case a file of the same name exists on two or more systems, but their size or md5sum differ. The file with the most recent mtime is used to update the older versions.

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=cut
sub insert_or_update_files
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_files()" }});
	
	my $uuid           = defined $parameter->{uuid}           ? $parameter->{uuid}           : "";
	my $file           = defined $parameter->{file}           ? $parameter->{file}           : "";
	my $line           = defined $parameter->{line}           ? $parameter->{line}           : "";
	my $file_uuid      = defined $parameter->{file_uuid}      ? $parameter->{file_uuid}      : "";
	my $file_name      = defined $parameter->{file_name}      ? $parameter->{file_name}      : "";
	my $file_directory = defined $parameter->{file_directory} ? $parameter->{file_directory} : "";
	my $file_size      = defined $parameter->{file_size}      ? $parameter->{file_size}      : "";
	my $file_md5sum    = defined $parameter->{file_md5sum}    ? $parameter->{file_md5sum}    : "";
	my $file_type      = defined $parameter->{file_type}      ? $parameter->{file_type}      : "";
	my $file_mtime     = defined $parameter->{file_mtime}     ? $parameter->{file_mtime}     : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid           => $uuid, 
		file           => $file,
		line           => $line,
		file_uuid      => $file_uuid, 
		file_name      => $file_name, 
		file_directory => $file_directory, 
		file_size      => $file_size, 
		file_md5sum    => $file_md5sum, 
		file_type      => $file_type, 
		file_mtime     => $file_mtime, 
	}});
	
	if (not $file_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_files()", parameter => "file_name" }});
		return("");
	}
	if (not $file_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_files()", parameter => "file_name" }});
		return("");
	}
	if (not $file_directory)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_files()", parameter => "file_directory" }});
		return("");
	}
	if (not $file_md5sum)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_files()", parameter => "file_md5sum" }});
		return("");
	}
	if (not $file_type)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_files()", parameter => "file_type" }});
		return("");
	}
	if (not $file_mtime)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_files()", parameter => "file_mtime" }});
		return("");
	}
	
	# If we don't have a UUID, see if we can find one for the given md5sum.
	if (not $file_uuid)
	{
		my $query = "
SELECT 
    file_uuid 
FROM 
    files 
WHERE 
    file_name   = ".$anvil->Database->quote($file_name)." 
AND 
    file_md5sum = ".$anvil->Database->quote($file_md5sum)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$file_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_uuid => $file_uuid }});
		}
	}
	
	# If I still don't have an file_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_uuid => $file_uuid }});
	if (not $file_uuid)
	{
		# INSERT
		$file_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_uuid => $file_uuid }});
		
		my $query = "
INSERT INTO 
    files 
(
    file_uuid, 
    file_name, 
    file_directory, 
    file_size, 
    file_md5sum, 
    file_type, 
    file_mtime, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($file_uuid).", 
    ".$anvil->Database->quote($file_name).", 
    ".$anvil->Database->quote($file_directory).", 
    ".$anvil->Database->quote($file_size).", 
    ".$anvil->Database->quote($file_md5sum).", 
    ".$anvil->Database->quote($file_type).", 
    ".$anvil->Database->quote($file_mtime).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    file_name, 
    file_directory, 
    file_size, 
    file_md5sum, 
    file_type, 
    file_mtime 
FROM 
    files 
WHERE 
    file_uuid = ".$anvil->Database->quote($file_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a file_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "file_uuid", uuid => $file_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_file_name      = $row->[0];
			my $old_file_directory = $row->[1];
			my $old_file_size      = $row->[2];
			my $old_file_md5sum    = $row->[3]; 
			my $old_file_type      = $row->[4]; 
			my $old_file_mtime     = $row->[5]; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_file_name      => $old_file_name, 
				old_file_directory => $old_file_directory, 
				old_file_size      => $old_file_size, 
				old_file_md5sum    => $old_file_md5sum, 
				old_file_type      => $old_file_type, 
				old_file_mtime     => $old_file_mtime, 
			}});
			
			# Anything change?
			if (($old_file_name      ne $file_name)      or 
			    ($old_file_directory ne $file_directory) or 
			    ($old_file_size      ne $file_size)      or 
			    ($old_file_md5sum    ne $file_md5sum)    or 
			    ($old_file_mtime     ne $file_mtime)     or 
			    ($old_file_type      ne $file_type))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    files 
SET 
    file_name      = ".$anvil->Database->quote($file_name).", 
    file_directory = ".$anvil->Database->quote($file_directory).", 
    file_size      = ".$anvil->Database->quote($file_size).", 
    file_md5sum    = ".$anvil->Database->quote($file_md5sum).", 
    file_type      = ".$anvil->Database->quote($file_type).", 
    file_mtime     = ".$anvil->Database->quote($file_mtime).", 
    modified_date  = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    file_uuid      = ".$anvil->Database->quote($file_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($file_uuid);
}


=head2 insert_or_update_health

This inserts or updates a value in the special c<< health >> table. 

This stores weighted health of nodes. Agents can set one or more health values. After a scan sweep completes, ScanCore will sum these weights and the node with the B<< highest >> value is considered the B<< least >> healthy and any servers on it will be migrated to the peer.

If there is a problem, an empty string is returned. Otherwise, the C<< health_uuid >> is returned.

parameters;

=head3 cache (optional)

If this is passed an array reference, SQL queries will be pushed into the array instead of actually committed to databases. It will be up to the caller to commit the queries.

=head3 delete (optional, default '0')

If set, the associated C<< health_uuid >> will be deleted.

B<< Note >>: If set, C<< health_uuid >> becomes required and no other parameter is required.

=head3 health_uuid (optional)

Is passed, the specific entry will be updated.

=head3 health_host_uuid (optional, default Get->host_uuid)

This is the host registering the health score. 

=head3 health_agent_name (required)

This is the scan agent (or program name) setting this score.

=head3 health_source_name (required)

This is a decriptive name of the problem causing the health score to be set.

=head3 health_source_weight (optional, default '1')

This is a whole number (0, 1, 2, ...) indicating the weight of the problem. The higher this number is, the more likely hosted server will be migrated to the peer. 

B<< Note >>: A weight of C<< 0 >> is equal to the entry being deleted as it won't be factored into any health related decisions.

=cut
sub insert_or_update_health
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_health()" }});
	
	my $uuid                 = defined $parameter->{uuid}                 ? $parameter->{uuid}                 : "";
	my $file                 = defined $parameter->{file}                 ? $parameter->{file}                 : "";
	my $line                 = defined $parameter->{line}                 ? $parameter->{line}                 : "";
	my $cache                = defined $parameter->{cache}                ? $parameter->{cache}                : "";
	my $delete               = defined $parameter->{'delete'}             ? $parameter->{'delete'}             : "";
	my $health_uuid          = defined $parameter->{health_uuid}          ? $parameter->{health_uuid}          : "";
	my $health_host_uuid     = defined $parameter->{health_host_uuid}     ? $parameter->{health_host_uuid}     : $anvil->Get->host_uuid;
	my $health_agent_name    = defined $parameter->{health_agent_name}    ? $parameter->{health_agent_name}    : "";
	my $health_source_name   = defined $parameter->{health_source_name}   ? $parameter->{health_source_name}   : "";
	my $health_source_weight = defined $parameter->{health_source_weight} ? $parameter->{health_source_weight} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                 => $uuid, 
		file                 => $file, 
		line                 => $line, 
		'delete'             => $delete,
		health_uuid          => $health_uuid,
		health_host_uuid     => $health_host_uuid,
		health_agent_name    => $health_agent_name,
		health_source_name   => $health_source_name,
		health_source_weight => $health_source_weight,
	}});
	
	if ($delete)
	{
		if (not $health_uuid)
		{
			# If we've got an agent and source name, try to find a health UUID.
			if (($health_agent_name) && ($health_source_name))
			{
				# See if we can find an entry. If not, this might be a simple check to clear.
				my $query = "
SELECT 
    health_uuid 
FROM 
    health 
WHERE 
    health_host_uuid   = ".$anvil->Database->quote($health_host_uuid)." 
AND 
    health_agent_name  = ".$anvil->Database->quote($health_agent_name)."
AND 
    health_source_name = ".$anvil->Database->quote($health_source_name)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				my $count   = @{$results};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					results => $results, 
					count   => $count, 
				}});
				if ($count)
				{
					$health_uuid = $results->[0]->[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { health_uuid => $health_uuid }});
				}
				else
				{
					# Silently exit.
					return("");
				}
			}
			else
			{
				# Throw an error and exit.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_health()", parameter => "health_uuid" }});
				return("");
			}
		}
		
		# Still alive? do a DELETE.
		my $query = "
UPDATE 
    health 
SET 
    health_source_name = 'DELETED', 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    health_uuid        = ".$anvil->Database->quote($health_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});

		$query = "
DELETE FROM 
    health 
WHERE 
    health_uuid = ".$anvil->Database->quote($health_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		if (not $health_agent_name)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_health()", parameter => "health_agent_name" }});
			return("");
		}
		if (not $health_source_name)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_health()", parameter => "health_source_name" }});
			return("");
		}
	}
	
	# If we don't have a health UUID, see if we can find one.
	if (not $health_uuid)
	{
		my $query = "
SELECT 
    health_uuid 
FROM 
    health 
WHERE 
    health_host_uuid   = ".$anvil->Database->quote($health_host_uuid)." 
AND 
    health_agent_name  = ".$anvil->Database->quote($health_agent_name)."
AND 
    health_source_name = ".$anvil->Database->quote($health_source_name)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$health_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { health_uuid => $health_uuid }});
		}
	}
	
	# If we have a health UUID now, look up the previous value and see if it has changed. If not, INSERT 
	# a new entry.
	if ($health_uuid)
	{
		my $query = "
SELECT 
    health_host_uuid, 
    health_agent_name, 
    health_source_name, 
    health_source_weight 
FROM 
    health 
WHERE 
    health_uuid = ".$anvil->Database->quote($health_uuid).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# What?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "health_uuid", uuid => $health_uuid }});
			return("");
		}
		my $old_health_host_uuid     = $results->[0]->[0];
		my $old_health_agent_name    = $results->[0]->[1];
		my $old_health_source_name   = $results->[0]->[2];
		my $old_health_source_weight = $results->[0]->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			old_health_host_uuid     => $old_health_host_uuid,
			old_health_agent_name    => $old_health_agent_name, 
			old_health_source_name   => $old_health_source_name, 
			old_health_source_weight => $old_health_source_weight, 
		}});
		
		if (($old_health_host_uuid     ne $health_host_uuid)   or 
		    ($old_health_agent_name    ne $health_agent_name)  or
		    ($old_health_source_name   ne $health_source_name) or
		    ($old_health_source_weight ne $health_source_weight))
		{
			# Update.
			my $query = "
UPDATE 
    health 
SET 
    health_host_uuid     = ".$anvil->Database->quote($health_host_uuid).",
    health_agent_name    = ".$anvil->Database->quote($health_agent_name).",
    health_source_name   = ".$anvil->Database->quote($health_source_name).", 
    health_source_weight = ".$anvil->Database->quote($health_source_weight).",
    modified_date        = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    health_uuid          = ".$anvil->Database->quote($health_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			if (ref($cache) eq "ARRAY")
			{
				push @{$cache}, $query;
			}
			else
			{
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# INSERT
		   $health_uuid = $anvil->Get->uuid();
		my $query       = "
INSERT INTO 
    health 
(
    health_uuid, 
    health_host_uuid, 
    health_agent_name, 
    health_source_name, 
    health_source_weight, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($health_uuid).", 
    ".$anvil->Database->quote($health_host_uuid).",
    ".$anvil->Database->quote($health_agent_name).",
    ".$anvil->Database->quote($health_source_name).",
    ".$anvil->Database->quote($health_source_weight).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		if (ref($cache) eq "ARRAY")
		{
			push @{$cache}, $query;
		}
		else
		{
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	
	return($health_uuid);
}


=head2 insert_or_update_hosts

This updates (or inserts) a record in the 'hosts' table. The C<< host_uuid >> UUID will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 host_ipmi (optional)

This is an optional string that tells machines how to check/control the power of this host. This allows C<< fence_agentlan >> to query and manipulate the power of the host from another host. 

There are three times this information is used;

* When one node needs to fence the other. Specifically, the information is parsed and used to configure stonith (fencing) in pacemaker.
* When a Striker dashboard determines that, after a power or thermal event, it is safe to restart the node
* When it is time to connect a DR host to update/synchronize storage.

The exact formatting needs to match the STDIN parameters supported by C<< fence_agentlan >>. Please see C<< man fence_agentlan >> -> C<< STDIN PARAMETERS >> for more information.

For example, this can be set to:

* C<< ip="10.201.11.1" lanplus="1" username="admin" password="super secret password" 

B<< NOTES >>: 
* If C<< password_script >> is used, it is required that the user has copied the script to all machines on that could use this information to fence/boot a target.
* Do not use C<< fence_agentlan >> or C<< action="..." >>. If either is found in the string, it will be ignored.
* Do not use C<< delay >>. It will be determined automatically based on which node has the most servers running on it.

=head3 host_key (required)

The is the host's public key used by other machines to validate this machine when connecting to it using ssh. The value comes from C<< /etc/ssh/ssh_host_ecdsa_key.pub >>. An example string would be C<< ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMLEG+mcczSUgmcSuRNZc5OAFPa7IudZQv/cYWzCzmlKPMkIdcNiYDuFM1iFNiV9wVtAvkIXVSkOe2Ah/BGt6fQ= >>.

=head3 host_name (required)

This default value is the local host name.

=head3 host_type (required)

This default value is the value returned by C<< Get->host_type >>.

=head3 host_uuid (required)

The default value is the host's UUID (as returned by C<< Get->host_uuid >>.

=head3 host_status (optional, default 'no_change')

This is the power state of the host. Valid values are;

* C<< unknown >>     - This should only be set when a node can not be reached and the previous setting was not C<< stopping >> or C<< booting >>.
* C<< powered off >> - This shoule be set only when the host is confirmed off via IPMI call
* C<< online >>      - This is set by the host itself when it boots up and first connects to the anvil database. B<< Note >> - This does NOT indicate readiness! Only that the host is accessible
* C<< rebooting >>   - This is a transitional state set by the host when it begins a reboot. The next step is 'online'.
* C<< stopping >>    - This is a transitional state set by the host when it begins powering off. The next step is 'powered off' and will be set by a Striker. Note that if there is no host IPMI, the may stay in this state until in next powers on.
* C<< booting >>     - This is a transitional state set by a Striker dashboard when it is powering on a host.

B<< Note >> - Given that most Striker dashboards do not have IPMI, it is expected that they will enter C<< stopping >> state and never transition to c<< powered off >>. This is OK as C<< powered off >> can only be set when a target is B<< confirmed >> off. There's no other way to ensure that a target is not stuck while shutting down. Lack of pings doesn't solve this, either, as the network can go down before the host powers off.

=cut
sub insert_or_update_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_hosts()" }});
	
	my $uuid        = defined $parameter->{uuid}        ? $parameter->{uuid}        : "";
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $line        = defined $parameter->{line}        ? $parameter->{line}        : "";
	my $host_ipmi   = defined $parameter->{host_ipmi}   ? $parameter->{host_ipmi}   : "";
	my $host_key    = defined $parameter->{host_key}    ? $parameter->{host_key}    : "";
	my $host_name   = defined $parameter->{host_name}   ? $parameter->{host_name}   : "";
	my $host_type   = defined $parameter->{host_type}   ? $parameter->{host_type}   : "";
	my $host_uuid   = defined $parameter->{host_uuid}   ? $parameter->{host_uuid}   : "";
	my $host_status = defined $parameter->{host_status} ? $parameter->{host_status} : "no_change";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		uuid        => $uuid, 
		file        => $file, 
		line        => $line, 
		host_ipmi   => $host_ipmi =~ /passw/ ? $anvil->Log->is_secure($host_ipmi) : $host_ipmi, 
		host_key    => $host_key, 
		host_name   => $host_name, 
		host_type   => $host_type, 
		host_uuid   => $host_uuid, 
		host_status => $host_status, 
	}});
	
	# This can be called before the DB is configured, so this check allows for more graceful handling.
	if (not $anvil->data->{sys}{database}{connections})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0190"});
		return("");
	}
	
	if (not $host_name)
	{
		# Can we get it?
		$host_name = $anvil->Get->host_name({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
		
		if (not $host_name)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_hosts()", parameter => "host_name" }});
			return("");
		}
	}
	if (not $host_type)
	{
		$host_type = $anvil->Get->host_type({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	}
	if (not $host_uuid)
	{
		# Can we get it?
		$host_uuid = $anvil->Get->host_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
		
		if (not $host_uuid)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_hosts()", parameter => "host_uuid" }});
			return("");
		}
	}
	
	# If we're looking at ourselves and we don't have the host_key, read it in.
	if ((not $host_key) && ($host_uuid eq $anvil->Get->host_uuid))
	{
		$host_key =  $anvil->Storage->read_file({file => $anvil->data->{path}{data}{host_ssh_key}});
		$host_key =~ s/\n$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_key => $host_key }});
		
		# If the host is added to the key, take it off.
		if ($host_key =~ /^(.*?\s+.*?)\s/)
		{
			$host_key = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_key => $host_key }});
		}
	}
	
	# Read the old values, if they exist.
	my $old_host_ipmi   = "";
	my $old_host_name   = "";
	my $old_host_type   = "";
	my $old_host_key    = "";
	my $old_host_status = "";
	my $query           = "
SELECT 
    host_ipmi, 
    host_name, 
    host_type, 
    host_key, 
    host_status 
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->Database->quote($host_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		$old_host_ipmi   = $row->[0];
		$old_host_name   = $row->[1];
		$old_host_type   = $row->[2];
		$old_host_key    = $row->[3];
		$old_host_status = $row->[4];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			old_host_ipmi   => $old_host_ipmi =~ /passw/ ? $anvil->Log->is_secure($old_host_ipmi) : $old_host_ipmi,
			old_host_name   => $old_host_name, 
			old_host_type   => $old_host_type, 
			old_host_key    => $old_host_key, 
			old_host_status => $old_host_status, 
		}});
		
		if ($host_status eq "no_change")
		{
			$host_status = $old_host_status;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_status => $host_status }});
		}
	}
	if (not $count)
	{
		# Add this host to the database
		my $say_host_status = $host_status eq "no_change" ? "unknown" : $host_status;
		my $query           = "
INSERT INTO 
    hosts 
(
    host_uuid, 
    host_name, 
    host_type, 
    host_key, 
    host_ipmi, 
    host_status,  
    modified_date
) VALUES (
    ".$anvil->Database->quote($host_uuid).", 
    ".$anvil->Database->quote($host_name).",
    ".$anvil->Database->quote($host_type).",
    ".$anvil->Database->quote($host_key).",
    ".$anvil->Database->quote($host_ipmi).",
    ".$anvil->Database->quote($say_host_status).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	elsif (($old_host_name   ne $host_name) or 
	       ($old_host_type   ne $host_type) or 
	       ($old_host_key    ne $host_key)  or 
	       ($old_host_status ne $host_status))
	{
		# Clear the stop data.
		my $query = "
UPDATE 
    hosts
SET 
    host_name     = ".$anvil->Database->quote($host_name).", 
    host_type     = ".$anvil->Database->quote($host_type).", 
    host_key      = ".$anvil->Database->quote($host_key).", 
    host_ipmi     = ".$anvil->Database->quote($host_ipmi).", 
    host_status   = ".$anvil->Database->quote($host_status).", 
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    host_uuid     = ".$anvil->Database->quote($host_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	# If a node was replaced, there could a host_uuid with the same host name. If that's found for this 
	# host, delete the other's host_key and register an alert.
	$query = "
SELECT 
    host_uuid 
FROM 
    hosts 
WHERE 
    host_name = ".$anvil->Database->quote($host_name)." 
AND 
    host_uuid != ".$anvil->Database->quote($host_uuid)." 
AND 
    host_key != 'DELETED'
;";
	$results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		my $other_host_uuid = $row->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { other_host_uuid => $other_host_uuid }});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0075", variables => { 
			host_name => $host_name, 
			host_uuid => $other_host_uuid,
		}});
		
		my $query = "
UPDATE 
    hosts 
SET 
    host_key      = 'DELETED', 
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    host_uuid     = ".$anvil->Database->quote($other_host_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	return($host_uuid);
}


=head2 insert_or_update_ip_addresses

This updates (or inserts) a record in the 'ip_addresses' table. The C<< ip_address_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 delete (optional, default '0')

When set to C<< 1 >>, the C<< ip_address_note >> is set to C<< DELETED >>, and nothing else is changed. If set, only C<< ip_address_uuid >> or C<< ip_address_address >> are required.

=head3 ip_address_address (required)

This is the acual IP address. It's tested with IPv4 addresses in dotted-decimal format, though it can also store IPv6 addresses. If this is set to C<< 0 >>, it will be treated as deleted and will be ignored (unless a new IP is assigned to the same interface in the future).

=head3 ip_address_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< ip_address_address >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head3 ip_address_host_uuid (optional)

This is the host that the IP address is on. If not passed, the local C<< sys::host_uuid >> will be used (indicating it is a local IP address).

=head3 ip_address_on_type (required)

This indicates what type of interface the IP address is on. This must be either C<< interface >>, C<< bond >> or C<< bridge >>. 

=head3 ip_address_on_uuid (required)

This is the UUID of the bridge, bond or interface that this IP address is on.

=head3 ip_address_subnet_mask (required)

This is the subnet mask for the IP address. It is tested with IPv4 in dotted decimal format, though it can also store IPv6 format subnet masks.

=head3 ip_address_default_gateway (optional, default '0')

If a gateway address is set, and this is set to C<< 1 >>, the associated interface will be the default gateway for the host.

=head3 ip_address_gateway (optional)

This is an option gateway IP address for this interface.

=head3 ip_address_dns (optional)

This is a comma-separated list of DNS servers used to resolve host names. This is recorded, but ignored unless C<< ip_address_gateway >> is set. Example format is C<< 8.8.8.8 >> or C<< 8.8.8.8,4.4.4.4 >>.

=head3 ip_address_note (optional)

This can be set to C<< DELETED >> when the IP address is no longer in use.

=cut
sub insert_or_update_ip_addresses
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_ip_addresses()" }});
	
	my $delete                     = defined $parameter->{'delete'}                   ? $parameter->{'delete'}                   : 0;
	my $uuid                       = defined $parameter->{uuid}                       ? $parameter->{uuid}                       : "";
	my $file                       = defined $parameter->{file}                       ? $parameter->{file}                       : "";
	my $line                       = defined $parameter->{line}                       ? $parameter->{line}                       : "";
	my $ip_address_uuid            = defined $parameter->{ip_address_uuid}            ? $parameter->{ip_address_uuid}            : "";
	my $ip_address_host_uuid       = defined $parameter->{ip_address_host_uuid}       ? $parameter->{ip_address_host_uuid}       : $anvil->data->{sys}{host_uuid};
	my $ip_address_on_type         = defined $parameter->{ip_address_on_type}         ? $parameter->{ip_address_on_type}         : "";
	my $ip_address_on_uuid         = defined $parameter->{ip_address_on_uuid}         ? $parameter->{ip_address_on_uuid}         : "";
	my $ip_address_address         = defined $parameter->{ip_address_address}         ? $parameter->{ip_address_address}         : "";
	my $ip_address_subnet_mask     = defined $parameter->{ip_address_subnet_mask}     ? $parameter->{ip_address_subnet_mask}     : "";
	my $ip_address_gateway         = defined $parameter->{ip_address_gateway}         ? $parameter->{ip_address_gateway}         : "";
	my $ip_address_default_gateway = defined $parameter->{ip_address_default_gateway} ? $parameter->{ip_address_default_gateway} : 0;
	my $ip_address_dns             = defined $parameter->{ip_address_dns}             ? $parameter->{ip_address_dns}             : "";
	my $ip_address_note            = defined $parameter->{ip_address_note}            ? $parameter->{ip_address_note}            : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                       => $uuid, 
		file                       => $file, 
		line                       => $line, 
		'delete'                   => $delete, 
		ip_address_uuid            => $ip_address_uuid, 
		ip_address_host_uuid       => $ip_address_host_uuid, 
		ip_address_on_type         => $ip_address_on_type, 
		ip_address_on_uuid         => $ip_address_on_uuid, 
		ip_address_address         => $ip_address_address, 
		ip_address_subnet_mask     => $ip_address_subnet_mask, 
		ip_address_gateway         => $ip_address_gateway, 
		ip_address_default_gateway => $ip_address_default_gateway, 
		ip_address_dns             => $ip_address_dns, 
		ip_address_note            => $ip_address_note, 
	}});
	
	if (not $delete)
	{
		# Not deleting, verify we have what we need.
		if (not $ip_address_on_type)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ip_addresses()", parameter => "ip_address_on_type" }});
			return("");
		}
		if (not $ip_address_on_uuid)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ip_addresses()", parameter => "ip_address_on_uuid" }});
			return("");
		}
		if (not $ip_address_address)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ip_addresses()", parameter => "ip_address_address" }});
			return("");
		}
		if (not $ip_address_subnet_mask)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ip_addresses()", parameter => "ip_address_subnet_mask" }});
			return("");
		}
	}
	
	# If we don't have a UUID, see if we can find one for the given ip_address name.
	if (not $ip_address_uuid)
	{
		# We'll try to find the existing interface a couple ways. First we'll look up using 
		# '_on_uuid' as that's as specific as it gets.
		my $query = "
SELECT 
    ip_address_uuid 
FROM 
    ip_addresses 
WHERE 
    ip_address_on_uuid = ".$anvil->Database->quote($ip_address_on_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$ip_address_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip_address_uuid => $ip_address_uuid }});
		}
		
		if (not $ip_address_uuid)
		{
			# No luck there... An IP can be on multiple machines at the same time 
			# (ie: 192.168.122.1), so we need to restrict to this host.
			my $query = "
SELECT 
    ip_address_uuid 
FROM 
    ip_addresses 
WHERE 
    ip_address_address   = ".$anvil->Database->quote($ip_address_address)." 
AND 
    ip_address_host_uuid = ".$anvil->Database->quote($ip_address_host_uuid)." 
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				$ip_address_uuid = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip_address_uuid => $ip_address_uuid }});
			}
		}
	}
	
	if ($delete)
	{
		# We need the ip_address_uuid _or_ the ip_address_address
		if (not $ip_address_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ip_addresses()", parameter => "ip_address_uuid" }});
			return("");
		}
		else
		{
			my $query = "SELECT ip_address_note FROM ip_addresses WHERE ip_address_uuid = ".$anvil->Database->quote($ip_address_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_ip_address_note = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_ip_address_note => $old_ip_address_note }});
				
				if ($old_ip_address_note ne "DELETED")
				{
					my $query = "
UPDATE 
    ip_addresses 
SET 
    ip_address_note = 'DELETED',
    modified_date   = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    ip_address_uuid = ".$anvil->Database->quote($ip_address_uuid)."
;";
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($ip_address_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# If I still don't have an ip_address_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip_address_uuid => $ip_address_uuid }});
	if (not $ip_address_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts({debug => $debug});
		my $found = 0;
		foreach my $hash_ref (@{$hosts})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hash_ref->{host_uuid}" => $hash_ref->{host_uuid}, 
				"sys::host_uuid"        => $anvil->data->{sys}{host_uuid}, 
			}});
			if ($hash_ref->{host_uuid} eq $anvil->data->{sys}{host_uuid})
			{
				$found = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
			}
		}
		if (not $found)
		{
			# We're out.
			return("");
		}
		
		# INSERT
		$ip_address_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip_address_uuid => $ip_address_uuid }});
		
		my $query = "
INSERT INTO 
    ip_addresses 
(
    ip_address_uuid, 
    ip_address_host_uuid, 
    ip_address_on_type, 
    ip_address_on_uuid, 
    ip_address_address, 
    ip_address_subnet_mask, 
    ip_address_gateway, 
    ip_address_default_gateway, 
    ip_address_dns, 
    ip_address_note, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($ip_address_uuid).", 
    ".$anvil->Database->quote($ip_address_host_uuid).", 
    ".$anvil->Database->quote($ip_address_on_type).", 
    ".$anvil->Database->quote($ip_address_on_uuid).", 
    ".$anvil->Database->quote($ip_address_address).", 
    ".$anvil->Database->quote($ip_address_subnet_mask).", 
    ".$anvil->Database->quote($ip_address_gateway).", 
    ".$anvil->Database->quote($ip_address_default_gateway).", 
    ".$anvil->Database->quote($ip_address_dns).", 
    ".$anvil->Database->quote($ip_address_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    ip_address_host_uuid, 
    ip_address_on_type, 
    ip_address_on_uuid, 
    ip_address_address, 
    ip_address_subnet_mask, 
    ip_address_gateway, 
    ip_address_default_gateway, 
    ip_address_dns, 
    ip_address_note 
FROM 
    ip_addresses 
WHERE 
    ip_address_uuid = ".$anvil->Database->quote($ip_address_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have an ip_address_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "ip_address_uuid", uuid => $ip_address_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_ip_address_host_uuid       = $row->[0];
			my $old_ip_address_on_type         = $row->[1];
			my $old_ip_address_on_uuid         = $row->[2];
			my $old_ip_address_address         = $row->[3];
			my $old_ip_address_subnet_mask     = $row->[4];
			my $old_ip_address_gateway         = $row->[5];
			my $old_ip_address_default_gateway = $row->[6];
			my $old_ip_address_dns             = $row->[7];
			my $old_ip_address_note            = $row->[8];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_ip_address_host_uuid       => $old_ip_address_host_uuid, 
				old_ip_address_on_type         => $old_ip_address_on_type, 
				old_ip_address_on_uuid         => $old_ip_address_on_uuid, 
				old_ip_address_address         => $old_ip_address_address, 
				old_ip_address_subnet_mask     => $old_ip_address_subnet_mask, 
				old_ip_address_gateway         => $old_ip_address_gateway, 
				old_ip_address_default_gateway => $old_ip_address_default_gateway, 
				old_ip_address_dns             => $old_ip_address_dns, 
				old_ip_address_note            => $old_ip_address_note, 
			}});
			
			# Anything change?
			if (($old_ip_address_host_uuid       ne $ip_address_host_uuid)       or 
			    ($old_ip_address_on_type         ne $ip_address_on_type)         or 
			    ($old_ip_address_on_uuid         ne $ip_address_on_uuid)         or 
			    ($old_ip_address_address         ne $ip_address_address)         or 
			    ($old_ip_address_subnet_mask     ne $ip_address_subnet_mask)     or 
			    ($old_ip_address_gateway         ne $ip_address_gateway)         or 
			    ($old_ip_address_default_gateway ne $ip_address_default_gateway) or 
			    ($old_ip_address_dns             ne $ip_address_dns)             or 
			    ($old_ip_address_note            ne $ip_address_note))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    ip_addresses 
SET 
    ip_address_host_uuid       = ".$anvil->Database->quote($ip_address_host_uuid).",  
    ip_address_on_type         = ".$anvil->Database->quote($ip_address_on_type).",  
    ip_address_on_uuid         = ".$anvil->Database->quote($ip_address_on_uuid).", 
    ip_address_address         = ".$anvil->Database->quote($ip_address_address).", 
    ip_address_subnet_mask     = ".$anvil->Database->quote($ip_address_subnet_mask).", 
    ip_address_gateway         = ".$anvil->Database->quote($ip_address_gateway).", 
    ip_address_default_gateway = ".$anvil->Database->quote($ip_address_default_gateway).", 
    ip_address_dns             = ".$anvil->Database->quote($ip_address_dns).", 
    ip_address_note            = ".$anvil->Database->quote($ip_address_note).", 
    modified_date              = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    ip_address_uuid            = ".$anvil->Database->quote($ip_address_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($ip_address_uuid);
}


=head2 insert_or_update_jobs

This updates (or inserts) a record in the 'jobs' table. The C<< job_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

B<< Note >>: if the C<< job_host_uuid >> is set to C<< all >>, a hash reference will be returned where they keys are the C<< host_uuid >> and the value is the C<< job_uuid >>.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 job_command (required)

This is the command (usually a shell call) to run.

=head3 job_data (optional)

This is used to pass information or store special progress data on a job. 

=head3 job_description (required*)

This is a string key to display in the body of the box showing that the job is running.

Variables can not be passed to this title key.

* This is not required when C<< update_progress_only >> is set

=head3 job_host_uuid (optional)

This is the host's UUID that this job entry belongs to. If not passed, C<< sys::host_uuid >> will be used.

B<< Note >>: If this is set to C<< all >>, the job will be recorded once for each host in the C<< hosts >> table.

=head3 job_name (required*)

This is the C<< job_name >> to INSERT or UPDATE. If a C<< job_uuid >> is passed, then the C<< job_name >> can be changed.

* This or C<< job_uuid >> must be passed

=head3 job_picked_up_at (optional)

When C<< anvil-daemon >> picks uup a job, it will record the (unix) time that it started.

=head3 job_picked_up_by (optional)

When C<< anvil-daemon >> picks up a job, it will record it's PID here.

=head3 job_progress (required)

This is a numeric value between C<< 0 >> and C<< 100 >>. The job will update this as it runs, with C<< 100 >> indicating that the job is complete. A value of C<< 0 >> will indicate that the job needs to be started. When the daemon picks up the job, it will set this to C<< 1 >>. Any value in between is set by the job itself.

=head3 job_status (optional)

This is used to tell the user the current status of the job. It can be included when C<< update_progress_only >> is set. 

The expected format is C<< <key>,!!var1!foo!!,...,!!varN!bar!!\n >>, one key/variable set per line. The new lines will be converted to C<< <br />\n >> automatically in Striker.

=head3 job_title (required*)

This is a string key to display in the title of the box showing that the job is running.

Variables can not be passed to this title key.

* This is not required when C<< update_progress_only >> is set

B<< Note >>: This can be set to the special C<< anvil_startup >>. When the job status is set to this value, the job will only run when ScanCore next starts up (generally after a reboot). 

=head3 job_uuid (optional)

This is the C<< job_uuid >> to update. If it is not specified but the C<< job_name >> is, a check will be made to see if an entry already exists. If so, that row will be UPDATEd. If not, a random UUID will be generated and a new entry will be INSERTed.

* This or C<< job_name >> must be passed

=head3 update_progress_only (optional)

When set, the C<< job_progress >> will be updated. Optionally, if C<< job_status >>, C<< job_picked_up_by >>, C<< job_picked_up_at >> or C<< job_data >> are set, they may also be updated.

=cut 
sub insert_or_update_jobs
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_jobs()" }});
	
	my $uuid                 = defined $parameter->{uuid}                 ? $parameter->{uuid}                 : "";
	my $file                 = defined $parameter->{file}                 ? $parameter->{file}                 : "";
	my $line                 = defined $parameter->{line}                 ? $parameter->{line}                 : "";
	my $job_uuid             = defined $parameter->{job_uuid}             ? $parameter->{job_uuid}             : "";
	my $job_host_uuid        = defined $parameter->{job_host_uuid}        ? $parameter->{job_host_uuid}        : $anvil->data->{sys}{host_uuid};
	my $job_command          = defined $parameter->{job_command}          ? $parameter->{job_command}          : "";
	my $job_data             = defined $parameter->{job_data}             ? $parameter->{job_data}             : "";
	my $job_picked_up_by     = defined $parameter->{job_picked_up_by}     ? $parameter->{job_picked_up_by}     : 0;
	my $job_picked_up_at     = defined $parameter->{job_picked_up_at}     ? $parameter->{job_picked_up_at}     : 0;
	my $job_updated          = defined $parameter->{job_updated}          ? $parameter->{job_updated}          : "";
	my $job_name             = defined $parameter->{job_name}             ? $parameter->{job_name}             : "";
	my $job_progress         = defined $parameter->{job_progress}         ? $parameter->{job_progress}         : "";
	my $job_title            = defined $parameter->{job_title}            ? $parameter->{job_title}            : "";
	my $job_description      = defined $parameter->{job_description}      ? $parameter->{job_description}      : "";
	my $job_status           = defined $parameter->{job_status}           ? $parameter->{job_status}           : "";
	my $update_progress_only = defined $parameter->{update_progress_only} ? $parameter->{update_progress_only} : 0;
	my $clear_status         = defined $parameter->{clear_status}         ? $parameter->{clear_status}         : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                 => $uuid, 
		file                 => $file, 
		line                 => $line, 
		job_uuid             => $job_uuid, 
		job_host_uuid        => $job_host_uuid, 
		job_command          => $job_command, 
		job_data             => $job_data, 
		job_picked_up_by     => $job_picked_up_by, 
		job_picked_up_at     => $job_picked_up_at, 
		job_updated          => $job_updated, 
		job_name             => $job_name, 
		job_progress         => $job_progress, 
		job_title            => $job_title, 
		job_description      => $job_description, 
		job_status           => $job_status, 
		update_progress_only => $update_progress_only, 
		clear_status         => $clear_status, 
	}});
	
	
	# If I have a job_uuid and update_progress_only is true, I only need the progress.
	my $problem = 0;
	
	# Do I have a valid progress?
	if (($job_progress !~ /^\d/) or ($job_progress < 0) or ($job_progress > 100))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0138", variables => { method => "Database->insert_or_update_jobs()", job_progress => $job_progress }});
		$problem = 1;
	}
	
	# Make sure I have the either a valid job UUID or a name
	if ((not $anvil->Validate->uuid({uuid => $job_uuid})) && (not $job_name))
	{
		$anvil->Log->entry({source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__, level => 0, priority => "err", key => "log_0136", variables => { 
			method   => "Database->insert_or_update_jobs()", 
			job_name => $job_name,
			job_uuid => $job_uuid,
		}});
		$problem = 1;
	}
	
	# Unless I am updating the progress, make sure everything is passed.
	if (not $update_progress_only)
	{
		# Everything is required, except 'job_uuid'. So, job command?
		if (not $job_command)
		{
			$anvil->Log->entry({source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_command" }});
			$problem = 1;
		}
		
		# Job name?
		if (not $job_name)
		{
			$anvil->Log->entry({source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_name" }});
			$problem = 1;
		}
		
		# Job title?
		if (not $job_title)
		{
			$anvil->Log->entry({source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_title" }});
			$problem = 1;
		}
		
		# Job description?
		if (not $job_description)
		{
			$anvil->Log->entry({source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_description" }});
			$problem = 1;
		}
	}
	
	# We're done if there was a problem
	if ($problem)
	{
		return("");
	}
	
	# If the job_host_uuid is set to 'all', go into a loop and call ourselves once per host using their host_uuid.
	if ($job_host_uuid eq "all")
	{
		my $job_uuids = {};
		$anvil->Database->get_hosts({debug => $debug});
		foreach my $host_uuid (keys %{$anvil->data->{hosts}{host_uuid}})
		{
			my $host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				host_uuid => $host_uuid,
				host_name => $host_name, 
			}});
			
			$job_uuids->{$host_uuid} = $anvil->Database->insert_or_update_jobs({
				debug                => $debug, 
				job_command          => $job_command, 
				job_host_uuid        => $host_uuid, 
				job_data             => $job_data, 
				job_picked_up_by     => $job_picked_up_by, 
				job_picked_up_at     => $job_picked_up_at, 
				job_updated          => $job_updated, 
				job_name             => $job_name, 
				job_progress         => $job_progress, 
				job_title            => $job_title, 
				job_description      => $job_description, 
				job_status           => $job_status, 
				update_progress_only => $update_progress_only, 
				clear_status         => $clear_status, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "job_uuids->{$host_uuid}" => $job_uuids->{$host_uuid} }});
		}
		
		return($job_uuids);
	}
	
	if (not $job_updated)
	{
		$job_updated = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_updated => $job_updated }});
	}
	
	# If we don't have a UUID, see if we can find one for the given job name.
	if (not $job_uuid)
	{
		my $query = "
SELECT 
    job_uuid 
FROM 
    jobs 
WHERE 
    job_name      = ".$anvil->Database->quote($job_name)." 
AND 
    job_command   = ".$anvil->Database->quote($job_command)." 
AND 
    job_data      = ".$anvil->Database->quote($job_data)." 
AND 
    job_host_uuid = ".$anvil->Database->quote($job_host_uuid)." 
AND 
    job_progress  != 100
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			$job_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
		}
	}
	
	# Now make sure I have a job_uuid if I am updating.
	if (($update_progress_only) && (not $job_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { parameter => "job_uuid" }});
		$problem = 1;
	}
	
	# If I still don't have an job_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	if (not $job_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts({debug => $debug});
		my $found = 0;
		foreach my $hash_ref (@{$hosts})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hash_ref->{host_uuid}" => $hash_ref->{host_uuid}, 
				"sys::host_uuid"        => $anvil->data->{sys}{host_uuid}, 
			}});
			if ($hash_ref->{host_uuid} eq $anvil->data->{sys}{host_uuid})
			{
				$found = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
				last;
			}
		}
		if (not $found)
		{
			# We're out.
			return("");
		}
		
		# INSERT
		   $job_uuid = $anvil->Get->uuid();
		my $query    = "
INSERT INTO 
    jobs 
(
    job_uuid, 
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
    modified_date 
) VALUES (
    ".$anvil->Database->quote($job_uuid).", 
    ".$anvil->Database->quote($job_host_uuid).", 
    ".$anvil->Database->quote($job_command).", 
    ".$anvil->Database->quote($job_data).", 
    ".$anvil->Database->quote($job_picked_up_by).", 
    ".$anvil->Database->quote($job_picked_up_at).", 
    ".$anvil->Database->quote($job_updated).", 
    ".$anvil->Database->quote($job_name).", 
    ".$anvil->Database->quote($job_progress).", 
    ".$anvil->Database->quote($job_title).", 
    ".$anvil->Database->quote($job_description).", 
    ".$anvil->Database->quote($job_status).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp({debug => $debug}))."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
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
    job_status 
FROM 
    jobs 
WHERE 
    job_uuid = ".$anvil->Database->quote($job_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a job_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "job_uuid", uuid => $job_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_job_host_uuid    = $row->[0];
			my $old_job_command      = $row->[1];
			my $old_job_data         = $row->[2];
			my $old_job_picked_up_by = $row->[3];
			my $old_job_picked_up_at = $row->[4];
			my $old_job_updated      = $row->[5];
			my $old_job_name         = $row->[6];
			my $old_job_progress     = $row->[7];
			my $old_job_title        = $row->[8];
			my $old_job_description  = $row->[9];
			my $old_job_status       = $row->[10];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_job_host_uuid    => $old_job_host_uuid,
				old_job_command      => $old_job_command, 
				old_job_data         => $old_job_data, 
				old_job_picked_up_by => $old_job_picked_up_by, 
				old_job_picked_up_at => $old_job_picked_up_at, 
				old_job_updated      => $old_job_updated, 
				old_job_name         => $old_job_name, 
				old_job_progress     => $old_job_progress,
				old_job_title        => $old_job_title, 
				old_job_description  => $old_job_description, 
				old_job_status       => $old_job_status, 
			}});
			
			# Anything change?
			if ($update_progress_only)
			{
				# We'll conditionally check and update 'job_status', 'job_picked_up_by', 
				# 'job_picked_up_at' and 'job_data'.
				my $update = 0;
				my $query  = "
UPDATE 
    jobs 
SET ";
				if ($old_job_progress ne $job_progress)
				{
					$update =  1;
					$query  .= "
    job_progress     = ".$anvil->Database->quote($job_progress).", ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update => $update, 
						query  => $query, 
					}});
				}
				if (($clear_status) or (($job_status ne "") && ($old_job_status ne $job_status)))
				{
					$update =  1;
					$query  .= "
    job_status       = ".$anvil->Database->quote($job_status).", ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update => $update, 
						query  => $query, 
					}});
				}
				if (($job_picked_up_by ne "") && ($old_job_picked_up_by ne $job_picked_up_by))
				{
					$update =  1;
					$query  .= "
    job_picked_up_by = ".$anvil->Database->quote($job_picked_up_by).", ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update => $update, 
						query  => $query, 
					}});
				}
				if (($job_picked_up_at ne "") && ($old_job_picked_up_at ne $job_picked_up_at))
				{
					$update =  1;
					$query  .= "
    job_picked_up_at = ".$anvil->Database->quote($job_picked_up_at).", ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update => $update, 
						query  => $query, 
					}});
				}
				if (($job_data ne "") && ($old_job_data ne $job_data))
				{
					$update =  1;
					$query  .= "
    job_data         = ".$anvil->Database->quote($job_data).", ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update => $update, 
						query  => $query, 
					}});
				}
				$query .= "
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp({debug => $debug}))." 
WHERE 
    job_uuid         = ".$anvil->Database->quote($job_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					update => $update, 
					query  => $query, 
				}});
				if ($update)
				{
					# Something changed, update
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
			}
			else
			{
				if (($old_job_host_uuid    ne $job_host_uuid)    or 
				    ($old_job_command      ne $job_command)      or 
				    ($old_job_data         ne $job_data)         or 
				    ($old_job_picked_up_by ne $job_picked_up_by) or 
				    ($old_job_picked_up_at ne $job_picked_up_at) or 
				    ($old_job_updated      ne $job_updated)      or 
				    ($old_job_name         ne $job_name)         or 
				    ($old_job_progress     ne $job_progress)     or 
				    ($old_job_title        ne $job_title)        or 
				    ($old_job_description  ne $job_description)  or 
				    ($old_job_status       ne $job_status))
				{
					# Something changed, save. Before I do though, refresh the database 
					# timestamp as it's likely this isn't the only update that will 
					# happen on this pass.
					my $query = "
UPDATE 
    jobs 
SET 
    job_host_uuid    = ".$anvil->Database->quote($job_host_uuid).",  
    job_command      = ".$anvil->Database->quote($job_command).", 
    job_data         = ".$anvil->Database->quote($job_data).", 
    job_picked_up_by = ".$anvil->Database->quote($job_picked_up_by).", 
    job_picked_up_at = ".$anvil->Database->quote($job_picked_up_at).", 
    job_updated      = ".$anvil->Database->quote($job_updated).", 
    job_name         = ".$anvil->Database->quote($job_name).", 
    job_progress     = ".$anvil->Database->quote($job_progress).", 
    job_title        = ".$anvil->Database->quote($job_title).", 
    job_description  = ".$anvil->Database->quote($job_description).", 
    job_status       = ".$anvil->Database->quote($job_status).", 
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp({debug => $debug}))." 
WHERE 
    job_uuid         = ".$anvil->Database->quote($job_uuid)." 
";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	return($job_uuid);
}


=head2 insert_or_update_mail_servers

This updates (or inserts) a record in the 'mail_servers' table. The C<< mail_server_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 delete (optional, default '0')

If set to C<< 1 >>, the associated mail server will be deleted. Specifically, the C<< mail_server_helo_domain >> is set to C<< DELETED >>.

When this is set, either C<< mail_server_uuid >> or C<< mail_server_address >> is required.

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 mail_server_address (required) 

This is the domain name or IP address of the mail server that alert emails will be forwarded to.

=head3 mail_server_authentication (optional, default 'normal_password')

This is the authentication method used to pass our password (or otherwise prove our identity) to the target mail server.

This can be set to anything you wish, but the expected values are;

* C<< normal_password >>
* C<< encrypted_password >>
* C<< kerberos_gssapi >> 
* C<< ntlm >>
* C<< tls_certificate >>
* C<< oauth2 >>

=head3 mail_server_helo_domain (optional, default is the local machine's domain name)

This is the string passed to the target mail server for the C<< HELO >> or C<< EHLO >> string. See C<< https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol#SMTP_transport_example >> for more information.

=head3 mail_server_password (optional)

If needed to authenticate, this is the password portion passed along with the C<< mail_server_username >>.

=head3 mail_server_port (optional, default depends on 'mail_server_security')

If set, this is the TCP port used when connecting to th mail server. If not set, the port is detemined based on the C<< mail_server_security >>. If it is C<< none >> or C<< starttls >>, the port is C<< 587 >>. if is it C<< ssl_tls >>, the port is C<< 993 >>. 

=head3 mail_server_security (optional)

This is the connection security used when establishing a connection to the mail server. 

This can be set to anything you wish, but the expected values are;

* C<< none >> (default port 587)
* C<< starttls >> (default port 587)
* C<< ssl_tls >> (default port 465)

B<< NOTE >> - If any other string is passed and C<< mail_server_port >> is not set, port C<< 143 >> will be used.

=head3 mail_server_username (optional)

If needed to authenticate, this is the user name portion passed along with the C<< mail_server_password >>.

=head3 mail_server_uuid (optional)

If set, this is the UUID that will be used to update a record in the database. If not set, it will be searched for by looking for a matching C<< mail_server_address >>.

=cut
sub insert_or_update_mail_servers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_mail_servers()" }});
	
	my $delete                     = defined $parameter->{'delete'}                   ? $parameter->{'delete'}                   : 0;
	my $uuid                       = defined $parameter->{uuid}                       ? $parameter->{uuid}                       : "";
	my $file                       = defined $parameter->{file}                       ? $parameter->{file}                       : "";
	my $line                       = defined $parameter->{line}                       ? $parameter->{line}                       : "";
	my $mail_server_address        = defined $parameter->{mail_server_address}        ? $parameter->{mail_server_address}        : "";
	my $mail_server_authentication = defined $parameter->{mail_server_authentication} ? $parameter->{mail_server_authentication} : "normal_password";
	my $mail_server_helo_domain    = defined $parameter->{mail_server_helo_domain}    ? $parameter->{mail_server_helo_domain}    : "";
	my $mail_server_password       = defined $parameter->{mail_server_password}       ? $parameter->{mail_server_password}       : "";
	my $mail_server_port           = defined $parameter->{mail_server_port}           ? $parameter->{mail_server_port}           : "";
	my $mail_server_security       = defined $parameter->{mail_server_security}       ? $parameter->{mail_server_security}       : "none";
	my $mail_server_username       = defined $parameter->{mail_server_username}       ? $parameter->{mail_server_username}       : "";
	my $mail_server_uuid           = defined $parameter->{mail_server_uuid}           ? $parameter->{mail_server_uuid}           : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'delete'                   => $delete, 
		uuid                       => $uuid, 
		file                       => $file, 
		line                       => $line, 
		mail_server_address        => $mail_server_address, 
		mail_server_authentication => $mail_server_authentication, 
		mail_server_helo_domain    => $mail_server_helo_domain, 
		mail_server_password       => $anvil->Log->is_secure($mail_server_password), 
		mail_server_port           => $mail_server_port, 
		mail_server_security       => $mail_server_security, 
		mail_server_username       => $mail_server_username, 
		mail_server_uuid           => $mail_server_uuid, 
	}});
	
	# Did we get a mail server name? 
	if ((not $mail_server_address) && (not $mail_server_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_mail_servers()", parameter => "mail_server_address" }});
		return("");
	}
	
	if (not $mail_server_uuid)
	{
		# Can we find it using the mail server address?
		my $query = "
SELECT 
    mail_server_uuid 
FROM 
    mail_servers 
WHERE 
    mail_server_address = ".$anvil->Database->quote($mail_server_address)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$mail_server_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mail_server_uuid => $mail_server_uuid }});
		}
	}
	
	if ($delete)
	{
		if (not $mail_server_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_mail_servers()", parameter => "mail_server_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT mail_server_helo_domain FROM mail_servers WHERE mail_server_uuid = ".$anvil->Database->quote($mail_server_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_mail_server_helo_domain = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_mail_server_helo_domain => $old_mail_server_helo_domain }});
				
				if ($old_mail_server_helo_domain ne "DELETED")
				{
					my $query = "
UPDATE 
    mail_servers 
SET 
    mail_server_helo_domain = 'DELETED',
    modified_date           = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    mail_server_uuid        = ".$anvil->Database->quote($mail_server_uuid)."
;";
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($mail_server_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# Fill some data
	if (not $mail_server_helo_domain)
	{
		$mail_server_helo_domain = $anvil->Get->domain_name();
		if (not $mail_server_helo_domain)
		{
			# Fall back on 'localdomain'
			$mail_server_helo_domain = "localdomain";
		}
	}
	if (not $mail_server_port)
	{
		$mail_server_port = 587;
		if ($mail_server_security eq "ssl_tls")
		{
			$mail_server_port = 465;
		}
	}
	
	# If I still don't have an mail_server_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mail_server_uuid => $mail_server_uuid }});
	if (not $mail_server_uuid)
	{
		# INSERT
		$mail_server_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mail_server_uuid => $mail_server_uuid }});
		
		my $query = "
INSERT INTO 
    mail_servers 
(
    mail_server_uuid, 
    mail_server_address, 
    mail_server_authentication, 
    mail_server_helo_domain, 
    mail_server_password, 
    mail_server_port, 
    mail_server_security, 
    mail_server_username, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($mail_server_uuid).", 
    ".$anvil->Database->quote($mail_server_address).", 
    ".$anvil->Database->quote($mail_server_authentication).", 
    ".$anvil->Database->quote($mail_server_helo_domain).", 
    ".$anvil->Database->quote($mail_server_password).", 
    ".$anvil->Database->quote($mail_server_port).", 
    ".$anvil->Database->quote($mail_server_security).", 
    ".$anvil->Database->quote($mail_server_username).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    mail_server_address, 
    mail_server_authentication, 
    mail_server_helo_domain, 
    mail_server_password, 
    mail_server_port, 
    mail_server_security, 
    mail_server_username 
FROM 
    mail_servers 
WHERE 
    mail_server_uuid = ".$anvil->Database->quote($mail_server_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a mail_server_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "mail_server_uuid", uuid => $mail_server_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_mail_server_address        = $row->[0]; 
			my $old_mail_server_authentication = $row->[1];
			my $old_mail_server_helo_domain    = $row->[2]; 
			my $old_mail_server_password       = $row->[3]; 
			my $old_mail_server_port           = $row->[4]; 
			my $old_mail_server_security       = $row->[5]; 
			my $old_mail_server_username       = $row->[6];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_mail_server_address        => $old_mail_server_address, 
				old_mail_server_authentication => $old_mail_server_authentication,
				old_mail_server_helo_domain    => $old_mail_server_helo_domain, 
				old_mail_server_password       => $anvil->Log->is_secure($old_mail_server_password), 
				old_mail_server_port           => $old_mail_server_port, 
				old_mail_server_security       => $old_mail_server_security, 
				old_mail_server_username       => $old_mail_server_username, 
			}});
			
			# Anything change?
			if (($old_mail_server_address        ne $mail_server_address)        or 
			    ($old_mail_server_authentication ne $mail_server_authentication) or 
			    ($old_mail_server_helo_domain    ne $mail_server_helo_domain)    or  
			    ($old_mail_server_password       ne $mail_server_password)       or  
			    ($old_mail_server_port           ne $mail_server_port)           or  
			    ($old_mail_server_security       ne $mail_server_security)       or  
			    ($old_mail_server_username       ne $mail_server_username))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    mail_servers 
SET 
    mail_server_address        = ".$anvil->Database->quote($mail_server_address).", 
    mail_server_authentication = ".$anvil->Database->quote($mail_server_authentication).", 
    mail_server_helo_domain    = ".$anvil->Database->quote($mail_server_helo_domain).", 
    mail_server_password       = ".$anvil->Database->quote($mail_server_password).", 
    mail_server_port           = ".$anvil->Database->quote($mail_server_port).", 
    mail_server_security       = ".$anvil->Database->quote($mail_server_security).", 
    mail_server_username       = ".$anvil->Database->quote($mail_server_username).", 
    modified_date              = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    mail_server_uuid           = ".$anvil->Database->quote($mail_server_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($mail_server_uuid);
}


=head2 insert_or_update_manifests

This updates (or inserts) a record in the 'manifests' table. This table is used to the "manifests" used to create and repair Anvil! systems.

If there is an error, an empty string is returned. Otherwise, the record's UUID is returned.

Parameters;

=head3 delete (optional)

If set, the C<< manifest_note >> is set to C<< DELETED >>. When set to C<< 1 >>, only the C<<  >> is required

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 manifest_uuid (optional)

When set, this UUID is used to update an existing record. When not passed, the C<< manifest_name >> is used to search for a match. If found, the associated UUID is used and the record is updated. 

=head3 manifest_name (required)

This is the name of the manifest. Generally, this is the name of the Anvil! itself. It can be set to something more useful to the user, however.

=head3 manifest_last_ran (optional, default 0)

This is the unix time when the manifest was last used to (re)build an Anvil! system. If not passed, the value is not changed. If the manifest is new, this is set to C<< 0 >>.

=head3 manifest_xml (required)

This is the raw XML containing the manifest.

=head3 manifest_note (optional)

This is a free-form field for saving notes about the mnaifest. If this is set to C<< DELETED >>, it will be ignored in the web interface.

=cut
sub insert_or_update_manifests
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_manifests()" }});
	
	my $delete            = defined $parameter->{'delete'}          ? $parameter->{'delete'}          : 0;
	my $uuid              = defined $parameter->{uuid}              ? $parameter->{uuid}              : "";
	my $file              = defined $parameter->{file}              ? $parameter->{file}              : "";
	my $line              = defined $parameter->{line}              ? $parameter->{line}              : "";
	my $manifest_uuid     = defined $parameter->{manifest_uuid}     ? $parameter->{manifest_uuid}     : "";
	my $manifest_name     = defined $parameter->{manifest_name}     ? $parameter->{manifest_name}     : "";
	my $manifest_last_ran = defined $parameter->{manifest_last_ran} ? $parameter->{manifest_last_ran} : "";
	my $manifest_xml      = defined $parameter->{manifest_xml}      ? $parameter->{manifest_xml}      : "";
	my $manifest_note     = defined $parameter->{manifest_note}     ? $parameter->{manifest_note}     : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'delete'          => $delete, 
		file              => $file, 
		line              => $line, 
		manifest_uuid     => $manifest_uuid, 
		manifest_name     => $manifest_name, 
		manifest_last_ran => $manifest_last_ran, 
		manifest_xml      => $manifest_xml, 
		manifest_note     => $manifest_note, 
	}});
	
	# INSERT, but make sure we have enough data first.
	if (not $delete)
	{
		if (not $manifest_xml)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_manifests()", parameter => "manifest_xml" }});
			return("");
		}
		if (not $manifest_name)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_manifests()", parameter => "manifest_name" }});
			return("");
		}
	}
	elsif ((not $manifest_name) && (not $manifest_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0127", variables => { table => "manifests" }});
		return("");
	}
	
	# If we don't have an install manifest UUID, try to look one up using the manifest name.
	if (not $manifest_uuid)
	{
		my $query = "
SELECT 
    manifest_uuid, 
    manifest_last_ran 
FROM 
    manifests 
WHERE 
    manifest_name = ".$anvil->Database->quote($manifest_name)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		if ($count)
		{
			# If we weren't passed a 'manifest_last_ran', load the old value here.
			$manifest_uuid     = $results->[0]->[0];
			$manifest_last_ran = $results->[0]->[1] if $manifest_last_ran eq "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				manifest_uuid     => $manifest_uuid,
				manifest_last_ran => $manifest_last_ran, 
			}});
		}
		elsif ($manifest_last_ran eq "")
		{
			# This is a new manifest and 'manifest_last_ran' wasn't passed, so set it to 0.
			$manifest_last_ran = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_last_ran => $manifest_last_ran }});
		}
	}
	
	if ($delete)
	{
		if (not $manifest_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_manifests()", parameter => "manifest_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT manifest_note FROM manifests WHERE manifest_uuid = ".$anvil->Database->quote($manifest_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_manifest_note = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_manifest_note => $old_manifest_note }});
				
				if ($old_manifest_note ne "DELETED")
				{
					my $query = "
UPDATE 
    manifests 
SET 
    manifest_note = 'DELETED', 
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    manifest_uuid = ".$anvil->Database->quote($manifest_uuid)."
;";
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($manifest_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# Now, if we're inserting or updating, we'll need to require different bits.
	if ($manifest_uuid)
	{
		# Update
		my $query = "
SELECT 
    manifest_name,
    manifest_last_ran, 
    manifest_xml, 
    manifest_note 
FROM 
    manifests 
WHERE 
    manifest_uuid = ".$anvil->Database->quote($manifest_uuid).";
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		if (not $count)
		{
			# I have a manifest_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "manifest_uuid", uuid => $manifest_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_manifest_name     = $row->[0];
			my $old_manifest_last_ran = $row->[1];
			my $old_manifest_xml      = $row->[2];
			my $old_manifest_note     = $row->[3];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_manifest_name     => $old_manifest_name,
				old_manifest_last_ran => $old_manifest_last_ran,
				old_manifest_xml      => $old_manifest_xml,
				old_manifest_note     => $old_manifest_note, 
			}});
			
			# If we're here and 'manifest_last_ran' is am empty string, use the old value.
			if ($manifest_last_ran eq "")
			{
				$manifest_last_ran = $old_manifest_last_ran;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_last_ran => $manifest_last_ran }});
			}
			
			# Anything to update? This is a little extra complicated because if a variable was
			# not passed in, we want to not compare it.
			if (($manifest_name     ne $old_manifest_name)     or 
			    ($manifest_last_ran ne $old_manifest_last_ran) or 
			    ($manifest_xml      ne $old_manifest_xml)      or 
			    ($manifest_note     ne $old_manifest_note))
			{
				# UPDATE any rows passed to us.
				my $query = "
UPDATE 
    manifests
SET 
    manifest_name     = ".$anvil->Database->quote($manifest_name).", 
    manifest_last_ran = ".$anvil->Database->quote($manifest_last_ran).", 
    manifest_xml      = ".$anvil->Database->quote($manifest_xml).", 
    manifest_note     = ".$anvil->Database->quote($manifest_note).", 
    modified_date     = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE
    manifest_uuid     = ".$anvil->Database->quote($manifest_uuid)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# And INSERT
		$manifest_uuid = $anvil->Get->uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
		
		my $query = "
INSERT INTO 
    manifests 
(
    manifest_uuid, 
    manifest_name, 
    manifest_last_ran, 
    manifest_xml, 
    manifest_note,  
    modified_date
) VALUES (
    ".$anvil->Database->quote($manifest_uuid).", 
    ".$anvil->Database->quote($manifest_name).", 
    ".$anvil->Database->quote($manifest_last_ran).", 
    ".$anvil->Database->quote($manifest_xml).", 
    ".$anvil->Database->quote($manifest_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
	return($manifest_uuid);
}


=head2 insert_or_update_network_interfaces

This updates (or inserts) a record in the 'interfaces' table. This table is used to store physical network interface information.

If there is an error, an empty string is returned. Otherwise, the record's UUID is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 link_only (optional, default '0')

If this is set to C<< 1 >>, only the C<< network_interface_name >>, C<< network_interface_link_state >>, C<< network_interface_mac_address >>, C<< network_interface_operational >> and C<< network_interface_speed >> are required and analyzed. Generally, C<< timestamp >> will also be passed as this parameter is generally used to flush out cached state changes.

B<< NOTE >>: This only works for existing records. If this is passed for an interface that is not previously known, it will be ignored and no C<< network_interface_uuid >> will be returned.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 delete (optional, default '0')

When set to C<< 1 >>, the C<< network_interface_operational >> is set to C<< DELETED >>, and nothing else is changed. When set, either C<< network_interface_uuid >> or C<< network_interface_mac_address >> and C<< network_interface_name >> are needed.

=head3 network_interface_bond_uuid (optional)

If this interface is part of a bond, this UUID will be the C<< bonds >> -> C<< bond_uuid >> that this interface is slaved to.

=head3 network_interface_bridge_uuid (optional)

If this interface is connected to a bridge, this is the C<< bridges >> -> C<< bridge_uuid >> of that bridge.

=head3 network_interface_device (optional)

This is the device name (nmcli's GENERAL.IP-IFACE) of the device. This is the name shown in 'ip addr list'. When the interface is down, this will be blank. Use the MAC address ideally, or the 'connection.id' if needed, to find this interface.

=head3 network_interface_duplex (optional)

This can be set to C<< full >>, C<< half >> or C<< unknown >>, with the later being the default.

=head3 network_interface_host_uuid (optional)

This is the host's UUID, as set in C<< sys::host_uuid >>. If not passed, the host's UUID will be read from the system.

=head3 network_interface_link_state (optional)

This can be set to C<< 0 >> or C<< 1 >>, with the later being the default. This indicates if a physical link is present.

=head3 network_interface_mac_address (required)

This is the MAC address of the interface.

=head3 network_interface_medium (required)

This is the medium the interface uses. This is generally C<< copper >>, C<< fiber >>, C<< radio >>, etc.

=head3 network_interface_mtu (optional)

This is the maximum transmit unit (MTU) that this interface supports, in bytes per second. This is usally C<< 1500 >>.

=head3 network_interface_name (required)

This is the nmcli 'connection.id' name (bios device name) for the current device of this interface. If the previously recorded MAC address is no longer found, but a new/unknown interface with this name is found, it is sane to configure the device with this name as the replacement 'network_interface_device'.

=head3 network_interface_nm_uuid (optional)

This is the network manager's UUID for this interface. 

=head3 network_interface_operational (optional)

This can be set to C<< up >>, C<< down >> or C<< unknown >>, with the later being the default. This indicates whether the interface is active or not.

=head3 network_interface_speed (optional)

This is the current speed of the network interface in Mbps (megabits per second). If it is not passed, it is set to 0.

=head3 network_interface_uuid (optional)

This is the UUID of an existing record to be updated. If this is not passed, the UUID will be searched using the interface's MAC address. If no match is found, the record will be INSERTed and a new random UUID generated.

=cut
sub insert_or_update_network_interfaces
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_network_interfaces()" }});
	
	my $delete                        = defined $parameter->{'delete'}                      ? $parameter->{'delete'}                      : 0;
	my $uuid                          = defined $parameter->{uuid}                          ? $parameter->{uuid}                          : "";
	my $file                          = defined $parameter->{file}                          ? $parameter->{file}                          : "";
	my $line                          = defined $parameter->{line}                          ? $parameter->{line}                          : "";
	my $link_only                     = defined $parameter->{link_only}                     ? $parameter->{link_only}                     : 0;
	my $network_interface_bond_uuid   =         $parameter->{network_interface_bond_uuid}   ? $parameter->{network_interface_bond_uuid}   : 'NULL';
	my $network_interface_bridge_uuid =         $parameter->{network_interface_bridge_uuid} ? $parameter->{network_interface_bridge_uuid} : 'NULL';
	my $network_interface_device      = defined $parameter->{network_interface_device}      ? $parameter->{network_interface_device}      : "";
	my $network_interface_duplex      = defined $parameter->{network_interface_duplex}      ? $parameter->{network_interface_duplex}      : "unknown";
	my $network_interface_host_uuid   = defined $parameter->{network_interface_host_uuid}   ? $parameter->{network_interface_host_uuid}   : $anvil->Get->host_uuid;
	my $network_interface_link_state  = defined $parameter->{network_interface_link_state}  ? $parameter->{network_interface_link_state}  : "unknown";
	my $network_interface_operational = defined $parameter->{network_interface_operational} ? $parameter->{network_interface_operational} : "unknown";
	my $network_interface_mac_address = defined $parameter->{network_interface_mac_address} ? $parameter->{network_interface_mac_address} : "";
	my $network_interface_medium      = defined $parameter->{network_interface_medium}      ? $parameter->{network_interface_medium}      : "";
	my $network_interface_mtu         = defined $parameter->{network_interface_mtu}         ? $parameter->{network_interface_mtu}         : 0;
	my $network_interface_name        = defined $parameter->{network_interface_name}        ? $parameter->{network_interface_name}        : "";
	my $network_interface_nm_uuid     = defined $parameter->{network_interface_nm_uuid}     ? $parameter->{network_interface_nm_uuid}     : "";
	my $network_interface_speed       = defined $parameter->{network_interface_speed}       ? $parameter->{network_interface_speed}       : 0;
	my $network_interface_uuid        = defined $parameter->{network_interface_uuid}        ? $parameter->{network_interface_uuid}        : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'delete'                      => $delete, 
		uuid                          => $uuid, 
		file                          => $file, 
		line                          => $line, 
		link_only                     => $link_only, 
		network_interface_bond_uuid   => $network_interface_bond_uuid, 
		network_interface_bridge_uuid => $network_interface_bridge_uuid, 
		network_interface_device      => $network_interface_device,
		network_interface_duplex      => $network_interface_duplex, 
		network_interface_host_uuid   => $network_interface_host_uuid, 
		network_interface_link_state  => $network_interface_link_state, 
		network_interface_operational => $network_interface_operational, 
		network_interface_mac_address => $network_interface_mac_address, 
		network_interface_medium      => $network_interface_medium, 
		network_interface_mtu         => $network_interface_mtu, 
		network_interface_name        => $network_interface_name,
		network_interface_nm_uuid     => $network_interface_nm_uuid, 
		network_interface_speed       => $network_interface_speed, 
		network_interface_uuid        => $network_interface_uuid,
	}});
	
	# INSERT, but make sure we have enough data first.
	if (not $delete)
	{
		if (not $network_interface_mac_address)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_mac_address" }});
			return("");
		}
		else
		{
			# Always lower-case the MAC address.
			$network_interface_mac_address = lc($network_interface_mac_address);
		}
		if (not $network_interface_name)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_name" }});
			return("");
		}
		if (($network_interface_bond_uuid ne 'NULL') && (not $anvil->Validate->uuid({uuid => $network_interface_bond_uuid})))
		{
			# Bad UUID.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0130", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_bond_uuid", uuid => $network_interface_bond_uuid }});
			return("");
		}
		if (($network_interface_bridge_uuid ne 'NULL') && (not $anvil->Validate->uuid({uuid => $network_interface_bridge_uuid})))
		{
			# Bad UUID.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0130", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_bridge_uuid", uuid => $network_interface_bridge_uuid }});
			return("");
		}
	}
	elsif ((not $network_interface_name) && (not $network_interface_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0127", variables => { table => "network_interfaces" }});
		return("");
	}
	
	# If we don't have a network interface UUID, try to look one up using the MAC address
	if (not $network_interface_uuid)
	{
		# See if I know this NIC by referencing it's MAC (if not a vnet device), host_uuid and name. 
		# The name is needed because virtual devices can share the MAC with the real interface.
		my $query = "
SELECT 
    network_interface_uuid 
FROM 
    network_interfaces 
WHERE ";
		if ($network_interface_name !~ /^vnet/)
		{
			$query .= "
    network_interface_mac_address = ".$anvil->Database->quote($network_interface_mac_address)." 
AND ";
		}
		### TODO: We may need to switch this to 'device' if the name or MAC address isn't found
		$query .= "
    network_interface_name        = ".$anvil->Database->quote($network_interface_name)."
AND 
    network_interface_host_uuid   = ".$anvil->Database->quote($network_interface_host_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		if ($count)
		{
			$network_interface_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_interface_uuid => $network_interface_uuid }});
		}
		elsif ($network_interface_device)
		{
			# Try again using the device name.
			my $query = "
SELECT 
    network_interface_uuid 
FROM 
    network_interfaces 
WHERE ";
			if ($network_interface_name !~ /^vnet/)
			{
				$query .= "
    network_interface_mac_address = ".$anvil->Database->quote($network_interface_mac_address)." 
AND ";
			}
			### TODO: We may need to switch this to 'device' if the name or MAC address isn't found
			$query .= "
    network_interface_device      = ".$anvil->Database->quote($network_interface_device)."
AND 
    network_interface_host_uuid   = ".$anvil->Database->quote($network_interface_host_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count,
			}});
			if ($count)
			{
				$network_interface_uuid = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_interface_uuid => $network_interface_uuid }});
			}
		}
		elsif ($network_interface_name !~ /^vnet/)
		{
			# Try finding it by MAC
			my $query = "
SELECT 
    network_interface_uuid 
FROM 
    network_interfaces 
WHERE 
    network_interface_mac_address = ".$anvil->Database->quote($network_interface_mac_address)." 
AND 
    network_interface_host_uuid   = ".$anvil->Database->quote($network_interface_host_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count,
			}});
			if ($count)
			{
				$network_interface_uuid = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_interface_uuid => $network_interface_uuid }});
			}
		}
		
		if (($link_only) && (not $network_interface_uuid))
		{
			# Can't INSERT.
			return("");
		}
	}
	
	if ($delete)
	{
		if (not $network_interface_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT network_interface_operational FROM network_interfaces WHERE network_interface_uuid = ".$anvil->Database->quote($network_interface_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_network_interface_operational = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_network_interface_operational => $old_network_interface_operational }});
				
				if ($old_network_interface_operational ne "DELETED")
				{
					my $query = "
UPDATE 
    network_interfaces 
SET 
    network_interface_operational = 'DELETED', 
    modified_date                 = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    network_interface_uuid        = ".$anvil->Database->quote($network_interface_uuid)."
;";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($network_interface_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# Now, if we're inserting or updating, we'll need to require different bits.
	if ($network_interface_uuid)
	{
		# Update
		my $query = "
SELECT 
    network_interface_host_uuid, 
    network_interface_nm_uuid, 
    network_interface_mac_address, 
    network_interface_name,
    network_interface_device,
    network_interface_speed, 
    network_interface_mtu, 
    network_interface_link_state, 
    network_interface_operational, 
    network_interface_duplex, 
    network_interface_medium, 
    network_interface_bond_uuid, 
    network_interface_bridge_uuid 
FROM 
    network_interfaces 
WHERE 
    network_interface_uuid = ".$anvil->Database->quote($network_interface_uuid).";
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		if (not $count)
		{
			# I have a network_interface_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "network_interface_uuid", uuid => $network_interface_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_network_interface_host_uuid   =         $row->[0];
			my $old_network_interface_nm_uuid     = defined $row->[1]  ? $row->[1] : 'NULL';
			my $old_network_interface_mac_address =         $row->[1];
			my $old_network_interface_name        =         $row->[2];
			my $old_network_interface_device      =         $row->[3];
			my $old_network_interface_speed       =         $row->[4];
			my $old_network_interface_mtu         =         $row->[5];
			my $old_network_interface_link_state  =         $row->[6];
			my $old_network_interface_operational =         $row->[7];
			my $old_network_interface_duplex      =         $row->[8];
			my $old_network_interface_medium      =         $row->[9];
			my $old_network_interface_bond_uuid   = defined $row->[10] ? $row->[10] : 'NULL';
			my $old_network_interface_bridge_uuid = defined $row->[11] ? $row->[11] : 'NULL';
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_network_interface_host_uuid   => $old_network_interface_host_uuid,
				old_network_interface_nm_uuid     => $old_network_interface_nm_uuid, 
				old_network_interface_mac_address => $old_network_interface_mac_address,
				old_network_interface_name        => $old_network_interface_name,
				old_network_interface_device      => $old_network_interface_device,
				old_network_interface_speed       => $old_network_interface_speed,
				old_network_interface_mtu         => $old_network_interface_mtu,
				old_network_interface_link_state  => $old_network_interface_link_state,
				old_network_interface_operational => $old_network_interface_operational, 
				old_network_interface_duplex      => $old_network_interface_duplex,
				old_network_interface_medium      => $old_network_interface_medium,
				old_network_interface_bond_uuid   => $old_network_interface_bond_uuid,
				old_network_interface_bridge_uuid => $old_network_interface_bridge_uuid,
			}});
			
			# If 'link_only' is set, we're only checking/updating a subset of values.
			if ($link_only)
			{
				if (($network_interface_nm_uuid     ne $old_network_interface_nm_uuid)     or 
				    ($network_interface_name        ne $old_network_interface_name)        or 
				    ($network_interface_device      ne $old_network_interface_device)      or 
				    ($network_interface_link_state  ne $old_network_interface_link_state)  or 
				    ($network_interface_operational ne $old_network_interface_operational) or 
				    ($network_interface_mac_address ne $old_network_interface_mac_address) or 
				    ($network_interface_speed       ne $old_network_interface_speed))
				{
					# Update.
					my $query = "
UPDATE 
    network_interfaces
SET 
    network_interface_host_uuid   = ".$anvil->Database->quote($network_interface_host_uuid).", 
    network_interface_nm_uuid     = ".$anvil->Database->quote($network_interface_nm_uuid).", 
    network_interface_name        = ".$anvil->Database->quote($network_interface_name).", 
    network_interface_device      = ".$anvil->Database->quote($network_interface_device).", 
    network_interface_link_state  = ".$anvil->Database->quote($network_interface_link_state).", 
    network_interface_operational = ".$anvil->Database->quote($network_interface_operational).", 
    network_interface_mac_address = ".$anvil->Database->quote($network_interface_mac_address).", 
    network_interface_speed       = ".$anvil->Database->quote($network_interface_speed).", 
    modified_date                 = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE
    network_interface_uuid        = ".$anvil->Database->quote($network_interface_uuid)."
;";
					$query =~ s/'NULL'/NULL/g;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($network_interface_uuid);
			}
			
			# Anything to update? This is a little extra complicated because if a variable was
			# not passed in, we want to not compare it.
			if (($network_interface_bond_uuid   ne $old_network_interface_bond_uuid)   or 
			    ($network_interface_bridge_uuid ne $old_network_interface_bridge_uuid) or 
			    ($network_interface_nm_uuid     ne $old_network_interface_nm_uuid)     or 
			    ($network_interface_name        ne $old_network_interface_name)        or 
			    ($network_interface_device      ne $old_network_interface_device)      or 
			    ($network_interface_duplex      ne $old_network_interface_duplex)      or 
			    ($network_interface_link_state  ne $old_network_interface_link_state)  or 
			    ($network_interface_operational ne $old_network_interface_operational) or 
			    ($network_interface_mac_address ne $old_network_interface_mac_address) or 
			    ($network_interface_medium      ne $old_network_interface_medium)      or 
			    ($network_interface_mtu         ne $old_network_interface_mtu)         or 
			    ($network_interface_speed       ne $old_network_interface_speed)       or
			    ($network_interface_host_uuid   ne $old_network_interface_host_uuid))
			{
				# UPDATE any rows passed to us.
				my $query = "
UPDATE 
    network_interfaces
SET 
    network_interface_host_uuid   = ".$anvil->Database->quote($network_interface_host_uuid).", 
    network_interface_nm_uuid     = ".$anvil->Database->quote($network_interface_nm_uuid).", 
    network_interface_bond_uuid   = ".$anvil->Database->quote($network_interface_bond_uuid).", 
    network_interface_bridge_uuid = ".$anvil->Database->quote($network_interface_bridge_uuid).", 
    network_interface_name        = ".$anvil->Database->quote($network_interface_name).", 
    network_interface_device      = ".$anvil->Database->quote($network_interface_device).", 
    network_interface_duplex      = ".$anvil->Database->quote($network_interface_duplex).", 
    network_interface_link_state  = ".$anvil->Database->quote($network_interface_link_state).", 
    network_interface_operational = ".$anvil->Database->quote($network_interface_operational).", 
    network_interface_mac_address = ".$anvil->Database->quote($network_interface_mac_address).", 
    network_interface_medium      = ".$anvil->Database->quote($network_interface_medium).", 
    network_interface_mtu         = ".$anvil->Database->quote($network_interface_mtu).", 
    network_interface_speed       = ".$anvil->Database->quote($network_interface_speed).", 
    modified_date                 = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE
    network_interface_uuid        = ".$anvil->Database->quote($network_interface_uuid)."
;";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# And INSERT
		$network_interface_uuid = $anvil->Get->uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_interface_uuid => $network_interface_uuid }});
		
		my $query = "
INSERT INTO 
    network_interfaces 
(
    network_interface_uuid, 
    network_interface_nm_uuid, 
    network_interface_bond_uuid, 
    network_interface_bridge_uuid, 
    network_interface_name, 
    network_interface_device, 
    network_interface_duplex, 
    network_interface_host_uuid, 
    network_interface_link_state,
    network_interface_operational,  
    network_interface_mac_address, 
    network_interface_medium, 
    network_interface_mtu, 
    network_interface_speed, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($network_interface_uuid).",  
    ".$anvil->Database->quote($network_interface_nm_uuid).",  
    ".$anvil->Database->quote($network_interface_bond_uuid).", 
    ".$anvil->Database->quote($network_interface_bridge_uuid).", 
    ".$anvil->Database->quote($network_interface_name).", 
    ".$anvil->Database->quote($network_interface_device).", 
    ".$anvil->Database->quote($network_interface_duplex).", 
    ".$anvil->Database->quote($network_interface_host_uuid).", 
    ".$anvil->Database->quote($network_interface_link_state).", 
    ".$anvil->Database->quote($network_interface_operational).", 
    ".$anvil->Database->quote($network_interface_mac_address).", 
    ".$anvil->Database->quote($network_interface_medium).", 
    ".$anvil->Database->quote($network_interface_mtu).", 
    ".$anvil->Database->quote($network_interface_speed).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0126", variables => { method => "Database->insert_or_update_network_interfaces()" }});
	return($network_interface_uuid);
}


=head2 insert_or_update_mac_to_ip

This updates (or inserts) a record in the C<< mac_to_ip >> table used for tracking what MAC addresses have what IP addresses.

If there is an error, an empty string is returned.

B<< NOTE >>: The information is this table IS NOT AUTHORITATIVE! It's generally updated daily, so the information here could be stale.

Parameters;

=head3 mac_to_ip_uuid (optional)

If passed, the column with that specific C<< mac_to_ip_uuid >> will be updated, if it exists.

=head3 mac_to_ip_ip_address (required)

This is the IP address seen in use by the associated C<< mac_to_ip_mac_address >>.

=head3 mac_to_ip_mac_address (required)

This is the MAC address associated with the IP in by C<< mac_to_ip_ip_address >>.

=head3 mac_to_ip_note (optional)

This is a free-form field to store information about the host (like the host name).

=head3 update_note (optional, default '1')

When set to C<< 0 >> and nothing was passed for C<< mac_to_ip_note >>, the note will not be changed if a note exists.

B<< NOTE >>: If C<< mac_to_ip_note >> is set, it will be updated regardless of this parameter.

=cut
sub insert_or_update_mac_to_ip
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_mac_to_ip()" }});
	
	my $uuid                  = defined $parameter->{uuid}                  ? $parameter->{uuid}                  : "";
	my $file                  = defined $parameter->{file}                  ? $parameter->{file}                  : "";
	my $line                  = defined $parameter->{line}                  ? $parameter->{line}                  : "";
	my $mac_to_ip_uuid        = defined $parameter->{mac_to_ip_uuid}        ? $parameter->{mac_to_ip_uuid}        : "";
	my $mac_to_ip_mac_address = defined $parameter->{mac_to_ip_mac_address} ? $parameter->{mac_to_ip_mac_address} : "";
	my $mac_to_ip_note        = defined $parameter->{mac_to_ip_note}        ? $parameter->{mac_to_ip_note}        : "";
	my $mac_to_ip_ip_address  = defined $parameter->{mac_to_ip_ip_address}  ? $parameter->{mac_to_ip_ip_address}  : "";
	my $update_note           = defined $parameter->{update_note}           ? $parameter->{update_note}           : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                  => $uuid, 
		file                  => $file, 
		line                  => $line, 
		mac_to_ip_uuid        => $mac_to_ip_uuid, 
		mac_to_ip_mac_address => $mac_to_ip_mac_address, 
		mac_to_ip_note        => $mac_to_ip_note,
		mac_to_ip_ip_address  => $mac_to_ip_ip_address, 
		update_note           => $update_note, 
	}});
	
	if (not $mac_to_ip_mac_address)
	{
		# No user_uuid Throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_mac_to_ip()", parameter => "mac_to_ip_mac_address" }});
		return("");
	}
	if (not $mac_to_ip_ip_address)
	{
		# No user_uuid Throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_mac_to_ip()", parameter => "mac_to_ip_ip_address" }});
		return("");
	}
	
	# If the MAC isn't 12 or 17 bytes long (18 being xx:xx:xx:xx:xx:xx), or isn't a valid hex string, abort.
	if (((length($mac_to_ip_mac_address) != 12) && (length($mac_to_ip_mac_address) != 17)) or (not $anvil->Validate->hex({debug => $debug, string => $mac_to_ip_mac_address, sloppy => 1})))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0096", variables => { mac_to_ip_mac_address => $mac_to_ip_mac_address }});
		return("");
	}
	
	# If I don't have an mac_to_ip_uuid, try to find one.
	if (not $mac_to_ip_uuid)
	{
		my $query = "
SELECT 
    mac_to_ip_uuid 
FROM 
    mac_to_ip 
WHERE 
    mac_to_ip_mac_address = ".$anvil->Database->quote($mac_to_ip_mac_address)." 
AND 
    mac_to_ip_ip_address  = ".$anvil->Database->quote($mac_to_ip_ip_address)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$mac_to_ip_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac_to_ip_uuid => $mac_to_ip_uuid }});
		}
	}
	
	# If I have an mac_to_ip_uuid, see if an update is needed. If there still isn't an mac_to_ip_uuid, INSERT it.
	if ($mac_to_ip_uuid)
	{
		# Load the old data and see if anything has changed.
		my $query = "
SELECT 
    mac_to_ip_mac_address, 
    mac_to_ip_ip_address, 
    mac_to_ip_note 
FROM 
    mac_to_ip 
WHERE 
    mac_to_ip_uuid = ".$anvil->Database->quote($mac_to_ip_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a mac_to_ip_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "mac_to_ip_uuid", uuid => $mac_to_ip_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_mac_to_ip_mac_address = $row->[0];
			my $old_mac_to_ip_ip_address  = $row->[1];
			my $old_mac_to_ip_note        = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_mac_to_ip_mac_address => $old_mac_to_ip_mac_address, 
				old_mac_to_ip_ip_address  => $old_mac_to_ip_ip_address, 
				old_mac_to_ip_note        => $old_mac_to_ip_note, 
			}});
			
			my $include_note = 1;
			if ((not $update_note) && (not $mac_to_ip_note))
			{
				# Don't evaluate the note. Make the old note empty so it doesn't trigger an 
				# update below.
				$include_note        = 0;
				$old_mac_to_ip_note = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					include_note       => $include_note, 
					old_mac_to_ip_note => $old_mac_to_ip_note, 
				}});
			}
			
			# Anything change?
			if (($old_mac_to_ip_mac_address ne $mac_to_ip_mac_address) or 
			    ($old_mac_to_ip_ip_address  ne $mac_to_ip_ip_address)  or 
			    ($old_mac_to_ip_note        ne $mac_to_ip_note))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    mac_to_ip 
SET 
    mac_to_ip_mac_address = ".$anvil->Database->quote($mac_to_ip_mac_address).", 
    mac_to_ip_ip_address  = ".$anvil->Database->quote($mac_to_ip_ip_address).", ";
			if ($include_note)
			{
				$query .= "
    mac_to_ip_note        = ".$anvil->Database->quote($mac_to_ip_note).", ";
			}
			$query .= "
    modified_date         = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    mac_to_ip_uuid        = ".$anvil->Database->quote($mac_to_ip_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# Save it.
		$mac_to_ip_uuid = $anvil->Get->uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac_to_ip_uuid => $mac_to_ip_uuid }});
		
		my $query = "
INSERT INTO 
    mac_to_ip 
(
    mac_to_ip_uuid, 
    mac_to_ip_mac_address, 
    mac_to_ip_ip_address, 
    mac_to_ip_note, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($mac_to_ip_uuid).",  
    ".$anvil->Database->quote($mac_to_ip_mac_address).", 
    ".$anvil->Database->quote($mac_to_ip_ip_address).", 
    ".$anvil->Database->quote($mac_to_ip_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($mac_to_ip_uuid);
}


=head2 insert_or_update_oui

This updates (or inserts) a record in the C<< oui >> (Organizationally Unique Identifier) table used for converting network MAC addresses to the company that owns it. The C<< oui_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

B<< NOTE >>: This is one of the rare tables that doesn't have an owning host UUID.

Parameters;

=head3 oui_uuid (optional)

If passed, the column with that specific C<< oui_uuid >> will be updated, if it exists.

=head3 oui_mac_prefix (required)

This is the first 6 bytes of the MAC address owned by C<< oui_company_name >>.

=head3 oui_company_address (optional)

This is the registered address of the company that owns the OUI.

=head3 oui_company_name (required)

This is the name of the company that owns the C<< oui_mac_prefix >>.

=cut
sub insert_or_update_oui
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_oui()" }});
	
	my $uuid                = defined $parameter->{uuid}                ? $parameter->{uuid}                : "";
	my $file                = defined $parameter->{file}                ? $parameter->{file}                : "";
	my $line                = defined $parameter->{line}                ? $parameter->{line}                : "";
	my $oui_uuid            = defined $parameter->{oui_uuid}            ? $parameter->{oui_uuid}            : "";
	my $oui_mac_prefix      = defined $parameter->{oui_mac_prefix}      ? $parameter->{oui_mac_prefix}      : "";
	my $oui_company_address = defined $parameter->{oui_company_address} ? $parameter->{oui_company_address} : "";
	my $oui_company_name    = defined $parameter->{oui_company_name}    ? $parameter->{oui_company_name}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                => $uuid, 
		file                => $file, 
		line                => $line, 
		oui_uuid            => $oui_uuid, 
		oui_mac_prefix      => $oui_mac_prefix, 
		oui_company_address => $oui_company_address,
		oui_company_name    => $oui_company_name, 
	}});
	
	if (not $oui_mac_prefix)
	{
		# No user_uuid Throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_oui()", parameter => "oui_mac_prefix" }});
		return("");
	}
	if (not $oui_company_name)
	{
		# No user_uuid Throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_oui()", parameter => "oui_company_name" }});
		return("");
	}
	
	# If the MAC isn't 6 or 8 bytes long (8 being xx:xx:xx), or isn't a valid hex string, abort.
	if (((length($oui_mac_prefix) != 6) && (length($oui_mac_prefix) != 8)) or (not $anvil->Validate->hex({debug => $debug, string => $oui_mac_prefix, sloppy => 1})))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0096", variables => { oui_mac_prefix => $oui_mac_prefix }});
		return("");
	}
	
	# If I don't have an oui_uuid, try to find one.
	if (not $oui_uuid)
	{
		my $query = "
SELECT 
    oui_uuid 
FROM 
    oui 
WHERE 
    oui_mac_prefix = ".$anvil->Database->quote($oui_mac_prefix)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$oui_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { oui_uuid => $oui_uuid }});
		}
	}
	
	# If I have an oui_uuid, see if an update is needed. If there still isn't an oui_uuid, INSERT it.
	if ($oui_uuid)
	{
		# Load the old data and see if anything has changed.
		my $query = "
SELECT 
    oui_mac_prefix, 
    oui_company_address, 
    oui_company_name 
FROM 
    oui 
WHERE 
    oui_uuid = ".$anvil->Database->quote($oui_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a oui_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "oui_uuid", uuid => $oui_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_oui_mac_prefix      = $row->[0];
			my $old_oui_company_address = $row->[1];
			my $old_oui_company_name    = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_oui_mac_prefix      => $old_oui_mac_prefix, 
				old_oui_company_address => $old_oui_company_address, 
				old_oui_company_name    => $old_oui_company_name, 
			}});
			
			# Anything change?
			if (($old_oui_mac_prefix      ne $oui_mac_prefix)      or 
			    ($old_oui_company_address ne $oui_company_address) or 
			    ($old_oui_company_name    ne $oui_company_name))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    oui 
SET 
    oui_mac_prefix      = ".$anvil->Database->quote($oui_mac_prefix).", 
    oui_company_address = ".$anvil->Database->quote($oui_company_address).", 
    oui_company_name    = ".$anvil->Database->quote($oui_company_name).", 
    modified_date       = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    oui_uuid            = ".$anvil->Database->quote($oui_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# Save it.
		$oui_uuid = $anvil->Get->uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { oui_uuid => $oui_uuid }});
		
		my $query = "
INSERT INTO 
    oui 
(
    oui_uuid, 
    oui_mac_prefix, 
    oui_company_address, 
    oui_company_name, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($oui_uuid).",  
    ".$anvil->Database->quote($oui_mac_prefix).", 
    ".$anvil->Database->quote($oui_company_address).", 
    ".$anvil->Database->quote($oui_company_name).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($oui_uuid);
}


=head2 insert_or_update_power

This inserts or updates a value in the special c<< power >> table. 

This stores the most recent view of UPSes, and can be updated by any node that is able to talk to the UPS. 

If there is a problem, an empty string is returned. Otherwise, the C<< power_uuid >> is returned.

parameters;

=head3 power_uuid (optional)

Is passed, the specific entry will be updated.

=head3 power_ups_uuid (required)

This is the UPS UUID (C<< upses -> ups_uuid >> of this UPS. This is required to track that status of the UPSes powering nodes.

=head3 power_on_battery (optional, default '0')

This is used to determine when load shedding and emergency shut down actions should be taken. When set to C<< 1 >>, the UPS is considered to be drawing down it's batteries. If both/all UPSes powering a node are on batteries, load shedding will occur after a set delay. 

=head3 power_seconds_left (required)

This is the estimated hold up time, in seconds, for the UPS. Of course, this estimate will fluctuate will actual load.

=head3 power_charge_percentage (required)

This is the percentage charge of the UPS batteries. Used to determine when the dashboard should boot the node after main power returns following a power loss event.

=cut
sub insert_or_update_power
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_power()" }});
	
	my $uuid                    = defined $parameter->{uuid}                    ? $parameter->{uuid}                    : "";
	my $file                    = defined $parameter->{file}                    ? $parameter->{file}                    : "";
	my $line                    = defined $parameter->{line}                    ? $parameter->{line}                    : "";
	my $power_uuid              = defined $parameter->{power_uuid}              ? $parameter->{power_uuid}              : "";
	my $power_ups_uuid          = defined $parameter->{power_ups_uuid}          ? $parameter->{power_ups_uuid}          : 1;
	my $power_on_battery        = defined $parameter->{power_on_battery}        ? $parameter->{power_on_battery}        : 0;
	my $power_seconds_left      = defined $parameter->{power_seconds_left}      ? $parameter->{power_seconds_left}      : "";
	my $power_charge_percentage = defined $parameter->{power_charge_percentage} ? $parameter->{power_charge_percentage} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                    => $uuid, 
		file                    => $file, 
		line                    => $line, 
		power_uuid              => $power_uuid,
		power_ups_uuid          => $power_ups_uuid,
		power_on_battery        => $power_on_battery, 
		power_seconds_left      => $power_seconds_left, 
		power_charge_percentage => $power_charge_percentage, 
	}});

	if (not $power_ups_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_power()", parameter => "power_ups_uuid" }});
		return("");
	}
	if ($power_seconds_left eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_power()", parameter => "power_seconds_left" }});
		return("");
	}
	if ($power_charge_percentage eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_power()", parameter => "power_charge_percentage" }});
		return("");
	}
	
	# Convert the passed in "on battery" value to TRUE/FALSE
	$power_on_battery = $power_on_battery ? "TRUE" : "FALSE";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { power_on_battery => $power_on_battery }});
	
	# If we don't have a power UUID, see if we can find one.
	if (not $power_uuid)
	{
		my $query = "
SELECT 
    power_uuid 
FROM 
    power 
WHERE 
    power_ups_uuid = ".$anvil->Database->quote($power_ups_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$power_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { power_uuid => $power_uuid }});
		}
	}
	
	# If we have a power UUID now, look up the previous value and see if it has changed. If not, INSERT 
	# a new entry.
	if ($power_uuid)
	{
		my $query = "
SELECT 
    power_ups_uuid, 
    power_on_battery, 
    power_seconds_left, 
    power_charge_percentage 
FROM 
    power 
WHERE 
    power_uuid = ".$anvil->Database->quote($power_uuid).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# What?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "power_uuid", uuid => $power_uuid }});
			return("");
		}
		my $old_power_ups_uuid          = $results->[0]->[0];
		my $old_power_on_battery        = $results->[0]->[1];
		my $old_power_seconds_left      = $results->[0]->[2];
		my $old_power_charge_percentage = $results->[0]->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			old_power_ups_uuid          => $old_power_ups_uuid, 
			old_power_on_battery        => $old_power_on_battery, 
			old_power_seconds_left      => $old_power_seconds_left, 
			old_power_charge_percentage => $power_charge_percentage, 
		}});
		
		# Convert the read-in "on battery" value to TRUE/FALSE
		$old_power_on_battery = $old_power_on_battery ? "TRUE" : "FALSE";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_power_on_battery => $old_power_on_battery }});
		
		if (($old_power_ups_uuid          ne $power_ups_uuid)       or 
		    ($old_power_on_battery        ne $power_on_battery)     or 
		    ($old_power_seconds_left      ne $power_seconds_left)   or
		    ($old_power_charge_percentage ne $power_charge_percentage))
		{
			# Update.
			my $query = "
UPDATE 
    power 
SET 
    power_ups_uuid          = ".$anvil->Database->quote($power_ups_uuid).",
    power_on_battery        = ".$anvil->Database->quote($power_on_battery).",
    power_seconds_left      = ".$anvil->Database->quote($power_seconds_left).",
    power_charge_percentage = ".$anvil->Database->quote($power_charge_percentage).",
    modified_date           = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    power_uuid              = ".$anvil->Database->quote($power_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	else
	{
		# INSERT
		   $power_uuid = $anvil->Get->uuid();
		my $query       = "
INSERT INTO 
    power 
(
    power_uuid, 
    power_ups_uuid, 
    power_on_battery, 
    power_seconds_left, 
    power_charge_percentage, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($power_uuid).", 
    ".$anvil->Database->quote($power_ups_uuid).",
    ".$anvil->Database->quote($power_on_battery).",
    ".$anvil->Database->quote($power_seconds_left).",
    ".$anvil->Database->quote($power_charge_percentage).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($power_uuid);
}


=head2 insert_or_update_recipients

This updates (or inserts) a record in the 'recipients' table. The C<< recipient_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 delete (optional, default '0')

If set to C<< 1 >>, the associated mail server will be deleted. Specifically, the C<< recipient_name >> is set to C<< DELETED >>.

When this is set, either C<< recipient_uuid >> or C<< recipient_email >> is required.

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 recipient_email (required)

This is the email address of the recipient. This is where alerts are sent to and as such, must be a valid email address.

=head3 recipient_language (optional, default 'en_CA')

This is the language that alert emails are crafted using for this recipient. This is the ISO language code, as set in the C<< <language name="en_CA" ... > >> element of the C<< words.xml >> file. If the preferred language is not available, the system language will be used in stead.

=head3 recipient_name (required)

This is the name of the recipient, and is used when crafting the email body and reply-to lists. 

=head3 recipient_level (optional, default '2')

When adding a new Anvil! to the system, the recipient will automatically start monitoring the new Anvil! using this alert level. This can be set to C<< 0 >> to prevent auto-monitoring of new systems.

Valid values;

=head4 0 (ignore)

None, ignore new systems

=head4 1 (critical)

Critical alerts. These are alerts that almost certainly indicate an issue with the system that has are likely will cause a service interruption. (ie: node was fenced, emergency shut down, etc)

=head4 2 (warning)

Warning alerts. These are alerts that likely require the attention of an administrator, but have not caused a service interruption. (ie: power loss/load shed, over/under voltage, fan failure, network link failure, etc)

=head4 3 (notice)

Notice alerts. These are generally low priority alerts that do not need attention, but might be indicators of developing problems. (ie: UPSes transfering to batteries, server migration/shut down/boot up, etc)

=head4 4 (info)

Info alerts. These are generally for debugging, and will generating a staggering number of alerts. Not recommended for most cases.

=head3 recipient_uuid (optional)

If set, this is the UUID that will be used to update a record in the database. If not set, it will be searched for by looking for a matching C<< recipient_email >>.

=cut
sub insert_or_update_recipients
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_recipients()" }});
	
	my $delete             = defined $parameter->{'delete'}           ? $parameter->{'delete'}           : 0;
	my $uuid               = defined $parameter->{uuid}               ? $parameter->{uuid}               : "";
	my $file               = defined $parameter->{file}               ? $parameter->{file}               : "";
	my $line               = defined $parameter->{line}               ? $parameter->{line}               : "";
	my $recipient_email    = defined $parameter->{recipient_email}    ? $parameter->{recipient_email}    : "";
	my $recipient_language = defined $parameter->{recipient_language} ? $parameter->{recipient_language} : "en_CA";
	my $recipient_name     = defined $parameter->{recipient_name}     ? $parameter->{recipient_name}     : "";
	my $recipient_level    = defined $parameter->{recipient_level}    ? $parameter->{recipient_level}    : "2";
	my $recipient_uuid     = defined $parameter->{recipient_uuid}     ? $parameter->{recipient_uuid}     : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'delete'           => $delete, 
		uuid               => $uuid, 
		file               => $file, 
		line               => $line, 
		recipient_email    => $recipient_email, 
		recipient_language => $recipient_language, 
		recipient_name     => $recipient_name, 
		recipient_level    => $recipient_level, 
		recipient_uuid     => $recipient_uuid, 
	}});
	
	# Did we get a mail server name? 
	if ((not $recipient_email) && (not $recipient_uuid))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_recipients()", parameter => "recipient_email" }});
		return("");
	}
	
	# Make sure the recipient_level is 0, 1, 2 or 3
	if (($recipient_level =~ /\D/) or ($recipient_level < 0) or ($recipient_level > 4))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0108", variables => { recipient_level => $recipient_level }});
		return("");
	}
	
	if (not $recipient_uuid)
	{
		# Can we find it using the mail server address?
		my $query = "
SELECT 
    recipient_uuid 
FROM 
    recipients 
WHERE 
    recipient_email = ".$anvil->Database->quote($recipient_email)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$recipient_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { recipient_uuid => $recipient_uuid }});
		}
	}
	
	if ($delete)
	{
		if (not $recipient_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_recipients()", parameter => "recipient_uuid" }});
			return("");
		}
		else
		{
			# Delete it
			my $query = "SELECT recipient_name FROM recipients WHERE recipient_uuid = ".$anvil->Database->quote($recipient_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			if ($count)
			{
				my $old_recipient_name = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_recipient_name => $old_recipient_name }});
				
				if ($old_recipient_name ne "DELETED")
				{
					my $query = "
UPDATE 
    recipients 
SET 
    recipient_name = 'DELETED', 
    modified_date  = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    recipient_uuid = ".$anvil->Database->quote($recipient_uuid)."
;";
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
				return($recipient_uuid);
			}
			else
			{
				# Not found.
				return("");
			}
		}
	}
	
	# If we're here and we still don't have a recipient name, there's a problem.
	if (not $recipient_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_recipients()", parameter => "recipient_name" }});
		return("");
	}
	
	# If I still don't have an recipient_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { recipient_uuid => $recipient_uuid }});
	if (not $recipient_uuid)
	{
		# INSERT
		$recipient_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { recipient_uuid => $recipient_uuid }});
		
		my $query = "
INSERT INTO 
    recipients 
(
    recipient_uuid, 
    recipient_email, 
    recipient_language, 
    recipient_name, 
    recipient_level, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($recipient_uuid).", 
    ".$anvil->Database->quote($recipient_email).", 
    ".$anvil->Database->quote($recipient_language).", 
    ".$anvil->Database->quote($recipient_name).", 
    ".$anvil->Database->quote($recipient_level).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    recipient_email, 
    recipient_language, 
    recipient_name, 
    recipient_level 
FROM 
    recipients 
WHERE 
    recipient_uuid = ".$anvil->Database->quote($recipient_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a recipient_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "recipient_uuid", uuid => $recipient_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_recipient_email    = $row->[0]; 
			my $old_recipient_language = $row->[1];
			my $old_recipient_name     = $row->[2]; 
			my $old_recipient_level    = $row->[3]; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_recipient_email    => $old_recipient_email, 
				old_recipient_language => $old_recipient_language,
				old_recipient_name     => $old_recipient_name, 
				old_recipient_level    => $old_recipient_level, 
			}});
			
			# Anything change?
			if (($old_recipient_email    ne $recipient_email)    or 
			    ($old_recipient_language ne $recipient_language) or 
			    ($old_recipient_name     ne $recipient_name)     or  
			    ($old_recipient_level    ne $recipient_level))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    recipients 
SET 
    recipient_email    = ".$anvil->Database->quote($recipient_email).", 
    recipient_language = ".$anvil->Database->quote($recipient_language).", 
    recipient_name     = ".$anvil->Database->quote($recipient_name).", 
    recipient_level    = ".$anvil->Database->quote($recipient_level).", 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    recipient_uuid     = ".$anvil->Database->quote($recipient_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($recipient_uuid);
}


=head2 insert_or_update_servers

This updates (or inserts) a record in the 'sessions' table. The C<< server_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 delete (optional, default '0')

If set to C<< 1 >>, the server referenced but the C<< server_uuid >> is marked as deleted. 

B<< Note >>: If this is set to C<< 1 >>, then only C<< server_uuid >> is required.

=head3 server_uuid (required)

This is the Server's UUID. In most tables, if a record doesn't exist then a random UUID is generated to create the new record. 

In the C<< servers >> table however, the UUID used is the UUID in the server's definition file. As such, this parameter is always required.

=head3 server_name (required)

This is the name of the server being added.

=head3 server_anvil_uuid (required)

This is the C<< anvils >> -> C<< anvil_uuid >> that this server is currently hosted on.

=head3 server_user_stop (optional, default '0')

This indicates when a server was stopped by a user. If this is set to C<< 1 >>, then the Anvil! will not boot the server (during an C<< anvil-safe-start >> run). 

=head3 server_start_after_server_uuid (optional)

If the user wants to boot this server after another server, this can be set to C<< servers >> -> C<< server_uuid >>. When set, the server referenced will be booted (at least) C<< server_start_delay >> seconds before this server is booted.

=head3 server_start_delay (optional, default '0')

If C<< server_start_after_server_uuid >> is set, then this value controls the delay between when the referenced server boots and when this server boots. This value is ignored if the server is not set to boot after another server.

B<< Note >>: This is the B<< minimum >> delay! It's possible that the actual delay could be a bit more than this value.

=head3 server_host_uuid (optional)

If the server is running, this is the C<< current hosts >> -> C<< host_uuid >> for this server. If the server is off, this will should be blank.

B<< Note >>: If the server is migating, this should be the old host until after the migration completes.

=head3 server_state (required)

This is the current status of the server. The values come from C<< virsh >> and are:

* running     - The domain is currently running on a CPU
* idle        - The domain is idle, and not running or runnable.  This can be caused because the domain is waiting on IO (a traditional wait state) or has gone to sleep because there was nothing else for it to do.
* paused      - The domain has been paused, usually occurring through the administrator running virsh suspend.  When in a paused state the domain will still consume allocated resources like memory, but will not be eligible for scheduling by the hypervisor.
* in shutdown - The domain is in the process of shutting down, i.e. the guest operating system has been notified and should be in the process of stopping its operations gracefully.
* shut off    - The domain is not running.  Usually this indicates the domain has been shut down completely, or has not been started.
* crashed     - The domain has crashed, which is always a violent ending.  Usually this state can only occur if the domain has been configured not to restart on crash.
* pmsuspended - The domain has been suspended by guest power management, e.g. entered into s3 state.
* migrating   - B<< Note >>: This is special, in that it's set by the Anvil! while a server is migrating between hosts.
* DELETED     - B<< Note >>: This is special, in that it marks the server as no longer exists and comes from the Anvil!, not C<< virsh >>.

=head3 server_live_migration (optional, default '1')

Normally, when a server migrates the server keeps running, with changes to memory being tracked and copied. When most of the memory has been copied, the server is frozen for a brief moment, the last of the memory is copied, and then the server is thawed on the new host.

In some cases, with servers that have a lot of RAM or very quickly change the memory contents, a migation could take a very long time to complete, if it ever does at all. 

For cases where a server can't be live migrated, set this to C<< 0 >>. When set to C<< 0 >>, the server is frozen before the RAM copy begins, and thawed on the new host when the migration is complete. In this way, the migration can be completed over a relatively short time. The tradeoff is that connections to the server could time out.

B<< Note >>: Depending on the BCN network speed and the amount of RAM to copy, the server could be in a frozen state long enough for client connections to timeout. The server itself should handle the freeze fine in most modern systems.

=head3 server_pre_migration_file_uuid (optional)

This is set to the C<< files >> -> C<< file_uuid >> of a script to run B<< BEFORE >> migrating a server. If the file isn't found or can't be run, the script is ignored.

=head3 server_pre_migration_arguments (optional)

These are arguments to pass to the pre-migration script above. 

=head3 server_post_migration_file_uuid (optional)

This is set to the C<< files >> -> C<< file_uuid >> of a script to run B<< AFTER >> migrating a server. If the file isn't found or can't run, the script is ignored.

=head3 server_post_migration_arguments (optional)

These are arguments to pass to the post-migration script above.

=head3 server_ram_in_use (optional, default '0')

This column, along with C<< server_configured_ram >>, is used to handle when the amount of RAM (in bytes) allocated to a server in the on-disk definition differs from the amount of RAM currently used by a running server. This can occur when a user has changed the allocated RAM but the server has not yet been poewr cycled to pick up the change.

B<< Note >>: If this is set to C<< 0 >>, it doesn't mean that the server has no RAM! 

The only time this and C<< server_configured_ram >> matters is when both are set to non-zero values and differ. Otherwise, these columns are ignored and the RAM is parsed from the XML definition data stored in the associated C<< server_definitions >> -> C<< server_definition_xml >>.

=head3 server_configured_ram (optional, default '0')

This is used to store the amount of RAM (in bytes) allocated to a server as stored in the on-disk XML file.

See C<< server_ram_in_use >> for more information.

=head3 server_updated_by_user (optional, default 0)

This is set to a unix timestamp when the user last updated the definition. When set, scan-server will check this value against the age of the definition file on disk. If this is newer and the running definition is different from the database definition, the database definition will be used to update the on-disk definition.

=head3 server_boot_time (optional, default 0)

This is the unix time (since epoch) when the server booted. It is calculated by checking the C<< ps -p <pid> -o etimes= >> when a server is seen to be running when it had be last seen as off. If a server that had been running is seen to be off, this is set back to 0.

=cut
sub insert_or_update_servers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_servers()" }});
	
	my $uuid                            = defined $parameter->{uuid}                            ? $parameter->{uuid}                            : "";
	my $file                            = defined $parameter->{file}                            ? $parameter->{file}                            : "";
	my $line                            = defined $parameter->{line}                            ? $parameter->{line}                            : "";
	my $delete                          = defined $parameter->{'delete'}                        ? $parameter->{'delete'}                        : 0;
	my $server_uuid                     = defined $parameter->{server_uuid}                     ? $parameter->{server_uuid}                     : "";
	my $server_name                     = defined $parameter->{server_name}                     ? $parameter->{server_name}                     : "";
	my $server_anvil_uuid               = defined $parameter->{server_anvil_uuid}               ? $parameter->{server_anvil_uuid}               : "";
	my $server_user_stop                = defined $parameter->{server_user_stop}                ? $parameter->{server_user_stop}                : "FALSE";
	my $server_start_after_server_uuid  = defined $parameter->{server_start_after_server_uuid}  ? $parameter->{server_start_after_server_uuid}  : "NULL";
	my $server_start_delay              = defined $parameter->{server_start_delay}              ? $parameter->{server_start_delay}              : 30;
	my $server_host_uuid                = defined $parameter->{server_host_uuid}                ? $parameter->{server_host_uuid}                : "NULL";
	my $server_state                    = defined $parameter->{server_state}                    ? $parameter->{server_state}                    : "";
	my $server_live_migration           = defined $parameter->{server_live_migration}           ? $parameter->{server_live_migration}           : "TRUE";
	my $server_pre_migration_file_uuid  = defined $parameter->{server_pre_migration_file_uuid}  ? $parameter->{server_pre_migration_file_uuid}  : "NULL";
	my $server_pre_migration_arguments  = defined $parameter->{server_pre_migration_arguments}  ? $parameter->{server_pre_migration_arguments}  : "";
	my $server_post_migration_file_uuid = defined $parameter->{server_post_migration_file_uuid} ? $parameter->{server_post_migration_file_uuid} : "NULL";
	my $server_post_migration_arguments = defined $parameter->{server_post_migration_arguments} ? $parameter->{server_post_migration_arguments} : "";
	my $server_ram_in_use               = defined $parameter->{server_ram_in_use}               ? $parameter->{server_ram_in_use}               : 0;
	my $server_configured_ram           = defined $parameter->{server_configured_ram}           ? $parameter->{server_configured_ram}           : 0;
	my $server_updated_by_user          = defined $parameter->{server_updated_by_user}          ? $parameter->{server_updated_by_user}          : 0;
	my $server_boot_time                = defined $parameter->{server_boot_time}                ? $parameter->{server_boot_time}                : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'delete'                        => $delete, 
		uuid                            => $uuid, 
		file                            => $file, 
		line                            => $line, 
		server_uuid                     => $server_uuid, 
		server_name                     => $server_name, 
		server_anvil_uuid               => $server_anvil_uuid,
		server_user_stop                => $server_user_stop,
		server_start_after_server_uuid  => $server_start_after_server_uuid,
		server_start_delay              => $server_start_delay,
		server_host_uuid                => $server_host_uuid,
		server_state                    => $server_state,
		server_live_migration           => $server_live_migration,
		server_pre_migration_file_uuid  => $server_pre_migration_file_uuid,
		server_pre_migration_arguments  => $server_pre_migration_arguments,
		server_post_migration_file_uuid => $server_post_migration_file_uuid,
		server_post_migration_arguments => $server_post_migration_arguments, 
		server_ram_in_use               => $server_ram_in_use,
		server_configured_ram           => $server_configured_ram,
		server_updated_by_user          => $server_updated_by_user, 
		server_boot_time                => $server_boot_time, 
	}});
	
	if (not $server_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_servers()", parameter => "server_uuid" }});
		return("!!error!!");
	}
	if (not $anvil->Validate->uuid({uuid => $server_uuid}))
	{
		# invalid UUID
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0160", variables => { variable => "server_uuid", uuid => $server_uuid }});
		return("!!error!!");
	}
	if (not $delete)
	{
		if (not $server_name)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_servers()", parameter => "server_name" }});
			return("!!error!!");
		}
		if (not $server_anvil_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_servers()", parameter => "server_anvil_uuid" }});
			return("!!error!!");
		}
		if (not $server_state)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_servers()", parameter => "server_state" }});
			return("!!error!!");
		}
	}
	
	# Do we already know about this 
	my $exists = 0; 
	my $query  = "SELECT COUNT(*) FROM servers WHERE server_uuid = ".$anvil->Database->quote($server_uuid).";";
	my $count  = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
	if ($count)
	{
		$exists = 1;
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'exists' => $exists }});
	
	if ($delete)
	{
		if (not $exists)
		{
			# Can't delete what doesn't exist...
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0161", variables => { server_uuid => "server_uuid" }});
			return("!!error!!");
		}

		# Delete it
		my $query = "SELECT server_state FROM servers WHERE server_uuid = ".$anvil->Database->quote($server_uuid).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});

		my $old_server_state = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_server_state => $old_server_state }});
		
		if ($old_server_state ne "DELETED")
		{
			my $query = "
UPDATE 
    servers 
SET 
    server_state  = 'DELETED', 
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE 
    server_uuid   = ".$anvil->Database->quote($server_uuid)."
;";
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
		return($server_uuid);
	}
	
	### TODO: Remove this eventually. There is a bug somewhere that is storing RAM in KiB, not Bytes.
	if (($server_configured_ram < 655360) or ($server_ram_in_use < 655360))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0472", variables => { 
			server_name    => $server_name, 
			configured_ram => $server_configured_ram,
			ram_in_use     => $server_ram_in_use, 
		}});
		return("!!error!!");
	}
	
	# Are we updating or inserting?
	if (not $exists)
	{
		# INSERT
		my $query = "
INSERT INTO 
    servers 
(
    server_uuid, 
    server_name, 
    server_anvil_uuid, 
    server_user_stop, 
    server_start_after_server_uuid, 
    server_start_delay, 
    server_host_uuid, 
    server_state, 
    server_live_migration, 
    server_pre_migration_file_uuid, 
    server_pre_migration_arguments, 
    server_post_migration_file_uuid, 
    server_post_migration_arguments, 
    server_ram_in_use, 
    server_configured_ram, 
    server_updated_by_user, 
    server_boot_time, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($server_uuid).", 
    ".$anvil->Database->quote($server_name).", 
    ".$anvil->Database->quote($server_anvil_uuid).", 
    ".$anvil->Database->quote($server_user_stop).", 
    ".$anvil->Database->quote($server_start_after_server_uuid).", 
    ".$anvil->Database->quote($server_start_delay).", 
    ".$anvil->Database->quote($server_host_uuid).", 
    ".$anvil->Database->quote($server_state).", 
    ".$anvil->Database->quote($server_live_migration).", 
    ".$anvil->Database->quote($server_pre_migration_file_uuid).", 
    ".$anvil->Database->quote($server_pre_migration_arguments).", 
    ".$anvil->Database->quote($server_post_migration_file_uuid).", 
    ".$anvil->Database->quote($server_post_migration_arguments).", 
    ".$anvil->Database->quote($server_ram_in_use).", 
    ".$anvil->Database->quote($server_configured_ram).", 
    ".$anvil->Database->quote($server_updated_by_user).", 
    ".$anvil->Database->quote($server_boot_time).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    server_name, 
    server_anvil_uuid, 
    server_user_stop, 
    server_start_after_server_uuid, 
    server_start_delay, 
    server_host_uuid, 
    server_state, 
    server_live_migration, 
    server_pre_migration_file_uuid, 
    server_pre_migration_arguments, 
    server_post_migration_file_uuid, 
    server_post_migration_arguments, 
    server_ram_in_use, 
    server_configured_ram, 
    server_updated_by_user, 
    server_boot_time 
FROM 
    servers 
WHERE 
    server_uuid = ".$anvil->Database->quote($server_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a server_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "server_uuid", uuid => $server_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_server_name                     =         $row->[0];
			my $old_server_anvil_uuid               =         $row->[1]; 
			my $old_server_user_stop                =         $row->[2]; 
			my $old_server_start_after_server_uuid  = defined $row->[3]  ? $row->[3]  : 'NULL'; 
			my $old_server_start_delay              =         $row->[4]; 
			my $old_server_host_uuid                = defined $row->[5]  ? $row->[5]  : 'NULL'; 
			my $old_server_state                    =         $row->[6]; 
			my $old_server_live_migration           =         $row->[7]; 
			my $old_server_pre_migration_file_uuid  = defined $row->[8]  ? $row->[8]  : 'NULL'; 
			my $old_server_pre_migration_arguments  =         $row->[9]; 
			my $old_server_post_migration_file_uuid = defined $row->[10] ? $row->[10] : 'NULL'; 
			my $old_server_post_migration_arguments =         $row->[11]; 
			my $old_server_ram_in_use               =         $row->[12];
			my $old_server_configured_ram           =         $row->[13];
			my $old_server_updated_by_user          =         $row->[14];
			my $old_server_boot_time                =         $row->[15];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_server_name                     => $old_server_name, 
				old_server_anvil_uuid               => $old_server_anvil_uuid, 
				old_server_user_stop                => $old_server_user_stop, 
				old_server_start_after_server_uuid  => $old_server_start_after_server_uuid, 
				old_server_start_delay              => $old_server_start_delay, 
				old_server_host_uuid                => $old_server_host_uuid, 
				old_server_state                    => $old_server_state, 
				old_server_live_migration           => $old_server_live_migration, 
				old_server_pre_migration_file_uuid  => $old_server_pre_migration_file_uuid, 
				old_server_pre_migration_arguments  => $old_server_pre_migration_arguments, 
				old_server_post_migration_file_uuid => $old_server_post_migration_file_uuid, 
				old_server_post_migration_arguments => $old_server_post_migration_arguments, 
				old_server_ram_in_use               => $old_server_ram_in_use, 
				old_server_configured_ram           => $old_server_configured_ram, 
				old_server_updated_by_user          => $old_server_updated_by_user,
				old_server_boot_time                => $old_server_boot_time,
			}});
			
			# Anything change?
			if (($old_server_name                     ne $server_name)                     or  
			    ($old_server_anvil_uuid               ne $server_anvil_uuid)               or 
			    ($old_server_user_stop                ne $server_user_stop)                or 
			    ($old_server_start_after_server_uuid  ne $server_start_after_server_uuid)  or 
			    ($old_server_start_delay              ne $server_start_delay)              or 
			    ($old_server_host_uuid                ne $server_host_uuid)                or 
			    ($old_server_state                    ne $server_state)                    or 
			    ($old_server_live_migration           ne $server_live_migration)           or 
			    ($old_server_pre_migration_file_uuid  ne $server_pre_migration_file_uuid)  or 
			    ($old_server_pre_migration_arguments  ne $server_pre_migration_arguments)  or 
			    ($old_server_post_migration_file_uuid ne $server_post_migration_file_uuid) or 
			    ($old_server_post_migration_arguments ne $server_post_migration_arguments) or 
			    ($old_server_ram_in_use               ne $server_ram_in_use)               or 
			    ($old_server_configured_ram           ne $server_configured_ram)           or
			    ($old_server_updated_by_user          ne $server_updated_by_user)          or 
			    ($old_server_boot_time                ne $server_boot_time)) 
			{
				# Something changed, save.
				my $query = "
UPDATE 
    servers 
SET 
    server_name                     = ".$anvil->Database->quote($server_name).", 
    server_anvil_uuid               = ".$anvil->Database->quote($server_anvil_uuid).", 
    server_user_stop                = ".$anvil->Database->quote($server_user_stop).", 
    server_start_after_server_uuid  = ".$anvil->Database->quote($server_start_after_server_uuid).", 
    server_start_delay              = ".$anvil->Database->quote($server_start_delay).", 
    server_host_uuid                = ".$anvil->Database->quote($server_host_uuid).", 
    server_state                    = ".$anvil->Database->quote($server_state).", 
    server_live_migration           = ".$anvil->Database->quote($server_live_migration).", 
    server_pre_migration_file_uuid  = ".$anvil->Database->quote($server_pre_migration_file_uuid).", 
    server_pre_migration_arguments  = ".$anvil->Database->quote($server_pre_migration_arguments).", 
    server_post_migration_file_uuid = ".$anvil->Database->quote($server_post_migration_file_uuid).", 
    server_post_migration_arguments = ".$anvil->Database->quote($server_post_migration_arguments).", 
    server_ram_in_use               = ".$anvil->Database->quote($server_ram_in_use).", 
    server_configured_ram           = ".$anvil->Database->quote($server_configured_ram).", 
    server_updated_by_user          = ".$anvil->Database->quote($server_updated_by_user).", 
    server_boot_time                = ".$anvil->Database->quote($server_boot_time).", 
    modified_date                   = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid                     = ".$anvil->Database->quote($server_uuid)." 
";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	return($server_uuid);
}


=head2 insert_or_update_server_definitions

This inserts or updates the C<< server_definitions >> table used to store (virtual) server XML definitions.

Parameters;

=head3 server_definition_uuid (optional)

This is the server_definition UUID of a specific record to update. 

=head3 server_definition_server_uuid (required)

This is the C<< servers >> -> C<< server_uuid >> of the server whose server_definition this belongs to.

server_definition_xml (required)

This is the server's XML definition file itself.

=cut
sub insert_or_update_server_definitions
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_server_definitions()" }});
	
	my $uuid                          = defined $parameter->{uuid}                          ? $parameter->{uuid}                          : "";
	my $file                          = defined $parameter->{file}                          ? $parameter->{file}                          : "";
	my $line                          = defined $parameter->{line}                          ? $parameter->{line}                          : "";
	my $server_definition_uuid        = defined $parameter->{server_definition_uuid}        ? $parameter->{server_definition_uuid}        : "";
	my $server_definition_server_uuid = defined $parameter->{server_definition_server_uuid} ? $parameter->{server_definition_server_uuid} : "";
	my $server_definition_xml         = defined $parameter->{server_definition_xml}         ? $parameter->{server_definition_xml}         : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                          => $uuid, 
		file                          => $file, 
		line                          => $line, 
		server_definition_uuid        => $server_definition_uuid, 
		server_definition_server_uuid => $server_definition_server_uuid, 
		server_definition_xml         => $server_definition_xml, 
	}});
	
	if (not $server_definition_server_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_server_definitions()", parameter => "server_definition_server_uuid" }});
		return("!!error!!");
	}
	if (not $anvil->Validate->uuid({uuid => $server_definition_server_uuid}))
	{
		# Bad UUID.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0130", variables => { method => "Database->insert_or_update_server_definitions()", parameter => "server_definition_server_uuid", uuid => $server_definition_server_uuid }});
		return("!!error!!");
	}
	if (not $server_definition_xml)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_server_definitions()", parameter => "server_definition_xml" }});
		return("!!error!!");
	}
	
	# Make sure the server_definition_xml looks valid.
	local $@;
	my $dom = eval { XML::LibXML->load_xml(string => $server_definition_xml); };
	if ($@)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0066", variables => { 
			xml   => $server_definition_xml,
			error => $@,
		}});
		return("!!error!!");
	}
	
	# Verify that I can read the UUID from the XML and verify that it matches the 
	# 'server_definition_server_uuid'.
	my $server_name = $dom->findvalue('/domain/name');
	my $read_uuid   = $dom->findvalue('/domain/uuid');
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server_name => $server_name, 
		read_uuid   => $read_uuid,
	}});
	
	if (not $read_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0067", variables => { xml => $server_definition_xml }});
		return("!!error!!");
	}
	elsif ($read_uuid ne $server_definition_server_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0067", variables => { 
			passed_uuid => $server_definition_server_uuid,
			read_uuid   => $read_uuid,
			xml         => $server_definition_xml,
		}});
		return("!!error!!");
	}
	
	# If we don't have a server_definition_uuid, look for one using the server_uuid.
	if (not $server_definition_uuid)
	{
		my $query = "
SELECT 
    server_definition_uuid 
FROM 
    server_definitions 
WHERE 
    server_definition_server_uuid = ".$anvil->Database->quote($server_definition_server_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$server_definition_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_definition_uuid => $server_definition_uuid }});
		}
	}
	
	# UPDATE or INSERT.
	if ($server_definition_uuid)
	{
		# Is there any difference?
		my $query = "
SELECT 
    server_definition_server_uuid, 
    server_definition_xml 
FROM 
    server_definitions 
WHERE 
    server_definition_uuid = ".$anvil->Database->quote($server_definition_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $old_server_definition_server_uuid = $row->[0];
			my $old_server_definition_xml         = $row->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
				old_server_definition_server_uuid => $old_server_definition_server_uuid,
				old_server_definition_xml         => $old_server_definition_xml, 
			}});
			if (($old_server_definition_server_uuid ne $server_definition_server_uuid) or 
			    ($old_server_definition_xml         ne $server_definition_xml))
			{
				# If the server_definition is what changed, log the diff.
				if ($old_server_definition_xml ne $server_definition_xml)
				{
					my $difference = diff \$old_server_definition_xml, \$server_definition_xml, { STYLE => 'Unified' };
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0556", variables => { 
						server_name => $server_name,
						server_uuid => $server_definition_server_uuid, 
						difference  => $difference,
					}});
				}
				
				# Save the changes.
				my $query = "
UPDATE 
    server_definitions
SET 
    server_definition_xml         = ".$anvil->Database->quote($server_definition_xml).", 
    server_definition_server_uuid = ".$anvil->Database->quote($server_definition_server_uuid).", 
    modified_date                 = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    server_definition_uuid        = ".$anvil->Database->quote($server_definition_uuid)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		   $server_definition_uuid = $anvil->Get->uuid();
		my $query = "
INSERT INTO 
    server_definitions 
(
    server_definition_uuid, 
    server_definition_server_uuid, 
    server_definition_xml, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($server_definition_uuid).", 
    ".$anvil->Database->quote($server_definition_server_uuid).",
    ".$anvil->Database->quote($server_definition_xml).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($server_definition_uuid);
}


=head2 insert_or_update_sessions

This updates (or inserts) a record in the 'sessions' table. The C<< session_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 session_uuid (optional)

If passed, the column with that specific C<< session_uuid >> will be updated, if it exists.

=head3 session_host_uuid (optional, default Get->host_uuid)

This is the host connected to the user's session.

=head3 session_user_uuid (optional, default 'cookie::anvil_user_uuid')

This is the user whose session is being manipulated. If this is not passed and C<< cookie::anvil_user_uuid >> is not set, this method will fail and return an empty string. This is only optional in so far as, most times, the appropriate cookie data is available.

=head3 session_salt (optional)

The session salt is appended to a session hash stored on the user's browser and used to authenticate a user session. If this is not passed, the existing salt will be removed, effectively (and literally) logging the user out of the host.

=head3 session_user_agent (optional, default '$ENV{HTTP_USER_AGENT})

This is the browser user agent string to record. If nothing is passed, and the C<< HTTP_USER_AGENT >> environment variable is set, that is used. 

=cut 
sub insert_or_update_sessions
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_sessions()" }});
	
	my $uuid               = defined $parameter->{uuid}               ? $parameter->{uuid}               : "";
	my $file               = defined $parameter->{file}               ? $parameter->{file}               : "";
	my $line               = defined $parameter->{line}               ? $parameter->{line}               : "";
	my $session_uuid       = defined $parameter->{session_uuid}       ? $parameter->{session_uuid}       : "";
	my $session_host_uuid  = defined $parameter->{session_host_uuid}  ? $parameter->{session_host_uuid}  : $anvil->Get->host_uuid;
	my $session_user_uuid  = defined $parameter->{session_user_uuid}  ? $parameter->{session_user_uuid}  : $anvil->data->{cookie}{anvil_user_uuid};
	my $session_salt       = defined $parameter->{session_salt}       ? $parameter->{session_salt}       : "";
	my $session_user_agent = defined $parameter->{session_user_agent} ? $parameter->{session_user_agent} : $ENV{HTTP_USER_AGENT};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid               => $uuid, 
		file               => $file, 
		line               => $line, 
		session_uuid       => $session_uuid, 
		session_host_uuid  => $session_host_uuid, 
		session_user_uuid  => $session_user_uuid, 
		session_salt       => $session_salt, 
		session_user_agent => $session_user_agent, 
	}});
	
	if (not $session_user_uuid)
	{
		# No user_uuid Throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_sessions()", parameter => "session_user_uuid" }});
		return("");
	}
	
	# If we don't have a session UUID, look for one using the host and user UUID.
	if (not $session_uuid)
	{
		my $query = "
SELECT 
    session_uuid 
FROM 
    sessions 
WHERE 
    session_user_uuid = ".$anvil->Database->quote($session_user_uuid)." 
AND 
    session_host_uuid = ".$anvil->Database->quote($session_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$session_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { session_uuid => $session_uuid }});
		}
	}
	
	# If we have a session UUID, check for changes before updating. If we still don't have a session 
	# UUID, we're INSERT'ing.
	if ($session_uuid)
	{
		# Read back the old data
		my $query = "
SELECT 
    session_host_uuid, 
    session_user_uuid, 
    session_salt, 
    session_user_agent 
FROM 
    sessions 
WHERE 
    session_uuid = ".$anvil->Database->quote($session_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a session_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "session_uuid", uuid => $session_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_session_host_uuid  =         $row->[0];
			my $old_session_user_uuid  =         $row->[1];
			my $old_session_salt       =         $row->[2];
			my $old_session_user_agent = defined $row->[3] ? $row->[3] : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_session_host_uuid  => $old_session_host_uuid, 
				old_session_user_uuid  => $old_session_user_uuid, 
				old_session_salt       => $old_session_salt, 
				old_session_user_agent => $old_session_user_agent, 
			}});
			
			# Anything change?
			if (($old_session_host_uuid  ne $session_host_uuid) or 
			    ($old_session_user_uuid  ne $session_user_uuid) or 
			    ($old_session_salt       ne $session_salt)      or 
			    ($old_session_user_agent ne $session_user_agent))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    sessions 
SET 
    session_host_uuid  = ".$anvil->Database->quote($session_host_uuid).",  
    session_user_uuid  = ".$anvil->Database->quote($session_user_uuid).", 
    session_salt       = ".$anvil->Database->quote($session_salt).", 
    session_user_agent = ".$anvil->Database->quote($session_user_agent).", 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    session_uuid       = ".$anvil->Database->quote($session_uuid)." 
";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		$session_uuid = $anvil->Get->uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { session_uuid => $session_uuid }});
		
		my $query = "
INSERT INTO 
    sessions 
(
    session_uuid, 
    session_host_uuid, 
    session_user_uuid, 
    session_salt, 
    session_user_agent, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($session_uuid).",  
    ".$anvil->Database->quote($session_host_uuid).", 
    ".$anvil->Database->quote($session_user_uuid).", 
    ".$anvil->Database->quote($session_salt).", 
    ".$anvil->Database->quote($session_user_agent).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($session_uuid);
}


=head2 insert_or_update_ssh_keys

This updates (or inserts) a record in the 'ssh_keys' table. The C<< ssh_key_uuid >> UUID will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 ssh_key_host_uuid (optional, default is Get->host_uuid)

This is the host that the corresponding user and key belong to.

=head3 ssh_key_public_key (required)

This is the B<<PUBLIC>> key for the user, the full line stored in the user's C<< ~/.ssh/id_rsa.pub >> file.

=head3 ssh_key_user_name (required)

This is the name of the user that the public key belongs to.

=head3 ssh_key_uuid (optional)

This is the specific record to update. If not provides, a search will be made to find a matching entry. If found, the record will be updated if one of the values has changed. If not, a new record will be inserted.

=cut
sub insert_or_update_ssh_keys
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_ssh_keys()" }});
	
	my $uuid                = defined $parameter->{uuid}                ? $parameter->{uuid}                : "";
	my $file                = defined $parameter->{file}                ? $parameter->{file}                : "";
	my $line                = defined $parameter->{line}                ? $parameter->{line}                : "";
	my $ssh_key_host_uuid  = defined $parameter->{ssh_key_host_uuid}  ? $parameter->{ssh_key_host_uuid}  : $anvil->Get->host_uuid;
	my $ssh_key_public_key = defined $parameter->{ssh_key_public_key} ? $parameter->{ssh_key_public_key} : "";
	my $ssh_key_user_name  = defined $parameter->{ssh_key_user_name}  ? $parameter->{ssh_key_user_name}  : "";
	my $ssh_key_uuid       = defined $parameter->{ssh_key_uuid}       ? $parameter->{ssh_key_uuid}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                => $uuid, 
		file                => $file, 
		line                => $line, 
		ssh_key_host_uuid  => $ssh_key_host_uuid, 
		ssh_key_public_key => $ssh_key_public_key, 
		ssh_key_user_name  => $ssh_key_user_name, 
		ssh_key_uuid       => $ssh_key_uuid, 
	}});
	
	if (not $ssh_key_public_key)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ssh_keys()", parameter => "ssh_key_public_key" }});
		return("");
	}
	if (not $ssh_key_user_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_ssh_keys()", parameter => "ssh_key_user_name" }});
		return("");
	}
	
	# If we don't have a UUID, see if we can find one for the given user and host.
	if (not $ssh_key_uuid)
	{
		my $query = "
SELECT 
    ssh_key_uuid, 
    modified_date  
FROM 
    ssh_keys 
WHERE 
    ssh_key_user_name = ".$anvil->Database->quote($ssh_key_user_name)." 
AND 
    ssh_key_host_uuid = ".$anvil->Database->quote($ssh_key_host_uuid)." 
ORDER BY 
    modified_date DESC
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$ssh_key_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ssh_key_uuid => $ssh_key_uuid }});
			
			# If there are multiple, there's a bug. Above is the most recent, so delete the others.
			foreach my $row (@{$results})
			{
				my $this_ssh_key_uuid = $row->[0];
				next if $ssh_key_uuid eq $this_ssh_key_uuid;
				
				my $query = "DELETE FROM ssh_keys WHERE ssh_key_uuid = ".$anvil->Database->quote($this_ssh_key_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	# If I still don't have an ssh_key_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ssh_key_uuid => $ssh_key_uuid }});
	if (not $ssh_key_uuid)
	{
		# INSERT
		$ssh_key_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ssh_key_uuid => $ssh_key_uuid }});
		
		my $query = "
INSERT INTO 
    ssh_keys 
(
    ssh_key_uuid, 
    ssh_key_host_uuid, 
    ssh_key_public_key, 
    ssh_key_user_name, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($ssh_key_uuid).", 
    ".$anvil->Database->quote($ssh_key_host_uuid).", 
    ".$anvil->Database->quote($ssh_key_public_key).", 
    ".$anvil->Database->quote($ssh_key_user_name).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    ssh_key_host_uuid, 
    ssh_key_public_key, 
    ssh_key_user_name 
FROM 
    ssh_keys 
WHERE 
    ssh_key_uuid = ".$anvil->Database->quote($ssh_key_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a ssh_key_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "ssh_key_uuid", uuid => $ssh_key_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_ssh_key_host_uuid  = $row->[0];
			my $old_ssh_key_public_key = $row->[1];
			my $old_ssh_key_user_name  = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_ssh_key_host_uuid  => $old_ssh_key_host_uuid, 
				old_ssh_key_public_key => $old_ssh_key_public_key, 
				old_ssh_key_user_name  => $old_ssh_key_user_name, 
			}});
			
			# Anything change?
			if (($old_ssh_key_host_uuid  ne $ssh_key_host_uuid)  or 
			    ($old_ssh_key_public_key ne $ssh_key_public_key) or 
			    ($old_ssh_key_user_name  ne $ssh_key_user_name))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    ssh_keys 
SET 
    ssh_key_host_uuid  = ".$anvil->Database->quote($ssh_key_host_uuid).",  
    ssh_key_public_key = ".$anvil->Database->quote($ssh_key_public_key).", 
    ssh_key_user_name  = ".$anvil->Database->quote($ssh_key_user_name).", 
    modified_date       = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    ssh_key_uuid       = ".$anvil->Database->quote($ssh_key_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ssh_key_uuid => $ssh_key_uuid }});
	return($ssh_key_uuid);
}


=head2 insert_or_update_states

This updates (or inserts) a record in the 'states' table. The C<< state_uuid >> referencing the database row will be returned. This table is meant to be used for transient information (ie: server is migrating, condition age, etc). 

B<< Note >>: No history is tracked on this table and it is excluded from resync operations. Think of this table as a scratch disk of sorts. 

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 state_uuid (optional)

This is the C<< state_uuid >> to update. If it is not specified but the C<< state_name >> is, a check will be made to see if an entry already exists. If so, that row will be UPDATEd. If not, a random UUID will be generated and a new entry will be INSERTed.

=head3 state_name (required)

This is the C<< state_name >> to INSERT or UPDATE. If a C<< state_uuid >> is passed, then the C<< state_name >> can be changed.

=head3 state_host_uuid (optional)

This is the host's UUID that this state entry belongs to. If not passed, C<< sys::host_uuid >> will be used.

=head3 state_note (optional)

This is an optional note related to this state entry.

=cut 
sub insert_or_update_states
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_states()" }});
	
	my $uuid            = defined $parameter->{uuid}            ? $parameter->{uuid}            : "";
	my $file            = defined $parameter->{file}            ? $parameter->{file}            : "";
	my $line            = defined $parameter->{line}            ? $parameter->{line}            : "";
	my $state_uuid      = defined $parameter->{state_uuid}      ? $parameter->{state_uuid}      : "";
	my $state_name      = defined $parameter->{state_name}      ? $parameter->{state_name}      : "";
	my $state_host_uuid = defined $parameter->{state_host_uuid} ? $parameter->{state_host_uuid} : $anvil->data->{sys}{host_uuid};
	my $state_note      = defined $parameter->{state_note}      ? $parameter->{state_note}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		uuid            => $uuid, 
		file            => $file, 
		line            => $line, 
		state_uuid      => $state_uuid, 
		state_name      => $state_name, 
		state_host_uuid => $state_host_uuid, 
		state_note      => $state_note, 
	}});
	
	# If we were passed a database UUID, check for the open handle.
	if ($uuid)
	{
		if ((not defined $anvil->data->{cache}{database_handle}{$uuid}) or (not $anvil->data->{cache}{database_handle}{$uuid}))
		{
			# Switch to another UUID
			foreach my $this_uuid (keys %{$anvil->data->{cache}{database_handle}})
			{
				if ($anvil->data->{cache}{database_handle}{$this_uuid})
				{
					# Switch to this UUID
					$uuid = $this_uuid;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
				}
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
		}});
	}
	
	if (not $state_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_states()", parameter => "state_name" }});
		return("");
	}
	if (not $state_host_uuid)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0108"});
		return("");
	}
	
	# It's possible during initialization that a state could be set before the host is in the database's
	# hosts table. This prevents that condition from causing a problem.
	my $hosts_ok = 1;
	my $db_uuids = [];
	my $query    = "SELECT COUNT(*) FROM hosts WHERE host_uuid = ".$anvil->Database->quote($state_host_uuid).";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	if ($uuid)
	{
		push @{$db_uuids}, $uuid;
	}
	else
	{
		foreach my $db_uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cache::database_handle::${db_uuid}" => $anvil->data->{cache}{database_handle}{$db_uuid},
			}});
			next if $anvil->data->{cache}{database_handle}{$db_uuid} !~ /^DBI::db=HASH/;
			push @{$db_uuids}, $db_uuid;
		}
	}
	foreach my $db_uuid (@{$db_uuids})
	{
		my $count = $anvil->Database->query({debug => $debug, uuid => $db_uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			's2:db_uuid' => $db_uuid, 
			's2:count'   => $count,
		}});
		if (not $count)
		{
			$hosts_ok = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hosts_ok => $hosts_ok }});
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0144", variables => { 
				state_info => $state_name." -> ".$state_note,
				db_uuid    => $db_uuid, 
				host_uuid  => $state_host_uuid, 
			}});
		}
	}
	if (not $hosts_ok)
	{
		# Don't save.
		return("");
	}
	
	# If we don't have a UUID, see if we can find one for the given state server name.
	if (not $state_uuid)
	{
		my $query = "
SELECT 
    state_uuid 
FROM 
    states 
WHERE 
    state_name      = ".$anvil->Database->quote($state_name)." 
AND 
    state_host_uuid = ".$anvil->Database->quote($state_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			$state_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
		}
	}
	
	# If I still don't have an state_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
	if (not $state_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		foreach my $db_uuid (@{$db_uuids})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { db_uuid => $db_uuid }});

			my $query = "SELECT COUNT(*) FROM hosts WHERE host_uuid = ".$anvil->Database->quote($anvil->data->{sys}{host_uuid}).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});

			my $count = $anvil->Database->query({query => $query, uuid => $db_uuid, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
			if (not $count)
			{
				# We're out.
				return("");
			}
		}
		
		# INSERT
		   $state_uuid = $anvil->Get->uuid();
		my $query      = "
INSERT INTO 
    states 
(
    state_uuid, 
    state_name,
    state_host_uuid, 
    state_note, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($state_uuid).", 
    ".$anvil->Database->quote($state_name).", 
    ".$anvil->Database->quote($state_host_uuid).", 
    ".$anvil->Database->quote($state_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# There's no history schema so we just UPDATE (in case, as in DB locking, the age since last 
		# update is important).
		my $query = "
UPDATE 
    states 
SET 
    state_name       = ".$anvil->Database->quote($state_name).", 
    state_host_uuid  = ".$anvil->Database->quote($state_host_uuid).",  
    state_note       = ".$anvil->Database->quote($state_note).", 
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    state_uuid       = ".$anvil->Database->quote($state_uuid)." 
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
	return($state_uuid);
}


=head2 insert_or_update_storage_groups

This method creates or renames a storage group. On success, the new C<< storage_group_uuid >> is returned. If there is a problem, C<< !!error!! >> is returned.

B<< Note >>: If C<< storage_group_name >> is set to C<< IGNORE >>. the storage group is not shown during server provisioning.

Parameters;

=head3 storage_group_anvil_uuid (required)

This is the Anvil! UUID that the storage group belongs to.

=head3 storage_group_name (optional)

This is the name of the new storage group, as shown to the user when they provision servers. If this is not set, the word string 'striker_0280' is used with increasing integer until a unique name is found.

This is set to C<< DELETED >> if the group is deleted.

If this is set and the given name is already in use, C<< !!error!! >> is returned.

=head3 storage_group_uuid (optional)

If set, the specific storage group will be updated. 

=cut
sub insert_or_update_storage_groups
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_storage_groups()" }});
	
	# Check my parameters.
	my $uuid                     = defined $parameter->{uuid}                     ? $parameter->{uuid}                     : "";
	my $file                     = defined $parameter->{file}                     ? $parameter->{file}                     : "";
	my $line                     = defined $parameter->{line}                     ? $parameter->{line}                     : "";
	my $storage_group_anvil_uuid = defined $parameter->{storage_group_anvil_uuid} ? $parameter->{storage_group_anvil_uuid} : "";
	my $storage_group_name       = defined $parameter->{storage_group_name}       ? $parameter->{storage_group_name}       : "";
	my $storage_group_uuid       = defined $parameter->{storage_group_uuid}       ? $parameter->{storage_group_uuid}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		uuid                     => $uuid, 
		file                     => $file, 
		line                     => $line, 
		storage_group_anvil_uuid => $storage_group_anvil_uuid, 
		storage_group_name       => $storage_group_name, 
		storage_group_uuid       => $storage_group_uuid, 
	}});
	
	if (not $storage_group_anvil_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_storage_groups()", parameter => "storage_group_anvil_uuid" }});
		return('!!error!!');
	}
	
	if ($storage_group_name)
	{
		# Make sure the name isn't already used.
		my $query     = "
SELECT 
    storage_group_uuid 
FROM 
    storage_groups 
WHERE 
    storage_group_anvil_uuid = ".$anvil->Database->quote($storage_group_anvil_uuid)." 
AND 
    storage_group_name       = ".$anvil->Database->quote($storage_group_name)."
;";
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		if ($count)
		{
			# Name collision
			my $storage_group_uuid = $results->[0]->[0];
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0071", variables => { 
				name => $storage_group_name,
				uuid => $storage_group_uuid, 
			}});
			return('!!error!!');
		}
	}
	else
	{
		my $vg_group_number = 0;
		until ($storage_group_name)
		{
			$vg_group_number++; 
			my $test_name = $anvil->Words->string({debug => $debug, key => "striker_0280", variables => { number => $vg_group_number }});
			my $query     = "
SELECT 
    storage_group_uuid 
FROM 
    storage_groups 
WHERE 
    storage_group_anvil_uuid = ".$anvil->Database->quote($storage_group_anvil_uuid)." 
AND 
    storage_group_name       = ".$anvil->Database->quote($test_name)."
;";
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			
			if ($count)
			{
				# Are there any members of this group? If not, we'll use it.
				my $storage_group_uuid = $results->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_uuid => $storage_group_uuid }});
				
				my $query = "
SELECT 
    COUNT(*) 
FROM 
    storage_group_members 
WHERE 
    storage_group_member_storage_group_uuid = ".$anvil->Database->quote($storage_group_uuid)." 
;";
				my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				my $count   = @{$results};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					results => $results, 
					count   => $count, 
				}});
				
				if (not $count)
				{
					# No members yet, and it's an auto-generated 
					$storage_group_name = $test_name;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_name => $storage_group_name }});
				}
			}
			if (not $count)
			{
				# We can use this name.
				$storage_group_name = $test_name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_name => $storage_group_name }});
			}
		}
	}
	
	# INSERT or UPDATE?
	if (not $storage_group_uuid)
	{
		# INSERT
		$storage_group_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_uuid => $storage_group_uuid }});
		
		my $query = "
INSERT INTO 
    storage_groups 
(
    storage_group_uuid, 
    storage_group_anvil_uuid, 
    storage_group_name, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($storage_group_uuid).", 
    ".$anvil->Database->quote($storage_group_anvil_uuid).", 
    ".$anvil->Database->quote($storage_group_name).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		
		$anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name} = $storage_group_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"storage_groups::anvil_uuid::${storage_group_anvil_uuid}::storage_group_uuid::${storage_group_uuid}::group_name" => $anvil->data->{storage_groups}{anvil_uuid}{$storage_group_anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name},
		}});
	}
	else
	{
		# UPDATE, if the name has changed.
		my $query     = "
SELECT 
    storage_group_name 
FROM 
    storage_groups 
WHERE 
    storage_group_uuid = ".$anvil->Database->quote($storage_group_uuid)." 
;";
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		my $old_storage_group_name = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_storage_group_name => $old_storage_group_name }});
		
		if ($old_storage_group_name ne $storage_group_name)
		{
			# It's changed, update it.
			my $query = "
UPDATE
    storage_groups 
SET 
    storage_group_name = ".$anvil->Database->quote($storage_group_name).", 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE  
    storage_group_uuid = ".$anvil->Database->quote($storage_group_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	
	return($storage_group_uuid);
}


=head2 insert_or_update_storage_group_members

This adds a volume group on a given host to a storage group on it's Anvil!. 

If there is a problem, C<< !!error!! >> is returned. Otherwise, the C<< storage_group_member_uuid >> is returned.

Parameters;

=head3 delete (optional, default 0)

This will remove the VG from the storage group.

If set, C<< storage_group_member_uuid >> is required and it is the only required attribute. 

=head3 storage_group_member_note (optional)

This is a note that can be placed about this member. When the member is deleted, this is set to C<< DELETED >>.

=head3 storage_group_member_uuid (optional)

If set, a specific storage group member is updated or deleted. 

=head3 storage_group_member_storage_group_uuid (required, unless delete is set)

This is the storage group the VG will belong to.

=head3 storage_group_member_host_uuid (required, unless delete is set)

This is the host UUID this VG is on.

=head3 storage_group_member_vg_uuid (required, unless delete is set)

This is the volume group's B<< internal >> UUID (which, to be clear, isn't a valid UUID formatted string, so it's treated as a string internally).

=cut
sub insert_or_update_storage_group_members
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_storage_group_members()" }});
	
	# Check my parameters.
	my $uuid                                    = defined $parameter->{uuid}                                    ? $parameter->{uuid}                                    : "";
	my $file                                    = defined $parameter->{file}                                    ? $parameter->{file}                                    : "";
	my $line                                    = defined $parameter->{line}                                    ? $parameter->{line}                                    : "";
	my $delete                                  = defined $parameter->{'delete'}                                ? $parameter->{'delete'}                                : 0;
	my $storage_group_member_uuid               = defined $parameter->{storage_group_member_uuid}               ? $parameter->{storage_group_member_uuid}               : "";
	my $storage_group_member_storage_group_uuid = defined $parameter->{storage_group_member_storage_group_uuid} ? $parameter->{storage_group_member_storage_group_uuid} : "";
	my $storage_group_member_host_uuid          = defined $parameter->{storage_group_member_host_uuid}          ? $parameter->{storage_group_member_host_uuid}          : "";
	my $storage_group_member_vg_uuid            = defined $parameter->{storage_group_member_vg_uuid}            ? $parameter->{storage_group_member_vg_uuid}            : "";
	my $storage_group_member_note               = defined $parameter->{storage_group_member_note}               ? $parameter->{storage_group_member_note}               : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		uuid                                    => $uuid, 
		file                                    => $file, 
		line                                    => $line, 
		'delete'                                => $delete, 
		storage_group_member_uuid               => $storage_group_member_uuid,
		storage_group_member_note               => $storage_group_member_note,
		storage_group_member_storage_group_uuid => $storage_group_member_storage_group_uuid,
		storage_group_member_host_uuid          => $storage_group_member_host_uuid, 
		storage_group_member_vg_uuid            => $storage_group_member_vg_uuid, 
	}});
	
	if ($delete)
	{
		if (not $storage_group_member_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_storage_group_members()", parameter => "storage_group_member_uuid" }});
			return('!!error!!');
		}
		else
		{
			my $query = "
UPDATE 
    storage_group_members 
SET 
    storage_group_member_note = 'DELETED',
    modified_date             = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE  
    storage_group_member_uuid = ".$anvil->Database->quote($storage_group_member_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
    
			$query = "DELETE FROM storage_group_members WHERE storage_group_member_uuid = ".$anvil->Database->quote($storage_group_member_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	else
	{
		if (not $storage_group_member_storage_group_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_storage_group_members()", parameter => "storage_group_member_storage_group_uuid" }});
			return('!!error!!');
		}
		if (not $storage_group_member_host_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_storage_group_members()", parameter => "storage_group_member_host_uuid" }});
			return('!!error!!');
		}
		if (not $storage_group_member_vg_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_storage_group_members()", parameter => "storage_group_member_vg_uuid" }});
			return('!!error!!');
		}
	}
	
	if (not $storage_group_member_uuid)
	{
		# See if we've seen this VG by searching for it's UUID.
		my $query = "
SELECT 
    storage_group_member_uuid 
FROM 
    storage_group_members 
WHERE 
    storage_group_member_vg_uuid   = ".$anvil->Database->quote($storage_group_member_vg_uuid)."
AND 
    storage_group_member_host_uuid = ".$anvil->Database->quote($storage_group_member_host_uuid)."
;";
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$storage_group_member_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_member_uuid => $storage_group_member_uuid }});
		}
	}
	
	# INSERT or UPDATE?
	if (not $storage_group_member_uuid)
	{
		# INSERT
		$storage_group_member_uuid = $anvil->Get->uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_member_uuid => $storage_group_member_uuid }});
		
		my $query = "
INSERT INTO 
    storage_group_members 
(
    storage_group_member_uuid, 
    storage_group_member_storage_group_uuid, 
    storage_group_member_host_uuid, 
    storage_group_member_vg_uuid,
    storage_group_member_note,
    modified_date
) VALUES (
    ".$anvil->Database->quote($storage_group_member_uuid).", 
    ".$anvil->Database->quote($storage_group_member_storage_group_uuid).", 
    ".$anvil->Database->quote($storage_group_member_host_uuid).", 
    ".$anvil->Database->quote($storage_group_member_vg_uuid).",
    ".$anvil->Database->quote($storage_group_member_note).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# UPDATE, if something has changed.
		my $query = "
SELECT 
    storage_group_member_storage_group_uuid, 
    storage_group_member_host_uuid, 
    storage_group_member_vg_uuid,
    storage_group_member_note
FROM
    storage_group_members 
WHERE 
    storage_group_member_uuid = ".$anvil->Database->quote($storage_group_member_uuid)."
;";
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		my $old_storage_group_member_storage_group_uuid = $results->[0]->[0];
		my $old_storage_group_member_host_uuid          = $results->[0]->[1];
		my $old_storage_group_member_vg_uuid            = $results->[0]->[2];
		my $old_storage_group_member_note               = $results->[0]->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			old_storage_group_member_storage_group_uuid => $old_storage_group_member_storage_group_uuid, 
			old_storage_group_member_host_uuid          => $old_storage_group_member_host_uuid, 
			old_storage_group_member_vg_uuid            => $old_storage_group_member_vg_uuid,
			old_storage_group_member_note               => $old_storage_group_member_note,
		}});
		
		if (($old_storage_group_member_storage_group_uuid ne $storage_group_member_storage_group_uuid) or 
		    ($old_storage_group_member_host_uuid          ne $storage_group_member_host_uuid)          or 
		    ($old_storage_group_member_vg_uuid            ne $storage_group_member_vg_uuid)            or
		    ($old_storage_group_member_note               ne $storage_group_member_note))
		{
			# Something changed, UPDATE
			my $query = "
UPDATE 
    storage_group_members 
SET 
    storage_group_member_storage_group_uuid = ".$anvil->Database->quote($storage_group_member_storage_group_uuid).", 
    storage_group_member_host_uuid          = ".$anvil->Database->quote($storage_group_member_host_uuid).", 
    storage_group_member_vg_uuid            = ".$anvil->Database->quote($storage_group_member_vg_uuid).",
    storage_group_member_note               = ".$anvil->Database->quote($storage_group_member_note).",
    modified_date                           = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    storage_group_member_uuid               = ".$anvil->Database->quote($storage_group_member_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	
	return($storage_group_member_uuid);
}


=head2 insert_or_update_temperature

This inserts or updates a value in the special c<< temperature >> table. 

This stores weighted temperature of nodes. Agents can set one or more temperature values. After a scan sweep completes, ScanCore will sum these weights and the node with the B<< highest >> value is considered the B<< least >> temperaturey and any servers on it will be migrated to the peer.

If there is a problem, an empty string is returned. Otherwise, the C<< temperature_uuid >> is returned.

parameters;

=head3 cache (optional)

If this is passed an array reference, SQL queries will be pushed into the array instead of actually committed to databases. It will be up to the caller to commit the queries.

=head3 delete (optional, default '0')

If set to C<< 1 >>, the associated C<< temperature_uuid >> will be deleted. When set, only C<< temperature_uuid >> is required.

=head3 temperature_uuid (optional)

Is passed, the specific entry will be updated.

=head3 temperature_host_uuid (optional, default Get->host_uuid)

This is the host B<< recording >> the temperature. It is B<< not >> the host that the sensor is read from (though of course they can be the same). This is an important distinction as, for example, Striker dashboards will monitor available temperature sensors of nodes to tell when it is safe to boot them up, after a thermal event caused a shutdown, 

=head3 temperature_agent_name (required)

This is the scan agent (or program name) setting this score.

=head3 temperature_sensor_host (required)

This is the host (uuid) that the sensor was read from. This is important as ScanCore on a striker will read available thermal data from a node using it's IPMI data.

NOTE: For shared temperature sensors (like UPSes), set this to the device UUID (ie: C<< upses >> -> C<<ups_uuid>>). Devices that use the device will add these values to their own when doing post-scan calculations.

=head3 temperature_sensor_name (required)

This is the name of the free-form, descriptive name of the sensor reporting the temperature.

=head3 temperature_value_c (required)

This is the actual temperature being recorded, in celsius. The value can be a signed decimal value.

=head3 temperature_state (optional, default 'ok')

This is a string represnting the state of the sensor. Valid values are C<< ok >>, C<< warning >>, and C<< critical >>.

When a sensor is in C<< warning >>, it's value is added up (along with C<< critical >> sensors) to derive a score. If that score is equal to over greater than C<< scancore::threshold::warning_temperature >> (default C<< 5 >>), servers will be migrated over to the peer, B<< if >> the peer's temperature score is below this threshold.

When a sensor is in C<< critical >>, it's score is summed up along with other C<< critical >> temperatures (C<< warnings >> are not factored). If the total score is equal to or greater than C<< scancore::threshold::warning_critical >>, (default C<< 5 >>), the node will enter emergency shutdown. 

=head3 temperature_is (optional, default 'nominal)

This indicate if the temperature 'nominal', 'high' or 'low'. This distinction is used when calculating if C<< scancore::threshold::warning_temperature >> or C<< scancore::threshold::warning_critical >> has been passed. Temperatures that are in a C<< warning >> or C<< critical >> state will be evaluated as groups. That is, if through some weird case some temperatures were reading high and others were reading cold, decisions about threashold would be calculated separately for the over temp and again for the under temp values.

=head3 temperature_weight (optional, default 1)

This sets the weight of the temperature sensor. This allows a given sensor to have more or less influence of the derived score used to see if C<< scancore::threshold::warning_temperature >> or C<< scancore::threshold::warning_critical >> has been exceeded.

=cut
sub insert_or_update_temperature
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_temperature()" }});
	
	my $uuid                    = defined $parameter->{uuid}                    ? $parameter->{uuid}                    : "";
	my $file                    = defined $parameter->{file}                    ? $parameter->{file}                    : "";
	my $line                    = defined $parameter->{line}                    ? $parameter->{line}                    : "";
	my $cache                   = defined $parameter->{cache}                   ? $parameter->{cache}                   : 0;
	my $delete                  = defined $parameter->{'delete'}                ? $parameter->{'delete'}                : 0;
	my $temperature_uuid        = defined $parameter->{temperature_uuid}        ? $parameter->{temperature_uuid}        : "";
	my $temperature_host_uuid   = defined $parameter->{temperature_host_uuid}   ? $parameter->{temperature_host_uuid}   : $anvil->Get->host_uuid;
	my $temperature_agent_name  = defined $parameter->{temperature_agent_name}  ? $parameter->{temperature_agent_name}  : "";
	my $temperature_sensor_host = defined $parameter->{temperature_sensor_host} ? $parameter->{temperature_sensor_host} : "";
	my $temperature_sensor_name = defined $parameter->{temperature_sensor_name} ? $parameter->{temperature_sensor_name} : "";
	my $temperature_value_c     = defined $parameter->{temperature_value_c}     ? $parameter->{temperature_value_c}     : "";
	my $temperature_state       = defined $parameter->{temperature_state}       ? $parameter->{temperature_state}       : "ok";
	my $temperature_is          = defined $parameter->{temperature_is}          ? $parameter->{temperature_is}          : "nominal";
	my $temperature_weight      = defined $parameter->{temperature_weight}      ? $parameter->{temperature_weight}      : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                    => $uuid, 
		file                    => $file, 
		line                    => $line, 
		cache                   => $cache,
		'delete'                => $delete,
		temperature_uuid        => $temperature_uuid,
		temperature_host_uuid   => $temperature_host_uuid,
		temperature_agent_name  => $temperature_agent_name,
		temperature_sensor_host => $temperature_sensor_host,
		temperature_sensor_name => $temperature_sensor_name,
		temperature_value_c     => $temperature_value_c, 
		temperature_state       => $temperature_state, 
		temperature_is          => $temperature_is, 
		temperature_weight      => $temperature_weight, 
	}});
	
	
	# Pointy end up?
	if (not $delete)
	{
		if ($temperature_state eq "norminal")
		{
			$temperature_state = "nominal";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temperature_state => $temperature_state }});
		}
		
		if (not $temperature_agent_name)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_agent_name" }});
			return("");
		}
		if (not $temperature_sensor_host)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_sensor_host" }});
			return("");
		}
		if (not $temperature_sensor_name)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_sensor_name" }});
			return("");
		}
		if ($temperature_value_c eq "")
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_value_c" }});
			return("");
		}
		if (not $temperature_state)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_state" }});
			return("");
		}
		elsif (($temperature_state ne "ok") && ($temperature_state ne "warning") && ($temperature_state ne "critical"))
		{
			# Invalid value.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0546", variables => { temperature_state => $temperature_state }});
			return("");
		}
		if (not $temperature_is)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_is" }});
			return("");
		}
		elsif (($temperature_is ne "nominal") && ($temperature_is ne "high") && ($temperature_is ne "low"))
		{
			# Invalid value.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0547", variables => { temperature_is => $temperature_is }});
			return("");
		}
		if ($temperature_weight eq "")
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_weight" }});
			return("");
		}
	}
	
	# If we don't have a temperature UUID, see if we can find one.
	if (not $temperature_uuid)
	{
		my $query = "
SELECT 
    temperature_uuid 
FROM 
    temperature 
WHERE 
    temperature_host_uuid   = ".$anvil->Database->quote($temperature_host_uuid)." 
AND 
    temperature_sensor_host = ".$anvil->Database->quote($temperature_sensor_host)."
AND 
    temperature_agent_name  = ".$anvil->Database->quote($temperature_agent_name)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$temperature_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temperature_uuid => $temperature_uuid }});
		}
	}
	
	if ($delete)
	{
		if (not $temperature_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_temperature()", parameter => "temperature_uuid" }});
			return("");
		}
		
		my $query = "
UPDATE 
    temperature 
SET 
    temperature_state  = 'DELETED', 
    modified_date      = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    temperature_uuid   = ".$anvil->Database->quote($temperature_uuid).";
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		if (ref($cache) eq "ARRAY")
		{
			push @{$cache}, $query;
		}
		else
		{
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
		
		$query = "
DELETE FROM 
    temperature 
WHERE
    temperature_uuid   = ".$anvil->Database->quote($temperature_uuid).";
";
		push @{$anvil->data->{'scan-hpacucli'}{queries}}, $query;
		if (ref($cache) eq "ARRAY")
		{
			push @{$cache}, $query;
		}
		else
		{
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
		return($temperature_uuid);
	}
	
	# If we have a temperature UUID now, look up the previous value and see if it has changed. If not, INSERT 
	# a new entry.
	if ($temperature_uuid)
	{
		my $query = "
SELECT 
    temperature_host_uuid, 
    temperature_agent_name, 
    temperature_sensor_host, 
    temperature_sensor_name, 
    temperature_value_c, 
    temperature_state, 
    temperature_is, 
    temperature_weight 
FROM 
    temperature 
WHERE 
    temperature_uuid = ".$anvil->Database->quote($temperature_uuid).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# What?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "temperature_uuid", uuid => $temperature_uuid }});
			return("");
		}
		my $old_temperature_host_uuid   = $results->[0]->[0];
		my $old_temperature_agent_name  = $results->[0]->[1];
		my $old_temperature_sensor_host = $results->[0]->[2];
		my $old_temperature_sensor_name = $results->[0]->[3];
		my $old_temperature_value_c     = $results->[0]->[4];
		my $old_temperature_state       = $results->[0]->[5];
		my $old_temperature_is          = $results->[0]->[6];
		my $old_temperature_weight      = $results->[0]->[7];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			old_temperature_host_uuid   => $old_temperature_host_uuid,
			old_temperature_agent_name  => $old_temperature_agent_name, 
			old_temperature_sensor_host => $old_temperature_sensor_host, 
			old_temperature_sensor_name => $old_temperature_sensor_name, 
			old_temperature_value_c     => $old_temperature_value_c, 
			old_temperature_state       => $old_temperature_state, 
			old_temperature_is          => $old_temperature_is, 
			old_temperature_weight      => $old_temperature_weight, 
		}});
		
		if (($old_temperature_host_uuid   ne $temperature_host_uuid)   or 
		    ($old_temperature_agent_name  ne $temperature_agent_name)  or
		    ($old_temperature_sensor_host ne $temperature_sensor_host) or
		    ($old_temperature_sensor_name ne $temperature_sensor_name) or 
		    ($old_temperature_value_c     ne $temperature_value_c)     or
		    ($old_temperature_state       ne $temperature_state)       or
		    ($old_temperature_is          ne $temperature_is)          or
		    ($old_temperature_weight      ne $temperature_weight))
		{
			# Update.
			my $query = "
UPDATE 
    temperature 
SET 
    temperature_host_uuid   = ".$anvil->Database->quote($temperature_host_uuid).",
    temperature_agent_name  = ".$anvil->Database->quote($temperature_agent_name).",
    temperature_sensor_host = ".$anvil->Database->quote($temperature_sensor_host).", 
    temperature_sensor_name = ".$anvil->Database->quote($temperature_sensor_name).", 
    temperature_value_c     = ".$anvil->Database->quote($temperature_value_c).",
    temperature_state       = ".$anvil->Database->quote($temperature_state).",
    temperature_is          = ".$anvil->Database->quote($temperature_is).",
    temperature_weight      = ".$anvil->Database->quote($temperature_weight).",
    modified_date           = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    temperature_uuid        = ".$anvil->Database->quote($temperature_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			if (ref($cache) eq "ARRAY")
			{
				push @{$cache}, $query;
			}
			else
			{
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# INSERT
		   $temperature_uuid = $anvil->Get->uuid();
		my $query            = "
INSERT INTO 
    temperature 
(
    temperature_uuid, 
    temperature_host_uuid, 
    temperature_agent_name, 
    temperature_sensor_host, 
    temperature_sensor_name, 
    temperature_value_c, 
    temperature_state, 
    temperature_is, 
    temperature_weight, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($temperature_uuid).", 
    ".$anvil->Database->quote($temperature_host_uuid).", 
    ".$anvil->Database->quote($temperature_agent_name).", 
    ".$anvil->Database->quote($temperature_sensor_host).", 
    ".$anvil->Database->quote($temperature_sensor_name).", 
    ".$anvil->Database->quote($temperature_value_c).", 
    ".$anvil->Database->quote($temperature_state).", 
    ".$anvil->Database->quote($temperature_is).", 
    ".$anvil->Database->quote($temperature_weight).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		if (ref($cache) eq "ARRAY")
		{
			push @{$cache}, $query;
		}
		else
		{
			$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		}
	}
	
	return($temperature_uuid);
}


=head2 insert_or_update_updated

This adds or updates an entry in the c<< updated >> tables, used to help track how long ago given programs ran. This helps with determin when scan agents, ScanCore or other programs last ran.

B<< Note >>: This method differs from most in two ways; First, it only take one parameter, specifc entries can't be updated. Second, this is considered a "scratch" function and has no history schema version. This table is not resync'ed if/when a resync is otherwise performed.

The C<< updated_uuid >> is returned.

Parameters;

=head3 updated_by (required)

This is the name of the caller updating the entry. Usually this is C<< $THIS_FILE >> as set in the caller.

=cut
sub insert_or_update_updated
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_updated()" }});
	
	my $uuid       = defined $parameter->{uuid}       ? $parameter->{uuid}       : "";
	my $file       = defined $parameter->{file}       ? $parameter->{file}       : "";
	my $line       = defined $parameter->{line}       ? $parameter->{line}       : "";
	my $updated_by = defined $parameter->{updated_by} ? $parameter->{updated_by} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		updated_by => $updated_by,
		
	}});
	
	if (not $updated_by)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_updated()", parameter => "updated_by" }});
		return("");
	}
	
	# Look up the 'updated_uuid', if possible.
	my $updated_uuid = "";
	my $query        = "
SELECT 
    updated_uuid 
FROM 
    updated 
WHERE 
    updated_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)."
AND 
    updated_by        = ".$anvil->Database->quote($updated_by)." 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count)
	{
		$updated_uuid = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { updated_uuid => $updated_uuid }});
	}
	
	# Update or insert?
	if ($updated_uuid)
	{
		# Update
		my $query = "
UPDATE 
    updated 
SET 
    updated_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid).", 
    updated_by        = ".$anvil->Database->quote($updated_by).", 
    modified_date     = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    updated_uuid      = ".$anvil->Database->quote($updated_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Insert
		   $updated_uuid = $anvil->Get->uuid();
		my $query      = "
INSERT INTO 
    updated 
(
    updated_uuid, 
    updated_host_uuid, 
    updated_by, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($updated_uuid).", 
    ".$anvil->Database->quote($anvil->Get->host_uuid).", 
    ".$anvil->Database->quote($updated_by).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($updated_uuid);
}


=head2 insert_or_update_upses

This updates (or inserts) a record in the 'upses' table. The C<< ups_uuid >> UUID will be returned.

If there is an error, an empty string is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 ups_agent (required)

This is the name of the ups agent to use when communicating with this ups device. The agent must be installed on any machine that may need to ups (or check the ups/power state of) a node.

=head3 ups_ip_address (optional, but generally required in practice)

This is the string that tells machines how to communicate / control the the ups device. This is used when configuring pacemaker's stonith (fencing). 

The exact formatting needs to match the STDIN parameters supported by C<< ups_agent >>. Please see C<< STDIN PARAMETERS >> section of the ups agent man page for this device.

For example, this can be set to:

* C<< ip="10.201.11.1" lanplus="1" username="admin" password="super secret password" 

B<< NOTES >>: 
* If C<< password_script >> is used, it is required that the user has copied the script to the nodes.
* Do not use C<< action="..." >> or the ups agent name. If either is found in the string, they will be ignored.
* Do not use C<< delay >>. It will be determined automatically based on which node has the most servers running on it.
* If this is set to C<< DELETED >>, the ups device is considered no longer used and it will be ignored by C<< Database->get_upses() >>.

=head3 ups_name (required)

This is the name of the ups device. Genreally, this is the short host name of the device.

=head3 ups_uuid (required)

The default value is the ups's UUID. When passed, the specific record is updated.

=cut
sub insert_or_update_upses
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_upses()" }});
	
	my $uuid           = defined $parameter->{uuid}           ? $parameter->{uuid}           : "";
	my $file           = defined $parameter->{file}           ? $parameter->{file}           : "";
	my $line           = defined $parameter->{line}           ? $parameter->{line}           : "";
	my $ups_agent      = defined $parameter->{ups_agent}      ? $parameter->{ups_agent}      : "";
	my $ups_ip_address = defined $parameter->{ups_ip_address} ? $parameter->{ups_ip_address} : "";
	my $ups_name       = defined $parameter->{ups_name}       ? $parameter->{ups_name}       : "";
	my $ups_uuid       = defined $parameter->{ups_uuid}       ? $parameter->{ups_uuid}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid           => $uuid, 
		file           => $file, 
		line           => $line, 
		ups_agent      => $ups_agent, 
		ups_ip_address => $ups_ip_address =~ /passwork=/ ? $anvil->Log->is_secure($ups_ip_address) : $ups_ip_address, 
		ups_name       => $ups_name, 
		ups_uuid       => $ups_uuid, 
	}});
	
	if (not $ups_agent)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_upses()", parameter => "ups_agent" }});
		return("");
	}
	if (not $ups_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_upses()", parameter => "ups_name" }});
		return("");
	}
	if (not $ups_ip_address)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_upses()", parameter => "ups_ip_address" }});
		return("");
	}
	
	# Do we have a UUID?
	if (not $ups_uuid)
	{
		### TODO: We might want to try finding it by the IP address, if the name doesn't match. This 
		###       might cause issues though if different UPSes spanning different BCNs could be 
		###       confused, perhaps?
		my $query = "
SELECT 
    ups_uuid 
FROM 
    upses 
WHERE 
    ups_name = ".$anvil->Database->quote($ups_name)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			$ups_uuid = $results->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ups_uuid => $ups_uuid }});
		}
	}
	
	# Do we have a UUID?
	if ($ups_uuid)
	{
		# Yup. Has something changed?
		my $query = "
SELECT 
    ups_agent, 
    ups_name, 
    ups_ip_address  
FROM 
    upses 
WHERE 
    ups_uuid = ".$anvil->Database->quote($ups_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $old_ups_agent     = $row->[0];
			my $old_ups_name      = $row->[1];
			my $old_ups_ip_address = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
				old_ups_agent     => $old_ups_agent,
				old_ups_name      => $old_ups_name =~ /passw/ ? $anvil->Log->is_secure($old_ups_name) : $old_ups_name, 
				old_ups_ip_address => $old_ups_ip_address, 
			}});
			if (($old_ups_agent     ne $ups_agent) or 
			    ($old_ups_name      ne $ups_name)  or 
			    ($old_ups_ip_address ne $ups_ip_address))
			{
				# Clear the stop data.
				my $query = "
UPDATE 
    upses
SET 
    ups_name       = ".$anvil->Database->quote($ups_name).", 
    ups_ip_address = ".$anvil->Database->quote($ups_ip_address).", 
    ups_agent      = ".$anvil->Database->quote($ups_agent).", 
    modified_date  = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
WHERE
    ups_uuid       = ".$anvil->Database->quote($ups_uuid)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	else
	{
		# No, INSERT.
		   $ups_uuid = $anvil->Get->uuid();
		my $query      = "
INSERT INTO 
    upses 
(
    ups_uuid, 
    ups_name, 
    ups_ip_address, 
    ups_agent, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($ups_uuid).", 
    ".$anvil->Database->quote($ups_name).",
    ".$anvil->Database->quote($ups_ip_address).",
    ".$anvil->Database->quote($ups_agent).",
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query =~ /passw/ ? $anvil->Log->is_secure($query) : $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	
	return($ups_uuid);
}


=head2 insert_or_update_users

This updates (or inserts) a record in the 'users' table. The C<< user_uuid >> referencing the database row will be returned.

If there is an error, C<< !!error!! >> is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 user_uuid (optional)

Is passed, the associated record will be updated.

=head3 user_name (required)

This is the user's name they type when logging into Striker.

=head3 user_password_hash (required)

This is either the B<< hash >> of the user's password, or the raw password. Which it is will be determined by whether C<< user_salt >> is passed in. If it is, C<< user_algorithm >> and C<< user_hash_count >> will also be required. If not, the password will be hashed (and a salt generated) using the default algorithm and hash count.

=head3 user_salt (optional, see 'user_password_hash')

This is the random salt used to generate the password hash.

=head3 user_algorithm (optional, see 'user_password_hash')

This is the algorithm used to create the password hash (with the salt appended to the password).

=head3 user_hash_count (optional, see 'user_password_hash')

This is how many times the initial hash is re-encrypted. 

=head3 user_language (optional, default 'sys::language')

=head3 user_is_admin (optional, default '0')

This determines if the user is an administrator or not. If set to C<< 1 >>, then all features and functions are available to the user.

=head3 user_is_experienced (optional, default '0')

This determines if the user is trusted with potentially dangerous operations, like changing the disk space allocated to a server, deleting a server, and so forth. This also reduces the number of confirmation boxes presented to the user. Set to C<< 1 >> to enable.

=head3 user_is_trusted (optional, default '0')

This determines if the user is trusted to perform operations that are inherently safe, but can cause service interruptions. This includes shutting down (gracefully or forced) servers. Set to C<< 1 >> to enable.

=cut
sub insert_or_update_users
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_users()" }});
	
	my $uuid                = defined $parameter->{uuid}                ? $parameter->{uuid}                : "";
	my $file                = defined $parameter->{file}                ? $parameter->{file}                : "";
	my $line                = defined $parameter->{line}                ? $parameter->{line}                : "";
	my $user_uuid           = defined $parameter->{user_uuid}           ? $parameter->{user_uuid}           : "";
	my $user_name           = defined $parameter->{user_name}           ? $parameter->{user_name}           : "";
	my $user_password_hash  = defined $parameter->{user_password_hash}  ? $parameter->{user_password_hash}  : "";
	my $user_salt           = defined $parameter->{user_salt}           ? $parameter->{user_salt}           : "";
	my $user_algorithm      = defined $parameter->{user_algorithm}      ? $parameter->{user_algorithm}      : "";
	my $user_hash_count     = defined $parameter->{user_hash_count}     ? $parameter->{user_hash_count}     : "";
	my $user_language       = defined $parameter->{user_language}       ? $parameter->{user_language}       : $anvil->data->{sys}{language};
	my $user_is_admin       = defined $parameter->{user_is_admin}       ? $parameter->{user_is_admin}       : 0;
	my $user_is_experienced = defined $parameter->{user_is_experienced} ? $parameter->{user_is_experienced} : 0;
	my $user_is_trusted     = defined $parameter->{user_is_trusted}     ? $parameter->{user_is_trusted}     : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                => $uuid, 
		file                => $file, 
		line                => $line, 
		user_uuid           => $user_uuid, 
		user_name           => $user_name, 
		user_password_hash  => $user_salt ? $user_password_hash : $anvil->Log->is_secure($user_password_hash), 
		user_salt           => $user_salt, 
		user_algorithm      => $user_algorithm, 
		user_hash_count     => $user_hash_count, 
		user_language       => $user_language, 
		user_is_admin       => $user_is_admin, 
		user_is_experienced => $user_is_experienced, 
		user_is_trusted     => $user_is_trusted, 
	}});
	
	if (not $user_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_users()", parameter => "user_name" }});
		return("");
	}
	if (not $user_password_hash)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_users()", parameter => "user_password_hash" }});
		return("");
	}
	
	# If we have a salt, we need the algorithm and hash count. If not, we'll generate the hash by 
	# treating the password like the initial string.
	if ($user_salt)
	{
		# We have a salt, so we also need the algorithm and loop count.
		if (not $user_algorithm)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_users()", parameter => "user_algorithm" }});
			return("");
		}
		if (not $user_hash_count)
		{
			# Throw an error and exit.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_users()", parameter => "user_hash_count" }});
			return("");
		}
	}
	else
	{
		# No salt given, we'll generate a hash now.
		my $answer             = $anvil->Account->encrypt_password({password => $user_password_hash});
		   $user_password_hash = $answer->{user_password_hash};
		   $user_salt          = $answer->{user_salt};
		   $user_algorithm     = $answer->{user_algorithm};
		   $user_hash_count    = $answer->{user_hash_count};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			user_password_hash => $user_salt ? $user_password_hash : $anvil->Log->is_secure($user_password_hash) , 
			user_salt          => $user_salt, 
			user_algorithm     => $user_algorithm, 
			user_hash_count    => $user_hash_count, 
		}});
		
		if (not $user_salt)
		{
			# Something went wrong.
			return("");
		}
	}
	
	# If we don't have a UUID, see if we can find one for the given user server name.
	if (not $user_uuid)
	{
		my $query = "
SELECT 
    user_uuid 
FROM 
    users 
WHERE 
    user_name = ".$anvil->Database->quote($user_name)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			$user_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_uuid => $user_uuid }});
		}
	}
	
	# If I still don't have an user_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_uuid => $user_uuid }});
	if (not $user_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts({debug => $debug});
		my $found = 0;
		foreach my $hash_ref (@{$hosts})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hash_ref->{host_uuid}" => $hash_ref->{host_uuid}, 
				"sys::host_uuid"        => $anvil->data->{sys}{host_uuid}, 
			}});
			if ($hash_ref->{host_uuid} eq $anvil->data->{sys}{host_uuid})
			{
				$found = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
			}
		}
		if (not $found)
		{
			# We're out.
			return("");
		}
		
		# INSERT
		   $user_uuid = $anvil->Get->uuid();
		my $query     = "
INSERT INTO 
    users 
(
    user_uuid, 
    user_name,
    user_password_hash, 
    user_salt, 
    user_algorithm, 
    user_hash_count, 
    user_language, 
    user_is_admin, 
    user_is_experienced, 
    user_is_trusted, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($user_uuid).", 
    ".$anvil->Database->quote($user_name).", 
    ".$anvil->Database->quote($user_password_hash).", 
    ".$anvil->Database->quote($user_salt).", 
    ".$anvil->Database->quote($user_algorithm).", 
    ".$anvil->Database->quote($user_hash_count).", 
    ".$anvil->Database->quote($user_language).", 
    ".$anvil->Database->quote($user_is_admin).", 
    ".$anvil->Database->quote($user_is_experienced).", 
    ".$anvil->Database->quote($user_is_trusted).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    user_name,
    user_password_hash, 
    user_salt, 
    user_algorithm, 
    user_hash_count, 
    user_language, 
    user_is_admin, 
    user_is_experienced, 
    user_is_trusted 
FROM 
    users 
WHERE 
    user_uuid = ".$anvil->Database->quote($user_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# I have a user_uuid but no matching record. Probably an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "user_uuid", uuid => $user_uuid }});
			return("");
		}
		foreach my $row (@{$results})
		{
			my $old_user_name           = $row->[0];
			my $old_user_password_hash  = $row->[1];
			my $old_user_salt           = $row->[2];
			my $old_user_algorithm      = $row->[3];
			my $old_user_hash_count     = $row->[4];
			my $old_user_language       = $row->[5];
			my $old_user_is_admin       = $row->[6];
			my $old_user_is_experienced = $row->[7];
			my $old_user_is_trusted     = $row->[8];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_user_name           => $old_user_name, 
				old_user_password_hash  => $old_user_password_hash,
				old_user_salt           => $old_user_salt,
				old_user_algorithm      => $old_user_algorithm,
				old_user_hash_count     => $old_user_hash_count,
				old_user_language       => $old_user_language,
				old_user_is_admin       => $old_user_is_admin,
				old_user_is_experienced => $old_user_is_experienced,
				old_user_is_trusted     => $old_user_is_trusted,
			}});
			
			# Anything change?
			if (($old_user_name           ne $user_name)           or 
			    ($old_user_name           ne $user_name)           or 
			    ($old_user_password_hash  ne $user_password_hash)  or 
			    ($old_user_salt           ne $user_salt)           or 
			    ($old_user_algorithm      ne $user_algorithm)      or 
			    ($old_user_hash_count     ne $user_hash_count)     or 
			    ($old_user_language       ne $user_language)       or 
			    ($old_user_is_admin       ne $user_is_admin)       or 
			    ($old_user_is_experienced ne $user_is_experienced) or 
			    ($old_user_is_trusted     ne $user_is_trusted))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    users 
SET 
    user_name           = ".$anvil->Database->quote($user_name).", 
    user_password_hash  = ".$anvil->Database->quote($user_password_hash).",  
    user_salt           = ".$anvil->Database->quote($user_salt).",  
    user_algorithm      = ".$anvil->Database->quote($user_algorithm).",  
    user_hash_count     = ".$anvil->Database->quote($user_hash_count).",  
    user_language       = ".$anvil->Database->quote($user_language).",  
    user_is_admin       = ".$anvil->Database->quote($user_is_admin).", 
    user_is_experienced = ".$anvil->Database->quote($user_is_experienced).", 
    user_is_trusted     = ".$anvil->Database->quote($user_is_trusted).", 
    modified_date       = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    user_uuid           = ".$anvil->Database->quote($user_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_uuid => $user_uuid }});
	return($user_uuid);
}


=head2 insert_or_update_variables

This updates (or inserts) a record in the 'variables' table. The C<< state_uuid >> referencing the database row will be returned.

Unlike the other methods of this type, this method can be told to update the 'variable_value' only. This is so because the section, description and default columns rarely ever change. If this is set and the variable name is new, an INSERT will be done the same as if it weren't set, with the unset columns set to an empty string.

If there is an error, C<< !!error!! >> is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 variable_uuid (optional)

If this is passed, the variable will be updated using this UUID, which allows the C<< variable_name >> to be changed.

=head3 variable_name (optional)

This is the name of variable to be inserted or updated. 

B<NOTE>: This paramter is only optional if C<< variable_uuid >> is used. Otherwise this parameter is required.

=head3 variable_value (optional)

This is the value to set the variable to. If it is empty, the variable's value will be set to empty.

=head3 variable_default (optional)

If this is set, it changes the default value for the given variable. This is used to tell the user what the default was or enable resetting to defaults.

=head3 variable_description (optional)

This can be set to a string key that explains what this variable does when presenting this variable to a user.

=head3 variable_section (option)

If this is set, it will group this variable with other variables in the same section when displaying this variable to the user.

=head3 variable_source_uuid (optional)

This is an optional field to mark a source UUID that this variable belongs to. By default, a variable applies to everything that reads it, but if this is set, the variable can be restricted to just a given record. This is often used to tag the variable to a particular host by setting the host UUID, but it could also be a UUID of an entry in another database table, when C<< variable_source_table >> is used. Ultimately, this can be used however you want.

=head3 variable_source_table (optional)

This is an optional database table name that the variables relates to. Generally it is used along side C<< variable_source_uuid >>, but that isn't required.

=head3 update_value_only (optional, default '0')

When set to C<< 1 >>, this method will only update the variable's C<< variable_value >> column. Any other parameters are used to help locate the variable to update only. If the C<< variable_uuid >> isn't passed and can't be found, the call will fail and an empty string is returned.

=cut
sub insert_or_update_variables
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_variables()" }});
	
	my $uuid                  = defined $parameter->{uuid}                  ? $parameter->{uuid}                  : "";
	my $file                  = defined $parameter->{file}                  ? $parameter->{file}                  : "";
	my $line                  = defined $parameter->{line}                  ? $parameter->{line}                  : "";
	my $variable_uuid         = defined $parameter->{variable_uuid}         ? $parameter->{variable_uuid}         : "";
	my $variable_name         = defined $parameter->{variable_name}         ? $parameter->{variable_name}         : "";
	my $variable_value        = defined $parameter->{variable_value}        ? $parameter->{variable_value}        : "";
	my $variable_default      = defined $parameter->{variable_default}      ? $parameter->{variable_default}      : "";
	my $variable_description  = defined $parameter->{variable_description}  ? $parameter->{variable_description}  : "";
	my $variable_section      = defined $parameter->{variable_section}      ? $parameter->{variable_section}      : "";
	my $variable_source_uuid  = defined $parameter->{variable_source_uuid}  ? $parameter->{variable_source_uuid}  : "NULL";
	my $variable_source_table = defined $parameter->{variable_source_table} ? $parameter->{variable_source_table} : "";
	my $update_value_only     = defined $parameter->{update_value_only}     ? $parameter->{update_value_only}     : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                  => $uuid, 
		file                  => $file, 
		line                  => $line, 
		variable_uuid         => $variable_uuid, 
		variable_name         => $variable_name, 
		variable_value        => $variable_value, 
		variable_default      => $variable_default, 
		variable_description  => $variable_description, 
		variable_section      => $variable_section, 
		variable_source_uuid  => $variable_source_uuid, 
		variable_source_table => $variable_source_table, 
		update_value_only     => $update_value_only, 
	}});
	
	# We'll need either the name or UUID.
	if ((not $variable_name) && (not $variable_uuid))
	{
		# Neither given, throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0037"});
		return("!!error!!");
	}
	
	if ($variable_source_uuid eq "")
	{
		$variable_source_uuid = "NULL";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_source_uuid => $variable_source_uuid }});
	}
	
	# If we have a variable UUID but not a name, read the variable name. If we don't have a UUID, see if
	# we can find one for the given variable name.
	if (($anvil->Validate->uuid({uuid => $variable_uuid})) && (not $variable_name))
	{
		my $query = "
SELECT 
    variable_name 
FROM 
    variables 
WHERE 
    variable_uuid = ".$anvil->Database->quote($variable_uuid);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$variable_name = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__})->[0]->[0];
		$variable_name = "" if not defined $variable_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_name => $variable_name }});
	}
	
	if (($variable_name) && (not $variable_uuid))
	{
		my $query = "
SELECT 
    variable_uuid 
FROM 
    variables 
WHERE 
    variable_name = ".$anvil->Database->quote($variable_name);
		if (($variable_source_uuid ne "NULL") && ($variable_source_table ne ""))
		{
			$query .= "
AND 
    variable_source_uuid  = ".$anvil->Database->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->Database->quote($variable_source_table)." 
";
		}
		$query .= ";";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			$variable_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
		}
	}
	
	# If I still don't have an variable_uuid, we're INSERT'ing (unless we've been told to update the 
	# value only, in which case we do nothing).
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
	if (not $variable_uuid)
	{
		# Were we asked to updat only?
		if ($update_value_only)
		{
			# Nothing to do.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0030"});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 
				uuid                  => $uuid, 
				file                  => $file, 
				line                  => $line, 
				variable_uuid         => $variable_uuid, 
				variable_name         => $variable_name, 
				variable_value        => $variable_value, 
				variable_default      => $variable_default, 
				variable_description  => $variable_description, 
				variable_section      => $variable_section, 
				variable_source_uuid  => $variable_source_uuid, 
				variable_source_table => $variable_source_table, 
				update_value_only     => $update_value_only, 
			}});
			return("");
		}
		
		# INSERT
		   $variable_uuid = $anvil->Get->uuid();
		my $query         = "
INSERT INTO 
    variables 
(
    variable_uuid, 
    variable_name, 
    variable_value, 
    variable_default, 
    variable_description, 
    variable_section, 
    variable_source_uuid, 
    variable_source_table, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($variable_uuid).", 
    ".$anvil->Database->quote($variable_name).", 
    ".$anvil->Database->quote($variable_value).", 
    ".$anvil->Database->quote($variable_default).", 
    ".$anvil->Database->quote($variable_description).", 
    ".$anvil->Database->quote($variable_section).", 
    ".$anvil->Database->quote($variable_source_uuid).", 
    ".$anvil->Database->quote($variable_source_table).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
	}
	else
	{
		# Query only the value
		if ($update_value_only)
		{
			my $query = "
SELECT 
    variable_value 
FROM 
    variables 
WHERE 
    variable_uuid = ".$anvil->Database->quote($variable_uuid);
			if (($variable_source_uuid ne "NULL") && ($variable_source_table ne ""))
			{
				$query .= "
AND 
    variable_source_table = ".$anvil->Database->quote($variable_source_table)." 
AND 
    variable_source_uuid  = ".$anvil->Database->quote($variable_source_uuid)." 
";
			}
			$query .= ";";
			$query =~ s/'NULL'/NULL/g;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count,
			}});
			if (not $count)
			{
				# I have a variable_uuid, source table and source uuid but no matching record. Probably an error.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0217", variables => { 
					variable_uuid         => $variable_uuid, 
					variable_source_table => $variable_source_table, 
					variable_source_uuid  => $variable_source_uuid, 
				}});
				return("");
			}
			foreach my $row (@{$results})
			{
				my $old_variable_value = $row->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_variable_value => $old_variable_value }});
				
				# Anything change?
				if ($old_variable_value ne $variable_value)
				{
					# Variable changed, save.
					my $query = "
UPDATE 
    variables 
SET 
    variable_value = ".$anvil->Database->quote($variable_value).", 
    modified_date  = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    variable_uuid  = ".$anvil->Database->quote($variable_uuid);
					if (($variable_source_uuid ne "NULL") && ($variable_source_table ne ""))
					{
						$query .= "
AND 
    variable_source_uuid  = ".$anvil->Database->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->Database->quote($variable_source_table)." 
";
					}
					$query .= ";";
					$query =~ s/'NULL'/NULL/g;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
			}
		}
		else
		{
			# Query the rest of the values and see if anything changed.
			my $query = "
SELECT 
    variable_name, 
    variable_value, 
    variable_default, 
    variable_description, 
    variable_section, 
    variable_source_table, 
    variable_source_uuid 
FROM 
    variables 
WHERE 
    variable_uuid = ".$anvil->Database->quote($variable_uuid)." 
;";
			$query =~ s/'NULL'/NULL/g;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count,
			}});
			if (not $count)
			{
				# I have a variable_uuid but no matching record. Probably an error.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0216", variables => { uuid_name => "variable_uuid", uuid => $variable_uuid }});
				return("");
			}
			foreach my $row (@{$results})
			{
				my $old_variable_name         =         $row->[0];
				my $old_variable_value        =         $row->[1];
				my $old_variable_default      =         $row->[2];
				my $old_variable_description  =         $row->[3];
				my $old_variable_section      =         $row->[4];
				my $old_variable_source_table =         $row->[5];
				my $old_variable_source_uuid  = defined $row->[6] ? $row->[6] : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					old_variable_name         => $old_variable_name, 
					old_variable_value        => $old_variable_value, 
					old_variable_default      => $old_variable_default, 
					old_variable_description  => $old_variable_description, 
					old_variable_section      => $old_variable_section, 
					old_variable_source_table => $old_variable_source_table, 
					old_variable_source_uuid  => $old_variable_source_uuid, 
				}});
				
				# Anything change?
				if (($old_variable_name         ne $variable_name)         or 
				    ($old_variable_value        ne $variable_value)        or 
				    ($old_variable_default      ne $variable_default)      or 
				    ($old_variable_description  ne $variable_description)  or 
				    ($old_variable_section      ne $variable_section)      or 
				    ($old_variable_source_table ne $variable_source_table) or 
				    ($old_variable_source_uuid  ne $variable_source_uuid))
				{
					# Something changed, save.
					my $query = "
UPDATE 
    variables 
SET 
    variable_name         = ".$anvil->Database->quote($variable_name).", 
    variable_value        = ".$anvil->Database->quote($variable_value).", 
    variable_default      = ".$anvil->Database->quote($variable_default).", 
    variable_description  = ".$anvil->Database->quote($variable_description).", 
    variable_section      = ".$anvil->Database->quote($variable_section).", 
    variable_source_table = ".$anvil->Database->quote($variable_source_table).", 
    variable_source_uuid  = ".$anvil->Database->quote($variable_source_uuid).", 
    modified_date         = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    variable_uuid         = ".$anvil->Database->quote($variable_uuid)." 
";
					$query =~ s/'NULL'/NULL/g;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					
					$anvil->Database->write({uuid => $uuid, query => $query, source => $file ? $file." -> ".$THIS_FILE : $THIS_FILE, line => $line ? $line." -> ".__LINE__ : __LINE__});
				}
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
	return($variable_uuid);
}


=head2 load_database

This takes a path to an uncompressed SQL database dump file, and loads it into the C<< anvil >> database. During the duration of this operation, remote access to the database will be disabled via C<< iptables >> drop on port 5432!

If necessary, the database server will be started. 

If the dump is successfully loaded, C<< 0 >> is returned. If there is a problem, C<< !!error!! >> is returned.

B<< Note >>: This method must be called by the root user.

B<< Note >>: This always and only works on the local database server's C<< anvil >> database.

Parameters;

=head3 backup (optional, default '1')

This controls whether the data in the existing database is saved to a file prior to the passed-in database file being loaded.

=head3 load_file (required)

This is the full path to the SQL file to load into the database.

=cut
sub load_database
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->load_database()" }});
	
	my $backup    = defined $parameter->{backup}    ? $parameter->{backup}    : 1;
	my $load_file = defined $parameter->{load_file} ? $parameter->{load_file} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		backup    => $backup,
		load_file => $load_file, 
	}});
	
	# Only the root user can do this
	if (($< != 0) && ($> != 0))
	{
		# Not root
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0350"});
		return('!!error!!');
	}
	
	# Does the file exist?
	if (not $load_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->load_database()", parameter => "load_file" }});
	}
	elsif (not -e $load_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0103", variables => { file => $load_file }});
		return('!!error!!');
	}
	
	my $start_time = time;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { start_time => $start_time }});
	
	# Throw up the firewall. Have the open call ready in case we hit an error.
	$anvil->Network->manage_firewall({debug => $debug});
	### TODO: Delete this when done with manage_firewall().
	my $block_call = $anvil->data->{path}{exe}{iptables}." -I INPUT -p tcp --dport 5432 -j REJECT";
	my $open_call  = $anvil->data->{path}{exe}{iptables}." -D INPUT -p tcp --dport 5432 -j REJECT";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { block_call => $block_call }});
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $block_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	
	# Start the database, if needed.
	my $running = $anvil->System->check_daemon({debug => $debug, daemon => $anvil->data->{sys}{daemon}{postgresql}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
	if (not $running)
	{
		# Start it up.
		my $return_code = $anvil->System->start_daemon({daemon => $anvil->data->{sys}{daemon}{postgresql}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
		if ($return_code eq "0")
		{
			# Started the daemon.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0059"});
		}
		else
		{
			# Failed to start
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0094"});
			
			# Drop the firewall block
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { open_call => $open_call }});
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $open_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code, 
			}});
			return("!!error!!");
		}
	}
	
	# Backup, if needed.
	if ($backup)
	{
		# Backup the database.
		my $dump_file = $anvil->Database->backup_database({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { dump_file => $dump_file }});
		if ($dump_file eq "!!error!!")
		{
			# Drop the firewall block
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { open_call => $open_call }});
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $open_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code, 
			}});
			return("!!error!!");
		}
	}
	
	# Drop the existing database.
	my $drop_call = $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{dropdb}." anvil\"";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { drop_call => $drop_call }});
	$output      = "";
	$return_code = "";
	($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $drop_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	if ($return_code)
	{
		# This is a failure, but it could be that the database simply didn't exist (was already 
		# dumped). If that's the case, we'll keep going.
		my $proceed = 0;
		if ($output =~ /database ".*?" does not exist/gs)
		{
			# proceed.
			$proceed = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { proceed => $proceed }});
		}
		if (not $proceed)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0353", variables => {
				shell_call  => $drop_call, 
				return_code => $return_code, 
				output      => $output, 
			}});
			
			# Drop the firewall block
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { open_call => $open_call }});
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $open_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code, 
			}});
			return('!!error!!');
		}
	}
	
	# Recreate the DB.
	my $create_call = $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{createdb}." --owner "."admin"." anvil\"";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_call => $create_call }});
	$output      = "";
	$return_code = "";
	($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $create_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	if ($return_code)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0354", variables => {
			shell_call  => $create_call, 
			return_code => $return_code, 
			output      => $output, 
		}});
		
		# Drop the firewall block
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { open_call => $open_call }});
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $open_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code, 
		}});
		return('!!error!!');
	}
	
	# Finally, load the database.
	my $load_call = $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." anvil < ".$load_file."\"";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { load_call => $load_call }});
	$output      = "";
	$return_code = "";
	($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $load_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	if ($return_code)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0355", variables => {
			shell_call  => $load_call, 
			return_code => $return_code, 
			output      => $output, 
		}});
		
		# Drop the firewall block
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { open_call => $open_call }});
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $open_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code, 
		}});
		return('!!error!!');
	}
	
	# Open the firewall back up
	$output      = "";
	$return_code = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { open_call => $open_call }});
	($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $open_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	
	# Done!
	my $took_time = time - $start_time;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0655", variables => { 
		file => $load_file,
		took => $took_time,
	}});
	
	return(0);
}


=head2 lock_file

This reads, sets or updates the database lock file timestamp.

Parameters;

=head3 do (required, default 'get')

This controls whether we're setting (C<< set >>) or checking for (C<< get >>) a lock file on the local system. 

If setting, or if checking and a lock file is found, the timestamp (in unixtime) in the lock fike is returned. If a lock file isn't found, C<< 0 >> is returned.

=cut
sub lock_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->lock_file()" }});
	
	my $do = $parameter->{'do'} ? $parameter->{'do'} : "get";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'do' => $do }});
	
	my $lock_time = 0;
	if ($do eq "set")
	{
		$lock_time = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lock_time => $lock_time }});
		$anvil->Storage->write_file({
			file      => $anvil->data->{path}{'lock'}{database}, 
			body      => $lock_time,
			overwrite => 1,
		});
	}
	else
	{
		# Read the lock file's time stamp, if the file exists.
		if (-e $anvil->data->{path}{'lock'}{database})
		{
			$lock_time = $anvil->Storage->read_file({file => $anvil->data->{path}{'lock'}{database}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lock_time => $lock_time }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lock_time => $lock_time }});
	return($lock_time);
}


=head2 locking

This handles requesting, releasing and waiting on locks.

If it is called without any parameters, it will act as a pauser that halts the program until any existing locks are released.

Parameters;

=head3 request (optional)

When set to C<< 1 >>, a log request will be made. If an existing lock exists, it will wait until the existing lock clears before requesting the lock and returning.

=head3 release (optional)

When set to C<< 1 >>, an existing lock held by this machine will be release.

=head3 renew (optional)

When set to C<< 1 >>, an existing lock held by this machine will be renewed.

=head3 check (optional)

This checks to see if a lock is in place and, if it is, the lock string is returned (in the format C<< <host_name>::<source_uuid>::<unix_time_stamp> >> that requested the active lock.

=cut
sub locking
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->locking()" }});
	
	my $request = defined $parameter->{request} ? $parameter->{request} : 0;
	my $release = defined $parameter->{release} ? $parameter->{release} : 0;
	my $renew   = defined $parameter->{renew}   ? $parameter->{renew}   : 0;
	my $check   = defined $parameter->{check}   ? $parameter->{check}   : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		request => $request, 
		release => $release, 
		renew   => $renew, 
		check   => $check, 
	}});
	
	# These are used to ID this lock.
	my $source_name = $anvil->Get->short_host_name;
	my $source_uuid = $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		source_name => $source_name, 
		source_uuid => $source_uuid, 
	}});
	
	my $set            = 0;
	my $state_name     = "lock_request";
	my $new_state_note = $source_name."::".$source_uuid."::".time;
	my $old_state_note = $source_name."::".$source_uuid."::%";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		state_name     => $state_name, 
		new_state_note => $new_state_note, 
		old_state_note => $old_state_note, 
	}});
	
	my $wildcard_select_query = "
SELECT 
    state_note 
FROM 
    states 
WHERE 
    state_host_uuid = ".$anvil->Database->quote($source_uuid)." 
AND 
    state_name      = ".$anvil->Database->quote($state_name)."
AND 
    state_note LIKE   ".$anvil->Database->quote($old_state_note)." 
;";
	my $wildcard_delete_query = "
DELETE FROM 
    states 
WHERE 
    state_host_uuid = ".$anvil->Database->quote($source_uuid)." 
AND 
    state_name      = ".$anvil->Database->quote($state_name)."
AND 
    state_note LIKE   ".$anvil->Database->quote($old_state_note)." 
;";

	
	# Make sure we have a sane lock age
	if ((not defined $anvil->data->{sys}{database}{locking}{reap_age}) or 
	    (not $anvil->data->{sys}{database}{locking}{reap_age})         or 
	    ($anvil->data->{sys}{database}{locking}{reap_age} =~ /\D/)
	)
	{
		$anvil->data->{sys}{database}{locking}{reap_age} = $anvil->data->{defaults}{database}{locking}{reap_age};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::locking::reap_age" => $anvil->data->{sys}{database}{locking}{reap_age} }});
	}
	
	# If I have been asked to check, we will return the state_note if a lock is set.
	if ($check)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wildcard_select_query => $wildcard_select_query }});
		my $state_note = $anvil->Database->query({query => $wildcard_select_query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		   $state_note = "" if not defined $state_note;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_note => $state_note }});
		
		return($state_note);
	}
	
	# If I've been asked to clear a lock, do so now.
	if ($release)
	{
		# We check to see if there is a lock before we clear it. This way we don't log that we 
		# released a lock unless we really released a lock.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wildcard_select_query => $wildcard_select_query }});
		my $results = $anvil->Database->query({debug => $debug, query => $wildcard_select_query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
		
		if ($count)
		{
			### NOTE: There is not history schema for states, so we just delete it.
			# Delete the state(s).
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wildcard_delete_query => $wildcard_delete_query }});
			$anvil->Database->write({debug => $debug, query => $wildcard_delete_query, source => $THIS_FILE, line => __LINE__});

			$anvil->data->{sys}{database}{local_lock_active} = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active}, 
			}});
			
			# Log that the lock has been released.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0039", variables => { host => $anvil->Get->host_name }});
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
		return($set);
	}
	
	# If I've been asked to renew, do so now.
	if ($renew)
	{
		# Yup, do it. Delete any old states first, thoguh. Batch them together to avoid there being 
		# a time where another process could falsely see no locks are held.
		my $queries = [];
		push @{$queries}, $wildcard_delete_query;
		push @{$queries}, "
INSERT INTO 
    states 
(
    state_uuid, 
    state_name,
    state_host_uuid, 
    state_note, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($anvil->Get->uuid).", 
    ".$anvil->Database->quote($state_name).", 
    ".$anvil->Database->quote($source_uuid).", 
    ".$anvil->Database->quote($new_state_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);";
		foreach my $query (@{$queries})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		}
		$anvil->Database->write({debug => $debug, query => $queries, source => $THIS_FILE, line => __LINE__});

		$anvil->data->{sys}{database}{local_lock_active} = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active}, 
		}});
		
		# Log that we've renewed the lock.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0044", variables => { host => $anvil->Get->short_host_name }});
		
		return(1);
	}
	
	# We always check for, and then wait for, locks. Read in the locks, if any. If any are set and they are 
	# younger than sys::database::locking::reap_age, we'll hold.
	my $waiting = 1;
	while ($waiting)
	{
		# Set the 'waiting' to '0'. If we find a lock, we'll set it back to '1'.
		$waiting = 0;
		
		# See if we had a lock.
		my ($lock_value, $state_uuid, $modified_date) = $anvil->Database->read_state({debug => $debug, state_name => $state_name});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			waiting         => $waiting, 
			lock_value      => $lock_value, 
			state_uuid      => $state_uuid, 
			state_host_uuid => $anvil->Get->host_uuid, 
			modified_date   => $modified_date, 
		}});
		if ($lock_value =~ /^(.*?)::(.*?)::(\d+)/)
		{
			my $lock_source_name = $1;
			my $lock_source_uuid = $2;
			my $lock_time        = $3;
			my $current_time     = time;
			my $timeout_time     = $lock_time + $anvil->data->{sys}{database}{locking}{reap_age};
			my $lock_age         = $current_time - $lock_time;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				lock_source_name => $lock_source_name, 
				lock_source_uuid => $lock_source_uuid, 
				current_time     => $current_time, 
				lock_time        => $lock_time, 
				timeout_time     => $timeout_time, 
				lock_age         => $lock_age, 
			}});
			
			# If the lock is stale, delete it.
			if ($current_time > $timeout_time)
			{
				### NOTE: There is no history schema for states.
				# The lock is stale.
				my $query = "DELETE FROM states WHERE state_uuid = ".$anvil->Database->quote($state_uuid).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
			}
			# Only wait if this isn't our own lock.
			elsif ($lock_source_uuid ne $source_uuid)
			{
				# Mark 'wait', set inactive and sleep.
				#$anvil->Database->mark_active({set => 0});
				
				$waiting = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					lock_source_uuid => $lock_source_uuid, 
					source_uuid      => $source_uuid, 
					waiting          => $waiting, 
				}});
				sleep 5;
			}
		}
	}
	
	# If I am here, there are no pending locks. Have I been asked to set one?
	if ($request)
	{
		# Yup, do it.
		my $state_uuid = $anvil->Get->uuid;
		my $queries    = [];
		push @{$queries}, $wildcard_delete_query;
		push @{$queries}, "
INSERT INTO 
    states 
(
    state_uuid, 
    state_name,
    state_host_uuid, 
    state_note, 
    modified_date 
) VALUES (
    ".$anvil->Database->quote($state_uuid).", 
    ".$anvil->Database->quote($state_name).", 
    ".$anvil->Database->quote($source_uuid).", 
    ".$anvil->Database->quote($new_state_note).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);";
		foreach my $query (@{$queries})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		}
		my $problem = $anvil->Database->write({debug => $debug, query => $queries, source => $THIS_FILE, line => __LINE__});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		
		# If we have a problem, it could be that we're locking against a database not yet in the 
		# hosts file.
		if ($problem)
		{
			# No lock
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
			return($set);
		}
		
		$set = 1;
		$anvil->data->{sys}{database}{local_lock_active} = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			set                      => $set, 
			"sys::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active}, 
		}});
		
		# Log that we've got the lock.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0045", variables => { host => $anvil->Get->short_host_name }});
	}
	
	# Now return.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
	return($set);
}


=head2 log_connections

This method logs details about open connections to databases. It's generally only used as a debugging tool.

This method takes no parameters.

=cut
sub log_connections
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->log_connections()" }});
	
	# Log how many connections there are.
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0132"});

	# Reading from
	my $read_uuid = $anvil->data->{sys}{database}{read_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { read_uuid => $read_uuid }});
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
	{
		my $host = $anvil->data->{database}{$uuid}{host};
		my $port = $anvil->data->{database}{$uuid}{port};
		my $name = $anvil->data->{database}{$uuid}{name};
		my $user = $anvil->data->{database}{$uuid}{user};
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0537", variables => { 
			name => $name,
			user => $user, 
			host => $host,
			port => $port,
		}});
		
		my $query      = "SELECT system_identifier FROM pg_control_system();";
		my $identifier = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0540", variables => { 
			uuid       => $uuid,
			identifier => $identifier, 
		}});
		
		if ($uuid eq $read_uuid)
		{
			# Reading from this DB
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0538"});
		}
		else
		{
			# Not reading from this DB
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0539"});
		}
	}
	
	return(0);
}

=head2 manage_anvil_conf

This adds, removes or updates a database entry in a machine's anvil.conf file. This returns C<< 0 >> on success, C<< 1 >> if there was a problem.

Parameters;

=head3 db_host (required)

This is the IP address or host name of the database server.

=head3 db_host_uuid (required)

This is the C<< host_uuid >> of the server hosting the database we will be managing.

=head3 db_password (required)

This is the password used to log into the database. 

=head3 db_ping (optional, default '1')

This sets whether the target will ping the DB server before trying to connect. See C<< Database->connect >> for more information.

=head3 db_port (optional, default '5432')

This is the port used to connect to the database server.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

B<< NOTE >>: Do not confuse this with C<< db_password >>. This is the password to log into the remote machine being managed.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

B<< NOTE >>: Do not confuse this with C<< db_port >>. This is the port used to SSH into a remote machine.

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

B<< NOTE >>: Do not confuse this with C<< db_user >>. This is the user to use when logging into the machine being managed.

=head3 remove (optional, default '0')

If set to C<< 1 >>, any existing extries for C<< host_uuid >> will be removed from that machine being managed.

B<< NOTE >>: When this is set to C<< 1 >>, C<< db_password >> and C<< db_host >> are not required.

=head3 target (optional)

If set, the file will be read from the target machine. This must be either an IP address or a resolvable host name. 

The file will be copied to the local system using C<< $anvil->Storage->rsync() >> and stored in C<< /tmp/<file_path_and_name>.<target> >>. if C<< cache >> is set, the file will be preserved locally. Otherwise it will be deleted once it has been read into memory.

B<< Note >>: the temporary file will be prefixed with the path to the file name, with the C<< / >> converted to C<< _ >>.

=cut
sub manage_anvil_conf
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->manage_anvil_conf()" }});
	
	my $db_password  = defined $parameter->{db_password}  ? $parameter->{db_password}  : "";
	my $db_ping      = defined $parameter->{db_ping}      ? $parameter->{db_ping}      : 1;
	my $db_port      = defined $parameter->{db_port}      ? $parameter->{db_port}      : 5432;
	my $db_host      = defined $parameter->{db_host}      ? $parameter->{db_host}      : "";
	my $db_host_uuid = defined $parameter->{db_host_uuid} ? $parameter->{db_host_uuid} : "";
	my $password     = defined $parameter->{password}     ? $parameter->{password}     : "";
	my $port         = defined $parameter->{port}         ? $parameter->{port}         : 22;
	my $remote_user  = defined $parameter->{remote_user}  ? $parameter->{remote_user}  : "root";
	my $remove       = defined $parameter->{remove}       ? $parameter->{remove}       : 0;
	my $target       = defined $parameter->{target}       ? $parameter->{target}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		db_password  => $anvil->Log->is_secure($db_password), 
		db_ping      => $db_ping, 
		db_port      => $db_port, 
		db_host_uuid => $db_host_uuid, 
		password     => $anvil->Log->is_secure($password), 
		port         => $port, 
		remote_user  => $remote_user, 
		remove       => $remove,
		target       => $target,
	}});
	
	if (not $db_host_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->manage_anvil_conf()", parameter => "db_host_uuid" }});
		return(1);
	}
	elsif (not $anvil->Validate->uuid({uuid => $db_host_uuid}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0031", variables => { db_host_uuid => $db_host_uuid }});
		return(1);
	}
	if (not $remove)
	{
		if (not $db_host)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->manage_anvil_conf()", parameter => "db_host" }});
			return(0);
		}
		if (not $db_password)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->manage_anvil_conf()", parameter => "db_password" }});
			return(0);
		}
	}
	
	# Read in the anvil.conf
	my ($anvil_conf) = $anvil->Storage->read_file({
		debug       => $debug, 
		file        => $anvil->data->{path}{configs}{'anvil.conf'},
		force_read  => 1, 
		port        => $port, 
		password    => $password, 
		remote_user => $remote_user, 
		secure      => 1, 
		target      => $target,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_conf => $anvil_conf }});
	
	if ($anvil_conf eq "!!error!!")
	{
		# Something went wrong.
		return(1);
	}
	
	# Now walk through the file and look for '### end db list ###'
	my $rewrite            = 0;
	my $host_variable      = "database::${db_host_uuid}::host";
	my $host_different     = 1;
	my $port_variable      = "database::${db_host_uuid}::port";
	my $port_different     = 1;
	my $password_variable  = "database::${db_host_uuid}::password";
	my $password_different = 1;
	my $ping_variable      = "database::${db_host_uuid}::ping";
	my $ping_different     = 1;
	my $delete_reported    = 0;
	my $update_reported    = 0;
	my $new_body           = "";
	my $just_deleted       = 0;
	my $test_line          = "database::${db_host_uuid}::";
	my $insert             = "";
	my $host_seen          = 0;
	
	# If we're not removing, and we don't find the entry at all, this will be inserted.
	if (not $remove)
	{
		$insert =  $host_variable."		=	".$db_host."\n";
		$insert .= $port_variable."		=	".$db_port."\n";
		$insert .= $password_variable."	=	".$db_password."\n";
		$insert .= $ping_variable."		=	".$db_ping."\n";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_variable     => $host_variable, 
		port_variable     => $port_variable, 
		password_variable => $anvil->Log->is_secure($password_variable), 
		ping_variable     => $ping_variable,
		insert            => $anvil->Log->is_secure($insert), 
		test_line         => $test_line, 
	}});
	
	foreach my $line (split/\n/, $anvil_conf)
	{
		# Secure password lines ? 
		my $secure = (($line =~ /password/) && ($line !~ /^#/)) ? 1 : 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, secure => $secure, level => $debug, list => { line => $line }});

		# If I removed an entry, I also want to delete the white space after it.
		if (($just_deleted) && ((not $line) or ($line =~ /^\s+$/)))
		{
			$just_deleted = 0;
			next;
		}
		$just_deleted = 0;
		
		# If we've hit the end of the DB list, see if we need to insert a new entry.
		if ($line eq "### end db list ###")
		{
			# If I've not seen this DB, enter it.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, secure => 0, level => $debug, list => { 
				host_seen => $host_seen,
				remove    => $remove,
			}});
			if ((not $host_seen) && (not $remove))
			{
				$new_body .= $insert."\n";
				$rewrite  =  1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, secure => 1, level => $debug, list => { 
					new_body => $new_body,
					rewrite  => $rewrite,
				}});
			}
		}
		
		# Now Skip any more comments.
		if ($line =~ /^#/)
		{
			$new_body .= $line."\n";
			next;
		}
		# Process lines with the 'var = val' format
		if ($line =~ /^(.*?)(\s*)=(\s*)(.*)$/)
		{
			my $variable    = $1;
			my $left_space  = $2;
			my $right_space = $3; 
			my $value       = $4;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:variable"    => $variable,
				"s2:value"       => $value, 
				"s3:left_space"  => $left_space, 
				"s4:right_space" => $right_space, 
			}});
			
			# Is the the host line we're possibly updating?
			if ($variable eq $host_variable)
			{
				# Yup. Are we removing it, or do we need to edit it?
				$host_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:value"     => $value,
					"s2:db_host"   => $db_host, 
					"s3:host_seen" => $host_seen, 
				}});
				if ($remove)
				{
					# Remove the line
					$delete_reported = 1;
					$just_deleted    = 1;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						just_deleted    => $just_deleted, 
						rewrite         => $rewrite,
						delete_reported => $delete_reported, 
					}});
					next;
				}
				elsif ($value eq $db_host)
				{
					# No change.
					$host_different = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_different => $host_different }});
				}
				else
				{
					# Needs to be updated.
					$line    = $variable.$left_space."=".$right_space.$db_host;
					$rewrite = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						line    => $line,
						rewrite => $rewrite, 
					}});
				}
			}
			elsif ($variable eq $port_variable)
			{
				# Port line
				$host_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:value"     => $value,
					"s2:port"      => $db_port, 
					"s3:host_seen" => $host_seen, 
				}});
				if ($remove)
				{
					# Remove it
					$delete_reported = 1;
					$just_deleted    = 1;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						delete_reported => $delete_reported, 
						just_deleted    => $just_deleted, 
						rewrite         => $rewrite,
					}});
					next;
				}
				elsif ($value eq $db_port)
				{
					# No change.
					$port_different = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port_different => $port_different }});
				}
				else
				{
					# Needs to be updated.
					$update_reported = 1;
					$line            = $variable.$left_space."=".$right_space.$db_port;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update_reported => $update_reported, 
						line            => $line,
						rewrite         => $rewrite, 
					}});
				}
			}
			elsif ($variable eq $password_variable)
			{
				# Password
				$host_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
					"s1:value"     => $value,
					"s2:password"  => $anvil->Log->is_secure($db_password), 
					"s3:host_seen" => $host_seen, 
				}});
				if ($remove)
				{
					# Remove it
					$delete_reported = 1;
					$just_deleted    = 1;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						delete_reported => $delete_reported, 
						just_deleted    => $just_deleted, 
						rewrite         => $rewrite,
					}});
					next;
				}
				elsif ($value eq $db_password)
				{
					# No change.
					$password_different = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { password_different => $password_different }});
				}
				else
				{
					# Changed, update it
					$update_reported = 1;
					$line            = $variable.$left_space."=".$right_space.$db_password;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update_reported => $update_reported, 
						line            => $anvil->Log->is_secure($line),
						rewrite         => $rewrite, 
					}});
				}
			}
			elsif ($variable eq $ping_variable)
			{
				# Ping?
				$host_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:value"     => $value,
					"s2:db_ping"   => $db_ping, 
					"s3:host_seen" => $host_seen, 
				}});
				if ($remove)
				{
					# Remove it
					$delete_reported = 1;
					$just_deleted    = 1;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						delete_reported => $delete_reported, 
						just_deleted    => $just_deleted, 
						rewrite         => $rewrite,
					}});
					next;
				}
				elsif ($value eq $db_ping)
				{
					# No change.
					$ping_different = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ping_different => $ping_different }});
				}
				else
				{
					# Changed, update
					$update_reported = 1;
					$line            = $variable.$left_space."=".$right_space.$db_ping;
					$rewrite         = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						update_reported => $update_reported, 
						line            => $line,
						rewrite         => $rewrite, 
					}});
				}
			}
		}
		# Add the (modified?) line to the new body.
		$new_body .= $line."\n";
	}

	# If there was a change, write the file out.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:new_body' => $new_body, 
		's2:rewrite'  => $rewrite,
	}});
	
	if ($rewrite)
	{
		# Now update! This will back up the file as well.
		my ($failed) = $anvil->Storage->write_file({
			debug       => $debug,
			secure      => 1, 
			file        => $anvil->data->{path}{configs}{'anvil.conf'}, 
			body        => $new_body, 
			user        => "admin", 
			group       => "admin", 
			mode        => "0644",
			overwrite   => 1,
			password    => $password, 
			port        => $port, 
			remote_user => $remote_user, 
			target      => $target,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		if ($failed)
		{
			# Something went wrong.
			return(1);
		}
		
		# If this is a local update, disconnect (if no connections exist, will still clear out known 
		# databases), the re-read the new config.
		if ($anvil->Network->is_local({host => $target}))
		{
			$anvil->Database->disconnect;
			
			# Re-read the config.
			sleep 1;
			$anvil->Storage->read_config({file => $anvil->data->{path}{configs}{'anvil.conf'}});
			
			# Reconnect
			$anvil->Database->connect({check_for_resync => 1});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0132"});
		}
	}
	
	return(0);
}


=head2 mark_active

This sets or clears that the caller is about to work on the database

Parameters;

=head3 set (optional, default C<< 1 >>)

If set to c<< 0 >>, 

=cut
sub mark_active
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->mark_active()" }});
	
	my $set = defined $parameter->{set} ? $parameter->{set} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
	
	# If I haven't connected to a database yet, why am I here?
	if (not $anvil->data->{sys}{database}{read_uuid})
	{
		return(0);
	}
	
	my $caller = $ENV{_} ? $ENV{_} : "unknown";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'caller' => $caller }});
	
	# Record that we're using each available striker DB UUID.
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
	{
		my $state_name = "db_in_use::".$uuid."::".$$."::".$caller;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			set        => $set,
			state_name => $state_name,
		}});
		
		if ($set)
		{
			my $state_uuid = $anvil->Database->insert_or_update_states({
				debug           => $debug, 
				state_name      => $state_name,
				state_host_uuid => $anvil->Get->host_uuid,
				state_note      => "1",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
		}
		else
		{
			### NOTE: The 'state' table has no history schema
			# Delete this specific db_in_use, if it exists.
			my $query = "DELETE FROM states WHERE state_name = ".$anvil->Database->quote($state_name)." AND state_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid).";";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
			$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
		}
	}
	return(0);
}


=head2 purge_data

This method takes an array reference of table name and will delete them in reverse order. 

Specifically, it takes each table name and looks for an associated function called C<< history_<table>() >> and calls a C<< DROP ... CASCADE; >> (which takes an associated TRIGGER with it), then looks to see if there is a table in the C<< history >> and C<< public >> schemas, DROP'ing them if found.

This method is designed to allow ScanCore scan agents to be called with C<< --purge >> so that collected data can be purged from the database(s) without deleting non-ScanCore data.

This method returns C<< !!error!! >> if there is a problem, and C<< 0 >> otherwise.

Parameters;

=head3 tables (required)

This is an array reference of table tables to search more. There is no need to specify schema as both C<< public >> and C<< history >> schemas are checked automatically.

This array is walked through in reverse order to allow the same array that is used to load and resync data to be used here.

=cut
sub purge_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->purge_data()" }});
	
	my $tables = $parameter->{tables} ? $parameter->{tables} : "";

	if (not $tables)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->purge_data()", parameter => "tables" }});
		return("!!error!!");
	}
	if (ref($tables) ne "ARRAY")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0218", variables => { name => "tables", value => $tables }});
		return("!!error!!");
	}
	
	my $count = @{$tables};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		my $vacuum = 0;
		foreach my $table (reverse @{$tables})
		{
			# Check for the function.
			my $safe_table       =  $anvil->Database->quote($table);
			   $safe_table       =~ s/^'(.*?)'$/$1/;
			my $history_function =  "history_".$table;
			my $function_query   =  "SELECT COUNT(*) FROM pg_catalog.pg_proc WHERE proname = ".$anvil->Database->quote($history_function).";";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { function_query => $function_query }});
			
			my $function_count = $anvil->Database->query({query => $function_query, uuid => $uuid, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { function_count => $function_count }});
			if ($function_count)
			{
				# Delete it.
				   $vacuum           =  1;
				   $history_function =~ s/^'(.*?)'$/$1/;
				my $query            =  "DROP FUNCTION ".$history_function."() CASCADE;";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
				$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			}
			
			my $history_query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename = ".$anvil->Database->quote($table)." AND schemaname='history';";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { history_query => $history_query }});
			
			my $history_count = $anvil->Database->query({query => $history_query, uuid => $uuid, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { history_count => $history_count }});
			if ($history_count)
			{
				# Delete it.
				   $vacuum =  1;
				my $query  =  "DROP TABLE history.".$safe_table.";";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
				$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			}
			
			my $public_query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename = ".$anvil->Database->quote($table)." AND schemaname='public';";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { public_query => $public_query }});
			
			my $public_count = $anvil->Database->query({query => $public_query, uuid => $uuid, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { public_count => $public_count }});
			if ($public_count)
			{
				# Delete it.
				   $vacuum = 1;
				my $query  = "DROP TABLE public.".$safe_table.";";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
				$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { vacuum => $vacuum }});
		if ($vacuum)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0458"});
			my $query = "VACUUM FULL;";
			$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		}
	}
	
	return(0);
}


=head2 query

This performs a query and returns an array reference of array references (from C<< DBO->fetchall_arrayref >>). The first array contains all the returned rows and each row is an array reference of columns in that row.

If an error occurs, an empty array reference is returned.

For example, given the query;

 anvil=# SELECT host_uuid, host_name, host_type FROM hosts ORDER BY host_name ASC;
               host_uuid               |        host_name         | host_type 
 --------------------------------------+--------------------------+-----------
  e27fc9a0-2656-4aaf-80e6-fedb3c339037 | an-a01n01.alteeve.com    | node
  4bea6ddd-c3ff-43e9-8e9e-b2dea1923145 | an-a01n02.alteeve.com    | node
  ff852db7-c77a-403b-877f-91f85f3ad95c | an-striker01.alteeve.com | dashboard
  2dd5aab1-65d6-4416-9bc1-98dc344aa08b | an-striker02.alteeve.com | dashboard
 (4 rows)

The returned array would have four values, one for each returned row. Each row would be an array reference containing three values, one per row. So given the above example;

 my $rows = $anvil->Database->query({query => "SELECT host_uuid, host_name, host_type FROM hosts ORDER BY host_name ASC;"});
 foreach my $columns (@{$results})
 {
 	my $host_uuid = $columns->[0];
 	my $host_name = $columns->[1];
 	my $host_type = $columns->[2];
	print "Host: [$host_name] (UUID: [$host_uuid], type: [$host_type]).\n";
 }

Would print;

 Host: [an-a01n01.alteeve.com] (UUID: [e27fc9a0-2656-4aaf-80e6-fedb3c339037], type: [node]).
 Host: [an-a01n02.alteeve.com] (UUID: [4bea6ddd-c3ff-43e9-8e9e-b2dea1923145], type: [node]).
 Host: [an-striker01.alteeve.com] (UUID: [ff852db7-c77a-403b-877f-91f85f3ad95c], type: [dashboard]).
 Host: [an-striker02.alteeve.com] (UUID: [2dd5aab1-65d6-4416-9bc1-98dc344aa08b], type: [dashboard]).

B<NOTE>: Do not sort the array references; They won't make any sense as the references are randomly created pointers. The arrays will be returned in the order of the returned data, so do your sorting in the query itself.

Parameters;

=head3 uuid (optional)

By default, the local database will be queried (if run on a machine with a database). Otherwise, the first database successfully connected to will be used for queries (as stored in C<< $anvil->data->{sys}{database}{read_uuid} >>).

If you want to read from a specific database, though, you can set this parameter to the ID of the database (C<< database::<id>::host). If you specify a read from a database that isn't available, An empty array reference will be returned.

=head3 line (optional)

To help with logging the source of a query, C<< line >> can be set to the line number of the script that requested the query. It is generally used along side C<< source >>.

=head3 query (required)

This is the SQL query to perform.

B<NOTE>: ALWAYS use C<< $anvil->Database->quote(...)>> when preparing data coming from ANY external source! Otherwise you'll end up XKCD 327'ing your database eventually...

=head3 secure (optional, defaul '0')

If set, the query will be treated as containing sensitive data and will only be logged if C<< $anvil->Log->secure >> is enabled.

=head3 source (optional)

To help with logging the source of a query, C<< source >> can be set to the name of the script that requested the query. It is generally used along side C<< line >>.

=head3 timeout (optional, default 30)

This sets a timeout on the execution of the query. If the query doesn't return in the set time, the query will be aborted and An empty array reference will be returned. 

Set to C<< 0 >> to set no / infinite timeout.

=cut
sub query
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->query()" }});
	
	my $uuid    =         $parameter->{uuid}    ? $parameter->{uuid}    : "";
	my $line    =         $parameter->{line}    ? $parameter->{line}    : __LINE__;
	my $query   =         $parameter->{query}   ? $parameter->{query}   : "";
	my $secure  =         $parameter->{secure}  ? $parameter->{secure}  : 0;
	my $source  =         $parameter->{source}  ? $parameter->{source}  : $THIS_FILE;
	my $timeout = defined $parameter->{timeout} ? $parameter->{timeout} : 30;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                              => $uuid, 
		"cache::database_handle::${uuid}" => $uuid ? $anvil->data->{cache}{database_handle}{$uuid} : "", 
		line                              => $line, 
		query                             => (not $secure) ? $query : $anvil->Log->is_secure($query), 
		secure                            => $secure, 
		source                            => $source, 
		timeout                           => $timeout, 
	}});
	
	# Use the default read_uuid if a specific UUID wasn't specified.
	my $used_read_uuid = 0;
	if (not $uuid)
	{
		$uuid           = $anvil->data->{sys}{database}{read_uuid};
		$used_read_uuid = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:uuid"                            => $uuid, 
			"s2:used_read_uuid"                  => $used_read_uuid, 
			"s3:cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
		}});
	}
	
	# Make logging code a little cleaner
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"s1:database::${uuid}::name"  => $anvil->data->{database}{$uuid}{name}, 
		"s2:database::${uuid}::host"  => $anvil->data->{database}{$uuid}{host}, 
		"s3:database::${uuid}::port"  => $anvil->data->{database}{$uuid}{port}, 
	}});
	my $database_name =  defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "anvil";
	my $say_server    =  $anvil->data->{database}{$uuid}{host}.":";
	   $say_server    .= $anvil->data->{database}{$uuid}{port}." -> ";
	   $say_server    .= $database_name;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"s1:database_name" => $database_name, 
		"s2:say_server"    => $say_server, 
	}});
	
	my $failed_array_ref = [];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
	
	if (not $uuid)
	{
		# No database to talk to...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0072", variables => { 
			query  => $query,
			source => $source, 
			line   => $line, 
		}});
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
		return($failed_array_ref);
	}
	elsif (not defined $anvil->data->{cache}{database_handle}{$uuid})
	{
		# Database handle is gone. Switch to the read_uuid
		my $old_uuid = $uuid;
		   $uuid     = $anvil->data->{sys}{database}{read_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			old_uuid => $old_uuid, 
			uuid     => $uuid, 
		}});
		if (not defined $anvil->data->{cache}{database_handle}{$uuid})
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0073", variables => { uuid => $uuid }});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
			return($failed_array_ref);
		}
		else
		{
			# Warn that we switched.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0131", variables => { 
				old_uuid => $old_uuid, 
				new_uuid => $uuid,
			}});
		}
	}
	if (not $query)
	{
		# No query
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0084", variables => { server => $say_server }});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
		return($failed_array_ref);
	}
	
	# Test access to the DB before we do the actual query
	my $problem = $anvil->Database->_test_access({debug => $debug, uuid => $uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		if ($used_read_uuid)
		{
			# Switch to the new read_uuid, if possible,
			if ($anvil->data->{sys}{database}{read_uuid})
			{
				$uuid = $anvil->data->{sys}{database}{read_uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
			}
			else
			{
				# No usable databases are available.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0181", variables => { server => $say_server }});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
				return($failed_array_ref);
			}
		}
		else
		{
			# We were given a specific UUID, and we can't read from it. Return an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0180", variables => { server => $say_server }});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
			return($failed_array_ref);
		}
	}
	
	# If I am still alive check if any locks need to be renewed.
	$anvil->Database->check_lock_age({debug => $debug});
	
	# Do I need to log the transaction?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::log_transactions" => $anvil->data->{sys}{database}{log_transactions}, 
	}});
	if ($anvil->data->{sys}{database}{log_transactions})
	{
		$anvil->Log->entry({source => $source, line => $line, secure => $secure, level => 0, key => "log_0074", variables => { 
			uuid  => $anvil->data->{database}{$uuid}{host}, 
			query => $query, 
		}});
	}

	### TODO: Remove this before pr/660 is released.
	# Trying to see how the handle changes if/when the handle is lost.
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid},
		}});
	}
	
	# Do the query.
	local $@;
	my $DBreq = eval { $anvil->data->{cache}{database_handle}{$uuid}->prepare($query) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0075", variables => { 
			query    => (not $secure) ? $query : $anvil->Log->is_secure($query), 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}}); };
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'eval_error' => $@ }});
	if ($@)
	{
		### TODO: Report back somehow that the handle is dead.
		my $connections = $anvil->Database->reconnect({
			debug     => $debug,
			lost_uuid => $uuid, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connections => $connections }});
		if ($connections)
		{
			# Try the prepare again
			$DBreq = eval { $anvil->data->{cache}{database_handle}{$uuid}->prepare($query) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0075", variables => {
				query    => (not $secure) ? $query : $anvil->Log->is_secure($query),
				server   => $say_server,
				db_error => $DBI::errstr,
			}}); };
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'eval_error' => $@ }});
			if ($@)
			{
				# No luck, we're dead
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0675", variables => {
					query      => (not $secure) ? $query : $anvil->Log->is_secure($query),
					server     => $say_server,
					eval_error => $@,
				}});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
				return($failed_array_ref);
			}
		}
		else
		{
			# No luck, we're dead
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0675", variables => {
				query      => (not $secure) ? $query : $anvil->Log->is_secure($query),
				server     => $say_server,
				eval_error => $@,
			}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
			return($failed_array_ref);
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid       => $uuid, 
		query      => (not $secure) ? $query : $anvil->Log->is_secure($query), 
		say_server => $say_server, 
		DBreq      => $DBreq,
	}});
	
	# Execute on the query
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { timeout => $timeout }});
	alarm($timeout);
	eval {
		$DBreq->execute() or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0076", variables => { 
			query    => (not $secure) ? $query : $anvil->Log->is_secure($query), 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}}); 
	};
	alarm(0);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'alarm $@' => $@ }});
	if ($@)
	{
		if (($@ =~ /time/i) && ($@ =~ /out/i))
		{
			# Timed out 
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0175", variables => { 
				query   => (not $secure) ? $query : $anvil->Log->is_secure($query),
				timeout => $timeout, 
				error   => $@,
			}});
		}
		else
		{
			# Other error
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0175", variables => { 
				query => (not $secure) ? $query : $anvil->Log->is_secure($query),
				error => $@,
			}});
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed_array_ref => $failed_array_ref }});
		return($failed_array_ref);
	}
	
	# Return the array
	return($DBreq->fetchall_arrayref());
}


=head2 quote

This quotes a string for safe use in database queries/writes. It operates exactly as C<< DBI >>'s C<< quote >> method. This method is simply a wrapper that uses the C<< DBI >> handle set as the currently active read database.

If there is a problem, an empty string will be returned and an error will be logged and printed to STDOUT.

Example;

 $anvil->Database->quote("foo");

B<< NOTE >>:

Unlike most Anvil methods, this one does NOT use hashes for the parameters! It is meant to replicate C<< DBI->quote("foo") >>, so the only passed-in value is the string to quote. If an undefined or empty string is passed in, a quoted empty string will be returned.

=cut
sub quote
{
	my $self   = shift;
	my $string = shift;
	my $anvil  = $self->parent;
	
	$string = "" if not defined $string;
	
	if (not $anvil->data->{sys}{database}{connections})
	{
		# No databases, can't quote.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, 'print' => 1, key => "warning_0188", variables => { string => $string }});
		
		# Given this might be about to get used in a DB query, return nothing. That should cause 
		# whatever query this was called for to error safely.
		return("");
	}
	
	# Make sure we're using an active handle.
	my $quoted = eval {$anvil->Database->read->quote($string); };
	if ($@)
	{
		$quoted = "" if not defined $quoted;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, 'print' => 1, key => "warning_0177", variables => { 
			string => $string,
			error  => $@,
		}});
		
		# Given this might be about to get used in a DB query, return nothing. That should cause 
		# whatever query this was called for to error safely.
		return("");
	}
	
	return($quoted);
}


=head2 read

This method returns the active database handle used for reading. When C<< Database->connect() >> is called, it tries to find the local database (if available) and use that for reads. If there is no local database, then the first database successfully connected to is used instead.

Example setting a handle to use for future reads;

 $anvil->Database->read({set => $dbh});

Example, using the database handle to quote a string;

 $anvil->Database->read->quote("foo");

Parameters;

=head3 set (optional)

If used, the passed in value is set as the new handle to use for future reads. 

=cut
sub read
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	
	# We could be passed an empty string, which is the same as 'delete'.
	if (defined $parameter->{set})
	{
		if ($parameter->{set} eq "delete")
		{
			$anvil->data->{sys}{database}{use_handle} = "";
		}
		else
		{
			$anvil->data->{sys}{database}{use_handle} = $parameter->{set};
		}
	}
	elsif (not defined $anvil->data->{sys}{database}{use_handle})
	{
		$anvil->data->{sys}{database}{use_handle} = "";
	}
	
	return($anvil->data->{sys}{database}{use_handle});
}


=head2 read_state

This reads a C<< state_note >> from the C<< states >> table. An anonymous array reference is returned with the C<< state_name >>, C<< state_uuid >>, and C<< modified_date >> (in unix time format) in that order.

If anything goes wrong, C<< !!error!! >> is returned for all values in the array reference. If the state didn't exist in the database, an empty string will be returned.

Parameters;

=head3 state_uuid (optional)

If specified, this specifies the state UUID to read. When this parameter is specified, the C<< state_name >> parameter is ignored.

=head3 state_name (required)

This is the name of the state we're reading.

=head3 state_host_uuid (optional)

This is the C<< host_uuid >> of the state we're reading

=head3 uuid (optional)

If set, this specified which database to read the C<< state_note >> from.

=cut
sub read_state
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->read_state()" }});
	
	my $state_uuid      = $parameter->{state_uuid}      ? $parameter->{state_uuid}      : "";
	my $state_name      = $parameter->{state_name}      ? $parameter->{state_name}      : "";
	my $state_host_uuid = $parameter->{state_host_uuid} ? $parameter->{state_host_uuid} : "";
	my $uuid            = $parameter->{uuid}            ? $parameter->{uuid}            : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid            => $uuid, 
		state_uuid      => $state_uuid, 
		state_name      => $state_name, 
		state_host_uuid => $state_host_uuid, 
	}});
	
	# If there are no DBs to connect to, we can't read any state.
	if (not $anvil->data->{sys}{database}{connections})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0189", variables => { 
			state_uuid      => $state_uuid, 
			state_name      => $state_name, 
			state_host_uuid => $state_host_uuid, 
		}});
		return("", $state_uuid, "");
	}
	
	if ((not $uuid) && ($anvil->data->{sys}{database}{read_uuid}))
	{
		$uuid = $anvil->data->{sys}{database}{read_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	}
	
	# Do we have either the state name or UUID?
	if ((not $state_name) && (not $state_uuid))
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0704"});
		return("!!error!!", "!!error!!", "!!error!!");
	}
	
	# If we don't have a UUID, see if we can find one for the given SMTP server name.
	my $query = "
SELECT 
    state_note, 
    state_uuid, 
    round(extract(epoch from modified_date)) AS mtime 
FROM 
    states 
WHERE ";
	if ($state_uuid)
	{
		$query .= "
    state_uuid = ".$anvil->Database->quote($state_uuid);
	}
	else
	{
		$query .= "
    state_name = ".$anvil->Database->quote($state_name);
		if ($state_host_uuid ne "")
		{
			$query .= "
AND 
    state_host_uuid  = ".$anvil->Database->quote($state_host_uuid)." 
";
		}
	}
	$query .= ";";
	$query =~ s/'NULL'/NULL/g;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	
	my $state_note = "";
	my $mtime      = "";
	my $results    = $anvil->Database->query({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
	my $count      = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		$state_note = $row->[0];
		$state_uuid = $row->[1];
		$mtime      = $row->[2];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			state_note => $state_note, 
			state_uuid => $state_uuid, 
			mtime      => $mtime, 
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		state_note => $state_note, 
		state_uuid => $state_uuid, 
		mtime      => $mtime, 
	}});
	return($state_note, $state_uuid, $mtime);
}


=head2 read_variable

This reads a variable from the C<< variables >> table. Be sure to only use the reply from here to override what might have been set in a config file. This method always returns the data from the database itself.

The method returns an array reference containing, in order, the variable's value, variable UUID and last modified date stamp in unix time (since epoch) and last as a normal time stamp.

If anything goes wrong, C<< !!error!! >> is returned. If the variable didn't exist in the database, an empty string will be returned for the UUID, value and modified date.

Parameters;

=head3 variable_uuid (optional)

If specified, this specifies the variable UUID to read. When this parameter is specified, the C<< variable_name >> parameter is ignored.

=head3 variable_name (required)

This is the name of the variable we're reading.

=head3 variable_source_table (optional)

If set along with C<< variable_source_uuid >>, the variable being read will be specified against this and the UUID.

=head3 variable_source_uuid (optional)

If set along with C<< variable_source_table >>, the variable being read will be specified against this and the source table.

=cut
sub read_variable
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->read_variable()" }});
	
	my $variable_uuid         = $parameter->{variable_uuid}         ? $parameter->{variable_uuid}         : "";
	my $variable_name         = $parameter->{variable_name}         ? $parameter->{variable_name}         : "";
	my $variable_source_uuid  = $parameter->{variable_source_uuid}  ? $parameter->{variable_source_uuid}  : "";
	my $variable_source_table = $parameter->{variable_source_table} ? $parameter->{variable_source_table} : "";
	my $uuid                  = $parameter->{uuid}                  ? $parameter->{uuid}                  : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                  => $uuid, 
		variable_uuid         => $variable_uuid, 
		variable_name         => $variable_name, 
		variable_source_uuid  => $variable_source_uuid, 
		variable_source_table => $variable_source_table, 
	}});
	
	if ((not $uuid) && ($anvil->data->{sys}{database}{read_uuid}))
	{
		$uuid = $anvil->data->{sys}{database}{read_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	}
	
	if (not $variable_source_uuid)
	{
		$variable_source_uuid = "NULL";
	}
	
	# Do we have either the variable name or UUID?
	if ((not $variable_name) && (not $variable_uuid))
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0036"});
		return("!!error!!", "!!error!!", "!!error!!");
	}
	
	# If we don't have a UUID, see if we can find one for the given SMTP server name.
	my $query = "
SELECT 
    variable_value, 
    variable_uuid, 
    round(extract(epoch from modified_date)) AS mtime, 
    modified_date
FROM 
    variables 
WHERE ";
	if ($variable_uuid)
	{
		$query .= "
    variable_uuid = ".$anvil->Database->quote($variable_uuid);
	}
	else
	{
		$query .= "
    variable_name = ".$anvil->Database->quote($variable_name);
		if (($variable_source_uuid ne "") && ($variable_source_table ne ""))
		{
			$query .= "
AND 
    variable_source_uuid  = ".$anvil->Database->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->Database->quote($variable_source_table)." 
";
		}
	}
	$query .= ";";
	$query =~ s/'NULL'/NULL/g;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	
	my $variable_value = "";
	my $mtime          = "";
	my $modified_date  = "";
	my $results        = $anvil->Database->query({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
	my $count          = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		$variable_value = $row->[0];
		$variable_uuid  = $row->[1];
		$mtime          = $row->[2];
		$modified_date  = $row->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			variable_value => $variable_value, 
			variable_uuid  => $variable_uuid, 
			mtime          => $mtime, 
			modified_date  => $modified_date, 
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		variable_value => $variable_value, 
		variable_uuid  => $variable_uuid, 
		mtime          => $mtime, 
		modified_date  => $modified_date, 
	}});
	return($variable_value, $variable_uuid, $mtime, $modified_date);
}


=head2 reconnect

This method disconnects from any connected databases, re-reads the config, and then tries to reconnect to any databases again. The number of connected datbaases is returned.

B<< Note >>: This calls C<< Database->disconnect({cleanup => 0}); >> to prevent attempts to talk to the potentially lost database handle.

Parameters;

=head3 lost_uuid (optional)

If set to a database UUID, then the database handle is deleted before the disconnect method is called, preventing an attempt to update locks and state information on a dead DB connection.

=cut
sub reconnect
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->reconnect()" }});
	
	my $lost_uuid = defined $parameter->{lost_uuid} ? $parameter->{lost_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		lost_uuid => $lost_uuid, 
	}});
	
	if (($lost_uuid) && ($anvil->data->{cache}{database_handle}{$lost_uuid}))
	{
		$anvil->data->{cache}{database_handle}{$lost_uuid} = "";
		$anvil->data->{sys}{database}{connections}-- if $anvil->data->{sys}{database}{connections} > 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:cache::database_handle::${lost_uuid}" => $anvil->data->{cache}{database_handle}{$lost_uuid}, 
			"s2:sys::database::connections"           => $anvil->data->{sys}{database}{connections}, 
		}});
	}

	# Disconnect from all databases and then stop the daemon, then reconnect.
	$anvil->Database->disconnect({
		debug   => $debug, 
		cleanup => 0,
	});
	sleep 2;

	# Refresh configs.
	$anvil->refresh();

	# Reconnect.
	$anvil->Database->connect({debug => $debug});

	# Log our connection count.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		"sys::database::connections" => $anvil->data->{sys}{database}{connections},
	}});
	return($anvil->data->{sys}{database}{connections});
}


=head2 refresh_timestamp

This refreshes C<< sys::database::timestamp >>. It returns C<< sys::database::timestamp >> as well.

This method takes no parameters.

=cut
sub refresh_timestamp
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	
	my $match = 0;
	my $ok    = 0;
	until ($ok)
	{
		my $query    = "SELECT cast(now() AS timestamp with time zone);";
		my $new_time = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		
		if (($anvil->data->{sys}{database}{timestamp}) && ($anvil->data->{sys}{database}{timestamp} eq $new_time))
		{
			# Log that we hit this, then loop until we get a different result.
			if (not $match)
			{
				$match = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0702"});
			}
		}
		else
		{
			# Different result. If we looped, log that we're clear now.
			$ok = 1;
			if ($match)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0703", variables => {
					old_time => $anvil->data->{sys}{database}{timestamp}, 
					new_time => $new_time, 
				}});
			}
			# Store the time stamp.
			$anvil->data->{sys}{database}{timestamp} = $new_time;
		}
	}
	
	return($anvil->data->{sys}{database}{timestamp});
}


=head2 resync_databases

This will resync the database data on this and peer database(s) if needed. It takes no arguments and will immediately return unless C<< sys::database::resync_needed >> was set.

If C<< switches::purge >> is set, this method will also return without doing anything.

=cut
sub resync_databases
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->resync_databases()" }});
	
	# If a resync isn't needed, just return. 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::database::resync_needed' => $anvil->data->{sys}{database}{resync_needed} }});
	if (not $anvil->data->{sys}{database}{resync_needed})
	{
		# We don't need table data, clear it.
		delete $anvil->data->{sys}{database}{table};
		return(0);
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "switches::purge" => $anvil->data->{switches}{purge} }});
	if ((exists $anvil->data->{switches}{purge}) && ($anvil->data->{switches}{purge}))
	{
		# The user is calling a purge, so skip resync for now as the data might be about to all go away anyway.
		delete $anvil->data->{sys}{database}{table};
		return(0);
	}
	
	# If we're not a striker, don't resync ever.
	my $host_type = $anvil->Get->host_type();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "striker")
	{
		# Not a dashboard, don't resync
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0686"});
		return(1);
	}
	
	# If we're hosting servers, don't resync. Too high of a risk of oom-killer being triggered.
	my $server_count = $anvil->Server->count_servers({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_count => $server_count }});
	if ($server_count)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0680", variables => { count => $server_count }});
		return(0);
	}
	
	# Before resync, age out the data in each DB
	$anvil->Database->_age_out_data({debug => $debug});
	
	# Build a list of tables 
	my $tables     = $anvil->Database->get_tables_from_schema({debug => $debug, schema_file => "all"});
	my $start_time = time;
	foreach my $table (@{$tables})
	{
		# We don't sync 'states' as it's transient and sometimes per-DB.
		next if $table eq "states";
		
		# Don't sync any table that doesn't have a history schema
		next if $table eq "alert_sent";
		next if $table eq "states";
		next if $table eq "update";
		
		# If the 'schema' is 'public', there is no table in the history schema.
		my $schema = $anvil->data->{sys}{database}{table}{$table}{schema} ? $anvil->data->{sys}{database}{table}{$table}{schema} : "public";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			table  => $table, 
			schema => $schema, 
		}});
		
		# If there is a column name that is '<table>_uuid', or the same with the table's name minus 
		# the last 's' or 'es', this will be the UUID column to keep records linked in history. We'll
		# need to know this off the bat. Tables where we don't find a UUID column won't be sync'ed.
		my $column1 = $table."_uuid";
		my $column2 = "";
		my $column3 = "";
		my $column4 = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column1 => $column1 }});
		if ($table =~ /^(.*)s$/)
		{
			$column2 = $1."_uuid";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column2 => $column2 }});
		}
		if ($table =~ /^(.*)es$/)
		{
			$column3 = $1."_uuid";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column3 => $column3 }});
		}
		if ($table =~ /^(.*)ies$/)
		{
			$column4 = $1."y_uuid";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column4 => $column4 }});
		}
		my $query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = 'anvil' AND table_schema = 'public' AND table_name = ".$anvil->Database->quote($table)." AND data_type = 'uuid' AND is_nullable = 'NO' AND column_name = ".$anvil->Database->quote($column1).";";
		if ($column4)
		{
			$query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = 'anvil' AND table_schema = 'public' AND table_name = ".$anvil->Database->quote($table)." AND data_type = 'uuid' AND is_nullable = 'NO' AND (column_name = ".$anvil->Database->quote($column1)." OR column_name = ".$anvil->Database->quote($column2)." OR column_name = ".$anvil->Database->quote($column3)." OR column_name = ".$anvil->Database->quote($column4).");";
		}
		elsif ($column3)
		{
			$query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = 'anvil' AND table_schema = 'public' AND table_name = ".$anvil->Database->quote($table)." AND data_type = 'uuid' AND is_nullable = 'NO' AND (column_name = ".$anvil->Database->quote($column1)." OR column_name = ".$anvil->Database->quote($column2)." OR column_name = ".$anvil->Database->quote($column3).");";
		}
		elsif ($column2)
		{
			$query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = 'anvil' AND table_schema = 'public' AND table_name = ".$anvil->Database->quote($table)." AND data_type = 'uuid' AND is_nullable = 'NO' AND (column_name = ".$anvil->Database->quote($column1)." OR column_name = ".$anvil->Database->quote($column2).");";
		}
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
		my $uuid_column = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		   $uuid_column = "" if not defined $uuid_column;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid_column => $uuid_column }});
		if (not $uuid_column)
		{
			# This is a problem
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0311", variables => { table => $table }});
			next;
		}
		
		# Get all the columns in this table.
		$query = "SELECT column_name, is_nullable, data_type FROM information_schema.columns WHERE table_schema = ".$anvil->Database->quote($schema)." AND table_name = ".$anvil->Database->quote($table)." AND column_name != 'history_id';";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $column_name = $row->[0];
			my $not_null    = $row->[1] eq "NO" ? 1 : 0;
			my $data_type   = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				column_name => $column_name, 
				not_null    => $not_null, 
				data_type   => $data_type,
			}});
			
			$anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{not_null}  = $not_null;
			$anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{data_type} = $data_type;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::table::${table}::column::${column_name}::not_null"  => $anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{not_null}, 
				"sys::database::table::${table}::column::${column_name}::data_type" => $anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{data_type}, 
			}});
		}
		
		### TODO: This can be removed later.
		# Look through the bridges, bonds, and network interfaces tables. Look for records in the 
		# history schema that don't exist in the public schema and purge them.
		if ($schema eq "history")
		{
			foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});

				my $query = "SELECT DISTINCT ".$uuid_column." FROM history.".$table.";";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
				
				my $results = $anvil->Database->query({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
				my $count   = @{$results};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					results => $results, 
					count   => $count,
				}});
				foreach my $row (@{$results})
				{
					my $column_uuid = $row->[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column_uuid => $column_uuid }});
					
					my $query = "SELECT COUNT(*) FROM ".$table." WHERE ".$uuid_column." = '".$column_uuid."';";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
					
					my $count = $anvil->Database->query({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
					
					if (not $count)
					{
						# Purge it from everywhere.
						my $queries = [];
						push @{$queries}, "DELETE FROM history.".$table." WHERE ".$uuid_column." = '".$column_uuid."';";
						push @{$queries}, "DELETE FROM ".$table." WHERE ".$uuid_column." = '".$column_uuid."';";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0365", variables => { 
							table       => $table, 
							uuid_column => $uuid_column, 
							column_uuid => $column_uuid, 
						}});
						# Delete across all DBs.
						$anvil->Database->write({debug => $debug, query => $queries, source => $THIS_FILE, line => __LINE__});
					}
				}
			}
		}
		
		# Now read in the data from the different databases.
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
			
			# This will store queries.
			$anvil->data->{db_resync}{$uuid}{public}{sql}  = [];
			$anvil->data->{db_resync}{$uuid}{history}{sql} = [];
			
			### NOTE: The history_id is used to insure that the first duplicate entry is the one
			###       we want to save, and any others are deleted. 
			# Read in the data, history_id and modified_date first as we'll need that for all entries we record.
			my $query        = "SELECT modified_date AT time zone 'UTC' AS utc_modified_date, $uuid_column, ";
			my $read_columns = [];
			if ($schema eq "history")
			{
				# Most tables are reading from history, but some aren't.
				$query = "SELECT history_id, modified_date AT time zone 'UTC' AS utc_modified_date, $uuid_column, ";
				push @{$read_columns}, "history_id";
			}
			push @{$read_columns}, "modified_date";
			push @{$read_columns}, $uuid_column;
			foreach my $column_name (sort {$a cmp $b} keys %{$anvil->data->{sys}{database}{table}{$table}{column}})
			{
				# We'll skip the host column as we'll use it in the conditional.
				next if $column_name eq "history_id";
				next if $column_name eq "modified_date";
				next if $column_name eq $uuid_column;
				$query .= $column_name.", ";
				
				push @{$read_columns}, $column_name;
			}
			
			# Strip the last comma and the add the schema.table name.
			$query =~ s/, $/ /;
			$query .= "FROM ".$schema.".".$table;
			if ($schema eq "history")
			{
				$query .= " ORDER BY utc_modified_date DESC, history_id DESC;";
			}
			else
			{
				$query .= " ORDER BY utc_modified_date DESC;";
			}
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0074", variables => { 
				uuid  => $anvil->Database->get_host_from_uuid({debug => $debug, short => 1, host_uuid => $uuid}), 
				query => $query,
			}});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
				results => $results, 
				count   => $count,
			}});
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:database'     => $anvil->Get->host_name_from_uuid({host_uuid => $uuid}),
				's2:schema.table' => $schema.".".$table,
				's3:count'        => $count,
			}});
			next if not $count;
			
			# In some cases, a single 'modified_date::uuid_column' can exist multiple times
			my $last_record = "";
			my $row_number  = 0;
			foreach my $row (@{$results})
			{
				   $row_number++;
				my $history_id    = "";
				my $modified_date = "";
				my $row_uuid      = "";
				for (my $column_number = 0; $column_number < @{$read_columns}; $column_number++)
				{
					my $column_name  = $read_columns->[$column_number];
					my $column_value = defined $row->[$column_number] ? $row->[$column_number] : "NULL";
					my $not_null     = $anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{not_null};
					my $data_type    = $anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{data_type};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:id"            => $uuid,
						"s2:row_number"    => $row_number,
						"s3:column_number" => $column_number,
						"s4:column_name"   => $column_name, 
						"s5:column_value"  => $column_value,
						"s6:not_null"      => $not_null,
						"s7:data_type"     => $data_type, 
					}});
					if (($not_null) && ($column_value eq "NULL"))
					{
						$column_value = "";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column_value => $column_value }});
					}
					
					# The history_id should be the first row.
					if ($column_name eq "history_id")
					{
						$history_id = $column_value;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { history_id => $history_id }});
						next;
					}
					# The modified_date should be the second row.
					if ($column_name eq "modified_date")
					{
						$modified_date = $column_value;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { modified_date => $modified_date }});
						next;
					}
					
					# The row's UUID should be the second row.
					if ($column_name eq $uuid_column)
					{
						$row_uuid = $column_value;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { row_uuid => $row_uuid }});
						
						# We should have the modified_date already, is this a 
						# duplicate?
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							last_record               => $last_record,
							"modified_date::row_uuid" => "${modified_date}::${row_uuid}",
						}});
						if (($last_record) && ($schema eq "history") && ($last_record eq "${modified_date}::${row_uuid}"))
						{
							# Duplicate! 
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0363", variables => { 
								table => $table, 
								key   => $last_record, 
								query => $query,
								host  => $anvil->Database->get_host_from_uuid({short => 1, host_uuid => $uuid}), 
							}});
							
							# Delete this entry.
							my $query = "DELETE FROM history.".$table." WHERE history_id = ".$history_id.";";
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
							
							$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
							next;
						}
						
						$last_record = $modified_date."::".$row_uuid;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_record => $last_record }});
						
						# This is used to determine if a given entry needs to be 
						# updated or inserted into the public schema
						$anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'} = 1;
						$anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen}     = 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::exists" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'}, 
							"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::seen"   => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen}, 
						}});
						
						next;
					}
					
					# If we failed to get a modified_date, something went very wrong.
					if (not $modified_date)
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0114", variables => { query => $query }});
						$anvil->nice_exit({exit_code => 1});
					}
					
					# If we don't have a row uuid, something has also gone wrong...
					if (not $row_uuid)
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0115", variables => { 
							uuid_column => $uuid_column, 
							query       => $query,
						}});
						$anvil->nice_exit({exit_code => 1});
					}
					
					# Record this in the unified and local hashes.
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { row_uuid => $row_uuid }});
					
					$anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name} = $column_value;
					$anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name}   = $column_value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"db_data::unified::${table}::modified_date::${modified_date}::${uuid_column}::${row_uuid}::${column_name}" => $anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name}, 
						"db_data::${uuid}::${table}::modified_date::${modified_date}::${uuid_column}::${row_uuid}::${column_name}" => $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name}, 
					}});
				}
			}
		}
		
		# Now all the data is read in, we can see what might be missing from each DB.
		foreach my $modified_date (sort {$b cmp $a} keys %{$anvil->data->{db_data}{unified}{$table}{modified_date}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { modified_date => $modified_date }});
			foreach my $row_uuid (sort {$a cmp $b} keys %{$anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { row_uuid => $row_uuid }});
				
				foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
					
					# For each 'row_uuid' we see;
					# - Check if we've *seen* it before
					#   |- If not seen; See if it *exists* in the public schema yet.
					#   |  |- If so, check to see if the entry in the public schema is up to date.
					#   |  |  \- If not, _UPDATE_ public schema.
					#   |  \- If not, do an _INSERT_ into public schema.
					#   \- If we have seen, see if it exists at the current timestamp.
					#      \- If not, _INSERT_ it into history schema.
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::seen" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen}, 
					}});
					$anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen} = 0 if not defined $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen};
					if (not $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen})
					{
						# Mark this record as now having been seen.
						$anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen} = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::seen" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen}, 
						}});
						
						# Does it exist?
						$anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'} = 0 if not defined $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::exists" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'}, 
						}});
						if ($anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'})
						{
							# It exists, but does it exist at this time stamp?
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"db_data::${uuid}::${table}::modified_date::${modified_date}::${uuid_column}::${row_uuid}" => $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}, 
							}});
							if (not $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid})
							{
								# No, so UPDATE it. We'll build the query now...
								my $query = "UPDATE public.$table SET ";
								foreach my $column_name (sort {$a cmp $b} keys %{$anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}})
								{
									my $column_value =  $anvil->Database->quote($anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name});
									   $column_value =  "NULL" if not defined $column_value;
									   $column_value =~ s/'NULL'/NULL/g;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
										column_name  => $column_name, 
										column_value => $column_value, 
									}});
									
									$query .= "$column_name = ".$column_value.", ";
								}
								$query .= "modified_date = ".$anvil->Database->quote($modified_date)."::timestamp AT TIME ZONE 'UTC' WHERE $uuid_column = ".$anvil->Database->quote($row_uuid).";";
								$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $table eq "hosts" ? 2 : $debug, key => "log_0460", variables => { uuid => $anvil->data->{database}{$uuid}{host}, query => $query }});
								
								# Now record the query in the array
								push @{$anvil->data->{db_resync}{$uuid}{public}{sql}}, $query;
							} # if not exists - timestamp
						} # if exists
						else
						{
							# It doesn't exist, so INSERT it. We need to 
							# build entries for the column names and 
							# values at the same time to make certain 
							# they're in the same order.
							my $columns = "";
							my $values  = "";
							foreach my $column_name (sort {$a cmp $b} keys %{$anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}})
							{
								my $column_value =  $anvil->Database->quote($anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name});
								   $column_value =~ s/'NULL'/NULL/g;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									column_name  => $column_name, 
									column_value => $column_value, 
								}});
								$columns .= $column_name.", ";
								$values  .= $column_value.", ";
							}
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								columns  => $columns, 
								'values' => $values, 
							}});
							
							my $query = "INSERT INTO public.".$table." (".$uuid_column.", ".$columns."modified_date) VALUES (".$anvil->Database->quote($row_uuid).", ".$values.$anvil->Database->quote($modified_date)."::timestamp AT TIME ZONE 'UTC');";
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $table eq "hosts" ? 2 : $debug, key => "log_0460", variables => { uuid => $anvil->data->{database}{$uuid}{host}, query => $query }});
							
							### NOTE: After an archive operationg, a record can 
							###       end up in the public schema while nothing 
							###       exists in the history schema (which is what
							###       we read during a resync). To deal with 
							###       this, we'll do an explicit check before 
							###       confirming the INSERT)
							my $count_query = "SELECT COUNT(*) FROM public.".$table." WHERE ".$uuid_column." = ".$anvil->Database->quote($row_uuid).";";
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count_query => $count_query }});
							my $count = $anvil->Database->query({uuid => $uuid, query => $count_query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
							if ($count)
							{
								# Already in, redirect to the history schema.
								$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0029", variables => { 
									table     => $table, 
									host_name => $anvil->Database->get_host_from_uuid({debug => $debug, short => 1, host_uuid => $uuid}), 
									host_uuid => $uuid, 
									column    => $uuid_column, 
									uuid      => $row_uuid, 
									query     => $query, 
								}});
								$query =~ s/INSERT INTO public./INSERT INTO history./;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $table eq "hosts" ? 2 : $debug, list => { query => $query }});
								
								push @{$anvil->data->{db_resync}{$uuid}{history}{sql}}, $query;
							}
							else
							{
								# No problem, record the query in the array
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
								push @{$anvil->data->{db_resync}{$uuid}{public}{sql}}, $query;
							}
						} # if not exists
					} # if not seen
					else
					{
						### NOTE: If the table doesn't have a history schema,
						###       we skip this.
						next if $schema eq "public";
						
						# We've seen this row_uuid before, so it is just a 
						# question of whether the entry for the current 
						# timestamp exists in the history schema.
						$anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid} = 0 if not defined $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"db_data::${uuid}::${table}::modified_date::${modified_date}::${uuid_column}::${row_uuid}" => $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}, 
						}});
						if (not $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid})
						{
							# It hasn't been seen, so INSERT it. We need 
							# to build entries for the column names and 
							# values at the same time to make certain 
							# they're in the same order.
							my $columns = "";
							my $values  = "";
							foreach my $column_name (sort {$a cmp $b} keys %{$anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}})
							{
								my $column_value =  $anvil->Database->quote($anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name});
									$column_value =~ s/'NULL'/NULL/g;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									column_name  => $column_name, 
									column_value => $column_value, 
								}});
								$columns .= $column_name.", ";
								$values  .= $column_value.", ";
							}
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								columns  => $columns, 
								'values' => $values, 
							}});
							
							my $query = "INSERT INTO history.$table (".$uuid_column.", ".$columns."modified_date) VALUES (".$anvil->Database->quote($row_uuid).", ".$values.$anvil->Database->quote($modified_date)."::timestamp AT TIME ZONE 'UTC');";
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0460", variables => { uuid => $anvil->data->{database}{$uuid}{host}, query => $query }});
							
							# Now record the query in the array
							push @{$anvil->data->{db_resync}{$uuid}{history}{sql}}, $query;
						} # if not exists - timestamp
					} # if seen
				} # foreach $uuid
			} # foreach $row_uuid
		} # foreach $modified_date ...
		
		# Free up memory by deleting the DB data from the main hash.
		delete $anvil->data->{db_data};
		
		# Do the INSERTs now and then release the memory.
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
			# Merge the queries for both schemas into one array, with public schema 
			# queries being first, then delete the arrays holding them to free memory
			# before we start the resync.
			my $merged = [];
			@{$merged} = (@{$anvil->data->{db_resync}{$uuid}{public}{sql}}, @{$anvil->data->{db_resync}{$uuid}{history}{sql}});
			undef $anvil->data->{db_resync}{$uuid}{public}{sql};
			undef $anvil->data->{db_resync}{$uuid}{history}{sql};
			
			# If the merged array has any entries, push them in.
			my $to_write_count = @{$merged};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { to_write_count => $to_write_count }});
			if ($to_write_count > 0)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0221", variables => { 
					to_write  => $anvil->Convert->add_commas({number => $to_write_count}),
					table     => $table, 
					host_name => $anvil->Get->host_name_from_uuid({host_uuid => $uuid}), 
				}});
				$anvil->Database->write({debug => $debug, uuid => $uuid, query => $merged, source => $THIS_FILE, line => __LINE__});
				undef $merged;
			}
		}
	} # foreach my $table

	# We're done with the table data, clear it.
	delete $anvil->data->{sys}{database}{table};
	
	# Search for duplicates from the resync
	$anvil->Database->_check_for_duplicates({debug => 2});
	
	# Clear the variable that indicates we need a resync.
	$anvil->data->{sys}{database}{resync_needed} = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::database::resync_needed' => $anvil->data->{sys}{database}{resync_needed} }});
	
	my $time_taken = time - $start_time;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { time_taken => $time_taken }});
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0674", variables => { took => $time_taken }});
	
	return(0);
}


=head2 shutdown

This gracefully shuts down the local database, waiting for active connections to exit before doing so. This call only works on a Striker dashboard. It creates a dump file of the database as part of the shutdown. It always returns C<< 0 >>.

B<< Note >>: This will not return until the database is stopped. This can take some time as it waits for all connections to close, with a C<< 600 >> second (five minute) timeout. 

This method takes no parameters.

=cut
sub shutdown
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->shutdown()" }});
	
	# Are we a striker?
	my $host_type = $anvil->Get->host_type();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "striker")
	{
		# Not a dashboard, nothing to do.
		return(0);
	}
	
	# Is the local databsae running?
	my $running = $anvil->System->check_daemon({
		debug  => $debug, 
		daemon => $anvil->data->{sys}{daemon}{postgresql},
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
	if (not $running)
	{
		# Already stopped.
		return(0);
	}
	
	# Set the variable to say we're shutting down.
	my $host_uuid =  $anvil->Database->quote($anvil->Get->host_uuid);
	   $host_uuid =~ s/^'(.*)'$/$1/;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	my $variable_uuid = $anvil->Database->insert_or_update_variables({
		variable_name         => "database::".$host_uuid."::active",
		variable_value        => "0",
		variable_default      => "0", 
		variable_description  => "striker_0294", 
		variable_section      => "database", 
		variable_source_uuid  => "NULL", 
		variable_source_table => "", 
	});
	
	# This query will be called repeatedly.
	my $query = "
SELECT 
    state_uuid, 
    state_name, 
    state_host_uuid 
FROM 
    states 
WHERE 
    state_name 
LIKE 
    'db_in_use::".$host_uuid."::%' 
AND 
    state_note = '1'
;";
	
	# Now wait for all clients to disconnect.
	my $waiting      =  1;
	my $wait_time    = 600;
	my $stop_waiting =  time + $wait_time;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:time'         => time,
		's2:wait_time'    => $wait_time, 
		's3:stop_waiting' => $stop_waiting, 
	}});
	while($waiting)
	{
		# PIDs will track pids using our DB locally. Users tracks how many other clients are using 
		# our DB.
		my $pids  = "";
		my $users = 0;
		
		# Check for any users using us.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count)
		{
			# Do the same checks we do in anvil-daemon 
			$anvil->System->pids();
			foreach my $row (@{$results})
			{
				my $state_uuid      = $row->[0];
				my $state_name      = $row->[1];
				my $state_host_uuid = $row->[2];
				my $state_pid       = ($state_name =~ /db_in_use::.*?::(.*)$/)[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:state_uuid'      => $state_uuid, 
					's2:state_name'      => $state_name, 
					's3:state_pid'       => $state_pid, 
					's4:state_host_uuid' => $state_host_uuid, 
					's4:our_pid'         => $$,
				}});
				# If this is held by us, make sure we ignore our active PID.
				if ($state_host_uuid eq $anvil->Get->host_uuid)
				{
					if ($state_pid eq $$)
					{
						# This is us, ignore it.
						next;
					}
					if (not exists $anvil->data->{pids}{$state_pid})
					{
						# Reap the 'db_is_use'.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0140", variables => { pid => $state_pid }});
						
						my $query = "DELETE FROM states WHERE state_uuid = ".$anvil->Database->quote($state_uuid).";";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
						$anvil->Database->write({debug => 2, query => $query, source => $THIS_FILE, line => __LINE__});
					}
					else
					{
						my $command = $anvil->data->{pids}{$state_pid}{command};
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0142", variables => { command => $command }});
						
						$pids .= $state_pid.",";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pids => $pids }});
					}
					$pids =~ s/,$//;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pids => $pids }});
				}
				else
				{
					$users++;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { users => $users }});
				}
			}
		}
		
		# If there's no count, we're done.
		if ((not $pids) && (not $users))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0697"});
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { waiting => $waiting }});
		}
		elsif (time > $stop_waiting)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0141", variables => { wait_time => $wait_time }});
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { waiting => $waiting }});
		}
		else
		{
			sleep 3;
		}
	}
	
	$host_uuid = $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	
	# Delete all jobs on our local database, and then stop the DB
	$query = "DELETE FROM history.jobs; DELETE FROM jobs;";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0124", variables => { query => $query }});
	$anvil->Database->write({debug => $debug, uuid => $host_uuid, query => $query, source => $THIS_FILE, line => __LINE__});
	
	# Mark ourself as no longer using the DB
	#$anvil->Database->mark_active->({set => 0});
	
	# Close our own connection.
	#$anvil->Database->locking({debug => $debug, release => 1});
	
	# Disconnect from all databases and then stop the daemon, then reconnect.
	$anvil->Database->disconnect({debug => $debug});
	
	# Stop the daemon.
	my $return_code = $anvil->System->stop_daemon({daemon => $anvil->data->{sys}{daemon}{postgresql}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
	if ($return_code eq "0")
	{
		# Stopped the daemon.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0660"});
	}
	
	# Reconnect
	$anvil->refresh();
	$anvil->Database->connect({debug => $debug});
	
	return(0);
}


=head2 track_file

This looks at all files in the database, and then for all Anvil! systems and linked DR hosts, ensures that there's a corresponding C<< file_locations >> entry.

This method takes no parameters.

=cut
sub track_files
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->track_files()" }});
	
	my $anvils = keys %{$anvil->data->{anvils}{anvil_name}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvils => $anvils }});
	if (not $anvils)
	{
		$anvil->Database->get_anvils({debug => $debug});
	}
	
	my $files = keys %{$anvil->data->{files}{file_uuid}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { files => $files }});
	if (not $files)
	{
		$anvil->Database->get_files({debug => $debug});
	}
	
	my $file_locations = keys %{$anvil->data->{file_locations}{file_location_uuid}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_locations => $file_locations }});
	if (not $file_locations)
	{
		$anvil->Database->get_file_locations({debug => $debug});
	}
	
	my $dr_link_uuid = keys %{$anvil->data->{dr_links}{dr_link_uuid}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { dr_link_uuid => $dr_link_uuid }});
	if (not $dr_link_uuid)
	{
		$anvil->Database->get_dr_links({debug => $debug});
	}

	foreach my $anvil_name (sort {$a cmp $b} keys %{$anvil->data->{anvils}{anvil_name}})
	{
		my $anvil_uuid            = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_uuid};
		my $anvil_description     = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_description};
		my $anvil_node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		my $anvil_node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:anvil_name'            => $anvil_name,
			's2:anvil_uuid'            => $anvil_uuid,
			's3:anvil_description'     => $anvil_description, 
			's4:anvil_node1_host_uuid' => $anvil_node1_host_uuid, 
			's5:anvil_node2_host_uuid' => $anvil_node2_host_uuid, 
		}});
		
		# Loop through all files and see if there's a corresponding file_location for each sub-node.
		my $reload = 0;
		foreach my $file_name (sort {$a cmp $b} keys %{$anvil->data->{files}{file_name}})
		{
			my $file_uuid = $anvil->data->{files}{file_name}{$file_name}{file_uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:file_name' => $file_name,
				's2:file_uuid' => $file_uuid, 
			}});
			
			foreach my $host_uuid ($anvil_node1_host_uuid, $anvil_node2_host_uuid)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
				
				if ((not exists $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}) or 
				    ($anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}{file_location_uuid}))
				{
					# Add it
					    $reload              = 1;
					my ($file_location_uuid) = $anvil->Database->insert_or_update_file_locations({
						debug                   => $debug,
						file_location_file_uuid => $file_uuid,
						file_location_host_uuid => $host_uuid,
						file_location_active    => 1,
						file_location_ready     => "same",
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						reload             => $reload,
						file_location_uuid => $file_location_uuid,
					}});
				}
			}
		}
		if ($reload)
		{
			$anvil->Database->get_file_locations({debug => $debug});
		}
		
		# Track the files on this Anvil!
		foreach my $file_location_uuid (keys %{$anvil->data->{file_locations}{file_location_uuid}})
		{
			my $file_uuid = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_file_uuid};
			my $file_type = $anvil->data->{files}{file_uuid}{$file_uuid}{file_type};
			my $file_name = $anvil->data->{files}{file_uuid}{$file_uuid}{file_name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				file_location_uuid => $file_location_uuid,
				file_uuid          => $file_uuid, 
				file_type          => $file_type, 
				file_name          => $file_name, 
			}});
			next if $file_type eq "DELETED";
			
			my $anvil_needs_file = 0;
			foreach my $host_uuid ($anvil_node1_host_uuid, $anvil_node2_host_uuid)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
				
				if ((exists $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}) && 
				    ($anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}{file_location_uuid}))
				{
					my $file_location_uuid   = $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}{file_location_uuid};
					my $file_location_active = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_active};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						file_location_uuid   => $file_location_uuid,
						file_location_active => $file_location_active, 
					}});
					
					if ($file_location_active)
					{
						$anvil_needs_file = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_needs_file => $anvil_needs_file }});
					}
				}
			}
			
			# If either node wanted the file, both nodes and all linked DRs need it.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_needs_file => $anvil_needs_file }});
			if ($anvil_needs_file)
			{
				# Update the hosts
				foreach my $host_uuid ($anvil_node1_host_uuid, $anvil_node2_host_uuid)
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
					
					my ($file_location_uuid) = $anvil->Database->insert_or_update_file_locations({
						debug                   => $debug,
						file_location_file_uuid => $file_uuid,
						file_location_host_uuid => $host_uuid,
						file_location_active    => 1,
						file_location_ready     => "same",
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
				}
				
				# Make sure linked DR hosts have this file, also.
				foreach my $host_uuid (keys %{$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host}})
				{
					my $file_location_uuid   = $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}{file_location_uuid};
					my $file_location_active = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_active};
					
					if (not $file_location_active)
					{
						my ($file_location_uuid) = $anvil->Database->insert_or_update_file_locations({
							debug                   => $debug,
							file_location_file_uuid => $file_uuid,
							file_location_host_uuid => $host_uuid,
							file_location_active    => 1,
							file_location_ready     => "same",
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
					}
				}
				
				# If the file was deleted, this won't exist
				next if not exists $anvil->data->{files}{file_uuid}{$file_uuid};
				
				# Record that this Anvil! node has this file.
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_name}      = $file_name;
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_directory} = $anvil->data->{files}{file_uuid}{$file_uuid}{file_directory};
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_size}      = $anvil->data->{files}{file_uuid}{$file_uuid}{file_size};
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_md5sum}    = $anvil->data->{files}{file_uuid}{$file_uuid}{file_md5sum};
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_type}      = $anvil->data->{files}{file_uuid}{$file_uuid}{file_type};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_uuid}::file_name"      => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_name}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_uuid}::file_directory" => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_directory}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_uuid}::file_size"      => $anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_size}})." (".$anvil->Convert->add_commas({number => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_size}}).")", 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_uuid}::file_md5sum"    => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_md5sum}, 
					"anvils::anvil_uuid::${anvil_uuid}::file_uuid::${file_uuid}::file_type"      => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_uuid}{$file_uuid}{file_type}, 
				}});
				
				# Make it so that we can list the files by name.
				$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_name}{$file_name}{file_uuid} = $file_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"anvils::anvil_uuid::${anvil_uuid}::file_name::${file_name}::file_uuid" => $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{file_name}{$file_name}{file_uuid}, 
				}});
				
				# Make sure linked DR hosts have this file, also.
				foreach my $host_uuid (keys %{$anvil->data->{dr_links}{by_anvil_uuid}{$anvil_uuid}{dr_link_host_uuid}})
				{
					my $host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						host_name => $host_name, 
						host_uuid => $host_uuid, 
					}});
					
					my $file_location_uuid   = "";
					my $file_location_active = 0;
					if (exists $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid})
					{
						$file_location_uuid   = $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid}{file_location_uuid};
						$file_location_active = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_active};
					}
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						file_location_uuid   => $file_location_uuid, 
						file_location_active => $file_location_active, 
					}});
					
					if (not $file_location_active)
					{
						my ($file_location_uuid) = $anvil->Database->insert_or_update_file_locations({
							debug                   => $debug,
							file_location_file_uuid => $file_uuid,
							file_location_host_uuid => $host_uuid,
							file_location_active    => 1,
							file_location_ready     => "same",
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_location_uuid => $file_location_uuid }});
					}
				}
			}
		}
	}
	
	return(0);
}


=head2 update_host_status

This is a variant on C<< insert_or_update_hosts >> designed only to update the power status of a host. 

Parameters;

=head3 host_uuid (optional, default Get->host_uuid)

This is the host whose power state is being updated.

=head3 host_status (required)

This is the host status to set. See C<< insert_or_update_hosts -> host_status >> for valid values.

=cut
sub update_host_status
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->update_host_status()" }});
	
	my $host_uuid   = defined $parameter->{host_uuid}   ? $parameter->{host_uuid}   : $anvil->Get->host_uuid;
	my $host_status = defined $parameter->{host_status} ? $parameter->{host_status} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid   => $host_uuid, 
		host_status => $host_status, 
	}});
	
	if (not $host_status)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->update_host_status()", parameter => "host_status" }});
		return("");
	}
	
	# We're only updating the status, so we'll read in the current data to pass back in.
	$anvil->Database->get_hosts({debug => $debug});
	$anvil->Database->insert_or_update_hosts({
		debug       => $debug, 
		host_ipmi   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_ipmi}, 
		host_key    => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}, 
		host_name   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}, 
		host_type   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}, 
		host_uuid   => $host_uuid, 
		host_status => $host_status, 
	});
	
	return(0);
}


=head2 write

This records data to one or all of the databases. If a UUID is passed, the query is written to one database only. Otherwise, it will be written to all DBs.

Parameters;

=head3 initializing (optional, default 0)

When set to C<< 1 >>, this tells the method that the database is being initialized, so some checks and lookups are disabled.

=head3 line (optional)

If you want errors to be traced back to the query called, this can be set (usually to C<< __LINE__ >>) along with the C<< source >> parameter. In such a case, if there is an error in this method, the caller's file and line are displayed in the logs. 

=head3 transaction (optional, default 0)

Normally, if C<< query >> is an array reference, a C<< BEGIN TRANSACTION; >> is called before the queries are written, and closed off with a C<< COMMIT; >>. In this way, either all queries succeed or none do. In some cases, like loading a schema, multiple queries are passed as a single line. In these cases, you can set this to C<< 1 >> to wrap the query in a transaction block.

=head3 query (required)

This is the query or queries to be written. In string context, the query is directly passed to the database handle(s). In array reference context, the queries are wrapped in a transaction block (see tjhe 'transaction' parameter). 

B<< Note >>: If the number of queries are in the array reference is greater than C<< sys::database::maximum_batch_size >>, the queries are "chunked" into smaller transaction blocks. This is done so that very large arrays don't take so long that locks time out or memory becomes an issue.

=head3 reenter (optional)

This is used internally to indicate when a very large query array has been broken up and we've re-entered this method to process component chunks. The main effect is that some checks this method performs are skipped.

=head3 secure (optional, default 0)

If the query contains sensitive information, like passwords, setting this will ensure that log entries will be appropriately surpressed unless secure logging is enabled.

=head3 source (optional)

If you want errors to be traced back to the query called, this can be set (usually to C<< $THIS_FILE >>) along with the C<< line >> parameter. In such a case, if there is an error in this method, the caller's file and line are displayed in the logs. 

=head3 uuid (optional)

By default, queries go to all connected databases. If a given write should go to only one database, set this to the C<< host_uuid >> of the dataabase host. This is generally only used internally during resync operations.

=cut
sub write
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->write()" }});
	
	my $initializing = $parameter->{initializing} ? $parameter->{initializing} : 0;
	my $line         = $parameter->{line}         ? $parameter->{line}         : __LINE__;
	my $query        = $parameter->{query}        ? $parameter->{query}        : "";
	my $reenter      = $parameter->{reenter}      ? $parameter->{reenter}      : "";
	my $secure       = $parameter->{secure}       ? $parameter->{secure}       : 0;
	my $source       = $parameter->{source}       ? $parameter->{source}       : $THIS_FILE;
	my $transaction  = $parameter->{transaction}  ? $parameter->{transaction}  : 0;
	my $uuid         = $parameter->{uuid}         ? $parameter->{uuid}         : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		initializing => $initializing,
		line         => $line, 
		query        => (not $secure) ? $query : $anvil->Log->is_secure($query), 
		reenter      => $reenter,
		secure       => $secure, 
		source       => $source, 
		transaction  => $transaction, 
		uuid         => $uuid, 
	}});
	
	if ($uuid)
	{
		$anvil->data->{cache}{database_handle}{$uuid} = "" if not defined $anvil->data->{cache}{database_handle}{$uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
		}});
	}
	
	### NOTE: The careful checks below are to avoid autovivication biting our arses later.
	# Make logging code a little cleaner
	my $database_name = "anvil";
	my $say_server    = $anvil->Words->string({key => "log_0129"});
	if (($uuid) && (exists $anvil->data->{database}{$uuid}) && (defined $anvil->data->{database}{$uuid}{name}) && ($anvil->data->{database}{$uuid}{name}))
	{
		$database_name = $anvil->data->{database}{$uuid}{name};
		$say_server    = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		database_name => $database_name, 
		say_server    => $say_server,
	}});
	
	# We don't check if ID is set here because not being set simply means to write to all available DBs.
	if (not $query)
	{
		# No query
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0085", variables => { server => $say_server }});
		return("!!error!!");
	}
	
	# If I am still alive check if any locks need to be renewed.
	$anvil->Database->check_lock_age({debug => $debug}) if not $initializing;
	
	# This array will hold either just the passed DB ID or all of them, if no ID was specified.
	my @db_uuids;
	if ($uuid)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		push @db_uuids, $uuid;
	}
	else
	{
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
			push @db_uuids, $uuid;
		}
	}
	
	# Sort out if I have one or many queries.
	my $limit     = 25000;
	my $count     = 0;
	my $query_set = [];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::maximum_batch_size" => $anvil->data->{sys}{database}{maximum_batch_size} }});
	if ($anvil->data->{sys}{database}{maximum_batch_size})
	{
		if ($anvil->data->{sys}{database}{maximum_batch_size} =~ /\D/)
		{
			# Bad value.
			$anvil->data->{sys}{database}{maximum_batch_size} = 25000;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::maximum_batch_size" => $anvil->data->{sys}{database}{maximum_batch_size} }});
		}
		
		# Use the set value now.
		$limit = $anvil->data->{sys}{database}{maximum_batch_size};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { limit => $limit }});
	}
	if (ref($query) eq "ARRAY")
	{
		# Multiple things to enter.
		$count = @{$query};
		
		# If I am re-entering, then we'll proceed normally. If not, and if we have more than 10k 
		# queries, we'll split up the queries into 10k chunks and re-enter.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			count   => $count, 
			limit   => $limit, 
			reenter => $reenter, 
		}});
		if (($count > $limit) && (not $reenter))
		{
			my $i    = 0;
			my $next = $limit;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { i => $i, 'next' => $next }});
			foreach my $this_query (@{$query})
			{
				push @{$query_set}, $this_query;
				$i++;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					this_query => $this_query,
					i          => $i,
				}});
				
				if ($i > $next)
				{
					# Commit this batch.
					foreach my $uuid (@db_uuids)
					{
						# Commit this chunk to this DB.
						$anvil->Database->write({uuid => $uuid, query => $query_set, source => $THIS_FILE, line => $line, reenter => 1});
						
						### TODO: Rework this so that we exit here (so that we can 
						###       send an alert) if the RAM use is too high.
						# This can get memory intensive, so check our RAM usage and 
						# bail if we're eating too much.
						my $ram_use = $anvil->System->check_memory({program_name => $THIS_FILE});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ram_use => $ram_use }});
						
						# Wipe out the old set array, create it as a new anonymous array and reset 'i'.
						undef $query_set;
						$query_set =  [];
						$i         =  0;
					}
				}
			}
		}
		else
		{
			# Not enough to worry about or we're dealing with a chunk, proceed as normal.
			foreach my $this_query (@{$query})
			{
				push @{$query_set}, $this_query;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_query => $this_query }});
			}
		}
	}
	else
	{
		push @{$query_set}, $query;
		my $query_set_count = @{$query_set};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query_set_count => $query_set_count }});
	}
	
	my $db_uuids_count = @db_uuids;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { db_uuids_count => $db_uuids_count }});
	foreach my $uuid (@db_uuids)
	{
		# Test access to the DB before we do the actual query
		if (not $initializing)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
			
			my $problem = $anvil->Database->_test_access({debug => $debug, uuid => $uuid});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			
			if ($problem)
			{
				# We can't use this DB. 
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0182", variables => { 
					uuid  => $uuid,
					query => (not $secure) ? $query : $anvil->Log->is_secure($query),
				}});
				next;
			}
		}
		
		# Do the actual query(ies)
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			uuid  => $uuid, 
			count => $count, 
		}});
		if (($count) or ($transaction))
		{
			# More than one query, so start a transaction block.
			$anvil->data->{cache}{database_handle}{$uuid}->begin_work;
		}
		
		foreach my $query (@{$query_set})
		{
			if (($anvil->data->{sys}{database}{log_transactions}) or ($debug <= $anvil->Log->level))
			{
				$anvil->Log->entry({source => $source, line => $line, secure => $secure, level => 0, key => "log_0083", variables => { 
					uuid  => $initializing ? $uuid : $anvil->Database->get_host_from_uuid({debug => 1, short => 1, host_uuid => $uuid}), 
					query => $query, 
				}});
			}
			
			if (not $anvil->data->{cache}{database_handle}{$uuid})
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0089", variables => { uuid => $uuid }});
				next;
			}

			# Do the do. Do it in an eval block though so that if it fails, we can do something 
			# useful.
			my $test = eval { $anvil->data->{cache}{database_handle}{$uuid}->do($query); };
			   $test = "" if not defined $test;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:test'  => $test,
				's2:$@'    => $@,
				's3:query' => $query, 
			}});
			
			if (not $test)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0090", variables => { 
					query    => (not $secure) ? $query : $anvil->Log->is_secure($query), 
					server   => $say_server." (".$uuid.")",
					db_error => $DBI::errstr, 
				}});
				if (($count) or ($transaction))
				{
					# Commit the changes.
					$anvil->data->{cache}{database_handle}{$uuid}->rollback();
				}
				return(1);
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
		if (($count) or ($transaction))
		{
			# Commit the changes.
			$anvil->data->{cache}{database_handle}{$uuid}->commit();
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
	if ($count)
	{
		# Free up some memory.
		undef $query_set;
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

=head2 _add_to_local_config

This adds this machine to the local C<< /etc/anvil/anvil.conf >> file.

If successful, the host's UUID will be returned. If there's a problem, C<< !!error!! >> will be returned.

=cut
sub _add_to_local_config
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_add_to_local_config()" }});
	
	my $host_uuid = $anvil->Get->host_uuid();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	if ((not exists $anvil->data->{database}{$host_uuid}{password}) or (not $anvil->data->{database}{$host_uuid}{password}))
	{
		# Use the default password used in kickstart scripts.
		$anvil->data->{database}{$host_uuid}{password} = $anvil->data->{defaults}{kickstart}{password};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, secure => 1, level => $debug, list => { 
			"database::${host_uuid}::password" => $anvil->data->{database}{$host_uuid}{password},
		}});
	}
	
	# Write the password to a file.
	my $password_file = "/tmp/striker-manage-peers.".$anvil->Get->uuid;
	$anvil->Storage->write_file({
		debug     => $debug,
		secure    => 1, 
		file      => $password_file, 
		body      => $anvil->data->{database}{$host_uuid}{password}, 
		mode      => "0600",
		overwrite => 1,
	});
	
	# Make the shell call, and parse the output looking for our own entry
	my $shell_call = $anvil->data->{path}{exe}{'striker-manage-peers'}." --add --host-uuid ".$anvil->Get->host_uuid." --host localhost --port 5432 --password-file ".$password_file." --ping 0".$anvil->Log->switches;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid  => $host_uuid, 
		shell_call => $shell_call,
	}});
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call, source => $THIS_FILE, line => __LINE__});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	# Remove the password.
	unlink $password_file;
	
	# Re-read the config and make sure we have our own entry.
	$anvil->refresh();
	
	# If we still don't have a local_uuid, something went wrong.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"database::${host_uuid}::host"     => $anvil->data->{database}{$host_uuid}{host}, 
		"database::${host_uuid}::port"     => $anvil->data->{database}{$host_uuid}{port}, 
		"database::${host_uuid}::password" => $anvil->Log->is_secure($anvil->data->{database}{$host_uuid}{password}), 
		"database::${host_uuid}::ping"     => $anvil->data->{database}{$host_uuid}{ping}, 
	}});
	if (not $anvil->data->{database}{$host_uuid}{host})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, 'print' => 1, key => "error_0010"});
		return('!!error!!');
	}
	
	return($host_uuid);
}


=head2 _age_out_data

This deletes any data considered transient (power, thermal, etc) after C<< scancore::database::age_out >> hours old. The exception are completed jobs that are more than 2 hours old, which are purged.

B<< Note >>:  Scan agents can have fast-growing tabled purged as well. This is done by setting the appropriate values in the C<< $to_clean >> hash contained within. This is hard coded so the source needs to be updated as the number of agents grow. 

=cut
sub _age_out_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_age_out_data()" }});

	# Get a lock.
	#$anvil->Database->locking({debug => $debug, request => 1});
	
	# Log our start, as this takes some time to run.
	my $start_time = time;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0623"});
	
	# Get the timestamp to delete jobs and processed alert records older than 2h
	my $query         = "SELECT now() - '24h'::interval";
	my $old_timestamp = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		query         => $query, 
		old_timestamp => $old_timestamp, 
	}});
	
	foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});

		# Before I proceed, see when the last age-out happened. If it's less than 24 hours ago, don't
		# bother. Of course, if we've been specfiically asked to age out data, proceed.
		if (not $anvil->data->{switches}{"age-out-database"})
		{
			my ($last_age_out, undef, undef) = $anvil->Database->read_variable({
				debug         => $debug,
				variable_name => "database::".$uuid."::aged-out",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_age_out => $last_age_out }});

			if (($last_age_out) && ($last_age_out =~ /^\d+$/))
			{
				my $age = time - $last_age_out;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});

				next if $age < 86400;
			}
		}

		my $queries = [];
		my $query   = "SELECT job_uuid FROM jobs WHERE modified_date <= '".$old_timestamp."' AND job_progress = 100;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			my $job_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});

			# Delete
			my $query = "DELETE FROM history.jobs WHERE job_uuid = ".$anvil->Database->quote($job_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			push @{$queries}, $query;
			
			$query = "DELETE FROM jobs WHERE job_uuid = ".$anvil->Database->quote($job_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			push @{$queries}, $query;
		}
		
		my $commits = @{$queries};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { commits => $commits }});
		if ($commits)
		{
			# Commit the DELETEs.
			$anvil->Database->write({debug => $debug, uuid => $uuid, query => $queries, source => $THIS_FILE, line => __LINE__});
		}

		my $variable_uuid = $anvil->Database->insert_or_update_variables({
			variable_name         => "database::".$uuid."::aged-out",
			variable_value        => time,
			variable_default      => "0",
			variable_description  => "striker_0199",
			variable_section      => "database",
			variable_source_uuid  => "NULL",
			variable_source_table => "",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});

		#$anvil->Database->locking({debug => $debug, renew => 1});
	}
	
	# Remove old processed alerts.
	foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
		my $queries = [];
		my $query   = "SELECT alert_uuid FROM alerts WHERE alert_processed = 1 AND modified_date <= '".$old_timestamp."';";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			my $alert_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_uuid => $alert_uuid }});

			# Delete
			my $query = "DELETE FROM history.alerts WHERE alert_uuid = ".$anvil->Database->quote($alert_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			push @{$queries}, $query;
			
			$query = "DELETE FROM alerts WHERE alert_uuid = ".$anvil->Database->quote($alert_uuid).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			push @{$queries}, $query;
		}
		
		my $commits = @{$queries};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { commits => $commits }});
		if ($commits)
		{
			# Commit the DELETEs.
			$anvil->Database->write({debug => $debug, uuid => $uuid, query => $queries, source => $THIS_FILE, line => __LINE__});
		}
		#$anvil->Database->locking({debug => $debug, renew => 1});
	}
	
	# Now process power and tempoerature, if not disabled.
	my $age = $anvil->data->{scancore}{database}{age_out} ? $anvil->data->{scancore}{database}{age_out} : 24; 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { age => $age }});
	
	if ($age =~ /\D/)
	{
		# Age is not valid, set it to defaults.
		$age = 24;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
	}
	
	if ($age == 0)
	{
		# Disabled, return.
		#$anvil->Database->locking({debug => $debug, release => 1});
		return(0);
	}
	
	# Get the timestamp to delete thermal and power records older than $age hours.
	$query         = "SELECT now() - '".$age."h'::interval;";
	$old_timestamp = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		query         => $query, 
		old_timestamp => $old_timestamp, 
	}});
	
	### Looks for scan agent data that grows quickly.
	# We don't use 'anvil->data' to prevent injecting SQL queries in anvil.conf
	my $to_clean = {};
	
	# Power, temperatures, ip addresses and variables
	$to_clean->{table}{temperature}{child_table}{temperature}{uuid_column}               = "temperature_uuid";
	$to_clean->{table}{power}{child_table}{power}{uuid_column}                           = "power_uuid";
	$to_clean->{table}{ip_addresses}{child_table}{ip_addresses}{uuid_column}             = "ip_address_uuid";
	$to_clean->{table}{variables}{child_table}{variables}{uuid_column}                   = "variable_uuid";
	$to_clean->{table}{network_interfaces}{child_table}{network_interfaces}{uuid_column} = "network_interface_uuid";
	
	# scan_apc_pdu
	$to_clean->{table}{scan_apc_pdus}{child_table}{scan_apc_pdu_phases}{uuid_column}    = "scan_apc_pdu_phase_uuid";
	$to_clean->{table}{scan_apc_pdus}{child_table}{scan_apc_pdu_variables}{uuid_column} = "scan_apc_pdu_variable_uuid";
	
	# scan_apc_ups
	$to_clean->{table}{scan_apc_upses}{child_table}{scan_apc_ups_batteries}{uuid_column} = "scan_apc_ups_battery_uuid";
	$to_clean->{table}{scan_apc_upses}{child_table}{scan_apc_ups_input}{uuid_column}     = "scan_apc_ups_input_uuid";
	$to_clean->{table}{scan_apc_upses}{child_table}{scan_apc_ups_output}{uuid_column}    = "scan_apc_ups_output_uuid";
	
	# scan_filesystems
	$to_clean->{table}{scan_filesystems}{child_table}{scan_filesystems}{uuid_column} = "scan_filesystem_uuid";
	
	# scan_hardware
	$to_clean->{table}{scan_hardware}{child_table}{scan_hardware}{uuid_column} = "scan_hardware_uuid";
	$to_clean->{table}{scan_hardware}{child_table}{scan_hardware}{uuid_column} = "scan_hardware_uuid";
	
	# scan_hpacucli
	$to_clean->{table}{scan_hpacucli_variables}{child_table}{scan_hpacucli_variables}{uuid_column} = "scan_hpacucli_variable_uuid";
	
	# scan_ipmitool
	$to_clean->{table}{scan_ipmitool}{child_table}{scan_ipmitool_values}{uuid_column} = "scan_ipmitool_value_uuid";
	
	# scan_storcli
	$to_clean->{table}{scan_storcli_variables}{child_table}{scan_storcli_variables}{uuid_column} = "scan_storcli_variable_uuid";
	
	# Network stuff
	$to_clean->{table}{network_interfaces}{child_table}{network_interfaces}{uuid_column} = "network_interface_uuid";
	$to_clean->{table}{bridges}{child_table}{bridges}{uuid_column}                       = "bridge_uuid";
	$to_clean->{table}{bonds}{child_table}{bonds}{uuid_column}                           = "bond_uuid";
	$to_clean->{table}{ip_addresses}{child_table}{ip_addresses}{uuid_column}             = "ip_address_uuid";
	
	# Misc stuff
	$to_clean->{table}{sessions}{child_table}{sessions}{uuid_column} = "session_uuid";
	
	my $vacuum = 0;
	foreach my $table (sort {$a cmp $b} keys %{$to_clean->{table}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
		
		# Does the table exist?
		$query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->Database->quote($table)." AND schemaname='public';";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
		if ($count)
		{
			# The table exists, clean up child tables.
			foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
				
				foreach my $child_table (sort {$a cmp $b} keys %{$to_clean->{table}{$table}{child_table}})
				{
					my $uuid_column = $to_clean->{table}{$table}{child_table}{$child_table}{uuid_column};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						child_table => $child_table,
						uuid_column => $uuid_column, 
					}});
					
					# Make sure the table exists, skip it if not.
					my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->Database->quote($child_table)." AND schemaname='public';";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					my $count     = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
					
					if (not $count)
					{
						# Table doesn't exist yet, skip it.
						next;
					}
					
					# Get a list of all records.
					my $queries = [];
					   $query   = "SELECT ".$uuid_column." FROM ".$child_table.";";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					
					my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
					   $count   = @{$results};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						results => $results, 
						count   => $count, 
					}});
					foreach my $row (@{$results})
					{
						my $column_uuid = $row->[0];
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { column_uuid => $column_uuid }});
						
						# Find out of there are any records to remove at all.
						my $query = "SELECT history_id FROM history.".$child_table." WHERE ".$uuid_column." = ".$anvil->Database->quote($column_uuid)." AND modified_date <= '".$old_timestamp."';";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
						
						my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
						my $count   = @{$results};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							results => $results, 
							count   => $count, 
						}});
						
						if ($count > 1)
						{
							# Find how many records will be left. If it's 0, we'll use an OFFSET 1.
							my $query = "SELECT history_id FROM history.".$child_table." WHERE ".$uuid_column." = ".$anvil->Database->quote($column_uuid)." AND modified_date > '".$old_timestamp."';";
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
							
							my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
							my $count   = @{$results};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								results => $results, 
								count   => $count, 
							}});
							if ($count)
							{
								# At least one record will be left, we can do a simple delete.
								my $query = "DELETE FROM history.".$child_table." WHERE ".$uuid_column." = ".$anvil->Database->quote($column_uuid)." AND modified_date <= '".$old_timestamp."';";
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
								push @{$queries}, $query;
							}
							else
							{
								# This would delete everything, reserve at 
								# least one record.
								my $query = "SELECT history_id FROM history.".$child_table." WHERE ".$uuid_column." = ".$anvil->Database->quote($column_uuid)." ORDER BY modified_date DESC LIMIT 1;";
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
								
								my $history_id = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
								
								$query = "DELETE FROM history.".$child_table." WHERE ".$uuid_column." = ".$anvil->Database->quote($column_uuid)." AND modified_date <= '".$old_timestamp."' AND history_id != '".$history_id."';";
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
								push @{$queries}, $query;
							}
						}
					}
					
					my $commits = @{$queries};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { commits => $commits }});
					if ($commits)
					{
						# Commit the DELETEs.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0622", variables => { 
							age      => $age,
							table    => $child_table,
							database => $anvil->Get->host_name_from_uuid({host_uuid => $uuid, debug => $debug}),
						}});
						$anvil->Database->write({debug => $debug, uuid => $uuid, query => $queries, source => $THIS_FILE, line => __LINE__});
						
						$vacuum += $commits;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { vacuum => $vacuum }});
						undef $queries;
					}
					#$anvil->Database->locking({debug => $debug, renew => 1});
				}
			}
		}
	}
	
	# VACCUM
	foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		
		my $query = "VACUUM FULL;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		
		#$anvil->Database->locking({debug => $debug, renew => 1});
	}
	
	my $runtime = time - $start_time;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0624", variables => { runtime => $runtime }});
	
	#$anvil->Database->locking({debug => $debug, release => 1});
	
	return(0);
}


=head2 _archive_table

NOTE: Not implemented yet (will do so once enough records are in the DB.)

This takes a table name 

This takes a table to check to see if old records need to be archived the data from the history schema to a plain-text dump. 

B<NOTE>: If we're asked to use an offset that is too high, we'll go into a loop and may end up doing some empty loops. We don't check to see if the offset is sensible, though setting it too high won't cause the archive operation to fail, but it won't chunk as expected.

B<NOTE>: The archive process works on all records, B<NOT> restricted to records referencing this host via a C<< *_host_uuid >> column.  

Parameters;

=head3 table <required>

This is the table that will be archived, if needed. 

An archive will be deemed required if there are more than C<< sys::database::archive::trigger >> records (default is C<< 100000 >>) in the table's C<< history >> schema. If this is set to C<< 0 >>, archiving will be disabled.

Individual tables can have custom triggers by setting C<< sys::database::archive::tables::<table>::trigger >>.

=cut
sub _archive_table
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_archive_table()" }});
	
	my $table = $parameter->{table} ? $parameter->{table} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		table => $table, 
	}});
	
	if (not $table)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->_archive_table()", parameter => "table" }});
		return("!!error!!");
	}
	
	# We don't archive the OUI table, it generally has more entries than needed to trigger the archive, but it's needed.
	if (($table eq "oui") or ($table eq "states"))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "err", key => "log_0459", variables => { table => $table }});
		return(0);
	}
	
	# These values are sanity checked before this method is called.
	my $compress   = $anvil->data->{sys}{database}{archive}{compress};
	my $directory  = $anvil->data->{sys}{database}{archive}{directory};
	my $drop_to    = $anvil->data->{sys}{database}{archive}{count};
	my $division   = $anvil->data->{sys}{database}{archive}{division};
	my $trigger    = $anvil->data->{sys}{database}{archive}{trigger};
	my $time_stamp = $anvil->Get->date_and_time({file_name => 1});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		compress   => $compress, 
		directory  => $directory, 
		drop_to    => $drop_to, 
		division   => $division, 
		trigger    => $trigger, 
		time_stamp => $time_stamp, 
	}});
	
	# Loop through each database so that we archive from everywhere before resync'ing.
	foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
	{
		# First, if this table doesn't have a history schema, exit.
		my $vacuum = 0;
		my $query  = "SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = 'history' AND table_name = ".$anvil->Database->quote($table).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $count = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
		if (not $count)
		{
			# History table doesn't exist, we're done.
			next;
		}
		
		# Before we do any real analysis, do we have enough entries in the history schema to trigger an archive?
		$query = "SELECT COUNT(*) FROM history.".$table.";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$count = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:uuid"  => $uuid,
			"s2:count" => $count,
		}});
		if ($count <= $trigger)
		{
			# Not enough records to bother archiving.
			next;
		}
		
		# Do some math...
		my $to_remove        = $count - $drop_to;
		my $loops            = (int($to_remove / $division) + 1);
		my $records_per_loop = $anvil->Convert->round({number => ($to_remove / $loops)});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:to_remove"        => $to_remove,
			"s2:loops"            => $loops,
			"s3:records_per_loop" => $records_per_loop,
		}});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0453", variables => { 
			records => $anvil->Convert->add_commas({number => $to_remove }),
			loops   => $anvil->Convert->add_commas({number => $loops }),
			table   => $table,
			host    => $anvil->Database->get_host_from_uuid({short => 1, host_uuid => $uuid}),
		}});
		
		# There is enough data to trigger an archive, so lets get started with a list of columns in 
		# this table.
		$query = "SELECT column_name FROM information_schema.columns WHERE table_schema = 'history' AND table_name = ".$anvil->Database->quote($table)." AND column_name != 'history_id' AND column_name != 'modified_date';";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
		
		my $columns      = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		my $column_count = @{$columns};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			columns      => $columns, 
			column_count => $column_count 
		}});
		
		my $offset    = $count - $records_per_loop;
		my $loop      = 0;
		my $do_delete = 1;
		for (1..$loops)
		{
			# We need to date stamp from the closest record to the offset.
			$loop++;
			
			# Are we archiving to disk?
			my $modified_date =  "";
			   $do_delete     =  1;
			my $archive_file  =  $directory."/".$anvil->Database->get_host_from_uuid({short => 1, host_uuid => $uuid}).".".$table.".".$time_stamp.".".$loop.".out";
			   $archive_file  =~ s/\/\//\//g;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { archive_file => $archive_file }});
			if ($anvil->data->{sys}{database}{archive}{save_to_disk})
			{
				if (not -d $anvil->data->{sys}{database}{archive}{directory})
				{
					my $failed = $anvil->Storage->make_directory({
						debug     => $debug,
						directory => $anvil->data->{sys}{database}{archive}{directory},
						mode      => "0700",
						user      => "root",
						group     => "root",
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
					if ($failed)
					{
						# No directory to archive into...
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "err", key => "error_0098", variables => { 
							directory => $anvil->data->{sys}{database}{archive}{directory},
						}});
						return("!!error!!");
					}
				}
				
				my $sql_file = "
-- Dump created at: [".$anvil->Get->date_and_time()."]
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

COPY history.".$table." (";
				my $query = "SELECT modified_date FROM history.".$table." ORDER BY modified_date ASC OFFSET ".$offset." LIMIT 1;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:loop"     => $loop,
					"s2:query"    => $query,
					"s3:sql_file" => $sql_file,
				}});
				
				$modified_date = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { modified_date => $modified_date }});
				
				# Build the query.
				$query = "SELECT ";
				foreach my $column (sort {$a cmp $b} @{$columns})
				{
					$sql_file .= $column->[0].", ";
					$query    .= $column->[0].", ";
				}
				$sql_file .= "modified_date) FROM stdin;\n";
				$query    .= "modified_date FROM history.".$table." WHERE modified_date >= '".$modified_date."' ORDER BY modified_date ASC;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					sql_file => $sql_file,
					query    => $query,
				}});
				my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
				my $count   = @{$results};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					results => $results, 
					count   => $count, 
				}});
				
				foreach my $row (@{$results})
				{
					# Build the string.
					my $line = "";
					my $i    = 0;
					foreach my $column (@{$columns})
					{
						my $value = defined $row->[$i] ? $row->[$i] : '\N';
						$i++;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:i"      => $i, 
							"s2:column" => $column, 
							"s3:value"  => $value, 
						}});
						
						# We need to convert tabs and newlines into \t and \n
						$value =~ s/\t/\\t/g;
						$value =~ s/\n/\\n/g;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
						
						$line .= $value."\t";
					}
					# Add the modified_date column.
					$line .= $row->[$i]."\n";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
					
					$sql_file .= $line;
				}
				$sql_file .= "\\.\n\n";;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sql_file => $sql_file }});
				
				# It may not be secure, but we play it safe.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0454", variables => { 
					records => $anvil->Convert->add_commas({number => $count}),
					file    => $archive_file,
				}});
				my ($failed) = $anvil->Storage->write_file({
					debug  => $debug, 
					body   => $sql_file,
					file   => $archive_file, 
					user   => "root", 
					group  => "root", 
					mode   => "0600",
					secure => 1.
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
				
				if ($failed)
				{
					$do_delete = 0;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0099", variables => { 
						file  => $archive_file,
						table => $table, 
					}});
					last;
				}
			}
			
			# Do Delete.
			if (($do_delete) && ($modified_date))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0283"});
				$vacuum = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				if ($compress)
				{
					# Whether the compression works or not doesn't break archiving, so we
					# don't care if this fails.
					my ($failed) = $anvil->Storage->compress({
						debug => $debug,
						file  => $archive_file,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
				}
				
				# Now actually remove the data.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0457"});
				my $query = "DELETE FROM history.".$table." WHERE modified_date >= '".$modified_date."';";
				$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			}
			
			$offset -= $records_per_loop;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { offset => $offset }});
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { vacuum => $vacuum }});
		if ($vacuum)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0458"});
			my $query = "VACUUM FULL;";
			$anvil->Database->write({debug => $debug, uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
		}
	}
	
	return(0);
}


=head2 _check_for_duplicates

This method looks for duplicate entries in the database and clears them, if found.

This method takes no parameters

=cut
sub _check_for_duplicates
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_check_for_duplicates()" }});
	
	my $query = "
SELECT 
    variable_uuid, 
    variable_section, 
    variable_name, 
    variable_source_table, 
    variable_source_uuid, 
    variable_value, 
    modified_date 
FROM 
    variables 
ORDER BY 
    modified_date DESC;
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
		my $variable_uuid         = $row->[0]; 
		my $variable_section      = $row->[1]; 
		my $variable_name         = $row->[2]; 
		my $variable_source_table = $row->[3] ? $row->[3] : "none"; 
		my $variable_source_uuid  = $row->[4] ? $row->[4] : "none"; 
		my $variable_value        = $row->[5]; 
		my $modified_date         = $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			variable_uuid         => $variable_uuid, 
			variable_section      => $variable_section, 
			variable_name         => $variable_name, 
			variable_source_table => $variable_source_table, 
			variable_source_uuid  => $variable_source_uuid, 
			variable_value        => $variable_value, 
			modified_date         => $modified_date,
		}});
		
		if (not $variable_source_table)
		{
			$variable_source_table = "none";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_source_table => $variable_source_table }});
		}
		if (not $variable_source_uuid)
		{
			$variable_source_uuid = "none";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_source_uuid => $variable_source_uuid }});
		}
		
		if ((not exists $anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}) && 
		    (not $anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_uuid}))
		{
			# Save it.
			$anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_value} = $variable_value; 
			$anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_uuid}  = $variable_uuid; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"duplicate_variables::${variable_section}::${variable_name}::${variable_source_table}::${variable_source_uuid}::variable_value" => $anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_value},
				"duplicate_variables::${variable_section}::${variable_name}::${variable_source_table}::${variable_source_uuid}::variable_uuid" => $anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_uuid},
			}});
		}
		else
		{
			# Duplicate! This is older, so delete it.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"duplicate_variables::${variable_section}::${variable_name}::${variable_source_table}::${variable_source_uuid}::variable_value" => $anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_value},
				"duplicate_variables::${variable_section}::${variable_name}::${variable_source_table}::${variable_source_uuid}::variable_uuid" => $anvil->data->{duplicate_variables}{$variable_section}{$variable_name}{$variable_source_table}{$variable_source_uuid}{variable_uuid},
			}});
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0165", variables => {
				section      => $variable_section,
				name         => $variable_name,
				source_table => $variable_source_table,
				source_uuid  => $variable_source_uuid, 
				value        => $variable_value,
			}});
			
			my $queries = [];
			push @{$queries}, "DELETE FROM history.variables WHERE variable_uuid = ".$anvil->Database->quote($variable_uuid).";";
			push @{$queries}, "DELETE FROM variables WHERE variable_uuid = ".$anvil->Database->quote($variable_uuid).";";
			foreach my $query (@{$queries})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
			}
			$anvil->Database->write({query => $queries, source => $THIS_FILE, line => __LINE__});
		}
	}
	
	# Delete to hash.
	delete $anvil->data->{duplicate_variables};
	
	return(0);
}

=head2 _find_column

This takes a table name and looks for a column that ends in C<< _host_uuid >> and, if found, stores it in the C<< sys::database::uuid_tables >> array.

Parameters;

=head3 table (required)

This is the table being queried.

=cut
sub _find_column
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_find_column()" }});
	
	my $table         = defined $parameter->{table}         ? $parameter->{table}         : "";
	my $search_column = defined $parameter->{search_column} ? $parameter->{search_column} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		table         => $table, 
		search_column => $search_column, 
	}});
	
	return('!!error!!') if not $table;
	
	my $query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = 'anvil' AND table_schema = 'public' AND table_name = ".$anvil->Database->quote($table)." AND data_type = 'uuid' AND column_name LIKE '\%_".$search_column."';";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		table => $table, 
		count => $count,
	}});
	if ($count)
	{
		my $host_uuid_column = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid_column => $host_uuid_column }});
		
		push @{$anvil->data->{sys}{database}{uuid_tables}}, {
			table            => $table, 
			host_uuid_column => $host_uuid_column,
		};
	}
	
	return(0);
}


=head2 _find_behind_databases

This returns the most up to date database ID, the time it was last updated and an array or DB IDs that are behind.

If there is a problem, C<< !!error!! >> is returned. If this is called by a host that isn't a Striker, C<< 0 >> is returned and no actions are take.

Parameters;

=head3 source (required)

This is used the same as in C<< Database->connect >>'s C<< source >> parameter. Please read that for usage information.

=head3 tables (optional)

This is used the same as in C<< Database->connect >>'s C<< tables >> parameter. Please read that for usage information.

=cut
sub _find_behind_databases
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_find_behind_databases()" }});
	
	my $source = defined $parameter->{source} ? $parameter->{source} : "";
	my $tables = defined $parameter->{tables} ? $parameter->{tables} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		source => $source, 
		tables => $tables, 
	}});
	
	# If we're not a striker, return.
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "striker")
	{
		return(0);
	}
	
	# This should always be set, but just in case...
	if (not $source)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->_find_behind_databases()", parameter => "source" }});
		return("!!error!!");
	}
	
	# Make sure I've got an array of tables.
	if (ref($tables) ne "ARRAY")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0218", variables => { name => "tables", value => $tables }});
		return("!!error!!");
	}
	
	# Now, look through the core tables, plus any tables the user might have passed, for differing 
	# 'modified_date' entries, or no entries in one DB with entries in the other (as can happen with a 
	# newly setup db).
	$anvil->data->{sys}{database}{check_tables} = [];
	
	### NOTE: Don't sort this! Tables need to be resynced in a specific order!
	# Loop through and resync the tables.
	foreach my $table (@{$tables}) 
	{
		# Record the table in 'sys::database::check_tables' array for later use in archive and 
		# resync methods.
		push @{$anvil->data->{sys}{database}{check_tables}}, $table;
		
		# Preset all tables to have an initial 'modified_date' and 'row_count' of 0.
		$anvil->data->{sys}{database}{table}{$table}{last_updated} = 0;
		$anvil->data->{sys}{database}{table}{$table}{row_count}    = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::table::${table}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{last_updated},
			"sys::database::table::${table}::row_count"    => $anvil->data->{sys}{database}{table}{$table}{row_count},
		}});
	}
	
	# Look at all the databases and find the most recent time stamp (and the UUID of the DB). Do this by
	# table then by database to keep the counts close together and reduce the chance of tables changing 
	# between counts.
	my $source_updated_time = 0;
	foreach my $table (@{$anvil->data->{sys}{database}{check_tables}})
	{
		# We don't sync 'states' or 'oui' as it's transient and sometimes per-DB.
		next if $table eq "states";
		
		# Does this table exist yet?
		my $query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = 'public' AND table_name = ".$anvil->Database->quote($table).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		# If not, skip. It'll get sync'ed later when the table is added.
		my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
		next if not $count;
		
		# Does this table have a history schema version?
		$query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = 'history' AND table_name = ".$anvil->Database->quote($table).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $has_history = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { has_history => $has_history }});
		
		foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
		{
			my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "#!string!log_0185!#";
			my $database_user = defined $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : "#!string!log_0185!#";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"database::${uuid}::host"     => $anvil->data->{database}{$uuid}{host},
				"database::${uuid}::port"     => $anvil->data->{database}{$uuid}{port},
				"database::${uuid}::name"     => $database_name,
				"database::${uuid}::user"     => $database_user, 
				"database::${uuid}::password" => $anvil->Log->is_secure($anvil->data->{database}{$uuid}{password}), 
			}});
			
			### Only Strikers resync, so limiting to the host_uuid doesn't make sense anymore.
			my $schema = $has_history ? "history" : "public";
			   $query  =  "
SELECT DISTINCT 
    round(extract(epoch from modified_date)) AS unix_modified_date 
FROM 
    ".$schema.".".$table." 
ORDER BY 
    unix_modified_date DESC
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				uuid  => $uuid, 
				query => $query, 
			}});
			
			# Get the count of columns as well as the most recent one.
			my $results   = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			my $row_count = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results   => $results, 
				row_count => $row_count, 
			}});
			
			my $last_updated = $results->[0]->[0];
			   $last_updated = 0 if not defined $last_updated;
			
			# Record this table's last modified_date for later comparison. We'll also 
			# record the schema and host column, if found, to save looking the same thing
			# up later if we do need a resync.
			$anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated} = $last_updated;
			$anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count}    = $row_count;
			$anvil->data->{sys}{database}{table}{$table}{schema}                    = $schema;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::table::${table}::uuid::${uuid}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated}, 
				"sys::database::table::${table}::uuid::${uuid}::row_count"    => $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count}, 
				"sys::database::table::${table}::last_updated"                => $anvil->data->{sys}{database}{table}{$table}{last_updated},
				"sys::database::table::${table}::schema"                      => $anvil->data->{sys}{database}{table}{$table}{schema},
			}});
			
			if ($anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count} > $anvil->data->{sys}{database}{table}{$table}{row_count})
			{
				$anvil->data->{sys}{database}{table}{$table}{row_count} = $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::table::${table}::row_count" => $anvil->data->{sys}{database}{table}{$table}{row_count}, 
				}});
			}
			
			if ($anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated} > $anvil->data->{sys}{database}{table}{$table}{last_updated})
			{
				$anvil->data->{sys}{database}{table}{$table}{last_updated} = $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::table::${table}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{last_updated}, 
				}});
			}
		}
	}
	
	# Are being asked to trigger a resync?
	foreach my $uuid (keys %{$anvil->data->{cache}{database_handle}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			"switches::resync-db" => $anvil->data->{switches}{'resync-db'},
			uuid                  => $uuid, 
		}});
		if ($anvil->data->{switches}{'resync-db'} eq $uuid)
		{
			# We've been asked to resync this DB.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0476", variables => { 
				uuid => $uuid,
				host => $anvil->Get->host_name_from_uuid({host_uuid => $uuid}),
			}});
			
			# Mark it as behind.
			$anvil->Database->_mark_database_as_behind({debug => $debug, uuid => $uuid});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::resync_needed" => $anvil->data->{sys}{database}{resync_needed} }});
		}
	}
	
	# Now loop through each table we've seen and see if the moditied_date differs for any of the 
	# databases. If it has, trigger a resync.
	foreach my $table (sort {$a cmp $b} keys %{$anvil->data->{sys}{database}{table}})
	{
		# We don't sync 'states' as it's transient and sometimes per-DB.
		next if $table eq "alert_sent";
		next if $table eq "states";
		next if $table eq "update";
		### TODO: Delete 'sessions' when issue #520 is solved 
		###       - https://github.com/ClusterLabs/anvil/issues/520
		next if $table eq "sessions";
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::table::${table}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{last_updated}, 
			"sys::database::table::${table}::row_count"    => $anvil->data->{sys}{database}{table}{$table}{row_count}, 
		}});
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{sys}{database}{table}{$table}{uuid}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::table::${table}::uuid::${uuid}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated}, 
				"sys::database::table::${table}::uuid::${uuid}::row_count"    => $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count}, 
			}});
			if ($anvil->data->{sys}{database}{table}{$table}{last_updated} > $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated})
			{
				# Resync needed.
				my $difference = $anvil->data->{sys}{database}{table}{$table}{last_updated} - $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:difference"                                                  => $anvil->Convert->add_commas({number => $difference }), 
					"s2:sys::database::table::${table}::last_updated"                => $anvil->data->{sys}{database}{table}{$table}{last_updated}, 
					"s3:sys::database::table::${table}::uuid::${uuid}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{last_updated}, 
				}});

				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0106", variables => { 
					seconds => $difference, 
					table   => $table, 
					uuid    => $uuid,
					host    => $anvil->Get->host_name_from_uuid({host_uuid => $uuid}),
				}});
				
				# Mark it as behind.
				$anvil->Database->_mark_database_as_behind({debug => $debug, uuid => $uuid});
				last;
			}
			if ($anvil->data->{sys}{database}{table}{$table}{row_count} > $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count})
			{
				# Resync needed.
				my $difference = ($anvil->data->{sys}{database}{table}{$table}{row_count} - $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:difference"                                               => $anvil->Convert->add_commas({number => $difference }), 
					"s2:sys::database::table::${table}::row_count"                => $anvil->data->{sys}{database}{table}{$table}{row_count}, 
					"s3:sys::database::table::${table}::uuid::${uuid}::row_count" => $anvil->data->{sys}{database}{table}{$table}{uuid}{$uuid}{row_count}, 
				}});
				
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0219", variables => { 
					missing => $difference, 
					table   => $table, 
					uuid    => $uuid,
					host    => $anvil->Get->host_name_from_uuid({host_uuid => $uuid}),
				}});
				
				# Mark it as behind.
				$anvil->Database->_mark_database_as_behind({debug => $debug, uuid => $uuid});
				last;
			}
		}
		last if $anvil->data->{sys}{database}{resync_needed};
	}
	
	# Force resync if requested by command line switch.
	$anvil->data->{switches}{'resync-db'} = "" if not defined $anvil->data->{switches}{'resync-db'};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"switches::resync-db" => $anvil->data->{switches}{'resync-db'},
	}});
	if ($anvil->data->{switches}{'resync-db'})
	{
		$anvil->data->{sys}{database}{resync_needed} = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::resync_needed" => $anvil->data->{sys}{database}{resync_needed},
		}});
		return(0);
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::resync_needed" => $anvil->data->{sys}{database}{resync_needed} }});
	return(0);
}


=head2 _mark_database_as_behind

This method marks that a resync is needed and, if needed, switches the database this machine will read from.

Parameters;

=head3 id

This is the C<< id >> of the database being marked as "behind".

=cut
sub _mark_database_as_behind
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_mark_database_as_behind()" }});
	
	
	my $uuid = $parameter->{uuid} ? $parameter->{uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
	$anvil->data->{sys}{database}{to_update}{$uuid}{behind} = 1;
	$anvil->data->{sys}{database}{resync_needed}            = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::to_update::${uuid}::behind" => $anvil->data->{sys}{database}{to_update}{$uuid}{behind}, 
		"sys::database::resync_needed"              => $anvil->data->{sys}{database}{resync_needed}, 
	}});
		
	# We can't trust this database for reads, so switch to another database for reads if
	# necessary.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                       => $uuid, 
		"sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid}, 
	}});
	if ($uuid eq $anvil->data->{sys}{database}{read_uuid})
	{
		# Switch.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ">> sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid} }});
		foreach my $this_uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
		{
			next if $this_uuid eq $uuid;
			$anvil->data->{sys}{database}{read_uuid} = $this_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "<< sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid} }});
			last;
		}
	}
	
	return(0);
}


=head2 _test_access

This method takes a database UUID and tests the connection to it using the DBD 'ping' method. If it fails, the database connections will be refreshed. If after this there is still no connection, C<< 1 >> is returned. If the connection is up (immediately or after reconnect), C<< 0 >> is returned.

This exists to handle the loss of a database mid-run where a normal query, which isn't wrapped in a query, could hang indefinately.

B<< Note >>: If there is no active handle, this returns C<< 1 >> immediately without trying to reconnect.

=cut
sub _test_access
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_test_access()" }});
	
	my $uuid = $parameter->{uuid} ? $parameter->{uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                              => $uuid,
		"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
	}});
	
	# If the handle is down, return 0.
	my $problem = 1;
	if ((not exists $anvil->data->{cache}{database_handle}{$uuid}) or (not $anvil->data->{cache}{database_handle}{$uuid}))
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		return($problem);
	}
	
	# Make logging code a little cleaner
	my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "anvil";
	my $say_server    = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
	
	# Log our test
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0087", variables => { server => $say_server }});
	
	# Check using ping. Returns '1' on success, '0' on fail.
	alarm(120);
	my $connected = $anvil->data->{cache}{database_handle}{$uuid}->ping();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connected => $connected }});
	alarm(0);
	if ($@) { $anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 'alarm $@' => $@ }}); }
	if (not $connected)
	{
		$anvil->data->{sys}{in_test_access} = 0 if not defined $anvil->data->{sys}{in_test_access};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::in_test_access" => $anvil->data->{sys}{in_test_access} }});
		if (not $anvil->data->{sys}{in_test_access})
		{
			# This prevents deep recursion
			$anvil->data->{sys}{in_test_access} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::in_test_access" => $anvil->data->{sys}{in_test_access},
			}});
			
			# Tell the user we're going to try to reconnect
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0192", variables => { server => $say_server }});
			
			# Try to reconnect.
			$anvil->Database->reconnect({
				debug     => 2,
				lost_uuid => $uuid, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::connections"      => $anvil->data->{sys}{database}{connections},
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid},
			}});
			
			$anvil->data->{sys}{in_test_access} = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:sys::in_test_access"             => $anvil->data->{sys}{in_test_access}, 
				"s2:cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
			}});
			
			if ($anvil->data->{cache}{database_handle}{$uuid})
			{
				alarm(120);
				my $connected = $anvil->data->{cache}{database_handle}{$uuid}->ping();
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connected => $connected }});
				alarm(0);
				if ($@) { $anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 'alarm $@' => $@ }}); }
				
				if ($connected)
				{
					# We reconnected.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0854", variables => { server => $say_server }});
					$problem = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
					return($problem);
				}
				else
				{
					# The tartget DB is gone.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0179", variables => { server => $say_server }});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
					return($problem);
				}
			}
			else
			{
				# The tartget DB is gone.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0179", variables => { server => $say_server }});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
				return($problem);
			}
		}
		else
		{
			# No luck.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0179", variables => { server => $say_server }});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			return($problem);
		}
	}
	
	# Success!
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0088"});
	$problem = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	return($problem);
}

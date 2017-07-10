package AN::Tools::Database;
# 
# This module contains methods related to databases.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Database.pm";

### Methods;
# connect
# get_local_id
# initialize
# query
# test_access
# write

=pod

=encoding utf8

=head1 NAME

AN::Tools::Database

Provides all methods related to managing and accessing databases.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Database->X'. 
 # 
 # Example using 'get_local_id()';
 my $local_id = $an->Database->get_local_id;

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

# Get a handle on the AN::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 connect_to_databases

This method tries to connect to all databases it knows of. To define databases for a machine to connect to, load a configuration file with the following parameters;

 database::1::host			=	an-striker01.alteeve.com
 database::1::port			=	5432
 database::1::name			=	scancore
 database::1::user			=	admin
 database::1::password			=	Initial1
 database::1::ping_before_connect	=	1
 
 database::2::host			=	an-striker02.alteeve.com
 database::2::port			=	5432
 database::2::name			=	scancore
 database::2::user			=	admin
 database::2::password			=	Initial1
 database::2::ping_before_connect	=	1

The C<< 1 >> and C<< 2 >> are the IDs of the given databases. They can be any number and do not need to be sequential, they just need to be unique. 

This module will return the number of databases that were successfully connected to. This makes it convenient to check and exit if no databases are available using a check like;

 my $database_count = $an->Database->connect({file => $THIS_FILE});
 if($database_count)
 {
 	# Connected to: [$database_count] database(s)!
 }
 else
 {
 	# No databases available, exiting.
 }

Parameters;

=head3 file (required)

The C<< file >> parameter is used to check the special C<< updated >> table one all connected databases to see when that file (program name) last updated a given database. If the date stamp is the same on all connected databases, nothing further happens. If one of the databases differ, however, a resync will be requested.

=head3 tables (optional)

This is an optional array reference of tables to specifically check when connecting to databases. If specified, the table's most recent C<< modified_date >> time stamp will be read (specifically; C<< SELECT modified_date FROM $table ORDER BY modified_date DESC LIMIT 1 >>) and if a table doesn't return, or any of the time stamps are missing, a resync will be requested.

To use this, use;

 $an->Database->connect({file => $THIS_FILE, tables => ("table1", "table2")});

=cut
sub connect
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	$an->Log->entry({log_level => 3, message_key => "tools_log_0001", message_variables => { function => "connect_to_databases" }, file => $THIS_FILE, line => __LINE__});
	
	my $file   = defined $parameter->{file}   ? $parameter->{file}   : "";
	my $tables = defined $parameter->{tables} ? $parameter->{tables} : "";
	
	# We need the host_uuid before we connect.
	if (not $an->data->{sys}{host_uuid})
	{
		$an->data->{sys}{host_uuid} = $an->Get->host_uuid;
	}
	
	# This will be used in a few cases where the local DB ID is needed (or the lack of it being set 
	# showing we failed to connect to the local DB).
	$an->data->{sys}{local_db_id} = "";
	
	# This will be set to '1' if either DB needs to be initialized or if the last_updated differs on any node.
	$an->data->{database_resync_needed} = 0;
	
	# Now setup or however-many connections
	my $seen_connections       = [];
	my $connections            = 0;
	my $failed_connections     = [];
	my $successful_connections = [];
	foreach my $id (sort {$a cmp $b} keys %{$an->data->{database}})
	{
		next if $id eq "general";	# This is used for global values.
		my $driver   = "DBI:Pg";
		my $host     = $an->data->{database}{$id}{host}     ? $an->data->{database}{$id}{host}     : ""; # This should fail
		my $port     = $an->data->{database}{$id}{port}     ? $an->data->{database}{$id}{port}     : 5432;
		my $name     = $an->data->{database}{$id}{name}     ? $an->data->{database}{$id}{name}     : ""; # This should fail
		my $user     = $an->data->{database}{$id}{user}     ? $an->data->{database}{$id}{user}     : ""; # This should fail
		my $password = $an->data->{database}{$id}{password} ? $an->data->{database}{$id}{password} : "";
		
		# If not set, we will always ping before connecting.
		if ((not exists $an->data->{database}{$id}{ping_before_connect}) or (not defined $an->data->{database}{$id}{ping_before_connect}))
		{
			$an->data->{database}{$id}{ping_before_connect} = 1;
		}
		
		# Make sure the user didn't specify the same target twice.
		my $target_host = "$host:$port";
		my $duplicate   = 0;
		foreach my $existing_host (sort {$a cmp $b} @{$seen_connections})
		{
			if ($existing_host eq $target_host)
			{
				# User is connecting to the same target twice.
				$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0053", variables => { target => $target_host }});
				$duplicate = 1;
			}
		}
		if (not $duplicate)
		{
			push @{$seen_connections}, $target_host;
		}
		next if $duplicate;
		
		# Log what we're doing.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0054", variables => { 
			id       => $id,
			driver   => $driver,
			host     => $host,
			port     => $port,
			name     => $name,
			user     => $user,
			password => $an->Log->secure ? $password : "--",
		}});
		
		# Assemble my connection string
		my $db_connect_string = "$driver:dbname=$name;host=$host;port=$port";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			db_connect_string                      => $db_connect_string, 
			"database::${id}::ping_before_connect" => $an->data->{database}{$id}{ping_before_connect},
		}});
		if ($an->data->{database}{$id}{ping_before_connect})
		{
			# Can I ping?
			my ($pinged) = $an->System->ping({ping => $host, count => 1});
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { pinged => $pinged }});
			if (not $pinged)
			{
				# Didn't ping and 'database::<id>::ping_before_connect' not set. Record this 
				# is the failed connections array.
				$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0063", variables => { id => $id }});
				push @{$failed_connections}, $id;
				next;
			}
		}
		
		# Connect!
		my $dbh = "";
		### NOTE: The Database->write() method, when passed an array, will automatically disable 
		###       autocommit, do the bulk write, then commit when done.
		# We connect with fatal errors, autocommit and UTF8 enabled.
		eval { $dbh = DBI->connect($db_connect_string, $user, $password, {
			RaiseError     => 1,
			AutoCommit     => 1,
			pg_enable_utf8 => 1
		}); };
		if ($@)
		{
			# Something went wrong...
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0064", variables => { 
				id   => $id,
				host => $host,
				name => $name,
			}});

			push @{$failed_connections}, $id;
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
				$variables   = { id => $id };
			}
			elsif ($DBI::errstr =~ /password authentication failed for user/)
			{
				$message_key = "log_0068";
				$variables   = { 
					id   => $id,
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
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => $message_key, variables => { $variables }});
		}
		elsif ($dbh =~ /^DBI::db=HASH/)
		{
			# Woot!
			$connections++;
			push @{$successful_connections}, $id;
			$an->data->{cache}{db_fh}{$id} = $dbh;
			
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0071", variables => { 
				host => $host,
				port => $port,
				name => $name,
				id   => $id,
			}});
			
			# Now that I have connected, see if my 'hosts' table exists.
			my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename='hosts' AND schemaname='public';";
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
			
			my $count = $an->Database->query({id => $id, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { count => $count }});
			if ($count < 1)
			{
				# Need to load the database.
				$an->Database->initialize({id => $id});
			}
			
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				"sys::read_db_id"   => $an->data->{sys}{read_db_id}, 
				"cache::db_fh::$id" => $an->data->{cache}{db_fh}{$id}, 
			}});
			
			# Set the first ID to be the one I read from later. Alternatively, if this host is 
			# local, use it.
			if (($host eq $an->_hostname)       or 
			    ($host eq $an->_short_hostname) or 
			    ($host eq "localhost")          or 
			    ($host eq "127.0.0.1")          or 
			    (not $an->data->{sys}{read_db_id}))
			{
				$an->data->{sys}{read_db_id}  = $id;
				$an->data->{sys}{local_db_id} = $id;
				$an->data->{sys}{use_db_fh}   = $an->data->{cache}{db_fh}{$id};
				
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					"sys::read_db_id" => $an->data->{sys}{read_db_id}, 
					"sys::use_db_fh"  => $an->data->{sys}{use_db_fh}
				});
			}
			
			# Get a time stamp for this run, if not yet gotten.
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				"cache::db_fh::$id" => $an->data->{cache}{db_fh}{$id}, 
				"sys::db_timestamp" => $an->data->{sys}{db_timestamp}
			});
			
			
			
			### NOTE: Left off here.
			if (not $an->data->{sys}{db_timestamp})
			{
				my $query = "SELECT cast(now() AS timestamp with time zone)";
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query });
				
				$an->data->{sys}{db_timestamp} = $an->Database->query({id => $id, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "sys::db_timestamp" => $an->data->{sys}{db_timestamp} });
			}
			
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				"sys::read_db_id"   => $an->data->{sys}{read_db_id},
				"sys::use_db_fh"    => $an->data->{sys}{use_db_fh},
				"sys::db_timestamp" => $an->data->{sys}{db_timestamp},
			});
		}
	}
	
	# Do I have any connections? Don't die, if not, just return.
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { connections => $connections }});
	if (not $connections)
	{
		# Failed to connect to any database. Log this, print to the caller and return.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0091"});
		return($connections);
	}
	
	# Report any failed DB connections
	foreach my $id (@{$failed_connections})
	{
		# Copy my alert hash before I delete the id.
		my $error_array = [];
		
		# Delete this DB so that we don't try to use it later.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0092", variables => { server => $say_server, id => $id }});
		
		# Delete it from the list of known databases for this run.
		delete $an->data->{database}{$id};
		
		# If I've not sent an alert about this DB loss before, send one now.
		my $set = $an->Alert->check_alert_sent({
			type			=>	"warning",
			alert_sent_by		=>	$THIS_FILE,
			alert_record_locator	=>	$id,
			alert_name		=>	"connect_to_db",
			modified_date		=>	$an->data->{sys}{db_timestamp},
		});
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1  => "set", value1 => $set
		}, file => $THIS_FILE, line => __LINE__});
		
		if ($set)
		{
			$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
				name1  => "error_array", value1 => $error_array
			}, file => $THIS_FILE, line => __LINE__});
			foreach my $hash (@{$error_array})
			{
				my $message_key       = $hash->{message_key};
				my $message_variables = $hash->{message_variables};
				$an->Log->entry({log_level => 3, message_key => "an_variables_0003", message_variables => {
					name1 => "hash",              value1 => $hash, 
					name2 => "message_key",       value2 => $message_key, 
					name3 => "message_variables", value3 => $message_variables, 
				}, file => $THIS_FILE, line => __LINE__});
				
				# These are warning level alerts.
				$an->Alert->register_alert({
					alert_level		=>	"warning", 
					alert_agent_name	=>	"ScanCore",
					alert_title_key		=>	"an_alert_title_0004",
					alert_message_key	=>	$message_key,
					alert_message_variables	=>	$message_variables,
				});
			}
		}
	}
	
	# Send an 'all clear' message if a now-connected DB previously wasn't.
	foreach my $id (@{$successful_connections})
	{
		# Query to see if the newly connected host is in the DB yet. If it isn't, don't send an
		# alert as it'd cause a duplicate UUID error.
		my $query = "SELECT COUNT(*) FROM hosts WHERE host_name = ".$an->data->{sys}{use_db_fh}->quote($an->data->{database}{$id}{host}).";";
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "query", value1 => $query
		}, file => $THIS_FILE, line => __LINE__});
		my $count = $an->Database->query({id => $id, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
			name1 => "count", value1 => $count
		}, file => $THIS_FILE, line => __LINE__});
		
		if ($count > 0)
		{
			my $cleared = $an->Alert->check_alert_sent({
				type			=>	"clear",
				alert_sent_by		=>	$THIS_FILE,
				alert_record_locator	=>	$id,
				alert_name		=>	"connect_to_db",
				modified_date		=>	$an->data->{sys}{db_timestamp},
			});
			if ($cleared)
			{
				$an->Alert->register_alert({
					alert_level		=>	"warning", 
					alert_agent_name	=>	"ScanCore",
					alert_title_key		=>	"an_alert_title_0006",
					alert_message_key	=>	"cleared_message_0001",
					alert_message_variables	=>	{
						name			=>	$an->data->{database}{$id}{name},
						host			=>	$an->data->{database}{$id}{host},
						port			=>	$an->data->{database}{$id}{port} ? $an->data->{database}{$id}{port} : 5432,
					},
				});
			}
		}
	}

	$an->Log->entry({log_level => 3, message_key => "an_variables_0001", message_variables => {
		name1 => "sys::host_uuid", value1 => $an->data->{sys}{host_uuid}, 
	}, file => $THIS_FILE, line => __LINE__});
	if ($an->data->{sys}{host_uuid} !~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/)
	{
		# derp
		$an->Log->entry({log_level => 0, message_key => "error_message_0061", file => $THIS_FILE, line => __LINE__});
		
		# Disconnect and set the connection count to '0'.
		$an->DB->disconnect_from_databases();
		$connections = 0;
	}
	
	# For now, we just find which DBs are behind and let each agent deal with bringing their tables up to
	# date.
	$an->DB->find_behind_databases({file => $file});
	
	# Hold if a lock has been requested.
	$an->DB->locking();
	
	# Mark that we're not active.
	$an->DB->mark_active({set => 1});
	
	return($connections);
}

=head2 get_local_id

This returns the database ID from 'C<< striker.conf >>' based on matching the 'C<< database::<id>::host >>' to the local machine's host name or one of the active IP addresses on the host.

 # Get the local ID
 my $local_id = $an->Database->get_local_id;

This will return a blank string if no match is found.

=cut
sub get_local_id
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $local_id        = "";
	my $network_details = $an->Get->network_details;
	foreach my $id (sort {$a cmp $b} keys %{$an->data->{database}})
	{
		next if $id eq "general";	# This is used for global values.
		if ($network_details->{hostname} eq $an->data->{database}{$id}{host})
		{
			$local_id = $id;
			last;
		}
	}
	if (not $local_id)
	{
		foreach my $interface (sort {$a cmp $b} keys %{$network_details->{interface}})
		{
			my $ip_address  = $network_details->{interface}{$interface}{ip};
			my $subnet_mask = $network_details->{interface}{$interface}{netmask};
			foreach my $id (sort {$a cmp $b} keys %{$an->data->{database}})
			{
				next if $id eq "general";	# This is used for global values.
				if ($ip_address eq $an->data->{database}{$id}{host})
				{
					$local_id = $id;
					last;
				}
			}
		}
	}
	
	return($local_id);
}

=head2 initialize

This will initialize an empty database.

=cut
sub initialize
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $id       = $parameter->{id}       ? $parameter->{id}       : $an->data->{sys}{read_db_id};
	my $sql_file = $parameter->{sql_file} ? $parameter->{sql_file} : $an->data->{database}{$id}{core_sql};
	my $success  = 1;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		id       => $id, 
		sql_file => $sql_file, 
	}});
	
	# This just makes some logging cleaner below.
	my $say_server = $an->data->{database}{$id}{host}.":".$an->data->{database}{$id}{port}." -> ".$an->data->{database}{$id}{name};
	
	if (not $id)
	{
		# No database to talk to...
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0077"});
		return(0);
	}
	elsif (not defined $an->data->{cache}{db_fh}{$id})
	{
		# Database handle is gone.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0078", variables => { id => $id }});
		return(0);
	}
	if (not $sql_file)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0079", variables => { 
			server => $say_server,
			id     => $id, 
		}});
		return(0);
	}
	elsif (not -e $sql_file)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0080", variables => { 
			server   => $say_server,
			id       => $id, 
			sql_file => $sql_file, 
		}});
		return(0);
	}
	elsif (not -r $sql_file)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0081", variables => { 
			server   => $say_server,
			id       => $id, 
			sql_file => $sql_file, 
		}});
		return(0);
	}
	
	# Tell the user we need to initialize
	$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0082", variables => { 
			server   => $say_server,
			id       => $id, 
			sql_file => $sql_file, 
	}});
	
	$an->Log->entry({log_level => 1, title_key => "tools_title_0005", message_key => "tools_log_0020", message_variables => {
		server   => $say_server,
		sql_file => $sql_file, 
	}, file => $THIS_FILE, line => __LINE__});
	
	# Read in the SQL file and replace #!variable!name!# with the database owner name.
	my $user = $an->data->{database}{$id}{user};
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { user => $user }});
	
	my $sql = $an->Storage->read_file({file => $sql_file});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { ">> sql" => $sql }});
	
	$sql =~ s/#!variable!user!#/$user/sg;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "<< sql" => $sql }});
	
	### NOTE: Left off here
	# Now that I am ready, disable autocommit, write and commit.
	$an->Database->write({id => $id, query => $sql, source => $THIS_FILE, line => __LINE__});
	
	$an->data->{sys}{db_initialized}{$id} = 1;
	
	# Mark that we need to update the DB.
	$an->data->{database_resync_needed} = 1;
	
	return($success);
};

=head2 query

This performs a query and returns an array reference of array references (from C<< DBO->fetchall_arrayref >>). The first array contains all the returned rows and each row is an array reference of columns in that row.

If an error occurs, C<< undef >> will be returned.

For example, given the query;

 scancore=# SELECT host_uuid, host_name, host_type FROM hosts ORDER BY host_name ASC;
               host_uuid               |        host_name         | host_type 
 --------------------------------------+--------------------------+-----------
  e27fc9a0-2656-4aaf-80e6-fedb3c339037 | an-a01n01.alteeve.com    | node
  4bea6ddd-c3ff-43e9-8e9e-b2dea1923145 | an-a01n02.alteeve.com    | node
  ff852db7-c77a-403b-877f-91f85f3ad95c | an-striker01.alteeve.com | dashboard
  2dd5aab1-65d6-4416-9bc1-98dc344aa08b | an-striker02.alteeve.com | dashboard
 (4 rows)

The returned array would have four values, one for each returned row. Each row would be an array reference containing three values, one per row. So given the above example;

 my $rows = $an->Database->query({query => "SELECT host_uuid, host_name, host_type FROM hosts ORDER BY host_name ASC;"});
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

=head3 id (optional)

By default, the local database will be queried (if run on a machine with a database). Otherwise, the first database successfully connected to will be used for queries (as stored in C<< $an->data->{sys}{read_db_id} >>).

If you want to read from a specific database, though, you can set this parameter to the ID of the database (C<< database::<id>::host). If you specify a read from a database that isn't available, C<< undef >> will be returned.

=head3 line (optional)

To help with logging the source of a query, C<< line >> can be set to the line number of the script that requested the query. It is generally used along side C<< source >>.

=head3 query (required)

This is the SQL query to perform.

B<NOTE>: ALWAYS use C<< $an->data->{sys}{use_db_fh}->quote(...)>> when preparing data coming from ANY external source! Otherwise you'll end up XKCD 327'ing your database eventually...

=head3 secure (optional, defaul '0')

If set, the query will be treated as containing sensitive data and will only be logged if C<< $an->Log->secure >> is enabled.

=head3 source (optional)

To help with logging the source of a query, C<< source >> can be set to the name of the script that requested the query. It is generally used along side C<< line >>.


=cut
sub query
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $id     = $parameter->{id}     ? $parameter->{id}     : $an->data->{sys}{read_db_id};
	my $line   = $parameter->{line}   ? $parameter->{line}   : __LINE__;
	my $query  = $parameter->{query}  ? $parameter->{query}  : "";
	my $secure = $parameter->{secure} ? $parameter->{secure} : 0;
	my $source = $parameter->{source} ? $parameter->{source} : $THIS_FILE;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		id                    => $id, 
		"cache::db_fh::${id}" => $an->data->{cache}{db_fh}{$id}, 
		line                  => $line, 
		query                 => ((not $an->Log->secure) && ($secure)) ? $query : "--", 
		secure                => $secure, 
		source                => $source, 
	}});
	
	# Make logging code a little cleaner
	my $say_server = $an->data->{database}{$id}{host}.":".$an->data->{database}{$id}{port}." -> ".$an->data->{database}{$id}{name};
	
	if (not $id)
	{
		# No database to talk to...
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0072"});
		return(undef);
	}
	elsif (not defined $an->data->{cache}{db_fh}{$id})
	{
		# Database handle is gone.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0073", variables => { id => $id }});
		return(undef);
	}
	if (not $query)
	{
		# No query
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0084", variables => { 
			server => $say_server,
		}});
		return(undef);
	}
	
	### TODO:  If I am still alive check if any locks need to be renewed.
	#$an->Database->check_lock_age;
	
	### TODO: Do I need to log the transaction?
	#if ($an->Log->db_transactions())
	if (1)
	{
		$an->Log->entry({source => $source, line => $line, secure => $secure, level => 2, key => "log_0074", variables => { 
			id    => $id 
			query => $query, 
		}});
	}
	
	# Test access to the DB before we do the actual query
	$an->Database->_test_access({id => $id});
	
	# Do the query.
	my $DBreq = $an->data->{cache}{db_fh}{$id}->prepare($query) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0075", variables => { 
			query    => ((not $an->Log->secure) && ($secure)) ? $query : "--", 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}});
	
	# Execute on the query
	$DBreq->execute() or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0076", variables => { 
			query    => ((not $an->Log->secure) && ($secure)) ? $query : "--", 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}});
	
	# Return the array
	return($DBreq->fetchall_arrayref());
}

=head2 write

This records data to one or all of the databases. If an ID is passed, the query is written to one database only. Otherwise, it will be written to all DBs.

=cut
sub write
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $id     = $parameter->{id}     ? $parameter->{id}     : $an->data->{sys}{read_db_id};
	my $line   = $parameter->{line}   ? $parameter->{line}   : __LINE__;
	my $query  = $parameter->{query}  ? $parameter->{query}  : "";
	my $secure = $parameter->{secure} ? $parameter->{secure} : 0;
	my $source = $parameter->{source} ? $parameter->{source} : $THIS_FILE;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		id                    => $id, 
		"cache::db_fh::${id}" => $an->data->{cache}{db_fh}{$id}, 
		line                  => $line, 
		query                 => ((not $an->Log->secure) && ($secure)) ? $query : "--", 
		secure                => $secure, 
		source                => $source, 
	}});
	
	# Make logging code a little cleaner
	my $say_server = $an->data->{database}{$id}{host}.":".$an->data->{database}{$id}{port}." -> ".$an->data->{database}{$id}{name};
	
	# We don't check if ID is set here because not being set simply means to write to all available DBs.
	if (not $query)
	{
		# No query
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0085", variables => { server => $say_server }});
		return(undef);
	}
	
	# TODO: If I am still alive check if any locks need to be renewed.
	#$an->DB->check_lock_age;
	
	# This array will hold either just the passed DB ID or all of them, if no ID was specified.
	my @db_ids;
	if ($id)
	{
		push @db_ids, $id;
	}
	else
	{
		foreach my $id (sort {$a cmp $b} keys %{$an->data->{cache}{db_fh}})
		{
			push @db_ids, $id;
		}
	}
	
	# Sort out if I have one or many queries.
	my $limit     = 25000;
	my $count     = 0;
	my $query_set = [];
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "database::general::maximum_batch_size" => $an->data->{database}{general}{maximum_batch_size} }});
	if ($an->data->{database}{general}{maximum_batch_size})
	{
		if ($an->data->{database}{general}{maximum_batch_size} =~ /\D/)
		{
			# Bad value.
			$an->data->{database}{general}{maximum_batch_size} = 25000;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "database::general::maximum_batch_size" => $an->data->{database}{general}{maximum_batch_size} }});
		}
		
		# Use the set value now.
		$limit = $an->data->{database}{general}{maximum_batch_size};
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { limit => $limit }});
	}
	if (ref($query) eq "ARRAY")
	{
		# Multiple things to enter.
		$count = @{$query};
		
		# If I am re-entering, then we'll proceed normally. If not, and if we have more than 10k 
		# queries, we'll split up the queries into 10k chunks and re-enter.
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			count   => $count, 
			limit   => $limit 
			reenter => $reenter, 
		}});
		if (($count > $limit) && (not $reenter))
		{
			my $i    = 0;
			my $next = $limit;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { i => $i, 'next' => $next }});
			foreach my $this_query (@{$query})
			{
				push @{$query_set}, $this_query;
				$i++;
				
				if ($i > $next)
				{
					# Commit this batch.
					foreach my $id (@db_ids)
					{
						# Commit this chunk to this DB.
						$an->DB->do_db_write({id => $id, query => $query_set, source => $THIS_FILE, line => $line, reenter => 1});
						
						### TODO: Rework this so that we exit here (so that we can 
						###       send an alert) if the RAM use is too high.
						# This can get memory intensive, so check our RAM usage and 
						# bail if we're eating too much.
						#my $ram_use = $an->System->check_memory({ program_name => $THIS_FILE });
						
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
			}
		}
	}
	else
	{
		push @{$query_set}, $query;
	}
	foreach my $id (@db_ids)
	{
		# Test access to the DB before we do the actual query
		$an->Database->_test_access({id => $id});
		
		# Do the actual query(ies)
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0085", variables => { 
			id    => $id, 
			count => $count, 
		}});
		if ($count)
		{
			# More than one query, so start a transaction block.
			$an->data->{cache}{db_fh}{$id}->begin_work;
		}
		
		foreach my $query (@{$query_set})
		{
			# TODO: Record the query
			#if ($an->Log->db_transactions())
			if (1)
			{
				$an->Log->entry({source => $source, line => $line, secure => $secure, level => 2, key => "log_0074", variables => { 
					id    => $id 
					query => $query, 
				}});
			}
			
			if (not $an->data->{cache}{db_fh}{$id})
			{
				$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0089", variables => { id => $id }});
				next;
			}
			
			# Do the do.
			$an->data->{cache}{db_fh}{$id}->do($query) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0090", variables => { 
					query    => ((not $an->Log->secure) && ($secure)) ? $query : "--", 
					server   => $say_server,
					db_error => $DBI::errstr, 
				}});
		}
		
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { count => $count }});
		if ($count)
		{
			# Commit the changes.
			$an->data->{cache}{db_fh}{$id}->commit();
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { count => $count }});
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

=head2 _test_access

This method takes a database ID and performs a simple C<< SELECT 1 >> query, wrapped in a ten second C<< alarm >>. If the database has died, the query will hang and the C<< alarm >> will fire, killing this program. If the call returns, the C<< alarm >> is cancelled.

This exists to handle the loss of a database mid-run where a normal query, which isn't wrapped in a query, could hang indefinately.

=cut
sub _test_access
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $id = $parameter->{id} ? $parameter->{id} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { id => $id }});
	
	# Make logging code a little cleaner
	my $say_server = $an->data->{database}{$id}{host}.":".$an->data->{database}{$id}{port}." -> ".$an->data->{database}{$id}{name};
	
	# Log our test
	$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0087", variables => { server => $say_server }});
	
	my $query = "SELECT 1";
	my $DBreq = $an->data->{cache}{db_fh}{$id}->prepare($query) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0075", variables => { 
			query    => $query, 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}});
	
	# Give the test query a few seconds to respond, just in case we have some latency to a remote DB.
	alarm(10);
	$DBreq->execute() or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0076", variables => { 
			query    => $query, 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}});
	# If we're here, we made contact.
	alarm(0);
	
	# Success!
	$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0088"});
	
	return(0);
}

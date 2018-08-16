package Anvil::Tools::Database;
# 
# This module contains methods related to databases.
# 

use strict;
use warnings;
use DBI;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Database.pm";

### Methods;
# archive_database
# check_lock_age
# configure_pgsql
# connect
# disconnect
# get_hosts
# get_local_uuid
# initialize
# insert_or_update_bridges
# insert_or_update_bonds
# insert_or_update_hosts
# insert_or_update_ip_addresses
# insert_or_update_jobs
# insert_or_update_network_interfaces
# insert_or_update_states
# insert_or_update_users
# insert_or_update_variables
# lock_file
# locking
# mark_active
# query
# read_variable
# resync_databases
# write
# _archive_table
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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 archive_database

NOTE: Not implemented yet.

=cut
sub archive_database
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->archive_database()" }});
	
	# Is archiving disabled?
	if (not $anvil->data->{sys}{database}{archive}{trigger})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0189"});
		return(1);
	}
	
	# Only the root user can archive the database so that the archived files can be properly secured.
	if (($< != 0) && ($> != 0))
	{
		# Not root
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0188"});
		return(1);
	}
	
	# If we don't have an array of tables, we have nothing to do.
	if ((not exists $anvil->data->{sys}{database}{check_tables}) or (ref(@{$anvil->data->{sys}{database}{check_tables}} ne "ARRAY")))
	{
		return(1);
	}
	
	# We'll use the list of tables created for _find_behind_databases()'s 'sys::database::check_tables' 
	# array, but in reverse so that tables with primary keys (first in the array) are archived last.
	foreach my $table (reverse(@{$anvil->data->{sys}{database}{check_tables}}))
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
		
		$anvil->Database->_archive_table({table => $table});
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0126", variables => { method => "Database->archive_database()" }});
	return(0);
}

=head2 check_lock_age

This checks to see if 'sys::database::local_lock_active' is set. If it is, its age is checked and if the age is >50% of sys::database::locking_reap_age, it will renew the lock.

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
			$anvil->Database->locking({renew => 1});
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

=head2 configure_pgsql

This configures the local database server. Specifically, it checks to make sure the daemon is running and starts it if not. It also checks the C<< pg_hba.conf >> configuration to make sure it is set properly to listen on this machine's IP addresses and interfaces.

If the system is already configured, this method will do nothing, so it is safe to call it at any time.

If the method completes, C<< 0 >> is returned. If this method is called without C<< root >> access, it returns C<< 1 >> without doing anything. If there is a problem, C<< !!error!! >> is returned.

=cut
sub configure_pgsql
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->configure_pgsql()" }});
	
	# The local host_uuid is the ID of the local database, so get that.
	my $uuid = $anvil->Get->host_uuid();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
	# If we're not running with root access, return.
	if (($< != 0) && ($> != 0))
	{
		# This is a minor error as it will be hit by every unpriviledged program that connects to the
		# database(s).
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0113"});
		return(1);
	}
	
	# First, is it running?
	my $running = $anvil->System->check_daemon({debug => $debug, daemon => "postgresql"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
	
	if (not $running)
	{
		# Do we need to initialize the databae?
		if (not -e $anvil->data->{path}{configs}{'pg_hba.conf'})
		{
			# Initialize.
			my $output = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'postgresql-setup'}." initdb", source => $THIS_FILE, line => __LINE__});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
			
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
				
				# Enable it on boot.
				my $return_code = $anvil->System->enable_daemon({debug => $debug, daemon => "postgresql"});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
			}
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pg_hba_backup => $pg_hba_backup }});
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
	if (not $running)
	{
		# Start the daemon.
		my $return_code = $anvil->System->start_daemon({daemon => "postgresql"});
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
	elsif (($update_postgresql_file) or ($update_pg_hba_file))
	{
		# Reload
		my $return_code = $anvil->System->start_daemon({daemon => "postgresql"});
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
	
	# Create the .pgpass file, if needed.
	my $created_pgpass = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
		'path::secure::postgres_pgpass' => $anvil->data->{path}{secure}{postgres_pgpass},
		"database::${uuid}::password"   => $anvil->data->{database}{$uuid}{password}, 
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
	my $database_user = $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : $anvil->data->{sys}{database}{user};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_user => $database_user }});
	if (not $database_user)
	{
		# No database user defined
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0099", variables => { uuid => $uuid }});
		return("!!error!!");
	}
	my $user_list = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT usename, usesysid FROM pg_catalog.pg_user;'\"", source => $THIS_FILE, line => __LINE__});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_list => $user_list }});
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
		my $create_output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{createuser}." --no-superuser --createdb --no-createrole $database_user\"", source => $THIS_FILE, line => __LINE__});
		my $user_list     = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT usename, usesysid FROM pg_catalog.pg_user;'\"", source => $THIS_FILE, line => __LINE__});
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
				my $update_output = $anvil->System->call({secure => 1, shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c \\\"ALTER ROLE $user WITH PASSWORD '".$anvil->data->{database}{$uuid}{password}."';\\\"\"", source => $THIS_FILE, line => __LINE__});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { update_output => $update_output }});
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
	my $database_name   = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : $anvil->data->{sys}{database}{name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_name => $database_name }});
	
	my $database_list = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT datname FROM pg_catalog.pg_database;'\"", source => $THIS_FILE, line => __LINE__});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_list => $database_list }});
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
		my $create_output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{createdb}."  --owner $database_user $database_name\"", source => $THIS_FILE, line => __LINE__});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_output => $create_output }});
		
		my $database_exists = 0;
		my $database_list   = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{su}." - postgres -c \"".$anvil->data->{path}{exe}{psql}." template1 -c 'SELECT datname FROM pg_catalog.pg_database;'\"", source => $THIS_FILE, line => __LINE__});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { database_list => $database_list }});
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
	
	# Make sure the psql TCP port is open.
	$anvil->data->{database}{$uuid}{port} = 5432 if not $anvil->data->{database}{$uuid}{port};
	my $port_status = $anvil->System->manage_firewall({
		task        => "open",
		port_number => $anvil->data->{database}{$uuid}{port},
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port_status => $port_status }});
	
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

=head3 db_uuid (optional)

If set, the connection will be made only to the database server matching the UUID.

=head3 source (optional)

The C<< source >> parameter is used to check the special C<< updated >> table one all connected databases to see when that source (program name, usually) last updated a given database. If the date stamp is the same on all connected databases, nothing further happens. If one of the databases differ, however, a resync will be requested.

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
sub connect
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->connect()" }});
	
	my $source     = defined $parameter->{source}     ? $parameter->{source}     : "core";
	my $sql_file   = defined $parameter->{sql_file}   ? $parameter->{sql_file}   : $anvil->data->{path}{sql}{'anvil.sql'};
	my $tables     = defined $parameter->{tables}     ? $parameter->{tables}     : "";
	my $test_table = defined $parameter->{test_table} ? $parameter->{test_table} : $anvil->data->{sys}{database}{test_table};
	my $db_uuid    = defined $parameter->{db_uuid}    ? $parameter->{db_uuid}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		source     => $source, 
		sql_file   => $sql_file, 
		tables     => $tables, 
		test_table => $test_table, 
		db_uuid    => $db_uuid,
	}});
	
	my $start_time = [gettimeofday];
	#print "Start time: [".$start_time->[0].".".$start_time->[1]."]\n";
	
	$anvil->data->{sys}{database}{timestamp} = "" if not defined $anvil->data->{sys}{database}{timestamp};
	
	# We need the host_uuid before we connect.
	if (not $anvil->data->{sys}{host_uuid})
	{
		$anvil->data->{sys}{host_uuid} = $anvil->Get->host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	}
	
	# This will be used in a few cases where the local DB ID is needed (or the lack of it being set 
	# showing we failed to connect to the local DB).
	$anvil->data->{sys}{database}{local_uuid} = "";
	
	# This will be set to '1' if either DB needs to be initialized or if the last_updated differs on any node.
	$anvil->data->{sys}{database}{resync_needed} = 0;
	
	# Now setup or however-many connections
	my $seen_connections       = [];
	my $failed_connections     = [];
	my $successful_connections = [];
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		if (($db_uuid) && ($db_uuid ne $uuid))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0191", variables => { db_uuid => $db_uuid, uuid => $uuid }});
			next;
		}
		
		my $driver   = "DBI:Pg";
		my $host     = $anvil->data->{database}{$uuid}{host}     ? $anvil->data->{database}{$uuid}{host}     : ""; # This should fail
		my $port     = $anvil->data->{database}{$uuid}{port}     ? $anvil->data->{database}{$uuid}{port}     : 5432;
		my $name     = $anvil->data->{database}{$uuid}{name}     ? $anvil->data->{database}{$uuid}{name}     : $anvil->data->{sys}{database}{name};
		my $user     = $anvil->data->{database}{$uuid}{user}     ? $anvil->data->{database}{$uuid}{user}     : $anvil->data->{sys}{database}{user};
		my $password = $anvil->data->{database}{$uuid}{password} ? $anvil->data->{database}{$uuid}{password} : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host     => $host,
			port     => $port,
			name     => $name,
			user     => $user, 
			password => $anvil->Log->secure ? $password : $anvil->Words->string({key => "log_0186"}), 
		}});
		
		# Some places will want to pull up the database user, so in case it isn't set (which is 
		# usual), set it as if we had read it from the config file using the default.
		if (not $anvil->data->{database}{$uuid}{name})
		{
			$anvil->data->{database}{$uuid}{name} = $anvil->data->{sys}{database}{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "database::${uuid}::name" => $anvil->data->{database}{$uuid}{name} }});
		}
		
		# If not set, we will always ping before connecting.
		if ((not exists $anvil->data->{database}{$uuid}{ping}) or (not defined $anvil->data->{database}{$uuid}{ping}))
		{
			$anvil->data->{database}{$uuid}{ping} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "database::${uuid}::ping" => $anvil->data->{database}{$uuid}{ping} }});
		}
		
		# Make sure the user didn't specify the same target twice.
		my $target_host = "$host:$port";
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
			password => $anvil->Log->secure ? $password : $anvil->Words->string({key => "log_0186"}),
		}});
		
		### TODO: Can we do a telnet port ping with a short timeout instead of a shell ping call?
		
		# Assemble my connection string
		my $db_connect_string = "$driver:dbname=$name;host=$host;port=$port";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			db_connect_string         => $db_connect_string, 
			"database::${uuid}::ping" => $anvil->data->{database}{$uuid}{ping},
		}});
		if ($anvil->data->{database}{$uuid}{ping})
		{
			# Can I ping?
			my ($pinged) = $anvil->System->ping({
				debug   => $debug, 
				ping    => $host, 
				count   => 1,
				timeout => $anvil->data->{database}{$uuid}{ping},
			});
			
			my $ping_time = tv_interval ($start_time, [gettimeofday]);
			#print "[".$ping_time."] - Pinged: [$host:$port:$name:$user]\n";
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pinged => $pinged }});
			if (not $pinged)
			{
				# Didn't ping and 'database::<uuid>::ping' not set. Record this 
				# in the failed connections array.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0063", variables => { 
					host => $port ? $host.":".$port : $host,
					name => $name, 
					uuid => $uuid,
				}});
				push @{$failed_connections}, $uuid;
				next;
			}
		}
		
		# Before we try to connect, see if this is a local database and, if so, make sure it's setup.
		my $is_local = $anvil->System->is_local({debug => $debug, host => $host});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
		if ($is_local)
		{
			$anvil->data->{sys}{database}{read_uuid} = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid} }});
			
			# Set it up (or update it) if needed. This method just returns if nothing is needed.
			$anvil->Database->configure_pgsql({debug => $debug, uuid => $uuid});
		}
		elsif (not $anvil->data->{sys}{database}{read_uuid})
		{
			$anvil->data->{sys}{database}{read_uuid} = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid} }});
		}
		
		# If this isn't a local database, read the target's Anvil! version (if available) and make 
		# sure it matches ours. If it doesn't, skip this database.
		if (not $is_local)
		{
			my $remote_version = $anvil->Get->anvil_version({
				debug    => $debug, 
				target   => $host,
				password => $password,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				remote_version          => $remote_version, 
				"anvil->_anvil_version" => $anvil->_anvil_version,
			}});
			
			if ($remote_version ne $anvil->_anvil_version({debug => $debug}))
			{
				# Version doesn't match, 
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0145", variables => { 
					host           => $host,
					local_version  => $anvil->_anvil_version, 
					target_version => $remote_version,
				}});
				next;
			}
		}
		
		# Connect!
		my $dbh = "";
		### NOTE: The Database->write() method, when passed an array, will automatically disable 
		###       autocommit, do the bulk write, then commit when done.
		# We connect with fatal errors, autocommit and UTF8 enabled.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			db_connect_string => $db_connect_string, 
			user              => $user, 
		}});
		eval { $dbh = DBI->connect($db_connect_string, $user, $password, {
			RaiseError     => 1,
			AutoCommit     => 1,
			pg_enable_utf8 => 1
		}); };
		if ($@)
		{
			# Something went wrong...
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0064", variables => { 
				uuid => $uuid,
				host => $host,
				name => $name,
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
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => $message_key, variables => $variables });
		}
		elsif ($dbh =~ /^DBI::db=HASH/)
		{
			# Woot!
			$anvil->data->{sys}{database}{connections}++;
			push @{$successful_connections}, $uuid;
			$anvil->data->{cache}{database_handle}{$uuid} = $dbh;
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0071", variables => { 
				host => $host,
				port => $port,
				name => $name,
				uuid => $uuid,
			}});
			
			if (not $anvil->data->{sys}{database}{use_handle})
			{
				$anvil->data->{sys}{database}{use_handle} = $dbh;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::database::use_handle' => $anvil->data->{sys}{database}{use_handle} }});
			}
			
			# If the '$test_table' isn't the same as 'sys::database::test_table', see if the core schema needs loading first.
			if ($test_table ne $anvil->data->{sys}{database}{test_table})
			{
				my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{defaults}{sql}{test_table})." AND schemaname='public';";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				my $count = $anvil->Database->query({uuid => $uuid, debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
				
				if ($count < 1)
				{
					### TODO: Create a version file/flag and don't sync with peers unless
					###       they are the same version. Back-port this to v2.
					# Need to load the database.
					$anvil->Database->initialize({debug => $debug, uuid => $uuid, sql_file => $anvil->data->{path}{sql}{'anvil.sql'}});
				}
			}
			
			# Now that I have connected, see if my 'hosts' table exists.
			my $query = "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE tablename=".$anvil->data->{sys}{database}{use_handle}->quote($test_table)." AND schemaname='public';";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $count = $anvil->Database->query({uuid => $uuid, debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
			if ($count < 1)
			{
				# Need to load the database.
				$anvil->Database->initialize({debug => $debug, uuid => $uuid, sql_file => $sql_file});
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::read_uuid"        => $anvil->data->{sys}{database}{read_uuid}, 
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
			}});
			
			# Set the first ID to be the one I read from later. Alternatively, if this host is 
			# local, use it.
			if (($host eq $anvil->_hostname)       or 
			    ($host eq $anvil->_short_hostname) or 
			    ($host eq "localhost")             or 
			    ($host eq "127.0.0.1")             or 
			    (not $anvil->data->{sys}{database}{read_uuid}))
			{
				$anvil->data->{sys}{database}{read_uuid}  = $uuid;
				$anvil->data->{sys}{database}{local_uuid} = $uuid;
				$anvil->data->{sys}{database}{use_handle} = $anvil->data->{cache}{database_handle}{$uuid};
				
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::read_uuid"  => $anvil->data->{sys}{database}{read_uuid}, 
					"sys::database::use_handle" => $anvil->data->{sys}{database}{use_handle}
				}});
			}
			
			# Get a time stamp for this run, if not yet gotten.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
				"sys::database::timestamp"        => $anvil->data->{sys}{database}{timestamp},
			}});
			
			# Pick a timestamp for this run, if we haven't yet.
			if (not $anvil->data->{sys}{database}{timestamp})
			{
				my $query = "SELECT cast(now() AS timestamp with time zone)::timestamptz(0);";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				$anvil->data->{sys}{database}{timestamp} = $anvil->Database->query({uuid => $uuid, debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::timestamp" => $anvil->data->{sys}{database}{timestamp} }});
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::read_uuid"  => $anvil->data->{sys}{database}{read_uuid},
				"sys::database::use_handle" => $anvil->data->{sys}{database}{use_handle},
				"sys::database::timestamp"  => $anvil->data->{sys}{database}{timestamp},
			}});
		}
	}
	
	my $total = tv_interval ($start_time, [gettimeofday]);
	#print "Total runtime: [".$total."]\n";
	
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
			"database::${uuid}::password" => $anvil->Log->secure ? $anvil->data->{database}{$uuid}{password} : $anvil->Words->string({key => "log_0186"}), 
		}});
		
		# Copy my alert hash before I delete the uuid.
		my $error_array = [];
		
		# Delete this DB so that we don't try to use it later. This is a quiet alert because the 
		# original connection error was likely logged.
		my $say_server = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, priority => "alert", key => "log_0092", variables => { server => $say_server, uuid => $uuid }});
		
		# Delete it from the list of known databases for this run.
		delete $anvil->data->{database}{$uuid};
		
		# If I've not sent an alert about this DB loss before, send one now.
		my $set = $anvil->Alert->check_alert_sent({
			debug          => $debug, 
			type           => "set",
			set_by         => $THIS_FILE,
			record_locator => $uuid,
			name           => "connect_to_db",
			modified_date  => $anvil->data->{sys}{database}{timestamp},
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
		
		if ($set)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error_array => $error_array }});
			foreach my $hash (@{$error_array})
			{
				my $message_key       = $hash->{message_key};
				my $message_variables = $hash->{message_variables};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					hash              => $hash, 
					message_key       => $message_key, 
					message_variables => $message_variables, 
				}});
				
				# These are warning level alerts.
				$anvil->Alert->register_alert({
					debug                   => $debug, 
					alert_level             => "warning", 
					alert_set_by            => $THIS_FILE,
					alert_title_key         => "alert_title_0003",
					alert_message_key       => $message_key,
					alert_message_variables => $message_variables,
				});
			}
		}
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
			"database::${uuid}::password" => $anvil->Log->secure ? $anvil->data->{database}{$uuid}{password} : $anvil->Words->string({key => "log_0186"}), 
		}});
		
		### TODO: Is this still an issue? If so, then we either need to require that the DB host 
		###       matches the actual hostname (dumb) or find another way of mapping the host name.
		# Query to see if the newly connected host is in the DB yet. If it isn't, don't send an
		# alert as it'd cause a duplicate UUID error.
# 		my $query = "SELECT COUNT(*) FROM hosts WHERE host_name = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{database}{$uuid}{host}).";";
# 		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
# 
# 		my $count = $anvil->Database->query({uuid => $uuid, debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
# 		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
# 		
# 		if ($count > 0)
# 		{
			my $cleared = $anvil->Alert->check_alert_sent({
				debug          => $debug, 
				type           => "clear",
				set_by         => $THIS_FILE,
				record_locator => $uuid,
				name           => "connect_to_db",
				modified_date  => $anvil->data->{sys}{database}{timestamp},
			});
			if ($cleared)
			{
				$anvil->Alert->register_alert({
					debug             => $debug, 
					level             => "warning", 
					agent_name        => "Anvil!",
					title_key         => "an_title_0006",
					message_key       => "cleared_log_0055",
					message_variables => {
						name => $database_name,
						host => $anvil->data->{database}{$uuid}{host},
						port => defined $anvil->data->{database}{$uuid}{port} ? $anvil->data->{database}{$uuid}{port} : 5432,
					},
				});
			}
# 		}
	}

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	if ($anvil->data->{sys}{host_uuid} !~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/)
	{
		# derp. bad UUID
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0103"});
		
		# Disconnect and set the connection count to '0'.
		$anvil->Database->disconnect({debug => $debug});
	}
	
	# For now, we just find which DBs are behind and let each agent deal with bringing their tables up to
	# date.
	if ($anvil->data->{sys}{database}{connections} > 1)
	{
		$anvil->Database->_find_behind_databases({
			debug  => $debug, 
			source => $source, 
			tables => $tables,
		});
	}
	
	# Hold if a lock has been requested.
	$anvil->Database->locking({debug => $debug});
	
	# Mark that we're not active.
	$anvil->Database->mark_active({debug => $debug, set => 1});
	
	# Archive old data.
	$anvil->Database->archive_database({debug => $debug});
	
	# Sync the database, if needed.
	$anvil->Database->resync_databases({debug => $debug});
	
	# Add ourselves to the database, if needed.
	$anvil->Database->insert_or_update_hosts({debug => $debug});
	
	return($anvil->data->{sys}{database}{connections});
}

=head2

This cleanly closes any open file handles to all connected databases and clears some internal database related variables.

=cut
sub disconnect
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->disconnect()" }});
	
	my $marked_inactive = 0;
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		# Don't do anything if there isn't an active file handle for this DB.
		next if ((not $anvil->data->{cache}{database_handle}{$uuid}) or ($anvil->data->{cache}{database_handle}{$uuid} !~ /^DBI::db=HASH/));
		
		# Clear locks and mark that we're done running.
		if (not $marked_inactive)
		{
			$anvil->Database->mark_active({set => 0});
			$anvil->Database->locking({release => 1});
			$marked_inactive = 1;
		}
		
		$anvil->data->{cache}{database_handle}{$uuid}->disconnect;
		delete $anvil->data->{cache}{database_handle}{$uuid};
	}
	
	# Delete the stored DB-related values.
	delete $anvil->data->{sys}{database}{timestamp};
	delete $anvil->data->{sys}{database}{use_handle};
	delete $anvil->data->{sys}{database}{read_uuid};
	
	# Set the connection count to 0.
	$anvil->data->{sys}{database}{connections} = 0;
	
	return(0);
}


=head2 get_hosts

Get a list of hosts from the c<< hosts >> table, returned as an array of hash references.

Each anonymous hash is structured as:

 host_uuid     => $host_uuid, 
 host_name     => $host_name, 
 host_type     => $host_type, 
 modified_date => $modified_date, 

It also sets the variables C<< sys::hosts::by_uuid::<host_uuid> = <host_name> >> and C<< sys::hosts::by_name::<host_name> = <host_uuid> >> per host read, for quick reference.

=cut
sub get_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_hosts()" }});
	
	my $query = "
SELECT 
    host_uuid, 
    host_name, 
    host_type, 
    modified_date 
FROM 
    hosts
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
		my $host_uuid     = $row->[0];
		my $host_name     = $row->[1];
		my $host_type     = $row->[2];
		my $modified_date = $row->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_uuid     => $host_uuid, 
			host_name     => $host_name, 
			host_type     => $host_type, 
			modified_date => $modified_date, 
		}});
		push @{$return}, {
			host_uuid     => $host_uuid,
			host_name     => $host_name, 
			host_type     => $host_type, 
			modified_date => $modified_date, 
		};
		
		# Record the host_uuid in a hash so that the name can be easily retrieved.
		$anvil->data->{sys}{hosts}{by_uuid}{$host_uuid} = $host_name;
		$anvil->data->{sys}{hosts}{by_name}{$host_name} = $host_uuid;
	}
	
	return($return);
}

=head2 get_local_uuid

This returns the database UUID (usually the host's UUID) from C<< anvil.conf >> based on matching the C<< database::<uuid>::host >> to the local machine's host name or one of the active IP addresses on the host.

NOTE: This returns nothing if the local machine is not found as a configured database in C<< anvil.conf >>. This is a good way to check if the system has been setup yet.

 # Get the local UUID
 my $local_uuid = $anvil->Database->get_local_uuid;

=cut
sub get_local_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->get_local_uuid()" }});
	
	my $local_uuid      = "";
	my $network_details = $anvil->Get->network_details;
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network_details->hostname" => $network_details->{hostname},
			"database::${uuid}::host"   => $anvil->data->{database}{$uuid}{host},
		}});
		# If the uuid matches our host_uuid or if the hostname matches ours (or is localhost), return
		# that UUID.
		if ($uuid eq $anvil->Get->host_uuid)
		{
			$local_uuid = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
			last;
		}
		elsif (($network_details->{hostname} eq $anvil->data->{database}{$uuid}{host}) or ($anvil->data->{database}{$uuid}{host} eq "localhost"))
		{
			$local_uuid = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
			last;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_uuid => $local_uuid }});
	if (not $local_uuid)
	{
		foreach my $interface (sort {$a cmp $b} keys %{$network_details->{interface}})
		{
			my $ip_address  = $network_details->{interface}{$interface}{ip};
			my $subnet_mask = $network_details->{interface}{$interface}{netmask};
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

=head2 initialize

This will initialize a database using a given file.

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
	my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : $anvil->data->{sys}{database}{name};
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
	my $user = $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : $anvil->data->{sys}{database}{user};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	
	my $sql = $anvil->Storage->read_file({file => $sql_file});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ">> sql" => $sql }});
	
	$sql =~ s/#!variable!user!#/$user/sg;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "<< sql" => $sql }});
	
	# Now that I am ready, disable autocommit, write and commit.
	$anvil->Database->write({
		debug  => 2,
		uuid   => $uuid, 
		query  => $sql, 
		source => $THIS_FILE, 
		line   => __LINE__,
	});
	
	$anvil->data->{sys}{db_initialized}{$uuid} = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::db_initialized::${uuid}" => $anvil->data->{sys}{db_initialized}{$uuid} }});
	
	# Mark that we need to update the DB.
	$anvil->data->{sys}{database}{resync_needed} = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::resync_needed" => $anvil->data->{sys}{database}{resync_needed} }});
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { success => $success }});
	return($success);
};

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

=head2 bridge_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< bridge_name >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head2 bridge_host_uuid (optional)

This is the host that the IP address is on. If not passed, the local C<< sys::host_uuid >> will be used (indicating it is a local IP address).

=head2 bridge_name (required)

This is the bridge's device name.

=head2 bridge_id (optional)

This is the unique identifier for the bridge.

=head2 bridge_stp_enabled (optional)

This is set to C<< yes >> or C<< no >> to indicate if spanning tree protocol is enabled on the switch.

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
	my $bridge_uuid        = defined $parameter->{bridge_uuid}        ? $parameter->{bridge_uuid}        : "";
	my $bridge_host_uuid   = defined $parameter->{bridge_host_uuid}   ? $parameter->{bridge_host_uuid}   : $anvil->data->{sys}{host_uuid};
	my $bridge_name        = defined $parameter->{bridge_name}        ? $parameter->{bridge_name}        : "";
	my $bridge_id          = defined $parameter->{bridge_id}          ? $parameter->{bridge_id}          : "";
	my $bridge_stp_enabled = defined $parameter->{bridge_stp_enabled} ? $parameter->{bridge_stp_enabled} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid               => $uuid, 
		file               => $file, 
		line               => $line, 
		bridge_uuid        => $bridge_uuid, 
		bridge_host_uuid   => $bridge_host_uuid, 
		bridge_name        => $bridge_name, 
		bridge_id          => $bridge_id, 
		bridge_stp_enabled => $bridge_stp_enabled, 
	}});
    
	if (not $bridge_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_bridges()", parameter => "bridge_name" }});
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
    bridge_name      = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_name)." 
AND 
    bridge_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
	
	# If I still don't have an bridge_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_uuid => $bridge_uuid }});
	if (not $bridge_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts();
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
    bridge_name, 
    bridge_id, 
    bridge_stp_enabled, 
    modified_date 
) VALUES (
    ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_id).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_stp_enabled).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    bridge_host_uuid, 
    bridge_name, 
    bridge_id, 
    bridge_stp_enabled 
FROM 
    bridges 
WHERE 
    bridge_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			my $old_bridge_host_uuid   = $row->[0];
			my $old_bridge_name        = $row->[1];
			my $old_bridge_id          = $row->[2];
			my $old_bridge_stp_enabled = $row->[3];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_bridge_host_uuid   => $old_bridge_host_uuid, 
				old_bridge_name        => $old_bridge_name, 
				old_bridge_id          => $old_bridge_id, 
				old_bridge_stp_enabled => $old_bridge_stp_enabled,  
			}});
			
			# Anything change?
			if (($old_bridge_host_uuid   ne $bridge_host_uuid) or 
			    ($old_bridge_name        ne $bridge_name)      or 
			    ($old_bridge_id          ne $bridge_id)        or 
			    ($old_bridge_stp_enabled ne $bridge_stp_enabled))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    bridges 
SET 
    bridge_host_uuid   = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_host_uuid).",  
    bridge_name        = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_name).", 
    bridge_id          = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_id).", 
    bridge_stp_enabled = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_stp_enabled).", 
    modified_date      = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    bridge_uuid        = ".$anvil->data->{sys}{database}{use_handle}->quote($bridge_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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

=head2 bond_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< bond_name >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head2 bond_host_uuid (optional)

This is the host that the IP address is on. If not passed, the local C<< sys::host_uuid >> will be used (indicating it is a local IP address).

=head2 bond_name (required)

This is the bond's device name.

=head2 bond_mode (required)

This is the bonding mode used for this bond. 

=head2 bond_mtu (optional)

This is the MTU for the bonded interface.

=head2 bond_operational (optional)

This is set to C<< up >>, C<< down >> or C<< unknown >>. It indicates whether the bond has a working slaved interface or not.

=head2 bond_primary_slave (optional)

This is the primary interface name in the bond.

=head2 bond_primary_reselect (optional)

This is the primary interface reselect policy.

=head2 bond_active_slave (optional)

This is the interface currently being used by the bond.

=head2 bond_mac_address (optional)

This is the current / active MAC address in use by the bond interface.

=head2 bond_mii_polling_interval (optional)

This is how often, in milliseconds, that the link (mii) status is manually checked.

=head2 bond_up_delay (optional)

This is how long the bond waits, in millisecinds, after an interfaces comes up before considering it for use.

=head2 bond_down_delay (optional)

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
	my $bond_uuid                 = defined $parameter->{bond_uuid}                 ? $parameter->{bond_uuid}                 : "";
	my $bond_host_uuid            = defined $parameter->{bond_host_uuid}            ? $parameter->{bond_host_uuid}            : $anvil->data->{sys}{host_uuid};
	my $bond_name                 = defined $parameter->{bond_name}                 ? $parameter->{bond_name}                 : "";
	my $bond_mode                 = defined $parameter->{bond_mode}                 ? $parameter->{bond_mode}                 : "";
	my $bond_mtu                  = defined $parameter->{bond_mtu}                  ? $parameter->{bond_mtu}                  : "";
	my $bond_primary_slave        = defined $parameter->{bond_primary_slave}        ? $parameter->{bond_primary_slave}        : "";
	my $bond_primary_reselect     = defined $parameter->{bond_primary_reselect}     ? $parameter->{bond_primary_reselect}     : "";
	my $bond_active_slave         = defined $parameter->{bond_active_slave}         ? $parameter->{bond_active_slave}         : "";
	my $bond_mii_polling_interval = defined $parameter->{bond_mii_polling_interval} ? $parameter->{bond_mii_polling_interval} : "";
	my $bond_up_delay             = defined $parameter->{bond_up_delay}             ? $parameter->{bond_up_delay}             : "";
	my $bond_down_delay           = defined $parameter->{bond_down_delay}           ? $parameter->{bond_down_delay}           : "";
	my $bond_mac_address          = defined $parameter->{bond_mac_address}          ? $parameter->{bond_mac_address}          : "";
	my $bond_operational          = defined $parameter->{bond_operational}          ? $parameter->{bond_operational}          : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                      => $uuid, 
		file                      => $file, 
		line                      => $line, 
		bond_uuid                 => $bond_uuid, 
		bond_host_uuid            => $bond_host_uuid, 
		bond_name                 => $bond_name, 
		bond_mode                 => $bond_mode, 
		bond_mtu                  => $bond_mtu, 
		bond_primary_slave        => $bond_primary_slave, 
		bond_primary_reselect     => $bond_primary_reselect, 
		bond_active_slave         => $bond_active_slave, 
		bond_mii_polling_interval => $bond_mii_polling_interval, 
		bond_up_delay             => $bond_up_delay, 
		bond_down_delay           => $bond_down_delay, 
		bond_mac_address          => $bond_mac_address, 
		bond_operational          => $bond_operational, 
	}});
	
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
	
	# If we don't have a UUID, see if we can find one for the given bond server name.
	if (not $bond_uuid)
	{
		my $query = "
SELECT 
    bond_uuid 
FROM 
    bonds 
WHERE 
    bond_name      = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_name)." 
AND 
    bond_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
	
	# If I still don't have an bond_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bond_uuid => $bond_uuid }});
	if (not $bond_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts();
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
    bond_name, 
    bond_mode, 
    bond_mtu, 
    bond_primary_slave, 
    bond_primary_reselect, 
    bond_active_slave, 
    bond_mii_polling_interval, 
    bond_up_delay, 
    bond_down_delay, 
    bond_mac_address, 
    bond_operational, 
    modified_date 
) VALUES (
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mode).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mtu).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_primary_slave).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_primary_reselect).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_active_slave).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mii_polling_interval).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_up_delay).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_down_delay).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mac_address).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($bond_operational).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    bond_host_uuid, 
    bond_name, 
    bond_mode, 
    bond_mtu, 
    bond_primary_slave, 
    bond_primary_reselect, 
    bond_active_slave, 
    bond_mii_polling_interval, 
    bond_up_delay, 
    bond_down_delay, 
    bond_mac_address, 
    bond_operational 
FROM 
    bonds 
WHERE 
    bond_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			my $old_bond_host_uuid            = $row->[0];
			my $old_bond_name                 = $row->[1];
			my $old_bond_mode                 = $row->[2];
			my $old_bond_mtu                  = $row->[3];
			my $old_bond_primary_slave        = $row->[4];
			my $old_bond_primary_reselect     = $row->[5];
			my $old_bond_active_slave         = $row->[6];
			my $old_bond_mii_polling_interval = $row->[7];
			my $old_bond_up_delay             = $row->[8];
			my $old_bond_down_delay           = $row->[9];
			my $old_bond_mac_address          = $row->[10];
			my $old_bond_operational          = $row->[11];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_bond_host_uuid            => $old_bond_host_uuid, 
				old_bond_name                 => $old_bond_name, 
				old_bond_mode                 => $old_bond_mode, 
				old_bond_mtu                  => $old_bond_mtu, 
				old_bond_primary_slave        => $old_bond_primary_slave, 
				old_bond_primary_reselect     => $old_bond_primary_reselect, 
				old_bond_active_slave         => $old_bond_active_slave, 
				old_bond_mii_polling_interval => $old_bond_mii_polling_interval, 
				old_bond_up_delay             => $old_bond_up_delay, 
				old_bond_down_delay           => $old_bond_down_delay, 
				old_bond_mac_address          => $old_bond_mac_address, 
				old_bond_operational          => $old_bond_operational, 
			}});
			
			# Anything change?
			if (($old_bond_host_uuid            ne $bond_host_uuid)            or 
			    ($old_bond_name                 ne $bond_name)                 or 
			    ($old_bond_mode                 ne $bond_mode)                 or 
			    ($old_bond_mtu                  ne $bond_mtu)                  or 
			    ($old_bond_primary_slave        ne $bond_primary_slave)        or 
			    ($old_bond_primary_reselect     ne $bond_primary_reselect)     or 
			    ($old_bond_active_slave         ne $bond_active_slave)         or 
			    ($old_bond_mii_polling_interval ne $bond_mii_polling_interval) or 
			    ($old_bond_up_delay             ne $bond_up_delay)             or 
			    ($old_bond_down_delay           ne $bond_down_delay)           or 
			    ($old_bond_mac_address          ne $bond_mac_address)          or 
			    ($old_bond_operational          ne $bond_operational))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    bonds 
SET 
    bond_host_uuid            = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_host_uuid).",  
    bond_name                 = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_name).", 
    bond_mode                 = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mode).", 
    bond_mtu                  = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mtu).", 
    bond_primary_slave        = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_primary_slave).", 
    bond_primary_reselect     = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_primary_reselect).", 
    bond_active_slave         = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_active_slave).", 
    bond_mii_polling_interval = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mii_polling_interval).", 
    bond_up_delay             = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_up_delay).", 
    bond_down_delay           = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_down_delay).", 
    bond_mac_address          = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_mac_address).", 
    bond_operational          = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_operational).", 
    modified_date             = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    bond_uuid                 = ".$anvil->data->{sys}{database}{use_handle}->quote($bond_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
			}
		}
	}
	
	return($bond_uuid);
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

=head3 host_name (required)

This default value is the local hostname.

=head3 host_type (required)

This default value is the value returned by C<< System->determine_host_type >>.

=head3 host_uuid (required)

The default value is the host's UUID (as returned by C<< Get->host_uuid >>.

=cut
sub insert_or_update_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_hosts()" }});
	
	my $uuid      = defined $parameter->{uuid}      ? $parameter->{uuid}      : "";
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $line      = defined $parameter->{line}      ? $parameter->{line}      : "";
	my $host_name = defined $parameter->{host_name} ? $parameter->{host_name} : $anvil->_hostname;
	my $host_type = defined $parameter->{host_type} ? $parameter->{host_type} : $anvil->System->determine_host_type;
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid      => $uuid, 
		file      => $file, 
		line      => $line, 
		host_name => $host_name, 
		host_type => $host_type, 
		host_uuid => $host_uuid, 
	}});
	
	if (not $host_name)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_hosts()", parameter => "host_name" }});
		return("");
	}
	if (not $host_uuid)
	{
		# Throw an error and exit.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_hosts()", parameter => "host_uuid" }});
		return("");
	}
	
	# Read the old values, if they exist.
	my $old_host_name = "";
	my $old_host_type = "";
	my $query = "
SELECT 
    host_name, 
    host_type  
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($host_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, uuid => $uuid, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		$old_host_name = $row->[0];
		$old_host_type = $row->[1];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			old_host_name => $old_host_name, 
			old_host_type => $old_host_type, 
		}});
	}
	if (not $count)
	{
		# Add this host to the database
		my $query = "
INSERT INTO 
    hosts 
(
    host_uuid, 
    host_name, 
    host_type, 
    modified_date
) VALUES (
    ".$anvil->data->{sys}{database}{use_handle}->quote($host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($host_name).",
    ".$anvil->data->{sys}{database}{use_handle}->quote($host_type).",
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, uuid => $uuid, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	}
	elsif (($old_host_name ne $host_name) or ($old_host_type ne $host_type))
	{
		# Clear the stop data.
		my $query = "
UPDATE 
    hosts
SET 
    host_name     = ".$anvil->data->{sys}{database}{use_handle}->quote($host_name).", 
    host_type     = ".$anvil->data->{sys}{database}{use_handle}->quote($host_type).", 
    modified_date = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
WHERE
    host_uuid     = ".$anvil->data->{sys}{database}{use_handle}->quote($host_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, uuid => $uuid, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0126", variables => { method => "Database->insert_or_update_hosts()" }});
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

=head2 ip_address_uuid (optional)

If not passed, a check will be made to see if an existing entry is found for C<< ip_address_address >>. If found, that entry will be updated. If not found, a new record will be inserted.

=head2 ip_address_host_uuid (optional)

This is the host that the IP address is on. If not passed, the local C<< sys::host_uuid >> will be used (indicating it is a local IP address).

=head2 ip_address_on_type (required)

This indicates what type of interface the IP address is on. This must be either C<< interface >>, C<< bond >> or C<< bridge >>. 

=head2 ip_address_on_uuid (required)

This is the UUID of the bridge, bond or interface that this IP address is on.

=head2 ip_address_address (required)

This is the acual IP address. It's tested with IPv4 addresses in dotted-decimal format, though it can also store IPv6 addresses. If this is set to C<< 0 >>, it will be treated as deleted and will be ignored (unless a new IP is assigned to the same interface in the future).

=head2 ip_address_subnet_mask (required)

This is the subnet mask for the IP address. It is tested with IPv4 in dotted decimal format, though it can also store IPv6 format subnet masks.

=head2 ip_address_default_gateway (optional, default '0')

If a gateway address is set, and this is set to C<< 1 >>, the associated interface will be the default gateway for the host.

=head2 ip_address_gateway (optional)

This is an option gateway IP address for this interface.

=head2 ip_address_dns (optional)

This is a comma-separated list of DNS servers used to resolve host names. This is recorded, but ignored unless C<< ip_address_gateway >> is set. Example format is C<< 8.8.8.8 >> or C<< 8.8.8.8,4.4.4.4 >>.

=cut
sub insert_or_update_ip_addresses
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_ip_addresses()" }});
	
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                       => $uuid, 
		file                       => $file, 
		line                       => $line, 
		ip_address_uuid            => $ip_address_uuid, 
		ip_address_host_uuid       => $ip_address_host_uuid, 
		ip_address_on_type         => $ip_address_on_type, 
		ip_address_on_uuid         => $ip_address_on_uuid, 
		ip_address_address         => $ip_address_address, 
		ip_address_subnet_mask     => $ip_address_subnet_mask, 
		ip_address_gateway         => $ip_address_gateway, 
		ip_address_default_gateway => $ip_address_default_gateway, 
		ip_address_dns             => $ip_address_dns, 
	}});
	
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
	
	# If we don't have a UUID, see if we can find one for the given ip_address server name.
	if (not $ip_address_uuid)
	{
		my $query = "
SELECT 
    ip_address_uuid 
FROM 
    ip_addresses 
WHERE 
    ip_address_address   = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_address)." 
AND 
    ip_address_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
	
	# If I still don't have an ip_address_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip_address_uuid => $ip_address_uuid }});
	if (not $ip_address_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts();
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
    modified_date 
) VALUES (
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_on_type).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_on_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_address).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_subnet_mask).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_gateway).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_default_gateway).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_dns).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
    ip_address_dns 
FROM 
    ip_addresses 
WHERE 
    ip_address_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_ip_address_host_uuid       => $old_ip_address_host_uuid, 
				old_ip_address_on_type         => $old_ip_address_on_type, 
				old_ip_address_on_uuid         => $old_ip_address_on_uuid, 
				old_ip_address_address         => $old_ip_address_address, 
				old_ip_address_subnet_mask     => $old_ip_address_subnet_mask, 
				old_ip_address_gateway         => $old_ip_address_gateway, 
				old_ip_address_default_gateway => $old_ip_address_default_gateway, 
				old_ip_address_dns             => $old_ip_address_dns, 
			}});
			
			# Anything change?
			if (($old_ip_address_host_uuid       ne $ip_address_host_uuid)       or 
			    ($old_ip_address_on_type         ne $ip_address_on_type)         or 
			    ($old_ip_address_on_uuid         ne $ip_address_on_uuid)         or 
			    ($old_ip_address_address         ne $ip_address_address)         or 
			    ($old_ip_address_subnet_mask     ne $ip_address_subnet_mask)     or 
			    ($old_ip_address_gateway         ne $ip_address_gateway)         or 
			    ($old_ip_address_default_gateway ne $ip_address_default_gateway) or 
			    ($old_ip_address_dns             ne $ip_address_dns))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    ip_addresses 
SET 
    ip_address_host_uuid       = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_host_uuid).",  
    ip_address_on_type         = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_on_type).",  
    ip_address_on_uuid         = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_on_uuid).", 
    ip_address_address         = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_address).", 
    ip_address_subnet_mask     = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_subnet_mask).", 
    ip_address_gateway         = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_gateway).", 
    ip_address_default_gateway = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_default_gateway).", 
    ip_address_dns             = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_dns).", 
    modified_date              = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    ip_address_uuid            = ".$anvil->data->{sys}{database}{use_handle}->quote($ip_address_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
			}
		}
	}
	
	return($ip_address_uuid);
}


=head2 insert_or_update_jobs

This updates (or inserts) a record in the 'jobs' table. The C<< job_uuid >> referencing the database row will be returned.

If there is an error, an empty string is returned.

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

=head3 job_uuid (optional)

This is the C<< job_uuid >> to update. If it is not specified but the C<< job_name >> is, a check will be made to see if an entry already exists. If so, that row will be UPDATEd. If not, a random UUID will be generated and a new entry will be INSERTed.

* This or C<< job_name >> must be passed

=head3 update_progress_only (optional)

When set, the progress percentage and, optionally, the C<< job_data >>, will be updated only.

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
	my $job_updated          = defined $parameter->{job_updated}          ? $parameter->{job_updated}          : 0;
	my $job_name             = defined $parameter->{job_name}             ? $parameter->{job_name}             : "";
	my $job_progress         = defined $parameter->{job_progress}         ? $parameter->{job_progress}         : 0;
	my $job_title            = defined $parameter->{job_title}            ? $parameter->{job_title}            : "";
	my $job_description      = defined $parameter->{job_description}      ? $parameter->{job_description}      : "";
	my $job_status           = defined $parameter->{job_status}           ? $parameter->{job_status}           : "";
	my $update_progress_only = defined $parameter->{update_progress_only} ? $parameter->{update_progress_only} : 0;
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
	if ((not $anvil->Validate->is_uuid({uuid => $job_uuid})) && (not $job_name))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0136", variables => { 
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
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_command" }});
			$problem = 1;
		}
		
		# Job name?
		if (not $job_name)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_name" }});
			$problem = 1;
		}
		
		# Job name?
		if (not $job_title)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_title" }});
			$problem = 1;
		}
		
		# Job description?
		if (not $job_description)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->insert_or_update_jobs()", parameter => "job_description" }});
			$problem = 1;
		}
	}
	
	# We're done if there was a problem
	if ($problem)
	{
		return("");
	}
	
	# If we don't have a UUID, see if we can find one for the given job server name.
	if (not $job_uuid)
	{
		my $query = "
SELECT 
    job_uuid 
FROM 
    jobs 
WHERE 
    job_name      = ".$anvil->data->{sys}{database}{use_handle}->quote($job_name)." 
AND 
    job_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($job_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
	
	# If I still don't have an job_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	if (not $job_uuid)
	{
		# It's possible that this is called before the host is recorded in the database. So to be
		# safe, we'll return without doing anything if there is no host_uuid in the database.
		my $hosts = $anvil->Database->get_hosts();
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
		   $job_uuid = $anvil->Get->uuid();
		my $query      = "
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
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_command).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_data).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_picked_up_by).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_picked_up_at).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_updated).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_progress).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_title).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_description).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($job_status).", 
   ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
    job_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
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
				if ($old_job_progress ne $job_progress)
				{
					# Something changed, save.
					my $query = "
UPDATE 
    jobs 
SET 
    job_progress  = ".$anvil->data->{sys}{database}{use_handle}->quote($job_progress).", 
    modified_date = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    job_uuid      = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)." 
";
					if ($job_status)
					{
						$query = "
UPDATE 
    jobs 
SET 
    job_progress  = ".$anvil->data->{sys}{database}{use_handle}->quote($job_progress).", 
    job_status    = ".$anvil->data->{sys}{database}{use_handle}->quote($job_status).", 
    modified_date = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    job_uuid      = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)." 
";
					}
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
					# Something changed, save.
					my $query = "
UPDATE 
    jobs 
SET 
    job_host_uuid    = ".$anvil->data->{sys}{database}{use_handle}->quote($job_host_uuid).",  
    job_command      = ".$anvil->data->{sys}{database}{use_handle}->quote($job_command).", 
    job_data         = ".$anvil->data->{sys}{database}{use_handle}->quote($job_data).", 
    job_picked_up_by = ".$anvil->data->{sys}{database}{use_handle}->quote($job_picked_up_by).", 
    job_picked_up_at = ".$anvil->data->{sys}{database}{use_handle}->quote($job_picked_up_at).", 
    job_updated      = ".$anvil->data->{sys}{database}{use_handle}->quote($job_updated).", 
    job_name         = ".$anvil->data->{sys}{database}{use_handle}->quote($job_name).", 
    job_progress     = ".$anvil->data->{sys}{database}{use_handle}->quote($job_progress).", 
    job_title        = ".$anvil->data->{sys}{database}{use_handle}->quote($job_title).", 
    job_description  = ".$anvil->data->{sys}{database}{use_handle}->quote($job_description).", 
    job_status       = ".$anvil->data->{sys}{database}{use_handle}->quote($job_status).", 
    modified_date    = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    job_uuid         = ".$anvil->data->{sys}{database}{use_handle}->quote($job_uuid)." 
";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
					$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
				}
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
	return($job_uuid);
}


=head2 insert_or_update_network_interfaces

This updates (or inserts) a record in the 'interfaces' table. This table is used to store physical network interface information.

If there is an error, an empty string is returned. Otherwise, the record's UUID is returned.

Parameters;

=head3 uuid (optional)

If set, only the corresponding database will be written to.

=head3 file (optional)

If set, this is the file name logged as the source of any INSERTs or UPDATEs.

=head3 line (optional)

If set, this is the file line number logged as the source of any INSERTs or UPDATEs.

=head3 network_interface_bond_uuid (optional)

If this interface is part of a bond, this UUID will be the C<< bonds >> -> C<< bond_uuid >> that this interface is slaved to.

=head3 network_interface_bridge_uuid (optional)

If this interface is connected to a bridge, this is the C<< bridges >> -> C<< bridge_uuid >> of that bridge.

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

This is the current device name for this interface.

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
	
	my $uuid                          = defined $parameter->{uuid}                          ? $parameter->{uuid}                          : "";
	my $file                          = defined $parameter->{file}                          ? $parameter->{file}                          : "";
	my $line                          = defined $parameter->{line}                          ? $parameter->{line}                          : "";
	my $network_interface_bond_uuid   =         $parameter->{network_interface_bond_uuid}   ? $parameter->{network_interface_bond_uuid}   : 'NULL';
	my $network_interface_bridge_uuid =         $parameter->{network_interface_bridge_uuid} ? $parameter->{network_interface_bridge_uuid} : 'NULL';
	my $network_interface_duplex      = defined $parameter->{network_interface_duplex}      ? $parameter->{network_interface_duplex}      : "unknown";
	my $network_interface_host_uuid   = defined $parameter->{network_interface_host_uuid}   ? $parameter->{network_interface_host_uuid}   : $anvil->Get->host_uuid;
	my $network_interface_link_state  = defined $parameter->{network_interface_link_state}  ? $parameter->{network_interface_link_state}  : "unknown";
	my $network_interface_operational = defined $parameter->{network_interface_operational} ? $parameter->{network_interface_operational} : "unknown";
	my $network_interface_mac_address = defined $parameter->{network_interface_mac_address} ? $parameter->{network_interface_mac_address} : "";
	my $network_interface_medium      = defined $parameter->{network_interface_medium}      ? $parameter->{network_interface_medium}      : "";
	my $network_interface_mtu         = defined $parameter->{network_interface_mtu}         ? $parameter->{network_interface_mtu}         : 0;
	my $network_interface_name        = defined $parameter->{network_interface_name}        ? $parameter->{network_interface_name}        : "";
	my $network_interface_speed       = defined $parameter->{network_interface_speed}       ? $parameter->{network_interface_speed}       : 0;
	my $network_interface_uuid        = defined $parameter->{network_interface_uuid}        ? $parameter->{interface_uuid}                : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                          => $uuid, 
		file                          => $file, 
		line                          => $line, 
		network_interface_bond_uuid   => $network_interface_bond_uuid, 
		network_interface_bridge_uuid => $network_interface_bridge_uuid, 
		network_interface_duplex      => $network_interface_duplex, 
		network_interface_host_uuid   => $network_interface_host_uuid, 
		network_interface_link_state  => $network_interface_link_state, 
		network_interface_operational => $network_interface_operational, 
		network_interface_mac_address => $network_interface_mac_address, 
		network_interface_medium      => $network_interface_medium, 
		network_interface_mtu         => $network_interface_mtu, 
		network_interface_name        => $network_interface_name,
		network_interface_speed       => $network_interface_speed, 
		network_interface_uuid        => $network_interface_uuid,
	}});
	
	# INSERT, but make sure we have enough data first.
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
	if (($network_interface_bond_uuid ne 'NULL') && (not $anvil->Validate->is_uuid({uuid => $network_interface_bond_uuid})))
	{
		# Bad UUID.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0130", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_bond_uuid", uuid => $network_interface_bond_uuid }});
		return("");
	}
	if (($network_interface_bridge_uuid ne 'NULL') && (not $anvil->Validate->is_uuid({uuid => $network_interface_bridge_uuid})))
	{
		# Bad UUID.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0130", variables => { method => "Database->insert_or_update_network_interfaces()", parameter => "network_interface_bridge_uuid", uuid => $network_interface_bridge_uuid }});
		return("");
	}
	
	# If we don't have a network interface UUID, try to look one up using the MAC address
	if (not $network_interface_uuid)
	{
		# See if I know this NIC by referencing it's MAC.
		my $query = "SELECT network_interface_uuid FROM network_interfaces WHERE network_interface_mac_address = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_mac_address).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$network_interface_uuid = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__})->[0]->[0];
		$network_interface_uuid = "" if not defined $network_interface_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_interface_uuid => $network_interface_uuid }});
	}
	
	# Now, if we're inserting or updating, we'll need to require different bits.
	if ($network_interface_uuid)
	{
		# Update
		my $query = "
SELECT 
    network_interface_host_uuid, 
    network_interface_mac_address, 
    network_interface_name,
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
    network_interface_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_uuid).";
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, uuid => $uuid, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			my $old_network_interface_host_uuid   =         $row->[0];
			my $old_network_interface_mac_address =         $row->[1];
			my $old_network_interface_name        =         $row->[2];
			my $old_network_interface_speed       =         $row->[3];
			my $old_network_interface_mtu         =         $row->[4];
			my $old_network_interface_link_state  =         $row->[5];
			my $old_network_interface_operational =         $row->[6];
			my $old_network_interface_duplex      =         $row->[7];
			my $old_network_interface_medium      =         $row->[8];
			my $old_network_interface_bond_uuid   = defined $row->[9]  ? $row->[9]  : 'NULL';
			my $old_network_interface_bridge_uuid = defined $row->[10] ? $row->[10] : 'NULL';
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_network_interface_host_uuid   => $old_network_interface_host_uuid,
				old_network_interface_mac_address => $old_network_interface_mac_address,
				old_network_interface_name        => $old_network_interface_name,
				old_network_interface_speed       => $old_network_interface_speed,
				old_network_interface_mtu         => $old_network_interface_mtu,
				old_network_interface_link_state  => $old_network_interface_link_state,
				old_network_interface_operational => $old_network_interface_operational, 
				old_network_interface_duplex      => $old_network_interface_duplex,
				old_network_interface_medium      => $old_network_interface_medium,
				old_network_interface_bond_uuid   => $old_network_interface_bond_uuid,
				old_network_interface_bridge_uuid => $old_network_interface_bridge_uuid,
			}});
			
			# If the caller didn't pass some values, we'll treat the 
			
			# Anything to update? This is a little extra complicated because if a variable was
			# not passed in, we want to not compare it.
			if (($network_interface_bond_uuid   ne $old_network_interface_bond_uuid)   or 
			    ($network_interface_bridge_uuid ne $old_network_interface_bridge_uuid) or 
			    ($network_interface_name        ne $old_network_interface_name)        or 
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
    network_interface_host_uuid   = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_host_uuid).", 
    network_interface_bond_uuid   = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_bond_uuid).", 
    network_interface_bridge_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_bridge_uuid).", 
    network_interface_name        = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_name).", 
    network_interface_duplex      = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_duplex).", 
    network_interface_link_state  = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_link_state).", 
    network_interface_operational = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_operational).", 
    network_interface_mac_address = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_mac_address).", 
    network_interface_medium      = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_medium).", 
    network_interface_mtu         = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_mtu).", 
    network_interface_speed       = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_speed).", 
    modified_date                 = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE
    network_interface_uuid        = ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_uuid)."
;";
				$query =~ s/'NULL'/NULL/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, uuid => $uuid, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
    network_interface_bond_uuid, 
    network_interface_bridge_uuid, 
    network_interface_name, 
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
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_uuid).",  
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_bond_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_bridge_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_duplex).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_link_state).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_operational).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_mac_address).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_medium).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_mtu).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($network_interface_speed).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$query =~ s/'NULL'/NULL/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, uuid => $uuid, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0126", variables => { method => "Database->insert_or_update_network_interfaces()" }});
	return($network_interface_uuid);
}


=head2 insert_or_update_states

This updates (or inserts) a record in the 'states' table. The C<< state_uuid >> referencing the database row will be returned.

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
	
	# If we don't have a UUID, see if we can find one for the given state server name.
	if (not $state_uuid)
	{
		my $query = "
SELECT 
    state_uuid 
FROM 
    states 
WHERE 
    state_name      = ".$anvil->data->{sys}{database}{use_handle}->quote($state_name)." 
AND 
    state_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($state_host_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
		my $hosts = $anvil->Database->get_hosts();
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
    ".$anvil->data->{sys}{database}{use_handle}->quote($state_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($state_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($state_host_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($state_note).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
	}
	else
	{
		# Query the rest of the values and see if anything changed.
		my $query = "
SELECT 
    state_name,
    state_host_uuid, 
    state_note 
FROM 
    states 
WHERE 
    state_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($state_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		foreach my $row (@{$results})
		{
			my $old_state_name         = $row->[0];
			my $old_state_host_uuid    = $row->[1];
			my $old_state_note         = $row->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_state_name      => $old_state_name, 
				old_state_host_uuid => $old_state_host_uuid, 
				old_state_note      => $old_state_note, 
			}});
			
			# Anything change?
			if (($old_state_name      ne $state_name)      or 
			    ($old_state_host_uuid ne $state_host_uuid) or 
			    ($old_state_note      ne $state_note))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    states 
SET 
    state_name       = ".$anvil->data->{sys}{database}{use_handle}->quote($state_name).", 
    state_host_uuid  = ".$anvil->data->{sys}{database}{use_handle}->quote($state_host_uuid).",  
    state_note       = ".$anvil->data->{sys}{database}{use_handle}->quote($state_note).", 
    modified_date    = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    state_uuid       = ".$anvil->data->{sys}{database}{use_handle}->quote($state_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
	return($state_uuid);
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->insert_or_update_states()" }});
	
	my $uuid                = defined $parameter->{uuid}                ? $parameter->{uuid}                : "";
	my $file                = defined $parameter->{file}                ? $parameter->{file}                : "";
	my $line                = defined $parameter->{line}                ? $parameter->{line}                : "";
	my $user_uuid           = defined $parameter->{user_uuid}           ? $parameter->{user_uuid}           : "";
	my $user_name           = defined $parameter->{user_name}           ? $parameter->{user_name}           : "";
	my $user_password_hash  = defined $parameter->{user_password_hash}  ? $parameter->{user_password_hash}  : "";
	my $user_salt           = defined $parameter->{user_salt}           ? $parameter->{user_salt}           : "";
	my $user_session_salt   = defined $parameter->{user_session_salt}   ? $parameter->{user_session_salt}   : "";
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
		user_password_hash  => (($anvil->Log->secure) or ($user_salt)) ? $user_password_hash : $anvil->Words->string({key => "log_0186"}) , 
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
			user_password_hash => (($anvil->Log->secure) or ($user_salt)) ? $user_password_hash : $anvil->Words->string({key => "log_0186"}) , 
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
    user_name = ".$anvil->data->{sys}{database}{use_handle}->quote($user_name)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
		my $hosts = $anvil->Database->get_hosts();
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
    user_session_salt, 
    modified_date 
) VALUES (
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_password_hash).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_salt).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_algorithm).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_hash_count).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_language).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_is_admin).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_is_experienced).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_is_trusted).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($user_session_salt).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
    user_is_trusted, 
    user_session_salt 
FROM 
    users 
WHERE 
    user_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($user_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
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
			my $old_user_session_salt   = $row->[9];
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
				old_user_session_salt   => $old_user_session_salt
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
			    ($old_user_is_trusted     ne $user_is_trusted)     or 
			    ($old_user_session_salt   ne $user_session_salt))
			{
				# Something changed, save.
				my $query = "
UPDATE 
    users 
SET 
    user_name           = ".$anvil->data->{sys}{database}{use_handle}->quote($user_name).", 
    user_password_hash  = ".$anvil->data->{sys}{database}{use_handle}->quote($user_password_hash).",  
    user_salt           = ".$anvil->data->{sys}{database}{use_handle}->quote($user_salt).",  
    user_algorithm      = ".$anvil->data->{sys}{database}{use_handle}->quote($user_algorithm).",  
    user_hash_count     = ".$anvil->data->{sys}{database}{use_handle}->quote($user_hash_count).",  
    user_language       = ".$anvil->data->{sys}{database}{use_handle}->quote($user_language).",  
    user_is_admin       = ".$anvil->data->{sys}{database}{use_handle}->quote($user_is_admin).", 
    user_is_experienced = ".$anvil->data->{sys}{database}{use_handle}->quote($user_is_experienced).", 
    user_is_trusted     = ".$anvil->data->{sys}{database}{use_handle}->quote($user_is_trusted).", 
    user_session_salt   = ".$anvil->data->{sys}{database}{use_handle}->quote($user_session_salt).", 
    modified_date       = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    user_uuid           = ".$anvil->data->{sys}{database}{use_handle}->quote($user_uuid)." 
";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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

=head3 update_value_only (optional)

When set to C<< 1 >>, this method will only update the variable's C<< variable_value >> column. Any other parameters are used to help locate the variable to update only.

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
	my $variable_source_uuid  = defined $parameter->{variable_source_uuid}  ? $parameter->{variable_source_uuid}  : "";
	my $variable_source_table = defined $parameter->{variable_source_table} ? $parameter->{variable_source_table} : "";
	my $update_value_only     = defined $parameter->{update_value_only}     ? $parameter->{update_value_only}     : 1;
	my $log_level             = defined $parameter->{log_level}             ? $parameter->{log_level}             : 3;	# Undocumented for now.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
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
		log_level             => $log_level, 
	}});
	
	# We'll need either the name or UUID.
	if ((not $variable_name) && (not $variable_uuid))
	{
		# Neither given, throw an error and return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0037"});
		return("!!error!!");
	}
	
	# If we have a variable UUID but not a name, read the variable name. If we don't have a UUID, see if
	# we can find one for the given variable name.
	if (($anvil->Validate->is_uuid({uuid => $variable_uuid})) && (not $variable_name))
	{
		my $query = "
SELECT 
    variable_name 
FROM 
    variables 
WHERE 
    variable_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
		
		$variable_name = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__})->[0]->[0];
		$variable_name = "" if not defined $variable_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { variable_name => $variable_name }});
	}
	
	if (($variable_name) && (not $variable_uuid))
	{
		my $query = "
SELECT 
    variable_uuid 
FROM 
    variables 
WHERE 
    variable_name = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_name);
		if (($variable_source_uuid ne "") && ($variable_source_table ne ""))
		{
			$query .= "
AND 
    variable_source_uuid  = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_table)." 
";
		}
		$query .= ";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
			results => $results, 
			count   => $count,
		}});
		foreach my $row (@{$results})
		{
			$variable_uuid = $row->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { variable_uuid => $variable_uuid }});
		}
	}
	
	# If I still don't have an variable_uuid, we're INSERT'ing .
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { variable_uuid => $variable_uuid }});
	if (not $variable_uuid)
	{
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
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_value).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_default).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_description).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_section).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_table).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
		
		$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
    variable_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid);
			if (($variable_source_uuid ne "") && ($variable_source_table ne ""))
			{
				$query .= "
AND 
    variable_source_uuid  = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_table)." 
";
			}
			$query .= ";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
			
			my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
				results => $results, 
				count   => $count,
			}});
			foreach my $row (@{$results})
			{
				my $old_variable_value = $row->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { old_variable_value => $old_variable_value }});
				
				# Anything change?
				if ($old_variable_value ne $variable_value)
				{
					# Variable changed, save.
					my $query = "
UPDATE 
    variables 
SET 
    variable_value = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_value).", 
    modified_date  = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    variable_uuid  = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid);
					if (($variable_source_uuid ne "") && ($variable_source_table ne ""))
					{
						$query .= "
AND 
    variable_source_uuid  = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_table)." 
";
					}
					$query .= ";";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
					
					$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
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
    variable_section 
FROM 
    variables 
WHERE 
    variable_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid)." 
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
			
			my $results = $anvil->Database->query({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
				results => $results, 
				count   => $count,
			}});
			foreach my $row (@{$results})
			{
				my $old_variable_name        = $row->[0];
				my $old_variable_value       = $row->[1];
				my $old_variable_default     = $row->[2];
				my $old_variable_description = $row->[3];
				my $old_variable_section     = $row->[4];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
					old_variable_name        => $old_variable_name, 
					old_variable_value       => $old_variable_value, 
					old_variable_default     => $old_variable_default, 
					old_variable_description => $old_variable_description, 
					old_variable_section     => $old_variable_section, 
				}});
				
				# Anything change?
				if (($old_variable_name        ne $variable_name)        or 
				    ($old_variable_value       ne $variable_value)       or 
				    ($old_variable_default     ne $variable_default)     or 
				    ($old_variable_description ne $variable_description) or 
				    ($old_variable_section     ne $variable_section))
				{
					# Something changed, save.
					my $query = "
UPDATE 
    variables 
SET 
    variable_name        = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_name).", 
    variable_value       = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_value).", 
    variable_default     = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_default).", 
    variable_description = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_description).", 
    variable_section     = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_section).", 
    modified_date        = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})." 
WHERE 
    variable_uuid        = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid)." 
";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { query => $query }});
					
					$anvil->Database->write({query => $query, source => $file ? $file : $THIS_FILE, line => $line ? $line : __LINE__});
				}
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { variable_uuid => $variable_uuid }});
	return($variable_uuid);
}

=head2 lock_file

This reads, sets or updates the database lock file timestamp.

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
	
	my $request     = defined $parameter->{request}     ? $parameter->{request}     : 0;
	my $release     = defined $parameter->{release}     ? $parameter->{release}     : 0;
	my $renew       = defined $parameter->{renew}       ? $parameter->{renew}       : 0;
	my $check       = defined $parameter->{check}       ? $parameter->{check}       : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		request => $request, 
		release => $release, 
		renew   => $renew, 
		check   => $check, 
	}});
	
	# These are used to ID this lock.
	my $source_name = $anvil->_hostname;
	my $source_uuid = $anvil->data->{sys}{host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		source_name => $source_name, 
		source_uuid => $source_uuid, 
	}});
	
	my $set            = 0;
	my $variable_name  = "lock_request";
	my $variable_value = $source_name."::".$source_uuid."::".time;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		variable_name  => $variable_name, 
		variable_value => $variable_value, 
	}});
	
	# Make sure we have a sane lock age
	if ((not defined $anvil->data->{database}{locking}{reap_age}) or 
	    (not $anvil->data->{database}{locking}{reap_age})         or 
	    ($anvil->data->{database}{locking}{reap_age} =~ /\D/)
	)
	{
		$anvil->data->{database}{locking}{reap_age} = $anvil->data->{defaults}{database}{locking}{reap_age};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "database::locking::reap_age" => $anvil->data->{database}{locking}{reap_age} }});
	}
	
	# If I have been asked to check, we will return the variable_uuid if a lock is set.
	if ($check)
	{
		my ($lock_value, $variable_uuid, $modified_date) = $anvil->Database->read_variable({variable_name => $variable_name});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			lock_value    => $lock_value, 
			variable_uuid => $variable_uuid, 
			modified_date => $modified_date, 
		}});
		
		return($lock_value);
	}
	
	# If I've been asked to clear a lock, do so now.
	if ($release)
	{
		# We check to see if there is a lock before we clear it. This way we don't log that we 
		# released a lock unless we really released a lock.
		my ($lock_value, $variable_uuid, $modified_date) = $anvil->Database->read_variable({variable_name => $variable_name});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			lock_value    => $lock_value, 
			variable_uuid => $variable_uuid, 
			modified_date => $modified_date, 
		}});
		
		if ($lock_value)
		{
			my $variable_uuid = $anvil->Database->insert_or_update_variables({
				variable_name     => $variable_name,
				variable_value    => "",
				update_value_only => 1,
			});
			$anvil->data->{sys}{database}{local_lock_active} = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				variable_uuid            => $variable_uuid, 
				"sys::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active}, 
			}});
			
			# Log that the lock has been released.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0039", variables => { host => $anvil->_hostname }});
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
		return($set);
	}
	
	# If I've been asked to renew, do so now.
	if ($renew)
	{
		# Yup, do it.
		my $variable_uuid = $anvil->Database->insert_or_update_variables({
			variable_name     => $variable_name,
			variable_value    => $variable_value,
			update_value_only => 1,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
		
		if ($variable_uuid)
		{
			$set = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
		}
		$anvil->data->{sys}{database}{local_lock_active} = time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			variable_uuid            => $variable_uuid, 
			"sys::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active}, 
		}});
		
		# Log that we've renewed the lock.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0044", variables => { host => $anvil->_hostname }});
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
		return($set);
	}
	
	# We always check for, and then wait for, locks. Read in the locks, if any. If any are set and they are 
	# younger than database::locking::reap_age, we'll hold.
	my $waiting = 1;
	while ($waiting)
	{
		# Set the 'waiting' to '0'. If we find a lock, we'll set it back to '1'.
		$waiting = 0;
		
		# See if we had a lock.
		my ($lock_value, $variable_uuid, $modified_date) = $anvil->Database->read_variable({variable_name => $variable_name});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			waiting       => $waiting, 
			lock_value    => $lock_value, 
			variable_uuid => $variable_uuid, 
			modified_date => $modified_date, 
		}});
		if ($lock_value =~ /^(.*?)::(.*?)::(\d+)/)
		{
			my $lock_source_name = $1;
			my $lock_source_uuid = $2;
			my $lock_time        = $3;
			my $current_time     = time;
			my $timeout_time     = $lock_time + $anvil->data->{database}{locking}{reap_age};
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
				# The lock is stale.
				my $variable_uuid = $anvil->Database->insert_or_update_variables({
					variable_name     => $variable_name,
					variable_value    => "",
					update_value_only => 1,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
			}
			# Only wait if this isn't our own lock.
			elsif ($lock_source_uuid ne $source_uuid)
			{
				# Mark 'wait', set inactive and sleep.
				$anvil->Database->mark_active({set => 0});
				
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
		my $variable_uuid = $anvil->Database->insert_or_update_variables({
			variable_name     => $variable_name,
			variable_value    => $variable_value,
			update_value_only => 1,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
		
		if ($variable_uuid)
		{
			$set = 1;
			$anvil->data->{sys}{database}{local_lock_active} = time;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				set                      => $set, 
				variable_uuid            => $variable_uuid, 
				"sys::local_lock_active" => $anvil->data->{sys}{database}{local_lock_active}, 
			}});
			
			# Log that we've got the lock.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0045", variables => { host => $anvil->_hostname }});
		}
	}
	
	# Now return.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
	return($set);
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
	
	my $value = "false";
	if ($set)
	{
		$value = "true";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
	
	my $state_uuid = $anvil->Database->insert_or_update_states({
		state_name      => "db_in_use",
		state_host_uuid => $anvil->data->{sys}{host_uuid},
		state_note      => $value,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
	
	return($state_uuid);
}

=head2 query

This performs a query and returns an array reference of array references (from C<< DBO->fetchall_arrayref >>). The first array contains all the returned rows and each row is an array reference of columns in that row.

If an error occurs, C<< !!error!! >> will be returned.

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

If you want to read from a specific database, though, you can set this parameter to the ID of the database (C<< database::<id>::host). If you specify a read from a database that isn't available, C<< !!error!! >> will be returned.

=head3 line (optional)

To help with logging the source of a query, C<< line >> can be set to the line number of the script that requested the query. It is generally used along side C<< source >>.

=head3 query (required)

This is the SQL query to perform.

B<NOTE>: ALWAYS use C<< $anvil->data->{sys}{database}{use_handle}->quote(...)>> when preparing data coming from ANY external source! Otherwise you'll end up XKCD 327'ing your database eventually...

=head3 secure (optional, defaul '0')

If set, the query will be treated as containing sensitive data and will only be logged if C<< $anvil->Log->secure >> is enabled.

=head3 source (optional)

To help with logging the source of a query, C<< source >> can be set to the name of the script that requested the query. It is generally used along side C<< line >>.

=cut
sub query
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->query()" }});
	
	my $uuid   = $parameter->{uuid}   ? $parameter->{uuid}   : $anvil->data->{sys}{database}{read_uuid};
	my $line   = $parameter->{line}   ? $parameter->{line}   : __LINE__;
	my $query  = $parameter->{query}  ? $parameter->{query}  : "";
	my $secure = $parameter->{secure} ? $parameter->{secure} : 0;
	my $source = $parameter->{source} ? $parameter->{source} : $THIS_FILE;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid                              => $uuid, 
		"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
		line                              => $line, 
		query                             => ((not $secure) or (($secure) && (not $anvil->Log->secure))) ? $query : $anvil->Words->string({key => "log_0186"}), 
		secure                            => $secure, 
		source                            => $source, 
	}});
	
	# Make logging code a little cleaner
	my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : $anvil->data->{sys}{database}{name};
	my $say_server    = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
	
	if (not $uuid)
	{
		# No database to talk to...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0072"});
		return("!!error!!");
	}
	elsif (not defined $anvil->data->{cache}{database_handle}{$uuid})
	{
		# Database handle is gone.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0073", variables => { uuid => $uuid }});
		return("!!error!!");
	}
	if (not $query)
	{
		# No query
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0084", variables => { 
			server => $say_server,
		}});
		return("!!error!!");
	}
	
	# Test access to the DB before we do the actual query
	$anvil->Database->_test_access({debug => $debug, uuid => $uuid});
	
	# If I am still alive check if any locks need to be renewed.
	$anvil->Database->check_lock_age({debug => $debug});
	
	# Do I need to log the transaction?
	if ($anvil->data->{sys}{database}{log_transactions})
	{
		$anvil->Log->entry({source => $source, line => $line, secure => $secure, level => 0, key => "log_0074", variables => { 
			uuid  => $uuid, 
			query => $query, 
		}});
	}
	
	# Do the query.
	my $DBreq = $anvil->data->{cache}{database_handle}{$uuid}->prepare($query) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0075", variables => { 
			query    => ((not $secure) or (($secure) && (not $anvil->Log->secure))) ? $query : $anvil->Words->string({key => "log_0186"}), 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}});
	
	# Execute on the query
	$DBreq->execute() or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0076", variables => { 
			query    => ((not $secure) or (($secure) && (not $anvil->Log->secure))) ? $query : $anvil->Words->string({key => "log_0186"}), 
			server   => $say_server,
			db_error => $DBI::errstr, 
		}});
	
	# Return the array
	return($DBreq->fetchall_arrayref());
}

=head2 read_variable

This reads a variable from the C<< variables >> table. Be sure to only use the reply from here to override what might have been set in a config file. This method always returns the data from the database itself.

The method returns an array reference containing, in order, the variable's value, database UUID and last modified date stamp.

If anything goes wrong, C<< !!error!! >> is returned. If the variable didn't exist in the database, an empty string will be returned for the UUID, value and modified date.

Parameters;

=head3 variable_uuid (optional)

If specified, this specifies the variable UUID to read. When this parameter is specified, the C<< variable_name >> parameter is ignored.

=head3 variable_name

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
	my $uuid                  = $parameter->{uuid}                  ? $parameter->{uuid}                  : $anvil->data->{sys}{database}{read_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		variable_uuid         => $variable_uuid, 
		variable_name         => $variable_name, 
		variable_source_uuid  => $variable_source_uuid, 
		variable_source_table => $variable_source_table, 
	}});
	
	# Do we have either the 
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
    round(extract(epoch from modified_date)) AS mtime
FROM 
    variables 
WHERE ";
	if ($variable_uuid)
	{
		$query .= "
    variable_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_uuid);
	}
	else
	{
		$query .= "
    variable_name = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_name);
		if (($variable_source_uuid ne "") && ($variable_source_table ne ""))
		{
			$query .= "
AND 
    variable_source_uuid  = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_uuid)." 
AND 
    variable_source_table = ".$anvil->data->{sys}{database}{use_handle}->quote($variable_source_table)." 
";
		}
	}
	$query .= ";";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	
	my $variable_value = "";
	my $modified_date  = "";
	my $results        = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
	my $count          = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		$variable_value = $row->[0];
		$variable_uuid  = $row->[1];
		$modified_date  = $row->[2];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			variable_value => $variable_value, 
			variable_uuid  => $variable_uuid, 
			modified_date  => $modified_date, 
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		variable_value => $variable_value, 
		variable_uuid  => $variable_uuid, 
		modified_date  => $modified_date, 
	}});
	return($variable_value, $variable_uuid, $modified_date);
}

=head2 resync_databases

This will resync the database data on this and peer database(s) if needed. It takes no arguments and will immediately return unless C<< sys::database::resync_needed >> was set.

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
		return(0);
	}
	
	### NOTE: Don't sort this array, we need to resync in the order that the user passed the tables to us
	###       to avoid trouble with primary/foreign keys.
	# We're going to use the array of tables assembles by _find_behind_databases() stored in 
	# 'sys::database::check_tables'
	foreach my $table (@{$anvil->data->{sys}{database}{check_tables}})
	{
		# If the 'schema' is 'public', there is no table in the history schema. If there is a host 
		# column, the resync will be restricted to entries from this host uuid.
		my $schema      = $anvil->data->{sys}{database}{table}{$table}{schema};
		my $host_column = $anvil->data->{sys}{database}{table}{$table}{host_column};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			table       => $table, 
			schema      => $schema, 
			host_column => $host_column, 
		}});
		
		# If there is a column name that is '<table>_uuid', or the same with the table's name minus 
		# the last 's', this will be the UUID column to keep records linked in history. We'll need to
		# know this off the bat. Tables where we don't find a UUID column won't be sync'ed.
		my $column1 = $table."_uuid";
		my $column2 = "";
		if ($table =~ /^(.*)s$/)
		{
			$column2 = $1."_uuid";
		}
		my $query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{name})." AND table_schema = 'public' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table)." AND data_type = 'uuid' AND is_nullable = 'NO' AND column_name = ".$anvil->data->{sys}{database}{use_handle}->quote($column1).";";
		if ($column2)
		{
			$query = "SELECT column_name FROM information_schema.columns WHERE table_catalog = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{name})." AND table_schema = 'public' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table)." AND data_type = 'uuid' AND is_nullable = 'NO' AND (column_name = ".$anvil->data->{sys}{database}{use_handle}->quote($column1)." OR column_name = ".$anvil->data->{sys}{database}{use_handle}->quote($column2).");";
		}
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
		my $uuid_column = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
		   $uuid_column = "" if not defined $uuid_column;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid_column => $uuid_column }});
		next if not $uuid_column;
		
		# Get all the columns in this table.
		$query = "SELECT column_name, is_nullable, data_type FROM information_schema.columns WHERE table_schema = ".$anvil->data->{sys}{database}{use_handle}->quote($schema)." AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table)." AND column_name != 'history_id';";
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
		
		# Now read in the data from the different databases.
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
		{
			# ...
			$anvil->data->{db_resync}{$uuid}{public}{sql}  = [];
			$anvil->data->{db_resync}{$uuid}{history}{sql} = [];
			
			# Read in the data, modified_date first as we'll need that for all entries we record.
			my $query        = "SELECT modified_date AT time zone 'UTC', $uuid_column, ";
			my $read_columns = [];
			push @{$read_columns}, "modified_date";
			push @{$read_columns}, $uuid_column;
			foreach my $column_name (sort {$a cmp $b} keys %{$anvil->data->{sys}{database}{table}{$table}{column}})
			{
				# We'll skip the host column as we'll use it in the conditional.
				next if $column_name eq "modified_date";
				next if $column_name eq $host_column;
				next if $column_name eq $uuid_column;
				$query .= $column_name.", ";
				
				push @{$read_columns}, $column_name;
			}
			
			# Strip the last comma and the add the schema.table name.
			$query =~ s/, $/ /;
			$query .= "FROM ".$schema.".".$table;
			
			# Restrict to this host if a host column was found.
			if ($host_column)
			{
				$query .= " WHERE ".$host_column." = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid});
			}
			$query .= " ORDER BY modified_date DESC;";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0074", variables => { uuid => $uuid, query => $query }});
			
			my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count,
			}});
			next if not $count;
			
			my $row_number = 0;
			foreach my $row (@{$results})
			{
				   $row_number++;
				my $modified_date = "";
				my $row_uuid      = "";
				for (my $column_number = 0; $column_number < @{$read_columns}; $column_number++)
				{
					my $column_name  = $read_columns->[$column_number];
					my $column_value = defined $row->[$column_number] ? $row->[$column_number] : "NULL";
					my $not_null     = $anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{not_null};
					my $data_type    = $anvil->data->{sys}{database}{table}{$table}{column}{$column_name}{data_type};
					$anvil->Log->variables({source => 2, line => __LINE__, level => $debug, list => { 
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
					
					# The modified_date should be the first row.
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
					
					# TODO: Remove these or make them proper errors
					die $THIS_FILE." ".__LINE__."; This row's modified_date wasn't the first column returned in query: [$query]\n" if not $modified_date;
					die $THIS_FILE." ".__LINE__."; This row's UUID column: [$uuid_column] wasn't the second column returned in query: [$query]\n" if not $row_uuid;
					
					# Record this in the unified and local hashes. 						# This table isn't restricted to given hosts.
					$anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name} = $column_value;
					$anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name}     = $column_value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"db_data::unified::${table}::modified_date::${modified_date}::${uuid_column}::${row_uuid}::${column_name}" => $anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name}, 
						"db_data::${uuid}::${table}::modified_date::${modified_date}::${uuid_column}::${row_uuid}::${column_name}"   => $anvil->data->{db_data}{$uuid}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name}, 
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
						"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::seen" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen} 
					}});
					if (not $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen})
					{
						# Mark this record as now having been seen.
						$anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen} = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::seen" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{seen} 
						}});
						
						# Does it exist?
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"db_data::${uuid}::${table}::${uuid_column}::${row_uuid}::exists" => $anvil->data->{db_data}{$uuid}{$table}{$uuid_column}{$row_uuid}{'exists'} 
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
									my $column_value =  $anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name});
									   $column_value =  "NULL" if not defined $column_value;
									   $column_value =~ s/'NULL'/NULL/g;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
										column_name  => $column_name, 
										column_value => $column_value, 
									}});
									
									$query .= "$column_name = ".$column_value.", ";
								}
								$query .= "modified_date = ".$anvil->data->{sys}{database}{use_handle}->quote($modified_date)."::timestamp AT TIME ZONE 'UTC' WHERE $uuid_column = ".$anvil->data->{sys}{database}{use_handle}->quote($row_uuid).";";
								$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0074", variables => { uuid => $uuid, query => $query }});
								
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
								my $column_value =  $anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name});
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
							
							my $query = "INSERT INTO public.$table (".$uuid_column.", ".$columns."modified_date) VALUES (".$anvil->data->{sys}{database}{use_handle}->quote($row_uuid).", ".$values.$anvil->data->{sys}{database}{use_handle}->quote($modified_date)."::timestamp AT TIME ZONE 'UTC');";
							if ($host_column)
							{
								# Add the host column.
								$query = "INSERT INTO public.$table ($host_column, $uuid_column, ".$columns."modified_date) VALUES (".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid}).", ".$anvil->data->{sys}{database}{use_handle}->quote($row_uuid).", ".$values.$anvil->data->{sys}{database}{use_handle}->quote($modified_date)."::timestamp AT TIME ZONE 'UTC');";
							}
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0074", variables => { uuid => $uuid, query => $query }});
							
							# Now record the query in the array
							push @{$anvil->data->{db_resync}{$uuid}{public}{sql}}, $query;
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
								my $column_value =  $anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{db_data}{unified}{$table}{modified_date}{$modified_date}{$uuid_column}{$row_uuid}{$column_name});
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
							
							my $query = "INSERT INTO history.$table (".$uuid_column.", ".$columns."modified_date) VALUES (".$anvil->data->{sys}{database}{use_handle}->quote($row_uuid).", ".$values.$anvil->data->{sys}{database}{use_handle}->quote($modified_date)."::timestamp AT TIME ZONE 'UTC');";
							if ($host_column)
							{
								# Add the host column.
								$query = "INSERT INTO history.$table ($host_column, $uuid_column, ".$columns."modified_date) VALUES (".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid}).", ".$anvil->data->{sys}{database}{use_handle}->quote($row_uuid).", ".$values.$anvil->data->{sys}{database}{use_handle}->quote($modified_date)."::timestamp AT TIME ZONE 'UTC');";
							}
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0074", variables => { uuid => $uuid, query => $query }});
							
							# Now record the query in the array
							push @{$anvil->data->{db_resync}{$uuid}{history}{sql}}, $query;
						} # if not exists - timestamp
					} # if seen
				} # foreach $id
			} # foreach $row_uuid
		} # foreach $modified_date ...
		
		# Free up memory by deleting the DB data from the main hash.
		delete $anvil->data->{db_data};
		
		# Do the INSERTs now and then release the memory.
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
		{
			# Merge the queries for both schemas into one array, with public schema 
			# queries being first, then delete the arrays holding them to free memory
			# before we start the resync.
			my $merged = [];
			@{$merged} = (@{$anvil->data->{db_resync}{$uuid}{public}{sql}}, @{$anvil->data->{db_resync}{$uuid}{history}{sql}});
			undef $anvil->data->{db_resync}{$uuid}{public}{sql};
			undef $anvil->data->{db_resync}{$uuid}{history}{sql};
			
			# If the merged array has any entries, push them in.
			if (@{$merged} > 0)
			{
				$anvil->Database->write({uuid => $uuid, query => $merged, source => $THIS_FILE, line => __LINE__});
				undef $merged;
			}
		}
	} # foreach my $table
	
	# Show tables;
	# SELECT table_schema, table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY table_name ASC, table_schema DESC;
	
	# Show columns;
	# SELECT table_catalog, table_schema, table_name, column_name, column_default, is_nullable, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'alerts';
	
	# psql -E anvil <<-- LOVE <3
	
	return(0);
}

=head2 write

This records data to one or all of the databases. If an ID is passed, the query is written to one database only. Otherwise, it will be written to all DBs.

=cut
sub write
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->write()" }});
	
	my $uuid    = $parameter->{uuid}    ? $parameter->{uuid}   : "";
	my $line    = $parameter->{line}    ? $parameter->{line}   : __LINE__;
	my $query   = $parameter->{query}   ? $parameter->{query}  : "";
	my $secure  = $parameter->{secure}  ? $parameter->{secure} : 0;
	my $source  = $parameter->{source}  ? $parameter->{source} : $THIS_FILE;
	my $reenter = $parameter->{reenter} ? $parameter->{reenter} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		uuid    => $uuid, 
		line    => $line, 
		query   => ((not $secure) or (($secure) && (not $anvil->Log->secure))) ? $query : $anvil->Words->string({key => "log_0186"}), 
		secure  => $secure, 
		source  => $source, 
		reenter => $reenter,
	}});
	
	if ($uuid)
	{
		$anvil->data->{cache}{database_handle}{$uuid} = "" if not defined $anvil->data->{cache}{database_handle}{$uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid}, 
		}});
	}
	
	# Make logging code a little cleaner
	my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : $anvil->data->{sys}{database}{name};
	my $say_server    = $uuid eq "" ? $anvil->Words->string({key => "log_0129"}) : $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
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
	$anvil->Database->check_lock_age({debug => $debug});
	
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		$anvil->Database->_test_access({debug => $debug, uuid => $uuid});
		
		# Do the actual query(ies)
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			uuid  => $uuid, 
			count => $count, 
		}});
		if ($count)
		{
			# More than one query, so start a transaction block.
			$anvil->data->{cache}{database_handle}{$uuid}->begin_work;
		}
		
		foreach my $query (@{$query_set})
		{
			if ($anvil->data->{sys}{database}{log_transactions})
			{
				$anvil->Log->entry({source => $source, line => $line, secure => $secure, level => 0, key => "log_0083", variables => { 
					uuid  => $uuid, 
					query => $query, 
				}});
			}
			
			if (not $anvil->data->{cache}{database_handle}{$uuid})
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0089", variables => { uuid => $uuid }});
				next;
			}
			
			# Do the do.
			$anvil->data->{cache}{database_handle}{$uuid}->do($query) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0090", variables => { 
					query    => ((not $secure) or (($secure) && (not $anvil->Log->secure))) ? $query : $anvil->Words->string({key => "log_0186"}), 
					server   => $say_server,
					db_error => $DBI::errstr, 
				}});
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
		if ($count)
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
	
	my $table    = $parameter->{table}    ? $parameter->{table}    : "";
	my $offset   = $parameter->{offset}   ? $parameter->{offset}   : 0;
	my $loop     = $parameter->{loop}     ? $parameter->{loop}     : 0;
	my $division = $parameter->{division} ? $parameter->{division} : $anvil->data->{sys}{database}{archive}{division};
	my $compress = $parameter->{compress} ? $parameter->{compress} : $anvil->data->{sys}{database}{archive}{compress};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		table    => $table, 
		offset   => $offset, 
		loop     => $loop, 
		division => $division, 
		compress => $compress, 
	}});
	
	if (not $table)
	{
		# ...
		return("!!error!!");
	}
	
	# First, if this table doesn't have a history schema, exit.
	my $query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = 'history' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table).";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
	if (not $count)
	{
		# History table doesn't exist, we're done.
		return(0);
	}
	
	# Before we do any real analysis, do we have enough entries in the history schema to trigger an archive?
	$query = "SELECT COUNT(*) FROM history.".$table.";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	$count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"s1:count"                           => $count,
		"s2:sys::database::archive::trigger" => $anvil->data->{sys}{database}{archive}{trigger},
	}});
	if ($count <= $anvil->data->{sys}{database}{archive}{trigger})
	{
		# History table doesn't exist, we're done.
		return(0);
	}
	
	# There is enough data to trigger an archive, so lets get started with a list of columns in this 
	# table.
	$query = "SELECT column_name FROM information_schema.columns WHERE table_schema = 'history' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table)." AND column_name != 'history_id' AND column_name != 'modified_date';";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	
	my $columns      = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $column_count = @{$columns};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		columns      => $columns, 
		column_count => $column_count 
	}});
	
	#print Dumper $columns;
	
	# See m2's DB->archive_if_needed() for old version of this.
	
	return(0);
}

=head2 _find_behind_databases

This returns the most up to date database ID, the time it was last updated and an array or DB IDs that are behind.

If there is a problem, C<< !!error!! >> is returned.

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
	
	my $source = $parameter->{source} ? $parameter->{source} : "";
	my $tables = $parameter->{tables} ? $parameter->{tables} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		source => $source, 
		tables => $tables, 
	}});
	
	# This should always be set, but just in case...
	if (not $source)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->_find_behind_databases()", parameter => "source" }});
		return("!!error!!");
	}
	
	# Now, look through the core tables, plus any tables the user might have passed, for differing 
	# 'modified_date' entries, or no entries in one DB with entries in the other (as can happen with a 
	# newly setup db).
	$anvil->data->{sys}{database}{check_tables} = [];
	foreach my $table (@{$anvil->data->{sys}{database}{core_tables}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
		push @{$anvil->data->{sys}{database}{check_tables}}, $table;
	}
	if (ref($tables) eq "ARRAY")
	{
		foreach my $table (@{$tables})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table => $table }});
			push @{$anvil->data->{sys}{database}{check_tables}}, $table;
		}
	}
	
	# Preset all tables to have an initial 'modified_date' of 0.
	foreach my $table (sort {$a cmp $b} @{$anvil->data->{sys}{database}{check_tables}})
	{
		$anvil->data->{sys}{database}{table}{$table}{last_updated} = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::table::${table}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{last_updated},
		}});
	}
	
	# Look at all the databases and find the most recent time stamp (and the ID of the DB).
	my $source_updated_time = 0;
	foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{database}})
	{
		my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : "#!string!log_0185!#";
		my $database_user = defined $anvil->data->{database}{$uuid}{user} ? $anvil->data->{database}{$uuid}{user} : "#!string!log_0185!#";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"database::${uuid}::host"     => $anvil->data->{database}{$uuid}{host},
			"database::${uuid}::port"     => $anvil->data->{database}{$uuid}{port},
			"database::${uuid}::name"     => $database_name,
			"database::${uuid}::user"     => $database_user, 
			"database::${uuid}::password" => $anvil->Log->secure ? $anvil->data->{database}{$uuid}{password} : $anvil->Words->string({key => "log_0186"}), 
		}});
		
		# Loop through the tables in this DB. For each table, we'll record the most recent time 
		# stamp. Later, We'll look through again and any table/DB with an older time stamp will be 
		# behind and a resync will be needed.
		foreach my $table (@{$anvil->data->{sys}{database}{check_tables}})
		{
			# Does this table exist yet?
			my $query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = 'public' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table).";";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $count = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
			
			if ($count == 1)
			{
				# Does this table have a '*_host_uuid' column?
				my $query = "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND column_name LIKE '\%_host_uuid' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				# See if there is a column that ends in '_host_uuid'. If there is, we'll use 
				# it later to restrict resync activity to these columns with the local 
				# 'sys::host_uuid'.
				my $host_column = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				   $host_column = "" if not defined $host_column;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_column => $host_column }});
				
				# Does this table have a history schema version?
				$query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema = 'history' AND table_name = ".$anvil->data->{sys}{database}{use_handle}->quote($table).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				my $count = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
				
				my $schema = $count ? "history" : "public";
				   $query  =  "
SELECT 
    round(extract(epoch from modified_date)) 
FROM 
    $schema.$table ";
				if ($host_column)
				{
					$query .= "
WHERE 
    $host_column = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid}) ;
				}
				$query .= "
ORDER BY 
    modified_date DESC
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					uuid  => $uuid, 
					query => $query, 
				}});
				
				my $last_updated = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				   $last_updated = 0 if not defined $last_updated;
				
				# Record this table's last modified_date for later comparison. We'll also 
				# record the schema and host column, if found, to save looking the same thing
				# up later if we do need a resync.
				$anvil->data->{sys}{database}{table}{$table}{id}{$uuid}{last_updated} = $last_updated;
				$anvil->data->{sys}{database}{table}{$table}{schema}                = $schema;
				$anvil->data->{sys}{database}{table}{$table}{host_column}           = $host_column;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::table::${table}::id::${uuid}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{id}{$uuid}{last_updated}, 
					"sys::database::table::${table}::last_updated"            => $anvil->data->{sys}{database}{table}{$table}{last_updated},
					"sys::database::table::${table}::schema"                  => $anvil->data->{sys}{database}{table}{$table}{schema},
					"sys::database::table::${table}::host_column"             => $anvil->data->{sys}{database}{table}{$table}{host_column},
				}});
				
				if ($anvil->data->{sys}{database}{table}{$table}{id}{$uuid}{last_updated} > $anvil->data->{sys}{database}{table}{$table}{last_updated})
				{
					$anvil->data->{sys}{database}{table}{$table}{last_updated} = $anvil->data->{sys}{database}{table}{$table}{id}{$uuid}{last_updated};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"sys::database::table::${table}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{last_updated}, 
					}});
				}
			}
		}
	}
	
	# Now loop through each table we've seen and see if the moditied_date differs for any of the 
	# databases. If it has, trigger a resync.
	foreach my $table (sort {$a cmp $b} keys %{$anvil->data->{sys}{database}{table}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::database::table::${table}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{last_updated}, 
		}});
		foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{sys}{database}{table}{$table}{id}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::table::${table}::id::${uuid}::last_updated" => $anvil->data->{sys}{database}{table}{$table}{id}{$uuid}{last_updated}, 
			}});
			if ($anvil->data->{sys}{database}{table}{$table}{last_updated} > $anvil->data->{sys}{database}{table}{$table}{id}{$uuid}{last_updated})
			{
				# Resync needed.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0106", variables => { uuid => $uuid }});
				
				# Mark it as behind.
				$anvil->Database->_mark_database_as_behind({uuid => $uuid});
				last;
			}
		}
		last if $anvil->data->{sys}{database}{resync_needed};
	}
	
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
	$anvil->data->{sys}{database}{resync_needed}          = 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::to_update::${uuid}::behind" => $anvil->data->{sys}{database}{to_update}{$uuid}{behind}, 
		"sys::database::resync_needed"            => $anvil->data->{sys}{database}{resync_needed}, 
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

This method takes a database UUID and tests the connection to it using the DBD 'ping' method. If it fails, open references to the database are removed or replaced, then an attempt to reconnect is made.

This exists to handle the loss of a database mid-run where a normal query, which isn't wrapped in a query, could hang indefinately.

=cut
sub _test_access
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->_test_access()" }});
	
	my $uuid = $parameter->{uuid} ? $parameter->{uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
	# Make logging code a little cleaner
	my $database_name = defined $anvil->data->{database}{$uuid}{name} ? $anvil->data->{database}{$uuid}{name} : $anvil->data->{sys}{database}{name};
	my $say_server    = $anvil->data->{database}{$uuid}{host}.":".$anvil->data->{database}{$uuid}{port}." -> ".$database_name;
	
	# Log our test
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0087", variables => { server => $say_server }});
	
	# TODO: Is there a use for this anymore?
	if (0)
	{
		# Ping works. Try a quick test query.
		my $query = "SELECT 1";
		my $DBreq = $anvil->data->{cache}{database_handle}{$uuid}->prepare($query) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0075", variables => { 
				query    => $query, 
				server   => $say_server,
				db_error => $DBI::errstr, 
			}});
		
		# Give the test query a few seconds to respond, just in case we have some latency to a remote DB.
		alarm(10);
		$DBreq->execute() or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0076", variables => { 
				query    => $query, 
				server   => $say_server,
				db_error => $DBI::errstr, 
			}});
		# If we're here, we made contact.
		alarm(0);
	}
	
	# Check using ping. Returns '1' on success, '0' on fail.
	my $connected = $anvil->data->{cache}{database_handle}{$uuid}->ping();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connected => $connected }});
	if (not $connected)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0192", variables => { server => $say_server }});
		
		# Try to reconnect.
		$anvil->data->{sys}{database}{connections}--;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
		
		# If this was the DB we were reading from or that the use_db_handle matches, and another DB 
		# appears to still be up, switch to one of the others.
		if ($anvil->data->{sys}{database}{connections})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::use_handle"       => $anvil->data->{sys}{database}{use_handle},
				"cache::database_handle::${uuid}" => $anvil->data->{cache}{database_handle}{$uuid},
			}});
			if ($anvil->data->{sys}{database}{use_handle} eq $anvil->data->{cache}{database_handle}{$uuid})
			{
				foreach my $this_uuid (keys %{$anvil->data->{cache}{database_handle}})
				{
					# We don't test this connection because, if it's down, we'll know 
					# when it is tested.
					my $database_name = defined $anvil->data->{database}{$this_uuid}{name} ? $anvil->data->{database}{$this_uuid}{name} : $anvil->data->{sys}{database}{name};
					my $say_server    = $anvil->data->{database}{$this_uuid}{host}.":".$anvil->data->{database}{$this_uuid}{port}." -> ".$database_name;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0193", variables => { server => $say_server }});

					$anvil->data->{sys}{database}{use_handle} = $anvil->data->{cache}{database_handle}{$this_uuid};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::use_handle" => $anvil->data->{sys}{database}{use_handle} }});
					last;
				}
			}

			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				uuid                       => $uuid,
				"sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid},
			}});
			if ($uuid eq $anvil->data->{sys}{database}{read_uuid})
			{
				# We were reading from this DB, switch.
				foreach my $this_uuid (keys %{$anvil->data->{cache}{database_handle}})
				{
					# We don't test this connection because, if it's down, we'll know 
					# when it is tested.
					my $database_name = defined $anvil->data->{database}{$this_uuid}{name} ? $anvil->data->{database}{$this_uuid}{name} : $anvil->data->{sys}{database}{name};
					my $say_server    = $anvil->data->{database}{$this_uuid}{host}.":".$anvil->data->{database}{$this_uuid}{port}." -> ".$database_name;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0194", variables => { server => $say_server }});

					$anvil->data->{sys}{database}{read_uuid} = $this_uuid;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::read_uuid" => $anvil->data->{sys}{database}{read_uuid} }});
					last;
				}
			}
			
		}
		else
		{
			# We're in trouble if we don't reconnect...
			$anvil->data->{sys}{database}{use_handle} = "";
			$anvil->data->{sys}{database}{read_uuid}  = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::database::use_handle" => $anvil->data->{sys}{database}{use_handle}, 
				"sys::database::read_uuid"  => $anvil->data->{sys}{database}{read_uuid},
			}});
			
		}
		
		# Delete the old handle and then try to reconnect. If the reconnect succeeds, and this is the
		# local database, this database will be re-selected as default for reads.
		delete $anvil->data->{cache}{database_handle}{$uuid};
		
		my $delay = 5;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0195", variables => { 
			delay  => $delay,
			server => $say_server,
		}});
		sleep $delay;
		$anvil->Database->connect({debug => $debug, db_uuid => $uuid});
		
		# If we're down to '0' databases, error out.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
		if (not $anvil->data->{sys}{database}{connections})
		{
			# No connections are left, die.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0196"});
			$anvil->nice_exit({code => 1});
			# In case we're still alive, die.
			die $THIS_FILE." ".__LINE__."; exiting on DB connection error.\n";
		}
	}
	
	# Success!
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0088"});
	
	return(0);
}

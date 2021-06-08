package Anvil::Tools::Server;
# 
# This module contains methods used to manager servers
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Server.pm";

### Methods;
# active_migrations
# boot_virsh
# find
# get_definition
# get_runtime
# get_status
# map_network
# parse_definition
# migrate_virsh
# shutdown_virsh

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Server

Provides all methods related to (virtual) servers.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Server->X'. 
 # 
 # 

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
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

=head2 active_migrations

This method returns C<< 1 >> if any servers are migrating to or from the local system. It returns C<< 0 >> otherwise.

This method takes no parameters.

=cut
sub active_migrations
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->active_migrations()" }});
	
	# Are we in an Anvil! system?
	my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
	if (not $anvil_uuid)
	{
		# We're not in an Anvil.
		return(0);
	}
	
	$anvil->Database->get_servers({debug => $debug});
	foreach my $server_uuid (keys %{$anvil->data->{servers}{server_uuid}})
	{
		my $server_name  = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_name};
		my $server_state = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
		if ($server_state eq "migrating")
		{
			return(1);
		}
	}
	
	return(0);
}


=head2 boot_virsh

This takes a server name and tries to boot it (using C<< virsh create /mnt/shared/definition/<server>.xml >>. It requires that any supporting systems already be started (ie: DRBD resource is up).

If booted, C<< 1 >> is returned. Otherwise, C<< 0 >> is returned.

#  my ($booted) = $anvil->Server->boot_virsh({server => "test_server"});

Parameters;

=head3 definition (optional, see below for default)

This is the full path to the XML definition file to use to boot the server.

By default, the definition file used will be named C<< <server>.xml >> in the C<< path::directories::shared::deinitions >> directory. 

=head3 server (required)

This is the name of the server, as it appears in C<< virsh >>.

=cut
sub boot_virsh
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->boot_virsh()" }});
	
	my $server     = defined $parameter->{server}     ? $parameter->{server}     : "";
	my $definition = defined $parameter->{definition} ? $parameter->{definition} : "";
	my $success    = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server     => $server, 
		definition => $definition, 
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->boot_virsh()", parameter => "server" }});
		return(1);
	}
	if (not $definition)
	{
		$definition = $anvil->data->{path}{directories}{shared}{definitions}."/".$server.".xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { efinition => $definition }});
	}
	
	# Is this a local call or a remote call?
	my ($output, $return_code) = $anvil->System->call({
		debug      => $debug, 
		shell_call => $anvil->data->{path}{exe}{virsh}." create ".$definition,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code,
	}});
	
	# Wait up to five seconds for the server to appear.
	my $wait = 5;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'wait' => $wait }});
	while($wait)
	{
		$anvil->Server->find({debug => $debug});
		if ((exists $anvil->data->{server}{location}{$server}) && ($anvil->data->{server}{location}{$server}{host_name}))
		{
			# Success!
			$wait    = 0;
			$success = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				'wait'  => $wait,
				success => $success, 
			}});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0421", variables => { 
				server => $server, 
				host   => $anvil->data->{server}{location}{$server}{host_name},
			}});
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
			if ($anvil->data->{sys}{database}{connections})
			{
				my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
				
				my $server_uuid = $anvil->Get->server_uuid_from_name({
					debug       => $debug, 
					server_name => $server, 
					anvil_uuid  => $anvil_uuid,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
				if (($server_uuid) && ($server_uuid ne "!!error!!"))
				{
					$anvil->Database->get_servers({debug => $debug});
					if (exists $anvil->data->{servers}{server_uuid}{$server_uuid})
					{
						my $old_state = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_state => $old_state }});
						
						if ($old_state ne "in shutdown")
						{
							# Update it.
							my $runtime = $anvil->Server->get_runtime({
								debug  => 2,
								server => $server,
							});
							my $query = "
UPDATE 
    servers 
SET 
    server_state     = 'running', 
    server_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid).", ";
							if ($runtime =~ /^\d+$/)
							{
								my $boot_time =  time - $runtime;
								   $query     .= "
    server_boot_time = ".$anvil->Database->quote($boot_time).",  ";
							}
							$query .= "
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid      = ".$anvil->Database->quote($server_uuid)."
;";
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
							$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
						}
					}
				}
			}
		}
		
		if ($wait)
		{
			$wait--;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'wait' => $wait }});
			sleep 1;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { success => $success }});
	return($success);
}

=head2 find

This will look on the local or a remote machine for the list of servers that are running. 

The list is stored as; 

 server::location::<server_name>::status = <status>
 server::location::<server_name>::host   = <host_name>

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 refresh (optional, default '1')

Is set to C<< 0 >>, any previously seen servers and their information is cleared.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub find
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->find()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $refresh     = defined $parameter->{refresh}     ? $parameter->{refresh}     : 1;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		refresh     => $refresh, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Clear any old data
	if ((exists $anvil->data->{server}{location}) && ($refresh))
	{
		delete $anvil->data->{server}{location};
	}
	
	my $host_type    = $anvil->Get->host_type({debug => $debug});
	my $host_name    = $anvil->Get->host_name;
	my $virsh_output = "";
	my $return_code  = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call
		($virsh_output, my $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{virsh}." list --all"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			virsh_output => $virsh_output,
			return_code  => $return_code,
		}});
	}
	else
	{
		# Remote call.
		($host_name, my $error, my $host_return_code) = $anvil->Remote->call({
			debug       => 2, 
			password    => $password, 
			shell_call  => $anvil->data->{path}{exe}{hostnamectl}." --static", 
			target      => $target,
			remote_user => "root", 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_name        => $host_name,
			error            => $error,
			host_return_code => $host_return_code, 
		}});
		($virsh_output, $error, $return_code) = $anvil->Remote->call({
			debug       => 2, 
			password    => $password, 
			shell_call  => $anvil->data->{path}{exe}{virsh}." list --all", 
			target      => $target,
			remote_user => "root", 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			virsh_output => $virsh_output,
			error        => $error,
			return_code  => $return_code, 
		}});
	}
	
	foreach my $line (split/\n/, $virsh_output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /^\d+ (.*) (.*?)$/)
		{
			my $server_name                                              = $1;
			   $anvil->data->{server}{location}{$server_name}{status}    = $2;
			   $anvil->data->{server}{location}{$server_name}{host_name} = $host_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::location::${server_name}::status"    => $anvil->data->{server}{location}{$server_name}{status}, 
				"server::location::${server_name}::host_name" => $anvil->data->{server}{location}{$server_name}{host_name}, 
			}});
		}
	}
	
	return(0);
}


=head2 get_definition

This returns the server definition XML for a server. 

Parameters;

=head3 server_uuid (optional, if 'server_name' used. required if not)

If provided, this is the specific server's definition we'll return. If it is not provided, C<< server_name >> is required.

=head3 server_name (optional)

If provided, and C<< server_uuid >> is not, the server will be searched for using this name. If C<< anvil_uuid >> is included, the name will be searched on the appropriate Anvil! system only. 

=head3 anvil_uuid (optional)

If set along with C<< server_name >>, the search for the server's XML will be restricted to the specified Anvil! system.

=cut
sub get_definition
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->get_definition()" }});
	
	my $definition_xml = "";
	my $anvil_uuid     = defined $parameter->{anvil_uuid}  ? $parameter->{anvil_uuid}  : "";
	my $server_name    = defined $parameter->{server_name} ? $parameter->{server_name} : "";
	my $server_uuid    = defined $parameter->{server_uuid} ? $parameter->{server_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid  => $anvil_uuid, 
		server_name => $server_name, 
		server_uuid => $server_uuid, 
	}});
	
	if (not $server_uuid)
	{
		$server_uuid = $anvil->Get->server_uuid_from_name({
			debug       => $debug, 
			server_name => $server_name, 
			anvil_uuid  => $anvil_uuid,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
	}
	if (($server_uuid) && ($anvil->Validate->uuid({uuid => $server_uuid})))
	{
		my $query = "SELECT server_definition_xml FROM server_definitions WHERE server_definition_server_uuid = ".$anvil->Database->quote($server_uuid).";";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if ($count == 1)
		{
			# Found it
			$definition_xml = defined $results->[0]->[0] ? $results->[0]->[0] : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_xml => $definition_xml }});
		}
	}
	
	return($definition_xml);
}


=head2 get_runtime

This returns the number of seconds that a (virtual) server has been running on this host. 

If the server is not found to be running locally, C<< 0 >> is returned. Otherwise, the number of seconds is returned.

B<< Note >>: This is NOT the overall runtime! If the server migrated, it will return the number of seconds that the server has been on this host, which could vary dramatically from the guest's actual runtime!

Parameters;

=head3 server (required)

This is the name of the server whose runtime we are checking. 

=cut
sub get_runtime
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->get_runtime()" }});
	
	my $runtime = 0;
	my $server  = defined $parameter->{server} ? $parameter->{server} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server => $server, 
	}});
	
	# To find the runtime, we first need to find the PID.
	my $server_pid = 0;
	my $shell_call = $anvil->data->{path}{exe}{ps}." aux";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({ string => $line });
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /^qemu\s+(\d+)\s.*?guest=\Q$server\E,/)
		{
			$server_pid = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_pid => $server_pid }});
			last;
		}
	}
	
	if ($server_pid)
	{
		my $shell_call = $anvil->data->{path}{exe}{ps}." -p ".$server_pid." -o etimes=";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
		foreach my $line (split/\n/, $output)
		{
			$runtime = $anvil->Words->clean_spaces({ string => $line });
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { runtime => $runtime }});
		}
	}
	
	return($runtime);
}

=head2 get_status

This reads in a server's XML definition file from disk, if available, and from memory, if the server is running. The XML is analyzed and data is stored under C<< server::<target>::<server_name>::from_disk::x >> for data from the on-disk XML and C<< server::<target>>::<server_name>::from_virsh::x >>. 

Any pre-existing data on the server is flushed before the new information is processed.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 server (required)

This is the name of the server we're gathering data on.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub get_status
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->get_status()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $server      = defined $parameter->{server}      ? $parameter->{server}      : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# This is used in the hash reference when storing the data.
	my $host = $target ? $target : $anvil->Get->short_host_name();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->get_status()", parameter => "server" }});
		return(1);
	}
	if (exists $anvil->data->{server}{$host}{$server})
	{
		delete $anvil->data->{server}{$host}{$server};
	}
	$anvil->data->{server}{$host}{$server}{from_virsh}{host} = "";
	
	# We're going to map DRBD devices to resources, so we need to collect that data now. 
	$anvil->DRBD->get_devices({
		debug       => $debug,
		password    => $password,
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	});
	
	# Is this a local call or a remote call?
	my $shell_call = $anvil->data->{path}{exe}{virsh}." dumpxml --inactive ".$server;
	my $this_host  = $anvil->Get->short_host_name;
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		($anvil->data->{server}{$host}{$server}{from_virsh}{xml}, $anvil->data->{server}{$host}{$server}{from_virsh}{return_code}) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${host}::${server}::from_virsh::xml"         => $anvil->data->{server}{$host}{$server}{from_virsh}{xml},
			"server::${host}::${server}::from_virsh::return_code" => $anvil->data->{server}{$host}{$server}{from_virsh}{return_code},
		}});
	}
	else
	{
		# Remote call.
		$this_host = $target;
		($anvil->data->{server}{$host}{$server}{from_virsh}{xml}, my $error, $anvil->data->{server}{$host}{$server}{from_virsh}{return_code}) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error                                                 => $error,
			"server::${host}::${server}::from_virsh::xml"         => $anvil->data->{server}{$host}{$server}{from_virsh}{xml},
			"server::${host}::${server}::from_virsh::return_code" => $anvil->data->{server}{$host}{$server}{from_virsh}{return_code},
		}});
	}
	
	# If the return code was non-zero, we can't parse the XML.
	if ($anvil->data->{server}{$host}{$server}{from_virsh}{return_code})
	{
		$anvil->data->{server}{$host}{$server}{from_virsh}{xml} = "";
	}
	else
	{
		$anvil->data->{server}{$host}{$server}{from_virsh}{host} = $this_host;
		$anvil->Server->parse_definition({
			debug      => $debug,
			host       => $this_host,
			server     => $server, 
			source     => "from_virsh",
			definition => $anvil->data->{server}{$host}{$server}{from_virsh}{xml}, 
		});
	}
	
	# Now get the on-disk XML.
	my $definition_file = $anvil->data->{path}{directories}{shared}{definitions}."/".$server.".xml";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_file => $definition_file }});
	($anvil->data->{server}{$host}{$server}{from_disk}{xml}) = $anvil->Storage->read_file({
		debug       => $debug, 
		password    => $password,
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
		force_read  => 1,
		file        => $definition_file,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${host}::${server}::from_disk::xml" => $anvil->data->{server}{$host}{$server}{from_disk}{xml},
	}});
	if (($anvil->data->{server}{$host}{$server}{from_disk}{xml} eq "!!error!!") or (not $anvil->data->{server}{$host}{$server}{from_disk}{xml}))
	{
		# Failed to read it. Can we write it?
		my $definition_xml = "";
		if ($anvil->data->{server}{$host}{$server}{from_virsh}{xml})
		{
			$definition_xml = $anvil->data->{server}{$host}{$server}{from_virsh}{xml};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_xml => $definition_xml }});
		}
		else
		{
			# Read in from the database.
			$definition_xml = $anvil->Server->get_definition({
				debug       => $debug, 
				server_name => $server,
				anvil_uuid  => $anvil->Cluster->get_anvil_uuid({debug => $debug}),
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_xml => $definition_xml }});
		}
		
		if ($definition_xml)
		{
			# Write it to disk
			my ($failed) = $anvil->Storage->write_file({
				secure      => 1, 
				file        => $definition_file, 
				body        => $definition_xml, 
				overwrite   => 1,
				password    => $password, 
				port        => $port, 
				remote_user => $remote_user, 
				target      => $target,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
			if ($failed)
			{
				# Simething went weong.
				$anvil->data->{server}{$host}{$server}{from_disk}{xml} = "";
				return(1);
			}
			
			# Now try to read it back.
			($anvil->data->{server}{$host}{$server}{from_disk}{xml}) = $anvil->Storage->read_file({
				debug       => $debug, 
				password    => $password,
				port        => $port, 
				remote_user => $remote_user, 
				target      => $target, 
				force_read  => 1,
				file        => $definition_file,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${host}::${server}::from_disk::xml" => $anvil->data->{server}{$host}{$server}{from_disk}{xml},
			}});
			if (($anvil->data->{server}{$host}{$server}{from_disk}{xml} eq "!!error!!") or (not $anvil->data->{server}{$host}{$server}{from_disk}{xml}))
			{
				# Failed to read it.
				$anvil->data->{server}{$host}{$server}{from_disk}{xml} = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"server::${host}::${server}::from_disk::xml" => $anvil->data->{server}{$host}{$server}{from_disk}{xml},
				}});
			}
			else
			{
				# Load
				$anvil->Server->parse_definition({
					debug      => $debug,
					host       => $this_host,
					server     => $server, 
					source     => "from_disk",
					definition => $anvil->data->{server}{$host}{$server}{from_disk}{xml}, 
				});
			}
		}
		else
		{
			$anvil->data->{server}{$host}{$server}{from_disk}{xml} = "";
		}
	}
	else
	{
		$anvil->Server->parse_definition({
			debug      => $debug,
			host       => $this_host,
			server     => $server, 
			source     => "from_disk",
			definition => $anvil->data->{server}{$host}{$server}{from_disk}{xml}, 
		});
	}
	
	return(0);
}

=head2 map_network

This method maps the network for any servers B<< running >> on the C<< target >>. 

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 refresh (optional, default '1')

Is set to C<< 0 >>, any previously seen servers and their information is cleared.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional, default '')

This is the IP or host name of the host to map the network of hosted servers on.

=cut
sub map_network
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->map_network()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $server      = defined $parameter->{server}      ? $parameter->{server}      : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# NOTE: We don't use 'Server->find' as the hassle of tracking hosts to target isn't worth it.
	# Get a list of servers. 
	my $shell_call = $anvil->data->{path}{exe}{virsh}." list";
	my $output     = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		($output, my $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	else
	{
		# Remote call.
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error       => $error,
			output      => $output,
			return_code => $return_code,
		}});
	}
	
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^\d+ (.*) (.*?)$/)
		{
			my $server = $1;
			my $state  = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				server  => $server,
				'state' => $state, 
			}});
			
			# Parse the data on this server.
			$anvil->Server->get_status({
				debug       => $debug,
				server      => $server, 
				password    => $password,
				port        => $port, 
				remote_user => $remote_user, 
				target      => $target, 
			});
			
			# This is used in the hash reference when storing the data.
			my $host = $target ? $target : $anvil->Get->short_host_name();
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
			foreach my $mac (sort {$a cmp $b} keys %{$anvil->data->{server}{$host}{$server}{from_virsh}{device}{interface}})
			{
				my $device = $anvil->data->{server}{$host}{$server}{from_virsh}{device}{interface}{$mac}{target};
				my $bridge = $anvil->data->{server}{$host}{$server}{from_virsh}{device}{interface}{$mac}{bridge};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:device' => $device, 
					's2:mac'    => $mac,
					's3:bridge' => $bridge, 
				}});
			}
		}
	}
	
	return(0);
}

=head2 provision

This method creates a new (virtual) server on an Anvil! system.

Parameters;

=cut
sub provision
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->provision()" }});
	
=cut
Provision order:

1. Create LVs and register the storage. 
  - NOTE: If the LV is already in the DB (from a past install) and the peer is not available and the local 
          DRBD resource doesn't show Consistent, abort. If the peer is alive but we can't contact it, it's 
          possible the peer is UpToDate.
2. Create the DRBD resource. If "Inconsistent" on both nodes, force up to date
3. Wait for install media/image to be ready
4. Provision VM and add to Pacemaker.

=cut
	
	
	return(0);
}

=head2 migrate_virsh

This will migrate (push or pull) a server from one node to another. If the migration was successful, C<< 1 >> is returned. Otherwise, C<< 0 >> is returned with a (hopefully) useful error being logged.

Generally speaking, this is B<< NOT >> the method you want to call. 

B<< Warning >>: This method is meant to do the raw C<< virsh >> call, it is NOT designed to be called by pacemaker. To migrate via pacemaker, use C<< Cluster->migrate >>.

B<< Note >>: It is assumed that sanity checks are completed before this method is called.

Parameters;

=head3 server (required)

This is the name of the server being migrated.

=head3 source (optional)

This is the host name (or IP) of the host that we're pulling the server from.

If set, the server will be pulled.

=head3 target (optional, defaukt is the full local host name)

This is the host name (or IP) Of the host that the server will be pushed to, if C<< source >> is not set. When this is not passed, the local full host name is used as default.

=cut
sub migrate_virsh
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->migrate_virsh()" }});
	
	my $server  = defined $parameter->{server} ? $parameter->{server} : "";
	my $source  = defined $parameter->{source} ? $parameter->{source} : "";
	my $target  = defined $parameter->{target} ? $parameter->{target} : $anvil->Get->host_name;
	my $success = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server => $server, 
		source => $source, 
		target => $target, 
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->migrate_virsh()", parameter => "server" }});
		return($success);
	}
	
	if (not $anvil->data->{server}{$source}{$server})
	{
		# The 'target' below is where I'm reading the server's definition from, which is the 
		# migration source.
		$anvil->Server->get_status({
			debug  => $debug,
			server => $server, 
			target => $source, 
		});
	}
	
	# This logs the path down to the resources under the servers, helps in the next step to enable dual 
	# primary fails.
	foreach my $source (sort {$a cmp $b} keys %{$anvil->data->{server}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source => $source }});
		foreach my $server (sort {$a cmp $b} keys %{$anvil->data->{server}{$source}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server => $server }});
			foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{server}{$source}{$server}{resource}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
			}
		}
	}
	
	# Enable dual-primary for any resources we know about for this server.
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{server}{$source}{$server}{resource}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		my ($return_code) = $anvil->DRBD->allow_two_primaries({
			debug    => $debug, 
			resource => $resource, 
		});
	}
	
	### NOTE: This method is called by ocf:alteeve:server, which operates without database access. As 
	###       such, queries need to be run only if we've got one or more DB connections.
	# Mark this server as being in a migration state.
	if ($anvil->data->{sys}{database}{connections})
	{
		$anvil->Database->get_servers({debug => 2});
	}
	my $migation_started = time;
	my $server_uuid      = "";
	my $old_server_state = "";
	foreach my $this_server_uuid (keys %{$anvil->data->{servers}{server_uuid}})
	{
		if ($server eq $anvil->data->{servers}{server_uuid}{$this_server_uuid}{server_name})
		{
			$server_uuid = $this_server_uuid;
			last;
		}
	}
	if (($server_uuid) && ($anvil->data->{sys}{database}{connections}))
	{
		if ($anvil->data->{servers}{server_uuid}{$server_uuid}{server_state} ne "migrating")
		{
			$old_server_state = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
			my $query = "
UPDATE 
    servers 
SET 
    server_state  = 'migrating',
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid   = ".$anvil->Database->quote($server_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
		}
	}
	
	# The virsh command switches host names to IPs and needs to have both the source and target IPs in 
	# the known_hosts file to work.
	my $live_migrate = "";
	if (($server_uuid) && ($anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration}))
	{
		$live_migrate = "--live";
	}
	my $target_ip    = $anvil->Convert->host_name_to_ip({debug => $debug, host_name => $target});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target_ip    => $target_ip,
		live_migrate => $live_migrate,
	}});
	foreach my $host ($target, $target_ip)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
		$anvil->Remote->add_target_to_known_hosts({
			debug  => $debug,
			target => $host,
		});
	}
	
	my $migration_command = $anvil->data->{path}{exe}{virsh}." migrate --undefinesource --tunnelled --p2p ".$live_migrate." ".$server." qemu+ssh://".$target."/system";
	if ($source)
	{
		my $source_ip = $anvil->Convert->host_name_to_ip({debug => $debug, host_name => $source});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source_ip => $source_ip }});
		foreach my $host ($source, $source_ip)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
			$anvil->Remote->add_target_to_known_hosts({
				debug  => $debug,
				target => $host,
			});
		}
		
		$migration_command = $anvil->data->{path}{exe}{virsh}." -c qemu+ssh://root\@".$source."/system migrate --undefinesource --tunnelled --p2p ".$live_migrate." ".$server." qemu+ssh://".$target."/system";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { migration_command => $migration_command }});
	
	# Call the migration now
	my ($output, $return_code) = $anvil->System->call({shell_call => $migration_command});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	# Before we update, re-scan servers as some time may have passed.
	if ($anvil->data->{sys}{database}{connections})
	{
		$anvil->Database->get_servers({debug => 2});
	}
	if ($return_code)
	{
		# Something went wrong.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0353", variables => { 
			server      => $server, 
			target      => $target, 
			return_code => $return_code, 
			output      => $output, 
		}});
		
		# Revert the migrating state.
		if (($server_uuid) && ($anvil->data->{sys}{database}{connections}))
		{
			my $query = "
UPDATE 
    servers 
SET 
    server_state  = ".$anvil->Database->quote($old_server_state).", 
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid   = ".$anvil->Database->quote($server_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
		}
	}
	else
	{
		my $migration_took     = time - $migation_started;
		my $say_migration_time = $anvil->Convert->time({'time' => $migration_took});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			migration_took     => $migration_took, 
			say_migration_time => $say_migration_time,
		}});
		
		# Log the migration.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0354", variables => { migration_time => $say_migration_time }});
		
		$success = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { success => $success }});
		
		# Update the server state, if we have a database connection.
		if ($anvil->data->{sys}{database}{connections})
		{
			# Revert the server state and update the server host.
			my $server_host_uuid = $anvil->Get->host_uuid_from_name({debug => $debug, host_name => $target});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_host_uuid => $server_host_uuid }});
			if (not $server_host_uuid)
			{
				# We didn't find the target's host_uuid, so use the old one and let scan-server 
				# handle it.
				$server_host_uuid = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_host_uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_host_uuid => $server_host_uuid }});
			}
			if ($server_uuid)
			{
				my $query = "
UPDATE 
    servers 
SET 
    server_state     = ".$anvil->Database->quote($old_server_state).", 
    server_host_uuid = ".$anvil->Database->quote($server_host_uuid).", 
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid      = ".$anvil->Database->quote($server_uuid)."
;";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
				$anvil->Database->insert_or_update_servers({
					debug                           => $debug, 
					server_uuid                     => $server_uuid, 
					server_name                     => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_name}, 
					server_anvil_uuid               => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_anvil_uuid}, 
					server_user_stop                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_user_stop}, 
					server_start_after_server_uuid  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_after_server_uuid}, 
					server_start_delay              => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_delay}, 
					server_host_uuid                => $server_host_uuid, 
					server_state                    => $old_server_state, 
					server_live_migration           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration}, 
					server_pre_migration_file_uuid  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_file_uuid}, 
					server_pre_migration_arguments  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_arguments}, 
					server_post_migration_file_uuid => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_file_uuid}, 
					server_post_migration_arguments => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_arguments}, 
					server_ram_in_use               => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_ram_in_use}, 
					server_configured_ram           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_configured_ram}, 
					server_updated_by_user          => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_updated_by_user},
					server_boot_time                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_boot_time},
				});
				
				# Record the migration time.
				my ($variable_uuid) = $anvil->Database->insert_or_update_variables({
					file                  => $THIS_FILE, 
					line                  => __LINE__, 
					variable_name         => "server::migration_duration", 
					variable_value        => $migration_took, 
					variable_default      => "", 
					variable_description  => "message_0236", 
					variable_section      => "servers", 
					variable_source_uuid  => $server_uuid, 
					variable_source_table => "servers", 
				});
			}
		}
		else
		{
			# There's no database, so write the migration time to a temp file.
			my $body = "server_name=".$server.",migration_took=".$migration_took."\n";
			my $file = "/tmp/anvil/migration-duration.".$server.".".time;
			my ($failed) = $anvil->Storage->write_file({
				file => $file, 
				body => $body, 
				mode => "0666",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		}
	}
	
	# Switch off dual-primary.
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{server}{$target}{$server}{resource}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		$anvil->DRBD->reload_defaults({
			debug    => $debug, 
			resource => $resource, 
		});
	}
	
	return($success);
}

=head2 

This method parses a server's C<< virsh >> XML definition. On successful parse, C<< 0 >> is returned. If there is a problem, C<< !!error!! >> is returned.

B<< Note >>: This method currently parses out data needed for specific tasks, and not the entire data structure.

Parameters;

=head3 server (required)

This is the name of the server whose XML is being parsed.

=head3 source (required)

This is the source of the XML. This is done to simplify looking for differences between definitions for the same server. It should be;

=head4 C<< from_disk >> 

The XML was read from a file on the host's storage.

=head4 C<< from_virsh >> 

The XML was dumped by C<< virsh >> from memory.

=head4 C<< from_db >> 

The XML was read from the C<< definitions >> database table.

=head3 definition (required)

This is the actual XML to be parsed.

=head3 host (optional, default 'Get->short_host_name')

This is the host name of the Anvil! node or DR host that the XML was generated on or read from.

=cut
sub parse_definition
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->parse_definition()" }});
	
	# Source is required.
	my $server     = defined $parameter->{server}     ? $parameter->{server}     : "";
	my $source     = defined $parameter->{source}     ? $parameter->{source}     : "";
	my $definition = defined $parameter->{definition} ? $parameter->{definition} : "";
	my $host       = defined $parameter->{host}       ? $parameter->{host}       : $anvil->Get->short_host_name;
	my $target     = $anvil->Get->short_host_name();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server     => $server,
		source     => $source, 
		definition => $definition, 
		host       => $host, 
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->parse_definition()", parameter => "server" }});
		return(1);
	}
	if (not $source)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->parse_definition()", parameter => "source" }});
		return(1);
	}
	if (not $definition)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->parse_definition()", parameter => "definition" }});
		return(1);
	}
	
	### TODO: Switch this away from XML::Simple
	local $@;
	my $xml        = XML::Simple->new();
	my $server_xml = "";
	my $test       = eval { $server_xml = $xml->XMLin($definition, KeyAttr => {}, ForceArray => 1) };
	if (not $test)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem parsing: [$definition]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", list => { error => $error }});
		$anvil->nice_exit({exit_code => 1});
	}
	
	$anvil->data->{server}{$target}{$server}{$source}{parsed} = $server_xml;
	#print Dumper $server_xml;
	#die;
	
	# Pull out some basic server info.
	$anvil->data->{server}{$target}{$server}{$source}{info}{uuid}         = $server_xml->{uuid}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{info}{name}         = $server_xml->{name}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{info}{on_poweroff}  = $server_xml->{on_poweroff}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{info}{on_crash}     = $server_xml->{on_crash}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{info}{on_reboot}    = $server_xml->{on_reboot}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{info}{boot_menu}    = $server_xml->{os}->[0]->{bootmenu}->[0]->{enable};
	$anvil->data->{server}{$target}{$server}{$source}{info}{architecture} = $server_xml->{os}->[0]->{type}->[0]->{arch};
	$anvil->data->{server}{$target}{$server}{$source}{info}{machine}      = $server_xml->{os}->[0]->{type}->[0]->{machine};
	$anvil->data->{server}{$target}{$server}{$source}{info}{id}           = exists $server_xml->{id} ? $server_xml->{id} : 0;
	$anvil->data->{server}{$target}{$server}{$source}{info}{emulator}     = $server_xml->{devices}->[0]->{emulator}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{info}{acpi}         = exists $server_xml->{features}->[0]->{acpi} ? 1 : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::info::uuid"         => $anvil->data->{server}{$target}{$server}{$source}{info}{uuid},
		"server::${target}::${server}::${source}::info::name"         => $anvil->data->{server}{$target}{$server}{$source}{info}{name},
		"server::${target}::${server}::${source}::info::on_poweroff"  => $anvil->data->{server}{$target}{$server}{$source}{info}{on_poweroff},
		"server::${target}::${server}::${source}::info::on_crash"     => $anvil->data->{server}{$target}{$server}{$source}{info}{on_crash},
		"server::${target}::${server}::${source}::info::on_reboot"    => $anvil->data->{server}{$target}{$server}{$source}{info}{on_reboot},
		"server::${target}::${server}::${source}::info::architecture" => $anvil->data->{server}{$target}{$server}{$source}{info}{architecture},
		"server::${target}::${server}::${source}::info::machine"      => $anvil->data->{server}{$target}{$server}{$source}{info}{machine},
		"server::${target}::${server}::${source}::info::boot_menu"    => $anvil->data->{server}{$target}{$server}{$source}{info}{boot_menu},
		"server::${target}::${server}::${source}::info::id"           => $anvil->data->{server}{$target}{$server}{$source}{info}{id},
		"server::${target}::${server}::${source}::info::emulator"     => $anvil->data->{server}{$target}{$server}{$source}{info}{emulator},
		"server::${target}::${server}::${source}::info::acpi"         => $anvil->data->{server}{$target}{$server}{$source}{info}{acpi},
	}});
	
	# CPU
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{total_cores}    = $server_xml->{vcpu}->[0]->{content};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{sockets}        = $server_xml->{cpu}->[0]->{topology}->[0]->{sockets};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{cores}          = $server_xml->{cpu}->[0]->{topology}->[0]->{cores};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{threads}        = $server_xml->{cpu}->[0]->{topology}->[0]->{threads};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{model_name}     = $server_xml->{cpu}->[0]->{model}->[0]->{content};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{model_fallback} = $server_xml->{cpu}->[0]->{model}->[0]->{fallback};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{match}          = $server_xml->{cpu}->[0]->{match};
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{vendor}         = $server_xml->{cpu}->[0]->{vendor}->[0];
	$anvil->data->{server}{$target}{$server}{$source}{cpu}{mode}           = $server_xml->{cpu}->[0]->{mode};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::cpu::total_cores"    => $anvil->data->{server}{$target}{$server}{$source}{cpu}{total_cores},
		"server::${target}::${server}::${source}::cpu::sockets"        => $anvil->data->{server}{$target}{$server}{$source}{cpu}{sockets},
		"server::${target}::${server}::${source}::cpu::cores"          => $anvil->data->{server}{$target}{$server}{$source}{cpu}{cores},
		"server::${target}::${server}::${source}::cpu::threads"        => $anvil->data->{server}{$target}{$server}{$source}{cpu}{threads},
		"server::${target}::${server}::${source}::cpu::model_name"     => $anvil->data->{server}{$target}{$server}{$source}{cpu}{model_name},
		"server::${target}::${server}::${source}::cpu::model_fallback" => $anvil->data->{server}{$target}{$server}{$source}{cpu}{model_fallback},
		"server::${target}::${server}::${source}::cpu::match"          => $anvil->data->{server}{$target}{$server}{$source}{cpu}{match},
		"server::${target}::${server}::${source}::cpu::vendor"         => $anvil->data->{server}{$target}{$server}{$source}{cpu}{vendor},
		"server::${target}::${server}::${source}::cpu::mode"           => $anvil->data->{server}{$target}{$server}{$source}{cpu}{mode},
	}});
	foreach my $hash_ref (@{$server_xml->{cpu}->[0]->{feature}})
	{
		my $name                                                                  = $hash_ref->{name};
		   $anvil->data->{server}{$target}{$server}{$source}{cpu}{feature}{$name} = $hash_ref->{policy};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::cpu::feature::${name}" => $anvil->data->{server}{$target}{$server}{$source}{cpu}{feature}{$name},
		}});
		
	}
	
	# Power Management
	$anvil->data->{server}{$target}{$server}{$source}{pm}{'suspend-to-disk'} = $server_xml->{pm}->[0]->{'suspend-to-disk'}->[0]->{enabled};
	$anvil->data->{server}{$target}{$server}{$source}{pm}{'suspend-to-mem'}  = $server_xml->{pm}->[0]->{'suspend-to-mem'}->[0]->{enabled};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::pm::suspend-to-disk" => $anvil->data->{server}{$target}{$server}{$source}{pm}{'suspend-to-disk'},
		"server::${target}::${server}::${source}::pm::suspend-to-mem"  => $anvil->data->{server}{$target}{$server}{$source}{pm}{'suspend-to-mem'},
	}});
	
	# RAM - 'memory' is as set at boot, 'currentMemory' is the RAM used at polling (so only useful when 
	#       running). In the Anvil!, we don't support memory ballooning, so we're use whichever is 
	#       higher.
	my $current_ram_value = $server_xml->{currentMemory}->[0]->{content};
	my $current_ram_unit  = $server_xml->{currentMemory}->[0]->{unit};
	my $current_ram_bytes = $anvil->Convert->human_readable_to_bytes({size => $current_ram_value, type => $current_ram_unit});
	my $ram_value         = $server_xml->{memory}->[0]->{content};
	my $ram_unit          = $server_xml->{memory}->[0]->{unit};
	my $ram_bytes         = $anvil->Convert->human_readable_to_bytes({size => $ram_value, type => $ram_unit});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		current_ram_value => $current_ram_value,
		current_ram_unit  => $current_ram_unit,
		current_ram_bytes => $anvil->Convert->add_commas({number => $current_ram_bytes})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $current_ram_bytes}).")",
		ram_value         => $ram_value,
		ram_unit          => $ram_unit,
		ram_bytes         => $anvil->Convert->add_commas({number => $ram_bytes})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $ram_bytes}).")",
	}});
	
	$anvil->data->{server}{$target}{$server}{$source}{memory} = $current_ram_bytes > $ram_bytes ? $current_ram_bytes : $ram_bytes;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::memory" => $anvil->Convert->add_commas({number => $anvil->data->{server}{$target}{$server}{$source}{memory}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{server}{$target}{$server}{$source}{memory}}).")",
	}});
	
	# Clock info
	$anvil->data->{server}{$target}{$server}{$source}{clock}{offset} = $server_xml->{clock}->[0]->{offset};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::clock::offset" => $anvil->data->{server}{$target}{$server}{$source}{clock}{offset},
	}});
	foreach my $hash_ref (@{$server_xml->{clock}->[0]->{timer}})
	{
		my $name = $hash_ref->{name};
		foreach my $variable (keys %{$hash_ref})
		{
			next if $variable eq "name";
			$anvil->data->{server}{$target}{$server}{$source}{clock}{$name}{$variable} = $hash_ref->{$variable};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::clock::${name}::${variable}" => $anvil->data->{server}{$target}{$server}{$source}{clock}{$name}{$variable},
			}});
		}
	}
	
	# Pull out my channels
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{channel}})
	{
		my $type = $hash_ref->{type};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { type => $type }});
		if ($type eq "unix")
		{
			# Bus stuff
			my $address_type       = $hash_ref->{address}->[0]->{type};
			my $address_controller = $hash_ref->{address}->[0]->{controller};
			my $address_bus        = $hash_ref->{address}->[0]->{bus};
			my $address_port       = $hash_ref->{address}->[0]->{port};
			
			# Store
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{source}{mode}        = defined $hash_ref->{source}->[0]->{mode} ? $hash_ref->{source}->[0]->{mode} : "";
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{source}{path}        = defined $hash_ref->{source}->[0]->{path} ? $hash_ref->{source}->[0]->{path} : "";
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{alias}               = defined $hash_ref->{alias}->[0]->{name}  ? $hash_ref->{alias}->[0]->{name}  : "";
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{type}       = $address_type;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{bus}        = $address_bus;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{controller} = $address_controller;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{port}       = $address_port;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{target}{type}        = $hash_ref->{target}->[0]->{type};
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{target}{'state'}     = defined $hash_ref->{target}->[0]->{'state'} ? $hash_ref->{target}->[0]->{'state'} : "";
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{target}{name}        = $hash_ref->{target}->[0]->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::channel::unix::source::mode"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{source}{mode},
				"server::${target}::${server}::${source}::device::channel::unix::source::path"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{source}{path},
				"server::${target}::${server}::${source}::device::channel::unix::alias"               => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{alias},
				"server::${target}::${server}::${source}::device::channel::unix::address::type"       => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{type},
				"server::${target}::${server}::${source}::device::channel::unix::address::bus"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{bus},
				"server::${target}::${server}::${source}::device::channel::unix::address::controller" => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{controller},
				"server::${target}::${server}::${source}::device::channel::unix::address::port"       => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{address}{port},
				"server::${target}::${server}::${source}::device::channel::unix::target::type"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{target}{type},
				"server::${target}::${server}::${source}::device::channel::unix::target::state"       => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{target}{'state'},
				"server::${target}::${server}::${source}::device::channel::unix::target::name"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{unix}{target}{name},
			}});
			
			### TODO: Store the parts in some format that allows representing it better to the user and easier to find "open slots".
			# Add to system bus list
# 			$anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port} = "channel - ".$type;
# 			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 				"server::${target}::${server}::${source}::address::${address_type}::controller::${address_controller}::bus::${address_bus}::port::${address_port}" => $anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port},
# 			}});
		}
		elsif ($type eq "spicevmc")
		{
			# Bus stuff
			my $address_type       = $hash_ref->{address}->[0]->{type};
			my $address_controller = $hash_ref->{address}->[0]->{controller};
			my $address_bus        = $hash_ref->{address}->[0]->{bus};
			my $address_port       = $hash_ref->{address}->[0]->{port};
			
			# Store
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{alias}               = defined $hash_ref->{alias}->[0]->{name} ? $hash_ref->{alias}->[0]->{name} : "";
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{type}       = $address_type;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{bus}        = $address_bus;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{controller} = $address_controller;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{port}       = $address_port;
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{target}{type}        = $hash_ref->{target}->[0]->{type};
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{target}{'state'}     = defined $hash_ref->{target}->[0]->{'state'} ? $hash_ref->{target}->[0]->{'state'} : "";
			$anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{target}{name}        = $hash_ref->{target}->[0]->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::channel::spicevmc::alias"               => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{alias},
				"server::${target}::${server}::${source}::device::channel::spicevmc::address::type"       => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{type},
				"server::${target}::${server}::${source}::device::channel::spicevmc::address::bus"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{bus},
				"server::${target}::${server}::${source}::device::channel::spicevmc::address::controller" => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{controller},
				"server::${target}::${server}::${source}::device::channel::spicevmc::address::port"       => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{address}{port},
				"server::${target}::${server}::${source}::device::channel::spicevmc::target::type"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{target}{type},
				"server::${target}::${server}::${source}::device::channel::spicevmc::target::state"       => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{target}{'state'},
				"server::${target}::${server}::${source}::device::channel::spicevmc::target::name"        => $anvil->data->{server}{$target}{$server}{$source}{device}{channel}{spicevmc}{target}{name},
			}});
			
			### TODO: Store the parts in some format that allows representing it better to the user and easier to find "open slots".
			# Add to system bus list
# 			$anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port} = "channel - ".$type;
# 			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 				"server::${target}::${server}::${source}::address::${address_type}::controller::${address_controller}::bus::${address_bus}::port::${address_port}" => $anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port},
# 			}});
		}
	}
	
	# Pull out console data
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{console}})
	{
		$anvil->data->{server}{$target}{$server}{$source}{device}{console}{type}        = $hash_ref->{type};
		$anvil->data->{server}{$target}{$server}{$source}{device}{console}{tty}         = defined $hash_ref->{tty}                 ? $hash_ref->{tty}                 : "";
		$anvil->data->{server}{$target}{$server}{$source}{device}{console}{alias}       = defined $hash_ref->{alias}->[0]->{name}  ? $hash_ref->{alias}->[0]->{name}  : "";
		$anvil->data->{server}{$target}{$server}{$source}{device}{console}{source}      = defined $hash_ref->{source}->[0]->{path} ? $hash_ref->{source}->[0]->{path} : "";
		$anvil->data->{server}{$target}{$server}{$source}{device}{console}{target_type} = $hash_ref->{target}->[0]->{type};
		$anvil->data->{server}{$target}{$server}{$source}{device}{console}{target_port} = $hash_ref->{target}->[0]->{port};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::device::console::type"        => $anvil->data->{server}{$target}{$server}{$source}{device}{console}{type},
			"server::${target}::${server}::${source}::device::console::tty"         => $anvil->data->{server}{$target}{$server}{$source}{device}{console}{tty},
			"server::${target}::${server}::${source}::device::console::alias"       => $anvil->data->{server}{$target}{$server}{$source}{device}{console}{alias},
			"server::${target}::${server}::${source}::device::console::source"      => $anvil->data->{server}{$target}{$server}{$source}{device}{console}{source},
			"server::${target}::${server}::${source}::device::console::target_type" => $anvil->data->{server}{$target}{$server}{$source}{device}{console}{target_type},
			"server::${target}::${server}::${source}::device::console::target_port" => $anvil->data->{server}{$target}{$server}{$source}{device}{console}{target_port},
		}});
	}
	
	# Controllers is a big chunk
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{controller}})
	{
		my $type             = $hash_ref->{type};
		my $index            = $hash_ref->{'index'};
		my $ports            = exists $hash_ref->{ports}                     ? $hash_ref->{ports}                    : "";
		my $target_chassis   = exists $hash_ref->{target}                    ? $hash_ref->{target}->[0]->{chassis}   : "";
		my $target_port      = exists $hash_ref->{target}                    ? $hash_ref->{target}->[0]->{port}      : "";
		my $address_type     = defined $hash_ref->{address}->[0]->{type}     ? $hash_ref->{address}->[0]->{type}     : "";
		my $address_domain   = defined $hash_ref->{address}->[0]->{domain}   ? $hash_ref->{address}->[0]->{domain}   : "";
		my $address_bus      = defined $hash_ref->{address}->[0]->{bus}      ? $hash_ref->{address}->[0]->{bus}      : "";
		my $address_slot     = defined $hash_ref->{address}->[0]->{slot}     ? $hash_ref->{address}->[0]->{slot}     : "";
		my $address_function = defined $hash_ref->{address}->[0]->{function} ? $hash_ref->{address}->[0]->{function} : "";
		
		# Model is weird, it can be at '$hash_ref->{model}->[X]' or '$hash_ref->{model}->[Y]->{name}'
		# as 'model' is both an attribute and a child element.
		$hash_ref->{model} = "" if not defined $hash_ref->{model};
		my $model = "";
		if (not ref($hash_ref->{model}))
		{
			$model = $hash_ref->{model};
		}
		else
		{
			foreach my $entry (@{$hash_ref->{model}})
			{
				if (ref($entry))
				{
					$model = $entry->{name} if $entry->{name};
				}
				else
				{
					$model = $entry if $entry;
				}
			}
		}
		
		# Store the data
		$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{alias} = defined $hash_ref->{alias}->[0]->{name} ? $hash_ref->{alias}->[0]->{name} : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::alias" => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{alias},
		}});
		if ($model)
		{
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{model} = $model;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::model" => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{model},
			}});
		}
		if ($ports)
		{
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{ports} = $ports;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::ports" => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{ports},
			}});
		}
		if ($target_chassis)
		{
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{chassis} = $target_chassis;
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{port}    = $target_port;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::target::chassis" => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{chassis},
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::target::port"    => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{port},
			}});
		}
		if ($address_type)
		{
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{type}     = $address_type;
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{domain}   = $address_domain;
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{bus}      = $address_bus;
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{slot}     = $address_slot;
			$anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{function} = $address_function;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::address::type"     => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{type},
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::address::domain"   => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{domain},
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::address::bus"      => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{bus},
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::address::slot"     => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{slot},
				"server::${target}::${server}::${source}::device::controller::${type}::index::${index}::address::function" => $anvil->data->{server}{$target}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{function},
			}});
			
			### TODO: Store the parts in some format that allows representing it better to the user and easier to find "open slots".
			# Add to system bus list
			# Controller type: [pci], alias: (pci.2), index: [2]
			# - Model: [pcie-root-port]
			# - Target chassis: [2], port: [0x11]
			# - Bus type: [pci], domain: [0x0000], bus: [0x00], slot: [0x02], function: [0x1]
			#      server::test_server::from_virsh::address::virtio-serial::controller::0::bus::0::port::2: [channel - spicevmc]
# 			$anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$type}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain} = $address_domain;
# 			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 				"server::${target}::${server}::${source}::address::${address_type}::controller::${type}::bus::${address_bus}::slot::${address_slot}::function::${address_function}::domain" => $anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$type}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain},
# 			}});
		}
	}
	
	# Find what drives (disk and "optical") this server uses.
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{disk}})
	{
		#print Dumper $hash_ref;
		my $device        = $hash_ref->{device};
		my $device_target = $hash_ref->{target}->[0]->{dev};
		my $type          = defined $hash_ref->{type}                 ? $hash_ref->{type}                 : "";
		my $alias         = defined $hash_ref->{alias}->[0]->{name}   ? $hash_ref->{alias}->[0]->{name}   : "";
		my $device_bus    = defined $hash_ref->{target}->[0]->{bus}   ? $hash_ref->{target}->[0]->{bus}   : "";
		my $address_type  = defined $hash_ref->{address}->[0]->{type} ? $hash_ref->{address}->[0]->{type} : "";
		my $address_bus   = defined $hash_ref->{address}->[0]->{bus}  ? $hash_ref->{address}->[0]->{bus}  : "";
		my $boot_order    = defined $hash_ref->{boot}->[0]->{order}   ? $hash_ref->{boot}->[0]->{order}   : 99;
		my $driver_name   = defined $hash_ref->{driver}->[0]->{name}  ? $hash_ref->{driver}->[0]->{name}  : "";
		my $driver_type   = defined $hash_ref->{driver}->[0]->{type}  ? $hash_ref->{driver}->[0]->{type}  : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			device        => $device,
			type          => $type,
			alias         => $alias, 
			device_target => $device_target, 
			device_bus    => $device_bus, 
			address_type  => $address_type, 
			address_bus   => $address_bus, 
			boot_order    => $boot_order, 
			driver_name   => $driver_name, 
			driver_type   => $driver_type,
		}});
		
		### NOTE: Live migration won't work unless the '/dev/drbdX' devices are block. If they come 
		###       up as 'file', virsh will refuse to migrate with a lack of shared storage error.
		# A device path can come from 'dev' or 'file'.
		my $device_path = "";
		if (defined $hash_ref->{source}->[0]->{dev})
		{
			$device_path = $hash_ref->{source}->[0]->{dev};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device_path => $device_path }});
		}
		else
		{
			$device_path = $hash_ref->{source}->[0]->{file};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device_path => $device_path }});
		}
		
		# Record common data
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{alias}         = $alias;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{boot_order}    = $boot_order;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{type}          = $type;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{type} = $address_type;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{bus}  = $address_bus;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{name}  = $driver_name;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{device_bus}    = $device_bus;
		$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{type}  = $driver_type;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::type" => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{type},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::bus"  => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{bus},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::alias"         => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{alias},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::boot_order"    => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{boot_order},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::device_bus"    => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{device_bus},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::driver::name"  => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{name},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::driver::type"  => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{type},
			"server::${target}::${server}::${source}::device::${device}::target::${device_target}::type"          => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{type},
		}});
		
		# Record type-specific data
		if ($device eq "disk")
		{
			my $address_slot     = defined $hash_ref->{address}->[0]->{slot}     ? $hash_ref->{address}->[0]->{slot}     : "";
			my $address_domain   = defined $hash_ref->{address}->[0]->{domain}   ? $hash_ref->{address}->[0]->{domain}   : "";
			my $address_function = defined $hash_ref->{address}->[0]->{function} ? $hash_ref->{address}->[0]->{function} : "";
			my $driver_io        = defined $hash_ref->{driver}->[0]->{io}        ? $hash_ref->{driver}->[0]->{io}        : "";
			my $driver_cache     = defined $hash_ref->{driver}->[0]->{cache}     ? $hash_ref->{driver}->[0]->{cache}     : "";
			
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{domain}   = $address_domain;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{slot}     = $address_slot;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{function} = $address_function;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{path}              = $device_path;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{io}        = $driver_io;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{cache}     = $driver_cache;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::domain"   => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{domain},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::slot"     => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{slot},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::function" => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{function},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::path"              => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{path},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::driver::io"        => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{io},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::driver::cache"     => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{cache},
			}});
			
			my $on_lv    = defined $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{on}       ? $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{on}       : "";
			my $resource = defined $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{resource} ? $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{resource} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				on_lv    => $on_lv,
				resource => $resource, 
			}});
			if ((not $resource) && ($anvil->data->{drbd}{config}{$host}{'by-res'}{$device_path}{resource}))
			{
				$resource = $anvil->data->{drbd}{config}{$host}{'by-res'}{$device_path}{resource};
				$on_lv    = $anvil->data->{drbd}{config}{$host}{'by-res'}{$device_path}{backing_lv};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					on_lv    => $on_lv,
					resource => $resource, 
				}});
			}
			
			$anvil->data->{server}{$target}{$server}{device}{$device_path}{on_lv}    = $on_lv;
			$anvil->data->{server}{$target}{$server}{device}{$device_path}{resource} = $resource;
			$anvil->data->{server}{$target}{$server}{device}{$device_path}{target}   = $device_target;
			$anvil->data->{server}{$target}{$server}{resource}{$resource}            = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				host                                                             => $host,
				"server::${target}::${server}::device::${device_path}::on_lv"    => $anvil->data->{server}{$target}{$server}{device}{$device_path}{on_lv},
				"server::${target}::${server}::device::${device_path}::resource" => $anvil->data->{server}{$target}{$server}{device}{$device_path}{resource},
				"server::${target}::${server}::device::${device_path}::target"   => $anvil->data->{server}{$target}{$server}{device}{$device_path}{target},
				"server::${target}::${server}::resource::${resource}"            => $anvil->data->{server}{$target}{$server}{resource}{$resource}, 
			}});
			
			# Keep a list of DRBD resources used by this server.
			my $drbd_resource                                                           = $anvil->data->{server}{$target}{$server}{device}{$device_path}{resource};
			   $anvil->data->{server}{$target}{$server}{drbd}{resource}{$drbd_resource} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::drbd::resource::${drbd_resource}" => $anvil->data->{server}{$target}{$server}{drbd}{resource}{$drbd_resource},
			}});
			
			### TODO: Store the parts in some format that allows representing it better to the user and easier to find "open slots".
# 			$anvil->data->{server}{$target}{$server}{$source}{address}{$device_bus}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain} = $address_domain;
# 			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 				"server::${target}::${server}::${source}::address::${address_type}::controller::${type}::bus::${address_bus}::slot::${address_slot}::function::${address_function}::domain" => $anvil->data->{server}{$target}{$server}{$source}{address}{$address_type}{controller}{$type}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain},
# 			}});
		}
		else
		{
			# Looks like IDE is no longer supported on RHEL 8.
			my $address_controller = $hash_ref->{address}->[0]->{controller};
			my $address_unit       = $hash_ref->{address}->[0]->{unit};
			my $address_target     = $hash_ref->{address}->[0]->{target};
			
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{controller} = $address_controller;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{unit}       = $address_unit;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{target}     = $address_target;
			$anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{path}                = $device_path;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::controller" => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{controller},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::unit"       => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{unit},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::target"     => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{target},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::path"                => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{path},
			}});
		
		}
	}
	
	# Pull out network data
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{interface}})
	{
		#print Dumper $hash_ref;
		my $mac = $hash_ref->{mac}->[0]->{address};
		
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{bridge}            = $hash_ref->{source}->[0]->{bridge};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{alias}             = defined $hash_ref->{alias}->[0]->{name} ? $hash_ref->{alias}->[0]->{name} : "";
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{target}            = defined $hash_ref->{target}->[0]->{dev} ? $hash_ref->{target}->[0]->{dev} : "";
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{model}             = $hash_ref->{model}->[0]->{type};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{bus}      = $hash_ref->{address}->[0]->{bus};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{domain}   = $hash_ref->{address}->[0]->{domain};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{type}     = $hash_ref->{address}->[0]->{type};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{slot}     = $hash_ref->{address}->[0]->{slot};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{function} = $hash_ref->{address}->[0]->{function};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::device::interface::${mac}::bridge"            => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{bridge},
			"server::${target}::${server}::${source}::device::interface::${mac}::alias"             => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{alias},
			"server::${target}::${server}::${source}::device::interface::${mac}::target"            => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{target},
			"server::${target}::${server}::${source}::device::interface::${mac}::model"             => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{model},
			"server::${target}::${server}::${source}::device::interface::${mac}::address::bus"      => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{bus},
			"server::${target}::${server}::${source}::device::interface::${mac}::address::domain"   => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{domain},
			"server::${target}::${server}::${source}::device::interface::${mac}::address::type"     => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{type},
			"server::${target}::${server}::${source}::device::interface::${mac}::address::slot"     => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{slot},
			"server::${target}::${server}::${source}::device::interface::${mac}::address::function" => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{function},
		}});
	}
	
	return(0);
}


=head2 shutdown_virsh

This takes a server name and tries to shut it down. If the server was found locally, the shut down is requested and this method will wait for the server to actually shut down before returning.

If shut down, C<< 1 >> is returned. If the server wasn't found or another problem occurs, C<< 0 >> is returned.

 my ($shutdown) = $anvil->Server->shutdown_virsh({server => "test_server"});

Parameters;

=head3 force (optional, default '0')

Normally, a graceful shutdown is requested. This requires that the guest respond to ACPI power button events. If the guest won't respond, or for some other reason you want to immediately force the server off, set this to C<< 1 >>.

B<WARNING>: Setting this to C<< 1 >> results in the immediate shutdown of the server! Same as if you pulled the power out of a traditional machine.

=head3 server (required)

This is the name of the server (as it appears in C<< virsh >>) to shut down.

=head3 wait_time (optional, default '0', wait indefinitely)

By default, this method will wait indefinetly for the server to shut down before returning. If this is set to a non-zero number, the method will wait that number of seconds for the server to shut dwwn. If the server is still not off by then, C<< 0 >> is returned.

Setting this to C<< 1 >> effectively disables waiting.

=cut
sub shutdown_virsh
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->shutdown_virsh()" }});
	
	my $server      = defined $parameter->{server}    ? $parameter->{server}    : "";
	my $force       = defined $parameter->{force}     ? $parameter->{force}     : 0;
	my $wait_time   = defined $parameter->{wait_time} ? $parameter->{wait_time} : 0;
	my $success     = 0;
	my $server_uuid = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		force     => $force, 
		server    => $server, 
		wait_time => $wait_time, 
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->shutdown_virsh()", parameter => "server" }});
		return($success);
	}
	if (($wait_time) && ($wait_time =~ /\D/))
	{
		# Bad value.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0422", variables => { server => $server, wait_time => $wait_time }});
		return($success);
	}
	
	# Is the server running? 
	$anvil->Server->find({debug => $debug});
	
	# And?
	if (exists $anvil->data->{server}{location}{$server})
	{
		my $shutdown = 1;
		my $status   = $anvil->data->{server}{location}{$server}{status};
		my $task     = "shutdown";
		if ($force)
		{
			$task = "destroy";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "log_0424", variables => { server => $server }});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0425", variables => { server => $server }});
		}
		if ($status eq "shut off")
		{
			# Already off. 
			$success = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0423", variables => { server => $server }});
			return($success);
		}
		elsif ($status eq "paused")
		{
			# The server is paused. Resume it, wait a few, then proceed with the shutdown.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0314", variables => { server => $server }});
			my ($output, $return_code) = $anvil->System->call({shell_call =>  $anvil->data->{path}{exe}{virsh}." resume $server"});
			if ($return_code)
			{
				# Looks like virsh isn't running.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0315", variables => { 
					server      => $server,
					return_code => $return_code, 
					output      => $output, 
				}});
				$anvil->nice_exit({exit_code => 1});
			}
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0316"});
			sleep 3;
		}
		elsif ($status eq "pmsuspended")
		{
			# The server is suspended. Resume it, wait a few, then proceed with the shutdown.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0317", variables => { server => $server }});
			my ($output, $return_code) = $anvil->System->call({shell_call =>  $anvil->data->{path}{exe}{virsh}." dompmwakeup $server"});
			if ($return_code)
			{
				# Looks like virsh isn't running.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0318", variables => { 
					server      => $server,
					return_code => $return_code, 
					output      => $output, 
				}});
				$anvil->nice_exit({exit_code => 1});
			}
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0319"});
			sleep 30;
		}
		elsif (($status eq "idle") or ($status eq "crashed"))
		{
			# The server needs to be destroyed.
			$task = "destroy";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0322", variables => { 
				server => $server,
				status => $status, 
			}});
		}
		elsif ($status eq "in shutdown")
		{
			# The server is already shutting down
			$shutdown = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0320", variables => { server => $server }});
		}
		elsif ($status ne "running")
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0325", variables => { 
				server => $server,
				status => $status, 
			}});
			return($success);
		}
		
		# Shut it down.
		if ($shutdown)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::database::connections" => $anvil->data->{sys}{database}{connections} }});
			if ($anvil->data->{sys}{database}{connections})
			{
				my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
				
				$server_uuid = $anvil->Get->server_uuid_from_name({
					debug       => $debug, 
					server_name => $server, 
					anvil_uuid  => $anvil_uuid,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
				if (($server_uuid) && ($server_uuid ne "!!error!!"))
				{
					$anvil->Database->get_servers({debug => $debug});
					if (exists $anvil->data->{servers}{server_uuid}{$server_uuid})
					{
						my $old_state = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_state => $old_state }});
						
						if ($old_state ne "in shutdown")
						{
							# Update it.
							my $query = "
UPDATE 
    servers 
SET 
    server_state  = 'in shutdown',
    modified_date = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid   = ".$anvil->Database->quote($server_uuid)."
;";
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
							$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
						}
					}
				}
			}
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0520", variables => { server => $server }});
			my ($output, $return_code) = $anvil->System->call({
				debug      => $debug, 
				shell_call => $anvil->data->{path}{exe}{virsh}." ".$task." ".$server,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
		}
	}
	else
	{
		# Server wasn't found, assume it's off.
		$success = 1;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0423", variables => { server => $server }});
		return($success);
	}
	
	# Wait indefinetely for the server to exit.
	my $stop_waiting = 0;
	if ($wait_time)
	{
		$stop_waiting = time + $wait_time;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { stop_waiting => $stop_waiting }});
	};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wait_time => $wait_time }});
	until($success)
	{
		# Update
		$anvil->Server->find({debug => $debug});
		if ((exists $anvil->data->{server}{location}{$server}) && ($anvil->data->{server}{location}{$server}{status}))
		{
			my $status = $anvil->data->{server}{location}{$server}{status};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { status => $status }});
			
			if ($status eq "shut off")
			{
				# Success! It should be undefined, but we're not the place to worry about 
				# that.
				$success = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0426", variables => { server => $server }});
			}
		}
		else
		{
			# Success!
			$success = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0426", variables => { server => $server }});
			
			# Mark it as stopped now. (if we have a server_uuid, we have a database connection)
			if ($server_uuid)
			{
				$anvil->Database->get_servers({debug => $debug});
				if (exists $anvil->data->{servers}{server_uuid}{$server_uuid})
				{
					my $old_state = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_state => $old_state }});
					
					if ($old_state ne "shut off")
					{
						# Update it.
						my $query = "
UPDATE 
    servers 
SET 
    server_state     = 'shut off', 
    server_boot_time = 0, 
    server_host_uuid = NULL, 
    modified_date    = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    server_uuid      = ".$anvil->Database->quote($server_uuid)."
;";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
						$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
					}
				}
			}
		}
		
		if (($stop_waiting) && (time > $stop_waiting))
		{
			# Give up waiting.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0427", variables => { 
				server    => $server,
				wait_time => $wait_time,
			}});
		}
		else
		{
			# Sleep a second and then try again.
			sleep 1;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { success => $success }});
	return($success);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################


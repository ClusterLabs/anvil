package Anvil::Tools::Server;
# 
# This module contains methods used to manager servers
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Text::Diff;
use Sys::Virt;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Server.pm";

### Methods;
# active_migrations
# boot_virsh
# connect_to_virsh
# count_servers
# find			# To be replaced by Server->locate();
# find_processes
# get_definition
# get_runtime
# get_server_ports
# get_status
# locate
# map_network
# migrate_virsh
# parse_definition
# shutdown_virsh
# update_definition

=cut TODO

Move all virsh calls over to using Sys::Virt;

Example;

 #!/usr/bin/perl
 use strict;
 use warnings;
 use Sys::Virt;

 # https://metacpan.org/pod/Sys::Virt::Domain
 # https://libvirt.org/api.html

 my $uri        = "qemu:///system";
 my $connection = Sys::Virt->new(uri => $uri);
 my @domains    = $connection->list_domains();
 foreach my $domain (@domains)
 {
	print $log_fh "Domain: [".$domain->get_name."], UUID: [".$domain->get_uuid_string()."]\n";
 	print $log_fh "Definition: [".$domain->get_xml_description."]\n";
 }

=cut

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
		shell_call => $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." create ".$definition,
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
			
			# Make sure the VNC port is open.
			$anvil->Network->manage_firewall({debug => $debug});
			
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

=head2 connect_to_libvirt

This creates a connection to the libvirtd daemon on the target host. The connection to the host will be stored in:

* libvirtd::<target>::connection

If the connection succeeds, C<< 0 >> will be returned. If the connection fails, C<< 1 >> will be returned.

parameters

=head3 server_name (optional)

If this is set to the name of a server, that server will be searched for and, if found, the handle to it will be stored in:

* libvirtd::<target>::server::<server_name>::connection

If the server is not found, that will be set to C<< 0 >>.

B<< Note >>: This can be set to C<< all >> and all servers we can connect to will be stored.

=head3 target (optional, default is the local short host name)

This is the target to connect to. 

B<< Note >>: Don't use C<< localhost >>! If you do, it will be changed to the short host name. This is because C<< localhost >> is converted to C<< ::1 >> which can cause connection problems.

=head3 target_ip (optional)

If this is set, when building the URI, this IP or host name is used to connect. This allows the hash to use the C<< target >> name separately.

=cut
sub connect_to_libvirt
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->connect_to_libvirt()" }});
	
	my $server_name = defined $parameter->{server_name} ? $parameter->{server_name} : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $target_ip   = defined $parameter->{target_ip}   ? $parameter->{target_ip}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server_name => $server_name, 
		target      => $target, 
		target_ip   => $target_ip, 
	}});
	
	if ((not $target) or ($target eq "localhost"))
	{
		# Change to the short host name.
		$target = $anvil->Get->short_host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target => $target }});
	}
	
	if (not $target_ip)
	{
		$target_ip = $target;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_ip => $target_ip }});
	}
	
	# Does the handle already exist?
	if ((exists $anvil->data->{libvirtd}{$target}) && (ref($anvil->data->{libvirtd}{$target}{connection}) eq "Sys::Virt"))
	{
		# Is this connection alive?
		my $info = $anvil->data->{libvirtd}{$target}{connection}->get_node_info();
		if (ref($info) eq "HASH")
		{
			# No need to connect.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0814", variables => { target => $target }});
		}
		else
		{
			# Stale connection.
			$anvil->data->{libvirtd}{$target}{connection} = "";
		}
	}
	else
	{
		$anvil->data->{libvirtd}{$target}{connection} = "";
	}
	
	# If we don't have a connection, try to establish one now.
	if (not $anvil->data->{libvirtd}{$target}{connection})
	{
		# Make sure the target is known.
		my $problem = $anvil->Remote->add_target_to_known_hosts({
			debug  => $debug, 
			target => $target_ip, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { problem => $problem }});
		
		### NOTE: For some reason, the below 'alarm'/SIGALRM' hook doesn't work if the ssh target's
		###       fingerprint isn't known, hence the call above. Whatever is causing this though 
		###       could bite us in other ways.
		# Test connect
		my $uri = "qemu+ssh://".$target_ip."/system";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { uri => $uri }});
		eval 
		{
			local $SIG{ALRM} = sub { die "Connection to: [".$uri."] timed out!\n" }; # NB: \n required
			alarm 10;
			$anvil->data->{libvirtd}{$target}{connection} = Sys::Virt->new(uri => $uri); 
			alarm 0;
		};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			"libvirtd::${target}::connection" => $anvil->data->{libvirtd}{$target}{connection},
		}});
		if ($@)
		{
			# Throw an error, then clear the URI so that we just update the DB/on-disk definitions.
			$anvil->data->{libvirtd}{$target}{connection} = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0162", variables => { 
				host_name => $target,
				uri       => $uri,
				error     => $@,
			}});
			return(1);
		}
	}
	
	if (($server_name) && ($server_name ne "all"))
	{
		if (ref($anvil->data->{libvirtd}{$target}{server}{$server_name}{connection}) eq "Sys::Virt::Domain")
		{
			# If this connection still valid?
			my $uuid = $anvil->data->{libvirtd}{$target}{server}{$server_name}{connection}->get_uuid_string();
			if ($uuid)
			{
				# We're good.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0815", variables => { server_name => $server_name }});
				return(0);
			}
			else
			{
				# Stale connection.
				$anvil->data->{libvirtd}{$target}{server}{$server_name}{connection} = "";
			}
		}
		else
		{
			$anvil->data->{libvirtd}{$target}{server}{$server_name}{connection} = "";
		}
	}
	
	# If we have a server name, or if it's 'all', connect.
	if ($server_name)
	{
		my $domain  = "";
		my @domains = $anvil->data->{libvirtd}{$target}{connection}->list_all_domains();
		foreach my $domain_handle (@domains)
		{
			my $this_server_name = $domain_handle->get_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				domain_handle    => $domain_handle, 
				this_server_name => $this_server_name,
			}});
			if (($server_name ne "all") && ($this_server_name ne $server_name))
			{
				next;
			}
			
			$anvil->data->{libvirtd}{$target}{server}{$server_name}{connection} = $domain_handle;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				"libvirtd::${target}::server::${server_name}::connection" => $anvil->data->{libvirtd}{$target}{server}{$server_name}{connection},
			}});
			last;
		}
	}
	
	my $return = 0;
	if (($server_name) && ($server_name ne "all") && (not $anvil->data->{libvirtd}{$target}{server}{$server_name}{connection}))
	{
		# Didn't find the server
		return(1)
	}
	
	return(0);
}

=head2 count_servers

This method counts the number of hosted servers and returns that number. If C<< virsh >> is not available, C<< 0 >> is returned. Note that it's B< possible >>, though unlikely on an Anvil!, that a qemu server is running outside C<< libvirtd >>.

This method takes no parameters.

=cut
sub count_servers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->count_servers()" }});
	
	my $count = 0;
	if (-e $anvil->data->{path}{exe}{virsh})
	{
		my $shell_call = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." list";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call, debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
		
		foreach my $line (split/\n/, $output)
		{
			$line = $anvil->Words->clean_spaces({string => $line});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			
			if ($line =~ /^\d+ (.*) (.*?)$/)
			{
=cut
* Server states;
running     - The domain is currently running on a CPU
idle        - The domain is idle, and not running or runnable.  This can be caused because the domain is waiting on IO (a traditional wait state) or has gone to sleep because there was nothing else for it to do.
paused      - The domain has been paused, usually occurring through the administrator running virsh suspend.  When in a paused state the domain will still consume allocated resources like memory, but will not be eligible for scheduling by the hypervisor.
in shutdown - The domain is in the process of shutting down, i.e. the guest operating system has been notified and should be in the process of stopping its operations gracefully.
shut off    - The domain is not running.  Usually this indicates the domain has been shut down completely, or has not been started.
crashed     - The domain has crashed, which is always a violent ending.  Usually this state can only occur if the domain has been configured not to restart on crash.
pmsuspended - The domain has been suspended by guest power management, e.g. entered into s3 state.
=cut
				my $name   = $1;
				my $status = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					status => $status, 
					name   => $name, 
				}});
				
				if ((lc($status) eq "running")     or 
				    (lc($status) eq "paused")      or 
				    (lc($status) eq "in shutdown") or 
				    (lc($status) eq "pmsuspended"))
				{
					$count++;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
				}
			}
		}
		
	}
	
	return($count);
}


### TODO: Phase this out in favor for Server->locate()
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
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0700", variables => { hash => "server::location" }});
		delete $anvil->data->{server}{location};
	}
	
	my $host_type    = $anvil->Get->host_type({debug => $debug});
	my $host_name    = $anvil->Get->host_name;
	my $virsh_call   = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." list --all";
	my $virsh_output = "";
	my $return_code  = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call
		($virsh_output, my $return_code) = $anvil->System->call({shell_call => $virsh_call});
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
			shell_call  => $virsh_call,
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


=head2 find_processes

Find a list of qemu-kvm processes and extracts server information from the process arguments.

Parameters;

=head3 base_vnc_port (optional)

This value is added to the port offset extracted from -vnc optional to qemu-kvm. Defaults to 5900.

=cut
sub find_processes
{
	my $self          = shift;
	my $parameters    = shift;
	my $anvil         = $self->parent;
	my $base_vnc_port = $parameters->{base_vnc_port} || 5900;
	my $debug         = $parameters->{debug} || 3;
	my $ps_name       = $parameters->{ps_name} // "qemu-kvm";

	$anvil->Log->variables({ source => $THIS_FILE, line => __LINE__, level => $debug, list => $parameters });

	$base_vnc_port = "$base_vnc_port";

	return (1) if (not $base_vnc_port =~ /^\d+$/);

	$base_vnc_port = int($base_vnc_port);

	# Servers only exist on non-striker
	return (1) if ($anvil->data->{sys}{host_type} eq "striker");

	my $nc    = $anvil->data->{path}{exe}{'nc'};
	my $pgrep = $anvil->data->{path}{exe}{'pgrep'};
	my $sed   = $anvil->data->{path}{exe}{'sed'};

	my $ps_call = "$pgrep -a '$ps_name' | $sed -E 's/^.*guest=([^,]+).*-uuid[[:space:]]+([^[:space:]]+)(.*-vnc[[:space:]]+([[:digit:].:]+))?.*\$/\\2,\\1,\\4/'";

	$anvil->Log->variables({ source => $THIS_FILE, line => __LINE__, level => $debug, list => { ps_call => $ps_call }});

	my ($call_output, $call_rcode) = $anvil->System->call({ shell_call => $ps_call });

	return (1) if ($call_rcode != 0);

	my $result = { names => {}, uuids => {} };

	foreach my $line (split(/\n/, $call_output))
	{
		my ($uuid, $name, $vnc) = split(/,/, $line);

		$anvil->Log->variables({ source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			server_name => $name,
			server_uuid => $uuid,
			server_vnc  => $vnc,
		}});

		$result->{uuids}{$uuid} = { name => $name, uuid => $uuid };
		# Record name to UUID mapping
		$result->{names}{$name} = $uuid;

		next if (not $vnc);

		my ($hostname, $port_offset) = split(/:/, $vnc);

		my $vnc_port = $base_vnc_port + int($port_offset);

		$anvil->Log->variables({ source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			server_vnc_hostname    => $hostname,
			server_vnc_port_offset => $port_offset,
			server_vnc_port        => $vnc_port,
		}});

		$result->{uuids}{$uuid}{vnc_port} = $vnc_port;

		my $nc_call = "$nc -z $hostname $vnc_port";

		$anvil->Log->variables({ source => $THIS_FILE, line => __LINE__, level => $debug, list => { nc_call => $nc_call }});

		my ($nc_output, $nc_rcode) = $anvil->System->call({ shell_call => $nc_call });

		$result->{uuids}{$uuid}{vnc_alive} = int($nc_rcode) > 0 ? 0 : 1;
	}

	return (0, $result);
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
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
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
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		foreach my $line (split/\n/, $output)
		{
			$runtime = $anvil->Words->clean_spaces({ string => $line });
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { runtime => $runtime }});
		}
	}
	
	return($runtime);
}


=head2 get_server_ports 

This looks at the servers on this host and finds their graphical type (VNC or spice), and the TCP port the connection is listening on. If there's a websockify proxy port (for server access via the Striker WebUI).

Data is stored in the hash:
 server_ports::<server_name>::host               = The short host name
 server_ports::<server_name>::state              = The state of the server (as a string)(
 server_ports::<server_name>::running            = 0 or 1, indicating if the server is running. If not, the values below are meaningless
 server_ports::<server_name>::graphics::type     = The graphics type, 'vnc' or 'spice'
 server_ports::<server_name>::graphics::port     = The TCP port used to connect to the server's graphics
 server_ports::<server_name>::graphics::ws_proxy = If found, this is the websockify proxy TCP port

This method returns C<< 0 >> if successful. If there's a problem, C<< 1 >> is returned.

This method takes no parameters.

=cut
sub get_server_ports
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->get_status()" }});
	
	my $pids = $anvil->System->pids({
		debug        => $debug,
		ignore_me    => 1,
		program_name => "websockify",
	});

	my $short_host_name = $anvil->Get->short_host_name;
	my $uri             = "qemu+ssh://".$short_host_name."/system";
	my $connection      = "";
	eval { $connection = Sys::Virt->new(uri => $uri); };
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"connection" => $connection, 
		'$@'         => $@,
	}});
	if ($@)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "warning_0008", variables => { 
			uri   => $uri, 
			error => $@,
		}});
		return(1);
	}
	my $stream  = $connection->new_stream();
	my @domains = $connection->list_all_domains();
	foreach my $domain (@domains)
	{
		my $server_name       = $domain->get_name;
		my $server_id         = $domain->get_id == -1 ? "" : $domain->get_id; 
		my $server_uuid       = $domain->get_uuid_string;
		my $is_updated        = $domain->is_updated();
		my $is_persistent     = $domain->is_persistent();
		my $os_type           = $domain->get_os_type();
		my $active_definition = $domain->get_xml_description();
		my ($state, $reason)  = $domain->get_state();
		my $is_running        = (($state) && ($state != 5)) ? 1 : 0;
		
		### Reasons are dependent on the state. 
		### See: https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainShutdownReason
		my $server_state = "unknown";
		if ($state == 1)    { $server_state = "running"; }	# Server is running.
		elsif ($state == 2) { $server_state = "blocked"; }	# Server is blocked (IO contention?).
		elsif ($state == 3) { $server_state = "paused"; }	# Server is paused (migration target?).
		elsif ($state == 4) { $server_state = "in shutdown"; }	# Server is shutting down.
		elsif ($state == 5) { $server_state = "shut off"; }	# Server is shut off.
		elsif ($state == 6) { $server_state = "crashed"; }	# Server is crashed!
		elsif ($state == 7) { $server_state = "pmsuspended"; }	# Server is suspended.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			server_name   => $server_name,
			server_id     => $server_id, 
			server_uuid   => $server_uuid, 
			is_updated    => $is_updated, 
			is_persistent => $is_persistent, 
			os_type       => $os_type, 
			server_state  => $server_state, 
			is_running    => $is_running, 
			'state'       => $state, 
			reason        => $reason,
		}});
		$anvil->data->{server_ports}{$server_name}{host}    = $short_host_name;
		$anvil->data->{server_ports}{$server_name}{'state'} = $server_state;
		$anvil->data->{server_ports}{$server_name}{running} = $is_running;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:server_ports::${server_name}::host"    => $anvil->data->{server_ports}{$server_name}{host},
			"s2:server_ports::${server_name}::state"   => $anvil->data->{server_ports}{$server_name}{'state'},
			"s3:server_ports::${server_name}::running" => $anvil->data->{server_ports}{$server_name}{running},
		}});
		
		# Find our TCP ports
		$anvil->data->{server_ports}{$server_name}{graphics}{type}     = "";
		$anvil->data->{server_ports}{$server_name}{graphics}{port}     = "";
		$anvil->data->{server_ports}{$server_name}{graphics}{ws_proxy} = "";
		my $source = "from_virsh";
		if ($is_running)
		{
			my $problem = $anvil->Server->parse_definition({
				debug      => 2,
				server     => $server_name,
				source     => $source, 
				definition => $active_definition, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			if (not $problem)
			{
				# Get the VNC port
				my $port    = $anvil->data->{server}{$short_host_name}{$server_name}{$source}{graphics}{port};
				my $address = $anvil->data->{server}{$short_host_name}{$server_name}{$source}{graphics}{listening};
				my $type    = $anvil->data->{server}{$short_host_name}{$server_name}{$source}{graphics}{port_type};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:port"    => $port,
					"s2:address" => $address, 
					"s3:type"    => $type,
				}});
				$anvil->data->{server_ports}{$server_name}{graphics}{type} = $type;
				$anvil->data->{server_ports}{$server_name}{graphics}{port} = $port;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:server_ports::${server_name}::graphics::type" => $anvil->data->{server_ports}{$server_name}{graphics}{type},
					"s2:server_ports::${server_name}::graphics::port" => $anvil->data->{server_ports}{$server_name}{graphics}{port},
				}});
				if ($port)
				{
					foreach my $pid (sort {$a <=> $b} @{$pids})
					{
						my $command = $anvil->data->{pids}{$pid}{command};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:pid"     => $pid,
							"s2:command" => $command,
						}});
						if ($command =~ /anvil-ws-(\d+)-(\d+).log (\d+) :(\d+)$/)
						{
							my $from_websockify = $1;
							my $to_vnc          = $2;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"s1:from_websockify" => $from_websockify,
								"s2:to_vnc"          => $to_vnc,
							}});
							if ($to_vnc eq $port) 
							{
								$anvil->data->{server_ports}{$server_name}{graphics}{ws_proxy} = $from_websockify;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									"s1:server_ports::${server_name}::graphics::ws_proxy" => $anvil->data->{server_ports}{$server_name}{graphics}{ws_proxy},
								}});
								last;
							}
						}
					}
				}
			}
		}
	}
	
	return(0);
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
	my $shell_call = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." dumpxml --inactive ".$server;
	my $this_host  = $anvil->Get->short_host_name;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		shell_call => $shell_call,
		this_host  => $this_host,
	}});
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		($anvil->data->{server}{$host}{$server}{from_virsh}{xml}, $anvil->data->{server}{$host}{$server}{from_virsh}{return_code}) = $anvil->System->call({
			debug      => $debug,
			shell_call => $shell_call,
		});
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
	
	### TODO: Switch to using Server->locate()
	my $shell_call = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." list";
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


=head2 locate

B<< Note >>: This is meant to replace C<< Server->find >>.

This walks through all known and accessible subnodes and DR hosts looking for a server. If a specific server is searched for and it's found running, the C<< short_host_name >> is returned. If there is a problem, C<< !!error!! >> is returned. 

If a specific requested server is found, or is being asked to search for all servers, the following data is stored;

* server_location::host::<short_host_name>::access                                     = [0,1]
* server_location::host::<short_host_name>::server::<server_name>::status              = <status>
* server_location::host::<short_host_name>::server::<server_name>::active_definition   = <XML>
* server_location::host::<short_host_name>::server::<server_name>::inactive_definition = <XML>
* server_location::host::<short_host_name>::server::<server_name>::definition_diff     = <diff>
* server_location::host::<short_host_name>::server::<server_name>::file_definition     = <file_body>
* server_location::host::<short_host_name>::server::<server_name>::drbd_config         = <file_body>

If the target was not accessible, C<< access >> is set to C<< 0 >>. This is meant to allow telling the difference between "we know there's no servers on that host" versus "we don't know what's there because we couldn't access it".

If the server is found to be C<< running >> or C<< paused >>, then C<< active_definition >> is set and, if there's a difference, that will be stored. In all other states, the inactive XML is stored. 

The C<< status >> can be:

* unknown	# The server was found, but it has an unknown state
* running	# Server is running.
* blocked	# Server is blocked (IO contention?).
* paused	# Server is paused (migration target?).
* in shutdown	# Server is shutting down.
* shut off	# Server is shut off.
* crashed	# Server is crashed!
* pmsuspended	# Server is suspended.

If there is a problem, C<< !!error!! >> is returned. If the server is found on at least one host, C<< 0 >> is returned. If the server is not located anywhere, C<< 1 >> is returned. 

If the server has a replicated storage (DRBD) config and/or a definition file, whether the server is found running or not, will be recorded. This can be used to see if the server has been configured to run there or not.

The connection to the host and to the server(s) is cached, for your use;

* server_location::host::<short_host_name>::connection                        = <Sys::Virt object>
* server_location::host::<short_host_name>::server::<server_name>::connection = <Sys::Virt::Domain object>

C<< Note >>: By design, servers are set to 'undefined' on subnodes, so when the server shuts off, it disappears from libvirtd. This is normal and expected.

Parameters;

=head3 anvil (optional, name or uuid)

If set, it restricts the search for a server to a specific Anvil! (and DR hosts, if protected). This will improve search performance on systems with nodes or DR hosts that are offline.

=head3 server_name (required)

This is the name of the server being located. It can be set to C<< all >>, in which case all servers on all hosts are located.

=cut
sub locate
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->locate()" }});
	
	my $anvil_string = defined $parameter->{anvil}       ? $parameter->{anvil}       : "";
	my $server_name  = defined $parameter->{server_name} ? $parameter->{server_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_string => $anvil_string, 
		server_name  => $server_name, 
	}});
	
	if (not $server_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->locate()", parameter => "server_name" }});
		return('!!error!!');
	}
	
	my $anvil_uuid = "";
	my $anvil_name = "";
	if ($anvil_string)
	{
		$anvil_uuid = $anvil->Database->get_anvil_uuid_from_string({
			debug  => $debug, 
			string => $anvil_string,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		if (not $anvil_uuid)
		{
			# Anvil! not found. Will be logged in Database->get_anvil_uuid_from_string().
			return('!!error!!');
		}
		$anvil_name = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
	}
	
	if (exists $anvil->data->{server_location}{host})
	{
		delete $anvil->data->{server_location}{host};
	}
	
	# This will be set if the server is found to be 'running' on a host.
	my $server_host = "";
	
	# Connect to all hosts.
	$anvil->Database->get_hosts({debug => $debug});
	
	if ($anvil_uuid)
	{
		my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		
		$anvil->data->{host_search}{$node1_host_uuid}{short_host_name} = $anvil->data->{hosts}{host_uuid}{$node1_host_uuid}{short_host_name};
		$anvil->data->{host_search}{$node2_host_uuid}{short_host_name} = $anvil->data->{hosts}{host_uuid}{$node2_host_uuid}{short_host_name};

		# Add DR hosts, if any.
		if (exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host})
		{
			foreach my $host_uuid (sort {$a cmp $b} keys %{$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{dr_host}})
			{
				$anvil->data->{host_search}{$host_uuid}{short_host_name} = $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name};
			}
		}
		
		# Log the hosts we'll search (alphabetically).
		foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{sys}{hosts}{by_name}})
		{
			my $host_uuid = $anvil->data->{sys}{hosts}{by_name}{$host_name};
			if (exists $anvil->data->{host_search}{$host_uuid})
			{
				# Searching this 
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:host_name' => $host_name, 
					's2:host_uuid' => $host_uuid, 
				}});
			}
		}
	}
	
	foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{sys}{hosts}{by_name}})
	{
		my $host_uuid       = $anvil->data->{sys}{hosts}{by_name}{$host_name};
		my $host_type       = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}; 
		my $short_host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:host_name'       => $host_name, 
			's2:host_uuid'       => $host_uuid, 
			's3:host_type'       => $host_type, 
			's4:short_host_name' => $short_host_name, 
		}});
		next if $host_type eq "striker";
		
		if ($anvil_uuid)
		{
			# Skip if this isn't a host we're searching.
			if (not exists $anvil->data->{host_search}{$host_uuid})
			{
				next;
			}
		}
		
		# This will switch to '1' if we connect to libvirtd.
		$anvil->data->{server_location}{host}{$short_host_name}{access} = 0;
		
		# What IP to use? Don't test access, it's too slow if there's several down hosts.
		my $target_ip = $anvil->Network->find_target_ip({
			debug       => $debug,
			host_uuid   => $host_uuid, 
			networks    => "bcn,mn,sn,ifn",
			test_access => 0,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_ip => $target_ip }});
		
		if ($target_ip)
		{
			# Try to connect to libvirtd. 
			$anvil->Server->connect_to_libvirt({
				debug       => $debug,
				target      => $short_host_name,
				target_ip   => $target_ip,
				server_name => $server_name,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"libvirtd::${short_host_name}::connection" => $anvil->data->{libvirtd}{$short_host_name}{connection},
			}});
			if (ref($anvil->data->{libvirtd}{$short_host_name}{connection}) eq "Sys::Virt")
			{
				# We're connected! Collect the data on the requested server(s), if applicable.
				$anvil->data->{server_location}{host}{$short_host_name}{access} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"server_location::host::${short_host_name}::access" => $anvil->data->{server_location}{host}{$short_host_name}{access},
				}});
				
				if ($server_name)
				{
					my $connection_handle = $anvil->data->{libvirtd}{$short_host_name}{connection};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connection_handle => $connection_handle }});
					foreach my $this_server_name (sort {$a cmp $b} keys %{$anvil->data->{libvirtd}{$short_host_name}{server}})
					{
						next if (ref($anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}) ne "Sys::Virt::Domain");
						if (($server_name eq "all") or ($server_name eq $this_server_name))
						{
							my $server_handle = $anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_handle => $server_handle }});
							
							# Get the server's state, then convert to a string
							my ($state, $reason) = $server_handle->get_state();
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								'state' => $state, 
								reason  => $reason,
							}});
							
							### Reasons are dependent on the state. 
							### See: https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainShutdownReason
							my $server_state = "unknown";
							if ($state == 1)    { $server_state = "running"; }	# Server is running.
							elsif ($state == 2) { $server_state = "blocked"; }	# Server is blocked (IO contention?).
							elsif ($state == 3) { $server_state = "paused"; }	# Server is paused (migration target?).
							elsif ($state == 4) { $server_state = "in shutdown"; }	# Server is shutting down.
							elsif ($state == 5) { $server_state = "shut off"; }	# Server is shut off.
							elsif ($state == 6) { $server_state = "crashed"; }	# Server is crashed!
							elsif ($state == 7) { $server_state = "pmsuspended"; }	# Server is suspended.
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_state => $server_state }});
							
							# Get the persistent definition
							my $inactive_definition = $server_handle->get_xml_description(Sys::Virt::Domain::XML_INACTIVE);
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { inactive_definition => $inactive_definition }});
							
							# Get the active definition, if applicable.
							my $active_definition = "";
							my $definition_diff   = "";
							if (($server_state eq "running") or ($server_state eq "paused"))
							{
								# Get the active definition
								$active_definition = $server_handle->get_xml_description();
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_definition => $active_definition }});
								
								# Check for a diff.
								$definition_diff = diff \$active_definition, \$inactive_definition, { STYLE => 'Unified' };
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_diff => $definition_diff }});
							}
							
							if ($server_state eq "running")
							{
								$server_host = $short_host_name;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_host => $server_host }});
							}
							
							# If it's running, record the host.
							$anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{status}              = $server_state;
							$anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{active_definition}   = $active_definition;
							$anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{inactive_definition} = $inactive_definition;
							$anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{definition_diff}     = $definition_diff;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"server_location::host::${short_host_name}::server::${server_name}::status"              => $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{status}, 
								"server_location::host::${short_host_name}::server::${server_name}::active_definition"   => $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{active_definition}, 
								"server_location::host::${short_host_name}::server::${server_name}::inactive_definition" => $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{inactive_definition}, 
								"server_location::host::${short_host_name}::server::${server_name}::definition_diff"     => $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{definition_diff}, 
							}});
						}
					}
					
					# If we've connected to the host, see if the XML definition file 
					# and/or DRBD config file exist.
					my $servers = [];
					if ($server_name eq "all")
					{
						# Search for any server we can find.
						$anvil->Database->get_servers();
						foreach my $server_uuid (sort {$a cmp $b} keys %{$anvil->data->{servers}{server_uuid}})
						{
							next if $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state} eq "DELETED";
							my $this_server_name = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_name};
							
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								server_uuid      => $server_uuid,
								this_server_name => $this_server_name, 
							}});
							push @{$servers}, $this_server_name;
						}
					}
					else
					{
						push @{$servers}, $server_name;
					}
					
					foreach my $this_server_name (sort {$a cmp $b} @{$servers})
					{
						# Look for the files for the specified server.
						$anvil->data->{server_location}{host}{$short_host_name}{server}{$this_server_name}{file_definition} = "";
						$anvil->data->{server_location}{host}{$short_host_name}{server}{$this_server_name}{drbd_config}     = "";
						
						# See if there's a definition file and/or a DRBD 
						# config file on this host.
						my $definition_file  = $anvil->data->{path}{directories}{shared}{definitions}."/".$this_server_name.".xml";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_file => $definition_file }});
						
						# Can I read the definition file?
						my $definition_body = $anvil->Storage->read_file({
							debug  => $debug, 
							file   => $definition_file, 
							target => $target_ip, 
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { definition_body => $definition_body }});
						
						if (($definition_body) && ($definition_body ne "!!error!!"))
						{
							$anvil->data->{server_location}{host}{$short_host_name}{server}{$this_server_name}{file_definition} = $definition_body;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"server_location::host::${short_host_name}::server::${this_server_name}::file_definition" => $anvil->data->{server_location}{host}{$short_host_name}{server}{$this_server_name}{file_definition}, 
							}});
						}
						
						my $drbd_config_file = $anvil->data->{path}{directories}{drbd_resources}."/".$this_server_name.".res";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { drbd_config_file => $drbd_config_file }});
						
						my $drbd_body = $anvil->Storage->read_file({
							debug  => $debug, 
							file   => $drbd_config_file, 
							target => $target_ip, 
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { drbd_body => $drbd_body }});
						if (($drbd_body) && ($drbd_body ne "!!error!!"))
						{
							$anvil->data->{server_location}{host}{$short_host_name}{server}{$this_server_name}{drbd_config} = $drbd_body;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"server_location::host::${short_host_name}::server::${this_server_name}::drbd_config" => $anvil->data->{server_location}{host}{$short_host_name}{server}{$this_server_name}{drbd_config}, 
							}});
						}
					}
				}
			} 
		}
	}
	
	return($server_host);
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

=head3 target (optional, default is the full local host name)

This is the host name (or IP) of the host that the server will be pushed to, if C<< source >> is not set. When this is not passed, the local full host name is used as default.

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
	my $resources_to_disable_dual_primary = [];
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{server}{$source}{$server}{resource}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		my ($return_code) = $anvil->DRBD->allow_two_primaries({
			debug    => 2, 
			resource => $resource, 
			set_to   => "yes",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
		
		if ($return_code) 
		{
			# Abort the migration.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "error_0422", variables => { 
				server_name => $server,
				return_code => $return_code, 
			}});
			return(0);
		}
		
		push @{$resources_to_disable_dual_primary}, $resource;
	}
	
	### NOTE: This method is called by ocf:alteeve:server, which operates without database access. As 
	###       such, queries need to be run only if we've got one or more DB connections.
	# Mark this server as being in a migration state.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		"sys::database::connections" => $anvil->data->{sys}{database}{connections},
	}});
	if ($anvil->data->{sys}{database}{connections})
	{
		$anvil->Database->get_servers({debug => 2});
	}
	my $migation_started = time;
	my $server_uuid      = "";
	my $old_server_state = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { migation_started => $migation_started }});
	foreach my $this_server_uuid (keys %{$anvil->data->{servers}{server_uuid}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
			this_server_uuid                                         => $this_server_uuid,
			"servers::server_uuid::${this_server_uuid}::server_name" => $anvil->data->{servers}{server_uuid}{$this_server_uuid}{server_name},
		}});
		if ($server eq $anvil->data->{servers}{server_uuid}{$this_server_uuid}{server_name})
		{
			$server_uuid = $this_server_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
			last;
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		server_uuid                  => $server_uuid,
		"sys::database::connections" => $anvil->data->{sys}{database}{connections},
	}});
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
	
	# We default to live migrations, but will remove that switch if it's been set to false.
	my $live_migrate = "--live";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		server_uuid                                                   => $server_uuid,
		"servers::server_uuid::${server_uuid}::server_live_migration" => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration},
	}});
	if (($server_uuid) && (not $anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration}))
	{
		$live_migrate = "";
	}
	my $target_ip = $anvil->Convert->host_name_to_ip({debug => $debug, host_name => $target});
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
	
	my $migration_command = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." migrate --undefinesource --tunnelled --p2p ".$live_migrate." ".$server." qemu+ssh://".$target."/system";
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
		
		$migration_command = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." -c qemu+ssh://root\@".$source."/system migrate --undefinesource --tunnelled --p2p ".$live_migrate." ".$server." qemu+ssh://".$target."/system";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { migration_command => $migration_command }});
	
	# Register a job for the peer so it can update its firewall once the target is created.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::database::connections" => $anvil->data->{sys}{database}{connections}
	}});
	if ($anvil->data->{sys}{database}{connections})
	{
		my $target_host_uuid = $anvil->Get->host_uuid_from_name({
			debug     => $debug, 
			host_name => $target,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_host_uuid => $target_host_uuid }});
		if ($target_host_uuid)
		{
			my ($job_uuid) = $anvil->Database->insert_or_update_jobs({
				file            => $THIS_FILE, 
				line            => __LINE__, 
				job_command     => $anvil->data->{path}{exe}{'anvil-manage-firewall'}.$anvil->Log->switches, 
				job_data        => "server=".$server, 
				job_name        => "manage::firewall", 
				job_title       => "job_0399", 
				job_description => "job_0400", 
				job_progress    => 0,
				job_host_uuid   => $target_host_uuid,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { job_uuid => $job_uuid }});
		}
	}
	
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
	foreach my $resource (sort {$a cmp $b} @{$resources_to_disable_dual_primary})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		my ($return_code) = $anvil->DRBD->allow_two_primaries({
			debug    => 2, 
			resource => $resource, 
			set_to   => "no", 
		});
		
# 		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
# 		$anvil->DRBD->reload_defaults({
# 			debug    => 2, 
# 			resource => $resource, 
# 		});
	}
	
	return($success);
}

=head2 

This method parses a server's C<< virsh >> XML definition. On successful parse, C<< 0 >> is returned. If there is a problem, C<< !!error!! >> is returned.

B<< Note >>: This method currently parses out data needed for specific tasks, and not the entire data structure.

Parameters;

=head3 anvil_uuid (optional)

If passed, the C<< anvil_uuid >> will be passed on to C<< DRBD->get_devices >>.

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

=head4 C<< test >> 

The XML is a test definition, and not actually from anywhere.

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
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	my $server     = defined $parameter->{server}     ? $parameter->{server}     : "";
	my $source     = defined $parameter->{source}     ? $parameter->{source}     : "";
	my $definition = defined $parameter->{definition} ? $parameter->{definition} : "";
	my $host       = defined $parameter->{host}       ? $parameter->{host}       : "";
	my $target     = $anvil->Get->short_host_name();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid, 
		server     => $server,
		source     => $source, 
		definition => $definition, 
		host       => $host, 
		target     => $target,
	}});
	
	if (not $target)
	{
		$target = $anvil->Get->short_host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target => $target }});
	}
	
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
	
	# If whoever called us did so after a 'virsh dumpxml <server>' while the server was off, the "definition" 
	# will contain the string 'error: failed to get domain'. In such a case, return.
	if ($definition =~ /error: failed to get domain/gs)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0367", variables => { definition => $definition }});
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
		my $error =  "[ Error ] - The was a problem parsing: [".$definition."]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", list => { error => $error }});
		return(1);
	}
	
	$anvil->data->{server}{$target}{$server}{$source}{parsed} = $server_xml;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::parsed" => $anvil->data->{server}{$target}{$server}{$source}{parsed}, 
	}});
	
	# Get the DRBD data that this server will almost certainly be using.
	$anvil->DRBD->get_devices({
		debug      => $debug,
		anvil_uuid => $anvil_uuid, 
	});
	
	# If there's nvram, we need to know so that we can undefine it with the 'virsh undefine --nvram' 
	# switch.
	if (exists $server_xml->{os}->[0]->{nvram})
	{
		$anvil->data->{server}{$target}{$server}{$source}{nvram}{data}     = $server_xml->{os}->[0]->{nvram}->[0]->{content};
		$anvil->data->{server}{$target}{$server}{$source}{nvram}{template} = $server_xml->{os}->[0]->{nvram}->[0]->{template};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::nvram::data"     => $anvil->data->{server}{$target}{$server}{$source}{nvram}{data},
			"server::${target}::${server}::${source}::nvram::template" => $anvil->data->{server}{$target}{$server}{$source}{nvram}{template},
		}});
	}
	else
	{
		$anvil->data->{server}{$target}{$server}{$source}{nvram}{data}     = "";
		$anvil->data->{server}{$target}{$server}{$source}{nvram}{template} = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${target}::${server}::${source}::nvram::data"     => $anvil->data->{server}{$target}{$server}{$source}{nvram}{data},
			"server::${target}::${server}::${source}::nvram::template" => $anvil->data->{server}{$target}{$server}{$source}{nvram}{template},
		}});
	}
	
	$anvil->data->{server}{$target}{$server}{$source}{graphics}{port}      = $server_xml->{devices}->[0]->{graphics}->[0]->{port} // "";
	$anvil->data->{server}{$target}{$server}{$source}{graphics}{port_type} = $server_xml->{devices}->[0]->{graphics}->[0]->{type} // "";
	$anvil->data->{server}{$target}{$server}{$source}{graphics}{listening} = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${target}::${server}::${source}::graphics::port"      => $anvil->data->{server}{$target}{$server}{$source}{graphics}{port},
		"server::${target}::${server}::${source}::graphics::port_type" => $anvil->data->{server}{$target}{$server}{$source}{graphics}{port_type},
	}});
	
	foreach my $ref (@{$server_xml->{devices}->[0]->{graphics}->[0]->{'listen'}})
	{
		if ((ref($ref) eq "HASH")      &&
		    ($ref->{type})              &&
		    ($ref->{type} eq "address") && 
		    ($ref->{address}))
		{
			$anvil->data->{server}{$target}{$server}{$source}{graphics}{listening} = $ref->{address};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::graphics::listening" => $anvil->data->{server}{$target}{$server}{$source}{graphics}{listening},
			}});
		}
	}
	
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
		
		if (($boot_order) && ($boot_order =~ /^\d+$/))
		{
			$anvil->data->{server}{$target}{$server}{$source}{boot_order}{$boot_order}{device_target} = $device_target;
			$anvil->data->{server}{$target}{$server}{$source}{boot_order}{$boot_order}{device_type}   = $device;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::boot_order::${boot_order}::device_target" => $anvil->data->{server}{$target}{$server}{$source}{boot_order}{$boot_order}{device_target},
				"server::${target}::${server}::${source}::boot_order::${boot_order}::device_type"   => $anvil->data->{server}{$target}{$server}{$source}{boot_order}{$boot_order}{device_type},
			}});
		}
		
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
			$anvil->data->{server}{$target}{$server}{$source}{device_target}{$device_target}{type}                        = $device;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::domain"   => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{domain},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::slot"     => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{slot},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::function" => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{function},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::path"              => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{path},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::driver::io"        => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{io},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::driver::cache"     => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{driver}{cache},
				"server::${target}::${server}::${source}::device_target::${device_target}::type"                          => $anvil->data->{server}{$target}{$server}{$source}{device_target}{$device_target}{type},
			}});
			
			my $on_lv    = defined $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{on}       ? $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{on}       : "";
			my $resource = defined $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{resource} ? $anvil->data->{drbd}{config}{$host}{drbd_path}{$device_path}{resource} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:host'        => $host, 
				's2:device_path' => $device_path, 
				's3:on_lv'       => $on_lv,
				's4:resource'    => $resource, 
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
			$anvil->data->{server}{$target}{$server}{$source}{device_target}{$device_target}{type}                          = $device;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::controller" => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{controller},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::unit"       => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{unit},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::address::target"     => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{address}{target},
				"server::${target}::${server}::${source}::device::${device}::target::${device_target}::path"                => $anvil->data->{server}{$target}{$server}{$source}{device}{$device}{target}{$device_target}{path},
				"server::${target}::${server}::${source}::device_target::${device_target}::type"                            => $anvil->data->{server}{$target}{$server}{$source}{device_target}{$device_target}{type},
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
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{link_state}        = exists $hash_ref->{'link'}->[0]->{'state'} ? $hash_ref->{'link'}->[0]->{'state'} : "up";
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{bus}      = $hash_ref->{address}->[0]->{bus};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{domain}   = $hash_ref->{address}->[0]->{domain};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{type}     = $hash_ref->{address}->[0]->{type};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{slot}     = $hash_ref->{address}->[0]->{slot};
		$anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{function} = $hash_ref->{address}->[0]->{function};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s01:server::${target}::${server}::${source}::device::interface::${mac}::bridge"            => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{bridge},
			"s02:server::${target}::${server}::${source}::device::interface::${mac}::alias"             => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{alias},
			"s03:server::${target}::${server}::${source}::device::interface::${mac}::target"            => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{target},
			"s04:server::${target}::${server}::${source}::device::interface::${mac}::model"             => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{model},
			"s05:server::${target}::${server}::${source}::device::interface::${mac}::link_state"        => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{link_state},
			"s06:server::${target}::${server}::${source}::device::interface::${mac}::address::bus"      => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{bus},
			"s07:server::${target}::${server}::${source}::device::interface::${mac}::address::domain"   => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{domain},
			"s08:server::${target}::${server}::${source}::device::interface::${mac}::address::type"     => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{type},
			"s09:server::${target}::${server}::${source}::device::interface::${mac}::address::slot"     => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{slot},
			"s10:server::${target}::${server}::${source}::device::interface::${mac}::address::function" => $anvil->data->{server}{$target}{$server}{$source}{device}{interface}{$mac}{address}{function},
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
			### TODO: No, don't do this! The server might be migrating
			# The server is paused. Resume it, wait a few, then proceed with the shutdown.
# 			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0314", variables => { server => $server }});
# 			my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." resume $server"});
# 			if ($return_code)
# 			{
# 				# Looks like virsh isn't running.
# 				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0315", variables => { 
# 					server      => $server,
# 					return_code => $return_code, 
# 					output      => $output, 
# 				}});
# 				$anvil->nice_exit({exit_code => 1});
# 			}
# 			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0316"});
# 			sleep 3;
		}
		elsif ($status eq "pmsuspended")
		{
			# The server is suspended. Resume it, wait a few, then proceed with the shutdown.
			my $shell_call = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." dompmwakeup ".$server;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0317", variables => { server => $server }});
			my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
				shell_call => $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." ".$task." ".$server,
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
	my $waiting = 1;
	while ($waiting)
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
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0426", variables => { 
				server  => $server,
				waiting => $waiting, 
			}});
			
			# Mark it as stopped now. (if we have a server_uuid, we have a database connection)
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
			if ($server_uuid)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::database::connections" => $anvil->data->{sys}{database}{connections},
				}});
				if ($anvil->data->{sys}{database}{connections})
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
		}
		
		if (($stop_waiting) && (time > $stop_waiting))
		{
			# Give up waiting.
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { waiting => $waiting }});
			
			my $key = $wait_time == 1 ? "log_0727" : "log_0427";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => $key, variables => { 
				server => $server,
				'wait' => $wait_time,
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

=head2 update_definition

This takes a new server XML definition and saves it in the database and writes it out to the on-disk files. If either subnode or DR host is inacessible, this still returns success as C<< scan-server >> will pick up the new definition when the server comes back online.

If there is a problem, C<< !!error!! >> is returned. If it is updated, C<< 0 >> is returned. 

Parameters;

=head3 server (required)

This is the name or UUID of the server being updated.

=head3 new_definition_xml

This is the new XML definition file. It will be parsed and sanity checked.

=cut
sub update_definition
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Server->update_definition()" }});
	
	my $server             = defined $parameter->{server}             ? $parameter->{server}             : "";
	my $new_definition_xml = defined $parameter->{new_definition_xml} ? $parameter->{new_definition_xml} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server             => $server, 
		new_definition_xml => $new_definition_xml, 
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->update_definition()", parameter => "server" }});
		return('!!error!!');
	}
	if (not $new_definition_xml)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->update_definition()", parameter => "new_definition_xml" }});
		return('!!error!!');
	}
	
	my ($server_name, $server_uuid) = $anvil->Get->server_from_switch({
		debug         => $debug,
		server_string => $server, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		server_name => $server_name,
		server_uuid => $server_uuid, 
	}});
	
	# Do we have a valid server UUID?
	$anvil->Database->get_anvils({debug => $debug});
	$anvil->Database->get_servers({debug => $debug});
	
	if (not exists $anvil->data->{servers}{server_uuid}{$server_uuid})
	{
		# Invalid.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0463", variables => { 
			server      => $server,
			server_uuid => $server_uuid, 
		}});
		return('!!error!!');
	}
	
	# Find where the server exists.
	my $anvil_uuid = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_anvil_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { anvil_uuid => $anvil_uuid }});
	$anvil->Server->locate({
		debug       => $debug, 
		server_name => $server_name,
		anvil       => $anvil_uuid,
	});
	
	# Validate the new XML
	my $short_host_name = $anvil->Get->short_host_name();
	my $problem         = $anvil->Server->parse_definition({
		debug      => 2,
		target     => $short_host_name,
		server     => $server_name, 
		source     => "test",
		definition => $new_definition_xml, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { problem => $problem }});
	if ($problem)
	{
		# Failed to parse.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0464", variables => { 
			server_name => $server_name,
			xml         => $new_definition_xml, 
		}});
		return('!!error!!');
	}
	else
	{
		my $test_uuid = $anvil->data->{server}{$short_host_name}{$server_name}{test}{info}{uuid} // "";
		if ((not $test_uuid) or ($test_uuid ne $server_uuid))
		{
			# Somehow the new XML is invalid.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0464", variables => { 
				server_name => $server_name,
				xml         => $new_definition_xml, 
			}});
			return('!!error!!');
		}
	}
	
	# Prep our variables.
	my $definition_uuid   = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_definition_uuid};
	my $db_definition_xml = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_definition_xml};
	my $node1_host_uuid   = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
	my $node1_host_name   = $anvil->data->{hosts}{host_uuid}{$node1_host_uuid}{host_name};
	my $node2_host_uuid   = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
	my $node2_host_name   = $anvil->data->{hosts}{host_uuid}{$node2_host_uuid}{host_name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		definition_uuid   => $definition_uuid, 
		db_definition_xml => $db_definition_xml,  
		node1_host_uuid   => $node1_host_uuid, 
		node1_host_name   => $node1_host_name, 
		node2_host_uuid   => $node2_host_uuid, 
		node2_host_name   => $node2_host_name, 
	}});
	
	# Is there a difference between the new and DB definition?
	my $db_difference = diff \$db_definition_xml, \$new_definition_xml, { STYLE => 'Unified' };
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { db_difference => $db_difference }});
	
	if ($db_difference)
	{
		# Update the DB.
		$anvil->Database->insert_or_update_server_definitions({
			debug                         => $debug,
			server_definition_uuid        => $definition_uuid, 
			server_definition_server_uuid => $server_uuid, 
			server_definition_xml         => $new_definition_xml, 
		});
	}
	
	# Look for definitions 
	my $hosts = [$node1_host_uuid, $node2_host_uuid];
	foreach my $dr_host_name (sort {$a cmp $b} keys %{$anvil->data->{dr_links}{by_anvil_uuid}{$anvil_uuid}{dr_link_host_name}})
	{
		my $dr_link_uuid = $anvil->data->{dr_links}{by_anvil_uuid}{$anvil_uuid}{dr_link_host_name}{$dr_host_name}{dr_link_uuid};
		my $dr_host_uuid = $anvil->data->{dr_links}{dr_link_uuid}{$dr_link_uuid}{dr_link_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:dr_host_name' => $dr_host_name,
			's2:dr_host_uuid' => $dr_host_uuid, 
			's3:dr_link_uuid' => $dr_link_uuid, 
		}});
		push @{$hosts}, $dr_host_uuid;
	}
	
	# Get the host UUIDs for the node this server is hosted by.
	my $definition_file = $anvil->data->{path}{directories}{shared}{definitions}."/".$server_name.".xml";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { definition_file => $definition_file }});
	foreach my $host_uuid (@{$hosts})
	{
		# Find a target_ip (local will be detected as local in the file read/write)
		my $short_host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name};
		my $target_ip       = $anvil->Network->find_target_ip({
			debug       => 2,
			host_uuid   => $host_uuid,
			test_access => 1,
			networks    => "bcn,mn,sn,ifn,any",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			target_ip       => $target_ip,
			short_host_name => $short_host_name, 
		}});
		if ($target_ip)
		{
			# The definition was read by Server->locate, so we can use it.
			my $old_definition_xml = defined $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{file_definition} ? $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{file_definition} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { old_definition_xml => $old_definition_xml }});
			
			### TODO: Handle when the definition file simply doesn't exist.
			if ((not $old_definition_xml) or ($old_definition_xml eq "!!error!!") or ($old_definition_xml !~ /<domain/ms))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0163", variables => { 
					server_name => $server_name,
					host_name   => $short_host_name, 
					file        => $definition_file,
				}});
			}
			else
			{
				my $file_difference = diff \$old_definition_xml, \$new_definition_xml, { STYLE => 'Unified' };
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { file_difference => $file_difference }});
				
				if ($file_difference)
				{
					# Update
					my $error = $anvil->Storage->write_file({
						debug     => $debug, 
						file      => $definition_file, 
						body      => $new_definition_xml, 
						backup    => 1,
						overwrite => 1,
						mode      => "0644",
						group     => "root",
						user      => "root",
						target    => $target_ip, 
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { error => $error }});
					if ($error)
					{
						my $host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0164", variables => { 
							server_name => $server_name,
							host_name   => $host_name, 
							file        => $definition_file,
						}});
					}
				}
				
				# If the server is defined, update that also.
				if ((exists $anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{inactive_definition}) && 
				    ($anvil->data->{server_location}{host}{$short_host_name}{server}{$server_name}{inactive_definition}))
				{
					# This will always differ, so just update.
					my $problem = $anvil->Server->connect_to_libvirt({
						debug       => $debug,
						target      => $short_host_name,
						target_ip   => $target_ip,
						server_name => $server_name,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { problem => $problem }});
					if (not $problem)
					{
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"libvirtd::${short_host_name}::connection" => $anvil->data->{libvirtd}{$short_host_name}{connection},
						}});
						
						# Define the server
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0818", variables => { server_name => $server_name }});
						eval { $anvil->data->{libvirtd}{$short_host_name}{connection}->define_domain($new_definition_xml); };
						if ($@)
						{
							# Throw an error, then clear the URI so that we just update the DB/on-disk definitions.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0166", variables => { 
								host_name   => $short_host_name,
								server_name => $server_name,
								error       => $@,
							}});
						}
						else
						{
							if (not ref($anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}) eq "Sys::Virt::Domain")
							{
								# Connect to the server.
								my @domains = $anvil->data->{libvirtd}{$short_host_name}{connection}->list_all_domains();
								foreach my $domain_handle (@domains)
								{
									my $this_server_name = $domain_handle->get_name;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
										domain_handle    => $domain_handle, 
										this_server_name => $this_server_name,
									}});
									if ($this_server_name eq $server_name)
									{
										$anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection} = $domain_handle;
										$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
											"libvirtd::${short_host_name}::server::${server_name}::connection" => $anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection},
										}});
										last;
									}
								}
								
							}
							
							# If this connection still valid?
							if (ref($anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}) eq "Sys::Virt::Domain")
							{
								$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0819", variables => { server_name => $server_name }});
								my $uuid = "";
								eval { $uuid = $anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}->get_uuid_string(); };
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "uuid" => $uuid }});
								if ((not $@) && ($uuid))
								{
									# Connection is good.
									my $updated = $anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}->is_updated();
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "updated" => $updated }});
									if ($updated)
									{
										eval { $anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}->undefine; };
										if ($@)
										{
											# Throw an error, then clear the URI so that we just update the DB/on-disk definitions.
											$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0167", variables => { 
												host_name   => $short_host_name,
												server_name => $server_name,
												error       => $@,
											}});
										}
										else
										{
											my $updated = $anvil->data->{libvirtd}{$short_host_name}{server}{$server_name}{connection}->is_updated();
											$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "updated" => $updated }});
											
											$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0817", variables => { server_name => $server_name }});
										}
									}
								}
							}
						}
					}
				}
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


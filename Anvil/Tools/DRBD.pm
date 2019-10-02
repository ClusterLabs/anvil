package Anvil::Tools::DRBD;
# 
# This module contains methods used to manager DRBD 9
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "DRBD.pm";

### Methods;
# allow_two_primaries
# get_devices
# get_status
# manage_resource
# reload_defaults

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::DRBD

Provides all methods related to managing DRBD version 9.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->DRBD->X'. 
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

=head2 allow_two_primaries

This enables dual-primary for the given resource. This is meant to be called prior to a live migration, and should be disabled again as soon as possible via C<< DRBD->reload_defaults >>.

Parameters; 

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 resource (required)

This is the name of the resource to enable two primaries on.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=head3 target_node_id (optional, but see condition below)

This is the DRBD target node's (connection) ID that we're enabling dual-primary with. If this is not passed, but C<< drbd::status::<local_short_host_name>::resource::<resource>::connection::<peer_name>::peer-node-id >> is set, it will be used. Otherwise this argument is required.

=cut
sub allow_two_primaries
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password       = defined $parameter->{password}       ? $parameter->{password}       : "";
	my $port           = defined $parameter->{port}           ? $parameter->{port}           : "";
	my $remote_user    = defined $parameter->{remote_user}    ? $parameter->{remote_user}    : "root";
	my $resource       = defined $parameter->{resource}       ? $parameter->{resource}       : "";
	my $target         = defined $parameter->{target}         ? $parameter->{target}         : "local";
	my $target_node_id = defined $parameter->{target_node_id} ? $parameter->{target_node_id} : "";
	my $return_code    = 255; 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password       => $anvil->Log->is_secure($password),
		port           => $port, 
		remote_user    => $remote_user,
		resource       => $resource, 
		target         => $target, 
		target_node_id => $target_node_id, 
	}});
	
	if (not $resource)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->allow_two_primaries()", parameter => "resource" }});
		return($return_code);
	}
	
	# Do we need to scan devices?
	my $host = $anvil->_short_host_name;
	if (not $anvil->data->{drbd}{config}{$host}{peer})
	{
		# Get our device list.
		$anvil->DRBD->get_devices({
			debug       => $debug,
			password    => $password,
			port        => $port, 
			remote_user => $remote_user, 
			target      => $target, 
		});
	}
	
	my $peer_name = $anvil->data->{drbd}{config}{$host}{peer};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { peer_name => $peer_name }});
	if ($target_node_id !~ /^\d+$/)
	{
		# Can we find it?
		if (not exists $anvil->data->{drbd}{status})
		{
			$anvil->DRBD->get_status({
				debug       => 2,
				password    => $password,
				port        => $port, 
				remote_user => $remote_user,
				target      => $target, 
			});
		}
		if ($anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'} =~ /^\d+$/)
		{
			$target_node_id = $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_node_id => $target_node_id }});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->allow_two_primaries()", parameter => "target_node_id" }});
			return($return_code);
		}
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 0, level => 1, key => "log_0350", variables => { 
		resource       => $resource,
		target_name    => $peer_name, 
		target_node_id => $target_node_id, 
	}});
	
	my $shell_call = $anvil->data->{path}{exe}{drbdsetup}." net-options ".$resource." ".$target_node_id." --allow-two-primaries=yes";
	my $output     = "";
	if ($anvil->Network->is_remote($target))
	{
		# Remote call.
		($output, my $error, $return_code) = $anvil->Remote->call({
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
	else
	{
		# Local.
		($output, $return_code) = $anvil->System->call({
			debug      => $debug,
			shell_call => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	
	if ($return_code)
	{
		# Something went wrong.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0356", variables => { 
			return_code => $return_code, 
			output      => $output, 
		}});
	}
	
	return($return_code);
}

=head2 get_devices

This finds all of the configured '/dev/drbdX' devices and maps them to their resource names.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub get_devices
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "local";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Is this a local call or a remote call?
	my $host       = $anvil->_short_host_name;
	my $shell_call = $anvil->data->{path}{exe}{drbdadm}." dump-xml";
	my $output     = "";
	if ($anvil->Network->is_remote($target))
	{
		# Remote call.
		($output, my $error, $anvil->data->{drbd}{'drbdadm-xml'}{return_code}) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$host = $target;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host                             => $host,
			error                            => $error,
			output                           => $output,
			"drbd::drbdadm-xml::return_code" => $anvil->data->{drbd}{'drbdadm-xml'}{return_code},
		}});
	}
	else
	{
		# Local.
		($output, $anvil->data->{drbd}{'drbdadm-xml'}{return_code}) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output                           => $output,
			"drbd::drbdadm-xml::return_code" => $anvil->data->{drbd}{'drbdadm-xml'}{return_code},
		}});
	}
	
	# Clear the hash where we'll store the data.
	if (exists $anvil->data->{drbd}{config}{$host})
	{
		delete $anvil->data->{drbd}{config}{$host};
	}
	
	my $xml      = XML::Simple->new();
	my $dump_xml = "";
	eval { $dump_xml = $xml->XMLin($output, KeyAttr => {}, ForceArray => 1) };
	if ($@)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem parsing: [$output]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
		$anvil->nice_exit({exit_code => 1});
	}
	
	#print Dumper $dump_xml;
	$anvil->data->{drbd}{config}{$host}{'auto-promote'} = 0;
	$anvil->data->{drbd}{config}{$host}{host}          = "";
	$anvil->data->{drbd}{config}{$host}{peer}          = "";
	$anvil->data->{drbd}{config}{$host}{nodes}         = {};
	
	foreach my $hash_ref (@{$dump_xml->{common}->[0]->{section}})
	{
		my $name = $hash_ref->{name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { name => $name }});
		if ($name eq "options")
		{
			foreach my $option_ref (@{$hash_ref->{option}})
			{
				my $variable = $option_ref->{name};
				my $value    = $option_ref->{value};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					variable => $variable,
					value    => $variable, 
				}});
				if ($variable eq "auto-promote")
				{
					$anvil->data->{drbd}{config}{$host}{'auto-promote'} = $value =~ /^y/i ? 1 : 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"drbd::config::${host}::auto-promote" => $anvil->data->{drbd}{config}{$host}{'auto-promote'},
					}});
				}
			}
		}
	}
	
	foreach my $hash_ref (@{$dump_xml->{resource}})
	{
		my $this_resource = $hash_ref->{name};
		foreach my $connection_href (@{$hash_ref->{connection}})
		{
			foreach my $host_href (@{$connection_href->{host}})
			{
				my $this_host                                                                                        = $host_href->{name};
				my $port                                                                                             = $host_href->{address}->[0]->{port};
				my $ip_address                                                                                       = $host_href->{address}->[0]->{content};
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{connection}{$this_host}{ip_family}  = $host_href->{address}->[0]->{family};
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{connection}{$this_host}{ip_address} = $host_href->{address}->[0]->{content};
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{connection}{$this_host}{port}       = $port;
				   $anvil->data->{drbd}{config}{$host}{ip_addresses}{$ip_address}                                    = $this_host;
				   $anvil->data->{drbd}{config}{$host}{tcp_ports}{$port}                                             = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"drbd::config::${host}::resource::${this_resource}::connection::${this_host}::ip_family"  => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{connection}{$this_host}{ip_family},
					"drbd::config::${host}::resource::${this_resource}::connection::${this_host}::ip_address" => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{connection}{$this_host}{ip_address},
					"drbd::config::${host}::resource::${this_resource}::connection::${this_host}::port"       => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{connection}{$this_host}{port},
					"drbd::config::${host}::ip_addresses::${ip_address}"                                      => $anvil->data->{drbd}{config}{$host}{ip_addresses}{$ip_address}, 
					"drbd::config::${host}::tcp_ports::${port}"                                               => $anvil->data->{drbd}{config}{$host}{tcp_ports}{$port},
				}});
			}
			foreach my $section_href (@{$connection_href->{section}})
			{
				my $section = $section_href->{name};
				foreach my $option_href (@{$section_href->{option}})
				{
					my $variable = $option_href->{name};
					$anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{section}{$section}{$variable} = $option_href->{value};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"drbd::config::${host}::resource::${this_resource}::section::${section}::${variable}" => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{section}{$section}{$variable},
					}});
				}
			}
		}
		
		foreach my $host_href (@{$hash_ref->{host}})
		{
			### TODO: Handle external metadata
			my $this_host = $host_href->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				this_host                  => $this_host,
				'$anvil->_host_name'       => $anvil->_host_name, 
				'$anvil->_short_host_name' => $anvil->_short_host_name, 
			}});
			if (($this_host eq $anvil->_host_name) or ($this_host eq $anvil->_short_host_name))
			{
				$anvil->data->{drbd}{config}{$host}{host} = $this_host;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::config::${host}::host" => $anvil->data->{drbd}{config}{$host}{host} }});
			}
			foreach my $volume_href (@{$host_href->{volume}})
			{
				my $volume                                                                                     = $volume_href->{vnr};
				my $drbd_path                                                                                  = $volume_href->{device}->[0]->{content};
				my $lv_path                                                                                    = $volume_href->{disk}->[0];
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_path}   = $drbd_path;
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_minor}  = $volume_href->{device}->[0]->{minor};
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{'meta-disk'} = $volume_href->{'meta-disk'}->[0];
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{backing_lv}  = $lv_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::drbd_path"  => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_path},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::drbd_minor" => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_minor},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::meta-disk"  => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{'meta-disk'},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::backing_lv" => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{backing_lv},
				}});
				if (($anvil->data->{drbd}{config}{$host}{host}) && ($anvil->data->{drbd}{config}{$host}{host} eq $this_host))
				{
					$anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{on}       = $lv_path;
					$anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{resource} = $this_resource;
					$anvil->data->{drbd}{config}{$host}{lv_path}{$lv_path}{under}        = $drbd_path;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"drbd::config::${host}::drbd_path::${drbd_path}::on"       => $anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{on},
						"drbd::config::${host}::drbd_path::${drbd_path}::resource" => $anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{resource},
						"drbd::config::${host}::lv_path::${lv_path}::under"        => $anvil->data->{drbd}{config}{$host}{lv_path}{$lv_path}{under},
					}});
				}
			}
		}
		
		### NOTE: Connections are listed as 'host A <-> Host B (options), 'host A <-> Host C 
		###       (options) and 'host B <-> Host C (options)'. So first we see which entry has 
		###       fencing, and ignore the others. The one with real fencing, we figure out which is 
		###       us (if any) and the other has to be the peer.
		# Find my peer, if I am myself a node.
		if (($anvil->data->{drbd}{config}{$host}{host}) && (not $anvil->data->{drbd}{config}{$host}{peer}))
		{
			#print Dumper $hash_ref->{connection};
			foreach my $hash_ref (@{$hash_ref->{connection}})
			{
				# Look in 'section' for fencing data.
				my $fencing  = "";
				my $protocol = "";
				#print Dumper $hash_ref;
				foreach my $section_ref (@{$hash_ref->{section}})
				{
					next if $section_ref->{name} ne "net";
					foreach my $option_ref (@{$section_ref->{option}})
					{
						if ($option_ref->{name} eq "fencing")
						{
							$fencing = $option_ref->{value};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { fencing => $fencing }});
						}
						elsif ($option_ref->{name} eq "protocol")
						{
							$protocol = $option_ref->{value};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { protocol => $protocol }});
						}
					}
				}
				
				# If the protocol is 'resource-and-stonith', we care. Otherwise it's a 
				# connection involving DR and we don't.
				next if $fencing ne "resource-and-stonith";
				
				# If we're still alive, this should be our connection to our peer.
				foreach my $host_ref (@{$hash_ref->{host}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"drbd::config::${host}::host" => $anvil->data->{drbd}{config}{$host}{host},
						"host_ref->name"              => $host_ref->{name}, 
					}});
					next if $host_ref->{name} eq $anvil->data->{drbd}{config}{$host}{host};
					
					# Found the peer.
					$anvil->data->{drbd}{config}{$host}{peer} = $host_ref->{name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::config::${host}::peer" => $anvil->data->{drbd}{config}{$host}{peer} }});
				}
			}
		}
	}
	
	return(0);
}


=head2 get_status

This parses the DRBD status on the local or remote system. The data collected is stored in the following hashes;

 - drbd::status::<host_name>::resource::<resource_name>::{ap-in-flight,congested,connection-state,peer-node-id,rs-in-flight}
 - drbd::status::<host_name>::resource::<resource_name>::connection::<peer_host_name>::volume::<volume>::{has-online-verify-details,has-sync-details,out-of-sync,peer-client,peer-disk-state,pending,percent-in-sync,received,replication-state,resync-suspended,sent,unacked}
 - # If the volume is resyncing, these additional values will be set:
 - drbd::status::<host_name>::resource::<resource_name>::connection::<peer_host_name>::volume::<volume>::{db-dt MiB-s,db0-dt0 MiB-s,db1-dt1 MiB-s,estimated-seconds-to-finish,percent-resync-done,rs-db0-sectors,rs-db1-sectors,rs-dt-start-ms,rs-dt0-ms,rs-dt1-ms,rs-failed,rs-paused-ms,rs-same-csum,rs-total,want}
 - drbd::status::<host_name>::resource::<resource>::devices::volume::<volume>::{al-writes,bm-writes,client,disk-state,lower-pending,minor,quorum,read,size,upper-pending,written}

If any data for the host was stored in a previous call, it will be deleted before the new data is collected and stored.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
# NOTE: the version is set in anvil.spec by sed'ing the release and arch onto anvil.version in anvil-core's %post
sub get_status
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "local";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Is this a local call or a remote call?
	my $shell_call = $anvil->data->{path}{exe}{drbdsetup}." status --json";
	my $output     = "";
	my $host       = $anvil->_short_host_name();
	if ($anvil->Network->is_remote($target))
	{
		# Clear the hash where we'll store the data.
		$host = $target;
		if (exists $anvil->data->{drbd}{status}{$host})
		{
			delete $anvil->data->{drbd}{status}{$host};
		}
		
		# Remote call.
		($output, my $error, $anvil->data->{drbd}{status}{$host}{return_code}) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error                                => $error,
			output                               => $output,
			"drbd::status::${host}::return_code" => $anvil->data->{drbd}{status}{return_code},
		}});
	}
	else
	{
		# Clear the hash where we'll store the data.
		if (exists $anvil->data->{drbd}{status}{$host})
		{
			delete $anvil->data->{drbd}{status}{$host};
		}
		
		# Local.
		($output, $anvil->data->{drbd}{status}{return_code}) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output                               => $output,
			"drbd::status::${host}::return_code" => $anvil->data->{drbd}{status}{return_code},
		}});
	}
	
	# Parse the output.
	my $json        = JSON->new->allow_nonref;
	my $drbd_status = $json->decode($output);
	foreach my $hash_ref (@{$drbd_status})
	{
		my $resource = $hash_ref->{name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		
		$anvil->data->{drbd}{status}{$host}{resource}{$resource}{role}             = $hash_ref->{role};
		$anvil->data->{drbd}{status}{$host}{resource}{$resource}{'node-id'}        = $hash_ref->{'node-id'};
		$anvil->data->{drbd}{status}{$host}{resource}{$resource}{suspended}        = $hash_ref->{suspended};
		$anvil->data->{drbd}{status}{$host}{resource}{$resource}{'write-ordering'} = $hash_ref->{'write-ordering'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"drbd::status::${host}::resource::${resource}::role"           => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{role},
			"drbd::status::${host}::resource::${resource}::node-id"        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{'node-id'},
			"drbd::status::${host}::resource::${resource}::suspended"      => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{suspended},
			"drbd::status::${host}::resource::${resource}::write-ordering" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{'write-ordering'},
		}});
		
		my $count_i = @{$hash_ref->{connections}};
		for (my $i = 0; $i < $count_i; $i++)
		{
			#print "i: [$i]\n";
			my $peer_name = $hash_ref->{connections}->[$i]->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { peer_name => $peer_name }});
			
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'ap-in-flight'}     = $hash_ref->{connections}->[$i]->{'ap-in-flight'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{congested}          = $hash_ref->{connections}->[$i]->{congested};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'connection-state'} = $hash_ref->{connections}->[$i]->{'connection-state'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'}     = $hash_ref->{connections}->[$i]->{'peer-node-id'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'rs-in-flight'}     = $hash_ref->{connections}->[$i]->{'rs-in-flight'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::ap-in-flight"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'ap-in-flight'},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::congested"        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{congested},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::connection-state" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'connection-state'},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::peer-node-id"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::rs-in-flight"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'rs-in-flight'},
			}});
			
			my $count_j = @{$hash_ref->{connections}->[$i]->{peer_devices}};
			for (my $j = 0; $j < $count_j; $j++)
			{
				my $volume = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{volume};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { volume => $volume }});
				
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'has-online-verify-details'} = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'has-online-verify-details'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'has-sync-details'}          = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'has-sync-details'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'out-of-sync'}               = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'out-of-sync'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'peer-client'}               = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'peer-client'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'peer-disk-state'}           = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'peer-disk-state'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{pending}                     = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{pending};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'percent-in-sync'}           = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'percent-in-sync'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{received}                    = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{received};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'replication-state'}         = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'replication-state'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'resync-suspended'}          = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'resync-suspended'};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{sent}                        = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{sent};
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{unacked}                     = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{unacked};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::has-online-verify-details" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'has-online-verify-details'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::has-sync-details"          => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'has-sync-details'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::out-of-sync"               => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'out-of-sync'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::peer-client"               => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'peer-client'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::peer-disk-state"           => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'peer-disk-state'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::pending"                   => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{pending},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::percent-in-sync"           => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'percent-in-sync'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::received"                  => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{received},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::replication-state"         => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'replication-state'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::resync-suspended"          => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'resync-suspended'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::sent"                      => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{sent},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::unacked"                   => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{unacked},
				}});
				
				### NOTE: 03:54 < lge> t0, t1, ...: time stamps. db/dt (0,1,...): delta blocks per delta time: the "estimated average" resync rate in kB/s from tX to now.
				#         03:57 < lge> time stamps and block gauges are send by the module, the rate is then calculated by the tool, so if there are funny numbers, you have to tool closely if the data from the module is already bogus, or if just the calculation in the tool is off.
				# These are set during a resync
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'db-dt MiB-s'}                 = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'db/dt [MiB/s]'}               ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'db/dt [MiB/s]'}               : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'db0-dt0 MiB-s'}               = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'db0/dt0 [MiB/s]'}             ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'db0/dt0 [MiB/s]'}             : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'db1-dt1 MiB-s'}               = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'db1/dt1 [MiB/s]'}             ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'db1/dt1 [MiB/s]'}             : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'estimated-seconds-to-finish'} = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'estimated-seconds-to-finish'} ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'estimated-seconds-to-finish'} : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'percent-resync-done'}         = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'percent-resync-done'}         ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'percent-resync-done'}         : 100;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-db0-sectors'}              = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-db0-sectors'}              ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-db0-sectors'}              : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-db1-sectors'}              = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-db1-sectors'}              ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-db1-sectors'}              : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-dt-start-ms'}              = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-dt-start-ms'}              ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-dt-start-ms'}              : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-dt0-ms'}                   = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-dt0-ms'}                   ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-dt0-ms'}                   : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-dt1-ms'}                   = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-dt1-ms'}                   ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-dt1-ms'}                   : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-failed'}                   = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-failed'}                   ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-failed'}                   : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-paused-ms'}                = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-paused-ms'}                ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-paused-ms'}                : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-same-csum'}                = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-same-csum'}                ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-same-csum'}                : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-total'}                    = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-total'}                    ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'rs-total'}                    : 0;
				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{want}                          = defined $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{want}                          ? $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{want}                          : 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::db-dt MiB-s"                 => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'db-dt MiB-s'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::db0-dt0 MiB-s"               => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'db0-dt0 MiB-s'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::db1-dt1 MiB-s"               => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'db1-dt1 MiB-s'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::estimated-seconds-to-finish" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'estimated-seconds-to-finish'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::percent-resync-done"         => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'percent-resync-done'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-db0-sectors"              => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-db0-sectors'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-db1-sectors"              => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-db1-sectors'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-dt-start-ms"              => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-dt-start-ms'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-dt0-ms"                   => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-dt0-ms'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-dt1-ms"                   => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-dt1-ms'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-failed"                   => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-failed'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-paused-ms"                => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-paused-ms'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-same-csum"                => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-same-csum'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::rs-total"                    => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'rs-total'},
					"drbd::status::${host}::resource::${resource}::connection::${peer_name}::volume::${volume}::want"                        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{want},
				}});
			}
		}
		
		$count_i = @{$hash_ref->{devices}};
		#print "hash_ref->{devices}: [".$hash_ref->{devices}."], count_i: [$count_i]\n";
 		for (my $i = 0; $i < $count_i; $i++)
		{
			#print "i: [$i], [".$hash_ref->{devices}->[$i]."]\n";
			my $volume = $hash_ref->{devices}->[$i]->{volume};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { volume => $volume }});
			
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'al-writes'}     = $hash_ref->{devices}->[$i]->{'al-writes'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'bm-writes'}     = $hash_ref->{devices}->[$i]->{'bm-writes'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{client}          = $hash_ref->{devices}->[$i]->{client};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'disk-state'}    = $hash_ref->{devices}->[$i]->{'disk-state'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'lower-pending'} = $hash_ref->{devices}->[$i]->{'lower-pending'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{minor}           = $hash_ref->{devices}->[$i]->{minor};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{quorum}          = $hash_ref->{devices}->[$i]->{quorum};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'read'}          = $hash_ref->{devices}->[$i]->{'read'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{size}            = $hash_ref->{devices}->[$i]->{size};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'upper-pending'} = $hash_ref->{devices}->[$i]->{'upper-pending'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{written}         = $hash_ref->{devices}->[$i]->{written};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::al-writes"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'al-writes'},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::bm-writes"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'bm-writes'},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::client"        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{client},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::disk-state"    => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'disk-state'},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::lower-pending" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'lower-pending'},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::minor"         => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{minor},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::quorum"        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{quorum},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::read"          => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'read'},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::size"          => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{size},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::upper-pending" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{'upper-pending'},
				"drbd::status::${host}::resource::${resource}::devices::volume::${volume}::written"       => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{devices}{volume}{$volume}{written},
			}});
		}
		
# 		foreach my $key (sort {$a cmp $b} keys %{$hash_ref})
# 		{
# 			next if $key eq "name";
# 			next if $key eq "role";
# 			next if $key eq "node-id";
# 			next if $key eq "suspended";
# 			next if $key eq "write-ordering";
# 			next if $key eq "connections";
# 			next if $key eq "devices";
# 			print "Key: [$key] -> [".$hash_ref->{$key}."]\n";
# 		}
	}
	
	return(0);
}

=head2 manage_resource

This takes a task, C<< up >>, C<< down >>, C<< primary >>, or C<< secondary >> and a resource name and acts on the request.

This returns the return code from the C<< drbdadm >> call. If C<< 255 >> is returned, then we did not get the actual return code from C<< drbdadm >>.

B<NOTE>: This just makes the call, it doesn't wait or watch for the action to actually finish.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

=head3 resource (required)

This is the name of the resource being acted upon.

=head3 task (required)

This is the action to take. Valid tasks are: C<< up >>, C<< down >>, C<< primary >>, and C<< secondary >>.

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub manage_resource
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $resource    = defined $parameter->{resource}    ? $parameter->{resource}    : "";
	my $task        = defined $parameter->{task}        ? $parameter->{task}        : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "local";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user,
		resource    => $resource,  
		task        => $task, 
		target      => $target, 
	}});
	
	if (not $resource)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->manage_resource()", parameter => "resource" }});
		return(1);
	}
	if (not $task)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->manage_resource()", parameter => "task" }});
		return(1);
	}
	
	### TODO: Sanity check the resource name and task requested.
	
	my $shell_call  = $anvil->data->{path}{exe}{drbdadm}." ".$task." ".$resource;
	my $output      = "";
	my $return_code = 255; 
	if ($anvil->Network->is_remote($target))
	{
		# Remote call.
		($output, my $error, $return_code) = $anvil->Remote->call({
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
	else
	{
		# Local.
		($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	
	return($return_code);
}

=head2 reload_defaults

This switches DRBD back to running using the values in the config files. Specifically, it calls C<< drbdadm adjust all >>.

The return code from the C<< drbdadm >> call is returned by this method.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 resource (required)

This is the name of the resource to reload the default configuration for (ie: disable dual primary, pickup changes from the config file, etc)..

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub reload_defaults
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $resource    = defined $parameter->{resource}    ? $parameter->{resource}    : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "local";
	my $return_code = 255; 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user,
		resource    => $resource,  
		target      => $target, 
	}});
	
	if (not $resource)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->allow_two_primaries()", parameter => "resource" }});
		return($return_code);
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 0, level => 2, key => "log_0355"});
	my $shell_call  = $anvil->data->{path}{exe}{drbdadm}." adjust ".$resource;
	my $output      = "";
	if ($anvil->Network->is_remote($target))
	{
		# Remote call.
		($output, my $error, $return_code) = $anvil->Remote->call({
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
	else
	{
		# Local.
		($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	
	if ($return_code)
	{
		# Something went wrong.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "log_0356", variables => { 
			return_code => $return_code, 
			output      => $output, 
		}});
	}
	
	return($return_code);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

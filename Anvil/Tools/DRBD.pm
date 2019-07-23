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
# status

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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}

#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 get_status

This parses the DRBD status on the local or remote system. It returns a JSON -> decoded reference.

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
	my $version     = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->secure ? $password : $anvil->Words->string({key => "log_0186"}),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Is this a local call or a remote call?
	my $shell_call = $anvil->data->{path}{exe}{drbdsetup}." status --json";
	my $output     = "";
	my $host       = $anvil->_short_hostname;
	if (($target) && ($target ne "local") && ($target ne $anvil->_hostname) && ($target ne $anvil->_short_hostname))
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
		$host = $target;
	}
	else
	{
		# Local.
		($output, my $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	}
	
	# Clear the hash where we'll store the data.
	if (exists $anvil->data->{drbd}{status}{$host})
	{
		delete $anvil->data->{drbd}{status}{$host};
	}
	
	# Parse the output.
	my $json        = JSON->new->allow_nonref;
	my $drbd_status = $json->decode($output);
	print "===] Raw Output [=======================================================================================\n";
	print $output."\n";
	print "========================================================================================================\n";
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
		print "hash_ref->{connections}: [".$hash_ref->{connections}."], count_i: [$count_i]\n";
 		for (my $i = 0; $i < $count_i; $i++)
		{
			print "i: [$i]\n";
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
			print "hash_ref->{connections}->[${i}]->{peer_devices}: [".$hash_ref->{connections}->[$i]->{peer_devices}."], count_j: [$count_j]\n";
			for (my $j = 0; $j < $count_j; $j++)
			{
				### TODO: What does this look like during a resync?
				print "j: [$j]\n";
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
				
				# These are set during a resync
#				$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'has-online-verify-details'} = $hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{'has-online-verify-details'};
# key: [db/dt [MiB/s]] -> [86.88]
# key: [db0/dt0 [MiB/s]] -> [86.88]
# key: [db1/dt1 [MiB/s]] -> [93.05]
# key: [estimated-seconds-to-finish] -> [213]
# key: [percent-resync-done] -> [3.35]
# key: [rs-db0-sectors] -> [1405248]
# key: [rs-db1-sectors] -> [933440]
# key: [rs-dt-start-ms] -> [7898]
# key: [rs-dt0-ms] -> [7898]
# key: [rs-dt1-ms] -> [4898]
# key: [rs-failed] -> [0]
# key: [rs-paused-ms] -> [0]
# key: [rs-same-csum] -> [1405248]
# key: [rs-total] -> [41940408]
# key: [want] -> [0]
				
				foreach my $key (sort {$a cmp $b} keys %{$hash_ref->{connections}->[$i]->{peer_devices}->[$j]})
				{
					print "key: [$key] -> [".$hash_ref->{connections}->[$i]->{peer_devices}->[$j]->{$key}."]\n";
				}
			}
		}
	}
	print "========================================================================================================\n";
	die;
	
	print "===] Full Dump [========================================================================================\n";
	print Dumper $drbd_status;
	print "========================================================================================================\n";
	my $count = @{$drbd_status};
	print "Array count: [$count]\n";
	foreach my $hash_ref (@{$drbd_status})
	{
		my $count = keys %{$hash_ref};
		print "Hash count: [$count]\n";
		foreach my $key (sort {$a cmp $b} keys %{$hash_ref})
		{
			if (ref($hash_ref->{$key}) eq "HASH")
			{
				print "key: [$key] is a hash\n";
				print Dumper $hash_ref->{$key};
			}
			elsif (ref($hash_ref->{$key}) eq "ARRAY")
			{
				print "key: [$key] is an array\n";
				print Dumper $hash_ref->{$key};
			}
			else
			{
				print "key: [$key] -> [".$hash_ref->{$key}."]\n";
			}
# 			if ($key eq "connections")
# 			{
# 				# Receive-Buffer Size in flight?
# 				$anvil->data->{drbd}{status}{$host}{$key} = $hash_ref->{$key};
# 				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::status::${host}::${key}" => $anvil->data->{drbd}{status}{$host}{$key} }});
# 			}
# 			elsif ($key eq "")
# 			{
# 				# 
# 				$anvil->data->{drbd}{status}{$host}{} = $hash_ref->{$key};
# 				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::status::${host}::" => $anvil->data->{drbd}{status}{$host}{} }});
# 			}
# 			elsif ($key eq "")
# 			{
# 				# 
# 				$anvil->data->{drbd}{status}{$host}{} = $hash_ref->{$key};
# 				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::status::${host}::" => $anvil->data->{drbd}{status}{$host}{} }});
# 			}
# 			elsif ($key eq "")
# 			{
# 				# 
# 				$anvil->data->{drbd}{status}{$host}{} = $hash_ref->{$key};
# 				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::status::${host}::" => $anvil->data->{drbd}{status}{$host}{} }});
# 			}
# 			elsif ($key eq "")
# 			{
# 				# 
# 				$anvil->data->{drbd}{status}{$host}{} = $hash_ref->{$key};
# 				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::status::${host}::" => $anvil->data->{drbd}{status}{$host}{} }});
# 			}
# 			else
# 			{
# 				print "Key: [".$key."] ========================================================================================\n";
# 				print Dumper $hash_ref->{$key};
# 			}
		}
	}
	print "========================================================================================================\n";
	foreach my $hash_ref (@{$drbd_status->[0]->{connections}})
	{
		#print "Hash ref: [".$hash_ref."]\n";
		my $peer_name = $hash_ref->{name};
		print "Connection: [".$peer_name."]\n";
		print "- ap-in-flight: ... [".$hash_ref->{'ap-in-flight'}."]\n";
		print "- Connection state: [".$hash_ref->{'connection-state'}."]\n";
		print "- Peer role: ...... [".$hash_ref->{'peer-role'}."]\n";
		print "- rs-in-flight: ... [".$hash_ref->{'rs-in-flight'}."]\n";
	}
	print "========================================================================================================\n";
	die;
	
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

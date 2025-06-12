package Anvil::Tools::DRBD;
# 
# This module contains methods used to manager DRBD 9
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Text::Diff;
use JSON;

our $VERSION  = "3.0.0";
my $THIS_FILE = "DRBD.pm";

### Methods;
# allow_two_primaries
# check_if_syncsource
# check_if_synctarget
# check_proxy_license
# delete_resource
# gather_data
# get_devices
# get_next_resource
# get_status
# manage_resource
# parse_resource
# reload_defaults
# remove_backing_lv
# resource_uuid
# update_global_common
# _initialize_kmod
# 

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

This enables or disables dual-primary for the given resource. This is meant to be called prior to a live migration, and should be disabled again as soon as possible. The return code of the C<< drbdsetup >> call is returned. If there is a problem, C<< 255 >> is returned.

Parameters; 

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 resource (required)

This is the name of the resource to enable two primaries on.

=head3 set_to (optional, default 'yes')

This can be set to C<< yes >> to allow two-primary, or C<< no >> to disable it. 

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->allow_two_primaries()" }});
	
	my $password       = defined $parameter->{password}       ? $parameter->{password}       : "";
	my $port           = defined $parameter->{port}           ? $parameter->{port}           : "";
	my $remote_user    = defined $parameter->{remote_user}    ? $parameter->{remote_user}    : "root";
	my $resource       = defined $parameter->{resource}       ? $parameter->{resource}       : "";
	my $set_to         = defined $parameter->{set_to}         ? $parameter->{set_to}         : "yes";
	my $target         = defined $parameter->{target}         ? $parameter->{target}         : "";
	my $target_node_id = defined $parameter->{target_node_id} ? $parameter->{target_node_id} : "";
	my $return_code    = 255; 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password       => $anvil->Log->is_secure($password),
		port           => $port, 
		set_to         => $set_to, 
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
	
	if (($set_to ne "yes") && ($set_to ne "no"))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0312", variables => { set_to => $set_to }});
		return($return_code);
	}
	
	# Do we need to scan devices?
	my $host = $anvil->Get->short_host_name;
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
		if ((exists $anvil->data->{drbd}{status}{$host})                                                               &&
		    (exists $anvil->data->{drbd}{status}{$host}{resource}{$resource})                                          && 
		    (exists $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name})                  && 
		    (defined $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'}) && 
		    ($anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'} =~ /^\d+$/))
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
	
	# If set to 'yes', make sure the peer is connected. Otherwise we'll just cause problems later when 
	# they do try to connect.
	if ($set_to eq "yes")
	{
		my $host = $anvil->Get->short_host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { host => $host }});
		if (not exists $anvil->data->{drbd}{config}{$host})
		{
			$anvil->DRBD->get_status({debug => $debug});
		}
		my $peer_name        = $anvil->data->{drbd}{config}{$host}{peer};
		my $connection_state = $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'connection-state'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			peer_name        => $peer_name,
			resource         => $resource,
			connection_state => $connection_state, 
		}});
		
		if (lc($connection_state) ne "connected")
		{
			# Don't do this!
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "error_0421", variables => { 
				resource         => $resource,
				peer_name        => $peer_name, 
				connection_state => $target_node_id, 
			}});
			return($return_code);
		}
	}
	
	my $key = $set_to eq "yes" ? "log_0350" : "log_0642";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 0, level => 1, key => $key, variables => { 
		resource       => $resource,
		target_name    => $peer_name, 
		target_node_id => $target_node_id, 
	}});
	
	my $shell_call = $anvil->data->{path}{exe}{drbdsetup}." net-options ".$resource." ".$target_node_id." --allow-two-primaries=".$set_to;
	my $output     = "";
	if ($anvil->Network->is_local({host => $target}))
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
	else
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


=head2 check_if_syncsource

This method checks to see if the local machine is C<< SyncSource >>. If so, this returns C<< 1 >>. Otherwise, it returns C<< 0 >>.

This method takes no parameters.

=cut
sub check_if_syncsource
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->check_if_syncsource()" }});
	
	my $short_host_name = $anvil->Get->short_host_name();
	$anvil->DRBD->get_status({debug => $debug});
		
	# Now check to see if anything is sync'ing.
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{drbd}{status}{$short_host_name}{resource}})
	{
		foreach my $peer_name (sort {$a cmp $b} keys %{$anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { peer_name => $peer_name }});
			foreach my $volume (sort {$a cmp $b} %{$anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}{$peer_name}{volume}})
			{
				next if not exists $anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'replication-state'};
				my $replication_state = $anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'replication-state'};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					volume            => $volume,
					replication_state => $replication_state, 
				}});
				
				if ($replication_state =~ /SyncSource/i)
				{
					# We're SyncSource
					return(1);
				}
			}
		}
	}
	
	return(0);
}


=head2 check_if_synctarget

This method checks to see if the local machine is C<< SyncTarget >>. If so, this returns C<< 1 >>. Otherwise, it returns C<< 0 >>.

This method takes no parameters.

=cut
sub check_if_synctarget
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->check_if_synctarget()" }});
	
	my $short_host_name = $anvil->Get->short_host_name();
	$anvil->DRBD->get_status({debug => $debug});
		
	# Now check to see if anything is sync'ing.
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{drbd}{status}{$short_host_name}{resource}})
	{
		foreach my $peer_name (sort {$a cmp $b} keys %{$anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { peer_name => $peer_name }});
			foreach my $volume (sort {$a cmp $b} %{$anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}{$peer_name}{volume}})
			{
				next if not exists $anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'replication-state'};
				my $replication_state = $anvil->data->{drbd}{status}{$short_host_name}{resource}{$resource}{connection}{$peer_name}{volume}{$volume}{'replication-state'};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					volume            => $volume,
					replication_state => $replication_state, 
				}});
				
				if ($replication_state =~ /SyncTarget/i)
				{
					# We're SyncTarget
					return(1);
				}
			}
		}
	}
	
	return(0);
}


=head2 check_proxy_license

This method checks to see if the DRBD Proxy license file exists and _appears_ correct. If things look good, C<< 0 >> is returned. If there is a problem, C<< 1 >> is returned.

=cut
sub check_proxy_license
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->check_proxy_license()" }});
	
	if (not -e $anvil->data->{path}{configs}{'drbd-proxy.license'})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0728"});
		return(1);
	}
	
	# Read in the file.
	my $wildcard_mac  = 0;
	my $problem       = 0;
	my $owner         = "";
	my $expiry_date   = 0;
	my $mac_addresses = [];
	my $features      = "";
	my $signature     = "";
	my $license_body  = $anvil->Storage->read_file({file => $anvil->data->{path}{configs}{'drbd-proxy.license'}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { license_body => $license_body }});
	foreach my $line (split/\n/, $license_body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /^owner: (.*)$/)
		{
			$owner = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { owner => $owner }});
			next;
		}
		if ($line =~ /^expiry-date: (.*)$/)
		{
			$expiry_date = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { expiry_date => $expiry_date }});
			next;
		}
		if ($line =~ /^mac-address: (.*)$/)
		{
			my $this_mac = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_mac => $this_mac }});
			
			if ($this_mac eq "00:00:00:00:00:00")
			{
				$wildcard_mac = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wildcard_mac => $wildcard_mac }});
			}
			
			push @{$mac_addresses}, $this_mac;
			next;
		}
		if ($line =~ /^features: (.*)$/)
		{
			$features = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { features => $features }});
			next;
		}
		if ($line =~ /^signature: (.*)$/)
		{
			$signature = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { signature => $signature }});
			next;
		}
	}
	
	if ((not $owner)       or 
	    (not $expiry_date) or 
	    (not $signature))
	{
		# Appears to not be a valid license file.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0731"});
		return(1);
	}
	
	if (time >= $expiry_date)
	{
		# The license has expired.
		$problem = 1;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0729"});
	}
	
	if (not $wildcard_mac)
	{
		# Loop through all MACs on this system and see if one matches the license.
		my $match     = 0;
		my $host      = $anvil->Get->short_host_name();
		my $mac_count = @{$mac_addresses};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host      => $host, 
			mac_count => $mac_count,
		}});
		
		if (not $mac_count)
		{
		}
		
		foreach my $in_iface (sort {$a cmp $b} keys %{$anvil->data->{network}{$host}{interface}})
		{
			my $mac_address = $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:in_iface'    => $in_iface,
				's2:mac_address' => $mac_address, 
			}});
			
			foreach my $licensed_mac (@{$mac_addresses})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { licensed_mac => $licensed_mac }});
				
				if (lc($mac_address) eq lc($licensed_mac))
				{
					$match = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { match => $match }});
					last;
				}
			}
			last if $match;
		}
		
		if (not $match)
		{
			# MACs don't match.
			$problem = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0730"});
		}
	}
	
	return($problem);
}


=head2 delete_resource

This method deletes an entire resource. It does this by looping through the volumes configured in a resource and deleting them one after the other (even if there is only one volume).

On success, C<< 0 >> is returned. If there are any issues, C<< !!error!! >> will be returned.

Parameters;

=head3 resource (required)

This is the name of the resource to be deleted.

=head3 wait (optional, default '1')

This controls whether we wait for a resource that is C<< Primary >> or C<< SyncSource >> to demote or the sync target to disconnect before proceeding. If whis is set to C<< 0 >>, instead of waiting, the method returns an error and aborts.

=cut
sub delete_resource
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->delete_resource()" }});
	
	my $resource = defined $parameter->{resource} ? $parameter->{resource} : "";
	my $wait     = defined $parameter->{'wait'}   ? $parameter->{'wait'}   : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		resource => $resource, 
		'wait'   => $wait
	}});
	
	if (not $resource)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->delete_resource()", parameter => "resource" }});
		return('!!error!!');
	}
	
	$anvil->DRBD->gather_data({debug => $debug});
	if (not exists $anvil->data->{new}{resource}{$resource})
	{
		# Resource not found, so it appears to already be gone.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0228", variables => { resource => $resource }});
		return(0);
	}
	
	my $waiting = 1;
	while($waiting)
	{
		my $peer_needs_us = 0;
		foreach my $volume (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{volume}})
		{
			# If we're sync source, or we're primary, we'll either wait or abort.
			my $device_path  = $anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_path};
			my $backing_disk = $anvil->data->{new}{resource}{$resource}{volume}{$volume}{backing_disk};
			my $device_minor = $anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_minor};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:device_path'  => $device_path, 
				's2:backing_disk' => $backing_disk, 
				's3:device_minor' => $device_minor, 
			}});
			$anvil->data->{drbd}{resource}{$resource}{backing_disk}{$backing_disk} = 1;
			foreach my $peer (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"new::resource::${resource}::volume::${volume}::peer::${peer}::local_disk_state" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state},
				}});
				if (($anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state} eq "startingsyncs") or 
				    ($anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state} eq "syncsource")    or 
				    ($anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state} eq "pausedsyncs")   or 
				    ($anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state} eq "ahead"))
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0074", variables => {
						peer_name  => $peer,
						resource   => $resource,
						volume     => $volume,
						disk_state => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state},
					}});
					
					$peer_needs_us = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { peer_needs_us => $peer_needs_us }});
				}
			}
		}
		if ($peer_needs_us)
		{
			if (not $wait)
			{
				# Abort.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0229"});
				return('!!error!!');
			}
			else
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0588"});
				sleep 10;
				$anvil->DRBD->gather_data({debug => $debug})
			}
		}
		else
		{
			# No need to wait now.
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { waiting => $waiting }});
		}
	}
	
	# Down the resource, if needed.
	my $return_code = $anvil->DRBD->manage_resource({
		debug    => $debug,
		resource => $resource, 
		task     => "down",
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
	if ($return_code)
	{
		# Don't proceed, we'd leave the resource up and unusable
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0401", variables => { 
			resource    => $resource, 
			return_code => $return_code,
		}});
		return('!!error!!');
	}
	
	# Wipe the DRBD MDs from each backing LV
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0590", variables => { resource => $resource }});
	my $shell_call = $anvil->data->{path}{exe}{drbdadm}." --force wipe-md ".$resource;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	(my $output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	if ($return_code)
	{
		# Should have been '0'
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0230", variables => { 
			shell_call  => $shell_call, 
			return_code => $return_code,
			output      => $output, 
		}});
		return('!!error!!');
	}
	
	# Now wipefs and lvremove each backing device
	foreach my $backing_disk (sort {$a cmp $b} keys %{$anvil->data->{drbd}{resource}{$resource}{backing_disk}})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0591", variables => { device_path => $backing_disk }});
		my $return_code = $anvil->DRBD->remove_backing_lv({
			debug        => $debug, 
			backing_disk => $backing_disk, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
		if ($return_code)
		{
			# Should have been '0'
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0230", variables => { 
				shell_call  => $shell_call, 
				return_code => $return_code,
				output      => $output, 
			}});
			return('!!error!!');
		}
	}
	
	# In the off chance something brough the resource back up, take it down again.
	my $test_directory = "/dev/drbd/by-res/".$resource;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_directory => $test_directory }});
	if (-e $test_directory)
	{
		my $return_code = $anvil->DRBD->manage_resource({
			debug    => $debug,
			resource => $resource, 
			task     => "down",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
		if ($return_code)
		{
			# Don't proceed, we'd leave the resource up and unusable
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0401", variables => { 
				resource    => $resource, 
				return_code => $return_code,
			}});
			return('!!error!!');
		}
	}
	
	# Now unlink the resource config file.
	my $resource_file = $anvil->data->{new}{resource}{$resource}{config_file};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource_file => $resource_file }});
	if (-f $resource_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0589", variables => { file => $resource_file }});
		unlink $resource_file;
		sleep 1;
		if (-f $resource_file)
		{
			# WTF?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0243", variables => { file => $resource_file }});
			return('!!error!!');
		}
		else
		{
			# Success!
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "job_0134", variables => { file_path => $resource_file }});
		}
	}
	
	# If we're DR, delete the definition file also.
	my $definition_file = $anvil->data->{path}{directories}{shared}{definitions}."/".$resource.".xml";
	my $host_type       = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		definition_file => $definition_file,
		host_type       => $host_type, 
	}});
	if (($host_type eq "dr") && (-f $definition_file))
	{
		unlink $definition_file;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "job_0134", variables => { file_path => $definition_file }});
	}
	
	# Call scan-lvm and scan-drbd to make sure the databases are updated.
	foreach my $agent ("scan-drbd", "scan-lvm")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0740", variables => { agent => $agent }});
		
		my $shell_call = $anvil->data->{path}{directories}{scan_agents}."/".$agent."/".$agent.$anvil->Log->switches();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code, 
		}});
	}
	
	return(0);
}


=head2 gather_data

This calls C<< drbdadm >> to collect the configuration of the local system and parses it. This methid is designed for use by C<< scan_drbd >>, but is useful elsewhere. This is note-worthy as the data is stored under a C<< new::... >> hash.

On error, C<< 1 >> is returned. On success, C<< 0 >> is returned.

Parameters;

=head3 xml (optional)

If set to the XML generated by C<< drbdadm dump-xml >> elsewhere, this will be parsed instead of making the call.

=cut
sub gather_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->gather_data()" }});
	
	### NOTE: Left off here - take an XML and parse that instead of collecting it, if passed.
	my $xml = defined $parameter->{xml} ? $parameter->{xml} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		xml => $xml,
	}});
	
	# Is DRBD even installed?
	if (not $xml)
	{
		if (not -e $anvil->data->{path}{exe}{drbdadm})
		{
			# This is an error, but it happens a lot because we're called by scan_drbd from Striker 
			# dashboards often. As such, this log level is '2'.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "error_0251"});
			return(1);
		}
		
		($xml, my $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{drbdadm}." dump-xml"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			xml         => $xml, 
			return_code => $return_code,
		}});
		if ($return_code)
		{
			# Failed to dump the XML.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0252", variables => { return_code => $return_code }});
			return(1);
		}
	}
	
	my $local_host_name       = $anvil->Get->host_name;
	my $local_short_host_name = $anvil->Get->short_host_name;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		local_host_name       => $local_host_name, 
		local_short_host_name => $local_short_host_name, 
	}});
	
	# Often, annoyingly, DRBD reports a message about usage before showing the XML. We need to detect and
	# strip that off.
	my $new_xml = "";
	my $in_xml  = 0;
	foreach my $line (split/\n/, $xml)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /<config/)
		{
			$in_xml = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_xml => $in_xml }});
		}
		next if not $in_xml;
		$new_xml .= $line."\n";
	}
	$xml = $new_xml;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { xml => $xml }});
	
	local $@;
	my $dom = eval { XML::LibXML->load_xml(string => $xml); };
	if ($@)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0253", variables => { 
			xml   => $xml,
			error => $@,
		}});
		return(1);
	}
	else
	{
		# Successful parse!
		### TODO: Might be best to config these default values by calling/parsing 
		###       'drbdsetup show <resource> --show-defaults'.
		$anvil->data->{new}{scan_drbd}{scan_drbd_common_xml}       = $xml;
		$anvil->data->{new}{scan_drbd}{scan_drbd_flush_disk}       = 1;
		$anvil->data->{new}{scan_drbd}{scan_drbd_flush_md}         = 1;
		$anvil->data->{new}{scan_drbd}{scan_drbd_timeout}          = 6;		# Default is '60', 6 seconds
		$anvil->data->{new}{scan_drbd}{scan_drbd_total_sync_speed} = 0;
		foreach my $name ($dom->findnodes('/config/common/section'))
		{
			my $section = $name->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { section => $section }});
			foreach my $option_name ($name->findnodes('./option'))
			{
				my $variable = $option_name->{name};
				my $value    = $option_name->{value};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:variable' => $variable, 
					's2:value'    => $value,
				}});

				if ($section eq "net")
				{
					if ($variable eq "timeout")
					{
						$value /= 10;
						$anvil->data->{new}{scan_drbd}{scan_drbd_timeout} = ($value / 10);
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::scan_drbd::scan_drbd_timeout" => $anvil->data->{new}{scan_drbd}{scan_drbd_timeout}, 
						}});
					}
				}
				if ($section eq "disk")
				{
					if ($variable eq "disk-flushes")
					{
						$anvil->data->{new}{scan_drbd}{scan_drbd_flush_disk} = $value eq "no" ? 0 : 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::scan_drbd::scan_drbd_flush_disk" => $anvil->data->{new}{scan_drbd}{scan_drbd_flush_disk}, 
						}});
					}
					if ($variable eq "md-flushes")
					{
						$anvil->data->{new}{scan_drbd}{scan_drbd_flush_md} = $value eq "no" ? 0 : 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::scan_drbd::scan_drbd_flush_md" => $anvil->data->{new}{scan_drbd}{scan_drbd_flush_md}, 
						}});
					}
				}
			}
		}
		
		foreach my $name ($dom->findnodes('/config/resource'))
		{
			my $resource  =  $name->{name};
			my $conf_file =  $name->{'conf-file-line'};
			   $conf_file =~ s/:\d+$//;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:resource'  => $resource, 
				's2:conf_file' => $conf_file,
			}});
			
			$anvil->data->{new}{resource}{$resource}{up}          = 0;
			$anvil->data->{new}{resource}{$resource}{xml}         = $name->toString;
			$anvil->data->{new}{resource}{$resource}{config_file} = $conf_file;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"new::resource::${resource}::xml"         => $anvil->data->{new}{resource}{$resource}{xml},
				"new::resource::${resource}::config_file" => $anvil->data->{new}{resource}{$resource}{config_file},
			}});
			
			foreach my $host ($name->findnodes('./host'))
			{
				my $this_host_name = $host->{name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_name => $this_host_name }});
				
				# Record the details under the hosts
				foreach my $volume_vnr ($host->findnodes('./volume'))
				{
					my $volume    = $volume_vnr->{vnr};
					my $meta_disk = $volume_vnr->findvalue('./meta-disk');
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:volume'    => $volume,
						's2:meta_disk' => $meta_disk, 
					}});
					
					$anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{device_path}  = $volume_vnr->findvalue('./device');
					$anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{backing_disk} = $volume_vnr->findvalue('./disk');
					$anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{device_minor} = $volume_vnr->findvalue('./device/@minor');
					$anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{meta_disk}    = $meta_disk;
					$anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{size}         = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:new::resource::${resource}::host::${this_host_name}::volume::${volume}::device_path"  => $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{device_path},
						"s2:new::resource::${resource}::host::${this_host_name}::volume::${volume}::backing_disk" => $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{backing_disk},
						"s3:new::resource::${resource}::host::${this_host_name}::volume::${volume}::device_minor" => $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{device_minor},
						"s4:new::resource::${resource}::host::${this_host_name}::volume::${volume}::meta_disk"    => $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{meta_disk},
					}});
					
					# Record the local data only.
					if (($this_host_name eq $local_host_name) or ($this_host_name eq $local_short_host_name))
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_path}  = $volume_vnr->findvalue('./device');
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{backing_disk} = $volume_vnr->findvalue('./disk');
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_minor} = $volume_vnr->findvalue('./device/@minor');
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{size}         = 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:new::resource::${resource}::volume::${volume}::device_path"  => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_path},
							"s2:new::resource::${resource}::volume::${volume}::backing_disk" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{backing_disk},
							"s3:new::resource::${resource}::volume::${volume}::device_minor" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_minor},
						}});
					}
				}
			}
			
			foreach my $connection ($name->findnodes('./connection'))
			{
				my $host1_name       = "";
				my $host1_ip_address = "";
				my $host1_tcp_port   = "";
				my $host2_name       = "";
				my $host2_ip_address = "";
				my $host2_tcp_port   = "";
				my $peer             = "";
				foreach my $host ($connection->findnodes('./host'))
				{
					my $this_host_name = $host->{name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_name => $this_host_name }});
					if (not $host1_name)
					{
						$host1_name       = $this_host_name;
						$host1_ip_address = $host->findvalue('./address');
						$host1_tcp_port   = $host->findvalue('./address/@port');
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							host1_name       => $host1_name,
							host1_ip_address => $host1_ip_address, 
							host1_tcp_port   => $host1_tcp_port, 
						}});
					}
					else
					{
						$host2_name       = $this_host_name;
						$host2_ip_address = $host->findvalue('./address');
						$host2_tcp_port   = $host->findvalue('./address/@port');
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							host2_name       => $host2_name,
							host2_ip_address => $host2_ip_address, 
							host2_tcp_port   => $host2_tcp_port, 
						}});
						
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address} = $host1_ip_address;
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port}   = $host1_tcp_port;
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address} = $host2_ip_address;
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port}   = $host2_tcp_port;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host1_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address},
							"s2:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host1_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port},
							"s3:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address},
							"s4:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port},
						}});
						
						foreach my $proxy ($host->findnodes('./proxy'))
						{
							my $host_name = $proxy->{hostname};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
							
							# This should always be the target, but lets be safe/careful
							next if $host_name ne $host2_name;
							
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_ip_address}  = $proxy->findvalue('./inside');
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_tcp_port}    = $proxy->findvalue('./inside/@port');
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_ip_address} = $proxy->findvalue('./outside');
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_tcp_port}   = $proxy->findvalue('./outside/@port');
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"s1:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_inside_ip_address"  => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_ip_address},
								"s2:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_inside_tcp_port"    => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_tcp_port},
								"s3:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_outside_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_ip_address},
								"s4:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_outside_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_tcp_port},
							}});
							
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{ip_address}  = $proxy->findvalue('./inside');
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{tcp_port}    = $proxy->findvalue('./inside/@port');
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{ip_address} = $proxy->findvalue('./outside');
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{tcp_port}   = $proxy->findvalue('./outside/@port');
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"new::resource::${resource}::proxy::${host_name}::inside::ip_address"  => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{ip_address},
								"new::resource::${resource}::proxy::${host_name}::inside::tcp_port"    => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{tcp_port},
								"new::resource::${resource}::proxy::${host_name}::outside::ip_address" => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{ip_address},
								"new::resource::${resource}::proxy::${host_name}::outside::tcp_port"   => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{tcp_port},
							}});
						}
					}
					
# 					$peer                                                                  = $this_host_name;
# 					$anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address} = $host->findvalue('./address'); 
# 					$anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port}        = $host->findvalue('./address/@port'); 
# 					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 						"s1:new::resource::${resource}::peer::${peer}::peer_ip_address" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address},
# 						"s2:new::resource::${resource}::peer::${peer}::tcp_port"        => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port}." (".$host->findvalue('./address/@port').")",
# 					}});
					
# 					if (not exists $anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol})
# 					{
# 						$anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol}        = "unknown";
# 						$anvil->data->{new}{resource}{$resource}{peer}{$peer}{fencing}         = "unknown";
# 						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 							"s1:new::resource::${resource}::peer::${peer}::protocol" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol},
# 							"s2:new::resource::${resource}::peer::${peer}::fencing"  => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{fencing},
# 						}});
# 					}
# 					
# 					foreach my $volume (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{volume}})
# 					{
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{connection_state}       = "disconnected";
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state}       = "down"; 
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_disk_state}        = "unknown"; 
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_role}             = "down"; 
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_role}              = "unknown"; 
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{out_of_sync_size}       = -1; 
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed}      = 0;
# 						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{estimated_time_to_sync} = 0; 
# 					}
				}
				
				if (($host1_name eq $local_short_host_name) or 
				    ($host1_name eq $local_host_name)       or 
				    ($host2_name eq $local_short_host_name) or 
				    ($host2_name eq $local_host_name))
				{
					# This is one of our connections.
					my $peer = "";
					if (($host1_name eq $local_short_host_name) or ($host1_name eq $local_host_name))
					{
						# Our peer is host2
						$peer                                                                  = $host2_name;
						$anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address} = $host2_ip_address; 
						$anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port}        = $host2_tcp_port; 
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:new::resource::${resource}::peer::${peer}::peer_ip_address" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address},
							"s2:new::resource::${resource}::peer::${peer}::tcp_port"        => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port},
						}});
					}
					else
					{
						# Our peer is host1
						$peer                                                                  = $host1_name;
						$anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address} = $host1_ip_address; 
						$anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port}        = $host1_tcp_port; 
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:new::resource::${resource}::peer::${peer}::peer_ip_address" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address},
							"s2:new::resource::${resource}::peer::${peer}::tcp_port"        => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port},
						}});
					}
					
					foreach my $name ($connection->findnodes('./section'))
					{
						my $section = $name->{name};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { section => $section }});
						
						foreach my $option_name ($name->findnodes('./option'))
						{
							my $variable = $option_name->{name};
							my $value    = $option_name->{value};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								's1:variable' => $variable, 
								's2:value'    => $value,
							}});

							if ($section eq "net")
							{
								if ($variable eq "protocol")
								{
									$anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol} = $value;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
										"new::resource::${resource}::peer::${peer}::protocol" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol},
									}});
								}
								if ($variable eq "fencing")
								{
									$anvil->data->{new}{resource}{$resource}{peer}{$peer}{fencing} = $value;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
										"new::resource::${resource}::peer::${peer}::fencing" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{fencing},
									}});
								}
							}
						}
					}
					
					foreach my $volume (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{volume}})
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{connection_state}       = "disconnected";
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state}       = "down"; 
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_disk_state}        = "unknown"; 
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_role}             = "down"; 
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_role}              = "unknown"; 
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{out_of_sync_size}       = -1; 
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed}      = 0;
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{estimated_time_to_sync} = 0; 
					}
				}
			}
		}
	}
	
	# If DRBD is stopped, this directory won't exist.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"path::directories::resource_status" => $anvil->data->{path}{directories}{resource_status},
	}});
	if (-d $anvil->data->{path}{directories}{resource_status})
	{
		local(*DIRECTORY);
		opendir(DIRECTORY, $anvil->data->{path}{directories}{resource_status});
		while(my $file = readdir(DIRECTORY))
		{
			next if $file eq ".";
			next if $file eq "..";
			my $full_path = $anvil->data->{path}{directories}{resource_status}."/".$file;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { full_path => $full_path }});
			if (-d $full_path)
			{
				my $resource                                    = $file;
				$anvil->data->{new}{resource}{$resource}{up} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"new::resource::${resource}::up" => $anvil->data->{new}{resource}{$resource}{up},
				}});
			}
		}
		closedir(DIRECTORY);
	}

	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"new::resource::${resource}::up" => $anvil->data->{new}{resource}{$resource}{up},
		}});
		
		# If the resource isn't up, there's won't be a proc file to read.
		next if not $anvil->data->{new}{resource}{$resource}{up};
		
		foreach my $volume (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{volume}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { volume => $volume }});
			
			foreach my $peer (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}})
			{
				my $proc_file = $anvil->data->{path}{directories}{resource_status}."/".$resource."/connections/".$peer."/".$volume."/proc_drbd";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { proc_file => $proc_file }});
				
				my $file_body = $anvil->Storage->read_file({file => $proc_file});
				my $progress  = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
				foreach my $line (split/\n/, $file_body)
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});

					if ($line =~ /cs:(.*?) /)
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{connection_state} = lc($1);
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::resource::${resource}::volume::${volume}::peer::${peer}::connection_state" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{connection_state},
						}});
					}
					if ($line =~ /ro:(.*?)\/(.*?) /)
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_role} = lc($1);
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_role}  = lc($2);
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::resource::${resource}::volume::${volume}::peer::${peer}::local_role" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_role},
							"new::resource::${resource}::volume::${volume}::peer::${peer}::peer_role"  => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_role},
						}});
						
						# Get the resource size by reading '/sys/block/drbd<minor>/size' and multiplying by '/sys/block/<disk>/queue/logical_block_size'
						my $drbd_device = "/sys/block/drbd".$anvil->data->{new}{resource}{$resource}{volume}{$volume}{device_minor};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { drbd_device => $drbd_device }});
						if (-d $drbd_device)
						{
							my $logical_block_size = $anvil->Words->clean_spaces({string => $anvil->Storage->read_file({file => $drbd_device."/queue/logical_block_size"})});
							my $sector_size        = $anvil->Words->clean_spaces({string => $anvil->Storage->read_file({file => $drbd_device."/size"})});
							my $size               = $logical_block_size * $sector_size;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
								logical_block_size => $anvil->Convert->add_commas({number => $logical_block_size}),
								sector_size        => $anvil->Convert->add_commas({number => $sector_size}),
								size               => $anvil->Convert->add_commas({number => $size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size}).")",
							}});
							
							if ($size > 0)
							{
								$anvil->data->{new}{resource}{$resource}{volume}{$volume}{size} = $size;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
									"new::resource::${resource}::volume::${volume}::size" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{size}}).")",
								}});
							}
						}
					}
					if ($line =~ /ds:(.*?)\/(.*?) /)
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state} = lc($1);
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_disk_state}  = lc($2); 
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::resource::${resource}::volume::${volume}::peer::${peer}::local_disk_state" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{local_disk_state},
							"new::resource::${resource}::volume::${volume}::peer::${peer}::peer_disk_state"  => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{peer_disk_state},
						}});
					}
					if ($line =~ /oos:(\d+)/)
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{out_of_sync_size} = $1 * 1024;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::resource::${resource}::volume::${volume}::peer::${peer}::out_of_sync_size" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{out_of_sync_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{out_of_sync_size}}).")",
						}});
					}
					
					if ($line =~ /sync'ed:\s+(\d.*\%)/)
					{
						$progress .= $1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { progress => $progress }});
					}
					if ($line =~ /speed: (.*?) \(/)
					{
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed} =  $1;
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed} =~ s/,//g;
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed} *= 1024;
						$anvil->data->{new}{scan_drbd}{scan_drbd_total_sync_speed}                                += $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed};
						
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:new::resource::${resource}::volume::${volume}::peer::${peer}::replication_speed" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{replication_speed}}).")",
							"s2:new::scan_drbd::scan_drbd_total_sync_speed"                                      => $anvil->data->{new}{scan_drbd}{scan_drbd_total_sync_speed}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{new}{scan_drbd}{scan_drbd_total_sync_speed}}).")",
						}});
						   
					}
					if ($line =~ /finish: (\d+):(\d+):(\d+) /)
					{
						my $hours   = $1;
						my $minutes = $2;
						my $seconds = $3;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:hours'   => $hours,
							's2:minutes' => $minutes,
							's3:seconds' => $seconds,
						}});
						
						$anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{estimated_time_to_sync} = (($hours * 3600) + ($minutes * 60) + $seconds);
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"new::resource::${resource}::volume::${volume}::peer::${peer}::estimated_time_to_sync" => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{estimated_time_to_sync}." (".$anvil->Convert->time({'time' => $anvil->data->{new}{resource}{$resource}{volume}{$volume}{peer}{$peer}{estimated_time_to_sync}, long => 1, translate => 1}).")",
						}});
					}
				}
			}
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"new::scan_drbd::scan_drbd_total_sync_speed" => $anvil->data->{new}{scan_drbd}{scan_drbd_total_sync_speed}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{new}{scan_drbd}{scan_drbd_total_sync_speed}}).")",
	}});
	
	# For resources using drbd-proxy, the host1_to_host2 will be using the internal IP, which we want to 
	# switch to the 'outside' IP. Also, the ports will need to be concatenated together as a CSV list.
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		foreach my $host1_name (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{host1_to_host2}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host1_name => $host1_name }});
			foreach my $host2_name (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host2_name => $host2_name }});
				
				my $host1_ip_address = $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address};
				my $host1_tcp_port   = $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port};
				my $host2_ip_address = $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address};
				my $host2_tcp_port   = $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:host1_ip_address" => $host1_ip_address,
					"s2:host1_tcp_port"   => $host1_tcp_port,
					"s3:host2_ip_address" => $host2_ip_address,
					"s4:host2_tcp_port"   => $host2_tcp_port,
				}});
				
				my $host1_tcp_ports = $host1_tcp_port.",";
				my $host2_tcp_ports = $host2_tcp_port.",";
				my $proxy_found = 0;
				if (exists $anvil->data->{new}{resource}{$resource}{proxy}{$host1_name})
				{
					   $proxy_found              =  1;
					my $host1_inside_ip_address  =  $anvil->data->{new}{resource}{$resource}{proxy}{$host1_name}{inside}{ip_address};
					my $host1_inside_tcp_port    =  $anvil->data->{new}{resource}{$resource}{proxy}{$host1_name}{inside}{tcp_port};
					my $host1_outside_ip_address =  $anvil->data->{new}{resource}{$resource}{proxy}{$host1_name}{outside}{ip_address};
					my $host1_outside_tcp_port   =  $anvil->data->{new}{resource}{$resource}{proxy}{$host1_name}{outside}{tcp_port};
					   $host1_tcp_ports          .= $host1_inside_tcp_port.",".$host1_outside_tcp_port;
					   $host1_ip_address         =  $host1_outside_ip_address;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:proxy_found"              => $proxy_found, 
						"s2:host1_inside_ip_address"  => $host1_inside_ip_address,
						"s3:host1_inside_tcp_port"    => $host1_inside_tcp_port,
						"s4:host1_outside_ip_address" => $host1_outside_ip_address,
						"s5:host1_outside_tcp_port"   => $host1_outside_tcp_port,
						"s6:host1_tcp_ports"          => $host1_tcp_ports, 
						"s7:host1_ip_address"         => $host1_ip_address, 
					}});
				}
				if (exists $anvil->data->{new}{resource}{$resource}{proxy}{$host2_name})
				{
					   $proxy_found              =  1;
					my $host2_inside_ip_address  =  $anvil->data->{new}{resource}{$resource}{proxy}{$host2_name}{inside}{ip_address};
					my $host2_inside_tcp_port    =  $anvil->data->{new}{resource}{$resource}{proxy}{$host2_name}{inside}{tcp_port};
					my $host2_outside_ip_address =  $anvil->data->{new}{resource}{$resource}{proxy}{$host2_name}{outside}{ip_address};
					my $host2_outside_tcp_port   =  $anvil->data->{new}{resource}{$resource}{proxy}{$host2_name}{outside}{tcp_port};
					   $host2_tcp_ports          .= $host2_inside_tcp_port.",".$host2_outside_tcp_port;
					   $host2_ip_address         =  $host2_outside_ip_address;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:proxy_found"              => $proxy_found, 
						"s2:host2_inside_ip_address"  => $host2_inside_ip_address,
						"s3:host2_inside_tcp_port"    => $host2_inside_tcp_port,
						"s4:host2_outside_ip_address" => $host2_outside_ip_address,
						"s5:host2_outside_tcp_port"   => $host2_outside_tcp_port,
						"s6:host2_tcp_ports"          => $host2_tcp_ports, 
						"s7:host2_ip_address"         => $host2_ip_address, 
					}});
				}
				next if not $proxy_found;
				
				# Clear off trailing commas
				$host1_tcp_ports =~ s/,$//;
				$host2_tcp_ports =~ s/,$//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:host1_tcp_ports" => $host1_tcp_ports, 
					"s2:host2_tcp_ports" => $host2_tcp_ports, 
				}});
				
				# Save the new info.
				$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address} = $host1_ip_address;
				$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port}   = $host1_tcp_ports;
				$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address} = $host2_ip_address;
				$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port}   = $host2_tcp_ports;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host1_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address},
					"s2:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host1_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port},
					"s3:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address},
					"s4:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port},
				}});
				
				my $peer = "";
				if (($host1_name eq $local_short_host_name) or ($host1_name eq $local_host_name))
				{
					# Our peer is host2. Is the protocol C? If so, this can't be proxy.
					   $peer          = $host2_name;
					my $peer_protocol = $anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:peer"          => $peer,
						"s2:peer_protocol" => $peer_protocol,
					}});
					next if uc($peer_protocol) eq "C";
					
					# Still here? Then this is a proxy connection, update the ports and IP
					$anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address} = $host2_ip_address; 
					$anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port}        = $host1_tcp_ports; 	# Store our ports.
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:new::resource::${resource}::peer::${peer}::peer_ip_address" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address},
						"s2:new::resource::${resource}::peer::${peer}::tcp_port"        => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port},
					}});
				}
				else
				{
					# Our peer is host1, Is the protocol C? If so, this can't be proxy.
					   $peer          = $host1_name;
					my $peer_protocol = $anvil->data->{new}{resource}{$resource}{peer}{$peer}{protocol};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:peer"          => $peer,
						"s2:peer_protocol" => $peer_protocol,
					}});
					next if uc($peer_protocol) eq "C";
					
					# Still here? Then this is a proxy connection, update the ports and IP
					$anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address} = $host1_ip_address; 
					$anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port}        = $host2_tcp_ports; 	# Store out ports
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:new::resource::${resource}::peer::${peer}::peer_ip_address" => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{peer_ip_address},
						"s2:new::resource::${resource}::peer::${peer}::tcp_port"        => $anvil->data->{new}{resource}{$resource}{peer}{$peer}{tcp_port},
					}});
				}
			}
		}
	}
	
	return(0);
}


=head2 get_devices

This finds all of the configured '/dev/drbdX' devices and maps them to their resource names.

Parameters;

=head3 anvil_uuid (optional)

If set, the C<< drbdadm dump-xml >> is not called, instead the most recent version as recorded in C<< scan_drbd -> scan_drbd_common_xml >> is loaded from one of the hosts.

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->get_devices()" }});
	
	my $anvil_uuid  = defined $parameter->{anvil_uuid}  ? $parameter->{anvil_uuid}  : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid  => $anvil_uuid, 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# If we've got an anvil_uuid, search for the drbd common XML from the database.
	my $host   = $anvil->Get->short_host_name;
	my $output = "";
	if ($anvil_uuid)
	{
		if (not exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid})
		{
			$anvil->Database->get_anvils({debug => $debug});
			if (not exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid})
			{
				# Failed to find the Anvil! data.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0360", variables => { anvil_uuid => $anvil_uuid }});
				return("!!error!!");
			}
		}
		my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			node1_host_uuid => $node1_host_uuid,
			node2_host_uuid => $node2_host_uuid,
		}});
		
		my $query = "
SELECT 
    scan_drbd_common_xml 
FROM 
    scan_drbd 
WHERE 
    scan_drbd_host_uuid = ".$anvil->Database->quote($node1_host_uuid)."
OR 
    scan_drbd_host_uuid = ".$anvil->Database->quote($node2_host_uuid)."
ORDER BY modified_date DESC 
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
			# Nothing found
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0361", variables => { anvil_uuid => $anvil_uuid }});
			return("!!error!!");
		}
		$output = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	}
	else
	{
		# Is this a local call or a remote call?
		my $shell_call = $anvil->data->{path}{exe}{drbdadm}." dump-xml";
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local.
			($output, $anvil->data->{drbd}{'drbdadm-xml'}{return_code}) = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output                           => $output,
				"drbd::drbdadm-xml::return_code" => $anvil->data->{drbd}{'drbdadm-xml'}{return_code},
			}});
		}
		else
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
	}
	
	# Clear the hash where we'll store the data.
	if (exists $anvil->data->{drbd}{config}{$host})
	{
		delete $anvil->data->{drbd}{config}{$host};
	}
	
	local $@;
	my $xml      = XML::Simple->new();
	my $dump_xml = "";
	my $test     = eval { $dump_xml = $xml->XMLin($output, KeyAttr => {}, ForceArray => 1) };
	if (not $test)
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
					value    => $value, 
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
				this_host              => $this_host,
				'Get->host_name'       => $anvil->Get->host_name,
				'Get->short_host_name' => $anvil->Get->short_host_name,
			}});
			if (($this_host eq $anvil->Get->host_name) or ($this_host eq $anvil->Get->short_host_name))
			{
				$anvil->data->{drbd}{config}{$host}{host} = $this_host;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "drbd::config::${host}::host" => $anvil->data->{drbd}{config}{$host}{host} }});
			}
			foreach my $volume_href (@{$host_href->{volume}})
			{
				my $volume                                                                                          = $volume_href->{vnr};
				my $lv_path                                                                                         = $volume_href->{disk}->[0];
				my $by_res                                                                                          = "/dev/drbd/by-res/".$this_resource."/".$volume;
				my $drbd_path                                                                                       = $by_res;	# This used to be '/dev/drbd_<server_name>_<volume>' before it was phased out.
				my $minor                                                                                           = $volume_href->{device}->[0]->{minor};
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_path}        = "/dev/drbd".$minor;
				   ### TODO: Anything using these are broken as the values get rewritten and 
				   ###       only store the last DRBD node's data. Switch to using the 
				   ###       'this_host' stored values below
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_path_by_res} = $by_res;
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_minor}       = $minor;
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{'meta-disk'}      = $volume_href->{'meta-disk'}->[0];
				   $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{backing_lv}       = $lv_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::drbd_path"        => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_path},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::drbd_path_by_res" => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_path_by_res},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::drbd_minor"       => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{drbd_minor},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::meta-disk"        => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{'meta-disk'},
					"drbd::config::${host}::resource::${this_resource}::volume::${volume}::backing_lv"       => $anvil->data->{drbd}{config}{$host}{resource}{$this_resource}{volume}{$volume}{backing_lv},
				}});
				
				if (($anvil->data->{drbd}{config}{$host}{host}) && ($anvil->data->{drbd}{config}{$host}{host} eq $this_host))
				{
					$anvil->data->{drbd}{config}{$host}{by_res}{$by_res}{on}             = $lv_path;
					$anvil->data->{drbd}{config}{$host}{by_res}{$by_res}{resource}       = $this_resource;
					$anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{on}       = $lv_path;
					$anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{resource} = $this_resource;
					$anvil->data->{drbd}{config}{$host}{lv_path}{$lv_path}{under}        = $drbd_path;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
						"drbd::config::${host}::by_res::${by_res}::on"             => $anvil->data->{drbd}{config}{$host}{by_res}{$by_res}{on},
						"drbd::config::${host}::by_res::${by_res}::resource"       => $anvil->data->{drbd}{config}{$host}{by_res}{$by_res}{resource},
						"drbd::config::${host}::drbd_path::${drbd_path}::on"       => $anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{on},
						"drbd::config::${host}::drbd_path::${drbd_path}::resource" => $anvil->data->{drbd}{config}{$host}{drbd_path}{$drbd_path}{resource},
						"drbd::config::${host}::lv_path::${lv_path}::under"        => $anvil->data->{drbd}{config}{$host}{lv_path}{$lv_path}{under},
					}});
				}
				
				# If this is ourself, store the resource name and backing LV in the 'by-res' 
				# hash.
				if ($anvil->Network->is_local({host => $this_host}))
				{
					$anvil->data->{drbd}{config}{$host}{'by-res'}{$by_res}{resource}   = $this_resource;
					$anvil->data->{drbd}{config}{$host}{'by-res'}{$by_res}{backing_lv} = $lv_path;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"drbd::config::${host}::by-res::${by_res}::resource"   => $anvil->data->{drbd}{config}{$host}{'by-res'}{$by_res}{resource},
						"drbd::config::${host}::by-res::${by_res}::backing_lv" => $anvil->data->{drbd}{config}{$host}{'by-res'}{$by_res}{backing_lv},
					}});
				}
				
				# This records the backing LV data for all hosts in this resource.
				$anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{drbd_path}        = "/dev/drbd".$minor;
				$anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{drbd_path_by_res} = $by_res;
				$anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{drbd_minor}       = $minor;
				$anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{'meta-disk'}      = $volume_href->{'meta-disk'}->[0];
				$anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{backing_lv}       = $lv_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"drbd::drbd_node::${this_host}::config::resource::${this_resource}::volume::${volume}::drbd_path"        => $anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{drbd_path},
					"drbd::drbd_node::${this_host}::config::resource::${this_resource}::volume::${volume}::drbd_path_by_res" => $anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{drbd_path_by_res},
					"drbd::drbd_node::${this_host}::config::resource::${this_resource}::volume::${volume}::drbd_minor"       => $anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{drbd_minor},
					"drbd::drbd_node::${this_host}::config::resource::${this_resource}::volume::${volume}::meta-disk"        => $anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{'meta-disk'},
					"drbd::drbd_node::${this_host}::config::resource::${this_resource}::volume::${volume}::backing_lv"       => $anvil->data->{drbd}{drbd_node}{$this_host}{config}{resource}{$this_resource}{volume}{$volume}{backing_lv},
				}});
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


=head2 get_next_resource

This returns the next free DRBD minor number and the next free TCP port. The minor number and TCP port returned are ones found to be free on both/all machines in Anvil! system. As such, the returned values may skip values free on any given system.

If a resource name is given, then the caller can either return an error if the name matches (useful for name conflict checks) or return the first (lowest) minor number and TCP used by the resource. 

 my ($free_minor, $free_port) = $anvil->DRBD->get_next_resource({anvil_uuid => "a5ae5242-e9d3-46c9-9ce8-306855aa56db"})
 
If there is a problem, two empty strings will be returned. 

B<< Note >>: Deleted resources, volumes and peers are ignored! As such, a minor or TCP port that used to be used by deleted resource can be returned. 

Parameters;

=head3 anvil_uuid (optional, default 'Cluster->get_anvil_uuid')

This is the Anvil! in which we're looking for the next free resources. It's required, but generally it doesn't need to be specified as we can find it via C<< Cluster->get_anvil_uuid() >>.

=head3 dr_tcp_ports (optional, default '0')

If set, the 'free_port' returned will be a comma-separated pair of TCP ports. This is meant to help find two TCP ports needed to connect a resource from both nodes to a DR host.

=head3 long_throw_ports (optional, default '0')

If set, the 'free_port' returned will be a comma-separated list of seven TCP ports needed for a full B<< Long Throw >> configuration.

=head3 minor_only (optional, default '0')

When set to C<< 1 >>, only a new minor number is returned. The tcp number will be an empty string.

=head3 resource_name (optional)

If this is set, and the resource is found to already exist, the first DRBD minor number and first used TCP port are returned. Alternatively, if C<< force_unique >> is set to C<< 1 >>, and the resource is found to exist, empty strings are returned.

=head3 force_unique (optional, default '0')

This can be used to cause this method to return an error if C<< resource_name >> is also set and the resource is found to already exist.

=cut
sub get_next_resource
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->get_next_resource()" }});
	
	### TODO: Cache results in the states or variables table and don't reuse ports given out for five 
	###       minutes. If the user batches a series of calls, TCP ports / minor numbers could be offered 
	###       multiple times.
	my $anvil_uuid       = defined $parameter->{anvil_uuid}       ? $parameter->{anvil_uuid}       : "";
	my $dr_tcp_ports     = defined $parameter->{dr_tcp_ports}     ? $parameter->{dr_tcp_ports}     : "";
	my $long_throw_ports = defined $parameter->{long_throw_ports} ? $parameter->{long_throw_ports} : "";
	my $minor_only       = defined $parameter->{minor_only}       ? $parameter->{minor_only}       : "";
	my $resource_name    = defined $parameter->{resource_name}    ? $parameter->{resource_name}    : "";
	my $force_unique     = defined $parameter->{force_unique}     ? $parameter->{force_unique}     : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid       => $anvil_uuid, 
		dr_tcp_ports     => $dr_tcp_ports, 
		long_throw_ports => $long_throw_ports, 
		minor_only       => $minor_only, 
		resource_name    => $resource_name, 
		force_unique     => $force_unique, 
	}});
	
	# If we weren't passed an anvil_uuid, see if we can find one locally
	if (not $anvil_uuid)
	{
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
	}
	
	if (not $anvil_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->get_next_resource()", parameter => "anvil_uuid" }});
		return("", "");
	}
	
	$anvil->Database->get_anvils({debug => $debug});
	if (not exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0162", variables => { anvil_uuid => $anvil_uuid }});
		return("", "");
	}
	
	# Read in the resource information from both nodes. They _should_ be identical, but that's not 100% 
	# certain.
	my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
	my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node1_host_uuid => $node1_host_uuid, 
		node2_host_uuid => $node2_host_uuid, 
	}});
	
my $query = "
SELECT 
    a.host_uuid, 
    a.host_name, 
    b.scan_drbd_resource_name, 
    c.scan_drbd_volume_number, 
    c.scan_drbd_volume_device_path, 
    c.scan_drbd_volume_device_minor, 
    d.scan_drbd_peer_host_name, 
    d.scan_drbd_peer_ip_address, 
    d.scan_drbd_peer_protocol, 
    d.scan_drbd_peer_fencing, 
    d.scan_drbd_peer_tcp_port 
FROM 
    hosts a, 
    scan_drbd_resources b, 
    scan_drbd_volumes c, 
    scan_drbd_peers d 
WHERE 
    a.host_uuid                       =  b.scan_drbd_resource_host_uuid 
AND 
    b.scan_drbd_resource_uuid         =  c.scan_drbd_volume_scan_drbd_resource_uuid 
AND 
    c.scan_drbd_volume_uuid           =  d.scan_drbd_peer_scan_drbd_volume_uuid 
AND 
    b.scan_drbd_resource_xml          != 'DELETED' 
AND 
    c.scan_drbd_volume_device_path    != 'DELETED' 
AND 
    d.scan_drbd_peer_connection_state != 'DELETED' 
AND 
    (
        scan_drbd_resource_host_uuid = ".$anvil->Database->quote($node1_host_uuid)." 
    OR 
        scan_drbd_resource_host_uuid = ".$anvil->Database->quote($node2_host_uuid)." 
    )
ORDER BY 
    b.scan_drbd_resource_name ASC, 
    c.scan_drbd_volume_device_minor ASC, 
    d.scan_drbd_peer_tcp_port ASC
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
		# I don't really need most of this, but it helps with debugging
		my $host_uuid                     = $row->[0];
		my $host_name                     = $row->[1];
		my $scan_drbd_resource_name       = $row->[2];
		my $scan_drbd_volume_number       = $row->[3];
		my $scan_drbd_volume_device_path  = $row->[4];
		my $scan_drbd_volume_device_minor = $row->[5];
		my $scan_drbd_peer_host_name      = $row->[6];
		my $scan_drbd_peer_ip_address     = $row->[7];
		my $scan_drbd_peer_protocol       = $row->[8];
		my $scan_drbd_peer_fencing        = $row->[9];
		my $scan_drbd_peer_tcp_port       = $row->[10];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:host_uuid'                     => $host_uuid, 
			's2:host_name'                     => $host_name, 
			's3:scan_drbd_resource_name'       => $scan_drbd_resource_name, 
			's4:scan_drbd_volume_number'       => $scan_drbd_volume_number, 
			's5:scan_drbd_volume_device_path'  => $scan_drbd_volume_device_path, 
			's6:scan_drbd_volume_device_minor' => $scan_drbd_volume_device_minor, 
			's7:scan_drbd_peer_host_name'      => $scan_drbd_peer_host_name, 
			's8:scan_drbd_peer_ip_address'     => $scan_drbd_peer_ip_address, 
			's9:scan_drbd_peer_protocol'       => $scan_drbd_peer_protocol, 
			's10:scan_drbd_peer_fencing'       => $scan_drbd_peer_fencing, 
			's11:scan_drbd_peer_tcp_port'      => $scan_drbd_peer_tcp_port, 
		}});
		
		$anvil->data->{drbd}{used_resources}{minor}{$scan_drbd_volume_device_minor}{used} = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"drbd::used_resources::minor::${scan_drbd_volume_device_minor}::used" => $anvil->data->{drbd}{used_resources}{minor}{$scan_drbd_volume_device_minor}{used}, 
		}});
		
		# DRBD proxy uses three ports per connection. This handles that, and still works fine for 
		# single TCP ports.
		foreach my $tcp_port (split/,/, $scan_drbd_peer_tcp_port)
		{
			$anvil->data->{drbd}{used_resources}{tcp_port}{$tcp_port}{used} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"drbd::used_resources::tcp_port::${tcp_port}::used" => $anvil->data->{drbd}{used_resources}{tcp_port}{$tcp_port}{used}, 
			}});
		}
		
		if (($resource_name) && ($scan_drbd_resource_name eq $resource_name))
		{
			# Found the resource the user was asking for.
			if ($force_unique)
			{
				# Error out.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => 'err', key => "error_0237", variables => { resource_name => $resource_name }});
				return("", "");
			}
			else
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0592", variables => { resource_name => $resource_name }});
				return($scan_drbd_volume_device_minor, $scan_drbd_peer_tcp_port);
			}
		}
	}	
	
	# If I'm here, We'll look for the next minor number for this host.
	my $looking    = 1;
	my $free_minor = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		looking    => $looking, 
		free_minor => $free_minor,
	}});
	while($looking)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { free_minor => $free_minor }});
		if (exists $anvil->data->{drbd}{used_resources}{minor}{$free_minor})
		{
			$free_minor++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { free_minor => $free_minor }});
		}
		else
		{
			# See if this minor is held by someone.
			my $variable_name                           = "drbd::hold::minor::".$free_minor."::until";
			my ($variable_value, $variable_uuid, undef) = $anvil->Database->read_variable({
				debug         => $debug,
				variable_name => $variable_name,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:variable_name'  => $variable_name, 
				's2:variable_value' => $variable_value,
				's3:variable_uuid'  => $variable_uuid, 
			}});
			
			# If the value set, a digit, and older than the current time?
			if (($variable_value) && (($variable_value !~ /^\d+$/) or (time > $variable_value)))
			{
				# Bad value, clear it.
				$variable_uuid = $anvil->Database->insert_or_update_variables({
					debug             => $debug,
					variable_uuid     => $variable_uuid,
					variable_value    => "0",
					update_value_only => "", 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid  => $variable_uuid }});
				
				# Clear the variable UUID for the next step.
				$variable_uuid  = "";
				$variable_value = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					variable_uuid  => $variable_uuid,
					variable_value => $variable_value
				}});
			}
			
			if ($variable_uuid) 
			{
				# This is being held, move on.
				$free_minor++;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { free_minor => $free_minor }});
				next;
			}
			
			# To prevent race conditions, put a one minute hold on the minor number.
			$variable_uuid = $anvil->Database->insert_or_update_variables({
				debug                 => $debug,
				variable_name         => $variable_name,
				variable_value        => time+60,
				variable_default      => "0", 
				variable_description  => "striker_0301", 
				variable_section      => "hold", 
				variable_source_uuid  => "NULL", 
				variable_source_table => "", 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { variable_uuid => $variable_uuid }});
			
			$looking = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { looking => $looking }});
		}
	}
	
	# If they're only asking for a minor number, like adding a disk, we're done.
	if ($minor_only)
	{
		# We're done.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { free_minor => $free_minor }});
		return($free_minor, "");
	}
	
	# I need to find the next free TCP port. 
	   $looking     = 1;
	my $check_port  = 7788;
	my $free_ports  = "";
	my $tcp_pair    = "";
	my $proxy_list  = "";
	my $port_count  = 0;
	my $neeed_ports = 1;
	if ($long_throw_ports)
	{
		$neeed_ports = 7;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { neeed_ports => $neeed_ports }});
	}
	elsif ($dr_tcp_ports)
	{
		$neeed_ports = 3;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { neeed_ports => $neeed_ports }});
	}
	while($looking)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_port => $check_port }});
		if ((exists $anvil->data->{drbd}{used_resources}{tcp_port}{$check_port}) && 
		    ($anvil->data->{drbd}{used_resources}{tcp_port}{$check_port}{used}))
		{
			$check_port++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_port => $check_port }});
			next;
		}
		else
		{
			# See if this minor is held by someone.
			my $variable_name                           = "drbd::hold::tcp_port::".$check_port."::until";
			my ($variable_value, $variable_uuid, undef) = $anvil->Database->read_variable({
				debug         => $debug,
				variable_name => $variable_name,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:variable_name'  => $variable_name,
				's2:variable_value' => $variable_value,
				's3:variable_uuid'  => $variable_uuid, 
			}});
			
			if (($variable_value) && (($variable_value !~ /^\d+$/) or (time > $variable_value)))
			{
				# Bad value, clear it.
				$variable_uuid = $anvil->Database->insert_or_update_variables({
					debug             => $debug,
					variable_uuid     => $variable_uuid,
					variable_value    => "0",
					update_value_only => "", 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid  => $variable_uuid }});
				
				# Clear the variable UUID for the next step.
				$variable_uuid  = "";
				$variable_value = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					variable_uuid  => $variable_uuid,
					variable_value => $variable_value
				}});
			}
			
			if ($variable_uuid)
			{
				$check_port++;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_port => $check_port }});
				next;
			}
			
			# To prevent a race condition, put a one minute hold on this port number.
			$variable_uuid = $anvil->Database->insert_or_update_variables({
				debug                 => $debug,
				variable_name         => $variable_name,
				variable_value        => time+60,
				variable_default      => "0", 
				variable_description  => "striker_0301", 
				variable_section      => "hold", 
				variable_source_uuid  => "NULL", 
				variable_source_table => "", 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { variable_uuid => $variable_uuid }});
			
			# This is a free port.
			$free_ports .= $check_port.",";
			$port_count++;
			$check_port++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				free_ports => $free_ports, 
				port_count => $port_count,
			}});
			
			if ($port_count >= $neeed_ports)
			{
				$looking    =  0;
				$free_ports =~ s/,$//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					looking    => $looking,
					free_ports => $free_ports, 
				}});
			}
		}
	}
	
	# Mark these ports as assigned.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		free_minor => $free_minor,
		free_ports => $free_ports, 
	}});
	return($free_minor, $free_ports);
}


=head2 get_status

This parses the DRBD status on the local or remote system. The data collected is stored in the following hashes;

 drbd::status::<host_name>::resource::<resource_name>::{ap-in-flight,congested,connection-state,peer-node-id,rs-in-flight}
 drbd::status::<host_name>::resource::<resource_name>::connection::<peer_host_name>::volume::<volume>::{has-online-verify-details,has-sync-details,out-of-sync,peer-client,peer-disk-state,pending,percent-in-sync,received,replication-state,resync-suspended,sent,unacked}
 
If the volume is resyncing, these additional values will be set:
 
 drbd::status::<host_name>::resource::<resource_name>::connection::<peer_host_name>::volume::<volume>::{db-dt MiB-s,db0-dt0 MiB-s,db1-dt1 MiB-s,estimated-seconds-to-finish,percent-resync-done,rs-db0-sectors,rs-db1-sectors,rs-dt-start-ms,rs-dt0-ms,rs-dt1-ms,rs-failed,rs-paused-ms,rs-same-csum,rs-total,want}
 drbd::status::<host_name>::resource::<resource>::devices::volume::<volume>::{al-writes,bm-writes,client,disk-state,lower-pending,minor,quorum,read,size,upper-pending,written}

If any data for the host was stored in a previous call, it will be deleted before the new data is collected and stored.

Parameters;

=head3 host (optional)

By default, the hash key C<< host_name >> listed above is either the local system's short host name, or the C<< target >>. If you'd like to use a specific host name in the hash key, you can use this parameter to set it.

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->get_status()" }});
	
	my $host        = defined $parameter->{host}        ? $parameter->{host}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host        => $host, 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# If we weren't passed a host, use this machine's short host name.
	my $is_local = $anvil->Network->is_local({host => $target});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
	if (not $host)
	{
		# Host not set, set one.
		if ($is_local)
		{
			$host = $anvil->Get->short_host_name();
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
		}
		else
		{
			# Remote, using the target as the host.
			$host = $target;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
		}
	}
	
	# Is this a local call or a remote call?
	my $shell_call = $anvil->data->{path}{exe}{drbdsetup}." status --json";
	my $output     = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	if ($is_local)
	{
		# Local.
		($output, $anvil->data->{drbd}{status}{$host}{return_code}) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output                               => $output,
			"drbd::status::${host}::return_code" => $anvil->data->{drbd}{status}{$host}{return_code},
		}});
	}
	else
	{
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
			"drbd::status::${host}::return_code" => $anvil->data->{drbd}{status}{$host}{return_code},
		}});
	}
	
	# Clear the hash where we'll store the data.
	if (exists $anvil->data->{drbd}{status}{$host})
	{
		delete $anvil->data->{drbd}{status}{$host};
	}
	
	if ($output =~ /modprobe: FATAL: Module drbd not found/i)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
		if ($is_local)
		{
			# Try rebuilding the module.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "message_0328"});
			
			my $problem = $anvil->DRBD->_initialize_kmod({debug => 2});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			
			if ($problem)
			{
				# Try again.
				($output, $anvil->data->{drbd}{status}{$host}{return_code}) = $anvil->System->call({shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output                               => $output,
					"drbd::status::${host}::return_code" => $anvil->data->{drbd}{status}{$host}{return_code},
				}});
				if ($output =~ /modprobe: FATAL: Module drbd not found/i)
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "error_0415", variables => { 
						output      => $output,
						return_code => $anvil->data->{drbd}{status}{$host}{return_code},
					}});
					return(1);
				}
			}
		}
	}
	
	# Parse the output.
	local $@;
	my $json        = JSON->new->allow_nonref;
	my $drbd_status = eval { $json->decode($output); };
	if ($@)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0416", variables => { 
			json  => $output,
			error => $@,
		}});
		return(1);
	}
	
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
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-role'}        = $hash_ref->{connections}->[$i]->{'peer-role'};
			$anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'rs-in-flight'}     = $hash_ref->{connections}->[$i]->{'rs-in-flight'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::ap-in-flight"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'ap-in-flight'},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::congested"        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{congested},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::connection-state" => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'connection-state'},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::peer-node-id"     => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-node-id'},
				"drbd::status::${host}::resource::${resource}::connection::${peer_name}::peer-role"        => $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'peer-role'},
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
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

This takes a task, C<< up >>, C<< down >>, C<< primary >>, C<< secondary >>, or C<< adjust >> and a resource name and acts on the request.

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

This is the action to take. Valid tasks are: C<< up >>, C<< down >>, C<< primary >>, C<< secondary >>, and C<< adjust >>.

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->manage_resource()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $resource    = defined $parameter->{resource}    ? $parameter->{resource}    : "";
	my $task        = defined $parameter->{task}        ? $parameter->{task}        : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $return_code = 255; 
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
	
	# If the task is 'adjust', do just that.
	if ($task eq "adjust")
	{
		# Reset to the values in the config and return.
		my $shell_call = $anvil->data->{path}{exe}{drbdadm}." adjust ".$resource;
		my $output     = "";
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
		}
		else
		{
			# Remote call.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
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
		
		return($return_code);
	}
	
	### TODO: When taking down a resource, check to see if any machine is SyncTarget and take it/them 
	###       down first. See anvil-rename-server -> verify_server_is_off() for the logic.
	### TODO: Sanity check the resource name and task requested.
	### NOTE: If a live-migration fails, one of the nodes could have their allow-two-primaries left up.
	###       This ensures that they're set to 'no' before connecting.
	if ($task eq "up")
	{
		# If our connection state is 'StandAlone', try to connect.
		my $host = $anvil->Get->short_host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { host => $host }});
		if (not exists $anvil->data->{drbd}{config}{$host})
		{
			$anvil->DRBD->get_status({debug => $debug});
		}
		my $peer_name        = $anvil->data->{drbd}{config}{$host}{peer}                                                            // "";
		my $connection_state = $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'connection-state'} // "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			peer_name        => $peer_name,
			resource         => $resource,
			connection_state => $connection_state, 
		}});
		if (($connection_state) && (lc($connection_state) eq "standalone"))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "log_0746", variables => { resource => $resource }});
			
			my $shell_call = $anvil->data->{path}{exe}{drbdadm}." connect ".$resource;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
			sleep 1;
			
			# Loop to see if it connects.
			my $waiting    = 1;
			my $wait_until = time + 10;
			while ($waiting)
			{
				$anvil->DRBD->get_status({debug => $debug});
				my $connection_state = $anvil->data->{drbd}{status}{$host}{resource}{$resource}{connection}{$peer_name}{'connection-state'};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { connection_state => $connection_state }});
				if (lc($connection_state eq "connecting"))
				{
					if (time > $wait_until)
					{
						# Stop waiting.
						$waiting = 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { waiting => $waiting }});
					}
					else
					{
						# Keep waiting.
						sleep 1;
					}
				}
				else
				{
					# Done!
					$waiting = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { waiting => $waiting }});
				}
			}
		}
		
		# This generally brings up the resource
		if ($peer_name)
		{
			# This isn't fatal when bringing up the resource
			my ($return_code) = $anvil->DRBD->allow_two_primaries({
				debug    => 2, 
				resource => $resource, 
				set_to   => "no", 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { return_code => $return_code }});
		}
		
		# Now call an adjust to make sure all other config details are loaded. It also up's the 
		# resource.
		my $shell_call = $anvil->data->{path}{exe}{drbdadm}." adjust ".$resource;
		my $output     = "";
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
		}
		else
		{
			# Remote call.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
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
		
		# Sleep for a moment to make sure adjust has taken hold.
		sleep 1;
	}
	
	# If we 'adjust'ed above, this will likely complain that the backing disk already exists, and that's 
	# fine.
	my $shell_call = $anvil->data->{path}{exe}{drbdadm}." ".$task." ".$resource;
	my $output     = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	else
	{
		# Remote call.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
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
	
	# If the task is down, make sure it's actually down. For some reason, rarely, we can get a 0 rc with
	# it still up.
	if ($task eq "down")
	{
		my $test_directory = "/dev/drbd/by-res/".$resource;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_directory => $test_directory }});
		if (-e $test_directory)
		{
			# Wait until it's gone.
			my $waiting    = 1;
			my $wait_until = time + 30;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wait_until => $wait_until }});
			while ($waiting)
			{
				sleep 2;
				if (not -e $test_directory)
				{
					# It's gone.
					$waiting = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { waiting => $waiting }});
				}
				elsif (time > $wait_until)
				{
					# Give up.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "resource", variables => { resource => $resource }});
					return(9999);
				}
			}
		}
	}
	
	return($return_code);
}


=head2 parse_resource

This takes the XML from a specific DRBD resource and parses it.

Parameters;

=head3 xml (required)

This is the XML to parse, generally as stored in the C<< scan_drbd_resources >> -> C<< scan_drbd_resource_xml >>.

=cut
sub parse_resource
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->parse_resource()" }});
	
	my $xml = defined $parameter->{xml} ? $parameter->{xml} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		xml => $xml, 
	}});
	
	if (not $xml)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->parse_resource()", parameter => "xml" }});
		return("!!error!!");
	}
	
	local $@;
	my $dom = eval { XML::LibXML->load_xml(string => $xml); };
	if ($@)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0253", variables => { 
			xml   => $xml,
			error => $@,
		}});
		return(1);
	}
	else
	{
		if (not exists $anvil->data->{lvm}{host_name})
		{
			$anvil->Database->get_lvm_data({debug => $debug});
		}
		
		# Successful parse!
		foreach my $name ($dom->findnodes('/resource'))
		{
			my $resource = $name->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
			
			foreach my $host ($name->findnodes('./host'))
			{
				my $this_host_name = $host->{name};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_name => $this_host_name }});
				
				# Record the details under the hosts
				foreach my $volume_vnr ($host->findnodes('./volume'))
				{
					my $volume    = $volume_vnr->{vnr};
					my $meta_disk = $volume_vnr->findvalue('./meta-disk');
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:volume'    => $volume,
						's2:meta_disk' => $meta_disk, 
					}});
					
					my $host_uuid       = $anvil->Get->host_uuid_from_name({host_name => $this_host_name});
					my $short_host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name};
					my $backing_disk    = $volume_vnr->findvalue('./disk');
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						host_uuid       => $host_uuid,
						short_host_name => $short_host_name, 
						backing_disk    => $backing_disk, 
					}});
					
					$anvil->data->{new}{resource}{$resource}{host_name}{$this_host_name}{host_uuid}                             = $host_uuid;
					$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{device_path}        = $volume_vnr->findvalue('./device');
					$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{backing_disk}       = $backing_disk;
					$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{device_minor}       = $volume_vnr->findvalue('./device/@minor');
					$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{meta_disk}          = $meta_disk;
					$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{size}               = 0;
					$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{storage_group_uuid} = "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:new::resource::${resource}::host_name::${this_host_name}::host_uuid"                  => $anvil->data->{new}{resource}{$resource}{host_name}{$this_host_name}{host_uuid},
						"s2:new::resource::${resource}::host_uuid::${host_uuid}::volume_number::${volume}::device_path"        => $anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{device_path},
						"s3:new::resource::${resource}::host_uuid::${host_uuid}::volume_number::${volume}::backing_disk"       => $anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{backing_disk},
						"s4:new::resource::${resource}::host_uuid::${host_uuid}::volume_number::${volume}::device_minor"       => $anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{device_minor},
						"s5:new::resource::${resource}::host_uuid::${host_uuid}::volume_number::${volume}::meta_disk"          => $anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{meta_disk},
						"s6:new::resource::${resource}::host_uuid::${host_uuid}::volume_number::${volume}::storage_group_uuid" => $anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{storage_group_uuid},
					}});
					
					# What Storage Group is this in?
					foreach my $this_scan_lvm_lv_name (sort {$a cmp $b} keys %{$anvil->data->{lvm}{host_name}{$short_host_name}{lv}})
					{
						my $this_scan_lvm_lv_path  = $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$this_scan_lvm_lv_name}{scan_lvm_lv_path}; 
						my $this_scan_lvm_lv_on_vg = $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$this_scan_lvm_lv_name}{scan_lvm_lv_on_vg}; 
						my $this_scan_lvm_lv_uuid  = $anvil->data->{lvm}{host_name}{$short_host_name}{lv}{$this_scan_lvm_lv_name}{scan_lvm_lv_uuid};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
							's1:this_scan_lvm_lv_name'  => $this_scan_lvm_lv_name, 
							's2:this_scan_lvm_lv_path'  => $this_scan_lvm_lv_path,
							's3:this_scan_lvm_lv_on_vg' => $this_scan_lvm_lv_on_vg, 
							's4:this_scan_lvm_lv_uuid'  => $this_scan_lvm_lv_uuid, 
						}});
						if ($anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{backing_disk} eq $this_scan_lvm_lv_path)
						{
							# While we're here, make it easy to go from LV -> DRBD resource and volume.
							$anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$backing_disk}{drbd}{resource} = $resource;
							$anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$backing_disk}{drbd}{volume}   = $volume;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
								"s1:lvm::host_name::${short_host_name}::lv_path::${backing_disk}::drbd::resource" => $anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$backing_disk}{drbd}{resource}, 
								"s2:lvm::host_name::${short_host_name}::lv_path::${backing_disk}::drbd::volume"   => $anvil->data->{lvm}{host_name}{$short_host_name}{lv_path}{$backing_disk}{drbd}{volume}, 
							}});
							
							# What's the VG's UUID? 
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
								's1:short_host_name'        => $short_host_name, 
								's2:this_scan_lvm_lv_on_vg' => $this_scan_lvm_lv_on_vg, 
							}});
							if (exists $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$this_scan_lvm_lv_on_vg})
							{
								my $scan_lvm_vg_internal_uuid = $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$this_scan_lvm_lv_on_vg}{scan_lvm_vg_internal_uuid};
								my $storage_group_uuid        = $anvil->data->{lvm}{host_name}{$short_host_name}{vg}{$this_scan_lvm_lv_on_vg}{storage_group_uuid};
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
									's1:scan_lvm_vg_internal_uuid' => $scan_lvm_vg_internal_uuid, 
									's2:storage_group_uuid'        => $storage_group_uuid, 
								}});
								
								if ($storage_group_uuid)
								{
									$anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{storage_group_uuid} = $storage_group_uuid;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
										"new::resource::${resource}::host_uuid::${host_uuid}::volume_number::${volume}::storage_group_uuid" => $anvil->data->{new}{resource}{$resource}{host_uuid}{$host_uuid}{volume_number}{$volume}{storage_group_uuid},
									}});
								}
							}
						}
					}
				}
			}
			foreach my $connection ($name->findnodes('./connection'))
			{
				my $host1_name       = "";
				my $host1_ip_address = "";
				my $host1_tcp_port   = "";
				my $host2_name       = "";
				my $host2_ip_address = "";
				my $host2_tcp_port   = "";
				my $peer             = "";
				foreach my $host ($connection->findnodes('./host'))
				{
					my $this_host_name = $host->{name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_name => $this_host_name }});
					if (not $host1_name)
					{
						$host1_name       = $this_host_name;
						$host1_ip_address = $host->findvalue('./address');
						$host1_tcp_port   = $host->findvalue('./address/@port');
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							host1_name       => $host1_name,
							host1_ip_address => $host1_ip_address, 
							host1_tcp_port   => $host1_tcp_port, 
						}});
					}
					else
					{
						$host2_name       = $this_host_name;
						$host2_ip_address = $host->findvalue('./address');
						$host2_tcp_port   = $host->findvalue('./address/@port');
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							host2_name       => $host2_name,
							host2_ip_address => $host2_ip_address, 
							host2_tcp_port   => $host2_tcp_port, 
						}});
						
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address} = $host1_ip_address;
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port}   = $host1_tcp_port;
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address} = $host2_ip_address;
						$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port}   = $host2_tcp_port;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host1_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_ip_address},
							"s2:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host1_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host1_tcp_port},
							"s3:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_ip_address},
							"s4:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_tcp_port},
						}});
						
						foreach my $proxy ($host->findnodes('./proxy'))
						{
							my $host_name = $proxy->{hostname};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
							
							# This should always be the target, but lets be safe/careful
							next if $host_name ne $host2_name;
							
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_ip_address}  = $proxy->findvalue('./inside');
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_tcp_port}    = $proxy->findvalue('./inside/@port');
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_ip_address} = $proxy->findvalue('./outside');
							$anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_tcp_port}   = $proxy->findvalue('./outside/@port');
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"s1:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_inside_ip_address"  => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_ip_address},
								"s2:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_inside_tcp_port"    => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_inside_tcp_port},
								"s3:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_outside_ip_address" => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_ip_address},
								"s4:new::resource::${resource}::host1_to_host2::${host1_name}::${host2_name}::host2_outside_tcp_port"   => $anvil->data->{new}{resource}{$resource}{host1_to_host2}{$host1_name}{$host2_name}{host2_outside_tcp_port},
							}});
							
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{ip_address}  = $proxy->findvalue('./inside');
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{tcp_port}    = $proxy->findvalue('./inside/@port');
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{ip_address} = $proxy->findvalue('./outside');
							$anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{tcp_port}   = $proxy->findvalue('./outside/@port');
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"new::resource::${resource}::proxy::${host_name}::inside::ip_address"  => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{ip_address},
								"new::resource::${resource}::proxy::${host_name}::inside::tcp_port"    => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{inside}{tcp_port},
								"new::resource::${resource}::proxy::${host_name}::outside::ip_address" => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{ip_address},
								"new::resource::${resource}::proxy::${host_name}::outside::tcp_port"   => $anvil->data->{new}{resource}{$resource}{proxy}{$host_name}{outside}{tcp_port},
							}});
						}
					}
				}
			}
		}
	}
	
	return(0);
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->reload_defaults()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $resource    = defined $parameter->{resource}    ? $parameter->{resource}    : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
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
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->reload_defaults()", parameter => "resource" }});
		return($return_code);
	}
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 0, level => $debug, key => "log_0355"});
	my $shell_call  = $anvil->data->{path}{exe}{drbdadm}." adjust ".$resource;
	my $output      = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	else
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


=head2 remove_backing_lv

This method does the work wiping the data from, and then deleting the logical volume backing a DRBD resource. The return value from the C<< lvremove >> call is returned. If the C<< wipefs >> call returns non-zero, that return code is returned. If something else goes wrong, C<< 255 >> is returned.

B<< NOTE >>: This does no sanity checks! This method assumes all checks were done before this method was called!

Parameters;

=head3 backing_disk (required)

This is the full logical volume path that is to be deleted. 

=cut
sub remove_backing_lv
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->remove_backing_lv()" }});
	
	my $backing_disk = defined $parameter->{backing_disk} ? $parameter->{backing_disk} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		backing_disk => $backing_disk,
	}});
	
	if (not $backing_disk)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->remove_backing_lv()", parameter => "backing_disk" }});
		return(255);
	}

	my $shell_call = $anvil->data->{path}{exe}{wipefs}." --all ".$backing_disk;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	if ($return_code)
	{
		# Should have been '0'
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0230", variables => { 
			shell_call  => $shell_call, 
			return_code => $return_code,
			output      => $output, 
		}});
		return($return_code);
	}
	
	# Now delete the logical volume
	$shell_call = $anvil->data->{path}{exe}{lvremove}." --force ".$backing_disk;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	# Call scan-lvm to update our view.
	$anvil->ScanCore->call_scan_agents({debug => $debug, agent => "scan-lvm"});

	return($return_code);
}

=head2 resource_uuid

This method reads the C<< scan_drbd_resource_uuid >> from a DRBD resource file. If no UUID is found (and C<< new_resource_uuid >> isn't set), an empty string is returned. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 new_resource_uuid (optional)

If this is set to a UUID, and no existing UUID is found, this UUID will be added to the resource config file.

=head3 replace (optional, default 0)

If this is set along with C<< new_resource_uuid >> is also set, the UUID will replace an existing UUID if one is found. Otherwise, it's added like no UUID was found.

=head3 resource (required)

This is the name of resource whose UUID we're looking for.

=head3 resource_file (required)

This is the full path to the resource configuration file that the UUID will be read from, if possible.

=cut
### NOTE: This is not used at this time. 
sub resource_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->resource_uuid()" }});
	
	my $new_resource_uuid = defined $parameter->{new_resource_uuid} ? $parameter->{new_resource_uuid} : 0;
	my $replace           = defined $parameter->{replace}           ? $parameter->{replace}           : "";
	my $resource          = defined $parameter->{resource}          ? $parameter->{resource}          : "";
	my $resource_file     = defined $parameter->{resource_file}     ? $parameter->{resource_file}     : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		new_resource_uuid => $new_resource_uuid, 
		replace           => $replace, 
		resource          => $resource, 
		resource_file     => $resource_file,
	}});
	
	if (not $resource)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->resource_uuid()", parameter => "resource" }});
		return('!!error!!');
	}
	if (not $resource_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "DRBD->resource_uuid()", parameter => "resource_file" }});
		return('!!error!!');
	}
	
	my $scan_drbd_resource_uuid = "";
	my $in_resource             = 0;
	my $resource_config         = $anvil->Storage->read_file({file => $resource_file});
	if ($resource_config eq "!!error!!")
	{
		# Something went wrong.
		return('!!error!!');
	}
	foreach my $line (split/\n/, $resource_config)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^resource (.*?) /)
		{
			my $this_resource = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_resource => $this_resource }});
			if ($this_resource eq $resource)
			{
				$in_resource = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_resource => $in_resource }});
			}
			else
			{
				$in_resource = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_resource => $in_resource }});
			}
		}
		
		if (($in_resource) && ($line =~ /# scan_drbd_resource_uuid = (.*)$/))
		{
			$scan_drbd_resource_uuid =  $1;
			$scan_drbd_resource_uuid =~ s/^\s+//;
			$scan_drbd_resource_uuid =~ s/\s.*$//;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { scan_drbd_resource_uuid => $scan_drbd_resource_uuid }});
			
			if (not $anvil->Validate->uuid({uuid => $scan_drbd_resource_uuid}))
			{
				# Found, but not valid.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0166", variables => { 
					resource => $resource, 
					file     => $resource_file, 
					uuid     => $scan_drbd_resource_uuid,
				}});
				return('!!error!!');
			}
		}
	}
	
	my $injected            = 0;
	my $new_resource_config = "";
	if ($replace)
	{
		if ((not $new_resource_uuid) or (not $anvil->Validate->uuid({uuid => $new_resource_uuid})))
		{
			# We can't do this.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0167", variables => { 
				resource => $resource, 
				file     => $resource_file, 
				uuid     => $scan_drbd_resource_uuid,
			}});
			return('!!error!!');
		}
		
		my $in_resource = 0;
		foreach my $line (split/\n/, $resource_config)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /^resource $resource /)
			{
				$in_resource = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_resource => $in_resource }});
			}
			elsif ($line =~ /^resource /)
			{
				$in_resource = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_resource => $in_resource }});
			}
			if ($in_resource)
			{
				if ($line =~ /# scan_drbd_resource_uuid = (.*)$/)
				{
					my $old_uuid = $1;
					if ($old_uuid ne $new_resource_uuid)
					{
						$line                    =~ s/# scan_drbd_resource_uuid = .*$/# scan_drbd_resource_uuid = $new_resource_uuid/;
						$injected                =  1;
						$scan_drbd_resource_uuid =  $new_resource_uuid;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							line                    => $line, 
							injected                => $injected,
							scan_drbd_resource_uuid => $scan_drbd_resource_uuid, 
						}});
					}
				}
			}
			$new_resource_config .= $line."\n";
		}
	}
	
	if ((not $scan_drbd_resource_uuid) && ($anvil->Validate->uuid({uuid => $new_resource_uuid})))
	{
		# Didn't find the resource UUID and we've been asked to add it.
		foreach my $line (split/\n/, $resource_config)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /^resource $resource /)
			{
				$injected                =  1;
				$scan_drbd_resource_uuid =  $new_resource_uuid;
				$new_resource_config     .= $line."\n";
				$new_resource_config     .= $anvil->Words->string({key => "message_0189", variables => { uuid => $scan_drbd_resource_uuid }});
				next;
			}
			$new_resource_config .= $line."\n";
		}
	}
	
	if ($injected)
	{
		my $error = $anvil->Storage->write_file({
			debug     => $debug,
			body      => $new_resource_config,
			file      => $resource_file,
			user      => "root",
			group     => "root", 
			mode      => "0644",
			overwrite => 1,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
	}
	
	return($scan_drbd_resource_uuid);
}


=head2 update_global_common

This configures C<< global_common.conf >> on the local host. Returns C<< !!error!! >> if there is a problem, an empty string if no update was needed and a unified C<< diff >> of the changes made, if any.

Parameters;

=head3 usage_count (optional, default '1')

By default, DRBD will call a LINBIT server and add itself to a counter, and then reports back what install number this machine is. This helps LINBIT understand how DRBD is used, and no personal identifiable information is passed to them. If you would like to disable this, set this to C<< 0 >>.

=head3 use_flushes (optional, default '1')

Normally, when a write is done, a flush is called to ensure the data has been written from cache to disk. This is usually desired as it is safe, but does impose a performance penalty.

When there is a hardware RAID controller with protected write cache, explicit flushes can safely be turned off, gaining performance.

If ScanCore can detect a hardware RAID controller, this method will disable disk flushes automatically. This parameter can be used to force flushes on (C<< 1 >>) or off (C<< 0 >>).

B<< Note >>: ScanCore can not yet do this.

=cut
sub update_global_common
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->update_global_common()" }});
	
	my $usage_count = defined $parameter->{usage_count} ? $parameter->{usage_count} : 1;
	my $use_flushes = defined $parameter->{use_flushes} ? $parameter->{use_flushes} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		usage_count => $usage_count, 
		use_flushes => $use_flushes,
	}});
	
	if (not -f $anvil->data->{path}{configs}{'global-common.conf'})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0139"});
		return('!!error!!');
	}
	
	# These values will be used to track where we are in processing the config file and what values are needed.
	my $update                   = 0;
	my $difference               = "";
	my $usage_count_seen         = 0;
	my $udev_always_use_vnr_seen = 0;
	my $fence_peer_seen          = 0;
	my $unfence_peer_seen        = 0;
	my $auto_promote_seen        = 0;
	my $disk_flushes_seen        = 0;
	my $md_flushes_seen          = 0;
	my $allow_two_primaries_seen = 0;
	my $after_sb_0pri_seen       = 0;
	my $after_sb_1pri_seen       = 0;
	my $after_sb_2pri_seen       = 0;
	my $timeout_seen             = 0;
	my $ping_timeout_seen        = 0;
	my $wfc_timeout_seen         = 0;
	
	my $in_global   = 0;
	my $in_common   = 0;
	my $in_handlers = 0;
	my $in_startup  = 0;
	my $in_options  = 0;
	my $in_disk     = 0;
	my $in_net      = 0;
	
	### NOTE: See 'man drbd.conf-9.0' for details on options.
	# These values will be used to track where we are in processing the config file and what values are needed.
	my $say_usage_count         = $usage_count ? "yes" : "no";
	my $say_fence_peer          = $anvil->data->{path}{exe}{fence_pacemaker};
	my $say_unfence_peer        = $anvil->data->{path}{exe}{unfence_pacemaker};
	my $say_auto_promote        = "yes";
	my $say_flushes             = $use_flushes ? "yes" : "no";
	my $say_allow_two_primaries = "no";
	my $say_after_sb_0pri       = "discard-zero-changes";
	my $say_after_sb_1pri       = "discard-secondary";
	my $say_after_sb_2pri       = "disconnect";
	my $say_timeout             = "100";
	my $say_ping_timeout        = "30";
	my $say_wfc_timeout         = 120;
	
	# Read in the existing config.
	my $new_global_common = "";
	my $old_global_common = $anvil->Storage->read_file({
		debug => $debug,
		file  => $anvil->data->{path}{configs}{'global-common.conf'},
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_global_common => $old_global_common }});
	foreach my $line (split/\n/, $old_global_common)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		my $comment = "";
		if ($line =~ /^#/)
		{
			$new_global_common .= $line."\n";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
			next;
		}
		
		if ($line =~ /(#.*)$/)
		{
			$comment =  $1;
			$line    =~ s/\Q$comment\E//;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				comment => $comment, 
				line    => $line,
			}});
		}
		
		if ($line =~ /\}/)
		{
			if ($in_global)
			{
				$in_global = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_global => $in_global }});
				
				if (not $usage_count_seen)
				{
					   $update   = 1;
					my $new_line = "\tusage-count ".$say_usage_count.";";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					$new_global_common .= $new_line."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
				}
				if (not $udev_always_use_vnr_seen)
				{
					   $update   = 1;
					my $new_line = "\tudev-always-use-vnr;";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					$new_global_common .= $new_line."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
				}
			}
			elsif ($in_common)
			{
				if ($in_handlers)
				{
					$in_handlers = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_handlers => $in_handlers }});
					
					if (not $fence_peer_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tfence-peer ".$say_fence_peer.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					if (not $unfence_peer_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tunfence-peer ".$say_unfence_peer.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
				}
				elsif ($in_startup)
				{
					$in_startup = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_startup => $in_startup }});
					
					if (not $wfc_timeout_seen)
					{
						   $update   = 1;
						my $new_line = "\t\twfc-timeout ".$say_wfc_timeout.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
				}
				elsif ($in_options)
				{
					$in_options = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_options => $in_options }});
					
					if (not $auto_promote_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tauto-promote ".$say_auto_promote.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
				}
				elsif ($in_disk)
				{
					$in_disk = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_disk => $in_disk }});
					
					if (not $disk_flushes_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tdisk-flushes ".$say_flushes.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					if (not $md_flushes_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tmd-flushes ".$say_flushes.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
				}
				elsif ($in_net)
				{
					$in_net = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_net => $in_net }});
					
					if (not $allow_two_primaries_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tallow-two-primaries ".$say_allow_two_primaries.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					
					if (not $after_sb_0pri_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tafter-sb-0pri ".$say_after_sb_0pri.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					
					if (not $after_sb_1pri_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tafter-sb-1pri ".$say_after_sb_1pri.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					
					if (not $after_sb_2pri_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tafter-sb-2pri ".$say_after_sb_2pri.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					
					if (not $timeout_seen)
					{
						   $update   = 1;
						my $new_line = "\t\ttimeout ".$say_timeout.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
					
					if (not $ping_timeout_seen)
					{
						   $update   = 1;
						my $new_line = "\t\tping-timeout ".$say_ping_timeout.";";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update'   => $update,
							's2:new_line' => $new_line, 
						}});
						$new_global_common .= $new_line."\n";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					}
				}
				else
				{
					$in_common = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_common => $in_common }});
				}
			}
		}
		if ($line =~ /global\s*\{/)
		{
			$in_global = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_global => $in_global }});
		}
		if ($in_common)
		{
			if ($line =~ /handlers\s*\{/)
			{
				$in_handlers = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_handlers => $in_handlers }});
			}
			if ($line =~ /startup\s*\{/)
			{
				$in_startup = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_startup => $in_startup }});
			}
			if ($line =~ /options\s*\{/)
			{
				$in_options = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_options => $in_options }});
			}
			if ($line =~ /disk\s*\{/)
			{
				$in_disk = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_disk => $in_disk }});
			}
			if ($line =~ /net\s*\{/)
			{
				$in_net = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_net => $in_net }});
			}
		}
		if ($line =~ /common\s*\{/)
		{
			$in_common = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_common => $in_common }});
		}
		if ($in_global)
		{
			if ($line =~ /(\s*)usage-count(\s+)(.*?)(;.*)$/)
			{
				my $left_space       = $1;
				my $middle_space     = $2;
				my $value            = $3;
				my $right_side       = $4;
				   $usage_count_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'       => $left_space,
					's2:middle_space'     => $middle_space, 
					's3:value'            => $value, 
					's4:right_side'       => $right_side,
					's5:usage_count_seen' => $usage_count_seen, 
				}});
				   
				if ($value ne $say_usage_count)
				{
					   $update   = 1;
					my $new_line = $left_space."usage-count".$middle_space.$say_usage_count.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			if ($line =~ /\s*udev-always-use-vnr;/)
			{
				$udev_always_use_vnr_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					udev_always_use_vnr_seen => $usage_count_seen, 
				}});
			}
		}
		if ($in_handlers)
		{
			if ($line =~ /(\s*)unfence-peer(\s+)(.*?)(;.*)$/)
			{
				my $left_space        = $1;
				my $middle_space      = $2;
				my $value             = $3;
				my $right_side        = $4;
				   $unfence_peer_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'        => $left_space,
					's2:middle_space'      => $middle_space, 
					's3:value'             => $value, 
					's4:right_side'        => $right_side,
					's5:unfence_peer_seen' => $unfence_peer_seen, 
					's6:say_unfence_peer'  => $say_unfence_peer, 
				}});
				   
				if ($value ne $say_unfence_peer)
				{
					   $update   = 1;
					my $new_line = $left_space."unfence-peer".$middle_space.$say_unfence_peer.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			elsif ($line =~ /(\s*)fence-peer(\s+)(.*?)(;.*)$/)
			{
				my $left_space       = $1;
				my $middle_space     = $2;
				my $value            = $3;
				my $right_side       = $4;
				   $fence_peer_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'      => $left_space,
					's2:middle_space'    => $middle_space, 
					's3:value'           => $value, 
					's4:right_side'      => $right_side,
					's5:fence_peer_seen' => $fence_peer_seen, 
					's6:say_fence_peer'  => $say_fence_peer, 
				}});
				   
				if ($value ne $say_fence_peer)
				{
					   $update   = 1;
					my $new_line = $left_space."fence-peer".$middle_space.$say_fence_peer.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
		}
		if ($in_startup)
		{
			if ($line =~ /(\s*)wfc-timeout(\s+)(.*?)(;.*)$/)
			{
				my $left_space       = $1;
				my $middle_space     = $2;
				my $value            = $3;
				my $right_side       = $4;
				   $wfc_timeout_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'       => $left_space,
					's2:middle_space'     => $middle_space, 
					's3:value'            => $value, 
					's4:right_side'       => $right_side,
					's5:wfc_timeout_seen' => $wfc_timeout_seen, 
				}});
				   
				if ($value ne $say_wfc_timeout)
				{
					   $update   = 1;
					my $new_line = $left_space."wfc-timeout".$middle_space.$say_wfc_timeout.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
		}
		if ($in_options)
		{
			if ($line =~ /(\s*)auto-promote(\s+)(.*?)(;.*)$/)
			{
				my $left_space        = $1;
				my $middle_space      = $2;
				my $value             = $3;
				my $right_side        = $4;
				   $auto_promote_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'        => $left_space,
					's2:middle_space'      => $middle_space, 
					's3:value'             => $value, 
					's4:right_side'        => $right_side,
					's5:auto_promote_seen' => $auto_promote_seen, 
				}});
				   
				if ($value ne $say_auto_promote)
				{
					   $update   = 1;
					my $new_line = $left_space."auto-promote".$middle_space.$say_auto_promote.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
		}
		if ($in_disk)
		{
			if ($line =~ /(\s*)disk-flushes(\s+)(.*?)(;.*)$/)
			{
				my $left_space        = $1;
				my $middle_space      = $2;
				my $value             = $3;
				my $right_side        = $4;
				   $disk_flushes_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'        => $left_space,
					's2:middle_space'      => $middle_space, 
					's3:value'             => $value, 
					's4:right_side'        => $right_side,
					's5:disk_flushes_seen' => $disk_flushes_seen, 
				}});
				   
				if ($value ne $say_flushes)
				{
					   $update   = 1;
					my $new_line = $left_space."disk-flushes".$middle_space.$say_flushes.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			if ($line =~ /(\s*)md-flushes(\s+)(.*?)(;.*)$/)
			{
				my $left_space      = $1;
				my $middle_space    = $2;
				my $value           = $3;
				my $right_side      = $4;
				   $md_flushes_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'      => $left_space,
					's2:middle_space'    => $middle_space, 
					's3:value'           => $value, 
					's4:right_side'      => $right_side,
					's5:md_flushes_seen' => $md_flushes_seen, 
				}});
				   
				if ($value ne $say_flushes)
				{
					   $update   = 1;
					my $new_line = $left_space."md-flushes".$middle_space.$say_flushes.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
		}
		if ($in_net)
		{
			if ($line =~ /(\s*)allow-two-primaries(\s+)(.*?)(;.*)$/)
			{
				my $left_space        = $1;
				my $middle_space      = $2;
				my $value             = $3;
				my $right_side        = $4;
				   $allow_two_primaries_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'               => $left_space,
					's2:middle_space'             => $middle_space, 
					's3:value'                    => $value, 
					's4:right_side'               => $right_side,
					's5:allow_two_primaries_seen' => $allow_two_primaries_seen, 
				}});
				   
				if ($value ne $say_allow_two_primaries)
				{
					   $update   = 1;
					my $new_line = $left_space."allow-two-primaries".$middle_space.$say_allow_two_primaries.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			if ($line =~ /(\s*)after-sb-0pri(\s+)(.*?)(;.*)$/)
			{
				my $left_space         = $1;
				my $middle_space       = $2;
				my $value              = $3;
				my $right_side         = $4;
				   $after_sb_0pri_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'         => $left_space,
					's2:middle_space'       => $middle_space, 
					's3:value'              => $value, 
					's4:right_side'         => $right_side,
					's5:after_sb_0pri_seen' => $after_sb_0pri_seen, 
				}});
				
				if ($value ne $say_after_sb_0pri)
				{
					   $update   = 1;
					my $new_line = $left_space."after-sb-0pri".$middle_space.$say_after_sb_0pri.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			if ($line =~ /(\s*)after-sb-1pri(\s+)(.*?)(;.*)$/)
			{
				my $left_space         = $1;
				my $middle_space       = $2;
				my $value              = $3;
				my $right_side         = $4;
				   $after_sb_1pri_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'         => $left_space,
					's2:middle_space'       => $middle_space, 
					's3:value'              => $value, 
					's4:right_side'         => $right_side,
					's5:after_sb_1pri_seen' => $after_sb_1pri_seen, 
				}});
				
				if ($value ne $say_after_sb_1pri)
				{
					   $update   = 1;
					my $new_line = $left_space."after-sb-1pri".$middle_space.$say_after_sb_1pri.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			if ($line =~ /(\s*)after-sb-2pri(\s+)(.*?)(;.*)$/)
			{
				my $left_space         = $1;
				my $middle_space       = $2;
				my $value              = $3;
				my $right_side         = $4;
				   $after_sb_2pri_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'         => $left_space,
					's2:middle_space'       => $middle_space, 
					's3:value'              => $value, 
					's4:right_side'         => $right_side,
					's5:after_sb_2pri_seen' => $after_sb_2pri_seen, 
				}});
				
				if ($value ne $say_after_sb_2pri)
				{
					   $update   = 1;
					my $new_line = $left_space."after-sb-2pri".$middle_space.$say_after_sb_2pri.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			
			if ($line =~ /(\s*)ping-timeout(\s+)(.*?)(;.*)$/)
			{
				my $left_space        = $1;
				my $middle_space      = $2;
				my $value             = $3;
				my $right_side        = $4;
				   $ping_timeout_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'        => $left_space,
					's2:middle_space'      => $middle_space, 
					's3:value'             => $value, 
					's4:right_side'        => $right_side,
					's5:ping_timeout_seen' => $ping_timeout_seen, 
				}});
				
				if ($value ne $say_ping_timeout)
				{
					   $update   = 1;
					my $new_line = $left_space."ping-timeout".$middle_space.$say_ping_timeout.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
			# For some reason, this matches 'ping-timeout' hence the 'else'.
			elsif ($line =~ /(\s*)timeout(\s+)(.*?)(;.*)$/)
			{
				my $left_space   = $1;
				my $middle_space = $2;
				my $value        = $3;
				my $right_side   = $4;
				   $timeout_seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:left_space'   => $left_space,
					's2:middle_space' => $middle_space, 
					's3:value'        => $value, 
					's4:right_side'   => $right_side,
					's5:timeout_seen' => $timeout_seen, 
				}});
				
				if ($value ne $say_timeout)
				{
					   $update   = 1;
					my $new_line = $left_space."timeout".$middle_space.$say_timeout.$right_side;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:update'   => $update,
						's2:new_line' => $new_line, 
					}});
					
					$new_global_common .= $new_line.$comment."\n";
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
					next;
				}
			}
		}
		
		# Add this line (will have 'next'ed if the line was modified before getting here).
		$new_global_common .= $line.$comment."\n";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0518", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'}, line => $line }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:update'            => $update,
		's2:new_global_common' => $new_global_common, 
	}});
	if ($update)
	{
		$difference = diff \$old_global_common, \$new_global_common, { STYLE => 'Unified' };
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0517", variables => { 
			file => $anvil->data->{path}{configs}{'global-common.conf'},
			diff => $difference,
		}});

		my $failed = $anvil->Storage->write_file({
			debug     => $debug,
			overwrite => 1, 
			backup    => 1, 
			file      => $anvil->data->{path}{configs}{'global-common.conf'}, 
			body      => $new_global_common, 
			user      => "root", 
			group     => "root", 
			mode      => "0644", 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		if ($failed)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0043", variables => { file => $anvil->data->{path}{configs}{'global-common.conf'} }});
			return('!!error!!');
		}
	}
	
	return($difference);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2 _initialize_kmod

This checks to see if the C<< drbd >> kernel module can load. If not, a check is made to see if an RPM that matches the kernel exists. If so, it is installed. If not, C<< akmods >> is asked to build and install the drbd kernel module.

Returns C<< 0 >> is the module loads or is already loaded. C<< !!error!! >> if not.

=cut
sub _initialize_kmod
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "DRBD->_initialize_kmod()" }});
	
	my $kernel_release = $anvil->Get->kernel_release({debug => $debug});
	my $shell_call     = $anvil->data->{path}{exe}{modprobe}." drbd";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		kernel_release => $kernel_release,
		shell_call     => $shell_call,
	}});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code,
	}});
	
	if (not $return_code)
	{
		# Loaded fine
		return(0);
	}
	else
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0676"});
		my $install    = 0;
		my $shell_call = $anvil->data->{path}{exe}{dnf}." -q search kmod-drbd-".$kernel_release;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /Name Exactly/)
			{
				# We can install.
				$install = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { install => $install }});
				last;
			}
		}
		
		# Install or build?
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { install => $install }});
		if ($install)
		{
			### TODO: Should this be a background process? 
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0677"});
			my $shell_call = $anvil->data->{path}{exe}{dnf}." -y install kmod-drbd-".$kernel_release;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0678"});
			my $shell_call = $anvil->data->{path}{exe}{akmods}." --force";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
		}
		
		# In either case, try again.
		$output      = undef;
		$return_code = undef;
		$shell_call  = $anvil->data->{path}{exe}{modprobe}." drbd";
		($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
		
		if (not $return_code)
		{
			# Loaded fine
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0679"});
			return(0);
		}
		else
		{
			# Failed
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0132"});
		}
	}
	
	return('!!error!!');
}

package Anvil::Tools::Network;
# 
# This module contains methods used to deal with networking stuff.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Net::Netmask;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Network.pm";

### Methods;
# bridge_info
# check_firewall
# check_network
# check_internet
# download
# find_access
# find_matches
# find_target_ip
# get_company_from_mac
# get_ip_from_mac
# get_ips
# get_network
# is_local
# is_our_interface
# is_ip_in_network
# load_interfces
# load_ips
# manage_firewall
# ping
# read_nmcli
# _check_firewalld_conf
# _get_existing_zone_interfaces
# _get_server_ports
# _get_drbd_ports
# _get_live_migration_ports
# _manage_port
# _manage_service
# _manage_dr_firewall
# _manage_node_firewall
# _manage_striker_firewall

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Network

Provides all methods related to networking.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Storage->X'. 
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

=head2 bridge_info

This calls C<< bridge >> to get data on interfaces connected to bridges. A list of interfaces to connected to each bridge is stored here;

* bridge::<target>::<bridge_name>::interfaces = Array reference of interfaces connected this bridge

The rest of the variable / value pairs are stored here. See C<< man bridge -> state >> for more information of these values

* bridge::<target>::<bridge_name>::<interface_name>::<variable> = <value>

The common variables are;

* bridge::<target>::<bridge_name>::<interface_name>::ifindex = Interface index number.
* bridge::<target>::<bridge_name>::<interface_name>::flags = An array reference storing the flags set for the interface on the bridge.
* bridge::<target>::<bridge_name>::<interface_name>::mtu = The maximum transmitable unit size, in bytes.
* bridge::<target>::<bridge_name>::<interface_name>::state = The state of the bridge.
* bridge::<target>::<bridge_name>::<interface_name>::priority = The priority for this interface.
* bridge::<target>::<bridge_name>::<interface_name>::cost = The cost of this interface.

Paramters;

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 target (optional, default '')

If set, the bridge data will be read from the target machine. This needs to be the IP address or (resolvable) host name of the target.

=cut
sub bridge_info
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->bridge_info()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	my $host = $target ? $target : $anvil->Get->short_host_name();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	
	# First get the list of bridges.
	my $shell_call = $anvil->data->{path}{exe}{ip}." link show type bridge";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my $output = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	else
	{
		# Remote call
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call,
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:error'       => $error,
			's3:return_code' => $return_code, 
		}});
	}
	
	# Find the bridge interfaces
	my $bridge = "";
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /^\d+:\s+(.*?):/)
		{
			$bridge = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge => $bridge }});
			
			$anvil->data->{bridge}{$host}{$bridge}{found} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge::${host}::${bridge}::found" => $anvil->data->{bridge}{$host}{$bridge}{found},
			}});
		}
		next if not $bridge;
		
		if ($line =~ /mtu (\d+) /)
		{
			$anvil->data->{bridge}{$host}{$bridge}{mtu} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge::${host}::${bridge}::mtu" => $anvil->data->{bridge}{$host}{$bridge}{mtu},
			}});
		}
		if ($line =~ /link\/ether (\w\w:\w\w:\w\w:\w\w:\w\w:\w\w) /)
		{
			$anvil->data->{bridge}{$host}{$bridge}{mac} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge::${host}::${bridge}::mac" => $anvil->data->{bridge}{$host}{$bridge}{mac},
			}});
		}
	}
	
	# Now use bridge to find the interfaces connected to the bridges.
	$shell_call = $anvil->data->{path}{exe}{bridge}." -json -pretty link show";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	$output = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	else
	{
		# Remote call
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call,
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:error'       => $error,
			's3:return_code' => $return_code, 
		}});
	}
	
	# Did I get usable data?
	if ($output !~ /^\[/)
	{
		# Bad data.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0443", variables => { output => $output }});
		return(1);
	}
	
	my $json        = JSON->new->allow_nonref;
	my $bridge_data = $json->decode($output);
	foreach my $hash_ref (@{$bridge_data})
	{
		next if not defined $hash_ref->{master};
		my $master    = $hash_ref->{master};	# This can be the bond name for bond members.
		my $interface = $hash_ref->{ifname};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:master'    => $master,
			's2:interface' => $interface, 
		}});
		
		# If the 'master' wasn't found in the call above, the 'master' is not a bridge.
		next if not exists $anvil->data->{bridge}{$host}{$master};
		
		# Record this interface as being connected to this bridge.
		$anvil->data->{bridge}{$host}{$master}{interface}{$interface}{found} = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"bridge::${host}::${master}::interface::${interface}::found" => $anvil->data->{bridge}{$host}{$master}{interface}{$interface}{found}, 
		}});
		
		# Now store the rest of the data.
		foreach my $key (sort {$a cmp $b} keys %{$hash_ref})
		{
			next if $key eq "master";
			next if $key eq "ifname";
			$anvil->data->{bridge}{$host}{$master}{interface}{$interface}{$key} = $hash_ref->{$key};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge::${host}::${master}::interface::${interface}::${key}" => $anvil->data->{bridge}{$host}{$master}{interface}{$interface}{$key}, 
			}});
		}
	}
	
	# Make it easy to find the bridge an interface is in.
	delete $anvil->data->{interface_to_bridge} if exists $anvil->data->{interface_to_bridge};
	foreach my $bridge_name (sort {$a cmp $b} keys %{$anvil->data->{bridge}{$host}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_name => $bridge_name }});
		foreach my $interface_name (sort {$a cmp $b} keys %{$anvil->data->{bridge}{$host}{$bridge_name}{interface}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface_name => $interface_name }});
			
			$anvil->data->{interface_to_bridge}{$interface_name} = $bridge_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"interface_to_bridge::${interface_name}" => $anvil->data->{interface_to_bridge}{$interface_name},
			}});
		}
	}
	
	return(0);
}


=head2 check_firewall

This checks to see if the firewall is running. If it is not, and if C<< sys::daemons::restart_firewalld >> is not set to C<< 0 >>, it will start the firewall. 

It returns C<< 1 >>, the firewall is running. If it returns C<< 0 >>, it is not.

This method takes no parameters.

=cut
sub check_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->check_firewall()" }});
	
	my $running = 0;
	return(0);
	
	# Make sure firewalld is running.
	my $firewalld_running = $anvil->System->check_daemon({daemon => $anvil->data->{sys}{daemon}{firewalld}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { firewalld_running => $firewalld_running }});
	if ($firewalld_running)
	{
		$running = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
	}
	else
	{
		if ($anvil->data->{sys}{daemons}{restart_firewalld})
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0127"});
			my $return_code = $anvil->System->start_daemon({daemon => $anvil->data->{sys}{daemon}{firewalld}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
			if ($return_code)
			{
				# non-0 means something went wrong.
				return("!!error!!");
			}
			else
			{
				# Started
				$running = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { running => $running }});
			}
		}
		else
		{
			# We've been asked to leave it off.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, priority => "alert", key => "log_0128"});
			return(0);
		}
	}
	
	
	return($running);
}


=head2 check_network

B<< NOTE >>: This method is not yet implemented.

This method checks to see if bridges and the links in bonds are up. It can simply report the bridge, bond and link states, or it can try to bring up interfaces that are down.

This method returns C<< 0 >> if nothing was done. It returns C<< 1 >> if any repairs were done.

Data is stored in the hash;

* bridge_health::<bridge_name>::up                               = [0,1]
* bond_health::<bond_name>::up                                   = [0,1]
* bond_health::<bond_name>::active_links                         = <number of interfaces active in the bond, but not necessarily up>
* bond_health::<bond_name>::up_links                             = <number of links that are 'up' or 'going back'>
* bond_health::<bond_name>::configured_links                     = <the number of interfaces configured to be members of this bond>
* bond_health::<bond_name>::interface::<interface_name>::in_bond = [0,1] <set to '1' if the interface is active in the bond>
* bond_health::<bond_name>::interface::<interface_name>::up      = [0,1] <set to '1' if 'up' or 'going back'>
* bond_health::<bond_name>::interface::<interface_name>::carrier = [0,1] <set to '1' if carrier detected>
* bond_health::<bond_name>::interface::<interface_name>::name    = <This is the NetworkManager name of the interface>

Parameters;

=head3 heal (optional, default 'down_only')

When set to C<< down_only >>, a bond where both links are down will attempt to up the links. However, bonds with at least one link up will be left alone. This is the default behaviour as it's not uncommon for admins to remotely down a single interface that is failing to stop alerts until a physical repair can be made.

When set to C<< all >>, any interfaces that are found to be down will attempt to brought up. 

Wen set to C<< none >>, no attempts will be made to bring up any interfaces. The states will simply be recorded.

B<< Note >>: Interfaces that show no carrier will not be started in any case.

=cut
sub check_network
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->check_internet()" }});
	
	# This is causing more problems than it solves. Disabled for the time being.
	return(0);
	
	my $heal = defined $parameter->{heal} ? $parameter->{heal} : "down_only";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		heal => $heal, 
	}});
	
	# Find out the bonds that are up.
	my $host = $anvil->Get->short_host_name();
	$anvil->Network->bridge_info({debug => $debug});
	
	if (exists $anvil->data->{bond_health})
	{
		delete $anvil->data->{bond_health};
	}
	
	# Read in the network configuration files to track which interfaces are bound to which bonds.
	my $repaired  = 0;
	my $interface = "";
	my $directory = $anvil->data->{path}{directories}{ifcfg};
	local(*DIRECTORY);
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0018", variables => { directory => $directory }});
	opendir(DIRECTORY, $directory);
	while(my $file = readdir(DIRECTORY))
	{
		if ($file =~ /^ifcfg-(.*)$/)
		{
			$interface = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
			
			# We'll check these, so this just makes sure we don't get an undefined variable error.
			$anvil->data->{raw_network}{interface}{$interface}{variable}{TYPE}   = "";
			$anvil->data->{raw_network}{interface}{$interface}{variable}{DEVICE} = "";
			$anvil->data->{raw_network}{interface}{$interface}{variable}{MASTER} = "";
		}
		else
		{
			next;
		}
		my $full_path = $directory."/".$file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { full_path => $full_path }});
		
		my $device  = "";
		my $is_link = "";
		my $in_bond = "";
		my $is_bond = "";
		
		# Read in the file. 
		my $file_body = $anvil->Storage->read_file({debug => ($debug+1), file => $full_path});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
		
		foreach my $line (split/\n/, $file_body)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			$line =~ s/#.*$//;
			if ($line =~ /^(.*?)=(.*)$/)
			{
				my $variable =  $1;
				my $value    =  $2;
				   $value    =~ s/^"(.*)"$/$1/;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					variable => $variable,
					value    => $value,
				}});
				
				$anvil->data->{raw_network}{interface}{$interface}{variable}{$variable} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"raw_network::interface::${interface}::variable::${variable}" => $anvil->data->{raw_network}{interface}{$interface}{variable}{$variable},
				}});
			}
		}
		$interface = "";
	}
	closedir(DIRECTORY);
	
	# Process
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{raw_network}{interface}})
	{
		my $type   =  $anvil->data->{raw_network}{interface}{$interface}{variable}{TYPE};
		my $device =  $anvil->data->{raw_network}{interface}{$interface}{variable}{DEVICE};
		my $name   =  defined $anvil->data->{raw_network}{interface}{$interface}{variable}{NAME} ? $anvil->data->{raw_network}{interface}{$interface}{variable}{NAME} : $device;
		   $name   =~ s/ /_/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			interface => $interface,
			type      => $type,
			device    => $device,
			name      => $name,
		}});
		
		# Is this a bridge?
		if (lc($type) eq "bridge")
		{
			# Yup!
			$anvil->data->{bridge_health}{$device}{up}   = 0;
			$anvil->data->{bridge_health}{$device}{name} = $name;
			if ((exists $anvil->data->{bridge}{$host}{$device}) && ($anvil->data->{bridge}{$host}{$device}{found}))
			{
				$anvil->data->{bridge_health}{$device}{up} = 1;
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge_health::${device}::up"   => $anvil->data->{bridge_health}{$device}{up},
				"bridge_health::${device}::name" => $anvil->data->{bridge_health}{$device}{name},
			}});
		}
		
		# Is this a bond?
		if (lc($type) eq "bond")
		{
			# Yes! 
			$anvil->data->{bond_health}{$device}{configured_links} = 0;
			$anvil->data->{bond_health}{$device}{active_links}     = 0;
			$anvil->data->{bond_health}{$device}{up_links}         = 0;
			$anvil->data->{bond_health}{$device}{name}             = $name;
			
			# Find the links configured to be under this bond.
			foreach my $this_interface (sort {$a cmp $b} keys %{$anvil->data->{raw_network}{interface}})
			{
				# Is this a bond?
				my $this_type   = $anvil->data->{raw_network}{interface}{$this_interface}{variable}{TYPE};
				my $this_device = $anvil->data->{raw_network}{interface}{$this_interface}{variable}{DEVICE};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					this_interface => $this_interface,
					this_type      => $this_type,
					this_device    => $this_device,
				}});
				next if lc($this_type) ne "ethernet";
				
				my $master = $anvil->data->{raw_network}{interface}{$this_interface}{variable}{MASTER};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { master => $master }});
				if (($master) && ($master eq $device))
				{
					# This interface belongs to this bond.
					$anvil->data->{bond_health}{$device}{interface}{$this_device}{in_bond} = 0;
					$anvil->data->{bond_health}{$device}{interface}{$this_device}{up}      = "unknown";
					$anvil->data->{bond_health}{$device}{interface}{$this_device}{carrier} = "unknown";
					$anvil->data->{bond_health}{$device}{interface}{$this_device}{name}    = $this_interface;
					$anvil->data->{bond_health}{$device}{configured_links}++;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"bond_health::${device}::interface::${this_device}::name" => $anvil->data->{bond_health}{$device}{interface}{$this_device}{name},
						"bond_health::${device}::configured_links"                => $anvil->data->{bond_health}{$device}{configured_links},
					}});
					
					# Read the interface's carrier
					my $carrier_file = "/sys/class/net/".$this_device."/carrier";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { carrier_file => $carrier_file }});
					
					if (-e $carrier_file)
					{
						my $carrier = $anvil->Storage->read_file({debug => ($debug+1), file => $carrier_file});
						chomp $carrier;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { carrier => $carrier }});
						
						$anvil->data->{bond_health}{$device}{interface}{$this_device}{carrier} = $carrier;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"bond_health::${device}::interface::${this_device}::carrier" => $anvil->data->{bond_health}{$device}{interface}{$this_device}{carrier},
						}});
					}
					
					my $operstate_file = "/sys/class/net/".$this_device."/operstate";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { operstate_file => $operstate_file }});
					
					if (-e $operstate_file)
					{
						my $operstate = $anvil->Storage->read_file({debug => ($debug+1), file => $operstate_file});
						chomp $operstate;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { operstate => $operstate }});
						
						$anvil->data->{bond_health}{$device}{interface}{$this_device}{up} = $operstate eq "up" ? 1 : 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"bond_health::${device}::interface::${this_device}::operstate" => $anvil->data->{bond_health}{$device}{interface}{$this_device}{operstate},
						}});
					}
				}
			}
			
			# Read in the /proc file.
			my $proc_file = "/proc/net/bonding/".$device;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { proc_file => $proc_file }});
			
			my $in_link   = "";
			my $file_body = $anvil->Storage->read_file({debug => $debug, file => $proc_file});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
			foreach my $line (split/\n/, $file_body)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
				
				if ($line =~ /Slave Interface: (.*)$/)
				{
					$in_link                                                           = $1;
					$anvil->data->{bond_health}{$device}{active_links}++;
					$anvil->data->{bond_health}{$device}{interface}{$in_link}{in_bond} = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"bond_health::${device}::active_links"                   => $anvil->data->{bond_health}{$device}{active_links},
						"bond_health::${device}::interface::${in_link}::in_bond" => $anvil->data->{bond_health}{$device}{interface}{$in_link}{in_bond},
					}});
					next;
				}
				if (not $line)
				{
					$in_link = "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_link => $in_link }});
					next;
				}
				if ($in_link)
				{
					if ($line =~ /MII Status: (.*)$/)
					{
						my $status = $1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { status => $status }});
						if ($status eq "up")
						{
							$anvil->data->{bond_health}{$device}{up_links}++;
							$anvil->data->{bond_health}{$device}{interface}{$in_link}{up} = 1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"bond_health::${device}::up_links"                  => $anvil->data->{bond_health}{$device}{up_links},
								"bond_health::${device}::interface::${in_link}::up" => $anvil->data->{bond_health}{$device}{interface}{$in_link}{up},
							}});
						}
						else
						{
							$anvil->data->{bond_health}{$device}{interface}{$in_link}{up} = 0;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"bond_health::${device}::interface::${in_link}::up" => $anvil->data->{bond_health}{$device}{interface}{$in_link}{up},
							}});
						}
						next;
					}
				}
				else
				{
					if ($line =~ /MII Status: (.*)$/)
					{
						my $status                                  = $1;
						   $anvil->data->{bond_health}{$device}{up} = $status eq "up" ? 1 : 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							status                       => $status, 
							"bond_health::${device}::up" => $anvil->data->{bond_health}{$device}{up},
						}});
						next;
					}
				}
			}
		}
	}
	
	# Before we check the bonds, check the bridges. Bonds won't come up if they're in a bridge that is 
	# down.
	my $bridge_count = keys %{$anvil->data->{bridge_health}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_count => $bridge_count }});
	if (($bridge_count) && (not $heal eq "none"))
	{
		foreach my $bridge (sort {$a cmp $b} keys %{$anvil->data->{bridge_health}})
		{
			my $up   = $anvil->data->{bridge_health}{$bridge}{up};
			my $name = $anvil->data->{bridge_health}{$bridge}{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				bridge => $bridge,
				name   => $name,
				up     => $up,
			}});
			
			if (not $up)
			{
				# Try to recover the interface
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0632", variables => { bridge => $bridge }});
				
				my $shell_call = $anvil->data->{path}{exe}{ifup}." ".$name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				
				my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					'output'      => $output,
					'return_code' => $return_code, 
				}});
			}
		}
	}
	
	foreach my $bond (sort {$a cmp $b} keys %{$anvil->data->{bond_health}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:bond_health::${bond}::name"             => $anvil->data->{bond_health}{$bond}{name},
			"s2:bond_health::${bond}::up"               => $anvil->data->{bond_health}{$bond}{up},
			"s3:bond_health::${bond}::configured_links" => $anvil->data->{bond_health}{$bond}{configured_links},
			"s4:bond_health::${bond}::active_links"     => $anvil->data->{bond_health}{$bond}{active_links},
			"s5:bond_health::${bond}::up_links"         => $anvil->data->{bond_health}{$bond}{up_links},
		}});
		foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{bond_health}{$bond}{interface}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:bond_health::${bond}::interface::${interface}::name"    => $anvil->data->{bond_health}{$bond}{interface}{$interface}{name},
				"s2:bond_health::${bond}::interface::${interface}::in_bond" => $anvil->data->{bond_health}{$bond}{interface}{$interface}{in_bond},
				"s3:bond_health::${bond}::interface::${interface}::up"      => $anvil->data->{bond_health}{$bond}{interface}{$interface}{up},
				"s4:bond_health::${bond}::interface::${interface}::carrier" => $anvil->data->{bond_health}{$bond}{interface}{$interface}{carrier},
			}});
		}
		
		if ($anvil->data->{bond_health}{$bond}{configured_links} != $anvil->data->{bond_health}{$bond}{up_links})
		{
			next if $heal eq "none";
			next if (($anvil->data->{bond_health}{$bond}{up}) && ($heal eq "down_only"));
			
			# Log that we're going to try to heal this bond.
			if ($heal eq "down_only")
			{
				# Log that we're healing fully down bonds.
				$repaired = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0627", variables => { bond => $bond }});
			}
			else
			{
				# Log that we're healing all bond links
				$repaired = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0628", variables => { bond => $bond }});
			}
			
			# For good measure, try to up the bond as well.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0630", variables => { bond => $bond }});
			
			my $shell_call = $anvil->data->{path}{exe}{ifup}." ".$anvil->data->{bond_health}{$bond}{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				'output'      => $output,
				'return_code' => $return_code, 
			}});
			
			# If we're here, try to bring up down'ed interfaces.
			foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{bond_health}{$bond}{interface}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s2:bond_health::${bond}::interface::${interface}::in_bond" => $anvil->data->{bond_health}{$bond}{interface}{$interface}{in_bond},
					"s4:bond_health::${bond}::interface::${interface}::carrier" => $anvil->data->{bond_health}{$bond}{interface}{$interface}{carrier},
				}});
				if ((not $anvil->data->{bond_health}{$bond}{interface}{$interface}{in_bond}) && ($anvil->data->{bond_health}{$bond}{interface}{$interface}{carrier}))
				{
					# Link shown, try to start the interface.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0629", variables => { 
						bond      => $bond,
						interface => $interface." (".$anvil->data->{bond_health}{$bond}{interface}{$interface}{name}.")",
					}});
					
					my $shell_call = $anvil->data->{path}{exe}{ifup}." ".$anvil->data->{bond_health}{$bond}{interface}{$interface}{name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { shell_call => $shell_call }});
					
					my ($output, $return_code) = $anvil->System->call({debug => 1, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						'output'      => $output,
						'return_code' => $return_code, 
					}});
				}
			}
		}
	}
	
	return($repaired);
}


=head2 check_internet

This method tries to connect to the internet. If successful, C<< 1 >> is returned. Otherwise, C<< 0 >> is returned.

Paramters;

=head3 domains (optional, default 'defaults::network::test::domains')

If passed an array reference, the domains in the array will be checked in the order they are found in the array. As soon as any respond to a ping, the check exits and C<< 1 >> is returned.

If not passed, C<< defaults::network::test::domains >> are used.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 target (optional)

If set, the file will be read from the target machine. This must be either an IP address or a resolvable host name. 

=head3 tries (optional, default 3)

This is how many times we'll try to ping the target. Pings are done one ping at a time, so that if the first ping succeeds, the test can exit quickly and return success. 

=cut
sub check_internet
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->check_internet()" }});
	
	my $access      = 0;
	my $domains     = defined $parameter->{domains}     ? $parameter->{domains}     : $anvil->data->{defaults}{network}{test}{domains};
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $tries       = defined $parameter->{tries}       ? $parameter->{tries}       : 3;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		domains     => $domains, 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target,
		tries       => $tries, 
	}});
	
	if (ref($domains) eq "ARRAY")
	{
		my $domain_count = @{$domains};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { domain_count => $domain_count }});
		if (not $domain_count)
		{
			# Array is empty
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0440", variables => { name => "domain" }});
			return($access);
		}
	}
	else
	{
		# Domains isn't an array.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0218", variables => { name => "domain", value => $domains }});
		return($access);
	}
	
	if (($tries =~ /\D/) or ($tries < 1))
	{
		# Invalid
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0441", variables => { name => "tries", value => $tries }});
		return($access);
	}
	
	foreach my $domain (@{$domains})
	{
		# Is the domain valid?
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { domain => $domain }});
		
		if ((not $anvil->Validate->domain_name({debug => $debug, name => $domain})) and 
		    (not $anvil->Validate->ipv4({debug => $debug, ip => $domain})))
		{
			# Not valid, skip
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0442", variables => { name => $domain }});
			next;
		}
		
		my ($pinged, $average_time) = $anvil->Network->ping({
			debug       => $debug, 
			target      => $target,
			port        => $port,
			password    => $password, 
			remote_user => $remote_user,
			ping        => $domain, 
			count       => 3,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			pinged       => $pinged,
			average_time => $average_time,
		}});
		if ($pinged)
		{
			$access = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { access => $access }});
		}
		last if $pinged;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { access => $access }});
	return($access);
}

=head2 download

This downloads a file from a network target and saves it to a local file. This must be called on a local system so that the download progress can be reported.

On success, the saved file is returned. On failure, an empty string is returned.

Parameters;

=head3 overwrite (optional, default '0')

When set, if the output file already exists, the existing file will be removed before the download is called.

B<< NOTE >>: If the output file already exists and is 0-bytes, it is removed and the download proceeds regardless of this setting.

=head3 save_to (optional)

If set, this is where the file will be downloaded to. If this ends with C<< / >>, the file name is preserved from the C<< url >> and will be saved in the C<< save_to >>'s directory with the original file name. Otherwise, the downlaoded file is saved with the file name given. As such, be careful about the trailing C<< / >>!

When not specified, the file name in the URL will be used and the file will be saved in the active user's home directory.

=head3 status (optional, default '1')

When set to C<< 1 >>, a periodic status message is printed. When set to C<< 0 >>, no status will be printed.

=head3 url (required)

This is the URL to the file to download.

=cut
sub download
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->download()" }});
	
	my $overwrite = defined $parameter->{overwrite} ? $parameter->{overwrite} : 0;
	my $save_to   = defined $parameter->{save_to}   ? $parameter->{save_to}   : "";
	my $status    = defined $parameter->{status}    ? $parameter->{status}    : 1;
	my $url       = defined $parameter->{url}       ? $parameter->{url}       : "";
	my $uuid      = $anvil->Get->uuid();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		overwrite => $overwrite, 
		save_to   => $save_to,
		status    => $status, 
		url       => $url, 
		uuid      => $uuid, 
	}});
	
	if (not $url)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->download()", parameter => "url" }});
		return("");
	}
	elsif (($url !~ /^ftp\:\/\//) && ($url !~ /^http\:\/\//) && ($url !~ /^https\:\/\//))
	{
		# Invalid URL.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0085", variables => { url => $url }});
		return("");
	}
	
	# The name of the file to be downloaded will be used if the path isn't specified, or if it ends in '/'.
	my $source_file = ($url =~ /^.*\/(.*)$/)[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source_file => $source_file }});
	
	if (not $save_to)
	{
		$save_to = $anvil->Get->users_home({debug => $debug})."/".$source_file;
		$save_to =~ s/\/\//\//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 0, list => { save_to => $save_to }});
	}
	elsif ($save_to =~ /\/$/)
	{
		$save_to .= "/".$source_file;
		$save_to =~ s/\/\//\//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 0, list => { save_to => $save_to }});
	}
	
	# Does the download file exist already?
	if (-e $save_to)
	{
		# If overwrite is set, or if the file is zero-bytes, remove it.
		my $size = (stat($save_to))[7];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			size => $size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size}).")",
		}});
		if (($overwrite) or ($size == 0))
		{
			unlink $save_to;
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "error_0094", variables => { 
				url     => $url,
				save_to => $save_to, 
			}});
			return("");
		}
	}
	
	### TODO: Make this work well as a job
	my $status_file      = "/tmp/".$source_file.".download_status";
	my $bytes_downloaded = 0;
	my $running_time     = 0;
	my $average_rate     = 0;
	my $start_printed    = 0;
	my $percent          = 0;
	my $rate             = 0;	# Bytes/sec
	my $downloaded       = 0;	# Bytes
	my $time_left        = 0;	# Seconds
	my $report_interval  = 5;	# Seconds between status file update
	my $next_report      = time + $report_interval;
	my $error            = 0;
	
	# This should print to a status file
	print "uuid=$uuid bytes_downloaded=0 percent=0 current_rate=0 average_rate=0 seconds_running=0 seconds_left=0 url=$url save_to=$save_to\n" if $status;;
	
	# Download command
	my $unix_start = 0;
	my $shell_call = $anvil->data->{path}{exe}{wget}." -c --progress=dot:binary ".$url." -O ".$save_to;
	my $output = "";
	open (my $file_handle, $shell_call." 2>&1 |") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
	while(<$file_handle>)
	{
		chomp;
		my $line =  $_;
		   $line =~ s/^\s+//;
		   $line =~ s/\s+$//;
		   $line =~ s/\s+/ /g;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0017", variables => { line => $line }});
		if (($line =~ /404/) && ($line =~ /Not Found/i))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0086", variables => { url => $url }});
			$error = 1;;
		}
		if ($line =~ /Name or service not known/i)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0087", variables => { url => $url }});
			$error = 1;;
		}
		if ($line =~ /Connection refused/i)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0088", variables => { url => $url }});
			$error = 1;;
		}
		if ($line =~ /route to host/i)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0089", variables => { url => $url }});
			$error = 1;;
		}
		if ($line =~ /Network is unreachable/i)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0090", variables => { url => $url }});
			$error = 1;;
		}
		if ($line =~ /ERROR (\d+): (.*)$/i)
		{
			my $error_code    = $1;
			my $error_message = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error_code    => $error_code,
				error_message => $error_message, 
			}});
			
			if ($error_code eq "403")
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0091", variables => { url => $url }});
			}
			elsif ($error_code eq "404")
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0092", variables => { url => $url }});
			}
			else
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "error_0093", variables => { 
					url           => $url,
					error_code    => $error_code, 
					error_message => $error_message, 
				}});
			}
			$error = 1;;
		}
		
		if ($line =~ /^(\d+)K .*? (\d+)% (.*?) (\d+.*)$/)
		{
			$downloaded = $1;
			$percent    = $2;
			$rate       = $3;
			$time_left  = $4;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				downloaded => $downloaded,
				percent    => $percent,
				rate       => $rate,
				time_left  => $time_left,
			}});
			
			if (not $start_printed)
			{
				### NOTE: This is meant to be parsed by a script, so don't translate it.
				print "started:$uuid\n" if $status;
				$start_printed = 1;
			}
			
			### NOTE: According to: http://savannah.gnu.org/bugs/index.php?22765, wget uses base-2.
			# Convert
			   $bytes_downloaded = $downloaded * 1024;
			my $say_downloaded   = $anvil->Convert->bytes_to_human_readable({'bytes' => $bytes_downloaded});
			my $say_percent      = $percent."%";
			my $byte_rate        = $anvil->Convert->human_readable_to_bytes({size => $rate, base2 => 1});
			my $say_rate         = $anvil->Convert->bytes_to_human_readable({'bytes' => $byte_rate})."/s";
			   $running_time     = time - $unix_start;
			my $say_running_time = $anvil->Convert->time({'time' => $running_time, translate => 1});
			# Time left is a bit more complicated
			my $days    = 0;
			my $hours   = 0;
			my $minutes = 0;
			my $seconds = 0;
			if ($time_left =~ /(\d+)d/)
			{
				$days = $1;
				#print "$THIS_FILE ".__LINE__."; == days: [$days]\n";
			}
			if ($time_left =~ /(\d+)h/)
			{
				$hours = $1;
				#print "$THIS_FILE ".__LINE__."; == hours: [$hours]\n";
			}
			if ($time_left =~ /(\d+)m/)
			{
				$minutes = $1;
				#print "$THIS_FILE ".__LINE__."; == minutes: [$minutes]\n";
			}
			if ($time_left =~ /(\d+)s/)
			{
				$seconds = $1;
				#print "$THIS_FILE ".__LINE__."; == seconds: [$seconds]\n";
			}
			my $seconds_left     = (($days * 86400) + ($hours * 3600) + ($minutes * 60) + $seconds);
			my $say_time_left    = $anvil->Convert->time({'time' => $seconds_left, long => 1, translate => 1});
			   $running_time     = 1 if not $running_time;
			   $average_rate     = int($bytes_downloaded / $running_time);
			my $say_average_rate = $anvil->Convert->bytes_to_human_readable({'bytes' => $average_rate})."/s";
			
			#print "$THIS_FILE ".__LINE__."; downloaded: [$downloaded], bytes_downloaded: [$bytes_downloaded], say_downloaded: [$say_downloaded], percent: [$percent], rate: [$rate], byte_rate: [$byte_rate], say_rate: [$say_rate], time_left: [$time_left]\n";
			if (time > $next_report)
			{
				#print "$THIS_FILE ".__LINE__."; say_downloaded: [$say_downloaded], percent: [$percent], say_rate: [$say_rate], running_time: [$running_time], say_running_time: [$say_running_time], seconds_left: [$seconds_left], say_time_left: [$say_time_left]\n";
				#print "$file; Downloaded: [$say_downloaded]/[$say_percent], Rate/Avg: [$say_rate]/[$say_average_rate], Running: [$say_running_time], Left: [$say_time_left]\n";
				#print "$THIS_FILE ".__LINE__."; bytes_downloaded=$bytes_downloaded, percent=$percent, current_rate=$byte_rate, average_rate=$average_rate, seconds_running=$running_time, seconds_left=$seconds_left, save_to=$save_to\n";
				$next_report += $report_interval;
				
				# This should print to a status file
				print "uuid=$uuid bytes_downloaded=$bytes_downloaded percent=$percent current_rate=$byte_rate average_rate=$average_rate seconds_running=$running_time seconds_left=$seconds_left url=$url save_to=$save_to\n" if $status;
			}
		}
	}
	close $file_handle;
	chomp($output);
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
	if ($error)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { save_to => $save_to }});
		if (-e $save_to)
		{
			# Unlink the output file, it's empty.
			my $size = (stat($save_to))[7];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				size => $size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size}).")",
			}});
			if (not $size)
			{
				unlink $save_to;
			}
		}
		return("");
	}
	
	return($save_to);
}


=head2 find_access

This takes a host's UUID or name, and finds networks that this host can reach it on. If the target is not found in the database, C<< !!error!! >> is returned. Otherwise, the number of matches found is returned.

B<< Note >>: This requires that the target has recorded it's network in the database. 

It was written to be a saner version of C<< Network->find_matches() >>

Matches will be stored as:

* network_access::<network_name>::local_ip_address   = <local_ip_address>
* network_access::<network_name>::local_subnet_mask  = <local_subnet_mask>
* network_access::<network_name>::local_interface    = <local_interface_with_ip>
* network_access::<network_name>::local_speed        = <speed_in_Mbps>
* network_access::<network_name>::target_ip_address  = <target_ip_address>
* network_access::<network_name>::target_subnet_mask = <target_subnet_mask>
* network_access::<network_name>::target_interface   = <target_interface_with_ip>
* network_access::<network_name>::target_speed       = <speed_in_Mbps>

Where C<< network_name >> will be C<< bcnX >>, C<< ifnX >>, etc.

Paramters;

=head3 target (required)

This is the host (name or UUID) we're looking for connection options with.

=cut
sub find_access
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->find_access()" }});
	
	my $target = defined $parameter->{target} ? $parameter->{target} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target => $target, 
	}});
	
	if (not $target)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_access()", parameter => "target" }});
		return("!!error!!");
	}
	
	# Take the target and find the host_uuid and host_name.
	my $target_host_uuid = $anvil->Database->get_host_uuid_from_string({debug => $debug, string => $target});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_host_uuid => $target_host_uuid }});
	
	if (not $target_host_uuid)
	{
		# Bad target. 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0414", variables => { target => $target }});
		return("!!error!!");
	}
	
	my $host_uuid              = $anvil->Get->host_uuid;
	my $short_host_name        = $anvil->Get->short_host_name;
	my $target_short_host_name = $anvil->data->{hosts}{host_uuid}{$target_host_uuid}{short_host_name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid              => $host_uuid, 
		short_host_name        => $short_host_name, 
		target_short_host_name => $target_short_host_name, 
	}});
	
	# Load our IPs
	$anvil->Network->load_ips({
		debug => $debug, 
		host  => $short_host_name,
	});
	# Load our target's IPs.
	$anvil->Network->load_ips({
		debug     => $debug, 
		host      => $target_short_host_name,
		host_uuid => $target_host_uuid, 
	});
	
	# Loop through the first, and on each interface with an IP/subnet mask, look for a match in the second.
	foreach my $local_interface (sort {$b cmp $a} keys %{$anvil->data->{network}{$short_host_name}{interface}})
	{
		my $local_ip          = $anvil->data->{network}{$short_host_name}{interface}{$local_interface}{ip};
		my $local_subnet_mask = $anvil->data->{network}{$short_host_name}{interface}{$local_interface}{subnet_mask};
		my $local_speed       = $anvil->data->{network}{$short_host_name}{interface}{$local_interface}{speed}; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			local_interface   => $local_interface,
			local_ip          => $local_ip,
			local_subnet_mask => $local_subnet_mask,  
			local_speed       => $local_speed, 
		}});
		
		if (($local_ip) && ($local_subnet_mask))
		{
			# Look for a match.
			my $local_network = $anvil->Network->get_network({
				debug       => $debug, 
				ip          => $local_ip, 
				subnet_mask => $local_subnet_mask,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_network => $local_network }});
			
			foreach my $target_interface (sort {$b cmp $a} keys %{$anvil->data->{network}{$target_short_host_name}{interface}})
			{
				my $target_ip          = $anvil->data->{network}{$target_short_host_name}{interface}{$target_interface}{ip};
				my $target_subnet_mask = $anvil->data->{network}{$target_short_host_name}{interface}{$target_interface}{subnet_mask};
				my $target_speed       = $anvil->data->{network}{$target_short_host_name}{interface}{$target_interface}{speed}; 
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					target_interface   => $target_interface,
					target_ip          => $target_ip,
					target_subnet_mask => $target_subnet_mask,  
					target_speed       => $target_speed,  
				}});
				if (($target_ip) && ($target_subnet_mask))
				{
					# Do we have a match?
					my $target_network = $anvil->Network->get_network({
						debug       => $debug, 
						ip          => $target_ip, 
						subnet_mask => $target_subnet_mask,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						local_network  => $local_network,
						target_network => $target_network,
					}});
					
					if ($local_network eq $target_network)
					{
						# Match!
						my $network_name =  $target_interface;
						   $network_name =~ s/^(\w+\d+)_.*$/$1/;
						   
						$anvil->data->{network_access}{$network_name}{local_interface}    = $local_interface;
						$anvil->data->{network_access}{$network_name}{local_speed}        = $local_speed;
						$anvil->data->{network_access}{$network_name}{local_ip_address}   = $local_ip;
						$anvil->data->{network_access}{$network_name}{local_subnet_mask}  = $local_subnet_mask;
						$anvil->data->{network_access}{$network_name}{target_interface}   = $target_interface;
						$anvil->data->{network_access}{$network_name}{target_speed}       = $target_speed;
						$anvil->data->{network_access}{$network_name}{target_ip_address}  = $target_ip;
						$anvil->data->{network_access}{$network_name}{target_subnet_mask} = $target_subnet_mask;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:network_access::${network_name}::local_interface"    => $anvil->data->{network_access}{$network_name}{local_interface},
							"s2:network_access::${network_name}::local_speed"        => $anvil->data->{network_access}{$network_name}{local_speed},
							"s3:network_access::${network_name}::local_ip_address"   => $anvil->data->{network_access}{$network_name}{local_ip_address},
							"s4:network_access::${network_name}::local_subnet_mask"  => $anvil->data->{network_access}{$network_name}{local_subnet_mask},
							"s5:network_access::${network_name}::target_interface"   => $anvil->data->{network_access}{$network_name}{target_interface},
							"s6:network_access::${network_name}::target_speed"       => $anvil->data->{network_access}{$network_name}{target_speed},
							"s7:network_access::${network_name}::target_ip_address"  => $anvil->data->{network_access}{$network_name}{target_ip_address},
							"s8:network_access::${network_name}::target_subnet_mask" => $anvil->data->{network_access}{$network_name}{target_subnet_mask},
						}});
					}
				}
			}
		}
	}
	
	my $matches = keys %{$anvil->data->{network_access}};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { matches => $matches }});
	return($matches);
}



=head2 find_matches

This takes two hash keys from prior C<< Network->get_ips() >> or C<< ->load_ips() >> runs and finds which are on the same network. 

A hash reference is returned using the format:

* <first>::<interface>::ip           = <ip_address>
* <first>::<interface>::subnet_mask  = <subnet_mask>
* <second>::<interface>::ip          = <ip_address>
* <second>::<interface>::subnet_mask = <subnet_mask>

Where C<< first >> and C<< second >> are the parameters passed in below and C<< interface >> is the name of the interface on the fist/second machine that can talk to one another.

Paramters;

=head3 first (required)

This is the hash key of the first machine being compared.

=head3 second (required)

This is the hash key of the second machine being compared.

=cut
sub find_matches
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->find_matches()" }});
	
	my $first  = defined $parameter->{first}  ? $parameter->{first}  : "";
	my $second = defined $parameter->{second} ? $parameter->{second} : "";
	my $source = defined $parameter->{source} ? $parameter->{source} : $THIS_FILE;
	my $line   = defined $parameter->{line}   ? $parameter->{line}   : __LINE__;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		first  => $first, 
		second => $second, 
		source => $source, 
		line   => $line, 
	}});
	
	if (not $first)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_matches()", parameter => "first" }});
		return("");
	}
	elsif (ref($anvil->data->{network}{$first}) ne "HASH")
	{
		$anvil->Network->load_ips({
			debug => $debug, 
			host  => $first,
		});
		if (ref($anvil->data->{network}{$first}) ne "HASH")
		{
			# Well, we tried.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0106", variables => { 
				key    => "first -> network::".$first,
				source => $source, 
				line   => $line,
			}});
			return("");
		}
	}
	if (not $second)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_matches()", parameter => "second" }});
		return("");
	}
	elsif (ref($anvil->data->{network}{$second}) ne "HASH")
	{
		$anvil->Network->load_ips({
			debug => $debug, 
			host  => $second,
		});
		if (ref($anvil->data->{network}{$second}) ne "HASH")
		{
			# Well, we tried.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0106", variables => { 
				key    => "second -> network::".$second,
				source => $source, 
				line   => $line,
			}});
			$anvil->nice_exit({exit_code => 1});
			return("");
		}
	}
	
	# Loop through the first, and on each interface with an IP/subnet mask, look for a match in the second.
	my $match = {};
	foreach my $first_interface (sort {$b cmp $a} keys %{$anvil->data->{network}{$first}{interface}})
	{
		my $first_ip          = $anvil->data->{network}{$first}{interface}{$first_interface}{ip};
		my $first_subnet_mask = $anvil->data->{network}{$first}{interface}{$first_interface}{subnet_mask};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			first             => $first,
			first_interface   => $first_interface,
			first_ip          => $first_ip,
			first_subnet_mask => $first_subnet_mask,  
		}});
		
		if (($first_ip) && ($first_subnet_mask))
		{
			# Look for a match.
			my $first_network = $anvil->Network->get_network({
				debug       => $debug, 
				ip          => $first_ip, 
				subnet_mask => $first_subnet_mask,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { a_network => $first_network }});
			
			foreach my $second_interface (sort {$b cmp $a} keys %{$anvil->data->{network}{$second}{interface}})
			{
				my $second_ip          = $anvil->data->{network}{$second}{interface}{$second_interface}{ip};
				my $second_subnet_mask = $anvil->data->{network}{$second}{interface}{$second_interface}{subnet_mask};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					second             => $second,
					second_interface   => $second_interface,
					second_ip          => $second_ip,
					second_subnet_mask => $second_subnet_mask,  
				}});
				if (($second_ip) && ($second_subnet_mask))
				{
					# Do we have a match?
					my $second_network = $anvil->Network->get_network({
						debug       => $debug, 
						ip          => $second_ip, 
						subnet_mask => $second_subnet_mask,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						a_network => $first_network,
						b_network => $second_network,
					}});
					
					if ($first_network eq $second_network)
					{
						# Match!
						$match->{$first}{$first_interface}{ip}            = $first_ip;
						$match->{$first}{$first_interface}{subnet_mask}   = $second_network;
						$match->{$second}{$second_interface}{ip}          = $second_ip;
						$match->{$second}{$second_interface}{subnet_mask} = $first_network;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"${first}::${first_interface}::ip"            => $match->{$first}{$first_interface}{ip},
							"${first}::${first_interface}::subnet_mask"   => $match->{$first}{$first_interface}{subnet_mask},
							"${second}::${second_interface}::ip"          => $match->{$second}{$second_interface}{ip},
							"${second}::${second_interface}::subnet_mask" => $match->{$second}{$second_interface}{subnet_mask},
						}});
					}
				}
			}
		}
	}
	
	return($match);
}


=head2 find_target_ip

This uses the IP information for the local machine and a target host UUID, and returns an IP address that can be used to contact it. When multiple networks are shared, the BCN IP is used. If no match is found, an empty string is returned.

 my $target_ip = $anvil->Network->find_target_ip({host_uuid => "8da3d2fe-783a-4619-abb5-8ccae58f7bd6"});

Parameters;

=head3 host_uuid (required)

This is the target's C<< host_uuid >> that we're looking to contact.

=cut
sub find_target_ip
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->find_target_ip()" }});
	
	my $target_ip = "";
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid => $host_uuid, 
	}});
	
	if (not $host_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_target_ip()", parameter => "host_uuid" }});
		return("");
	}
	
	$anvil->Database->get_hosts();
	if (not exists $anvil->data->{hosts}{host_uuid}{$host_uuid})
	{
		# Unknown host
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0031", variables => { host_uuid => $host_uuid }});
		return("");
	}
	
	my $target_host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{short_host_name};
	my $short_host_name  = $anvil->Get->short_host_name({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target_host_name => $target_host_name, 
		short_host_name  => $short_host_name, 
	}});
	
	$anvil->Network->load_ips({
		debug     => $debug,
		host_uuid => $anvil->Get->host_uuid,
		host      => $short_host_name, 
		clear     => 1,
	});
	
	$anvil->Network->load_ips({
		debug     => $debug,
		host_uuid => $host_uuid,
		host      => $target_host_name, 
		clear     => 1,
	});
	
	my ($match) = $anvil->Network->find_matches({
		debug  => $debug,
		first  => $short_host_name,
		second => $target_host_name, 
		source => $THIS_FILE, 
		line   => __LINE__,
	});
	if ($match)
	{
		# Yup!
		my $match_found = 0;
		foreach my $interface (sort {$a cmp $b} keys %{$match->{$target_host_name}})
		{
			$target_ip = $match->{$target_host_name}{$interface}{ip};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_ip => $target_ip }});
			last;
		}
		
	}
	
	return($target_ip);
}


=head2 get_company_from_mac

This takes a MAC address (or the first six bytes) and returns the company that owns the OUI. If the company name is not found, an expty string is returned.

Parameters;

=head3 mac (required)

This is the first six bytes of the mac address,  C<< xx:xx:xx >> format, being searched for.

=cut
sub get_company_from_mac
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->get_company_from_mac()" }});
	
	my $mac     = defined $parameter->{mac} ? lc($parameter->{mac}) : "";
	my $company = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		mac => $mac,
	}});
	
	if (not $mac)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->get_company_from_mac()", parameter => "mac_prefix" }});
		return("");
	}
	
	# Have I already looked this one up?
	if ($anvil->data->{cache}{mac_to_oui}{$mac})
	{
		# Yup, no need to process.
		return($anvil->data->{cache}{mac_to_oui}{$mac});
	}
	
	my $valid_mac = $anvil->Validate->mac({mac => $mac});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac => $mac }});
	if ($valid_mac)
	{
		# Strip the first six bytes.
		$mac = ($mac =~ /^([0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2})/i)[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac => $mac }});
	}
	elsif ($mac !~ /[0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}/i)
	{
		# Bad format
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0104", variables => { mac => $mac }});
		return("");
	}
	
	my $query = "SELECT oui_company_name FROM oui WHERE oui_mac_prefix = ".$anvil->Database->quote(lc($mac)).";";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	if ($count)
	{
		$company = $results->[0]->[0];
		$anvil->data->{cache}{mac_to_oui}{$mac} = $company;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { company => $company }});
	}
	
	if ((not $company) && ($mac =~ /^52:54:00/))
	{
		$company = "KVM/qemu";
	}
	
	return($company);
}


=head2 get_ip_from_mac

This takes a MAC address and tries to convert it to an IP address. If no IP is found, an empty string is returned.

Parameters;

=head3 mac (required)

This is the MAC address we're looking for an IP to match to. The format must be C<< aa:bb:cc:dd:ee:ff >>.

=cut
sub get_ip_from_mac
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->get_ip_from_mac()" }});
	
	my $ip  = "";
	my $mac = defined $parameter->{mac} ? $parameter->{mac} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		mac => $mac, 
	}});
	
	my $query = "SELECT mac_to_ip_ip_address FROM mac_to_ip WHERE mac_to_ip_mac_address = ".$anvil->Database->quote(lc($mac)).";";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	if ($count)
	{
		$ip = $results->[0]->[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	}
	
	return($ip);
}


=head2 get_ips

This method checks the local system for interfaces and stores them in:

* C<< network::<target>::interface::<iface_name>::ip >>              - If an IP address is set
* C<< network::<target>::interface::<iface_name>::subnet_mask >>     - If an IP is set
* C<< network::<target>::interface::<iface_name>::mac_address >>     - Always set.
* C<< network::<target>::interface::<iface_name>::mtu >>             - Always set.
* C<< network::<target>::interface::<iface_name>::default_gateway >> = C<< 0 >> if not the default gateway, C<< 1 >> if so.
* C<< network::<target>::interface::<iface_name>::gateway >>         = If the default gateway, this is the gateway IP address.
* C<< network::<target>::interface::<iface_name>::dns >>             = If the default gateway, this is the comma-separated list of active DNS servers.

To make it convenient to translate a MAC address into interface names, this hash is also stored;

* C<< network::<target>::mac_address::<mac_address>::interface = Interface name.

When called without a C<< target >>, C<< local >> is used.

To aid in look-up by MAC address, C<< network::mac_address::<mac_address>::iface >> is also set. Note that this is not target-dependent.

Parameters;

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 target (optional)

If set, the file will be read from the target machine. This must be either an IP address or a resolvable host name. 

The file will be copied to the local system using C<< $anvil->Storage->rsync() >> and stored in C<< /tmp/<file_path_and_name>.<target> >>. if C<< cache >> is set, the file will be preserved locally. Otherwise it will be deleted once it has been read into memory.

B<< Note >>: the temporary file will be prefixed with the path to the file name, with the C<< / >> converted to C<< _ >>.

=cut
sub get_ips
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->get_ips()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
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
	
	if (exists $anvil->data->{network}{$host})
	{
		delete $anvil->data->{network}{$host};
	}
	
	# Reading locally or remote?
	my $in_iface   = "";
	my $shell_call = $anvil->data->{path}{exe}{ip}." addr list";
	my $output     = "";
	my $is_local   = $anvil->Network->is_local({host => $target});
	if ($is_local)
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	else
	{
		# Remote call
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call,
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:error'       => $error,
			's3:return_code' => $return_code, 
		}});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^\d+: (.*?): <(.*?)>/)
		{
			   $in_iface = $1;
			my $status   = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				in_iface => $in_iface,
				status   => $status, 
			}});
			
			$anvil->data->{network}{$host}{interface}{$in_iface}{ip}              = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{ip};
			$anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask}     = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask};
			$anvil->data->{network}{$host}{interface}{$in_iface}{mac_address}     = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address};
			$anvil->data->{network}{$host}{interface}{$in_iface}{mtu}             = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{mtu};
			$anvil->data->{network}{$host}{interface}{$in_iface}{default_gateway} = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{default_gateway};
			$anvil->data->{network}{$host}{interface}{$in_iface}{gateway}         = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{gateway};
			$anvil->data->{network}{$host}{interface}{$in_iface}{dns}             = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{dns};
			$anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes}        = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes};
			$anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes}        = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes};
			$anvil->data->{network}{$host}{interface}{$in_iface}{status}          = $status;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${in_iface}::ip"              => $anvil->data->{network}{$host}{interface}{$in_iface}{ip}, 
				"network::${host}::interface::${in_iface}::subnet_mask"     => $anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask}, 
				"network::${host}::interface::${in_iface}::mac_address"     => $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address}, 
				"network::${host}::interface::${in_iface}::mtu"             => $anvil->data->{network}{$host}{interface}{$in_iface}{mtu}, 
				"network::${host}::interface::${in_iface}::default_gateway" => $anvil->data->{network}{$host}{interface}{$in_iface}{default_gateway}, 
				"network::${host}::interface::${in_iface}::gateway"         => $anvil->data->{network}{$host}{interface}{$in_iface}{gateway}, 
				"network::${host}::interface::${in_iface}::dns"             => $anvil->data->{network}{$host}{interface}{$in_iface}{dns}, 
				"network::${host}::interface::${in_iface}::status"          => $anvil->data->{network}{$host}{interface}{$in_iface}{status}, 
			}});
			
			if ($in_iface ne "lo")
			{
				# Read the read and write bytes.
				my $read_bytes  = 0;
				my $write_bytes = 0;
				my $shell_call  = "
if [ -e '/sys/class/net/".$in_iface."/statistics/rx_bytes' ]; 
then 
    echo -n 'rx:'; 
    cat /sys/class/net/".$in_iface."/statistics/rx_bytes; 
    echo -n 'tx:'; 
    cat /sys/class/net/".$in_iface."/statistics/tx_bytes; 
else 
    echo 'rx:0'; 
    echo 'tx:0';
fi";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				my $transmit_sizes = "";
				if ($is_local)
				{
					# Local call.
					($transmit_sizes, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:transmit_sizes' => $transmit_sizes,
						's2:return_code'    => $return_code, 
					}});
				}
				else
				{
					# Remote call
					($transmit_sizes, my $error, my $return_code) = $anvil->Remote->call({
						debug       => $debug, 
						shell_call  => $shell_call,
						target      => $target,
						user        => $remote_user, 
						password    => $password,
						remote_user => $remote_user, 
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:transmit_sizes' => $transmit_sizes,
						's2:error'          => $error,
						's3:return_code'    => $return_code, 
					}});
				}
				foreach my $line (split/\n/, $transmit_sizes)
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
					if ($line =~ /rx:(\d+)/)
					{
						$anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes} = $1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"network::${host}::interface::${in_iface}::rx_bytes" => $anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes}}).")", 
						}});
					}
					if ($line =~ /tx:(\d+)/)
					{
						$anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes} = $1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"network::${host}::interface::${in_iface}::tx_bytes" => $anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes}}).")", 
						}});
					}
				}
			}
		}
		next if not $in_iface;
		if ($in_iface eq "lo")
		{
			# We don't care about 'lo'.
			delete $anvil->data->{network}{$host}{interface}{$in_iface};
			next;
		}
		if ($line =~ /inet (.*?)\/(.*?) /)
		{
			my $ip   = $1;
			my $cidr = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip, cidr => $cidr }});
			
			my $subnet_mask = $cidr;
			if (($cidr =~ /^\d{1,2}$/) && ($cidr >= 0) && ($cidr <= 32))
			{
				# Convert to subnet mask
				$subnet_mask = $anvil->Convert->cidr({cidr => $cidr});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { subnet_mask => $subnet_mask }});
			}
			
			$anvil->data->{network}{$host}{interface}{$in_iface}{ip}          = $ip;
			$anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask} = $subnet_mask;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:network::${host}::interface::${in_iface}::ip"          => $anvil->data->{network}{$host}{interface}{$in_iface}{ip},
				"s2:network::${host}::interface::${in_iface}::subnet_mask" => $anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask},
			}});
		}
		if ($line =~ /ether (.*?) /i)
		{
			my $mac_address = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac_address => $mac_address }});
			
			# Wireless interfaces have a 'permaddr' that is stable. The MAC address shown by 'ether' changes constantly, for some odd reason.
			if ($line =~ /permaddr (.*)$/)
			{
				$mac_address = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac_address => $mac_address }});
			}
			
			$anvil->data->{network}{$host}{interface}{$in_iface}{mac_address} = $mac_address;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${in_iface}::mac_address" => $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address},
			}});
			
			# If this is a bond or bridge, don't record the MAC address. It confuses things as 
			# they show the MAC of the active interface. If this is an interface, see if the file
			# '/sys/class/net/<nic>/bonding_slave/perm_hwaddr' exists and, if so, read the MAC 
			# address from there. If not, read the MAC address from
			# '/sys/class/net/<nic>/address'. 
			my $shell_call = 'IFACE='.$in_iface.'
if [ -e "/sys/class/net/${IFACE}/bridge" ];  
then 
    echo bridge;
elif [ -e "/proc/net/bonding/${IFACE}" ];
then 
    echo bond; 
else 
    ethtool -P ${IFACE}
fi';
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			if ($is_local)
			{
				# Local call.
				($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:output'      => $output,
					's2:return_code' => $return_code, 
				}});
			}
			else
			{
				# Remote call
				($output, my $error, my $return_code) = $anvil->Remote->call({
					debug       => $debug, 
					shell_call  => $shell_call,
					target      => $target,
					user        => $remote_user, 
					password    => $password,
					remote_user => $remote_user, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:output'      => $output,
					's2:error'       => $error,
					's3:return_code' => $return_code, 
				}});
			}
			foreach my $line (split/\n/, $output)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
				if ($line =~ /^.*: (\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)$/)
				{
					my $real_mac                                                         = $1;
					   $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address} = $real_mac;
					
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"network::${host}::interface::${in_iface}::mac_address" => $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address},
					}});
					
					# Make it easy to look up an interface name based on a given MAC 
					# address.
					$anvil->data->{network}{$host}{mac_address}{$real_mac}{interface} = $in_iface;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"network::${host}::mac_address::${real_mac}::interface" => $anvil->data->{network}{$host}{mac_address}{$real_mac}{interface},
					}});
				}
			}
		}
		if ($line =~ /mtu (\d+) /i)
		{
			my $mtu                                                      = $1;
			   $anvil->data->{network}{$host}{interface}{$in_iface}{mtu} = $mtu;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${in_iface}::mtu" => $anvil->data->{network}{$host}{interface}{$in_iface}{mtu},
			}});
		}
	}
	
	# Read the config files for the interfaces we've found. Use 'ls' to find the interface files. Then 
	# we'll read them all in.
	$shell_call = $anvil->data->{path}{exe}{ls}." ".$anvil->data->{path}{directories}{ifcfg};
	$output     = "";
	if ($is_local)
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	else
	{
		# Remote call
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call,
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:error'       => $error,
			's3:return_code' => $return_code, 
		}});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		next if $line !~ /^ifcfg-/;
		
		my $full_path = $anvil->data->{path}{directories}{ifcfg}."/".$line;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { full_path => $full_path }});
		
		my $file_body = $anvil->Storage->read_file({
			debug       => $debug, 
			file        => $full_path,
			target      => $target,
			password    => $password, 
			port        => $port,
			remote_user => $remote_user,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:full_path" => $full_path,
			"s2:file_body" => $file_body, 
		}});
		
		# Break it apart and store any variables.
		my $temp      = {};
		my $interface = "";
		foreach my $line (split/\n/, $file_body)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			next if $line =~ /^#/;
			if ($line =~ /(.*?)=(.*)/)
			{
				my $variable          =  $1;
				my $value             =  $2;
				   $value             =~ s/^"(.*)"$/$1/;
				   $temp->{$variable} =  $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "temp->{$variable}" => $temp->{$variable} }});
				
				if (uc($variable) eq "DEVICE")
				{
					# If this isn't a device we saw in 'ip addr', skip it by just not setting the interface variable
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
					last if not exists $anvil->data->{network}{$host}{interface}{$value};
					
					$interface = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
				}
			}
			
			if ($interface)
			{
				$anvil->data->{network}{$host}{interface}{$interface}{file} = $full_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"network::${host}::interface::${interface}::file" => $anvil->data->{network}{$host}{interface}{$interface}{file},
				}});
				foreach my $variable (sort {$a cmp $b} keys %{$temp})
				{
					$anvil->data->{network}{$host}{interface}{$interface}{variable}{$variable} = $temp->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"network::${host}::interface::${interface}::file::variable::${variable}" => $anvil->data->{network}{$host}{interface}{$interface}{variable}{$variable},
					}});
				}
			}
		}
	}
	
	# Get the routing info.
	my $lowest_metric   = 99999999;
	my $route_interface = "";
	my $route_ip        = "";
	   $shell_call      = $anvil->data->{path}{exe}{ip}." route show";
	   $output          = "";
	if ($is_local)
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	else
	{
		# Remote call
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call,
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:error'       => $error,
			's3:return_code' => $return_code, 
		}});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /default via (.*?) dev (.*?) proto .*? metric (\d+)/i)
		{
			my $this_ip        = $1;
			my $this_interface = $2;
			my $metric         = $3;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:this_ip'        => $this_ip,
				's2:this_interface' => $this_interface, 
				's3:metric'         => $metric, 
				's4:lowest_metric'  => $lowest_metric, 
			}});
			
			if ($metric < $lowest_metric)
			{
				$lowest_metric   = $metric;
				$route_interface = $this_interface;
				$route_ip        = $this_ip;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					lowest_metric   => $lowest_metric,
					route_interface => $route_interface, 
					route_ip        => $route_ip, 
				}});
			}
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		route_interface => $route_interface, 
		route_ip        => $route_ip, 
	}});
	
	# If I got a route, get the DNS.
	if ($route_interface)
	{
		# I want to build the DNS list from only the interface that is used for routing.
		my $in_interface = "";
		my $dns_list     = "";
		my $dns_hash     = {};
		my $shell_call   = $anvil->data->{path}{exe}{nmcli}." dev show";
		my $output       = "";
		if ($is_local)
		{
			# Local call.
			($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:output'      => $output,
				's2:return_code' => $return_code, 
			}});
		}
		else
		{
			# Remote call
			($output, my $error, my $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call,
				target      => $target,
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:output'      => $output,
				's2:error'       => $error,
				's3:return_code' => $return_code, 
			}});
		}
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /GENERAL.DEVICE:\s+(.*)$/)
			{
				$in_interface = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_interface => $in_interface }});
			}
			if (not $line)
			{
				$in_interface = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_interface => $in_interface }});
			}
			
			next if $in_interface ne $route_interface;
			
			if ($line =~ /IP4.DNS\[(\d+)\]:\s+(.*)/i)
			{
				my $order = $1;
				my $ip    = $2;
				
				$dns_hash->{$order} = $ip;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "dns_hash->{$order}" => $dns_hash->{$order} }});
			}
		}
		
		foreach my $order (sort {$a cmp $b} keys %{$dns_hash})
		{
			$dns_list .= $dns_hash->{$order}.", ";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:dns_hash->{$order}" => $dns_hash->{$order}, 
				"s2:dns_list"           => $dns_list, 
			}});
		}
		$dns_list =~ s/, $//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { dns_list => $dns_list }});
		
		$anvil->data->{network}{$host}{interface}{$route_interface}{default_gateway} = 1;
		$anvil->data->{network}{$host}{interface}{$route_interface}{gateway}         = $route_ip;
		$anvil->data->{network}{$host}{interface}{$route_interface}{dns}             = $dns_list;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${host}::interface::${route_interface}::default_gateway" => $anvil->data->{network}{$host}{interface}{$route_interface}{default_gateway}, 
			"network::${host}::interface::${route_interface}::gateway"         => $anvil->data->{network}{$host}{interface}{$route_interface}{gateway}, 
			"network::${host}::interface::${route_interface}::dns"             => $anvil->data->{network}{$host}{interface}{$route_interface}{dns}, 
		}});
	}
	
	return(0);
}

=head2 get_network

This takes an IP address and subnet and returns the network it belongs too. For example;

 my $network = $anvil->Network->get_network({ip => "10.2.4.1", subnet_mask => "255.255.0.0"});

This would set C<< $network >> to C<< 10.2.0.0 >>.

If the network can't be caluclated for any reason, and empty string will be returned.

Parameters;

=head3 ip (required)

This is the IPv4 IP address being calculated.

=head3 subnet_mask (required)

This is the subnet mask of the IP address being calculated.

=cut
sub get_network
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->get_network()" }});
	
	my $network     = "";
	my $ip          = defined $parameter->{ip}          ? $parameter->{ip}          : "";
	my $subnet_mask = defined $parameter->{subnet_mask} ? $parameter->{subnet_mask} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ip          => $ip,
		subnet_mask => $subnet_mask,
	}});
	
	if (not $ip)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->get_network()", parameter => "ip" }});
		return("");
	}
	if (not $subnet_mask)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->get_network()", parameter => "subnet_mask" }});
		return("");
	}
	
	my $block = Net::Netmask->new($ip."/".$subnet_mask);
	my $base  = $block->base();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { base => $base }});
	
	if ($anvil->Validate->ipv4({ip => $base}))
	{
		$network = $base;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network => $network }});
	}
	
	return($network);
}


=head2 is_local

This method takes a host name or IP address and looks to see if it matches the local system. If it does, it returns C<< 1 >>. Otherwise it returns C<< 0 >>.

Parameters;

=head3 host (required)

This is the host name (or IP address) to check against the local system.

=cut
### NOTE: Do not log in here, it will cause a recursive loop!
sub is_local
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $host = $parameter->{host} ? $parameter->{host} : "";
	return(1) if not $host;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host => $host,
	}});
	
	# If we've checked this host before, return the cached answer
	if (exists $anvil->data->{cache}{is_local}{$host})
	{
		return($anvil->data->{cache}{is_local}{$host});
	}
	
	$anvil->data->{cache}{is_local}{$host} = 0;
	if (($host eq $anvil->Get->host_name)       or 
	    ($host eq $anvil->Get->short_host_name) or 
	    ($host eq "localhost")              or 
	    ($host eq "127.0.0.1"))
	{
		# It's local
		$anvil->data->{cache}{is_local}{$host} = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::is_local::${host}" => $anvil->data->{cache}{is_local}{$host} }});
	}
	else
	{
		# Get the list of current IPs and see if they match.
		my $local_host = $anvil->Get->short_host_name();
		if (not exists $anvil->data->{network}{$local_host}{interface})
		{
			$anvil->Network->get_ips({debug => 9999});
		}
		foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$local_host}{interface}})
		{
			next if not defined $anvil->data->{network}{$local_host}{interface}{$interface}{ip};
			if ($host eq $anvil->data->{network}{$local_host}{interface}{$interface}{ip})
			{
				$anvil->data->{cache}{is_local}{$host} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::is_local::${host}" => $anvil->data->{cache}{is_local}{$host} }});
				last;
			}
		}
	}
	
	#$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
	return($anvil->data->{cache}{is_local}{$host});
}


=head2 is_our_interface

This method takes an interface name and returns C<< 1 >> if the interface is one of the ones we manage (A C<< BCN >>, C<< IFN >>, C<< SN >> or C<< MN >> interface). If not, C<< 0 >> is returned.

Parameters;

=head3 interface (required)

This is the name of the interface being evaluated.

=cut
sub is_our_interface
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->is_our_interface()" }});
	
	my $interface = $parameter->{interface} ? $parameter->{interface} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		interface => $interface,
	}});
	
	if (not $interface)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->is_our_interface()", parameter => "interface" }});
		return(0);
	}
	
	my $ours = 0;
	if (($interface =~ /^bcn/i) or 
	    ($interface =~ /^sn/i)  or 
	    ($interface =~ /^ifn/i) or 
	    ($interface =~ /^mn/i))
	{
		$ours = 1;
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ours => $ours }});
	return($ours);
}

=head2 is_ip_in_network

This takes an IP address, along with network and subnet mask and sees if the IP address is within the network. If it is, it returns C<< 1 >>. If the IP address doesn't match the network, C<< 0 >> is returned.

Parameters

=head3 ip (required)

This is the ip IP address being analyzed.

=head3 network (required)

This is the IP address that will be paired with the subnet mask to see if the ip matches.

=head3 subnet_mask (required)

This is the subnet mask paired against the IP address used to check the ip against.

=cut
sub is_ip_in_network
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->is_ip_in_network()" }});
	
	my $ip          = defined $parameter->{ip}          ? $parameter->{ip}          : "";
	my $network     = defined $parameter->{network}     ? $parameter->{network}     : "";
	my $subnet_mask = defined $parameter->{subnet_mask} ? $parameter->{subnet_mask} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ip          => $ip, 
		network     => $network,
		subnet_mask => $subnet_mask,
	}});
	
	if (not $network)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->is_ip_in_network()", parameter => "network" }});
		return(0);
	}
	elsif (not $anvil->Validate->ipv4({ip => $network}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0019", variables => { parameter => "network", network => $network }});
		return(0);
	}
	if (not $ip)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->is_ip_in_network()", parameter => "ip" }});
		return(0);
	}
	elsif (not $anvil->Validate->ipv4({ip => $ip}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0019", variables => { parameter => "ip", network => $ip }});
		return(0);
	}
	if (not $subnet_mask)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->is_ip_in_network()", parameter => "subnet_mask" }});
		return(0);
	}
	elsif (not $anvil->Validate->subnet_mask({subnet_mask => $subnet_mask}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0020", variables => { parameter => "subnet_mask", subnet_mask => $subnet_mask }});
		return(0);
	}
	
	my $match = 0;
	my $block = Net::Netmask->new($network."/".$subnet_mask);
	if ($block->match($ip))
	{
		# This is a match!
		$match = 1;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { match => $match }});
	return($match);
}


=head2 load_interfces

This loads all network information for the given host UUID.

The main difference from C<< ->load_ips() >> is that this method loads information about all interfaces, regardless of if they have an IP, as well as their link state and link information.

The loaded data will be stored as:

* C<< machine::<target>::interface::<iface_name>::

Parameters;

=head3 clear (optional, default '1')

When set, any previously known information is cleared. Specifically, the C<< network::<target>> >> hash is deleted prior to the load. To prevent this, set this to C<< 0 >>.

=head3 host (optional, default is 'host_uuid' value)

This is the optional C<< target >> string to use in the hash where the data is stored.

=head3 host_uuid (optional, default 'sys::host_uuid')

This is the C<< host_uuid >> of the hosts whose IP and interface data that you want to load. The default is to load the local machine's data.

=cut
sub load_interfces
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->load_interfces()" }});
	
	my $clear     = defined $parameter->{clear}     ? $parameter->{clear}     : 1;
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->data->{sys}{host_uuid};
	my $host      = defined $parameter->{host}      ? $parameter->{host}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		clear     => $clear, 
		host      => $host, 
		host_uuid => $host_uuid,
	}});
	
	if (not $host_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->load_interfces()", parameter => "host_uuid" }});
		return("");
	}
	
	if (not $host)
	{
		$host = $host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	}
	
	if (($clear) && (exists $anvil->data->{network}{$host}))
	{
		delete $anvil->data->{network}{$host};
	}
	
	# Now load bridge info
	my $query = "
SELECT 
    bridge_uuid, 
    bridge_name, 
    bridge_id, 
    bridge_mac_address, 
    bridge_mtu, 
    bridge_stp_enabled 
FROM 
    bridges 
WHERE 
    bridge_id != 'DELETED' 
AND 
    bridge_host_uuid = ".$anvil->Database->quote($host_uuid)." 
;";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		my $bridge_uuid        = defined $row->[0] ? $row->[0] : "";
		my $bridge_name        = defined $row->[1] ? $row->[1] : ""; 
		my $bridge_id          = defined $row->[2] ? $row->[2] : ""; 
		my $bridge_mac_address = defined $row->[3] ? $row->[3] : ""; 
		my $bridge_mtu         = defined $row->[4] ? $row->[4] : ""; 
		my $bridge_stp_enabled = defined $row->[5] ? $row->[5] : ""; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			bridge_uuid        => $bridge_uuid, 
			bridge_name        => $bridge_name, 
			bridge_id          => $bridge_id, 
			bridge_mac_address => $bridge_mac_address, 
			bridge_mtu         => $bridge_mtu, 
			bridge_stp_enabled => $bridge_stp_enabled, 
		}});
		
		# Record the bridge_uuid -> name
		$anvil->data->{network}{$host}{bridge_uuid}{$bridge_uuid}{name} = $bridge_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${host}::bridge_uuid::${bridge_uuid}::name" => $anvil->data->{network}{$host}{bridge_uuid}{$bridge_uuid}{name}, 
		}});
		
		# We'll initially load empty strings for what would be the IP information. Any interface with IPs will be populated when we call 
		$anvil->data->{network}{$host}{interface}{$bridge_name}{uuid}        = $bridge_uuid; 
		$anvil->data->{network}{$host}{interface}{$bridge_name}{id}          = $bridge_id; 
		$anvil->data->{network}{$host}{interface}{$bridge_name}{mac_address} = $bridge_mac_address; 
		$anvil->data->{network}{$host}{interface}{$bridge_name}{mtu}         = $bridge_mtu; 
		$anvil->data->{network}{$host}{interface}{$bridge_name}{stp_enabled} = $bridge_stp_enabled; 
		$anvil->data->{network}{$host}{interface}{$bridge_name}{type}        = "bridge";
		$anvil->data->{network}{$host}{interface}{$bridge_name}{interfaces}  = [];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${host}::interface::${bridge_name}::uuid"        => $anvil->data->{network}{$host}{interface}{$bridge_name}{uuid}, 
			"network::${host}::interface::${bridge_name}::id"          => $anvil->data->{network}{$host}{interface}{$bridge_name}{id}, 
			"network::${host}::interface::${bridge_name}::mac_address" => $anvil->data->{network}{$host}{interface}{$bridge_name}{mac_address}, 
			"network::${host}::interface::${bridge_name}::mtu"         => $anvil->data->{network}{$host}{interface}{$bridge_name}{mtu}, 
			"network::${host}::interface::${bridge_name}::stp_enabled" => $anvil->data->{network}{$host}{interface}{$bridge_name}{stp_enabled}, 
			"network::${host}::interface::${bridge_name}::type"        => $anvil->data->{network}{$host}{interface}{$bridge_name}{type}, 
		}});
	}
	
	# Now load bond info
	$query = "
SELECT 
    bond_uuid, 
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
    bonds WHERE bond_mode != 'DELETED' 
AND 
    bond_host_uuid = ".$anvil->Database->quote($host_uuid)." 
;";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		my $bond_uuid                 = defined $row->[0]  ? $row->[0]  : "";
		my $bond_name                 = defined $row->[1]  ? $row->[1]  : ""; 
		my $bond_mode                 = defined $row->[2]  ? $row->[2]  : ""; 
		my $bond_mtu                  = defined $row->[3]  ? $row->[3]  : ""; 
		my $bond_primary_interface    = defined $row->[4]  ? $row->[4]  : ""; 
		my $bond_primary_reselect     = defined $row->[5]  ? $row->[5]  : ""; 
		my $bond_active_interface     = defined $row->[6]  ? $row->[6]  : ""; 
		my $bond_mii_polling_interval = defined $row->[7]  ? $row->[7]  : ""; 
		my $bond_up_delay             = defined $row->[8]  ? $row->[8]  : ""; 
		my $bond_down_delay           = defined $row->[9]  ? $row->[9]  : ""; 
		my $bond_mac_address          = defined $row->[10] ? $row->[10] : ""; 
		my $bond_operational          = defined $row->[11] ? $row->[11] : ""; 
		my $bond_bridge_uuid          = defined $row->[12] ? $row->[12] : ""; 
		my $bridge_name               = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			bond_uuid                 => $bond_uuid,
			bond_name                 => $bond_name,
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
		
		# If this bond is connected to a bridge, get the bridge name.
		if (($bond_bridge_uuid) && (defined $anvil->data->{network}{$host}{bridge_uuid}{$bond_bridge_uuid}{name}))
		{
			$bridge_name = $anvil->data->{network}{$host}{bridge_uuid}{$bond_bridge_uuid}{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				bond_bridge_uuid => $bond_bridge_uuid, 
				bridge_name     => $bridge_name,
			}});
			push @{$anvil->data->{network}{$host}{interface}{$bridge_name}{interfaces}}, $bond_name;
		}
		
		# Record the bond_uuid -> name
		$anvil->data->{network}{$host}{bond_uuid}{$bond_uuid}{name} = $bond_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${host}::bond_uuid::${bond_uuid}::name" => $anvil->data->{network}{$host}{bond_uuid}{$bond_uuid}{name}, 
		}});
		
		# We'll initially load empty strings for what would be the IP information. Any interface with IPs will be populated when we call 
		$anvil->data->{network}{$host}{interface}{$bond_name}{uuid}                 = $bond_uuid; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{mode}                 = $bond_mode; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{mtu}                  = $bond_mtu; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{primary_interface}    = $bond_primary_interface; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{primary_reselect}     = $bond_primary_reselect; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{active_interface}     = $bond_active_interface; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{mii_polling_interval} = $bond_mii_polling_interval; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{up_delay}             = $bond_up_delay; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{down_delay}           = $bond_down_delay; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{mac_address}          = $bond_mac_address; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{operational}          = $bond_operational; 
		$anvil->data->{network}{$host}{interface}{$bond_name}{bridge_uuid}          = $bond_bridge_uuid;
		$anvil->data->{network}{$host}{interface}{$bond_name}{type}                 = "bond";
		$anvil->data->{network}{$host}{interface}{$bond_name}{interfaces}           = [];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${host}::interface::${bond_name}::uuid"                 => $anvil->data->{network}{$host}{interface}{$bond_name}{uuid}, 
			"network::${host}::interface::${bond_name}::mode"                 => $anvil->data->{network}{$host}{interface}{$bond_name}{mode}, 
			"network::${host}::interface::${bond_name}::mtu"                  => $anvil->data->{network}{$host}{interface}{$bond_name}{mtu}, 
			"network::${host}::interface::${bond_name}::primary_interface"    => $anvil->data->{network}{$host}{interface}{$bond_name}{primary_interface}, 
			"network::${host}::interface::${bond_name}::primary_reselect"     => $anvil->data->{network}{$host}{interface}{$bond_name}{primary_reselect}, 
			"network::${host}::interface::${bond_name}::active_interface"     => $anvil->data->{network}{$host}{interface}{$bond_name}{active_interface}, 
			"network::${host}::interface::${bond_name}::mii_polling_interval" => $anvil->data->{network}{$host}{interface}{$bond_name}{mii_polling_interval}, 
			"network::${host}::interface::${bond_name}::up_delay"             => $anvil->data->{network}{$host}{interface}{$bond_name}{up_delay}, 
			"network::${host}::interface::${bond_name}::down_delay"           => $anvil->data->{network}{$host}{interface}{$bond_name}{down_delay}, 
			"network::${host}::interface::${bond_name}::mac_address"          => $anvil->data->{network}{$host}{interface}{$bond_name}{mac_address}, 
			"network::${host}::interface::${bond_name}::operational"          => $anvil->data->{network}{$host}{interface}{$bond_name}{operational}, 
			"network::${host}::interface::${bond_name}::bridge_uuid"          => $anvil->data->{network}{$host}{interface}{$bond_name}{bridge_uuid}, 
			"network::${host}::interface::${bond_name}::type"                 => $anvil->data->{network}{$host}{interface}{$bond_name}{type}, 
		}});
	}
	
	# The order will allow us to show the order in which the interfaces were changed, which the user can 
	# use to track interfaces as they unplug and plug cables back in.
	my $order = 1;
	   $query = "
SELECT 
    network_interface_uuid, 
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
    network_interface_operational != 'DELETED' 
AND 
    network_interface_host_uuid   =  ".$anvil->Database->quote($host_uuid)." 
ORDER BY 
    modified_date DESC 
;";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	$count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	my $changed_order = 1;
	foreach my $row (@{$results})
	{
		my $network_interface_uuid        = defined $row->[0]  ? $row->[0]  : "";
		my $network_interface_mac_address = defined $row->[1]  ? $row->[1]  : ""; 
		my $network_interface_name        = defined $row->[2]  ? $row->[2]  : ""; 
		my $network_interface_speed       = defined $row->[3]  ? $row->[3]  : ""; 
		my $network_interface_mtu         = defined $row->[4]  ? $row->[4]  : ""; 
		my $network_interface_link_state  = defined $row->[5]  ? $row->[5]  : ""; 
		my $network_interface_operational = defined $row->[6]  ? $row->[6]  : ""; 
		my $network_interface_duplex      = defined $row->[7]  ? $row->[7]  : ""; 
		my $network_interface_medium      = defined $row->[8]  ? $row->[8]  : ""; 
		my $network_interface_bond_uuid   = defined $row->[9]  ? $row->[9]  : ""; 
		my $network_interface_bridge_uuid = defined $row->[10] ? $row->[10] : ""; 
		my $bond_name                     = "";
		my $bridge_name                   = "";
		my $this_change_orger             = 0;
		if (($network_interface_name =~ /^virbr/) or ($network_interface_name =~ /^vnet/))
		{
			# This isn't a physical NIC, so it doesn't get a changed order
		}
		else
		{
			$this_change_orger = $changed_order++;
		}
		if (($network_interface_bond_uuid) && (defined $anvil->data->{network}{$host}{bond_uuid}{$network_interface_bond_uuid}{name}))
		{
			$bond_name = $anvil->data->{network}{$host}{bond_uuid}{$network_interface_bond_uuid}{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				network_interface_name => $network_interface_name, 
				bond_name              => $bond_name,
			}});
			push @{$anvil->data->{network}{$host}{interface}{$bond_name}{interfaces}}, $network_interface_name;
		}
		if (($network_interface_bridge_uuid) && (defined $anvil->data->{network}{$host}{bridge_uuid}{$network_interface_bridge_uuid}{name}))
		{
			$bridge_name = $anvil->data->{network}{$host}{bridge_uuid}{$network_interface_bridge_uuid}{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				network_interface_name => $network_interface_name, 
				bridge_name            => $bridge_name,
			}});
			push @{$anvil->data->{network}{$host}{interface}{$bridge_name}{interfaces}}, $network_interface_name;
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			network_interface_uuid        => $network_interface_uuid, 
			network_interface_mac_address => $network_interface_mac_address, 
			network_interface_name        => $network_interface_name, 
			network_interface_speed       => $network_interface_speed, 
			network_interface_mtu         => $network_interface_mtu, 
			network_interface_link_state  => $network_interface_link_state, 
			network_interface_operational => $network_interface_operational, 
			network_interface_duplex      => $network_interface_duplex, 
			network_interface_medium      => $network_interface_medium, 
			network_interface_bond_uuid   => $network_interface_bond_uuid, 
			network_interface_bridge_uuid => $network_interface_bridge_uuid, 
			bond_name                     => $bond_name, 
			changed_order                 => $this_change_orger,
		}});
		
		# We'll initially load empty strings for what would be the IP information. Any interface with IPs will be populated when we call 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{uuid}          = $network_interface_uuid; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{mac_address}   = $network_interface_mac_address; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{speed}         = $network_interface_speed; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{mtu}           = $network_interface_mtu; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{link_state}    = $network_interface_link_state; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{operational}   = $network_interface_operational; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{duplex}        = $network_interface_duplex; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{medium}        = $network_interface_medium; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{bond_uuid}     = $network_interface_bond_uuid; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{bond_name}     = $bond_name; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{bridge_uuid}   = $network_interface_bridge_uuid; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{bridge_name}   = $bridge_name; 
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{type}          = "interface";
		$anvil->data->{network}{$host}{interface}{$network_interface_name}{changed_order} = $this_change_orger;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${host}::interface::${network_interface_name}::uuid"          => $anvil->data->{network}{$host}{interface}{$network_interface_name}{uuid}, 
			"network::${host}::interface::${network_interface_name}::mac_address"   => $anvil->data->{network}{$host}{interface}{$network_interface_name}{mac_address}, 
			"network::${host}::interface::${network_interface_name}::speed"         => $anvil->data->{network}{$host}{interface}{$network_interface_name}{speed}, 
			"network::${host}::interface::${network_interface_name}::mtu"           => $anvil->data->{network}{$host}{interface}{$network_interface_name}{mtu}, 
			"network::${host}::interface::${network_interface_name}::link_state"    => $anvil->data->{network}{$host}{interface}{$network_interface_name}{link_state}, 
			"network::${host}::interface::${network_interface_name}::operational"   => $anvil->data->{network}{$host}{interface}{$network_interface_name}{operational}, 
			"network::${host}::interface::${network_interface_name}::duplex"        => $anvil->data->{network}{$host}{interface}{$network_interface_name}{duplex}, 
			"network::${host}::interface::${network_interface_name}::medium"        => $anvil->data->{network}{$host}{interface}{$network_interface_name}{medium}, 
			"network::${host}::interface::${network_interface_name}::bond_uuid"     => $anvil->data->{network}{$host}{interface}{$network_interface_name}{bond_uuid}, 
			"network::${host}::interface::${network_interface_name}::bond_name"     => $anvil->data->{network}{$host}{interface}{$network_interface_name}{bond_name}, 
			"network::${host}::interface::${network_interface_name}::bridge_uuid"   => $anvil->data->{network}{$host}{interface}{$network_interface_name}{bridge_uuid}, 
			"network::${host}::interface::${network_interface_name}::bridge_name"   => $anvil->data->{network}{$host}{interface}{$network_interface_name}{bridge_name}, 
			"network::${host}::interface::${network_interface_name}::type"          => $anvil->data->{network}{$host}{interface}{$network_interface_name}{type}, 
			"network::${host}::interface::${network_interface_name}::changed_order" => $anvil->data->{network}{$host}{interface}{$network_interface_name}{changed_order}, 
		}});
	}
	
	# Load the IPs
	$anvil->Network->load_ips({
		debug     => $debug,
		host_uuid => $host_uuid,
		host      => $host, 
		clear     => 0,
	});
	
	return(0);
}


=head2 load_ips

This method loads and stores the same data as the C<< get_ips >> method, but does so by loading data from the database, instead of collecting it directly from the host. As such, it can also be used by C<< find_matches >>.

C<< Note >>: IP addresses that have been deleted will be marked so by C<< ip >> being set to C<< DELETED >>.

The loaded data will be stored as:

* C<< network::<host>::interface::<iface_name>::ip >>              - If an IP address is set
* C<< network::<host>::interface::<iface_name>::subnet_mask >>     - If an IP is set
* C<< network::<host>::interface::<iface_name>::mac >>             - Always set.
* C<< network::<host>::interface::<iface_name>::default_gateway >> = C<< 0 >> if not the default gateway, C<< 1 >> if so.
* C<< network::<host>::interface::<iface_name>::gateway >>         = If the default gateway, this is the gateway IP address.
* C<< network::<host>::interface::<iface_name>::dns >>             = If the default gateway, this is the comma-separated list of active DNS servers.

Parameters;

=head3 clear (optional, default '1')

When set, any previously known information is cleared. Specifically, the C<< network::<host>> >> hash is deleted prior to the load. To prevent this, set this to C<< 0 >>.

=head3 host (optional, default is 'host_uuid' value)

This is the optional C<< host >> string to use in the hash where the data is stored.

=head3 host_uuid (optional, default 'sys::host_uuid')

This is the C<< host_uuid >> of the hosts whose IP and interface data that you want to load. The default is to load the local machine's data.

=cut
sub load_ips
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->load_ips()" }});
	
	my $clear     = defined $parameter->{clear}     ? $parameter->{clear}     : 1;
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "";
	my $host      = defined $parameter->{host}      ? $parameter->{host}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		clear     => $clear, 
		host      => $host, 
		host_uuid => $host_uuid,
	}});
	
	if (not $host_uuid)
	{
		$host_uuid = $anvil->Get->host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	}
	
	if (not $host)
	{
		$host = $host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	}
	
	if (($clear) && (exists $anvil->data->{network}{$host}))
	{
		delete $anvil->data->{network}{$host};
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0700", variables => { hash => "network::${host}" }});
	}
	
	# Read in all IPs, so that we know which to remove.
	my $query = "
SELECT 
    ip_address_address, 
    ip_address_subnet_mask, 
    ip_address_gateway, 
    ip_address_default_gateway, 
    ip_address_dns, 
    ip_address_on_type, 
    ip_address_on_uuid 
FROM 
    ip_addresses 
WHERE 
    ip_address_host_uuid =  ".$anvil->Database->quote($host_uuid)." 
AND 
    ip_address_note      != 'DELETED'
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
		my $ip_address_address         = $row->[0]; 
		my $ip_address_subnet_mask     = $row->[1]; 
		my $ip_address_gateway         = $row->[2]; 
		my $ip_address_default_gateway = $row->[3]; 
		my $ip_address_dns             = $row->[4]; 
		my $ip_address_on_type         = $row->[5]; 
		my $ip_address_on_uuid         = $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			ip_address_address         => $ip_address_address,
			ip_address_subnet_mask     => $ip_address_subnet_mask,
			ip_address_gateway         => $ip_address_gateway,
			ip_address_default_gateway => $ip_address_default_gateway,
			ip_address_dns             => $ip_address_dns,
			ip_address_on_type         => $ip_address_on_type,
			ip_address_on_uuid         => $ip_address_on_uuid,
		}});
		
		my $device_type_with_ip    = $ip_address_on_type;
		my $bridge_name            = "";
		my $bond_name              = "";
		my $interface_name         = "";
		my $interface_mac          = "";
		my $network_interface_uuid = "";
		if ($ip_address_on_type eq "interface")
		{
			$network_interface_uuid = $ip_address_on_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_interface_uuid => $network_interface_uuid }});
		}
		else
		{
			my $query = "";
			if ($ip_address_on_type eq "bridge")
			{
				# What's the bridge UUID?
				$query = "SELECT bond_name, bond_active_interface FROM bonds WHERE bond_bridge_uuid = ".$anvil->Database->quote($ip_address_on_uuid).";";
				
				# Get the bridge name, also.
				if (1)
				{
					my $query       = "SELECT bridge_name FROM bridges WHERE bridge_uuid = ".$anvil->Database->quote($ip_address_on_uuid).";";
					   $bridge_name = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { bridge_name => $bridge_name }});
				}
			}
			else
			{
				$query = "SELECT bond_name, bond_active_interface FROM bonds WHERE bond_uuid = ".$anvil->Database->quote($ip_address_on_uuid).";";
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			my $results          = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
			   $bond_name        = $results->[0]->[0];
			my $active_interface = $results->[0]->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				bond_name        => $bond_name, 
				active_interface => $active_interface,
			}});
			
			if ($active_interface)
			{
				my $query = "SELECT network_interface_uuid FROM network_interfaces WHERE network_interface_host_uuid = ".$anvil->Database->quote($host_uuid)." AND network_interface_name = ".$anvil->Database->quote($active_interface).";";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
				
				$network_interface_uuid = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_interface => $active_interface }});
			}
		}
		
		my $device_name_with_ip = "";
		if ($ip_address_on_type eq "bridge")
		{
			$device_name_with_ip = $bridge_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device_name_with_ip => $device_name_with_ip }});
		}
		elsif ($ip_address_on_type eq "bond")
		{
			$device_name_with_ip = $bond_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device_name_with_ip => $device_name_with_ip }});
		}
		
		if ($network_interface_uuid)
		{
			my $query = "
SELECT 
    network_interface_uuid, 
    network_interface_name, 
    network_interface_mac_address, 
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
    network_interface_uuid        =  ".$anvil->Database->quote($network_interface_uuid)."
AND 
    network_interface_operational != 'DELETED'
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			next if not $count;
			
			$interface_name = $results->[0]->[1];
			$interface_mac  = $results->[0]->[2];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				interface_name => $interface_name, 
				interface_mac  => $interface_mac, 
			}});
			
			$anvil->data->{network}{$host}{interface}{$interface_name}{network_interface_uuid} =         $results->[0]->[0];
			$anvil->data->{network}{$host}{interface}{$interface_name}{mac_address}            =         $interface_mac;
			$anvil->data->{network}{$host}{interface}{$interface_name}{ip}                     =         $ip_address_address;
			$anvil->data->{network}{$host}{interface}{$interface_name}{subnet_mask}            =         $ip_address_subnet_mask;
			$anvil->data->{network}{$host}{interface}{$interface_name}{default_gateway}        =         $ip_address_default_gateway;
			$anvil->data->{network}{$host}{interface}{$interface_name}{gateway}                =         $ip_address_gateway;
			$anvil->data->{network}{$host}{interface}{$interface_name}{dns}                    =         $ip_address_dns;
			$anvil->data->{network}{$host}{interface}{$interface_name}{type}                   =         "interface";
			$anvil->data->{network}{$host}{interface}{$interface_name}{speed}                  =         $results->[0]->[3];
			$anvil->data->{network}{$host}{interface}{$interface_name}{mtu}                    =         $results->[0]->[4];
			$anvil->data->{network}{$host}{interface}{$interface_name}{link_state}             =         $results->[0]->[5];
			$anvil->data->{network}{$host}{interface}{$interface_name}{operational}            =         $results->[0]->[6];
			$anvil->data->{network}{$host}{interface}{$interface_name}{duplex}                 =         $results->[0]->[7];
			$anvil->data->{network}{$host}{interface}{$interface_name}{medium}                 =         $results->[0]->[8];
			$anvil->data->{network}{$host}{interface}{$interface_name}{bond_uuid}              = defined $results->[0]->[9]  ? $results->[0]->[9]  : "";
			$anvil->data->{network}{$host}{interface}{$interface_name}{bridge_uuid}            = defined $results->[0]->[10] ? $results->[0]->[10] : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${interface_name}::network_interface_uuid" => $anvil->data->{network}{$host}{interface}{$interface_name}{network_interface_uuid}, 
				"network::${host}::interface::${interface_name}::mac_address"            => $anvil->data->{network}{$host}{interface}{$interface_name}{mac_address}, 
				"network::${host}::interface::${interface_name}::ip"                     => $anvil->data->{network}{$host}{interface}{$interface_name}{ip}, 
				"network::${host}::interface::${interface_name}::subnet_mask"            => $anvil->data->{network}{$host}{interface}{$interface_name}{subnet_mask}, 
				"network::${host}::interface::${interface_name}::default_gateway"        => $anvil->data->{network}{$host}{interface}{$interface_name}{default_gateway}, 
				"network::${host}::interface::${interface_name}::gateway"                => $anvil->data->{network}{$host}{interface}{$interface_name}{gateway}, 
				"network::${host}::interface::${interface_name}::dns"                    => $anvil->data->{network}{$host}{interface}{$interface_name}{dns}, 
				"network::${host}::interface::${interface_name}::type"                   => $anvil->data->{network}{$host}{interface}{$interface_name}{type}, 
				"network::${host}::interface::${interface_name}::speed"                  => $anvil->data->{network}{$host}{interface}{$interface_name}{speed}, 
				"network::${host}::interface::${interface_name}::mtu"                    => $anvil->data->{network}{$host}{interface}{$interface_name}{mtu}, 
				"network::${host}::interface::${interface_name}::link_state"             => $anvil->data->{network}{$host}{interface}{$interface_name}{link_state}, 
				"network::${host}::interface::${interface_name}::operational"            => $anvil->data->{network}{$host}{interface}{$interface_name}{operational}, 
				"network::${host}::interface::${interface_name}::duplex"                 => $anvil->data->{network}{$host}{interface}{$interface_name}{duplex}, 
				"network::${host}::interface::${interface_name}::medium"                 => $anvil->data->{network}{$host}{interface}{$interface_name}{medium}, 
				"network::${host}::interface::${interface_name}::bond_uuid"              => $anvil->data->{network}{$host}{interface}{$interface_name}{bond_uuid}, 
				"network::${host}::interface::${interface_name}::bridge_uuid"            => $anvil->data->{network}{$host}{interface}{$interface_name}{bridge_uuid}, 
			}});
			
			if (not $device_name_with_ip)
			{
				$device_name_with_ip = $interface_name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device_name_with_ip => $device_name_with_ip }});
			}
		}
		elsif ($ip_address_on_type eq "bond")
		{
			my $query = "
SELECT 
    bond_name, 
    bond_mac_address 
FROM 
    bonds 
WHERE 
    bond_uuid        =  ".$anvil->Database->quote($ip_address_on_uuid)."
AND 
    bond_operational != 'DELETED'
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			next if not $count;
			
			$interface_name = $results->[0]->[0];
			$interface_mac  = $results->[0]->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				interface_name => $interface_name, 
				interface_mac  => $interface_mac, 
			}});
			
			$anvil->data->{network}{$host}{interface}{$interface_name}{mac_address}     = $interface_mac;
			$anvil->data->{network}{$host}{interface}{$interface_name}{ip}              = $ip_address_address;
			$anvil->data->{network}{$host}{interface}{$interface_name}{subnet_mask}     = $ip_address_subnet_mask;
			$anvil->data->{network}{$host}{interface}{$interface_name}{default_gateway} = $ip_address_default_gateway;
			$anvil->data->{network}{$host}{interface}{$interface_name}{gateway}         = $ip_address_gateway;
			$anvil->data->{network}{$host}{interface}{$interface_name}{dns}             = $ip_address_dns;
			$anvil->data->{network}{$host}{interface}{$interface_name}{type}            = $ip_address_on_type;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${interface_name}::mac_address"     => $anvil->data->{network}{$host}{interface}{$interface_name}{mac_address}, 
				"network::${host}::interface::${interface_name}::ip"              => $anvil->data->{network}{$host}{interface}{$interface_name}{ip}, 
				"network::${host}::interface::${interface_name}::subnet_mask"     => $anvil->data->{network}{$host}{interface}{$interface_name}{subnet_mask}, 
				"network::${host}::interface::${interface_name}::default_gateway" => $anvil->data->{network}{$host}{interface}{$interface_name}{default_gateway}, 
				"network::${host}::interface::${interface_name}::gateway"         => $anvil->data->{network}{$host}{interface}{$interface_name}{gateway}, 
				"network::${host}::interface::${interface_name}::dns"             => $anvil->data->{network}{$host}{interface}{$interface_name}{dns}, 
				"network::${host}::interface::${interface_name}::type"            => $anvil->data->{network}{$host}{interface}{$interface_name}{type}, 
			}});
		}
		elsif ($ip_address_on_type eq "bridge")
		{
			my $query = "
SELECT 
    bridge_name, 
    bridge_mac_address 
FROM 
    bridges 
WHERE 
    bridge_uuid =  ".$anvil->Database->quote($ip_address_on_uuid)."
AND 
    bridge_id   != 'DELETED'
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			next if not $count;
			
			$interface_name = $results->[0]->[0];
			$interface_mac  = $results->[0]->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				interface_name => $interface_name, 
				interface_mac  => $interface_mac, 
			}});
			
			$anvil->data->{network}{$host}{interface}{$interface_name}{mac_address}     = $interface_mac;
			$anvil->data->{network}{$host}{interface}{$interface_name}{ip}              = $ip_address_address;
			$anvil->data->{network}{$host}{interface}{$interface_name}{subnet_mask}     = $ip_address_subnet_mask;
			$anvil->data->{network}{$host}{interface}{$interface_name}{default_gateway} = $ip_address_default_gateway;
			$anvil->data->{network}{$host}{interface}{$interface_name}{gateway}         = $ip_address_gateway;
			$anvil->data->{network}{$host}{interface}{$interface_name}{dns}             = $ip_address_dns;
			$anvil->data->{network}{$host}{interface}{$interface_name}{type}            = $ip_address_on_type;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${interface_name}::mac_address"     => $anvil->data->{network}{$host}{interface}{$interface_name}{mac_address}, 
				"network::${host}::interface::${interface_name}::ip"              => $anvil->data->{network}{$host}{interface}{$interface_name}{ip}, 
				"network::${host}::interface::${interface_name}::subnet_mask"     => $anvil->data->{network}{$host}{interface}{$interface_name}{subnet_mask}, 
				"network::${host}::interface::${interface_name}::default_gateway" => $anvil->data->{network}{$host}{interface}{$interface_name}{default_gateway}, 
				"network::${host}::interface::${interface_name}::gateway"         => $anvil->data->{network}{$host}{interface}{$interface_name}{gateway}, 
				"network::${host}::interface::${interface_name}::dns"             => $anvil->data->{network}{$host}{interface}{$interface_name}{dns}, 
				"network::${host}::interface::${interface_name}::type"            => $anvil->data->{network}{$host}{interface}{$interface_name}{type}, 
			}});
		}
	}
	
	return(0);
}



=head2 manage_firewall

B<< NOTE >>: So far, only C<< check >> is implemented.

This method manages a C<< firewalld >> firewall.

If no parameters are passed, it works by determining what should be open, making sure those things are open, and closing anything open that shouldn't be. 

If the firewall is off, C<< 1 >> is returned. Otherwise C<< 0 >> is returned, unless there was an error in which case C<< !!error!! >> is returned.

When called with C<< task = check >>, and if a port is specified, then C<< 1 >> will be returned if the port is open and C<< 0 >> if it is closed.

Parameters;

=head3 task (optional, default 'check')

If set to C<< open >>, it will open the corresponding C<< port >>. If set to C<< close >>, it will close the corresponding C<< port >>. If set to c<< check >>, then it depends on is a port is given. If not, the full configuration is checked, and updated to the firewall are made as needed. If a port (and optionally zone and/or protocol) is specified, that specific request is checked. 

The default is C<< all >>, which checks the entire configuration, updating the active configuration as needed.

=head3 port_number (required)

This is the port number to work on.

If not specified, C<< service >> is required.

=head3 protocol (optional, required if 'port' set)

This can be c<< tcp >> or C<< upd >> and is used to specify what protocol to use with the C<< port >>, when specified. Multiple protocols can be defined using comma-separated list. Example, C<< tcp,udp >>.

=head3 zone (optional)

If set to a zone name, the check/change is performed against the specific zone. Multiple zones can be specified using comma-separated list. Example, C<< BCN1 >>, or C<< BCN1,IFN1 >>.

=cut
sub manage_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->manage_firewall()" }});
	
	my $task        = defined $parameter->{task}        ? $parameter->{task}        : "check";
	my $port_number = defined $parameter->{port_number} ? $parameter->{port_number} : "";
	my $protocol    = defined $parameter->{protocol}    ? $parameter->{protocol}    : "";
	my $zone        = defined $parameter->{zone}        ? $parameter->{zone}        : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		task        => $task,
		port_number => $port_number,
		protocol    => $protocol, 
		zone        => $zone
	}});
	
	### TODO: Remove when fixed.
	my $firewalld_running = $anvil->System->check_daemon({daemon => $anvil->data->{sys}{daemon}{firewalld}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { firewalld_running => $firewalld_running }});
	if ($firewalld_running)
	{
		# Disable and stop.
		$anvil->System->disable_daemon({
			now    => 1, 
			daemon => $anvil->data->{sys}{daemon}{firewalld},
		});
	}
	
	return(0);
	
	# Before we do anything, is the firewall even running?
# 	my $firewalld_running = $anvil->Network->check_firewall({debug => $debug});
# 	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { firewalld_running => $firewalld_running }});
# 	if (not $firewalld_running)
# 	{
# 		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, key => "log_0669"});
# 		return(1);
# 	}
	
	# What we do next depends on what we're doing. 
	my $host_type = $anvil->Get->host_type;
	my $host_name = $anvil->Get->short_host_name;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_type => $host_type,
		host_name => $host_name, 
	}});
	$anvil->Network->get_ips({target => $host_name});
	if (($task eq "check") && ($port_number eq ""))
	{
		### Check everything.
		my $reload = 0;
		
		# Check the base firewalld config.
		my $changes = $anvil->Network->_check_firewalld_conf({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
		if ($changes eq "1")
		{
			$reload = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
		}
		
		# Get a list of zones and the interfaces already in them.
		$anvil->Network->_get_existing_zone_interfaces({debug => $debug});
		
		# What zones do we need, and what zones do we have?
		foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$host_name}{interface}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface}});
			next if not $anvil->data->{network}{$host_name}{interface}{$interface}{ip};
			my $ip_address      = $anvil->data->{network}{$host_name}{interface}{$interface}{ip};
			my $subnet_mask     = $anvil->data->{network}{$host_name}{interface}{$interface}{subnet_mask};
			my $default_gateway = $anvil->data->{network}{$host_name}{interface}{$interface}{default_gateway};
			my $zone            = uc(($interface =~ /^(.*?)_/)[0]);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				ip_address      => $ip_address,
				subnet_mask     => $subnet_mask, 
				default_gateway => $default_gateway, 
				zone            => $zone,
			}});
			
			$anvil->data->{firewalld}{zones}{$zone}{needed}            = 1;
			$anvil->data->{firewalld}{zones}{$zone}{have}              = 0;
			$anvil->data->{firewalld}{zones}{$zone}{short_description} = "";
			$anvil->data->{firewalld}{zones}{$zone}{long_description}  = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"firewalld::zones::${zone}::needed" => $anvil->data->{firewalld}{zones}{$zone}{needed},
			}});
		}
		
		# What zones do we have?
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"path::directories::firewalld_zones_etc" => $anvil->data->{path}{directories}{firewalld_zones_etc},
		}});
		local(*DIRECTORY);
		opendir(DIRECTORY, $anvil->data->{path}{directories}{firewalld_zones_etc});
		while(my $file = readdir(DIRECTORY))
		{
			next if $file !~ /\.xml$/;
			my $full_path =  $anvil->data->{path}{directories}{firewalld_zones_etc}."/".$file;
			   $full_path =~ s/\/\//\//g; 
			my $zone      =  ($file =~ /(.*)\.xml$/)[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				file      => $file, 
				full_path => $full_path,
				zone      => $zone,
			}});
			
			if (not exists $anvil->data->{firewalld}{zones}{$zone})
			{
				$anvil->data->{firewalld}{zones}{$zone}{needed} = 0;
			}
			$anvil->data->{firewalld}{zones}{$zone}{have} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"firewalld::zones::${zone}::have"   => $anvil->data->{firewalld}{zones}{$zone}{have},
				"firewalld::zones::${zone}::needed" => $anvil->data->{firewalld}{zones}{$zone}{needed},
			}});
			
			my $file_body = $anvil->Storage->read_file({
				debug      => $debug, 
				file       => $full_path,
				force_read => 1,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
			local $@;
			my $dom = eval { XML::LibXML->load_xml(string => $file_body); };
			if ($@)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0146", variables => { 
					file  => $full_path, 
					body  => $file_body,
					error => $@,
				}});
			}
			else
			{
				foreach my $element ($dom->findnodes('/zone'))
				{
					$anvil->data->{firewalld}{zones}{$zone}{short_description} = $element->findvalue('./short')       ? $element->findvalue('./short')       : "--";
					$anvil->data->{firewalld}{zones}{$zone}{long_description}  = $element->findvalue('./description') ? $element->findvalue('./description') : "--";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"firewalld::zones::${zone}::short_description" => $anvil->data->{firewalld}{zones}{$zone}{short_description},
						"firewalld::zones::${zone}::long_description"  => $anvil->data->{firewalld}{zones}{$zone}{long_description},
					}});
				}
				foreach my $service ($dom->findnodes('/zone/service'))
 				{
 					my $service_name = $service->{name};
					$anvil->data->{firewalld}{zones}{$zone}{service}{$service_name}{opened} = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"firewalld::zones::${zone}::service::${service_name}::opened" => $anvil->data->{firewalld}{zones}{$zone}{service}{$service_name}{opened},
					}});
				}
				foreach my $port ($dom->findnodes('/zone/port'))
 				{
 					my $port_number   = $port->{port};
 					my $port_protocol = $port->{protocol};
					$anvil->data->{firewalld}{zones}{$zone}{port}{$port_number}{protocol}{$port_protocol}{opened} = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"firewalld::zones::${zone}::port::${port_number}::protocol::${port_protocol}::opened" => $anvil->data->{firewalld}{zones}{$zone}{port}{$port_number}{protocol}{$port_protocol}{opened}, 
					}});
				}
			}
		}
		closedir(DIRECTORY);
		
		# Check if any zones need to be added or managed.
		foreach my $zone (sort {$a cmp $b} keys %{$anvil->data->{firewalld}{zones}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"firewalld::zones::${zone}::have"   => $anvil->data->{firewalld}{zones}{$zone}{have},
				"firewalld::zones::${zone}::needed" => $anvil->data->{firewalld}{zones}{$zone}{needed},
			}});
			
			# If this isn't a zone I need, ignore it completely. It might be something the user 
			# is doing.
			next if not $anvil->data->{firewalld}{zones}{$zone}{needed};
			
			# Is this zone one of ours?
			if (($zone !~ /^IFN/) && ($zone !~ /^BCN/) && ($zone !~ /^SN/) && ($zone !~ /^MN/))
			{
				# Not a zone we manage
				next;
			}
			
			# If the zone doesn't exist, create it. 
			if (not $anvil->data->{firewalld}{zones}{$zone}{have})
			{
				# Create the zone.
				$reload = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
				
				my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --new-zone=\"".$zone."\"";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
				
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $debug, key => "log_0708", variables => { zone => $zone }});
			}
			
			# Do any interfaces need to be added to this zone?
			foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$host_name}{interface}})
			{
				next if not $anvil->data->{network}{$host_name}{interface}{$interface}{ip};
				my $interface_zone  = uc(($interface =~ /^(.*?)_/)[0]);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					interface      => $interface,
					interface_zone => $interface_zone, 
				}});
				next if $interface_zone ne $zone;
				
				if (not exists $anvil->data->{firewall}{zone}{$zone}{interface}{$interface})
				{
					# Add it.
					$reload = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
					
					my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=\"".$zone."\" --add-interface=\"".$interface."\"";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
					my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						output      => $output,
						return_code => $return_code, 
					}});
					
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => $debug, key => "log_0709", variables => { 
						interface => $interface, 
						zone      => $zone,
					}});
				}
			}
			
			# Does the short description need to be updated?
			if ($anvil->data->{firewalld}{zones}{$zone}{short_description} ne $zone)
			{
				# Update the short description
				my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=\"".$zone."\" --set-short=\"".$zone."\"";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
			}
			
			# Does the long description need to be updated?
			my $description = "";
			my $network     = "";
			my $sequence    = 0;
			if ($zone =~ /^(.*?)(\d+)$/)
			{
				$network  = $1;
				$sequence = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					network  => $network,
					sequence => $sequence, 
				}});
				
				if ($network eq "BCN")
				{
					$description = $anvil->Words->string({key => 'message_0160'})." ".$sequence;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { description => $description }});
				}
				elsif ($network eq "SN")
				{
					$description = $anvil->Words->string({key => 'message_0161'})." ".$sequence;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { description => $description }});
				}
				elsif ($network eq "IFN")
				{
					$description = $anvil->Words->string({key => 'message_0162'})." ".$sequence;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { description => $description }});
				}
				elsif ($network eq "MN")
				{
					$description = $anvil->Words->string({key => 'message_0293'})." ".$sequence;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { description => $description }});
				}
			}
			
			if (($description) && ($anvil->data->{firewalld}{zones}{$zone}{long_description} ne $description))
			{
				my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=\"".$zone."\" --set-description=\"".$description."\"";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
			}
			
			# Now we need to decide what should be opened for each network. 
			if ($network)
			{
				# Load the ports we need to open for servers and DRBD resources.
				$anvil->Network->_get_server_ports({debug => $debug});
				$anvil->Network->_get_drbd_ports({debug => $debug});

				# Log found ports.
				foreach my $port (sort {$a <=> $b} keys %{$anvil->data->{firewall}{server}{port}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "firewall::server::port::$port" => $anvil->data->{firewall}{server}{port}{$port} }});
				}
				foreach my $port (sort {$a <=> $b} keys %{$anvil->data->{firewall}{drbd}{port}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "firewall::drbd::port::$port" => $anvil->data->{firewall}{drbd}{port}{$port} }});
				}
				
				# If we're a striker, make sure that postgresql 
				if ($host_type eq "striker")
				{
					my $changes = $anvil->Network->_manage_striker_firewall({debug => $debug, zone => $zone});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
					if ($changes)
					{
						$reload = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
					}
				}
				elsif ($host_type eq "node")
				{
					my $changes = $anvil->Network->_manage_node_firewall({debug => $debug, zone => $zone});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
					if ($changes)
					{
						$reload = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
					}
				}
				elsif ($host_type eq "dr")
				{
					my $changes = $anvil->Network->_manage_dr_firewall({debug => $debug, zone => $zone});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
					if ($changes)
					{
						$reload = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
					}
				}
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
		if ($reload)
		{
			# Reload
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0716"});
			
			my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --reload";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code, 
			}});
		}
	}
	
	return(0);
}


=head2 ping

This method will attempt to ping a target, by host name or IP, and returns C<< 1 >> if successful, and C<< 0 >> if not.

Example;

 # Test access to the internet. Allow for three attempts to account for network jitter.
 my ($pinged, $average_time) = $anvil->Network->ping({
 	ping  => "google.ca", 
 	count => 3,
 });
 
 # Test 9000-byte jumbo-frame access to a target over the BCN.
 my ($jumbo_to_peer, $average_time) = $anvil->Network->ping({
 	ping     => "an-a01n02.bcn", 
 	count    => 1, 
 	payload  => 9000, 
 	fragment => 0,
 });
 
 # Check to see if an Anvil! node has internet access
 my ($pinged, $average_time) = $anvil->Network->ping({
 	target      => "an-a01n01.alteeve.com",
 	port        => 22,
	password    => "super secret", 
	remote_user => "admin",
 	ping        => "google.ca", 
 	count       => 3,
 });

Parameters;

=head3 count (optional, default '1')

This tells the method how many time to try to ping the target. The method will return as soon as any ping attemp succeeds (unlike pinging from the command line, which always pings the requested count times).

=head3 debug (optional, default '3')

This is an optional way to alter to level at which this method is logged. Useful when the caller is trying to debug a problem. Generally this can be ignored.

=head3 fragment (optional, default '1')

When set to C<< 0 >>, the ping will fail if the packet has to be fragmented. This is meant to be used along side C<< payload >> for testing MTU sizes.

=head3 password (optional)

This is the password used to access a remote machine. This is used when pinging from a remote machine to a given ping target.

=head3 payload (optional)

This can be used to force the ping packet size to a larger number of bytes. It is most often used along side C<< fragment => 0 >> as a way to test if jumbo frames are working as expected.

B<NOTE>: The payload will have 28 bytes removed to account for ICMP overhead. So if you want to test an MTU of '9000', specify '9000' here. You do not need to account for the ICMP overhead yourself.

=head3 port (optional, default '22')

This is the port used to access a remote machine. This is used when pinging from a remote machine to a given ping target.

B<NOTE>: See C<< Remote->call >> for additional information on specifying the SSH port as part of the target.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user we will use to log into the remote machine to run the actual ping.

=head3 target (optional)

This is the host name or IP address of a remote machine that you want to run the ping on. This is used to test a remote machine's access to a given ping target.

=head3 timeout (optional, default '1')

This is how long we will wait for a ping to return, in seconds. Any real number is allowed (C<< 1 >> (one second), C<< 0.25 >> (1/4 second), etc). If set to C<< 0 >>, we will wait for the ping command to exit without limit.

=cut
sub ping
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->ping()" }});
	
# 	my $start_time = [gettimeofday];
# 	print "Start time: [".$start_time->[0].".".$start_time->[1]."]\n";
# 	
# 	my $ping_time = tv_interval ($start_time, [gettimeofday]);
# 	print "[".$ping_time."] - Pinged: [$host]\n";
	
	# If we were passed a target, try pinging from it instead of locally
	my $count       = defined $parameter->{count}       ? $parameter->{count}       : 1;	# How many times to try to ping it? Will exit as soon as one succeeds
	my $fragment    = defined $parameter->{fragment}    ? $parameter->{fragment}    : 1;	# Allow fragmented packets? Set to '0' to check MTU.
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $payload     = defined $parameter->{payload}     ? $parameter->{payload}     : 0;	# The size of the ping payload. Use when checking MTU.
	my $ping        = defined $parameter->{ping}        ? $parameter->{ping}        : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $timeout     = defined $parameter->{timeout}     ? $parameter->{timeout}     : 1;	# This sets the 'timeout' delay.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		count       => $count, 
		fragment    => $fragment, 
		payload     => $payload, 
		password    => $anvil->Log->is_secure($password),
		ping        => $ping, 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Was timeout specified as a simple integer?
	if (($timeout !~ /^\d+$/) && ($timeout !~ /^\d+\.\d+$/))
	{
		# The timeout was invalid, switch it to 1
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { timeout => $timeout }});
		$timeout = 1;
	}
	
	# If the payload was set, take 28 bytes off to account for ICMP overhead.
	if ($payload)
	{
		$payload -= 28;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { payload => $payload }});
	}
	
	# Build the call. Note that we use 'timeout' because if there is no connection and the host name is 
	# used to ping and DNS is not available, it could take upwards of 30 seconds time timeout otherwise.
	my $shell_call = "";
	if ($timeout)
	{
		$shell_call = $anvil->data->{path}{exe}{timeout}." $timeout ";
	}
	$shell_call .= $anvil->data->{path}{exe}{'ping'}." -W 1 -n ".$ping." -c 1";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	if (not $fragment)
	{
		$shell_call .= " -M do";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	}
	if ($payload)
	{
		$shell_call .= " -s $payload";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	}
	$shell_call .= " || ".$anvil->data->{path}{exe}{echo}." timeout";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my $pinged            = 0;
	my $average_ping_time = 0;
	foreach my $try (1..$count)
	{
		last if $pinged;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			count => $count, 
			try   => $try,
		}});
		
		my $output = "";
		my $error  = "";
		
		# If the 'target' is set, we'll call over SSH unless 'target' is our host name.
		my $is_local = $anvil->Network->is_local({host => $target});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			target   => $target, 
			is_local => $is_local,
		}});
		if ($is_local)
		{
			### Local calls
			($output, my $return_code) = $anvil->System->call({
				debug      => $debug, 
				shell_call => $shell_call,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
		}
		else
		{
			### Remote calls
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
			($output, $error, my $return_code) = $anvil->Remote->call({
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /(\d+) packets transmitted, (\d+) received/)
			{
				# This isn't really needed, but might help folks watching the logs.
				my $pings_sent     = $1;
				my $pings_received = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					pings_sent     => $pings_sent,
					pings_received => $pings_received, 
				}});
				
				if ($pings_received)
				{
					# Contact!
					$pinged = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pinged => $pinged }});
					last;
				}
				else
				{
					# Not yet... Sleep to give time for transient network problems to 
					# pass.
					sleep 1;
				}
			}
			if ($line =~ /min\/avg\/max\/mdev = .*?\/(.*?)\//)
			{
				$average_ping_time = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { average_ping_time => $average_ping_time }});
			}
		}
	}
	
	# 0 == Ping failed
	# 1 == Ping success
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		pinged            => $pinged,
		average_ping_time => $average_ping_time,
	}});
	return($pinged, $average_ping_time);
}

=head2 read_nmcli

This method reads and parses the C<< nmcli >> data. The data is stored as;

 nmcli::<host>::uuid::<uuid>::name
 nmcli::<host>::uuid::<uuid>::type
 nmcli::<host>::uuid::<uuid>::timestamp_unix
 nmcli::<host>::uuid::<uuid>::timestamp
 nmcli::<host>::uuid::<uuid>::autoconnect
 nmcli::<host>::uuid::<uuid>::autoconnect_priority
 nmcli::<host>::uuid::<uuid>::read_only
 nmcli::<host>::uuid::<uuid>::dbus_path
 nmcli::<host>::uuid::<uuid>::active
 nmcli::<host>::uuid::<uuid>::device
 nmcli::<host>::uuid::<uuid>::state
 nmcli::<host>::uuid::<uuid>::active_path
 nmcli::<host>::uuid::<uuid>::slave
 nmcli::<host>::uuid::<uuid>::filename

Where C<< uuid >> is the UUID of the connection. For C<< host >>, please see the parameter below. For information on what each value means, please see C<< man nmcli >>. 

For each of reference, the following to values are also stored;

 nmcli::<host>::name_to_uuid::<name>
 nmcli::<host>::device_to_uuid::<device>
 
Where C<< name >> is the value in the interface set by the C<< NAME= >> variable and C<< device >> is the interface name (as used in C<< ip >>) and as set in the C<< DEVICE= >> variable in the C<< ifcfg-X >> files.

Parameters;

=head3 host (optional, default 'target' or local short host name)

This is the hash key under which the parsed C<< nmcli >> data is stored. By default, this is C<< local >> when called locally, or it will be C<< target >> if C<< target >> is passed.

=head3 password (optional)

This is the password used to access a remote machine. This is used when reading C<< nmcli >> data on a remote system.

=head3 port (optional, default '22')

This is the port used to access a remote machine. This is used when reading C<< nmcli >> data on a remote system.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the remote user we use to log into the remote system.

=head3 target (optional)

This is the host name or IP address of a remote machine that you want to read C<< nmcli >> data from.

=cut
sub read_nmcli
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->read_nmcli()" }});
	
	# If we were passed a target, try pinging from it instead of locally
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $host        = defined $parameter->{host}        ? $parameter->{host}        : "";
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
	
	if (not $host)
	{
		$host = $target ? $target : $anvil->Get->short_host_name();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	}
	
	if (exists $anvil->data->{nmcli}{$host})
	{
		delete $anvil->data->{nmcli}{$host};
	}
	
	# Reading locally or remote?
	my $shell_call = $anvil->data->{path}{exe}{nmcli}." --colors no --terse --fields name,device,state,type,uuid,filename connection show";
	my $output     = "";
	my $is_local   = $anvil->Network->is_local({host => $target});
	if ($is_local)
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	else
	{
		# Remote call
		($output, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call,
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:error'       => $error,
			's3:return_code' => $return_code, 
		}});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'line >>' => $line }});
		
		$line =~ s/\\:/!col!/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'line <<' => $line }});
		
		my ($name, $device, $state, $type, $uuid, $filename) = (split/:/, $line);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:name'     => $name,
			's2:device'   => $device, 
			's3:state'    => $state,
			's4:type'     => $type, 
			's5:uuid'     => $uuid,
			's6:filename' => $filename, 
		}});
		if ($uuid)
		{
			# Inactive interfaces have a name but not a device;
			if (not $device)
			{
				# Read the file, see if we can find it there.
				if (-e $filename)
				{
					my $file_body = $anvil->Storage->read_file({debug => ($debug+1), file => $filename});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
					
					foreach my $line (split/\n/, $file_body)
					{
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
						$line =~ s/#.*$//;
						if ($line =~ /DEVICE=(.*)$/)
						{
							$device =  $1;
							$device =~ s/^\s+//;
							$device =~ s/\s+$//;
							$device =~ s/"(.*)"$/$1/;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device => $device }});
						}
					}
				}
				
				if (not $device)
				{
					# Odd. Well, pull the device off the file name.
					$device = ($filename =~ /\/ifcfg-(.*)$/)[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device => $device }});
				}
			}
			
			# Make it easy to look up a device's UUID by device or name.
			$anvil->data->{nmcli}{$host}{name_to_uuid}{$name}     = $uuid;
			$anvil->data->{nmcli}{$host}{device_to_uuid}{$device} = $uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"nmcli::${host}::name_to_uuid::${name}"     => $anvil->data->{nmcli}{$host}{name_to_uuid}{$name},
				"nmcli::${host}::device_to_uuid::${device}" => $anvil->data->{nmcli}{$host}{device_to_uuid}{$device}, 
			}});
			
			# Translate some values;
			my $say_state = not $state ? 0 : 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_state => $say_state }});
			
			# Now store the data
			$anvil->data->{nmcli}{$host}{uuid}{$uuid}{name}     = $name;
			$anvil->data->{nmcli}{$host}{uuid}{$uuid}{device}   = $device;
			$anvil->data->{nmcli}{$host}{uuid}{$uuid}{'state'}  = $state;
			$anvil->data->{nmcli}{$host}{uuid}{$uuid}{type}     = $type;
			$anvil->data->{nmcli}{$host}{uuid}{$uuid}{filename} = $filename;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"nmcli::${host}::uuid::${uuid}::name"     => $anvil->data->{nmcli}{$host}{uuid}{$uuid}{name},
				"nmcli::${host}::uuid::${uuid}::device"   => $anvil->data->{nmcli}{$host}{uuid}{$uuid}{device},
				"nmcli::${host}::uuid::${uuid}::state"    => $anvil->data->{nmcli}{$host}{uuid}{$uuid}{'state'},
				"nmcli::${host}::uuid::${uuid}::type"     => $anvil->data->{nmcli}{$host}{uuid}{$uuid}{type},
				"nmcli::${host}::uuid::${uuid}::filename" => $anvil->data->{nmcli}{$host}{uuid}{$uuid}{filename}, 
			}});
		}
	}
	
	return(0);
}

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

# Return '1' if changed, '0' if not changed.
sub _check_firewalld_conf
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_check_firewalld_conf()" }});
	
	# Read in the firewalld.conf file.
	my $changes            = 0;
	my $new_firewalld_conf = "";
	my $old_firewalld_conf = $anvil->Storage->read_file({
		debug      => $debug, 
		file       => $anvil->data->{path}{configs}{'firewalld.conf'},
		force_read => 1,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_firewalld_conf => $old_firewalld_conf }});
	
	# For now, the only thing we want to change is to disable 'AllowZoneDrifting'
	# * firewalld[458395]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.
	# Possible values; "yes", "no". Defaults to "yes".
	my $allowzonedrifting_seen = 0;
	foreach my $line (split/\n/, $old_firewalld_conf)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^AllowZoneDrifting=(.*)$/)
		{
			my $old_value              = $1;
			   $allowzonedrifting_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				old_value              => $old_value,
				allowzonedrifting_seen => $allowzonedrifting_seen, 
			}});
			if ($old_value ne "no")
			{
				# Change needed.
				$changes            =  1;
				$new_firewalld_conf .= "AllowZoneDrifting=no\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					changes            => $changes,
					new_firewalld_conf => $new_firewalld_conf, 
				}});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0707"});
				next;
			}
		}
		$new_firewalld_conf .= $line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_firewalld_conf => $new_firewalld_conf }});
	}
	if (not $allowzonedrifting_seen)
	{
		$new_firewalld_conf .= $anvil->Words->string({key => 'message_0292'})."\n";
		$new_firewalld_conf .= "AllowZoneDrifting=no\n";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0707"});
	}
	
	if ($changes)
	{
		# Write the file out
		$anvil->Storage->write_file({
			debug     => $debug, 
			backup    => 1,
			overwrite => 1, 
			body      => $new_firewalld_conf, 
			file      => $anvil->data->{path}{configs}{'firewalld.conf'},
			user      => "root",
			group     => "root", 
			mode      => "0644",
		});
	}
	
	return($changes);
}

sub _get_existing_zone_interfaces
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_get_existing_zone_interfaces()" }});
	
	my $this_zone  = "";
	my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --get-active-zones";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /interfaces: (.*)$/)
		{
			my $interfaces = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interfaces => $interfaces }});
			next if not $this_zone;
			
			foreach my $interface (split/\s+/, $interfaces)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
				
				$anvil->data->{firewall}{zone}{$this_zone}{interface}{$interface} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"firewall::zone::${this_zone}::interface::${interface}" => $anvil->data->{firewall}{zone}{$this_zone}{interface}{$interface},
				}});
			}
		}
		else
		{
			$this_zone = $line;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_zone => $this_zone }});
		}
	}
	
	return(0);
}

# This looks for all servers running here and stores their ports in a hash.
sub _get_server_ports
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_get_server_ports()" }});
	
	my $shell_call = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." list --name";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:output'      => $output,
		's2:return_code' => $return_code, 
	}});
	
	my $servers = [];
	foreach my $server (split/\n/, $output)
	{
		$server = $anvil->Words->clean_spaces({string => $server});
		next if not $server;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server => $server }});
		
		push @{$servers}, $server;
	}
	
	foreach my $server (sort {$a cmp $b} @{$servers})
	{
		my $shell_call = $anvil->data->{path}{exe}{setsid}." --wait ".$anvil->data->{path}{exe}{virsh}." dumpxml ".$server;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
		
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if (($line =~ /<graphics/) && ($line =~ /port='(\d+)'/))
			{
				my $port = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
				
				$anvil->data->{firewall}{server}{port}{$port} = $server;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"firewall::server::port::$port" => $anvil->data->{firewall}{server}{port}{$port},
				}});
				last;
			}
		}
	}
	
	return(0);
}

# This looks for all drbd resources configured here and stores their ports in a hash.
sub _get_drbd_ports
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_get_drbd_ports()" }});
	
	my $directory = $anvil->data->{path}{directories}{drbd_resources};
	if (not -d $directory)
	{
		# DRBD isn't installed.
		return(0);
	}
		
	local(*DIRECTORY);
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0018", variables => { directory => $directory }});
	opendir(DIRECTORY, $directory);
	while(my $file = readdir(DIRECTORY))
	{
		next if $file !~ /\.res$/;
		my $full_path =  $directory."/".$file;
		   $full_path =~ s/\/\//\//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { full_path => $full_path }});
		
		my $file_body = $anvil->Storage->read_file({debug => ($debug+1), file => $full_path});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
		
		foreach my $line (split/\n/, $file_body)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			
			if ($line =~ /host\s+.*?address.*?\s(\d.*?):(\d+);/)
			{
				my $ip   = $1;
				my $port = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:ip"   => $ip,
					"s2:port" => $port, 
				}});
				
				$anvil->data->{firewall}{drbd}{port}{$port} = $ip;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"firewall::drbd::port::$port" => $anvil->data->{firewall}{drbd}{port}{$port},
				}});
			}
		}
	}
	closedir(DIRECTORY);
	
	return(0);
}

# This looks in qemu.conf for the minimum and maximum TCP ports 
sub _get_live_migration_ports
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_get_live_migration_ports()" }});
	
	my $default_minimum = 49152;
	my $default_maximum = 49215;
	my $set_minimum     = 0;
	my $set_maximum     = 0;
	
	my $file_body = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{configs}{'qemu.conf'}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_body => $file_body }});
	foreach my $line (split/\n/, $file_body)
	{
		if (($line =~ /^#/) && ($line =~ /migration_port_min.*?=.*?(\d+)$/))
		{
			$default_minimum = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { default_minimum => $default_minimum }});
		}
		elsif (($line =~ /^#/) && ($line =~ /migration_port_max.*?=.*?(\d+)$/))
		{
			$default_maximum = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { default_maximum => $default_maximum }});
		}
		elsif ($line =~ /migration_port_min.*?=.*?(\d+)$/)
		{
			$set_minimum = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set_minimum => $set_minimum }});
		}
		elsif ($line =~ /migration_port_max.*?=.*?(\d+)$/)
		{
			$set_maximum = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set_maximum => $set_maximum }});
		}
	}
	
	if (not $set_minimum)
	{
		$set_minimum = $default_minimum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set_minimum => $set_minimum }});
	}
	if (not $set_maximum)
	{
		$set_maximum = $default_maximum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set_maximum => $set_maximum }});
	}
	
	return($set_minimum, $set_maximum);
}

sub _manage_port
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_manage_port()" }});
	
	my $port     = defined $parameter->{port}     ? $parameter->{port}     : "";
	my $protocol = defined $parameter->{protocol} ? $parameter->{protocol} : "";
	my $task     = defined $parameter->{task}     ? $parameter->{task}     : "";
	my $zone     = defined $parameter->{zone}     ? $parameter->{zone}     : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		port     => $port, 
		protocol => $protocol, 
		task     => $task, 
		zone     => $zone, 
	}});
	
	if ((not $port) or (not $protocol) or (not $task) or (not $zone))
	{
		return("!!error!!");
	}
	if (($task ne "close") && ($task ne "open"))
	{
		return("!!error!!");
	}
	if (($protocol ne "tcp") && ($protocol ne "udp"))
	{
		return("!!error!!");
	}
	if ($port =~ /^(\d+)-(\d+)$/)
	{
		my $minimum_port = $1;
		my $maximum_port = $2;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:minimum_port" => $minimum_port, 
			"s2:maximum_port" => $maximum_port, 
		}});
		
		if (($minimum_port < 1) or ($minimum_port > 66635) or 
		    ($maximum_port < 1) or ($maximum_port > 66635))
		{
			return("!!error!!");
		}
	}
	elsif (($port =~ /\D/) or ($port < 1) or ($port > 65535))
	{
		return("!!error!!");
	}
	
	# Do we need to actually do this?
	if ($task eq "close")
	{
		# Is it open?
		if ((not exists $anvil->data->{firewalld}{zones}{$zone}{port}{$port}{protocol}{$protocol}) or 
		    (not $anvil->data->{firewalld}{zones}{$zone}{port}{$port}{protocol}{$protocol}{opened}))
		{
			# Already closed.
			return(0);
		}
	}
	elsif ($anvil->data->{firewalld}{zones}{$zone}{port}{$port}{protocol}{$protocol}{opened})
	{
		# Already opened.
		return(0);
	}
	
	my $shell_call = "";
	if ($task eq "close")
	{
		$shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=".$zone." --remove-port=".$port."/".$protocol;
		if ($port =~ /-/)
		{
			# Range
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0715", variables => { 
				port     => $port, 
				protocol => $protocol, 
				zone     => $zone, 
			}});
		}
		else
		{
			# Single port
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0714", variables => { 
				port     => $port, 
				protocol => $protocol, 
				zone     => $zone, 
			}});
		}
	}
	else
	{
		$shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=".$zone." --add-port=".$port."/".$protocol;
		if ($port =~ /-/)
		{
			# Range
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0713", variables => { 
				port     => $port, 
				protocol => $protocol, 
				zone     => $zone, 
			}});
		}
		else
		{
			# Single port
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0712", variables => { 
				port     => $port, 
				protocol => $protocol, 
				zone     => $zone, 
			}});
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'output'      => $output,
		'return_code' => $return_code, 
	}});
	
	return(1);
}

# Returns '0' if nothing was done, '1' otherwise.
sub _manage_service
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_manage_service()" }});
	
	my $service = defined $parameter->{service} ? $parameter->{service} : "";
	my $task    = defined $parameter->{task}    ? $parameter->{task}    : "";
	my $zone    = defined $parameter->{zone}    ? $parameter->{zone}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		service => $service, 
		task    => $task, 
		zone    => $zone, 
	}});
	
	if ((not $service) or (not $task) or (not $zone))
	{
		return("!!error!!");
	}
	if (($task ne "close") && ($task ne "open"))
	{
		return("!!error!!");
	}
	
	# Do we actually need to do something?
	if ($task eq "close")
	{
		# Is it open?
		if ((not exists $anvil->data->{firewalld}{zones}{$zone}{service}{$service}) or 
		    (not $anvil->data->{firewalld}{zones}{$zone}{service}{$service}{opened}))
		{
			# Already closed.
			return(0);
		}
	}
	elsif ($anvil->data->{firewalld}{zones}{$zone}{service}{$service}{opened})
	{
		# Already opened.
		return(0);
	}
	
	
	my $shell_call = "";
	if ($task eq "close")
	{
		$shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=".$zone." --remove-service=".$service;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0711", variables => { 
			service => $service, 
			zone    => $zone, 
		}});
	}
	else
	{
		$shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --zone=".$zone." --add-service=".$service;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0710", variables => { 
			service => $service, 
			zone    => $zone, 
		}});
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'output'      => $output,
		'return_code' => $return_code, 
	}});
	
	return(1);
}

sub _manage_dr_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_manage_dr_firewall()" }});
	
	my $zone = defined $parameter->{zone} ? $parameter->{zone} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		zone => $zone, 
	}});
	
	# Set the services we want opened.
	my $changes      = 0;
	my @bcn_services = ("audit", "ssh", "zabbix-agent", "zabbix-server");
	my @ifn_services = ("audit", "ssh", "zabbix-agent", "zabbix-server");
	my @sn_services  = ("ssh");	# May use as a backup corosync network later
	
	# We need to make sure that the postgresql service is open for all networks.
	if ($zone =~ /BCN/)
	{
		foreach my $service (@bcn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	if ($zone =~ /IFN/)
	{
		foreach my $service (@ifn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	
	# Open VNC/Spice/etc ports for servers/
	if (($zone =~ /BCN/) or ($zone =~ /IFN/))
	{
		foreach my $port (sort {$a cmp $b} keys %{$anvil->data->{firewall}{server}{port}})
		{
			# Make sure the port is open.
			my $chenged = $anvil->Network->_manage_port({
				debug    => $debug, 
				port     => $port, 
				protocol => "tcp", 
				task     => "open",
				zone     => $zone,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
		
		# Open up live migration ports. It's possible that DR could migrate off to a prod Anvil! 
		# post-incident.
		my ($migration_minimum, $migration_maximum) = $anvil->Network->_get_live_migration_ports({debug => $debug});
		my $range = $migration_minimum."-".$migration_maximum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:migration_minimum" => $migration_minimum,
			"s2:migration_maximum" => $migration_maximum, 
			"s3:range"             => $range, 
			"s4:zone"              => $zone, 
		}});
		
		my $chenged = $anvil->Network->_manage_port({
			debug    => $debug, 
			port     => $range, 
			protocol => "tcp", 
			task     => "open",
			zone     => $zone,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
		if ($chenged)
		{
			$changes = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
		}
	}
	
	if ($zone =~ /SN/)
	{
		foreach my $service (@sn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
		
		# Open all the ports DRBD needs.
		foreach my $port (sort {$a <=> $b} keys %{$anvil->data->{firewall}{drbd}{port}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				port => $port,
				zone => $zone,
			}});
			my $chenged = $anvil->Network->_manage_port({
				debug    => $debug, 
				port     => $port, 
				protocol => "tcp", 
				task     => "open",
				zone     => $zone,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	
	return($changes);
}

sub _manage_node_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_manage_node_firewall()" }});
	
	my $zone = defined $parameter->{zone} ? $parameter->{zone} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		zone => $zone, 
	}});
	
	# We open dhcp, tftp, and dns on the BCN for the install target feature. DNS is not currently 
	# provided, but it should be added later.
	my $changes      = 0;
	my @bcn_services = ("audit", "high-availability", "ssh", "zabbix-agent", "zabbix-server");
	my @ifn_services = ("audit", "ssh", "zabbix-agent", "zabbix-server");
	my @sn_services  = ("high-availability", "ssh");	# May use as a backup corosync network later
	my @mn_services  = ("high-availability", "ssh");	# May use as a backup corosync network later
	
	# We need to make sure that the postgresql service is open for all networks.
	if ($zone =~ /BCN/)
	{
		foreach my $service (@bcn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	if ($zone =~ /IFN/)
	{
		foreach my $service (@ifn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	
	# Open VNC/Spice/etc ports for servers/
	if (($zone =~ /BCN/) or ($zone =~ /IFN/))
	{
		foreach my $port (sort {$a cmp $b} keys %{$anvil->data->{firewall}{server}{port}})
		{
			# Make sure the port is open.
			my $chenged = $anvil->Network->_manage_port({
				debug    => $debug, 
				port     => $port, 
				protocol => "tcp", 
				task     => "open",
				zone     => $zone,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	
	if ($zone =~ /SN/)
	{
		foreach my $service (@sn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
		
		# Open all the ports DRBD needs.
		foreach my $port (sort {$a <=> $b} keys %{$anvil->data->{firewall}{drbd}{port}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				port => $port,
				zone => $zone,
			}});
			my $chenged = $anvil->Network->_manage_port({
				debug    => $debug, 
				port     => $port, 
				protocol => "tcp", 
				task     => "open",
				zone     => $zone,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	
	if ($zone =~ /MN/)
	{
		foreach my $service (@mn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			my $chenged = $anvil->Network->_manage_service({
				debug   => $debug, 
				service => $service, 
				zone    => $zone, 
				task    => "open",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
			if ($chenged)
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			}
		}
	}
	
	if (($zone =~ /BCN/) or ($zone =~ /MN/))
	{
		### TODO: Find any old instances with a different port range and remove it if needed.
		# Open up live migration ports
		my ($migration_minimum, $migration_maximum) = $anvil->Network->_get_live_migration_ports({debug => $debug});
		my $range = $migration_minimum."-".$migration_maximum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:migration_minimum" => $migration_minimum,
			"s2:migration_maximum" => $migration_maximum, 
			"s3:range"             => $range, 
			"s4:zone"              => $zone, 
		}});
		
		my $chenged = $anvil->Network->_manage_port({
			debug    => $debug, 
			port     => $range, 
			protocol => "tcp", 
			task     => "open",
			zone     => $zone,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
		if ($chenged)
		{
			$changes = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
		}
		
	}
	
	return($changes);
}

sub _manage_striker_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Network->_manage_striker_firewall()" }});
	
	my $zone = defined $parameter->{zone} ? $parameter->{zone} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		zone => $zone, 
	}});
	
	if (($zone !~ /^BCN/) && ($zone !~ /^IFN/))
	{
		# Not a zone used by striker.
		return(0);
	}
	
	# We open dhcp, tftp, and dns on the BCN for the install target feature. DNS is not currently 
	# provided, but it should be added later.
	my $changes      = 0;
	my @services     = ("audit", "http", "https", "postgresql", "ssh", "vnc-server", "zabbix-agent", "zabbix-server", "vnc-server");
	my @bcn_services = ("dhcp", "dns", "tftp");
	my @ifn_services = ();
	
	# We need to make sure that the postgresql service is open for all networks.
	if ($zone =~ /BCN/)
	{
		foreach my $service (@bcn_services)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			push @services, $service;
		}
	}
	foreach my $service (@services)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
		my $chenged = $anvil->Network->_manage_service({
			debug   => $debug, 
			service => $service, 
			zone    => $zone, 
			task    => "open",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { chenged => $chenged }});
		if ($chenged)
		{
			$changes = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
		}
	}
	
	return($changes);
}

1;

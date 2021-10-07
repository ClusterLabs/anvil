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
# check_internet
# check_network
# download
# find_matches
# find_target_ip
# get_company_from_mac
# get_ips
# get_network
# is_local
# load_interfces
# load_ips
# is_ip_in_network
# ping
# read_nmcli

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
	
	my $shell_call = $anvil->data->{path}{exe}{bridge}." -json -pretty link show";
	my $output     = "";
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
		my $bridge    = $hash_ref->{master};
		my $interface = $hash_ref->{ifname};
		my $host      = $target ? $target : $anvil->Get->short_host_name();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:bridge'    => $bridge,
			's2:interface' => $interface, 
			's3:host'      => $host,
		}});
		if ((not exists $anvil->data->{bridge}{$host}{$bridge}) or (ref($anvil->data->{bridge}{$host}{$bridge}{interfaces}) ne "ARRAY"))
		{
			$anvil->data->{bridge}{$host}{$bridge}{interfaces} = [];
			$anvil->data->{bridge}{$host}{$bridge}{found}      = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge::${host}::${bridge}::interfaces" => $anvil->data->{bridge}{$host}{$bridge}{interfaces}, 
				"bridge::${host}::${bridge}::found"      => $anvil->data->{bridge}{$host}{$bridge}{found}, 
			}});
		}
		push @{$anvil->data->{bridge}{$host}{$bridge}{interfaces}}, $interface;
		
		# Now store the rest of the data.
		foreach my $key (sort {$a cmp $b} keys %{$hash_ref})
		{
			next if $key eq "master";
			next if $key eq "ifname";
			$anvil->data->{bridge}{$host}{$bridge}{$interface}{$key} = $hash_ref->{$key};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"bridge::${host}::${bridge}::${interface}::${key}" => $anvil->data->{bridge}{$host}{$bridge}{$interface}{$key}, 
			}});
		}
	}
	
	return(0);
}


=head2 check_network

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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			"s1:bond_health::${bond}::name"             => $anvil->data->{bond_health}{$bond}{name},
			"s2:bond_health::${bond}::up"               => $anvil->data->{bond_health}{$bond}{up},
			"s3:bond_health::${bond}::configured_links" => $anvil->data->{bond_health}{$bond}{configured_links},
			"s4:bond_health::${bond}::active_links"     => $anvil->data->{bond_health}{$bond}{active_links},
			"s5:bond_health::${bond}::up_links"         => $anvil->data->{bond_health}{$bond}{up_links},
		}});
		foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{bond_health}{$bond}{interface}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		first  => $first, 
		second => $second, 
	}});
	
	if (not $first)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_matches()", parameter => "first" }});
		return("");
	}
	elsif (ref($anvil->data->{network}{$first}) ne "HASH")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0106", variables => { key => "first -> network::".$first }});
		return("");
	}
	if (not $second)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_matches()", parameter => "second" }});
		return("");
	}
	elsif (ref($anvil->data->{network}{$second}) ne "HASH")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0106", variables => { key => "second -> network::".$second }});
		return("");
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
			"network::${host}::interface::${bond_name}::bridge_uuid"          => $anvil->data->{network}{$host}{interface}{$bond_name}{bridge}, 
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
    network_interface_host_uuid = ".$anvil->Database->quote($host_uuid)." 
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
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	my $host      = defined $parameter->{host}      ? $parameter->{host}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		clear     => $clear, 
		host      => $host, 
		host_uuid => $host_uuid,
	}});
	
	if (not $host_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->load_ips()", parameter => "ip" }});
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
		
		my $interface_name = "";
		my $interface_mac  = "";
		if ($ip_address_on_type eq "interface")
		{
			my $query = "
SELECT 
    network_interface_name, 
    network_interface_mac_address 
FROM 
    network_interfaces 
WHERE 
    network_interface_uuid        =  ".$anvil->Database->quote($ip_address_on_uuid)."
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
	
	return($company);
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
		if ($line =~ /^\d+: (.*?): /)
		{
			$in_iface = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_iface => $in_iface }});
			
			$anvil->data->{network}{$host}{interface}{$in_iface}{ip}              = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{ip};
			$anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask}     = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask};
			$anvil->data->{network}{$host}{interface}{$in_iface}{mac_address}     = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address};
			$anvil->data->{network}{$host}{interface}{$in_iface}{mtu}             = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{mtu};
			$anvil->data->{network}{$host}{interface}{$in_iface}{default_gateway} = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{default_gateway};
			$anvil->data->{network}{$host}{interface}{$in_iface}{gateway}         = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{gateway};
			$anvil->data->{network}{$host}{interface}{$in_iface}{dns}             = "" if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{dns};
			$anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes}        = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{tx_bytes};
			$anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes}        = 0  if not defined $anvil->data->{network}{$host}{interface}{$in_iface}{rx_bytes};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${host}::interface::${in_iface}::ip"              => $anvil->data->{network}{$host}{interface}{$in_iface}{ip}, 
				"network::${host}::interface::${in_iface}::subnet_mask"     => $anvil->data->{network}{$host}{interface}{$in_iface}{subnet_mask}, 
				"network::${host}::interface::${in_iface}::mac_address"     => $anvil->data->{network}{$host}{interface}{$in_iface}{mac_address}, 
				"network::${host}::interface::${in_iface}::mtu"             => $anvil->data->{network}{$host}{interface}{$in_iface}{mtu}, 
				"network::${host}::interface::${in_iface}::default_gateway" => $anvil->data->{network}{$host}{interface}{$in_iface}{default_gateway}, 
				"network::${host}::interface::${in_iface}::gateway"         => $anvil->data->{network}{$host}{interface}{$in_iface}{gateway}, 
				"network::${host}::interface::${in_iface}::dns"             => $anvil->data->{network}{$host}{interface}{$in_iface}{dns}, 
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
elif [ -e "/sys/class/net/${IFACE}/bonding_slave/perm_hwaddr" ];
then 
    echo -n mac:
    cat /sys/class/net/${IFACE}/bonding_slave/perm_hwaddr;
else 
    echo -n mac:
    cat /sys/class/net/${IFACE}/address; 
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
				if ($line =~ /^mac:(.*)$/)
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
	
	my $pinged            = 0;
	my $average_ping_time = 0;
	foreach my $try (1..$count)
	{
		last if $pinged;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count, try => $try }});
		
		my $output = "";
		my $error  = "";
		
		# If the 'target' is set, we'll call over SSH unless 'target' is our host name.
		if ($anvil->Network->is_local({host => $target}))
		{
			### Local calls
			($output, my $return_code) = $anvil->System->call({shell_call => $shell_call});
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
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

1;

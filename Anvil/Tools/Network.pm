package Anvil::Tools::Network;
# 
# This module contains methods used to deal with networking stuff.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Network.pm";

### Methods;
# find_matches
# get_ips
# get_network
# is_local

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

=head2 find_matches

This takes two hash keys from prior C<< Network->get_ips() >> runs and finds which are on the same network.

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
	
	if (ref($anvil->data->{network}{$first}) ne "HASH")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_matches()", parameter => "first" }});
		return("");
	}
	if (ref($anvil->data->{network}{$second}) ne "HASH")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->find_matches()", parameter => "second" }});
		return("");
	}
	
	# Loop through the first, and on each interface with an IP/subnet, look for a match in the second.
	my $match = {};
	foreach my $first_interface (sort {$b cmp $a} keys %{$anvil->data->{network}{$first}{interface}})
	{
		my $first_ip     = $anvil->data->{network}{$first}{interface}{$first_interface}{ip};
		my $first_subnet = $anvil->data->{network}{$first}{interface}{$first_interface}{subnet};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			first           => $first,
			first_interface => $first_interface,
			first_ip        => $first_ip,
			first_subnet    => $first_subnet,  
		}});
		
		if (($first_ip) && ($first_subnet))
		{
			# Look for a match.
			my $first_network = $anvil->Network->get_network({
				debug  => $debug, 
				ip     => $first_ip, 
				subnet => $first_subnet,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { a_network => $first_network }});
			
			foreach my $second_interface (sort {$b cmp $a} keys %{$anvil->data->{network}{$second}{interface}})
			{
				my $second_ip     = $anvil->data->{network}{$second}{interface}{$second_interface}{ip};
				my $second_subnet = $anvil->data->{network}{$second}{interface}{$second_interface}{subnet};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					second           => $second,
					second_interface => $second_interface,
					second_ip        => $second_ip,
					second_subnet    => $second_subnet,  
				}});
				if (($second_ip) && ($second_subnet))
				{
					# Do we have a match?
					my $second_network = $anvil->Network->get_network({
						debug  => $debug, 
						ip     => $second_ip, 
						subnet => $second_subnet,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						a_network => $first_network,
						b_network => $second_network,
					}});
					
					if ($first_network eq $second_network)
					{
						# Match!
						$match->{$first}{$first_interface}   = $second_network;
						$match->{$second}{$second_interface} = $second_network;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"${first}::${first_interface}"   => $match->{$first}{$first_interface},
							"${second}::${second_interface}" => $match->{$second}{$second_interface},
						}});
					}
				}
			}
		}
	}
	
	return($match);
}

=head2 get_ips

This method checks the local system for interfaces and stores them in:

* C<< network::<target>::interface::<iface_name>::ip >>              - If an IP address is set
* C<< network::<target>::interface::<iface_name>::subnet >>          - If an IP is set
* C<< network::<target>::interface::<iface_name>::mac >>             - Always set.
* C<< network::<target>::interface::<iface_name>::default_gateway >> = C<< 0 >> if not the default gateway, C<< 1 >> if so.
* C<< network::<target>::interface::<iface_name>::gateway >>         = If the default gateway, this is the gateway IP address.
* C<< network::<target>::interface::<iface_name>::dns >>             = If the default gateway, this is the comma-separated list of active DNS servers.

When called without a C<< target >>, C<< local >> is used.

To aid in look-up by MAC address, C<< network::mac::<mac_address>::iface >> is also set. Note that this is not target-dependent.

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
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "local";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target,
	}});
	
	# Reading locally or remote?
	my $in_iface   = "";
	my $shell_call = $anvil->data->{path}{exe}{ip}." addr list";
	my $output     = "";
	if ($anvil->Network->is_remote($target))
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
	else
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
		}});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^\d+: (.*?): /)
		{
			$in_iface = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_iface => $in_iface }});
			
			$anvil->data->{network}{$target}{interface}{$in_iface}{ip}              = "" if not defined $anvil->data->{network}{$target}{interface}{$in_iface}{ip};
			$anvil->data->{network}{$target}{interface}{$in_iface}{subnet}          = "" if not defined $anvil->data->{network}{$target}{interface}{$in_iface}{subnet};
			$anvil->data->{network}{$target}{interface}{$in_iface}{mac}             = "" if not defined $anvil->data->{network}{$target}{interface}{$in_iface}{mac};
			$anvil->data->{network}{$target}{interface}{$in_iface}{default_gateway} = 0  if not defined $anvil->data->{network}{$target}{interface}{$in_iface}{default_gateway};
			$anvil->data->{network}{$target}{interface}{$in_iface}{gateway}         = "" if not defined $anvil->data->{network}{$target}{interface}{$in_iface}{gateway};
			$anvil->data->{network}{$target}{interface}{$in_iface}{dns}             = "" if not defined $anvil->data->{network}{$target}{interface}{$in_iface}{dns};
		}
		next if not $in_iface;
		if ($in_iface eq "lo")
		{
			# We don't care about 'lo'.
			delete $anvil->data->{network}{$target}{interface}{$in_iface};
			next;
		}
		if ($line =~ /inet (.*?)\/(.*?) /)
		{
			my $ip   = $1;
			my $cidr = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip, cidr => $cidr }});
			
			my $subnet = $cidr;
			if (($cidr =~ /^\d{1,2}$/) && ($cidr >= 0) && ($cidr <= 32))
			{
				# Convert to subnet
				$subnet = $anvil->Convert->cidr({cidr => $cidr});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { subnet => $subnet }});
			}
			
			$anvil->data->{network}{$target}{interface}{$in_iface}{ip}     = $ip;
			$anvil->data->{network}{$target}{interface}{$in_iface}{subnet} = $subnet;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:network::${target}::interface::${in_iface}::ip"     => $anvil->data->{network}{$target}{interface}{$in_iface}{ip},
				"s2:network::${target}::interface::${in_iface}::subnet" => $anvil->data->{network}{$target}{interface}{$in_iface}{subnet},
			}});
		}
		if ($line =~ /ether ([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}) /i)
		{
			my $mac                                                        = $1;
			   $anvil->data->{network}{$target}{interface}{$in_iface}{mac} = $mac;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"network::${target}::interface::${in_iface}::mac" => $anvil->data->{network}{$target}{interface}{$in_iface}{mac},
			}});
			
			# We only record the mac in 'network::mac' if this isn't a bond.
			my $test_file = "/proc/net/bonding/".$in_iface;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_file => $test_file }});
			if (not -e $test_file)
			{
				$anvil->data->{network}{mac}{$mac}{iface} = $in_iface;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"network::mac::${mac}::iface" => $anvil->data->{network}{mac}{$mac}{iface}, 
				}});
			}
		}
	}
	
	# Read the config files for the interfaces we've found. Use 'ls' to find the interface files. Then 
	# we'll read them all in.
	$shell_call = $anvil->data->{path}{exe}{ls}." ".$anvil->data->{path}{directories}{ifcfg};
	$output     = "";
	if ($anvil->Network->is_remote($target))
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
	else
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
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
				my $variable =  $1;
				my $value    =  $2;
				   $value    =~ s/^"(.*)"$/$1/;
				$temp->{$variable} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "temp->{$variable}" => $temp->{$variable} }});
				
				if (uc($variable) eq "DEVICE")
				{
					$interface = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "interface" => $interface }});
				}
			}
			
			if ($interface)
			{
				$anvil->data->{network}{$target}{interface}{$interface}{file} = $full_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"network::${target}::interface::${interface}::file" => $anvil->data->{network}{$target}{interface}{$interface}{file},
				}});
				foreach my $variable (sort {$a cmp $b} keys %{$temp})
				{
					$anvil->data->{network}{$target}{interface}{$interface}{variable}{$variable} = $temp->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"network::${target}::interface::${interface}::file::variable::${variable}" => $anvil->data->{network}{$target}{interface}{$interface}{variable}{$variable},
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
	if ($anvil->Network->is_remote($target))
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
	else
	{
		# Local call.
		($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:output'      => $output,
			's2:return_code' => $return_code, 
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
		if ($anvil->Network->is_remote($target))
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
		else
		{
			# Local call.
			($output, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:output'      => $output,
				's2:return_code' => $return_code, 
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
		
		$anvil->data->{network}{$target}{interface}{$route_interface}{default_gateway} = 1;
		$anvil->data->{network}{$target}{interface}{$route_interface}{gateway}         = $route_ip;
		$anvil->data->{network}{$target}{interface}{$route_interface}{dns}             = $dns_list;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"network::${target}::interface::${route_interface}::default_gateway" => $anvil->data->{network}{$target}{interface}{$route_interface}{default_gateway}, 
			"network::${target}::interface::${route_interface}::gateway"         => $anvil->data->{network}{$target}{interface}{$route_interface}{gateway}, 
			"network::${target}::interface::${route_interface}::dns"             => $anvil->data->{network}{$target}{interface}{$route_interface}{dns}, 
		}});
	}
	
	return(0);
}

=head2 get_network

This takes an IP address and subnet and returns the network it belongs too. For example;

 my $network = $anvil->Network->get_network({ip => "10.2.4.1", subnet => "255.255.0.0"});

This would set C<< $network >> to C<< 10.2.0.0 >>.

If the network can't be caluclated for any reason, and empty string will be returned.

Parameters;

=head3 ip (required)

This is the IPv4 IP address being calculated.

=head3 subnet (required)

This is the subnet of the IP address being calculated.

=cut
sub get_network
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $network = "";
	my $ip      = defined $parameter->{ip}     ? $parameter->{ip}     : "";
	my $subnet  = defined $parameter->{subnet} ? $parameter->{subnet} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ip     => $ip,
		subnet => $subnet,
	}});
	
	if (not $ip)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->get_network()", parameter => "ip" }});
		return("");
	}
	if (not $subnet)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Network->get_network()", parameter => "subnet" }});
		return("");
	}
	
	my $block = Net::Netmask->new($ip."/".$subnet);
	my $base  = $block->base();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { base => $base }});
	
	if ($anvil->Validate->is_ipv4({ip => $base}))
	{
		$network = $base;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network => $network }});
	}
	
	return($network);
}

=head2 is_remote

This looks at the C<< target >> and determines if it relates to the local system or not. If the C<< target >> is remote, C<< 1 >> is returned. Otherwise, C<< 0 >> is returned.

 if ($anvil->Network->is_remote($target))
 {
	# Do something remotely
 }
 else
 {
	# Do something locally
 }

B<< NOTE >>: Unlike most methods, this one does not take a hash reference for the parameters. It takes the string directly.

=cut
sub is_remote
{
	my $self   = shift;
	my $target = shift;
	my $anvil  = $self->parent;
	
	my $remote = 0;
	if (($target) && ($target ne "local") && ($target ne $anvil->_hostname) && ($target ne $anvil->_short_hostname))
	{
		# It's a remote system
		$remote = 1;
	}
	
	return($remote);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

1;

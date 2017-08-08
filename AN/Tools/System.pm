package AN::Tools::System;
# 
# This module contains methods used to handle common system tasks.
# 

use strict;
use warnings;
use Data::Dumper;
use Net::SSH2;

our $VERSION  = "3.0.0";
my $THIS_FILE = "System.pm";

### Methods;
# call
# check_daemon
# check_memory
# determine_host_type
# enable_daemon
# is_local
# manage_firewall
# ping
# read_ssh_config
# remote_call
# reload_daemon
# start_daemon
# stop_daemon

=pod

=encoding utf8

=head1 NAME

AN::Tools::System

Provides all methods related to storage on a system.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->System->X'. 
 # 
 # Example using 'system_call()';
 my $hostname = $an->System->call({shell_call => $an->data->{path}{exe}{hostname}});

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

=head2 call

This method makes a system call and returns the output (with the last new-line removed). If there is a problem, 'C<< #!error!# >>' is returned and the error will be logged.

Parameters;

=head3 line (optional)

This is the line number of the source file that called this method. Useful for logging and debugging.

=head3 secure (optional)

If set to 'C<< 1 >>', the shell call will be treated as if it contains a password or other sensitive data for logging.

=head3 shell_call (required)

This is the shell command to call.

=head3 source (optional)

This is the name of the source file calling this method. Useful for logging and debugging.

=cut
sub call
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $line       = defined $parameter->{line}       ? $parameter->{line}       : __LINE__;
	my $shell_call = defined $parameter->{shell_call} ? $parameter->{shell_call} : "";
	my $secure     = defined $parameter->{secure}     ? $parameter->{secure}     : 0;
	my $source     = defined $parameter->{source}     ? $parameter->{source}     : $THIS_FILE;
	$an->Log->variables({source => $source, line => $line, level => 3, secure => $secure, list => { shell_call => $shell_call }});
	
	my $output = "#!error!#";
	if (not $shell_call)
	{
		# wat?
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0043"});
	}
	else
	{
		# Make the system call
		$output = "";
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, secure => $secure, key => "log_0011", variables => { shell_call => $shell_call }});
		open (my $file_handle, $shell_call." 2>&1 |") or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => $secure, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			   $line =~ s/\n$//;
			   $line =~ s/\r$//;
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, secure => $secure, key => "log_0017", variables => { line => $line }});
			$output .= $line."\n";
		}
		close $file_handle;
		chomp($output);
		$output =~ s/\n$//s;
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, secure => $secure, list => { output => $output }});
	return($output);
}

=head2 check_daemon

This method checks to see if a daemon is running or not. If it is, it returns 'C<< 1 >>'. If the daemon isn't running, it returns 'C<< 0 >>'. If the daemon wasn't found, 'C<< 2 >>' is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to check.

=cut
sub check_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $return     = 2;
	my $daemon     = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	my $say_daemon = $daemon =~ /\.service$/ ? $daemon : $daemon.".service";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { daemon => $daemon, say_daemon => $say_daemon }});
	
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{systemctl}." status ".$say_daemon."; ".$an->data->{path}{exe}{'echo'}." return_code:\$?"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /return_code:(\d+)/)
		{
			my $return_code = $1;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { return_code => $return_code }});
			if ($return_code eq "3")
			{
				# Stopped
				$return = 0;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
			}
			elsif ($return_code eq "0")
			{
				# Running
				$return = 1;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
			}
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
	return($return);
}

=head2 check_memory

# Not yet written...

=cut
sub check_memory
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $program_name = defined $parameter->{program_name} ? $parameter->{program_name} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { program_name => $program_name }});
	if (not $program_name)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0086"});
		return("");
	}
	
	my $used_ram = 0;
	
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{''}." --program $program_name"});
	foreach my $line (split/\n/, $output)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
		if ($line =~ /= (\d+) /)
		{
			$used_ram = $1;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { used_ram => $used_ram }});
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { used_ram => $used_ram }});
	return($used_ram);
}

=head2 determine_host_type

This method tries to determine the host type and returns a value suitable for use is the C<< hosts >> table.

First, it looks to see if C<< sys::host_type >> is set and, if so, uses that string as it is. 

If that isn't set, it then looks at the short host name. The following rules are used, in order;

1. If the host name ends in C<< n<digits> >> or C<< node<digits> >>, C<< node >> is returned.
2. If the host name ends in C<< striker<digits> >> or C<< dashboard<digits> >>, C<< dashboard >> is returned.
3. If the host name ends in C<< dr<digits> >>, C<< dr >> is returned.

=cut
sub determine_host_type
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $host_type = "";
	my $host_name = $an->_hostname;
	   $host_type = "unknown";
	if ($an->data->{sys}{host_type})
	{
		$host_type = $an->data->{sys}{host_type};
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { host_type => $host_type }});
	}
	elsif (($host_name =~ /n\d+$/) or ($host_name =~ /node\d+$/))
	{
		$host_type = "node";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { host_type => $host_type }});
	}
	elsif (($host_name =~ /striker\d+$/) or ($host_name =~ /dashboard\d+$/))
	{
		$host_type = "dashboard";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { host_type => $host_type }});
	}
	elsif ($host_name =~ /dr\d+$/)
	{
		$host_type = "dr";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { host_type => $host_type }});
	}
	
	return($host_type);
}

=head2 enable_daemon

This method enables a daemon (so that it starts when the OS boots). The return code from the start request will be returned.

If the return code for the enable command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to enable.

=cut
sub enable_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $return     = undef;
	my $daemon     = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	my $say_daemon = $daemon =~ /\.service$/ ? $daemon : $daemon.".service";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { daemon => $daemon, say_daemon => $say_daemon }});
	
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{systemctl}." enable ".$say_daemon." 2>&1; ".$an->data->{path}{exe}{'echo'}." return_code:\$?"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { line => $line }});
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
	return($return);
}

=head2 is_local

This method takes a host name or IP address and looks to see if it matches the local system. If it does, it returns C<< 1 >>. Otherwise it returns C<< 0 >>.

Parameters;

=head3 host (required)

This is the host name (or IP address) to check against the local system.

=cut
sub is_local
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0125", variables => { method => "System->_is_local()" }});
	
	my $host = $parameter->{host} ? $parameter->{host} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { host => $host }});
	
	my $is_local = 0;
	if (($host eq $an->_hostname)       or 
	    ($host eq $an->_short_hostname) or 
	    ($host eq "localhost")          or 
	    ($host eq "127.0.0.1"))
	{
		# It's local
		$is_local = 1;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { is_local => $is_local }});
	}
	else
	{
		# Get the list of current IPs and see if they match.
		my $network = $an->Get->network_details;
		foreach my $interface (keys %{$network->{interface}})
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { "network->interface::${interface}::ip" => $network->{interface}{$interface}{ip} }});
			if ($host eq $network->{interface}{$interface}{ip})
			{
				$is_local = 1;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { is_local => $is_local }});
				last;
			}
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { is_local => $is_local }});
	return($is_local);
}

=head2 manage_firewall

This method manages a firewalld firewall.

B<NOTE>: This is pretty basic at this time. Capabilities will be added over time so please expect changes to this method.

Parameters;

=head3 task (optional)

If set to C<< open >>, it will open the corresponding C<< port >>. If set to C<< close >>, it will close the corresponding C<< port >>. If set to c<< check >>, the state of the given C<< port >> is returned.

The default is C<< check >>.

=head3 port_number (required)

This is the port number to work on.

If not specified, C<< service >> is required.

=head3 port_type (optional)

This can be c<< tcp >> or C<< upd >> and is used to specify what protocol to use with the C<< port >>, when specified. The default is C<< tcp >>.

=cut
sub manage_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $task        = defined $parameter->{task}        ? $parameter->{task}        : "check";
	my $port_number = defined $parameter->{port_number} ? $parameter->{port_number} : "";
	my $port_type   = defined $parameter->{port_type}   ? $parameter->{port_type}   : "tcp";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		task        => $task,
		port_number => $port_number,
		port_type   => $port_type, 
	}});
	
	# Make sure we have a port or service.
	if (not $port_number)
	{
		# ...
		return("!!error!!");
	}
	
	# Before we do anything, what zone is active?
	my $active_zone = "";
	if (not $active_zone)
	{
		my $shell_call = $an->data->{path}{exe}{'firewall-cmd'}." --get-active-zones";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
		
		my $output = $an->System->call({shell_call => $shell_call});
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
		foreach my $line (split/\n/, $output)
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
			if ($line !~ /\s/)
			{
				$active_zone = $line;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { active_zone => $active_zone }});
			}
			last;
		}
	}
	
	# What is the default zone?
	my $default_zone = "";
	if (not $default_zone)
	{
		my $shell_call = $an->data->{path}{exe}{'firewall-cmd'}." --get-default-zone";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
		
		my $output = $an->System->call({shell_call => $shell_call});
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
		foreach my $line (split/\n/, $output)
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
			if ($line !~ /\s/)
			{
				$default_zone = $line;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { default_zone => $default_zone }});
			}
			last;
		}
	}
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		active_zone  => $active_zone,
		default_zone => $default_zone,
	}});
	
	# If we have an active zone, see if the requested port is open.
	my $open_tcp_ports = [];
	my $open_udp_ports = [];
	my $open_services  = [];
	if ($active_zone)
	{
		my $shell_call = $an->data->{path}{exe}{'firewall-cmd'}." --zone=".$active_zone." --list-all";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
		
		my $output = $an->System->call({shell_call => $shell_call});
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
		foreach my $line (split/\n/, $output)
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
			if ($line =~ /services: (.*)$/)
			{
				my $services = $an->Words->clean_spaces({ string => $1 });
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { services => $services }});
				foreach my $service (split/\s/, $services)
				{
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { service => $service }});
					push @{$open_services}, $service;
				}
			}
			if ($line =~ /ports: (.*)$/)
			{
				my $open_ports = $an->Words->clean_spaces({ string => $1 });
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { open_ports => $open_ports }});
				foreach my $port (split/\s/, $open_ports)
				{
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
					if ($port =~ /^(\d+)\/tcp/)
					{
						my $tcp_port = $1;
						$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { tcp_port => $tcp_port }});
						push @{$open_tcp_ports}, $tcp_port;
					}
					elsif ($port =~ /^(\d+)\/udp/)
					{
						my $udp_port = $1;
						$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { udp_port => $udp_port }});
						push @{$open_udp_ports}, $udp_port;
					}
					else
					{
						# Bad port.
						return("!!error!!");
					}
				}
			}
		}
		
		# Convert services to ports.
		foreach my $service (sort @{$open_services})
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { service => $service }});
			
			my $shell_call = $an->data->{path}{exe}{'firewall-cmd'}." --info-service ".$service;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
			
			my $output   = $an->System->call({shell_call => $shell_call});
			my $port     = "";
			my $protocol = "";
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
			foreach my $line (split/\n/, $output)
			{
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
				if ($line =~ /ports: (\d+)\/(.*)$/)
				{
					$port     = $1;
					$protocol = $2;
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
						port     => $port,
						protocol => $protocol,
					}});
					if ($protocol eq "tcp")
					{
						$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
						push @{$open_tcp_ports}, $port;
					}
					elsif ($protocol eq "udp")
					{
						$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
						push @{$open_udp_ports}, $port;
					}
					else
					{
						# What?
						return("!!error!!");
					}
				}
			}
			if ((not $port) or (not $protocol))
			{
				# What?
				return("!!error!!");
			}
		}
	}
	
	# Debugging
	foreach my $open_tcp_port (sort {$a cmp $b} @{$open_tcp_ports})
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { open_tcp_port => $open_tcp_port }});
	}
	foreach my $open_udp_port (sort {$a cmp $b} @{$open_udp_ports})
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { open_udp_port => $open_udp_port }});
	}
	
	# See if the requested port is open.
	my $open = 0;
	if ($port_type eq "tcp")
	{
		foreach my $port (sort {$a cmp $b} @{$open_tcp_ports})
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
			if ($port eq $port_number)
			{
				$open = 1;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 'open' => $open }});
				last;
			}
		}
	}
	elsif ($port_type eq "udp")
	{
		foreach my $port (sort {$a cmp $b} @{$open_udp_ports})
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
			if ($port eq $port_number)
			{
				$open = 1;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 'open' => $open }});
				last;
			}
		}
	}
	else
	{
		# Bad port type
		return("!!error!!");
	}
	
	# We're done if we were just checking.
	if ($task eq "check")
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 'open' => $open }});
		return($open);
	}
	
	# If we're opening or closing, work on the active and default zones (or just the one when they're the
	# same zone)
	my $zones = $default_zone;
	if (($default_zone) && ($active_zone))
	{
		if ($default_zone ne $active_zone)
		{
			$zones = $active_zone.",".$default_zone;
		}
	}
	elsif ($default_zone)
	{
		$zones = $default_zone;
	}
	elsif ($active_zone)
	{
		$zones = $active_zone;
	}
	else
	{
		# No zones found...
		return("!!error!!");
	}
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { zones => $zones }});
	foreach my $zone (split/,/, $zones)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { zone => $zone }});
	}
	
	
	# my $zone = firewall-cmd --get-default-zone
	# firewall-cmd --zone=$zone --list-all 
	# check for 'services: ... postgresql ...' (for 5432) or 'ports: ... X ...' otherwise
	# Check 'firewall-cmd --info-service=postgresql' to nonfirm 'ports: 5432/tcp'
	
	return($open);
}

=head2 ping

This method will attempt to ping a target, by hostname or IP, and returns C<< 1 >> if successful, and C<< 0 >> if not.

Example;

 # Test access to the internet. Allow for three attempts to account for network jitter.
 my $pinged = $an->System->ping({
 	ping  => "google.ca", 
 	count => 3,
 });
 
 # Test 9000-byte jumbo-frame access to a target over the BCN.
 my $jumbo_to_peer = $an->System->ping({
 	ping     => "an-a01n02.bcn", 
 	count    => 1, 
 	payload  => 9000, 
 	fragment => 0,
 });
 
 # Check to see if an Anvil! node has internet access
 my $pinged = $an->System->ping({
 	target   => "an-a01n01.alteeve.com",
 	port     => 22,
	password => "super secret", 
 	ping     => "google.ca", 
 	count    => 3,
 });

Parameters;

=head3 count (optional, default '1')

This tells the method how many time to try to ping the target. The method will return as soon as any ping attemp succeeds (unlike pinging from the command line, which always pings the requested count times).

=head3 fragment (optional, default '1')

When set to C<< 0 >>, the ping will fail if the packet has to be fragmented. This is meant to be used along side C<< payload >> for testing MTU sizes.

=head3 password (optional)

This is the password used to access a remote machine. This is used when pinging from a remote machine to a given ping target.

=head3 payload (optional)

This can be used to force the ping packet size to a larger number of bytes. It is most often used along side C<< fragment => 0 >> as a way to test if jumbo frames are working as expected.

B<NOTE>: The payload will have 28 bytes removed to account for ICMP overhead. So if you want to test an MTU of '9000', specify '9000' here. You do not need to account for the ICMP overhead yourself.

=head3 port (optional, default '22')

This is the port used to access a remote machine. This is used when pinging from a remote machine to a given ping target.

B<NOTE>: See C<< System->remote_call >> for additional information on specifying the SSH port as part of the target.

=head3 target (optional)

This is the host name or IP address of a remote machine that you want to run the ping on. This is used to test a remote machine's access to a given ping target.

=cut
sub ping
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# If we were passed a target, try pinging from it instead of locally
	my $count    = $parameter->{count}    ? $parameter->{count}    : 1;	# How many times to try to ping it? Will exit as soon as one succeeds
	my $fragment = $parameter->{fragment} ? $parameter->{fragment} : 1;	# Allow fragmented packets? Set to '0' to check MTU.
	my $password = $parameter->{password} ? $parameter->{password} : "";
	my $payload  = $parameter->{payload}  ? $parameter->{payload}  : 0;	# The size of the ping payload. Use when checking MTU.
	my $ping     = $parameter->{ping}     ? $parameter->{ping}     : "";
	my $port     = $parameter->{port}     ? $parameter->{port}     : "";
	my $target   = $parameter->{target}   ? $parameter->{target}   : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		count    => $count, 
		fragment => $fragment, 
		payload  => $payload, 
		password => $an->Log->secure ? $password : "--",
		ping     => $ping, 
		port     => $port, 
		target   => $target, 
	}});
	
	# If the payload was set, take 28 bytes off to account for ICMP overhead.
	if ($payload)
	{
		$payload -= 28;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { payload => $payload }});
	}
	
	# Build the call. Note that we use 'timeout' because if there is no connection and the hostname is 
	# used to ping and DNS is not available, it could take upwards of 30 seconds time timeout otherwise.
	my $shell_call = $an->data->{path}{exe}{timeout}." 2 ".$an->data->{path}{exe}{'ping'}." -W 1 -n $ping -c 1";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { shell_call => $shell_call }});
	if (not $fragment)
	{
		$shell_call .= " -M do";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { shell_call => $shell_call }});
	}
	if ($payload)
	{
		$shell_call .= " -s $payload";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { shell_call => $shell_call }});
	}
	$shell_call .= " || ".$an->data->{path}{exe}{echo}." timeout";
	
	my $pinged            = 0;
	my $average_ping_time = 0;
	foreach my $try (1..$count)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { count => $count, try => $try }});
		last if $pinged;
		
		my $output = "";
		
		# If the 'target' is set, we'll call over SSH unless 'target' is 'local' or our hostname.
		if (($target) && ($target ne "local") && ($target ne $an->_hostname) && ($target ne $an->_short_hostname))
		{
			### Remote calls
			$output = $an->System->remote_call({
				shell_call => $shell_call, 
				target     => $target,
				port       => $port, 
				password   => $password,
			});
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
		}
		else
		{
			### Local calls
			$output = $an->System->call({shell_call => $shell_call});
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
		}
		
		foreach my $line (split/\n/, $output)
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { line => $line }});
			if ($line =~ /(\d+) packets transmitted, (\d+) received/)
			{
				# This isn't really needed, but might help folks watching the logs.
				my $pings_sent     = $1;
				my $pings_received = $2;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
					pings_sent     => $pings_sent,
					pings_received => $pings_received, 
				}});
				
				if ($pings_received)
				{
					# Contact!
					$pinged = 1;
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { pinged => $pinged }});
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
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { average_ping_time => $average_ping_time }});
			}
		}
	}
	
	# 0 == Ping failed
	# 1 == Ping success
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		pinged            => $pinged,
		average_ping_time => $average_ping_time,
	}});
	return($pinged, $average_ping_time);
}

=head2 read_ssh_config

This reads /etc/ssh/ssh_config and notes hosts with defined ports. When found, the associated port will be automatically used for a given host name or IP address.

Matches will have their ports stored in C<< hosts::<host_name>::port >>.

This method takes no parameters.

=cut
sub read_ssh_config
{
	my $self = shift;
	my $an   = $self->parent;
	
	# This will hold the raw contents of the file.
	my $this_host                   = "";
	   $an->data->{raw}{ssh_config} = $an->Storage->read_file({file => $an->data->{path}{configs}{ssh_config}});
	foreach my $line (split/\n/, $an->data->{raw}{ssh_config})
	{
		$line =~ s/#.*$//;
		$line =~ s/\s+$//;
		next if not $line;
		
		if ($line =~ /^host (.*)/i)
		{
			$this_host = $1;
			next;
		}
		next if not $this_host;
		if ($line =~ /port (\d+)/i)
		{
			my $port = $1;
			$an->data->{hosts}{$this_host}{port} = $port;
		}
	}
	
	return(0);
}

=head2 remote_call

This does a remote call over SSH. The connection is held open and the file handle for the target is cached and re-used unless a specific ssh_fh is passed or a request to close the connection is received. 

Example;

 # Call 'hostname' on a node.
 my ($error, $output) = $an->System->remote_call({
 	target     => "an-a01n01.alteeve.com",
 	user       => "admin",
 	password   => "super secret password",
 	shell_call => "/usr/bin/hostname",
 });
 
 # Make a call with sensitive data that you want logged only if $an->Log->secure is set and close the 
 # connection when done.
 my ($error, $output) = $an->System->remote_call({
 	target     => "an-a01n01.alteeve.com",
 	user       => "root", 
 	password   => "super secret password",
 	shell_call => "/usr/sbin/fence_ipmilan -a an-a01n02.ipmi -l admin -p \"super secret password\" -o status",
 	secure     => 1,
	close      => 1, 
 });

B<NOTE>: By default, a connection to a target will be held open and cached to increase performance for future connections. 

Parameters;

=head3 close (optional, default '0')

If set, the connection to the target will be closed at the end of the call.

=head3 no_cache (optional, default '0')

If set, and if an existing cached connection is open, it will be closed and a new connection to the target will be established.

=head3 password (optional)

This is the password used to connect to the remote target as the given user.

B<NOTE>: Passwordless SSH is supported. If you can ssh to the target as the given user without a password, then no password needs to be given here.

=head3 port (optional, default '22')

This is the TCP port to use when connecting to the C<< target >>. The default is port 22.

B<NOTE>: See C<< target >> for optional port definition.

=head3 secure (optional, default '0')

If set, the C<< shell_call >> is treated as containing sensitive data and will not be logged unless C<< $an->Log->secure >> is enabled.

=head3 shell_call (required)

This is the command to run on the target machine as the target user.

=head3 target (required)

This is the host name or IP address of the target machine that the C<< shell_call >> will be run on.

B<NOTE>: If the target matches an entry in '/etc/ssh/ssh_config', the port defined there is used. If the port is set as part of the target name, the port in 'ssh_config' is ignored.

B<NOTE>: If the C<< target >> is presented in the format C<< target:port >>, the port will be separated from the target and used as the TCP port. If the C<< port >> parameter is set, however, the port split off the C<< target >> will be ignored.

=head3 user (optional, default 'root')

This is the user account on the C<< target >> to connect as and to run the C<< shell_call >> as. The C<< password >> if so this user's account on the C<< target >>.

=cut
sub remote_call
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Get the target and port so that we can create the ssh_fh key
	my $port       = defined $parameter->{port}     ? $parameter->{port}     : 22;
	my $target     = defined $parameter->{target}   ? $parameter->{target}   : "";
	my $ssh_fh_key = $target.":".$port;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		port   => $port, 
		target => $target,
	}});
	
	# This will store the SSH file handle for the given target after the initial connection.
	$an->data->{cache}{ssh_fh}{$ssh_fh_key} = defined $an->data->{cache}{ssh_fh}{$ssh_fh_key} ? $an->data->{cache}{ssh_fh}{$ssh_fh_key} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "cache::ssh_fh::${ssh_fh_key}" => $an->data->{cache}{ssh_fh}{$ssh_fh_key} }});
	
	# Now pick up the rest of the variables.
	my $close      = defined $parameter->{'close'}    ? $parameter->{'close'}    : 0;
	my $no_cache   = defined $parameter->{no_cache}   ? $parameter->{no_cache}   : 0;
	my $password   = defined $parameter->{password}   ? $parameter->{password}   : $an->data->{sys}{root_password};
	my $secure     = defined $parameter->{secure}     ? $parameter->{secure}     : 0;
	my $shell_call = defined $parameter->{shell_call} ? $parameter->{shell_call} : "";
	my $user       = defined $parameter->{user}       ? $parameter->{user}       : "root";
	my $start_time = time;
	my $ssh_fh     = $an->data->{cache}{ssh_fh}{$ssh_fh_key};
	# NOTE: The shell call might contain sensitive data, so we show '--' if 'secure' is set and $an->Log->secure is not.
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		'close'    => $close, 
		password   => $an->Log->secure ? $password : "--", 
		secure     => $secure, 
		shell_call => ((not $an->Log->secure) && ($secure)) ? "--" : $shell_call,
		ssh_fh     => $ssh_fh,
		start_time => $start_time, 
		user       => $user,
	}});
	
	if (not $shell_call)
	{
		# No shell call
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->remote_call()", parameter => "shell_call" }});
		return("!!error!!");
	}
	if (not $target)
	{
		# No target
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->remote_call()", parameter => "target" }});
		return("!!error!!");
	}
	if (not $user)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->remote_call()", parameter => "user" }});
		return("!!error!!");
	}
	
	# If the user didn't pass a port, but there is an entry in 'hosts::<host>::port', use it.
	if ((not $parameter->{port}) && ($an->data->{hosts}{$target}{port}))
	{
		$port = $an->data->{hosts}{$target}{port};
	}
	
	# Break out the port, if needed.
	my $state;
	my $error;
	if ($target =~ /^(.*):(\d+)$/)
	{
		$target = $1;
		$port   = $2;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			port   => $port, 
			target => $target,
		}});
		
		# If the user passed a port, override this.
		if ($parameter->{port} =~ /^\d+$/)
		{
			$port = $parameter->{port};
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
		}
	}
	else
	{
		# In case the user is using ports in /etc/ssh/ssh_config, we'll want to check for an entry.
		$an->System->read_ssh_config();
		
		$an->data->{hosts}{$target}{port} = "" if not defined $an->data->{hosts}{$target}{port};
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "hosts::${target}::port" => $an->data->{hosts}{$target}{port} }});
		if ($an->data->{hosts}{$target}{port} =~ /^\d+$/)
		{
			$port = $an->data->{hosts}{$target}{port};
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { port => $port }});
		}
	}
	
	# Make sure the port is valid.
	if (($port !~ /^\d+$/) or ($port < 0) or ($port > 65536))
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0058", variables => { port => $port }});
		return("!!error!!");
	}
	
	# If the target is a host name, convert it to an IP.
	if (not $an->Validate->is_ipv4({ip => $target}))
	{
		my $new_target = $an->Convert->hostname_to_ip({host_name => $target});
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { new_target => $new_target }});
		if ($new_target)
		{
			$target = $new_target;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { target => $target }});
		}
	}
	
	# If the user set 'no_cache', don't use any existing 'ssh_fh'.
	if (($no_cache) && ($ssh_fh))
	{
		# Close the connection.
		$ssh_fh->disconnect();
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "message_0010", variables => { target => $target }});
		
		# For good measure, blank both variables.
		$an->data->{cache}{ssh_fh}{$ssh_fh_key} = "";
		$ssh_fh                                 = "";
	}
	
	# These will be merged into a single 'output' array before returning.
	my $stdout_output = [];
	my $stderr_output = [];
	
	# If I don't already have an active SSH file handle, connect now.
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { ssh_fh => $ssh_fh }});
	if ($ssh_fh !~ /^Net::SSH2/)
	{
		$ssh_fh = Net::SSH2->new();
		if (not $ssh_fh->connect($target, $port, Timeout => 10))
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", list => { 
				user       => $user,
				target     => $target, 
				port       => $port, 
				shell_call => $shell_call,
				error      => $@,
			}});
			
			# We'll now try to get a more useful message for the user and logs.
			my $message_key = "message_0005";
			my $variables   = { target => $target };
			if ($@ =~ /Bad hostname/i)
			{
				$message_key = "message_0001";
			}
			elsif ($@ =~ /Connection refused/i)
			{
				$message_key = "message_0002";
				$variables   = {
					target => $target,
					port   => $port,
					user   => $user,
				};
			}
			elsif ($@ =~ /No route to host/)
			{
				$message_key = "message_0003";
			}
			elsif ($@ =~ /timeout/)
			{
				$message_key = "message_0004";
			}
			$error = $an->Words->string({key => $message_key, variables => { $variables }});
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => $message_key, variables => { $variables }});
		}
		
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { error => $error, ssh_fh => $ssh_fh }});
		if (not $error)
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				user     => $user,
				password => $an->Log->secure ? $password : "--", 
			}});
			if (not $ssh_fh->auth_password($user, $password)) 
			{
				# Can we log in without a password?
				my $user           = getpwuid($<);
				my $home_directory = $an->Get->users_home({user => $user});
				my $public_key     = $home_directory."/.ssh/id_rsa.pub";
				my $private_key    = $home_directory."/.ssh/id_rsa";
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					user           => $user,
					home_directory => $home_directory, 
					public_key     => $public_key, 
					private_key    => $private_key,
				}});
				
				if ($ssh_fh->auth_publickey($user, $public_key, $private_key)) 
				{
					# We're in! Record the file handle for this target.
					$an->data->{cache}{ssh_fh}{$ssh_fh_key} = $ssh_fh;
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "cache::ssh_fh::${ssh_fh_key}" => $an->data->{cache}{ssh_fh}{$ssh_fh_key} }});
					
					# Log that we got in without a password.
					$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0062", variables => { target => $target }});
				}
				else
				{
					# This is for the user
					$error = $an->Words->string({key => "message_0006", variables => { target => $target }});
					$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "message_0006", variables => { target => $target }});
				}
			}
			else
			{
				# We're in! Record the file handle for this target.
				$an->data->{cache}{ssh_fh}{$ssh_fh_key} = $ssh_fh;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "cache::ssh_fh::${ssh_fh_key}" => $an->data->{cache}{ssh_fh}{$ssh_fh_key} }});
				
				# Record our success
				$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "message_0007", variables => { target => $target }});
			}
		}
	}
	
	### Special thanks to Rafael Kitover (rkitover@gmail.com), maintainer of Net::SSH2, for helping me
	### sort out the polling and data collection in this section.
	#
	# Open a channel and make the call.
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		error  => $error, 
		ssh_fh => $ssh_fh, 
	}});
	if (($ssh_fh =~ /^Net::SSH2/) && (not $error))
	{
		# We need to open a channel every time for 'exec' calls. We want to keep blocking off, but we
		# need to enable it for the channel() call.
		   $ssh_fh->blocking(1);
		my $channel = $ssh_fh->channel();
		   $ssh_fh->blocking(0);
		
		# Make the shell call
		if (not $channel)
		{
			# ... or not.
			$ssh_fh = "";
			$error  = $an->Words->string({key => "message_0008", variables => { target => $target }});
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "message_0008", variables => { target => $target }});
		}
		else
		{
			### TODO: Timeout if the call doesn't respond in X seconds, closing the filehandle if hit.
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { 
				channel    => $channel, 
				shell_call => $shell_call, 
			}});
			$channel->exec("$shell_call");
			
			# This keeps the connection open when the remote side is slow to return data, like in
			# '/etc/init.d/rgmanager stop'.
			my @poll = {
				handle => $channel,
				events => [qw/in err/],
			};
			
			# We'll store the STDOUT and STDERR data here.
			my $stdout = "";
			my $stderr = "";
			
			# Not collect the data.
			while(1)
			{
				$ssh_fh->poll(250, \@poll);
				
				# Read in anything from STDOUT
				while($channel->read(my $chunk, 80))
				{
					$stdout .= $chunk;
				}
				while ($stdout =~ s/^(.*)\n//)
				{
					my $line = $1;
					   $line =~ s/\r//g;	# Remove \r from things like output of daemon start/stops.
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { "STDOUT:line" => $line }});
					push @{$stdout_output}, $line;
				}
				
				# Read in anything from STDERR
				while($channel->read(my $chunk, 80, 1))
				{
					$stderr .= $chunk;
				}
				while ($stderr =~ s/^(.*)\n//)
				{
					my $line = $1;
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { "STDERR:line" => $line }});
					push @{$stderr_output}, $line;
				}
				
				# Exit when we get the end-of-file.
				last if $channel->eof;
			}
			if ($stdout)
			{
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { stdout => $stdout }});
				push @{$stdout_output}, $stdout;
			}
			if ($stderr)
			{
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { stderr => $stderr }});
				push @{$stderr_output}, $stderr;
			}
		}
	}
	
	# Merge the STDOUT and STDERR
	my $output = [];
	
	foreach my $line (@{$stderr_output}, @{$stdout_output})
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { line => $line }});
		push @{$output}, $line;
	}
	
	# Close the connection if requested.
	if ($close)
	{
		if ($ssh_fh)
		{
			# Close it.
			$ssh_fh->disconnect();
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "message_0009", variables => { target => $target }});
		}
		
		# For good measure, blank both variables.
		$an->data->{cache}{ssh_fh}{$ssh_fh_key} = "";
		$ssh_fh                                  = "";
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "cache::ssh_fh::${ssh_fh_key}" => $an->data->{cache}{ssh_fh}{$ssh_fh_key} }});
	}
	
	$error = "" if not defined $error;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, secure => $secure, list => { 
		error  => $error,
		ssh_fh => $ssh_fh, 
		output => $output, 
	}});
	return($error, $output);
};

=head2 reload_daemon

This method reloads a daemon (typically to pick up a change in configuration). The return code from the start request will be returned.

If the return code for the reload command wasn't read, C<< !!error!! >> is returned. If it did reload, C<< 0 >> is returned. If the reload failed, a non-0 return code will be returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to reload.

=cut
sub reload_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $return     = undef;
	my $daemon     = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	my $say_daemon = $daemon =~ /\.service$/ ? $daemon : $daemon.".service";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { daemon => $daemon, say_daemon => $say_daemon }});
	
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{systemctl}." reload ".$say_daemon."; ".$an->data->{path}{exe}{'echo'}." return_code:\$?"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 'return' => $return }});
	return($return);
}

=head2 start_daemon

This method starts a daemon. The return code from the start request will be returned.

If the return code for the start command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to start.

=cut
sub start_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $return     = undef;
	my $daemon     = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	my $say_daemon = $daemon =~ /\.service$/ ? $daemon : $daemon.".service";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { daemon => $daemon, say_daemon => $say_daemon }});
	
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{systemctl}." start ".$say_daemon."; ".$an->data->{path}{exe}{'echo'}." return_code:\$?"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { line => $line }});
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
	return($return);
}

=head2 stop_daemon

This method stops a daemon. The return code from the stop request will be returned.

If the return code for the stop command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to stop.

=cut
sub stop_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $return     = undef;
	my $daemon     = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	my $say_daemon = $daemon =~ /\.service$/ ? $daemon : $daemon.".service";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { daemon => $daemon, say_daemon => $say_daemon }});
	
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{systemctl}." stop ".$say_daemon."; ".$an->data->{path}{exe}{'echo'}." return_code:\$?"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
		}
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'return' => $return }});
	return($return);
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

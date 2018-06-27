package Anvil::Tools::Remote;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Remote.pm";

### Methods;
# add_target_to_known_hosts
# call
# _call_ssh_keyscan
# _check_known_hosts_for_target

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Remote

Provides all methods related to accessing a remote system. Currently, all methods use SSH for remote access

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Storage->X'. 
 # 
 # Example using 'find()';
 my $foo_path = $anvil->Storage->find({file => "foo"});

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

=head2 add_target_to_known_hosts

This checks the C<< user >>'s C<< ~/.ssh/known_hosts >> file for the presence of the C<< target >>'s SSH RSA fingerprint. If it isn't found, it uses C<< ssh-keyscan >> to add the host. Optionally, it can delete any existing fingerprints (useful for handling a rebuilt machine).

Returns C<< 0 >> on success, C<< 1 >> on failure.

Parameters;

=head3 delete_if_found (optional, default 0)

If set, and if a previous fingerprint was found for the C<< target >>, the old fingerprint will be removed.

B<< NOTE >>: Obviously, this introduces a possible security issue. Care needs to be taken that the key being removed is, in fact, no longer needed.

=head3 port (optional, default 22)

This is the TCP port to use when connecting to the C<< target >> over SSH.

=head3 target (required)

This is the IP address or (resolvable) host name of the machine who's key we're recording.

=head3 user (optional, defaults to user running this method)

This is the user who we're recording the key for. 

=cut
sub add_target_to_known_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $delete_if_found = defined $parameter->{delete_if_found} ? $parameter->{delete_if_found} : 0;
	my $port            = defined $parameter->{port}            ? $parameter->{port}            : 22;
	my $target          = defined $parameter->{target}          ? $parameter->{target}          : "";
	my $user            = defined $parameter->{user}            ? $parameter->{user}            : $<; 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		delete_if_found => $delete_if_found,
		port            => $port, 
		target          => $target,
		user            => $user,
	}});
	
	# Get the local user's home
	my $users_home = $anvil->Get->users_home({debug => $debug, user => $user});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { users_home => $users_home }});
	if (not $users_home)
	{
		# No sense proceeding... An error will already have been recorded.
		return(1);
	}
	
	# I'll need to make sure I've seen the fingerprint before.
	my $known_hosts = $users_home."/.ssh/known_hosts";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { known_hosts => $known_hosts }});
	
	# OK, now do we have a 'known_hosts' at all?
	my $known_machine = 0;
	if (-e $known_hosts)
	{
		# Yup, see if the target is there already,
		$known_machine = $anvil->Remote->_check_known_hosts_for_target({
			target          => $target, 
			port            => $port, 
			known_hosts     => $known_hosts, 
			user            => $user,
			delete_if_found => $delete_if_found,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { known_machine => $known_machine }});
	}
	
	# If either known_hosts didn't contain this target or simply didn't exist, add it.
	if (not $known_machine)
	{
		# We don't know about this machine yet, so scan it.
		my $added = $anvil->Remote->_call_ssh_keyscan({
			debug       => $debug, 
			target      => $target, 
			port        => $port, 
			user        => $user, 
			known_hosts => $known_hosts});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { added => $added }});
		if (not $added)
		{
			# Failed to add. :(
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0009", variables => { 
				target => $target, 
				port   => $port, 
				user   => $user, 
			}});
			return(1);
		}
	}
	
	return(0);
}

=head2 call

This does a remote call over SSH. The connection is held open and the file handle for the target is cached and re-used unless a specific ssh_fh is passed or a request to close the connection is received. 

Example;

 # Call 'hostname' on a node.
 my ($error, $output) = $anvil->Remote->call({
 	target      => "an-a01n01.alteeve.com",
 	password    => "super secret password",
 	remote_user => "admin",
 	shell_call  => "/usr/bin/hostname",
 });
 
 # Make a call with sensitive data that you want logged only if $anvil->Log->secure is set and close the 
 # connection when done.
 my ($error, $output) = $anvil->Remote->call({
 	target      => "an-a01n01.alteeve.com",
 	password    => "super secret password",
 	remote_user => "root",
 	shell_call  => "/usr/sbin/fence_ipmilan -a an-a01n02.ipmi -l admin -p \"super secret password\" -o status",
 	secure      => 1,
	'close'     => 1, 
 });

If there is any problem connecting to the target, C<< $error >> will contain a translated string explaining what went wrong. Checking if this is B<< false >> is a good way to verify that the call succeeded.

Any output from the call will be stored in C<< $output >>, which is an array reference with each output line as an array entry. STDERR and STDOUT are merged into the C<< $output >> array reference, with anything from STDERR coming first in the array.

B<NOTE>: By default, a connection to a target will be held open and cached to increase performance for future connections. 

Parameters;

=head3 close (optional, default '0')

If set, the connection to the target will be closed at the end of the call.

=head3 log_level (optional, default C<< 3 >>)

If set, the method will use the given log level. Valid values are integers between C<< 0 >> and C<< 4 >>.

=head3 no_cache (optional, default C<< 0 >>)

If set, and if an existing cached connection is open, it will be closed and a new connection to the target will be established.

=head3 password (optional)

This is the password used to connect to the remote target as the given user.

B<NOTE>: Passwordless SSH is supported. If you can ssh to the target as the given user without a password, then no password needs to be given here.

=head3 port (optional, default C<< 22 >>)

This is the TCP port to use when connecting to the C<< target >>. The default is port 22.

B<NOTE>: See C<< target >> for optional port definition.

=head3 remote_user (optional, default root)

This is the user account on the C<< target >> to connect as and to run the C<< shell_call >> as. The C<< password >> if so this user's account on the C<< target >>.

=head3 secure (optional, default C<< 0 >>)

If set, the C<< shell_call >> is treated as containing sensitive data and will not be logged unless C<< $anvil->Log->secure >> is enabled.

=head3 shell_call (required)

This is the command to run on the target machine as the target user.

=head3 target (required)

This is the host name or IP address of the target machine that the C<< shell_call >> will be run on.

B<NOTE>: If the target matches an entry in '/etc/ssh/ssh_config', the port defined there is used. If the port is set as part of the target name, the port in 'ssh_config' is ignored.

B<NOTE>: If the C<< target >> is presented in the format C<< target:port >>, the port will be separated from the target and used as the TCP port. If the C<< port >> parameter is set, however, the port split off the C<< target >> will be ignored.

=cut
sub call
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Get the target and port so that we can create the ssh_fh key
	my $log_level  = defined $parameter->{log_level} ? $parameter->{log_level} : 3;
	if (($log_level !~ /^\d$/) or ($log_level < 0) or ($log_level > 4))
	{
		# Invalid log level, set 2.
		$log_level = 3;
	}
	
	my $port       = defined $parameter->{port}   ? $parameter->{port}   : 22;
	my $target     = defined $parameter->{target} ? $parameter->{target} : "";
	my $ssh_fh_key = $target.":".$port;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
		port   => $port, 
		target => $target,
	}});
	
	# This will store the SSH file handle for the given target after the initial connection.
	$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = defined $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} ? $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { "cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} }});
	
	# Now pick up the rest of the variables.
	my $close       = defined $parameter->{'close'}     ? $parameter->{'close'}     : 0;
	my $no_cache    = defined $parameter->{no_cache}    ? $parameter->{no_cache}    : 0;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : $anvil->data->{sys}{root_password};
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : 0;
	my $shell_call  = defined $parameter->{shell_call}  ? $parameter->{shell_call}  : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $start_time  = time;
	my $ssh_fh      = $anvil->data->{cache}{ssh_fh}{$ssh_fh_key};
	# NOTE: The shell call might contain sensitive data, so we show '--' if 'secure' is set and $anvil->Log->secure is not.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
		'close'     => $close, 
		password    => $anvil->Log->secure ? $password : "#!string!log_0186!#", 
		secure      => $secure, 
		shell_call  => ((not $anvil->Log->secure) && ($secure)) ? "#!string!log_0186!#" : $shell_call,
		ssh_fh      => $ssh_fh,
		start_time  => $start_time, 
		remote_user => $remote_user,
	}});
	
	if (not $shell_call)
	{
		# No shell call
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->call()", parameter => "shell_call" }});
		return("!!error!!");
	}
	if (not $target)
	{
		# No target
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->call()", parameter => "target" }});
		return("!!error!!");
	}
	if (not $remote_user)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->call()", parameter => "remote_user" }});
		return("!!error!!");
	}
	
	# If the user didn't pass a port, but there is an entry in 'hosts::<host>::port', use it.
	if ((not $parameter->{port}) && ($anvil->data->{hosts}{$target}{port}))
	{
		$port = $anvil->data->{hosts}{$target}{port};
	}
	
	# Break out the port, if needed.
	my $state;
	my $error;
	if ($target =~ /^(.*):(\d+)$/)
	{
		$target = $1;
		$port   = $2;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
			port   => $port, 
			target => $target,
		}});
		
		# If the user passed a port, override this.
		if ($parameter->{port} =~ /^\d+$/)
		{
			$port = $parameter->{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { port => $port }});
		}
	}
	else
	{
		# In case the user is using ports in /etc/ssh/ssh_config, we'll want to check for an entry.
		$anvil->System->read_ssh_config();
		
		$anvil->data->{hosts}{$target}{port} = "" if not defined $anvil->data->{hosts}{$target}{port};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { "hosts::${target}::port" => $anvil->data->{hosts}{$target}{port} }});
		if ($anvil->data->{hosts}{$target}{port} =~ /^\d+$/)
		{
			$port = $anvil->data->{hosts}{$target}{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { port => $port }});
		}
	}
	
	# Make sure the port is valid.
	if ($port eq "")
	{
		$port = 22;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { port => $port }});
	}
	elsif ($port !~ /^\d+$/)
	{
		$port = getservbyname($port, 'tcp');
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { port => $port }});
	}
	if ((not defined $port) or (($port !~ /^\d+$/) or ($port < 0) or ($port > 65536)))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0058", variables => { port => $port }});
		return("!!error!!");
	}
	
	# If the target is a host name, convert it to an IP.
	if (not $anvil->Validate->is_ipv4({ip => $target}))
	{
		my $new_target = $anvil->Convert->hostname_to_ip({host_name => $target});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { new_target => $new_target }});
		if ($new_target)
		{
			$target = $new_target;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { target => $target }});
		}
	}
	
	# If the user set 'no_cache', don't use any existing 'ssh_fh'.
	if (($no_cache) && ($ssh_fh))
	{
		# Close the connection.
		$ssh_fh->disconnect();
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $log_level, key => "message_0010", variables => { target => $target }});
		
		# For good measure, blank both variables.
		$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = "";
		$ssh_fh                                    = "";
	}
	
	# These will be merged into a single 'output' array before returning.
	my $stdout_output = [];
	my $stderr_output = [];
	
	# If I don't already have an active SSH file handle, connect now.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { ssh_fh => $ssh_fh }});
	
	if ($ssh_fh !~ /^Net::SSH2/)
	{
		use Time::HiRes qw (usleep ualarm gettimeofday tv_interval nanosleep
                          clock_gettime clock_getres clock_nanosleep clock
                          stat);
		### NOTE: Nevermind, timeout isn't supported... >_< Find a newer version if IO::Socket::IP?
		### TODO: Make the timeout user-configurable to handle slow connections. Make it 
		###       'sys::timeout::{all|host} = x'
		my $start_time = [gettimeofday];
		$ssh_fh = Net::SSH2->new(timeout => 1000);
		if (not $ssh_fh->connect($target, $port))
		{
			
			my $connect_time = tv_interval ($start_time, [gettimeofday]);
			#print "[".$connect_time."] - Connection failed time to: [$target:$port]\n";
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", list => { 
				remote_user => $remote_user,
				target      => $target, 
				port        => $port, 
				shell_call  => $shell_call,
				error       => $@,
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
					target      => $target,
					port        => $port,
					remote_user => $remote_user,
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
			$error = $anvil->Words->string({key => $message_key, variables => $variables});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => $message_key, variables => $variables});
		}
		
		my $connect_time = tv_interval ($start_time, [gettimeofday]);
		#print "[".$connect_time."] - Connect time to: [$target:$port]\n";
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { error => $error, ssh_fh => $ssh_fh }});
		if (not $error)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
				remote_user => $remote_user,
				password    => $anvil->Log->secure ? $password : "#!string!log_0186!#", 
			}});
			if (not $ssh_fh->auth_password($remote_user, $password)) 
			{
				# Can we log in without a password?
				my $user           = getpwuid($<);
				my $home_directory = $anvil->Get->users_home({debug => $debug, user => $user});
				my $public_key     = $home_directory."/.ssh/id_rsa.pub";
				my $private_key    = $home_directory."/.ssh/id_rsa";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
					user           => $user,
					home_directory => $home_directory, 
					public_key     => $public_key, 
					private_key    => $private_key,
				}});
				
				if ($ssh_fh->auth_publickey($user, $public_key, $private_key)) 
				{
					# We're in! Record the file handle for this target.
					$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = $ssh_fh;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { "cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} }});
					
					# Log that we got in without a password.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $log_level, key => "log_0062", variables => { target => $target }});
				}
				else
				{
					# This is for the user
					$error = $anvil->Words->string({key => "message_0006", variables => { target => $target }});
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "message_0006", variables => { target => $target }});
				}
			}
			else
			{
				# We're in! Record the file handle for this target.
				$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = $ssh_fh;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { "cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} }});
				
				# Record our success
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $log_level, key => "message_0007", variables => { target => $target }});
			}
		}
	}
	
	### Special thanks to Rafael Kitover (rkitover@gmail.com), maintainer of Net::SSH2, for helping me
	### sort out the polling and data collection in this section.
	#
	# Open a channel and make the call.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { 
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
			$error  = $anvil->Words->string({key => "message_0008", variables => { target => $target }});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "message_0008", variables => { target => $target }});
		}
		else
		{
			### TODO: Timeout if the call doesn't respond in X seconds, closing the filehandle if hit.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { 
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
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { "STDOUT:line" => $line }});
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
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { "STDERR:line" => $line }});
					push @{$stderr_output}, $line;
				}
				
				# Exit when we get the end-of-file.
				last if $channel->eof;
			}
			if ($stdout)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { stdout => $stdout }});
				push @{$stdout_output}, $stdout;
			}
			if ($stderr)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { stderr => $stderr }});
				push @{$stderr_output}, $stderr;
			}
		}
	}
	
	# Merge the STDOUT and STDERR
	my $output = [];
	
	foreach my $line (@{$stderr_output}, @{$stdout_output})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { line => $line }});
		push @{$output}, $line;
	}
	
	# Close the connection if requested.
	if ($close)
	{
		if ($ssh_fh)
		{
			# Close it.
			$ssh_fh->disconnect();
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $log_level, key => "message_0009", variables => { target => $target }});
		}
		
		# For good measure, blank both variables.
		$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = "";
		$ssh_fh                                  = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, list => { "cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} }});
	}
	
	$error = "" if not defined $error;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $log_level, secure => $secure, list => { 
		error  => $error,
		ssh_fh => $ssh_fh, 
		output => $output, 
	}});
	return($error, $output);
};


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2 _call_ssh_keyscan

This calls C<< ssh-keyscan >> to add a remote machine's fingerprint to the C<< user >>'s C<< known_hosts >> file.

Returns C<< 0 >> if the addition failed, returns C<< 1 >> if it was successful.

Parameters;

=head3 known_hosts (required)

This is the specific C<< known_hosts >> file we're checking.

=head3 port (optional, default 22)

This is the SSH TCP port used to connect to C<< target >>.

=head3 target (required)

This is the IP or (resolvable) host name of the machine who's RSA fingerprint we're checking.

=head3 user (optional, default to user running this method)

This is the user who's C<< known_hosts >> we're checking.

=cut
sub _call_ssh_keyscan
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $known_hosts = defined $parameter->{known_hosts} ? $parameter->{known_hosts} : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : $<;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		known_hosts => $known_hosts, 
		port        => $port, 
		target      => $target,
		user        => $user,
	}});
	
	# Log what we're doing
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0159", variables => { 
		target => $target, 
		port   => $port, 
		user   => $user, 
	}});
	
	# Redirect STDERR to STDOUT and grep off the comments.
	my $shell_call = $anvil->data->{path}{exe}{'ssh-keyscan'}." ".$target." 2>&1 | ".$anvil->data->{path}{exe}{'grep'}." -v ^# >> ".$known_hosts;
	if (($port) && ($port ne "22"))
	{
		$shell_call = $anvil->data->{path}{exe}{'ssh-keyscan'}." -p ".$port." ".$target." 2>&1 | ".$anvil->data->{path}{exe}{'grep'}." -v ^# >> ".$known_hosts;
	}
	my $output = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
	}
	
	# Set the ownership
	$output     = "";
	$shell_call = $anvil->data->{path}{exe}{'chown'}." ".$user.":".$user." ".$known_hosts;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
	}
	
	# Verify that it's now there.
	my $known_machine = $anvil->Remote->_check_known_hosts_for_target({
		target      => $target, 
		port        => $port, 
		known_hosts => $known_hosts, 
		user        => $user,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { known_machine => $known_machine }});
	
	return($known_machine);
}

=head3 _check_known_hosts_for_target

This checks to see if a given C<< target >> machine is in the C<< user >>'s C<< known_hosts >> file.

Returns C<< 0 >> if the target is not in the C<< known_hosts >> file, C<< 1 >> if it was found.

Parameters;

=head3 delete_if_found (optional, default 0)

Deletes the existing RSA fingerprint if one is found for the C<< target >>.

=head3 known_hosts (required)

This is the specific C<< known_hosts >> file we're checking.

=head3 port (optional, default 22)

This is the SSH TCP port used to connect to C<< target >>.

=head3 target (required)

This is the IP or (resolvable) host name of the machine who's RSA fingerprint we're checking.

=head3 user (optional, default to user running this method)

This is the user who's C<< known_hosts >> we're checking.

=cut
sub _check_known_hosts_for_target
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $delete_if_found = defined $parameter->{delete_if_found} ? $parameter->{delete_if_found} : 0;
	my $known_hosts     = defined $parameter->{known_hosts}     ? $parameter->{known_hosts}     : "";
	my $port            = defined $parameter->{port}            ? $parameter->{port}            : "";
	my $target          = defined $parameter->{target}          ? $parameter->{target}          : "";
	my $user            = defined $parameter->{user}            ? $parameter->{user}            : $<;
	my $known_machine   = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		delete_if_found => $delete_if_found,
		known_hosts     => $known_hosts, 
		port            => $port, 
		target          => $target,
		user            => $user,
	}});
	
	# Is there a known_hosts file at all?
	if (not $known_hosts)
	{
		# Nope.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0163", variables => { file => $$known_hosts }});
		return($known_machine)
	}
	
	# read it in and search.
	my $body = $anvil->Storage->read_file({debug => $debug, file => $known_hosts});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { body => $body }});
	foreach my $line (split/\n/, $body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { line => $line }});
		
		if (($line =~ /$target ssh-rsa /) or ($line =~ /\[$target\]:$port ssh-rsa /))
		{
			# We already know this machine (or rather, we already have a fingerprint for
			# this machine).
			$known_machine = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { known_machine => $known_machine }});
		}
	}
	
	# If we know of this machine and we've been asked to remove it, do so.
	if (($delete_if_found) && ($known_machine))
	{
		### NOTE: It appears the port is not needed.
		# If we have a non-digit user, run this through 'su.
		my $shell_call = $anvil->data->{path}{exe}{'ssh-keygen'}." -R ".$target;
		if (($user) && ($user =~ /\D/))
		{
			$shell_call = $anvil->data->{path}{exe}{su}." - ".$user." -c '".$anvil->data->{path}{exe}{'ssh-keygen'}." -R ".$target."'";
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { shell_call => $shell_call }});
		my $output = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		}
		
		# Mark the machine as no longer known.
		$known_machine = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { known_machine => $known_machine }});
	}
	
	return($known_machine);
}

1;

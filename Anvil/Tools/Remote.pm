package Anvil::Tools::Remote;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Net::SSH2;	### TODO: Phase out.
use Net::OpenSSH;
use Capture::Tiny ':all';

our $VERSION  = "3.0.0";
my $THIS_FILE = "Remote.pm";

### Methods;
# add_target_to_known_hosts
# call
# read_snmp_oid
# test_access
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
		weaken($self->{HANDLE}{TOOLS});
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Remote->add_target_to_known_hosts()" }});
	
	my $delete_if_found = defined $parameter->{delete_if_found} ? $parameter->{delete_if_found} : 0;
	my $port            = defined $parameter->{port}            ? $parameter->{port}            : 22;
	my $target          = defined $parameter->{target}          ? $parameter->{target}          : "";
	my $user            = defined $parameter->{user}            ? $parameter->{user}            : getpwuid($<); 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		delete_if_found => $delete_if_found,
		port            => $port, 
		target          => $target,
		user            => $user,
	}});
	
	# Get the local user's home
	my $users_home = $anvil->Get->users_home({debug => 3, user => $user});
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
			debug           => $debug, 
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
			my $say_user = $user;
			if (($say_user =~ /^\d+$/) && (getpwuid($user)))
			{
				$say_user = getpwuid($user);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_user => $say_user }});
			}
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0009", variables => { 
				target => $target, 
				port   => $port, 
				user   => $say_user, 
			}});
			return(1);
		}
	}
	
	return(0);
}

=head2 call

This does a remote call over SSH. The connection is held open and the file handle for the target is cached and re-used unless a C<< close >> is set to C<< 1 >>. 

Example;

 # Call 'hostnamectl' on a node.
 my ($output, $error, $return_code) = $anvil->Remote->call({
 	target      => "an-a01n01.alteeve.com",
 	password    => "super secret password",
 	remote_user => "admin",
 	shell_call  => "/usr/bin/hostnamectl",
 });
 
 # Make a call with sensitive data that you want logged only if $anvil->Log->secure is set and close the 
 # connection when done.
 my ($output, $error, $return_code) = $anvil->Remote->call({
 	target      => "an-a01n01.alteeve.com",
 	password    => "super secret password",
 	remote_user => "root",
 	shell_call  => "/usr/sbin/fence_ipmilan -a an-a01n02.ipmi -l admin -p \"super secret password\" -o status",
 	secure      => 1,
	'close'     => 1, 
 });

If there is any problem connecting to the target, C<< $error >> will contain a translated string explaining what went wrong. Checking if this is B<< false >> is a good way to verify that the call succeeded.

Any output from the call will be stored in C<< $output >>. STDERR and STDOUT are merged into the C<< $output >> array reference.

B<NOTE>: By default, a connection to a target will be held open and cached to increase performance for future connections. 

B<NOTE>: If the C<< target >> is actually the local system, C<< System->call >> is called instead, and the C<< error >> variable will be set to C<< local >>.

Parameters;

=head3 close (optional, default '0')

If set, the connection to the target will be closed at the end of the call.

=head3 log_level (optional, default C<< 3 >>)

If set, the method will use the given log level. Valid values are integers between C<< 0 >> and C<< 4 >>.

=head3 no_cache (optional, default C<< 0 >>)

If set, and if an existing cached connection is open, it will be closed and a new connection to the target will be established.

=head3 ossh_opts (optional, default [])

This is a ref to an array of named elements which extends the options passed to Net:OpenSSH->new().

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

=head3 timeout (optional, default '10')

B<NOTE>: This is the timeout for the command to return, in seconds. This is NOT the connection timeout!

If this is set to a numeric whole number, then the called shell command will have the set number of seconds to complete. If this is set to C<< 0 >>, then no timeout will be used.

=cut
sub call
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Remote->call()" }});
	# Get the target and port so that we can create the ssh_fh key
	my $port        =         $parameter->{port}              ? $parameter->{port}        : 22;
	my $target      = defined $parameter->{target}            ? $parameter->{target}      : "";
	my $remote_user = defined $parameter->{remote_user}       ? $parameter->{remote_user} : "root";
	my $ossh_opts   = ref($parameter->{ossh_opts}) eq "ARRAY" ? $parameter->{ossh_opts}   : [];
	my $ssh_fh_key  = $remote_user."\@".$target.":".$port;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:remote_user' => $remote_user,
		's2:target'      => $target,
		's3:port'        => $port, 
		's4:ssh_fh_key'  => $ssh_fh_key, 
		's5:ossh_opts'   => $ossh_opts,
	}});
	
	# This will store the SSH file handle for the given target after the initial connection.
	$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = defined $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} ? $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} }});
	
	# Now pick up the rest of the variables.
	my $close       = defined $parameter->{'close'}    ? $parameter->{'close'}    : 0;
	my $no_cache    = defined $parameter->{no_cache}   ? $parameter->{no_cache}   : 0;
	my $password    = defined $parameter->{password}   ? $parameter->{password}   : "";
	my $secure      = defined $parameter->{secure}     ? $parameter->{secure}     : 0;
	my $shell_call  = defined $parameter->{shell_call} ? $parameter->{shell_call} : "";
	my $timeout     = defined $parameter->{timeout}    ? $parameter->{timeout}    : 10;
	my $start_time  = time;
	my $ssh_fh      = $anvil->data->{cache}{ssh_fh}{$ssh_fh_key};
	# NOTE: The shell call might contain sensitive data, so we show '--' if 'secure' is set and $anvil->Log->secure is not.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'close'    => $close, 
		no_cache   => $no_cache,
		password   => $anvil->Log->is_secure($password), 
		secure     => $secure, 
		shell_call => (not $secure) ? $shell_call : $anvil->Log->is_secure($shell_call),
		ssh_fh     => $ssh_fh,
		start_time => $start_time, 
		timeout    => $timeout, 
		port       => $port, 
		target     => $target,
		ssh_fh_key => $ssh_fh_key, 
	}});
	
	if ((not $password) && (defined $anvil->data->{sys}{root_password}))
	{
		$password = $anvil->data->{sys}{root_password};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			password => $anvil->Log->is_secure($password), 
		}});
	}
	
	# Is the global "always reconnect" is set, set 'close' to 1 and clear any cached connections.
	$anvil->data->{sys}{net}{always_reconnect} = 0 if not defined $anvil->data->{sys}{net}{always_reconnect};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::net::always_reconnect" => $anvil->data->{sys}{net}{always_reconnect}, 
	}});
	if ($anvil->data->{sys}{net}{always_reconnect})
	{
		$close    = 1;
		$no_cache = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			'close'  => $close,
			no_cache => $no_cache, 
		}});
	}

	### NOTE: This caused problems that are currently unsolved.
=cut
	# If the call is to ourselves, switch to a local system call.
	if ($anvil->Network->is_local({host => $target}))
	{
		# Use a local system call.
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
		
		return($output, "local", $return_code);
	}
=cut
	
	if (not $shell_call)
	{
		# No shell call
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->call()", parameter => "shell_call" }});
		return("!!error!!", "!!error!!", 9999);
	}
	if (not $target)
	{
		# No target, this should not happen...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0239", variables => { 
			remote_user => $remote_user,
			port        => $port, 
			'close'     => $close, 
			secure      => $secure, 
			shell_call  => (not $secure) ? $shell_call : $anvil->Log->is_secure($shell_call),
		}});
		return("!!error!!", "!!error!!", 9999);
	}
	if (not $remote_user)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->call()", parameter => "remote_user" }});
		return("!!error!!", "!!error!!", 9999);
	}
	if (($timeout) && ($timeout =~ /\D/))
	{
		# Bad value, should only be digits. Warn and reset to default.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0295", variables => { timeout => $timeout }});
		$timeout = 10;
	}
	
	# If the user didn't pass a port, but there is an entry in 'hosts::<host>::port', use it.
	if ((not $parameter->{port}) && ($anvil->data->{hosts}{$target}{port}))
	{
		$port = $anvil->data->{hosts}{$target}{port};
	}
	
	# Break out the port, if needed.
	if ($target =~ /^(.*):(\d+)$/)
	{
		$target = $1;
		$port   = $2;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			port   => $port, 
			target => $target,
		}});
		
		# If the user passed a port, override this.
		if ($parameter->{port} =~ /^\d+$/)
		{
			$port = $parameter->{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
		}
	}
	else
	{
		# In case the user is using ports in /etc/ssh/ssh_config, we'll want to check for an entry.
		$anvil->System->read_ssh_config({deubg => $debug});
		
		$anvil->data->{hosts}{$target}{port} = 22 if not defined $anvil->data->{hosts}{$target}{port};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "hosts::${target}::port" => $anvil->data->{hosts}{$target}{port} }});
		if ($anvil->data->{hosts}{$target}{port} =~ /^\d+$/)
		{
			$port = $anvil->data->{hosts}{$target}{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
		}
	}
	
	# Make sure the port is valid.
	if ($port eq "")
	{
		$port = 22;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
	}
	elsif ($port !~ /^\d+$/)
	{
		$port = getservbyname($port, 'tcp');
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
	}
	if ((not defined $port) or (($port !~ /^\d+$/) or ($port < 0) or ($port > 65536)))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0058", variables => { port => $port }});
		return("!!error!!", "!!error!!", 9999);
	}
	
	# If the target is a host name, convert it to an IP.
	if (not $anvil->Validate->ipv4({ip => $target}))
	{
		my $new_target = $anvil->Convert->host_name_to_ip({host_name => $target});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_target => $new_target }});
		if ($new_target)
		{
			$target = $new_target;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target => $target }});
			
			# Verify that it's host key is OK.
			my $known_machine = $anvil->Remote->_check_known_hosts_for_target({
				debug  => $debug, 
				target => $target, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { known_machine => $known_machine }});
		}
	}
	
	# If the user set 'no_cache', don't use any existing 'ssh_fh'.
	if (($no_cache) && ($ssh_fh))
	{
		# Close the connection.
		$ssh_fh->disconnect();
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "message_0010", variables => { target => $target }});
		
		# For good measure, blank both variables.
		$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = "";
		$ssh_fh                                    = "";
	}
	
	# This will store the output 
	my $output         = "";
	my $state          = "";
	my $error          = "";
	my $connect_output = "";
	my $return_code    = 9999;
	
	# If I don't already have an active SSH file handle, connect now.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ssh_fh => $ssh_fh }});
	if ($ssh_fh =~ /^Net::OpenSSH/)
	{
		# We have an open connection, reusing it.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0296", variables => { connection => $ssh_fh_key }});
	}
	else
	{
		# We're going to try up to 3 times, as sometimes there are transient issues that cause 
		# connection errors.
		my $connected   = 0;
		my $message_key = "message_0005";
		my $last_loop   = 2;
		my $bad_file    = "";
		my $bad_line    = "";
		foreach (my $i = 0; $i <= $last_loop; $i++)
		{
			last if $connected;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:i'           => $i, 
				's2:target'      => $target, 
				's3:remote_user' => $remote_user, 
				's4:port'        => $port, 
			}});
			alarm(120);
			($connect_output) = capture_merged {
				$ssh_fh = Net::OpenSSH->new($target, 
					user       => $remote_user,
					port       => $port, 
					batch_mode => 1,
					@$ossh_opts,
				);
			};
			$connect_output =~ s/\r//gs;
			$connect_output =~ s/\n$//; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:ssh_fh'         => $ssh_fh,
				's2:ssh_fh->error'  => $ssh_fh->error,
				's3:connect_output' => $connect_output, 
			}});
			alarm(0);
			if ($@) { $anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 'alarm $@' => $@ }}); }
			
			# Any fatal issues reaching the target?
			if ($connect_output =~ /Could not resolve hostname/i)
			{
				$i           = $last_loop;
				$message_key = "message_0001";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { i => $i, message_key => $message_key }});
			}
			elsif ($connect_output =~ /No route to host/i)
			{
				$i           = $last_loop;
				$message_key = "message_0003";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { i => $i, message_key => $message_key }});
			}
			elsif ($connect_output =~ /IDENTIFICATION HAS CHANGED/i)
			{
				# Host's ID has changed, rebuilt? Find the line and file to tell the user.
				my $user = getpwuid($<);
				foreach my $line (split/\n/, $connect_output)
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
					if ($line =~ /Offending .*? key in (\/.*?known_hosts):(\d+)$/)
					{
						# NOTE: We don't use the line now, but we're recording it 
						#       anyway in case it happens to be useful in the future.
						$bad_file = $1;
						$bad_line = $2;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							bad_file => $bad_file,
							bad_line => $bad_line, 
						}});
					}
				}
				$message_key = "message_0149";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { i => $i, message_key => $message_key }});
				
				# If I have a database connection, record this bad entry in 'states'.
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::database::connections' => $anvil->data->{sys}{database}{connections} }});
				if (not $anvil->data->{sys}{database}{connections})
				{
					# Try to connect
					$anvil->Database->connect();
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, secure => 0, key => "log_0132"});
				}
				if ($anvil->data->{sys}{database}{connections})
				{
					my ($state_uuid) = $anvil->Database->insert_or_update_states({
						debug      => 2, 
						state_name => "host_key_changed::".$target, 
						state_note => "file=".$bad_file.",line=".$bad_line, 
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
				}
			}
			elsif ($connect_output =~ /Host key verification failed/i)
			{
				# Need to accept the fingerprint
				$message_key = "message_0135";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { i => $i, message_key => $message_key }});
				
				# Make sure we know the fingerprint of the remote machine
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0158", variables => { target => $target, user => getpwuid($<) }});
				$anvil->Remote->add_target_to_known_hosts({
					debug  => $debug, 
					target => $target, 
					user   => getpwuid($<),
				});
			}
			elsif ($connect_output =~ /Connection refused/i)
			{
				$i           = $last_loop;
				$message_key = "message_0002";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { i => $i, message_key => $message_key }});
			} # If I didn't connect, try again if I have a password.
			elsif (($ssh_fh->error) && ($password) && ($connect_output =~ /Permission denied/i))
			{
				# Try again.
				#print "Connection without a password failed, trying again with the password.\n";
				$connect_output   = "";
				($connect_output) = capture_merged {
					$ssh_fh = Net::OpenSSH->new($target, 
						user       => $remote_user,
						port       => $port, 
						passwd     => $password,
						batch_mode => 1,
						@$ossh_opts,
					);
				};
				$connect_output =~ s/\n$//; 
				$connect_output =~ s/\r$//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:i'              => $i, 
					's2:target'         => $target, 
					's3:port'           => $port, 
					's4:ssh_fh'         => $ssh_fh,
					's5:ssh_fh->error'  => $ssh_fh->error,
					's6:connect_output' => $connect_output, 
				}});
				
				# If the password is bad, exit the loop.
				if ($ssh_fh->error =~ /bad password/i)
				{
					$i           = $last_loop;
					$message_key = "message_0006";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						i           => $i,
						message_key => $message_key, 
					}});
				}
			}
			
			if (not $ssh_fh->error)
			{
				# Connected!
				$connected = 1;
				$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = $ssh_fh;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:connected"                    => $connected,
					"s2:cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key}, 
				}});
				last;
			}
			elsif ($i < $last_loop)
			{
				# Sleep and then try again.
				$connect_output = "";
				sleep 1;
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:connected'     => $connected,
			's2:ssh_fh->error' => $ssh_fh->error, 
		}});
		my $variables = { 
			remote_user => $remote_user, 
			target      => $target.":".$port,
			user        => getpwuid($<),
			error       => $ssh_fh->error,
			connection  => $ssh_fh_key, 
			file        => $bad_file, 
			line        => $bad_line, 
		};
		if (not $connected)
		{
			$error = $anvil->Words->string({key => $message_key, variables => $variables});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => $message_key, variables => $variables});
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 
				'close'    => $close, 
				password   => $anvil->Log->is_secure($password), 
				secure     => $secure, 
				shell_call => (not $secure) ? $shell_call : $anvil->Log->is_secure($shell_call),
				ssh_fh     => $ssh_fh,
				start_time => $start_time, 
				timeout    => $timeout, 
				port       => $port, 
				target     => $target,
				ssh_fh_key => $ssh_fh_key, 
			}});
		}
	}
	
	# If I have a valid handle, try to call our command now. Note that if we're using a cached connection
	# that has died, we might fail.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { ssh_fh => $ssh_fh }});
	if ($ssh_fh =~ /^Net::OpenSSH/)
	{
		# The shell_call can't end is a newline. Conveniently, we want the return code. By adding 
		# this, we ensure it doesn't end in a new-line (and we can't blindly strip off the last 
		# new-line because of 'EOF' type cat's). 
		$shell_call .= "\n".$anvil->data->{path}{exe}{echo}." return_code:\$?";
		
		# Make sure the output variables are clean and then make the call.
		$output = ""; 
		$error  = "";
		if ($timeout)
		{
			# Call with a timeout. Use alarm also, as capture2's timeout is questionaly reliable.
			alarm($timeout + 60);
			($output, $error) = $ssh_fh->capture2({timeout => $timeout}, $shell_call);
			$output = "" if not defined $output;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 'ssh_fh->error' => $ssh_fh->error }});
			alarm(0);
			if ($@) { $anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 'alarm $@' => $@ }}); }
		}
		else
		{
			# Call without a timeout.
			($output, $error) = $ssh_fh->capture2($shell_call);
			$output = "" if not defined $output;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 'ssh_fh->error' => $ssh_fh->error }});
		}
		
		# Was there a problem?
		if ($ssh_fh->error)
		{
			# Something went wrong.
			$error = $anvil->Words->string({key => "message_0008", variables => { 
				shell_call => $shell_call, 
				connection => $ssh_fh_key, 
				error      => $ssh_fh->error,
			}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { error => $error }});
			
			# Close the connection.
			$close = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 'close' => $close }});
		}
		
		# Take the last new line off.
		$output =~ s/\n$//; $output =~ s/\r//g;
		$error  =~ s/\n$//; $error  =~ s/\r//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 
			error   => $error,
			output  => $output, 
			'close' => $close,
		}});
		
		# Pull the return code out.
		my $clean_output = "";
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { line => $line }});
			if ($line =~ /^return_code:(\d+)$/)
			{
				$return_code = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { return_code => $return_code }});
			}
			elsif ($line =~ /return_code:(\d+)$/)
			{
				### NOTE: This should never happen given we have a newline before the echo, 
				###       but it's here just in case.
				# If the output of the shell call doesn't end in a newline, the return_code:X
				# could be appended. This catches those cases and removes it.
				$return_code  =  $1;
				$line         =~ s/return_code:\d+$//;
				$clean_output .= $line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					line        => $line, 
					output      => $output, 
					return_code => $return_code, 
				}});
			}
			else
			{
				$clean_output .= $line."\n";
			}
		}
		$clean_output =~ s/\n$//;
		$output       =  $clean_output;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
		
		# Have we been asked to close the connection?
		if ($close)
		{
			# Close it.
			$ssh_fh->disconnect();
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "message_0009", variables => { target => $target }});
			
			# For good measure, blank both variables.
			$anvil->data->{cache}{ssh_fh}{$ssh_fh_key} = "";
			$ssh_fh                                    = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::ssh_fh::${ssh_fh_key}" => $anvil->data->{cache}{ssh_fh}{$ssh_fh_key} }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 
		error       => $error,
		output      => $output,
		return_code => $return_code, 
	}});
	return($output, $error, $return_code);
}


=head2 read_snmp_oid

This connects to a remote machine using SNMP and reads (if possible) the OID specified. If unable to reach the target device, C<< !!no_connection!! >> is returned. If there is a problem with the call made to this method, C<< !!error!! >> is returned. 

Otherwise, two values are returned; first the data and second the data type.

Parameters;

=head3 community (optional)

This is the SNMP community used to connect to.

=head3 mib (optional)

If set to a path to a file, the file is treated as a custom MIB to be fed into C<< snmpget >>

=head3 oid (required)

This is the OID string to query.

=head3 target (required)

This is the IP or (resolvable) host name to query.

=head3 version (optional, default '2c')

This is the SNMP protocol version to use when connecting to the target.

=cut
sub read_snmp_oid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Remote->read_snmp_oid()" }});
	
	my $community = defined $parameter->{community} ? $parameter->{community} : "";
	my $mib       = defined $parameter->{mib}       ? $parameter->{mib}       : "";
	my $oid       = defined $parameter->{oid}       ? $parameter->{oid}       : "";
	my $target    = defined $parameter->{target}    ? $parameter->{target}    : "";
	my $version   = defined $parameter->{version}   ? $parameter->{version}   : "2c";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		community => $community, 
		mib       => $mib, 
		oid       => $oid, 
		target    => $target,
		version   => $version, 
	}});
	
	if (not $oid)
	{
		# Um, what are we supposed to read?
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->read_snmp_oid()", parameter => "oid" }});
		$anvil->nice_exit({exit_code => 1});
		
		return("!!error!!");
	}
	if (not $target)
	{
		# Who ya gonna call? No, seriously, I have no idea...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Remote->read_snmp_oid()", parameter => "target" }});
		$anvil->nice_exit({exit_code => 1});
		
		return("!!error!!");
	}
	if (($mib) && (not -r $mib))
	{
		# Bad MIB path
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0163", variables => { mib => $mib }});
		$anvil->nice_exit({exit_code => 1});
		
		return("!!error!!");
	}
	
	my $data_type  = "unknown";
	my $shell_call = $anvil->data->{path}{exe}{snmpget}." -On";
	if ($community)
	{
		$shell_call .= " -c ".$community;
	}
	if ($mib)
	{
		$shell_call .= " -m ".$mib;
	}
	$shell_call .= " -v ".$version." ".$target." ".$oid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	my $value = "#!no_value!#";
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /No Response/i)
		{
			$value = "#!no_connection!#";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
		}
		elsif (($line =~ /STRING: "(.*)"$/i) or ($line =~ /STRING: (.*)$/i))
		{
			$value     = $1;
			$data_type = "string";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				value     => $value,
				data_type => $data_type, 
			}});
		}
		elsif ($line =~ /INTEGER: (\d+)$/i)
		{
			$value     = $1;
			$data_type = "integer";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				value     => $value,
				data_type => $data_type, 
			}});
		}
		elsif ($line =~ /Hex-STRING: (.*)$/i)
		{
			$value     = $1;
			$data_type = "hex-string";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				value     => $value,
				data_type => $data_type, 
			}});
		}
		elsif ($line =~ /Gauge32: (.*)$/i)
		{
			$value     = $1;
			$data_type = "guage32";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				value     => $value,
				data_type => $data_type, 
			}});
		}
		elsif ($line =~ /Timeticks: \((\d+)\) /i)
		{
			$value     = $1;
			$data_type = "timeticks";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				value     => $value,
				data_type => $data_type, 
			}});
		}
		elsif ($line =~ /No Such Instance/i)
		{
			$value = "--";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
		}
		elsif ($line =~ /^(.*?): (.*$)/i)
		{
			$data_type = $1;
			$value     = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				value     => $value,
				data_type => $data_type, 
			}});
		}
	}
	
	return($value, $data_type);
}


=head2 test_access

This attempts to log into the target to verify that the target is up and reachable. It returns C<< 1 >> on access, C<< 0 >> otherwise.

 my $access = $anvil->Remote->test_access({
 	target   => "remote_host",
 	password => "secret",
 });

Parameters;

=head3 close (optional, default '1')

If set, the SSH connection used to test the access to the remote host wil be closed. This can be useful it there might be a delay between when the connecton is tested and when it is used again.

=head3 password (optional)

This is the password used to connect to the remote target as the given user.

B<NOTE>: Passwordless SSH is supported. If you can ssh to the target as the given user without a password, then no password needs to be given here.

=head3 port (optional, default '22')

This is the TCP port to use when connecting to the C<< target >> over SSH.

=head3 target (required)

This is the IP address or (resolvable) host name of the machine who's key we're recording.

=head3 user (optional, defaults to user running this method)

This is the user who we're recording the key for. 

=cut
sub test_access
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Remote->test_access()" }});
	
	my $close    = defined $parameter->{'close'}  ? $parameter->{'close'}  : 1;
	my $password = defined $parameter->{password} ? $parameter->{password} : "";
	my $port     = defined $parameter->{port}     ? $parameter->{port}     : 22;
	my $target   = defined $parameter->{target}   ? $parameter->{target}   : "";
	my $user     = defined $parameter->{user}     ? $parameter->{user}     : getpwuid($<); 
	my $access   = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		'close'  => $close,
		password => $anvil->Log->is_secure($password), 
		port     => $port, 
		target   => $target,
		user     => $user,
	}});
	
	# Make sure we've got the target in our known_hosts file.
	my $output      = "";
	my $error       = "";
	my $return_code = 255;
	my $timeout     = 30;
	alarm($timeout);
	eval {
		$anvil->Remote->add_target_to_known_hosts({
			debug  => $debug, 
			target => $target, 
			user   => getpwuid($<),
		});
		
		# Call the target
		($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			password    => $password, 
			shell_call  => $anvil->data->{path}{exe}{echo}." 1", 
			target      => $target,
			remote_user => $user, 
			'close'     => $close,
			no_cache    => 1,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			error       => $error,
			return_code => $return_code, 
		}});
	};
	alarm(0);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'alarm $@' => $@ }});
	if ($@)
	{
		# Timed out 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0192", variables => { 
			target  => $target, 
			timeout => $timeout, 
			error   => $@, 
		}});
	}
	
	if ($output eq "1")
	{
		$access = 1;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { access => $access }});
	return($access);
}

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Remote->_call_ssh_keyscan()" }});
	
	my $known_hosts = defined $parameter->{known_hosts} ? $parameter->{known_hosts} : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : getpwuid($<);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		known_hosts => $known_hosts, 
		port        => $port, 
		target      => $target,
		user        => $user,
	}});
	
	# Log what we're doing
	my $say_user = $user;
	if (($say_user =~ /^\d+$/) && (getpwuid($user)))
	{
		$say_user = getpwuid($user);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_user => $say_user }});
	}
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0159", variables => { 
		target => $target, 
		port   => $port, 
		user   => $say_user, 
	}});
	
	# Is there a known_hosts file at all?
	if (not $known_hosts)
	{
		# Can we divine it?
		my $users_home = $anvil->Get->users_home({debug => 3, user => $user});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { users_home => $users_home }});
		if ($users_home)
		{
			$known_hosts = $users_home."/.ssh/known_hosts";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { known_hosts => $known_hosts }});
		}
		
		if (not $known_hosts)
		{
			# Nope.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0163", variables => { file => $known_hosts }});
			return("");
		}
	}
	
	# Does the known_hosts file actually exist?
	if (not -f $known_hosts)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0163", variables => { file => $known_hosts }});
		return("");
	}
	
	# Redirect STDERR to STDOUT and grep off the comments.
	my $shell_call = $anvil->data->{path}{exe}{'ssh-keyscan'}." -4 -t ecdsa-sha2-nistp256 ".$target." 2>&1 | ".$anvil->data->{path}{exe}{'grep'}." -v ^# >> ".$known_hosts;
	if (($port) && ($port ne "22"))
	{
		$shell_call = $anvil->data->{path}{exe}{'ssh-keyscan'}." -4 -t ecdsa-sha2-nistp256 -p ".$port." ".$target." 2>&1 | ".$anvil->data->{path}{exe}{'grep'}." -v ^# >> ".$known_hosts;
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
		debug       => $debug, 
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Remote->_check_known_hosts_for_target()" }});
	
	my $delete_if_found = defined $parameter->{delete_if_found} ? $parameter->{delete_if_found} : 0;
	my $known_hosts     = defined $parameter->{known_hosts}     ? $parameter->{known_hosts}     : "";
	my $port            = defined $parameter->{port}            ? $parameter->{port}            : "";
	my $target          = defined $parameter->{target}          ? $parameter->{target}          : "";
	my $user            = defined $parameter->{user}            ? $parameter->{user}            : getpwuid($<);
	my $known_machine   = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		delete_if_found => $delete_if_found,
		known_hosts     => $known_hosts, 
		port            => $port, 
		target          => $target,
		user            => $user,
	}});
	
	# Is there a known_hosts file at all?
	if (not $known_hosts)
	{
		# Can we divine it?
		my $users_home = $anvil->Get->users_home({debug => 3, user => $user});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { users_home => $users_home }});
		if ($users_home)
		{
			$known_hosts = $users_home."/.ssh/known_hosts";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { known_hosts => $known_hosts }});
		}
		
		if (not $known_hosts)
		{
			# Nope.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0163", variables => { file => $known_hosts }});
			return($known_machine);
		}
	}
	
	# Does the known_hosts file actually exist?
	if (not -f $known_hosts)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0163", variables => { file => $known_hosts }});
		return($known_machine);
	}
	
	### NOTE: This is called by ocf:alteeve:server, so there might not be a database available.
	# Make sure we've loaded hosts.
	if (($anvil->data->{sys}{database}{read_uuid}) && (not exists $anvil->data->{hosts}{host_uuid}))
	{
		$anvil->Database->get_hosts({debug => $debug});
	}
	
	if (exists $anvil->data->{duplicate_keys})
	{
		delete $anvil->data->{duplicate_keys};
	}
	
	# read it in and search.
	my $bad_line = 0;
	my $new_body = "";
	my $old_body = $anvil->Storage->read_file({
		debug      => $debug, 
		file       => $known_hosts,
		cache      => 0, 
		force_read => 1,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { old_body => $old_body }});
	foreach my $line (split/\n/, $old_body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { line => $line }});
		
		# If the line isn't a comment or isn't in the format '<host> <algo> <key>', consider it bad.
		my $test_line =  $anvil->Words->clean_spaces({string => $line});
		   $test_line =~ s/#.*$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { test_line => $test_line }});
		if (($test_line !~ /^\w.*?\s+\w.*?\s+\w.*/) or 
		    ($test_line =~ /No route to host/i)     or 
		    ($test_line =~ /Connection refused/i)   or 
		    ($test_line =~ /getaddrinfo/))
		{
			# Bad line.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0185", variables => { 
				file => $known_hosts,
				line => $line,
			}});
			$bad_line = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { bad_line => $bad_line }});
			next;
		}
		
		# Watch for duplicate entries.
		if ($line =~ /^(.*?) (.*?) (.*)$/)
		{
			my $target_host = $1;
			my $algorithm   = $2;
			my $key         = $anvil->Words->clean_spaces({string => $3});;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:target_host' => $target_host,
				's2:algorithm'   => $algorithm, 
				's3:key'         => $key,
			}});
			
			if (not exists $anvil->data->{duplicate_keys}{$target_host}{$algorithm})
			{
				$anvil->data->{duplicate_keys}{$target_host}{$algorithm} = $key;
			}
			else
			{
				# Duplicate! Same key?
				my $old_key  = $anvil->data->{duplicate_keys}{$target_host}{$algorithm};
				   $bad_line = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					old_key  => $old_key,
					bad_line => $bad_line, 
				}});
				
				if ($old_key eq $key)
				{
					# Simple duplicate, delete it.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0186", variables => { 
						file        => $known_hosts,
						target_host => $target_host,
						algorithm   => $algorithm,
					}});
				}
				else
				{
					# Tke keys differ, Delete the subsequent keys and the earlier ones are more trust-worthy
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0187", variables => { 
						file        => $known_hosts,
						target_host => $target_host,
						algorithm   => $algorithm,
						old_key     => $old_key, 
						key         => $key,
					}});
				}
				next;
			}
		}
		$new_body .= $line."\n";
		
		# This is wider scope now to catch hosts using other hashes than 'ssh-rsa'
		if (($line =~ /$target (.*)$/) or ($line =~ /\[$target\]:$port (.*)$/))
		{
			# We already know this machine (or rather, we already have a fingerprint for
			# this machine).
			my $current_key   = $anvil->Words->clean_spaces({string => $1});
			my $is_host_name  = $anvil->Validate->host_name({debug => 3, name => $target});
			my $is_ip         = $anvil->Validate->ipv4({debug => 3, ip => $target});
			   $known_machine = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
				current_key   => $current_key, 
				is_host_name  => $is_host_name, 
				is_ip         => $is_ip, 
				known_machine => $known_machine,
			}});
			
			# If we're already planning to delete 
			next if $delete_if_found;
			
			# If we don't have any DBs to read from, we're also done.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
				'sys::database::read_uuid' => $anvil->data->{sys}{database}{read_uuid},
			}});
			next if not $anvil->data->{sys}{database}{read_uuid};
			
			my $target_host_uuid = "";
			my $target_host_name = "";
			if ($is_ip)
			{
				($target_host_uuid, $target_host_name) = $anvil->Get->host_from_ip_address({debug => 2, ip_address => $target});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
					target_host_uuid => $target_host_uuid, 
					target_host_name => $target_host_name,
				}});
			}
			elsif ($is_host_name)
			{
				$target_host_name = $target;
				$target_host_uuid = $anvil->Get->host_uuid_from_name({debug => 3, host_name => $target});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
					target_host_uuid => $target_host_uuid, 
					target_host_name => $target_host_name,
				}});
			}
			
			if ($target_host_uuid)
			{
				# If we have a host_key and it doesn't match the one we just read, delete it.
				my $host_key = $anvil->Words->clean_spaces({string => $anvil->data->{hosts}{host_uuid}{$target_host_uuid}{host_key}});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
					's1:host_key'    => $host_key,
					's2:current_key' => $current_key, 
				}});
				
				my ($current_key_type, $current_key_string) =  ($current_key =~ /(.*?)\s+(.*)$/);
				my ($host_key_type, $host_key_string)       =  ($host_key =~ /(.*?)\s+(.*)$/);
				   $host_key_string                         =~ s/\s.*$//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
					's1:current_key_type'   => $current_key_type,
					's2:host_key_type'      => $host_key_type, 
					's3:current_key_string' => $current_key_string, 
					's4:host_key_string'    => $host_key_string, 
				}});
				
				# If the key type is the same, but the string is not, delete the old key.
				if (($current_key_type eq $host_key_type) && ($current_key_string ne $host_key_string))
				{
					# It's changed, clear the old one.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0851", variables => { 
						known_hosts => $known_hosts, 
						target      => $target, 
						key_type    => $current_key_type, 
						old_key     => $current_key_string,
						new_key     => $host_key_string,
					}});
					$delete_if_found = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_if_found => $delete_if_found }});
				}
			}
		}
	}
	
	# If there was a bad line, write out the fixed body first.
	if ($bad_line)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
		
		# Read the stat of the known_hosts file.
		$anvil->Storage->get_file_stats({debug => $debug, file_path => $known_hosts});
		my $unix_mode  = $anvil->data->{file_stat}{$known_hosts}{unix_mode};
		my $user_name  = $anvil->data->{file_stat}{$known_hosts}{user_name};
		my $group_name = $anvil->data->{file_stat}{$known_hosts}{group_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:known_hosts' => $known_hosts, 
			's2:unix_mode'   => $unix_mode, 
			's3:user_name'   => $user_name, 
			's4:group_name'  => $group_name, 
		}});
		
		$anvil->Storage->write_file({
			debug     => $debug, 
			file      => $known_hosts, 
			body      => $new_body, 
			backup    => 1, 
			overwrite => 1, 
			mode      => $unix_mode, 
			user      => $user_name, 
			group     => $group_name, 
		})
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

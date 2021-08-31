package Anvil::Tools::System;
# 
# This module contains methods used to handle common system tasks.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Time::HiRes qw(gettimeofday tv_interval);
use Proc::Simple;
use NetAddr::IP;
use JSON;
use Text::Diff;
use String::ShellQuote;
use Encode;

our $VERSION  = "3.0.0";
my $THIS_FILE = "System.pm";

### Methods;
# activate_lv
# call
# change_shell_user_password
# check_daemon
# check_if_configured
# check_ssh_keys
# check_memory
# check_storage
# collect_ipmi_data
# configure_ipmi
# disable_daemon
# enable_daemon
# find_matching_ip
# host_name
# maintenance_mode
# manage_authorized_keys
# manage_firewall
# pids
# parse_lshw
# read_ssh_config
# reload_daemon
# reboot_needed
# restart_daemon
# start_daemon
# stop_daemon
# stty_echo
# update_hosts
# _check_anvil_conf
# _load_firewalld_zones
# _load_specific_firewalld_zone
# _match_port_to_service

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::System

Provides all methods related to storage on a system.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->System->X'. 
 # 
 # Example using 'system_call()';
 my ($host_name, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{hostnamectl}." --static"});

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

=head2 activate_lv

This takes a logical volume path and tries to activate it. If it is successfully activated, C<< 1 >> is returned. If the activation fails for any reason, C<< 0 >> is returned.

 my $activated = $anvil->System->activate_lv({path => "/dev/foo/bar"});
 
Parameters;

=head3 path (required)

This is the full path to the logical volume to activate.

=cut
sub activate_lv
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->activate_lv()" }});
	
	my $path      = defined $parameter->{path} ? $parameter->{path} : "";
	my $activated = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		path => $path, 
	}});
	
	if (not $path)
	{
		# Woops!
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->activate_lv()", parameter => "path" }});
		return($activated);
	}
	if ((not -e $path) or (not -b $path))
	{
		# Bad path
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0064", variables => { path => $path }});
	}
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{lvchange}." --activate y ".$path});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	
	# A non-zero return code indicates failure, but we'll check directly.
	$anvil->System->check_storage({debug => $debug, scan => 2});
	
	# Check if it worked.
	my $host = $anvil->Get->short_host_name();
	$activated = $anvil->data->{lvm}{$host}{lv}{$path}{active};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { activated => $activated }});
	
	return($activated);
}

=head2 call

This method makes a system call and returns the output (with the last new-line removed) and the return code. If there is a problem, 'C<< #!error!# >>' is returned and the error will be logged.

 my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => "host_name"});

Parameters;

=head3 background (optional, default '0')

If set to C<< 1 >>, the program will be started in the background and the C<< Proc::Simple >> handle will be returned instead of the command's output.

=head3 line (optional)

This is the line number of the source file that called this method. Useful for logging and debugging.

=head3 redirect_stderr (optional, default '1')

By default, C<< STDERR >> is redirected to C<< STDOUT >>. If this is set to C<< 0 >>, this is disabled.

=head3 secure (optional)

If set to 'C<< 1 >>', the shell call will be treated as if it contains a password or other sensitive data for logging.

=head3 shell_call (required)

This is the shell command to call.

=head3 source (optional)

This is the name of the source file calling this method. Useful for logging and debugging.

=head3 stderr_file (optional)

B<NOTE>: This is only used when C<< background >> is set to C<< 1 >>.

If set, the C<< STDERR >> output will be sent to the corresponding file. If this isn't a full path, the file will be placed under C<< /tmp/ >>.

=head3 stdout_file (optional)

B<NOTE>: This is only used when C<< background >> is set to C<< 1 >>.

If set, the C<< STDOUT >> output will be sent to the corresponding file. If this isn't a full path, the file will be placed under C<< /tmp/ >>.

=head3 timeout (optional, default '0')

If set, a timeout will be placed on the call. If the call takes more than C<< timeout >> seconds, the call will fail and the C<< return_code >> will be C<< 124 >>.

=cut
sub call
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->call()" }});
	
	my $background      = defined $parameter->{background}      ? $parameter->{background}      : 0;
	my $line            = defined $parameter->{line}            ? $parameter->{line}            : __LINE__;
	my $redirect_stderr = defined $parameter->{redirect_stderr} ? $parameter->{redirect_stderr} : 1;
	my $shell_call      = defined $parameter->{shell_call}      ? $parameter->{shell_call}      : "";
	my $secure          = defined $parameter->{secure}          ? $parameter->{secure}          : 0;
	my $source          = defined $parameter->{source}          ? $parameter->{source}          : $THIS_FILE;
	my $stderr_file     = defined $parameter->{stderr_file}     ? $parameter->{stderr_file}     : "";
	my $stdout_file     = defined $parameter->{stdout_file}     ? $parameter->{stdout_file}     : "";
	my $timeout         = defined $parameter->{timeout}         ? $parameter->{timeout}         : 0;
	my $redirect        = $redirect_stderr ? " 2>&1" : "";
	$anvil->Log->variables({source => $source, line => $line, level => $debug, secure => $secure, list => { 
		background      => $background, 
		shell_call      => $shell_call,
		redirect        => $redirect, 
		redirect_stderr => $redirect_stderr, 
		stderr_file     => $stderr_file, 
		stdout_file     => $stdout_file, 
	}});
	
	my $return_code = 9999;
	my $output      = "#!error!#";
	if (not $shell_call)
	{
		# wat?
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0043"});
	}
	else
	{
		# If this is an executable, make sure the program exists.
		my $found = 1;
		if (($shell_call =~ /^(\/.*?) /) or ($shell_call =~ /^(\/.*)/))
		{
			my $program = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { program => $program }});
			if (not -e $program)
			{
				$found = 0;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0141", variables => {
					program    => $program,
					shell_call => $shell_call,
				}});
			}
			elsif (not -x $program)
			{
				$found = 0;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0142", variables => {
					program    => $program,
					shell_call => $shell_call,
				}});
			}
		}
		
		if ($found)
		{
			# Make the system call
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, key => "log_0011", variables => { shell_call => $shell_call }});
			### TODO: We should split the arguments off, which the below does, to pass arguments 
			###       to the shell without having the shell expand the arguments
			my $program   = $shell_call;
			my $arguments = "";
			if ($shell_call =~ /^(\/.*?) (.*)$/)
			{
				$program   = $1;
				$arguments = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 
					"s1:program"   => $program,
					"s2:arguments" => $arguments, 
				}});
			}
			
			if ($timeout)
			{
				# Prepend a timeout.
				$shell_call = $anvil->data->{path}{exe}{timeout}." ".$timeout." ".$shell_call;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { shell_call => $shell_call }});
			}
			
			if ($background)
			{
				# Prepend '/tmp/' to STDOUT and/or STDERR output files, if needed.
				if (($stderr_file) && ($stderr_file !~ /^\//))
				{
					$stderr_file = "/tmp/".$stderr_file;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { stderr_file => $stderr_file }});
				}
				if (($stdout_file) && ($stdout_file !~ /^\//))
				{
					$stdout_file = "/tmp/".$stdout_file;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { stdout_file => $stdout_file }});
				}
				my $process = Proc::Simple->new();
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { process => $process }});
				
				# Setup output files
				if (($stderr_file) && ($stdout_file))
				{
					$process->redirect_output($stdout_file, $stderr_file);
				}
				elsif ($stdout_file)
				{
					$process->redirect_output($stdout_file, undef);
				}
				elsif ($stderr_file)
				{
					$process->redirect_output(undef, $stderr_file);
				}
				
				# Start the process
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, key => "log_0204", variables => { call => $shell_call }});
				my $status = $process->start($shell_call);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { status => $status }});
				
				# Report that it started with PID.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, key => "log_0205", variables => { call => $shell_call, pid => $process->pid }});
				
				# We'll return the handle instead of output. There's no return code from the
				# program, so set it to 0 to show we initiated the program in the background.
				$return_code = 0;
				$output      = $process;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 
					return_code => $return_code, 
					output      => $output,
				}});
			}
			else
			{
				$output = "";
				open (my $file_handle, $shell_call.$redirect."; ".$anvil->data->{path}{exe}{echo}." return_code:\$? |") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => $secure, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
				while(<$file_handle>)
				{
					chomp;
					my $line =  $_;
					   $line =~ s/\n$//;
					   $line =~ s/\r$//;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, key => "log_0017", variables => { line => $line }});
					if ($line =~ /^return_code:(\d+)$/)
					{
						$return_code = $1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
					}
					elsif ($line =~ /return_code:(\d+)$/)
					{
						# If the output of the shell call doesn't end in a newline, 
						# the return_code:X could be appended. This catches those 
						# cases and removes it.
						$return_code =  $1;
						$line        =~ s/return_code:\d+$//;
						$output      .= $line."\n";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							line        => $line, 
							output      => $output, 
							return_code => $return_code, 
						}});
					}
					else
					{
						$output .= $line."\n";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
					}
				}
				close $file_handle;
				chomp($output);
				$output =~ s/\n$//s;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	return($output, $return_code);
}


=head2 change_shell_user_password

This changes the password for a shell user account. It can change the password on either the local or a remote machine.

The return code will be C<< 255 >> on internal error. Otherwise, it will be the code returned from the C<< passwd >> call.

B<< Note >>; The password is salted and (sha-512, C<< $6$<salt>$<hash>$ >>

Parameters;

=head3 new_password (required)

This is the new password to set. The user should be encouraged to select a good (long) password.

=head3 password (optional)

If you are changing the password of a user on a remote machine, this is the password used to connect to that machine. If not passed, an attempt to connect with passwordless SSH will be made (but this won't be the case in most instances). Ignored if C<< target >> is not given.

=head3 port (optional, default 22)

This is the TCP port number to use if connecting to a remote machine over SSH. Ignored if C<< target >> is not given.

=head3 remote_user (optional, default root)

If C<< target >> is set and we're changing the password for a remote user, this is the user we B<< log into >> the remote machine as, B<< not >> the user whose password we will change.

=head3 target (optional)

This is the IP address or (resolvable) host name of the target machine whose user account you want to change the password 

=head3 user (required)

This is the user name whose password is being changed.

=cut
sub change_shell_user_password
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->change_shell_user_password()" }});
	
	my $new_password = defined $parameter->{new_password} ? $parameter->{new_password} : "";
	my $password     = defined $parameter->{password}     ? $parameter->{password}     : "";
	my $port         = defined $parameter->{port}         ? $parameter->{port}         : "";
	my $remote_user  = defined $parameter->{remote_user}  ? $parameter->{remote_user}  : "root";
	my $target       = defined $parameter->{target}       ? $parameter->{target}       : "";
	my $user         = defined $parameter->{user}         ? $parameter->{user}         : "";
	my $return_code  = 255;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		user         => $user, 
		target       => $target, 
		port         => $port, 
		remote_user  => $remote_user, 
		new_password => $anvil->Log->is_secure($new_password), 
		password     => $anvil->Log->is_secure($password), 
	}});
	
	# Do I have a user?
	if (not $user)
	{
		# Woops!
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->change_shell_user_password()", parameter => "user" }});
		return($return_code);
	}
	
	# OK, what about a password?
	if (not $new_password)
	{
		# Um...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->change_shell_user_password()", parameter => "new_password" }});
		return($return_code);
	}
	
	# Only the root user can do this!
	# $< == real UID, $> == effective UID
	if (($< != 0) && ($> != 0))
	{
		# Not root
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0156", variables => { method => "Systeme->change_shell_user_password()" }});
		return($return_code);
	}
	
	# Generate a salt and then use it to create a hash.
	(my $salt, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{openssl}." rand 1000 | ".$anvil->data->{path}{exe}{strings}." | ".$anvil->data->{path}{exe}{'grep'}." -io [0-9A-Za-z\.\/] | ".$anvil->data->{path}{exe}{head}." -n 16 | ".$anvil->data->{path}{exe}{'tr'}." -d '\\n'" });
	my $new_hash             = crypt($new_password,"\$6\$".$salt."\$");
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		salt        => $salt, 
		new_hash    => $new_hash, 
		return_code => $return_code, 
	}});
	
	# Update the password using 'usermod'. NOTE: The single-quotes are crtical!
	my $output     = "";
	my $error      = "";
	my $shell_call = $anvil->data->{path}{exe}{usermod}." --password '".$new_hash."' ".$user;
	if ($target)
	{
		# Remote call.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
			return_code => $return_code, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error  => $error,
			output => $output,
		}});
	}
	else
	{
		# Local call
		($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
	}
	
	return($return_code);
}


=head2 check_daemon

This method checks to see if a daemon is running or not. If it is, it returns 'C<< 1 >>'. If the daemon isn't running, it returns 'C<< 0 >>'. If the daemon wasn't found, 'C<< 2 >>' is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to check. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub check_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->check_daemon()" }});
	
	my $return = 2;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
	}
	if ($return_code eq "3")
	{
		# Stopped
		$return = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	}
	elsif ($return_code eq "0")
	{
		# Running
		$return = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
}

=head2 check_if_configured

This returns C<< 1 >> is the system has finished initial configuration, and C<< 0 >> if not.

This method takes no parameters.

=cut
sub check_if_configured
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->check_if_configured()" }});
	
	my ($configured, $variable_uuid, $modified_date) = $anvil->Database->read_variable({
		variable_name         => "system::configured", 
		variable_source_uuid  => $anvil->Get->host_uuid, 
		variable_source_table => "hosts", 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		configured    => $configured, 
		variable_uuid => $variable_uuid, 
		modified_date => $modified_date, 
	}});
	
	$configured = 0 if not defined $configured;
	$configured = 0 if $configured eq "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { configured => $configured }});
	return($configured);
}

=head2 check_memory

This calls 'anvil-check-memory' with the given program name, and looks at the output to see how much RAM that program uses (if it is even running).

Parameters;

=head3 program_name (required)

This is the name of the program (as seen in the output of C<< ps aux >>) to check the RAM of.

=cut
sub check_memory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->check_memory()" }});
	
	my $program_name = defined $parameter->{program_name} ? $parameter->{program_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { program_name => $program_name }});
	if (not $program_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0086"});
		return("");
	}
	
	my $used_ram = 0;
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'anvil-check-memory'}." --program $program_name".$anvil->Log->switches});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /= (\d+) /)
		{
			$used_ram = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				used_ram => $anvil->Convert->add_commas({number => $used_ram})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $used_ram}).")",
			}});
		}
	}
	
	return($used_ram);
}


=head2 check_ssh_keys

This method does several things;

1. This makes sure the users on this system have SSH keys, and creates the keys if needed.
2. It records the user's keys in the C<< ssh_keys >> table.
3. For the dashboard machines whose databases this host uses, it adds their host machine public key (SSH fingerprint) to C<< ~/.ssh/known_hosts >>. 
4. If this machine is a node or DR host, it sets up passwordless SSH between the other machines in the same Anvil! system.

This works on the C<< admin >> and C<< root >> users. If the host is a node, it will also work on the c<< hacluster >> user.

B<< Note >>: If a machine's fingerprint changes, this method will NOT update C<< ~/.ssh/known_hosts >>! You will see an alert on the Striker dashboard prompting you to clear the bad keys (or, if that wasn't expected, find the "man in the middle" attacker).

This method takes no parameters.

=cut
sub check_ssh_keys
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->check_ssh_keys()" }});
	
	# We do a couple things here. First we make sure our user's keys are up to date and stored in the 
	# 'ssh_keys' table. Then we look through the 'Get->trusted_hosts' array any other users@hosts we're
	# supposed to trust. For each, we make sure that they're in the appropriate local user's 
	# authorized_keys file.
	
	# Load the host keys and the SSH keys
	$anvil->Database->get_hosts({debug => $debug});
	$anvil->Database->get_ssh_keys({debug => $debug});
	
	# Users to check:
	my $users = ["root", "admin"];
	foreach my $user (@{$users})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
		
		my $user_home = $anvil->Get->users_home({user => $user});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_home => $user_home }});
		
		# If the user doesn't exist, their home directory won't either, so skip.
		next if not $user_home;
		next if not -d $user_home;
		
		# If the user's ~/.ssh directory doesn't exist, we need to create it.
		my $ssh_directory =  $user_home."/.ssh";
		   $ssh_directory =~ s/\/\//\//g;
		if (not -e $ssh_directory)
		{
			# Create it.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0272", variables => { user => $user, directory => $ssh_directory }});
			$anvil->Storage->make_directory({
				debug     => $debug,
				directory => $ssh_directory, 
				user      => $user,
				group     => $user, 
				mode      => "0700",
			});
		}
		
		my $ssh_private_key_file = $user_home."/.ssh/id_rsa";
		my $ssh_public_key_file  = $user_home."/.ssh/id_rsa.pub";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			ssh_public_key_file  => $ssh_public_key_file,
			ssh_private_key_file => $ssh_private_key_file, 
		}});
		if (not -e $ssh_public_key_file)
		{
			# Generate the SSH keys.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0270", variables => { user => $user }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'ssh-keygen'}." -t rsa -N \"\" -b 8191 -f ".$ssh_private_key_file});
			if (-e $ssh_public_key_file)
			{
				# Success!
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0271", variables => { user => $user, output => $output }});
			}
			else
			{
				# Failed?
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "error_0057", variables => { user => $user, output => $output }});
				next;
			}
		}
		
		# Now read in the key.
		my $users_public_key = $anvil->Storage->read_file({
			debug => $debug,
			file  => $ssh_public_key_file,
		});
		$users_public_key =~ s/\n$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { users_public_key => $users_public_key }});
		
		# Now store the key in the 'ssh_key' table, if needed.
		my $ssh_key_uuid = $anvil->Database->insert_or_update_ssh_keys({
			debug              => $debug,
			ssh_key_host_uuid  => $anvil->Get->host_uuid, 
			ssh_key_public_key => $users_public_key, 
			ssh_key_user_name  => $user, 
		});
		
		# Read in the existing 'known_hosts' file, if it exists. The 'old' and 'new' variables will 
		# be used when looking for needed changes.
		my $known_hosts_file_body = "";
		my $known_hosts_old_body  = "";
		my $known_hosts_new_body  = "";
		my $known_hosts_file      = $ssh_directory."/known_hosts";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { known_hosts_file => $known_hosts_file }});
		if (-e $known_hosts_file)
		{
			$known_hosts_file_body = $anvil->Storage->read_file({
				debug => $debug,
				file  => $known_hosts_file,
			});
			$known_hosts_old_body  = $known_hosts_file_body;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { known_hosts_file_body => $known_hosts_file_body }});
		}
		
		# Read in the existing 'authorized_keys' file, if it exists.
		my $authorized_keys_file_body = "";
		my $authorized_keys_old_body  = "";
		my $authorized_keys_new_body  = "";
		my $authorized_keys_file      = $ssh_directory."/authorized_keys";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { authorized_keys_file => $authorized_keys_file }});
		if (-e $authorized_keys_file)
		{
			$authorized_keys_file_body = $anvil->Storage->read_file({
				debug => $debug,
				file  => $authorized_keys_file,
			});
			$authorized_keys_old_body  = $authorized_keys_file_body;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { authorized_keys_file_body => $authorized_keys_file_body }});
		}
		
		# Walk through the Striker dashboards we use. If we're a Node or DR host, walk through our 
		# peers as well. As we we do, loop through the old file body to see if it exists. If it does,
		# and the key has changed, update the line with the new key. If it isn't found, add it. Once
		# we check the old body for this entry, change the "old" body to the new one, then repeat the
		# process.
		my $trusted_host_uuids = $anvil->Get->trusted_hosts();
		
		# Look at all the hosts I know about (other than myself) and see if any of the machine or 
		# user keys either don't exist or have changed.
		my $update_known_hosts        = 0;
		my $update_authorized_keys    = 0;
		my $known_hosts_new_lines     = "";
		my $authorized_keys_new_lines = "";
		
		### TODO: We need to handle all the IP addresses and host names with 
		###       <short_hostname>.<bc|s|ifnX>, while dealing with duplicates.
		# Check for changes to known_hosts
		foreach my $host_uuid (@{$trusted_host_uuids})
		{
			my $host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
			my $host_key  = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				host_name => $host_name, 
				host_uuid => $host_uuid,
				host_key  => $host_key, 
			}});
			
			# If the host_key is 'DELETED', skip if.
			next if $host_key eq "DELETED";
			
			# Is this in the file and, if so, has it changed?
			my $found     = 0;
			my $test_line = $host_name." ".$host_key;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_line => $test_line }});
			foreach my $line (split/\n/, $known_hosts_old_body)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
				if ($line eq $test_line)
				{
					# No change needed, key is the same.
					$found = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
				}
				elsif ($line =~ /^$host_name /)
				{
					# Key has changed, update.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0274", variables => { 
						machine => $host_name, 
						old_key => $line, 
						new_key => $test_line,
						
					}});
					$found              = 1;
					$line               = $test_line;
					$update_known_hosts = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						found              => $found,
						line               => $line, 
						update_known_hosts => $update_known_hosts, 
					}});
				}
				$known_hosts_new_body .= $line."\n";
			}
			
			# If we didn't find the key, add it.
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
			if (not $found)
			{
				$update_known_hosts    =  1;
				$known_hosts_new_lines .= $test_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:update_known_hosts'    => $update_known_hosts, 
					's2:known_hosts_new_lines' => $known_hosts_new_lines, 
				}});
			}
			
			# Move the new body over to the old body (even though it may not have 
			# changed) and then clear the new body to prepare for the next pass.
			$known_hosts_old_body = $known_hosts_new_body;
			$known_hosts_new_body = "";
		}
		
		# Lastly, copy the last version of the old body to the new body,
		$known_hosts_new_body = $known_hosts_old_body.$known_hosts_new_lines;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:update_known_hosts'    => $update_known_hosts, 
			's2:known_hosts_file_body' => $known_hosts_file_body, 
			's3:known_hosts_new_body'  => $known_hosts_new_body, 
			's4:difference'            => diff \$known_hosts_file_body, \$known_hosts_new_body, { STYLE => 'Unified' },
		}});
		
		# Check for changes to authorized_keys
		foreach my $host_uuid (@{$trusted_host_uuids})
		{
			my $host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				host_uuid => $host_uuid,
				host_name => $host_name, 
			}});
			foreach my $user (sort {$a cmp $b} @{$users})
			{
				if ((exists $anvil->data->{ssh_keys}{host_uuid}{$host_uuid}{ssh_key_user_name}{$user}) && ($anvil->data->{ssh_keys}{host_uuid}{$host_uuid}{ssh_key_user_name}{$user}{ssh_key_public_key}))
				{
					my $ssh_key_public_key = $anvil->data->{ssh_keys}{host_uuid}{$host_uuid}{ssh_key_user_name}{$user}{ssh_key_public_key};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:user'               => $user,
						's2:host_name'          => $host_name, 
						's3:ssh_key_public_key' => $ssh_key_public_key,
					}});
					
					# The key in the file might have a different trailing suffix (user@host_name)
					# and doesn't really matter. So we search by the key type and public key to 
					# see if it exists already.
					my $found     = 0;
					my $test_line = ($ssh_key_public_key =~ /^(ssh-.*? .*?) /)[0];
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_line => $test_line }});
					foreach my $line (split/\n/, $authorized_keys_old_body)
					{
						# NOTE: Use '\Q...\E' so that the '+' characters in the key aren't 
						#       evaluated as part of the regex.
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
						if ($line =~ /^\Q$test_line\E/)
						{
							# No change needed, key is the same.
							$found = 1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
						}
						$authorized_keys_new_body .= $line."\n";
					}
					# If we didn't find the key, add it.
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
					if (not $found)
					{
						$update_authorized_keys    =  1;
						$authorized_keys_new_lines .= $ssh_key_public_key."\n";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:update_authorized_keys'    => $update_authorized_keys, 
							's2:authorized_keys_new_lines' => $authorized_keys_new_lines, 
						}});
					}
					
					# Move the new body over to the old body (even though it may not have 
					# changed) and then clear the new body to prepare for the next pass.
					$authorized_keys_old_body = $authorized_keys_new_body;
					$authorized_keys_new_body = "";
				}
			}
		}
		
		# Lastly, copy the last version of the old body to the new body,
		$authorized_keys_new_body = $authorized_keys_old_body.$authorized_keys_new_lines;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:update_authorized_keys'    => $update_authorized_keys, 
			's2:authorized_keys_file_body' => $authorized_keys_file_body, 
			's3:authorized_keys_new_body'  => $authorized_keys_new_body, 
			's4:difference'                => diff \$authorized_keys_file_body, \$authorized_keys_new_body, { STYLE => 'Unified' },
		}});
		
		# Update the known_hosts files, if needed.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_known_hosts => $update_known_hosts }});
		if ($update_known_hosts)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0273", variables => { user => $user, file => $known_hosts_file }});
			if (-e $known_hosts_file)
			{
				my $backup_file = $anvil->Storage->backup({
					debug => $debug,
					fatal => 1, 
					file  => $known_hosts_file, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { backup_file => $backup_file }});
				if (-e $backup_file)
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0154", variables => { source_file => $known_hosts_file, target_file => $backup_file }});
				}
				else
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "error_0058", variables => { file => $known_hosts_file }});
				}
			}
			my $failed = $anvil->Storage->write_file({
				debug     => $debug,
				overwrite => 1, 
				file      => $known_hosts_file, 
				body      => $known_hosts_new_body, 
				user      => $user, 
				group     => $user, 
				mode      => "0644", 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		}
		
		# Update the authorized_keys files, if needed.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_authorized_keys => $update_authorized_keys }});
		if ($update_authorized_keys)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0273", variables => { user => $user, file => $authorized_keys_file }});
			if (-e $authorized_keys_file)
			{
				my $backup_file = $anvil->Storage->backup({
					debug => $debug,
					fatal => 1, 
					file  => $authorized_keys_file, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { backup_file => $backup_file }});
				if (-e $backup_file)
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0154", variables => { source_file => $authorized_keys_file, target_file => $backup_file }});
				}
				else
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "error_0058", variables => { file => $authorized_keys_file }});
				}
			}
			my $failed = $anvil->Storage->write_file({
				debug     => $debug,
				overwrite => 1, 
				file      => $authorized_keys_file, 
				body      => $authorized_keys_new_body, 
				user      => $user, 
				group     => $user, 
				mode      => "0644", 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		}
	}
	
	return(0);
}


=head2 check_storage

Thic gathers LVM data from the local system.

Parameters;

=head4 scan (optional, default '1')

Setting this to C<< 0 >> will disable scanning prior to data collection. When enabled, C<< pvscan; vgscan; lvscan >> are called before the C<< pvs >>, C<< vgs >> and C<< lvs >> calls used to collect the data this parses.

=cut
sub check_storage
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->check_storage()" }});
	
	my $scan = defined $parameter->{scan} ? $parameter->{scan} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { scan => $scan }});
	
	# Do a scan, if requested.
	if ($scan)
	{
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{pvscan}." 2>/dev/null"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output          => $output,
			return_code     => $return_code, 
			redirect_stderr => 0, 
		}});
		
		$output      = "";
		$return_code = "";
		($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{vgscan}." 2>/dev/null"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output          => $output,
			return_code     => $return_code, 
			redirect_stderr => 0, 
		}});
		
		$output      = "";
		$return_code = "";
		($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{lvscan}." 2>/dev/null"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output          => $output,
			return_code     => $return_code, 
			redirect_stderr => 0, 
		}});
	}
	
	### NOTE: In case: 'lvm.conf -> filter = [ "r|/dev/drbd.*|" ]' isn't set, we'll get warnings about 
	###       DRBD devices being "wrong medium type" when Secondary. We check for and ignore these 
	###       warnings.
	# Gather PV data.
	my $host = $anvil->Get->short_host_name();
	my ($pvs_output, $pvs_return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{pvs}." --units b --noheadings --separator \\\#\\\!\\\# -o pv_name,vg_name,pv_fmt,pv_attr,pv_size,pv_free,pv_used,pv_uuid 2>/dev/null"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		pvs_output      => $pvs_output,
		pvs_return_code => $pvs_return_code, 
		redirect_stderr => 0, 
	}});
	foreach my $line (split/\n/, $pvs_output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		next if $line =~ /Wrong medium type/i;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		my ($this_pv, $used_by_vg, $format, $attributes, $total_size, $free_size, $used_size, $uuid) = (split /#!#/, $line);
		$total_size =~ s/B$//;
		$free_size  =~ s/B$//;
		$used_size  =~ s/B$//;
		
		$anvil->data->{lvm}{$host}{pv}{$this_pv}{used_by_vg} = $used_by_vg;
		$anvil->data->{lvm}{$host}{pv}{$this_pv}{attributes} = $attributes;
		$anvil->data->{lvm}{$host}{pv}{$this_pv}{total_size} = $total_size;
		$anvil->data->{lvm}{$host}{pv}{$this_pv}{free_size}  = $free_size;
		$anvil->data->{lvm}{$host}{pv}{$this_pv}{used_size}  = $used_size;
		$anvil->data->{lvm}{$host}{pv}{$this_pv}{uuid}       = $uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::${host}::pv::${this_pv}::used_by_vg" => $anvil->data->{lvm}{$host}{pv}{$this_pv}{used_by_vg},
			"lvm::${host}::pv::${this_pv}::attributes" => $anvil->data->{lvm}{$host}{pv}{$this_pv}{attributes},
			"lvm::${host}::pv::${this_pv}::total_size" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{pv}{$this_pv}{total_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{pv}{$this_pv}{total_size}}).")",
			"lvm::${host}::pv::${this_pv}::free_size"  => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{pv}{$this_pv}{free_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{pv}{$this_pv}{free_size}}).")",
			"lvm::${host}::pv::${this_pv}::used_size"  => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{pv}{$this_pv}{used_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{pv}{$this_pv}{used_size}}).")",
			"lvm::${host}::pv::${this_pv}::uuid"       => $anvil->data->{lvm}{$host}{pv}{$this_pv}{uuid},
		}});
	}
	
	# Gather VG data.
	my ($vgs_output, $vgs_return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{vgs}." --units b --noheadings --separator \\\#\\\!\\\# -o vg_name,vg_attr,vg_extent_size,vg_extent_count,vg_uuid,vg_size,vg_free_count,vg_free,pv_name 2>/dev/null"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		vgs_output      => $vgs_output,
		vgs_return_code => $vgs_return_code, 
		redirect_stderr => 0, 
	}});
	foreach my $line (split/\n/, $vgs_output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		next if $line =~ /Wrong medium type/i;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		my ($this_vg, $attributes, $pe_size, $total_pe, $uuid, $vg_size, $free_pe, $vg_free, $pv_name) = split /#!#/, $line;
		$pe_size    = "" if not defined $pe_size;
		$vg_size    = "" if not defined $vg_size;
		$vg_free    = "" if not defined $vg_free;
		$attributes = "" if not defined $attributes;
		
		$pe_size =~ s/B$//;
		$vg_size =~ s/B$//;
		$vg_free =~ s/B$//;
		
		my $used_pe = 0;
		if (($total_pe) && ($free_pe))
		{
			$used_pe = $total_pe - $free_pe;
		}
		my $used_space = 0;
		if (($vg_size) && ($vg_free))
		{
			$used_space = $vg_size - $vg_free;
		}
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{pe_size}    = $pe_size;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{total_pe}   = $total_pe;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{uuid}       = $uuid;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{size}       = $vg_size;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{used_pe}    = $used_pe;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{used_space} = $used_space;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{free_pe}    = $free_pe;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{free_space} = $vg_free;
		$anvil->data->{lvm}{$host}{vg}{$this_vg}{pv_name}    = $pv_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::${host}::vg::${this_vg}::pe_size"    => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{vg}{$this_vg}{pe_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{vg}{$this_vg}{pe_size}}).")",
			"lvm::${host}::vg::${this_vg}::total_pe"   => $anvil->data->{lvm}{$host}{vg}{$this_vg}{total_pe},
			"lvm::${host}::vg::${this_vg}::uuid"       => $anvil->data->{lvm}{$host}{vg}{$this_vg}{uuid},
			"lvm::${host}::vg::${this_vg}::size"       => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{vg}{$this_vg}{size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{vg}{$this_vg}{size}}).")",
			"lvm::${host}::vg::${this_vg}::used_pe"    => $anvil->data->{lvm}{$host}{vg}{$this_vg}{used_pe},
			"lvm::${host}::vg::${this_vg}::used_space" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{vg}{$this_vg}{used_space}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{vg}{$this_vg}{used_space}}).")",
			"lvm::${host}::vg::${this_vg}::free_pe"    => $anvil->data->{lvm}{$host}{vg}{$this_vg}{free_pe},
			"lvm::${host}::vg::${this_vg}::free_space" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{vg}{$this_vg}{free_space}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{vg}{$this_vg}{free_space}}).")",
			"lvm::${host}::vg::${this_vg}::pv_name"    => $anvil->data->{lvm}{$host}{vg}{$this_vg}{pv_name},
		}});
	}
	
	# And finally, the LV data.
	my ($lvs_output, $lvs_return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{lvs}." --units b --noheadings --separator \\\#\\\!\\\# -o lv_name,vg_name,lv_attr,lv_size,lv_uuid,lv_path,devices 2>/dev/null"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		lvs_output      => $lvs_output,
		lvs_return_code => $lvs_return_code, 
		redirect_stderr => 0, 
	}});
	foreach my $line (split/\n/, $lvs_output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		next if $line =~ /Wrong medium type/i;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		my ($lv_name, $on_vg, $attributes, $total_size, $uuid, $path, $devices) = (split /#!#/, $line);

		$total_size =~ s/B$//;
		$devices    =~ s/\(\d+\)//g;	# Strip the starting PE number

		$anvil->data->{lvm}{$host}{lv}{$path}{name}       = $lv_name;
		$anvil->data->{lvm}{$host}{lv}{$path}{on_vg}      = $on_vg;
		$anvil->data->{lvm}{$host}{lv}{$path}{active}     = ($attributes =~ /.{4}(.{1})/)[0] eq "a" ? 1 : 0;
		$anvil->data->{lvm}{$host}{lv}{$path}{attributes} = $attributes;
		$anvil->data->{lvm}{$host}{lv}{$path}{total_size} = $total_size;
		$anvil->data->{lvm}{$host}{lv}{$path}{uuid}       = $uuid;
		$anvil->data->{lvm}{$host}{lv}{$path}{on_devices} = $devices;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::${host}::lv::${path}::name"       => $anvil->data->{lvm}{$host}{lv}{$path}{name},
			"lvm::${host}::lv::${path}::on_vg"      => $anvil->data->{lvm}{$host}{lv}{$path}{on_vg},
			"lvm::${host}::lv::${path}::active"     => $anvil->data->{lvm}{$host}{lv}{$path}{active},
			"lvm::${host}::lv::${path}::attributes" => $anvil->data->{lvm}{$host}{lv}{$path}{attributes},
			"lvm::${host}::lv::${path}::total_size" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{$host}{lv}{$path}{total_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{$host}{lv}{$path}{total_size}}).")",
			"lvm::${host}::lv::${path}::uuid"       => $anvil->data->{lvm}{$host}{lv}{$path}{uuid},
			"lvm::${host}::lv::${path}::on_devices" => $anvil->data->{lvm}{$host}{lv}{$path}{on_devices},
		}});
	}
	
	return(0);
}


=head2 collect_ipmi_data

This takes an C<< ipmitool >> command (for access, not including ending command or password!) and calls thae target IPMI BMC. The returned data is collected and parsed.

If failed to access, C<< 1 >> is returned. If there is a problem, C<< !!error!! >> is returned. If data is collected, C<< 0 >> is returned. 

Recorded data is stored as:

 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_value_sensor_value
 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_sensor_units
 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_sensor_status
 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_sensor_high_critical
 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_sensor_high_warning
 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_sensor_low_critical
 ipmi::<host_name>::scan_ipmitool_sensor_name::$sensor_name::scan_ipmitool_sensor_low_warning

parameters;

=head3 host_name (required)

This is the name used to store the target's information. Generally, this should be the C<< host_name >> value for the target machine, as stored in C<< hosts >>.

=head3 ipmitool_command (required)

This is the C<< ipmitool >> command used to authenticate against and access the target BMC. This must not contain the password, or the command to run on the BMC. Those parts are handled by this method.

=head3 ipmi_password (optional)

If the target BMC requires a password (and they usually do...), the password will be written to a temporary file, and C<< -f <temp_file > >> will be used as part of the final C<< ipmitool >> command call. As soon as the call returns, the temp file is deleted.

=cut
sub collect_ipmi_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->collect_ipmi_data()" }});
	
	my $host_name        = defined $parameter->{host_name}        ? $parameter->{host_name}        : "";
	my $ipmitool_command = defined $parameter->{ipmitool_command} ? $parameter->{ipmitool_command} : "";
	my $ipmi_password    = defined $parameter->{ipmi_password}    ? $parameter->{ipmi_password}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_name        => $host_name,
		ipmitool_command => $ipmitool_command, 
		ipmi_password    => $anvil->Log->is_secure($ipmi_password), 
	}});
	
	if (not $host_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->collect_ipmi_data()", parameter => "host_name" }});
		return('!!error!!');
	}
	if (not $ipmitool_command)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->collect_ipmi_data()", parameter => "ipmitool_command" }});
		return('!!error!!');
	}
	
	my $read_start_time = time;
	
	# If there is a password, write it to a temp file.
	my $problem   = 1;
	my $temp_file = "";
	if ($ipmi_password)
	{
		# Write the password to a temp file.
		$temp_file = "/tmp/scancore.".$anvil->Get->uuid({short => 1});
		$anvil->Storage->write_file({
			debug     => 2,
			body      => $ipmi_password,
			secure    => 1,
			file      => $temp_file,
			overwrite => 1,
		});
	}
	
	# Call with a timeout in case the call hangs.
	my $shell_call = $ipmitool_command." sensor list all";
	if ($ipmi_password)
	{
		$shell_call = $ipmitool_command." -f ".$temp_file." sensor list all";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({timeout => 30, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => {
		output      => $output, 
		return_code => $return_code,
	}});
	
	my $delete_entries   = [];
	my $duplicate_exists = 0;
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { ">> line" => $line }});
		
		# Clean up the output
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		$line =~ s/\s+\|/|/g;
		$line =~ s/\|\s+/|/g;
		
		### TODO: If we determine that the IPMI BMC is hung, set the health to '10'
		###       $anvil->data->{'scan-ipmitool'}{health}{new}{'ipmi:bmc_controller'} = 10;
		# Catch errors:
		if ($line =~ /Activate Session command failed/)
		{
			# Failed to connect.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "scan_ipmitool_log_0002", variables => { 
				host_name => $host_name, 
				call      => $ipmitool_command, 
			}});
		}
		next if $line !~ /\|/;
		
		if ($problem)
		{
			$problem = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => {problem => $problem }});
		}
		
		#     high fail -------------------------------------.
		# high critical ---------------------------------.   |
		#  high warning -----------------------------.   |   |
		#   low warning -------------------------.   |   |   |
		#  low critical ---------------------.   |   |   |   |
		#      low fail -----------------.   |   |   |   |   |
		#        status -------------.   |   |   |   |   |   |
		#         units ---------.   |   |   |   |   |   |   |
		# current value -----.   |   |   |   |   |   |   |   |
		#   sensor name -.   |   |   |   |   |   |   |   |   |
		# Columns:       |   |   |   |   |   |   |   |   |   |
		#                x | x | x | x | x | x | x | x | x | x 
		my ($sensor_name, 
			$current_value, 
			$units, 
			$status, 
			$low_fail, 
			$low_critical, 
			$low_warning, 
			$high_warning, 
			$high_critical, 
			$high_fail) = split /\|/, $line;
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			sensor_name   => $sensor_name, 
			current_value => $current_value, 
			units         => $units, 
			status        => $status, 
			low_fail      => $low_fail, 
			low_critical  => $low_critical, 
			low_warning   => $low_warning, 
			high_warning  => $high_warning, 
			high_critical => $high_critical, 
			high_fail     => $high_fail, 
		}});
		
		next if not $sensor_name;
		next if not $status;
		next if not $units;
		next if $units =~ /discrete/;
		
		$units = "C" if $units =~ /degrees C/i;
		$units = "F" if $units =~ /degrees F/i;
		$units = "%" if $units =~ /percent/i;
		$units = "W" if $units =~ /watt/i;
		$units = "V" if $units =~ /volt/i;
		
		# The BBU and RAID Controller, as reported by IPMI, is flaky and redundant. We 
		# monitor it via storcli/hpacucli (or OEM variant of), so we ignore it here.
		next if $sensor_name eq "BBU";
		next if $sensor_name eq "RAID Controller";
		
		# HP seems to stick 'XX-' in front of some sensor names.
		$sensor_name =~ s/^\d\d-//;
		
		# Single PSU hosts often call their PSU just that, without a suffix integer. We'll 
		# add '1' in such cases.
		if ($sensor_name eq "PSU")
		{
			$sensor_name = "PSU1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { sensor_name => $sensor_name }});
		}
		
		if (exists $anvil->data->{seen_sensors}{$sensor_name})
		{
			$duplicate_exists                                     = 1;
			$anvil->data->{seen_sensors}{$sensor_name}{duplicate} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				duplicate_exists                          => $duplicate_exists,
				"seen_sensors::${sensor_name}::duplicate" => $anvil->data->{seen_sensors}{$sensor_name}{duplicate}, 
			}});
			
			push @{$delete_entries}, $sensor_name;
		}
		else
		{
			$anvil->data->{seen_sensors}{$sensor_name}{duplicate} = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				"seen_sensors::${sensor_name}::duplicate" => $anvil->data->{seen_sensors}{$sensor_name}{duplicate}, 
			}});
		}
		
		# Thresholds that are 'na' need to be converted to numeric
		$low_fail      = -99 if $low_fail      eq "na";
		$low_critical  = -99 if $low_critical  eq "na";
		$low_warning   = -99 if $low_warning   eq "na";
		$high_warning  = 999 if $high_warning  eq "na";
		$high_critical = 999 if $high_critical eq "na";
		$high_fail     = 999 if $high_fail     eq "na";
		
		# Values in the DB that are 'double precision' must be '' if not set.
		$current_value = '' if not $current_value;
		$low_fail      = '' if not $low_fail;
		$low_critical  = '' if not $low_critical;
		$low_warning   = '' if not $low_warning;
		$high_warning  = '' if not $high_warning;
		$high_critical = '' if not $high_critical;
		$high_fail     = '' if not $high_fail;
		
		# Some values list 'inf' on some machines (HP...). Convert these to ''.
		$current_value = '' if $current_value eq "inf";
		$low_fail      = '' if $low_fail      eq "inf";
		$low_critical  = '' if $low_critical  eq "inf";
		$low_warning   = '' if $low_warning   eq "inf";
		$high_warning  = '' if $high_warning  eq "inf";
		$high_critical = '' if $high_critical eq "inf";
		$high_fail     = '' if $high_fail     eq "inf";
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			sensor_name   => $sensor_name, 
			current_value => $current_value, 
			units         => $units, 
			status        => $status, 
			low_fail      => $low_fail, 
			low_critical  => $low_critical, 
			low_warning   => $low_warning, 
			high_warning  => $high_warning, 
			high_critical => $high_critical, 
			high_fail     => $high_fail, 
		}});
		
		if ($units eq "F")
		{
			# Convert to 'C'
			$high_critical = $anvil->Convert->fahrenheit_to_celsius({temperature => $high_critical}) if $high_critical ne "";
			$high_warning  = $anvil->Convert->fahrenheit_to_celsius({temperature => $high_warning})  if $high_warning  ne "";
			$low_critical  = $anvil->Convert->fahrenheit_to_celsius({temperature => $low_critical})  if $low_critical  ne "";
			$low_warning   = $anvil->Convert->fahrenheit_to_celsius({temperature => $low_warning})   if $low_warning   ne "";
			$units         = "C";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				low_critical  => $low_critical, 
				low_warning   => $low_warning, 
				high_warning  => $high_warning, 
				high_critical => $high_critical, 
				units         => $units, 
			}});
		}
		
		### TODO: It looks like the PSU state and the PSU temperature are called, simply, 
		###       'PSUx'... If so, change the temperature to 'PSUx Temperature'
		if (($units eq "C") && ($sensor_name =~ /^PSU\d/i))
		{
			$sensor_name .= " Temperature";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { sensor_name => $sensor_name }});
		}
		
		# Similarly, 'PSUx Power' is used for power status and wattage....
		if (($units eq "W") && ($sensor_name =~ /PSU\d Power/i))
		{
			$sensor_name =~ s/Power/Wattage/;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { sensor_name => $sensor_name }});
		}
		
		# And again, 'FAN PSUx' is used for both RPM and state...
		if (($units eq "RPM") && ($sensor_name =~ /^FAN PSU\d/i))
		{
			$sensor_name .= " RPM";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { sensor_name => $sensor_name }});
		}
		
		# Record
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_value_sensor_value}   = $current_value;
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_units}         = $units;
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_status}        = $status;
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_high_critical} = $high_critical;
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_high_warning}  = $high_warning;
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_low_critical}  = $low_critical;
		$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_low_warning}   = $low_warning;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_value_sensor_value"   => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_value_sensor_value}, 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_sensor_units"         => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_units}, 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_sensor_status"        => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_status}, 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_sensor_high_critical" => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_high_critical}, 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_sensor_high_warning"  => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_high_warning}, 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_sensor_low_critical"  => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_low_critical}, 
			"ipmi::${host_name}::scan_ipmitool_sensor_name::${sensor_name}::scan_ipmitool_sensor_low_warning"   => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_low_warning}, 
		}});
	}
	
	### NOTE: This is a dirty hack... It assumes the duplicates share the same thresholds, which works 
	###       for the 'Temp' duplicates, but could well not apply to future duplicates. The real fix is
	###       for hardware vendors to not duplicate sensor names.
	# If there were two or more sensors with the same name, call 'ipmitool sdr elist' and change their 
	# names to include the address and pull the values from here.
	if ($duplicate_exists)
	{
		my $shell_call = $ipmitool_command." sdr elist full";
		if ($ipmi_password)
		{
			$shell_call = $ipmitool_command." -f ".$temp_file." sdr elist full";
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
		
		my ($output, $return_code) = $anvil->System->call({timeout => 30, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => {
			output      => $output, 
			return_code => $return_code,
		}});
		
		my $duplicate_exists = 0;
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { ">> line" => $line }});
			
			# Clean up the output
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			$line =~ s/\s+\|/|/g;
			$line =~ s/\|\s+/|/g;
			
			# current value -----------------.
			#     entity ID -------------.   |
			#        status ---------.   |   |
			#   Hex address -----.   |   |   |
			#   sensor name -.   |   |   |   |
			# Columns:       |   |   |   |   |
			#                x | x | x | x | x 
			my ($sensor_name, 
			    $hex_address,
			    $status, 
			    $entity_id, 
			    $current_value) = split /\|/, $line;
			next if not $sensor_name;
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				sensor_name   => $sensor_name, 
				hex_address   => $hex_address, 
				status        => $status, 
				entity_id     => $entity_id, 
				current_value => $current_value, 
			}});
			
			# This is a duplicate, over write the name 
			if ((exists $anvil->data->{seen_sensors}{$sensor_name}) && ($anvil->data->{seen_sensors}{$sensor_name}{duplicate}))
			{
				my $units = "";
				if ($current_value =~ /^(.*?)\s+degrees C/)
				{
					$current_value = $1;
					$units         = "degrees C";
				}
				if ($current_value =~ /^(.*?)\s+Volts/)
				{
					$current_value = $1;
					$units         = "V";
				}
				my $new_sensor_name = $sensor_name." (".$hex_address.")";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					new_sensor_name => $new_sensor_name, 
					current_value   => $current_value, 
				}});
				
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_value_sensor_value}   = $current_value;
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_units}         = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_units};
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_status}        = $status;
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_high_critical} = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_high_critical};
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_high_warning}  = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_high_warning};
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_low_critical}  = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_low_critical};
				$anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_low_warning}   = $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name}{scan_ipmitool_sensor_low_warning};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_value_sensor_value"   => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_value_sensor_value}, 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_sensor_units"         => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_units}, 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_sensor_status"        => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_status}, 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_sensor_high_critical" => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_high_critical}, 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_sensor_high_warning"  => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_high_warning}, 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_sensor_low_critical"  => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_low_critical}, 
					"ipmi::${host_name}::scan_ipmitool_sensor_name::${new_sensor_name}::scan_ipmitool_sensor_low_warning"   => $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$new_sensor_name}{scan_ipmitool_sensor_low_warning}, 
				}});
			}
		}
		
		# Delete duplicate sensor names 
		foreach my $sensor_name (@{$delete_entries})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { sensor_name => $sensor_name }});
			delete $anvil->data->{ipmi}{$host_name}{scan_ipmitool_sensor_name}{$sensor_name};
		}
	}
	
	# Delete the temp file.
	unlink $temp_file;
	
	# Record how long it took.
	my $sensor_read_time = (time - $read_start_time);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { sensor_read_time => $sensor_read_time }});
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "scan_ipmitool_log_0003", variables => { 
		host_name => $host_name, 
		'time'    => $anvil->Convert->time({'time' => $sensor_read_time}),
	}});
	
	return($problem);
}


=head2 configure_ipmi

This uses the host information along with the Anvil! the host is in to find and configure the local IPMI BMC.

If this host is not in an Anvil!, or if the host is in an Anvil!, but no IPMI BMC was found, or any other issue arises, C<< 0 >> is returned. If there is any problem, C<< !!error!! >> will be returned.

If a BMC is found and configured, the C<< fence_ipmilan >> call used to check the status is stored in C<< hosts >> -> C<< host_ipmi >>, and the same string is returned.

B<< NOTE >>: The password used to set the IPMI BMC access is included both in the database table and the returned string.

Parameters;

=head3 manifest_uuid (Optional, default sys::manifest_uuid)

The C<< manifests >> -> C<< manifest_uuid >> used to pull out configuration data. This is required, but in most cases, it can be determined if not passed. 

If not passed, C<< sys::manifest_uuid >> is checked. If this is set, it is used. If this isn't set either, the call will fail.

=cut
sub configure_ipmi
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->configure_ipmi()" }});
	
	my $manifest_uuid = defined $parameter->{manifest_uuid} ? $parameter->{manifest_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		manifest_uuid => $manifest_uuid,
	}});
	
	if ((not $manifest_uuid) && (exists $anvil->data->{sys}{manifest_uuid}) && ($anvil->data->{sys}{manifest_uuid}))
	{
		$manifest_uuid = $anvil->data->{sys}{manifest_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
	}
	if (not $manifest_uuid)
	{
		# Nothing more we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->configure_ipmi()", parameter => "manifest_uuid" }});
		return(0);
	}
	
	# Is this host in an Anvil!?
	$anvil->Database->get_hosts();
	$anvil->Database->get_anvils();
	
	my $anvil_uuid = "";
	my $host_uuid  = $anvil->Get->host_uuid;
	if ((exists $anvil->data->{hosts}{host_uuid}{$host_uuid}) && ($anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_uuid}))
	{
		# We're in an Anvil! 
		$anvil_uuid = $anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
	}
	else
	{
		# Not in an Anvil!, return 0.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0498"});
		return(0);
	}
	
	# Look for a match in the anvils table for this host uuid.
	my $machine = "";
	if ($anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid} eq $host_uuid)
	{
		$machine = "node1";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { machine => $machine }});
	}
	elsif ($anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid} eq $host_uuid)
	{
		$machine = "node2";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { machine => $machine }});
	}
	elsif ($anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_dr1_host_uuid} eq $host_uuid)
	{
		$machine = "dr1";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { machine => $machine }});
	}
	
	if (not $machine)
	{
		# Look for a job for 'anvil-join-anvil' for this host. With it, we'll figure out the password
		# and which machine we are.
		my $query = "
SELECT 
    job_uuid, 
    job_data
FROM 
    jobs 
WHERE 
    job_command LIKE '\%anvil-join-anvil' 
AND 
    job_host_uuid = ".$anvil->Database->quote($host_uuid)." 
ORDER BY 
    modified_date DESC 
LIMIT 1
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		my $job_uuid = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		my $job_data = defined $results->[0]->[1] ? $results->[0]->[1] : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			job_uuid => $job_uuid, 
			job_data => $anvil->Log->is_secure($job_data), 
		}});
		if (not $job_uuid)
		{
			# Unable to proceed.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0501"});
			return(0);
		}
		
		($machine, $manifest_uuid, $anvil_uuid) = ($job_data =~ /as_machine=(.*?),manifest_uuid=(.*?),anvil_uuid=(.*?)$/);
		$machine       = "" if not defined $machine;
		$manifest_uuid = "" if not defined $manifest_uuid;
		$anvil_uuid    = "" if not defined $anvil_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			machine       => $machine,
			manifest_uuid => $manifest_uuid, 
			anvil_uuid    => $anvil_uuid, 
		}});
	}
	
	# Load the manifest.
	my $problem = $anvil->Striker->load_manifest({debug => $debug, manifest_uuid => $manifest_uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		# The load_manifest method would log the details.
		return(0);
	}
	
	# Make sure the IPMI IP, subnet mask and password are available.
	my $ipmi_ip_address = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ipmi_ip};
	my $ipmi_password   = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password};
	my $password_length = length(Encode::encode('UTF-8', $ipmi_password));
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ipmi_ip_address => $ipmi_ip_address,
		ipmi_password   => $anvil->Log->is_secure($ipmi_password), 
		password_length => $password_length,
	}});
	
	my $subnet_mask = "";
	my $gateway     = "";
	my $in_network  = "";
	
	# Find the subnet the IPMI IP is in.
	foreach my $network_type ("bcn", "ifn", "sn")
	{
		my $count = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{$network_type};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			network_type => $network_type,
			count        => $count, 
		}});
		foreach my $i (1..$count)
		{
			my $network_name     = $network_type.$i;
			my $network          = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{network};
			my $this_subnet_mask = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{subnet};
			my $this_gateway     = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{gateway};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				network_name     => $network_name,
				network          => $network, 
				this_subnet_mask => $this_subnet_mask, 
				this_gateway     => $this_gateway, 
			}});
			
			my $match = $anvil->Network->is_ip_in_network({
				network     => $network,
				subnet_mask => $this_subnet_mask, 
				ip          => $ipmi_ip_address,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { network_name => $match}});
			if ($match)
			{
				$subnet_mask = $this_subnet_mask;
				$gateway     = $this_gateway;
				$in_network  = $network_name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					subnet_mask => $subnet_mask, 
					gateway     => $gateway, 
					in_network  => $in_network, 
				}});
				last;
			}
		}
	}
	
	# If we didn't find a network, we're done.
	if (not $subnet_mask)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0502", variables => {
			ip_address    => $ipmi_ip_address,
			manifest_uuid => $manifest_uuid,
		}});
		return(0);
	}
	
	# Call dmidecode to see if there even is an IPMI BMC on this host.
	my $host_ipmi              = "";
	my $has_ipmi               = 0;
	my $manufacturer           = "";
	my $lan_channel            = 99;
	my $current_network_type   = "";
	my $current_ip_address     = "";
	my $current_subnet_mask    = "";
	my $current_gateway        = "";
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{dmidecode}." --type 38"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /IPMI/i)
		{
			# Looks like 
			$has_ipmi = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { has_ipmi => $has_ipmi }});
			last;
		}
	}
	$output      = "";
	$return_code = "";
	
	if (not $has_ipmi)
	{
		# Return
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0499"});
		return(0);
	}

	# Find the manufacturer 
	($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." mc info"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		# Examples;
		# Manufacturer Name         : Fujitsu Siemens
		# Manufacturer Name         : Hewlett-Packard
		# Manufacturer Name         : DELL Inc
		if ($line =~ /Manufacturer Name\s+:\s+(.*)$/i)
		{
			$manufacturer = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manufacturer => $manufacturer }});
			
			if ($manufacturer =~ /fujitsu/i)
			{
				$manufacturer = "Fujitsu";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manufacturer => $manufacturer }});
			}
			elsif ($manufacturer =~ /dell/i)
			{
				$manufacturer = "Dell";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manufacturer => $manufacturer }});
			}
			elsif (($manufacturer =~ /^hp/i) or ($manufacturer =~ /hewlett/i))
			{
				$manufacturer = "HP";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manufacturer => $manufacturer }});
			}
		}
	}
	$output      = "";
	$return_code = "";
	
	# Find LAN channel. Fujitsu and HP are on channel 2, Dell id on 1. Unsure yet what other OEMs
	# use, but we'll scan 1..9 + 0.
	foreach my $i (1..9, 0)
	{
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." lan print ".$i});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code,
		}});
		if (not $return_code)
		{
			# Found it, but confirm.
			$lan_channel = $i; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lan_channel => $lan_channel }});
			
			foreach my $line (split/\n/, $output)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
				
				# IP Address Source       : Static Address
				# IP Address Source       : DHCP Address
				if ($line =~ /IP Address Source\s+:\s+(.*)$/i)
				{
					$current_network_type = $1 =~ /DHCP/i ? "dhcp" : "static";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { current_network_type => $current_network_type }});
				}
				# IP Address              : 0.0.0.0
				# IP Address              : 10.255.199.201
				if ($line =~ /IP Address\s+:\s+(.*)$/i)
				{
					$current_ip_address = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { current_ip_address => $current_ip_address }});
				}
				# Subnet Mask             : 0.0.0.0
				# Subnet Mask             : 255.255.0.0
				if ($line =~ /Subnet Mask\s+:\s+(.*)$/i)
				{
					$current_subnet_mask = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { current_subnet_mask => $current_subnet_mask }});
				}
				# Default Gateway IP      : 0.0.0.0
				# Default Gateway IP      : 10.255.255.254
				if ($line =~ /Default Gateway IP\s+:\s+(.*)$/i)
				{
					$current_gateway = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { current_gateway => $current_gateway }});
				}
			}
			last;
		}
	}
	
	# If we didn't find a LAN channel, we can't proceed.
	if ($lan_channel eq 99)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0499"});
		return(0);
	}
	
	# Is the desired values different from the current network?
	my $changes = 0;
	if ($current_network_type eq "dhcp")
	{
		# Change to static.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0503"});
		   $changes                = 1;
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." lan set ".$lan_channel." ipsrc static"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			changes     => $changes,
			output      => $output, 
			return_code => $return_code,
		}});
	}
	if (($ipmi_ip_address) && ($ipmi_ip_address ne $current_ip_address))
	{
		# Update the IP
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0504", variables => {
			old => $current_ip_address,
			new => $ipmi_ip_address,
		}});
		   $changes                = 1;
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." lan set ".$lan_channel." ipaddr ".$ipmi_ip_address});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			changes     => $changes,
			output      => $output, 
			return_code => $return_code,
		}});
	}
	if (($subnet_mask) && ($subnet_mask ne $current_subnet_mask))
	{
		# Update the subnet mask
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0505", variables => {
			old => $current_subnet_mask,
			new => $subnet_mask,
		}});
		   $changes                = 1;
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." lan set ".$lan_channel." netmask ".$subnet_mask});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			changes     => $changes,
			output      => $output, 
			return_code => $return_code,
		}});
	}
	if (($gateway) && ($gateway ne $current_gateway))
	{
		# Update the gateway
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0506", variables => {
			old => $current_gateway,
			new => $gateway,
		}});
		   $changes                = 1;
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." lan set ".$lan_channel." defgw ipaddr ".$gateway});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			changes     => $changes,
			output      => $output, 
			return_code => $return_code,
		}});
	}
	
	# HPs require a warm restart
	if (($changes) && (($manufacturer eq "HP") or ($manufacturer eq "Dell")))
	{
		# HPs can get away with a warm reset. Dells need a cold reset.
		my $reset_type  = $manufacturer eq "HP" ? "warm" : "cold";
		my $reset_delay = $reset_type eq "cold" ? 60 : 30;
		my $wait_until  = time + 120;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			manufacturer => $manufacturer, 
			reset_type   => $reset_type,
			reset_delay  => $reset_delay, 
			wait_until   => $wait_until, 
		}});
		
		# Do the reset. This should take about 30 ~ 60 seconds for pings to respond. We'll wait that 
		# long anyway in case the IP itself didn't change, then wait for the pings to respond.
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." mc reset ".$reset_type});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code,
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0516", variables => { reset_delay => $reset_delay}});
		sleep $reset_delay;
		
		my $done = 0;
		until($done)
		{
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ping}." -c 1 ".$ipmi_ip_address});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code,
			}});
			if (not $return_code)
			{
				# Pinged!
				$done = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0509", variables => { ip_address => $ipmi_ip_address }});
			}
			elsif (time > $wait_until)
			{
				# Timed out.
				$done = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "log_0510", variables => { ip_address => $ipmi_ip_address }});
			}
		}
	}
	
	# This can take a while to come up after cold resetting a BMC. So we'll try for a minute.
	my $user_name   = "";
	my $user_number = "";
	my $waiting     = 1;
	my $wait_until  = time + 120;
	while ($waiting)
	{
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ipmitool}." user list ".$lan_channel});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code,
		}});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			
			next if $line =~ /Empty User/i;
			next if $line =~ /NO ACCESS/i;
			next if $line =~ /Unknown/i;
			if ($line =~ /^(\d+)\s+(.*?)\s+(\w+)\s+(\w+)\s+(\w+)\s+(.*)$/)
			{
				my $this_user_number = $1;
				my $this_user_name   = $2;
				my $callin           = $3;
				my $link_auth        = $4;
				my $ipmi_message     = $5;
				my $channel_priv     = lc($6);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					this_user_number => $this_user_number,
					this_user_name   => $this_user_name, 
					callin           => $callin, 
					link_auth        => $link_auth, 
					ipmi_message     => $ipmi_message,
					channel_priv     => $channel_priv, 
				}});
				if (($channel_priv eq "oem") or ($channel_priv eq "administrator"))
				{
					# Found the user.
					$waiting     = 0;
					$user_name   = $this_user_name;
					$user_number = $this_user_number;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						waiting     => $waiting, 
						user_name   => $user_name,
						user_number => $user_number, 
					}});
					last;
				}
			}
		}
		
		# Try again later or give up?
		if (time > $wait_until)
		{
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0331", variables => {
				shell_call => $anvil->data->{path}{exe}{ipmitool}." user list ".$lan_channel,
				output     => $output,
			}});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0129", variables => {
				shell_call => $anvil->data->{path}{exe}{ipmitool}." user list ".$lan_channel,
				output     => $output,
			}});
			sleep 10;
		}
	}
	if (not $user_name)
	{
		# Failed to find a user.
		return(0);
	}
	
	# Now ask the Striker running the database we're using to try to call the IPMI BMC.
	my $striker_host_uuid = $anvil->data->{sys}{database}{read_uuid};
	my $striker_host      = $anvil->data->{database}{$striker_host_uuid}{host};
	my $striker_password  = $anvil->data->{database}{$striker_host_uuid}{password};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		striker_host_uuid => $striker_host_uuid, 
		striker_host      => $striker_host,
		striker_password  => $anvil->Log->is_secure($striker_password), 
	}});
	
	# See if the current password works.
	my $lanplus = "no-yes";
	if (($manufacturer eq "HP") or ($manufacturer eq "Dell"))
	{
		# These need LAN Plus
		$lanplus = "yes-no"
	}
	my $try_again = 1;
	$host_ipmi = $anvil->System->test_ipmi({
		debug         => $debug,
		ipmi_user     => $user_name,
		ipmi_password => $ipmi_password,
		ipmi_target   => $ipmi_ip_address, 
		lanplus       => $lanplus,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { host_ipmi => $host_ipmi}});
	if (($host_ipmi) && ($host_ipmi ne "!!error!!"))
	{
		# We're good! 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0511"});
		
		# Update the database, in case needed.
		my $host_uuid = $anvil->Get->host_uuid();
		$anvil->Database->insert_or_update_hosts({
			debug       => $debug, 
			host_ipmi   => $host_ipmi, 
			host_key    => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}, 
			host_name   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}, 
			host_type   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}, 
			host_uuid   => $host_uuid, 
			host_status => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_status}, 
		});
		
		$try_again = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { try_again => $try_again }});
	}
	else
	{
		# Try it again from the dashboard, we may just not be able to talk to our own BMC (can happen
		# on shared interfaces)
		$host_ipmi = $anvil->System->test_ipmi({
			debug         => $debug,
			ipmi_user     => $user_name,
			ipmi_password => $ipmi_password,
			ipmi_target   => $ipmi_ip_address, 
			lanplus       => $lanplus,
			target        => $striker_host, 
			password      => $striker_password, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { host_ipmi => $host_ipmi}});
		if (($host_ipmi) && ($host_ipmi ne "!!error!!"))
		{
			# We're good! 
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0512"});
		
			# Update the database, in case needed.
			my $host_uuid = $anvil->Get->host_uuid();
			$anvil->Database->insert_or_update_hosts({
				debug       => $debug, 
				host_ipmi   => $host_ipmi, 
				host_key    => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}, 
				host_name   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}, 
				host_type   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}, 
				host_uuid   => $host_uuid, 
				host_status => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_status}, 
			});
			
			$try_again = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { try_again => $try_again }});
		}
		else
		{
			# Change the password and then try again.
			my $escaped_ipmi_password = shell_quote($ipmi_password);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { escaped_ipmi_password => $escaped_ipmi_password }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, secure => 1, shell_call => $anvil->data->{path}{exe}{ipmitool}." user set password ".$user_number." ".$escaped_ipmi_password});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code,
			}});
			if (($return_code) or ($output =~ /Password is too long/))
			{
				# Try again with the 20-byte password.
				my $twenty_byte_ipmi_password = $anvil->Words->shorten_string({
					debug    => $debug,
					secure   => 1,
					string   => $ipmi_password, 
					'length' => 20,
				});
				my $twenty_byte_escaped_ipmi_password = shell_quote($twenty_byte_ipmi_password);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
					twenty_byte_ipmi_password         => $twenty_byte_ipmi_password, 
					twenty_byte_escaped_ipmi_password => $twenty_byte_escaped_ipmi_password,
				}});
				
				my ($output, $return_code) = $anvil->System->call({debug => $debug, secure => 1, shell_call => $anvil->data->{path}{exe}{ipmitool}." user set password ".$user_number." ".$twenty_byte_escaped_ipmi_password});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output, 
					return_code => $return_code,
				}});
				if ($return_code)
				{
					# Try once more with the 16-byte password.
					my $sixteen_byte_ipmi_password = $anvil->Words->shorten_string({
						debug    => $debug,
						secure   => 1,
						string   => $ipmi_password, 
						'length' => 16,
					});
					my $sixteen_byte_escaped_ipmi_password = shell_quote($sixteen_byte_ipmi_password);
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
						sixteen_byte_ipmi_password         => $sixteen_byte_ipmi_password, 
						sixteen_byte_escaped_ipmi_password => $sixteen_byte_escaped_ipmi_password,
					}});
					
					my ($output, $return_code) = $anvil->System->call({debug => $debug, secure => 1, shell_call => $anvil->data->{path}{exe}{ipmitool}." user set password ".$user_number." ".$sixteen_byte_escaped_ipmi_password});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						output      => $output, 
						return_code => $return_code,
					}});
					if ($return_code)
					{
						# Nothing more to do.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0137", variables => {
							user_name   => $user_name, 
							user_number => $user_number, 
							output      => $output,
							return_code => $return_code,
						}});
						return('!!error!!');
					}
					else
					{
						# Looks like the 16-byte version worked.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0515"});
					}
				}
				else
				{
					# Looks like the 20-byte version worked.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0514"});
				}
			}
			else
			{
				# Looks like the password took.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0513"});
			}
		}
	}
	
	if ($try_again)
	{
		$host_ipmi = $anvil->System->test_ipmi({
			debug         => $debug,
			ipmi_user     => $user_name,
			ipmi_password => $ipmi_password,
			ipmi_target   => $ipmi_ip_address, 
			lanplus       => $lanplus,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { host_ipmi => $host_ipmi}});
		if (($host_ipmi) && ($host_ipmi ne "!!error!!"))
		{
			# We're good, password was changed! 
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0511"});
		
			# Update the database, in case needed.
			my $host_uuid = $anvil->Get->host_uuid();
			$anvil->Database->insert_or_update_hosts({
				debug       => $debug, 
				host_ipmi   => $host_ipmi, 
				host_key    => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}, 
				host_name   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}, 
				host_type   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}, 
				host_uuid   => $host_uuid, 
				host_status => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_status}, 
			});
		}
		else
		{
			# Try it again from the dashboard, we may just not be able to talk to our own BMC (
			# can happen on shared interfaces)
			my $host_ipmi = $anvil->System->test_ipmi({
				debug         => $debug,
				ipmi_user     => $user_name,
				ipmi_password => $ipmi_password,
				ipmi_target   => $ipmi_ip_address, 
				lanplus       => $lanplus,
				target        => $striker_host, 
				password      => $striker_password, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { host_ipmi => $host_ipmi}});
			if (($host_ipmi) && ($host_ipmi ne "!!error!!"))
			{
				# We're good! 
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0511"});
		
				# Update the database, in case needed.
				my $host_uuid = $anvil->Get->host_uuid();
				$anvil->Database->insert_or_update_hosts({
					debug       => $debug, 
					host_ipmi   => $host_ipmi, 
					host_key    => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key}, 
					host_name   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name}, 
					host_type   => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type}, 
					host_uuid   => $host_uuid, 
					host_status => $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_status}, 
				});
			}
			else
			{
				# Nothing worked. :(
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0138", variables => {
					user_name   => $user_name, 
					user_number => $user_number, 
				}});
				return('!!error!!');
			}
		}
	}
	
	# Re-read the hosts so that it's updated.
	$anvil->Database->get_hosts();
	
	return($host_ipmi);
}

=head2 disable_daemon

This method disables a daemon. The return code from the disable request will be returned.

If the return code for the disable command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to disable. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub disable_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->disable_daemon()" }});
	
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." disable ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	return($return_code);
}

=head2 generate_state_json

This method generates the C<< all_status.json >> file. 

B<< Note >>: Contained in are translations of some values, for the sake of JSON readers. Developers should note to translate values in-situ as the language used here may not be the user's desired language.

This method takes no parameters.

=cut
sub generate_state_json
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->generate_state_json()" }});
	
	# We're going to look for matches as we go, so look 
	$anvil->Network->load_ips({
		debug     => $debug,
		host      => $anvil->Get->short_host_name(),
		host_uuid => $anvil->data->{sys}{host_uuid},
	});
	
	$anvil->data->{json}{all_systems}{hosts} = [];
	$anvil->Database->get_hosts_info({debug => 3});
	foreach my $host_uuid (keys %{$anvil->data->{machine}{host_uuid}})
	{
		my $host_name       = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name};
		my $short_host_name = $host_name =~ /\./ ? ($host_name =~ /^(.*?)\./)[0] : $host_name;
		my $host_type       = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_type};
		my $host_key        = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_key};
		my $configured      = defined $anvil->data->{machine}{host_uuid}{$host_uuid}{variables}{'system::configured'} ? $anvil->data->{machine}{host_uuid}{$host_uuid}{variables}{'system::configured'} : 0;
		my $ifaces_array    = [];
		my $host            = $short_host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:host_name"       => $host_name,
			"s2:short_host_name" => $short_host_name, 
			"s3:host_type"       => $host_type,
			"s4:configured"      => $configured, 
			"s5:host_uuid"       => $host_uuid, 
			"s6:host_key"        => $host_key, 
		}});
		
		$anvil->Network->load_interfces({
			debug     => $debug,
			host_uuid => $host_uuid, 
			host      => $short_host_name,
		});
		
		# Find what interface on this host we can use to talk to it (if we're not looking at ourselves).
		my $matched_interface  = "";
		my $matched_ip_address = "";
		if ($host_name ne $anvil->Get->host_name)
		{
			# Don't need to call 'local_ips', it was called by load_interfaces above.
			my ($match) = $anvil->Network->find_matches({
				debug  => $debug,
				first  => $anvil->Get->short_host_name(),
				second => $short_host_name, 
			});
			
			if ($match)
			{
				# Yup!
				my $match_found = 0;
				foreach my $interface (sort {$a cmp $b} keys %{$match->{$short_host_name}})
				{
					$matched_interface  = $interface;
					$matched_ip_address = $match->{$short_host_name}{$interface}{ip};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						matched_interface  => $matched_interface, 
						matched_ip_address => $matched_ip_address, 
					}});
					last;
				}
			}
		}
		
		foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$host}{interface}})
		{
			my $type        = $anvil->data->{network}{$host}{interface}{$interface}{type};
			my $uuid        = $anvil->data->{network}{$host}{interface}{$interface}{uuid};
			my $mtu         = $anvil->data->{network}{$host}{interface}{$interface}{mtu};
			my $mac_address = $anvil->data->{network}{$host}{interface}{$interface}{mac_address}; 
			my $iface_hash  = {};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:interface"   => $interface,
				"s2:mac_address" => $mac_address, 
				"s3:type"        => $type,
				"s4:mtu"         => $mtu,
				"s5:configured"  => $configured, 
				"s6:host_uuid"   => $host_uuid, 
				"s7:host_key"    => $host_key, 
			}});
			$iface_hash->{name}        = $interface;
			$iface_hash->{type}        = $type;
			$iface_hash->{mtu}         = $mtu;
			$iface_hash->{uuid}        = $uuid;
			$iface_hash->{mac_address} = $mac_address;
			if ($type eq "bridge")
			{
				my $id              = $anvil->data->{network}{$host}{interface}{$interface}{id}; 
				my $stp_enabled     = $anvil->data->{network}{$host}{interface}{$interface}{stp_enabled}; 
				my $interfaces      = $anvil->data->{network}{$host}{interface}{$interface}{interfaces};
				my $say_stp_enabled = $stp_enabled;
				if (($stp_enabled eq "0") or ($stp_enabled eq "disabled"))
				{
					$say_stp_enabled = $anvil->Words->string({key => "unit_0020"});
				}
				elsif (($stp_enabled eq "1") or ($stp_enabled eq "enabled_kernel"))
				{
					$say_stp_enabled = $anvil->Words->string({key => "unit_0021"});
				}
				elsif (($stp_enabled eq "2") or ($stp_enabled eq "enabled_userland"))
				{
					$say_stp_enabled = $anvil->Words->string({key => "unit_0022"});
				}
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					bridge_id       => $id,
					stp_enabled     => $stp_enabled,
					say_stp_enabled => $say_stp_enabled,
				}});
				
				my $connected_interfaces = [];
				foreach my $connected_interface_name (sort {$a cmp $b} @{$interfaces})
				{
					push @{$connected_interfaces}, $connected_interface_name;
					my $connected_interface_count = @{$connected_interfaces};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						connected_interface_count => $connected_interface_count, 
						connected_interface_name  => $connected_interface_name,
					}});
				}
				
				$iface_hash->{bridge_id}            = $id;
				$iface_hash->{stp_enabled}          = $stp_enabled;
				$iface_hash->{say_stp_enabled}      = $say_stp_enabled;
				$iface_hash->{connected_interfaces} = $connected_interfaces;
			}
			elsif ($type eq "bond")
			{
				my $mode                 = $anvil->data->{network}{$host}{interface}{$interface}{mode};
				my $primary_interface    = $anvil->data->{network}{$host}{interface}{$interface}{primary_interface}; 
				my $primary_reselect     = $anvil->data->{network}{$host}{interface}{$interface}{primary_reselect}; 
				my $active_interface     = $anvil->data->{network}{$host}{interface}{$interface}{active_interface}; 
				my $mii_polling_interval = $anvil->Convert->add_commas({number => $anvil->data->{network}{$host}{interface}{$interface}{mii_polling_interval}});
				my $say_up_delay         = $anvil->Convert->add_commas({number => $anvil->data->{network}{$host}{interface}{$interface}{up_delay}});
				my $up_delay             = $anvil->data->{network}{$host}{interface}{$interface}{up_delay};
				my $say_down_delay       = $anvil->Convert->add_commas({number => $anvil->data->{network}{$host}{interface}{$interface}{down_delay}}); 
				my $down_delay           = $anvil->data->{network}{$host}{interface}{$interface}{down_delay}; 
				my $operational          = $anvil->data->{network}{$host}{interface}{$interface}{operational}; 
				my $interfaces           = $anvil->data->{network}{$host}{interface}{$interface}{interfaces};
				my $bridge_uuid          = $anvil->data->{network}{$host}{interface}{$interface}{bridge_uuid};
				my $bridge_name          = $anvil->data->{network}{$host}{interface}{$interface}{bridge_name} ? $anvil->data->{network}{$host}{interface}{$interface}{bridge_name} : $anvil->Words->string({key => "unit_0005"});
				my $say_mode             = $mode;
				my $say_operational      = $operational;
				my $say_primary_reselect = $primary_reselect;
				if (($mode eq "0") or ($mode eq "balance-rr"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0006"});
				}
				elsif (($mode eq "1") or ($mode eq "active-backup"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0007"});
				}
				elsif (($mode eq "2") or ($mode eq "balanced-xor"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0008"});
				}
				elsif (($mode eq "3") or ($mode eq "broadcast"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0009"});
				}
				elsif (($mode eq "4") or ($mode eq "802.3ad"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0010"});
				}
				elsif (($mode eq "5") or ($mode eq "balanced-tlb"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0011"});
				}
				elsif (($mode eq "6") or ($mode eq "balanced-alb"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0012"});
				}
				if ($operational eq "up")
				{
					$say_operational = $anvil->Words->string({key => "unit_0013"});
				}
				elsif ($operational eq "down")
				{
					$say_operational = $anvil->Words->string({key => "unit_0014"});
				}
				elsif ($operational eq "unknown")
				{
					$say_operational = $anvil->Words->string({key => "unit_0004"});
				}
				if (($primary_reselect eq "always") or ($primary_reselect eq "0"))
				{
					$say_primary_reselect = $anvil->Words->string({key => "unit_0017"});
				}
				elsif (($primary_reselect eq "better") or ($primary_reselect eq "1"))
				{
					$say_primary_reselect = $anvil->Words->string({key => "unit_0018"});
				}
				elsif (($primary_reselect eq "failure") or ($primary_reselect eq "2"))
				{
					$say_primary_reselect = $anvil->Words->string({key => "unit_0019"});
				}
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					say_mode             => $say_mode,
					mode                 => $mode,
					active_interface     => $active_interface,
					primary_interface    => $primary_interface,
					say_primary_reselect => $say_primary_reselect,
					primary_reselect     => $primary_reselect,
					say_up_delay         => $up_delay,
					up_delay             => $anvil->data->{network}{$host}{interface}{$interface}{up_delay},
					say_down_delay       => $down_delay,
					down_delay           => $anvil->data->{network}{$host}{interface}{$interface}{down_delay},
					say_operational      => $say_operational,
					operational          => $operational,
					mii_polling_interval => $mii_polling_interval,
					bridge_uuid          => $bridge_uuid, 
					bridge_name          => $bridge_name, 
				}});
				my $connected_interfaces = [];
				foreach my $connected_interface_name (sort {$a cmp $b} @{$interfaces})
				{
					push @{$connected_interfaces}, $connected_interface_name;
					my $connected_interface_count = @{$connected_interfaces};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						connected_interface_count => $connected_interface_count, 
						connected_interface_name  => $connected_interface_name,
					}});
				}
				$iface_hash->{say_mode}             = $say_mode;
				$iface_hash->{mode}                 = $mode;
				$iface_hash->{active_interface}     = $active_interface;
				$iface_hash->{primary_interface}    = $primary_interface;
				$iface_hash->{primary_reselect}     = $primary_reselect;
				$iface_hash->{say_up_delay}         = $say_up_delay;
				$iface_hash->{up_delay}             = $up_delay;
				$iface_hash->{say_down_delay}       = $say_down_delay;
				$iface_hash->{down_delay}           = $down_delay;
				$iface_hash->{say_operational}      = $say_operational;
				$iface_hash->{operational}          = $operational;
				$iface_hash->{mii_polling_interval} = $mii_polling_interval;
				$iface_hash->{connected_interfaces} = $connected_interfaces;
				$iface_hash->{bridge_uuid}          = $bridge_uuid;
				$iface_hash->{bridge_name}          = $bridge_name;
			}
			else
			{
				my $speed           = $anvil->data->{network}{$host}{interface}{$interface}{speed};
				my $say_speed       = $anvil->Convert->add_commas({number => $anvil->data->{network}{$host}{interface}{$interface}{speed}})." ".$anvil->Words->string({key => "suffix_0050"});
				my $link_state      = $anvil->data->{network}{$host}{interface}{$interface}{link_state};
				my $operational     = $anvil->data->{network}{$host}{interface}{$interface}{operational};
				my $duplex          = $anvil->data->{network}{$host}{interface}{$interface}{duplex};
				my $medium          = $anvil->data->{network}{$host}{interface}{$interface}{medium};
				my $bond_uuid       = $anvil->data->{network}{$host}{interface}{$interface}{bond_uuid};
				my $bond_name       = $anvil->data->{network}{$host}{interface}{$interface}{bond_name}   ? $anvil->data->{network}{$host}{interface}{$interface}{bond_name}   : $anvil->Words->string({key => "unit_0005"});
				my $bridge_uuid     = $anvil->data->{network}{$host}{interface}{$interface}{bridge_uuid};
				my $bridge_name     = $anvil->data->{network}{$host}{interface}{$interface}{bridge_name} ? $anvil->data->{network}{$host}{interface}{$interface}{bridge_name} : $anvil->Words->string({key => "unit_0005"});
				my $changed_order   = $anvil->data->{network}{$host}{interface}{$interface}{changed_order};
				my $say_link_state  = $link_state;
				my $say_operational = $operational;
				my $say_medium      = $medium; # This will be flushed out later. For now, we just send out what we've got.
				my $say_duplex      = $duplex;
				if ($anvil->data->{network}{$host}{interface}{$interface}{speed} >= 1000)
				{
					# Report in Gbps 
					$say_speed = $anvil->Convert->add_commas({number => ($anvil->data->{network}{$host}{interface}{$interface}{speed} / 1000)})." ".$anvil->Words->string({key => "suffix_0051"});
				}
				if ($duplex eq "full")
				{
					$say_duplex = $anvil->Words->string({key => "unit_0015"});
				}
				elsif ($duplex eq "half")
				{
					$say_duplex = $anvil->Words->string({key => "unit_0016"});
				}
				elsif ($duplex eq "unknown")
				{
					$say_duplex = $anvil->Words->string({key => "unit_0004"});
				}
				if ($operational eq "up")
				{
					$say_operational = $anvil->Words->string({key => "unit_0013"});
				}
				elsif ($operational eq "down")
				{
					$say_operational = $anvil->Words->string({key => "unit_0014"});
				}
				elsif ($operational eq "unknown")
				{
					$say_operational = $anvil->Words->string({key => "unit_0004"});
				}
				if ($link_state eq "1")
				{
					$say_link_state = $anvil->Words->string({key => "unit_0013"});
				}
				elsif ($link_state eq "0")
				{
					$say_link_state = $anvil->Words->string({key => "unit_0014"});
				}
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					say_speed       => $say_speed,
					speed           => $speed,
					say_link_state  => $say_link_state,
					link_state      => $link_state,
					say_operational => $say_operational,
					operational     => $operational,
					say_duplex      => $say_duplex,
					duplex          => $duplex,
					say_medium      => $say_medium,
					medium          => $medium,
					bond_uuid       => $bond_uuid, 
					bond_name       => $bond_name,
					bridge_uuid     => $bridge_uuid, 
					bridge_name     => $bridge_name,
					changed_order   => $changed_order,
				}});
				
				$iface_hash->{say_speed}       = $say_speed;
				$iface_hash->{speed}           = $speed;
				$iface_hash->{say_link_state}  = $say_link_state;
				$iface_hash->{link_state}      = $link_state;
				$iface_hash->{say_operational} = $say_operational;
				$iface_hash->{operational}     = $operational;
				$iface_hash->{say_duplex}      = $say_duplex;
				$iface_hash->{duplex}          = $duplex;
				$iface_hash->{say_medium}      = $say_medium;
				$iface_hash->{medium}          = $medium;
				$iface_hash->{bond_uuid}       = $bond_uuid;
				$iface_hash->{bond_name}       = $bond_name;
				$iface_hash->{bridge_uuid}     = $bridge_uuid;
				$iface_hash->{bridge_name}     = $bridge_name;
				$iface_hash->{changed_order}   = $changed_order;
			};
			
			# Is there an IP on this interface?
			my $ip_address      = "";
			my $subnet_mask     = "";
			my $default_gateway = 0;
			my $gateway         = "";
			my $dns             = "";
			if ((exists $anvil->data->{network}{$host}{interface}{$interface}{ip}) && ($anvil->data->{network}{$host}{interface}{$interface}{ip}))
			{
				$ip_address      = $anvil->data->{network}{$host}{interface}{$interface}{ip};
				$subnet_mask     = $anvil->data->{network}{$host}{interface}{$interface}{subnet_mask};
				$default_gateway = $anvil->data->{network}{$host}{interface}{$interface}{default_gateway};
				$gateway         = $anvil->data->{network}{$host}{interface}{$interface}{gateway};
				$dns             = $anvil->data->{network}{$host}{interface}{$interface}{dns};
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				ip_address      => $ip_address,
				subnet_mask     => $subnet_mask,
				default_gateway => $default_gateway,
				gateway         => $gateway,
				dns             => $dns,
			}});
			
			$iface_hash->{ip_address}      = $ip_address;
			$iface_hash->{subnet_mask}     = $subnet_mask;
			$iface_hash->{default_gateway} = $default_gateway;
			$iface_hash->{gateway}         = $gateway;
			$iface_hash->{dns}             = $dns;
			
			push @{$ifaces_array}, $iface_hash;
		}
		
		push @{$anvil->data->{json}{all_systems}{hosts}}, {
			name               => $host_name,
			short_name         => $short_host_name, 
			type               => $host_type,
			host_uuid          => $host_uuid,
			configured         => $configured,
			ssh_fingerprint    => $host_key,
			matched_interface  => $matched_interface,
			matched_ip_address => $matched_ip_address,
			network_interfaces => $ifaces_array,
		};
	}
	
	# Write out the JSON file.
	my $json = JSON->new->utf8->encode($anvil->data->{json}{all_systems});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { json => $json }});
	
	# Write it out.
	my $json_file = $anvil->data->{path}{directories}{status}."/".$anvil->data->{path}{json}{all_status};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { json_file => $json_file }});
	my $error = $anvil->Storage->write_file({
		debug     => $debug, 
		overwrite => 1, 
		backup    => 0, 
		file      => $json_file, 
		body      => $json, 
		group     => "apache",
		user      => "apache",
		mode      => "0644",
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
	
	# Clear out the records.
	delete $anvil->data->{json}{all_systems};
	
	return(0);
}

=head2 enable_daemon

This method enables a daemon (so that it starts when the OS boots). The return code from the start request will be returned.

If the return code for the enable command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to enable. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub enable_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->enable_daemon()" }});
	
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." enable ".$daemon." 2>&1"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	return($return_code);
}

=head2 find_matching_ip

This takes an IP (or host name, which is translated to an IP using local resources), and tries to figure out which local IP address is on the same subnet.

If no match is found, an empty string is returned. If there is an error, C<< !!error!! >> is returned.

Parameters;

=head3 host (required)

This is the IP address or host name we're going to use when searching for a local IP address that can reach it.

=cut
sub find_matching_ip
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->find_matching_ip()" }});
	
	my $local_ip = "";
	my $host     = defined $parameter->{host} ? $parameter->{host} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	
	# Do I have a host?
	if (not $host)
	{
		# Woops!
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->find_matching_ip()", parameter => "host" }});
		return("!!error!!");
	}
	
	# Translate the host name to an IP address, if it isn't already an IP address.
	if (not $anvil->Validate->ipv4({ip => $host}))
	{
		# This will be '0' if it failed, and pre-validated if it returns an IP.
		$host = $anvil->Convert->host_name_to_ip({host_name => $host});
		if (not $host)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0211", variables => { host => $parameter->{host} }});
			return(0);
		}
	}
	
	# Get my local IPs
	$anvil->Network->get_ips({debug => $debug});
	
	my $ip = NetAddr::IP->new($host);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	
	# Look through our IPs. First match wins.
	my $local_host = $anvil->Get->short_host_name();
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$local_host}{interface}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
		next if not $anvil->data->{network}{$local_host}{interface}{$interface}{ip};
		my $this_ip          = $anvil->data->{network}{$local_host}{interface}{$interface}{ip};
		my $this_subnet_mask = $anvil->data->{network}{$local_host}{interface}{$interface}{subnet_mask};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:this_ip"          => $this_ip,
			"s2:this_subnet_mask" => $this_subnet_mask, 
		}});
		
		my $network_range = $this_ip."/".$this_subnet_mask;
		my $network       = NetAddr::IP->new($network_range);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:network_range" => $network_range,
			"s2:network"       => $network, 
		}});
		
		if ($ip->within($network))
		{
			$local_ip = $this_ip;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_ip => $local_ip }});
			last;
		}
		
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { local_ip => $local_ip }});
	return($local_ip);
}

=head2 host_name

Get or set the local host name. The current (or new) "static" (traditional) host name and the "pretty" (descriptive) host names are returned.

 # Get the current host name.
 my ($traditional_host_name, $descriptive_host_name) = $anvil->System->host_name();

 # Set the traditional host name.
 my ($traditional_host_name, $descriptive_host_name) = $anvil->System->host_name({set => "an-striker01.alteeve.com");

 # Set the traditional and descriptive host names.
 my ($traditional_host_name, $descriptive_host_name) = $anvil->System->host_name({set => "an-striker01.alteeve.com", pretty => "Alteeve - Striker 01");

The current host name (or the new host name if C<< set >> was used) is returned as a string.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 pretty (optional)

If set, this will be set as the "pretty" host name.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 set (optional)

If set, this will become the new host name.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub host_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->host_name()" }});
	
	my $pretty      = defined $parameter->{pretty}      ? $parameter->{pretty}      : "";
	my $set         = defined $parameter->{set}         ? $parameter->{set}         : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		pretty      => $pretty, 
		set         => $set, 
		target      => $target, 
		port        => $port, 
		remote_user => $remote_user, 
		password    => $anvil->Log->is_secure($password), 
	}});
	
	# Set?
	if ($set)
	{
		my $shell_call = $anvil->data->{path}{exe}{hostnamectl}." set-hostname $set";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my $output      = "";
		my $return_code = "";
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local call
			($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code,
			}});
		}
		else
		{
			# Remote call
			($output, my $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call, 
				target      => $target,
				port        => $port, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output,
			}});
		}
	}
	
	# Pretty
	if ($pretty)
	{
		# TODO: Escape this for bash properly
		#   $pretty     =~ s/"/\\"/g;
		my $shell_call = $anvil->data->{path}{exe}{hostnamectl}." set-hostname --pretty \"$pretty\"";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my $output      = "";
		my $return_code = "";
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local call
			($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output, 
				return_code => $return_code,
			}});
		}
		else
		{
			# Remote call
			($output, my $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call, 
				target      => $target,
				port        => $port, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output,
			}});
		}
	}
	
	# Get the static (traditional) host name
	my $shell_call = $anvil->data->{path}{exe}{hostnamectl}." --static";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my $host_name   = "";
	my $descriptive = "";
	my $output      = "";
	my $return_code = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call
		($host_name, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_name    => $host_name, 
			return_code  => $return_code,
		}});
	}
	else
	{
		# Remote call
		($host_name, my $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_name => $host_name,
			output    => $output,
		}});
	}
	
	# Get the pretty (descriptive) host name
	$shell_call = $anvil->data->{path}{exe}{hostnamectl}." --pretty";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	$output      = "";
	$return_code = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call
		($descriptive, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			descriptive => $descriptive, 
			return_code => $return_code,
		}});
	}
	else
	{
		# Remove call
		($descriptive, my $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			descriptive => $descriptive,
			output      => $output,
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_name   => $host_name, 
		return_code => $return_code,
	}});
	return($host_name, $descriptive);
}

=head2 maintenance_mode

This sets, clears or checks if the local system is in maintenance mode. Any system in maintenance mode will not be used by normal Anvil! tasks.

This returns C<< 1 >> if maintenance mode is enabled and C<< 0 >> if disabled.

Parameters;

=head3 set (optional)

If this is set to C<< 1 >>, maintenance mode is enabled. If this is set to C<< 0 >>, maintenance mode is disabled.

=cut
sub maintenance_mode
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->maintenance_mode()" }});
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
	
	if (($set) or ($set eq "0"))
	{
		### TODO: stop other systems from using this database if this is a Striker dashboard.
		# Am I enabling or disabling?
		if ($set eq "1")
		{
			# Enabling
			$anvil->Database->insert_or_update_variables({
				debug                 => $debug, 
				variable_name         => "maintenance_mode", 
				variable_value        => "1", 
				variable_default      => "0", 
				variable_description  => "striker_0087", 
				variable_section      => "system", 
				variable_source_uuid  => $anvil->Get->host_uuid, 
				variable_source_table => "hosts", 
			});
		}
		elsif ($set eq "0")
		{
			# Disabling
			$anvil->Database->insert_or_update_variables({
				debug                 => $debug, 
				variable_name         => "maintenance_mode", 
				variable_value        => "0", 
				variable_default      => "0", 
				variable_description  => "striker_0087", 
				variable_section      => "system", 
				variable_source_uuid  => $anvil->Get->host_uuid, 
				variable_source_table => "hosts", 
			});
		}
		else
		{
			# Called with an invalid value.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0197", variables => { set => $set }});
			$set = "";
		}
	}
	
	my ($maintenance_mode, $variable_uuid, $modified_date) = $anvil->Database->read_variable({
		debug                 => $debug, 
		variable_name         => "maintenance_mode",
		variable_source_table => "hosts",
		variable_source_uuid  => $anvil->Get->host_uuid,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		debug            => $debug, 
		maintenance_mode => $maintenance_mode, 
		variable_uuid    => $variable_uuid, 
		modified_date    => $modified_date, 
	}});
	
	if ($maintenance_mode eq "")
	{
		$maintenance_mode = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { maintenance_mode => $maintenance_mode }});
	}
	
	return($maintenance_mode);
}

### TODO: Move and document.
### NOTE: This only works if the firewall is enabled.
sub check_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->check_firewall()" }});
	
	# Show live or permanent rules? Permanent is default 
	my $permanent = defined $parameter->{permanent} ? $parameter->{permanent} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { permanent => $permanent }});
	
	# Read in /etc/firewalld/firewalld.conf and parse the 'DefaultZone' variable.
	my $firewall_conf = $anvil->Storage->read_file({file => $anvil->data->{path}{configs}{'firewalld.conf'}});
	foreach my $line (split/\n/, $firewall_conf)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^DefaultZone=(.*?)$/)
		{
			$anvil->data->{firewall}{default_zone} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "firewall::default_zone" => $anvil->data->{firewall}{default_zone} }});
			last;
		}
	}
	$anvil->data->{firewall}{default_zone} = "" if not defined $anvil->data->{firewall}{default_zone};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "firewall::default_zone" => $anvil->data->{firewall}{default_zone} }});
	
	### NOTE: 'iptables-save' doesn't seem to show the loaded firewall in RHEL8. Slower or not, we seem 
	###       to have to use 'firewall-cmd'
	my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --list-all-zones";
	if (not $permanent)
	{
		$shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --list-all-zones";
	}
	
	my $zone                          = "";
	my $active_state                  = "";
	my ($firewall_data, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	foreach my $line (split/\n/, $firewall_data)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:zone' => $zone,
			's2:line' => $line,
		}});
		
		if ($line =~ /^(\w.*)$/)
		{
			$zone         = $1;
			$active_state = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { zone => $zone }});
			if ($line =~ /^(\w+) \((.*?)\)/)
			{
				$zone         = $1;
				$active_state = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					zone         => $zone, 
					active_state => $active_state 
				}});
			}
			$anvil->data->{firewall}{zone}{$zone}{file} = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "firewall::zone::${zone}::file" => $anvil->data->{firewall}{zone}{$zone}{file} }});
		}
		elsif ($zone)
		{
			if ((not $line) or ($line =~ /^\s+$/))
			{
				# Done reading this zone, record.
				my $interfaces = defined $anvil->data->{firewall}{zone}{$zone}{variable}{interfaces} ? $anvil->data->{firewall}{zone}{$zone}{variable}{interfaces} : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					zone       => $zone,
					interfaces => $interfaces, 
				}});
				foreach my $interface (split/ /, $interfaces)
				{
					$anvil->data->{firewall}{interface}{$interface}{zone} = $zone;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"firewall::interface::${interface}::zone" => $anvil->data->{firewall}{interface}{$interface}{zone},
					}});
				}
				
				$zone         = "";
				$active_state = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					zone         => $zone, 
					active_state => $active_state, 
				}});
			}
			elsif (($active_state) && ($line =~ /(\S.*?):(.*)$/))
			{
				my $variable =  $1;
				my $value    =  $2;
				   $variable =~ s/^\s+//;
				   $variable =~ s/\s+$//;
				   $value    =~ s/^\s+//;
				   $value    =~ s/\s+$//;
				$anvil->data->{firewall}{zone}{$zone}{variable}{$variable} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:line"                                           => $line,
					"s2:firewall::zone::${zone}::variable::${variable}" => $anvil->data->{firewall}{zone}{$zone}{variable}{$variable}, 
				}});
			}
		}
	}
	
	# Make sure, for each zone, we've got a zone file. We should, so we'll read it in.
	foreach my $zone (sort {$a cmp $b} keys %{$anvil->data->{firewall}{zone}})
	{
		$anvil->data->{firewall}{zone}{$zone}{file} =  $anvil->data->{path}{directories}{firewalld_zones}."/".$zone.".xml";
		$anvil->data->{firewall}{zone}{$zone}{file} =~ s/\/\//\//g;
		$anvil->data->{firewall}{zone}{$zone}{body} =  "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"firewall::zone::${zone}::file" => $anvil->data->{firewall}{zone}{$zone}{file},
		}});
		if (-e $anvil->data->{firewall}{zone}{$zone}{file})
		{
			$anvil->data->{firewall}{zone}{$zone}{body} = $anvil->Storage->read_file({file => $anvil->data->{firewall}{zone}{$zone}{file}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"firewall::zone::${zone}::body" => $anvil->data->{firewall}{zone}{$zone}{body},
			}});
		}
	}
	
	return(0);
}

=head2 manage_authorized_keys

This takes a host's UUID and will adds or removes their ssh public key to the target host user (or users). On success, C<< 0 >> is returned. Otherwise, C<< 1 >> is returned.

Parameters;

=head3 host_uuid (required)

This is the C<< hosts >> -> C<< host_uuid >> whose key we're adding or removing. When adding, the C<< 

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional, default local shost host name)

This is the IP or host name of the machine to manage keys on. If not passed, the keys on the local machine will be managed.

=head3 users (optional)

This is a comma separated list of users whose keys are being managed. If not set, the default on Striker and DR Hosts is C<< root,admin >> and on nodes it is C<< root,admin,hacluster >>.

=cut
sub manage_authorized_keys
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->manage_authorized_keys()" }});
	
	my $host_uuid   = defined $parameter->{host_uuid}   ? $parameter->{host_uuid}   : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $users       = defined $parameter->{users}       ? $parameter->{users}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target      => $target, 
		port        => $port, 
		remote_user => $remote_user, 
		password    => $anvil->Log->is_secure($password), 
		users       => $users, 
	}});
	
	if (not $users)
	{
		$users = $anvil->Striker->get_host_type eq "node" ? "root,admin,hacluster" : "root,admin";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { users => $users }});
	}
	
	
	
	return(0);
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

=head3 protocol (optional)

This can be c<< tcp >> or C<< upd >> and is used to specify what protocol to use with the C<< port >>, when specified. The default is C<< tcp >>.

=cut
### TODO: This is slooooow. We need to be able to get more data per system call.
###       - Getting better...
sub manage_firewall
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->manage_firewall()" }});
	
	my $task        = defined $parameter->{task}        ? $parameter->{task}        : "check";
	my $port_number = defined $parameter->{port_number} ? $parameter->{port_number} : "";
	my $protocol    = defined $parameter->{protocol}    ? $parameter->{protocol}    : "tcp";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		task        => $task,
		port_number => $port_number,
		protocol    => $protocol, 
	}});
	
	### NOTE: Disabled during development
	return(0);
	
	# Make sure we have a port or service.
	if (not $port_number)
	{
		# ...
		return("!!error!!");
	}
	if (($protocol ne "tcp") && ($protocol ne "udp"))
	{
		# Bad protocol
		return("!!error!!");
	}
	
	# This will be set if the port is found to be open.
	my $open = 0;
	
	# Checking the iptables rules in memory is very fast, relative to firewall-cmd. So we'll do an 
	# initial check there to see if the port in question is listed.
	my $shell_call = $anvil->data->{path}{exe}{'iptables-save'};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($iptables, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	foreach my $line (split/\n/, $iptables)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if (($line =~ /-m $protocol /) && ($line =~ /--dport $port_number /) && ($line =~ /ACCEPT/))
		{
			$open = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open }});
			last;
		}
	}
	
	# If the port is open and the task is 'check' or 'open', we're done and can return now and save a lot
	# of time.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'task' => $task, 'open' => $open }});
	if ((($task eq "check") or ($task eq "open")) && ($open))
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open }});
		return($open);
	}
	
	# Make sure firewalld is running.
	my $firewalld_running = $anvil->System->check_daemon({daemon => $anvil->data->{sys}{daemon}{firewalld}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { firewalld_running => $firewalld_running }});
	if (not $firewalld_running)
	{
		if ($anvil->data->{sys}{daemons}{restart_firewalld})
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0127"});
			my $return_code = $anvil->System->start_daemon({daemon => $anvil->data->{sys}{daemon}{firewalld}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
			if ($return_code)
			{
				# non-0 means something went wrong.
				return("!!error!!");
			}
		}
		else
		{
			# We've been asked to leave it off.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0128"});
			return(0);
		}
	}

	
	# Before we do anything, what zone is active?
	my $active_zone = "";
	if (not $active_zone)
	{
		my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --get-active-zones";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line !~ /\s/)
			{
				$active_zone = $line;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_zone => $active_zone }});
			}
			last;
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { active_zone  => $active_zone }});
	
	# If I still don't know what the active zone is, we're done.
	if (not $active_zone)
	{
		return("!!error!!");
	}
	
	# If we have an active zone, see if the requested port is open.
	my $zone_file = $anvil->data->{path}{directories}{firewalld_zones}."/".$active_zone.".xml";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { zone_file => $zone_file }});
	if (not -e $zone_file)
	{
		#...
		return($open);
	}
	
	# Read the XML to see what services are opened already and translate those into port numbers and 
	# protocols.
	local $@;
	my $open_services = [];
	my $xml           = XML::Simple->new();
	my $body          = "";
	my $test          = eval { $body = $xml->XMLin($zone_file, KeyAttr => { language => 'name', key => 'name' }, ForceArray => [ 'service' ]) };
	if (not $test)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem reading: [$zone_file]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => $error});
		
		# Clear the error so it doesn't propogate out to a future 'die' and confuse things.
		$@ = '';
	}
	else
	{
		# Parse the already-opened services
		foreach my $hash_ref (@{$body->{service}})
		{
			# Load the details of this service.
			my $service = $hash_ref->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			$anvil->System->_load_specific_firewalld_zone({service => $hash_ref->{name}});
			push @{$open_services}, $service;
		}
		
		# Now loop through the open services, protocols and ports looking for the one passed in by 
		# the caller. If found, the port is already open.
		foreach my $service (sort {$a cmp $b} @{$open_services})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
			foreach my $this_protocol ("tcp", "udp")
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_protocol => $this_protocol }});
				foreach my $this_port (sort {$a cmp $b} @{$anvil->data->{firewalld}{zones}{by_name}{$service}{tcp}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_port => $this_port }});
					if (($port_number eq $this_port) && ($this_protocol eq $protocol))
					{
						# Opened already (as the recorded service).
						$open = $service;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open }});
						last if $open;
					}
					last if $open;
				}
				last if $open;
			}
			last if $open;
		}
	}
	
	# We're done if we were just checking. However, if we've been asked to open a currently closed port,
	# or vice versa, make the change before returning.
	my $changed = 0;
	if (($task eq "open") && (not $open))
	{
		# Map the port to a service, if possible.
		my $service = $anvil->System->_match_port_to_service({port => $port_number});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
		
		# Open the port
		if ($service)
		{
			my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --add-service ".$service;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
			if ($output eq "success")
			{
				$open    = 1;
				$changed = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open, changed => $changed }});
			}
			else
			{
				# Something went wrong...
				return("!!error!!");
			}
		}
		else
		{
			my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --add-port ".$port_number."/".$protocol;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
			if ($output eq "success")
			{
				$open    = 1;
				$changed = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open, changed => $changed }});
			}
			else
			{
				# Something went wrong...
				return("!!error!!");
			}
		}
	}
	elsif (($task eq "close") && ($open))
	{
		# Map the port to a service, if possible.
		my $service = $anvil->System->_match_port_to_service({port => $port_number});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
		
		# Close the port
		if ($service)
		{
			my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --remove-service ".$service;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
			if ($output eq "success")
			{
				$open    = 0;
				$changed = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open, changed => $changed }});
			}
			else
			{
				# Something went wrong...
				return("!!error!!");
			}
		}
		else
		{
			my $shell_call = $anvil->data->{path}{exe}{'firewall-cmd'}." --permanent --remove-port ".$port_number."/".$protocol;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
			if ($output eq "success")
			{
				$open    = 0;
				$changed = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open, changed => $changed }});
			}
			else
			{
				# Something went wrong...
				return("!!error!!");
			}
		}
	}
	
	# If we made a change, reload.
	if ($changed)
	{
		$anvil->System->reload_daemon({daemon => $anvil->data->{sys}{daemon}{firewalld}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'open' => $open }});
	return($open);
}

=head2 pids

This parses C<< ps aux >> and stores the information about running programs in C<< pids::<pid_number>::<data> >>. If called against a remote host, the data is stored in C<< remote_pids::<pid_number>::<data> >>.

Optionally, if the C<< program_name >> parameter is set, an array of PIDs for that program will be returned.

Parameters;

=head3 ignore_me (optional, default '0')

If set to C<< 1 >>, the PID of this program is ignored.

=head3 program_name (optional)

This is an option string that is searched for in the 'command' portion of the 'ps aux' call. If this string matches, the PID is added to the array reference returned by this method.

=head3 password (optional)

If you are testing IPMI from a remote machine, this is the password used to connect to that machine. If not passed, an attempt to connect with passwordless SSH will be made (but this won't be the case in most instances). Ignored if C<< target >> is not given.

=head3 port (optional, default 22)

This is the TCP port number to use if connecting to a remote machine over SSH. Ignored if C<< target >> is not given.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user we will use when logging in to the target machine.

=head3 target (optional)

This is the IP address or (resolvable) host name of the target machine to test the IPMI connection from.

=cut
sub pids
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->pids()" }});
	
	my $ignore_me     = defined $parameter->{ignore_me}     ? $parameter->{ignore_me}     : 0;
	my $program_name  = defined $parameter->{program_name}  ? $parameter->{program_name}  : "";
	my $password      = defined $parameter->{password}      ? $parameter->{password}      : "";
	my $port          = defined $parameter->{port}          ? $parameter->{port}          : "";
	my $remote_user   = defined $parameter->{remote_user}   ? $parameter->{remote_user}   : "";
	my $target        = defined $parameter->{target}        ? $parameter->{target}        : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ignore_me    => $ignore_me, 
		program_name => $program_name,
	}});
	
	my $my_pid      = $$;
	my $pids        = [];
	my $shell_call  = $anvil->data->{path}{exe}{ps}." aux";
	my $pid_key     = "pids";
	my $output      = "";
	my $return_code = "";
	if ($anvil->Network->is_local({host => $target}))
	{
		
		# Local call
		($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output       => $output, 
			return_code  => $return_code,
		}});
	}
	else
	{
		# Remote call, clear the 'my_pid'
		$my_pid  = "";
		$pid_key = "remote_pids";
		($output, my $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error  => $error,
			output => $output,
		}});
	}
	
	# If we stored this data before, delete it as it is now stale.
	if (exists $anvil->data->{$pid_key})
	{
		delete $anvil->data->{$pid_key};
	}
	
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({ string => $line });
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});

		if ($line =~ /^\S+ \d+ /)
		{
			my ($user, $pid, $cpu, $memory, $virtual_memory_size, $resident_set_size, $control_terminal, $state_codes, $start_time, $time, $command) = ($line =~ /^(\S+) (\d+) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*)$/);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				user                => $user, 
				pid                 => $pid, 
				cpu                 => $cpu, 
				memory              => $memory, 
				virtual_memory_size => $virtual_memory_size, 
				resident_set_size   => $resident_set_size, 
				control_terminal    => $control_terminal, 
				state_codes         => $state_codes, 
				start_time          => $start_time, 
				'time'              => $time, 
				command             => $command, 
			}});
			
			if ($ignore_me)
			{
				if ($pid eq $my_pid)
				{
					# This is us! :D
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						pid    => $pid, 
						my_pid => $my_pid, 
					}});
					next;
				}
				elsif (($command =~ /--status/) or ($command =~ /--state/))
				{
					# Ignore this, it is someone else also checking the state.
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { command => $command }});
					next;
				}
				elsif ($command =~ /\/timeout (\d)/)
				{
					# Ignore this, we were called by 'timeout' so the pid will be 
					# different but it is still us.
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { command => $command }});
					next;
				}
			}
			
			# Store by PID
			$anvil->data->{$pid_key}{$pid}{user}                = $user;
			$anvil->data->{$pid_key}{$pid}{cpu}                 = $cpu;
			$anvil->data->{$pid_key}{$pid}{memory}              = $memory;
			$anvil->data->{$pid_key}{$pid}{virtual_memory_size} = $virtual_memory_size;
			$anvil->data->{$pid_key}{$pid}{resident_set_size}   = $resident_set_size;
			$anvil->data->{$pid_key}{$pid}{control_terminal}    = $control_terminal;
			$anvil->data->{$pid_key}{$pid}{state_codes}         = $state_codes;
			$anvil->data->{$pid_key}{$pid}{start_time}          = $start_time;
			$anvil->data->{$pid_key}{$pid}{'time'}              = $time;
			$anvil->data->{$pid_key}{$pid}{command}             = $command;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"${pid_key}::${pid}::cpu"                 => $anvil->data->{$pid_key}{$pid}{cpu}, 
				"${pid_key}::${pid}::memory"              => $anvil->data->{$pid_key}{$pid}{memory}, 
				"${pid_key}::${pid}::virtual_memory_size" => $anvil->data->{$pid_key}{$pid}{virtual_memory_size}, 
				"${pid_key}::${pid}::resident_set_size"   => $anvil->data->{$pid_key}{$pid}{resident_set_size}, 
				"${pid_key}::${pid}::control_terminal"    => $anvil->data->{$pid_key}{$pid}{control_terminal}, 
				"${pid_key}::${pid}::state_codes"         => $anvil->data->{$pid_key}{$pid}{state_codes}, 
				"${pid_key}::${pid}::start_time"          => $anvil->data->{$pid_key}{$pid}{start_time}, 
				"${pid_key}::${pid}::time"                => $anvil->data->{$pid_key}{$pid}{'time'}, 
				"${pid_key}::${pid}::command"             => $anvil->data->{$pid_key}{$pid}{command}, 
			}});
			
			if ($command =~ /$program_name/)
			{
				# If we're calling locally and we see our own PID, skip it.
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					command      => $command, 
					program_name => $program_name, 
					pid          => $pid, 
					my_pid       => $my_pid, 
					line         => $line
				}});
				push @{$pids}, $pid;
			}
		}
	}
	
	return($pids);
}


=head2 parse_arguments 

This takes command-line switches, similar to how C<< Get->switches >> does, and breaks them up and stores them in a hash reference which is returned. The difference being that this processes any argument-like string instead of specific C<< @ARGV >>. 

Switches without associated values are set to C<< #!SET!# >>. If there is a problem, and empty string is returned. On success, a hash reference is returned in the format C<< <switch> = <value> >>.

Parameters;

=head3 arguments (required)

This is a plain string of arguments to be broken up.

=cut
sub parse_arguments
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->parse_arguments()" }});
	
	my $arguments = defined $parameter->{arguments} ? $parameter->{arguments} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		arguments => $arguments, 
	}});
	
	my $hash   = {};
	my $quoted = "";
	my $switch = "";
	my $value  = "";
	foreach my $arg (split/ /, $arguments)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { arg => $arg }});
		if (($arg =~ /^'/) or ($arg =~ /^"/))
		{
			# Store a quoted value.
			$quoted .= $arg." ";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { quoted => $quoted }});
		}
		elsif ($quoted)
		{
			if (($arg =~ /'$/) or ($arg =~ /"$/))
			{
				# Done
				$quoted .= $arg;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { quoted => $quoted }});
				if ($quoted =~ /^'(.*)'$/)
				{
					$value = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
				}
				elsif ($quoted =~ /^"(.*)"$/)
				{
					$value = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
				}
				$hash->{$switch} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "hash->{$switch}" => $hash->{$switch} }});
				
				$quoted = "";
				$switch = "";
				$value  = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					quoted => $quoted,
					switch => $switch, 
					value  => $value,
				}});
			}
			else
			{
				$quoted .= $arg." ";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { quoted => $quoted }});
			}
		}
		elsif ($arg =~ /^-/)
		{
			if ($switch)
			{
				$value = "#!SET!#";
				$hash->{$switch} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "hash->{$switch}" => $hash->{$switch} }});
				
				$switch = "";
				$value  = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					switch => $switch, 
					value  => $value,
				}});
			}
			
			$quoted =  "";
			if ($arg =~ /^(.*?)=(.*)$/)
			{
				$switch =  $1;
				$value  =  $2;
				$switch =~ s/^-{1,2}//g;
				
				if (($value =~ /^'/) or ($value =~ /^"/))
				{
					$quoted .= $value." ";
				}
				else
				{
					$hash->{$switch} = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "hash->{$switch}" => $hash->{$switch} }});
					
					$switch = "";
					$value  = "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						switch => $switch, 
						value  => $value,
					}});
				}
			}
			else
			{
				$switch =  $arg;
				$switch =~ s/^-{1,2}//g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { switch => $switch }});
			}
		}
		else
		{
			$hash->{$switch} = $arg;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "hash->{$switch}" => $hash->{$switch} }});
			
			$switch = "";
			$value  = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				switch => $switch, 
				value  => $value,
			}});
		}
	}
	
	return($hash);
}


=head2 parse_lshw

B<< NOTE >>: This method is not complete, do not use it yet!

This calls C<< lshw >> (in XML format) and parses the output. Data is stored as:

 * lshw::...

Parameters;

=head3 xml (optional)

If set, the passed-in XML is parsed and C<< lshw -xml >> is not called. This should only be used for testing / debugging.

=cut
sub parse_lshw
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->parse_lsblk()" }});
	
	my $xml = defined $parameter->{xml} ? $parameter->{xml} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { xml => $xml }});
	
	if (not $xml)
	{
		my $shell_call = $anvil->data->{path}{exe}{lshw}." -xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		($xml, my $return_code) = $anvil->System->call({shell_call => $shell_call});
		if ($return_code)
		{
			# Failed.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0080", variables => { 
				return_code => $return_code,
				output      => $xml, 
			}});
			return(1);
		}
	}
	
	local $@;
	my $dom = eval { XML::LibXML->load_xml(string => $xml); };
	if ($@)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0053", variables => { 
			cib   => $xml,
			error => $@,
		}});
	}

	foreach my $node ($dom->findnodes('/list/node'))
	{
		my $id    = $node->{id};
		my $class = $node->{class};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			id    => $id, 
			class => $class,
		}});
	}
=cut
	foreach my $node ($dom->findnodes('/list/node'))
	{
		my $id                   = $node->{id};
		my $class                = $node->{class};
		my $handle               = $node->{handle};
		my $parent_description   = defined $node->findvalue('./description') ? $node->findvalue('./description') : "";
		my $logical_name         = defined $node->findvalue('./logicalname') ? $node->findvalue('./logicalname') : "";
		my $parent_vendor        = defined $node->findvalue('./vendor')      ? $node->findvalue('./vendor')      : "";
		my $parent_model         = defined $node->findvalue('./product')     ? $node->findvalue('./product')     : "";
		my $parent_serial_number = defined $node->findvalue('./serial')      ? $node->findvalue('./serial')      : "";
		my $parent_media         = $id;
		if ($id eq "device")
		{
			if (($parent_description =~ /sd card/i) or ($logical_name =~ /\/dev\/mmcblk/))
			{
				$parent_media = "sdcard";
			}
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			id                  => $id, 
			class               => $class,
			logical_name        => $logical_name, 
			parent_vendor       => $parent_vendor, 
			parent_model        => $parent_model, 
		}});
		# Sub devices may not appear, so we'll later match logical names (when they're a path) to devices in 'df' later.
		foreach my $device ($node->findnodes('./node'))
		{
			my $dev_id        = $device->{id};
			my $dev_class     = $device->{class};
			my $bus_info      = defined $device->findvalue('./businfo')     ? $device->findvalue('./businfo')     : "";
			my $path          = defined $device->findvalue('./logicalname') ? $device->findvalue('./logicalname') : "";
			my $description   = defined $device->findvalue('./description') ? $device->findvalue('./description') : "";
			my $vendor        = defined $device->findvalue('./vendor')      ? $device->findvalue('./vendor')      : "";
			$vendor        = $parent_vendor if not $vendor;
			my $model         = defined $device->findvalue('./product')     ? $device->findvalue('./product')     : "";
			$model         = $parent_model if not $model;
			my $serial_number = defined $device->findvalue('./serial')      ? $device->findvalue('./serial')      : "";
			$serial_number = $parent_serial_number if not $serial_number;
			my $size_number   = defined $device->findvalue('./size')        ? $device->findvalue('./size')        : "";
			$size_number   = 0 if not $size_number;
			my ($size_dom)    = $device->findnodes('./size');
			my $size_units    = $size_dom->{units};
			$size_units    = "bytes" if not $size_units;
			my $size_in_bytes = $anvil->Convert->human_readable_to_bytes({size => $size_number, type => $size_units});
			my $media         = $dev_id;
			if (($bus_info =~ /nvme/i) or ($path =~ /\/dev\/nvm/))
			{
				$bus_info = "nvme";
				$media    = "ssd";
			}
			if ($dev_id eq "cdrom")
			{
				$media = "optical";
			}
			if (($bus_info =~ /^scsi/) or ($description =~ /ATA Disk/i))
			{
				# Call 
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				dev_id        => $dev_id, 
				dev_class     => $dev_class,
				bus_info      => $bus_info,
				path          => $path,
				description   => $description, 
				vendor        => $vendor, 
				model         => $model, 
				serial_number => $serial_number, 
				size_number   => $size_number, 
				size_units    => $size_units, 
				size_in_bytes => $anvil->Convert->add_commas({number => $size_in_bytes})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size_in_bytes}),
				media         => $media, 
			}});
		}
	}
=cut

	return(0);
}


=head2 read_ssh_config

This reads /etc/ssh/ssh_config and notes hosts with defined ports. When found, the associated port will be automatically used for a given host name or IP address.

Matches will have their ports stored in C<< hosts::<host_name>::port >>.

This method takes no parameters.

=cut
sub read_ssh_config
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->read_ssh_config()" }});
	
	# This will hold the raw contents of the file.
	my $this_host                   = "";
	   $anvil->data->{raw}{ssh_config} = $anvil->Storage->read_file({file => $anvil->data->{path}{configs}{ssh_config}});
	foreach my $line (split/\n/, $anvil->data->{raw}{ssh_config})
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
			$anvil->data->{hosts}{$this_host}{port} = $port;
		}
	}
	
	return(0);
}

=head2 reload_daemon

This method reloads a daemon (typically to pick up a change in configuration). The return code from the start request will be returned.

If the return code for the reload command wasn't read, C<< !!error!! >> is returned. If it did reload, C<< 0 >> is returned. If the reload failed, a non-0 return code will be returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to reload. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub reload_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->reload_daemon()" }});
	
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." reload ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	return($return_code);
}

=head2 reboot_needed

This sets, clears or checks if the local system needs to be restart.

This returns C<< 1 >> if a reset is currently needed and C<< 0 >> if not.

Parameters;

=head3 set (optional)

If this is set to C<< 1 >>, the reset needed variable is set. If this is set to C<< 0 >>, reset needed is cleared.

=cut
sub reboot_needed
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->reboot_needed()" }});
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
	
	if (($set) or ($set eq "0"))
	{
		### TODO: stop other systems from using this database.
		# Am I enabling or disabling?
		if ($set eq "1")
		{
			# Set
			$anvil->Database->insert_or_update_variables({
				debug                 => $debug,
				file                  => $THIS_FILE,
				line                  => __LINE__,
				variable_name         => "reboot::needed", 
				variable_value        => "1", 
				variable_default      => "0", 
				variable_description  => "striker_0089", 
				variable_section      => "system", 
				variable_source_uuid  => $anvil->Get->host_uuid, 
				variable_source_table => "hosts", 
			});
		}
		elsif ($set eq "0")
		{
			# Clear
			$anvil->Database->insert_or_update_variables({
				debug                 => $debug,
				file                  => $THIS_FILE,
				line                  => __LINE__,
				variable_name         => "reboot::needed", 
				variable_value        => "0", 
				variable_default      => "0", 
				variable_description  => "striker_0089", 
				variable_section      => "system", 
				variable_source_uuid  => $anvil->Get->host_uuid, 
				variable_source_table => "hosts", 
			});
		}
		else
		{
			# Called with an invalid value.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0197", variables => { set => $set }});
			$set = "";
		}
	}
	
	my ($reboot_needed, $variable_uuid, $modified_date) = $anvil->Database->read_variable({
		debug                 => $debug, 
		file                  => $THIS_FILE,
		line                  => __LINE__,
		variable_name         => "reboot::needed",
		variable_source_table => "hosts",
		variable_source_uuid  => $anvil->Get->host_uuid,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		reboot_needed => $reboot_needed, 
		variable_uuid => $variable_uuid, 
		modified_date => $modified_date, 
	}});
	
	if ($reboot_needed eq "")
	{
		$reboot_needed = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reboot_needed => $reboot_needed }});
	}
	
	return($reboot_needed);
}

=head2 restart_daemon

This method restarts a daemon (typically to pick up a change in configuration). The return code from the start request will be returned.

If the return code for the restart command wasn't read, C<< !!error!! >> is returned. If it did restart, C<< 0 >> is returned. If the restart failed, a non-0 return code will be returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to restart. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub restart_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->restart_daemon()" }});
	
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." restart ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	return($return_code);
}

=head2 start_daemon

This method starts a daemon. The return code from the start request will be returned.

If the return code for the start command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to start. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub start_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->start_daemon()" }});
	
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." start ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	return($return_code);
}

=head2 stop_daemon

This method stops a daemon. The return code from the stop request will be returned.

If the return code for the stop command wasn't read, C<< !!error!! >> is returned.

Parameters;

=head3 daemon (required)

This is the name of the daemon to stop. The exact name given is passed to C<< systemctl >>, so please be mindful of appropriate suffixes.

=cut
sub stop_daemon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->stop_daemon()" }});
	
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." stop ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code,
	}});
	
	return($return_code);
}

=head2 stty_echo

This turns echo off (for password prompts, for example) and back on again. It does so in a way that a SIGINT/SIGKILL can restore the echo before the program dies.

B<< Note >>: Calling C<< on >> before C<< off >> will result in no change. The C<< off >> stores the current TTY in C<< sys::stty >> and uses the value in there to reset the terminal. If you want to change the terminal, you can set that variable manually then call C<< on >>, though this is not recommended.

Parameters;

=head3 set (required, default 'on')

This is set to C<< on >> or C<< off >>, which enables or disables echo'ing respectively.

=cut
sub stty_echo
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->stty_echo()" }});
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0018", variables => { set => $set }});
	
	if ($set eq "off")
	{
		($anvil->data->{sys}{terminal}{stty}, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{stty}." --save"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::terminal::stty' => $anvil->data->{sys}{terminal}{stty}, return_code => $return_code }});
		$anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{stty}." -echo"});
	}
	elsif (($set eq "on") && ($anvil->data->{sys}{terminal}{stty}))
	{
		$anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{stty}." ".$anvil->data->{sys}{terminal}{stty}});
	}
	
	return(0);
}

=head2 test_ipmi

This tests access to an IPMI interface, either locally or from a remote client. This method will automatically shorten the passed-in IPMI password to 20 bytes if the existing password is longer and fails. If the 20 byte password also fails, it will try a third time with a 16 byte password. 

If a working connection is found, the C<< fence_ipmilan >> command that worked will be returned (including the password that worked). 

B<< Note >>: This test uses the C<< fence_ipmilan >> fence agent. This must installed and available on the remote machine (if testing remotely).

Parameters;

=head3 ipmi_password (required)

This is the IPMI user password to use for the IPMI user. It will be shortened to 20 bytes and 16 bytes if necessary.

B<< Note >>: The password will be escaped for the shell inside this method. Do NOT escape it before sending it in!

=head3 ipmi_target (required)

This is the IP or (resolvable) host name of the IPMI BCM to be called.

=head3 ipmi_user (required)

This is the IPMI user to use when trying to log into the IPMI BMC.

=head3 lanplus (optional, default "no-yes")

This determines if LAN Plus is tried when connecting to the IPMI BMC. This is often vendor-specific (some vendors _usually_ use it, others _usually_ don't). If you know for sure which your BMC needs, you can set it. If you aren't sure, but think you know, you can have it try both, either using or not using LAN Plus initially.

This can be set to;

* C<< yes >> - use LAN Plus
* C<< no >> - don't use LAN Plus
* C<< yes-no >> - Try both, using LAN Plus, then trying without.
* C<< no-yes >> - Try both, trying without LAN Plus first, then trying with it.

B<< Note >>: If there is an existing entry in C<< hosts >> -> C<< host_ipmi >>, that will possibly change this value. If C<< --lanplus >> is found, and this is set to C<< no >> or C<< no-yes >>, it will be changed to C<< yes-no >>. Reversed, if C<< --lanplus >> is NOT found, and this was set to C<< yes >> or C<< yes-no >>, it will be changed to C<< no-yes >>. As such, you may want to verify the returned shell command to see if LAN Plus is needed or not, regardless of how this is set.

=head3 password (optional)

If you are testing IPMI from a remote machine, this is the password used to connect to that machine. If not passed, an attempt to connect with passwordless SSH will be made (but this won't be the case in most instances). Ignored if C<< target >> is not given.

=head3 port (optional, default 22)

This is the TCP port number to use if connecting to a remote machine over SSH. Ignored if C<< target >> is not given.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user we will use when logging in to the target machine.

=head3 target (optional)

This is the IP address or (resolvable) host name of the target machine to test the IPMI connection from.

=cut
sub test_ipmi
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->test_ipmi()" }});
	
	my $ipmi_password = defined $parameter->{ipmi_password} ? $parameter->{ipmi_password} : "";
	my $ipmi_target   = defined $parameter->{ipmi_target}   ? $parameter->{ipmi_target}   : "";
	my $ipmi_user     = defined $parameter->{ipmi_user}     ? $parameter->{ipmi_user}     : "";
	my $lanplus       = defined $parameter->{lanplus}       ? $parameter->{lanplus}       : "no-yes";
	my $password      = defined $parameter->{password}      ? $parameter->{password}      : "";
	my $port          = defined $parameter->{port}          ? $parameter->{port}          : "";
	my $remote_user   = defined $parameter->{remote_user}   ? $parameter->{remote_user}   : "";
	my $target        = defined $parameter->{target}        ? $parameter->{target}        : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ipmi_password => $anvil->Log->is_secure($ipmi_password), 
		ipmi_user     => $ipmi_user,
		lanplus       => $lanplus, 
		password      => $anvil->Log->is_secure($password),
		port          => $port, 
		remote_user   => $remote_user, 
	}});
	
	if (not $ipmi_user)
	{
		# Nothing more we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->test_ipmi()", parameter => "ipmi_user" }});
		return("!!error!!");
	}
	if (not $ipmi_target)
	{
		# Nothing more we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->test_ipmi()", parameter => "ipmi_target" }});
		return("!!error!!");
	}
	if (not $ipmi_password)
	{
		# Nothing more we can do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Systeme->test_ipmi()", parameter => "ipmi_password" }});
		return("!!error!!");
	}
	if (($lanplus ne "yes") && ($lanplus ne "no") && ($lanplus ne "yes-no") && ($lanplus ne "no-yes"))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0136", variables => { lanplus => $lanplus }});
		return("!!error!!");
	}
	
	my $escaped_ipmi_password = shell_quote($ipmi_password);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { escaped_ipmi_password => $escaped_ipmi_password }});

	my $twenty_byte_ipmi_password         = "";
	my $twenty_byte_escaped_ipmi_password = "";
	if (length($ipmi_password) > 20)
	{
		$twenty_byte_ipmi_password = $anvil->Words->shorten_string({
			debug    => 3,
			string   => $ipmi_password, 
			'length' => 20,
			secure   => 1,
		});
		$twenty_byte_escaped_ipmi_password = shell_quote($twenty_byte_ipmi_password);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
			twenty_byte_ipmi_password         => $twenty_byte_ipmi_password, 
			twenty_byte_escaped_ipmi_password => $twenty_byte_escaped_ipmi_password,
		}});
	}
	my $sixteen_byte_ipmi_password         = "";
	my $sixteen_byte_escaped_ipmi_password = "";
	if (length($ipmi_password) > 16)
	{
		$sixteen_byte_ipmi_password = $anvil->Words->shorten_string({
			debug    => 3,
			string   => $ipmi_password, 
			'length' => 16,
			secure   => 1,
		});
		$sixteen_byte_escaped_ipmi_password = shell_quote($sixteen_byte_ipmi_password);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
			sixteen_byte_ipmi_password         => $sixteen_byte_ipmi_password, 
			sixteen_byte_escaped_ipmi_password => $sixteen_byte_escaped_ipmi_password,
		}});
	}
	
	# Read in the 'host_ipmi' (if it exists) to see if there's an old entry. If there is, and if the 
	# password matches one of the shorter ones, we'll try that first.
	my $query = "SELECT host_ipmi FROM hosts WHERE host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid).";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	my $host_ipmi = defined $results->[0]->[0] ? $results->[0]->[0] : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { host_ipmi => $host_ipmi }});
	
	my @password_array = ($escaped_ipmi_password, $twenty_byte_escaped_ipmi_password, $sixteen_byte_escaped_ipmi_password);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
		'password_array[0]' => $password_array[0],
		'password_array[1]' => $password_array[1],
		'password_array[2]' => $password_array[2],
	}});
	
	my $old_password = "";
	my $old_lanplus  = "";
	if ($host_ipmi)
	{
		if ($host_ipmi =~ /--lanplus/) 
		{
			# If we were given 'lanplus' of 'no' or 'no-yes', change it to 'yes-no'.
			if (($lanplus eq "no") or ($lanplus eq "no-yes"))
			{
				$lanplus = "yes-no";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lanplus => $lanplus }});
			}
		}
		else
		{
			# If we were given 'lanplus' of 'yes' or 'yes-no', change it to 'no-yes'.
			if (($lanplus eq "yes") or ($lanplus eq "yes-no"))
			{
				$lanplus = "no-yes";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lanplus => $lanplus }});
			}
		}
		
		# If there was an old password, we ONLY use it if it matches the passed in password or one
		# of the shorter variants. The caller may be checking if the password needs to be updated or
		# has been updated successfully.
		if ($host_ipmi =~ /--password (.*) --action/) 
		{
			$old_password = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { old_password => $old_password }});
			
			if (($twenty_byte_escaped_ipmi_password) && ($twenty_byte_escaped_ipmi_password eq $old_password))
			{
				# It matches the 20-byte password, try it first.
				@password_array = ($twenty_byte_escaped_ipmi_password, $escaped_ipmi_password, $sixteen_byte_escaped_ipmi_password);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
					'password_array[0]' => $password_array[0],
					'password_array[1]' => $password_array[1],
					'password_array[2]' => $password_array[2],
				}});
			}
			elsif (($sixteen_byte_escaped_ipmi_password) && ($sixteen_byte_escaped_ipmi_password eq $old_password))
			{
				# It matches the 16-byte password, try it first.
				@password_array = ($sixteen_byte_escaped_ipmi_password, $escaped_ipmi_password, $twenty_byte_escaped_ipmi_password);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
					'password_array[0]' => $password_array[0],
					'password_array[1]' => $password_array[1],
					'password_array[2]' => $password_array[2],
				}});
			}
		}
	}
	
	my @lanplus_array;
	if ($lanplus eq "no-yes")
	{
		@lanplus_array = ("", "--lanplus");
	}
	elsif ($lanplus eq "yes-no")
	{
		@lanplus_array = ("--lanplus", "");
	}
	elsif ($lanplus eq "yes")
	{
		@lanplus_array = ("--lanplus");
	}
	elsif ($lanplus eq "no")
	{
		@lanplus_array = ("");
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'lanplus_array[0]' => $lanplus_array[0],
		'lanplus_array[1]' => defined $lanplus_array[1] ? defined $lanplus_array[1] : "--",
	}});
	
	my $shell_call = "";
	my $found_it   = 0;
	foreach my $lanplus_switch (@lanplus_array)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lanplus_switch => $lanplus_switch }});
		foreach my $test_password (@password_array)
		{
			# If the password is blank, it's because the previous password wasn't too long, so 
			# no sense trying again.
			next if $test_password eq "";
			
			# Build the shell call.
			$shell_call = $anvil->data->{path}{directories}{fence_agents}."/fence_ipmilan ".$lanplus_switch." --ip ".$ipmi_target." --username ".$ipmi_user." --password ".$test_password." --action status";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { shell_call => $shell_call }});
	
			my $output      = "";
			my $return_code = "";
			if ($target)
			{
				### Remote call
				# HPs can take over 10 seconds to respond, so we set the timeout higher to account for this.
				($output, my $error, $return_code) = $anvil->Remote->call({
					debug       => $debug, 
					secure      => 1,
					timeout     => 30,
					shell_call  => $shell_call, 
					target      => $target,
					password    => $password,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					error       => $error,
					output      => $output,
					return_code => $return_code, 
				}});
			}
			else
			{
				### Local call
				($output, $return_code) = $anvil->System->call({
					debug       => $debug, 
					secure      => 1,
					shell_call  => $shell_call, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
			}
			if (not $return_code)
			{
				# Got it!
				$found_it = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found_it => $found_it }});
			}
			else
			{
				$shell_call = "";
			}
			last if $found_it;
		}
		last if $found_it;
	}
	
	# If we have a valid shell call, and it doesn't match the one we read in earlier, update it.
	if (($shell_call) && ($host_ipmi ne $shell_call))
	{
		# Take the '--action status' off.
		$shell_call =~ s/ --action status//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, secure => 1, level => $debug, list => { shell_call => $shell_call }});
		
		# Update it.
		my $query = "UPDATE hosts SET host_ipmi = ".$anvil->Database->quote($shell_call)."  WHERE host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid).";";
		$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
	}
	
	return($shell_call);
}

=head2 update_hosts

This uses the host list from C<< Get->trusted_hosts >>, along with data from C<< ip_addresses >>, to create a list of host name to IP addresses that should be in C<< /etc/hosts >>. Existing hosts where the IP has changed will be updated. Missing entries will be added. All other existing entries are left unchanged.

B<< Note >>: If C<< sys::hosts::manage >> is set to C<< 0 >>, this method will return without doing anything

This method takes no parameters.

=cut
sub update_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->update_hosts()" }});
	
	# Is managing hosts disabled?
	if ((exists $anvil->data->{sys}{hosts}{manage}) && ($anvil->data->{sys}{hosts}{manage} eq "0"))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0648"});
		return(0);
	}
	
	# Get the list of hosts we trust.
	my $trusted_host_uuids = $anvil->Get->trusted_hosts({debug => $debug});
	$anvil->Database->get_ip_addresses({debug => $debug});
	
	# Load the IPs we manage. If we find any entries for these that we don't expect, we'll remove them.
	$anvil->Database->get_ip_addresses({debug => $debug});
	
	foreach my $host_uuid (keys %{$anvil->data->{hosts}{host_uuid}})
	{
		my $host_name       = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
		my $short_host_name = $host_name;
		   $short_host_name =~ s/\..*$//;
		my $host_type       = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:host_name'       => $host_name,
			's2:short_host_name' => $short_host_name, 
			's3:host_type'       => $host_type, 
		}});
		
		foreach my $on_network (sort {$a cmp $b} keys %{$anvil->data->{hosts}{host_uuid}{$host_uuid}{network}})
		{
			# Break the network sequence off the name for later sorting
			my ($network_type, $sequence) = ($on_network =~ /^(.*?)(\d+)$/);
			my $ip_address                = $anvil->data->{hosts}{host_uuid}{$host_uuid}{network}{$on_network}{ip_address};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:on_network"   => $on_network, 
				"s2:network_type" => $network_type, 
				"s3:sequence"     => $sequence, 
				"s4:ip_address"   => $ip_address,
			}});
			
			# Store the hostname in an easy to lookup format, too.
			my $store_host_name                                            = $short_host_name.".".$on_network;
			   $anvil->data->{hosts}{needed}{$store_host_name}{ip_address} = $ip_address;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"hosts::needed::${store_host_name}::ip_address" => $anvil->data->{hosts}{needed}{$store_host_name}{ip_address},
			}});
			
			# If this is BCN 1, store the full and short host names as well.
			if ($on_network eq "bcn1")
			{
				# If the host name and short host name, this will be duplicate. No harm...
				$anvil->data->{hosts}{needed}{$host_name}{ip_address}       = $ip_address;
				$anvil->data->{hosts}{needed}{$short_host_name}{ip_address} = $ip_address;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"hosts::needed::${host_name}::ip_address"       => $anvil->data->{hosts}{needed}{$host_name}{ip_address},
					"hosts::needed::${short_host_name}::ip_address" => $anvil->data->{hosts}{needed}{$short_host_name}{ip_address},
				}});
			}
		}
	}
	
	# Read in the existing hosts file
	my $add_header    = 1;
	my $changes       = 0;
	my $added_lo_ipv4 = 0; 
	my $added_lo_ipv6 = 0;
	my $new_body      = "";
	my $old_body      = $anvil->Storage->read_file({
		debug => $debug,
		file  => $anvil->data->{path}{configs}{hosts},
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_body => $old_body }});
	
	# This will track the IPs we've seen. We'll only write these out once, and skip any futher entries 
	# that may be found.
	my $written_ips = {};
	
	# Parse the existing 
	foreach my $line (split/\n/, $old_body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /##] anvil-daemon \[##/)
		{
			$add_header = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { add_header => $add_header }});
		}
		
		# Delete everything follow a hash, then clear spaces.
		my $line_comment = "";
		my $line_hosts   = "";
		if ($line =~ /^#/)
		{
			$new_body .= $line."\n";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
			next;
		}
		if ($line =~ /#(.*)$/)
		{
			$line_comment = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line_comment => $line_comment }});
		}
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if (not $line)
		{
			$new_body .= "\n";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
			next;
		}
		
		# If this line is localhost, set it statically. This is needed because cloud-init sets the 
		# real host name to point to 127.0.0.1 / ::1. (WHY?!)
		if ($line =~ /^127.0.0.1\s/)
		{
			if ($line ne "127.0.0.1\tlocalhost localhost.localdomain localhost4 localhost4.localdomain4")
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
				
				if (not $added_lo_ipv4)
				{
					$new_body      .= "127.0.0.1\tlocalhost localhost.localdomain localhost4 localhost4.localdomain4\n";
					$added_lo_ipv4 =  1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { added_lo_ipv4 => $added_lo_ipv4 }});
				}
			}
			else
			{
				# Line is as expected.
				$added_lo_ipv4 =  1;
				$new_body      .= $line."\n";
			}
			next;
		}
		if ($line =~ /^::1\s/)
		{
			if ($line ne "::1\t\tlocalhost localhost.localdomain localhost6 localhost6.localdomain6")
			{
				$changes = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
				
				if (not $added_lo_ipv6)
				{
					$new_body      .= "::1\t\tlocalhost localhost.localdomain localhost6 localhost6.localdomain6\n";
					$added_lo_ipv6 =  1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { added_lo_ipv6 => $added_lo_ipv6 }});
				}
			}
			else
			{
				# Line is as expected.
				$added_lo_ipv6 =  1;
				$new_body      .= $line."\n";
			}
			next;
		}
		
		# Now pull apart the line and store the entries.
		my ($ip_address, $names) = ($line =~ /^(.*?)\s+(.*)$/);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:ip_address' => $ip_address,
			's2:names'      => $names,
		}});
		
		# Make sure the IP is valid.
		my $is_ip = $anvil->Validate->ip({ip => $ip_address, debug => 3});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_ip => $is_ip }});
		if (not $is_ip)
		{
			# Log and skip.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, key => "warning_0051", variables => { 
				ip    => $ip_address,
				names => $names,
			}});
			next;
		}
		
		if (exists $written_ips->{$ip_address})
		{
			# Skipping at least one line, rewrite the file.
			$changes = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
			next;
		}
		$written_ips->{$ip_address} = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "written_ips->{".$ip_address."}" => $written_ips->{$ip_address} }});
		
		foreach my $name (split/\s+/, $names)
		{
			# Is this name one we manage? If so, has the IP changed?
			if ((exists $anvil->data->{hosts}{needed}{$name}) && ($anvil->data->{hosts}{needed}{$name}{ip_address}))
			{
				my $current_ip = $anvil->data->{hosts}{needed}{$name}{ip_address};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					ip_address => $ip_address,
					current_ip => $current_ip,
				}});
				if ($current_ip eq $ip_address)
				{
					# Matches, we don't need to deal with this name.
					delete $anvil->data->{hosts}{needed}{$name};
				}
				else
				{
					# The IP has changed. Skip this name (which removes it from the list).
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0481", variables => { 
						old_ip => $current_ip,
						new_ip => $ip_address, 
						host   => $name,
					}});
					$changes = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
					next;
				}
			}
			
			$line_hosts .= $name." ";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line_hosts => $line_hosts }});
		}
		
		# If we have any names for this IP, store it.
		if ($line_hosts)
		{
			my $tab = "\t";
			if (length($ip_address) < 8)
			{
				$tab = "\t\t";
			}
			my $new_line .= $ip_address.$tab.$line_hosts;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_line => $new_line }});
			if ($line_comment)
			{
				$new_line .= "\t# ".$line_comment."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_line => $new_line }});
			}
			else
			{
				$new_line =~ s/\s+$//;
				$new_line .= "\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_line => $new_line }});
			}
			$new_body .= $new_line;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
		}
	}
	
	# Do we need to pre-pend the header?
	if ($add_header)
	{
		# Prepend the header.
		my $header   =  $anvil->Words->string({key => "message_0177"});
		   $header   =~ s/^\n//;
		   $new_body =  $header.$new_body;
		   $changes  =  1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:changes'  => $changes,
			's2:header'   => $header,
			's3:new_body' => $new_body,
		}});
	}
	
	# Now add any hosts we still need.
	my $ip_order = [];
	my $lines    = {};
	foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{hosts}{needed}})
	{
		my $ip_address = $anvil->data->{hosts}{needed}{$host_name}{ip_address};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip_address => $ip_address }});
		
		if (not exists $lines->{$ip_address})
		{
			my $tab = "\t";
			if (length($ip_address) < 8)
			{
				$tab = "\t\t";
			}

			$lines->{$ip_address} = $ip_address.$tab;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "lines->${ip_address}" => $lines->{$ip_address} }});
			
			# Push the IP into the array so that we print them in the order be first saw them.
			push @{$ip_order}, $ip_address;
		}
		$lines->{$ip_address} .= $host_name." ";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lines->${ip_address}" => $lines->{$ip_address},
		}});
	}
	
	my $new_line_count = @{$ip_order};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_line_count => $new_line_count }});
	if ($new_line_count)
	{
		$changes = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changes => $changes }});
		$new_body .= "\n";
		#$new_body .= "\n# ".$anvil->Words->string({key => "message_0178", variables => { date => $anvil->Get->date_and_time({debug => $debug}) }})."\n";
		
		foreach my $ip_address (@{$ip_order})
		{
			$new_body .= $lines->{$ip_address}."\n";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:changes'  => $changes,
		's2:new_body' => $new_body,
	}});
	if ($changes)
	{
		# Write the new file.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
		my $failed = $anvil->Storage->write_file({
			debug     => $debug,
			overwrite => 1, 
			file      => $anvil->data->{path}{configs}{hosts}, 
			body      => $new_body, 
			user      => "root", 
			group     => "root", 
			mode      => "0644", 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
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


=head2 _check_anvil_conf

This looks for anvil.conf and, if it's missing, regenerates it.

=cut
sub _check_anvil_conf
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->_check_anvil_conf" }});
	
	# Make sure the 'admin' user exists...
	my $admin_uid = getpwnam('admin');
	my $admin_gid = getgrnam('admin');
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		admin_uid => $admin_uid,
		admin_gid => $admin_gid, 
	}});
	if (not $admin_gid)
	{
		# Create the admin group 
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{groupadd}." --system admin"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code, 
		}});
		
		$admin_gid = getgrnam('admin');
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0118", variables => { gid => $admin_gid }});
	}
	if (not $admin_uid)
	{
		# Create the admin user
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{useradd}." --create-home --gid admin --comment \"Anvil! user account\" admin"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code, 
		}});
		
		my $admin_uid = getpwnam('admin');
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0119", variables => { uid => $admin_gid }});
	}
	
	# Does the file exist?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "path::configs::anvil.conf" => $anvil->data->{path}{configs}{'anvil.conf'} }});
	if (not -e $anvil->data->{path}{configs}{'anvil.conf'})
	{
		
		# Nope! What the hell? Create it.
		my $failed = $anvil->Storage->write_file({
			debug     => $debug,
			overwrite => 1, 
			file      => $anvil->data->{path}{configs}{'anvil.conf'}, 
			body      => $anvil->Words->string({key => "file_0002"}), 
			user      => "admin", 
			group     => "admin", 
			mode      => "0644", 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		if (not $failed)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0117", variables => { file => $anvil->data->{path}{configs}{'anvil.conf'} }});
		}
		return($failed);
	}
	
	return(0);
}

=head2 _load_firewalld_zones

This reads in the XML files for all of the firewalld zones.

It takes no arguments.

=cut
sub _load_firewalld_zones
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->_load_firewalld_zones()" }});
	
	my $directory = $anvil->data->{path}{directories}{firewalld_services};
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0018", variables => { directory => $directory }});
	if (not -d $directory)
	{
		# Missing directory...
		return("!!error!!");
	}
	
	$anvil->data->{sys}{firewalld}{services_loaded} = 0 if not defined $anvil->data->{sys}{firewalld}{services_loaded};
	return(0) if $anvil->data->{sys}{firewalld}{services_loaded};
	
	local(*DIRECTORY);
	opendir(DIRECTORY, $directory);
	while(my $file = readdir(DIRECTORY))
	{
		next if $file !~ /\.xml$/;
		my $full_path = $directory."/".$file;
		my $service   = ($file =~ /^(.*?)\.xml$/)[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			full_path => $full_path,
			service   => $service, 
		}});
		
		$anvil->System->_load_specific_firewalld_zone({service => $service});
	}
	closedir DIRECTORY;
	
	# Set this so we don't waste time calling this again.
	$anvil->data->{sys}{firewalld}{services_loaded} = 1;
	
	return(0);
}

=head2 _load_specific_firewalld_zone

This takes the name of a service (with or without the C<< .xml >> suffix) and reads it into the C<< $anvil->data >> hash.

Data will be stored as:

* C<< firewalld::zones::by_name::<service>::name = Short name >>
* C<< firewalld::zones::by_name::<service>::tcp  = <array of port numbers> >>
* C<< firewalld::zones::by_name::<service>::tcp  = <array of port numbers> >>
* C<< firewalld::zones::by_port::<tcp or udp>::<port number> = <service> >>

The 'C<< service >> name is the service file name, minus the C<< .xml >> suffix.

If there is a problem, C<< !!error!! >> will be returned.

Parameters;

=head3 service (required)

This is the name of the service to read in. It expects the file to be in the C<< path::directories::firewalld_services >> diretory. If the service name doesn't end in C<< .xml >>, that suffix will be added automatically.

=cut
sub _load_specific_firewalld_zone
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->_load_specific_firewalld_zone()" }});
	
	my $service = defined $parameter->{service} ? $parameter->{service} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
	
	if (not $service)
	{
		# No service name
		return("!!error!!");
	}
	
	if ($service !~ /\.xml$/)
	{
		$service .= ".xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service => $service }});
	}
	
	# We want the service name to be the file name without the '.xml' suffix.
	my $service_name = ($service =~ /^(.*?)\.xml$/)[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service_name => $service_name }});
	
	my $full_path = $anvil->data->{path}{directories}{firewalld_services}."/".$service;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { full_path => $full_path }});
	if (not -e $full_path)
	{
		# File not found
		return("!!error!!");
	}
	
	local $@;
	my $xml  = XML::Simple->new();
	my $body = "";
	my $test = eval { $body = $xml->XMLin($full_path, KeyAttr => { language => 'name', key => 'name' }, ForceArray => [ 'port' ]) };
	if (not $test)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem reading: [$full_path]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => $error});
		
		# Clear the error so it doesn't propogate out to a future 'die' and confuse things.
		$@ = '';
	}
	else
	{
		my $name = $body->{short};
		$anvil->data->{firewalld}{zones}{by_name}{$service_name}{name} = $name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "firewalld::zones::by_name::${service_name}::name" => $anvil->data->{firewalld}{zones}{by_name}{$service_name}{name} }});
		
		if ((not defined $anvil->data->{firewalld}{zones}{by_name}{$service_name}{tcp}) or (ref($anvil->data->{firewalld}{zones}{by_name}{$service_name}{tcp}) ne "ARRAY"))
		{
			$anvil->data->{firewalld}{zones}{by_name}{$service_name}{tcp} = [];
		}
		if ((not defined $anvil->data->{firewalld}{zones}{by_name}{$service_name}{udp}) or (ref($anvil->data->{firewalld}{zones}{by_name}{$service_name}{udp}) ne "ARRAY"))
		{
			$anvil->data->{firewalld}{zones}{by_name}{$service_name}{udp} = [];
		}
		
		foreach my $hash_ref (@{$body->{port}})
		{
			my $this_port     = $hash_ref->{port};
			my $this_protocol = $hash_ref->{protocol};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				this_port     => $this_port,
				this_protocol => $this_protocol,
			}});
			
			# Is this a range?
			if ($this_port =~ /^(\d+)-(\d+)$/)
			{
				# Yup.
				my $start = $1;
				my $end   = $2;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					start => $start,
					end   => $end,
				}});
				foreach my $port ($start..$end)
				{
					$anvil->data->{firewalld}{zones}{by_port}{$this_protocol}{$port} = $service_name;
					push @{$anvil->data->{firewalld}{zones}{by_name}{$service_name}{$this_protocol}}, $port;
				}
			}
			else
			{
				# Nope
				$anvil->data->{firewalld}{zones}{by_port}{$this_protocol}{$this_port} = $service_name;
				push @{$anvil->data->{firewalld}{zones}{by_name}{$service_name}{$this_protocol}}, $this_port;
			}
		}
	}
	
	return(0);
}

=head2 _match_port_to_service

This takes a port number and returns the service name, if it matches one of them. Otherwise it returns an empty string.

Parameters;

=head3 port (required) 

This is the port number to match.

=head3 protocol (optional)

This is the protocol to match, either C<< tcp >> or C<< udp >>. If this is not specified, C<< tcp >> is used.

=cut
# NOTE: We read the XML files instead of use 'firewall-cmd' directly because reading the files is about 30x 
#       faster.
sub _match_port_to_service
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->_match_port_to_service()" }});
	
	my $port     = defined $parameter->{port}     ? $parameter->{port}     : "";
	my $protocol = defined $parameter->{protocol} ? $parameter->{protocol} : "tcp";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		port     => $port, 
		protocol => $protocol,
	}});
	
	# Do we already know about this service?
	my $service_name = "";
	if ((exists $anvil->data->{firewalld}{zones}{by_port}{$protocol}{$port}) && ($anvil->data->{firewalld}{zones}{by_port}{$protocol}{$port}))
	{
		# Yay!
		$service_name = $anvil->data->{firewalld}{zones}{by_port}{$protocol}{$port};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service_name => $service_name }});
	}
	else
	{
		# Load all zones and look
		$anvil->System->_load_firewalld_zones;
		if ((exists $anvil->data->{firewalld}{zones}{by_port}{$protocol}{$port}) && ($anvil->data->{firewalld}{zones}{by_port}{$protocol}{$port}))
		{
			# Got it now.
			$service_name = $anvil->data->{firewalld}{zones}{by_port}{$protocol}{$port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service_name => $service_name }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { service_name => $service_name }});
	return($service_name);
}

1;

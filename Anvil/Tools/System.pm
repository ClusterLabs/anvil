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

our $VERSION  = "3.0.0";
my $THIS_FILE = "System.pm";

### Methods;
# call
# change_shell_user_password
# check_daemon
# check_if_configured
# check_memory
# get_host_type
# enable_daemon
# find_matching_ip
# get_ips
# get_uptime
# get_os_type
# hostname
# is_local
# maintenance_mode
# manage_firewall
# ping
# read_ssh_config
# reload_daemon
# reboot_needed
# restart_daemon
# start_daemon
# stop_daemon
# stty_echo
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
 my $hostname = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{hostname}});

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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 call

This method makes a system call and returns the output (with the last new-line removed). If there is a problem, 'C<< #!error!# >>' is returned and the error will be logged.

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
	my $redirect        = $redirect_stderr ? " 2>&1" : "";
	$anvil->Log->variables({source => $source, line => $line, level => $debug, secure => $secure, list => { 
		background      => $background, 
		shell_call      => $shell_call,
		redirect        => $redirect, 
		redirect_stderr => $redirect_stderr, 
		stderr_file     => $stderr_file, 
		stdout_file     => $stdout_file, 
	}});
	
	my $output = "#!error!#";
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
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0141", variable => {
					program    => $program,
					shell_call => $shell_call,
				}});
			}
			elsif (not -x $program)
			{
				$found = 0;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "log_0142", variable => {
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
				
				# We'll return the handle instead of output.
				$output = $process;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { output => $output }});
			}
			else
			{
				$output = "";
				open (my $file_handle, $shell_call.$redirect." |") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => $secure, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
				while(<$file_handle>)
				{
					chomp;
					my $line =  $_;
					   $line =~ s/\n$//;
					   $line =~ s/\r$//;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, key => "log_0017", variables => { line => $line }});
					$output .= $line."\n";
				}
				close $file_handle;
				chomp($output);
				$output =~ s/\n$//s;
			}
		}
	}
	
	return($output);
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		user         => $user, 
		target       => $target, 
		port         => $port, 
		remote_user  => $remote_user, 
		new_password => $anvil->Log->secure ? $new_password : $anvil->Words->string({key => "log_0186"}), 
		password     => $anvil->Log->secure ? $password     : $anvil->Words->string({key => "log_0186"}), 
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
	my $salt     = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{openssl}." rand 1000 | ".$anvil->data->{path}{exe}{strings}." | ".$anvil->data->{path}{exe}{'grep'}." -io [0-9A-Za-z\.\/] | ".$anvil->data->{path}{exe}{head}." -n 16 | ".$anvil->data->{path}{exe}{'tr'}." -d '\n'" });
	my $new_hash = crypt($new_password,"\$6\$".$salt."\$");
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		salt     => $salt, 
		new_hash => $new_hash, 
	}});
	
	# Update the password using 'usermod'. NOTE: The single-quotes are crtical!
	my $output     = "";
	my $error      = "";
	my $shell_call = $anvil->data->{path}{exe}{usermod}." --password '".$new_hash."' ".$user."; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?";
	if ($target)
	{
		# Remote call.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		($output, $error) = $anvil->Remote->call({
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
	else
	{
		# Local call
		$output = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	}
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /^return_code:(\d+)$/)
		{
			$return_code = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
		}
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
	
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon."; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /return_code:(\d+)/)
		{
			my $return_code = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { return_code => $return_code }});
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
		}
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

# Not yet written...

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
	
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{''}." --program $program_name"});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /= (\d+) /)
		{
			$used_ram = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { used_ram => $used_ram }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { used_ram => $used_ram }});
	return($used_ram);
}

=head2 get_host_type

This method tries to determine the host type and returns a value suitable for use is the C<< hosts >> table.

First, it looks to see if C<< sys::host_type >> is set and, if so, uses that string as it is. 

If that isn't set, it then looks at the short host name. The following rules are used, in order;

1. If the host name ends in C<< n<digits> >> or C<< node<digits> >>, C<< node >> is returned.
2. If the host name ends in C<< striker<digits> >> or C<< dashboard<digits> >>, C<< dashboard >> is returned.
3. If the host name ends in C<< dr<digits> >>, C<< dr >> is returned.

=cut
sub get_host_type
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->get_host_type()" }});
	
	my $host_type = "";
	my $host_name = $anvil->_short_hostname;
	   $host_type = "unknown";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_type        => $host_type,
		host_name        => $host_name,
		"sys::host_type" => $anvil->data->{sys}{host_type},
	}});
	if ($anvil->data->{sys}{host_type})
	{
		$host_type = $anvil->data->{sys}{host_type};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	}
	elsif (($host_name =~ /n\d+$/) or ($host_name =~ /node\d+$/))
	{
		$host_type = "node";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	}
	elsif (($host_name =~ /striker\d+$/) or ($host_name =~ /dashboard\d+$/))
	{
		$host_type = "dashboard";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	}
	elsif ($host_name =~ /dr\d+$/)
	{
		$host_type = "dr";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	}
	
	return($host_type);
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
	
	my $return     = undef;
	my $daemon     = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." enable ".$daemon." 2>&1; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
}

=head2 find_matching_ip

This takes an IP (or hostname, which is translated to an IP using local resources), and tries to figure out which local IP address is on the same subnet.

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
	if (not $anvil->Validate->is_ipv4({ip => $host}))
	{
		# This will be '0' if it failed, and pre-validated if it returns an IP.
		$host = $anvil->Convert->hostname_to_ip({hostname => $host});
		if (not $host)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0211", variables => { host => $parameter->{host} }});
			return(0);
		}
	}
	
	# Get my local IPs
	$anvil->System->get_ips({debug => $debug});
	
	my $ip = NetAddr::IP->new($host);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	
	# Look through our IPs. First match wins.
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{sys}{network}{interface}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
		next if not $anvil->data->{sys}{network}{interface}{$interface}{ip};
		my $this_ip     = $anvil->data->{sys}{network}{interface}{$interface}{ip};
		my $this_subnet = $anvil->data->{sys}{network}{interface}{$interface}{subnet};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:this_ip"     => $this_ip,
			"s2:this_subnet" => $this_subnet, 
		}});
		
		my $network_range = $this_ip."/".$this_subnet;
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

=head2 get_ips

This method checks the local system for interfaces and stores them in:

* C<< sys::network::interface::<iface_name>::ip >>              - If an IP address is set
* C<< sys::network::interface::<iface_name>::subnet >>          - If an IP is set
* C<< sys::network::interface::<iface_name>::mac >>             - Always set.
* C<< sys::network::interface::<iface_name>::default_gateway >> = C<< 0 >> if not the default gateway, C<< 1 >> if so.
* C<< sys::network::interface::<iface_name>::gateway >>         = If the default gateway, this is the gateway IP address.
* C<< sys::network::interface::<iface_name>::dns >>             = If the default gateway, this is the comma-separated list of active DNS servers.

To aid in look-up by MAC address, C<< sys::mac::<mac_address>::iface >> is also set.

No parameters are accepted by this method.

=cut
sub get_ips
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->get_ips()" }});
	
	my $in_iface = "";
	my $ip_addr  = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ip}." addr list"});
	foreach my $line (split/\n/, $ip_addr)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^\d+: (.*?): /)
		{
			$in_iface = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_iface => $in_iface }});
			
			$anvil->data->{sys}{network}{interface}{$in_iface}{ip}              = "" if not defined $anvil->data->{sys}{network}{interface}{$in_iface}{ip};
			$anvil->data->{sys}{network}{interface}{$in_iface}{subnet}          = "" if not defined $anvil->data->{sys}{network}{interface}{$in_iface}{subnet};
			$anvil->data->{sys}{network}{interface}{$in_iface}{mac}             = "" if not defined $anvil->data->{sys}{network}{interface}{$in_iface}{mac};
			$anvil->data->{sys}{network}{interface}{$in_iface}{default_gateway} = 0  if not defined $anvil->data->{sys}{network}{interface}{$in_iface}{default_gateway};
			$anvil->data->{sys}{network}{interface}{$in_iface}{gateway}         = "" if not defined $anvil->data->{sys}{network}{interface}{$in_iface}{gateway};
			$anvil->data->{sys}{network}{interface}{$in_iface}{dns}             = "" if not defined $anvil->data->{sys}{network}{interface}{$in_iface}{dns};
		}
		next if not $in_iface;
		if ($in_iface eq "lo")
		{
			# We don't care about 'lo'.
			delete $anvil->data->{sys}{network}{interface}{$in_iface};
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
			
			$anvil->data->{sys}{network}{interface}{$in_iface}{ip}     = $ip;
			$anvil->data->{sys}{network}{interface}{$in_iface}{subnet} = $subnet;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:sys::network::interface::${in_iface}::ip"     => $anvil->data->{sys}{network}{interface}{$in_iface}{ip},
				"s2:sys::network::interface::${in_iface}::subnet" => $anvil->data->{sys}{network}{interface}{$in_iface}{subnet},
			}});
		}
		if ($line =~ /ether ([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}) /i)
		{
			my $mac                                                    = $1;
			   $anvil->data->{sys}{network}{interface}{$in_iface}{mac} = $mac;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::network::interface::${in_iface}::mac" => $anvil->data->{sys}{network}{interface}{$in_iface}{mac},
			}});
			
			# We only record the mac in 'sys::mac' if this isn't a bond.
			my $test_file = "/proc/net/bonding/".$in_iface;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_file => $test_file }});
			if (not -e $test_file)
			{
				$anvil->data->{sys}{mac}{$mac}{iface} = $in_iface;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::mac::${mac}::iface" => $anvil->data->{sys}{mac}{$mac}{iface}, 
				}});
			}
		}
	}
	
	# Read the config files for the interfaces we've found.
	local(*DIRECTORY);
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0018", variables => { "path::directories::ifcfg" => $anvil->data->{path}{directories}{ifcfg} }});
	opendir(DIRECTORY, $anvil->data->{path}{directories}{ifcfg});
	while(my $file = readdir(DIRECTORY))
	{
		next if $file eq ".";
		next if $file eq "..";
		next if $file eq "ifcfg-lo";
		next if $file !~ /^ifcfg/;
		next if $file =~ /\.bak$/;
		my $full_path =  $anvil->data->{path}{directories}{ifcfg}."/".$file;
		   $full_path =~ s/\/\///g;
		next if not -f $full_path;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
		
		# Read the file.
		my $file_body = $anvil->Storage->read_file({file => $full_path});
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
				$anvil->data->{sys}{network}{interface}{$interface}{file} = $full_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"sys::network::interface::${interface}::file" => $anvil->data->{sys}{network}{interface}{$interface}{file},
				}});
				foreach my $variable (sort {$a cmp $b} keys %{$temp})
				{
					$anvil->data->{sys}{network}{interface}{$interface}{variable}{$variable} = $temp->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"sys::network::interface::${interface}::file::variable::${variable}" => $anvil->data->{sys}{network}{interface}{$interface}{variable}{$variable},
					}});
				}
			}
		}
	}
	closedir(DIRECTORY);
	
	# Get the routing info.
	my $lowest_metric   = 99999999;
	my $route_interface = "";
	my $route_ip        = "";
	my $ip_route        = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{ip}." route show"});
	foreach my $line (split/\n/, $ip_route)
	{
		$line = $anvil->Words->clean_spaces({ string => $line });
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
		my $ip_route     = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{nmcli}." dev show"});
		foreach my $line (split/\n/, $ip_route)
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
		
		$anvil->data->{sys}{network}{interface}{$route_interface}{default_gateway} = 1;
		$anvil->data->{sys}{network}{interface}{$route_interface}{gateway}         = $route_ip;
		$anvil->data->{sys}{network}{interface}{$route_interface}{dns}             = $dns_list;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::network::interface::${route_interface}::default_gateway" => $anvil->data->{sys}{network}{interface}{$route_interface}{default_gateway}, 
			"sys::network::interface::${route_interface}::gateway"         => $anvil->data->{sys}{network}{interface}{$route_interface}{gateway}, 
			"sys::network::interface::${route_interface}::dns"             => $anvil->data->{sys}{network}{interface}{$route_interface}{dns}, 
		}});
	}
	
	return(0);
}

=head2 get_uptime

This returns, in seconds, how long the host has been up and running for. 

This method takes no parameters.

=cut
sub get_uptime
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->get_uptime()" }});
	
	my $uptime = $anvil->Storage->read_file({
		force_read => 1,
		cache      => 0,
		file       => $anvil->data->{path}{proc}{uptime},
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uptime => $uptime }});
	
	# Clean it up. We'll have gotten two numbers, the uptime in seconds (to two decimal places) and the 
	# total idle time. We only care about the int number.
	$uptime =~ s/^(\d+)\..*$/$1/;
	$uptime =~ s/\n//gs;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uptime => $uptime }});
	
	return($uptime);
}

=head2 get_os_type

This returns the operating system type and the system architecture as two separate string variables.

 # Run on RHEL 7, on a 64-bit system
 my ($os_type, $os_arch) = $anvil->System->get_os_type();
 
 # '$os_type' holds 'rhel8'  ('rhel' or 'centos' + release version) 
 # '$os_arch' holds 'x86_64' (specifically, 'uname --hardware-platform')

If either can not be determined, C<< unknown >> will be returned.

This method takes no parameters.

=cut
sub get_os_type
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->get_os_type()" }});
	
	my $os_type = "unknown";
	my $os_arch = "unknown";
	
	### NOTE: Examples;
	# Red Hat Enterprise Linux release 8.0 Beta (Ootpa)
	# Red Hat Enterprise Linux Server release 7.5 (Maipo)
	# CentOS Linux release 7.5.1804 (Core) 

	# Read in the /etc/redhat-release file
	my $release = $anvil->Storage->read_file({file => $anvil->data->{path}{data}{'redhat-release'}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { release => $release }});
	if ($release =~ /Red Hat Enterprise Linux .* (\d+)\./)
	{
		# RHEL, with the major version number appended
		$os_type = "rhel".$1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { os_type => $os_type }});
	}
	elsif ($release =~ /CentOS .*? (\d+)\./)
	{
		# CentOS, with the major version number appended
		$os_type = "centos".$1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { os_type => $os_type }});
	}
	
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{uname}." --hardware-platform"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	if ($output)
	{
		$os_arch = $output;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { os_arch => $os_arch }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		os_type => $os_type, 
		os_arch => $os_arch,
	}});
	return($os_type, $os_arch);
}

=head2 hostname

Get or set the local hostname. The current (or new) "static" (traditional) host name and the "pretty" (descriptive) host names are returned.

 # Get the current host name.
 my ($traditional_hostname, $descriptive_hostname) = $anvil->System->hostname();

 # Set the traditional host name.
 my ($traditional_hostname, $descriptive_hostname) = $anvil->System->hostname({set => "an-striker01.alteeve.com");

 # Set the traditional and descriptive host names.
 my ($traditional_hostname, $descriptive_hostname) = $anvil->System->hostname({set => "an-striker01.alteeve.com", pretty => "Alteeve - Striker 01");

The current host name (or the new hostname if C<< set >> was used) is returned as a string.

Parameters;

=head3 set (optional)

If set, this will become the new host name.

=head3 pretty (optional)

If set, this will be set as the "pretty" host name.

=cut
sub hostname
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->hostname()" }});
	
	my $pretty = $parameter->{pretty} ? $parameter->{pretty} : "";
	my $set    = $parameter->{set}    ? $parameter->{set}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		pretty => $pretty, 
		set    => $set, 
	}});
	
	# Set
	if ($set)
	{
		# TODO: Sanity check the host name
		my $shell_call = $anvil->data->{path}{exe}{hostnamectl}." set-hostname $set";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my $output = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	}
	
	# Pretty
	if ($pretty)
	{
		# TODO: Escape this for bash properly
		#   $pretty     =~ s/"/\\"/g;
		my $shell_call = $anvil->data->{path}{exe}{hostnamectl}." set-hostname --pretty \"$pretty\"";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my $output = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	}
	
	# Get the static (traditional) hostname
	my $hostname = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{hostnamectl}." --static"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hostname => $hostname }});
	
	# Get the pretty (descriptive) hostname
	my $descriptive = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{hostnamectl}." --pretty"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { descriptive => $descriptive }});
	
	return($hostname, $descriptive);
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
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->_is_local()" }});
	
	my $host = $parameter->{host} ? $parameter->{host} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host => $host }});
	
	my $is_local = 0;
	if (($host eq $anvil->_hostname)       or 
	    ($host eq $anvil->_short_hostname) or 
	    ($host eq "localhost")          or 
	    ($host eq "127.0.0.1"))
	{
		# It's local
		$is_local = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
	}
	else
	{
		# Get the list of current IPs and see if they match.
		my $network = $anvil->Get->network_details;
		foreach my $interface (keys %{$network->{interface}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "network->interface::${interface}::ip" => $network->{interface}{$interface}{ip} }});
			if ($host eq $network->{interface}{$interface}{ip})
			{
				$is_local = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
				last;
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
	return($is_local);
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
		### TODO: stop other systems from using this database.
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
				update_value_only     => 1, 
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
				update_value_only     => 1, 
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->manage_firewall()" }});
	
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
	
	my $zone          = "";
	my $active_state  = "";
	my $firewall_data = $anvil->System->call({debug => $debug, shell_call => $shell_call});
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
	
	my $iptables = $anvil->System->call({shell_call => $shell_call});
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
		
		my $output = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
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
	my $open_services = [];
	my $xml           = XML::Simple->new();
	my $body          = "";
	eval { $body = $xml->XMLin($zone_file, KeyAttr => { language => 'name', key => 'name' }, ForceArray => [ 'service' ]) };
	if ($@)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem reading: [$zone_file]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => $error});
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
			
			my $output = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
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
			
			my $output = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
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
			
			my $output = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
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
			
			my $output = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
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

This parses 'ps aux' and stores the information about running programs in C<< pids::<pid_number>::<data> >>.

Optionally, if the C<< program_name >> parameter is set, an array of PIDs for that program will be returned.

Parameters;

=head3 ignore_me (optional)

If set to '1', the PID of this program is ignored.

=head3 program_name (optional)

This is an option string that is searched for in the 'command' portion of the 'ps aux' call. If this string matches, the PID is added to the array reference returned by this method.

=cut
sub pids
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->pids()" }});
	
	my $ignore_me    = defined $parameter->{ignore_me}    ? $parameter->{ignore_me}    : "";
	my $program_name = defined $parameter->{program_name} ? $parameter->{program_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ignore_me    => $ignore_me, 
		program_name => $program_name,
	}});
	
	# If we stored this data before, delete it as it is now stale.
	if (exists $anvil->data->{pids})
	{
		delete $anvil->data->{pids};
	}
	my $my_pid     = $$;
	my $pids       = [];
	my $shell_call = $anvil->data->{path}{exe}{ps}." aux";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my $output = $anvil->System->call({shell_call => $shell_call});
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
			$anvil->data->{pids}{$pid}{user}                = $user;
			$anvil->data->{pids}{$pid}{cpu}                 = $cpu;
			$anvil->data->{pids}{$pid}{memory}              = $memory;
			$anvil->data->{pids}{$pid}{virtual_memory_size} = $virtual_memory_size;
			$anvil->data->{pids}{$pid}{resident_set_size}   = $resident_set_size;
			$anvil->data->{pids}{$pid}{control_terminal}    = $control_terminal;
			$anvil->data->{pids}{$pid}{state_codes}         = $state_codes;
			$anvil->data->{pids}{$pid}{start_time}          = $start_time;
			$anvil->data->{pids}{$pid}{'time'}              = $time;
			$anvil->data->{pids}{$pid}{command}             = $command;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"pids::${pid}::cpu"                 => $anvil->data->{pids}{$pid}{cpu}, 
				"pids::${pid}::memory"              => $anvil->data->{pids}{$pid}{memory}, 
				"pids::${pid}::virtual_memory_size" => $anvil->data->{pids}{$pid}{virtual_memory_size}, 
				"pids::${pid}::resident_set_size"   => $anvil->data->{pids}{$pid}{resident_set_size}, 
				"pids::${pid}::control_terminal"    => $anvil->data->{pids}{$pid}{control_terminal}, 
				"pids::${pid}::state_codes"         => $anvil->data->{pids}{$pid}{state_codes}, 
				"pids::${pid}::start_time"          => $anvil->data->{pids}{$pid}{start_time}, 
				"pids::${pid}::time"                => $anvil->data->{pids}{$pid}{'time'}, 
				"pids::${pid}::command"             => $anvil->data->{pids}{$pid}{command}, 
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


=head2 ping

This method will attempt to ping a target, by hostname or IP, and returns C<< 1 >> if successful, and C<< 0 >> if not.

Example;

 # Test access to the internet. Allow for three attempts to account for network jitter.
 my $pinged = $anvil->System->ping({
 	ping  => "google.ca", 
 	count => 3,
 });
 
 # Test 9000-byte jumbo-frame access to a target over the BCN.
 my $jumbo_to_peer = $anvil->System->ping({
 	ping     => "an-a01n02.bcn", 
 	count    => 1, 
 	payload  => 9000, 
 	fragment => 0,
 });
 
 # Check to see if an Anvil! node has internet access
 my $pinged = $anvil->System->ping({
 	target   => "an-a01n01.alteeve.com",
 	port     => 22,
	password => "super secret", 
 	ping     => "google.ca", 
 	count    => 3,
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->ping()" }});
	
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
		password    => $anvil->Log->secure ? $password : $anvil->Words->string({key => "log_0186"}),
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
	
	# Build the call. Note that we use 'timeout' because if there is no connection and the hostname is 
	# used to ping and DNS is not available, it could take upwards of 30 seconds time timeout otherwise.
	my $shell_call = "";
	if ($timeout)
	{
		$shell_call = $anvil->data->{path}{exe}{timeout}." $timeout ";
	}
	$shell_call .= $anvil->data->{path}{exe}{'ping'}." -W 1 -n $ping -c 1";
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count, try => $try }});
		last if $pinged;
		
		my $output = "";
		my $error  = "";
		
		# If the 'target' is set, we'll call over SSH unless 'target' is 'local' or our hostname.
		if (($target) && ($target ne "local") && ($target ne $anvil->_hostname) && ($target ne $anvil->_short_hostname))
		{
			### Remote calls
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
			($output, $error) = $anvil->Remote->call({
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
		else
		{
			### Local calls
			$output = $anvil->System->call({shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
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
	
	my $return = undef;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my $shell_call = $anvil->data->{path}{exe}{systemctl}." reload ".$daemon."; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my $output = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
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
				debug                 => 2,
				variable_name         => "reboot::needed", 
				variable_value        => "1", 
				variable_default      => "0", 
				variable_description  => "striker_0089", 
				variable_section      => "system", 
				variable_source_uuid  => $anvil->Get->host_uuid, 
				variable_source_table => "hosts", 
				update_value_only     => 1, 
			});
		}
		elsif ($set eq "0")
		{
			# Clear
			$anvil->Database->insert_or_update_variables({
				debug                 => 2,
				variable_name         => "reboot::needed", 
				variable_value        => "0", 
				variable_default      => "0", 
				variable_description  => "striker_0089", 
				variable_section      => "system", 
				variable_source_uuid  => $anvil->Get->host_uuid, 
				variable_source_table => "hosts", 
				update_value_only     => 1, 
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
	
	my $return = undef;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my $shell_call = $anvil->data->{path}{exe}{systemctl}." restart ".$daemon."; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my $output = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
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
	
	my $return = undef;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." start ".$daemon."; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?", debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
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
	
	my $return = undef;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." stop ".$daemon."; ".$anvil->data->{path}{exe}{'echo'}." return_code:\$?"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /return_code:(\d+)/)
		{
			$return = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
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
		$anvil->data->{sys}{terminal}{stty} = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{stty}." --save"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 'sys::terminal::stty' => $anvil->data->{sys}{terminal}{stty} }});
		$anvil->System->call({shell_call => $anvil->data->{path}{exe}{stty}." -echo"});
	}
	elsif (($set eq "on") && ($anvil->data->{sys}{terminal}{stty}))
	{
		$anvil->System->call({shell_call => $anvil->data->{path}{exe}{stty}." ".$anvil->data->{sys}{terminal}{stty}});
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
	
	my $xml  = XML::Simple->new();
	my $body = "";
	eval { $body = $xml->XMLin($full_path, KeyAttr => { language => 'name', key => 'name' }, ForceArray => [ 'port' ]) };
	if ($@)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem reading: [$full_path]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => $error});
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

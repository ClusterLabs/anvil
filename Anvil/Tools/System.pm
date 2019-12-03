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

our $VERSION  = "3.0.0";
my $THIS_FILE = "System.pm";

### Methods;
# activate_lv
# call
# change_shell_user_password
# check_daemon
# check_if_configured
# check_memory
# check_storage
# get_bridges
# get_free_memory
# get_host_type
# enable_daemon
# find_matching_ip
# get_uptime
# get_os_type
# host_name
# maintenance_mode
# manage_firewall
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
 my ($host_name, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{hostnamectl}." --static"});

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->call()" }});
	
	my $path      = defined $parameter->{path} ? $parameter->{path} : "";
	my $activated = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
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
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{lvchange}." --activate y ".$path});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	
	# A non-zero return code indicates failure, but we'll check directly.
	$anvil->System->check_storage({debug => $debug, scan => 2});
	
	# Check if it worked.
	$activated = $anvil->data->{lvm}{'local'}{lv}{$path}{active};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { activated => $activated }});
	
	return($activated);
}

=head2 call

This method makes a system call and returns the output (with the last new-line removed) and the return code. If there is a problem, 'C<< #!error!# >>' is returned and the error will be logged.

 my ($output, $return_code) = $anvil->System->call({shell_call => "host_name"});

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
					}
					else
					{
						$output .= $line."\n";
					}
				}
				close $file_handle;
				chomp($output);
				$output =~ s/\n$//s;
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
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
	(my $salt, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{openssl}." rand 1000 | ".$anvil->data->{path}{exe}{strings}." | ".$anvil->data->{path}{exe}{'grep'}." -io [0-9A-Za-z\.\/] | ".$anvil->data->{path}{exe}{head}." -n 16 | ".$anvil->data->{path}{exe}{'tr'}." -d '\n'" });
	my $new_hash             = crypt($new_password,"\$6\$".$salt."\$");
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
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
		($output, $return_code, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
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
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon});
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
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{'anvil-check-memory'}." --program $program_name"});
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
		
		$anvil->data->{lvm}{'local'}{pv}{$this_pv}{used_by_vg} = $used_by_vg;
		$anvil->data->{lvm}{'local'}{pv}{$this_pv}{attributes} = $attributes;
		$anvil->data->{lvm}{'local'}{pv}{$this_pv}{total_size} = $total_size;
		$anvil->data->{lvm}{'local'}{pv}{$this_pv}{free_size}  = $free_size;
		$anvil->data->{lvm}{'local'}{pv}{$this_pv}{used_size}  = $used_size;
		$anvil->data->{lvm}{'local'}{pv}{$this_pv}{uuid}       = $uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::local::pv::${this_pv}::used_by_vg" => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{used_by_vg},
			"lvm::local::pv::${this_pv}::attributes" => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{attributes},
			"lvm::local::pv::${this_pv}::total_size" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{total_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{total_size}}).")",
			"lvm::local::pv::${this_pv}::free_size"  => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{free_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{free_size}}).")",
			"lvm::local::pv::${this_pv}::used_size"  => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{used_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{used_size}}).")",
			"lvm::local::pv::${this_pv}::uuid"       => $anvil->data->{lvm}{'local'}{pv}{$this_pv}{uuid},
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
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{pe_size}    = $pe_size;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{total_pe}   = $total_pe;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{uuid}       = $uuid;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{size}       = $vg_size;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{used_pe}    = $used_pe;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{used_space} = $used_space;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{free_pe}    = $free_pe;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{free_space} = $vg_free;
		$anvil->data->{lvm}{'local'}{vg}{$this_vg}{pv_name}    = $pv_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::local::vg::${this_vg}::pe_size"    => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{pe_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{pe_size}}).")",
			"lvm::local::vg::${this_vg}::total_pe"   => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{total_pe},
			"lvm::local::vg::${this_vg}::uuid"       => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{uuid},
			"lvm::local::vg::${this_vg}::size"       => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{size}}).")",
			"lvm::local::vg::${this_vg}::used_pe"    => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{used_pe},
			"lvm::local::vg::${this_vg}::used_space" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{used_space}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{used_space}}).")",
			"lvm::local::vg::${this_vg}::free_pe"    => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{free_pe},
			"lvm::local::vg::${this_vg}::free_space" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{free_space}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{free_space}}).")",
			"lvm::local::vg::${this_vg}::pv_name"    => $anvil->data->{lvm}{'local'}{vg}{$this_vg}{pv_name},
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

		$anvil->data->{lvm}{'local'}{lv}{$path}{name}       = $lv_name;
		$anvil->data->{lvm}{'local'}{lv}{$path}{on_vg}      = $on_vg;
		$anvil->data->{lvm}{'local'}{lv}{$path}{active}     = ($attributes =~ /.{4}(.{1})/)[0] eq "a" ? 1 : 0;
		$anvil->data->{lvm}{'local'}{lv}{$path}{attributes} = $attributes;
		$anvil->data->{lvm}{'local'}{lv}{$path}{total_size} = $total_size;
		$anvil->data->{lvm}{'local'}{lv}{$path}{uuid}       = $uuid;
		$anvil->data->{lvm}{'local'}{lv}{$path}{on_devices} = $devices;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"lvm::local::lv::${path}::name"       => $anvil->data->{lvm}{'local'}{lv}{$path}{name},
			"lvm::local::lv::${path}::on_vg"      => $anvil->data->{lvm}{'local'}{lv}{$path}{on_vg},
			"lvm::local::lv::${path}::active"     => $anvil->data->{lvm}{'local'}{lv}{$path}{active},
			"lvm::local::lv::${path}::attributes" => $anvil->data->{lvm}{'local'}{lv}{$path}{attributes},
			"lvm::local::lv::${path}::total_size" => $anvil->Convert->add_commas({number => $anvil->data->{lvm}{'local'}{lv}{$path}{total_size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{lvm}{'local'}{lv}{$path}{total_size}}).")",
			"lvm::local::lv::${path}::uuid"       => $anvil->data->{lvm}{'local'}{lv}{$path}{uuid},
			"lvm::local::lv::${path}::on_devices" => $anvil->data->{lvm}{'local'}{lv}{$path}{on_devices},
		}});
	}
	
	return(0);
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
		host      => 'local',
		host_uuid => $anvil->data->{sys}{host_uuid},
	});
	
	$anvil->data->{json}{all_systems}{hosts} = [];
	$anvil->Database->get_hosts_info({debug => 3});
	foreach my $host_uuid (keys %{$anvil->data->{machine}{host_uuid}})
	{
		my $host_name       = $anvil->data->{machine}{host_uuid}{$host_uuid}{hosts}{host_name};
		my $short_host_name = ($host_name =~ /^(.*?)\./)[0];
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
		if ($host_name ne $anvil->_host_name)
		{
			# Don't need to call 'local_ips', it was called by load_interfaces above.
			my ($match) = $anvil->Network->find_matches({
				debug  => $debug,
				first  => 'local',
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

=head2 get_bridges

This finds a list of bridges on the host. Bridges that are found are stored is '

=cut
sub get_bridges
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->get_bridges()" }});
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{bridge}." -json -details link show"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	# Delete any previously known data
	if (exists $anvil->data->{'local'}{network}{bridges})
	{
		delete $anvil->data->{'local'}{network}{bridges};
	};
	
	my $json        = JSON->new->allow_nonref;
	my $bridge_data = $json->decode($output);
	#print Dumper $bridge_data;
	foreach my $hash_ref (@{$bridge_data})
	{
		# If the ifname and master are the same, it's a bridge.
		my $type           = "interface";
		my $interface = $hash_ref->{ifname};
		my $master_bridge  = $hash_ref->{master};
		if ($interface eq $master_bridge)
		{
			$type = "bridge";
			$anvil->data->{'local'}{network}{bridges}{bridge}{$interface}{found} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"local::network::bridges::bridge::${interface}::found" => $anvil->data->{'local'}{network}{bridges}{bridge}{$interface}{found}, 
			}});
		}
		else
		{
			# Store this interface under the bridge.
			$anvil->data->{'local'}{network}{bridges}{bridge}{$master_bridge}{connected_interface}{$interface} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"local::network::bridges::bridge::${master_bridge}::connected_interface::${interface}" => $anvil->data->{'local'}{network}{bridges}{bridge}{$master_bridge}{connected_interface}{$interface}, 
			}});
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			interface     => $interface,
			master_bridge => $master_bridge, 
			type          => $type, 
		}});
		foreach my $key (sort {$a cmp $b} keys %{$hash_ref})
		{
			if (ref($hash_ref->{$key}) eq "ARRAY")
			{
				$anvil->data->{'local'}{network}{bridges}{$type}{$interface}{$key} = [];
				foreach my $value (sort {$a cmp $b} @{$hash_ref->{$key}})
				{
					push @{$anvil->data->{'local'}{network}{bridges}{$type}{$interface}{$key}}, $value;
				}
				for (my $i = 0; $i < @{$anvil->data->{'local'}{network}{bridges}{$type}{$interface}{$key}}; $i++)
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"local::network::bridges::${type}::${interface}::${key}->[$i]" => $anvil->data->{'local'}{network}{bridges}{$type}{$interface}{$key}->[$i], 
					}});
				}
			}
			else
			{
				$anvil->data->{'local'}{network}{bridges}{$type}{$interface}{$key} = $hash_ref->{$key};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"local::network::bridges::${type}::${interface}::${key}" => $anvil->data->{'local'}{network}{bridges}{$type}{$interface}{$key}, 
				}});
			}
		}
	}
	
	# Summary of found bridges.
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{'local'}{network}{bridges}{bridge}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"local::network::bridges::bridge::${interface}::found" => $anvil->data->{'local'}{network}{bridges}{bridge}{$interface}{found}, 
		}});
	}
	
	return(0);
}

=head2 get_free_memory

This returns, in bytes, host much free memory is available on the local system.

=cut
### TODO: Make this work on remote systems.
sub get_free_memory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->get_free_memory()" }});
	
	my $available               = 0;
	my ($free_output, $free_rc) = $anvil->System->call({shell_call =>  $anvil->data->{path}{exe}{free}." --bytes"});
	foreach my $line (split/\n/, $free_output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { line => $line }});
		if ($line =~ /Mem:\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/)
		{
			my $total     = $1;
			my $used      = $2;
			my $free      = $3;
			my $shared    = $4;
			my $cache     = $5;
			   $available = $6;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				total     => $total." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $total})."})", 
				used      => $used." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $used})."})",
				free      => $free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $free})."})", 
				shared    => $shared." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $shared})."})", 
				cache     => $cache." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $cache})."})", 
				available => $available." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $available})."})", 
			}});
		}
	}
	
	return($available);
}

=head2 get_host_type

This method tries to determine the host type and returns a value suitable for use is the C<< hosts >> table.

 my $type = $anvil->System->get_host_type();

First, it looks to see if C<< sys::host_type >> is set and, if so, uses that string as it is. 

If that isn't set, it then looks to see if the file C<< /etc/anvil/type.X >> exists, where C<< X >> is C<< node >>, C<< dashboard >> or C<< dr >>. If found, the appropriate type is returned.

If that file doesn't exist, then it looks at the short host name. The following rules are used, in order;

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
	my $host_name = $anvil->_short_host_name;
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
	else
	{
		# Can I determine it by seeing a file?
		if (-e $anvil->data->{path}{configs}{'type.node'})
		{
			$host_type = "node";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		elsif (-e $anvil->data->{path}{configs}{'type.dashboard'})
		{
			$host_type = "dashboard";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		elsif (-e $anvil->data->{path}{configs}{'type.dr'})
		{
			$host_type = "dr";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		elsif (($host_name =~ /n\d+$/) or ($host_name =~ /node\d+$/) or ($host_name =~ /new-node+$/))
		{
			$host_type = "node";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		elsif (($host_name =~ /striker\d+$/) or ($host_name =~ /dashboard\d+$/))
		{
			$host_type = "dashboard";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		elsif (($host_name =~ /dr\d+$/) or ($host_name =~ /new-dr$/))
		{
			$host_type = "dr";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
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
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." enable ".$daemon." 2>&1"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
	return($return);
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
	if (not $anvil->Validate->is_ipv4({ip => $host}))
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
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{'local'}{interface}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
		next if not $anvil->data->{network}{'local'}{interface}{$interface}{ip};
		my $this_ip          = $anvil->data->{network}{'local'}{interface}{$interface}{ip};
		my $this_subnet_mask = $anvil->data->{network}{'local'}{interface}{$interface}{subnet_mask};
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
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{uname}." --hardware-platform"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
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
			($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
			($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
		($host_name, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
		($descriptive, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
	
	my ($iptables, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
		
		my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
			
			my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
			
			my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
			
			my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
			
			my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
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
	
	my $return = 9999;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." reload ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
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
	
	my $return = 9999;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." restart ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	
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
	
	my $return = 9999;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{systemctl}." start ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	
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
	
	my $return = 9999;
	my $daemon = defined $parameter->{daemon} ? $parameter->{daemon} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { daemon => $daemon }});
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." stop ".$daemon});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	
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
		($anvil->data->{sys}{terminal}{stty}, my $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{stty}." --save"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 'sys::terminal::stty' => $anvil->data->{sys}{terminal}{stty}, return_code => $return_code }});
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

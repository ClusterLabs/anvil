package AN::Tools::System;
# 
# This module contains methods used to handle common system tasks.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "System.pm";

### Methods;
# call
# check_daemon
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

=head2 start_daemon

This method starts a daemon. The return code from the start request will be returned.

If the return code for the start command wasn't read, C<< undef >> is returned.

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

If the return code for the stop command wasn't read, C<< undef >> is returned.

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

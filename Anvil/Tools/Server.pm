package Anvil::Tools::Server;
# 
# This module contains methods used to manager servers
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Server.pm";

### Methods;
# status

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Server

Provides all methods related to (virtual) servers.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Server->X'. 
 # 
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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}

#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 get_status

This reads in a server's XML definition file from disk, if available, and from memory, if the server is running. The XML is analyzed and data is stored in the following locations;

 - 

Any pre-existing data on the server is flushed before the new information is processed.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 server (required)

This is the name of the server we're gathering data on.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
# NOTE: the version is set in anvil.spec by sed'ing the release and arch onto anvil.version in anvil-core's %post
sub get_status
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $server      = defined $parameter->{server}      ? $parameter->{server}      : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "local";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->secure ? $password : $anvil->Words->string({key => "log_0186"}),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	if (not $server)
	{
		return(1);
	}
	if (exists $anvil->data->{server}{$server})
	{
		delete $anvil->data->{server}{$server};
	}
	
	# Is this a local call or a remote call?
	my $shell_call  = $anvil->data->{path}{exe}{virsh}." dumpxml ".$server;
	if (($target) && ($target ne "local") && ($target ne $anvil->_hostname) && ($target ne $anvil->_short_hostname))
	{
		# Remote call.
		$host = $target;
		
		($anvil->data->{server}{$server}{running}{xml}, my $error, $anvil->data->{server}{$server}{running}{return_code}) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error                                     => $error,
			"server::${server}::running::xml"         => $anvil->data->{server}{$server}{running}{xml},
			"server::${server}::running::return_code" => $anvil->data->{server}{$server}{running}{return_code},
		}});
	}
	else
	{
		# Local.
		($anvil->data->{server}{$server}{running}{xml}, $anvil->data->{server}{$server}{running}{return_code}) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${server}::running::xml"         => $anvil->data->{server}{$server}{running}{xml},
			"server::${server}::running::return_code" => $anvil->data->{server}{$server}{running}{return_code},
		}});
	}
	
	# If the return code was non-zero, we can't parse the XML.
	if ($anvil->data->{server}{$server}{running}{return_code})
	{
		$anvil->data->{server}{$server}{running}{xml} = "";
	}
	
	# Now get the on-disk XML.
	($anvil->data->{server}{$server}{disk}{xml}) = $anvil->Storage->read_file({
		debug       => $debug, 
		password    => $password,
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
		force_read  => 1,
		file        => $anvil->data->{path}{directories}{shared}{definitions}."/".$server.".xml",
	})
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${server}::disk::xml" => $anvil->data->{server}{$server}{disk}{xml},
	}});
	
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

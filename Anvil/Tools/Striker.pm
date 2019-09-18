package Anvil::Tools::Striker;
# 
# This module contains methods used to handle common Striker (webUI) tasks.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Striker.pm";

### Methods;
# get_local_repo
# get_peer_data

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Striker

Provides all methods related to the Striker WebUI.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Striker->X'. 
 # 
 # Example using 'system_call()';
 

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

=head2 get_local_repo

This builds the body of an RPM repo for the local machine. If, for some reason, this machine can't be used as a repo, an empty string will be returned.

The method takes no paramters.

=cut
sub get_local_repo
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_peer_data()" }});
	
	# What is the repo directory?
	my $document_root = "";
	my $httpd_conf    = $anvil->Storage->read_file({file => $anvil->data->{path}{data}{httpd_conf} });
	foreach my $line (split/\n/, $httpd_conf)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^DocumentRoot\s+"(\/.*?)"/)
		{
			$document_root = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { document_root => $document_root }});
			last;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { document_root => $document_root }});
	if (not $document_root)
	{
		# Problem with apache.
		return("");
	}
	
	$anvil->Storage->scan_directory({
		debug      => $debug,
		directory  => $document_root,
		recursive  => 1, 
		no_files   => 1,
		search_for => "repodata",
	});
	my $directory = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "scan::searched" => $anvil->data->{scan}{searched} }});
	if ($anvil->data->{scan}{searched})
	{
		$directory =  $anvil->data->{scan}{searched};
		$directory =~ s/^$document_root//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { directory => $directory }});
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { directory => $directory }});
	if (not $directory)
	{
		# No repo found.
		return("");
	}
	
	# What are my IPs?
	$anvil->System->get_ips();
	my $base_url = "";
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{sys}{network}{interface}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
		if ($anvil->data->{sys}{network}{interface}{$interface}{ip})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::network::interface::${interface}::ip" => $anvil->data->{sys}{network}{interface}{$interface}{ip} }});
			if (not $base_url)
			{
				$base_url = "baseurl=http://".$anvil->data->{sys}{network}{interface}{$interface}{ip}.$directory;
			}
			else
			{
				$base_url .= "\n        http://".$anvil->data->{sys}{network}{interface}{$interface}{ip}.$directory;
			}
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { base_url => $base_url }});
	
	# Create the local repo file body
	my $repo = "[".$anvil->_short_hostname."-repo]
name=Repo on ".$anvil->_hostname."
".$base_url."
enabled=1
gpgcheck=0
timeout=5
skip_if_unavailable=1";
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { repo => $repo }});
	return($repo);
}

=head2 get_peer_data

This calls the C<< call_striker-get-peer-data >> program to try to connect to the target (as C<< root >>). If successful, it will return the target's host UUID (either by reading C<< /etc/anvil/host.uuid >> if it exists, or using C<< dmidecode >> if not). 

This method will return a string variable with C<< 1 >> if the peer was reached, or C<< 0 >> if it was not. It will also return a hash reference containing the collected data.

 my ($connected, $data) = $anvil->Striker->get_peer_data({target => 10.255.1.218, password => "Initial1"});
 if ($connected)
 {
	print "Hostname: [".$data->{host_name}."], host UUID: [".$data->{host_uuid}."]\n";
 }

Parameters;

=head3 password (required)

This is the target machine's C<< root >> password.

=head3 port (optional, default 22)

This is the TCP port to use when connecting to the target

=head3 target (required, IPv4 address)

This is the current IP address of the target machine.

=cut
sub get_peer_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_peer_data()" }});
	
	my $target   = defined $parameter->{target}   ? $parameter->{target}   : "";
	my $password = defined $parameter->{password} ? $parameter->{password} : "";
	my $port     = defined $parameter->{port}     ? $parameter->{port}     : 22;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target   => $target,
		password => $anvil->Log->is_secure($password),
		port     => $port, 
	}});
	
	# Store the password.
	my $connected  = 0;
	my $data       = {
		host_uuid     => "",
		host_name     => "",
		host_os       => "",
		os_registered => "", 
	};
	
	if (not $target)
	{
		# No target...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Striker->get_peer_data()", parameter => "target" }});
		return($connected, $data);
	}
	
	my $state_uuid = $anvil->Database->insert_or_update_states({
		debug      => $debug,
		file       => $THIS_FILE, 
		line       => __LINE__, 
		state_name => "peer::".$target."::password",
		state_note => $password, 
		uuid       => $anvil->data->{sys}{host_uuid}, # Only write to our DB, no reason to store elsewhere
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { state_uuid => $state_uuid }});
	my ($output, $return_code) = $anvil->System->call({
		debug      => $debug,
		shell_call => $anvil->data->{path}{exe}{'call_striker-get-peer-data'}." --target root\@".$target.":".$port." --state-uuid ".$state_uuid,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output, 
		return_code => $return_code, 
	}});
	
	# Pull out the details
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /connected=(.*)$/)
		{
			# We collect this, but apparently not for any real reason...
			$connected = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connected => $connected }});
		}
		if ($line =~ /host_name=(.*)$/)
		{
			# We collect this, but apparently not for any real reason...
			$data->{host_name} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'data->{host_name}' => $data->{host_name} }});
		}
		if ($line =~ /host_uuid=(.*)$/)
		{
			$data->{host_uuid} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'data->{host_uuid}' => $data->{host_uuid} }});
		}
		if ($line =~ /host_os=(.*)$/)
		{
			$data->{host_os} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'data->{host_os}' => $data->{host_os} }});
		}
		if ($line =~ /os_registered=(.*)$/)
		{
			$data->{os_registered} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'data->{os_registered}' => $data->{os_registered} }});
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		connected               => $connected, 
		'data->{host_name}'     => $data->{host_name},
		'data->{host_uuid}'     => $data->{host_uuid},
		'data->{host_os}'       => $data->{host_os},
		'data->{os_registered}' => $data->{os_registered}, 
	}});
	
	# Make sure the database entry is gone (striker-get-peer-data should have removed it, but lets be safe).
	my $query = "DELETE FROM states WHERE state_name = ".$anvil->Database->quote("peer::".$target."::password").";";
	$anvil->Database->write({uuid => $anvil->data->{sys}{host_uuid}, debug => 3, query => $query, source => $THIS_FILE, line => __LINE__});
	
	if (not $anvil->Validate->is_uuid({uuid => $data->{host_uuid}}))
	{
		$data->{host_uuid} = "";
	}
	
	return($connected, $data);
}



1;

package Anvil::Tools::Striker;
# 
# This module contains methods used to handle common Striker (webUI) tasks.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use JSON;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Striker.pm";

### Methods;
# get_fence_data
# get_local_repo
# get_peer_data
# parse_all_status_json

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

=head2 get_fence_data

This parses the unified metadata file from the avaialable fence_devices on this host. If the unified file (location stored in C<< path::data::fences_unified_metadata >>, default is C<< /tmp/fences_unified_metadata.xml >> is not found or fails to parse, C<< 1 >> is returned. If the file is successfully parsed. C<< 0 >> is returned.

The parsed data is stored under C<< fences::<agent_name>::... >>.

=cut
sub get_fence_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_fence_data()" }});
	
	my $parsed_xml = "";
	my $xml_body   = $anvil->Storage->read_file({file => $anvil->data->{path}{data}{fences_unified_metadata}});
	
	# Globally replace \fI (opening underline) with '[' and \fP (closing underline) with ']'.
	$xml_body =~ s/\\fI/[/gs;
	$xml_body =~ s/\\fP/]/gs;
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { xml_body => $xml_body }});
	if ($xml_body =~ /<\?xml version="1.0" \?>/gs)
	{
		my $xml = XML::Simple->new();
		eval { $parsed_xml = $xml->XMLin($xml_body, KeyAttr => { key => 'name' }, ForceArray => []) };
		if ($@)
		{
			chomp $@;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0111", variables => { 
				xml_body   => $xml_body, 
				eval_error => $@,
			}});
			return(1);
		}
	}
	else
	{
		$anvil->nice_exit({exit_code => 1});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0112"});
		return(1);
	}
	
	foreach my $agent_ref (@{$parsed_xml->{agent}})
	{
		my $fence_agent                                      = $agent_ref->{name};
		   $anvil->data->{fences}{$fence_agent}{description} = $agent_ref->{'resource-agent'}->{longdesc};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"fences::${fence_agent}::description" => $anvil->data->{fences}{$fence_agent}{description},
		}});
		if (exists $agent_ref->{'resource-agent'}->{'symlink'})
		{
			if (ref($agent_ref->{'resource-agent'}->{'symlink'}) eq "ARRAY")
			{
				foreach my $hash_ref (@{$agent_ref->{'resource-agent'}->{'symlink'}})
				{
					my $name = $hash_ref->{name};
					$anvil->data->{fences}{$fence_agent}{'symlink'}{$name} = $hash_ref->{shortdesc};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"fences::${fence_agent}::symlink::${name}" => $anvil->data->{fences}{$fence_agent}{'symlink'}{$name},
					}});
				}
			}
			else
			{
				my $name = $agent_ref->{'resource-agent'}->{'symlink'}->{name};
				$anvil->data->{fences}{$fence_agent}{'symlink'}{$name} = $agent_ref->{'resource-agent'}->{'symlink'}->{shortdesc};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fences::${fence_agent}::symlink::${name}" => $anvil->data->{fences}{$fence_agent}{'symlink'}{$name},
				}});
			}
		}
		
		foreach my $hash_ref (@{$agent_ref->{'resource-agent'}->{parameters}{parameter}})
		{
			# We ignore some parameters that are not useful parameters in our case.
			my $name = $hash_ref->{name};
			next if $name eq "help";
			next if $name eq "version";
			next if $name eq "delay";
			next if $name eq "separator";
			next if $name =~ /snmp(.*?)_path/;
			
			my $unique     = exists $hash_ref->{unique}     ? $hash_ref->{unique}     : 0;
			my $required   = exists $hash_ref->{required}   ? $hash_ref->{required}   : 0;
			my $deprecated = exists $hash_ref->{deprecated} ? $hash_ref->{deprecated} : 0;
			my $obsoletes  = exists $hash_ref->{obsoletes}  ? $hash_ref->{obsoletes}  : 0;
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{unique}       =  $unique;
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{required}     =  $required;
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{deprecated}   =  $deprecated;
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{obsoletes}    =  $obsoletes;
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{description}  =  $hash_ref->{shortdesc}->{content};
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{description}  =~ s/\n/ /g;
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{switches}     =  defined $hash_ref->{getopt}->{mixed} ? $hash_ref->{getopt}->{mixed} : "";
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} =  $hash_ref->{content}->{type};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"fences::${fence_agent}::parameters::${name}::unique"       => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{unique},
				"fences::${fence_agent}::parameters::${name}::required"     => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{required},
				"fences::${fence_agent}::parameters::${name}::deprecated"   => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{deprecated},
				"fences::${fence_agent}::parameters::${name}::obsoletes"    => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{obsoletes},
				"fences::${fence_agent}::parameters::${name}::description"  => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{description},
				"fences::${fence_agent}::parameters::${name}::switches"     => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{switches},
				"fences::${fence_agent}::parameters::${name}::content_type" => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type},
			}});
			
			# 'action' is a string, but it has a set list of allowed values, so we manually switch it to a 'select' for the web interface
			if ($name eq "action")
			{
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'}    = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} = "select";
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options}      = [];
				
				# Read the action 
				print "Agent: [".$fence_agent."]; actions (default: [".$anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'}."]);\n";
				foreach my $array_ref (sort {$a cmp $b} @{$agent_ref->{'resource-agent'}->{actions}->{action}})
				{
					# There are several options that don't make sense for us.
					next if $array_ref->{name} eq "list";
					next if $array_ref->{name} eq "monitor";
					next if $array_ref->{name} eq "manpage";
					next if $array_ref->{name} eq "status";
					next if $array_ref->{name} eq "validate-all";
					next if $array_ref->{name} eq "list-status";
					next if $array_ref->{name} eq "metadata";
					next if $array_ref->{name} eq "on";
					
					push @{$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options}}, $array_ref->{name};
				}
				
				foreach my $option (sort {$a cmp $b} @{$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { option => $option }});
				}
			}
			elsif ($anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} eq "string")
			{
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'} = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fences::${fence_agent}::parameters::${name}::default" => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'},
				}});
			}
			elsif ($anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} eq "select")
			{
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options} = [];
				foreach my $option_ref (@{$hash_ref->{content}->{option}})
				{
					push @{$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options}}, $option_ref->{value};
				}
				
				foreach my $option (sort {$a cmp $b} @{$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { option => $option }});
				}
			}
			elsif ($anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} eq "boolean")
			{
				# Nothing to collect here.
			}
			elsif ($anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} eq "second")
			{
				# Nothing to collect here.
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'} = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fences::${fence_agent}::parameters::${name}::default" => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'},
				}});
			}
			elsif ($anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type} eq "integer")
			{
				# Nothing to collect here.
				$anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'} = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fences::${fence_agent}::parameters::${name}::default" => $anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'},
				}});
			}
			
			# If this obsoletes another parameter, mark it as such.
			$anvil->data->{fences}{$fence_agent}{parameters}{$name}{replacement} = "" if not exists $anvil->data->{fences}{$fence_agent}{parameters}{$name}{replacement};
			if ($obsoletes)
			{
				$anvil->data->{fences}{$fence_agent}{parameters}{$obsoletes}{replacement} = $name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fences::${fence_agent}::parameters::${obsoletes}::replacement" => $anvil->data->{fences}{$fence_agent}{parameters}{$obsoletes}{replacement},
				}});
			}
		}
		
		$anvil->data->{fences}{$fence_agent}{actions} = [];
		foreach my $hash_ref (@{$agent_ref->{'resource-agent'}->{actions}{action}})
		{
			push @{$anvil->data->{fences}{$fence_agent}{actions}}, $hash_ref->{name};
		}
		foreach my $action (sort {$a cmp $b} @{$anvil->data->{fences}{$fence_agent}{actions}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { action => $action }});
		}
	}

	
	return(0);
}

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
	$anvil->Network->get_ips();
	my $base_url = "";
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{'local'}{interface}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
		if ($anvil->data->{network}{'local'}{interface}{$interface}{ip})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "network::local::interface::${interface}::ip" => $anvil->data->{network}{'local'}{interface}{$interface}{ip} }});
			if (not $base_url)
			{
				$base_url = "baseurl=http://".$anvil->data->{network}{'local'}{interface}{$interface}{ip}.$directory;
			}
			else
			{
				$base_url .= "\n        http://".$anvil->data->{network}{'local'}{interface}{$interface}{ip}.$directory;
			}
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { base_url => $base_url }});
	
	### NOTE: The 'module_hotfixes=1' is needed until we can figure out how to add libssh2 to 
	###       'modules.yaml' (from anvil-striker-extra, in turn from the RHEL 8.x repodata). See: 
	###       - https://docs.fedoraproject.org/en-US/modularity/making-modules/defining-modules/
	###       - https://docs.fedoraproject.org/en-US/modularity/hosting-modules/
	# Create the local repo file body
	my $repo = "[".$anvil->_short_host_name."-repo]
name=Repo on ".$anvil->_host_name."
".$base_url."
enabled=1
gpgcheck=0
timeout=5
skip_if_unavailable=1
module_hotfixes=1";
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { repo => $repo }});
	return($repo);
}

=head2 get_peer_data

This calls the C<< call_striker-get-peer-data >> program to try to connect to the target (as C<< root >>). This method returns a string variable and a hash reference. The string variable will be C<< 1 >> if we connected successfully, C<< 0 >> if not. The hash reference will contain parsed details about the peer, assuming it connected. If the connection failed, the hash reference will exist but the values will be empty.

Keys in the hash;

* C<< host_uuid >> - The host's UUID.
* C<< host_name >> - The host's current (static) host name.
* C<< host_os >> - This is the host's operating system and version. The OS is returned as C<< rhel >> or C<< centos >>. The version is returned as C<< 8.x >>.
* C<< internet >> - This indicates if the target was found to have a a working Internet connection.
* C<< os_registered >> - This indicates if the OS is registered with Red Hat (if the OS is C<< rhel >>). It will be C<< yes >>, C<< no >> or C<< unknown >>.

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
		internet      => 0,
		os_registered => "", 
	};
	
	if (not $target)
	{
		# No target...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Striker->get_peer_data()", parameter => "target" }});
		return($connected, $data);
	}
	
	# Record the password in the database so that we don't pass it over the command line.
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
		if ($line =~ /internet=(.*)$/)
		{
			$data->{internet} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'data->{internet}' => $data->{internet} }});
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		connected               => $connected, 
		'data->{host_name}'     => $data->{host_name},
		'data->{host_uuid}'     => $data->{host_uuid},
		'data->{host_os}'       => $data->{host_os},
		'data->{internet}'      => $data->{internet},
		'data->{os_registered}' => $data->{os_registered}, 
	}});
	
	# Make sure the database entry is gone (striker-get-peer-data should have removed it, but lets be safe).
	my $query = "DELETE FROM states WHERE state_name = ".$anvil->Database->quote("peer::".$target."::password").";";
	$anvil->Database->write({uuid => $anvil->data->{sys}{host_uuid}, debug => 3, query => $query, source => $THIS_FILE, line => __LINE__});
	
	# Verify that the host UUID is actually valid.
	if (not $anvil->Validate->is_uuid({uuid => $data->{host_uuid}}))
	{
		$data->{host_uuid} = "";
	}
	
	return($connected, $data);
}

=head2 parse_all_status_json

This parses the c<< all_status.json >> file is a way that Striker can more readily use. If the read or parse failes, C<< 1 >> is returned. Otherwise C<< 0 >> is returned.

This method doesn't take any parameters.

=cut
sub parse_all_status_json
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_peer_data()" }});
	
	# Read it in
	my $json_file = $anvil->data->{path}{directories}{status}."/".$anvil->data->{path}{json}{all_status};
	if (not -e $json_file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0105", variables => { file => $json_file }});
		return(1);
	}
	my $body = $anvil->Storage->read_file({debug => $debug, file => $json_file});
	if ($body eq "!!error!!")
	{
		return(1);
	}
	
	my $json = JSON->new->allow_nonref;
	my $data = $json->decode($body);
	
	if (exists $anvil->data->{json}{all_status})
	{
		delete $anvil->data->{json}{all_status};
	}
	
	# We're going to look for matches as we go, so look 
	$anvil->Network->load_ips({
		debug     => $debug,
		host      => 'local',
		host_uuid => $anvil->data->{sys}{host_uuid},
	});
	
	# We'll be adding data to this JSON file over time. So this will be an ever evolving method.
	foreach my $host_hash (@{$data->{hosts}})
	{
		my $host_name  = $host_hash->{name}; 
		my $short_name = $host_hash->{short_name}; 
		
		$anvil->data->{json}{all_status}{hosts}{$host_name}{host_uuid}          = $host_hash->{host_uuid};
		$anvil->data->{json}{all_status}{hosts}{$host_name}{type}               = $host_hash->{type};
		$anvil->data->{json}{all_status}{hosts}{$host_name}{short_host_name}    = $host_hash->{short_name};
		$anvil->data->{json}{all_status}{hosts}{$host_name}{configured}         = $host_hash->{configured};
		$anvil->data->{json}{all_status}{hosts}{$host_name}{ssh_fingerprint}    = $host_hash->{ssh_fingerprint};
		$anvil->data->{json}{all_status}{hosts}{$host_name}{matched_interface}  = $host_hash->{matched_interface};
		$anvil->data->{json}{all_status}{hosts}{$host_name}{matched_ip_address} = $host_hash->{matched_ip_address};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"json::all_status::hosts::${host_name}::host_uuid"          => $anvil->data->{json}{all_status}{hosts}{$host_name}{host_uuid}, 
			"json::all_status::hosts::${host_name}::type"               => $anvil->data->{json}{all_status}{hosts}{$host_name}{type}, 
			"json::all_status::hosts::${host_name}::short_host_name"    => $anvil->data->{json}{all_status}{hosts}{$host_name}{short_host_name}, 
			"json::all_status::hosts::${host_name}::configured"         => $anvil->data->{json}{all_status}{hosts}{$host_name}{configured}, 
			"json::all_status::hosts::${host_name}::ssh_fingerprint"    => $anvil->data->{json}{all_status}{hosts}{$host_name}{ssh_fingerprint}, 
			"json::all_status::hosts::${host_name}::matched_interface"  => $anvil->data->{json}{all_status}{hosts}{$host_name}{matched_interface}, 
			"json::all_status::hosts::${host_name}::matched_ip_address" => $anvil->data->{json}{all_status}{hosts}{$host_name}{matched_ip_address}, 
		}});
		
		# Find what interface on this host we can use to talk to it (if we're not looking at ourselves).
		my $matched_interface  = "";
		my $matched_ip_address = "";
		if ($host_name ne $anvil->_host_name)
		{
			$anvil->Network->load_ips({
				debug     => $debug, 
				host      => $short_name, 
				host_uuid => $anvil->data->{json}{all_status}{hosts}{$host_name}{host_uuid},
			});
			my ($match) = $anvil->Network->find_matches({
				debug  => 3,
				first  => 'local',
				second => $short_name, 
			});
			if ($match)
			{
				# Yup!
				my $match_found = 0;
				foreach my $interface (sort {$a cmp $b} keys %{$match->{$short_name}})
				{
					$matched_interface  = $interface;
					$matched_ip_address = $match->{$short_name}{$interface}{ip_address};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						matched_interface  => $matched_interface, 
						matched_ip_address => $matched_ip_address, 
					}});
					last;
				}
			}
		}
		$anvil->data->{json}{all_status}{hosts}{$host_name}{matched_interface}  = $matched_interface;
		$anvil->data->{json}{all_status}{hosts}{$host_name}{matched_ip_address} = $matched_ip_address;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"json::all_status::hosts::${host_name}::matched_interface"  => $anvil->data->{json}{all_status}{hosts}{$host_name}{matched_interface}, 
			"json::all_status::hosts::${host_name}::matched_ip_address" => $anvil->data->{json}{all_status}{hosts}{$host_name}{matched_ip_address}, 
		}});
		
		foreach my $interface_hash (@{$host_hash->{network_interfaces}})
		{
			my $interface_name  = $interface_hash->{name};
			my $interface_type  = $interface_hash->{type};
			my $mac_address     = $interface_hash->{mac_address};
			my $ip_address      = $interface_hash->{ip_address};
			my $subnet_mask     = $interface_hash->{subnet_mask};
			my $default_gateway = $interface_hash->{default_gateway};
			my $gateway         = $interface_hash->{gateway};
			my $dns             = $interface_hash->{dns};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				interface_name  => $interface_name, 
				interface_type  => $interface_type,
				mac_address     => $mac_address, 
				ip_address      => $ip_address,
				subnet_mask     => $subnet_mask,
				default_gateway => $default_gateway,
				gateway         => $gateway,
				dns             => $dns,
			}});
			
			# This lets us easily map interface names to types.
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface_name_to_type}{$interface_name} = $interface_type;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"json::all_status::hosts::${host_name}::network_interface_name_to_type::${interface_name}" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface_name_to_type}{$interface_name}, 
			}});
			
			# Record the rest of the data.
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{uuid}            = $interface_hash->{uuid};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mtu}             = $interface_hash->{mtu};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mac_address}     = $interface_hash->{mac_address};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{ip_address}      = $interface_hash->{ip_address};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{subnet_mask}     = $interface_hash->{subnet_mask};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{default_gateway} = $interface_hash->{default_gateway};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{gateway}         = $interface_hash->{gateway};
			$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{dns}             = $interface_hash->{dns};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::uuid"            => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{uuid}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::mtu"             => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mtu}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::mac_address"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mac_address}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::ip_address"      => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{ip_address}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::subnet_mask"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{subnet_mask}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::default_gateway" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{default_gateway}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::gateway"         => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{gateway}, 
				"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::dns"             => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{dns}, 
			}});
			
			if ((exists $interface_hash->{connected_interfaces}) && (ref($interface_hash->{connected_interfaces}) eq "ARRAY"))
			{
				my $connected_interfaces_count = @{$interface_hash->{connected_interfaces}};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connected_interfaces_count => $connected_interfaces_count }});
				foreach my $connected_interface_name (sort {$a cmp $b} @{$interface_hash->{connected_interfaces}})
				{
					# We'll sort out the types after
					$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{connected_interfaces}{$connected_interface_name}{type} = "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::connected_interfaces::${connected_interface_name}::type" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{connected_interfaces}{$connected_interface_name}{type}, 
					}});
				}
			}
			
			if ($interface_type eq "bridge")
			{
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_id}   = $interface_hash->{bridge_id};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{stp_enabled} = $interface_hash->{stp_enabled};
				
				my $say_stp_enabled = $interface_hash->{stp_enabled};
				if (($say_stp_enabled eq "0") or ($say_stp_enabled eq "disabled"))
				{
					$say_stp_enabled = $anvil->Words->string({key => "unit_0020"});
				}
				elsif (($say_stp_enabled eq "1") or ($say_stp_enabled eq "enabled_kernel"))
				{
					$say_stp_enabled = $anvil->Words->string({key => "unit_0021"});
				}
				elsif (($say_stp_enabled eq "2") or ($say_stp_enabled eq "enabled_userland"))
				{
					$say_stp_enabled = $anvil->Words->string({key => "unit_0022"});
				}
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_stp_enabled} = $interface_hash->{say_stp_enabled};
				
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bridge_id"       => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_id}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::stp_enabled"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{stp_enabled}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_stp_enabled" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_stp_enabled}, 
				}});
			}
			elsif ($interface_type eq "bond")
			{
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mode}                 = $interface_hash->{mode};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{active_interface}     = $interface_hash->{active_interface};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{primary_interface}    = $interface_hash->{primary_interface};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{primary_reselect}     = $interface_hash->{primary_reselect};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{up_delay}             = $interface_hash->{up_delay};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{down_delay}           = $interface_hash->{down_delay};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{operational}          = $interface_hash->{operational};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mii_polling_interval} = $interface_hash->{mii_polling_interval}." ".$anvil->Words->string({key => "suffix_0012"});
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_uuid}          = $interface_hash->{bridge_uuid};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_name}          = $interface_hash->{bridge_name};
				
				# Translate some values
				my $say_mode = $interface_hash->{mode};
				if (($say_mode eq "0") or ($say_mode eq "balance-rr"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0006"});
				}
				elsif (($say_mode eq "1") or ($say_mode eq "active-backup"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0007"});
				}
				elsif (($say_mode eq "2") or ($say_mode eq "balanced-xor"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0008"});
				}
				elsif (($say_mode eq "3") or ($say_mode eq "broadcast"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0009"});
				}
				elsif (($say_mode eq "4") or ($say_mode eq "802.3ad"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0010"});
				}
				elsif (($say_mode eq "5") or ($say_mode eq "balanced-tlb"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0011"});
				}
				elsif (($say_mode eq "6") or ($say_mode eq "balanced-alb"))
				{
					$say_mode = $anvil->Words->string({key => "unit_0012"});
				}
				
				my $say_operational = $interface_hash->{operational};
				if ($say_operational eq "up")
				{
					$say_operational = $anvil->Words->string({key => "unit_0001"});
				}
				elsif ($say_operational eq "down")
				{
					$say_operational = $anvil->Words->string({key => "unit_0002"});
				}
				elsif ($say_operational eq "unknown")
				{
					$say_operational = $anvil->Words->string({key => "unit_0004"});
				}
				
				my $say_primary_reselect = $interface_hash->{primary_reselect};
				if (($say_primary_reselect eq "always") or ($say_primary_reselect eq "0"))
				{
					$say_primary_reselect = $anvil->Words->string({key => "unit_0017"});
				}
				elsif (($say_primary_reselect eq "better") or ($say_primary_reselect eq "1"))
				{
					$say_primary_reselect = $anvil->Words->string({key => "unit_0018"});
				}
				elsif (($say_primary_reselect eq "failure") or ($say_primary_reselect eq "2"))
				{
					$say_primary_reselect = $anvil->Words->string({key => "unit_0019"});
				}
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_up_delay}         = $interface_hash->{up_delay}." ".$anvil->Words->string({key => "suffix_0012"});
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_down_delay}       = $interface_hash->{say_down_delay}." ".$anvil->Words->string({key => "suffix_0012"});
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_mode}             = $say_mode;
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_operational}      = $say_operational;
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_primary_reselect} = $say_primary_reselect;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::mode"                 => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mode}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::active_interface"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{active_interface}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::primary_interface"    => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{primary_interface}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::primary_reselect"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{primary_reselect}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::up_delay"             => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{up_delay}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::down_delay"           => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{down_delay}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::operational"          => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{operational}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::mii_polling_interval" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{mii_polling_interval}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bridge_uuid"          => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_uuid}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bridge_name"          => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_name}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_up_delay"         => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_up_delay}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_down_delay"       => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_down_delay}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_mode"             => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_mode}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_operational"      => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_operational}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_primary_reselect" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_primary_reselect}, 
				}});
			}
			else
			{
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{speed}         = $interface_hash->{speed};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{link_state}    = $interface_hash->{link_state};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{operational}   = $interface_hash->{operational};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{duplex}        = $interface_hash->{duplex};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{medium}        = $interface_hash->{medium};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bond_uuid}     = $interface_hash->{bond_uuid};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bond_name}     = $interface_hash->{bond_name};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_uuid}   = $interface_hash->{bridge_uuid};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_name}   = $interface_hash->{bridge_name};
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{changed_order} = $interface_hash->{changed_order};
				
				my $say_speed = $anvil->Convert->add_commas({number => $interface_hash->{speed}})." ".$anvil->Words->string({key => "suffix_0050"});
				if ($interface_hash->{speed} >= 1000)
				{
					# Report in Gbps 
					$say_speed = $anvil->Convert->add_commas({number => ($interface_hash->{speed} / 1000)})." ".$anvil->Words->string({key => "suffix_0051"});
				}
				
				my $say_duplex = $interface_hash->{duplex};
				if ($say_duplex eq "full")
				{
					$say_duplex = $anvil->Words->string({key => "unit_0015"});
				}
				elsif ($say_duplex eq "half")
				{
					$say_duplex = $anvil->Words->string({key => "unit_0016"});
				}
				elsif ($say_duplex eq "unknown")
				{
					$say_duplex = $anvil->Words->string({key => "unit_0004"});
				}
				
				my $say_link_state = $interface_hash->{link_state};
				if ($say_link_state eq "1")
				{
					$say_link_state = $anvil->Words->string({key => "unit_0013"});
				}
				elsif ($say_link_state eq "0")
				{
					$say_link_state = $anvil->Words->string({key => "unit_0014"});
				}
				
				my $say_operational = $interface_hash->{operational};
				if ($say_operational eq "up")
				{
					$say_operational = $anvil->Words->string({key => "unit_0013"});
				}
				elsif ($say_operational eq "down")
				{
					$say_operational = $anvil->Words->string({key => "unit_0014"});
				}
				elsif ($say_operational eq "unknown")
				{
					$say_operational = $anvil->Words->string({key => "unit_0004"});
				}
				
				# This will be flushed out later. For now, we just send out what we've got.
				my $say_medium = $interface_hash->{medium};
				
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_speed}      = $say_speed;
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_duplex}     = $say_duplex;
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_link_state} = $say_link_state;
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_operationa} = $say_operational;
				$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_medium}     = $say_medium;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::speed"          => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{speed}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::link_state"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{link_state}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::operational"    => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{operational}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::duplex"         => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{duplex}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::medium"         => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{medium}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bond_uuid"      => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bond_uuid}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bond_name"      => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bond_name}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bridge_uuid"    => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_uuid}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::bridge_name"    => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{bridge_name}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::changed_order"  => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{changed_order}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_speed"      => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_speed}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_duplex"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_duplex}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_link_state" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_link_state}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_operationa" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_operationa}, 
					"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::say_medium"     => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{say_medium}, 
				}});
			}
		}
	}
	
	foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
		foreach my $interface_type (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface_type => $interface_type }});
			foreach my $interface_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface_name => $interface_name }});
				foreach my $connected_interface_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{connected_interfaces}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { connected_interface_name => $connected_interface_name }});
					if (defined $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface_name_to_type}{$connected_interface_name})
					{
						$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{connected_interfaces}{$connected_interface_name}{type} = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface_name_to_type}{$connected_interface_name};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"json::all_status::hosts::${host_name}::network_interface::${interface_type}::${interface_name}::connected_interfaces::${connected_interface_name}::type" => $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$interface_type}{$interface_name}{connected_interfaces}{$connected_interface_name}{type},
						}});
					}
				}
			}
		}
	}
	
	return(0);
}


1;

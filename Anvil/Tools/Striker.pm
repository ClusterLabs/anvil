package Anvil::Tools::Striker;
# 
# This module contains methods used to handle common Striker (webUI) tasks.
# 

use strict;
use warnings;
use Data::Dumper;
use JSON;
use Scalar::Util qw(weaken isweak);
use Text::Diff;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Striker.pm";

### Methods;
# generate_manifest
# get_fence_data
# get_local_repo
# get_peer_data
# get_ups_data
# load_manifest
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


=head2 generate_manifest

This reads the CGI data coming from the manifest form to generate the manifest XML. On success, the C<< manifest_uuid >>, and C<< manifest_uuid >> are returned. If there's a problem, C<< !!error!! >> is returned.

Parameters;

=head3 dns (optional)

This is a comma-separated list of DNS servers to use. 

=head3 domain (required)

This is the domain name to use for this Anvil! node.

=head3 manifest_uuid (required)

This allows updating an existing manifest, or specifying the manifest UUID to use for the new manifest. When creating a new manifest, set this to C<< new >>.

=head3 mtu (optional)

This allows specifying a custome MTU (maximum transmission unit) size. Only use this if you know all network devices support this MTU size!

=head3 ntp (optional)

This allows specifying a custom NTP (network time protocol) server to use to sync the subnode's time against.

=head3 prefix (required)

This is the node's descriptive prefix (usually 1~5 characters). 

=head3 sequence (required)

This is an integer, 1 or higher, indication the node's sequence number.

=cut
sub generate_manifest
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->generate_manifest()" }});

	my $network_dns     = defined $parameter->{dns}           ? $parameter->{dns}           : "";
	my $domain          = defined $parameter->{domain}        ? $parameter->{domain}        : "";
	my $manifest_uuid   = defined $parameter->{manifest_uuid} ? $parameter->{manifest_uuid} : "";
	my $network_mtu     = defined $parameter->{mtu}           ? $parameter->{mtu}           : "";
	my $network_ntp     = defined $parameter->{ntp}           ? $parameter->{ntp}           : "";
	my $name_prefix     = defined $parameter->{prefix}        ? $parameter->{prefix}        : "";
	my $padded_sequence = defined $parameter->{sequence}      ? $parameter->{sequence}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		network_dns     => $network_dns,
		domain          => $domain, 
		manifest_uuid   => $manifest_uuid, 
		network_mtu     => $network_mtu, 
		network_ntp     => $network_ntp, 
		name_prefix     => $name_prefix, 
		padded_sequence => $padded_sequence, 
	}});
	
	if (not $domain)
	{
		# No target...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Striker->generate_manifest()", parameter => "domain" }});
		return('!!error!!', '!!error!!');
	}
	
	if (not $name_prefix)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Striker->generate_manifest()", parameter => "name_prefix" }});
		return('!!error!!', '!!error!!');
	}
	if (not $padded_sequence)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Striker->generate_manifest()", parameter => "padded_sequence" }});
		return('!!error!!', '!!error!!');
	}
	
	$anvil->Database->get_upses({debug => $debug});
	$anvil->Database->get_fences({debug => $debug});
	
	if (not $manifest_uuid)
	{
		# Don't proceed, we'd get an invalid manifest.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0041"});
		return('!!error!!');
	}
	
	if ($manifest_uuid eq "new")
	{
		$manifest_uuid = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
	}
	
	if (length($padded_sequence) == 1)
	{
		$padded_sequence = sprintf("%02d", $padded_sequence);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { padded_sequence => $padded_sequence }});
	}
	
	my $anvil_name = $name_prefix."-anvil-".$padded_sequence;
	my $node1_name = $name_prefix."-a".$padded_sequence."n01";
	my $node2_name = $name_prefix."-a".$padded_sequence."n02";
	my $machines   = {};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_name => $anvil_name,
		node1_name => $node1_name, 
		node2_name => $node2_name, 
	}});
	
	my $manifest_xml = '<?xml version="1.0" encoding="UTF-8"?>
<install_manifest name="'.$anvil_name.'" domain="'.$domain.'">
	<networks mtu="'.$network_mtu.'" dns="'.$network_dns.'" ntp="'.$network_ntp.'">
';
	foreach my $network ("bcn", "ifn", "sn", "mn")
	{
		my $count_key = $network."_count";
		my $count_value = $parameter->{$count_key} // $anvil->data->{cgi}{$count_key}{value};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "${count_key}" => $count_value }});
		foreach my $i (1..$count_value)
		{
			my $network_name  = $network.$i;
			my $network_key   = $network_name."_network";
			my $network_value = $parameter->{$network_key} // $anvil->data->{cgi}{$network_key}{value};
			my $subnet_key    = $network_name."_subnet";
			my $subnet_value  = $parameter->{$subnet_key} // $anvil->data->{cgi}{$subnet_key}{value};
			my $gateway_key   = $network_name."_gateway";
			my $gateway_value = $parameter->{$gateway_key} // $anvil->data->{cgi}{$gateway_key}{value};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:network_key'   => $network_key,
				's2:network_value' => $network_value, 
				's3:subnet_key'    => $subnet_key, 
				's4:subnet_value'  => $subnet_value, 
				's5:gateway_key'   => $gateway_key, 
				's6:gateway_value' => $gateway_value, 
			}});

			$manifest_xml .= '		<network name="'.$network_name.'" network="'.$network_value.'" subnet="'.$subnet_value.'" gateway="'.$gateway_value.'" />'."\n";
			
			# While we're here, gather the network data for the machines.
			foreach my $machine ("node1", "node2")
			{
				# Record the network
				my $ip_key   = $machine."_".$network_name."_ip";
				my $ip_value = ($parameter->{$ip_key} // $anvil->data->{cgi}{$ip_key}{value}) // "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:ip_key'   => $ip_key,
					's2:ip_value' => $ip_value, 
				}});

				$machines->{$machine}{network}{$network_name} = $ip_value;
				
				# On the first loop (bcn1), pull in the other information as well.
				if (($network eq "bcn") && ($i eq "1"))
				{
					# Get the IP.
					my $ipmi_ip_key   = $machine."_ipmi_ip";
					my $ipmi_ip_value = ($parameter->{$ipmi_ip_key} // $anvil->data->{cgi}{$ipmi_ip_key}{value}) // "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:ipmi_ip_key'   => $ipmi_ip_key,
						's2:ipmi_ip_value' => $ipmi_ip_value, 
					}});

					$machines->{$machine}{ipmi_ip} = $ipmi_ip_value;
					
					# Find the UPSes.
					foreach my $ups_name (sort {$a cmp $b} keys %{$anvil->data->{upses}{ups_name}})
					{
						my $ups_key                              = $machine."_ups_".$ups_name;
						my $ups_value = ($parameter->{$ups_key} // $anvil->data->{cgi}{$ups_key}{value}) // "";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:ups_key'   => $ups_key,
							's2:ups_value' => $ups_value, 
						}});

						$machines->{$machine}{ups}{$ups_name} = $ups_value ? "1" : "0";
					}
					
					# Find the Fence devices.
					foreach my $fence_name (sort {$a cmp $b} keys %{$anvil->data->{fences}{fence_name}})
					{
						my $fence_key   = $machine."_fence_".$fence_name;
						my $fence_value = ($parameter->{$fence_key} // $anvil->data->{cgi}{$fence_key}{value}) // "";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							's1:fence_key'   => $fence_key,
							's2:fence_value' => $fence_value, 
						}});

						$machines->{$machine}{fence}{$fence_name} = $fence_value;
					}
				}
			}
		}
	}
	$manifest_xml .= '	</networks>
	<upses>
';
	# We don't store information about the UPS as it may change over time. We just need the reference.
	foreach my $ups_name (sort {$a cmp $b} keys %{$anvil->data->{upses}{ups_name}})
	{
		$manifest_xml .= '		<ups name="'.$ups_name.'" uuid="'.$anvil->data->{upses}{ups_name}{$ups_name}{ups_uuid}.'" />
';
	}
	$manifest_xml .= '	</upses>
	<fences>
';
	
	# We don't store information about the UPS as it may change over time. We just need the reference.
	foreach my $fence_name (sort {$a cmp $b} keys %{$anvil->data->{fences}{fence_name}})
	{
		$manifest_xml .= '		<fence name="'.$fence_name.'" uuid="'.$anvil->data->{fences}{fence_name}{$fence_name}{fence_uuid}.'" />
';
	}
	$manifest_xml .= '	</fences>
	<machines>
';

	# Now record the info about the machines.
	foreach my $machine (sort {$a cmp $b} keys %{$machines})
	{
		my $host_name = "";
		if ($machine eq "node1") { $host_name = $node1_name; }
		if ($machine eq "node2") { $host_name = $node2_name; }
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
		$manifest_xml .= '		<'.$machine.' name="'.$host_name.'" ipmi_ip="'.$machines->{$machine}{ipmi_ip}.'">
			<networks>
';
		foreach my $network_name (sort {$a cmp $b} keys %{$machines->{$machine}{network}})
		{
			$manifest_xml .= '				<network name="'.$network_name.'" ip="'.$machines->{$machine}{network}{$network_name}.'" />
';
		}
		$manifest_xml .= '			</networks>
			<upses>
';
		foreach my $ups_name (sort {$a cmp $b} keys %{$machines->{$machine}{ups}})
		{
			$manifest_xml .= '				<ups name="'.$ups_name.'" used="'.$machines->{$machine}{ups}{$ups_name}.'" />
';
		}
		$manifest_xml .= '			</upses>
			<fences>
';
		foreach my $fence_name (sort {$a cmp $b} keys %{$machines->{$machine}{fence}})
		{
			$manifest_xml .= '				<fence name="'.$fence_name.'" plug="'.$machines->{$machine}{fence}{$fence_name}.'" />
';
		}
		$manifest_xml .= '			</fences>
		</'.$machine.'>
';
	}
	$manifest_xml .= '	</machines>
</install_manifest>
';
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_xml => $manifest_xml }});
	
	# Now save the manifest!
	($manifest_uuid) = $anvil->Database->insert_or_update_manifests({
		debug         => $debug,
		manifest_uuid => $manifest_uuid, 
		manifest_name => $anvil_name, 
		manifest_xml  => $manifest_xml, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
	
	return($manifest_uuid, $anvil_name);
}


=head2 get_fence_data

This parses the unified metadata file from the avaialable fence_devices on this host. If the unified file (location stored in C<< path::data::fences_unified_metadata >>, default is C<< /tmp/fences_unified_metadata.xml >> is not found or fails to parse, C<< 1 >> is returned. If the file is successfully parsed. C<< 0 >> is returned.

The parsed data is stored under C<< fence_data::<agent_name>::... >>.

=cut
sub get_fence_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_fence_data()" }});
	
	my $parsed_xml = "";
	my $xml_body   = $anvil->Storage->read_file({
		debug => $debug, 
		file  => $anvil->data->{path}{data}{fences_unified_metadata},
	});
	
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
			
			# Clear the error so it doesn't propogate out to a future 'die' and confuse things.
			$@ = '';
			
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
		my $fence_agent                                          = $agent_ref->{name};
		   $anvil->data->{fence_data}{$fence_agent}{description} = $agent_ref->{'resource-agent'}->{longdesc};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"fence_data::${fence_agent}::description" => $anvil->data->{fence_data}{$fence_agent}{description},
		}});
		if (exists $agent_ref->{'resource-agent'}->{'symlink'})
		{
			if (ref($agent_ref->{'resource-agent'}->{'symlink'}) eq "ARRAY")
			{
				foreach my $hash_ref (@{$agent_ref->{'resource-agent'}->{'symlink'}})
				{
					my $name = $hash_ref->{name};
					$anvil->data->{fence_data}{$fence_agent}{'symlink'}{$name} = $hash_ref->{shortdesc};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"fence_data::${fence_agent}::symlink::${name}" => $anvil->data->{fence_data}{$fence_agent}{'symlink'}{$name},
					}});
				}
			}
			else
			{
				my $name = $agent_ref->{'resource-agent'}->{'symlink'}->{name};
				$anvil->data->{fence_data}{$fence_agent}{'symlink'}{$name} = $agent_ref->{'resource-agent'}->{'symlink'}->{shortdesc};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_data::${fence_agent}::symlink::${name}" => $anvil->data->{fence_data}{$fence_agent}{'symlink'}{$name},
				}});
			}
		}
		
		foreach my $hash_ref (@{$agent_ref->{'resource-agent'}->{parameters}{parameter}})
		{
			# We ignore some parameters that are not useful parameters in our case.
			my $name = $hash_ref->{name};
			next if $name =~ /debug/;
			next if $name eq "delay";
			next if $name eq "help";
			next if $name eq "version";
			next if $name eq "separator";
			# next if $name eq "plug";
			next if $name =~ /snmp(.*?)_path/;
			next if $name eq "verbose";
			
			my $unique     = exists $hash_ref->{unique}     ? $hash_ref->{unique}     : 0;
			my $required   = exists $hash_ref->{required}   ? $hash_ref->{required}   : 0;
			my $deprecated = exists $hash_ref->{deprecated} ? $hash_ref->{deprecated} : 0;
			my $obsoletes  = exists $hash_ref->{obsoletes}  ? $hash_ref->{obsoletes}  : 0;
			
			# Port is deprecated, but we can't stop using it just yet.
			if ($name eq "port")
			{
				$deprecated = 0;
			}
			
			# Store the data on the hash
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{unique}       =  $unique;
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{required}     =  $required;
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{deprecated}   =  $deprecated;
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{obsoletes}    =  $obsoletes;
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{description}  =  $hash_ref->{shortdesc}->{content};
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{description}  =~ s/\n/ /g;
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{switches}     =  defined $hash_ref->{getopt}->{mixed} ? $hash_ref->{getopt}->{mixed} : "";
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} =  $hash_ref->{content}->{type};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"fence_data::${fence_agent}::parameters::${name}::unique"       => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{unique},
				"fence_data::${fence_agent}::parameters::${name}::required"     => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{required},
				"fence_data::${fence_agent}::parameters::${name}::deprecated"   => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{deprecated},
				"fence_data::${fence_agent}::parameters::${name}::obsoletes"    => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{obsoletes},
				"fence_data::${fence_agent}::parameters::${name}::description"  => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{description},
				"fence_data::${fence_agent}::parameters::${name}::switches"     => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{switches},
				"fence_data::${fence_agent}::parameters::${name}::content_type" => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type},
			}});
			
			# Make it easier to tranlate a switch to a parameter name.
			if (($anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{switches}) and (not $deprecated))
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					fence_agent => $fence_agent,
					name        => $name, 
				}});
				foreach my $switch (split/,/, $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{switches})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { '>> switch' => $switch }});
					$switch =~ s/=.*$//;
					$switch =~ s/\s//g;
					$switch =~ s/^-{1,2}//;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { '<< switch' => $switch }});
					
					$anvil->data->{fence_data}{$fence_agent}{switch}{$switch}{name} = $name;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"fence_data::${fence_agent}::switch::${switch}::name" => $anvil->data->{fence_data}{$fence_agent}{switch}{$switch}{name},
					}});
				}
			}
			
			# 'action' is a string, but it has a set list of allowed values, so we manually switch it to a 'select' for the web interface
			if ($name eq "action")
			{
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'}    = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} = "select";
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{options}      = [];
				
				# Read the action 
				#print "Agent: [".$fence_agent."]; actions (default: [".$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'}."]);\n";
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
					
					push @{$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{options}}, $array_ref->{name};
				}
				
				foreach my $option (sort {$a cmp $b} @{$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{options}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { option => $option }});
				}
			}
			elsif ($anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} eq "string")
			{
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'} = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_data::${fence_agent}::parameters::${name}::default" => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'},
				}});
			}
			elsif ($anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} eq "select")
			{
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{options} = [];
				foreach my $option_ref (@{$hash_ref->{content}->{option}})
				{
					push @{$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{options}}, $option_ref->{value};
				}
				
				foreach my $option (sort {$a cmp $b} @{$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{options}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { option => $option }});
				}
			}
			elsif ($anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} eq "boolean")
			{
				# Nothing to collect here.
			}
			elsif ($anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} eq "second")
			{
				# Nothing to collect here.
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'} = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_data::${fence_agent}::parameters::${name}::default" => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'},
				}});
			}
			elsif ($anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{content_type} eq "integer")
			{
				# Nothing to collect here.
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'} = exists $hash_ref->{content}->{'default'} ? $hash_ref->{content}->{'default'} : "";;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_data::${fence_agent}::parameters::${name}::default" => $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{'default'},
				}});
			}
			
			# If this obsoletes another parameter, mark it as such.
			$anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{replacement} = "" if not exists $anvil->data->{fence_data}{$fence_agent}{parameters}{$name}{replacement};
			if ($obsoletes)
			{
				$anvil->data->{fence_data}{$fence_agent}{parameters}{$obsoletes}{replacement} = $name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_data::${fence_agent}::parameters::${obsoletes}::replacement" => $anvil->data->{fence_data}{$fence_agent}{parameters}{$obsoletes}{replacement},
				}});
			}
		}
		
		$anvil->data->{fence_data}{$fence_agent}{actions} = [];
		foreach my $hash_ref (@{$agent_ref->{'resource-agent'}->{actions}{action}})
		{
			push @{$anvil->data->{fence_data}{$fence_agent}{actions}}, $hash_ref->{name};
		}
		foreach my $action (sort {$a cmp $b} @{$anvil->data->{fence_data}{$fence_agent}{actions}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { action => $action }});
		}
	}
	
	# ScanCore will load this to check nodes that are not accessible. To reduce load, as this is an 
	# expensive call, this time is set so a caller can decide if the data should be updated.
	$anvil->data->{sys}{fence_data_updated} = time;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::fence_data_updated" => $anvil->data->{sys}{fence_data_updated},
	}});
	
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_local_repo()" }});
	
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
	my $host     = $anvil->Get->short_host_name();
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{network}{$host}{interface}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { interface => $interface }});
		if ($anvil->data->{network}{$host}{interface}{$interface}{ip})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "network::local::interface::${interface}::ip" => $anvil->data->{network}{$host}{interface}{$interface}{ip} }});
			if (not $base_url)
			{
				$base_url = "baseurl=http://".$anvil->data->{network}{$host}{interface}{$interface}{ip}.$directory;
			}
			else
			{
				$base_url .= "\n        http://".$anvil->data->{network}{$host}{interface}{$interface}{ip}.$directory;
			}
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { base_url => $base_url }});
	
	### NOTE: The 'module_hotfixes=1' is needed until we can figure out how to add libssh2 to 
	###       'modules.yaml' (from the RHEL 8.x repodata). See: 
	###       - https://docs.fedoraproject.org/en-US/modularity/making-modules/defining-modules/
	###       - https://docs.fedoraproject.org/en-US/modularity/hosting-modules/
	# Create the local repo file body
	my $repo = "[".$anvil->Get->short_host_name."-repo]
name=Repo on ".$anvil->Get->host_name."
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
	if (not $anvil->Validate->uuid({uuid => $data->{host_uuid}}))
	{
		$data->{host_uuid} = "";
	}
	
	return($connected, $data);
}

=head2 get_ups_data

This parses the special C<< ups_X >> string keys to create a list of supported UPSes (in ScanCore and Install Manifests).

Parsed data is stored in;
* C<< ups_data::<key>::agent >>
* C<< ups_data::<key>::brand >>
* C<< ups_data::<key>::description >>

The language used is the language returned by C<< Words->language() >>.

This method takes no parameters.

=cut
sub get_ups_data
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->get_ups_data()" }});
	
	# In case we've loaded the data before, clear it.
	if (exists $anvil->data->{ups_data})
	{
		delete $anvil->data->{ups_data};
	}
	
	my $language = $anvil->Words->language();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { language => $language }});
	
	foreach my $word_file (sort {$a cmp $b} keys %{$anvil->data->{words}})
	{
		# Now loop through all keys looking for 'ups_*'.
		foreach my $key (sort {$a cmp $b} keys %{$anvil->data->{words}{$word_file}{language}{$language}{key}})
		{
			next if $key !~ /^ups_(\d+)/;
			
			# If we're here, we've got a UPS.
			my $description = $anvil->data->{words}{$word_file}{language}{$language}{key}{$key}{content};
			my $brand       = $anvil->data->{words}{$word_file}{language}{$language}{key}{$key}{brand};
			my $agent       = $anvil->data->{words}{$word_file}{language}{$language}{key}{$key}{agent};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:brand'       => $brand,
				's2:agent'       => $agent,
				's3:description' => $description,
			}});
			
			$anvil->data->{ups_data}{$key}{agent}       = $agent;
			$anvil->data->{ups_data}{$key}{brand}       = $brand;
			$anvil->data->{ups_data}{$key}{description} = $description;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:ups_data::${key}::agent"       => $anvil->data->{ups_data}{$key}{agent},
				"s2:ups_data::${key}::brand"       => $anvil->data->{ups_data}{$key}{brand},
				"s3:ups_data::${key}::description" => $anvil->data->{ups_data}{$key}{description},
			}});
			
			# Make it easy to convert the agent to the brand.
			$anvil->data->{ups_agent}{$agent}{brand}       = $brand;
			$anvil->data->{ups_agent}{$agent}{key}         = $key;
			$anvil->data->{ups_agent}{$agent}{description} = $description;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"ups_agent::${agent}::brand"       => $anvil->data->{ups_agent}{$agent}{brand},
				"ups_agent::${agent}::key"         => $anvil->data->{ups_agent}{$agent}{key},
				"ups_agent::${agent}::description" => $anvil->data->{ups_agent}{$agent}{description},
			}});
		}
	}
	
	return(0);
}

=head2 load_manifest

This takes a manifest UUID and loads and parses it. If the manifest is loaded, C<< 0 >> is returned. C<< 1 >> is returned on error.

The loaded data is stored in a hash as:

 manifests::manifest_uuid::<manifest_uuid>::manifest_name     = <name>
 manifests::manifest_uuid::<manifest_uuid>::manifest_last_ran = <unix time>
 manifests::manifest_uuid::<manifest_uuid>::manifest_xml      = <raw_xml>
 manifests::manifest_uuid::<manifest_uuid>::manifest_note     = <user note>
 manifests::manifest_uuid::<manifest_uuid>::modified_date     = <unix time>

The following hash is used to facilitate manifest name to UUID look up.

 manifests::name_to_uuid::<manifest_name> = <manifest_uuid>

The parsed manifest XML is stored as (<machine> == node1, node2 or dr1):

 manifests::manifest_uuid::<manifest_uuid>::parsed::name                                            = <Anvil! name>
 manifests::manifest_uuid::<manifest_uuid>::parsed::domain                                          = <Anvil! domain name>
 manifests::manifest_uuid::<manifest_uuid>::parsed::prefix                                          = <Anvil! prefix>
 manifests::manifest_uuid::<manifest_uuid>::parsed::sequence                                        = <Anvil! sequence, zero-padded to two digits>
 manifests::manifest_uuid::<manifest_uuid>::parsed::upses::<ups_name>::uuid                         = <upses -> ups_uuid of named UPS>
 manifests::manifest_uuid::<manifest_uuid>::parsed::fences::<fence_name>::uuid                      = <fences -> fence_uuid of named fence device>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::dns                                   = <DNS to use, default is '8.8.8.8,8.8.4.4'>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::ntp                                   = <NTP to use, if any>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::mtu                                   = <MTU of network>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::count::bcn                            = <number of BCNs>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::count::sn                             = <number of SNs>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::count::ifn                            = <number of IFNs>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::name::<network_name>::network         = <base network ip, ie: 10.255.0.0>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::name::<network_name>::subnet          = <subnet mask>
 manifests::manifest_uuid::<manifest_uuid>::parsed::networks::name::<network_name>::gateway         = <gateway ip, if any>
 manifests::manifest_uuid::<manifest_uuid>::parsed::machine::<machine>::name                        = <host name>
 manifests::manifest_uuid::<manifest_uuid>::parsed::machine::<machine>::ipmi_ip                     = <ip of IPMI BMC, if any>
 manifests::manifest_uuid::<manifest_uuid>::parsed::machine::<machine>::fence::<fence_name>::plug   = <'plug' name/number (see fence agent man page)
 manifests::manifest_uuid::<manifest_uuid>::parsed::machine::<machine>::ups::<ups_name>::used       = <1 if powered by USB, 0 if not>
 manifests::manifest_uuid::<manifest_uuid>::parsed::machine::<machine>::network::<network_name>::ip = <ip used on network>

B<Note>: The machines to use in each role is selected when the manifest is run. Unlike in M2, the manifest does not store machine-specific information (like MAC addresses, etc). The chosen machines at run time contain that information. Similarly, passwords are NOT stored in the manifest, and passed when the manifest is run.
 
Parameters; 

=head3 manifest_uuid (required)

This is the manifest UUID to load.

=cut
sub load_manifest
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->load_manifest()" }});
	
	my $manifest_uuid = defined $parameter->{manifest_uuid} ? $parameter->{manifest_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		manifest_uuid => $manifest_uuid, 
	}});
	
	if (not $manifest_uuid)
	{
		# Didn't get a UUID
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Striker->load_manifest()", parameter => "manifest_uuid" }});
		return(1);
	}
	elsif (not $anvil->Validate->uuid({uuid => $manifest_uuid}))
	{
		# UUID isn't valid
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0130", variables => { method => "Striker->load_manifest()", parameter => "manifest_uuid", uuid => $manifest_uuid}});
		return(1);
	}
	
	my $query = "
SELECT 
    manifest_name, 
    manifest_last_ran, 
    manifest_xml, 
    manifest_note, 
    ROUND(extract(epoch FROM modified_date)) 
FROM 
    manifests 
WHERE 
    manifest_uuid = ".$anvil->Database->quote($manifest_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	my $manifest_template = "";
	if ($count)
	{
		my $manifest_name     = $results->[0]->[0];
		my $manifest_last_ran = $results->[0]->[1];
		my $manifest_xml      = $results->[0]->[2];
		my $manifest_note     = $results->[0]->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			manifest_name     => $manifest_name, 
			manifest_last_ran => $manifest_last_ran,
			manifest_xml      => $manifest_xml, 
			manifest_note     => $manifest_note, 
		}});
		
		# Record the data. 
		$anvil->data->{manifests}{$manifest_uuid}{manifest_name}     = $manifest_name;
		$anvil->data->{manifests}{$manifest_uuid}{manifest_last_ran} = $manifest_last_ran;
		$anvil->data->{manifests}{$manifest_uuid}{manifest_xml}      = $manifest_xml;
		$anvil->data->{manifests}{$manifest_uuid}{manifest_note}     = $manifest_note;
		$anvil->data->{manifests}{name_to_uuid}{$manifest_name}      = $manifest_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::${manifest_uuid}::manifest_name"     => $anvil->data->{manifests}{$manifest_uuid}{manifest_name}, 
			"manifests::${manifest_uuid}::manifest_last_ran" => $anvil->data->{manifests}{$manifest_uuid}{manifest_last_ran}, 
			"manifests::${manifest_uuid}::manifest_xml"      => $anvil->data->{manifests}{$manifest_uuid}{manifest_xml}, 
			"manifests::${manifest_uuid}::manifest_note"     => $anvil->data->{manifests}{$manifest_uuid}{manifest_note}, 
			"manifests::name_to_uuid::${manifest_name}"      => $anvil->data->{manifests}{name_to_uuid}{$manifest_name}, 
		}});
		
		# Whoever is calling us will want the fence data, so load it as well.
		$anvil->Database->get_fences({debug => $debug});
		
		# Parse the XML.
		local $@;
		my $parsed_xml = "";
		my $xml        = XML::Simple->new();
		my $test       = eval { $parsed_xml = $xml->XMLin($manifest_xml, KeyAttr => { key => 'name' }, ForceArray => []) };
		if (not $test)
		{
			chomp $@;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0111", variables => { 
				xml_body   => $manifest_xml, 
				eval_error => $@,
			}});
			return(1);
		}
		
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{domain} = $parsed_xml->{domain};
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{name}   = $parsed_xml->{name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::domain" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{domain}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::name"   => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{name}, 
		}});
		
		my ($prefix, $sequence) = ($anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{name} =~ /^(.*?)-anvil-(\d+)$/);
		   $sequence            = sprintf("%02d", $sequence);
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{prefix}   = $prefix;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{sequence} = $sequence;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::prefix"   => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{prefix}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::sequence" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{sequence}, 
		}});
		
		if (ref($parsed_xml->{upses}{ups}) eq "HASH")
		{
			# Only a single ups device
			my $ups_name                                                                                = $parsed_xml->{upses}{ups}{name};
			   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{upses}{$ups_name}{uuid} = $parsed_xml->{upses}{ups}{uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::upses::${ups_name}::uuid" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{upses}{$ups_name}{uuid}, 
			}});
		}
		elsif (ref($parsed_xml->{fences}{fence}) eq "ARRAY")
		{
			# Two or more UPSes
			foreach my $hash_ref (@{$parsed_xml->{upses}{ups}})
			{
				my $ups_name                                                                                = $hash_ref->{name};
				   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{upses}{$ups_name}{uuid} = $hash_ref->{uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"manifests::manifest_uuid::${manifest_uuid}::parsed::upses::${ups_name}::uuid" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{upses}{$ups_name}{uuid}, 
				}});
			}
		}
		
		if (ref($parsed_xml->{fences}{fence}) eq "HASH")
		{
			# Only a single fence device
			my $fence_name                                                                                 = $parsed_xml->{fences}{fence}{name};
			   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{fences}{$fence_name}{uuid} = $parsed_xml->{fences}{fence}{uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::fences::${fence_name}::uuid" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{fences}{$fence_name}{uuid}, 
			}});
		}
		elsif (ref($parsed_xml->{fences}{fence}) eq "ARRAY")
		{
			# Two or more fence devices.
			foreach my $hash_ref (@{$parsed_xml->{fences}{fence}})
			{
				my $fence_name                                                                                 = $hash_ref->{name};
				   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{fences}{$fence_name}{uuid} = $hash_ref->{uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"manifests::manifest_uuid::${manifest_uuid}::parsed::fences::${fence_name}::uuid" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{fences}{$fence_name}{uuid}, 
				}});
			}
		}
		
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{dns} = $parsed_xml->{networks}{dns};
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{ntp} = $parsed_xml->{networks}{ntp};
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{mtu} = $parsed_xml->{networks}{mtu};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::dns" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{dns}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::ntp" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{ntp}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::mtu" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{mtu}, 
		}});
		my $bcn_count = 0;
		my $sn_count  = 0;
		my $ifn_count = 0;
		my $mn_count  = 0;
		foreach my $hash_ref (@{$parsed_xml->{networks}{network}})
		{
			my $network_name                                                                                            = $hash_ref->{name};
			   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{network} = $hash_ref->{network};
			   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{subnet}  = $hash_ref->{subnet};
			   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{gateway} = $hash_ref->{gateway};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::name::${network_name}::network" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{network}, 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::name::${network_name}::subnet"  => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{subnet}, 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::name::${network_name}::gateway" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{name}{$network_name}{gateway}, 
			}});
			if    ($network_name =~ /^bcn/) { $bcn_count++; }
			elsif ($network_name =~ /^sn/)  { $sn_count++; }
			elsif ($network_name =~ /^ifn/) { $ifn_count++; }
			elsif ($network_name =~ /^mn/)  { $mn_count++; }
		}
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{bcn} = $bcn_count;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{sn}  = $sn_count;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{ifn} = $ifn_count;
		$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{mn}  = $mn_count;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::count::bcn" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{bcn}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::count::sn"  => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{sn}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::count::ifn" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{ifn}, 
			"manifests::manifest_uuid::${manifest_uuid}::parsed::networks::count::mn"  => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{networks}{count}{mn}, 
		}});
		
		foreach my $machine (sort {$a cmp $b} keys %{$parsed_xml->{machines}})
		{
			$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{name}    = $parsed_xml->{machines}{$machine}{name};
			$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ipmi_ip} = defined $parsed_xml->{machines}{$machine}{ipmi_ip} ? $parsed_xml->{machines}{$machine}{ipmi_ip} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::name"    => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{name}, 
				"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::ipmi_ip" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ipmi_ip}, 
			}});
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"ref(parsed_xml->{machines}{$machine}{upses}{ups})" => ref($parsed_xml->{machines}{$machine}{upses}{ups}), 
			}});
			if (ref($parsed_xml->{machines}{$machine}{upses}{ups}) eq "HASH")
			{
				my $ups_name                                                                                                 = $parsed_xml->{machines}{$machine}{upses}{ups}{name};
				   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ups}{$ups_name}{used} = $parsed_xml->{machines}{$machine}{upses}{ups}{used};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::ups::${ups_name}::used" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ups}{$ups_name}{used}, 
				}});
			}
			elsif (ref($parsed_xml->{machines}{$machine}{upses}{ups}) eq "ARRAY")
			{
				foreach my $hash_ref (@{$parsed_xml->{machines}{$machine}{upses}{ups}})
				{
					my $ups_name                                                                                                 = $hash_ref->{name};
					   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ups}{$ups_name}{used} = $hash_ref->{used};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::ups::${ups_name}::used" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{ups}{$ups_name}{used}, 
					}});
				}
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"ref(parsed_xml->{machines}{$machine}{fences}{fence})" => ref($parsed_xml->{machines}{$machine}{fences}{fence}), 
			}});
			if (ref($parsed_xml->{machines}{$machine}{fences}{fence}) eq "HASH")
			{
				my $fence_name                                                                                                   = $parsed_xml->{machines}{$machine}{fences}{fence}{name};
				   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{port} = $parsed_xml->{machines}{$machine}{fences}{fence}{plug} ? $parsed_xml->{machines}{$machine}{fences}{fence}{plug} : $parsed_xml->{machines}{$machine}{fences}{fence}{port};
				   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{plug} = $parsed_xml->{machines}{$machine}{fences}{fence}{plug} ? $parsed_xml->{machines}{$machine}{fences}{fence}{plug} : $parsed_xml->{machines}{$machine}{fences}{fence}{port};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::fence::${fence_name}::port" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{port}, 
					"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::fence::${fence_name}::plug" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{plug}, 
				}});
			}
			elsif (ref($parsed_xml->{machines}{$machine}{fences}{fence}) eq "ARRAY")
			{
				foreach my $hash_ref (@{$parsed_xml->{machines}{$machine}{fences}{fence}})
				{
					my $fence_name                                                                                                   = $hash_ref->{name};
					   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{port} = $hash_ref->{plug} ? $hash_ref->{plug} : $hash_ref->{port};
					   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{plug} = $hash_ref->{plug} ? $hash_ref->{plug} : $hash_ref->{port};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::fence::${fence_name}::port" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{port}, 
						"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::fence::${fence_name}::plug" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{fence}{$fence_name}{plug}, 
					}});
				}
			}
			
			foreach my $hash_ref (@{$parsed_xml->{machines}{$machine}{networks}{network}})
			{
				my $network_name                                                                                                   = $hash_ref->{name};
				   $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{network}{$network_name}{ip} = $hash_ref->{ip};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"manifests::manifest_uuid::${manifest_uuid}::parsed::machine::${machine}::network::${network_name}::ip" => $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$machine}{network}{$network_name}{ip}, 
				}});
			}
		}
	}
	else
	{
		# Not found.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0042", variables => { 
			table  => "manifests", 
			column => "manifest_uuid", 
			value  => $manifest_uuid,
		}});
		return(1);
	}
	
	return(0);
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Striker->parse_all_status_json()" }});
	
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
		host      => $anvil->Get->short_host_name(),
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
		if ($host_name ne $anvil->Get->host_name)
		{
			$anvil->Network->load_ips({
				debug     => $debug, 
				host      => $short_name, 
				host_uuid => $anvil->data->{json}{all_status}{hosts}{$host_name}{host_uuid},
			});
			my ($match) = $anvil->Network->find_matches({
				debug  => 3,
				first  => $anvil->Get->short_host_name(),
				second => $short_name, 
				source => $THIS_FILE, 
				line   => __LINE__,
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

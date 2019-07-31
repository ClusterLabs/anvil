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
# get_status

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

=head2 find

This looks on an Anvil! for what servers are running where.



=cut

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
	$anvil->data->{server}{$server}{from_memory}{host} = "";
	
	# Is this a local call or a remote call?
	my $shell_call = $anvil->data->{path}{exe}{virsh}." dumpxml ".$server;
	my $host       = $anvil->_short_hostname;
	if (($target) && ($target ne "local") && ($target ne $anvil->_hostname) && ($target ne $anvil->_short_hostname))
	{
		# Remote call.
		$host = $target;
		($anvil->data->{server}{$server}{from_memory}{xml}, my $error, $anvil->data->{server}{$server}{from_memory}{return_code}) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error                                     => $error,
			"server::${server}::from_memory::xml"         => $anvil->data->{server}{$server}{from_memory}{xml},
			"server::${server}::from_memory::return_code" => $anvil->data->{server}{$server}{from_memory}{return_code},
		}});
	}
	else
	{
		# Local.
		($anvil->data->{server}{$server}{from_memory}{xml}, $anvil->data->{server}{$server}{from_memory}{return_code}) = $anvil->System->call({shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${server}::from_memory::xml"         => $anvil->data->{server}{$server}{from_memory}{xml},
			"server::${server}::from_memory::return_code" => $anvil->data->{server}{$server}{from_memory}{return_code},
		}});
	}
	
	# If the return code was non-zero, we can't parse the XML.
	if ($anvil->data->{server}{$server}{from_memory}{return_code})
	{
		$anvil->data->{server}{$server}{from_memory}{xml} = "";
	}
	else
	{
		$anvil->data->{server}{$server}{from_memory}{host} = $host;
		$anvil->Server->_parse_definition({
			debug      => $debug,
			server     => $server, 
			source     => "from_memory",
			definition => $anvil->data->{server}{$server}{from_memory}{xml}, 
		});
	}
	
	# Now get the on-disk XML.
	($anvil->data->{server}{$server}{from_disk}{xml}) = $anvil->Storage->read_file({
		debug       => $debug, 
		password    => $password,
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
		force_read  => 1,
		file        => $anvil->data->{path}{directories}{shared}{definitions}."/".$server.".xml",
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${server}::disk::xml" => $anvil->data->{server}{$server}{disk}{xml},
	}});
	if ($anvil->data->{server}{$server}{disk}{xml})
	{
		$anvil->Server->_parse_definition({
			debug      => $debug,
			server     => $server, 
			source     => "from_disk",
			definition => $anvil->data->{server}{$server}{from_disk}{xml}, 
		});
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

### NOTE: This is a work in progress. As of now, it parses out what ocf:alteeve:server needs.
# This pulls apart specific data out of a definition file. 
sub _parse_definition
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Source is required.
	my $server     = defined $parameter->{server}     ? $parameter->{server}     : "";
	my $source     = defined $parameter->{source}     ? $parameter->{source}     : "";
	my $definition = defined $parameter->{definition} ? $parameter->{definition} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		source     => $source, 
		definition => $definition, 
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->_parse_definition()", parameter => "server" }});
		return(1);
	}
	if (not $source)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->_parse_definition()", parameter => "source" }});
		return(1);
	}
	if (not $definition)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Server->_parse_definition()", parameter => "definition" }});
		return(1);
	}
	
	# We're going to map DRBD devices to resources, so we need to collect that data now.
	$anvil->DRBD->get_devices({debug => $debug});
	
	my $xml        = XML::Simple->new();
	my $server_xml = "";
	eval { $server_xml = $xml->XMLin($definition, KeyAttr => {}, ForceArray => 1) };
	if ($@)
	{
		chomp $@;
		my $error =  "[ Error ] - The was a problem parsing: [$definition]. The error was:\n";
		   $error .= "===========================================================\n";
		   $error .= $@."\n";
		   $error .= "===========================================================\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", list => { error => $error }});
		$anvil->nice_exit({exit_code => 1});
	}
	
	$anvil->data->{server}{$server}{$source}{parsed} = $server_xml;
	#print Dumper $server_xml;
	
	# Pull out some basic server info.
	$anvil->data->{server}{$server}{$source}{info}{uuid} = $server_xml->{uuid}->[0];
	$anvil->data->{server}{$server}{$source}{info}{name} = $server_xml->{name}->[0];
	$anvil->data->{server}{$server}{$source}{info}{on_poweroff} = $server_xml->{on_poweroff}->[0];
	$anvil->data->{server}{$server}{$source}{info}{on_crash}    = $server_xml->{on_crash}->[0];
	$anvil->data->{server}{$server}{$source}{info}{on_reboot}   = $server_xml->{on_reboot}->[0];
	$anvil->data->{server}{$server}{$source}{info}{boot_menu}   = $server_xml->{os}->[0]->{bootmenu}->[0]->{enable};
	$anvil->data->{server}{$server}{$source}{info}{id}          = $server_xml->{id};
	$anvil->data->{server}{$server}{$source}{info}{emulator}    = $server_xml->{devices}->[0]->{emulator}->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${server}::${source}::info::uuid"        => $anvil->data->{server}{$server}{$source}{info}{uuid},
		"server::${server}::${source}::info::name"        => $anvil->data->{server}{$server}{$source}{info}{name},
		"server::${server}::${source}::info::on_poweroff" => $anvil->data->{server}{$server}{$source}{info}{on_poweroff},
		"server::${server}::${source}::info::on_crash"    => $anvil->data->{server}{$server}{$source}{info}{on_crash},
		"server::${server}::${source}::info::on_reboot"   => $anvil->data->{server}{$server}{$source}{info}{on_reboot},
		"server::${server}::${source}::info::boot_menu"   => $anvil->data->{server}{$server}{$source}{info}{boot_menu},
		"server::${server}::${source}::info::id"          => $anvil->data->{server}{$server}{$source}{info}{id},
		"server::${server}::${source}::info::emulator"    => $anvil->data->{server}{$server}{$source}{info}{emulator},
	}});
	
	# CPU
	$anvil->data->{server}{$server}{$source}{cpu}{total_cores}    = $server_xml->{vcpu}->[0]->{content};
	$anvil->data->{server}{$server}{$source}{cpu}{sockets}        = $server_xml->{cpu}->[0]->{topology}->[0]->{sockets};
	$anvil->data->{server}{$server}{$source}{cpu}{cores}          = $server_xml->{cpu}->[0]->{topology}->[0]->{cores};
	$anvil->data->{server}{$server}{$source}{cpu}{threads}        = $server_xml->{cpu}->[0]->{topology}->[0]->{threads};
	$anvil->data->{server}{$server}{$source}{cpu}{model_name}     = $server_xml->{cpu}->[0]->{model}->[0]->{content};
	$anvil->data->{server}{$server}{$source}{cpu}{model_fallback} = $server_xml->{cpu}->[0]->{model}->[0]->{fallback};
	$anvil->data->{server}{$server}{$source}{cpu}{match}          = $server_xml->{cpu}->[0]->{match};
	$anvil->data->{server}{$server}{$source}{cpu}{vendor}         = $server_xml->{cpu}->[0]->{vendor}->[0];
	$anvil->data->{server}{$server}{$source}{cpu}{mode}           = $server_xml->{cpu}->[0]->{mode};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${server}::${source}::cpu::total_cores"    => $anvil->data->{server}{$server}{$source}{cpu}{total_cores},
		"server::${server}::${source}::cpu::sockets"        => $anvil->data->{server}{$server}{$source}{cpu}{sockets},
		"server::${server}::${source}::cpu::cores"          => $anvil->data->{server}{$server}{$source}{cpu}{cores},
		"server::${server}::${source}::cpu::threads"        => $anvil->data->{server}{$server}{$source}{cpu}{threads},
		"server::${server}::${source}::cpu::model_name"     => $anvil->data->{server}{$server}{$source}{cpu}{model_name},
		"server::${server}::${source}::cpu::model_fallback" => $anvil->data->{server}{$server}{$source}{cpu}{model_fallback},
		"server::${server}::${source}::cpu::match"          => $anvil->data->{server}{$server}{$source}{cpu}{match},
		"server::${server}::${source}::cpu::vendor"         => $anvil->data->{server}{$server}{$source}{cpu}{vendor},
		"server::${server}::${source}::cpu::mode"           => $anvil->data->{server}{$server}{$source}{cpu}{mode},
	}});
	foreach my $hash_ref (@{$server_xml->{cpu}->[0]->{feature}})
	{
		my $name                                                         = $hash_ref->{name};
		   $anvil->data->{server}{$server}{$source}{cpu}{feature}{$name} = $hash_ref->{policy};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${server}::${source}::cpu::feature::${name}" => $anvil->data->{server}{$server}{$source}{cpu}{feature}{$name},
		}});
		
	}
	
	# Power Management
	$anvil->data->{server}{$server}{$source}{pm}{'suspend-to-disk'} = $server_xml->{pm}->[0]->{'suspend-to-disk'}->[0]->{enabled};
	$anvil->data->{server}{$server}{$source}{pm}{'suspend-to-mem'}  = $server_xml->{pm}->[0]->{'suspend-to-mem'}->[0]->{enabled};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${server}::${source}::pm::suspend-to-disk" => $anvil->data->{server}{$server}{$source}{pm}{'suspend-to-disk'},
		"server::${server}::${source}::pm::suspend-to-mem"  => $anvil->data->{server}{$server}{$source}{pm}{'suspend-to-mem'},
	}});
	
	# RAM - 'memory' is as set at boot, 'currentMemory' is the RAM used at polling (so only useful when 
	#       running). In the Anvil!, we don't support memory ballooning, so we're use whichever is 
	#       higher.
	my $current_ram_value = $server_xml->{currentMemory}->[0]->{content};
	my $current_ram_unit  = $server_xml->{currentMemory}->[0]->{unit};
	my $current_ram_bytes = $anvil->Convert->human_readable_to_bytes({size => $current_ram_value, type => $current_ram_unit});
	my $ram_value         = $server_xml->{memory}->[0]->{content};
	my $ram_unit          = $server_xml->{memory}->[0]->{unit};
	my $ram_bytes         = $anvil->Convert->human_readable_to_bytes({size => $ram_value, type => $ram_unit});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		current_ram_value => $current_ram_value,
		current_ram_unit  => $current_ram_unit,
		current_ram_bytes => $anvil->Convert->add_commas({number => $current_ram_bytes})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $current_ram_bytes}).")",
		ram_value         => $ram_value,
		ram_unit          => $ram_unit,
		ram_bytes         => $anvil->Convert->add_commas({number => $ram_bytes})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $ram_bytes}).")",
	}});
	
	$anvil->data->{server}{$server}{$source}{memory} = $current_ram_bytes > $ram_bytes ? $current_ram_bytes : $ram_bytes;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"server::${server}::${source}::memory" => $anvil->Convert->add_commas({number => $anvil->data->{server}{$server}{$source}{memory}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{server}{$server}{$source}{memory}}).")",
	}});
	
	# Pull out my channels
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{channel}})
	{
		my $type = $hash_ref->{type};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { type => $type }});
		if ($type eq "unix")
		{
			# Bus stuff
			my $address_type       = $hash_ref->{address}->[0]->{type};
			my $address_controller = $hash_ref->{address}->[0]->{controller};
			my $address_bus        = $hash_ref->{address}->[0]->{bus};
			my $address_port       = $hash_ref->{address}->[0]->{port};
			
			# Store
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{source}{mode}        = $hash_ref->{source}->[0]->{mode};
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{source}{path}        = $hash_ref->{source}->[0]->{path};
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{alias}               = $hash_ref->{alias}->[0]->{name};
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{type}       = $address_type;
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{bus}        = $address_bus;
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{controller} = $address_controller;
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{port}       = $address_port;
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{target}{type}        = $hash_ref->{target}->[0]->{type};
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{target}{'state'}     = $hash_ref->{target}->[0]->{'state'};
			$anvil->data->{server}{$server}{$source}{device}{channel}{unix}{target}{name}        = $hash_ref->{target}->[0]->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::channel::unix::source::mode"        => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{source}{mode},
				"server::${server}::${source}::device::channel::unix::source::path"        => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{source}{path},
				"server::${server}::${source}::device::channel::unix::alias"               => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{alias},
				"server::${server}::${source}::device::channel::unix::address::type"       => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{type},
				"server::${server}::${source}::device::channel::unix::address::bus"        => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{bus},
				"server::${server}::${source}::device::channel::unix::address::controller" => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{controller},
				"server::${server}::${source}::device::channel::unix::address::port"       => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{address}{port},
				"server::${server}::${source}::device::channel::unix::target::type"        => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{target}{type},
				"server::${server}::${source}::device::channel::unix::target::state"       => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{target}{'state'},
				"server::${server}::${source}::device::channel::unix::target::name"        => $anvil->data->{server}{$server}{$source}{device}{channel}{unix}{target}{name},
			}});
			
			# Add to system bus list
			$anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port} = "channel - ".$type;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::address::${address_type}::controller::${address_controller}::bus::${address_bus}::port::${address_port}" => $anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port},
			}});
		}
		elsif ($type eq "spicevmc")
		{
			# Bus stuff
			my $address_type       = $hash_ref->{address}->[0]->{type};
			my $address_controller = $hash_ref->{address}->[0]->{controller};
			my $address_bus        = $hash_ref->{address}->[0]->{bus};
			my $address_port       = $hash_ref->{address}->[0]->{port};
			
			# Store
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{alias}               = $hash_ref->{alias}->[0]->{name};
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{type}       = $address_type;
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{bus}        = $address_bus;
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{controller} = $address_controller;
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{port}       = $address_port;
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{target}{type}        = $hash_ref->{target}->[0]->{type};
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{target}{'state'}     = $hash_ref->{target}->[0]->{'state'};
			$anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{target}{name}        = $hash_ref->{target}->[0]->{name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::channel::spicevmc::alias"               => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{alias},
				"server::${server}::${source}::device::channel::spicevmc::address::type"       => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{type},
				"server::${server}::${source}::device::channel::spicevmc::address::bus"        => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{bus},
				"server::${server}::${source}::device::channel::spicevmc::address::controller" => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{controller},
				"server::${server}::${source}::device::channel::spicevmc::address::port"       => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{address}{port},
				"server::${server}::${source}::device::channel::spicevmc::target::type"        => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{target}{type},
				"server::${server}::${source}::device::channel::spicevmc::target::state"       => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{target}{'state'},
				"server::${server}::${source}::device::channel::spicevmc::target::name"        => $anvil->data->{server}{$server}{$source}{device}{channel}{spicevmc}{target}{name},
			}});
			
			# Add to system bus list
			$anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port} = "channel - ".$type;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::address::${address_type}::controller::${address_controller}::bus::${address_bus}::port::${address_port}" => $anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$address_controller}{bus}{$address_bus}{port}{$address_port},
			}});
		}
	}
	
	# Pull out console data
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{console}})
	{
		$anvil->data->{server}{$server}{$source}{device}{console}{type}        = $hash_ref->{type};
		$anvil->data->{server}{$server}{$source}{device}{console}{tty}         = $hash_ref->{tty};
		$anvil->data->{server}{$server}{$source}{device}{console}{alias}       = $hash_ref->{alias}->[0]->{name};
		$anvil->data->{server}{$server}{$source}{device}{console}{source}      = $hash_ref->{source}->[0]->{path};
		$anvil->data->{server}{$server}{$source}{device}{console}{target_type} = $hash_ref->{target}->[0]->{type};
		$anvil->data->{server}{$server}{$source}{device}{console}{target_port} = $hash_ref->{target}->[0]->{port};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${server}::${source}::device::console::type"        => $anvil->data->{server}{$server}{$source}{device}{console}{type},
			"server::${server}::${source}::device::console::tty"         => $anvil->data->{server}{$server}{$source}{device}{console}{tty},
			"server::${server}::${source}::device::console::alias"       => $anvil->data->{server}{$server}{$source}{device}{console}{alias},
			"server::${server}::${source}::device::console::source"      => $anvil->data->{server}{$server}{$source}{device}{console}{source},
			"server::${server}::${source}::device::console::target_type" => $anvil->data->{server}{$server}{$source}{device}{console}{target_type},
			"server::${server}::${source}::device::console::target_port" => $anvil->data->{server}{$server}{$source}{device}{console}{target_port},
		}});
	}
	
	# Controllers is a big chunk
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{controller}})
	{
		my $type             = $hash_ref->{type};
		my $index            = $hash_ref->{'index'};
		my $ports            = exists $hash_ref->{ports}                     ? $hash_ref->{ports}                    : "";
		my $target_chassis   = exists $hash_ref->{target}                    ? $hash_ref->{target}->[0]->{chassis}   : "";
		my $target_port      = exists $hash_ref->{target}                    ? $hash_ref->{target}->[0]->{port}      : "";
		my $address_type     = defined $hash_ref->{address}->[0]->{type}     ? $hash_ref->{address}->[0]->{type}     : "";
		my $address_domain   = defined $hash_ref->{address}->[0]->{domain}   ? $hash_ref->{address}->[0]->{domain}   : "";
		my $address_bus      = defined $hash_ref->{address}->[0]->{bus}      ? $hash_ref->{address}->[0]->{bus}      : "";
		my $address_slot     = defined $hash_ref->{address}->[0]->{slot}     ? $hash_ref->{address}->[0]->{slot}     : "";
		my $address_function = defined $hash_ref->{address}->[0]->{function} ? $hash_ref->{address}->[0]->{function} : "";
		
		# Model is weird, it can be at '$hash_ref->{model}->[X]' or '$hash_ref->{model}->[Y]->{name}'
		# as 'model' is both an attribute and a child element.
		$hash_ref->{model} = "" if not defined $hash_ref->{model};
		my $model = "";
		if (not ref($hash_ref->{model}))
		{
			$model = $hash_ref->{model};
		}
		else
		{
			foreach my $entry (@{$hash_ref->{model}})
			{
				if (ref($entry))
				{
					$model = $entry->{name} if $entry->{name};
				}
				else
				{
					$model = $entry if $entry;
				}
			}
		}
		
		# Store the data
		$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{alias} = $hash_ref->{alias}->[0]->{name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"server::${server}::${source}::device::controller::${type}::index::${index}::alias" => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{alias},
		}});
		if ($model)
		{
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{model} = $model;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::controller::${type}::index::${index}::model" => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{model},
			}});
		}
		if ($ports)
		{
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{ports} = $ports;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::controller::${type}::index::${index}::ports" => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{ports},
			}});
		}
		if ($target_chassis)
		{
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{chassis} = $target_chassis;
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{port}    = $target_port;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::controller::${type}::index::${index}::target::chassis" => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{chassis},
				"server::${server}::${source}::device::controller::${type}::index::${index}::target::port"    => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{target}{port},
			}});
		}
		if ($address_type)
		{
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{type}     = $address_type;
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{domain}   = $address_domain;
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{bus}      = $address_bus;
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{slot}     = $address_slot;
			$anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{function} = $address_function;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::controller::${type}::index::${index}::address::type"     => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{type},
				"server::${server}::${source}::device::controller::${type}::index::${index}::address::domain"   => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{domain},
				"server::${server}::${source}::device::controller::${type}::index::${index}::address::bus"      => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{bus},
				"server::${server}::${source}::device::controller::${type}::index::${index}::address::slot"     => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{slot},
				"server::${server}::${source}::device::controller::${type}::index::${index}::address::function" => $anvil->data->{server}{$server}{$source}{device}{controller}{$type}{'index'}{$index}{address}{function},
			}});
			
			# Add to system bus list
			# Controller type: [pci], alias: (pci.2), index: [2]
			# - Model: [pcie-root-port]
			# - Target chassis: [2], port: [0x11]
			# - Bus type: [pci], domain: [0x0000], bus: [0x00], slot: [0x02], function: [0x1]
			#      server::test_server::from_memory::address::virtio-serial::controller::0::bus::0::port::2: [channel - spicevmc]
			$anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$type}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain} = $address_domain;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::address::${address_type}::controller::${type}::bus::${address_bus}::slot::${address_slot}::function::${address_function}::domain" => $anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$type}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain},
			}});
		}
	}
	
	# Find what drives (disk and "optical") this server uses.
	foreach my $hash_ref (@{$server_xml->{devices}->[0]->{disk}})
	{
		#print Dumper $hash_ref;
		my $device        = $hash_ref->{device};
		my $type          = $hash_ref->{type};
		my $device_target = $hash_ref->{target}->[0]->{dev};
		my $device_bus    = $hash_ref->{target}->[0]->{bus};
		my $address_type  = $hash_ref->{address}->[0]->{type};
		my $address_bus   = $hash_ref->{address}->[0]->{bus};
		my $boot_order    = defined $hash_ref->{boot}->[0]->{order} ? $hash_ref->{boot}->[0]->{order} : 99;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			device        => $device,
			type          => $type,
			device_target => $device_target, 
			device_bus    => $device_bus, 
			address_type  => $address_type, 
			address_bus   => $address_bus, 
			boot_order    => $boot_order, 
		}});
		
		if ($device eq "disk")
		{
			my $address_slot     = $hash_ref->{address}->[0]->{slot};
			my $address_domain   = $hash_ref->{address}->[0]->{domain};
			my $address_function = $hash_ref->{address}->[0]->{function};
			my $device_path      = $hash_ref->{source}->[0]->{dev};
			
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{type}     = $address_type;
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{domain}   = $address_domain;
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{bus}      = $address_bus;
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{slot}     = $address_slot;
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{function} = $address_function;
			$anvil->data->{server}{$server}{$source}{device}{$device}{path}              = $device_path;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::${device}::address::type"     => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{type},
				"server::${server}::${source}::device::${device}::address::domain"   => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{domain},
				"server::${server}::${source}::device::${device}::address::bus"      => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{bus},
				"server::${server}::${source}::device::${device}::address::slot"     => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{slot},
				"server::${server}::${source}::device::${device}::address::function" => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{function},
				"server::${server}::${source}::device::${device}::path"              => $anvil->data->{server}{$server}{$source}{device}{$device}{path},
			}});
			
			$anvil->data->{server}{$server}{$source}{device}{$device_path}{on_lv}    = defined $anvil->data->{drbd}{'local'}{drbd_path}{$device_path}{on}       ? $anvil->data->{drbd}{'local'}{drbd_path}{$device_path}{on}       : "";
			$anvil->data->{server}{$server}{$source}{device}{$device_path}{resource} = defined $anvil->data->{drbd}{'local'}{drbd_path}{$device_path}{resource} ? $anvil->data->{drbd}{'local'}{drbd_path}{$device_path}{resource} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::${device_path}::on_lv"    => $anvil->data->{server}{$server}{$source}{device}{$device_path}{on_lv},
				"server::${server}::${source}::device::${device_path}::resource" => $anvil->data->{server}{$server}{$source}{device}{$device_path}{resource},
			}});
			
# 			$anvil->data->{server}{$server}{$source}{address}{$device_bus}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain} = $address_domain;
# 			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
# 				"server::${server}::${source}::address::${address_type}::controller::${type}::bus::${address_bus}::slot::${address_slot}::function::${address_function}::domain" => $anvil->data->{server}{$server}{$source}{address}{$address_type}{controller}{$type}{bus}{$address_bus}{bus}{$address_bus}{slot}{$address_slot}{function}{$address_function}{domain},
# 			}});
		}
		else
		{
			# Looks like IDE is no longer supported on RHEL 8.
			my $device_path        = defined $hash_ref->{source}->[0]->{file} ? $hash_ref->{source}->[0]->{file} : "";
			my $address_controller = $hash_ref->{address}->[0]->{controller};
			my $address_unit       = $hash_ref->{address}->[0]->{unit};
			my $address_target     = $hash_ref->{address}->[0]->{target};
			
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{controller} = $address_controller;
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{unit}       = $address_unit;
			$anvil->data->{server}{$server}{$source}{device}{$device}{address}{target}     = $address_target;
			$anvil->data->{server}{$server}{$source}{device}{$device}{path}                = $device_path;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"server::${server}::${source}::device::${device}::address::controller" => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{controller},
				"server::${server}::${source}::device::${device}::address::unit"       => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{unit},
				"server::${server}::${source}::device::${device}::address::target"     => $anvil->data->{server}{$server}{$source}{device}{$device}{address}{target},
				"server::${server}::${source}::device::${device}::path"                => $anvil->data->{server}{$server}{$source}{device}{$device}{path},
			}});
		
		}
	}
	die;
	
	# Pull out other devices
	foreach my $device (sort {$a cmp $b} keys %{$server_xml->{devices}->[0]})
	{
		next if $device eq "emulator";
		next if $device eq "channel";
		print "Device: [$device] -> [".$server_xml->{devices}->[0]->{$device}."] (".@{$server_xml->{devices}->[0]->{$device}}."))\n";
		
		foreach my $hash_ref (@{$server_xml->{devices}->[0]->{$device}})
		{
			# video, memballoon, rng and sound don't have type.
			my $type = defined $hash_ref->{type} ? $hash_ref->{type} : "";
			print "- Type: [$type]\n";
			#print Dumper $hash_ref;
			if ($type)
			{
				
			}
		}
	}
	
	die;
	
	return(0);
}

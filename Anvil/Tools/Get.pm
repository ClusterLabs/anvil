package Anvil::Tools::Get;
# 
# This module contains methods used to handle access to frequently used data. 
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Encode;
use JSON;
use Net::Netmask;
use Text::Diff;
use UUID::Tiny qw(:std);
use String::ShellQuote;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Get.pm";

### Methods;
# anvil_from_switch
# anvil_name_from_uuid
# anvil_version
# available_resources
# bridges
# cgi
# cpu_flags
# date_and_time
# domain_name
# free_memory
# host_from_ip_address
# host_name
# host_name_from_uuid
# host_uuid_from_name
# host_type
# host_uuid
# kernel_release
# load_average
# md5sum
# os_type
# server_from_switch
# server_uuid_from_name
# switches
# trusted_hosts
# uptime
# users_home
# uuid
# virsh_list_net
# virsh_list_os
# _salt
# _wrap_to

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Get

Provides all methods related to getting access to frequently used data.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Get->X'. 
 # 
 # Example using 'date_and_time()';
 my $date = $anvil->Get->date_and_time({...});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		HOST	=>	{
			UUID	=>	"",
		},
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

=head2 anvil_from_switch

This takes a C<< switches::anvil >> switch, which could be a name or UUID, and tries to find the associated Anvil!. If/when found, C<< switches::anvil_uuid >> and C<< switches::anvil_name >> are set accordingly.

If no match is found, two empty strings are returned. If it is found, the Anvil! name is returned first, and the Anvil! UUID is returned after. If there is a problemm C<< !!error!! >> is returned.

Parameters;

=head3 anvil (optional, required, optional if 'switches::anvil' used if set)

This is the Anvil! name or UUID that we're looking for. 

=cut
sub anvil_from_switch
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->anvil_from_switch()" }});
	
	my $anvil_string = defined $parameter->{anvil} ? $parameter->{anvil} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_string => $anvil_string,
	}});
	
	if ((not $anvil_string) && ($anvil->data->{switches}{'anvil'}))
	{
		$anvil_string = $anvil->data->{switches}{'anvil'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_string => $anvil_string }});
	}
	if (not $anvil_string)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->anvil_from_switch()", parameter => "anvil" }});
		return("!!error!!", "");
	}
	
	$anvil->Database->get_anvils({debug => $debug});
	$anvil->data->{switches}{anvil_name} = "" if not exists $anvil->data->{switches}{anvil_name};
	$anvil->data->{switches}{anvil_uuid} = "" if not exists $anvil->data->{switches}{anvil_uuid};
	if (exists $anvil->data->{anvils}{anvil_uuid}{$anvil_string})
	{
		# Found it by UUID.
		$anvil->data->{switches}{anvil_name} = $anvil->data->{anvils}{anvil_uuid}{$anvil_string}{anvil_name};
		$anvil->data->{switches}{anvil_uuid} = $anvil_string;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"switches::anvil_name" => $anvil->data->{switches}{anvil_name},
			"switches::anvil_uuid" => $anvil->data->{switches}{anvil_uuid},
		}});
	}
	elsif (exists $anvil->data->{anvils}{anvil_name}{$anvil_string})
	{
		$anvil->data->{switches}{anvil_name} = $anvil_string;
		$anvil->data->{switches}{anvil_uuid} = $anvil->data->{anvils}{anvil_name}{$anvil_string}{anvil_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"switches::anvil_name" => $anvil->data->{switches}{anvil_name},
			"switches::anvil_uuid" => $anvil->data->{switches}{anvil_uuid},
		}});
	}
	
	return($anvil->data->{switches}{anvil_name}, $anvil->data->{switches}{anvil_uuid});
}


=head2 anvil_name_from_uuid

This takes a Anvil! UUID and returns the Anvil! name (as recorded in the C<< anvils >> table). If the entry is not found, an empty string is returned. If there is a problem, C<< !!error!! >> will be returned.

Parameters;

=head3 anvil_uuid (required)

This is the C<< anvils >> -> C<< anvil_uuid >> to translate into the Anvil! name.

=cut
sub anvil_name_from_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->anvil_name_from_uuid()" }});
	
	my $anvil_name = "";
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid,
	}});
	
	if (not $anvil_uuid)
	{
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		
		if (not $anvil_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->anvil_name_from_uuid()", parameter => "server_name" }});
			return("!!error!!");
		}
	}
	
	my $query = "
SELECT 
    anvil_name 
FROM 
    anvils 
WHERE 
    anvil_uuid = ".$anvil->Database->quote($anvil_uuid).";
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count == 1)
	{
		# Found it
		$anvil_name = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
	return($anvil_name);
}


=head2 anvil_version

This reads to C<< VERSION >> file of a local or remote machine. If the version file isn't found, C<< 0 >> is returned. 

This also reads the main C<< anvil.sql >> schema file and parses 

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
# NOTE: the version is set in anvil.spec by sed'ing the release and arch onto anvil.version in anvil-core's %post
sub anvil_version
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->anvil_version()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# The variables that will store the versions.
	my $anvil_version  = 0;
	my $schema_version = 0;
	my $schema_body    = "";
	
	# Is this a local call or a remote call?
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		$anvil_version = $anvil->Storage->read_file({file => $anvil->data->{path}{configs}{'anvil.version'}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_version => $anvil_version }});
		
		# Did we actually read a version?
		if ($anvil_version eq "!!error!!")
		{
			$anvil_version = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { anvil_version => $anvil_version }});
		}
		
		# Now read in the SQL schema
		$schema_body = $anvil->Storage->read_file({file => $anvil->data->{path}{sql}{'anvil.sql'}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_version => $anvil_version }});
		
		# Did we actually read a version?
		if ($schema_body eq "!!error!!")
		{
			$schema_version = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { schema_version => $schema_version }});
		}
	}
	else
	{
		# Remote call. If we're running as the apache user, we need to read the cached version for 
		# the peer. otherwise, after we read the version, will write the cached version.
		my $user              = getpwuid($<);
		my $anvil_cache_file  = $anvil->data->{path}{directories}{anvil}."/anvil.".$target.".version";
		my $schema_cache_file = $anvil->data->{path}{directories}{anvil}."/anvil.".$target.".schema";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_cache_file  => $anvil_cache_file, 
			schema_cache_file => $schema_cache_file, 
			user              => $user,
		}});
		if (($user eq "apache") or ($user eq "striker-ui-api"))
		{
			# Try to read the local cached version.
			if (-e $anvil_cache_file)
			{
				# Read it in.
				$anvil_version = $anvil->Storage->read_file({file => $anvil_cache_file});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_version => $anvil_version }});
			}
			if (-e $schema_cache_file)
			{
				# Read it in.
				$schema_body = $anvil->Storage->read_file({file => $schema_cache_file});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_version => $anvil_version }});
			}
		}
		else
		{
			foreach my $file ($anvil->data->{path}{configs}{'anvil.version'}, $anvil->data->{path}{sql}{'anvil.sql'})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
				my $shell_call = "
if [ -e ".$file." ];
then
    cat ".$file.";
else
   echo 0;
fi;
";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
				my ($file_body, $error, $return_code) = $anvil->Remote->call({
					debug       => $debug, 
					shell_call  => $shell_call, 
					target      => $target,
					port        => $port, 
					password    => $password,
					remote_user => $remote_user, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					file_body => $file_body,
					error     => $error,
				}});
				
				if ($file eq $anvil->data->{path}{configs}{'anvil.version'})
				{
					$anvil_version = $file_body;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_version => $anvil_version }});
				}
				else
				{
					$schema_body = $file_body;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { schema_body => $schema_body }});
				}
				
				# Create/Update the cache file.
				if ($file_body)
				{
					my $update_cache  = 0;
					my $old_file_body = "";
					my $cache_file    = $file eq $anvil->data->{path}{configs}{'anvil.version'} ? $anvil_cache_file : $schema_cache_file;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cache_file => $cache_file }});
					if (-e $cache_file)
					{
						$old_file_body = $anvil->Storage->read_file({file => $cache_file});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							old_file_body => $old_file_body,
							file_body     => $file_body, 
						}});
						my $difference = diff \$old_file_body, \$file_body, { STYLE => 'Unified' };
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { difference => $difference }});
						if ($difference)
						{
							# update needed
							$update_cache = 1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_cache => $update_cache }});
						}
					}
					else
					{
						# Cache file needs to be created.
						$update_cache = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_cache => $update_cache }});
					}
					
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_cache => $update_cache }});
					if ($update_cache)
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0437", variables => { 
							target => $target, 
							file   => $cache_file, 
						}});
						$anvil->Storage->write_file({
							debug     => $debug, 
							backup    => 0,
							file      => $cache_file, 
							body      => $file_body,
							mode      => "0666",
							overwrite => 1,
						});
					}
				}
			}
		}
	}
	
	# Clear off any newline.
	$anvil_version =~ s/\n//gs;
	
	# Pull the schema version out of the schema body.
	foreach my $line (split/\n/, $schema_body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /-- SchemaVersion: (\d+\.\d+\.\d+)/)
		{
			$schema_version = $1; 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { schema_version => $schema_version }});
			last;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_version  => $anvil_version, 
		schema_version => $schema_version,
	}});
	return($anvil_version, $schema_version);
}


=head2 available_resources

This method looks at the resource used and available on the nodes in a given Anvil! system. The DR's resources are also ready, but don't contribute to the "least available" values.

If either node has no data in the C<< scan_hardware >> table, this method will return with C<< !!no_data!! >>. Callers should abort on this value and remind the user that ScanCore needs to run on both nodes.

Data is store in the following hashes;

 anvil_resources::<anvil_uuid>::cpu::cores
 anvil_resources::<anvil_uuid>::cpu::threads
 anvil_resources::<anvil_uuid>::cpu::available
 anvil_resources::<anvil_uuid>::ram::available
 anvil_resources::<anvil_uuid>::ram::allocated
 anvil_resources::<anvil_uuid>::ram::hardware
 anvil_resources::<anvil_uuid>::bridges::<bridge_name>::on_nodes
 anvil_resources::<anvil_uuid>::storage_group::<storage_group_uuid>::group_name
 anvil_resources::<anvil_uuid>::storage_group::<storage_group_uuid>::vg_size
 anvil_resources::<anvil_uuid>::storage_group::<storage_group_uuid>::free_size

All sizes are stored in bytes.

Parameters;

=head3 anvil_uuid (required)

This is the Anvil! UUID for which we're getting available resources from.

=cut
sub available_resources
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->available_resources()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid=> $anvil_uuid,
	}});
	
	if (not $anvil_uuid)
	{
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		
		if (not $anvil_uuid)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->available_resources()", parameter => "anvil_uuid" }});
			return("!!error!!");
		}
	}
	
	if (exists $anvil->data->{anvil_resources}{$anvil_uuid})
	{
		delete $anvil->data->{anvil_resources}{$anvil_uuid};
	}
	
	# Load hosts and network bridges. This loads Anvil! data as well
	$anvil->Database->get_hosts({debug => $debug});
	$anvil->Database->get_bridges({debug => $debug});
	$anvil->Database->get_lvm_data({debug => $debug});

	# Get the details.
	my $anvil_name      = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name};
	my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
	my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:anvil_name'      => $anvil_name,
		's2:node1_host_uuid' => $node1_host_uuid, 
		's3:node2_host_uuid' => $node2_host_uuid, 
	}});
	
	# This will store the available resources based on the least of the nodes.
	$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores}     = 0;
	$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads}   = 0;
	$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available} = 0;
	$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{hardware}  = 0;
	foreach my $host_uuid ($node1_host_uuid, $node2_host_uuid)
	{
		my $this_is = "node1";
		if ($host_uuid eq $node2_host_uuid)
		{
			$this_is = "node2";
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_is => $this_is }});
		
		# Start collecting data.
		my $host_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_uuid => $host_uuid,
			host_name => $host_name, 
		}});
		
		# Gather bridge data.
		foreach my $bridge_name (sort {$a cmp $b} keys %{$anvil->data->{bridges}{bridge_host_uuid}{$host_uuid}{bridge_name}})
		{
			my $bridge_uuid = $anvil->data->{bridges}{bridge_host_uuid}{$host_uuid}{bridge_name}{$bridge_name}{bridge_uuid};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				bridge_uuid => $bridge_uuid,
				bridge_name => $bridge_name, 
			}});
			
			$anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on}{$host_uuid} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::bridges::${bridge_name}::on::${host_uuid}" => $bridge_name, 
			}});
		}
		
		# Get the CPU and RAM data 
		my $query = "
SELECT 
    scan_hardware_cpu_cores, 
    scan_hardware_cpu_threads, 
    scan_hardware_cpu_model, 
    scan_hardware_ram_total 
FROM 
    scan_hardware 
WHERE 
    scan_hardware_host_uuid = ".$anvil->Database->quote($host_uuid)."
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		if (not $count)
		{
			# Looks like scan-hardware hasn't run. We can't use this host yet.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0236", variables => { host_name => $host_name }});
			return('!!no_data!!');
		}
		
		my $scan_hardware_cpu_cores   = $results->[0]->[0];
		my $scan_hardware_cpu_threads = $results->[0]->[1];
		my $scan_hardware_cpu_model   = $results->[0]->[2];
		my $scan_hardware_ram_total   = $results->[0]->[3];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_hardware_cpu_cores   => $scan_hardware_cpu_cores,
			scan_hardware_cpu_threads => $scan_hardware_cpu_threads, 
			scan_hardware_cpu_model   => $scan_hardware_cpu_model, 
			scan_hardware_ram_total   => $scan_hardware_ram_total." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_hardware_ram_total}).")", 
		}});
		
		$anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{cpu}{cores}     = $scan_hardware_cpu_cores;
		$anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{cpu}{threads}   = $scan_hardware_cpu_threads;
		$anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{cpu}{model}     = $scan_hardware_cpu_model;
		$anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{ram}{hardware}  = $scan_hardware_ram_total;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::host_uuid::${host_uuid}::cpu::cores"     => $anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{cpu}{cores},
			"anvil_resources::${anvil_uuid}::host_uuid::${host_uuid}::cpu::threads"   => $anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{cpu}{threads},
			"anvil_resources::${anvil_uuid}::host_uuid::${host_uuid}::cpu::model"     => $anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{cpu}{model},
			"anvil_resources::${anvil_uuid}::host_uuid::${host_uuid}::ram::hardware"  => $anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{ram}{hardware}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{host_uuid}{$host_uuid}{ram}{hardware}}).")",
		}});
		
		# How many cores?
		if ((not $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores}) or 
		    ($scan_hardware_cpu_cores < $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores}))
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores} = $scan_hardware_cpu_cores;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::cpu::cores" => $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores},
			}});
		}
		if ((not $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads}) or 
		    ($scan_hardware_cpu_threads < $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads}))
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads} = $scan_hardware_cpu_threads;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::cpu::threads" => $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads},
			}});
		}
		
		# If there are less threads than cores, set the cores to be equal to threads.
		if ($anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads} < $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores})
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads} = $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::cpu::threads" => $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads},
			}});
		}
		
		# How many can be allocated to a single VM?
		$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available} = $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::cpu::available" => $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available},
		}});
		if ($anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available} <= 4)
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available} -= 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::cpu::available" => $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available},
			}});
		}
		else
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available} -= 2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::cpu::available" => $anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{available},
			}});
		}
		
		if ((not $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}) or 
		    ($scan_hardware_ram_total < $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{hardware}))
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available} = $scan_hardware_ram_total;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::ram::available" => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}}).")",
			}});
		}
	}
	
	# Read in the amount of RAM allocated to servers and subtract it from the RAM available.
	$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated} =  0;
	$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{hardware}  = $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available};
	
	my $query = "
SELECT 
    server_name, 
    server_ram_in_use 
FROM 
    servers 
WHERE 
    server_anvil_uuid =  ".$anvil->Database->quote($anvil_uuid)." 
AND 
    server_state      != 'DELETED' 
ORDER BY 
    server_name ASC;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $server_name = $row->[0];
		my $ram_in_use  = $row->[1];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:server_name" => $server_name,
			"s2:ram_in_use"  => $ram_in_use." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $ram_in_use}).")",
		}});
		
		$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated} += $ram_in_use;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::ram::allocated" => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated}}).")",
		}});
	}

	# Check if the reserved RAM is overriden by the config
	my $default_reserved = 8192;
	if (not exists $anvil->data->{anvil_resources}{ram}{reserved})
	{
		$anvil->data->{anvil_resources}{ram}{reserved} = $default_reserved;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			default_reserved                 => $default_reserved, 
			"anvil_resources::ram::reserved" => $anvil->data->{anvil_resources}{ram}{reserved},
		}});
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"anvil_resources::ram::reserved" => $anvil->data->{anvil_resources}{ram}{reserved},
	}});
	
	$anvil->data->{anvil_resources}{ram}{reserved} =~ s/,//g;
	$anvil->data->{anvil_resources}{ram}{reserved} =~ s/\s//g;
	$anvil->data->{anvil_resources}{ram}{reserved} =~ s/MiB$//i;
	$anvil->data->{anvil_resources}{ram}{reserved} =~ s/MB$//i;
	$anvil->data->{anvil_resources}{ram}{reserved} =~ s/M$//i;
	if ((not $anvil->data->{anvil_resources}{ram}{reserved}) or ($anvil->data->{anvil_resources}{ram}{reserved} =~ /\D/))
	{
		# Invalid value.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0151", variables => { 
			was => $anvil->data->{anvil_resources}{ram}{reserved}, 
			set => $default_reserved,
		}});
		$anvil->data->{anvil_resources}{ram}{reserved} = $default_reserved;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::ram::reserved" => $anvil->data->{anvil_resources}{ram}{reserved},
		}});
	}
	
	#anvil::<anvil_uuid>::resources::ram::reserved
	if (exists $anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved})
	{
		$anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved} =~ s/,//g;
		$anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved} =~ s/\s//g;
		$anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved} =~ s/MiB$//i;
		$anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved} =~ s/MB$//i;
		$anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved} =~ s/M$//i;
		if ((not $anvil->data->{anvil_resources}{ram}{reserved}) or ($anvil->data->{anvil_resources}{ram}{reserved} =~ /\D/))
		{
			# Invalid value.
			my $anvil_name = $anvil->Get->anvil_name_from_uuid({anvil_uuid => $anvil_uuid});
			   $anvil_name = $anvil_uuid if not $anvil_name;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0152", variables => { 
				anvil => $anvil_name,
				was   => $anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved}, 
				set   => $anvil->data->{anvil_resources}{ram}{reserved},
			}});
			$anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved} = $anvil->data->{anvil_resources}{ram}{reserved};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil::${anvil_uuid}::resources::ram::reserved" => $anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved},
			}});
		}
	
		if ($anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved})
		{
			$anvil->data->{anvil_resources}{ram}{reserved} = $anvil->data->{anvil}{$anvil_uuid}{resources}{ram}{reserved};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::ram::reserved" => $anvil->data->{anvil_resources}{ram}{reserved},
			}});
		}
	}
	
	my $ram_reserved = $anvil->Convert->human_readable_to_bytes({
		base2 => 1,
		size  => $anvil->data->{anvil_resources}{ram}{reserved}." MiB", 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ram_reserved => $ram_reserved." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $ram_reserved}).")",
	}});
	if (($ram_reserved eq "!!error!!") or 
	    (not $ram_reserved)            or 
	    ($ram_reserved < (2**30))      or 
	    ($ram_reserved > $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{hardware}))
	{
		# The reserved RAM is invalid, so reset it to 8 GiB
		$ram_reserved = 8589934592;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			ram_reserved => $ram_reserved." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $ram_reserved}).")",
		}});
	}

	# Take 4 GiB or what was provided by the config off the available RAM for the host
	$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{reserved}   = $ram_reserved;
	$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available} -= $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{reserved};
	$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available} -= $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"anvil_resources::${anvil_uuid}::ram::allocated" => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{allocated}}).")",
		"anvil_resources::${anvil_uuid}::ram::reserved"  => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{reserved}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{reserved}}).")",
		"anvil_resources::${anvil_uuid}::ram::available" => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}}).")",
	}});
	
	if ($anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available} < 0)
	{
		$anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available} = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::ram::available" => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}}).")",
		}});
	}
	
	# process bridges now
	foreach my $bridge_name (sort {$a cmp $b} keys %{$anvil->data->{anvil_resources}{$anvil_uuid}{bridges}})
	{
		$anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on_nodes} = 0;
		if (($anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on}{$node1_host_uuid}) && 
		    ($anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on}{$node2_host_uuid}))
		{
			$anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on_nodes} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"anvil_resources::${anvil_uuid}::bridges::${bridge_name}::on_nodes" => $anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on_nodes},
			}});
		}
	}
	
	# Get storage group data now.
	foreach my $storage_group_uuid (keys %{$anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}})
	{
		$anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{group_name} = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::storage_group::${storage_group_uuid}::group_name" => $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{group_name},
		}});
		
		my $node1_vg_size = 0;
		my $node1_vg_free = 0;
		my $node2_vg_size = 0;
		my $node2_vg_free = 0;
		if (exists $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$node1_host_uuid})
		{
			$node1_vg_size = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$node1_host_uuid}{vg_size};
			$node1_vg_free = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$node1_host_uuid}{vg_free};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				node1_vg_size => $node1_vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node1_vg_size}).")",
				node1_vg_free => $node1_vg_free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node1_vg_free}).")",
			}});
		}
		if (exists $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$node2_host_uuid})
		{
			$node2_vg_size = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$node2_host_uuid}{vg_size};
			$node2_vg_free = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$node2_host_uuid}{vg_free};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				node2_vg_size => $node2_vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node2_vg_size}).")",
				node2_vg_free => $node2_vg_free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node2_vg_free}).")",
			}});
		}
		
		$anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{vg_size}   = $node2_vg_size < $node1_vg_size ? $node2_vg_size : $node1_vg_size;
		$anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{free_size} = $node2_vg_free < $node1_vg_free ? $node2_vg_free : $node1_vg_free;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::storage_group::${storage_group_uuid}::vg_size"   => $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{vg_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{vg_size}}).")",
			"anvil_resources::${anvil_uuid}::storage_group::${storage_group_uuid}::free_size" => $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{free_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{free_size}}).")",
		}});
		
		# Make it easy to sort by group name
		my $storage_group_name                                                                                       = $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{group_name};
		   $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group_name}{$storage_group_name}{storage_group_uuid} = $storage_group_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"anvil_resources::${anvil_uuid}::storage_group_name::${storage_group_name}::storage_group_uuid" => $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group_name}{$storage_group_name}{storage_group_uuid},
		}});
	}
	
	# This re-connects files available on each Anvil! node.
	$anvil->Database->get_files({debug => 2});
	$anvil->Database->get_file_locations({debug => 2});
	
	return(0);
}


=head2 bridges

This finds a list of bridges on the host. Bridges that are found are stored in;

* <host>::network::bridges::bridge::<bridge_name>::found                            = 1
* <host>::network::bridges::bridge::<bridge_name>::flags                            = [array of flags]
* <host>::network::bridges::bridge::<bridge_name>::connected_interface::<interface> = 1
* <host>::network::bridges::bridge::<bridge_name>::<variable>                       = [array reference or string variable]
* <host>::network::bridges::interface::<interface_name>::<variable>                 = [array reference or string variable]

Where 'host' is C<< Get->short_host_name() >>. 

This method takes no parameters.

=cut
sub bridges
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->bridges()" }});
	
	my $shell_call = $anvil->data->{path}{exe}{bridge}." -json -details link show";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	# Delete any previously known data
	my $host = $anvil->Get->short_host_name();
	if (exists $anvil->data->{$host}{network}{bridges})
	{
		delete $anvil->data->{$host}{network}{bridges};
	};
	
	local $@;
	my $bridge_data = "";
	my $json        = JSON->new->allow_nonref;
	my $test        = eval { $bridge_data = $json->decode($output); };
	if (not $test)
	{
		# JSON parse failed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "error_0140", variables => { 
			json  => $output,
			error => $@,
		}});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0519"});
		
		# NOTE: This is not design to be normally used. It was created as a stop-gap while waiting 
		#       for resolution on: https://bugzilla.redhat.com/show_bug.cgi?id=1868467
		my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{bridge}." -details link show"});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code, 
		}});
		my $interface = "";
		my $type      = "";
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if ($line =~ /^\d+:\s+(.*?):/)
			{
				$interface = $1;
				$type      = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					interface => $interface,
					type      => $type, 
				}});
				
				$anvil->data->{$host}{network}{bridges}{bridge}{$interface}{found} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"${host}::network::bridges::bridge::${interface}::found" => $anvil->data->{$host}{network}{bridges}{bridge}{$interface}{found}, 
				}});
			}
			if ($interface)
			{
				if (($line =~ /master (.*?) /) or ($line =~ /master (.*?)$/))
				{
					my $master_bridge = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { master_bridge => $master_bridge }});
					
					if ($master_bridge eq $interface)
					{
						# This is the bridge
						$type = "bridge";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { type => $type }});
					}
					else
					{
						# It's an interface, store it under the bridge.
						$type                                                                                            = "interface";
						$anvil->data->{$host}{network}{bridges}{bridge}{$master_bridge}{connected_interface}{$interface} = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							type                                                                                     => $type,
							"${host}::network::bridges::bridge::${master_bridge}::connected_interface::${interface}" => $anvil->data->{$host}{network}{bridges}{bridge}{$master_bridge}{connected_interface}{$interface}, 
						}});
					}
				}
			}
			
			if (($interface) && ($type))
			{
				if ($line =~ /<(.*?)>/)
				{
					my $flags = $1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { flags => $flags }});
					
					my $i = 0;
					foreach my $flag (split/,/, $flags)
					{
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { flag => $flag }});
						push @{$anvil->data->{$host}{network}{bridges}{$type}{$interface}{flags}}, $flag;
					}
				}
			}
			if ($line =~ /^\s+(.*?)$interface/)
			{
				# Break out settings.
				my $values = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'values' => $values }});
				
				my $variable = "";
				foreach my $word (split/ /, $values)
				{
					if (($variable) && (($word eq "on") or ($word eq "off")))
					{
						my $value = $word;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
						
						$anvil->data->{$host}{network}{bridges}{$type}{$interface}{$variable} = $value eq "on" ? "true" : "false";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"${host}::network::bridges::${type}::${interface}::${variable}" => $anvil->data->{$host}{network}{bridges}{$type}{$interface}{$variable}, 
						}});
						$variable = "";
					}
					else
					{
						$variable = $word;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable => $variable }});
					}
				}
			}
		}
	}
	else
	{
		foreach my $hash_ref (@{$bridge_data})
		{
			# If the ifname and master are the same, it's a bridge.
			my $type          = "interface";
			my $interface     = $hash_ref->{ifname};
			my $master_bridge = $hash_ref->{master};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				interface     => $interface, 
				master_bridge => $master_bridge, 
			}});
			
			$anvil->data->{$host}{network}{bridges}{bridge}{$master_bridge}{found} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"${host}::network::bridges::bridge::${master_bridge}::found" => $anvil->data->{$host}{network}{bridges}{bridge}{$master_bridge}{found}, 
			}});
			if ($interface eq $master_bridge)
			{
				$type = "bridge";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { type => $type }});
			}
			else
			{
				# Store this interface under the bridge.
				$anvil->data->{$host}{network}{bridges}{bridge}{$master_bridge}{connected_interface}{$interface} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"${host}::network::bridges::bridge::${master_bridge}::connected_interface::${interface}" => $anvil->data->{$host}{network}{bridges}{bridge}{$master_bridge}{connected_interface}{$interface}, 
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
					$anvil->data->{$host}{network}{bridges}{$type}{$interface}{$key} = [];
					foreach my $value (sort {$a cmp $b} @{$hash_ref->{$key}})
					{
						push @{$anvil->data->{$host}{network}{bridges}{$type}{$interface}{$key}}, $value;
					}
					for (my $i = 0; $i < @{$anvil->data->{$host}{network}{bridges}{$type}{$interface}{$key}}; $i++)
					{
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"${host}::network::bridges::${type}::${interface}::${key}->[$i]" => $anvil->data->{$host}{network}{bridges}{$type}{$interface}{$key}->[$i], 
						}});
					}
				}
				else
				{
					$anvil->data->{$host}{network}{bridges}{$type}{$interface}{$key} = $hash_ref->{$key};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"${host}::network::bridges::${type}::${interface}::${key}" => $anvil->data->{$host}{network}{bridges}{$type}{$interface}{$key}, 
					}});
				}
			}
		}
	}
	
	# Summary of found bridges.
	foreach my $interface (sort {$a cmp $b} keys %{$anvil->data->{$host}{network}{bridges}{bridge}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"${host}::network::bridges::bridge::${interface}::found" => $anvil->data->{$host}{network}{bridges}{bridge}{$interface}{found}, 
		}});
	}
	
	return(0);
}

=head2 cgi

This reads in the CGI variables passed in by a form or URL.

This method takes no parameters.

=cut
sub cgi
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->cgi()" }});
	
	# This will store all of the CGI variables.
	$anvil->data->{sys}{cgi_string} = "?";
	
	# Needed to read in passed CGI variables
	my $cgi = CGI->new();
	
	my $cgis      = [];
	my $cgi_count = 0;
	# Get the list of parameters coming in, if possible, 
	if (exists $cgi->{param})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'cgi->{param}' => $cgi->{param} }});
		foreach my $variable (sort {$a cmp $b} keys %{$cgi->{param}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable => $variable }});
			push @{$cgis}, $variable;
		}
	}
	
	$cgi_count = @{$cgis};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cgi_count => $cgi_count }});
	
	# If we don't have at least one variable, we're done.
	if ($cgi_count < 1)
	{
		return(0);
	}
	
	# NOTE: Later, we will have another array for handling file uploads.
	# Now read in the variables.
	foreach my $variable (sort {$a cmp $b} @{$cgis})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable => $variable }});
		
		$anvil->data->{cgi}{$variable}{value}       = "";
		$anvil->data->{cgi}{$variable}{mime_type}   = "string";
		$anvil->data->{cgi}{$variable}{file_handle} = "";
		$anvil->data->{cgi}{$variable}{file_name}   = "";
		$anvil->data->{cgi}{$variable}{alert}       = 0;	# This is set if a sanity check fails
		
		# This is a special CGI key for download files (upload from the user's perspective)
		if ($variable eq "upload_file")
		{
			if (not $cgi->upload('upload_file'))
			{
				# Empty file passed, looks like the user forgot to select a file to upload.
				$anvil->Log->entry({level => 2, key => "log_0242", file => $THIS_FILE, line => __LINE__});
			}
			else
			{
				   $anvil->data->{cgi}{upload_file}{file_handle} = $cgi->upload('upload_file');
				my $file                                         = $anvil->data->{cgi}{upload_file}{file_handle};
				   $anvil->data->{cgi}{upload_file}{file_name}   = $file;
				   $anvil->data->{cgi}{upload_file}{mime_type}   = $cgi->uploadInfo($file)->{'Content-Type'};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					variable                                => 'upload_file',
					"cgi::${variable}::file_handle"         => $anvil->data->{cgi}{upload_file}{file_handle},
					"cgi::${variable}::file_handle->handle" => $anvil->data->{cgi}{upload_file}{file_handle}->handle,
					"cgi::${variable}::file_name"           => $anvil->data->{cgi}{upload_file}{file_name},
					"cgi::${variable}::mime_type"           => $anvil->data->{cgi}{upload_file}{mime_type},
					"cgi->upload('upload_file')"            => $cgi->upload('upload_file'),
					"cgi->upload('upload_file')->handle"    => $cgi->upload('upload_file')->handle,
				}});
			}
		}
		
		if (defined $cgi->param($variable))
		{
			# Make this UTF8 if it isn't already.
			if (Encode::is_utf8($cgi->param($variable)))
			{
				$anvil->data->{cgi}{$variable}{value} = $cgi->param($variable);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cgi::${variable}::value" => $anvil->data->{cgi}{$variable}{value} }});
			}
			else
			{
				$anvil->data->{cgi}{$variable}{value} = Encode::decode_utf8($cgi->param($variable));
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cgi::${variable}::value" => $anvil->data->{cgi}{$variable}{value} }});
			}
			
			# Append to 'sys::cgi_string', so long as the variable doesn't have 'passwd' or 'password' in it.
			if (($variable !~ /password/) && ($variable !~ /passwd/))
			{
				$anvil->data->{sys}{cgi_string} .= "$variable=".$anvil->data->{cgi}{$variable}{value}."&";
			}
		}
	}
	
	# This is a pretty way of displaying the passed-in CGI variables. It loops through all we've got and
	# sorts out the longest variable name. Then it loops again, appending '.' to shorter ones so that 
	# everything is lined up in the logs. This almost always prints, save for log level 0.
	if ($anvil->Log->level >= 1)
	{
		my $longest_variable = 0;
		foreach my $variable (sort {$a cmp $b} keys %{$anvil->data->{cgi}})
		{
			next if $anvil->data->{cgi}{$variable} eq "";
			if (length($variable) > $longest_variable)
			{
				$longest_variable = length($variable);
			}
		}
		
		# Now loop again.
		foreach my $variable (@{$cgis})
		{
			next if $anvil->data->{cgi}{$variable} eq "";
			my $difference   = $longest_variable - length($variable);
			my $say_value    = "value";
			if ($difference == 0)
			{
				# Do nothing
			}
			elsif ($difference == 1) 
			{
				$say_value .= " ";
			}
			elsif ($difference == 2) 
			{
				$say_value .= "  ";
			}
			else
			{
				my $dots      =  $difference - 2;
				   $say_value .= " ";
				for (1 .. $dots)
				{
					$say_value .= ".";
				}
				$say_value .= " ";
			}
			# This is always '1' as the passed-in variables are what we want to see.
			my $censored_value = $anvil->data->{cgi}{$variable}{value};
			if ((($variable =~ /passwd/) or ($variable =~ /password/)) && (not $anvil->Log->secure))
			{
				# This is a password and we're not logging sensitive data, obfuscate it.
				$censored_value = $anvil->Words->string({key => "log_0186"});
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cgi::${variable}::$say_value" => $censored_value,
			}});
		}
	}
	
	# Clear the last &
	$anvil->data->{sys}{cgi_string} =~ s/&$//;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::cgi_string" => $anvil->data->{sys}{cgi_string} }});
	
	return(0);
}


=head2 cpu_flags

This parses C<< scan_hardware_cpu_flags >> and stores it by host. The flags are stored in the hash;

* cpu_flags::<host_uuid>::flag::<flag> = 1

This method takes no parameters.

=cut
sub cpu_flags
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->cpu_flags()" }});
	
	if (not exists $anvil->data->{hosts}{host_uuid})
	{
		$anvil->Database->get_hosts({debug => $debug});
	}
	
	if (exists $anvil->data->{cpu_flags})
	{
		delete $anvil->data->{cpu_flags};
	}
	
	my $query = "
SELECT 
    scan_hardware_host_uuid, 
    scan_hardware_cpu_flags 
FROM 
    scan_hardware
ORDER BY 
    scan_hardware_host_uuid ASC
;
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	foreach my $row (@{$results})
	{
		my $scan_hardware_host_uuid = $row->[0];
		my $scan_hardware_cpu_flags = $row->[1];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_hardware_host_uuid => $scan_hardware_host_uuid, 
			scan_hardware_cpu_flags => $scan_hardware_cpu_flags, 
		}});
		
		foreach my $flag (split/\s+/, $scan_hardware_cpu_flags)
		{
			next if not $flag;
			$anvil->data->{cpu_flags}{$scan_hardware_host_uuid}{flag}{$flag} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cpu_flags::${scan_hardware_host_uuid}::flag::${flag}" => $anvil->data->{cpu_flags}{$scan_hardware_host_uuid}{flag}{$flag}, 
			}});
		}
	}
	
	return(0);
}


=head2 date_and_time

This method returns the date and/or time using either the current time, or a specified unix time.

NOTE: This only returns times in 24-hour notation.

=head2 Parameters;

=head3 date_only (optional)

If set, only the date will be returned (in C<< yyyy/mm/dd >> format).

=head3 file_name (optional)

When set, the date and/or time returned in a string more useful in file names. Specifically, it will replace spaces with 'C<< _ >>' and 'C<< : >>' and 'C<< / >>' for 'C<< - >>'. This will result in a string in the format like 'C<< yyyy-mm-dd_hh-mm-ss >>'.

=head3 offset (optional)

If set to a signed number, it will add or subtract the number of seconds from the 'C<< use_time >>' before processing.

=head3 use_time (optional)

This can be set to a unix timestamp. If it is not set, the current time is used.

=head3 time_only (optional)

If set, only the time will be returned (in C<< hh:mm:ss >> format).

=head3 use_utc (optional)

If set, C<< gmtime >> is used instead of C<< localtime >>. The effect of this is that GMTime (greenwhich mean time, UTC-0) is used instead of the local system's time zone.

=cut
sub date_and_time
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $offset    = defined $parameter->{offset}    ? $parameter->{offset}    : 0;
	my $use_time  = defined $parameter->{use_time}  ? $parameter->{use_time}  : time;
	my $use_utc   = defined $parameter->{use_utc}   ? $parameter->{use_utc}   : 0;
	my $file_name = defined $parameter->{file_name} ? $parameter->{file_name} : 0;
	my $time_only = defined $parameter->{time_only} ? $parameter->{time_only} : 0;
	my $date_only = defined $parameter->{date_only} ? $parameter->{date_only} : 0;
	
	### NOTE: This is used too early for normal error handling.
	# Are things sane?
	if ($use_time =~ /D/)
	{
		warn "Get->date_and_time() was called with 'use_time' set to: [$use_time]. Only a unix timestamp is allowed.\n";
		$anvil->nice_exit({exit_code => 1});
	}
	if ($offset =~ /D/)
	{
		warn "Get->date_and_time() was called with 'offset' set to: [$offset]. Only real number is allowed.\n";
		$anvil->nice_exit({exit_code => 1});
	}
	
	# Do my initial calculation.
	my $return_string = "";
	my $time          = {};
	my $adjusted_time = $use_time + $offset;
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - adjusted_time: [$adjusted_time]\n";
	
	# Get the date and time pieces
	if ($use_utc)
	{
		($time->{sec}, $time->{min}, $time->{hour}, $time->{mday}, $time->{mon}, $time->{year}, $time->{wday}, $time->{yday}, $time->{isdst}) = gmtime($adjusted_time);
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{sec}: [".$time->{sec}."], time->{min}: [".$time->{min}."], time->{hour}: [".$time->{hour}."], time->{mday}: [".$time->{mday}."], time->{mon}: [".$time->{mon}."], time->{year}: [".$time->{year}."], time->{wday}: [".$time->{wday}."], time->{yday}: [".$time->{yday}."], time->{isdst}: [".$time->{isdst}."]\n";
	}
	else
	{
		($time->{sec}, $time->{min}, $time->{hour}, $time->{mday}, $time->{mon}, $time->{year}, $time->{wday}, $time->{yday}, $time->{isdst}) = localtime($adjusted_time);
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{sec}: [".$time->{sec}."], time->{min}: [".$time->{min}."], time->{hour}: [".$time->{hour}."], time->{mday}: [".$time->{mday}."], time->{mon}: [".$time->{mon}."], time->{year}: [".$time->{year}."], time->{wday}: [".$time->{wday}."], time->{yday}: [".$time->{yday}."], time->{isdst}: [".$time->{isdst}."]\n";
	}
	
	# Process the raw data
	$time->{pad_hour} = sprintf("%02d", $time->{hour});
	$time->{mon}++;
	$time->{pad_min}  = sprintf("%02d", $time->{min});
	$time->{pad_sec}  = sprintf("%02d", $time->{sec});
	$time->{year}     = ($time->{year} + 1900);
	$time->{pad_mon}  = sprintf("%02d", $time->{mon});
	$time->{pad_mday} = sprintf("%02d", $time->{mday});
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{pad_hour}: [".$time->{pad_hour}."], time->{pad_min}: [".$time->{pad_min}."], time->{pad_sec}: [".$time->{pad_sec}."], time->{year}: [".$time->{year}."], time->{pad_mon}: [".$time->{pad_mon}."], time->{pad_mday}: [".$time->{pad_mday}."], time->{mon}: [".$time->{mon}."]\n";
	
	# Now, the date and time separator depends on if 'file_name' is set.
	my $date_separator  = $file_name ? "-" : "/";
	my $time_separator  = $file_name ? "-" : ":";
	my $space_separator = $file_name ? "_" : " ";
	if ($time_only)
	{
		$return_string = $time->{pad_hour}.$time_separator.$time->{pad_min}.$time_separator.$time->{pad_sec};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	elsif ($date_only)
	{
		$return_string = $time->{year}.$date_separator.$time->{pad_mon}.$date_separator.$time->{pad_mday};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	else
	{
		$return_string = $time->{year}.$date_separator.$time->{pad_mon}.$date_separator.$time->{pad_mday}.$space_separator.$time->{pad_hour}.$time_separator.$time->{pad_min}.$time_separator.$time->{pad_sec};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	
	return($return_string);
}


=head2 domain_name

This returns the domain name portion of the local system's host name. That is to say, the host name after the first C<< . >>. If there is no domain portion, nothing is returned.

This method takes no parameters.

=cut
sub domain_name
{
	### NOTE: This method doesn't offer logging.
	my $self  = shift;
	my $anvil = $self->parent;
	
	my $domain_name =  $anvil->Get->host_name;
	   $domain_name =~ s/^.*?\.//;
	   $domain_name =  "" if not defined $domain_name;
	
	return($domain_name);
}


=head2 host_from_ip_address

This takes an IP address and looks for the host that has the IP. If the given IP is not in the database (or was but is deleted now), an empty string is returned. Otherwise, the host name and host UUID are returned.

 my ($host_uuid, $host_name) = $anvil->Get->host_from_ip_address({ip_address => "10.201.10.1"});

Parameters;

=head3 host_from_ip_address (required) 

This is the IP address being converted.

=cut
sub host_from_ip_address
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->host_from_ip_address()" }});
	
	my $host_uuid  = "";
	my $host_name  = "";
	my $ip_address = defined $parameter->{ip_address} ? $parameter->{ip_address} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ip_address => $ip_address,
	}});
	
	if (not $ip_address)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->host_from_ip_address()", parameter => "ip_address" }});
		return($host_uuid, $host_name);
	}
	if (not $anvil->Validate->ipv4({ip => $ip_address}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "warning_0010", variables => { ip_address => $ip_address }});
		return($host_uuid, $host_name);
	}
	
	my $query = "
SELECT 
    a.host_uuid, 
    a.host_name 
FROM 
    hosts a, 
    ip_addresses b 
WHERE 
    a.host_uuid          =  b.ip_address_host_uuid 
AND 
    a.host_key           != 'DELETED' 
AND 
    b.ip_address_note    != 'DELETED' 
AND 
    b.ip_address_address =  ".$anvil->Database->quote($ip_address)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count == 1)
	{
		# Found it
		$host_uuid = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$host_name = defined $results->[0]->[1] ? $results->[0]->[1] : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			host_uuid => $host_uuid,
			host_name => $host_name,
		}});
	}
	
	return($host_uuid, $host_name);
}


=head2 host_name

This returns the full host name for the local machine.

Parameters;

=head3 refresh (optional, default '0')

If set to C<< 1 >>, and if C<< sys::host_name >>, the cached value will be ignored and the hostname will be queried directly.

=cut
sub host_name
{
	### NOTE: This method doesn't offer logging.
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	
	my $refresh   = defined $parameter->{refresh} ? $parameter->{refresh} : 0;
	my $host_name = "";
	
	# NOTE: Don't use 'ENV{HOSTNAME}'! It lags behind changes made by 'hostnamectl'.
	if ((not $refresh) && ($anvil->data->{sys}{host_name}))
	{
		# We have an environment variable, so use it.
		$host_name = $anvil->data->{sys}{host_name};
	}
	else
	{
		# The environment variable isn't set. Call 'hostnamectl' on the command line.
		($host_name, my $return_code) = $anvil->System->call({debug => 9999, shell_call => $anvil->data->{path}{exe}{hostnamectl}." --static"});
		if ($return_code)
		{
			# We can't trust the hostname. This could be an error like "Could not get property: 
			# Refusing activation, D-Bus is shutting down.". Try reading in the '/etc/hostname'
			# file instead.
			$host_name = $anvil->Storage->read_file({debug => 9999, file => $anvil->data->{path}{configs}{hostname}});
			if ($host_name eq "!!error!!")
			{
				# Failed to read the file, too. What the hell? Exit out.
				print "Failed to query the hostname using 'hostnamectl --static' and failed to read the content of: [".$anvil->data->{path}{configs}{hostname}."]. Something is very wrong, exiting.\n";
				$anvil->nice_exit({exit_code => 1});
			}
		}
		else
		{
			# Did we get a real answer? If it's "unet", the string will be emtpy.
			if (not $host_name)
			{
				# Try seeing if there is a transient hostname.
				($host_name, my $return_code) = $anvil->System->call({debug => 9999, shell_call => $anvil->data->{path}{exe}{hostnamectl}." --transient"});
				if (not $host_name)
				{
					# OK, can we get it from the 'hostname' command?
					($host_name, my $return_code) = $anvil->System->call({debug => 9999, shell_call => $anvil->data->{path}{exe}{hostname}});
					if (not $host_name)
					{
						# Failed to find the hostname at all.
						print "Failed to query the hostname using 'hostnamectl --static', 'hostnamectl --transient' or 'hostname'. Something is very wrong, exiting.\n";
						$anvil->nice_exit({exit_code => 1});
					}
				}
			}
			
			# Cache the answer
			$anvil->data->{sys}{host_name} = $host_name;
		}
	}
	
	return($host_name);
}


=head2 host_name_from_uuid

This takes a host UUID and returns the host name (as recorded in the C<< hosts >> table). If the entry is not found, an empty string is returned. If the C<< host_uuid >> is C<< NULL >>, an empty string is returned.

 my $host_name = $anvil->Get->host_name_from_uuid({host_uuid => "8da3d2fe-783a-4619-abb5-8ccae58f7bd6"});

Parameters;

=head3 host_uuid (required)

This is the C<< host_uuid >> to translate into a host name.

=cut
sub host_name_from_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->host_name_from_uuid()" }});
	
	my $host_name = "";
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	
	if ($host_uuid eq "NULL")
	{
		# No UUID.
		return($host_name);
	}
	
	my $query = "
SELECT 
    host_name 
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->Database->quote($host_uuid).";
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count == 1)
	{
		# Found it
		$host_name = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
	return($host_name);
}


=head2 host_uuid_from_name

This takes a host name and looks for a UUID from the C<< hosts >> table). If the entry is not found, an empty string is returned.

 my $host_uuid = $anvil->Get->host_uuid_from_name({host_name => "an-a02n01.alteeve.com"});

Parameters;

=head3 host_name (required)

This is the host name to translate into a C<< host_uuid >>. If an exact match isn't found, the short host name will be used to try to find a match.

=cut
sub host_uuid_from_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->host_uuid_from_name()" }});
	
	my $host_uuid = "";
	my $host_name = defined $parameter->{host_name} ? $parameter->{host_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
	
	my $short_host_name =  $host_name;
	   $short_host_name =~ s/\..*$//;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { short_host_name => $short_host_name }});
	
	# We use Database->get_hosts(), first looping for an exact match. If that fails, we'll loop again, 
	# reducing all host names to short version.
	$anvil->Database->get_hosts({debug => 2});
	
	if (exists $anvil->data->{sys}{hosts}{by_name}{$host_name})
	{
		$host_uuid = $anvil->data->{sys}{hosts}{by_name}{$host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	}
	else
	{
		foreach my $this_host_uuid (keys %{$anvil->data->{hosts}{host_uuid}})
		{
			my $this_host_name       = $anvil->data->{hosts}{host_uuid}{$this_host_uuid}{host_name};
			my $this_short_host_name = $this_host_name;
			   $this_short_host_name =~ s/\..*$//;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				this_host_name       => $this_host_name,
				this_short_host_name => $this_short_host_name, 
			}});
			
			if ($host_name eq $this_host_name)
			{
				# Found it.
				$host_uuid = $this_host_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
				last;
			}
			elsif ($short_host_name eq $this_short_host_name)
			{
				# This is probably it, but we'll keep looping to be sure.
				$host_uuid = $this_host_uuid;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	return($host_uuid);
}


=head2 free_memory

This returns, in bytes, host much free memory is available on the local system.

=cut
### TODO: Make this work on remote systems.
sub free_memory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->free_memory()" }});
	
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

=head2 host_type

This method tries to determine the host type and returns a value suitable for use is the C<< hosts >> table. Returned values are;

 striker - Striker dashboards
 node    - Anvil! nodes (active protection of VMs)
 dr      - DR Hosts (passive DR host targets)

 my $type = $anvil->Get->host_type();

First, it looks to see if C<< sys::host_type >> is set and, if so, uses that string as it is. 

If that isn't set, it then looks to see if the file C<< /etc/anvil/type.X >> exists, where C<< X >> is C<< node >>, C<< striker >> or C<< dr >>. If found, the appropriate type is returned.

If that file doesn't exist, then it then checks to see which C<< anvil-<type> >> rpm is installed. In order, it looks for C<< anvil-striker >>, then C<< anvil-node >> and finally C<< anvil-dr >>. If one of them is found, the appropriate C<< /etc/anvil/type.X >> is created.

=cut
sub host_type
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->host_type()" }});
	
	my $host_type = "";
	my $host_name = $anvil->Get->short_host_name();
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
		elsif (-e $anvil->data->{path}{configs}{'type.striker'})
		{
			$host_type = "striker";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		elsif (-e $anvil->data->{path}{configs}{'type.dr'})
		{
			$host_type = "dr";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
		}
		else
		{
			# Last gasp here is to use 'rpm' to see which RPMs are installed. If we find one, 
			# we'll touch 'type.X' file
			my $check_types = {
				'striker' => 1,
				'node'    => 1,
				'dr'      => 1,
			};
			foreach my $rpm ("anvil-striker", "anvil-node", "anvil-dr")
			{
				my ($output, $return_code) = $anvil->System->call({
					debug      => $debug, 
					shell_call => $anvil->data->{path}{exe}{rpm}." -q ".$rpm,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
				if ($return_code eq "0")
				{
					# Found out what we are.
					if ($output =~ /anvil-(.*?)-/)
					{
						$host_type = $1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
						
						$check_types->{$host_type} = 0;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "check_types->{$host_type}" => $check_types->{$host_type} }});
					}
					
					my $key  = "type.".$host_type;
					my $file = $anvil->data->{path}{configs}{$key};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						key  => $key,
						file => $file, 
					}});
					# If we have a file and we're root, touch to the file.
					if (($< == 0) or ($> == 0))
					{
						foreach my $test_type (sort {$a cmp $b} keys %{$check_types})
						{
							my $test_key  = "type.".$test_type;
							my $test_file = $anvil->data->{path}{configs}{$test_key};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"check_types->{$test_type}" => $check_types->{$test_type},
								test_file                   => $test_file,
							}});
							
							if (($check_types->{$test_type}) && (-e $test_file))
							{
								# Remove the old type.
								$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0497", variables => { file => $test_file }});
								unlink $test_file;
							}
						}
						if ($file)
						{
							my $error = $anvil->Storage->write_file({
								debug => $debug,
								body  => "",
								file  => $file,
							});
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
						}
					}
					last;
				}
			}
		}
	}
	
	return($host_type);
}

=head2 host_uuid

This returns the local host's system UUID (as reported by 'dmidecode'). If the host UUID isn't available, and the program is not running with root priviledges, C<< #!error!# >> is returned.

 print "This host's UUID: [".$anvil->Get->host_uuid."]\n";

It is possible to override the local UUID, though it is not recommended.

 $anvil->Get->host_uuid({set => "720a0509-533d-406b-8fc1-03aca3e75fa7"})

=cut
sub host_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->host_uuid()" }});
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		set          => $set,
		'HOST::UUID' => $anvil->{HOST}{UUID}, 
	}});
	
	if ($set)
	{
		$anvil->{HOST}{UUID} = $set;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "HOST::UUID" => $anvil->{HOST}{UUID} }});
	}
	elsif (not $anvil->{HOST}{UUID})
	{
		# Read /etc/anvil/host.uuid if it exists. If not, and if we're root, we'll create that file 
		# using the UUID from dmidecode.
		my $uuid = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			'$<'                    => $<, 
			'$>'                    => $>,
			'path::data::host_uuid' => $anvil->data->{path}{data}{host_uuid}, 
		}});
		if (-e $anvil->data->{path}{data}{host_uuid})
		{
			# Read the UUID in
			$uuid = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{data}{host_uuid}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		}
		elsif (($< == 0) or ($> == 0))
		{
			# Create the UUID file.
			($uuid, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{dmidecode}." --string system-uuid"});
			$uuid = lc($uuid);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				uuid        => $uuid, 
				return_code => $return_code,
			}});
		}
		else
		{
			# Host UUID file doesn't exist and I'm Not running as root, I'm done.
			# We're done.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0187"});
			return("#!error!#");
		}
		
		if ($anvil->Validate->uuid({uuid => $uuid}))
		{
			$anvil->{HOST}{UUID} = $uuid;
			if (not -e $anvil->data->{path}{data}{host_uuid})
			{
				### TODO: This will need to set the proper SELinux context.
				# Apache run scripts can't call the system UUID, so we'll write it to a text
				# file.
				$anvil->Storage->write_file({
					debug     => $debug, 
					file      => $anvil->data->{path}{data}{host_uuid}, 
					body      => $uuid,
					user      => "striker-ui-api", 
					group     => "striker-ui-api",
					mode      => "0666",
					overwrite => 0,
				});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0011", variables => { file => $anvil->data->{path}{data}{host_uuid} }});
			}
		}
		else
		{
			# Bad UUID.
			$anvil->{HOST}{UUID} = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "HOST::UUID" => $anvil->{HOST}{UUID} }});
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0134", variables => { uuid => $uuid }});
			return("#!error!#");
		}
	}
	
	# We'll also store the host UUID in a variable.
	if ((not $anvil->data->{sys}{host_uuid}) && ($anvil->{HOST}{UUID}))
	{
		$anvil->data->{sys}{host_uuid} = $anvil->{HOST}{UUID};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "HOST::UUID" => $anvil->{HOST}{UUID} }});
	return($anvil->{HOST}{UUID});
}


=head2 kernel_release

This returns the kernel release (same output as C<<uname -r>>) on the local or remote host. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the kernel release. If this is not set, the local system's kernel release is checked.

=cut
sub kernel_release
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "System->kernel_release()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target      => $target, 
		port        => $port, 
		remote_user => $remote_user, 
		password    => $anvil->Log->is_secure($password), 
	}});
	
	my $kernel_release = "";
	my $return_code    = "";
	my $shell_call     = $anvil->data->{path}{exe}{uname}." --kernel-release";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call
		($kernel_release, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			kernel_release => $kernel_release, 
			return_code    => $return_code,
		}});
	}
	else
	{
		# Remote call
		($kernel_release, my $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			kernel_release => $kernel_release, 
			error          => $error,
			return_code    => $return_code,
		}});
		
		if ($return_code)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "err", key => "error_0356", variables => {
				target      => $target, 
				output      => $kernel_release, 
				return_code => $return_code,
			}});
			$kernel_release = "!!error!!";
		}
	}
	
	return($kernel_release);
}


=head2 load_average

This reads in the current load average and stores the data in the following hashes;

* loads::load_average::one_minute
* loads::load_average::five_minute
* loads::load_average::ten_minute
* loads::load_average::running_processes
* loads::load_average::total_processes

This tracks the total number of interrupts since boot.

* loads::interrupts::total

This tracks the total PIDs, running PIDs and most importantly, blocked processes.

* loads::processes::total
* loads::processes::running
* loads::processes::blocked

This tracks the percentage time processes spent in certain states (see iostat);

* loads::load_percent::user
* loads::load_percent::steal
* loads::load_percent::idle
* loads::load_percent::nice
* loads::load_percent::system
* loads::load_percent::iowait

This tracks the total time spent on CPU loads, IO wait and IRQ data. Per-CPU core is tracked in matching hashes, with C<< average >> being replaced by C<< loads::cpu::core::<core_number>::X >>.

* loads::cpu::average::user_mode
* loads::cpu::average::user_mode_nice
* loads::cpu::average::system_mode
* loads::cpu::average::idle_tasks
* loads::cpu::average::io_wait
* loads::cpu::average::hard_irq
* loads::cpu::average::soft_irq

This is the number of IO operations in progress. When IOs in progress is non-zero, the weighted time (in 1/100ths of a second), doing those IOs.

* loads::storage::<device_name>::ios_currently_in_progress
* loads::storage::<device_name>::weighted_time_spent_doing_ios

This data comes from C<< /proc/loadavg >>, C<< /proc/stat >>, and C<< /proc/diskstats >>. For more information on these values, please see the relevant kernel documentation.

If there is a problem, C<< 1 >> is returned and the data in the hash will be blank, or stale. If the load averge data is collected successfully, C<< 0 >> is returned.

This method takes no parameters.

=cut
sub load_average
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->load_average()" }});
	
	my $load_average =  $anvil->Storage->read_file({debug => $debug, file => '/proc/loadavg' });
	   $load_average =~ s/\n//;
	   $load_average =~ s/\r//;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { load_average => $load_average }});
	
	my $stat = $anvil->Storage->read_file({debug => $debug, file => '/proc/stat' });
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'stat' => $stat }});
	
	my $diskstats = $anvil->Storage->read_file({debug => $debug, file => '/proc/diskstats' });
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { diskstats => $diskstats }});
	
	my $shell_call = $anvil->data->{path}{exe}{iostat}." -c -o JSON ";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($iostat_json, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { iostat_json => $iostat_json, return_code => $return_code }});
	
	local $@;
	my $iostat_data = "";
	my $json        = JSON->new->allow_nonref;
	my $test        = eval { $iostat_data = $json->decode($iostat_json); };
	if (not $test)
	{
		# JSON parse failed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "error_0140", variables => { 
			json  => $iostat_json,
			error => $@,
		}});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0519"});
		return(1);
	}
	
	if (exists $anvil->data->{load_average})
	{
		delete $anvil->data->{load_average};
	}
	
	if (($load_average eq "!!error!!") or ($stat eq "!!error!!"))
	{
		return(0);
	}
	
	# Process Load Average
	my ($one_minute, $five_minute, $ten_minute, $processes, $last_pid) = (split/\s+/, $load_average);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:one_minute'  => $one_minute,
		's2:five_minute' => $five_minute, 
		's3:ten_minute'  => $ten_minute, 
		's4:processes'   => $processes, 
		's5:last_pid'    => $last_pid, 
	}});
	
	my ($running_processes, $total_processes) = (split/\//, $processes);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:running_processes' => $running_processes, 
		's2:total_processes'   => $total_processes, 
	}});
	
	$anvil->data->{loads}{load_percent}{user}     = $iostat_data->{sysstat}{hosts}->[0]->{statistics}->[0]->{'avg-cpu'}{user};
	$anvil->data->{loads}{load_percent}{steal}    = $iostat_data->{sysstat}{hosts}->[0]->{statistics}->[0]->{'avg-cpu'}{steal};
	$anvil->data->{loads}{load_percent}{idle}     = $iostat_data->{sysstat}{hosts}->[0]->{statistics}->[0]->{'avg-cpu'}{idle};
	$anvil->data->{loads}{load_percent}{nice}     = $iostat_data->{sysstat}{hosts}->[0]->{statistics}->[0]->{'avg-cpu'}{nice};
	$anvil->data->{loads}{load_percent}{'system'} = $iostat_data->{sysstat}{hosts}->[0]->{statistics}->[0]->{'avg-cpu'}{'system'};
	$anvil->data->{loads}{load_percent}{iowait}   = $iostat_data->{sysstat}{hosts}->[0]->{statistics}->[0]->{'avg-cpu'}{iowait};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:loads::load_percent::user'   => $anvil->data->{loads}{load_percent}{user}."%", 
		's2:loads::load_percent::steal'  => $anvil->data->{loads}{load_percent}{steal}."%", 
		's3:loads::load_percent::idle'   => $anvil->data->{loads}{load_percent}{idle}."%", 
		's4:loads::load_percent::nice'   => $anvil->data->{loads}{load_percent}{nice}."%", 
		's5:loads::load_percent::system' => $anvil->data->{loads}{load_percent}{'system'}."%", 
		's6:loads::load_percent::iowait' => $anvil->data->{loads}{load_percent}{iowait}."%", 
	}});
	
	$anvil->data->{loads}{load_average}{one_minute}        = $one_minute;
	$anvil->data->{loads}{load_average}{five_minute}       = $five_minute;
	$anvil->data->{loads}{load_average}{ten_minute}        = $ten_minute;
	$anvil->data->{loads}{load_average}{running_processes} = $running_processes;
	$anvil->data->{loads}{load_average}{total_processes}   = $total_processes;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:loads::load_average::one_minute'        => $anvil->data->{loads}{load_average}{one_minute}, 
		's2:loads::load_average::five_minute'       => $anvil->data->{loads}{load_average}{five_minute}, 
		's3:loads::load_average::ten_minute'        => $anvil->data->{loads}{load_average}{ten_minute}, 
		's4:loads::load_average::running_processes' => $anvil->data->{loads}{load_average}{running_processes}, 
		's5:loads::load_average::total_processes'   => $anvil->data->{loads}{load_average}{total_processes}, 
	}});
	
	### NOTE: "jiffy" = 1/100 second on x86
	# Process diskstats
	foreach my $line (split/\n/, $diskstats)
	{
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		### NOTE: Much of these values are not useful for us yet, as they need to be tracked over 
		###       time to see any useful patterns. It's all parsed though, for ease of future use.
		# See https://www.kernel.org/doc/Documentation/admin-guide/iostats.rst
		my ($major_number, 
		    $minor_number, 
		    $device_name, 
		    $reads_completed_successfully,	# Since boot
		    $reads_merged, 			# How often adjacent reads are merged before being passed to the IO driver
		    $sectors_read, 			# This is the total number of sectors read successfully.
		    $time_spent_reading, 		# This is the total number of milliseconds spent by all reads
		    $writes_completed, 			# Since boot
		    $writes_merged, 			# How often adjacent writes are merged before being passed to the IO driver
		    $sectors_written, 			# This is the total number of sectors written successfully
		    $time_spent_writing, 		# This is the total number of milliseconds spent by all writes
		    $ios_currently_in_progress, 	# Number of I/Os currently in progress. - This is what we care about the most
		    $time_spent_doing_ios, 		# This field increases so long as above is non-zero. counts jiffies when at least one request was started or completed. If request runs more than 2 jiffies then some I/O time might be not accounted in case of concurrent requests
		    $weighted_time_spent_doing_ios, 	# Weighted number of milliseconds spent doing I/Os. This field is incremented at each I/O start, I/O completion, I/O merge, or read of these stats by the number of I/Os in progress times the number of milliseconds spent doing I/O since the last update of this field. This can provide an easy measure of both I/O completion time and the backlog that may be accumulating.
		    $discards_completed_successfully, 	# This is the total number of discards completed successfully.
		    $discards_merged, 			# How often adjacent discards are merged before being passed to the IO driver
		    $sectors_discarded, 		# This is the total number of sectors discarded successfully
		    $time_spent_discarding, 		# This is the total number of milliseconds spent by all discards
		    $flush_requests_completed_successfully, # This is the total number of flush requests completed successfully.
		    $time_spent_flushing		# This is the total number of milliseconds spent by all flush requests.
		) = (split/\s+/, $line);
		# These require kernel 5.5+
		$flush_requests_completed_successfully = "na" if not defined $flush_requests_completed_successfully;
		$time_spent_flushing                   = "na" if not defined $time_spent_flushing;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's01:major_number'                          => $major_number,
			's02:minor_number'                          => $minor_number, 
			's03:device_name'                           => $device_name, 
			's04:reads_completed_successfully'          => $reads_completed_successfully, 
			's05:reads_merged'                          => $reads_merged, 
			's06:sectors_read'                          => $sectors_read, 
			's07:time_spent_reading'                    => $time_spent_reading,
			's08:writes_completed'                      => $writes_completed, 
			's09:writes_merged'                         => $writes_merged, 
			's10:sectors_written'                       => $sectors_written, 
			's11:time_spent_writing'                    => $time_spent_writing,
			's12:ios_currently_in_progress'             => $ios_currently_in_progress, 
			's13:time_spent_doing_ios'                  => $time_spent_doing_ios,
			's14:weighted_time_spent_doing_ios'         => $weighted_time_spent_doing_ios,
			's15:discards_completed_successfully'       => $discards_completed_successfully, 
			's16:discards_merged'                       => $discards_merged, 
			's17:sectors_discarded'                     => $sectors_discarded, 
			's18:time_spent_discarding'                 => $time_spent_discarding, 
			's19:flush_requests_completed_successfully' => $flush_requests_completed_successfully, 
			's20:time_spent_flushing'                   => $time_spent_flushing,
		}});
		
		$anvil->data->{loads}{storage}{$device_name}{ios_currently_in_progress}     = $ios_currently_in_progress;
		$anvil->data->{loads}{storage}{$device_name}{weighted_time_spent_doing_ios} = $weighted_time_spent_doing_ios;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"loads::storage::${device_name}::ios_currently_in_progress"     => $anvil->data->{loads}{storage}{$device_name}{ios_currently_in_progress},
			"loads::storage::${device_name}::weighted_time_spent_doing_ios" => $anvil->data->{loads}{storage}{$device_name}{weighted_time_spent_doing_ios},
		}});
	}
	
	# Process stat
	foreach my $line (split/\n/, $stat)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/)
		{
			# Time in jiffied handling tasks
			$anvil->data->{loads}{cpu}{average}{user_mode}      = $1;
			$anvil->data->{loads}{cpu}{average}{user_mode_nice} = $2;
			$anvil->data->{loads}{cpu}{average}{system_mode}    = $3;
			$anvil->data->{loads}{cpu}{average}{idle_tasks}     = $4;
			$anvil->data->{loads}{cpu}{average}{io_wait}        = $5;
			$anvil->data->{loads}{cpu}{average}{hard_irq}       = $6;
			$anvil->data->{loads}{cpu}{average}{soft_irq}       = $7;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:loads::cpu::average::user_mode'      => $anvil->data->{loads}{cpu}{average}{user_mode},
				's2:loads::cpu::average::user_mode_nice' => $anvil->data->{loads}{cpu}{average}{user_mode_nice},
				's3:loads::cpu::average::system_mode'    => $anvil->data->{loads}{cpu}{average}{system_mode},
				's4:loads::cpu::average::idle_tasks'     => $anvil->data->{loads}{cpu}{average}{idle_tasks},
				's5:loads::cpu::average::io_wait'        => $anvil->data->{loads}{cpu}{average}{io_wait},
				's6:loads::cpu::average::hard_irq'       => $anvil->data->{loads}{cpu}{average}{hard_irq},
				's7:loads::cpu::average::soft_irq'       => $anvil->data->{loads}{cpu}{average}{soft_irq},
			}});
		}
		elsif ($line =~ /^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/)
		{
			# Time in jiffied handling tasks
			my $cpu = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cpu => $cpu }});
			
			$anvil->data->{loads}{cpu}{core}{$cpu}{user_mode}      = $2;
			$anvil->data->{loads}{cpu}{core}{$cpu}{user_mode_nice} = $3;
			$anvil->data->{loads}{cpu}{core}{$cpu}{system_mode}    = $4;
			$anvil->data->{loads}{cpu}{core}{$cpu}{idle_tasks}     = $5;
			$anvil->data->{loads}{cpu}{core}{$cpu}{io_wait}        = $6;
			$anvil->data->{loads}{cpu}{core}{$cpu}{hard_irq}       = $7;
			$anvil->data->{loads}{cpu}{core}{$cpu}{soft_irq}       = $8;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:loads::cpu::core::${cpu}::user_mode"      => $anvil->data->{loads}{cpu}{core}{$cpu}{user_mode},
				"s2:loads::cpu::core::${cpu}::user_mode_nice" => $anvil->data->{loads}{cpu}{core}{$cpu}{user_mode_nice},
				"s3:loads::cpu::core::${cpu}::system_mode"    => $anvil->data->{loads}{cpu}{core}{$cpu}{system_mode},
				"s4:loads::cpu::core::${cpu}::idle_tasks"     => $anvil->data->{loads}{cpu}{core}{$cpu}{idle_tasks},
				"s5:loads::cpu::core::${cpu}::io_wait"        => $anvil->data->{loads}{cpu}{core}{$cpu}{io_wait},
				"s6:loads::cpu::core::${cpu}::hard_irq"       => $anvil->data->{loads}{cpu}{core}{$cpu}{hard_irq},
				"s7:loads::cpu::core::${cpu}::soft_irq"       => $anvil->data->{loads}{cpu}{core}{$cpu}{soft_irq},
			}});
		}
		elsif ($line =~ /^intr (\d+) (.*?)$/)
		{
			my $total_interrupts = $1;
			my $other_interrupts = $2;	# We might want to pull this apart later.
			$anvil->data->{loads}{interrupts}{total} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:loads::interrupts::total" => $anvil->data->{loads}{interrupts}{total},
			}});
		}
		elsif ($line =~ /^processes (\d+)$/)
		{
			$anvil->data->{loads}{processes}{total} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"loads::processes::total" => $anvil->data->{loads}{processes}{total},
			}});
		}
		elsif ($line =~ /^procs_running (\d+)$/)
		{
			$anvil->data->{loads}{processes}{running} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"loads::processes::running" => $anvil->data->{loads}{processes}{running},
			}});
		}
		elsif ($line =~ /^procs_blocked (\d+)$/)
		{
			$anvil->data->{loads}{processes}{blocked} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"loads::processes::blocked" => $anvil->data->{loads}{processes}{blocked},
			}});
		}
	}
	
	return(0);
}


=head2 md5sum

This returns the C<< md5sum >> of a given file.

Parameters;

=head3 file

This is the full or relative path to the file. If the file doesn't exist, an empty string is returned.

=cut
sub md5sum
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->md5sum()" }});
	
	my $sum = "";
	my $file = defined $parameter->{file} ? $parameter->{file} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
	
	if (-e $file)
	{
		my $shell_call = $anvil->data->{path}{exe}{md5sum}." ".$file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($return, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return, return_code => $return_code }});
		
		# split the sum off.
		$sum = ($return =~ /^(.*?)\s+$file$/)[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sum => $sum }});
	}
	
	return($sum);
}

=head2 os_type

This returns the operating system type and the system architecture as two separate string variables. This can be called on the local system, or against a remote system.

 # Run on RHEL 8, on a 64-bit system
 my ($os_type, $os_arch) = $anvil->Get->os_type();
 
 # '$os_type' holds 'rhel8'  ('rhel' or 'centos' + release version) 
 # '$os_arch' holds 'x86_64' (specifically, 'uname --hardware-platform')

If either can not be determined, C<< unknown >> will be returned.

Paramters;

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 remote_user (optional, default 'root')

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 target (optional)

If set, the os type of the target machine is determined. This must be either an IP address or a resolvable host name. 

If not set, the local system's OS type is checked.

=cut
sub os_type
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->os_type()" }});
	
	my $os_type = "unknown";
	my $os_arch = "unknown";
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target,
	}});
	
	### NOTE: Examples;
	# Red Hat Enterprise Linux release 8.0 Beta (Ootpa)
	# CentOS Stream release 8
	my $release = "";
	if ($target)
	{
		### NOTE: This can be called before 'rsync' is called, so we use 'cat'
		# Read in the /etc/redhat-release file
		($release, my $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $anvil->data->{path}{exe}{cat}." ".$anvil->data->{path}{data}{'redhat-release'}, 
			port        => $port, 
			password    => $password, 
			remote_user => $remote_user, 
			target      => $target,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			release     => $release,
			error       => $error,
			return_code => $return_code, 
		}});
	}
	else
	{
		# Local call.
		$release = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{data}{'redhat-release'}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { release => $release }});
	}
	if ($release =~ /Red Hat Enterprise Linux .* (\d+)\./)
	{
		# RHEL, with the major version number appended
		$os_type = "rhel".$1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { os_type => $os_type }});
	}
	elsif ($release =~ /CentOS Stream .*? (\d+)/)
	{
		$os_type = "centos-stream".$1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { os_type => $os_type }});
	}
	elsif ($release =~ /AlmaLinux .*? (\d+)/)
	{
		$os_type = "alma".$1;
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


=head2 server_from_switch

This takes a C<< switches::server >> switch, which could be a name or UUID, and tries to find the associated server. If/when found, C<< switches::server_uuid >> and C<< switches::server_name >> are set accordingly.

If no match is found, two empty strings are returned. If it is found, the server's name is returned first, and the server's UUID is returned after. If there is a problemm C<< !!error!! >> is returned.

Parameters;

=head4 anvil_uuid (optional)

If specified, the server will be searched for on the specified Anvil! only. If not specified, all Anvil! nodes are searched, with the first match being returned. This should only be needed in the unlikely event that two or more servers share the same name across different Anvil! systems (something that should not be possible).

=head3 server (optional, required, optional if 'switches::server' used if set)

This is the server name or UUID that we're looking for. 

=cut
sub server_from_switch
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->server_from_switch()" }});
	
	my $server_string = defined $parameter->{server}     ? $parameter->{server}     : "";
	my $anvil_uuid    = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid    => $anvil_uuid, 
		server_string => $server_string,
	}});
	
	if ((not $server_string) && ($anvil->data->{switches}{'server'}))
	{
		$server_string = $anvil->data->{switches}{'server'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_string => $server_string }});
	}
	if (not $server_string)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->server_from_switch()", parameter => "server" }});
		return("!!error!!", "");
	}
	
	$anvil->Database->get_anvils({debug => $debug});
	$anvil->Database->get_servers({debug => $debug});
	$anvil->data->{switches}{server_name} = "" if not exists $anvil->data->{switches}{server_name};
	$anvil->data->{switches}{server_uuid} = "" if not exists $anvil->data->{switches}{server_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server_string           => $server_string, 
		"switches::server_name" => $anvil->data->{switches}{server_name},
		"switches::server_uuid" => $anvil->data->{switches}{server_uuid}, 
	}});
	if (exists $anvil->data->{servers}{server_uuid}{$server_string})
	{
		# Found it by UUID.
		$anvil->data->{switches}{server_name} = $anvil->data->{servers}{server_uuid}{$server_string}{server_name};
		$anvil->data->{switches}{server_uuid} = $server_string;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"switches::server_name" => $anvil->data->{switches}{server_name},
			"switches::server_uuid" => $anvil->data->{switches}{server_uuid},
		}});
	}
	else
	{
		# If we have an anvil_uuid, see if the server exists there.
		foreach my $this_anvil_name (sort {$a cmp $b} keys %{$anvil->data->{anvils}{anvil_name}})
		{
			my $this_anvil_uuid = $anvil->data->{anvils}{anvil_name}{$this_anvil_name}{anvil_uuid};
			if (($anvil_uuid) && ($anvil_uuid ne $this_anvil_uuid))
			{
				next;
			}
			foreach my $this_server_name (sort {$a cmp $b} keys %{$anvil->data->{servers}{anvil_uuid}{$this_anvil_uuid}{server_name}})
			{
				my $this_server_uuid = $anvil->data->{servers}{anvil_uuid}{$this_anvil_uuid}{server_name}{$this_server_name}{server_uuid};
				if (($server_string eq $this_server_name) or 
				    ($server_string eq $this_server_uuid))
				{
					# Found it 
					$anvil->data->{switches}{server_name} = $this_server_name;
					$anvil->data->{switches}{server_uuid} = $this_server_uuid;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"switches::server_name" => $anvil->data->{switches}{server_name},
						"switches::server_uuid" => $anvil->data->{switches}{server_uuid},
					}});
					last;
				}
			}
		}
	}
	
	return($anvil->data->{switches}{server_name}, $anvil->data->{switches}{server_uuid});
}


=head2 server_uuid_from_name

This takes a server name and returns the server's uuid (as recorded in the C<< servers >> table). If the entry is not found, an empty string is returned. If there is a problem, C<< !!error!! >> will be returned.

Parameters;

=head3 anvil_uuid (optional)

If defined, only servers associated with the referenced Anvil! will be searched. This can help prevent situations where the same server name was used on different Anvil! systems.

=head3 server_name (required)

This is the C<< servers >> -> C<< server_name >> to translate into the server UUID.

=cut
sub server_uuid_from_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->server_uuid_from_name()" }});
	
	my $server_uuid = "";
	my $anvil_uuid  = defined $parameter->{anvil_uuid}  ? $parameter->{anvil_uuid}  : "";
	my $server_name = defined $parameter->{server_name} ? $parameter->{server_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid  => $anvil_uuid,
		server_name => $server_name, 
	}});
	
	if (not $server_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->server_uuid_from_name()", parameter => "server_name" }});
		return("!!error!!");
	}
	if ($anvil_uuid)
	{
		# Make sure the Anvil! UUID is valid. 
		my $anvil_name = $anvil->Get->anvil_name_from_uuid({debug => $debug, anvil_uuid => $anvil_uuid});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
		if ((not $anvil_name) or ($anvil_name eq "!!error!!"))
		{
			# Invalid anvil_uuid
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0162", variables => { anvil_uuid => $anvil_uuid }});
			return("!!error!!");
		}
	}
	
	my $query = "
SELECT 
    server_uuid 
FROM 
    servers 
WHERE 
    server_name = ".$anvil->Database->quote($server_name)." ";
	if ($anvil_uuid)
	{
		$query .= "
AND 
    server_anvil_uuid = ".$anvil->Database->quote($anvil_uuid)." ";
	}
	$query .= "
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count == 1)
	{
		# Found it
		$server_uuid = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
	return($server_uuid);
}


=head2 short_host_name

This returns the short host name for the machine this is running on. That is to say, the host name up to the first C<< . >>.

The method takes no parameters.

=cut
sub short_host_name
{
	### NOTE: This method doesn't offer logging.
	my $self  = shift;
	my $anvil = $self->parent;
	
	my $short_host_name =  $anvil->Get->host_name;
	   $short_host_name =~ s/\..*$//;
	
	return($short_host_name);
}


=head2 switches

This reads in the command line switches used to invoke the parent program. 

It takes no arguments, and data is stored in 'C<< $anvil->data->{switches}{x} >>', where 'x' is the switch used.

Switches in the form 'C<< -x >>' and 'C<< --x >>' are treated the same and the corresponding 'C<< $anvil->data->{switches}{x} >>' will contain '#!set!#'. 

Switches in the form 'C<< -x foo >>', 'C<< --x foo >>', 'C<< -x=foo >>' and 'C<< --x=foo >>' are treated the same and the corresponding 'C<< $anvil->data->{switches}{x} >>' will contain 'foo'. 

The switches 'C<< -v >>', 'C<< -vv >>', 'C<< -vvv >>' and 'C<< -vvvv >>' will cause the active log level to automatically change to 1, 2, 3 or 4 respectively. Passing 'C<< -V >>' will set the log level to '0'.

The switch 'C<< --log-secure >>' will enable logging of "secure" data, like passwords.

Anything after 'C<< -- >>' is treated as a raw string and is not processed. 

The switches C<< -h >>, C<< -? >> and C<< --help >> will set the C<< help >> switch to C<< #!set!# >> so that calling program knows to display it's help, if available.

Parameters

=head3 list (optional)

If set to an anonymous array, only switches in the list will be allowed. If a switch is passed that doesn't match an entry in this list, an error message is printed to STDOUT and C<< #!error!# >> is returned.. If this is set but it is not an array reference, C<< #!error!# >> is returned.

B<< NOTE >>: The always-supported switches described above are allowed regardless of the contents of the C<< list >> parameter.

=head3 man (optional)

This is the name of the man page for the calling program. If C<< --help >> and C<< man >> are set, the man page will be displayed to the user, and then exit when the program returns.

B<< NOTE >>: The always-supported switches described above are allowed regardless of the contents of the C<< list >> parameter.

=cut
### TODO: This doesn't handle quoted values, System->parse_arguments() does. Switch to using it. Note that 
###       we'll still need to process '--raw' here (or make it work there)
sub switches
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $list = defined $parameter->{list} ? $parameter->{list} : "";
	my $man  = defined $parameter->{man}  ? $parameter->{man}  : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		list => $list,
		man  => $man,
	}});
	
	if ($list)
	{
		if (ref($list) ne "ARRAY")
		{
			# No logging here. 
			return('#!error!#');
		}
		
		# Set all switches to be empty strings
		foreach my $switch (@{$list})
		{
			$anvil->data->{switches}{$switch} = "";
		}
	}
	
	my $last_argument = "";
	foreach my $argument (@ARGV)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { argument => $argument }});
		if ($last_argument eq "raw")
		{
			# Don't process anything.
			$anvil->data->{switches}{raw} .= " $argument";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"switches::raw" => $anvil->data->{switches}{raw},
			}});
		}
		elsif ($argument =~ /^-/)
		{
			# If the argument is just '--', appeand everything after it to 'raw'.
			if ($argument eq "--")
			{
				$last_argument                = "raw";
				$anvil->data->{switches}{raw} = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					last_argument   => $last_argument, 
					"switches::raw" => $anvil->data->{switches}{raw},
				}});
			}
			else
			{
				($last_argument) = ($argument =~ /^-{1,2}(.*)/)[0];
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_argument => $last_argument }});
				if ($last_argument =~ /=/)
				{
					# Break up the variable/value.
					($last_argument, my $value)              = (split /=/, $last_argument, 2);
					$anvil->data->{switches}{$last_argument} = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						value                        => $value, 
						"switches::${last_argument}" => $anvil->data->{switches}{$last_argument},
					}});
				}
				else
				{
					$anvil->data->{switches}{$last_argument} = "#!SET!#";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"switches::${last_argument}" => $anvil->data->{switches}{$last_argument},
					}});
				}
			}
		}
		else
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_argument => $last_argument }});
			if ($last_argument)
			{
				$anvil->data->{switches}{$last_argument} = $argument;
				$last_argument                           = "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					last_argument                => $last_argument, 
					"switches::${last_argument}" => $anvil->data->{switches}{$last_argument},
				}});
			}
			else
			{
				# Got a value without an argument, so just record it as '#!SET!#'.
				$anvil->data->{switches}{$argument} = "#!SET!#";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"switches::${last_argument}" => $anvil->data->{switches}{$last_argument},
				}});
			}
		}
	}
	
	# Clean up the initial space added to 'raw'.
	if ($anvil->data->{switches}{raw})
	{
		$anvil->data->{switches}{raw} =~ s/^ //;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"switches::raw" => $anvil->data->{switches}{raw},
		}});
	}
	
	# Adjust the log level if requested.
	$anvil->Log->_adjust_log_level();
	
	# Make sure 'help' is set if 'h' or '?' is set.
	if (($anvil->data->{switches}{'?'}) or ($anvil->data->{switches}{h}))
	{
		$anvil->data->{switches}{help} = "#!SET!#";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"switches::help" => $anvil->data->{switches}{help},
		}});
	}
	
	# Check for any switches not in the list, if used.
	if ($list)
	{
		my $problem = 0;
		foreach my $set_switch (sort {$a cmp $b} keys %{$anvil->data->{switches}})
		{
			next if $set_switch eq "?";
			next if $set_switch eq "age-out-database";
			next if $set_switch eq "h";
			next if $set_switch eq "help";
			next if $set_switch eq "job-uuid";
			next if $set_switch eq "log-secure";
			next if $set_switch eq "log-db-transactions";
			next if $set_switch eq "raw";
			next if $set_switch eq "resync-db";
			next if $set_switch eq "V";
			next if $set_switch eq "v";
			next if $set_switch eq "vv";
			next if $set_switch eq "vvv";
			next if $set_switch eq "vvvv";
			next if $set_switch =~ /y/i;
			next if $set_switch =~ /yes/i;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set_switch => $set_switch }});
			
			my $found = 0;
			foreach my $allowed_switch (@{$list})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { allowed_switch => $allowed_switch }});
				if ($allowed_switch eq $set_switch)
				{
					$found = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
					last;
				}
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
			if (not $found)
			{
				print "Switch '--".$set_switch."' is not recognized.\n";
				$problem = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			}
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		if ($problem)
		{
			return('#!error!#');
		}
	}
	
	if (($anvil->data->{switches}{help}) && ($man))
	{
		# Show the man page and then exit.
		system($anvil->data->{path}{exe}{man}." ".$man);
		$anvil->nice_exit({exit_code => 0});
	}
	
	# Lastly, if there's a anvil.debug file, set logging to '-vv --log-secure'
	if (-e $anvil->data->{path}{configs}{'anvil.debug'})
	{
		# Set defaults, then see if we should override from the body.
		$anvil->data->{switches}{V}            = "";
		$anvil->data->{switches}{v}            = "";
		$anvil->data->{switches}{vv}           = "#!SET!#";
		$anvil->data->{switches}{'log-secure'} = "#!SET!#";
		$anvil->data->{defaults}{'log'}{pids}  = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"switches::V"          => $anvil->data->{switches}{V},
			"switches::v"          => $anvil->data->{switches}{v},
			"switches::vv"         => $anvil->data->{switches}{vv},
			"switches::log-secure" => $anvil->data->{switches}{'log-secure'}, 
			"defaults::log::pids"  => $anvil->data->{defaults}{'log'}{pids}, 
		}});
		
		### TODO: We might want to set this?
		#$anvil->data->{sys}{database}{log_transactions} = 1;
	
		# Adjust the log level if requested.
		$anvil->Log->_adjust_log_level();
	}
	
	return(0);
}

=head2 trusted_hosts

This returns an array reference containing host UUIDs of hosts this machine should trust. Specifically, any Striker dashboards this host uses, and if this host is in an Anvil!, the peers. The array will include this host's UUID as well.

This method takes no parameters

=cut
sub trusted_hosts
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->trusted_hosts()" }});
	
	# Make sure hosts are loaded.
	if (not exists $anvil->data->{hosts}{host_uuid})
	{
		$anvil->Database->get_hosts({debug => $debug});
	}
	
	my $local_host_uuid    = $anvil->Get->host_uuid;
	my $in_anvil           = $anvil->data->{hosts}{host_uuid}{$local_host_uuid}{anvil_name};
	my $trusted_host_uuids = [$local_host_uuid];
	foreach my $host_uuid (keys %{$anvil->data->{hosts}{host_uuid}})
	{
		# Skip ourselves.
		next if $host_uuid eq $anvil->Get->host_uuid;
		
		my $host_name  = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
		my $host_type  = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_type};
		my $host_key   = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_key};
		my $anvil_name = $anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_name};
		my $anvil_uuid = $anvil->data->{hosts}{host_uuid}{$host_uuid}{anvil_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:host_uuid'  => $host_uuid, 
			's2:host_name'  => $host_name, 
			's3:host_type'  => $host_type, 
			's4:host_key'   => $host_key, 
			's5:anvil_name' => $anvil_name, 
			's6:anvil_uuid' => $anvil_uuid, 
		}});
		
		# Skip if the host_key is 'DELETED'.
		next if $host_key eq "DELETED";
		
		if ($anvil->Get->host_type eq "striker")
		{
			# Add all known machines
			push @{$trusted_host_uuids}, $host_uuid;
		}
		elsif ((($in_anvil) && ($anvil_name eq $in_anvil)) or (exists $anvil->data->{database}{$host_uuid}))
		{
			# Add dashboards we use and peers
			push @{$trusted_host_uuids}, $host_uuid;
		}
	}
	
	return($trusted_host_uuids)
}

=head2 uptime

This returns, in seconds, how long the host has been up and running for. 

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub uptime
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->uptime()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Read the file
	my $uptime = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uptime => $uptime }});
	
	# Is this a local call or a remote call?
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		$uptime = $anvil->Storage->read_file({
			debug       => $debug, 
			force_read  => 1,
			cache       => 0,
			file        => $anvil->data->{path}{proc}{uptime},
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uptime => $uptime }});
	}
	else
	{
		# Remote, we have to cat the file.
		my $shell_call = $anvil->data->{path}{exe}{cat}." ".$anvil->data->{path}{proc}{uptime};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			error       => $error,
			return_code => $return_code, 
		}});
		if (not $return_code)
		{
			$uptime = $output;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uptime => $uptime }});
		}
	}
	
	# Clean it up. We'll have gotten two numbers, the uptime in seconds (to two decimal places) and the 
	# total idle time. We only care about the int number.
	$uptime =~ s/^(\d+)\..*$/$1/;
	$uptime =~ s/\n//gs;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uptime => $uptime }});
	
	return($uptime);
}

=head2 users_home

This method takes a user's name and returns the user's home directory. If the home directory isn't found, C<< 0 >> is returned.

Parameters;

=head3 user (optional, default is the user name of the real UID (as stored in '$<'))

This is the user whose home directory you are looking for.

=cut
sub users_home
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->users_home()" }});
	
	my $home_directory = 0;
	
	my $user = defined $parameter->{user} ? $parameter->{user} : getpwuid($<);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	
	# Make sure the user is only one digit. Sometimes $< (and others) will return multiple IDs.
	if ($user =~ /^\d+ \d$/)
	{
		$user =~ s/^(\d+)\s.*$/$1/;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	}
	
	# If the user is numerical, convert it to a name.
	if ($user =~ /^\d+$/)
	{
		$user = getpwuid($user);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	}
	
	# Still don't have a name? fail...
	if ($user eq "")
	{
		# No user? No bueno...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->users_home()", parameter => "user" }});
		return($home_directory);
	}
	
	# If we've cached the answer, just return it.
	if ((exists $anvil->data->{sys}{users_home_cache}{$user}) && ($anvil->data->{sys}{users_home_cache}{$user}))
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"sys::users_home_cache::${user}" => $anvil->data->{sys}{users_home_cache}{$user},
		}});
		return($anvil->data->{sys}{users_home_cache}{$user});
	}
	
	my $body = $anvil->Storage->read_file({file => $anvil->data->{path}{data}{passwd}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
	foreach my $line (split /\n/, $body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^$user:/)
		{
			$home_directory = (split/:/, $line)[5];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { home_directory => $home_directory }});
			last;
		}
	}
	
	# Do I have the a user's $HOME now?
	if (not $home_directory)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0061", variables => { user => $user }});
	}
	
	# Cache the answer.
	$anvil->data->{sys}{users_home_cache}{$user} = $home_directory;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::users_home_cache::${user}" => $anvil->data->{sys}{users_home_cache}{$user},
	}});
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { home_directory => $home_directory }});
	return($home_directory);
}

=head2 uuid

This method returns a new v4 UUID (using 'UUID::Tiny').

Parameters;

=head3 short (optional, default '0')

This returns just the first 8 bytes of the uuid. For example, if the generated UUID is C<< 9e4b3f7c-5a98-40b6-9c34-84fdb24ddd30 >>, only C<< 9e4b3f7c >> is returned.

=cut
sub uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->uuid()" }});
	
	my $short = defined $parameter->{short} ? $parameter->{short} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		short => $short,
	}});
	
	my $uuid = create_uuid_as_string(UUID_RANDOM);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
	if ($short)
	{
		$uuid =~ s/^(\w+?)-.*$/$1/;
	}
	
	return($uuid);
}

=head2 virsh_list_net

This parses the output from C<< osinfo-query device class=net >> and populated the hash;

 osinfo::net::<name>::vendor     = Company name
 osinfo::net::<name>::vendor_id  = Vendor ID hex value
 osinfo::net::<name>::product    = Device friendly name
 osinfo::net::<name>::product_id = Product ID hex value

This method takes no parameters.

=cut
sub virsh_list_net
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->virsh_list_net()" }});
	
	my $shell_call = $anvil->data->{path}{exe}{'osinfo-query'}." device class=net";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	if (exists $anvil->data->{osinfo}{net})
	{
		delete $anvil->data->{osinfo}{net};
	}
	
	my $last_vendor = "";
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		next if $line =~ /Vendor \| Vendor ID/;
		next if $line =~ /----+----/;
		if ($line =~ /(.*?) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \| (.*)$/)
		{
			my $vendor     = $1;
			my $vendor_id  = $2;
			my $product    = $3;
			my $product_id = $4; 
			my $name       = $5;
			my $class      = $6;
			my $bus        = $7;
			my $id         = $8;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:vendor'     => $vendor, 
				's2:vendor_id'  => $vendor_id, 
				's3:product'    => $product, 
				's4:product_id' => $product_id, 
				's5:name'       => $name, 
				's6:class'      => $class, 
				's7:bus'        => $bus, 
				's8:id'         => $id, 
			}});
			
			if ($vendor)
			{
				$last_vendor = $vendor;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { last_vendor => $last_vendor }});
			}
			else
			{
				$vendor = $last_vendor;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { vendor => $vendor }});
			}
			next if $bus eq "xen";
			
			$anvil->data->{osinfo}{net}{$name}{vendor}     = $vendor;
			$anvil->data->{osinfo}{net}{$name}{vendor_id}  = $vendor_id;
			$anvil->data->{osinfo}{net}{$name}{product}    = $product;
			$anvil->data->{osinfo}{net}{$name}{product_id} = $product_id;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:osinfo::net::${name}::vendor"     => $anvil->data->{osinfo}{net}{$name}{vendor}, 
				"s2:osinfo::net::${name}::vendor_id"  => $anvil->data->{osinfo}{net}{$name}{vendor_id}, 
				"s3:osinfo::net::${name}::product"    => $anvil->data->{osinfo}{net}{$name}{product}, 
				"s4:osinfo::net::${name}::product_id" => $anvil->data->{osinfo}{net}{$name}{product_id}, 
			}});
		}
	}
	
	# If there's only a 'virtio-net', create a 'virtio' alias.
	if ((not exists $anvil->data->{osinfo}{net}{virtio}) && (exists $anvil->data->{osinfo}{net}{'virtio-net'}))
	{
		$anvil->data->{osinfo}{net}{virtio}{vendor}     = $anvil->data->{osinfo}{net}{'virtio-net'}{vendor};
		$anvil->data->{osinfo}{net}{virtio}{vendor_id}  = $anvil->data->{osinfo}{net}{'virtio-net'}{vendor_id};
		$anvil->data->{osinfo}{net}{virtio}{product}    = $anvil->data->{osinfo}{net}{'virtio-net'}{product};
		$anvil->data->{osinfo}{net}{virtio}{product_id} = $anvil->data->{osinfo}{net}{'virtio-net'}{product_id};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"s1:osinfo::net::virtio::vendor"     => $anvil->data->{osinfo}{net}{virtio}{vendor}, 
			"s2:osinfo::net::virtio::vendor_id"  => $anvil->data->{osinfo}{net}{virtio}{vendor_id}, 
			"s3:osinfo::net::virtio::product"    => $anvil->data->{osinfo}{net}{virtio}{product}, 
			"s4:osinfo::net::virtio::product_id" => $anvil->data->{osinfo}{net}{virtio}{product_id}, 
		}});
	}
	
	return(0);
}

=head2 virsh_list_os

This parses the output from C<< osinfo-query os >> and populates the hash;

 osinfo::os-list::<name>::name    = Operating System name
 osinfo::os-list::<name>::version = OS Version
 osinfo::os-list::<name>::id      = ID URL

It also loads the OSes into the strings as 'os_list_<short_name>' = OS 
 
This method takes no parameters.

=cut
sub virsh_list_os
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->virsh_list_os()" }});
	
	my $shell_call = $anvil->data->{path}{exe}{'osinfo-query'}." os";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	if (exists $anvil->data->{osinfo}{'os-list'})
	{
		delete $anvil->data->{osinfo}{'os-list'};
	}
	
	my $last_vendor = "";
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		next if $line =~ /Short ID \| Name/;
		next if $line =~ /----+----/;
		if ($line =~ /(.*?) \| (.*?) \| (.*?) \| (.*)$/)
		{
			my $short_id = $1;
			my $name     = $2;
			my $version  = $3;
			my $id       = $4;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:short_id' => $short_id, 
				's2:name'     => $name, 
				's3:version'  => $version, 
				's4:id'       => $id, 
			}});
			
			$version = "unknown" if $version eq "";
			
			$anvil->data->{osinfo}{'os-list'}{$short_id}{name}    = $name;
			$anvil->data->{osinfo}{'os-list'}{$short_id}{version} = $version;
			$anvil->data->{osinfo}{'os-list'}{$short_id}{id}      = $id;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:osinfo::os-list::${short_id}::name"    => $anvil->data->{osinfo}{'os-list'}{$short_id}{name}, 
				"s2:osinfo::os-list::${short_id}::version" => $anvil->data->{osinfo}{'os-list'}{$short_id}{version}, 
				"s3:osinfo::os-list::${short_id}::id"      => $anvil->data->{osinfo}{'os-list'}{$short_id}{id}, 
			}});
			
			my $key = "os_list_".$short_id;
			foreach my $file (sort {$a cmp $b} keys %{$anvil->data->{words}})
			{
				foreach my $language (sort {$a cmp $b} keys %{$anvil->data->{words}{$file}{language}})
				{
					$anvil->data->{words}{$file}{language}{$language}{key}{$key}{content} = $name;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"words::${file}::language::${language}::key::${key}::content" => $anvil->data->{words}{$file}{language}{$language}{key}{$key}{content}, 
					}});
				}
			}
		}
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

=head2 _salt

This generates a random salt string for use with internal Striker passwords.

=cut
sub _salt
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->_salt()" }});

	my $salt        = "";
	my $salt_length = $anvil->data->{sys}{password}{salt_length} =~ /^\d+$/ ? $anvil->data->{sys}{password}{salt_length} : 16;
	my @seed        = (" ", "~", "`", "!", "#", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "[", "}", "]", "|", ":", ";", "'", ",", "<", ".", ">", "/");
	my @alpha       = ("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");
	my $seed_count  = @seed;
	my $alpha_count = @alpha;

	my $skip_count = 0;
	for (1..$salt_length)
	{
		# We want to have a little randomness in the salt length, but not skip tooooo many times.
		if ((int(rand(20)) == 2) && ($skip_count <= 3))
		{
			$skip_count++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { skip_count => $skip_count }});
			next;
		}
		
		# What character will this string be?
		my $this_integer = int(rand(3));
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_integer => $this_integer }});
		if ($this_integer == 0)
		{
			# Inject a random digit
			$salt .= int(rand(10));
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
		}
		elsif ($this_integer == 1)
		{
			# Inject a random letter
			$salt .= $alpha[int(rand($alpha_count))];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
		}
		else
		{
			# Inject a random character
			$salt .= $seed[int(rand($seed_count))];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
		}
	}

	return($salt);
}


=head2 _wrap_to

This determines how wide the user's terminal currently is and returns that width, as well as store it in C<< sys::terminal::columns >>.

This takes no parameters. If there is a problem reading the column width, C<< 0 >> will be returned.

=cut
sub _wrap_to
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Get->_wrap_to()" }});
	
	# Get the column width
	my ($columns, $return_code) = $anvil->System->call({debug => $debug, redirect_stderr => 0, shell_call => $anvil->data->{path}{exe}{tput}." cols" });
	if ((not defined $columns) or ($columns !~ /^\d+$/))
	{
		# Set 0.
		$columns = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { columns => $columns }});
	}
	else
	{
		# Got a good value
		$anvil->data->{sys}{terminal}{columns} = $columns;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::terminal::columns' => $anvil->data->{sys}{terminal}{columns} }});
	}

	return($columns);
}

1;

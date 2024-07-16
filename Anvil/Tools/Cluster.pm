package Anvil::Tools::Cluster;
# 
# This module contains methods related to Pacemaker/pcs and clustering functions in general.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use String::ShellQuote;
use Text::Diff;
use XML::LibXML;
use XML::Simple qw(:strict);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Cluster.pm";

### Methods;
# add_server
# assemble_storage_groups
# boot_server
# check_node_status
# check_server_constraints
# check_stonith_config
# configure_logind
# delete_server
# get_fence_methods
# get_anvil_name
# get_anvil_uuid
# get_peers
# get_primary_host_uuid
# is_primary
# manage_fence_delay
# migrate_server
# parse_cib
# parse_crm_mon
# parse_quorum
# recover_server
# shutdown_server
# start_cluster
# which_node
# _set_server_constraint

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Cluster

Provides all methods related to clustering specifically (pacemaker, pcs, etc).

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Cluster->X'. 
 # 

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

=head2 add_server

This takes a server name, finds where it is running and then adds it to pacemaker. On success, C<< 0 >> is returned. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 ok_if_exists (optional, default '0')

Normally, if the server is already in the cluster, C<< !!error!! >> is returned. If this is set to C<< 1 >> and the server is already in pacemaker, we'll return C<< 0 >> instead.

=head3 server_name (required)

This is the name of the server being added.

=cut
sub add_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 2;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->add_server()" }});
	
	my $ok_if_exists = defined $parameter->{ok_if_exists} ? $parameter->{ok_if_exists} : "";
	my $server_name  = defined $parameter->{server_name}  ? $parameter->{server_name}  : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ok_if_exists => $ok_if_exists, 
		server_name  => $server_name,
	}});
	
	if (not $server_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->add_server()", parameter => "server_name" }});
		return("!!error!!");
	}
	
	# Are we in the cluster?
	my ($problem) = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		# The cluster isn't running, unable to add the server.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0211", variables => { server_name => $server_name }});
		return("!!error!!");
	}
	
	# Does the server already exist?
	if (exists $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$server_name}{type})
	{
		# The server already exists
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::cib::resources::primitive::${server_name}::type" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$server_name}{type}, 
		}});
		if ($ok_if_exists)
		{
			return(0);
		}
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0213", variables => { server_name => $server_name }});
		return("!!error!!");
	}
	
	my $local_ready = $anvil->data->{cib}{parsed}{'local'}{ready};
	my $local_name  = $anvil->data->{cib}{parsed}{'local'}{name};
	my $peer_name   = $anvil->data->{cib}{parsed}{peer}{name};
	my $peer_ready  = $anvil->data->{cib}{parsed}{peer}{ready};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		local_name  => $local_name, 
		local_ready => $local_ready, 
		peer_name   => $peer_name, 
		peer_ready  => $peer_ready, 
	}});
	
	if (not $local_ready)
	{
		# Can't add it
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0212", variables => { server_name => $server_name }});
		return("!!error!!");
	}
	
	# Find where the server is running. First, who is and where is my peer?
	$anvil->Database->get_anvils({debug => $debug});
	my $anvil_uuid      = $anvil->Cluster->get_anvil_uuid({debug => $debug});
	my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
	my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
	my $peer_host_uuid  = $anvil->Get->host_uuid() eq $node1_host_uuid ? $node2_host_uuid : $node1_host_uuid;
	my $peer_target_ip  = $anvil->Network->find_target_ip({host_uuid => $peer_host_uuid});
	my $password        = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid      => $anvil_uuid, 
		node1_host_uuid => $node1_host_uuid, 
		node2_host_uuid => $node2_host_uuid, 
		peer_host_uuid  => $peer_host_uuid, 
		peer_target_ip  => $peer_target_ip, 
		password        => $anvil->Log->is_secure($password),
	}});
	
	# Verify that the server is here or on the peer. Given they could be called at the same time that the
	# server is being provisioned, we'll wait up to 15 seconds for it to appear.
	my $waiting    = 1;
	my $wait_until = time + 15;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wait_until => $wait_until }});
	while ($waiting)
	{
		$anvil->Server->find({
			debug  => $debug,
			server => $server_name, 
		});
		$anvil->Server->find({
			debug    => $debug,
			refresh  => 0, 
			password => $password,
			target   => $peer_target_ip, 
			server   => $server_name, 
		});
		
		if (exists $anvil->data->{server}{location}{$server_name}{status})
		{
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				waiting                                       => $waiting,
				"server::location::${server_name}::status"    => $anvil->data->{server}{location}{$server_name}{status},
				"server::location::${server_name}::host_name" => $anvil->data->{server}{location}{$server_name}{host_name},
			}});
		}
		
		if (($waiting) && (time > $wait_until))
		{
			# Stop waiting.
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { waiting => $waiting }});
		}
	}
	
	# The host here is the full host name.
	my $host_name    = $anvil->Get->host_name();
	my $server_state = defined $anvil->data->{server}{location}{$server_name}{status}    ? $anvil->data->{server}{location}{$server_name}{status}    : "";
	my $server_host  = defined $anvil->data->{server}{location}{$server_name}{host_name} ? $anvil->data->{server}{location}{$server_name}{host_name} : "";
	my $target_role  = $server_host ? "started" : "stopped";	# Don't use state as it could be 'paused' if caught during initialization.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_name    => $host_name, 
		server_state => $server_state, 
		server_host  => $server_host, 
		target_role  => $target_role, 
	}});
	
	### NOTE: 'INFINITY' doesn't work in some cases, so we set 1 day timeouts. If windows can't install 
	###       an OS update in 24 hours, there's probably deeper issues.
	### 
	### NOTE: If you update this command, check that scan-cluster->check_resources() is also updated!
	### 
	### TODO: If the target_role is 'started' because the server was running, we may need to later do an 
	###       update to set it to 'stopped' after we've verified it's in the cluster below.
	my $pcs_file             = "/tmp/anvil.add_server.".$server_name.".cib";
	my $pcs_cib_file_command = $anvil->data->{path}{exe}{pcs}." cluster cib ".$pcs_file;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pcs_cib_file_command => $pcs_cib_file_command }});
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $pcs_cib_file_command});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	undef $output;
	undef $return_code;
	
	my $resource_command =  $anvil->data->{path}{exe}{pcs}." -f ".$pcs_file." resource create ".$server_name." ocf:alteeve:server ";
	   $resource_command .= "name=\"".$server_name."\" log_level=".$anvil->Log->level." log_secure=".$anvil->Log->secure." ";
	   $resource_command .= "meta allow-migrate=\"true\" target-role=\"".$target_role."\" ";
	   $resource_command .= "op monitor interval=\"60\" timeout=\"60\" ";
	   $resource_command .= "start timeout=\"60\" on-fail=\"block\" ";
	   $resource_command .= "stop timeout=\"300\" on-fail=\"block\" ";
	   $resource_command .= "migrate_to timeout=\"600\" on-fail=\"block\" ";
	   $resource_command .= "migrate_from timeout=\"600\" on-fail=\"block\"";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource_command => $resource_command }});

	($output, $return_code) = $anvil->System->call({shell_call => $resource_command});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	### NOTE: The higher the constraint score, the more preferred the host is.
	# Which sub-node do we want to run the server on?
	my $run_on_host_name = "";
	my $backup_host_name = "";
	my $target_host_uuid = $anvil->Cluster->get_primary_host_uuid({debug => 2, anvil_uuid => $anvil_uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { target_host_uuid => $target_host_uuid }});
	
	if ($target_role eq "started")
	{
		# Run on the current host.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			server_host => $server_host,
			host_name   => $host_name, 
		}});
		if ($server_host eq $host_name)
		{
			# Run here
			$run_on_host_name = $local_name;
			$backup_host_name = $peer_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				run_on_host_name => $run_on_host_name,
				backup_host_name => $backup_host_name, 
			}});
		}
		else
		{
			# Run on the 
			$run_on_host_name = $peer_name;
			$backup_host_name = $local_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				run_on_host_name => $run_on_host_name,
				backup_host_name => $backup_host_name, 
			}});
		}
	}
	else
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			target_host_uuid => $target_host_uuid,
			peer_host_uuid   => $peer_host_uuid, 
		}});
		if ($target_host_uuid eq $peer_host_uuid)
		{
			# Run on the 
			$run_on_host_name = $peer_name;
			$backup_host_name = $local_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				run_on_host_name => $run_on_host_name,
				backup_host_name => $backup_host_name, 
			}});
		}
		else
		{
			# Run here
			$run_on_host_name = $local_name;
			$backup_host_name = $peer_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				run_on_host_name => $run_on_host_name,
				backup_host_name => $backup_host_name, 
			}});
		}
	}
	
	my $constraint_command = $anvil->data->{path}{exe}{pcs}." -f ".$pcs_file." constraint location ".$server_name." prefers ".$run_on_host_name."=200 ".$backup_host_name."=100";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { constraint_command => $constraint_command }});

	undef $output;
	undef $return_code;
	($output, $return_code) = $anvil->System->call({shell_call => $constraint_command});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	# Log the contents of the PCS file
	my $pcs_body = $anvil->Storage->read_file({debug => $debug, file => $pcs_file});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pcs_body => $pcs_body }});
	
	# Commit 
	my $commit_command = $anvil->data->{path}{exe}{pcs}." cluster cib-push ".$pcs_file;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { commit_command => $commit_command }});

	($output, $return_code) = $anvil->System->call({shell_call => $commit_command});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	# Unlink the temp CIB
	unlink $pcs_file;
	
	# Reload the CIB
	($problem) = $anvil->Cluster->parse_cib({debug => 2});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	
	# Does the server already exist?
	if (not exists $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$server_name}{type})
	{
		# The server wasn't added
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0214", variables => { server_name => $server_name }});
		return("!!error!!");
	}
	
	return(0);
}


=head2 assemble_storage_groups

This method takes an Anvil! UUID and sees if there are any ungrouped LVM VGs that can be automatically grouped together.

Parameters;

=head3 anvil_uuid (required)

This is the Anvil! UUID that we're looking for ungrouped VGs in.

=cut
sub assemble_storage_groups
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 2;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->assemble_storage_groups()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid=> $anvil_uuid,
	}});
	
	if (not $anvil_uuid)
	{
		# Can we deduce the anvil_uuid?
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid=> $anvil_uuid }});
		
		if (not $anvil_uuid)
		{
			# Still no anvil_uuid
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->assemble_storage_groups()", parameter => "anvil_uuid" }});
			return("!!error!!");
		}
	}
	
	# Get the node UUIDs for this anvil.
	my $query = "
SELECT 
    anvil_name, 
    anvil_node1_host_uuid, 
    anvil_node2_host_uuid 
FROM 
    anvils 
WHERE 
    anvil_uuid = ".$anvil->Database->quote($anvil_uuid)."
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
		# Not found.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0169", variables => { anvil_uuid => $anvil_uuid }});
		return("!!error!!");
	}
	
	# Get the details.
	my $anvil_name      = $results->[0]->[0];
	my $node1_host_uuid = $results->[0]->[1];
	my $node2_host_uuid = $results->[0]->[2];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_name      => $anvil_name,
		node1_host_uuid => $node1_host_uuid, 
		node2_host_uuid => $node2_host_uuid, 
	}});
	
	# Load known storage groups.
	$anvil->Database->get_storage_group_data({debug => $debug});
	
	# Look for ungrouped VGs and see if we can group them by matching identical sizes together.
	my $hosts = [$node1_host_uuid, $node2_host_uuid];
	foreach my $host_uuid (@{$hosts})
	{
		my $this_is = $host_uuid eq $node2_host_uuid ? "node2" : "node1";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_is => $this_is }});
		
		$anvil->data->{ungrouped_vg_count}{$this_is} = 0;
		
		my $query = "
SELECT 
    scan_lvm_vg_uuid, 
    scan_lvm_vg_name, 
    scan_lvm_vg_extent_size, 
    scan_lvm_vg_size, 
    scan_lvm_vg_free, 
    scan_lvm_vg_internal_uuid 
FROM 
    scan_lvm_vgs 
WHERE 
    scan_lvm_vg_host_uuid =  ".$anvil->Database->quote($host_uuid)." 
AND 
    scan_lvm_vg_name      != 'DELETED'
ORDER BY 
    scan_lvm_vg_size ASC
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		foreach my $row (@{$results})
		{
			my $scan_lvm_vg_size          = $row->[3];
			my $scan_lvm_vg_internal_uuid = $row->[5];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				scan_lvm_vg_size          => $scan_lvm_vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_size}).")", 
				scan_lvm_vg_internal_uuid => $scan_lvm_vg_internal_uuid, 
			}});
			
			# Skip VGs that are in a group already.
			if ((exists $anvil->data->{storage_groups}{vg_uuid}{$scan_lvm_vg_internal_uuid}) && 
			    ($anvil->data->{storage_groups}{vg_uuid}{$scan_lvm_vg_internal_uuid}{storage_group_uuid}))
			{
				# Already in a group, we can skip it. We log this data for debugging reasons
				# only.
				my $storage_group_uuid        = $anvil->data->{storage_groups}{vg_uuid}{$scan_lvm_vg_internal_uuid}{storage_group_uuid};
				my $group_name                = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{group_name};
				#my $storage_group_member_uuid = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_uuid}{$scan_lvm_vg_internal_uuid}{storage_group_member_uuid};
				my $storage_group_member_uuid = $anvil->data->{storage_groups}{anvil_uuid}{$anvil_uuid}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{storage_group_member_uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					anvil_uuid                => $anvil_uuid, 
					host_uuid                 => $host_uuid, 
					storage_group_uuid        => $storage_group_uuid, 
					scan_lvm_vg_internal_uuid => $scan_lvm_vg_internal_uuid, 
					storage_group_member_uuid => $storage_group_member_uuid, 
				}});
				next;
			}
			
			$anvil->data->{ungrouped_vg_count}{$this_is}++;
			$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_uuid}          = $row->[0];
			$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_name}          = $row->[1];
			$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_extent_size}   = $row->[2];
			$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_size}          = $row->[3];
			$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_free}          = $row->[4];
			$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_internal_uuid} = $row->[5];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"ungrouped_vg_count::${this_is}"                                                => $anvil->data->{ungrouped_vg_count}{$this_is},
				"ungrouped_vgs::${scan_lvm_vg_size}::host_uuid::${host_uuid}::vg_uuid"          => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_uuid}, 
				"ungrouped_vgs::${scan_lvm_vg_size}::host_uuid::${host_uuid}::vg_name"          => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_name}, 
				"ungrouped_vgs::${scan_lvm_vg_size}::host_uuid::${host_uuid}::vg_extent_size"   => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_extent_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_extent_size}}).")", 
				"ungrouped_vgs::${scan_lvm_vg_size}::host_uuid::${host_uuid}::vg_size"          => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_size}}).")", 
				"ungrouped_vgs::${scan_lvm_vg_size}::host_uuid::${host_uuid}::vg_free"          => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_free}}).")", 
				"ungrouped_vgs::${scan_lvm_vg_size}::host_uuid::${host_uuid}::vg_internal_uuid" => $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_internal_uuid}, 
			}});
		}
	}
	
	# Find ungrouped VGs and see if we can group them. First by looking for identical sizes.
	my $reload_storage_groups = 0;
	foreach my $scan_lvm_vg_size (sort {$a cmp $b} keys %{$anvil->data->{ungrouped_vgs}})
	{
		# If there are two VGs, we can create a group.
		my $count = keys %{$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_lvm_vg_size => $scan_lvm_vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_size}).")", 
			count            => $count,
		}});
		if ($count == 2)
		{
			# Create the volume group ... group. First we need a group number
			my $storage_group_uuid = $anvil->Database->insert_or_update_storage_groups({
				debug                    => 2,
				storage_group_anvil_uuid => $anvil_uuid, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_uuid => $storage_group_uuid }});
			
			# Now add the VGs as members.
			foreach my $host_uuid (keys %{$anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}})
			{
				my $this_is = $host_uuid eq $node2_host_uuid ? "node2" : "node1";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_is => $this_is }});
				
				my $storage_group_member_vg_uuid = $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_internal_uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_member_vg_uuid => $storage_group_member_vg_uuid }});
				
				my $storage_group_member_uuid = $anvil->Database->insert_or_update_storage_group_members({
					debug                                   => 2, 
					storage_group_member_storage_group_uuid => $storage_group_uuid, 
					storage_group_member_host_uuid          => $host_uuid, 
					storage_group_member_vg_uuid            => $storage_group_member_vg_uuid,
					storage_group_member_note               => "auto-created",
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_member_uuid => $storage_group_member_uuid }});
				
				$anvil->data->{ungrouped_vg_count}{$this_is}--;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"ungrouped_vg_count::${this_is}" => $anvil->data->{ungrouped_vg_count}{$this_is},
				}});
			}
			
			# Delete this so we don't keel creating new Storage groups.
			delete $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size};
			
			# Reload storage group data
			$reload_storage_groups = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload_storage_groups => $reload_storage_groups }});
		}
	}
	
	# If there's only one VG on each node that is ungrouped, group them even though they're not the same 
	# size.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"ungrouped_vg_count::node1" => $anvil->data->{ungrouped_vg_count}{node1},
		"ungrouped_vg_count::node2" => $anvil->data->{ungrouped_vg_count}{node2},
	}});
	if (($anvil->data->{ungrouped_vg_count}{node1} == 1) && ($anvil->data->{ungrouped_vg_count}{node2} == 1))
	{
		# We do!
		my $storage_group_uuid = $anvil->Database->insert_or_update_storage_groups({
			debug                    => 2,
			storage_group_anvil_uuid => $anvil_uuid, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_uuid => $storage_group_uuid }});
		
		foreach my $host_uuid ($node1_host_uuid, $node2_host_uuid)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
		
			# I need to find the size of VG UUID without knowing it's size. 
			my $storage_group_member_vg_uuid = "";
			foreach my $scan_lvm_vg_size (sort {$a cmp $b} keys %{$anvil->data->{ungrouped_vgs}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					scan_lvm_vg_size => $scan_lvm_vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_vg_size}).")",
				}});
				if ((exists $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}) &&
				    ($anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_internal_uuid}))
				{
					# Found it.
					$storage_group_member_vg_uuid = $anvil->data->{ungrouped_vgs}{$scan_lvm_vg_size}{host_uuid}{$host_uuid}{vg_internal_uuid};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_member_vg_uuid => $storage_group_member_vg_uuid }});
				}
			}
			my $storage_group_member_uuid = $anvil->Database->insert_or_update_storage_group_members({
				debug                                   => 2, 
				storage_group_member_storage_group_uuid => $storage_group_uuid, 
				storage_group_member_host_uuid          => $host_uuid, 
				storage_group_member_vg_uuid            => $storage_group_member_vg_uuid, 
				storage_group_member_note               => "auto-created",
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { storage_group_member_uuid => $storage_group_member_uuid }});
			
			# Reload storage group data
			$reload_storage_groups = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload_storage_groups => $reload_storage_groups }});
		}
	}
	
	if ($reload_storage_groups)
	{
		$anvil->Database->get_storage_group_data({debug => $debug});
	}
	
	# Now loop through any attached DRs and add the VGs that are closest in sizes to the VGs we have in 
	# this Anvil! node.
	$anvil->Database->get_dr_links({debug => 2});
	
	return(0);
}


=head2 boot_server

This uses pacemaker to boot a server.

If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 server (required)

This is the name of the server to boot.

=head3 node (optional)

If set, a resource constraint is placed so that the server prefers one node over the other before it boots.

B<< Note >>; The method relies on pacemaker to boot the node. As such, if for some reason it decides the server can not be booted on the preferred node, it may boot on the other node. As such, this parameter does not guarantee that the server will be booted on the target node!

=head3 wait (optional, default '1')

This controls whether the method waits for the server to actually boot up before returning. By default, it will go into a loop and check every 2 seconds to see if the server is still running. Once it's found to be running, the method returns. If this is set to C<< 0 >>, the method will return as soon as the request to shut down the server is issued.

=cut
sub boot_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->boot_server()" }});
	
	my $node   = defined $parameter->{node}   ? $parameter->{node}   : "";
	my $server = defined $parameter->{server} ? $parameter->{server} : "";
	my $wait   = defined $parameter->{'wait'} ? $parameter->{'wait'} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node   => $node,
		server => $server,
		'wait' => $wait,
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->boot_server()", parameter => "server" }});
		return("!!error!!");
	}
	
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0146", variables => { server => $server }});
		return("!!error!!");
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0145", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is this node fully in the cluster?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0147", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is the server one we know of?
	if (not exists $anvil->data->{cib}{parsed}{data}{server}{$server})
	{
		# The server isn't in the pacemaker config.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0149", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is the server already running? If so, do nothing.
	my $status = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
	my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		status => $status,
		host   => $host, 
	}});
	
	if ($status eq "running")
	{
		# Nothing to do.
		if ((not $node) or ($host eq $node))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0548", variables => { server => $server }});
			return(0);
		}
		else
		{
			# It's running, but on the other node.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0059", variables => { 
				server         => $server,
				requested_node => $node,
				current_host   => $host,
			}});
			return(0);
		}
	}
	
	### TODO: If we don't have a node, pick the node with the most VMs already running (by total RAM 
	###       count)
	if ($node)
	{
		$anvil->Cluster->_set_server_constraint({
			debug          => $debug,
			server         => $server,
			preferred_node => $node,
		});
	}
	
	# Now boot the server.
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{pcs}." resource enable ".$server});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	if (not $wait)
	{
		# We're done.
		return(0);
	}
	
	# Wait now for the server to start.
	my $waiting = 1;
	while($waiting)
	{
		$anvil->Cluster->parse_cib({debug => $debug});
		my $status    = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host_name = $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			status    => $status,
			host_name => $host_name, 
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0552", variables => { server => $server }});
		if ($status eq "running")
		{
			# It's up.
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0553", variables => { 
				server    => $server,
				host_name => $host_name, 
			}});
		}
		else
		{
			# Wait a bit and check again.
			sleep 2;
		}
	}
	
	return(0);
}


=head2 check_node_status

This takes a node name (generally the short host name) and, using a C<< parse_cib >> call data (made before calling this method), the node's ready state will be checked. If the node is ready, C<< 1 >> is returned. If not, C<< 0 >> is returned. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 node_name (required)

This is the node name as used when configured in the cluster. In most cases, this is the short host name.

=cut
sub check_node_status
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->check_node_status()" }});
	
	my $node_name = defined $parameter->{node_name} ? $parameter->{node_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node_name => $node_name,
	}});
	
	if (not $node_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->get_host_from_uuid()", parameter => "host_uuid" }});
		return("!!error!!");
	}
	
	if (not exists $anvil->data->{cib}{parsed}{data}{node}{$node_name})
	{
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{in_ccm} = 0;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{crmd}   = 0;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'join'} = 0;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready}  = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::data::node::${node_name}::node_state::in_ccm" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{in_ccm},
			"cib::parsed::data::node::${node_name}::node_state::crmd"   => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{crmd},
			"cib::parsed::data::node::${node_name}::node_state::join"   => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'join'},
			"cib::parsed::data::node::${node_name}::node_state::ready"  => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready},
		}});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"cib::parsed::data::node::${node_name}::node_state::ready"  => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready},
	}});
	return($anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready});
}


=head2 check_server_constraints

This checks to see if the constraints on a server are sane. Specifically;

* If the server is on a sub-node and the peer is offline, ensure that the location constraints prefer the current host. This prevents migrations back to the old host.
* Check to see if a DRBD resource constriant was applied against a node, and the node's DRBD resource is UpToDate. If so, remove the constraint.

This method takes no parameters.

=cut
sub check_server_constraints
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->check_server_constraints()" }});
	
	# Are we a node?
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0125"});
		return("!!error!!");
	}
	
	# Are we in the cluster?
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0126"});
		return('!!error!!');
	}
	
	# Are we a full member?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, priority => "alert", key => "warning_0127"});
		return('!!error!!');
	}
	
	# Is our peer offline? If it's online, do nothing
	if ($anvil->data->{cib}{parsed}{peer}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0640"});
		return(0);
	}
	
	# Get the list of fence methods for my peer and I and make sure their configs are valid.
	my $anvil_uuid      = $anvil->Cluster->get_anvil_uuid({debug => $debug});
	my $anvil_name      = $anvil->Get->anvil_name_from_uuid({debug => $debug, anvil_uuid => $anvil_uuid });
	my $local_node_name = $anvil->data->{cib}{parsed}{'local'}{name};
	my $local_host_uuid = $anvil->Get->host_uuid();
	my $peer_node_name  = $anvil->data->{cib}{parsed}{peer}{name};
	my $peer_host_uuid  = $anvil->data->{cib}{parsed}{peer}{host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid      => $anvil_uuid, 
		anvil_name      => $anvil_name, 
		local_node_name => $local_node_name,
		local_host_uuid => $local_host_uuid, 
		peer_node_name  => $peer_node_name, 
		peer_host_uuid  => $peer_host_uuid, 
	}});
	
	foreach my $id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{constraints}{location}})
	{
		my $node_name = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node};
		my $resource  = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource};
		my $score     = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			id        => $id, 
			node_name => $node_name,
			resource  => $resource, 
			score     => $score, 
		}});
		
		$anvil->data->{location_constraint}{resource}{$resource}{node}{$node_name}{score} = $score;
		$anvil->data->{location_constraint}{resource}{$resource}{node}{$node_name}{id}    = $id;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"location_constraint::resource::${resource}::node::${node_name}::score" => $anvil->data->{location_constraint}{resource}{$resource}{node}{$node_name}{score}, 
			"location_constraint::resource::${resource}::node::${node_name}::id"    => $anvil->data->{location_constraint}{resource}{$resource}{node}{$node_name}{id}, 
		}});
	}
	
	# Higher score == preferred
	foreach my $resource (sort {$a cmp $b} keys %{$anvil->data->{location_constraint}{resource}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
		my $high_score     = 0;
		my $preferred_node = "";
		foreach my $node_name (sort {$a cmp $b} keys %{$anvil->data->{location_constraint}{resource}{$resource}{node}})
		{
			my $score = $anvil->data->{location_constraint}{resource}{$resource}{node}{$node_name}{score};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				node_name => $node_name,
				score     => $score, 
			}});
			if ($score > $high_score)
			{
				$high_score     = $score;
				$preferred_node = $node_name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					high_score     => $high_score,
					preferred_node => $preferred_node, 
				}});
			}
			
			if ($local_node_name ne $preferred_node)
			{
				# Make us the preferred node.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0641", variables => { server => $resource }});
				$anvil->Cluster->_set_server_constraint({
					debug          => $debug,
					server         => $resource,
					preferred_node => $local_node_name,
				});
			}
 		}
	}
	
	return(0);
}


=head2 check_stonith_config

This loads the running CIB and compares the fence (stonith) configuration against the records in the database. If a method needs to be updated, added or removed, this method will make those changes. As such, this method must be called on an active Anvil! node in order to work.

This method will return C<< !!error!! >> if called on a node that is not in a cluster, or called on a machine that isn't a node. Otherwise it returns C<< 1 >> if something was changed, and returns C<< 0 >> if no changes were made.

This method takes no parameters.

=cut
sub check_stonith_config
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->check_stonith_config()" }});
	
	# Are we a node?
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0298", variables => { host_type => $host_type }});
		return('!!error!!');
	}
	
	# See if we already have a parsed CIB. Generally we're called by scan-cluster, so we should.
	if (not exists $anvil->data->{cib}{parsed})
	{
		my $problem = $anvil->Cluster->parse_cib({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		if (($problem) or (not $anvil->data->{cib}{parsed}{'local'}{ready}))
		{
			# We're not in a cluster or we're not ready
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0299"});
			return('!!error!!');
		}
	}
	
	# Get the list of fence methods for my peer and I and make sure their configs are valid.
	my $anvil_uuid      = $anvil->Cluster->get_anvil_uuid({debug => $debug});
	my $anvil_name      = $anvil->Get->anvil_name_from_uuid({debug => $debug, anvil_uuid => $anvil_uuid });
	my $local_node_name = $anvil->data->{cib}{parsed}{'local'}{name};
	my $local_host_uuid = $anvil->Get->host_uuid();
	my $peer_node_name  = $anvil->data->{cib}{parsed}{peer}{name};
	my $peer_host_uuid  = $anvil->data->{cib}{parsed}{peer}{host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid      => $anvil_uuid, 
		anvil_name      => $anvil_name, 
		local_node_name => $local_node_name,
		local_host_uuid => $local_host_uuid, 
		peer_node_name  => $peer_node_name, 
		peer_host_uuid  => $peer_host_uuid, 
	}});
	
	# Load host information so that we can check for IPMI configs, if needed.
	$anvil->Database->get_hosts({debug => $debug});
	$anvil->Database->get_anvils({debug => $debug});
	$anvil->Database->get_manifests({debug => $debug});
	
	# Parse the manifest for the Anvil! so that we know what fence methods should be used.
	my $manifest_uuid = exists $anvil->data->{manifests}{manifest_name}{$anvil_name}{manifest_uuid} ? $anvil->data->{manifests}{manifest_name}{$anvil_name}{manifest_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { manifest_uuid => $manifest_uuid }});
	
	# If we don't have a manifest_uuid, abort.
	if (not $manifest_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0300", variables => { anvil_name => $anvil_name }});
		return('!!error!!');
	}
	my $problem = $anvil->Striker->load_manifest({debug => $debug, manifest_uuid => $manifest_uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0301", variables => { manifest_uuid => $manifest_uuid }});
		return('!!error!!');
	}
	
	# If we have a local host_IPMI, test it.
	my $check_ipmi_config = 1;
	if ($anvil->data->{hosts}{host_uuid}{$local_host_uuid}{host_ipmi})
	{
		my $shell_call = $anvil->data->{hosts}{host_uuid}{$local_host_uuid}{host_ipmi}." -o status";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { shell_call => $shell_call }});
		
		my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call, secure => 1});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code,
		}});
		
		if ($return_code eq "0")
		{
			# IPMI is fine.
			$check_ipmi_config = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { check_ipmi_config => $check_ipmi_config }});
		}
	}
	if ($check_ipmi_config)
	{
		# See if it needs to be configured or updated.
		$anvil->System->configure_ipmi({debug => $debug, manifest_uuid => $manifest_uuid});
	}
	
	# now lets check the stonith config.
	$anvil->Cluster->get_peers({debug => $debug});
	my $local_node_is = $anvil->data->{sys}{anvil}{i_am};
	my $peer_node_is  = $anvil->data->{sys}{anvil}{peer_is};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		local_node_is => $local_node_is, 
		peer_node_is  => $peer_node_is, 
	}});
	
	# Collecting fence data is expensive, so lets only load if needed.
	my $update_fence_data = 1;
	if ((exists $anvil->data->{sys}{fence_data_updated}) && ($anvil->data->{sys}{fence_data_updated}))
	{
		my $age = time - $anvil->data->{sys}{fence_data_updated};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
		if ($age < 86400)
		{
			# Only refresh daily.
			$update_fence_data = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_fence_data => $update_fence_data }});
		}
	}
	if ($update_fence_data)
	{
		$anvil->Striker->get_fence_data({debug => $debug});
	}
	
	### NOTE: This was copied from 'anvil-join-anvil' and modified.
	# Now I know what I have, lets see what I should have.
	my $host_name    = $anvil->Get->host_name;
	my $new_password = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_name    => $host_name, 
		new_password => $anvil->Log->is_secure($new_password), 
	}});
	
	$anvil->data->{machine}{node1}{host_name} = "";
	$anvil->data->{machine}{node1}{host_uuid} = "";
	$anvil->data->{machine}{node1}{use_delay} = 0;
	$anvil->data->{machine}{node2}{host_name} = "";
	$anvil->data->{machine}{node2}{host_uuid} = "";
	$anvil->data->{machine}{node2}{use_delay} = 0;
	if ($local_node_is eq "node1")
	{
		# We're node 1
		$anvil->data->{machine}{node1}{host_name} = $local_node_name;
		$anvil->data->{machine}{node1}{host_uuid} = $local_host_uuid;
		$anvil->data->{machine}{node2}{host_name} = $peer_node_name;
		$anvil->data->{machine}{node2}{host_uuid} = $peer_host_uuid;
	}
	else
	{
		# Our peer is node 1
		$anvil->data->{machine}{node1}{host_name} = $peer_node_name;
		$anvil->data->{machine}{node1}{host_uuid} = $peer_host_uuid;
		$anvil->data->{machine}{node2}{host_name} = $local_node_name;
		$anvil->data->{machine}{node2}{host_uuid} = $local_host_uuid;
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"machine::node1::host_name" => $anvil->data->{machine}{node1}{host_name}, 
		"machine::node1::host_uuid" => $anvil->data->{machine}{node1}{host_uuid}, 
		"machine::node2::host_name" => $anvil->data->{machine}{node2}{host_name}, 
		"machine::node2::host_uuid" => $anvil->data->{machine}{node2}{host_uuid}, 
	}});
	
	my $something_changed = {};
	my $fence_order       = {};
	my $fence_devices     = {};
	foreach my $node ("node1", "node2")
	{
		my $node_name         = $anvil->data->{machine}{$node}{host_name};
		my $host_uuid         = $anvil->data->{machine}{$node}{host_uuid};
		my $host_ipmi         = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_ipmi};
		my $ipmi_stonith_name = "ipmilan_".$node; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			node_name         => $node_name, 
			host_uuid         => $host_uuid, 
			host_ipmi         => $host_ipmi =~ /passw/ ? $anvil->Log->is_secure($host_ipmi) : $host_ipmi,
			ipmi_stonith_name => $ipmi_stonith_name, 
		}});
		
		# This will store the fence level order. If something changes
		$fence_order->{$node_name} = [];
		
		# Does this stonith method already exist?
		my $create_entry    = 0;
		my $delete_old      = 0;
		my $pcs_add_command = "";
		if ($host_ipmi)
		{
			push @{$fence_order->{$node_name}}, "fence_ipmilan";
			$fence_devices->{$node_name}{fence_ipmilan} = [$ipmi_stonith_name];
			
			# The --action switch needs to be 'pcmk_off_action' in pcs, so we convert it here.
			$host_ipmi =~ s/--action status//;
			$host_ipmi =~ s/--action/--pcmk_off_action/;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				host_ipmi => $host_ipmi =~ /passw/ ? $anvil->Log->is_secure($host_ipmi) : $host_ipmi,
			}});
			
			# We have IPMI, so we also want fence_delay for this node.
			$anvil->data->{machine}{$node}{use_delay} = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"machine::${node}::use_delay" => $anvil->data->{machine}{$node}{use_delay},
			}});
			
			# If we're here, break up the command and turn it into the pcs call.
			my $old_switches              = {};
			my ($fence_agent, $arguments) = ($host_ipmi =~ /^\/.*\/(.*?)\s+(.*)$/);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				fence_agent  => $fence_agent,
				arguments    => $arguments =~ /passw/ ? $anvil->Log->is_secure($arguments) : $arguments,
			}});
			
			   $pcs_add_command = $anvil->data->{path}{exe}{pcs}." stonith create ".$ipmi_stonith_name." ".$fence_agent." pcmk_host_list=\"".$node_name."\" ";
			my $switches        = $anvil->System->parse_arguments({arguments => $arguments});
			foreach my $switch (sort {$a cmp $b} keys %{$switches})
			{
				# Ignore 'delay', we handle that in Cluster->set_delay(); Also, 
				# convert '#!SET!#' to 'true'.
				my $value =  $switches->{$switch};
					$value =~ s/"/\\"/g;
					$value =~ s/#!SET!#/true/g;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					switch => $switch,
					value  => $value,
				}});
				next if $anvil->data->{fence_data}{$fence_agent}{switch}{$switch}{name} eq "delay";
				next if $anvil->data->{fence_data}{$fence_agent}{switch}{$switch}{name} eq "action";
				
				# Find the argument=value version.
				my $argument        =  $anvil->data->{fence_data}{$fence_agent}{switch}{$switch}{name};
				   $pcs_add_command .= $argument."=\"".$value."\" ";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					argument        => $argument,
					value           => $argument        =~ /passw/ ? $anvil->Log->is_secure($value)           : $value,
					pcs_add_command => $pcs_add_command =~ /passw/ ? $anvil->Log->is_secure($pcs_add_command) : $pcs_add_command,
				}});
				
				# Store this to see if it's different from what's already in the CIB.
				$old_switches->{$argument} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"old_switches->{$argument}" => $old_switches->{$argument},
				}});
			}
			$pcs_add_command .= "op monitor interval=\"60\"";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				pcs_add_command => $pcs_add_command =~ /passw/ ? $anvil->Log->is_secure($pcs_add_command) : $pcs_add_command,
			}});
			
			# If there's an entry in the CIB, see if it's different somehow
			if (exists $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$ipmi_stonith_name})
			{
				foreach my $argument (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$ipmi_stonith_name}{argument}})
				{
					next if $argument eq "delay";
					next if $argument eq "action";
					my $old_entry = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$ipmi_stonith_name}{argument}{$argument}{value};
					my $new_entry = exists $old_switches->{$argument} ? $old_switches->{$argument} : "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:argument'  => $argument, 
						's2:old_entry' => $old_entry,
						's3:new_entry' => $new_entry,
					}});
					
					if ($old_entry ne $new_entry)
					{
						# Changed, delete and recreate.
						$delete_old   = 1;
						$create_entry = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							delete_old   => $delete_old,
							create_entry => $create_entry,
						}});
						
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0117"});
						last;
					}
					
					# Delete the old switch.
					delete $old_switches->{$argument};
				}
				
				# Are there any old switches left?
				my $old_switch_count = keys %{$old_switches};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					delete_old       => $delete_old, 
					old_switch_count => $old_switch_count,
				}});
				if ((not $delete_old) && ($old_switch_count))
				{
					# Delete and recreate. 
					$delete_old   = 1;
					$create_entry = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						delete_old   => $delete_old,
						create_entry => $create_entry,
					}});
					
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0117"});
				}
			}
			else
			{
				# No existing entry, add a new one.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0116"});
		
				$create_entry = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_entry => $create_entry }});
			}
		}
		elsif (exists $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$ipmi_stonith_name})
		{
			# There was an existing fence config, but there's no entry in 'host_ipmi'. 
			# Remove the stonith entry.
			$delete_old = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_old => $delete_old }});
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0118"});
		}
		
		# Process the IPMI entry.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			delete_old   => $delete_old,
			create_entry => $create_entry, 
		}});
		if ($delete_old)
		{
			# Delete
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0119", variables => { device => $ipmi_stonith_name }});
			
			my $shell_call = $anvil->data->{path}{exe}{pcs}." stonith delete ".$ipmi_stonith_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code, 
			}});
			if ($return_code)
			{
				# Something went wrong.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
					shell_call  => $shell_call, 
					output      => $output, 
					return_code => $return_code, 
				}});
				return(1);
			}
		}
		if ($create_entry)
		{
			# Create.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0120", variables => { device => $ipmi_stonith_name }});
			
			my $shell_call = $pcs_add_command;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code, 
			}});
			if ($return_code)
			{
				# Something went wrong.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
					shell_call  => $shell_call, 
					output      => $output, 
					return_code => $return_code, 
				}});
				return(1);
			}
		}
		
		### Now any other fence devices.
		foreach my $device (sort {$a cmp $b} keys %{$anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$node}{fence}})
		{
			my $delete_old      = 0;
			my $create_entry    = 0;
			my $dont_create     = 0;
			my $old_switches    = {};
			my $fence_uuid      = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{fences}{$device}{uuid};
			my $fence_name      = $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_name};
			my $fence_arguments = $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_arguments};
			my $fence_agent     = $anvil->data->{fences}{fence_uuid}{$fence_uuid}{fence_agent};
			my $stonith_name    = ($fence_agent =~ /^fence_(.*)$/)[0]."_".$node."_".$fence_name; 
			my $port            = $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid}{parsed}{machine}{$node}{fence}{$device}{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				device          => $device, 
				fence_uuid      => $fence_uuid, 
				fence_name      => $fence_name, 
				fence_arguments => $fence_arguments =~ /passw/ ? $anvil->Log->is_secure($fence_arguments) : $fence_arguments,
				stonith_name    => $stonith_name, 
				port            => $port, 
			}});
			
			# We use this to tell if there are two or more entries per agent. If there
			# are, we link them later when setting up the fence levels.
			if (not exists $fence_devices->{$node_name}{$fence_agent})
			{
				push @{$fence_order->{$node_name}}, $fence_agent;
				$fence_devices->{$node_name}{$fence_agent} = [];
			}
			push @{$fence_devices->{$node_name}{$fence_agent}}, $stonith_name;
			
			# Fence arguments use 'action', but pcs deprecated it in favour of 'pcmk_off_action', so rename it.
			$fence_arguments =~ s/action=/pcmk_off_action=/;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				fence_arguments => $fence_arguments =~ /passw/ ? $anvil->Log->is_secure($fence_arguments) : $fence_arguments, 
			}});
			
			# Build the pcs command
			my $pcs_add_command = $anvil->data->{path}{exe}{pcs}." stonith create ".$stonith_name." ".$fence_agent." pcmk_host_list=\"".$node_name."\" ".$fence_arguments." ";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				pcs_add_command => $pcs_add_command =~ /passw/ ? $anvil->Log->is_secure($pcs_add_command) : $pcs_add_command, 
			}});
			while ($fence_arguments =~ /=/)
			{
				# Ignore 'delay', we handle that in Cluster->set_delay();
				my $pair               =  ($fence_arguments =~ /(\S*?=".*?")/)[0];
				   $fence_arguments    =~ s/$pair//;
				   $fence_arguments    =~ s/^\s+//;
				   $fence_arguments    =~ s/\s+$//;
				my ($argument, $value) =  ($pair =~ /(.*)="(.*)"/);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:fence_arguments' => $fence_arguments, 
					's2:pair'            => $pair =~ /passw/ ? $anvil->Log->is_secure($pair) : $pair,
					's3:argument'        => $argument,
					's4:value'           => $argument =~ /passw/ ? $anvil->Log->is_secure($value) : $value,
				}});
				
				# Ignore 'delay', we handle that in Cluster->set_delay();
				if (($argument ne "pcmk_off_action")                                           && 
				    (exists $anvil->data->{fence_data}{$fence_agent}{switch}{$argument}{name}) && 
				    ($anvil->data->{fence_data}{$fence_agent}{switch}{$argument}{name} eq "delay"))
				{
					next;
				}
				
				# Store this to see if it's different from what's already in the CIB.
				$old_switches->{$argument} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"old_switches->{$argument}" => $old_switches->{$argument},
				}});
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
			if ($port)
			{
				$port                 =~ s/"/\\"/g;
				$pcs_add_command      .= "port=\"".$port."\" ";
				$old_switches->{port} =  $port;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					pcs_add_command => $pcs_add_command =~ /passw/ ? $anvil->Log->is_secure($pcs_add_command) : $pcs_add_command, 
					"old_switches->{port}" => $old_switches->{port},
				}});
			}
			else
			{
				# If the port is required but not defined, remove this.
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_data::${fence_agent}::parameters::port::required" => $anvil->data->{fence_data}{$fence_agent}{parameters}{port}{required}, 
					port                                                     => $port,
				}});
				if (($anvil->data->{fence_data}{$fence_agent}{parameters}{port}{required}) && (not $port))
				{
					if (exists $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$stonith_name})
					{
						$delete_old = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_old => $delete_old }});
						
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0430", variables => { device => $stonith_name }});
					}
					else
					{
						# Don't create it.
						$dont_create = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { dont_create => $dont_create }});
					}
				}
			}
			$pcs_add_command .= "op monitor interval=\"60\"";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				pcs_add_command => $pcs_add_command =~ /passw/ ? $anvil->Log->is_secure($pcs_add_command) : $pcs_add_command, 
			}});
			
			# Does this device exist already?
			if (exists $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$stonith_name})
			{
				foreach my $argument (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$stonith_name}{argument}})
				{
					next if $argument eq "delay";
					my $old_entry = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$stonith_name}{argument}{$argument}{value};
					my $new_entry = exists $old_switches->{$argument} ? $old_switches->{$argument} : "";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:argument'  => $argument, 
						's2:old_entry' => $old_entry,
						's3:new_entry' => $new_entry,
					}});
					
					if ($old_entry ne $new_entry)
					{
						# If the port was removed, delete his entry.
						if (not $port)
						{
							$delete_old = 1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delete_old => $delete_old }});
							
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0430", variables => { device => $stonith_name }});
						}
						else
						{
							# Changed, delete and recreate.
							$delete_old   = 1;
							$create_entry = 1 if not $dont_create;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								delete_old   => $delete_old,
								create_entry => $create_entry,
							}});
							
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0121", variables => { device => $stonith_name }});
						}
						last;
					}
					
					# Delete the old switch.
					delete $old_switches->{$argument};
				}
				
				# Are there any old switches left?
				my $old_switch_count = keys %{$old_switches};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_switch_count => $old_switch_count }});
				if ((not $delete_old) && ($old_switch_count))
				{
					# Delete and recreate. 
					$delete_old   = 1;
					$create_entry = 1 if not $dont_create;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						delete_old   => $delete_old,
						create_entry => $create_entry,
					}});
					
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0121", variables => { device => $stonith_name }});
				}
			}
			elsif ((not $delete_old) && (not $dont_create))
			{
				# No existing entry, add a new one.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0122", variables => { device => $stonith_name }});
				
				$create_entry = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { create_entry => $create_entry }});
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				delete_old   => $delete_old,
				create_entry => $create_entry, 
			}});
			if ($delete_old)
			{
				# Delete
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0119", variables => { device => $stonith_name }});
				
				my $shell_call = $anvil->data->{path}{exe}{pcs}." stonith delete ".$stonith_name;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				
				my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
				if ($return_code)
				{
					# Something went wrong.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
						shell_call  => $shell_call, 
						output      => $output, 
						return_code => $return_code, 
					}});
					return(1);
				}
			}
			if (($create_entry) && (not $dont_create))
			{
				# Create.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "job_0120", variables => { device => $stonith_name }});
				
				my $shell_call = $pcs_add_command;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				
				my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
				if ($return_code)
				{
					# Something went wrong.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
						shell_call  => $shell_call, 
						output      => $output, 
						return_code => $return_code, 
					}});
					return(1);
				}
			}
		}
		
		
		### If we had a fence_ipmilan entry, add a 'fence_delay' entry, if needed.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"machine::${node}::use_delay" => $anvil->data->{machine}{$node}{use_delay}, 
		}});
		if ($anvil->data->{machine}{$node}{use_delay})
		{
			my $stonith_name = "delay_".$node; 
			push @{$fence_order->{$node_name}}, "fence_delay";
			$fence_devices->{$node_name}{fence_delay} = [$stonith_name];
			
			# Add the fence delay if it doesn't exist yet.
			if (not exists $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$stonith_name})
			{
				my $shell_call = $anvil->data->{path}{exe}{pcs}." stonith create ".$stonith_name." fence_delay pcmk_host_list=\"".$node_name."\" wait=\"60\" op monitor interval=\"60\"";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				
				my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					output      => $output,
					return_code => $return_code, 
				}});
				if ($return_code)
				{
					# Something went wrong.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
						shell_call  => $shell_call, 
						output      => $output, 
						return_code => $return_code, 
					}});
					return(1);
				}
			}
		}
	}
	
	# Setup fence levels.
	foreach my $node_name (sort {$a cmp $b} keys %{$fence_order})
	{
		# Update our view of the cluster.
		my $problem = $anvil->Cluster->parse_cib({debug => 2});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		
		# Check our current levels and update if needed.
		my $index = 1;
		foreach my $fence_agent (@{$fence_order->{$node_name}})
		{
			my $key_name = "fl-".$node_name."-".$index;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				fence_agent => $fence_agent,
				key_name    => $key_name, 
			}});
			
			# Does the fence level exist, and is it for the right fence agent?
			if (exists $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$key_name})
			{
				# If there's multiple fence devices in this method, crop off the extra ones.
				my $old_fence_name  =  $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$key_name}{devices};
				   $old_fence_name  =~ s/,.*//;
				my $old_fence_agent =  exists $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$old_fence_name} ? 
				                              $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$old_fence_name}{variables}{resource_agent} : "";
				   $old_fence_agent =~ s/^stonith://;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					old_fence_name  => $old_fence_name,
					old_fence_agent => $old_fence_agent, 
				}});
				if ($fence_agent eq $old_fence_agent)
				{
					# The fence level exists and it's the same fence agent, nothing to do.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0848"});
					$index++;
					next;
				}
				else
				{
					# The fence level exists, but it's for a different fence agent, deleting it
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0849", variables => {
						old_fence_name  => $old_fence_name,
						old_fence_agent => $old_fence_agent, 
					}});
					
					my $shell_call = $anvil->data->{path}{exe}{pcs}." stonith level delete ".$index." ".$node_name;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
					
					my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						output      => $output,
						return_code => $return_code, 
					}});
					if ($return_code)
					{
						# Something went wrong. We'll not exit, but this is probably not going to end well.
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
							shell_call  => $shell_call, 
							output      => $output, 
							return_code => $return_code, 
						}});
					}
				}
			}
			else
			{
				# The fence level doesn't exist.
			}
			
			# Create the fence level now.
			my $devices = "";
			foreach my $device (sort {$a cmp $b} @{$fence_devices->{$node_name}{$fence_agent}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { device => $device }});
				$devices .= $device.",";
			}
			$devices =~ s/,$//;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0850", variables => {
				key_name    => $key_name, 
				fence_agent => $fence_agent, 
				devices     => $devices,
			}});
			
			my $shell_call = $anvil->data->{path}{exe}{pcs}." stonith level add ".$index." ".$node_name." ".$devices;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
			
			my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code, 
			}});
			if ($return_code)
			{
				# Something went wrong.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0138", variables => {
					shell_call  => $shell_call, 
					output      => $output, 
					return_code => $return_code, 
				}});
				return(1);
			}
			
			$index++;
		}
	}
	
	return(0);
}


=head2 configure_logind

This configures logind to ensure it doesn't try to do a graceful shutdown when being fenced via acpid power-button events.

See: https://access.redhat.com/solutions/1578823

This method takes no parameters

=cut
sub configure_logind
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->configure_logind()" }});

	# Only run this on nodes.
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		return(0);
	}

	# Read in the file.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		'path::configs::logind.conf' => $anvil->data->{path}{configs}{'logind.conf'},
	}});
	if (not -e $anvil->data->{path}{configs}{'logind.conf'})
	{
		# wtf?
		return(0);
	}

	my $added    = 0;
	my $new_body = "";
	my $old_body = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{configs}{'logind.conf'}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_body => $old_body }});

	if ($old_body eq "!!error!!")
	{
		return(0);
	}

	# If we don't see 'HandlePowerKey=ignore', we need to add it.
	foreach my $line (split/\n/, $old_body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_body => $old_body }});
		$new_body .= $line."\n";
		if ($line =~ /^HandlePowerKey=(.*)$/)
		{
			# It's been set. No matter how it's set, we don't change it again.
			my $set_to = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set_to => $set_to }});
			return(0);
		}
		if ($line =~ /^#HandlePowerKey=/)
		{
			# Add line under the commented out one.
			$new_body .= "HandlePowerKey=ignore\n";
			$added    = 1;
		}
	}

	if (not $added)
	{
		# Append it.
		$new_body .= "HandlePowerKey=ignore\n";
		$added    = 1;
	}

	# Still here? We almost certainly want to save then, but lets look for a difference just the same.
	my $difference = diff \$old_body, \$new_body, { STYLE => 'Unified' };
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => {
		added      => $added,
		difference => $difference,
	}});
	if ($added)
	{
		# Write it out.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0732"});
		$anvil->Storage->write_file({
			file      => $anvil->data->{path}{configs}{'logind.conf'},
			body      => $new_body,
			backup    => 1,
			overwrite => 1,
		});

		sleep 1;

		# Restart the daemon.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0733", variables => { daemon => "systemd-logind.service" }});
		$anvil->System->restart_daemon({
			debug  => $debug,
			daemon => "systemd-logind.service",
		});
	}

	return(0);
}


=head2 delete_server

This takes a server (resource) name and deletes it from pacemaker. If there is a problem, C<< !!error!! >> is returned. Otherwise, C<< 0 >> is removed either once the resource is deleted, or if the resource didn't exist in the first place.

Parameters;

=head3 server_name (required)

This is the name of the resource to delete.

=cut
sub delete_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->delete_server()" }});
	
	my $server_name = defined $parameter->{server_name} ? $parameter->{server_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server_name => $server_name,
	}});
	
	if (not $server_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->delete_server()", parameter => "server_name" }});
		return('!!error!!');
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0224", variables => { server_name => $server_name }});
		return('!!error!!');
	}
	
	# Is this node fully in the cluster?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0225", variables => { server_name => $server_name }});
		return('!!error!!');
	}
	
	# Does the server exist in the config?
	if (not exists $anvil->data->{cib}{parsed}{data}{server}{$server_name})
	{
		# The server is already gone.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0149", variables => { server_name => $server_name }});
		return(0);
	}
	
	# Is the server running? If so, stop it first.
	my $status = $anvil->data->{cib}{parsed}{data}{server}{$server_name}{status};
	my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server_name}{host_name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		status => $status,
		host   => $host, 
	}});
	
	# Stop the server
	if ($status eq "running")
	{
		my $problem = $anvil->Cluster->shutdown_server({
			server => $server_name, 
			'wait' => 1,
		});
		if ($problem)
		{
			# Failed to stop.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => 'err', key => "error_0223", variables => { server_name => $server_name }});
			return('!!error!!');
		}
	}
	
	# Now delete the resource. Any constraints will be deleted automatically.
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{pcs}." resource delete ".$server_name});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	if (not $return_code)
	{
		# Success!
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0587", variables => { server_name => $server_name }});
		return(0);
	}
	else
	{
		# Unexpected return code.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => 'err', key => "error_0226", variables => { 
			server_name => $server_name,
			return_code => $return_code, 
			output      => $output, 
		}});
		return('!!error!!');
	}
	
	return(0);
}


=head2 get_fence_methods

This takes a host UUID, looks up which Anvil! it belongs to, and then load and parses the recorded CIB, if possible. If one is found for the Anvil!, it parses the fence methods and stores them in a hash.

If the target host is not in an Anvil!, or there is no CIB recorded for the Anvi!, C<< 1 >> is returned. 

B<< Note >>: There is usually only one method, but if there are two or more, they must all be confirmed off before the fence action can be considered successful.

* fence_method::<short_host_name>::order::<X>::method::<method>::command

Parameters;

=head3 host_uuid (Optional, default Get->host_uuid)

This is the host whose fence methods we're looking for.

=cut
sub get_fence_methods
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->get_fence_methods()" }});
	
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : $anvil->Get->host_uuid;
	my $host_name = $anvil->Get->host_name_from_uuid({debug => $debug, host_uuid => $host_uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid => $host_uuid, 
		host_name => $host_name, 
	}});
	
	my $short_host_name =  $host_name;
	   $short_host_name =~ s/\..*$//;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { short_host_name => $short_host_name }});
	
	# Find the Anvil! UUID.
	my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({host_uuid => $host_uuid});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
	if (not $anvil_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0295", variables => { host_name => $host_name }});
		return(1);
	}
	
	# Get the Anvil! name now, for logging.
	my $anvil_name = $anvil->Get->anvil_name_from_uuid({
		debug      => $debug,
		anvil_uuid => $anvil_uuid, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
	
	### NOTE: This probably won't work with fence methods that require multiple calls be run in parallel.
	###       As this is PDUs usually, and we skip them anyway, this shouldn't be an issue.
	my $query = "SELECT scan_cluster_cib FROM scan_cluster WHERE scan_cluster_anvil_uuid = ".$anvil->Database->quote($anvil_uuid).";";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $scan_cluster_cib = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	   $scan_cluster_cib = "" if not defined $scan_cluster_cib; 
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { scan_cluster_cib => $scan_cluster_cib }});
	if (not $scan_cluster_cib)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0296", variables => { anvil_name => $anvil_name }});
		return(1);
	}
	
	# Delete past data, if any.
	if (exists $anvil->data->{fence_method}{$short_host_name})
	{
		delete $anvil->data->{fence_method}{$short_host_name};
	}
	
	# Reading in fence data is expensive, so we only do it as needed.
	my $update_fence_data = 1;
	if ((exists $anvil->data->{sys}{fence_data_updated}) && ($anvil->data->{sys}{fence_data_updated}))
	{
		my $age = time - $anvil->data->{sys}{fence_data_updated};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
		if ($age < 86400)
		{
			# Only refresh daily.
			$update_fence_data = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_fence_data => $update_fence_data }});
		}
	}
	if ($update_fence_data)
	{
		$anvil->Striker->get_fence_data({debug => $debug});
	}
	
	# Parse out the fence methods for this host. 
	my $problem = $anvil->Cluster->parse_cib({
		debug => $debug,
		cib   => $scan_cluster_cib, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if (not $problem)
	{
		# Parsed! Do we have a fence method we can trust to check the power 
		# state of this node?
		my $node_name = exists $anvil->data->{cib}{parsed}{data}{node}{$short_host_name} ? $short_host_name : $host_name;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_name => $node_name }});
		foreach my $order (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}})
		{
			my $method = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$order}{devices};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:order'  => $order,
				's2:method' => $method, 
			}});
			
			foreach my $this_method (split/,/, $method)
			{
				my $agent = $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$this_method}{agent};
				
				# We ignore the fake, delay method 
				next if $agent eq "fence_delay";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:this_method' => $this_method,
					's2:agent'       => $agent,
				}});
				
				my $shell_call = $agent." ";
				foreach my $stdin_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$this_method}{argument}})
				{
					next if $stdin_name =~ /pcmk_o\w+_action/;
					my $switch = "";
					my $value  = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$this_method}{argument}{$stdin_name}{value};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:stdin_name' => $stdin_name,
						's2:value'      => $value, 
					}});
					
					foreach my $this_switch (sort {$a cmp $b} keys %{$anvil->data->{fence_data}{$agent}{switch}})
					{
						my $this_name = $anvil->data->{fence_data}{$agent}{switch}{$this_switch}{name};
						if ($stdin_name eq $this_name)
						{
								$switch  =  $this_switch;
							my $dashes  =  (length($switch) > 1) ? "--" : "-";
							$shell_call .= $dashes.$switch." \"".$value."\" ";
							last;
						}
					}
					if (not $switch)
					{
						if ($anvil->data->{fence_data}{$agent}{switch}{$stdin_name}{name})
						{
							my $dashes  =  (length($stdin_name) > 1) ? "--" : "-";
							$shell_call .= $dashes.$stdin_name." \"".$value."\" ";
						}
					}
				}
				$anvil->data->{fence_method}{$short_host_name}{order}{$order}{method}{$this_method}{command} = $shell_call;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_method::${short_host_name}::order::${order}::method::${this_method}::command" => $anvil->data->{fence_method}{$short_host_name}{order}{$order}{method}{$this_method}{command},
				}});
			}
		}
	}
	
	return(0);
}


=head2 get_anvil_name

This returns the C<< anvils >> -> C<< anvil_name >> for a given C<< anvil_uuid >>. If no C<< anvil_uuid >> is passed, a check is made to see if this host is in an Anvil! and, if so, the Anvil! name it's a member of is returned.

If not match is found, a blank string is returned.

 my $anvil_name = $anvil->Cluster->get_anvil_name({anvil_uuid => "2ac4dbcb-25d2-44b2-ae07-59707b0551ca"});

Parameters;

=head3 anvil_uuid (optional, default Cluster->get_anvil_uuid)

This is the C<< anvil_uuid >> of the Anvil! whose name we're looking for.

=cut
sub get_anvil_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->get_anvil_name()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : $anvil->Cluster->get_anvil_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid,
	}});
	
	my $anvil_name = "";
	if (not $anvil_uuid)
	{
		$anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
	}
	if (not $anvil_uuid)
	{
		return($anvil_name);
	}
	
	# Load the Anvil! data.
	$anvil->Database->get_anvils({debug => $debug});
	if (exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid})
	{
		$anvil_name = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name};
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_name => $anvil_name }});
	return($anvil_name);
}


=head2 get_anvil_uuid

This returns the C<< anvils >> -> C<< anvil_uuid >> that a host belongs to. If the host is not found in any Anvil!, an empty string is returned.

Optionally, this method can be passed an C<< anvil_name >>. If so, the name is used to find the UUID.

Parameters;

=head3 anvil_name (optional)

If set, this is used to look up the Anvil! UUID.

=head3 host_uuid (optional, default Get->host_uuid)

This is the C<< host_uuid >> of the host who we're looking for Anvil! membership of.

=cut
sub get_anvil_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->get_anvil_uuid()" }});
	
	my $anvil_name = defined $parameter->{anvil_name} ? $parameter->{anvil_name} : "";
	my $host_uuid  = defined $parameter->{host_uuid}  ? $parameter->{host_uuid}  : $anvil->Get->host_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_name => $anvil_name, 
		host_uuid  => $host_uuid,
	}});
	
	# Load the Anvil! data.
	$anvil->Database->get_anvils({debug => $debug});
	
	if ($anvil_name)
	{
		# Convert to the UUID directly.
		my $anvil_uuid = "";
		if (exists $anvil->data->{anvils}{anvil_name}{$anvil_name})
		{
			$anvil_uuid = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_uuid};
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
		return($anvil_uuid);
	}
	
	my $member_anvil_uuid = "";
	foreach my $anvil_uuid (keys %{$anvil->data->{anvils}{anvil_uuid}})
	{
		my $anvil_name            = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name};
		my $anvil_node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		my $anvil_node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_name            => $anvil_name,
			anvil_node1_host_uuid => $anvil_node1_host_uuid, 
			anvil_node2_host_uuid => $anvil_node2_host_uuid, 
		}});
		
		if (($host_uuid eq $anvil_node1_host_uuid) or 
		    ($host_uuid eq $anvil_node2_host_uuid))
		{
			# Found ot!
			$member_anvil_uuid = $anvil_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { member_anvil_uuid => $member_anvil_uuid }});
			last;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { member_anvil_uuid => $member_anvil_uuid }});
	return($member_anvil_uuid);
}

=head2 get_peers

This method uses the local machine's host UUID and finds the host names of the cluster memebers. If this host is in a cluster and it is a node, the peer's short host name is returned. Otherwise, an empty string is returned.

The data is stored as;

 sys::anvil::node1::host_uuid 
 sys::anvil::node1::host_name 
 sys::anvil::node2::host_uuid
 sys::anvil::node2::host_name

To assist with lookup, the following are also set;

 sys::anvil::i_am    = {node1,node2}
 sys::anvil::peer_is = {node1,node2}

This method takes no parameters.

=cut
sub get_peers
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->get_peers()" }});
	
	$anvil->data->{sys}{anvil}{node1}{host_uuid} = "";
	$anvil->data->{sys}{anvil}{node1}{host_name} = "";
	$anvil->data->{sys}{anvil}{node2}{host_uuid} = "";
	$anvil->data->{sys}{anvil}{node2}{host_name} = "";
	$anvil->data->{sys}{anvil}{i_am}             = "";
	$anvil->data->{sys}{anvil}{peer_is}          = "";
	
	# Load hosts and anvils
	$anvil->Database->get_hosts({debug => $debug});
	$anvil->Database->get_anvils({debug => $debug});
	
	# Is ths host in an anvil?
	my $host_uuid = $anvil->Get->host_uuid({debug => $debug});
	my $in_anvil  = "";
	my $found     = 0;
	my $peer      = "";
	
	foreach my $anvil_uuid (keys %{$anvil->data->{anvils}{anvil_uuid}})
	{
		my $anvil_node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		my $anvil_node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_node1_host_uuid => $anvil_node1_host_uuid, 
			anvil_node2_host_uuid => $anvil_node2_host_uuid,
		}});
		
		if ($host_uuid eq $anvil_node1_host_uuid)
		{
			# Found our Anvil!, and we're node 1.
			$found                              = 1;
			$anvil->data->{sys}{anvil}{i_am}    = "node1";
			$anvil->data->{sys}{anvil}{peer_is} = "node2";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				found                 => $found, 
				"sys::anvil::i_am"    => $anvil->data->{sys}{anvil}{i_am},
				"sys::anvil::peer_is" => $anvil->data->{sys}{anvil}{peer_is},
			}});
		}
		elsif ($host_uuid eq $anvil_node2_host_uuid)
		{
			# Found our Anvil!, and we're node 1.
			$found                              = 1;
			$anvil->data->{sys}{anvil}{i_am}    = "node2";
			$anvil->data->{sys}{anvil}{peer_is} = "node1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				found                 => $found, 
				"sys::anvil::i_am"    => $anvil->data->{sys}{anvil}{i_am},
				"sys::anvil::peer_is" => $anvil->data->{sys}{anvil}{peer_is},
			}});
		}
		if ($found)
		{
			$anvil->data->{sys}{anvil}{node1}{host_uuid} = $anvil_node1_host_uuid;
			$anvil->data->{sys}{anvil}{node1}{host_name} = $anvil->data->{hosts}{host_uuid}{$anvil_node1_host_uuid}{host_name};
			$anvil->data->{sys}{anvil}{node2}{host_uuid} = $anvil_node2_host_uuid;
			$anvil->data->{sys}{anvil}{node2}{host_name} = $anvil->data->{hosts}{host_uuid}{$anvil_node2_host_uuid}{host_name};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::anvil::node1::host_uuid" => $anvil->data->{sys}{anvil}{node1}{host_uuid}, 
				"sys::anvil::node1::host_name" => $anvil->data->{sys}{anvil}{node1}{host_name}, 
				"sys::anvil::node2::host_uuid" => $anvil->data->{sys}{anvil}{node2}{host_uuid}, 
				"sys::anvil::node2::host_name" => $anvil->data->{sys}{anvil}{node2}{host_name}, 
			}});
			
			# If this is a node, return the peer's short host name.
			if ($anvil->data->{sys}{anvil}{i_am})
			{
				$peer =  $anvil->data->{sys}{anvil}{i_am} eq "node1" ? $anvil->data->{sys}{anvil}{node1}{host_name} : $anvil->data->{sys}{anvil}{node2}{host_name};
				$peer =~ s/\..*//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { peer => $peer }});
			}
			last;
		}
	}
	
	return($peer);
}


=head2 get_primary_host_uuid

This takes an Anvil! UUID and returns with the node's host UUID that is currently the "primary" node. That is to say, which node has the most servers running on it, by allocated RAM. For example, if node 1 has two servers, each with 8 GiB of RAM and node 2 has one VM with 32 GiB of RAM, node 2 will be considered primary as it would take longest to migrate servers off.

If all is equal, node 1 is considered primary. If only one node is a cluster member, it is considered primary. If neither node is up, an empty string is returned.

Parameters;

=head3 anvil_uuid (optional, default Cluster->get_anvil_uuid)

This is the Anvil! UUID we're looking for the primary node in.

=cut
sub get_primary_host_uuid
{
	my $self             = shift;
	my $parameter        = shift;
	my $anvil            = $self->parent;
	my $test_access_user = defined $parameter->{test_access_user} ? $parameter->{test_access_user} : undef;
	my $debug            = defined $parameter->{debug}            ? $parameter->{debug}            : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->get_primary_host_uuid()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid,
	}});
	
	if (not $anvil_uuid)
	{
		my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
	}
	
	if (not $anvil_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->get_primary_host_uuid()", parameter => "anvil_uuid" }});
		return("");
	}
	
	# Get the two node UUIDs, if not already loaded
	if (not exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid})
	{
		$anvil->Database->get_anvils({debug => $debug});
	}
	
	if (not exists $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid})
	{
		# Invalid Anvil! UUID.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0169", variables => { anvil_uuid => $anvil_uuid }});
		return("");
	}
	
	my $node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
	my $node1_target_ip = $anvil->Network->find_target_ip({debug => $debug, host_uuid => $node1_host_uuid});
	my $node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
	my $node2_target_ip = $anvil->Network->find_target_ip({debug => $debug, host_uuid => $node2_host_uuid});
	my $password        = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_password};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node1_host_uuid => $node1_host_uuid,
		node1_target_ip => $node1_target_ip, 
		node2_host_uuid => $node2_host_uuid, 
		node2_target_ip => $node2_target_ip, 
		password        => $anvil->Log->is_secure($password),
	}});
	
	# Are the nodes up?
	my $node1_access = $anvil->Remote->test_access({
		debug    => $debug, 
		target   => $node1_target_ip, 
		password => $password, 
		user     => $test_access_user,
	});
	my $node2_access = $anvil->Remote->test_access({
		debug    => $debug, 
		target   => $node2_target_ip, 
		password => $password, 
		user     => $test_access_user,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node1_access => $node1_access,
		node2_access => $node2_access, 
	}});
	
	# Can we parse the CIB from node 1? 
	my $cib_from = "";
	if ($node1_access)
	{
		my $problem = $anvil->Cluster->parse_cib({
			debug    => $debug,
			target   => $node1_target_ip, 
			password => $password, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		if (not $problem)
		{
			$cib_from = "node1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cib_from => $cib_from }});
		}
		elsif ($node2_access)
		{
			# Try to read the CIB from node 2.
			my $problem = $anvil->Cluster->parse_cib({
				debug    => $debug,
				target   => $node2_target_ip, 
				password => $password, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			if (not $problem)
			{
				$cib_from = "node2";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cib_from => $cib_from }});
			}
		}
	}
	
	# If we failed to load the CIB, we're done.
	if (not $cib_from)
	{
		return("");
	}
	
	# Is the node we got the CIB from fully in the cluster?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"cib::parsed::local::ready" => $anvil->data->{cib}{parsed}{'local'}{ready},
		"cib::parsed::peer::ready"  => $anvil->data->{cib}{parsed}{peer}{ready},
	}});
	if (($anvil->data->{cib}{parsed}{'local'}{ready}) && (not $anvil->data->{cib}{parsed}{peer}{ready}))
	{
		# The node we got the CIB from is ready, the other node is not.
		if ($cib_from eq "node1")
		{
			# Node 1 is primary
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node1_host_uuid => $node1_host_uuid }});
			return($node1_host_uuid);
		}
		else
		{
			# Node 2 is primary
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node2_host_uuid => $node2_host_uuid }});
			return($node2_host_uuid);
		}
	}
	elsif ((not $anvil->data->{cib}{parsed}{'local'}{ready}) && ($anvil->data->{cib}{parsed}{peer}{ready}))
	{
		# Opposite; the other node is ready and the node we read from was not.
		if ($cib_from eq "node1")
		{
			# Node 2 is primary
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node2_host_uuid => $node2_host_uuid }});
			return($node2_host_uuid);
		}
		else
		{
			# Node 1 is primary
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node1_host_uuid => $node1_host_uuid }});
			return($node1_host_uuid);
		}
	}
	
	# Still alive? Both nodes are in the cluster. Start counting RAM allocated to servers.
	my $node1_ram_in_use_by_servers = 0;
	my $node2_ram_in_use_by_servers = 0;
	
	# Loop through servers. 
	$anvil->Database->get_servers({debug => $debug});
	foreach my $server_name (sort {$a cmp $b} keys %{$anvil->data->{servers}{anvil_uuid}{$anvil_uuid}{server_name}})
	{
		my $server_uuid = $anvil->data->{servers}{anvil_uuid}{$anvil_uuid}{server_name}{$server_name}{server_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			server_name => $server_name,
			server_uuid => $server_uuid, 
		}});
		
		my $server_host_uuid  = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_host_uuid};
		my $server_state      = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
		my $server_ram_in_use = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_ram_in_use};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			server_host_uuid  => $server_host_uuid,
			server_state      => $server_state, 
			server_ram_in_use => $server_ram_in_use." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $server_ram_in_use}).")"
		}});
		
		next if $server_state ne "running";
		if ($server_host_uuid eq $node1_host_uuid)
		{
			$node1_ram_in_use_by_servers += $server_ram_in_use;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				node1_ram_in_use_by_servers => $node1_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node1_ram_in_use_by_servers}).")"
			}});
		}
		elsif ($server_host_uuid eq $node2_host_uuid)
		{
			$node2_ram_in_use_by_servers += $server_ram_in_use;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				node2_ram_in_use_by_servers => $node2_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node2_ram_in_use_by_servers}).")"
			}});
		}
	}
	
	# if we're node 1 and have equal RAM, or we have more RAM, we're primary.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node1_ram_in_use_by_servers => $node1_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node1_ram_in_use_by_servers}).")", 
		node2_ram_in_use_by_servers => $node2_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $node2_ram_in_use_by_servers}).")", 
	}});
	
	if (($node1_ram_in_use_by_servers == $node2_ram_in_use_by_servers) or 
	    ($node1_ram_in_use_by_servers > $node2_ram_in_use_by_servers))
	{
		# Matching RAM, node 1 wins, or node 1 has more RAM.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node1_host_uuid => $node1_host_uuid }});
		return($node1_host_uuid);
	}
	else
	{
		# Node 2 has more RAM in use, it's primary
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node2_host_uuid => $node2_host_uuid }});
		return($node2_host_uuid);
	}
	
	# This should never be hit
	return("");
}


=head2 is_primary

This methid returns C<< 1 >> if the caller is the "primary" node in the cluster, C<< 0 >> in all other cases. 

"Primary", in this context, means;
" The node that is running the servers. 
" If both nodes are running servers, then the node with the most active RAM (summed from the RAM allocated to running servers) is deemed "primary" (would take the longest to migrate servers off). 
" If both nodes have no servers, or the amount of RAM allocated to running servers is the same, node 1 is deemed primary.
" If only one node is up, it is deemed primary.

This method takes no parameters.

=cut
sub is_primary
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->is_primary()" }});
	
	my $host_uuid  = $anvil->Get->host_uuid({debug => $debug});
	my $host_type  = $anvil->Get->host_type({debug => $debug});
	my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid  => $host_uuid,
		host_type  => $host_type, 
		anvil_uuid => $anvil_uuid,
	}});
	
	if ($host_type ne "node")
	{
		# Not a node? not primary.
		return(0);
	}
	if (not $anvil_uuid)
	{
		# Not an Anvil! member, so, ya...
		return(0);
	}
	
	# Are we in the cluster? If not, we're not primary.
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		# Nope.
		return(0);
	}
	
	# Is this node fully in the cluster?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"cib::parsed::local::ready" => $anvil->data->{cib}{parsed}{'local'}{ready},
	}});
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		# Nope.
		return(0);
	}
	
	# Still alive? Excellent! What state is our peer in?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"cib::parsed::peer::ready" => $anvil->data->{cib}{parsed}{peer}{ready},
	}});
	if (not $anvil->data->{cib}{parsed}{peer}{ready})
	{
		# Our peer is not ready, so we're primary
		return(1);
	}
	
	# If we're alive, both we and our peer is online. Who is primary?
	$anvil->Cluster->get_peers();
	my $peer_is        = $anvil->data->{sys}{anvil}{peer_is};
	my $my_host_uuid   = $anvil->Get->host_uuid;
	my $peer_host_uuid = $peer_is eq "node2" ? $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid} : $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		peer_is        => $peer_is,
		my_host_uuid   => $my_host_uuid, 
		peer_host_uuid => $peer_host_uuid, 
	}});
	
	my $my_ram_in_use_by_servers   = 0;
	my $peer_ram_in_use_by_servers = 0;
	
	# Loop through servers. 
	foreach my $server_name (sort {$a cmp $b} keys %{$anvil->data->{servers}{anvil_uuid}{$anvil_uuid}{server_name}})
	{
		my $server_uuid = $anvil->data->{servers}{anvil_uuid}{$anvil_uuid}{server_name}{$server_name}{server_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			server_name => $server_name,
			server_uuid => $server_uuid, 
		}});
		
		my $server_host_uuid  = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_host_uuid};
		my $server_state      = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_state};
		my $server_ram_in_use = $anvil->data->{servers}{server_uuid}{$server_uuid}{server_ram_in_use};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			server_host_uuid  => $server_host_uuid,
			server_state      => $server_state, 
			server_ram_in_use => $server_ram_in_use." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $server_ram_in_use}).")"
		}});
		
		next if $server_state ne "running";
		if ($server_host_uuid eq $my_host_uuid)
		{
			$my_ram_in_use_by_servers += $server_ram_in_use;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				my_ram_in_use_by_servers => $my_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $my_ram_in_use_by_servers}).")"
			}});
		}
		elsif ($server_host_uuid eq $peer_host_uuid)
		{
			$peer_ram_in_use_by_servers += $server_ram_in_use;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				peer_ram_in_use_by_servers => $peer_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $peer_ram_in_use_by_servers}).")"
			}});
		}
	}
	
	# if we're node 1 and have equal RAM, or we have more RAM, we're primary.
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		my_ram_in_use_by_servers   => $my_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $my_ram_in_use_by_servers}).")", 
		peer_ram_in_use_by_servers => $peer_ram_in_use_by_servers." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $peer_ram_in_use_by_servers}).")", 
	}});
	
	if (($my_ram_in_use_by_servers == $peer_ram_in_use_by_servers) && ($peer_is eq "node2"))
	{
		# Matching RAM and we're node 1, so we're primary.
		return(1);
	}
	elsif ($my_ram_in_use_by_servers > $peer_ram_in_use_by_servers)
	{
		# More RAM allocated to us than our peer, we're primary.
		return(1);
	}
	
	# Any other condition, and we're not primary.
	return(0);
}


=head2 manage_fence_delay

This method checks or sets the fence delay that controls which node survives in a network split. Generally, this is the node hosting servers, as ScanCore's C<< scan-cluster >> should set this based on where the servers are run.

If C<< set >> is given an invalid host name, or if this is called on a node that is not a cluster member, C<< !!error!! >> is returned. Otherwise, the node with the delay favouring it is returned. If, somehow, neither node has a delay, then an empty string is returned.

B<< Note >>: This must run on a node in a cluster.

Parameters;

=head3 prefer (optional)

If this is set to a node name, that node will have the fence delay set to favour it. Specifically, the first fence method on this node has the C<< delay="15" >> argument added to it. If a delay is found on any other method, it is removed.

=cut
sub manage_fence_delay
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->manage_fence_delay()" }});
	
	my $prefer = defined $parameter->{prefer} ? $parameter->{prefer} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		prefer => $prefer, 
	}});
	
	### NOTE: We don't really need this anymore, though there is one reason we might (to be decided later);
	###       See: https://clusterlabs.org/pacemaker/doc/2.1/Pacemaker_Explained/singlehtml/index.html#cluster-options
	###       - priority-fencing-delay
	
	# Are we a node?
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0123"});
		return("!!error!!");
	}
	
	# Are we in the cluster?
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0124"});
		return('!!error!!');
	}
	
	# Are we a full member?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0125"});
		return('!!error!!');
	}
	
	# Now look for stonith info.
	foreach my $node_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_name => $node_name }});
		foreach my $order (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}})
		{
			my $method = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$order}{devices};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:order'  => $order,
				's2:method' => $method, 
			}});
			
			foreach my $this_method (split/,/, $method)
			{
				my $agent = $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$this_method}{agent};
				
				# We ignore the fake, delay method 
				next if $agent eq "fence_delay";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:this_method' => $this_method,
					's2:agent'       => $agent,
				}});
				
				my $config_line = $agent." ";
				foreach my $stdin_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$this_method}{argument}})
				{
					next if $stdin_name =~ /pcmk_o\w+_action/;
					my $value = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$this_method}{argument}{$stdin_name}{value};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:stdin_name' => $stdin_name,
						's2:value'      => $value, 
					}});
					
					$config_line .= $stdin_name."=\"".$value."\" ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { config_line => $config_line }});
				}
				$anvil->data->{fence_method}{$node_name}{order}{$order}{method}{$this_method}{command} = $config_line;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"fence_method::${node_name}::order::${order}::method::${this_method}::command" => $anvil->data->{fence_method}{$node_name}{order}{$order}{method}{$this_method}{command},
				}});
			}
		}
	}
	
	### TODO: We don't need to specify the full argument list, we only need to set 'delay=""' to delete 
	###       the delay, and 'delay="15"' to add it.
	my $preferred_node = "";
	foreach my $node_name (sort {$a cmp $b} keys %{$anvil->data->{fence_method}})
	{
		# There's only one, no reason to sort
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_name => $node_name }});
		foreach my $method (keys %{$anvil->data->{fence_method}{$node_name}{order}{1}{method}})
		{
			my $config_line = $anvil->data->{fence_method}{$node_name}{order}{1}{method}{$method}{command};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:node_name'   => $node_name,
				's2:method'      => $method,
				's3:config_line' => $config_line, 
			}});
			if ($config_line =~ / delay="(\d+)"/)
			{
				# If we're being asked to set a preferred node, and this isn't it, set it to 0.
				my $delay = $1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
				
				if ($delay)
				{
					if (($prefer) && ($prefer ne $node_name))
					{
						# Set it to delay="0"
						   $config_line =~ s/ delay=\".*?\"/ delay="0"/;
						my $shell_call  =  $anvil->data->{path}{exe}{pcs}." stonith update ".$method." ".$config_line;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
						my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							output      => $output,
							return_code => $return_code,
						}});
						
						# Make sure we're now the preferred host anymore.
						$preferred_node = $anvil->Cluster->manage_fence_delay({debug => $debug});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { preferred_node => $preferred_node }});
						
						if (($preferred_node ne "!!error!!") && ($preferred_node ne $node_name))
						{
							# Success! Register an alert.
							my $variables = {
								node => $node_name, 
							};
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0253", variables => $variables});
							$anvil->Alert->register({alert_level => "notice", message => "message_0253", variables => $variables, set_by => $THIS_FILE});
						}
						else
						{
							# What?!
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0310", variables => { 
								node    => $node_name,
								current => $preferred_node, 
							}});
							return("!!error!!")
						}
					}
					else
					{
						$preferred_node = $node_name;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { preferred_node => $preferred_node }});
					}
				}
				elsif (($prefer) && ($prefer eq $node_name))
				{
					# Change it to delay="15"
					   $config_line =~ s/ delay=\"\d+\"/ delay="15"/;
					my $shell_call  =  $anvil->data->{path}{exe}{pcs}." stonith update ".$method." ".$config_line;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
					my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						output      => $output,
						return_code => $return_code,
					}});
					
					# Verify that this is now the prferred host.
					$preferred_node = $anvil->Cluster->manage_fence_delay({debug => $debug});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { preferred_node => $preferred_node }});
					
					if ($prefer eq $preferred_node)
					{
						# Success! Register an alert.
						my $variables = {
							node => $node_name, 
						};
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0254", variables => $variables});
						$anvil->Alert->register({alert_level => "notice", message => "message_0254", variables => $variables, set_by => $THIS_FILE});
						
						return($prefer);
					}
					else
					{
						# What?!
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0309", variables => { 
							prefer  => $prefer,
							current => $preferred_node, 
						}});
						return("!!error!!")
					}
				}
			}
			else
			{
				# If 'prefer' is set, and this is the node, add it.
				if (($prefer) && ($prefer eq $node_name))
				{
					   $config_line .= " delay=\"15\"";
					my $shell_call  =  $anvil->data->{path}{exe}{pcs}." stonith update ".$method." ".$config_line;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
					my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						output      => $output,
						return_code => $return_code,
					}});
					
					# Verify that this is now the prferred host.
					$preferred_node = $anvil->Cluster->manage_fence_delay({debug => $debug});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { preferred_node => $preferred_node }});
					
					if ($prefer eq $preferred_node)
					{
						# Success! Register an alert.
						my $variables = {
							node => $node_name, 
						};
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0254", variables => $variables});
						$anvil->Alert->register({alert_level => "notice", message => "message_0254", variables => $variables, set_by => $THIS_FILE});
						
						return($prefer);
					}
					else
					{
						# What?!
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0309", variables => { 
							prefer  => $prefer,
							current => $preferred_node, 
						}});
						return("!!error!!")
					}
				}
			}
		}
	}
	
	return($preferred_node);
}


=head2 migrate_server

This manipulates pacemaker's location constraints to trigger a pacemaker-controlled migration of one or more servers.

This method works by confirming that the server is running and it not on the target C<< node >>. If the server is server indeed needs to be migrated, a location constraint is set to give preference to the target node. Optionally, this method can wait until the migration is complete.

B<< Note >>: This method does not make the actual C<< virsh >> call! To perform a migration B<< OUTSIDE >> pacemaker, use C<< Server->migrate_virsh() >>. 

Parameters;

=head3 server (required)

This is the server to migrate.

=head3 node (required)

This is the name of the node to move the server to. 

=head3 wait (optional, default '1')

This controls whether the method waits for the server to shut down before returning. By default, it will go into a loop and check every 2 seconds to see if the server is still running. Once it's found to be off, the method returns. If this is set to C<< 0 >>, the method will return as soon as the request to shut down the server is issued.

=cut
sub migrate_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->migrate_server()" }});
	
	my $server = defined $parameter->{server} ? $parameter->{server} : "";
	my $node   = defined $parameter->{node}   ? $parameter->{node}   : "";
	my $wait   = defined $parameter->{'wait'} ? $parameter->{'wait'} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server => $server,
		node   => $node, 
		'wait' => $wait,
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->migrate_server()", parameter => "server" }});
		return("!!error!!");
	}
	
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0154", variables => { server => $server }});
		return("!!error!!");
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0155", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Are both nodes fully in the cluster?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0156", variables => { server => $server }});
		return('!!error!!');
	}
	if (not $anvil->data->{cib}{parsed}{peer}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0157", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is the server one we know of?
	if (not exists $anvil->data->{cib}{parsed}{data}{server}{$server})
	{
		# The server isn't in the pacemaker config.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0158", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is the server already running? If so, where?
	my $status = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
	my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name};
	my $role   = $anvil->data->{cib}{parsed}{data}{server}{$server}{role};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		status => $status,
		host   => $host, 
		role   => $role,
	}});
	
	if (($status eq "off") or ($status eq "stopped"))
	{
		# It's not running on either node, nothing to do.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0061", variables => { 
			server         => $server,
			requested_node => $node,
		}});
		return(0);
	}
	elsif (($status eq "running") && ($host eq $node))
	{
		# Already running on the target.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0549", variables => { 
			server         => $server,
			requested_node => $node,
		}});
		return(0);
	}
	elsif (lc($role) eq "stopping")
	{
		# It's stopping, don't migrate.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0064", variables => { 
			server         => $server,
			requested_node => $node,
		}});
		return('!!error!!');
	}
	elsif (lc($role) eq "migating")
	{
		# It's stopping, don't migrate.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0065", variables => { 
			server         => $server,
			requested_node => $node,
		}});
		return('!!error!!');
	}
	elsif ($status ne "running")
	{
		# The server is in an unknown state.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0061", variables => { 
			server        => $server,
			current_host  => $host,
			current_state => $status, 
		}});
		return('!!error!!');
	}
	
	### NOTE: A server's state is set in Server->migrate_virsh(), so we don't need to do it here.
	# change the constraint to trigger the move.
	if ($node)
	{
		$anvil->Cluster->_set_server_constraint({
			debug          => $debug,
			server         => $server,
			preferred_node => $node,
		});
	}
	
	if (not $wait)
	{
		# We'll leave it to the scan-server scan agent to clear the migration flag from the database.
		return(0);
	}
	
	# Wait now for the server to start.
	my $waiting = 1;
	while($waiting)
	{
		$anvil->Cluster->parse_cib({debug => $debug});
		my $status    = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host_name = $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			status    => $status,
			host_name => $host_name, 
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0550", variables => { 
			server         => $server,
			requested_node => $node, 
		}});
		if (($status eq "running") && ($host_name eq $node))
		{
			# It's done.
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0551", variables => { 
				server         => $server,
				requested_node => $node, 
			}});
		}
		else
		{
			# Wait a bit and check again.
			sleep 2;
		}
	}
	
	return(0);
}


=head2 parse_cib

This reads in the CIB XML and parses it from a local or remote system. On success, it returns C<< 0 >>. On failure (ie: pcsd isn't running), returns C<< 1 >>.

If you call this against a remote machine, the data will be loaded the same as if it had been run locally. As such, if this is used from a Striker, be mindful of if it was called on Node 1 or 2. 

Parameters;

=head3 cib (optional)

B<< Note >>: Generally this should not be used.

By default, the CIB is read by calling C<< pcs cluster cib >>. However, this parameter can be used to pass in a CIB instead. If this is set, the live CIB is B<< NOT >> read.

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
sub parse_cib
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->parse_cib()" }});
	
	my $cib         = defined $parameter->{cib}         ? $parameter->{cib}         : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		cib         => $cib,
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# If we parsed before, delete it.
	if (exists $anvil->data->{cib}{parsed})
	{
		delete $anvil->data->{cib}{parsed};
	}
	# This stores select data we've pulled out that's meant to be easier to find.
	if (exists $anvil->data->{cib}{data})
	{
		delete $anvil->data->{cib}{data};
	}
	
	my $problem     = 1;
	my $cib_data    = "";
	my $return_code = 0;
	if ($cib)
	{
		$cib_data = $cib;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cib_data => $cib_data }});
	}
	else
	{
		my $shell_call = $anvil->data->{path}{exe}{pcs}." cluster cib";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local call
			($cib_data, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				cib_data    => $cib_data,
				return_code => $return_code,
			}});
		}
		else
		{
			# Remote call.
			($cib_data, my $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call, 
				target      => $target,
				port        => $port, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error       => $error,
				cib_data    => $cib_data,
				return_code => $return_code,
			}});
		}
	}
	if ($return_code)
	{
		# Failed to read the CIB.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0052"});
	}
	else
	{
		local $@;
		my $dom = eval { XML::LibXML->load_xml(string => $cib_data); };
		if ($@)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0053", variables => { 
				cib   => $cib_data,
				error => $@,
			}});
		}
		else
		{
			### NOTE: Full CIB details; 
			###       - https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/2.0/html-single/Pacemaker_Explained/index.html
			# Successful parse!
			$problem = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			foreach my $nvpair ($dom->findnodes('/cib/configuration/crm_config/cluster_property_set/nvpair'))
			{
				my $nvpair_id = $nvpair->{id};
				foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{$variable} = $nvpair->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::configuration::crm_config::cluster_property_set::nvpair::${nvpair_id}::${variable}" => $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{$variable}, 
					}});
				}
			}
			foreach my $node ($dom->findnodes('/cib/configuration/nodes/node'))
			{
				my $node_id = $node->{id};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_id => $node_id }});
				foreach my $variable (sort {$a cmp $b} keys %{$node})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{configuration}{nodes}{$node_id}{$variable} = $node->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::configuration::nodes::${node_id}::${variable}" => $anvil->data->{cib}{parsed}{configuration}{nodes}{$node_id}{$variable}, 
					}});
					
					if ($variable eq "uname")
					{
						my $node                                              = $node->{$variable};
						   $anvil->data->{cib}{parsed}{data}{node}{$node}{id} = $node_id;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::data::node::${node}::id" => $anvil->data->{cib}{parsed}{data}{node}{$node}{id}, 
						}});
						
						# Preload state values (in case they're not read in this CIB.
						# Don't log these as it's confusing
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm}             = "false";
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd}               = "offline";
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'}             = "down";
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'maintenance-mode'} = "off";
					}
				}
				foreach my $instance_attributes ($node->findnodes('./instance_attributes'))
				{
					my $instance_attributes_id = $instance_attributes->{id};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { instance_attributes_id => $instance_attributes_id }});
					foreach my $nvpair ($instance_attributes->findnodes('./nvpair'))
					{
						my $id    = $nvpair->{id};
						my $name  = $nvpair->{name};
						my $value = $nvpair->{value};
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{$name} = $value;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::cib::node_state::${node_id}::${name}" => $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{$name}, 
						}});
					}
				}
			}
			foreach my $clone ($dom->findnodes('/cib/configuration/resources/clone'))
			{
				my $clone_id = $clone->{id};
				foreach my $primitive ($clone->findnodes('./primitive'))
				{
					my $primitive_id = $primitive->{id};
					$anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{primitive}{$primitive_id}{class} = $primitive->{class};
					$anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{primitive}{$primitive_id}{type}  = $primitive->{type};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::cib::resources::clone::${clone_id}::primitive::${primitive_id}::class" => $anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{primitive}{$primitive_id}{class}, 
						"cib::parsed::cib::resources::clone::${clone_id}::primitive::${primitive_id}::type"  => $anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{primitive}{$primitive_id}{type}, 
					}});
					foreach my $op ($primitive->findnodes('./operations/op'))
					{
						my $op_id = $op->{id};
						foreach my $variable (sort {$a cmp $b} keys %{$op})
						{
							next if $variable eq "id";
							$anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{operations}{$op_id}{$variable} = $op->{$variable};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"cib::parsed::cib::resources::clone::${clone_id}::operations::${op_id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{operations}{$op_id}{$variable}, 
							}});
						}
					}
				}
				foreach my $meta_attributes ($clone->findnodes('./meta_attributes'))
				{
					my $meta_attributes_id = $meta_attributes->{id};
					foreach my $nvpair ($meta_attributes->findnodes('./nvpair'))
					{
						my $id = $nvpair->{id};
						foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
						{
							next if $variable eq "id";
							$anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{meta_attributes}{$id}{$variable} = $nvpair->{$variable};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"cib::parsed::cib::resources::clone::${clone_id}::meta_attributes::${id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{clone}{$clone_id}{meta_attributes}{$id}{$variable}, 
							}});
						}
					}
				}
			}
			foreach my $fencing_level ($dom->findnodes('/cib/configuration/fencing-topology/fencing-level'))
			{
				my $id = $fencing_level->{id};
				foreach my $variable (sort {$a cmp $b} keys %{$fencing_level})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{$variable} = $fencing_level->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::configuration::fencing-topology::fencing-level::${id}::${variable}" => $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{$variable}, 
					}});
				}
			}
			foreach my $constraint ($dom->findnodes('/cib/configuration/constraints/rsc_location'))
			{
				my $id = $constraint->{id};
				$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node}     = $constraint->{node}  ? $constraint->{node}  : "";
				$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource} = $constraint->{rsc};
				$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score}    = $constraint->{score} ? $constraint->{score} : "";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"cib::parsed::configuration::constraints::location::${id}::node"     => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node}, 
					"cib::parsed::configuration::constraints::location::${id}::resource" => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource}, 
					"cib::parsed::configuration::constraints::location::${id}::score"    => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score}, 
				}});
				
				# If there's no 'node', this is probably a drbd fence constraint. If there is
				# a node, make it easier to look up the score for each node.
				if ($anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node})
				{
					my $server = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource};
					my $node   = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node};
					my $score  = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:server" => $server, 
						"s2:node"   => $node, 
						"s3:score"  => $score, 
					}});
					
					$anvil->data->{cib}{parsed}{data}{location_constraint}{$server}{node}{$node}{score} = $score;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::data::location_constraint::${server}::node::${node}::score" => $anvil->data->{cib}{parsed}{data}{location_constraint}{$server}{node}{$node}{score}, 
					}});
				}
				else
				{
					foreach my $rule_id ($constraint->findnodes('./rule'))
					{
						my $constraint_id = $rule_id->{id};
						$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{score} = $rule_id->{score};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::configuration::constraints::location::${id}::constraint::${constraint_id}::score" => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{score}, 
						}});
						foreach my $expression_id ($rule_id->findnodes('./expression'))
						{
							my $attribute = $expression_id->{attribute};
							$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}{$attribute}{operation} = $expression_id->{operation};
							$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}{$attribute}{value}     = $expression_id->{value};
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								"cib::parsed::configuration::constraints::location::${id}::constraint::${constraint_id}::attribute::${attribute}::operation" => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}{$attribute}{operation}, 
								"cib::parsed::configuration::constraints::location::${id}::constraint::${constraint_id}::attribute::${attribute}::value"     => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}{$attribute}{value}, 
							}});
						}
					}
				}
			}
			foreach my $node_state ($dom->findnodes('/cib/status/node_state'))
			{
				my $id = $node_state->{id};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { id => $id }});
				foreach my $variable (sort {$a cmp $b} keys %{$node_state})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{cib}{node_state}{$id}{$variable} = $node_state->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::cib::node_state::${id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{node_state}{$id}{$variable}, 
					}});
				}
				foreach my $lrm ($node_state->findnodes('./lrm'))
				{
					my $lrm_id = $lrm->{id};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lrm_id => $lrm_id }});
					foreach my $lrm_resource ($lrm->findnodes('./lrm_resources/lrm_resource'))
					{
						my $lrm_resource_id                                                                                                  = $lrm_resource->{id};
						   $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{type}  = $lrm_resource->{type};
						   $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{class} = $lrm_resource->{class};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::cib::status::node_state::${id}::lrm_id::${lrm_id}::lrm_resource::${lrm_resource_id}::type"  => $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{type}, 
							"cib::parsed::cib::status::node_state::${id}::lrm_id::${lrm_id}::lrm_resource::${lrm_resource_id}::class" => $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{class}, 
						}});
						foreach my $lrm_rsc_op ($lrm_resource->findnodes('./lrm_rsc_op'))
						{
							my $lrm_rsc_op_id = $lrm_rsc_op->{id};
							foreach my $variable (sort {$a cmp $b} keys %{$lrm_rsc_op})
							{
								next if $variable eq "id";
								$anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}{$lrm_rsc_op_id}{$variable} = $lrm_rsc_op->{$variable};
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									"cib::parsed::cib::status::node_state::${id}::lrm_id::${lrm_id}::lrm_resource::${lrm_resource_id}::lrm_rsc_op_id::${lrm_rsc_op_id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}{$lrm_rsc_op_id}{$variable}, 
								}});
							}
						}
					}
				}
				foreach my $transient_attributes ($node_state->findnodes('./transient_attributes'))
				{
					# Currently, there seems to be no other data stored here.
					my $transient_attributes_id = $transient_attributes->{id};
					foreach my $instance_attributes ($transient_attributes->findnodes('./instance_attributes'))
					{
						$anvil->data->{cib}{parsed}{cib}{node_state}{$id}{transient_attributes_id}{$transient_attributes_id}{instance_attributes_id} = $instance_attributes->{id};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::cib::status::node_state::${id}::transient_attributes_id::${transient_attributes_id}::instance_attributes_id" => $anvil->data->{cib}{parsed}{cib}{node_state}{$id}{transient_attributes_id}{$transient_attributes_id}{instance_attributes_id}, 
						}});
					}
				}
			}
			foreach my $primitive ($dom->findnodes('/cib/configuration/resources/primitive'))
			{
				my $id                                                                = $primitive->{id};
				   $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{type}  = $primitive->{type};
				   $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{class} = $primitive->{class};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"cib::parsed::cib::resources::primitive::${id}::type"  => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{type}, 
					"cib::parsed::cib::resources::primitive::${id}::class" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{class}, 
				}});
				
				# If this is a stonith class, store the type as the 'agent' variable.
				if ($anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{class} eq "stonith")
				{
					$anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$id}{agent} = $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{type};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::data::stonith::primitive_id::${id}::agent" => $anvil->data->{cib}{parsed}{data}{stonith}{primitive_id}{$id}{agent}, 
					}});
				}
				foreach my $nvpair ($primitive->findnodes('./instance_attributes/nvpair'))
				{
					my $nvpair_id = $nvpair->{id};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "id";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{instance_attributes}{$nvpair_id}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::cib::resources::primitive::${id}::instance_attributes::${nvpair_id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{instance_attributes}{$nvpair_id}{$variable}, 
						}});
					}
				}
				foreach my $nvpair ($primitive->findnodes('./operations/op'))
				{
					my $nvpair_id = $nvpair->{id};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "id";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{operations}{op}{$nvpair_id}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::cib::resources::primitive::${id}::operations::op::${nvpair_id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{operations}{op}{$nvpair_id}{$variable}, 
						}});
					}
				}
			}
			foreach my $attribute ($dom->findnodes('/cib'))
			{
				foreach my $variable (sort {$a cmp $b} keys %{$attribute})
				{
					$anvil->data->{cib}{parsed}{cib}{$variable} = $attribute->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::cib::${variable}" => $anvil->data->{cib}{parsed}{cib}{$variable}, 
					}});
				}
			}
		}
	}
	
	# Set some cluster value defaults.
	$anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'} = "false";
	foreach my $nvpair_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}})
	{
		my $variable = $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{name};
		my $value    = $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{value};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:nvpair_id' => $nvpair_id,
			's2:variable'  => $variable, 
			's3:value'     => $value,
		}});
		
		if ($variable eq "stonith-max-attempts")
		{
			$anvil->data->{cib}{parsed}{data}{stonith}{'max-attempts'} = $value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cib::parsed::data::stonith::max-attempts" => $anvil->data->{cib}{parsed}{data}{stonith}{'max-attempts'}, 
			}});
		}
		if ($variable eq "stonith-enabled")
		{
			$anvil->data->{cib}{parsed}{data}{stonith}{enabled} = $value eq "true" ? 1 : 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cib::parsed::data::stonith::enabled" => $anvil->data->{cib}{parsed}{data}{stonith}{enabled}, 
			}});
		}
		if ($variable eq "cluster-name")
		{
			$anvil->data->{cib}{parsed}{data}{cluster}{name} = $value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cib::parsed::data::cluster::name" => $anvil->data->{cib}{parsed}{data}{cluster}{name}, 
			}});
		}
		if ($variable eq "maintenance-mode")
		{
			$anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'} = $value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cib::parsed::data::cluster::maintenance-mode" => $anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'}, 
			}});
		}
	}
	
	# Pull some data out for easier access.
	$anvil->data->{cib}{parsed}{peer}{ready} = "";
	$anvil->data->{cib}{parsed}{peer}{name}  = "";
	foreach my $node_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}})
	{
		# The "coming up" order is 'in_ccm' then 'crmd' then 'join'.
		my $node_id          = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{id};
		my $maintenance_mode = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'maintenance-mode'} eq "on"     ? 1 : 0; # 'on' or 'off'         - Node is not monitoring resources
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:node_name'        => $node_name, 
			's2:node_id'          => $node_id, 
			's3:maintenance_mode' => $maintenance_mode, 
		}});
		
		### These have changed. In older clusters, these are 'true/false' or 'online/offline', but now show as a timestamp.
		# in_ccm - Corosync member
		my $in_ccm = 0;
		if (($anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm} eq "true") or ($anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm} =~ /^\d+$/))
		{
			$in_ccm = 1;
		}
		# crmd - In corosync process group
		my $crmd = 0;
		if (($anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd} eq "online") or ($anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd} =~ /^\d+$/))
		{
			$crmd = 1; 
		}
		# join - Completed controller join process
		my $join = 0;
		if (($anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'} eq "member") or ($anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'} =~ /^\d+$/))
		{
			$join = 1;
		}
		
		# If the global maintenance mode is set, set maintenance mode to true.
		if (($anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'}) && ($anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'} eq "true"))
		{
			$maintenance_mode = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { maintenance_mode => $maintenance_mode }});
		}
		# Our summary of if the node is "up"
		my $ready = (($in_ccm) && ($crmd) && ($join)) ? 1 : 0; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:in_ccm' => $in_ccm, 
			's2:crmd'   => $crmd,
			's3:join'   => $join,
			's4:ready'  => $ready, 
		}});
		
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{pacemaker_id}       = $node_id;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'maintenance-mode'} = $maintenance_mode;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{in_ccm}             = $in_ccm;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{crmd}               = $crmd;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'join'}             = $join;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready}              = $ready;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::data::node::${node_name}::node_state::pacemaker_id"     => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{pacemaker_id}, 
			"cib::parsed::data::node::${node_name}::node_state::maintenance_mode" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'maintenance-mode'}, 
			"cib::parsed::data::node::${node_name}::node_state::in_ccm"           => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{in_ccm}, 
			"cib::parsed::data::node::${node_name}::node_state::crmd"             => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{crmd}, 
			"cib::parsed::data::node::${node_name}::node_state::join"             => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'join'}, 
			"cib::parsed::data::node::${node_name}::node_state::ready"            => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready}, 
		}});
		
		# Is this me or the peer? Or if we're being called remotely, is the target (the short host 
		# name) the same?
		my $target_host_uuid       = "";
		my $target_host_name       = "";
		my $target_short_host_name = "";
		if ($target)
		{
			($target_host_uuid, $target_host_name) = $anvil->Get->host_from_ip_address({
				debug      => $debug, 
				ip_address => $target,
			});
			$target_short_host_name =  $target_host_name;
			$target_short_host_name =~ s/\..*$//;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				target_host_uuid       => $target_host_uuid, 
				target_host_name       => $target_host_name, 
				target_short_host_name => $target_short_host_name, 
			}});
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			node_name              => $node_name, 
			target                 => $target, 
			target_short_host_name => $target_short_host_name, 
		}});
		if (($node_name eq $anvil->Get->host_name)       or 
		    ($node_name eq $anvil->Get->short_host_name) or 
		    (($target_short_host_name) && ($node_name =~ /^$target_short_host_name/)))
		{
			# Me (or the node the CIB was read from).
			$anvil->data->{cib}{parsed}{'local'}{ready} = $ready;
			$anvil->data->{cib}{parsed}{'local'}{name}  = $node_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cib::parsed::local::ready" => $anvil->data->{cib}{parsed}{'local'}{ready}, 
				"cib::parsed::local::name"  => $anvil->data->{cib}{parsed}{'local'}{name}, 
			}});
		}
		else
		{
			# It's our peer. Note that we only get the peer's host UUID if we have a DB 
			# connection. This method is called by ocf:alteeve:anvil which skips the DB.
			$anvil->data->{cib}{parsed}{peer}{ready}     = $ready;
			$anvil->data->{cib}{parsed}{peer}{name}      = $node_name;
			$anvil->data->{cib}{parsed}{peer}{host_uuid} = $anvil->data->{sys}{database}{connections} ? $anvil->Get->host_uuid_from_name({debug => $debug, host_name => $node_name}) : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cib::parsed::peer::ready"     => $anvil->data->{cib}{parsed}{peer}{ready}, 
				"cib::parsed::peer::name"      => $anvil->data->{cib}{parsed}{peer}{name}, 
				"cib::parsed::peer::host_uuid" => $anvil->data->{cib}{parsed}{peer}{host_uuid}, 
			}});
		}
	}
	
	# Fencing devices and levels.
	my $delay_set = 0;
	foreach my $primitive_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{resources}{primitive}})
	{
		next if not $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{class};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { primitive_id => $primitive_id }});
		if ($anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{class} eq "stonith")
		{
			my $variables = {};
			my $node_name = "";
			foreach my $fence_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{instance_attributes}})
			{
				my $name  = $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{instance_attributes}{$fence_id}{name};
				my $value = $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{instance_attributes}{$fence_id}{value};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:fence_id' => $fence_id, 
					's2:name'     => $name, 
					's3:value'    => $value, 
				}});
				
				if ($name eq "pcmk_host_list")
				{
					$node_name = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_name => $node_name }});
				}
				else
				{
					$variables->{$name} = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "variables->{$name}" => $variables->{$name} }});
				}
			}
			if ($node_name)
			{
				my $argument_string = "";
				foreach my $name (sort {$a cmp $b} keys %{$variables})
				{
					$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$primitive_id}{argument}{$name}{value} = $variables->{$name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::data::node::${node_name}::fencing::device::${primitive_id}::argument::${name}::value" => $variables->{$name},
					}});
					
					if ($name eq "delay")
					{
						$delay_set = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay_set => $delay_set }});
					}
					
					my $value           =  $variables->{$name};
					   $value           =~ s/"/\\"/g;
					   $argument_string .= $name."=\"".$value."\" ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						argument_string => $argument_string,
					}});
				}
				$argument_string =~ s/ $//;
				$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$primitive_id}{arguments} = $argument_string;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"cib::parsed::data::node::${node_name}::fencing::device::${primitive_id}::arguments" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$primitive_id}{arguments},
				}});
			}
		}
	}
	$anvil->data->{cib}{parsed}{data}{stonith}{delay_set} = $delay_set;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"cib::parsed::data::stonith::delay_set" => $anvil->data->{cib}{parsed}{data}{stonith}{delay_set}, 
	}});
	
	foreach my $id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}})
	{
		my $node_name = $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{target};
		my $devices   = $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{devices};
		my $index     = $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{'index'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			node_name => $node_name, 
			devices   => $devices, 
			'index'   => $index,
		}});
		
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$index}{devices} = $devices;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::data::node::${node_name}::fencing::order::${index}::devices" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$index}{devices},
		}});
	}
	
	# Hosted server information... We can only get basic information out of the CIB, so we'll use crm_mon
	# for details. We don't just rely on 'crm_mon' however, as servers that aren't running will not (yet)
	# show there.
	foreach my $id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{status}{node_state}})
	{
		my $node_name = $anvil->data->{cib}{parsed}{configuration}{nodes}{$id}{uname};
		foreach my $lrm_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}})
		{
			foreach my $lrm_resource_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}})
			{
				my $lrm_resource_operations_count = keys %{$anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lrm_resource_operations_count => $lrm_resource_operations_count }});
				foreach my $lrm_rsc_op_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}})
				{
					my $type      = $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{type};
					my $class     = $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{class};
					my $operation = $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}{$lrm_rsc_op_id}{operation};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:lrm_rsc_op_id' => $lrm_rsc_op_id,
						's2:type'          => $type,
						's3:class'         => $class, 
						's4:operation'     => $operation, 
					}});
					
					# Skip unless it's a server.
					next if $type ne "server";
					
					# This will be updated below if the server is running.
					if (not exists $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id})
					{
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{status}    = "off";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{host_name} = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{host_id}   = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{active}    = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{blocked}   = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{failed}    = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{managed}   = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{orphaned}  = "";
						$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{role}      = "";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"cib::parsed::data::server::${lrm_resource_id}::status"    => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{status},
							"cib::parsed::data::server::${lrm_resource_id}::host_name" => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{host_name},
							"cib::parsed::data::server::${lrm_resource_id}::host_id"   => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{host_id},
							"cib::parsed::data::server::${lrm_resource_id}::active"    => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{active},
							"cib::parsed::data::server::${lrm_resource_id}::blocked"   => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{blocked},
							"cib::parsed::data::server::${lrm_resource_id}::failed"    => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{failed},
							"cib::parsed::data::server::${lrm_resource_id}::managed"   => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{managed},
							"cib::parsed::data::server::${lrm_resource_id}::orphaned"  => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{orphaned},
							"cib::parsed::data::server::${lrm_resource_id}::role"      => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{role},
						}});
					}
					
					# Do we have a DRBD fence rule?
					$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{'exists'} = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"cib::parsed::data::server::${lrm_resource_id}::drbd_fence_rule::exists" => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{'exists'},
					}});
					foreach my $id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{constraints}{location}})
					{
						my $node     = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node};
						my $resource = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource};
						my $score    = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"s1:id"       => $id,
							"s2:node"     => $node,
							"s3:resource" => $resource,
							"s4:score"    => $score,
						}});
						
						# Is this the server?
						next if $resource ne $lrm_resource_id;
						next if not exists $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint};
						foreach my $constraint_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}})
						{
							my $score = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{score};
							foreach my $attribute (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}})
							{
								my $operation = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}{$attribute}{operation};
								my $value     = $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{constraint}{$constraint_id}{attribute}{$attribute}{value};
								my $test_key  = "location-".$resource."-rule";
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									's1:constraint_id' => $constraint_id, 
									's2:score'         => $score,
									's3:attribute'     => $attribute, 
									's4:operation'     => $operation, 
									's5:value'         => $value, 
									's6:test_key'      => $test_key, 
								}});
								
								if ($constraint_id eq $test_key)
								{
									$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{'exists'}  = 1;
									$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{attribute} = $attribute;
									$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{operation} = $operation;
									$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{value}     = $value;
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
										"s1:cib::parsed::data::server::${lrm_resource_id}::drbd_fence_rule::exists"    => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{'exists'},
										"s2:cib::parsed::data::server::${lrm_resource_id}::drbd_fence_rule::attribute" => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{attribute},
										"s3:cib::parsed::data::server::${lrm_resource_id}::drbd_fence_rule::operation" => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{operation},
										"s4:cib::parsed::data::server::${lrm_resource_id}::drbd_fence_rule::value"     => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{value},
									}});
									
									# Is this refereneced by any node attributes?
									foreach my $node_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{node_state}})
									{
										my $node_name = $anvil->data->{cib}{parsed}{configuration}{nodes}{$node_id}{uname};
										my $value     = defined $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{$attribute} ? $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{$attribute} : "";
										$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
											"s1:node_id"   => $node_id,
											"s2:node_name" => $node_name, 
											"s3:value"     => $value,
										}});
										
										$anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_node}{$node_name}{value} = $value;
										$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
											"cib::parsed::data::server::${lrm_resource_id}::drbd_fence_node::${node_name}::value" => $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_node}{$node_name}{value},
										}});
									}
								}
							}
							last if $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{'exists'};
						}
						
						# Did we find it?
						last if $anvil->data->{cib}{parsed}{data}{server}{$lrm_resource_id}{drbd_fence_rule}{'exists'};
					}
				}
			}
		}
	}
	
	# Sort out which node a given server prefers.
	foreach my $server (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{location_constraint}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server => $server }});
		my $highest_score  = 0;
		my $preferred_host = "";
		foreach my $node (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{location_constraint}{$server}{node}})
		{
			my $this_score = $anvil->data->{cib}{parsed}{data}{location_constraint}{$server}{node}{$node}{score};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"s1:node"       => $node,
				"s2:this_score" => $this_score,
			}});
			
			if ($this_score > $highest_score)
			{
				$highest_score  = $this_score;
				$preferred_host = $node;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:highest_score"  => $highest_score,
					"s2:preferred_host" => $preferred_host,
				}});
			}
		}
		
		$anvil->data->{cib}{parsed}{data}{location_constraint}{$server}{preferred_host} = $preferred_host;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::data::location_constraint::${server}::preferred_host" => $anvil->data->{cib}{parsed}{data}{location_constraint}{$server}{preferred_host},
		}});
	}
	
	# Now call 'crm_mon --output-as=xml' to determine which resource are running where. As of the time 
	# of writing this (late 2020), stopped resources are not displayed. So the principle purpose of this
	# call is to determine what resources are running, and where they are running.
	$anvil->Cluster->parse_crm_mon({
		debug       => $debug,
		password    => $password,
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	});
	foreach my $server (sort {$a cmp $b} keys %{$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}})
	{
		my $host_name = defined $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{host}{node_name} ? $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{host}{node_name} : "";
		my $host_id   = defined $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{host}{node_id}   ? $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{host}{node_id}   : "";
		my $role      =         $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{role};
		my $active    =         $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{active}   eq "true" ? 1 : 0;
		my $blocked   =         $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{blocked}  eq "true" ? 1 : 0;
		my $failed    =         $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{failed}   eq "true" ? 1 : 0;
		my $managed   =         $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{managed}  eq "true" ? 1 : 0;
		my $orphaned  =         $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{orphaned} eq "true" ? 1 : 0;
		my $status    = lc($role);
		if ($role)
		{
			### Known roles;
			# Started
			# Starting
			# Migrating
			# Stopping
			# Stopped
			$status = $active ? "running" : "off";
			
			# If the role is NOT 'migrating', and we have a database connection, check to see if 
			# it's marked as such in the database.
			if (($role ne "migrating") && ($anvil->data->{sys}{database}{connections}))
			{
				$anvil->Database->get_servers({debug => $debug});
				my $anvil_uuid = $anvil->Cluster->get_anvil_uuid({debug => $debug});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { anvil_uuid => $anvil_uuid }});
				
				my $server_uuid = $anvil->Get->server_uuid_from_name({
					debug       => $debug, 
					server_name => $server, 
					anvil_uuid  => $anvil_uuid,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { server_uuid => $server_uuid }});
				if (($server_uuid) && (exists $anvil->data->{servers}{server_uuid}{$server_uuid}) && ($anvil->data->{servers}{server_uuid}{$server_uuid}{server_state} eq "migrating"))
				{
					# We need to clean up a stale migration state. It may
					# not actually be 'running', but if not, scan-server 
					# will clean it up. So long as the state is 
					# 'migrating', scan-server won't touch it.
					$anvil->Database->insert_or_update_servers({
						debug                           => $debug, 
						server_uuid                     => $server_uuid, 
						server_name                     => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_name}, 
						server_anvil_uuid               => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_anvil_uuid}, 
						server_user_stop                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_user_stop}, 
						server_start_after_server_uuid  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_after_server_uuid}, 
						server_start_delay              => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_start_delay}, 
						server_host_uuid                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_host_uuid}, 
						server_state                    => "running", 
						server_live_migration           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_live_migration}, 
						server_pre_migration_file_uuid  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_file_uuid}, 
						server_pre_migration_arguments  => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_pre_migration_arguments}, 
						server_post_migration_file_uuid => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_file_uuid}, 
						server_post_migration_arguments => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_post_migration_arguments}, 
						server_ram_in_use               => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_ram_in_use}, 
						server_configured_ram           => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_configured_ram}, 
						server_updated_by_user          => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_updated_by_user},
						server_boot_time                => $anvil->data->{servers}{server_uuid}{$server_uuid}{server_boot_time},
					});
				}
			}
		}
		
		$anvil->data->{cib}{parsed}{data}{server}{$server}{status}    = $status;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{host_name} = $host_name;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{host_id}   = $host_id;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{role}      = $role;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{active}    = $active;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{blocked}   = $blocked;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{failed}    = $failed;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{managed}   = $managed;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{orphaned}  = $orphaned;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"cib::parsed::data::server::${server}::status"    => $anvil->data->{cib}{parsed}{data}{server}{$server}{status},
			"cib::parsed::data::server::${server}::host_name" => $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name},
			"cib::parsed::data::server::${server}::host_id"   => $anvil->data->{cib}{parsed}{data}{server}{$server}{host_id},
			"cib::parsed::data::server::${server}::role"      => $anvil->data->{cib}{parsed}{data}{server}{$server}{role},
			"cib::parsed::data::server::${server}::active"    => $anvil->data->{cib}{parsed}{data}{server}{$server}{active},
			"cib::parsed::data::server::${server}::blocked"   => $anvil->data->{cib}{parsed}{data}{server}{$server}{blocked},
			"cib::parsed::data::server::${server}::failed"    => $anvil->data->{cib}{parsed}{data}{server}{$server}{failed},
			"cib::parsed::data::server::${server}::managed"   => $anvil->data->{cib}{parsed}{data}{server}{$server}{managed},
			"cib::parsed::data::server::${server}::orphaned"  => $anvil->data->{cib}{parsed}{data}{server}{$server}{orphaned},
		}});
	}
	
	# Debug code.
	foreach my $server (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{server}})
	{
		my $status    = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host_name = $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name};
		my $role      = $anvil->data->{cib}{parsed}{data}{server}{$server}{role};
		my $active    = $anvil->data->{cib}{parsed}{data}{server}{$server}{active};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:server'    => $server,
			's2:status'    => $status,
			's2:host_name' => $host_name,
			's4:role'      => $role,
			's5:active'    => $active, 
		}});
	}
	
	

	return($problem);
}


=head2 parse_crm_mon

This reads in the XML output of C<< crm_mon >> and parses it. On success, it returns C<< 0 >>. On failure (ie: pcsd isn't running), returns C<< 1 >>.

B<< Note >>: At this time, this method only pulls out the host for running servers. More data may be parsed out at a future time.

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=head3 xml (optional)

B<< Note >>: Generally this should not be used.

By default, the C<< crm_mon --output-as=xml >> is read directly. However, this parameter can be used to pass in raw XML instead. If this is set, C<< crm_mon >> is B<< NOT >> invoked.

=cut
sub parse_crm_mon
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->parse_crm_mon()" }});
	
	my $xml         = defined $parameter->{xml}         ? $parameter->{xml}         : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		xml => $xml,
	}});
	
	my $problem      = 1;
	my $crm_mon_data = "";
	my $return_code  = 0;
	if ($xml)
	{
		$crm_mon_data = $xml;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { crm_mon_data => $crm_mon_data }});
	}
	else
	{
		# When called on Striker during post-scan analysis, this won't work. So to avoid noise in the
		# logs, we do en explicit check if the binary exists and exit quietly if it does not.
		if (not -e $anvil->data->{path}{exe}{crm_mon})
		{
			return(1);
		}
		my $shell_call = $anvil->data->{path}{exe}{crm_mon}." --output-as=xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local call
			($crm_mon_data, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				crm_mon_data => $crm_mon_data,
				return_code  => $return_code,
			}});
		}
		else
		{
			# Remote call.
			($crm_mon_data, my $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call, 
				target      => $target,
				port        => $port, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error        => $error,
				crm_mon_data => $crm_mon_data,
				return_code  => $return_code,
			}});
		}
	}
	if ($return_code)
	{
		# Failed to read the CIB.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0062"});
	}
	else
	{
		local $@;
		my $dom = eval { XML::LibXML->load_xml(string => $crm_mon_data); };
		if ($@)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0063", variables => { 
				xml   => $crm_mon_data,
				error => $@,
			}});
		}
		else
		{
			# Successful parse!
			$problem = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
			foreach my $resource ($dom->findnodes('/pacemaker-result/resources/resource'))
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource => $resource }});
				if ($resource =~ /<resource /)
				{
					# If this is pure XML, parse it manually. This shouldn't happen, but it seems to.
					my $id             = "";
					my $resource_agent = "";
					my $resource_key   = "";
					my $stonith_name   = "";
					foreach my $line (split/\n/, $resource)
					{
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
						if (($line !~ /<node /) && ($line =~ /id="(.*?)"/))
						{
							$id = $1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { id => $id }});
						}
						if ($line =~ /resource_agent="(.*?)"/)
						{
							$resource_agent = $1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource_agent => $resource_agent }});
							
							if (($resource_agent eq "ocf:alteeve:server") or 
							    ($resource_agent eq "ocf::alteeve:server"))
							{
								$resource_key = "resource";
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { resource_key => $resource_key }});
							}
							elsif ($resource_agent =~ /stonith:(.*)$/)
							{
								$stonith_name = $1;
								$resource_key = "stonith";
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									stonith_name => $stonith_name,
									resource_key => $resource_key,
								}});
								$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{variables}{resource_agent} = $stonith_name;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									"crm_mon::parsed::pacemaker-result::resources::${resource_key}::${id}::variables::resource_agent" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{variables}{resource_agent}, 
								}});
							}
						}
						if (($id) && ($resource_agent))
						{
							if ($line =~ /<node /)
							{
								$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{host}{node_name} = ($line =~ /name="(.*?)"/)[0];
								$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{host}{node_id}   = ($line =~ /id="(.*?)"/)[0];
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									"crm_mon::parsed::pacemaker-result::resources::${resource_key}::${id}::host::node_name" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{host}{node_name}, 
									"crm_mon::parsed::pacemaker-result::resources::${resource_key}::${id}::host::node_id"   => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{host}{node_id}, 
								}});
							}
							else
							{
								foreach my $pair (split/ /, $line)
								{
									$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pair => $pair }});
									if ($pair =~ /^(.*?)="(.*)"$/)
									{
										my $variable = $1;
										my $value    = $2;
										$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
											's1:variable' => $variable,
											's2:value'    => $value,
										}});
										next if $variable eq "id";
										next if $variable eq "resource_agent";
										
										$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{variables}{$variable} = $value;
										$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
											"crm_mon::parsed::pacemaker-result::resources::${resource_key}::${id}::variables::${variable}" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{$resource_key}{$id}{variables}{$variable}, 
										}});
									}
								}
							}
						}
					}
				}
				elsif ($resource->{resource_agent} eq "ocf::alteeve:server")
				{
					my $id = $resource->{id};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { id => $id }});
					foreach my $variable (sort {$a cmp $b} keys %{$resource})
					{
						next if $variable eq "id";
						$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{variables}{$variable} = $resource->{$variable};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"crm_mon::parsed::pacemaker-result::resources::resource::${id}::variables::${variable}" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{variables}{$variable}, 
						}});
					}
					foreach my $node ($resource->findnodes('./node'))
					{
						my $node_id   = $node->{id};
						my $node_name = $node->{name};
						$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_name} = $node->{name};
						$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_id}   = $node->{id};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"crm_mon::parsed::pacemaker-result::resources::resource::${id}::host::node_name" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_name}, 
							"crm_mon::parsed::pacemaker-result::resources::resource::${id}::host::node_id"   => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_id}, 
						}});
					}
				}
				elsif ($resource->{resource_agent} =~ /stonith:(.*)$/)
				{
					my $fence_agent = $1;
					my $id          = $resource->{id};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						's1:fence_agent' => $fence_agent, 
						's2:id'          => $id,
					}});
					foreach my $variable (sort {$a cmp $b} keys %{$resource})
					{
						next if $variable eq "id";
						$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$id}{variables}{$variable} = $resource->{$variable};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"crm_mon::parsed::pacemaker-result::resources::stonith::${id}::variables::${variable}" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$id}{variables}{$variable}, 
						}});
					}
					foreach my $node ($resource->findnodes('./node'))
					{
						my $node_id   = $node->{id};
						my $node_name = $node->{name};
						$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$id}{host}{node_name} = $node->{name};
						$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$id}{host}{node_id}   = $node->{id};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							"crm_mon::parsed::pacemaker-result::resources::stonith::${id}::host::node_name" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$id}{host}{node_name}, 
							"crm_mon::parsed::pacemaker-result::resources::stonith::${id}::host::node_id"   => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{stonith}{$id}{host}{node_id}, 
						}});
					}
				}
			}
		}
	}
	
	return($problem);
}


=head2 parse_quorum

This parses C<< corosync-quorumtool -s -p >> to check the status of quorum, as it is more reliable that the CIB's c<< have-quorum >> flag. This does not parse out per-node information.

b<< Note >>: See c<< man corosync-quorumtool >> for details on what these values store.

If the cluster is down, C<< 1 >> is returned. Otherwise, C<< 1 >> is returned.

Data is stored as: 
 quorum::expected-votes
 quorum::flags
 quorum::nodes
 quorum::quorate
 quorum::ring_id
 quorum::total-votes

This method takes no parameters.

=cut
sub parse_quorum
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->parse_quorum()" }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'corosync-quorumtool'}." -p -s"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	if ($return_code)
	{
		# Cluster is down
		return(1);
	}
	else
	{
		$anvil->data->{quorum}{'expected-votes'} = "";
		$anvil->data->{quorum}{flags}            = "";
		$anvil->data->{quorum}{nodes}            = "";
		$anvil->data->{quorum}{quorate}          = "";
		$anvil->data->{quorum}{ring_id}          = "";
		$anvil->data->{quorum}{'total-votes'}    = "";
	}
	
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /Expected votes:\s+(\d+)$/)
		{
			$anvil->data->{quorum}{'expected-votes'} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"quorum::expected-votes" => $anvil->data->{quorum}{'expected-votes'},
			}});
			next;
		}
		if ($line =~ /Flags:\s+(.*)$/)
		{
			$anvil->data->{quorum}{flags} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"quorum::flags" => $anvil->data->{quorum}{flags},
			}});
			next;
		}
		if ($line =~ /Nodes:\s+(\d+)$/)
		{
			$anvil->data->{quorum}{nodes} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"quorum::nodes" => $anvil->data->{quorum}{nodes},
			}});
			next;
		}
		if ($line =~ /Quorate:\s+(.*)$/)
		{
			$anvil->data->{quorum}{quorate} = lc($1) eq "yes" ? 1 : 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"quorum::quorate" => $anvil->data->{quorum}{quorate},
			}});
			next;
		}
		if ($line =~ /Ring ID:\s+(.*)$/)
		{
			$anvil->data->{quorum}{ring_id} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"quorum::ring_id" => $anvil->data->{quorum}{ring_id},
			}});
			next;
		}
		if ($line =~ /Nodes:\s+(\d+)$/)
		{
			$anvil->data->{quorum}{'total-votes'} = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"quorum::total-votes" => $anvil->data->{quorum}{'total-votes'},
			}});
			next;
		}
	}
	
	return(0);
}


=head2 recover_server

This tries to recover a C<< FAILED >> resource (server).

Parameters;

=head3 server (required)

This is the server (resource) name to try to recover.

=head3 running (required)

This indicates if the server should be recovered into the running state when set to C<< 1 >>, or stopped state when set to C<< 0 >>.

=cut
sub recover_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->recover_server()" }});
	
	my $running = defined $parameter->{running} ? $parameter->{running} : "";
	my $server  = defined $parameter->{server}  ? $parameter->{server}  : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		running => $running,
		server  => $server,
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->recover_server()", parameter => "server" }});
		return("!!error!!");
	}
	if ($running eq "")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->recover_server()", parameter => "running" }});
		return("!!error!!");
	}
	
	# Set the desired state post recovery.
	my $wanted_state = $running ? "enable" : "disable";
	my $shell_call   = $anvil->data->{path}{exe}{pcs}." resource ".$wanted_state." ".$server;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	# Now tell it to refresh
	$shell_call = $anvil->data->{path}{exe}{crm_resource}." --resource ".$server." --refresh";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	return(0);
}


=head2 shutdown_server

This shuts down a server that is running on the Anvil! system. If there is a problem, C<< !!error!! >> is returned. On success, C<< 0 >> is returned.

B<< Note >>: If C<< wait >> is set to C<< 0 >>, then C<< 0 >> is returned once the shutdown is requested, not when it's actually turned off.

Parameters;

=head3 server (required)

This is the name of the server to shut down.

=head3 wait (optional, default '1')

This controls whether the method waits for the server to shut down before returning. By default, it will go into a loop and check every 2 seconds to see if the server is still running. Once it's found to be off, the method returns. If this is set to C<< 0 >>, the method will return as soon as the request to shut down the server is issued.

=cut
sub shutdown_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->shutdown_server()" }});
	
	my $server = defined $parameter->{server} ? $parameter->{server} : "";
	my $wait   = defined $parameter->{'wait'} ? $parameter->{'wait'} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server => $server,
		'wait' => $wait,
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->shutdown_server()", parameter => "server" }});
		return("!!error!!");
	}
	
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0150", variables => { server => $server }});
		return("!!error!!");
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
	if ($problem)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0151", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is this node fully in the cluster?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0152", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is the server one we know of?
	if (not exists $anvil->data->{cib}{parsed}{data}{server}{$server})
	{
		# The server isn't in the pacemaker config.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0153", variables => { server => $server }});
		return('!!error!!');
	}
	
	# Is the server already stopped? If so, do nothing.
	my $status =         $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
	my $host   = defined $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name} ? $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		status => $status,
		host   => $host, 
	}});
	
	if (($status eq "off") or ($status eq "stopped"))
	{
		# Already off.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0548", variables => { server => $server }});
		return(0);
	}
	elsif ($status ne "running")
	{
		# It's in an unknown state, abort.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0060", variables => { 
			server        => $server,
			current_host  => $host,
			current_state => $status, 
		}});
		return('!!error!!');
	}
	
	# Now shut down the server.
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{pcs}." resource disable ".$server});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	if (not $wait)
	{
		# We're done.
		return(0);
	}
	
	# Wait now for the server to start.
	my $waiting = 1;
	while($waiting)
	{
		$anvil->Cluster->parse_cib({debug => $debug});
		my $status =         $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host   = defined $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name} ? $anvil->data->{cib}{parsed}{data}{server}{$server}{host_name} : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			status => $status,
			host   => $host, 
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0554", variables => { server => $server }});
		if ($status eq "running")
		{
			# Wait a bit and check again.
			sleep 2;
		}
		else
		{
			# It's down.
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0555", variables => { server => $server }});
		}
	}
	
	return(0);
}


=head2 start_cluster

This will join the local node to the pacemaker cluster. Optionally, it can try to start the cluster on both nodes if C<< all >> is set.

Parameters;

=head3 all (optional, default '0')

If set, the cluster will be started on both (all) nodes.

=cut 
sub start_cluster
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->start_cluster()" }});
	
	my $all = defined $parameter->{all} ? $parameter->{all} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		all => $all,
	}});
	
	my $success    = 1;
	my $shell_call = $anvil->data->{path}{exe}{pcs}." cluster start";
	if ($all)
	{
		$shell_call .= " --all";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		shell_call => $shell_call,
	}});
	
	my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	return($success);
}


=head2 which_node

This method returns which node a given machine is in the cluster, returning either C<< node1 >> or C<< node2 >>. If the host is not a node, an empty string is returned.

This method is meant to compliment C<< Database->get_anvils() >> to make it easy for tasks that only need to run on one node in the cluster to decide it that is them or not.

Parameters;

=head3 host_name (optional, default Get->short_host_name)

This is the host name to look up. If not set, B<< and >> C<< node_uuid >> is also not set, the short host name of the local system is used.

B<< Note >>; If the host name is passed and the host UUID is not, and the host UUID can not be located (or the host name is invalid), this method will return C<< !!error!! >>.

=head3 host_uuid (optional, default Get->host_uuid)

This is the host UUID to look up. If not set, B<< and >> C<< node_name >> is also not set, the local system's host UUID is used.

=cut
sub which_node
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->start_cluster()" }});
	
	my $node_is   = "";
	my $node_name = defined $parameter->{node_name} ? $parameter->{node_name} : "";
	my $node_uuid = defined $parameter->{node_uuid} ? $parameter->{node_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node_name => $node_name,
		node_uuid => $node_uuid, 
	}});
	
	if ((not $node_name) && (not $node_uuid))
	{
		$node_name = $anvil->Get->short_host_name();
		$node_uuid = $anvil->Get->host_uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			node_name => $node_name,
			node_uuid => $node_uuid, 
		}});
	}
	elsif (not $node_uuid)
	{
		# Get the node UUID from the host name.
		$node_uuid = $anvil->Get->host_name_from_uuid({host_name => $node_name}); 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_uuid => $node_uuid }});
		
		if (not $node_uuid)
		{
			return("!!error!!");
		}
	}
	
	# Load Anvil! systems.
	if ((not exists $anvil->data->{anvils}{anvil_name}) && (not $anvil->data->{anvils}{anvil_name}))
	{
		$anvil->Database->get_anvils({debug => $debug});
	}
	
	foreach my $anvil_name (sort {$a cmp $b} keys %{$anvil->data->{anvils}{anvil_name}})
	{
		my $node1_host_uuid = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node1_host_uuid};
		my $node2_host_uuid = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node2_host_uuid};

		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_name      => $anvil_name,
			node1_host_uuid => $node1_host_uuid, 
			node2_host_uuid => $node2_host_uuid, 
		}});
		
		if ($node_uuid eq $node1_host_uuid)
		{
			$node_is = "node1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_is => $node_is }});
			last;
		}
		elsif ($node_uuid eq $node2_host_uuid)
		{
			$node_is = "node2";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { node_is => $node_is }});
			last;
		}
	}
	
	return($node_is);
}


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2 _set_server_constraint

This is a private method used to set a preferencial location constraint for a server. It takes a server name and a preferred host node. It checks to see if a location constraint exists and, if so, which node is preferred. If it is not the requested node, the constraint is updated. If no constraint exists, it is created.

Returns C<< !!error!! >> if there is a problem, C<< 0 >> otherwise

Parameters;

=head3 server (required)

This is the name of the server whose preferred host node priproty is being set.

=head3 preferred_node (required)

This is the name the node that a server will prefer to run on.

=cut
sub _set_server_constraint
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->_set_server_constraint()" }});
	
	my $preferred_node = defined $parameter->{preferred_node} ? $parameter->{preferred_node} : "";
	my $server         = defined $parameter->{server}         ? $parameter->{server}         : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		server         => $server,
		preferred_node => $preferred_node,
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->_set_server_constraint()", parameter => "server" }});
		return("!!error!!");
	}
	
	if (not $preferred_node)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->_set_server_constraint()", parameter => "preferred_node" }});
		return("!!error!!");
	}
	
	if (not exists $anvil->data->{cib}{parsed}{data}{cluster}{name})
	{
		my $problem = $anvil->Cluster->parse_cib({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { problem => $problem }});
		if ($problem)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0145", variables => { server => $server }});
		}
	}
	
	# Is this node fully in the cluster?
	if (not $anvil->data->{cib}{parsed}{'local'}{ready})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0148", variables => { 
			server => $server,
			node   => $preferred_node,
		}});
		return('!!error!!');
	}

	my $peer_name  = $anvil->data->{cib}{parsed}{peer}{name};
	my $local_name = $anvil->data->{cib}{parsed}{'local'}{name};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		peer_name  => $peer_name,
		local_name => $local_name,
	}});
	
	my $shell_call = "";
	if ($preferred_node eq $peer_name)
	{
		$shell_call = $anvil->data->{path}{exe}{pcs}." constraint location ".$server." prefers ".$peer_name."=200 ".$local_name."=100";
	}
	elsif ($preferred_node eq $local_name)
	{
		$shell_call = $anvil->data->{path}{exe}{pcs}." constraint location ".$server." prefers ".$peer_name."=100 ".$local_name."=200";
	}
	else
	{
		# Invalid
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0144", variables => { 
			server => $server, 
			node   => $preferred_node,
			node1  => $local_name,
			node2  => $peer_name, 
		}});
		return("!!error!!");
	}
	
	# Change the location constraint
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	return(0);
}

package Anvil::Tools::Cluster;
# 
# This module contains methods related to Pacemaker/pcs and clustering functions in general.
# 

use strict;
use warnings;
use Data::Dumper;
use XML::Simple qw(:strict);
use XML::LibXML;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Cluster.pm";

### Methods;
# check_node_status
# get_peers
# parse_cib
# start_cluster

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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		node_name => $node_name,
	}});
	
	if (not $node_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->get_host_from_uuid()", parameter => "host_uuid" }});
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

=head2 get_peers

This method uses the local machine's host UUID and finds the host names of the cluster memebers. If this host is in a cluster and it is a node, the peer's short host name is returned. Otherwise, an empty string is returned.

The data is stored as;

 sys::anvil::node1::host_uuid 
 sys::anvil::node1::host_name 
 sys::anvil::node2::host_uuid
 sys::anvil::node2::host_name
 sys::anvil::dr1::host_uuid
 sys::anvil::dr1::host_name

To assist with lookup, the following are also set;

 sys::anvil::i_am    = {node1,node2,dr1}
 sys::anvil::peer_is = {node1,node2}     # Not set if this host is 'dr1'

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
	$anvil->data->{sys}{anvil}{dr1}{host_uuid}   = "";
	$anvil->data->{sys}{anvil}{dr1}{host_name}   = "";
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
		my $anvil_dr1_host_uuid   = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_dr1_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			anvil_node1_host_uuid => $anvil_node1_host_uuid, 
			anvil_node2_host_uuid => $anvil_node2_host_uuid,
			anvil_dr1_host_uuid   => $anvil_dr1_host_uuid,
		}});
		
		if ($host_uuid eq $anvil_node1_host_uuid)
		{
			# Found our Anvil!, and we're node 1.
			$found                             = 1;
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
			$found                             = 1;
			$anvil->data->{sys}{anvil}{i_am}    = "node2";
			$anvil->data->{sys}{anvil}{peer_is} = "node1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				found                 => $found, 
				"sys::anvil::i_am"    => $anvil->data->{sys}{anvil}{i_am},
				"sys::anvil::peer_is" => $anvil->data->{sys}{anvil}{peer_is},
			}});
		}
		elsif ($host_uuid eq $anvil_dr1_host_uuid)
		{
			# Found our Anvil!, and we're node 1.
			$found = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { found => $found }});
		}
		if ($found)
		{
			$anvil->data->{sys}{anvil}{node1}{host_uuid} = $anvil_node1_host_uuid;
			$anvil->data->{sys}{anvil}{node1}{host_name} = $anvil->data->{hosts}{host_uuid}{$anvil_node1_host_uuid}{host_name};
			$anvil->data->{sys}{anvil}{node2}{host_uuid} = $anvil_node2_host_uuid;
			$anvil->data->{sys}{anvil}{node2}{host_name} = $anvil->data->{hosts}{host_uuid}{$anvil_node2_host_uuid}{host_name};
			$anvil->data->{sys}{anvil}{dr1}{host_uuid}   = $anvil_dr1_host_uuid ? $anvil_dr1_host_uuid : "";
			$anvil->data->{sys}{anvil}{dr1}{host_name}   = $anvil_dr1_host_uuid ? $anvil->data->{hosts}{host_uuid}{$anvil_dr1_host_uuid}{host_name} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"sys::anvil::node1::host_uuid" => $anvil->data->{sys}{anvil}{node1}{host_uuid}, 
				"sys::anvil::node1::host_name" => $anvil->data->{sys}{anvil}{node1}{host_name}, 
				"sys::anvil::node2::host_uuid" => $anvil->data->{sys}{anvil}{node2}{host_uuid}, 
				"sys::anvil::node2::host_name" => $anvil->data->{sys}{anvil}{node2}{host_name}, 
				"sys::anvil::dr1::host_uuid"   => $anvil->data->{sys}{anvil}{dr1}{host_uuid}, 
				"sys::anvil::dr1::host_name"   => $anvil->data->{sys}{anvil}{dr1}{host_name}, 
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

=head2 parse_cib

This reads in the CIB XML and parses it. On success, it returns C<< 0 >>. On failure (ie: pcsd isn't running), returns C<< 1 >>.

Parameters;

=head3 cib (optional)

B<< Note >>: Generally this should not be used.

By default, the CIB is read by calling C<< pcs cluster cib >>. However, this parameter can be used to pass in a CIB instead. If this is set, the live CIB is B<< NOT >> read.

=cut
sub parse_cib
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->parse_cib()" }});
	
	my $cib = defined $parameter->{cib} ? $parameter->{cib} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		cib => $cib,
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { cib_data => $cib_data }});
	}
	else
	{
		my $shell_call = $anvil->data->{path}{exe}{pcs}." cluster cib";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { shell_call => $shell_call }});
		
		($cib_data, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			cib_data    => $cib_data,
			return_code => $return_code, 
		}});
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
			foreach my $nvpair ($dom->findnodes('/cib/configuration/crm_config/cluster_property_set/nvpair'))
			{
				my $nvpair_id = $nvpair->{id};
				foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{$variable} = $nvpair->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::configuration::crm_config::cluster_property_set::nvpair::${nvpair_id}::${variable}" => $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{$variable}, 
					}});
				}
			}
			foreach my $node ($dom->findnodes('/cib/configuration/nodes/node'))
			{
				my $node_id = $node->{id};
				foreach my $variable (sort {$a cmp $b} keys %{$node})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{configuration}{nodes}{$node_id}{$variable} = $node->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::configuration::nodes::${node_id}::${variable}" => $anvil->data->{cib}{parsed}{configuration}{nodes}{$node_id}{$variable}, 
					}});
					
					if ($variable eq "uname")
					{
						my $node                                              = $node->{$variable};
						   $anvil->data->{cib}{parsed}{data}{node}{$node}{id} = $node_id;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
							"cib::parsed::data::node::${node}::id" => $anvil->data->{cib}{parsed}{data}{node}{$node}{id}, 
						}});
						
						# Preload state values (in case they're not read in this CIB.
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm} = "false";
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd}   = "offline";
						$anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'} = "down";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
							"cib::parsed::cib::node_state::${node_id}::in_ccm" => $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm}, 
							"cib::parsed::cib::node_state::${node_id}::crmd"   => $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd}, 
							"cib::parsed::cib::node_state::${node_id}::join"   => $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'}, 
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
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::configuration::fencing-topology::fencing-level::${id}::${variable}" => $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{$variable}, 
					}});
				}
			}
			### TODO: /cib/configuration/constraints
			foreach my $node_state ($dom->findnodes('/cib/status/node_state'))
			{
				my $id = $node_state->{id};
				foreach my $variable (sort {$a cmp $b} keys %{$node_state})
				{
					next if $variable eq "id";
					$anvil->data->{cib}{parsed}{cib}{node_state}{$id}{$variable} = $node_state->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::cib::node_state::${id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{node_state}{$id}{$variable}, 
					}});
				}
				foreach my $lrm ($node_state->findnodes('./lrm'))
				{
					my $lrm_id = $lrm->{id};
					foreach my $lrm_resource ($lrm->findnodes('./lrm_resources/lrm_resource'))
					{
						my $lrm_resource_id                                                                                                  = $lrm_resource->{id};
						   $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{type}  = $lrm_resource->{type};
						   $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{class} = $lrm_resource->{class};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::cib::resources::primitive::${id}::type"  => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{type}, 
					"cib::parsed::cib::resources::primitive::${id}::class" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{class}, 
				}});
				foreach my $nvpair ($primitive->findnodes('./instance_attributes/nvpair'))
				{
					my $nvpair_id = $nvpair->{id};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "id";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{instance_attributes}{$nvpair_id}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::cib::${variable}" => $anvil->data->{cib}{parsed}{cib}{$variable}, 
					}});
				}
			}
		}
	}
	
	# Pull some data out for easier access.
	$anvil->data->{cib}{parsed}{peer}{ready} = "";
	$anvil->data->{cib}{parsed}{peer}{name}  = "";
	foreach my $node_name (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{data}{node}})
	{
		# The "coming up" order is 'in_ccm' then 'crmd' then 'join'.
		my $node_id = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{id};
		my $in_ccm  = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm} eq "true"   ? 1 : 0; # 'true' or 'false'     - Corosync member
		my $crmd    = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd}   eq "online" ? 1 : 0; # 'online' or 'offline' - In corosync process group
		my $join    = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'} eq "member" ? 1 : 0; # 'member' or 'down'    - Completed controller join process
		my $ready   = (($in_ccm) && ($crmd) && ($join))                                          ? 1 : 0; # Our summary of if the node is "up"
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			's1:node_name' => $node_name, 
			's2:node_id'   => $node_id, 
			's3:in_ccm'    => $in_ccm, 
			's4:crmd'      => $crmd,
			's5:join'      => $join,
			's6:ready'     => $ready, 
		}});
		
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{in_ccm} = $in_ccm;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{crmd}   = $crmd;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'join'} = $join;
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready}  = $ready;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			"cib::parsed::data::node::${node_name}::node_state::in_ccm" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{in_ccm}, 
			"cib::parsed::data::node::${node_name}::node_state::crmd"   => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{crmd}, 
			"cib::parsed::data::node::${node_name}::node_state::join"   => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{'join'}, 
			"cib::parsed::data::node::${node_name}::node_state::ready"  => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{node_state}{ready}, 
		}});
		
		# Is this me or the peer?
		if (($node_name ne $anvil->_host_name) && ($node_name ne $anvil->_short_host_name))
		{
			# It's our peer.
			$anvil->data->{cib}{parsed}{peer}{ready} = $ready;
			$anvil->data->{cib}{parsed}{peer}{name}  = $node_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
				"cib::parsed::peer::ready" => $anvil->data->{cib}{parsed}{peer}{ready}, 
				"cib::parsed::peer::name"  => $anvil->data->{cib}{parsed}{peer}{name}, 
			}});
		}
	}
	
	# Set some cluster value defaults.
	$anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'} = "false";
	foreach my $nvpair_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}})
	{
		my $variable = $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{name};
		my $value    = $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$nvpair_id}{value};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			's1:nvpair_id' => $nvpair_id,
			's2:variable'  => $variable, 
			's3:value'     => $value,
		}});
		
		if ($variable eq "stonith-max-attempts")
		{
			$anvil->data->{cib}{parsed}{data}{stonith}{'max-attempts'} = $value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
				"cib::parsed::data::stonith::max-attempts" => $anvil->data->{cib}{parsed}{data}{stonith}{'max-attempts'}, 
			}});
		}
		if ($variable eq "stonith-enabled")
		{
			$anvil->data->{cib}{parsed}{data}{stonith}{enabled} = $value eq "true" ? 1 : 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
				"cib::parsed::data::stonith::enabled" => $anvil->data->{cib}{parsed}{data}{stonith}{enabled}, 
			}});
		}
		if ($variable eq "cluster-name")
		{
			$anvil->data->{cib}{parsed}{data}{cluster}{name} = $value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
				"cib::parsed::data::cluster::name" => $anvil->data->{cib}{parsed}{data}{cluster}{name}, 
			}});
		}
		if ($variable eq "maintenance-mode")
		{
			$anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'} = $value;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
				"cib::parsed::data::cluster::name" => $anvil->data->{cib}{parsed}{data}{cluster}{name}, 
			}});
		}
	}
	
	# Fencing devices and levels.
	my $delay_set = 0;
	foreach my $primitive_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{resources}{primitive}})
	{
		next if not $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{class};
		if ($anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{class} eq "stonith")
		{
			my $variables = {};
			my $node_name = "";
			foreach my $fence_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{instance_attributes}})
			{
				my $name  = $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{instance_attributes}{$fence_id}{name};
				my $value = $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$primitive_id}{instance_attributes}{$fence_id}{value};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					name  => $name, 
					value => $value, 
				}});
				
				if ($name eq "pcmk_host_list")
				{
					$node_name = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { node_name => $node_name }});
				}
				else
				{
					$variables->{$name} = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { "variables->{$name}" => $variables->{$name} }});
				}
			}
			if ($node_name)
			{
				my $argument_string = "";
				foreach my $name (sort {$a cmp $b} keys %{$variables})
				{
					$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$primitive_id}{argument}{$name}{value} = $variables->{$name};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::data::node::${node_name}::fencing::device::${primitive_id}::argument::${name}::value" => $variables->{$name},
					}});
					
					if ($name eq "delay")
					{
						$delay_set = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { delay_set => $delay_set }});
					}
					
					my $value           =  $variables->{$name};
					   $value           =~ s/"/\\"/g;
					   $argument_string .= $name."=\"".$value."\" ";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						argument_string => $argument_string,
					}});
				}
				$argument_string =~ s/ $//;
				$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$primitive_id}{arguments} = $argument_string;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::data::node::${node_name}::fencing::device::${primitive_id}::arguments" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{device}{$primitive_id}{arguments},
				}});
			}
		}
	}
	$anvil->data->{cib}{parsed}{data}{stonith}{delay_set} = $delay_set;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		"cib::parsed::data::stonith::delay_set" => $anvil->data->{cib}{parsed}{data}{stonith}{delay_set}, 
	}});
	
	foreach my $id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}})
	{
		my $node_name = $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{target};
		my $devices   = $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{devices};
		my $index     = $anvil->data->{cib}{parsed}{configuration}{'fencing-topology'}{'fencing-level'}{$id}{'index'};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			node_name => $node_name, 
			devices   => $devices, 
			'index'   => $index,
		}});
		
		$anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$index}{devices} = $devices;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			"cib::parsed::data::node::${node_name}::fencing::order::${index}::devices" => $anvil->data->{cib}{parsed}{data}{node}{$node_name}{fencing}{order}{$index}{devices},
		}});
	}
	
	return($problem);
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

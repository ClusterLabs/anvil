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
# parse_cib

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

=head2 parse_cib

This reads in the CIB XML and parses it. On success, it returns C<< 0 >>. On failure (ie: pcsd isn't running), returns C<< 1 >>.

=cut
sub parse_cib
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->parse_cib()" }});
	
	# If we parsed before, delete it.
	if (exists $anvil->data->{cib}{parsed})
	{
		delete $anvil->data->{cib}{parsed};
	}
	
	my $problem    = 1;
	my $shell_call = $anvil->data->{path}{exe}{pcs}." cluster cib";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { shell_call => $shell_call }});
	
	my ($cib_data, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		cib_data    => $cib_data,
		return_code => $return_code, 
	}});
	if ($return_code)
	{
		# Failed to read the CIB.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0052"});
	}
	else
	{
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
			# Successful parse!
			$problem = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
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
			foreach my $primitive ($dom->findnodes('/cib/configuration/resources/primitive'))
			{
				my $id                                                                = $primitive->{id};
				   $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{type}  = $primitive->{type};
				   $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{class} = $primitive->{class};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::cib::resources::primitive:${id}::type"  => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{type}, 
					"cib::parsed::cib::resources::primitive:${id}::class" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$id}{class}, 
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
				}
			}
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
			}
			die;
		}
	}
	
	#print Dumper $anvil->data->{cib}{parsed};
	
	return($problem);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

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
			foreach my $primitive ($dom->findnodes('/cib/configuration/resources/primitive'))
			{
				my $class                                                                    = $primitive->{class};
				my $id                                                                       = $primitive->{id};
				my $type                                                                     = $primitive->{type};
				   $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{type} = $type;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::cib::resources::primitive:${class}::${id}::type" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{type}, 
				}});
				foreach my $nvpair ($primitive->findnodes('./instance_attributes/nvpair'))
				{
					my $name = $nvpair->{name};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "name";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{instance_attributes}{$name}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
							"cib::parsed::cib::resources::primitive::${class}::${id}::instance_attributes::${name}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{instance_attributes}{$name}{$variable}, 
						}});
					}
				}
				foreach my $nvpair ($primitive->findnodes('./operations/op'))
				{
					my $id = $nvpair->{id};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "id";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{operations}{op}{$id}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
							"cib::parsed::cib::resources::primitive::${class}::${id}::operations::op::${id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{operations}{op}{$id}{$variable}, 
						}});
					}
				}
			}
			die;
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
				my $name                                                                                              = $nvpair->{name};
				   $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{id}    = $nvpair->{id};
				   $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{value} = $nvpair->{value};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::configuration::crm_config::cluster_property_set::nvpair::${name}::id"    => $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{id}, 
					"cib::parsed::configuration::crm_config::cluster_property_set::nvpair::${name}::value" => $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{value}, 
				}});
			}
			foreach my $node ($dom->findnodes('/cib/configuration/nodes/node'))
			{
				my $uname                                                        = $node->{uname};
				   $anvil->data->{cib}{parsed}{configuration}{nodes}{$uname}{id} = $node->{id};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::configuration::nodes::${uname}::id" => $anvil->data->{cib}{parsed}{configuration}{nodes}{$uname}{id}, 
				}});
			}
			# Status isn't available until the cluster has been up for a bit.
			foreach my $node_state ($dom->findnodes('/cib/status/node_state'))
			{
				my $uname = $node_state->{uname};
				foreach my $variable (sort {$a cmp $b} keys %{$node_state})
				{
					next if $variable eq "uname";
					$anvil->data->{cib}{parsed}{cib}{node_state}{$uname}{$variable} = $node_state->{$variable};;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::cib::node_state::${uname}::${variable}" => $anvil->data->{cib}{parsed}{cib}{node_state}{$uname}{$variable}, 
					}});
				}
			}
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

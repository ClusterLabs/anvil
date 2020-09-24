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
# boot_server
# check_node_status
# get_peers
# migrate_server
# parse_cib
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

=head2 boot_server

This uses pacemaker to boot a server.

If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 server (required)

This is the name of the server to boot.

=head3 node (optional)

If set, a resource constraint is placed so that the server prefers one node over the other before it boots.

B<< Note >>; The method relies on pacemaker to boot the node. As such, if for some reason it decides the server can not be booted on the prefered node, it may boot on the other node. As such, this parameter does not guarantee that the server will be booted on the target node!

=head3 wait (optional, default '1')

This controls whether the method waits for the server to shut down before returning. By default, it will go into a loop and check every 2 seconds to see if the server is still running. Once it's found to be off, the method returns. If this is set to C<< 0 >>, the method will return as soon as the request to shut down the server is issued.

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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0146", variables => { server => $server }});
		return("!!error!!");
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
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
	my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		status => $status,
		host   => $host, 
	}});
	
	if ($status eq "running")
	{
		# Nothing to do.
		if ((not $node) or ($host eq $node))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0548", variables => { server => $server }});
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
	
	if ($node)
	{
		$anvil->Cluster->_set_server_constraint({
			server         => $server,
			preferred_node => $node,
		});
	}
	
	# Now boot the server.
	my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $anvil->data->{path}{exe}{pcs}." resource enable ".$server});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
		my $status = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			status => $status,
			host   => $host, 
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0552", variables => { server => $server }});
		if ($host eq "running")
		{
			# It's up.
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0553", variables => { server => $server }});
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
			$found                              = 1;
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0154", variables => { server => $server }});
		return("!!error!!");
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
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
	my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		status => $status,
		host   => $host, 
	}});
	
	if ($status eq "off")
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
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0549", variables => { 
			server         => $server,
			requested_node => $node,
		}});
		return(0);
	}
	elsif ($status ne "running")
	{
		# The server is in an unknown state.
		# It's in an unknown state, abort.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0060", variables => { 
			server        => $server,
			current_host  => $host,
			current_state => $status, 
		}});
		return('!!error!!');
	}
	
	# TODO: Record that the server is migrating
	
	# change the constraint to trigger the move.
	if ($node)
	{
		$anvil->Cluster->_set_server_constraint({
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
		my $status = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			status => $status,
			host   => $host, 
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0550", variables => { 
			server         => $server,
			requested_node => $node, 
		}});
		if (($host eq "running") && ($host eq $node))
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
			foreach my $constraint ($dom->findnodes('/cib/configuration/constraints/rsc_location'))
			{
				my $id = $constraint->{id};
				$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node}     = $constraint->{node};
				$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource} = $constraint->{rsc};
				$anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score}    = $constraint->{score};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::configuration::constraints::location::${id}::node"     => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{node}, 
					"cib::parsed::configuration::constraints::location::${id}::resource" => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{resource}, 
					"cib::parsed::configuration::constraints::location::${id}::score"    => $anvil->data->{cib}{parsed}{configuration}{constraints}{location}{$id}{score}, 
				}});
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
		if (($node_name eq $anvil->Get->host_name) or ($node_name eq $anvil->Get->short_host_name))
		{
			# Me.
			$anvil->data->{cib}{parsed}{'local'}{ready} = $node_name;
			$anvil->data->{cib}{parsed}{'local'}{name}  = $node_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
				"cib::parsed::local::ready" => $anvil->data->{cib}{parsed}{'local'}{ready}, 
				"cib::parsed::local::name"  => $anvil->data->{cib}{parsed}{'local'}{name}, 
			}});
		}
		else
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
				"cib::parsed::data::cluster::maintenance-mode" => $anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'}, 
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
				foreach my $lrm_rsc_op_id (sort {$a cmp $b} keys %{$anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}})
				{
					my $type      = $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{type};
					my $class     = $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{class};
					my $operation = $anvil->data->{cib}{parsed}{cib}{status}{node_state}{$id}{lrm_id}{$lrm_id}{lrm_resource}{$lrm_resource_id}{lrm_rsc_op_id}{$lrm_rsc_op_id}{operation};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						lrm_resource_operations_count => $lrm_resource_operations_count,
						type                          => $type,
						class                         => $class, 
						operation                     => $operation, 
						lrm_rsc_op_id                 => $lrm_rsc_op_id,
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
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
				}
			}
		}
	}
	
	# Now call 'crm_mon --output-as=xml' to determine which resource are running where. As of the time 
	# of writting this (late 2020), stopped resources are not displayed. So the principle purpose of this
	# call is to determine what resources are running, and where they are running.
	$anvil->Cluster->parse_crm_mon({debug => $debug});
	foreach my $server (sort {$a cmp $b} keys %{$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}})
	{
		my $host_name = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{host}{node_name};
		my $host_id   = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{host}{node_id};
		my $role      = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{role};
		my $active    = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{active}   eq "true" ? 1 : 0;
		my $blocked   = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{blocked}  eq "true" ? 1 : 0;
		my $failed    = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{failed}   eq "true" ? 1 : 0;
		my $managed   = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{managed}  eq "true" ? 1 : 0;
		my $orphaned  = $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$server}{variables}{orphaned} eq "true" ? 1 : 0;
		my $status    = lc($role);
		if ((lc($role) eq "started") or (lc($role) eq "starting"))
		{
			$status = "on";
		}
=cut
2020/09/24 18:14:42:Cluster.pm:1154; Variables:
|- server: ..... [srv07-el6]
|- host_name: .. [mk-a02n02] <- Old host
|- status: ..... [migrating]
|- role: ....... [Migrating]
\- active: ..... [1]
=cut
		$anvil->data->{cib}{parsed}{data}{server}{$server}{status}    = $status;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{host_name} = $host_name;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{host_id}   = $host_id;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{role}      = $role;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{active}    = $active;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{blocked}   = $blocked;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{failed}    = $failed;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{managed}   = $managed;
		$anvil->data->{cib}{parsed}{data}{server}{$server}{orphaned}  = $orphaned;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
	
	my $xml = defined $parameter->{xml} ? $parameter->{xml} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		xml => $xml,
	}});
	
	my $problem      = 1;
	my $crm_mon_data = "";
	my $return_code  = 0;
	if ($xml)
	{
		$crm_mon_data = $xml;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { crm_mon_data => $crm_mon_data }});
	}
	else
	{
		my $shell_call = $anvil->data->{path}{exe}{crm_mon}." --output-as=xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { shell_call => $shell_call }});
		
		($crm_mon_data, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			crm_mon_data => $crm_mon_data,
			return_code  => $return_code, 
		}});
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
			foreach my $resource ($dom->findnodes('/pacemaker-result/resources/resource'))
			{
				next if $resource->{resource_agent} ne "ocf::alteeve:server";
				my $id             = $resource->{id};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { id => $id }});
				foreach my $variable (sort {$a cmp $b} keys %{$resource})
				{
					next if $variable eq "id";
					$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{variables}{$variable} = $resource->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"crm_mon::parsed::pacemaker-result::resources::resource::${id}::variables::${variable}" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{variables}{$variable}, 
					}});
				}
				foreach my $node ($resource->findnodes('./node'))
				{
					my $node_id   = $node->{id};
					my $node_name = $node->{name};
					my $cached    = $node->{cached};
					$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_name} = $node->{name};
					$anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_id}   = $node->{id};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"crm_mon::parsed::pacemaker-result::resources::resource::${id}::host::node_name" => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_name}, 
						"crm_mon::parsed::pacemaker-result::resources::resource::${id}::host::node_id"   => $anvil->data->{crm_mon}{parsed}{'pacemaker-result'}{resources}{resource}{$id}{host}{node_id}, 
					}});
				}
			}
		}
	}
	
	return($problem);
}


=head2 shutdown_server

This shuts down a server that is running on the Anvil! system. 

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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		server => $server,
		'wait' => $wait,
	}});
	
	if (not $server)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Cluster->shutdown_server()", parameter => "server" }});
		return("!!error!!");
	}
	
	my $host_type = $anvil->Get->host_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { host_type => $host_type }});
	if ($host_type ne "node")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0150", variables => { server => $server }});
		return("!!error!!");
	}
	
	my $problem = $anvil->Cluster->parse_cib({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
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
	
	# Is the server already running? If so, do nothing.
	my $status = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
	my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		status => $status,
		host   => $host, 
	}});
	
	if ($status eq "off")
	{
		# Already off.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0548", variables => { server => $server }});
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
	my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $anvil->data->{path}{exe}{pcs}." resource disable ".$server});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
		my $status = $anvil->data->{cib}{parsed}{data}{server}{$server}{status};
		my $host   = $anvil->data->{cib}{parsed}{data}{server}{$server}{host};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			status => $status,
			host   => $host, 
		}});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0554", variables => { server => $server }});
		if ($host eq "running")
		{
			# Wait a bit and check again.
			sleep 2;
		}
		else
		{
			# It's down.
			$waiting = 0;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0555", variables => { server => $server }});
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		node_name => $node_name,
		node_uuid => $node_uuid, 
	}});
	
	if ((not $node_name) && (not $node_uuid))
	{
		$node_name = $anvil->Get->short_host_name();
		$node_uuid = $anvil->Get->host_uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			node_name => $node_name,
			node_uuid => $node_uuid, 
		}});
	}
	elsif (not $node_uuid)
	{
		# Get the node UUID from the host name.
		$node_uuid = $anvil->Get->host_name_from_uuid({host_name => $node_name}); 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { node_uuid => $node_uuid }});
		
		if (not $node_uuid)
		{
			return("!!error!!");
		}
	}
	
	# Load Anvil! systems.
	if ((not exists $anvil->data->{anvils}{anvil_name}) && (not $anvil->data->{anvils}{anvil_name}))
	{
		$anvil->Database->load_anvils({debug => $debug});
	}
	
	foreach my $anvil_name (sort {$a cmp $b} keys %{$anvil->data->{anvils}{anvil_name}})
	{
		my $node1_host_uuid = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node1_host_uuid};
		my $node2_host_uuid = $anvil->data->{anvils}{anvil_name}{$anvil_name}{anvil_node2_host_uuid};

		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
			anvil_name      => $anvil_name,
			node1_host_uuid => $node1_host_uuid, 
			node2_host_uuid => $node2_host_uuid, 
		}});
		
		if ($node_uuid eq $node1_host_uuid)
		{
			$node_is = "node1";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { node_is => $node_is }});
			last;
		}
		elsif ($node_uuid eq $node2_host_uuid)
		{
			$node_is = "node2";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { node_is => $node_is }});
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
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
	my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	
	return(0);
}

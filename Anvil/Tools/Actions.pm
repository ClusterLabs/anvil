package Anvil::Tools::Actions;
# 
# This module contains methods used to handle action logging and inserting to the Database. The actions are taken by Scancore.
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Actions.pm";

### Methods;
# insert_action_node_assume
# insert_action_node_down
# insert_action_node_up

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Actions

Provides all methods related to logging the Scancore actions.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Actions->X'. 
 # 
 # Example using 'insert_action_node_down()';
 my $local_id = $anvil->Actions->insert_action_node_down;

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

=head2 insert_action_node_assume

This method inserts "1" into "scancore::actions::node::{number}::assume" variable's value where number is parsed from node_name. 
This method also updates "scancore::actions::node::{number}::assume" variable's value to "0" where number is parsed from peer_node_name. This insures that there is only one assume action, two assumes do not make sense.

If there is an error, C<< !!error!! >> is returned.

Parameters;

=head3 node_name (required)

This is the name/number of the node on which assume action was executed by ScanCore. Must include the node number that is either "1" or "2". Example: C<< node1 >> or C<< 2 >>

=head3 peer_node_name (required)

This is the name/number of the peer node to unset its assume variable. Must include the node number that is either "1" or "2". Example: C<< node1 >> or C<< 2 >>

=cut
sub insert_action_node_assume {
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 2;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Actions->insert_action_node_assume()" }});

	my $node_name      = defined $parameter->{node_name} ? $parameter->{node_name} : "";
	my $peer_node_name = defined $parameter->{peer_node_name} ? $parameter->{peer_node_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node_name      => $node_name,
		peer_node_name => $peer_node_name,
	}});

	if (not $node_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Actions->insert_action_node_assume()", parameter => "node_name" }});
		return("!!error!!");
	}

	if (not $peer_node_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Actions->insert_action_node_assume()", parameter => "peer_node_name" }});
		return("!!error!!");
	}

	# Can we parse a node number from node_name or peer_node_name
	my ($node_number) = $node_name =~ /(\d)/;
	if ((not $node_number) or (($node_number ne "1") and ($node_number ne "2")))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0149", variables => { method => "Actions->insert_action_node_assume()", parameter => "node_name" }});
		return("!!error!!");
	}
	my ($peer_node_number) = $peer_node_name =~ /(\d)/;
	if ((not $peer_node_number) or (($peer_node_number ne "1") and ($peer_node_number ne "2")))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0149", variables => { method => "Actions->insert_action_node_assume()", parameter => "peer_node_name" }});
		return("!!error!!");
	}

	# Variable names for assume actions in the Database
	my $node_assume_name      = "scancore::actions::node::${node_number}::assume";
	my $peer_node_assume_name = "scancore::actions::node::${peer_node_number}::assume";

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		$node_assume_name      => 1,
		$peer_node_assume_name => 0
	}});
	$anvil->Database->insert_or_update_variables({
		debug             => $debug,
		variable_name     => $node_assume_name,
		variable_value    => 1,
		update_value_only => 1,
	});
	$anvil->Database->insert_or_update_variables({
		debug             => $debug,
		variable_name     => $peer_node_assume_name,
		variable_value    => 0,
		update_value_only => 1,
	});

	return(0);
}


=head2 insert_action_node_down

This method inserts "1" into "scancore::actions::node::{number}::down" variable's value where number is parsed from node_name. 
This method also updates "scancore::actions::node::{number}::up" variable's value to "0" where number is parsed from node_name. This insures that there is either up or down actions on the node, both actions do not make sense.

If there is an error, C<< !!error!! >> is returned.

Parameters;

=head3 node_name (required)

This is the name/number of the node on which action was executed by ScanCore. Must include the node number that is either "1" or "2". Example: C<< node1 >> or C<< 2 >>

=cut
sub insert_action_node_down {
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 2;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Actions->insert_action_node_down()" }});

	my $node_name = defined $parameter->{node_name} ? $parameter->{node_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node_name => $node_name,
	}});

	if (not $node_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Actions->insert_action_node_down()", parameter => "node_name" }});
		return("!!error!!");
	}

	# Can we parse a node number from node_name
	my ($node_number) = $node_name =~ /(\d)/;
	if ((not $node_number) or (($node_number ne "1") and ($node_number ne "2")))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0149", variables => { method => "Actions->insert_action_node_down()", parameter => "node_name" }});
		return("!!error!!");
	}

	# Variable names for down and up actions in the Database
	my $node_down_name = "scancore::actions::node::${node_number}::down";
	my $node_up_name   = "scancore::actions::node::${node_number}::up";

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		$node_down_name => 0,
		$node_up_name   => 1
	}});
	$anvil->Database->insert_or_update_variables({
		debug             => $debug,
		variable_name     => $node_down_name,
		variable_value    => 1,
		update_value_only => 1,
	});
	$anvil->Database->insert_or_update_variables({
		debug             => $debug, 
		variable_name     => $node_up_name,
		variable_value    => 0,
		update_value_only => 1,
	});

	return(0);
}

=head2 insert_action_node_up

this method inserts "1" into "scancore::actions::node::{number}::up" variable's value where number is parsed from node_name. 
This method also updates "scancore::actions::node::{number}::down" variable's value to "0" where number is parsed from node_name. This insures that there is either up or down actions on the node, both actions do not make sense.

If there is an error, C<< !!error!! >> is returned.

Parameters;

=head3 node_name (required)

This is the name/number of the node on which action was executed by ScanCore. Must include the node number that is either "1" or "2". Example: C<< node1 >> or C<< 2 >>

=cut
sub insert_action_node_up {
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 2;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Actions->insert_action_node_up()" }});
	
	my $node_name = defined $parameter->{node_name} ? $parameter->{node_name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		node_name => $node_name,
	}});

	if (not $node_name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Actions->insert_action_node_up()", parameter => "node_name" }});
		return("!!error!!");
	}

	# Can we parse a node number from node_name
	my ($node_number) = $node_name =~ /(\d)/;
	if ((not $node_number) or (($node_number ne "1") and ($node_number ne "2")))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0149", variables => { method => "Actions->insert_action_node_down()", parameter => "node_name" }});
		return("!!error!!");
	}

	# Variable names for down and up actions in the Database
	my $node_down_name = "scancore::actions::node::${node_number}::down";
	my $node_up_name   = "scancore::actions::node::${node_number}::up";

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		$node_down_name => 1,
		$node_up_name   => 0
	}});
	$anvil->Database->insert_or_update_variables({
		debug             => $debug,
		variable_name     => $node_down_name,
		variable_value    => 0,
		update_value_only => 1,
	});
	$anvil->Database->insert_or_update_variables({
		debug             => $debug,
		variable_name     => $node_up_name,
		variable_value    => 1,
		update_value_only => 1,
	});

	return(0);
}
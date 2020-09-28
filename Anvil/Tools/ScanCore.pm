package Anvil::Tools::ScanCore;
# 
# This module contains methods used to handle message processing related to support of multi-lingual use.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use Text::Diff;

our $VERSION  = "3.0.0";
my $THIS_FILE = "ScanCore.pm";

### Methods;
# agent_startup

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::ScanCore

Provides all methods related to ScanCore and scan agents.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->ScanCore->X'. 
 # 
 # Example using 'agent_startup()';
 my $foo_path = $anvil->ScanCore->read({file => $anvil->data->{path}{words}{'anvil.xml'}});

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


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################


=head2 agent_startup

This method handles connecting to the databases, loading the agent's schema, resync'ing database tables if needed and reading in the words files.

If there is a problem, this method exits with C<< 1 >>. Otherwise, it exits with C<< 0 >>.

Parameters;

=head3 agent (required)

This is the name of the scan agent. Usually this can be set as C<< $THIS_FILE >>.

=head3 tables (required)

This is an array reference of database tables to check when resync'ing. It is important that the tables are sorted in the order they need to be resync'ed in. (tables with primary keys before their foreign key tables).

=cut
sub agent_startup
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "ScanCore->agent_startup()" }});
	
	my $agent  = defined $parameter->{agent}  ? $parameter->{agent}  : "";
	my $tables = defined $parameter->{tables} ? $parameter->{tables} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		agent  => $agent, 
		tables => $tables, 
	}});
	
	if (not $agent)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "ScanCore->agent_startup()", parameter => "agent" }});
		return("!!error!!");
	}
	if ((not $tables) or (ref($tables) ne "ARRAY"))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "ScanCore->agent_startup()", parameter => "tables" }});
		return("!!error!!");
	}
	
	my $table_count = @{$tables};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { table_count => $table_count }});
	
	# It's possible that some agents don't have a database (or use core database tables only)
	if (@{$tables} > 0)
	{
		# Append our tables 
		foreach my $table (@{$tables})
		{
			push @{$anvil->data->{sys}{database}{check_tables}}, $table;
		}
		
		# Connect to DBs.
		$anvil->Database->connect({debug => $debug});
		$anvil->Log->entry({source => $agent, line => __LINE__, level => $debug, secure => 0, key => "log_0132"});
		if (not $anvil->data->{sys}{database}{connections})
		{
			# No databases, exit.
			$anvil->Log->entry({source => $agent, line => __LINE__, 'print' => 1, level => 0, secure => 0, key => "error_0003"});
			return(1);
		}

		# Make sure our schema is loaded.
		$anvil->Database->check_agent_data({
			debug => $debug,
			agent => $agent,
		});
	}

	# Read in our word strings.
	my $words_file = $anvil->data->{path}{directories}{scan_agents}."/".$agent."/".$agent.".xml";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { words_file => $words_file }});
	
	my $problem = $anvil->Words->read({
		debug => $debug, 
		file  => $words_file,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { problem => $problem }});
	
	if ($problem)
	{
		# Something went wrong loading the file.
		return(1);
	}
	
	return(0);
	
}

1;

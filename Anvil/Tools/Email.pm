package Anvil::Tools::Email;
# 
# This module contains methods used to manage the local postfix server and handle and dispatch email via 
# mailx.
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Email.pm";

### Methods;

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Email

Provides all methods used to manage the local C<< postfix >> server and handle and dispatch email via C<< mailx >>

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Email->X'. 
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
		weaken($self->{HANDLE}{TOOLS});
	}
	
	return ($self->{HANDLE}{TOOLS});
}

#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 check_postfix

This method checks the current postfix server configuration to see if it needs to be updated, then checks to see if the local C<< postfix >> daemin is enabled and started.

If any problem is encountered, C<< 1 >> is returned. Otherwise, if all is well, C<< 0 >> is returned.

Parameters;

=head3 config (optional, default '1')

If set to C<< 0 >>, the configuration is not checked or updated. 

=head3 daemon (optional, default '1')

If set to C<< 0 >>, the C<< postfix >> daemon is not checked or started.

=cut
sub check_postfix
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $problem = 0;
	my $config  = defined $parameter->{config} ? $parameter->{config} : 1;
	my $daemon  = defined $parameter->{daemon} ? $parameter->{daemon} : 1;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		config => $config,
		daemon => $daemon, 
	}});
	
	
	
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

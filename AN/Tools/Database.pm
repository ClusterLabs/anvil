package AN::Tools::Database;
# 
# This module contains methods related to databases.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Database.pm";

### Methods;
# get_local_id

=pod

=encoding utf8

=head1 NAME

AN::Tools::Database

Provides all methods related to managing and accessing databases.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Database->X'. 
 # 
 # Example using 'get_local_id()';
 my $local_id = $an->Database->get_local_id;

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

# Get a handle on the AN::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 get_local_id

This returns the database ID from 'C<< striker.conf >>' based on matching the 'C<< database::<id>::host >>' to the local machine's host name or one of the active IP addresses on the host.

 # Get the local ID
 my $local_id = $an->Database->get_local_id;

This will return a blank string if no match is found.

=cut
sub get_local_id
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $local_id        = "";
	my $network_details = $an->Get->network_details;
	foreach my $id (sort {$a cmp $b} keys %{$an->data->{database}})
	{
		if ($network_details->{hostname} eq $an->data->{database}{$id}{host})
		{
			$local_id = $id;
			last;
		}
	}
	if (not $local_id)
	{
		foreach my $interface (sort {$a cmp $b} keys %{$network_details->{interface}})
		{
			my $ip_address  = $network_details->{interface}{$interface}{ip};
			my $subnet_mask = $network_details->{interface}{$interface}{netmask};
			foreach my $id (sort {$a cmp $b} keys %{$an->data->{database}})
			{
				if ($ip_address eq $an->data->{database}{$id}{host})
				{
					$local_id = $id;
					last;
				}
			}
		}
	}
	
	return($local_id);
}


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

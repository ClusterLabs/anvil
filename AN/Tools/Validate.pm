package AN::Tools::Validate;
# 
# This module contains methods used to validate types of data.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Validate.pm";

### Methods;
# is_uuid

=pod

=encoding utf8

=head1 NAME

AN::Tools::Validate

Provides all methods related to data validation.

=head1 SYNOPSIS

 use AN::Tools;

 # Validate a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Validate->X'. 
 # 
 # Example using 'is_uuid()';
 if ($an->Validate->is_uuid({uuid => $string}))
 {
 	print "The UUID: [$string] is valid!\n";
 }

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

=head2 is_uuid

This method takes a UUID string and returns 'C<< 1 >>' if it is a valid UUID string. Otherwise it returns 'C<< 0 >>'.

NOTE: This method is strict and will only validate UUIDs that are lower case!

 if ($an->Validate->is_uuid({uuid => $string}))
 {
 	print "The UUID: [$string] is valid!\n";
 }

=head2 Parameters;

=head3 uuid (required)

This is the UUID to verify.

=cut
sub is_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $uuid  = defined $parameter->{uuid} ? $parameter->{uuid} : 0;
	my $valid = 0;
	
	if (($uuid) && ($uuid =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/))
	{
		$valid = 1;
	}
	
	return($valid);
}

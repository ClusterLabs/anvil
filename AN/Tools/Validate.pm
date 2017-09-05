package AN::Tools::Validate;
# 
# This module contains methods used to validate types of data.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Validate.pm";

### Methods;
# is_alphanumeric
# is_domain_name
# is_ipv4
# is_positive_integer
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
	
	# Defend against memory leads. See Scalar::Util'.
	if (not isweak($self->{HANDLE}{TOOLS}))
	{
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 is_alphanumeric

This verifies that the passed-in string contains only alpha-numeric characters. This is strict and will return invalid if spaces, hyphens or other characters are found.

NOTE: An empty string is considered invalid.

 $string = "4words";
 if ($an->Validate->is_alphanumeric({string => $string}))
 {
 	print "The string: [$string] is valid!\n";
 }

=head2 Parameters;

=head3 string (required)

This is the string name to validate.

=cut
sub is_alphanumeric
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $valid  = 1;
	my $debug  = 3;
	my $string = defined $parameter->{string} ? $parameter->{string} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	
	if (not $string)
	{
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	if ($string !~ /^[a-zA-Z0-9]+$/)
	{
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_domain_name

Checks if the passed-in string is a valid domain name. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $name = "alteeve.com";
 if ($an->Validate->is_domain_name({name => $name}))
 {
 	print "The domain name: [$name] is valid!\n";
 }

=head2 Parameters;

=head3 name (required)

This is the domain name to validate.

=cut
sub is_domain_name
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $valid = 1;
	my $debug = 3;
	my $name  = $parameter->{name} ? $parameter->{name} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { name => $name }});
	
	if (not $name)
	{
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	elsif (($name !~ /^((([a-z]|[0-9]|\-)+)\.)+([a-z])+$/i) && (($name !~ /^\w+$/) && ($name !~ /-/)))
	{
		# Doesn't appear to be valid.
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_ipv4

Checks if the passed-in string is an IPv4 address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $ip = "111.222.33.44";
 if ($an->Validate->is_ipv4({ip => $ip}))
 {
 	print "The IP address: [$ip] is valid!\n";
 }

=head2 Parameters;

=head3 ip (required)

This is the IP address to verify.

=cut
sub is_ipv4
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $debug = 3;
	my $ip    = defined $parameter->{ip} ? $parameter->{ip} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	
	my $valid = 1;
	if ($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)
	{
		# It is in the right format.
		my $first_octet  = $1;
		my $second_octet = $2;
		my $third_octet  = $3;
		my $fourth_octet = $4;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			first_octet  => $first_octet, 
			second_octet => $second_octet, 
			third_octet  => $third_octet, 
			fourth_octet => $fourth_octet, 
		}});
		
		if (($first_octet  < 0) or ($first_octet  > 255) or
		    ($second_octet < 0) or ($second_octet > 255) or
		    ($third_octet  < 0) or ($third_octet  > 255) or
		    ($fourth_octet < 0) or ($fourth_octet > 255))
		{
			# One of the octets is out of range.
			$valid = 0;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
		}
	}
	else
	{
		# Not in the right format.
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_positive_integer

This method verifies that the passed in value is a positive integer. 

NOTE: This method is strict and will only validate numbers without decimal places and that have no sign or a positive sign only (ie: C<< +3 >>, or C<< 3 >> are valid, but C<< -3 >> or C<< 3.0 >> are not).

 my $number = 3;
 if ($an->Validate->is_positive_integer({number => $number}))
 {
 	print "The number: [$number] is valid!\n";
 }

=head2 Parameters;

=head3 number (required)

This is the number to verify.

=head3 zero (optional)

If set, the number C<< 0 >> will be considered valid. By default, c<< 0 >> is not considered "positive".

=cut
sub is_positive_integer
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $debug  = 3;
	my $valid  = 1;
	my $number = defined $parameter->{number} ? $parameter->{number} : "";
	my $zero   = defined $parameter->{zero}   ? $parameter->{zero}   : 0;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		number => $number,
		zero   => $zero,
	}});
	
	# We'll strip a positive leading character as that is allowed.
	$number =~ s/^\+//;
	
	# Now anything 
	if ($number !~ /^\d+$/)
	{
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	if ((not $zero) && (not $number))
	{
		$valid = 0;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

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

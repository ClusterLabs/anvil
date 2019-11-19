package Anvil::Tools::Validate;
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
# form_field
# is_alphanumeric
# is_domain_name
# is_ipv4
# is_mac
# is_positive_integer
# is_subnet_mask
# is_uuid

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Validate

Provides all methods related to data validation.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Validate a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Validate->X'. 
 # 
 # Example using 'is_uuid()';
 if ($anvil->Validate->is_uuid({uuid => $string}))
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

=head2 form_field

This validates that a given HTML form field is valid. It takes an input ID and the type of data that is expected. If it is sane, C<< 1 >> is returned. If it fails to validate, C<< 0 >> is returned and C<< cgi::<name>::alert >> is set to C<< 1 >>.

Parameters;

=head3 empty_ok (optional)

This can be set to C<< 1 >> to have this method return valid is the variable exists, is defined by is an empty string.

=head3 name (required)

This is the input field name, which is used to check C<< cgi::<name>::value >>.

=head3 type (required)

This is the type to be checked. Valid options are;

=head4 alphanumeric

=head4 domain_name

=head4 ipv4

=head4 mac

=head4 positive_integer

If this type is used, you can use the C<< zero >> parameter which can be set to C<< 1 >>  to have a value of C<< 0 >> be considered valid.

=head4 subnet_mask

=head4 uuid

=cut
sub form_field
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $valid    = 1;
	my $name     = defined $parameter->{name}     ? $parameter->{name}     : "";
	my $type     = defined $parameter->{type}     ? $parameter->{type}     : "";
	my $empty_ok = defined $parameter->{empty_ok} ? $parameter->{empty_ok} : 0;
	my $zero     = defined $parameter->{zero}     ? $parameter->{zero}     : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		name     => $name,
		type     => $type,
		empty_ok => $empty_ok,
	}});
	
	if ((not $name) or (not $type))
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	else
	{
		if ((not exists $anvil->data->{cgi}{$name}{value}) or (not defined $anvil->data->{cgi}{$name}{value}))
		{
			# Not defined
			$valid = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
		}
		else
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cgi::${name}::value" => $anvil->data->{cgi}{$name}{value} }});
			if (not $anvil->data->{cgi}{$name}{value})
			{
				if (not $empty_ok)
				{
					$valid = 0;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
				}
			}
			elsif (($type eq "alphanumeric") && (not $anvil->Validate->is_alphanumeric({string => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "domain_name") && (not $anvil->Validate->is_domain_name({name => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "ipv4") && (not $anvil->Validate->is_ipv4({ip => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "mac") && (not $anvil->Validate->is_mac({mac => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "positive_integer") && (not $anvil->Validate->is_positive_integer({number => $anvil->data->{cgi}{$name}{value}, zero => $zero})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "subnet_mask") && (not $anvil->Validate->is_subnet_mask({subnet_mask => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "uuid") && (not $anvil->Validate->is_uuid({uuid => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                         = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_alphanumeric

This verifies that the passed-in string contains only alpha-numeric characters. This is strict and will return invalid if spaces, hyphens or other characters are found.

NOTE: An empty string is considered invalid.

 $string = "4words";
 if ($anvil->Validate->is_alphanumeric({string => $string}))
 {
 	print "The string: [$string] is valid!\n";
 }

Parameters;

=head3 string (required)

This is the string name to validate.

=cut
sub is_alphanumeric
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $valid  = 1;
	my $string = defined $parameter->{string} ? $parameter->{string} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	
	if (not $string)
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	if ($string !~ /^[a-zA-Z0-9]+$/)
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_domain_name

Checks if the passed-in string is a valid domain name. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $name = "alteeve.com";
 if ($anvil->Validate->is_domain_name({name => $name}))
 {
 	print "The domain name: [$name] is valid!\n";
 }

Parameters;

=head3 name (required)

This is the domain name to validate.

=cut
sub is_domain_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $valid = 1;
	my $name  = $parameter->{name} ? $parameter->{name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { name => $name }});
	
	if (not $name)
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	elsif (($name !~ /^((([a-z]|[0-9]|\-)+)\.)+([a-z])+$/i) && (($name !~ /^\w+$/) && ($name !~ /-/)))
	{
		# Doesn't appear to be valid.
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_hex

Checks if the passed-in string contains only hexidecimal characters. A prefix of C<< 0x >> is allowed.

Parameters;

=head3 sloppy (optional, default '0')

If set to C<< 1 >>, the string will be allowed to contain C<< : >> and C<< - >> and a closing C<< h >>characters (as found in MAC addresses, for example). 

=head3 string (required)

This is the string to validate

=cut
sub is_hex
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $sloppy = defined $parameter->{sloppy} ? $parameter->{sloppy} : "";
	my $string = defined $parameter->{string} ? $parameter->{string} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		sloppy => $sloppy, 
		string => $string,
	}});
	
	if ($sloppy)
	{
		$string =~ s/-//g;
		$string =~ s/://g;
		$string =~ s/h$//gi;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	}
	
	my $valid = 1;
	if ($string !~ /^(0[xX])*[0-9a-fA-F]+$/)
	{
		# There's something un-hexxy about this.
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_ipv4

Checks if the passed-in string is an IPv4 address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $ip = "111.222.33.44";
 if ($anvil->Validate->is_ipv4({ip => $ip}))
 {
 	print "The IP address: [$ip] is valid!\n";
 }

Parameters;

=head3 ip (required)

This is the IP address to verify.

=cut
sub is_ipv4
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $ip = defined $parameter->{ip} ? $parameter->{ip} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	
	my $valid = 1;
	if ($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)
	{
		# It is in the right format.
		my $first_octet  = $1;
		my $second_octet = $2;
		my $third_octet  = $3;
		my $fourth_octet = $4;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
		}
	}
	else
	{
		# Not in the right format.
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_mac

Checks if the passed-in string is a valid network MAC address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

Parameters;

=head3 mac (required)

This is the network MAC address to verify.

=cut
sub is_mac
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $mac = defined $parameter->{mac} ? $parameter->{mac} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mac => $mac }});
	
	my $valid = 0;
	if ($mac =~ /^([0-9a-f]{2}([:-]|$)){6}$/i)
	{
		# It is in the right format.
		$valid = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_positive_integer

This method verifies that the passed in value is a positive integer. 

NOTE: This method is strict and will only validate numbers without decimal places and that have no sign or a positive sign only (ie: C<< +3 >>, or C<< 3 >> are valid, but C<< -3 >> or C<< 3.0 >> are not).

 my $number = 3;
 if ($anvil->Validate->is_positive_integer({number => $number}))
 {
 	print "The number: [$number] is valid!\n";
 }

Parameters;

=head3 number (required)

This is the number to verify.

=head3 zero (optional)

If set, the number C<< 0 >> will be considered valid. By default, c<< 0 >> is not considered "positive".

=cut
sub is_positive_integer
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $valid  = 1;
	my $number = defined $parameter->{number} ? $parameter->{number} : "";
	my $zero   = defined $parameter->{zero}   ? $parameter->{zero}   : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		number => $number,
		zero   => $zero,
	}});
	
	# We'll strip a positive leading character as that is allowed.
	$number =~ s/^\+//;
	
	# Now anything 
	if ($number !~ /^\d+$/)
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	if ((not $zero) && (not $number))
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_subnet_mask

This method takes a subnet mask string and checks to see if it is a valid IPv4 address or CIDR notation. It returns 'C<< 1 >>' if it is a valid address. Otherwise it returns 'C<< 0 >>'.

Parameters;

=head3 subnet_mask (required)

This is the address to verify.

=cut
sub is_subnet_mask
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $valid       = 0;
	my $subnet_mask = defined $parameter->{subnet_mask} ? $parameter->{subnet_mask} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		subnet_mask => $subnet_mask,
	}});
	
	if ($subnet_mask)
	{
		# We have something. Is it an IPv4 address?
		if ($anvil->Validate->is_ipv4({ip => $subnet_mask}))
		{
			# It is. Try converting it to a CIDR notation. If we get an empty string back, it isn't valid.
			my $cidr = $anvil->Convert->cidr({subnet_mask => $subnet_mask});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cidr => $cidr }});
			if ($cidr)
			{
				# It's valid.
				$valid = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
			}
			else
			{
				# OK, maybe it's a CIDR notation?
				my $ip = $anvil->Convert->cidr({cidr => $subnet_mask});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
				if ($ip)
				{
					# There we go.
					$valid = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
				}
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 is_uuid

This method takes a UUID string and returns 'C<< 1 >>' if it is a valid UUID string. Otherwise it returns 'C<< 0 >>'.

NOTE: This method is strict and will only validate UUIDs that are lower case!

 if ($anvil->Validate->is_uuid({uuid => $string}))
 {
 	print "The UUID: [$string] is valid!\n";
 }

Parameters;

=head3 uuid (required)

This is the UUID to verify.

=cut
sub is_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $uuid  = defined $parameter->{uuid} ? $parameter->{uuid} : 0;
	my $valid = 0;
	
	if (($uuid) && ($uuid =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/))
	{
		$valid = 1;
	}
	
	return($valid);
}

1;
 

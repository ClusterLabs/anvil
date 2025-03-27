package Anvil::Tools::Validate;
# 
# This module contains methods used to validate types of data.
# 

use strict;
use warnings;
use Data::Dumper;
use Data::Validate::Domain qw(is_domain);
use Data::Validate::IP;
use Scalar::Util qw(weaken isweak);
use Mail::RFC822::Address qw(valid validlist);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Validate.pm";

### Methods;
# alphanumeric
# domain_name
# email
# form_field
# hex
# host_name
# ip
# ipv4
# ipv6
# mac
# positive_integer
# subnet_mask
# uuid

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
 # Example using 'uuid()';
 if ($anvil->Validate->uuid({uuid => $string}))
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

=head2 alphanumeric

This verifies that the passed-in string contains only alpha-numeric characters. This is strict and will return invalid if spaces, hyphens or other characters are found.

NOTE: An empty string is considered invalid.

 $string = "4words";
 if ($anvil->Validate->alphanumeric({string => $string}))
 {
 	print "The string: [$string] is valid!\n";
 }

Parameters;

=head3 string (required)

This is the string name to validate.

=cut
sub alphanumeric
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->alphanumeric()" }});
	
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

=head2 domain_name

Checks if the passed-in string is a valid domain name. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $name = "alteeve.com";
 if ($anvil->Validate->domain_name({name => $name}))
 {
 	print "The domain name: [$name] is valid!\n";
 }

Parameters;

=head3 name (required)

This is the domain name to validate.

=cut
sub domain_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->domain_name()" }});
	
	my $valid = 1;
	my $name  = $parameter->{name} ? $parameter->{name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { name => $name }});
	
	if (not $name)
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	else
	{
		# Underscores are allowd in domain names, but not host names. We disable TLD checks as we
		# frequently use '.remote', '.bcn', etc. 
		### TODO: Add a 'strict' parameter to control this) and/or support domain_private_tld
		my %options = (domain_allow_underscore => 1, domain_disable_tld_validation => 1);
		my $dvd     = Data::Validate::Domain->new(%options);
		my $test    = $dvd->is_domain($name);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test => $test }});
		if (not $test)
		{
			# Doesn't appear to be valid.
			$valid = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
		}
	}
	

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}


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

=head4 email

=head4 ipv4

=head4 mac

=head4 positive_integer

If this type is used, you can use the C<< zero >> parameter which can be set to C<< 1 >>  to have a value of C<< 0 >> be considered valid.

=head4 subnet_mask

=head4 uuid

=head3 zero (optional, default '0')

See 'type -> positive_integer' above for usage.

=cut
sub form_field
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->form_field()" }});
	
	my $valid    = 1;
	my $name     = defined $parameter->{name}     ? $parameter->{name}     : "";
	my $type     = defined $parameter->{type}     ? $parameter->{type}     : "";
	my $empty_ok = defined $parameter->{empty_ok} ? $parameter->{empty_ok} : 0;
	my $zero     = defined $parameter->{zero}     ? $parameter->{zero}     : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		name     => $name,
		type     => $type,
		empty_ok => $empty_ok,
		zero     => $zero,
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
			elsif (($type eq "alphanumeric") && (not $anvil->Validate->alphanumeric({string => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "domain_name") && (not $anvil->Validate->domain_name({name => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "email") && (not $anvil->Validate->email({email => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "ipv4") && (not $anvil->Validate->ipv4({ip => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "mac") && (not $anvil->Validate->mac({mac => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "positive_integer") && (not $anvil->Validate->positive_integer({number => $anvil->data->{cgi}{$name}{value}, zero => $zero})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "subnet_mask") && (not $anvil->Validate->subnet_mask({subnet_mask => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
			elsif (($type eq "uuid") && (not $anvil->Validate->uuid({uuid => $anvil->data->{cgi}{$name}{value}})))
			{
				$valid                            = 0;
				$anvil->data->{cgi}{$name}{alert} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { valid => $valid, "cgi::${name}::alert" => $anvil->data->{cgi}{$name}{alert} }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}


=head2 hex

Checks if the passed-in string contains only hexidecimal characters. A prefix of C<< 0x >> is allowed.

Parameters;

=head3 sloppy (optional, default '0')

If set to C<< 1 >>, the string will be allowed to contain C<< : >> and C<< - >> and a closing C<< h >>characters (as found in MAC addresses, for example). 

=head3 string (required)

This is the string to validate

=cut
sub hex
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->hex()" }});
	
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


=head2 host_name

Checks if the passed-in string is a valid host name. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

B<NOTE>: If this method receives a full domain name, the host name is checked in this method and the domain (anything after the first C<< . >>) is tested using C<< Validate->domain_name >>. If either fails, C<< 0 >> is returned.

 $name = "an-a05n01";
 if ($anvil->Validate->host_name({name => $name}))
 {
 	print "The host name: [$name] is valid!\n";
 }

Parameters;

=head3 name (required)

This is the host name to validate.

=cut
sub host_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->host_name()" }});
	
	my $valid = 1;
	my $name  = $parameter->{name} ? $parameter->{name} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { name => $name }});
	
	my $domain = "";
	if ($name =~ /\./)
	{
		($name, $domain) = ($name =~ /^(.*?)\.(.*)$/);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			name   => $name,
			domain => $domain, 
		}});
	}
	
	if ($domain)
	{
		$valid = $anvil->Validate->domain_name({
			name  => $domain, 
			debug => $debug,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	if (not $name)
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	else
	{
		# Underscores are allowd in domain names, but not host names.
		my %options = (domain_allow_underscore => 1);
		my $dvd     = Data::Validate::Domain->new(%options);
		my $test    = $dvd->is_hostname($name);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test => $test }});
		if (not $test)
		{
			# Doesn't appear to be valid.
			$valid = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
		}
	}

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}


=head2 email

Checks if the passed-in string is a valid address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $email = "test@example.com";
 if ($anvil->Validate->email({email => $email}))
 {
 	print "The email address: [$email] is valid!\n";
 }

Parameters;

=head3 email (required)

This is the email address to verify.

=cut
sub email
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->email()" }});
	
	my $email = defined $parameter->{email} ? $parameter->{email} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { email => $email }});
	
	# Validating email ourself is madness... See (https://www.youtube.com/watch?v=xxX81WmXjPg). So we use
	# 'Mail::RFC822::Address'.
	my $valid = 0;
	if (valid($email))
	{
		$valid = 1;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 ip

This is a meta method. It takes the IP and tests it against both C<< ipv4 >> and C<< ipv6 >>. If either return as valid, this method returns as valid.

Said more simply; This tests an IP to see if it is IPv4 OR IPv6. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

Parameters;

=head3 ip (required)

This is the IP address to validate.

=cut
sub ip
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->ip()" }});
	
	my $ip = defined $parameter->{ip} ? $parameter->{ip} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});

	my $ipv4 =             $anvil->Validate->ipv4({ip => $ip, debug => $debug});
	my $ipv6 = not $ipv4 ? $anvil->Validate->ipv6({ip => $ip, debug => $debug}) : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		ipv4 => $ipv4,
		ipv6 => $ipv6,
	}});
	
	my $valid = 1;
	if ((not $ipv4) && (not $ipv6))
	{
		$valid = 0;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 ipv4

Checks if the passed-in string is an IPv4 address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $ip = "111.222.33.44";
 if ($anvil->Validate->ipv4({ip => $ip}))
 {
 	print "The IP address: [$ip] is valid!\n";
 }

Parameters;

=head3 ip (required)

This is the IP address to verify.

=cut
sub ipv4
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->ipv4()" }});
	
	my $ip = defined $parameter->{ip} ? $parameter->{ip} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	
	my $valid = 1;
	if (not is_ipv4($ip))
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 ipv6

Checks if the passed-in string is an IPv6 address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

 $ip = "::1";
 if ($anvil->Validate->ipv6({ip => $ip}))
 {
 	print "The IP address: [$ip] is valid!\n";
 }

B<<Note>>: This will validate domain names as IPv6 addresses.

Parameters;

=head3 ip (required)

This is the IPv6 address to verify.

=cut
sub ipv6
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->ipv6()" }});
	
	my $ip = defined $parameter->{ip} ? $parameter->{ip} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
	
	my $valid = 1;
	if (not is_ipv6($ip))
	{
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 mac

Checks if the passed-in string is a valid network MAC address. Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

Parameters;

=head3 mac (required)

This is the network MAC address to verify.

=cut
sub mac
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->mac()" }});
	
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

=head2 port

This tests to see if the value passed is a valid TCP/UDP port (1 ~ 65536). Returns 'C<< 1 >>' if OK, 'C<< 0 >>' if not.

B<< Note >>: This is a strict test. A comma will cause this test to return C<< 0 >>.

Parameters;

=head3 port (required)

This is the port being tested.

=cut
sub port
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->port()" }});
	
	my $port = defined $parameter->{port} ? $parameter->{port} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { port => $port }});
	
	my $valid = 1;
	if ($port =~ /\D/)
	{
		# Not a digit
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	elsif (($port < 1) or ($port > 65535))
	{
		# Out of range
		$valid = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	return($valid);
}

=head2 positive_integer

This method verifies that the passed in value is a positive integer. 

NOTE: This method is strict and will only validate numbers without decimal places and that have no sign or a positive sign only (ie: C<< +3 >>, or C<< 3 >> are valid, but C<< -3 >> or C<< 3.0 >> are not).

 my $number = 3;
 if ($anvil->Validate->positive_integer({number => $number}))
 {
 	print "The number: [$number] is valid!\n";
 }

Parameters;

=head3 number (required)

This is the number to verify.

=head3 zero (optional)

If set, the number C<< 0 >> will be considered valid. By default, c<< 0 >> is not considered "positive".

=cut
sub positive_integer
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->positive_integer()" }});
	
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

=head2 subnet_mask

This method takes a subnet mask string and checks to see if it is a valid IPv4 address or CIDR notation. It returns 'C<< 1 >>' if it is a valid address. Otherwise it returns 'C<< 0 >>'.

Parameters;

=head3 subnet_mask (required)

This is the address to verify.

=cut
sub subnet_mask
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Validate->subnet_mask()" }});
	
	my $valid       = 0;
	my $subnet_mask = defined $parameter->{subnet_mask} ? $parameter->{subnet_mask} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		subnet_mask => $subnet_mask,
	}});
	
	if ($subnet_mask)
	{
		# We have something. Is it an IPv4 address?
		if ($anvil->Validate->ipv4({ip => $subnet_mask}))
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

=head2 uuid

This method takes a UUID string and returns 'C<< 1 >>' if it is a valid UUID string. Otherwise it returns 'C<< 0 >>'.

NOTE: This method is strict and will only validate UUIDs that are lower case!

 if ($anvil->Validate->uuid({uuid => $string}))
 {
 	print "The UUID: [$string] is valid!\n";
 }

Parameters;

=head3 uuid (required)

This is the UUID to verify.

=cut
### NOTE: Don't call Log->entry from here, causes a deep recursion.
sub uuid
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
 

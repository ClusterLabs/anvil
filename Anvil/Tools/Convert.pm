package Anvil::Tools::Convert;
# 
# This module contains methods used to convert data between types
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Math::BigInt;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Convert.pm";

### Methods;
# add_commas
# bytes_to_human_readable
# cidr
# hostname_to_ip
# human_readable_to_bytes
# round


=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Convert

Provides all methods related to converting data.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Convert->X'. 
 # 
 # Example using 'cidr()';
 my $subnet = $anvil->Convert->codr({cidr => "24"});

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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 add_commas

This takes an integer and inserts commas to make it more readable by people.

If the input string isn't a string of digits, it is simply returned as-is. 

 my $string = $anvil->Convert->add_commas({number => 123456789});
 
 # string = 123,456,789

Parameters;

=head3 number (required)

This is the number to add commas to.

=cut
sub add_commas
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Now see if the user passed the values in a hash reference or directly.
	my $number = defined $parameter->{number} ? $parameter->{number} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { number => $number }});
	
	# Remove any existing commands or leading '+' signs.
	$number =~ s/,//g;
	$number =~ s/^\+//g;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { number => $number }});
	
	# Split on the left-most period.
	my ($whole, $decimal) = split/\./, $number, 2;
	$whole   = "" if not defined $whole;
	$decimal = "" if not defined $decimal;
	
	# Now die if either number has a non-digit character in it.
	if (($whole =~ /\D/) or ($decimal =~ /\D/))
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { number => $number }});
		return ($number);
	}
	
	local($_) = $whole ? $whole : "";
	
	1 while s/^(-?\d+)(\d{3})/$1,$2/;
	$whole = $_;
	
	# Put it together
	$number = $decimal ? "$whole.$decimal" : $whole;
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { number => $number }});
	return ($number);
}

=head2 bytes_to_human_readable

This takes a number of bytes and converts it to a a human-readable format. Optionally, you can request the human readable size be returned using specific units.

If anything goes wrong, C<< !!error!! >> is returned.

* Base2 Notation;
B<Term>			B<Factor>	C<Bytes>
Yobiabyte (YiB)		2^80	1,208,925,819,614,629,174,706,176
Zebiabyte (ZiB)		2^70	1,180,591,620,717,411,303,424
Exbibyte (EiB)		2^60	1,152,921,504,606,846,976
Pebibyte (PiB)		2^50	1,125,899,906,842,624
Tebibyte (TiB)		2^40	1,099,511,627,776
Gibibyte (GiB)		2^30	1,073,741,824
Mebibyte (MiB)		2^20	1,048,576
Kibibyte (KiB)		2^10	1,024
Byte (B)		2^1	1

* Base10 Notation;
B<Term>			B<Factor>	C<Bytes>
Yottabyte (YB)		10^24	1,000,000,000,000,000,000,000,000
Zettabyte (ZB)		10^21	1,000,000,000,000,000,000,000
Exabyte (EB)		10^18	1,000,000,000,000,000,000
Petabyte (PB)		10^15	1,000,000,000,000,000
Terabyte (TB)		10^12	1,000,000,000,000
Gigabyte (GB)		10^9	1,000,000,000
Megabyte (MB)		10^6	1,000,000
Kilobyte (KB)		10^3	1,000
Byte (B)		1	1

Parameters;

=head3 base2 (optional)

This can be set to C<< 1 >> to return the units in base2 notation, or set to C<< 0 >> to return in base10 notation. The default is controlled by c<< sys::use_base2 >>, which is set to C<< 1 >> by default.

The suffix will use C<< XiB >> when base2 notation is used and C<< XB >> will be returned for base10.

=head3 bytes (required)

This is the number of bytes that will be converted. This can be a signed integer.

=head3 unit (optional)

This is a letter 

=cut
sub bytes_to_human_readable
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Now see if the user passed the values in a hash reference or directly.
	my $size  = defined $parameter->{'bytes'} ? $parameter->{'bytes'}  : 0;
	my $unit  = defined $parameter->{unit}    ? uc($parameter->{unit}) : "";
	my $base2 = defined $parameter->{base2}   ? $parameter->{base2}    : $anvil->data->{sys}{use_base2};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		size   => $size, 
		unit   => $unit, 
		base2  => $base2, 
	}});
	
	# Expand exponential numbers.
	if ($size =~ /(\d+)e\+(\d+)/)
	{
		my $base = $1;
		my $exp  = $2;
		   $size = $base;
		for (1..$exp)
		{
			$size .= "0";
		}
	}
	
	# Setup my variables.
	my $suffix              = "";
	my $human_readable_size = $size;
	
	# Store and strip the sign
	my $sign = "";
	if ($human_readable_size =~ /^-/)
	{
		$sign    =  "-";
		$human_readable_size =~ s/^-//;
	}
	$human_readable_size =~ s/,//g;
	$human_readable_size =~ s/^\+//g;
	
	# Die if either the 'time' or 'float' has a non-digit character in it.	
	if ($human_readable_size =~ /\D/)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0116", variables => { 
			method    => "Convert->bytes_to_human_readable()", 
			parameter => "hostnmae",
			value     => $human_readable_size,
		}});
		return ("!!error!!");
	}
	
	# Do the math.
	if ($base2)
	{
		# Has the user requested a certain unit to use?
		if ($unit)
		{
			# Yup
			if ($unit =~ /Y/i)
			{
				# Yebibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 80)));
				$suffix              = "YiB";
			}
			elsif ($unit =~ /Z/i)
			{
				# Zebibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 70)));
				$suffix              = "ZiB";
			}
			elsif ($unit =~ /E/i)
			{
				# Exbibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 60)));
				$suffix              = "EiB";
			}
			elsif ($unit =~ /P/i)
			{
				# Pebibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 50)));
				$suffix              = "PiB";
			}
			elsif ($unit =~ /T/i)
			{
				# Tebibyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (2 ** 40)));
				$suffix              = "TiB";
			}
			elsif ($unit =~ /G/i)
			{
				# Gibibyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (2 ** 30)));
				$suffix              = "GiB";
			}
			elsif ($unit =~ /M/i)
			{
				# Mebibyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (2 ** 20)));
				$suffix              = "MiB";
			}
			elsif ($unit =~ /K/i)
			{
				# Kibibyte
				$human_readable_size = sprintf("%.1f", ($human_readable_size /= (2 ** 10)));
				$suffix              = "KiB";
			}
			else
			{
				$suffix = "B";
			}
		}
		else
		{
			# Nope, use the most efficient.
			if ($human_readable_size >= (2 ** 80))
			{
				# Yebibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 80)));
				$suffix              = "YiB";
			}
			elsif ($human_readable_size >= (2 ** 70))
			{
				# Zebibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 70)));
				$suffix              = "ZiB";
			}
			elsif ($human_readable_size >= (2 ** 60))
			{
				# Exbibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 60)));
				$suffix              = "EiB";
			}
			elsif ($human_readable_size >= (2 ** 50))
			{
				# Pebibyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (2 ** 50)));
				$suffix              = "PiB";
			}
			elsif ($human_readable_size >= (2 ** 40))
			{
				# Tebibyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (2 ** 40)));
				$suffix              = "TiB";
			}
			elsif ($human_readable_size >= (2 ** 30))
			{
				# Gibibyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (2 ** 30)));
				$suffix              = "GiB";
			}
			elsif ($human_readable_size >= (2 ** 20))
			{
				# Mebibyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (2 ** 20)));
				$suffix              = "MiB";
			}
			elsif ($human_readable_size >= (2 ** 10))
			{
				# Kibibyte
				$human_readable_size = sprintf("%.1f", ($human_readable_size /= (2 ** 10)));
				$suffix              = "KiB";
			}
			else
			{
				$suffix  = "B";
			}
		}
	}
	else
	{
		# Has the user requested a certain unit to use?
		if ($unit)
		{
			# Yup
			if ($unit =~ /Y/i)
			{
				# Yottabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 24)));
				$suffix              = "YB";
			}
			elsif ($unit =~ /Z/i)
			{
				# Zettabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 21)));
				$suffix              = "ZB";
			}
			elsif ($unit =~ /E/i)
			{
				# Exabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 18)));
				$suffix              = "EB";
			}
			elsif ($unit =~ /P/i)
			{
				# Petabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 15)));
				$suffix              = "PB";
			}
			elsif ($unit =~ /T/i)
			{
				# Terabyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (10 ** 12)));
				$suffix              = "TB";
			}
			elsif ($unit =~ /G/i)
			{
				# Gigabyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (10 ** 9)));
				$suffix              = "GB";
			}
			elsif ($unit =~ /M/i)
			{
				# Megabyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (10 ** 6)));
				$suffix              = "MB";
			}
			elsif ($unit =~ /K/i)
			{
				# Kilobyte
				$human_readable_size = sprintf("%.1f", ($human_readable_size /= (10 ** 3)));
				$suffix              = "KB";
			}
			else
			{
				$suffix = "b";
			}
		}
		else
		{
			# Nope, use the most efficient.
			if ($human_readable_size >= (10 ** 24))
			{
				# Yottabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 24)));
				$suffix              = "YB";
			}
			elsif ($human_readable_size >= (10 ** 21))
			{
				# Zettabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 21)));
				$suffix              = "ZB";
			}
			elsif ($human_readable_size >= (10 ** 18))
			{
				# Exabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 18)));
				$suffix              = "EB";
			}
			elsif ($human_readable_size >= (10 ** 15))
			{
				# Petabyte
				$human_readable_size = sprintf("%.3f", ($human_readable_size /= (10 ** 15)));
				$suffix              = "PB";
			}
			elsif ($human_readable_size >= (10 ** 12))
			{
				# Terabyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (10 ** 12)));
				$suffix              = "TB";
			}
			elsif ($human_readable_size >= (10 ** 9))
			{
				# Gigabyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (10 ** 9)));
				$suffix              = "GB";
			}
			elsif ($human_readable_size >= (10 ** 6))
			{
				# Megabyte
				$human_readable_size = sprintf("%.2f", ($human_readable_size /= (10 ** 6)));
				$suffix              = "MB";
			}
			elsif ($human_readable_size >= (10 ** 3))
			{
				# Kilobyte
				$human_readable_size = sprintf("%.1f", ($human_readable_size /= (10 ** 3)));
				$suffix              = "KB";
			}
			else
			{
				$suffix = "b";
			}
		}
	}
	
	# If needed, insert commas
	$human_readable_size = $anvil->Convert->add_commas({number => $human_readable_size});
	
	# Restore the sign.
	if ($sign)
	{
		$human_readable_size = $sign.$human_readable_size;
	}
	$human_readable_size .= " ".$suffix;
	
	return($human_readable_size);
}

=head2 cidr

This takes an IPv4 CIDR notation and returns the dotted-decimal subnet, or the reverse.

 # Convert a CIDR notation to a subnet.
 my $subnet = $anvil->Convert->cidr({cidr => "24"});

In the other direction;
 
 # Convert a subnet to a CIDR notation.
 my $cidr = $anvil->Convert->cidr({subnet => "255.255.255.0"});

If the input data is invalid, an empty string will be returned.

=head2 Parameters;

There are two parameters, each of which is optional, but one of them is required. 

=head3 cidr (optional)

This is a CIDR notation (between 0 and 24) to convert to a dotted-decimal address.

=head3 subnet (optional)

This is a dotted-decimal subnet to convert to a CIDR notation.
 
=cut
sub cidr
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $cidr   = defined $parameter->{cidr}   ? $parameter->{cidr}   : "";
	my $subnet = defined $parameter->{subnet} ? $parameter->{subnet} : "";
	my $output = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		cidr   => $cidr, 
		subnet => $subnet, 
	}});
	
	if ($cidr =~ /^\d{1,2}$/)
	{
		# Convert a cidr to a subnet
		if    ($cidr eq "0")  { $output = "0.0.0.0"; }
		elsif ($cidr eq "1")  { $output = "128.0.0.0"; }
		elsif ($cidr eq "2")  { $output = "192.0.0.0"; }
		elsif ($cidr eq "3")  { $output = "224.0.0.0"; }
		elsif ($cidr eq "4")  { $output = "240.0.0.0"; }
		elsif ($cidr eq "5")  { $output = "248.0.0.0"; }
		elsif ($cidr eq "6")  { $output = "252.0.0.0"; }
		elsif ($cidr eq "7")  { $output = "254.0.0.0"; }
		elsif ($cidr eq "8")  { $output = "255.0.0.0"; }
		elsif ($cidr eq "9")  { $output = "255.128.0.0"; }
		elsif ($cidr eq "10") { $output = "255.192.0.0"; }
		elsif ($cidr eq "11") { $output = "255.224.0.0"; }
		elsif ($cidr eq "12") { $output = "255.240.0.0"; }
		elsif ($cidr eq "13") { $output = "255.248.0.0"; }
		elsif ($cidr eq "14") { $output = "255.252.0.0"; }
		elsif ($cidr eq "15") { $output = "255.254.0.0"; }
		elsif ($cidr eq "16") { $output = "255.255.0.0"; }
		elsif ($cidr eq "17") { $output = "255.255.128.0"; }
		elsif ($cidr eq "18") { $output = "255.255.192.0"; }
		elsif ($cidr eq "19") { $output = "255.255.224.0"; }
		elsif ($cidr eq "20") { $output = "255.255.240.0"; }
		elsif ($cidr eq "21") { $output = "255.255.248.0"; }
		elsif ($cidr eq "22") { $output = "255.255.252.0"; }
		elsif ($cidr eq "23") { $output = "255.255.254.0"; }
		elsif ($cidr eq "24") { $output = "255.255.255.0"; }
		elsif ($cidr eq "25") { $output = "255.255.255.128"; }
		elsif ($cidr eq "26") { $output = "255.255.255.192"; }
		elsif ($cidr eq "27") { $output = "255.255.255.224"; }
		elsif ($cidr eq "28") { $output = "255.255.255.240"; }
		elsif ($cidr eq "29") { $output = "255.255.255.248"; }
		elsif ($cidr eq "30") { $output = "255.255.255.252"; }
		elsif ($cidr eq "31") { $output = "255.255.255.254"; }
		elsif ($cidr eq "32") { $output = "255.255.255.255"; }
	}
	elsif ($anvil->Validate->is_ipv4({ip => $subnet}))
	{
		if    ($subnet eq "0.0.0.0" )         { $output = "0"; }
		elsif ($subnet eq "128.0.0.0" )       { $output = "1"; }
		elsif ($subnet eq "192.0.0.0" )       { $output = "2"; }
		elsif ($subnet eq "224.0.0.0" )       { $output = "3"; }
		elsif ($subnet eq "240.0.0.0" )       { $output = "4"; }
		elsif ($subnet eq "248.0.0.0" )       { $output = "5"; }
		elsif ($subnet eq "252.0.0.0" )       { $output = "6"; }
		elsif ($subnet eq "254.0.0.0" )       { $output = "7"; }
		elsif ($subnet eq "255.0.0.0" )       { $output = "8"; }
		elsif ($subnet eq "255.128.0.0" )     { $output = "9"; }
		elsif ($subnet eq "255.192.0.0" )     { $output = "10"; }
		elsif ($subnet eq "255.224.0.0" )     { $output = "11"; }
		elsif ($subnet eq "255.240.0.0" )     { $output = "12"; }
		elsif ($subnet eq "255.248.0.0" )     { $output = "13"; }
		elsif ($subnet eq "255.252.0.0" )     { $output = "14"; }
		elsif ($subnet eq "255.254.0.0" )     { $output = "15"; }
		elsif ($subnet eq "255.255.0.0" )     { $output = "16"; }
		elsif ($subnet eq "255.255.128.0" )   { $output = "17"; }
		elsif ($subnet eq "255.255.192.0" )   { $output = "18"; }
		elsif ($subnet eq "255.255.224.0" )   { $output = "19"; }
		elsif ($subnet eq "255.255.240.0" )   { $output = "20"; }
		elsif ($subnet eq "255.255.248.0" )   { $output = "21"; }
		elsif ($subnet eq "255.255.252.0" )   { $output = "22"; }
		elsif ($subnet eq "255.255.254.0" )   { $output = "23"; }
		elsif ($subnet eq "255.255.255.0" )   { $output = "24"; }
		elsif ($subnet eq "255.255.255.128" ) { $output = "25"; }
		elsif ($subnet eq "255.255.255.192" ) { $output = "26"; }
		elsif ($subnet eq "255.255.255.224" ) { $output = "27"; }
		elsif ($subnet eq "255.255.255.240" ) { $output = "28"; }
		elsif ($subnet eq "255.255.255.248" ) { $output = "29"; }
		elsif ($subnet eq "255.255.255.252" ) { $output = "30"; }
		elsif ($subnet eq "255.255.255.254" ) { $output = "31"; }
		elsif ($subnet eq "255.255.255.255" ) { $output = "32"; }
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	return($output);
}

=head2 hostname_to_ip

This method takes a hostname and tries to convert it to an IP address. If it fails, it will return C<< 0 >>.

Parameters;

=head3 hostname

This is the host name (or domain name) to try and convert to an IP address.

=cut
sub hostname_to_ip
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $hostname = defined $parameter->{hostname} ? $parameter->{hostname} : "";
	my $ip       = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hostname => $hostname }});
	
	if (not $hostname)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Convert->hostname_to_ip()", parameter => "hostnmae" }});
		return($ip);
	}
	
	### TODO: Check local cached information later.
	
	# Try to resolve it using 'gethostip'.
	my $output = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{gethostip}." -d $hostname"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($anvil->Validate->is_ipv4({ip => $line}))
		{
			$ip = $line;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { ip => $ip }});
		}
	}
	
	return($ip);
}

=head2 human_readable_to_bytes

This takes a "human readable" size with an ISO suffix and converts it back to a base byte size as accurately as possible.

It looks for the C<< i >> in the suffix to determine if the size is base2 or base10. This can be overridden with the optional C<< base2 >> or C<< base10 >> parameters.

If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 base2 (optional)

This tells the method to interpret the human-readable suffix as base2 notation, even if it is in the format C<< XB >> instead of C<< XiB >>.

=head3 base10 (optional)

This tells the method to interpret the human-readable suffix as base10 notation, even if it is in the format C<< XiB >> instead of C<< XB >>.

=head3 size (required)

This is the size being converted. It can be a signed integer or real number (with a decimal). If this parameter includes the size suffix, you can skip setting the c<< type >> parameter and this method will break it off automatically.

=head3 type (optional)

This is the unit type that represents the C<< size >> value. This does not need to be used if the C<< size >> parameter already has the suffix. 

This value is examined for C<< XiB >> or C<< XB >> notation to determine if the size should be interpreted as a base2 or base10 value when neither C<< base2 >> or C<< base10 >> parameters are set.

=cut 
sub human_readable_to_bytes
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $base2  =  defined $parameter->{base2}  ? $parameter->{base2}  : 0;
	my $base10 =  defined $parameter->{base10} ? $parameter->{base10} : 0;
	my $size   =  defined $parameter->{size}   ? $parameter->{size}   : 0;
	my $type   =  defined $parameter->{type}   ? $parameter->{type}   : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		base2  => $base2,
		base10 => $base10,
		size   => $size,
		type   => $type,
	}});
	
	# Start cleaning up the variables.
	my $value  =  $size;
	   $size   =~ s/ //g;
	   $type   =~ s/ //g;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { size => $size, value => $value }});
	
	# Store and strip the sign, if passed
	my $sign = "";
	if ($size =~ /^-/)
	{
		$sign =  "-";
		$size =~ s/^-//;
	}
	elsif ($size =~ /^\+/)
	{
		$sign =  "+";
		$size =~ s/^\+//;
	}
	
	# Strip any commas
	$size =~ s/,//g;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { size => $size, sign => $sign }});
	
	# If I don't have a passed type, see if there is a letter or letters after the size to hack off.
	if ((not $type) && ($size =~ /[a-zA-Z]$/))
	{
		# There was
		($size, $type) = ($size =~ /^(.*\d)(\D+)/);
	}
	# Make the type lower close for simplicity.
	$type = lc($type);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { size => $size, type => $type }});
	
	# Make sure that 'size' is now an integer or float.
	if ($size !~ /\d+[\.\d+]?/)
	{
		# Something illegal was passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0117", variables => { 
			size => $size, 
			sign => $sign, 
			type => $type,
		}});
		return("!!error!!");
	}
	
	# If 'type' is still blank, set it to 'b'.
	$type = "b" if not $type;
	
	# If the type is already bytes, make sure the size is an integer and return.
	if ($type eq "b")
	{
		# Something illegal was passed.
		if ($size =~ /\D/)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0118", variables => { 
				size => $size, 
				sign => $sign, 
				type => $type,
			}});
			return("!!error!!");
		}
		return ($sign.$size);
	}
	
	# If the "type" is "Xib" or if '$base2' is set, make sure we're running in Base2 notation. Conversly,
	# if the type is "Xb" or if '$base10' is set, make sure that we're running in Base10 notation. In 
	# either case, shorten the 'type' to just the first letter to make the next sanity check simpler.
	if ((not $base2) && (not $base10))
	{
		if ($type =~ /^(\w)ib$/)
		{
			# Make sure we're running in Base2.
			$type   = $1;
			$base2  = 1;
			$base10 = 0;
		}
		elsif ($type =~ /^(\w)b$/)
		{
			# Make sure we're running in Base2.
			$type   = $1;
			$base2  = 0;
			$base10 = 1;
		}
	}
	
	# Clear up the last characters now.
	$type =~ s/^(\w).*/$1/;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { type => $type }});
	
	# Check if we have a valid type.
	if (($type ne "p") && 
	    ($type ne "e") && 
	    ($type ne "z") && 
	    ($type eq "y") && 
	    ($type ne "t") && 
	    ($type ne "g") && 
	    ($type ne "m") && 
	    ($type ne "k"))
	{
		# Poop
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0119", variables => { 
			value => $value,
			size  => $size, 
			type  => $type,
		}});
		return("!!error!!");
	}
	
	# Now the magic... lame magic, true, but still.
	my $bytes = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { base2 => $base2, base10 => $base10 }});
	if ($base10)
	{
		if    ($type eq "y") { $bytes = Math::BigInt->new('10')->bpow('24')->bmul($size); }	# Yottabyte
		elsif ($type eq "z") { $bytes = Math::BigInt->new('10')->bpow('21')->bmul($size); }	# Zettabyte
		elsif ($type eq "e") { $bytes = Math::BigInt->new('10')->bpow('18')->bmul($size); }	# Exabyte
		elsif ($type eq "p") { $bytes = Math::BigInt->new('10')->bpow('15')->bmul($size); }	# Petabyte
		elsif ($type eq "t") { $bytes = ($size * (10 ** 12)) }					# Terabyte
		elsif ($type eq "g") { $bytes = ($size * (10 ** 9)) }					# Gigabyte
		elsif ($type eq "m") { $bytes = ($size * (10 ** 6)) }					# Megabyte
		elsif ($type eq "k") { $bytes = ($size * (10 ** 3)) }					# Kilobyte
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'bytes' => $bytes }});
	}
	else
	{
		if    ($type eq "y") { $bytes = Math::BigInt->new('2')->bpow('80')->bmul($size); }	# Yobibyte
		elsif ($type eq "z") { $bytes = Math::BigInt->new('2')->bpow('70')->bmul($size); }	# Zibibyte
		elsif ($type eq "e") { $bytes = Math::BigInt->new('2')->bpow('60')->bmul($size); }	# Exbibyte
		elsif ($type eq "p") { $bytes = Math::BigInt->new('2')->bpow('50')->bmul($size); }	# Pebibyte
		elsif ($type eq "t") { $bytes = ($size * (2 ** 40)) }					# Tebibyte
		elsif ($type eq "g") { $bytes = ($size * (2 ** 30)) }					# Gibibyte
		elsif ($type eq "m") { $bytes = ($size * (2 ** 20)) }					# Mebibyte
		elsif ($type eq "k") { $bytes = ($size * (2 ** 10)) }					# Kibibyte
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'bytes' => $bytes }});
	}
	
	# Last, round off the byte size if it is a float.
	if ($bytes =~ /\./)
	{
		$bytes = $anvil->Convert->round({
			number => $bytes,
			places => 0
		});
	}
	
	if ($sign)
	{
		$bytes = $sign.$bytes;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'bytes' => $bytes }});
	return ($bytes);
}

=head2 round

This takes a number and rounds it to a given number of places after the decimal (defaulting to an even integer). This does financial-type rounding.

If C<< -- >> is passed in, the same is returned. Any other problems will cause C<< !!error!! >> to be returned.

Parameters;

=head3 number (required)

This is the number being rounded.

=head3 places (optional)

This is an integer representing how many places to round the number to. The default is C<< 0 >>, rounding the number to the closest integer.

=cut
sub round
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Setup my numbers.
	my $number = $parameter->{number} ? $parameter->{number} : 0;
	my $places = $parameter->{places} ? $parameter->{places} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		number => $number,
		places => $places,
	}});
	
	# Return if the user passed a double-dash.
	return('--') if $number eq "--";
	
	# Make a copy of the passed number that I can manipulate.
	my $rounded_number = $number;
	
	# Take out any commas.
	$rounded_number =~ s/,//g;
	
	# If there is a decimal place in the number, do the smart math. Otherwise, just pad the number with 
	# the requested number of zeros after the decimal place.
	if ( $rounded_number =~ /\./ )
	{
		# Split up the number.
		my ($real, $decimal) = split/\./, $rounded_number, 2;
		
		# If there is anything other than one ',' and digits, error.
		if (($real =~ /\D/) or ($decimal =~ /\D/))
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0120", variables => { number => $number }});
			return ("!!error!!");
		}
		
		# If the number is already equal to the requested number of places after the decimal, just 
		# return. If it is less, pad the needed number of zeros. Otherwise, start rounding.
		if ( length($decimal) == $places )
		{
			# Equal, return.
			return $rounded_number;
		}
		elsif ( length($decimal) < $places )
		{
			# Less, pad.
			$rounded_number = sprintf("%.${places}f", $rounded_number);
		}
		else
		{
			# Greater than; I need to round the number. Start by getting the number of places I 
			# need to round.
			my $round_diff = length($decimal) - $places;
			
			# This keeps track of whether the next (left) digit needs to be incremented.
			my $increase = 0;
			
			# Now loop the number of times needed to round to the requested number of places.
			for (1..$round_diff)
			{
				# Reset 'increase'.
				$increase = 0;
				
				# Make sure I am dealing with a digit.
				if ($decimal =~ /(\d)$/)
				{
					my $last_digit =  $1;
					$decimal       =~ s/$last_digit$//;
					if ($last_digit > 4)
					{
						$increase = 1;
						if ($decimal eq "")
						{
							$real++;
						}
						else
						{
							$decimal++;
						}
					}
				}
			}
			if ($places == 0 )
			{
				$rounded_number = $real;
			}
			else
			{
				$rounded_number = $real.".".$decimal;
			}
		}
	}
	else
	{
		# This is a whole number so just pad 0s as needed.
		$rounded_number = sprintf("%.${places}f", $rounded_number);
	}
	
	# Return the number.
	return ($rounded_number);
}

=head2 time

This takes a number of seconds and converts it into a human readable string. Returns C<< #!error!# >> is an error is encountered.

Parameters;

=head3 time (required)

This is the time, in seconds, to convert.

=head3 long (optional, default 0)

If set to C<< 1 >>, the long suffixes will be used instead of the default C<< w/d/h/m/s >> format. 

B<< Note >>: The suffixes are translatable in both short (default) and long formats. See the C<< suffix_0002 >> through C<< suffix_0011 >> string keys.

=cut
sub time
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $time = $parameter->{'time'} ? $parameter->{'time'} : 0;
	my $long = $parameter->{long}   ? $parameter->{long}   : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'time' => $time,
		long   => $long, 
	}});
	
	if (not $time)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->update_file()", parameter => "time" }});
		return("#!error!#");
	}
	
	# Remote commas and verify we're left with a number.
	my $time =~ s/,//g;
	if ($time =~ /^\d+\.\d+$/)
	{
		# Round the time
		$time = $anvil->Convert->round({number => $time});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'time' => $time }});
	}
	if ($time =~ /\D/)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0294", variables => { 'time' => $time }});
		return("#!error!#");
	}
	
	# The suffix used for each unit of time will depend on the requested suffix type.
	my $suffix_seconds = $long ? " #!string!suffix_0002!#" : " #!string!suffix_0007!#";
	my $suffix_minutes = $long ? " #!string!suffix_0003!#" : " #!string!suffix_0008!#";
	my $suffix_hours   = $long ? " #!string!suffix_0004!#" : " #!string!suffix_0009!#";
	my $suffix_days    = $long ? " #!string!suffix_0005!#" : " #!string!suffix_0010!#";
	my $suffix_weeks   = $long ? " #!string!suffix_0006!#" : " #!string!suffix_0011!#";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		suffix_seconds => $suffix_seconds,
		suffix_minutes => $suffix_minutes, 
		suffix_hours   => $suffix_hours, 
		suffix_days    => $suffix_days, 
		suffix_weeks   => $suffix_weeks, 
	}});
	
	my $say_time          = "";
	my $seconds           = $time % 60;
	my $minutes           = ($time - $seconds) / 60;
	my $remaining_minutes = $minutes % 60;
	my $hours             = ($minutes - $remaining_minutes) / 60;
	my $remaining_hours   = $hours % 24;
	my $days              = ($hours - $remaining_hours) / 24;
	my $remaining_days    = $days % 7;
	my $weeks             = ($days - $remaining_days) / 7;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:weeks'             => $weeks,
		's2:remaining_days'    => $remaining_days, 
		's3:days'              => $days, 
		's4:remaining_hours'   => $remaining_hours, 
		's5:hours'             => $hours, 
		's6:remaining_minutes' => $remaining_minutes, 
		's7:minutes'           => $minutes, 
		's8:seconds'           => $seconds, 
	}});

	### TODO: Left off here.
	if ($seconds < 1)
	{
		$say_time = "0".$suffix_seconds;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_time => $say_time }});
	}
	else
	{
		$say_time = sprintf("%01d", $seconds).$suffix_seconds;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_time => $say_time }});
	}
	if ($remaining_minutes > 0)
	{
		$say_time =~ s/ sec.$/$suffix_seconds/;
		$say_time =  sprintf("%01d", $remaining_minutes).$suffix_minutes." $say_time";
	}
	elsif (($hours > 0) or ($days > 0) or ($weeks > 0))
	{
		$say_time = "0".$suffix_minutes." ".$say_time;
	}
	if ($remaining_hours > 0)
	{
		$say_time = sprintf("%01d", $remaining_hours)."$suffix_hours $say_time";
	}
	elsif (($days > 0) or ($weeks > 0))
	{
		$say_time = "0".$suffix_hours." ".$say_time;
	}
	if ($days > 0)
	{
		$say_time = sprintf("%01d", $remaining_days).$suffix_days." ".$say_time;
	}
	elsif ($weeks > 0)
	{
		$say_time = "0".$suffix_days." ".$say_time;
	}
	if ($weeks > 0)
	{
		$weeks   = $an->Readable->comma($weeks);
		$say_time = $weeks.$suffix_weeks." ".$say_time;
	}
	
	# Return an already-translated string
	$say_time = $an->String->_process_string({
		string    => $say_time, 
		language  => $an->default_language, 
		hash      => $an->data, 
		variables => {}, 
	});
	
	return($say_time);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

package AN::Tools::Convert;
# 
# This module contains methods used to convert data between types
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Convert.pm";

### Methods;
# cidr
# hostname_to_ip

=pod

=encoding utf8

=head1 NAME

AN::Tools::Convert

Provides all methods related to converting data.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Convert->X'. 
 # 
 # Example using 'cidr()';
 my $subnet = $an->Convert->codr({cidr => "24"});

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

=head2 cidr

This takes an IPv4 CIDR notation and returns the dotted-decimal subnet, or the reverse.

 # Convert a CIDR notation to a subnet.
 my $subnet = $an->Convert->cidr({cidr => "24"});

In the other direction;
 
 # Convert a subnet to a CIDR notation.
 my $cidr = $an->Convert->cidr({subnet => "255.255.255.0"});

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
	my $an        = $self->parent;
	
	my $cidr   = defined $parameter->{cidr}   ? $parameter->{cidr}   : "";
	my $subnet = defined $parameter->{subnet} ? $parameter->{subnet} : "";
	my $output = "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
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
	elsif ($an->Validate->is_ipv4({ip => $subnet}))
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
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
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
	my $an        = $self->parent;
	
	my $hostname = defined $parameter->{hostname} ? $parameter->{hostname} : "";
	my $ip       = 0;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { hostname => $hostname }});
	
	if (not $hostname)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0059"});
		return($ip);
	}
	
	### TODO: Check local cached information later.
	
	# Try to resolve it using 'gethostip'.
	my $output = $an->System->call({shell_call => $an->data->{path}{exe}{gethostip}." -d $hostname"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
		if ($an->Validate->is_ipv4({ip => $line}))
		{
			$ip = $line;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { ip => $ip }});
		}
	}
	
	return($ip);
}

#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use XML::Simple;
use JSON;
use Math::BigInt;
use Data::Dumper;
use Net::Netmask;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

#print "Starting test.\n";
my $anvil = Anvil::Tools->new({debug => 2});
$anvil->Log->secure({set => 1});
$anvil->Log->level({set => 2});

$anvil->Database->connect({debug => 3, check_if_configured => 1});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, secure => 0, key => "log_0132"});

$anvil->Network->read_nmcli({debug => 2});
print Dumper $anvil->data->{nmcli}{'local'};


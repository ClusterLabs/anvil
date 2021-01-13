#!/usr/bin/perl
# 
 
use strict;
use warnings;
use Anvil::Tools;
use Data::Dumper;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

my $anvil = Anvil::Tools->new();
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0115", variables => { program => $THIS_FILE }});

# Read switches (target ([user@]host[:port]) and the file with the target's password.
$anvil->Get->switches;

# Connect to the database(s).
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0132"});

my $anvil_uuid      = "2ac4dbcb-25d2-44b2-ae07-59707b0551ca";
my $node1_host_uuid = "92d0106c-8717-45da-a413-663d50323982";
my $node2_host_uuid = "8da3d2fe-783a-4619-abb5-8ccae58f7bd6";

my $primary_host_uuid = $anvil->Cluster->get_primary_host_uuid({debug => 2, anvil_uuid => $anvil_uuid});
if (not $primary_host_uuid)
{
	print "Neither node is primary.\n";
}
elsif ($primary_host_uuid eq $node1_host_uuid)
{
	print "Node 1 is primary\n";
}
elsif ($primary_host_uuid eq $node2_host_uuid)
{
	print "Node 2 is primary\n";
}
else
{
	print "wtf? [".$primary_host_uuid."]\n";
}

$anvil->nice_exit({exit_code => 0});

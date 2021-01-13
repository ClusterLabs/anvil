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

my $anvil_uuid = "a5ae5242-e9d3-46c9-9ce8-306855aa56db";
my ($free_minor, $free_port) = $anvil->DRBD->get_next_resource({anvil_uuid => "a5ae5242-e9d3-46c9-9ce8-306855aa56db"})
print "Next free minor: [".$free_minor."], port: [".$free_port."]\n";

$anvil->nice_exit({exit_code => 0});

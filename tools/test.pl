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
#$anvil->Database->connect;
#$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0132"});

my $hours   = 0;
my $minutes = 3;
my $seconds = 24;

print "Hours: [".$hours."], minutes: [".$minutes."], seconds: [".$seconds."]\n";

my $estimated_time_to_sync = (($hours * 3600) + ($minutes * 60) + $seconds);
print "ETA: [".$estimated_time_to_sync."] (".$anvil->Convert->time({'time' => $estimated_time_to_sync}).")\n";

$anvil->nice_exit({exit_code => 0});

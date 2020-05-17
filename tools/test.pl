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

my $anvil = Anvil::Tools->new({debug => 2});
$anvil->Log->secure({set => 1});
$anvil->Log->level({set => 2});

print "Connecting to the database(s);\b";
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, secure => 0, key => "log_0132"});
print "DB Connections: [".$anvil->data->{sys}{database}{connections}."]\n";

my $manifest_uuid = "8b4734e0-df34-4653-966f-73d8f29b6931";
$anvil->Striker->load_manifest({
	debug         => 2,
	manifest_uuid => $manifest_uuid,
});

print Dumper $anvil->data->{manifests}{manifest_uuid}{$manifest_uuid};

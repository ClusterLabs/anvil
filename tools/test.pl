#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use Data::Dumper;
use utf8;
binmode(STDERR, ':encoding(utf-8)');
binmode(STDOUT, ':encoding(utf-8)');
 
my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

my $anvil = Anvil::Tools->new();
$anvil->Log->level({set => 2});
$anvil->Log->secure({set => 1});

my $string = "スパ シコレ パソーワアド";
my $short  = $anvil->Words->shorten_string({
	debug    => 2, 
	string   => $string,
	'length' => 16,
});
print "String: [".$string."]\n";
print "Short:  [".$short."]\n";
die;

print "Connecting to the database(s);\n";
$anvil->Database->connect();
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});
$anvil->Get->switches;

$anvil->System->configure_ipmi({
	debug         => 2,
	manifest_uuid => "6115d040-bdc4-4c76-9514-15870d88fb43",
});

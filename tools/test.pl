#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use Data::Dumper;
use String::ShellQuote;
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

$anvil->data->{switches}{'shutdown'} = "";
$anvil->data->{switches}{boot}       = "";
$anvil->data->{switches}{server}     = "";
$anvil->Get->switches;

print "Connecting to the database(s);\n";
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});

my $agent       = "scan-apc-ups";
my $schema_file = $anvil->data->{path}{directories}{scan_agents}."/".$agent."/".$agent.".sql";
my $tables      = $anvil->Database->get_tables_from_schema({debug => 2, schema_file => $schema_file});
print "Schema file: [".$schema_file."]\n";
foreach my $table (@{$tables})
{
	print "- ".$table."\n";
}

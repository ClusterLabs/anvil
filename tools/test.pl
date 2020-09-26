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
$anvil->Get->switches;

print "Connecting to the database(s);\n";
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});

$anvil->Storage->get_file_stats({
	debug     => 2,
	file_path => "/root/test",
});

# $anvil->Cluster->shutdown_server({
# 	debug  => 2,
# 	server => "srv07-el6",
# });
# $anvil->Cluster->shutdown_server({
# 	debug  => 2,
# 	server => "srv01-sql",
# });
# exit;

if (0)
{
	my $xml = '';
	my $problem = $anvil->Cluster->parse_crm_mon({debug => 2, xml => $xml});
	if ($problem)
	{
		print "Problem reading or parsing the 'crm_mon' XML.\n";
	}
	else
	{
		print "crm_mon parsed.\n";
	}
}

if (0)
{
	my $problem = $anvil->Cluster->parse_cib({debug => 2});
	print "Problem: [".$problem."]\n";
}

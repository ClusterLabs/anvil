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

my $parsed_xml = "";
my $xml_body   = $anvil->Storage->read_file({file => "/root/test.xml"});


my $xml = XML::Simple->new();
eval { $parsed_xml = $xml->XMLin($xml_body, KeyAttr => { key => 'name' }, ForceArray => []) };
if ($@)
{
	chomp $@;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0111", variables => { 
		xml_body   => $xml_body, 
		eval_error => $@,
	}});
	return(1);
}

print Dumper $parsed_xml;

#print "Connecting to the database(s);\b";
#$anvil->Database->connect({debug => 3});
#$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, secure => 0, key => "log_0132"});
#print "DB Connections: [".$anvil->data->{sys}{database}{connections}."]\n";
#$anvil->Striker->get_ups_data({debug => 2});

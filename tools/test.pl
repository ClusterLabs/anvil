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

my $host_name = "mk-a02n02";
my $host_uuid = $anvil->Get->host_uuid_from_name({
	debug     => 2,
	host_name => $host_name,
});
print "host name: [".$host_name."], host_uuid: [".$host_uuid."]\n";

exit;


my $server_name = $anvil->data->{switches}{server} ? $anvil->data->{switches}{server} : "srv07-el6";
if ($anvil->data->{switches}{boot})
{
	print "Booting: [".$server_name."]\n";
	$anvil->Server->boot_virsh({
		debug  => 2,
		server => $server_name,
	});
}
elsif ($anvil->data->{switches}{'shutdown'})
{
	print "Shutting down: [".$server_name."]\n";
	$anvil->Server->shutdown_virsh({
		debug  => 2,
		server => $server_name,
	});
}
exit;

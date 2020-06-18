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
$anvil->Log->level({set => 2});
$anvil->Log->secure({set => 1});

print "Connecting to the database(s);\n";
#$anvil->data->{switches}{'resync-db'} = "ceea1896-6dc3-470c-b42f-9be831f670d3";
$anvil->Database->connect();
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});

foreach my $uuid (sort {$a cmp $b} keys %{$anvil->data->{cache}{database_handle}})
{
	my $query = "SELECT host_name, host_type FROM hosts WHERE host_uuid = '3f3f2cfb-bd93-43dd-9bd3-ae3a693b50b8';";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0074", variables => { 
		uuid  => $anvil->data->{database}{$uuid}{host}, 
		query => $query,
	}});
	
	my $results = $anvil->Database->query({uuid => $uuid, query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		's1:uuid'    => $uuid,
		's2:count'   => $count,
		's3:results' => $results, 
		's4:name'    => $results->[0]->[0],
		's5:type'    => $results->[0]->[1],
	}});
	
}

#$anvil->Database->insert_or_update_hosts({debug => 2});
#$anvil->System->check_ssh_keys({debug => 2});

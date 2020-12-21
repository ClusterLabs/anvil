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
$anvil->Database->connect;
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0132"});

if (0)
{
	foreach my $uuid ("4c4c4544-0043-4210-8043-c3c04f523533", "4c4c4544-0043-4210-8042-c3c04f523533", "30343536-3138-5355-4534-3238324b4842", "b4e46faf-0ebe-e211-a0d6-00262d0ca874", "4ba42b4e-9bf7-e311-a889-899427029de4")
	{
		my $variable_uuid = $anvil->Database->insert_or_update_variables({
			debug                 => 2,
			variable_name         => 'system::stop_reason', 
			variable_value        => 'thermal', 
			variable_default      => '', 
			variable_description  => 'striker_0279', 
			variable_section      => 'system', 
			variable_source_uuid  => $uuid, 
			variable_source_table => 'hosts', 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { variable_uuid => $variable_uuid }});
	}
}

if (1)
{
	$anvil->ScanCore->post_scan_analysis({debug => 3});
}

if (0)
{
	my $problem = $anvil->Striker->load_manifest({
		debug         => 2, 
		manifest_uuid => "006ee2cb-1fbd-4ea6-89d6-96cf3bc94940",
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { problem => $problem }});
}

$anvil->nice_exit({exit_code => 0});

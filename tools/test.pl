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

exit;

my $anvil_uuid = $anvil->data->{switches}{'anvil-uuid'};
print "Anvil! UUID: [".$anvil_uuid."]\n";
$anvil->Database->get_anvils();
$anvil->Get->available_resources({
	debug      => 2,
	anvil_uuid => $anvil_uuid,
});

my $has_dr = $anvil->data->{anvil_resources}{$anvil_uuid}{has_dr} ? "Yes" : "No";
print "- Anvil! Name: ..... [".$anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_name}."] available resources;\n";
print "- Has DR Host? ..... [".$has_dr."]\n";
print "- CPU Cores/Threads: [".$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{cores}." / ".$anvil->data->{anvil_resources}{$anvil_uuid}{cpu}{threads}."]\n";
print "- RAM Total/Free: .. [".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{hardware}})." / ".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}})."] (".$anvil->Convert->add_commas({number => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{hardware}})." / ".$anvil->Convert->add_commas({number => $anvil->data->{anvil_resources}{$anvil_uuid}{ram}{available}}).")\n";
print "- Networks;\n";
foreach my $bridge_name (sort {$a cmp $b} keys %{$anvil->data->{anvil_resources}{$anvil_uuid}{bridges}})
{
	if ($anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on_nodes})
	{
		if ($anvil->data->{anvil_resources}{$anvil_uuid}{bridges}{$bridge_name}{on_dr})
		{
			print "  - ".$bridge_name."\n";
		}
		else
		{
			print "  - ".$bridge_name." (not on DR)\n";
		}
	}
}
print "- Storage:\n";
foreach my $storage_group_name (sort {$a cmp $b} keys %{$anvil->data->{anvil_resources}{$anvil_uuid}{storage_group_name}})
{
	my $storage_group_uuid = $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group_name}{$storage_group_name}{storage_group_uuid};
	my $vg_size            = $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{vg_size};
	my $vg_free            = $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{free_size};
	my $dr_size            = $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{vg_size_on_dr};
	my $dr_free            = $anvil->data->{anvil_resources}{$anvil_uuid}{storage_group}{$storage_group_uuid}{available_on_dr};
	print "  - Storage group: [".$storage_group_uuid."]\n";
	print "  |- Name: ....... [".$storage_group_name."]\n";
	print "  |- Size/Free: .. [".$anvil->Convert->bytes_to_human_readable({'bytes' => $vg_size})." / ".$anvil->Convert->bytes_to_human_readable({'bytes' => $vg_free})."] (".$anvil->Convert->add_commas({number => $vg_size})." / ".$anvil->Convert->add_commas({number => $vg_free}).")\n";
	print "  \\- DR Size/Free: [".$anvil->Convert->bytes_to_human_readable({'bytes' => $dr_size})." / ".$anvil->Convert->bytes_to_human_readable({'bytes' => $dr_free})."] (".$anvil->Convert->add_commas({number => $dr_size})." / ".$anvil->Convert->add_commas({number => $dr_free}).")\n";
}	

$anvil->nice_exit({exit_code => 0});

#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use XML::Simple;
use JSON;
use Math::BigInt;
use Data::Dumper;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

#print "Starting test.\n";
my $anvil = Anvil::Tools->new({debug => 2});
$anvil->Log->secure({set => 1});
$anvil->Log->level({set => 2});

$anvil->Database->connect({debug => 3, check_if_configured => 1});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, secure => 0, key => "log_0132"});

my $interface_uuid = "ffd6d29b-100c-452f-be4f-51cbc94eb069";
my $query          = "SELECT network_interface_bridge_uuid FROM network_interfaces WHERE network_interface_uuid = ".$anvil->Database->quote($interface_uuid).";";
$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { query => $query }});
my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
my $count   = @{$results};
$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
	results => $results, 
	count   => $count,
}});
my $network_interface_bridge_uuid = defined $results->[0]->[0] ? $results->[0]->[0] : "";
$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { network_interface_bridge_uuid => $network_interface_bridge_uuid }});


#$anvil->System->generate_state_json({debug => 3});
#$anvil->Striker->parse_all_status_json({debug => 3});

#print Dumper $anvil->data->{json}{all_status}{hosts}{'el8-a01n01.digimer.ca'};
die;

foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}})
{
	print "\n";
	print "Host: [".$host_name." (".$anvil->data->{json}{all_status}{hosts}{$host_name}{short_host_name}.")], Type: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{type}."], Configured: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{configured}."], \n";
	#print " - Host UUID: ..... [".$anvil->data->{json}{all_status}{hosts}{$host_name}{host_uuid}."]\n";
	#print " - SSH Fingerprint: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{ssh_fingerprint}."]\n";
	
	foreach my $interface_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}})
	{
		my $uuid            = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{uuid};
		my $mtu             = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{mtu}." ".$anvil->Words->string({key => "suffix_0014"});
		my $bridge_id       = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{bridge_id};
		my $stp_enabled     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{stp_enabled};
		my $ip              = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{ip};
		my $subnet_mask     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{subnet_mask};
		my $default_gateway = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{default_gateway};
		my $gateway         = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{gateway};
		my $dns             = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{dns};
		print "- Bridge: [".$interface_name."], MTU: [".$mtu."], ID: [".$bridge_id."], STP: [".$stp_enabled."]\n";
		if ($ip)
		{
			if ($gateway)
			{
				print " - IP: [".$ip."/".$subnet_mask."], Gateway (default?): [".$gateway." (".$default_gateway.")], DNS: [".$dns."]\n";
			}
			else
			{
				print " - IP: [".$ip."/".$subnet_mask."]\n";
			}
		}
		else
		{
			print " - No IP on this bridge\n";
		}
		
		my $connected_interfaces = keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{connected_interfaces}};
		if ($connected_interfaces)
		{
			print "==[ Interfaces connected to this bridge ]==\n";
			foreach my $connected_interface (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{connected_interfaces}})
			{
				my $type = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{connected_interfaces}{$connected_interface}{type};
				if ($type eq "bond")
				{
					show_bond($anvil, $host_name, $connected_interface);
				}
				else
				{
					show_interface($anvil, $host_name, $connected_interface);
				}
			}
			print "===========================================\n";
		}
		else
		{
			print "==[ Nothing connected to this bridge ]===\n";
		}
		$anvil->data->{json}{all_status}{hosts}{$host_name}{shown}{$interface_name} = 1;
	}
	
	# Print the rest of the interfaces now.
	foreach my $interface_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}})
	{
		next if $anvil->data->{json}{all_status}{hosts}{$host_name}{shown}{$interface_name};
		show_bond($anvil, $host_name, $interface_name, "");
	}
	
	foreach my $interface_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}})
	{
		next if $anvil->data->{json}{all_status}{hosts}{$host_name}{shown}{$interface_name};
		show_interface($anvil, $host_name, $interface_name, "");
	}
}

$anvil->nice_exit({exit_code => 0});

sub show_bond
{ 
	my ($anvil, $host_name, $interface_name) = @_;
	
	print "Bond: [".$interface_name."]\n";
	my $uuid                 = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{uuid};
	my $mtu                  = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{mtu}." ".$anvil->Words->string({key => "suffix_0014"});
	my $ip                   = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{ip};
	my $subnet_mask          = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{subnet_mask};
	my $default_gateway      = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{default_gateway};
	my $gateway              = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{gateway};
	my $dns                  = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{dns};
	my $mode                 = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{mode};
	my $active_interface     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{active_interface};
	my $primary_interface    = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{primary_interface};
	my $primary_reselect     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{primary_reselect};
	my $up_delay             = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{up_delay};
	my $down_delay           = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{down_delay};
	my $operational          = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{operational};
	my $mii_polling_interval = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{mii_polling_interval};
	my $bridge_name          = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{bridge_name};
	my $say_up_delay         = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{say_up_delay};
	my $say_down_delay       = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{say_down_delay};
	my $say_mode             = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{say_mode};
	my $say_operational      = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{say_operational};
	my $say_primary_reselect = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{say_primary_reselect};
	
	print "- Bond: [".$interface_name."], Mode: [".$say_mode." (".$mode.")], MTU: [".$mtu."], Operational: [".$say_operational." (".$operational.")], Bridge: [".$bridge_name."]\n";
	print "  Active interface: [".$active_interface."], Primary interface: [".$primary_interface."], Primary reselect policy: [".$say_primary_reselect." (".$primary_reselect.")]\n";
	print "  Up delay: [".$say_up_delay." (".$up_delay.")], Down delay: [".$say_down_delay." (".$down_delay.")], MII polling interval: [".$mii_polling_interval."]\n";
	if ($ip)
	{
		if ($gateway)
		{
			print " - IP: [".$ip."/".$subnet_mask."], Gateway (default?): [".$gateway." (".$default_gateway.")], DNS: [".$dns."]\n";
		}
		else
		{
			print " - IP: [".$ip."/".$subnet_mask."]\n";
		}
	}
	else
	{
		print " - No IP on this bond\n";
	}
	
	my $connected_interfaces = keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{connected_interfaces}};
	if ($connected_interfaces)
	{
		print "--[ Interfaces connected to this bond ]----\n";
		foreach my $connected_interface (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bond}{$interface_name}{connected_interfaces}})
		{
			show_interface($anvil, $host_name, $connected_interface);
		}
		print "-------------------------------------------";
	}
	else
	{
		print "--[ Nothing connected to this bond ]-----\n";
	}
	
	print "\n";
	$anvil->data->{json}{all_status}{hosts}{$host_name}{shown}{$interface_name} = 1;
	
	return(0);
}

sub show_interface
{ 
	my ($anvil, $host_name, $interface_name) = @_;
	print "Interface: [".$interface_name."]\n";
	
	my $uuid            = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{uuid};
	my $mtu             = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{mtu}." ".$anvil->Words->string({key => "suffix_0014"});
	my $ip              = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{ip};
	my $subnet_mask     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{subnet_mask};
	my $default_gateway = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{default_gateway};
	my $gateway         = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{gateway};
	my $dns             = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{dns};
	my $speed           = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{speed};
	my $link_state      = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{link_state};
	my $operational     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{operational};
	my $duplex          = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{duplex};
	my $medium          = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{medium};
	my $bridge_name     = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{bridge_name};
	my $bond_name       = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{bond_name};
	my $changed_order   = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{changed_order};
	my $say_speed       = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{say_speed};
	my $say_duplex      = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{say_duplex};
	my $say_link_state  = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{say_link_state};
	my $say_operational = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{say_operationa};
	my $say_medium      = $anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{interface}{$interface_name}{say_medium};
	
	print "- Interface: [".$interface_name."], MTU: [".$mtu."], Operational: [".$say_operational." (".$operational.")], Link state: [".$say_link_state." (".$link_state.")]\n";
	print "  Change Order: [".$changed_order."], Speed: [".$say_speed." (".$speed.")], Duplex: [".$say_duplex." (".$duplex.")], Medium: [".$say_medium." (".$medium.")]\n";
	print "  Connected to bond: [".$bond_name."], bridge: [".$bridge_name."]\n";
	if ($ip)
	{
		if ($gateway)
		{
			print " - IP: [".$ip."/".$subnet_mask."], Gateway (default?): [".$gateway." (".$default_gateway.")], DNS: [".$dns."]\n";
		}
		else
		{
			print " - IP: [".$ip."/".$subnet_mask."]\n";
		}
	}
	else
	{
		print " - No IP on this interface\n";
	}
	
	print "\n";
	$anvil->data->{json}{all_status}{hosts}{$host_name}{shown}{$interface_name} = 1;
	
	return(0);
}

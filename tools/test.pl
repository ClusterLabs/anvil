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

$anvil->System->generate_state_json({debug => 3});
$anvil->Striker->parse_all_status_json({debug => 3});

# print Dumper $anvil->data->{json}{all_status}{hosts};
# die;

# foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}})
# {
# 	print $THIS_FILE." ".__LINE__."; Host: [".$host_name."]\n";
# 	foreach my $network_type (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}})
# 	{
# 		print $THIS_FILE." ".__LINE__.";  - Network type: [".$network_type."]\n";
# 		foreach my $interface_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}})
# 		{
# 			print $THIS_FILE." ".__LINE__.";   - Interface: [".$interface_name."]\n";
# 			foreach my $variable (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}})
# 			{
# 				if (ref ($anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}{$variable}) eq "HASH")
# 				{
# 					print $THIS_FILE." ".__LINE__.";    - ".$variable.";\n";
# 					foreach my $value (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}{$variable}})
# 					{
# 						print $THIS_FILE." ".__LINE__.";     - ".$value." -> [".$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}{$variable}{$value}{type}."]\n";
# 					}
# 				}
# 				elsif (ref ($anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}{$variable}) eq "ARRAY")
# 				{
# 					print $THIS_FILE." ".__LINE__.";    - ".$variable.";\n";
# 					foreach my $value (sort {$a cmp $b} @{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}{$variable}})
# 					{
# 						print $THIS_FILE." ".__LINE__.";     - ".$value."\n";
# 					}
# 				}
# 				else
# 				{
# 					print $THIS_FILE." ".__LINE__.";    - ".$variable.": [".$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{$network_type}{$interface_name}{$variable}."]\n";
# 				}
# 			}
# 		}
# 	}
# }

# print Dumper $anvil->data->{json}{all_status}{hosts};
#die;

foreach my $host_name (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}})
{
	print "Host: [".$host_name." (".$anvil->data->{json}{all_status}{hosts}{$host_name}{short_host_name}.")], Type: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{type}."], Configured: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{configured}."], \n";
	print " - Host UUID: ..... [".$anvil->data->{json}{all_status}{hosts}{$host_name}{host_uuid}."]\n";
	print " - SSH Fingerprint: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{ssh_fingerprint}."]\n";
	
	my $highest_mtu = 0;
	my $shown       = {};
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
		print "   - Bridge: [".$interface_name."], MTU: [".$mtu."], ID: [".$bridge_id."], STP: [".$stp_enabled."]\n";
		if ($ip)
		{
			if ($gateway)
			{
				print "   - IP: [".$ip."/".$subnet_mask."], Gateway (default?): [".$gateway." (".$default_gateway.")], DNS: [".$dns."]\n";
			}
			else
			{
				print "   - IP: [".$ip."/".$subnet_mask."]\n";
			}
		}
		else
		{
			print "   - No IP on this device\n";
		}
		foreach my $connected_interface (sort {$a cmp $b} keys %{$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{connected_interfaces}})
		{
			print "     - Connected: [".$connected_interface."], type: [".$anvil->data->{json}{all_status}{hosts}{$host_name}{network_interface}{bridge}{$interface_name}{connected_interfaces}{$connected_interface}{type}."]\n";
			if ($type eq "bond")
			{
				show_bond($anvil, $connected_interface);
			}
			else
			{
				show_interface($anvil, $connected_interface);
			}
		}
		
		$shown->{$interface_name} = 1;
	}
}

$anvil->nice_exit({exit_code => 0});

sub show_bond
{ 
	my ($anvil, $connected_interface) = @_;
	
	
	
	return(0);
}

sub show_interface
{ 
	my ($anvil, $connected_interface) = @_;
	
	
	
	return(0);
}

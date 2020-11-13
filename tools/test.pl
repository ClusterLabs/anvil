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

# These packages can't be downloaded on RHEL Striker dashboads as they usually are not entitled to 
$anvil->data->{ha_packages} = {
	c	=>	[
		"corosync.x86_64",
		"corosynclib.x86_64",
	],
	l	=>	[
		"libknet1.x86_64",
		"libknet1-compress-bzip2-plugin.x86_64",
		"libknet1-compress-lz4-plugin.x86_64",
		"libknet1-compress-lzma-plugin.x86_64",
		"libknet1-compress-lzo2-plugin.x86_64",
		"libknet1-compress-plugins-all.x86_64",
		"libknet1-compress-zlib-plugin.x86_64",
		"libknet1-crypto-nss-plugin.x86_64", 
		"libknet1-crypto-openssl-plugin.x86_64",
		"libknet1-crypto-plugins-all.x86_64",
		"libknet1-plugins-all.x86_64",
		"libnozzle1.x86_64",
	],
	p	=>	[
		"pacemaker.x86_64",
		"pacemaker-cli.x86_64",
		"pacemaker-cluster-libs.x86_64",
		"pacemaker-libs.x86_64",
		"pacemaker-schemas.noarch",
	],
	r	=>	[
		"resource-agents.x86_64",
	],
};

my $use_node_name = "";
my $use_node_ip   = "";
my $use_password  = "";

my ($os_type, $os_arch) = $anvil->Get->os_type();
$anvil->data->{host_os}{os_type} = $os_type;
$anvil->data->{host_os}{os_arch} = $os_arch;
if ($anvil->data->{host_os}{os_type} eq "rhel8")
{
	my $local_short_host_name = $anvil->Get->short_host_name;
	$anvil->Network->load_ips({
		debug => 3,
		host  => $local_short_host_name, 
	});
	print "My OS is: [".$anvil->data->{host_os}{os_type}."], [".$anvil->data->{host_os}{os_arch}."]\n";

	my $query = "
SELECT 
    a.host_uuid, 
    a.host_name, 
    b.anvil_password 
FROM 
    hosts a, 
    anvils b 
WHERE 
    a.host_type = 'node' 
AND 
    (
        a.host_uuid = b.anvil_node1_host_uuid 
    OR 
        a.host_uuid = b.anvil_node2_host_uuid
    ) 
ORDER BY 
    a.host_name ASC
;";
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		results => $results, 
		count   => $count,
	}});
	foreach my $row (@{$results})
	{
		my $host_uuid       = $row->[0];
		my $host_name       = $row->[1];
		my $anvil_password  = $row->[2];
		my $short_host_name = $host_name;
		$short_host_name =~ s/\..*$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			host_uuid       => $host_uuid, 
			host_name       => $host_name, 
			anvil_password  => $anvil->Log->is_secure($anvil_password), 
			short_host_name => $short_host_name, 
		}});
		$anvil->Network->load_ips({
			debug     => 3, 
			host_uuid => $host_uuid,
			host      => $short_host_name, 
		});

		my $access  = 0;
		my ($match) = $anvil->Network->find_matches({
			debug  => 3,
			first  => $local_short_host_name, 
			second => $short_host_name,
		});
		
		my $keys = keys %{$match};
		print "Node: [".$host_name."]\n";
		print "- match: [".$match."], keys: [".$keys."]\n";
		
		if ($keys)
		{
			foreach my $interface (sort {$a cmp $b} keys %{$match->{$short_host_name}})
			{
				my $remote_ip = $match->{$short_host_name}{$interface}{ip};
				print "- Should be able to reach: [".$short_host_name."] at the IP: [".$remote_ip."]\n";
				
				my $pinged = $anvil->Network->ping({
					ping  => $remote_ip, 
					count => 1,
				});
				if ($pinged)
				{
					print "- The node is pingable, checking access.\n";
					my $access = $anvil->Remote->test_access({
						target   => $remote_ip,
						password => $anvil_password,
					});
					if ($access)
					{
						print "- Accessed! Testing Internet...\n";
						
						my $internet = $anvil->Network->check_internet({
							debug    => 3,
							target   => $remote_ip, 
							password => $anvil_password, 
						});
						if ($internet)
						{
							print "- Has Internet access! Checking OS...\n";
							my ($os_type, $os_arch) = $anvil->Get->os_type({
								debug    => 3,
								target   => $remote_ip,
								password => $anvil_password, 
							});
							print "- The host OS is: [".$os_type."], [".$os_arch."]\n";
							if (($anvil->data->{host_os}{os_type} eq $os_type) && ($os_arch eq $anvil->data->{host_os}{os_arch}))
							{
								print "- Found a match!\n";
								$use_node_name = $host_name;
								$use_node_ip   = $remote_ip;
								$use_password  = $anvil_password;
								last;
							}
						}
					}
					else
					{
						print "- Unable to connect.\n";
					}
				}
				else
				{
					print "- Unable to ping, skipping.\n";
				}
			}
		}
	}

	if ($use_node_ip)
	{
		print "Will download RPMs via: [".$use_node_name."] via IP: [".$use_node_ip."]\n";
		
		foreach my $letter (sort {$a cmp $b} keys %{$anvil->data->{ha_packages}})
		{
			my $download_path = "/tmp/Packages/".$letter;
			my $local_path    = "/var/www/html/".$anvil->data->{host_os}{os_type}."/".$anvil->data->{host_os}{os_arch}."/os/Packages/".$letter;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				letter        => $letter, 
				download_path => $download_path, 
				local_path    => $local_path, 
			}});
			
			# This is the directory we'll download the packages to on the node.
			$anvil->Storage->make_directory({
				debug     => 3,
				directory => $download_path, 
				target    => $use_node_ip, 
				password  => $use_password, 
				mode      => "0775", 
			});
			
			my $packages   = "";
			my $shell_call = $anvil->data->{path}{exe}{dnf}." download --destdir ".$download_path." ";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { shell_call => $shell_call }});
			foreach my $package (sort {$a cmp $b} @{$anvil->data->{ha_packages}{$letter}})
			{
				# Append the package to the active shell call.
				$packages .= $package." ";
			}
			$packages   =~ s/ $//;
			$shell_call .= " ".$packages;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
			
			# None of the HA packages are large os it's not worth trying to monitor the downlaods
			# in real time. As such, we'll make a standard remote call.
			my ($output, $error, $return_code) = $anvil->Remote->call({
				debug       => 3, 
				target      => $use_node_ip,
				password    => $use_password,
				shell_call  => $shell_call,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				output      => $output,
				error       => $error, 
				return_code => $return_code, 
			}});
			
			if (not $return_code)
			{
				# Success! Copy the files.
				my $failed = $anvil->Storage->rsync({
					debug       => 2, 
					source      => "root\@".$use_node_ip.":".$download_path."/*",
					destination => $local_path."/",
					password    => $use_password, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { failed => $failed }});
			}
		}
	}
	else
	{
		print "No nodes are available to try to download HA packages from.\n"
	}
}

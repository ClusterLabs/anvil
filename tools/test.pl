#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use Data::Dumper;
use String::ShellQuote;

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
$anvil->Database->connect();
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});

$anvil->data->{switches}{start} = "";
$anvil->data->{switches}{stop}  = "";
$anvil->Get->switches;

my $peer      = $anvil->Cluster->get_peers();
my $i_am      = $anvil->data->{sys}{anvil}{i_am};
my $peer_is   = $anvil->data->{sys}{anvil}{peer_is};
my $my_name   = $i_am    ? $anvil->data->{sys}{anvil}{$i_am}{host_name}    : "--";
my $peer_name = $peer_is ? $anvil->data->{sys}{anvil}{$peer_is}{host_name} : "--";
print "I am: .. [".$i_am."], my host name is: . [".$my_name."]\n";
print "Peer is: [".$peer_is."], peer host name is: [".$peer_name."]\n";
print "- Returned peer: [".$peer."]\n";

if ($anvil->data->{switches}{start})
{
	foreach my $daemon ("libvirtd.service", "drbd.service")
	{
		my $running_local = 0;
		my $running_peer  = 0;
		
		my ($local_output, $local_return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			local_output      => $local_output, 
			local_return_code => $local_return_code,
		}});
		if ($local_return_code eq "3")
		{
			# Stopped, start it..
			print "Starting: [".$daemon."] locally\n";
			my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." start ".$daemon});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				output      => $output, 
				return_code => $return_code,
			}});
			
			my $loops   = 0;
			my $running = 0;
			until ($running)
			{
				my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					output      => $output, 
					return_code => $return_code,
				}});
				if ($return_code eq "0")
				{
					$running = 1;
					print "Verified start of: [".$daemon."]\n";
				}
				else
				{
					$loops++;
					if ($loops > 3)
					{
						# Give up
						print "[ Error ] - Start of: [".$daemon."] appears to have failed!\n";
						die;
					}
					else
					{
						# Wait for a second.
						sleep 1;
						print "Waiting for: [".$daemon."] to start...\n";
					}
				}
			}
		}
		elsif ($local_return_code eq "0")
		{
			# Running, nothing to do.
			print "The daemon: [".$daemon."] is already running locally.\n";
		}
		
		my ($remote_output, $remote_error, $remote_return_code) = $anvil->Remote->call({
			target     => $peer_name,
			shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			remote_output      => $remote_output, 
			remote_error       => $remote_error, 
			remote_return_code => $remote_return_code,
		}});
		if ($remote_return_code eq "3")
		{
			# Stopped, start it..
			print "Starting: [".$daemon."] on: [".$peer_name."]\n";
			my ($output, $error, $return_code) = $anvil->Remote->call({
				target     => $peer_name, 
				shell_call => $anvil->data->{path}{exe}{systemctl}." start ".$daemon,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				output      => $output, 
				error       => $error, 
				return_code => $return_code,
			}});
			
			my $loops   = 0;
			my $running = 0;
			until ($running)
			{
				my ($output, $error, $return_code) = $anvil->Remote->call({
					target     => $peer_name,
					shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					output      => $output, 
					error       => $error, 
					return_code => $return_code,
				}});
				if ($return_code eq "0")
				{
					$running = 1;
					print "Verified start of: [".$daemon."] on: [".$peer_name."]\n";
				}
				else
				{
					$loops++;
					if ($loops > 3)
					{
						# Give up
						print "[ Error ] - Start of: [".$daemon."] on: [".$peer_name."] appears to have failed!\n";
						die;
					}
					else
					{
						# Wait for a second.
						sleep 1;
						print "Waiting for: [".$daemon."] to start on: [".$peer_name."]...\n";
					}
				}
			}
		}
		elsif ($remote_return_code eq "0")
		{
			# Running, nothing to do.
			print "The daemon: [".$daemon."] is already running on: [".$peer_name."].\n";
		}
	}
}
elsif ($anvil->data->{switches}{stop})
{
	my $stop = 0;
	
	# Check both nodes if a server is running on either node.
	my $local_vm_count  = 0;
	my $remote_vm_count = 0;
	
	# Call virsh list --all
	my ($local_output, $local_return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{virsh}." list --all"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		local_output      => $local_output, 
		local_return_code => $local_return_code,
	}});
	if (not $local_return_code)
	{
		# Parse output
		foreach my $line (split/\n/, $local_output)
		{
			$line = $anvil->Words->clean_spaces({ string => $line });
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
			
			if ($line =~ /(\d+)\s+(.*?)\s+running/)
			{
				$local_vm_count++;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { local_vm_count => $local_vm_count }});
			}
		}
	}
	
	my ($remote_output, $remote_error, $remote_return_code) = $anvil->Remote->call({
		target     => $peer_name,
		shell_call => $anvil->data->{path}{exe}{virsh}." list --all",
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		remote_output      => $remote_output, 
		remote_error       => $remote_error, 
		remote_return_code => $remote_return_code,
	}});
	if (not $remote_return_code)
	{
		# Parse output
		foreach my $line (split/\n/, $remote_output)
		{
			$line = $anvil->Words->clean_spaces({ string => $line });
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
			
			if ($line =~ /(\d+)\s+(.*?)\s+running/)
			{
				$remote_vm_count++;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { remote_vm_count => $remote_vm_count }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		local_vm_count  => $local_vm_count, 
		remote_vm_count => $remote_vm_count,
	}});
	if ((not $local_vm_count) && (not $remote_vm_count))
	{
		print "No servers running on either node, stopping daemons.\n";
		foreach my $daemon ("libvirtd.service", "drbd.service")
		{
			my $running_local = 0;
			my $running_peer  = 0;
			
			my ($local_output, $local_return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				local_output      => $local_output, 
				local_return_code => $local_return_code,
			}});
			if ($local_return_code eq "3")
			{
				# Already stopped.
				print "The daemon: [".$daemon."] is already stopped locally.\n";
			}
			elsif ($local_return_code eq "0")
			{
				# Running, stop it.
				print "Stopping: [".$daemon."] locally\n";
				my ($output, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." stop ".$daemon});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					output      => $output, 
					return_code => $return_code,
				}});
			}
			
			my ($remote_output, $remote_error, $remote_return_code) = $anvil->Remote->call({
				target     => $peer_name,
				shell_call => $anvil->data->{path}{exe}{systemctl}." status ".$daemon,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				remote_output      => $remote_output, 
				remote_error       => $remote_error, 
				remote_return_code => $remote_return_code,
			}});
			if ($remote_return_code eq "3")
			{
				# Already stopped.
				print "The daemon: [".$daemon."] is already stopped on: [".$peer_name."].\n";
			}
			elsif ($remote_return_code eq "0")
			{
				# Running, stop it.
				print "Stopping: [".$daemon."] on: [".$peer_name."]\n";
				my ($output, $error, $return_code) = $anvil->Remote->call({
					target     => $peer_name, 
					shell_call => $anvil->data->{path}{exe}{systemctl}." stop ".$daemon,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					output      => $output, 
					error       => $error, 
					return_code => $return_code,
				}});
			}
		}
	}
}

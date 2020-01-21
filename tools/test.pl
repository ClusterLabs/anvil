#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use XML::Simple;
use JSON;
use Math::BigInt;
use Data::Dumper;
use Net::Netmask;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

print "Starting test.\n";
my $anvil = Anvil::Tools->new({debug => 3});
$anvil->Log->secure({set => 1});
$anvil->Log->level({set => 2});

#print "Connecting to the database(s);\b";
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, secure => 0, key => "log_0132"});
#print "DB Connections: [".$anvil->data->{sys}{database}{connections}."]\n";
#$anvil->Network->load_interfces({debug => 2});
#$anvil->System->generate_state_json({debug => 2});

#$anvil->Words->language_list();
#foreach my $iso (sort {$a cmp $b} keys %{$anvil->data->{sys}{languages}})
#{
#	print "iso: [".$iso."] -> [".$anvil->data->{sys}{languages}{$iso}."]\n";
#}

# $anvil->Striker->get_fence_data({debug => 3});

# foreach my $fence_agent (sort {$a cmp $b} keys %{$anvil->data->{fences}})
# {
# 	# We skip fence_ipmilan, that's handled in the host.
# 	next if $fence_agent eq "fence_ipmilan";
# 	
# 	my $agent_description = $anvil->data->{fences}{$fence_agent}{description};
# 	print "Agent: [".$fence_agent."]\n";
# 	print "==========\n";
# 	print $agent_description."\n";
# 	print "==========\n";
# 	foreach my $name (sort {$a cmp $b} keys %{$anvil->data->{fences}{$fence_agent}{parameters}})
# 	{
# 		next if $anvil->data->{fences}{$fence_agent}{parameters}{$name}{replacement};
# 		next if $anvil->data->{fences}{$fence_agent}{parameters}{$name}{deprecated};
# 		my $unique      = $anvil->data->{fences}{$fence_agent}{parameters}{$name}{unique};
# 		my $required    = $anvil->data->{fences}{$fence_agent}{parameters}{$name}{required};
# 		my $description = $anvil->data->{fences}{$fence_agent}{parameters}{$name}{description};
# 		my $switches    = $anvil->data->{fences}{$fence_agent}{parameters}{$name}{switches};
# 		my $type        = $anvil->data->{fences}{$fence_agent}{parameters}{$name}{content_type};
# 		my $star        = $required ? "*" : "";
# 		my $default     = exists $anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'} ? $anvil->data->{fences}{$fence_agent}{parameters}{$name}{'default'} : "";
# 		print "- [".$name."]".$star.": Type: [".$type."], default: [".$default."], switches: [".$switches."]: [".$description."]\n";
# 		print " - Unique!\n"     if $unique;
# 		
# 		if ($type eq "select")
# 		{
# 			# Build the select box
# 			my $options = "";
# 			foreach my $option (sort @{$anvil->data->{fences}{$fence_agent}{parameters}{$name}{options}})
# 			{
# 				if (($default) && ($option eq $default))
# 				{
# 					$options .= " - [".$option."]*\n";
# 				}
# 				else
# 				{
# 					$options .= " - [".$option."]\n";
# 				}
# 			}
# 			print $options;
# 		}
# 	}
# 	
# 	
# }

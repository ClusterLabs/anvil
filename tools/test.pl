#!/usr/bin/perl
# 

use strict;
use warnings;
#use Anvil::Tools;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

foreach my $i (1..6)
{
	my $out = 8 + (2 * $i);
	print "$i: [$out]\n";
}


# # 2.75 = 69.85 - use up to 55 mm
# # 2.25 = 57.15 - use up to 45 mm
# # 1.75 = 44.45 - use up to 30 mm
# # 1.25 = 31.75 - use up to 20 mm
# 
# my $one_two_five   = [];
# my $one_seven_five = [];
# my $two_two_five   = [];
# my $two_seven_five = [];
# 
# my $data = "26,31,25,22,24,23,,
# ,36,37,34,30,38,35,,
# ,43,43,42,34,39,35,,
# ,47,47,48,40,33,31,23,17,
# ,47,47,41,37,35,22,19,8,11
# ,42,42,46,50,39,27,21,5,10
# ,42,40,43,49,35,33,30,26,
# ,39,39,36,39,31,28,25,25,
# ,36,35,32,29,19,20,15,15,
# ,33,31,31,15,21,23,17,11,
# ,31,33,30,23,26,21,20,14,
# ,23,42,26,17,12,20,16,20";
# 
# 
# foreach my $line (split/\n/, $data)
# {
# 	foreach my $depth (split/,/, $line)
# 	{
# 		next if not $depth;
# 		if    ($depth >= 45) { push @{$two_seven_five}, $depth; }
# 		elsif ($depth >= 30) { push @{$two_two_five},   $depth; }
# 		elsif ($depth >= 20) { push @{$one_seven_five}, $depth; }
# 		else                 { push @{$one_two_five},   $depth; }
# 	}
# }
# 
# print "2.75\": [".@{$two_seven_five}."]\n";
# print "2.25\": [".@{$two_two_five}."]\n";
# print "1.75\": [".@{$one_seven_five}."]\n";
# print "1.25\": [".@{$one_two_five}."]\n";
# print "Total: [".(@{$two_seven_five} + @{$two_two_five} + @{$one_seven_five} + @{$one_two_five})."]\n";

# my $anvil = Anvil::Tools->new({debug => 3});
# $anvil->Log->secure({set => 1});
# $anvil->Log->level({set => 2});

#print "Connecting to the database(s);\b";
#$anvil->Database->connect({debug => 3});
#$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, secure => 0, key => "log_0132"});
#print "DB Connections: [".$anvil->data->{sys}{database}{connections}."]\n";
#$anvil->Striker->get_ups_data({debug => 2});

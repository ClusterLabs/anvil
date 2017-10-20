#!/usr/bin/perl
#
use strict;
use warnings;
use Anvil::Tools;

my $anvil = Anvil::Tools->new();
$anvil->Log->level({set => 2});

# This is used to initialize the database
my $connections = $anvil->Database->connect();
print "Connections: [$connections]\n";


exit(0);

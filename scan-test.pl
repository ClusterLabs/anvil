#!/usr/bin/perl

use strict;
use warnings;
use Anvil::Tools;

my $anvil = Anvil::Tools->new();

print "Scanning... this may take 5+ minutes.\n\n";

my $results = $anvil->NetworkScan->scan({subnet => "10.20"});

print "IP,MAC,OEM\n";

foreach my $result (@{$results}) {
  print "$result->{ip},$result->{mac},$result->{oem}\n";
}

print "Saving Scan Results to the Database.\n";

$anvil->NetworkScan->save_scan_to_db({results => $results});

print "Scan Completed.\n";


exit(0);

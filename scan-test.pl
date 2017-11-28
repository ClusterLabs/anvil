#!/usr/bin/perl

use strict;
use warnings;
use Anvil::Tools;

my $anvil = Anvil::Tools->new();

print "Scanning devices...\n\n";

$anvil->Get->switches();

my $subnet = defined $an->data->{switches}{subnet} ? $an->data->{switches}{subnet} : "10.20";
$anvil->NetworkScan->scan({subnet => $subnet});

print "IP,MAC,OEM\n";

foreach my $this_ip (sort {$a cmp $b} keys %{$anvil->data->{scan}{ip}})
{
  my $mac = $anvil->data->{scan}{ip}{$this_ip}{mac};
  my $oem = $anvil->data->{scan}{ip}{$this_ip}{oem};
  print "$this_ip,$mac,$oem\n";
}

#print "Saving Scan Results to the Database.\n";

#$anvil->NetworkScan->save_scan_to_db();

print "Scan Completed.\n";


exit(0);

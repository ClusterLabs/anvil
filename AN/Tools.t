#!/usr/bin/perl
 
use strict;
use warnings;
use POSIX;

# Be nice and set a version number.
our $VERSION="3.0.0";
 
# Call in the test module, telling it how many tests to expect to run.
use Test::More tests => 2;
 
# Load my module via 'use_ok' test.
BEGIN
{
	print "Will now test AN::Tools on $^O.\n";
	use_ok('AN::Tools', 3.0.0);
}

my $an = AN::Tools->new();
like($an, qr/^AN::Tools=HASH\(0x\w+\)$/, "AN::Tools object appears valid.");


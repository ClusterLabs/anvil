#!/usr/bin/perl
 
use strict;
use warnings;
use POSIX;
use Data::Dumper;
use utf8;

# Be nice and set a version number.
our $VERSION="3.0.0";
 
# Call in the test module, telling it how many tests to expect to run.
use Test::More tests => 28;

# Load my module via 'use_ok' test.
BEGIN
{
	print "Beginning tests of the AN::Tools suite of modules.\n";
	use_ok('AN::Tools', 3.0.0);
}

### Core tests
my $an = AN::Tools->new();
like($an, qr/^AN::Tools=HASH\(0x\w+\)$/, "Verifying that AN::Tools object is valid.");
like($an->data, qr/^HASH\(0x\w+\)$/, "Verifying that '\$an->data' is a hash reference.");
is($an->environment, "cli", "Verifying that \$an->environment initially reports 'cli'.");
$an->environment('html');
is($an->environment, "html", "Verifying that \$an->environment was properly set to 'html'.");
$an->environment('cli');
is($an->environment, "cli", "Verifying that \$an->environment was properly reset back to 'cli'.");

# Test handles to child modules.
like($an->Alert, qr/^AN::Tools::Alert=HASH\(0x\w+\)$/, "Verifying that '\$an->Alert' is a handle to AN::Tools::Alert.");
like($an->Storage, qr/^AN::Tools::Storage=HASH\(0x\w+\)$/, "Verifying that '\$an->Alert' is a handle to AN::Tools::Storage.");
like($an->Words, qr/^AN::Tools::Words=HASH\(0x\w+\)$/, "Verifying that '\$an->Alert' is a handle to AN::Tools::Words.");

### AN::Tools::Storage methods
# Search directory tests
my $array1   = $an->Storage->search_directories;
my $a1_count = @{$array1};
cmp_ok($a1_count, '>', 0, "Verifying that \$an->Storage->search_directories has at least one entry. Found: [$a1_count] directories.");
$an->Storage->search_directories({directories => "/root,/usr/bin,/some/fake/directory"});
my $array2   = $an->Storage->search_directories;
my $a2_count = @{$array2};
cmp_ok($a2_count, '==', 2, "Verifying that \$an->Storage->search_directories now has 2 entries from a passed in CSV, testing that the list changed and a fake directory was dropped.");

$an->Storage->search_directories({directories => ["/usr/bin", "/tmp", "/home"] });
my $array3   = $an->Storage->search_directories;
my $a3_count = @{$array3};
cmp_ok($a3_count, '==', 3, "Verifying that \$an->Storage->search_directories now has 3 entries from a passed in array reference, verifying that the list changed again.");

$an->Storage->search_directories({directories => "invalid" });
my $array4   = $an->Storage->search_directories;
my $a4_count = @{$array4};
cmp_ok($a4_count, '==', $a1_count, "Verifying that \$an->Storage->search_directories has the original number of directories: [$a4_count] after being called with an invalid 'directories' parameter, showing that it reset properly.");

my $test_path = $an->Storage->find({ file => "AN/Tools.t" });
is($test_path, "/usr/share/perl5/AN/Tools.t", "Verifying that \$an->Storage->find successfully found 'AN/Tools.t'.");
my $bad_path  = $an->Storage->find({ file => "AN/wa.t" });
is($bad_path, "#!not_found!#", "Verifying that \$an->Storage->find properly returned '#!not_found!#' for a non-existed file.");

# Config file read tests.
$an->data->{foo}{bar}{a} = "test";
is($an->Storage->read_config({ file => "AN/test.conf" }), 0, "Verifying that '\$an->Storage->read_config' successfully found 'AN/test.conf'.");
is($an->Storage->read_config({ file => "" }), 1, "Verifying that '\$an->Storage->read_config' returns '1' when called without a 'file' parameter being set.");
is($an->Storage->read_config({ file => "AN/moo.conf" }), 2, "Verifying that '\$an->Storage->read_config' returns '2' when the non-existent 'AN/moo.conf' is passed.");
cmp_ok($an->data->{foo}{bar}{a}, 'eq', 'I am "a"', "Verifying that 'AN/test.conf's 'foo::bar::a' overwrote an earlier set value.");
cmp_ok($an->data->{foo}{bar}{b}, 'eq', 'I am "b", split with tabs and having trailing spaces.', "Verifying that 'AN/test.conf's 'foo::bar::b' has whitespaces removed as expected.");
cmp_ok($an->data->{foo}{baz}{1}, 'eq', 'This is \'1\' with no spaces', "Verifying that 'AN/test.conf's 'foo::baz::1' parsed without spaces around '='.");
cmp_ok($an->data->{foo}{baz}{2}, 'eq', 'I had a $dollar = sign and split with tabs.', "Verifying that 'AN/test.conf's 'foo::baz::2' had no trouble with a '$' and '=' characters in the string.");

### AN::Tools::Words methods
# Make sure we can read words files
is($an->Words->read({file =>$an->data->{path}{words}{'an-tools.xml'}}), 0, "Verifying that '\$an->Words->read' properly returned '0' when asked to read the AN::Tools's words file.");
is($an->Words->read({file => ''}), 1, "Verifying that '\$an->Words->read' properly returned '1' when asked to read a works file without a file being passed.");
is($an->Words->read({file => '/tmp/dummy.xml'}), 2, "Verifying that '\$an->Words->read' properly returned '2' when asked to read a non-existent file.");
### NOTE: At this time, we don't test for unreadable files (rc = 3) or general read faults as set by XML::Simple (rc = 4).

# Make sure we can read strings.
is($an->Words->key({key => 't_0001'}), "Test replace: [#!variable!test!#].", "Verifying that '\$an->Words->key' returned the Canadian English 't_0001' string.");
is($an->Words->key({key => 't_0001', language => 'jp'}), "テスト いれかえる: [#!variable!test!#]。", "Verifying that '\$an->Words->read' returned the Japanese 't_0001' string.");
is($an->Words->key({key => 't_0003', language => 'jp'}), "#!not_found!#", "Verifying that '\$an->Words->read' returned '#!not_found!#' for the missing 't_0003' key.");


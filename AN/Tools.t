#!/usr/bin/perl
 
use strict;
use warnings;
use POSIX;
use Data::Dumper;
use utf8;

# Be nice and set a version number.
our $VERSION   = "3.0.0";
our $THIS_FILE = "Tools.t";
 
# Call in the test module, telling it how many tests to expect to run.
use Test::More tests => 62;

# Load my module via 'use_ok' test.
BEGIN
{
	print "Beginning tests of the AN::Tools suite of modules.\n";
	use_ok('AN::Tools', 3.0.0);
}

### Core tests
my $an = AN::Tools->new();
like($an, qr/^AN::Tools=HASH\(0x\w+\)$/, "Verifying that AN::Tools object is valid.");
like($an->data, qr/^HASH\(0x\w+\)$/, "Verifying that 'data' is a hash reference.");
is($an->environment, "cli", "Verifying that environment initially reports 'cli'.");
$an->environment('html');
is($an->environment, "html", "Verifying that environment was properly set to 'html'.");
$an->environment('cli');
is($an->environment, "cli", "Verifying that environment was properly reset back to 'cli'.");

# Test handles to child modules.
like($an->Alert, qr/^AN::Tools::Alert=HASH\(0x\w+\)$/, "Verifying that 'Alert' is a handle to AN::Tools::Alert.");
like($an->Convert, qr/^AN::Tools::Convert=HASH\(0x\w+\)$/, "Verifying that 'Convert' is a handle to AN::Tools::Convert.");
like($an->Database, qr/^AN::Tools::Database=HASH\(0x\w+\)$/, "Verifying that 'Database' is a handle to AN::Tools::Database.");
like($an->Get, qr/^AN::Tools::Get=HASH\(0x\w+\)$/, "Verifying that 'Get' is a handle to AN::Tools::Get.");
like($an->Log, qr/^AN::Tools::Log=HASH\(0x\w+\)$/, "Verifying that 'Log' is a handle to AN::Tools::Log.");
like($an->Storage, qr/^AN::Tools::Storage=HASH\(0x\w+\)$/, "Verifying that 'Storage' is a handle to AN::Tools::Storage.");
like($an->System, qr/^AN::Tools::System=HASH\(0x\w+\)$/, "Verifying that 'System' is a handle to AN::Tools::System.");
like($an->Template, qr/^AN::Tools::Template=HASH\(0x\w+\)$/, "Verifying that 'Template' is a handle to AN::Tools::Template.");
like($an->Validate, qr/^AN::Tools::Validate=HASH\(0x\w+\)$/, "Verifying that 'Validate' is a handle to AN::Tools::Validate.");
like($an->Words, qr/^AN::Tools::Words=HASH\(0x\w+\)$/, "Verifying that 'Words' is a handle to AN::Tools::Words.");

### Special
# We log a note telling the user to ignore log entries caused by this test suite. We'll then read it back and
# make sure it logged properly
$an->Log->entry({level => 0, priority => "alert", key => "log_0048"});
my $message  = $an->Words->string({key => "log_0048"});
my $last_log = $an->System->call({shell_call => $an->data->{path}{exe}{journalctl}." -t an-tools --lines 1 --full --output cat --no-pager"});
is($last_log, $message, "Verified that we could write a log entry to journalctl by warning the user of incoming warnings and errors.");

### AN::Tools::Alert tests
# <none yet>

### AN::Tools::Convert tests
# cidr tests
is($an->Convert->cidr({cidr => "fake"}), "", "Verifying that Convert->cidr properly returned an empty string for a bad 'cidr' parameter.");
is($an->Convert->cidr({cidr => "0"}), "0.0.0.0", "Verifying that Convert->cidr properly returned '0.0.0.0' when given a 'cidr' parameter of '0'.");
is($an->Convert->cidr({cidr => "1"}), "128.0.0.0", "Verifying that Convert->cidr properly returned '128.0.0.0' when given a 'cidr' parameter of '1'.");
is($an->Convert->cidr({cidr => "2"}), "192.0.0.0", "Verifying that Convert->cidr properly returned '192.0.0.0' when given a 'cidr' parameter of '2'.");
is($an->Convert->cidr({cidr => "3"}), "224.0.0.0", "Verifying that Convert->cidr properly returned '224.0.0.0' when given a 'cidr' parameter of '3'.");
is($an->Convert->cidr({cidr => "4"}), "240.0.0.0", "Verifying that Convert->cidr properly returned '240.0.0.0' when given a 'cidr' parameter of '4'.");
is($an->Convert->cidr({cidr => "5"}), "248.0.0.0", "Verifying that Convert->cidr properly returned '248.0.0.0' when given a 'cidr' parameter of '5'.");
is($an->Convert->cidr({cidr => "6"}), "252.0.0.0", "Verifying that Convert->cidr properly returned '252.0.0.0' when given a 'cidr' parameter of '6'.");
is($an->Convert->cidr({cidr => "7"}), "254.0.0.0", "Verifying that Convert->cidr properly returned '254.0.0.0' when given a 'cidr' parameter of '7'.");
is($an->Convert->cidr({cidr => "8"}), "255.0.0.0", "Verifying that Convert->cidr properly returned '255.0.0.0' when given a 'cidr' parameter of '8'.");
is($an->Convert->cidr({cidr => "9"}), "255.128.0.0", "Verifying that Convert->cidr properly returned '255.128.0.0' when given a 'cidr' parameter of '9'.");
is($an->Convert->cidr({cidr => "10"}), "255.192.0.0", "Verifying that Convert->cidr properly returned '255.192.0.0' when given a 'cidr' parameter of '10'.");
is($an->Convert->cidr({cidr => "11"}), "255.224.0.0", "Verifying that Convert->cidr properly returned '255.224.0.0' when given a 'cidr' parameter of '11'.");
is($an->Convert->cidr({cidr => "12"}), "255.240.0.0", "Verifying that Convert->cidr properly returned '255.240.0.0' when given a 'cidr' parameter of '12'.");
is($an->Convert->cidr({cidr => "13"}), "255.248.0.0", "Verifying that Convert->cidr properly returned '255.248.0.0' when given a 'cidr' parameter of '13'.");
is($an->Convert->cidr({cidr => "14"}), "255.252.0.0", "Verifying that Convert->cidr properly returned '255.252.0.0' when given a 'cidr' parameter of '14'.");
is($an->Convert->cidr({cidr => "15"}), "255.254.0.0", "Verifying that Convert->cidr properly returned '255.254.0.0' when given a 'cidr' parameter of '15'.");
is($an->Convert->cidr({cidr => "16"}), "255.255.0.0", "Verifying that Convert->cidr properly returned '255.255.0.0' when given a 'cidr' parameter of '16'.");
is($an->Convert->cidr({cidr => "17"}), "255.255.128.0", "Verifying that Convert->cidr properly returned '255.255.128.0' when given a 'cidr' parameter of '17'.");
is($an->Convert->cidr({cidr => "18"}), "255.255.192.0", "Verifying that Convert->cidr properly returned '255.255.192.0' when given a 'cidr' parameter of '18'.");
is($an->Convert->cidr({cidr => "19"}), "255.255.224.0", "Verifying that Convert->cidr properly returned '255.255.224.0' when given a 'cidr' parameter of '19'.");
is($an->Convert->cidr({cidr => "20"}), "255.255.240.0", "Verifying that Convert->cidr properly returned '255.255.240.0' when given a 'cidr' parameter of '20'.");
is($an->Convert->cidr({cidr => "21"}), "255.255.248.0", "Verifying that Convert->cidr properly returned '255.255.248.0' when given a 'cidr' parameter of '21'.");
is($an->Convert->cidr({cidr => "22"}), "255.255.252.0", "Verifying that Convert->cidr properly returned '255.255.252.0' when given a 'cidr' parameter of '22'.");
is($an->Convert->cidr({cidr => "23"}), "255.255.254.0", "Verifying that Convert->cidr properly returned '255.255.254.0' when given a 'cidr' parameter of '23'.");
is($an->Convert->cidr({cidr => "24"}), "255.255.255.0", "Verifying that Convert->cidr properly returned '255.255.255.0' when given a 'cidr' parameter of '24'.");
is($an->Convert->cidr({cidr => "25"}), "255.255.255.128", "Verifying that Convert->cidr properly returned '255.255.255.128' when given a 'cidr' parameter of '25'.");
is($an->Convert->cidr({cidr => "26"}), "255.255.255.192", "Verifying that Convert->cidr properly returned '255.255.255.192' when given a 'cidr' parameter of '26'.");
is($an->Convert->cidr({cidr => "27"}), "255.255.255.224", "Verifying that Convert->cidr properly returned '255.255.255.224' when given a 'cidr' parameter of '27'.");
is($an->Convert->cidr({cidr => "28"}), "255.255.255.240", "Verifying that Convert->cidr properly returned '255.255.255.240' when given a 'cidr' parameter of '28'.");
is($an->Convert->cidr({cidr => "29"}), "255.255.255.248", "Verifying that Convert->cidr properly returned '255.255.255.248' when given a 'cidr' parameter of '29'.");
is($an->Convert->cidr({cidr => "30"}), "255.255.255.252", "Verifying that Convert->cidr properly returned '255.255.255.252' when given a 'cidr' parameter of '30'.");
is($an->Convert->cidr({cidr => "31"}), "255.255.255.254", "Verifying that Convert->cidr properly returned '255.255.255.254' when given a 'cidr' parameter of '31'.");
is($an->Convert->cidr({cidr => "32"}), "255.255.255.255", "Verifying that Convert->cidr properly returned '255.255.255.255' when given a 'cidr' parameter of '32'.");
is($an->Convert->cidr({subnet => "fake"}), "", "Verifying that Convert->cidr properly returned an empty string for a bad 'subnet' parameter.");
is($an->Convert->cidr({subnet => "0.0.0.0"}), "0", "Verifying that Convert->cidr properly returned '0' when given a 'subnet' parameter of '0.0.0.0'.");
is($an->Convert->cidr({subnet => "128.0.0.0"}), "1", "Verifying that Convert->cidr properly returned '1' when given a 'subnet' parameter of '128.0.0.0'.");
is($an->Convert->cidr({subnet => "192.0.0.0"}), "2", "Verifying that Convert->cidr properly returned '2' when given a 'subnet' parameter of '192.0.0.0'.");
is($an->Convert->cidr({subnet => "224.0.0.0"}), "3", "Verifying that Convert->cidr properly returned '3' when given a 'subnet' parameter of '224.0.0.0'.");
is($an->Convert->cidr({subnet => "240.0.0.0"}), "4", "Verifying that Convert->cidr properly returned '4' when given a 'subnet' parameter of '240.0.0.0'.");
is($an->Convert->cidr({subnet => "248.0.0.0"}), "5", "Verifying that Convert->cidr properly returned '5' when given a 'subnet' parameter of '248.0.0.0'.");
is($an->Convert->cidr({subnet => "252.0.0.0"}), "6", "Verifying that Convert->cidr properly returned '6' when given a 'subnet' parameter of '252.0.0.0'.");
is($an->Convert->cidr({subnet => "254.0.0.0"}), "7", "Verifying that Convert->cidr properly returned '7' when given a 'subnet' parameter of '254.0.0.0'.");
is($an->Convert->cidr({subnet => "255.0.0.0"}), "8", "Verifying that Convert->cidr properly returned '8' when given a 'subnet' parameter of '255.0.0.0'.");
is($an->Convert->cidr({subnet => "255.128.0.0"}), "9", "Verifying that Convert->cidr properly returned '9' when given a 'subnet' parameter of '255.128.0.0'.");
is($an->Convert->cidr({subnet => "255.192.0.0"}), "10", "Verifying that Convert->cidr properly returned '10' when given a 'subnet' parameter of '255.192.0.0'.");
is($an->Convert->cidr({subnet => "255.224.0.0"}), "11", "Verifying that Convert->cidr properly returned '11' when given a 'subnet' parameter of '255.224.0.0'.");
is($an->Convert->cidr({subnet => "255.240.0.0"}), "12", "Verifying that Convert->cidr properly returned '12' when given a 'subnet' parameter of '255.240.0.0'.");
is($an->Convert->cidr({subnet => "255.248.0.0"}), "13", "Verifying that Convert->cidr properly returned '13' when given a 'subnet' parameter of '255.248.0.0'.");
is($an->Convert->cidr({subnet => "255.252.0.0"}), "14", "Verifying that Convert->cidr properly returned '14' when given a 'subnet' parameter of '255.252.0.0'.");
is($an->Convert->cidr({subnet => "255.254.0.0"}), "15", "Verifying that Convert->cidr properly returned '15' when given a 'subnet' parameter of '255.254.0.0'.");
is($an->Convert->cidr({subnet => "255.255.0.0"}), "16", "Verifying that Convert->cidr properly returned '16' when given a 'subnet' parameter of '255.255.0.0'.");
is($an->Convert->cidr({subnet => "255.255.128.0"}), "17", "Verifying that Convert->cidr properly returned '17' when given a 'subnet' parameter of '255.255.128.0'.");
is($an->Convert->cidr({subnet => "255.255.192.0"}), "18", "Verifying that Convert->cidr properly returned '18' when given a 'subnet' parameter of '255.255.192.0'.");
is($an->Convert->cidr({subnet => "255.255.224.0"}), "19", "Verifying that Convert->cidr properly returned '19' when given a 'subnet' parameter of '255.255.224.0'.");
is($an->Convert->cidr({subnet => "255.255.240.0"}), "20", "Verifying that Convert->cidr properly returned '20' when given a 'subnet' parameter of '255.255.240.0'.");
is($an->Convert->cidr({subnet => "255.255.248.0"}), "21", "Verifying that Convert->cidr properly returned '21' when given a 'subnet' parameter of '255.255.248.0'.");
is($an->Convert->cidr({subnet => "255.255.252.0"}), "22", "Verifying that Convert->cidr properly returned '22' when given a 'subnet' parameter of '255.255.252.0'.");
is($an->Convert->cidr({subnet => "255.255.254.0"}), "23", "Verifying that Convert->cidr properly returned '23' when given a 'subnet' parameter of '255.255.254.0'.");
is($an->Convert->cidr({subnet => "255.255.255.0"}), "24", "Verifying that Convert->cidr properly returned '24' when given a 'subnet' parameter of '255.255.255.0'.");
is($an->Convert->cidr({subnet => "255.255.255.128"}), "25", "Verifying that Convert->cidr properly returned '25' when given a 'subnet' parameter of '255.255.255.128'.");
is($an->Convert->cidr({subnet => "255.255.255.192"}), "26", "Verifying that Convert->cidr properly returned '26' when given a 'subnet' parameter of '255.255.255.192'.");
is($an->Convert->cidr({subnet => "255.255.255.224"}), "27", "Verifying that Convert->cidr properly returned '27' when given a 'subnet' parameter of '255.255.255.224'.");
is($an->Convert->cidr({subnet => "255.255.255.240"}), "28", "Verifying that Convert->cidr properly returned '28' when given a 'subnet' parameter of '255.255.255.240'.");
is($an->Convert->cidr({subnet => "255.255.255.248"}), "29", "Verifying that Convert->cidr properly returned '29' when given a 'subnet' parameter of '255.255.255.248'.");
is($an->Convert->cidr({subnet => "255.255.255.252"}), "30", "Verifying that Convert->cidr properly returned '30' when given a 'subnet' parameter of '255.255.255.252'.");
is($an->Convert->cidr({subnet => "255.255.255.254"}), "31", "Verifying that Convert->cidr properly returned '31' when given a 'subnet' parameter of '255.255.255.254'.");
is($an->Convert->cidr({subnet => "255.255.255.255"}), "32", "Verifying that Convert->cidr properly returned '32' when given a 'subnet' parameter of '255.255.255.255'.");

### AN::Tools::Database tests
# <none yet>

### AN::Tools::Get tests
# date_and_time
like($an->Get->date_and_time(), qr/^\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d$/, "Verifying the current date and time is returned.");
like($an->Get->date_and_time({date_only => 1}), qr/^\d\d\d\d\/\d\d\/\d\d$/, "Verifying the current date alone is returned.");
like($an->Get->date_and_time({time_only => 1}), qr/^\d\d:\d\d:\d\d$/, "Verifying the current time alone is returned.");
like($an->Get->date_and_time({file_name => 1}), qr/^\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d$/, "Verifying the current date and time is returned in a file-friendly format.");
like($an->Get->date_and_time({file_name => 1, date_only => 1}), qr/^\d\d\d\d-\d\d-\d\d$/, "Verifying the current date only is returned in a file-friendly format.");
like($an->Get->date_and_time({file_name => 1, time_only => 1}), qr/^\d\d-\d\d-\d\d$/, "Verifying the current time only is returned in a file-friendly format.");
# We can't be too specific because the user's TZ will shift the results
like($an->Get->date_and_time({use_time => 1234567890}), qr/2009\/02\/1[34] \d\d:\d\d:\d\d$/, "Verified that a specific unixtime returned the expected date.");
like($an->Get->date_and_time({use_time => 1234567890, offset => 31536000}), qr/2010\/02\/1[34] \d\d:\d\d:\d\d$/, "Verified that a specific unixtime with a one year in the future offset returned the expected date.");
like($an->Get->date_and_time({use_time => 1234567890, offset => -31536000}), qr/2008\/02\/1[34] \d\d:\d\d:\d\d$/, "Verified that a specific unixtime with a one year in the past offset returned the expected date.");
# host_uuid
like($an->Get->host_uuid, qr/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/, "Verifying ability to read host uuid.");
### TODO: How to test Get->switches?

### AN::Tools::Log tests
# language
is($an->Log->language, "en_CA", "Verifying the default log language is 'en_CA'.");
$an->Log->language({set => "jp"});
is($an->Log->language, "jp", "Verifying the log language was changed to 'jp'.");
$an->Log->language({set => "en_CA"});
is($an->Log->language, "en_CA", "Verifying the log language is back to 'en_CA'.");

# log_level
is($an->Log->level, "1", "Verifying the default log level is '1'.");
$an->Log->level({set => 0});
is($an->Log->level, "0", "Verifying the log level changed to '0'.");
$an->Log->level({set => 1});
is($an->Log->level, "1", "Verifying the log level changed to '1'.");
$an->Log->level({set => 2});
is($an->Log->level, "2", "Verifying the log level changed to '2'.");
$an->Log->level({set => 3});
is($an->Log->level, "3", "Verifying the log level changed to '3'.");
$an->Log->level({set => 4});
is($an->Log->level, "4", "Verifying the log level changed to '4'.");
$an->Log->level({set => "foo"});
is($an->Log->level, "4", "Verifying the log level stayed at '4' with bad input.");
$an->Log->level({set => 1});
is($an->Log->level, "1", "Verifying the log level changed back to '1'.");
# We're simulating switches to test Log->_adjust_log_level
$an->data->{switches}{V} = "#!set!#";
$an->data->{switches}{v} = "";
$an->data->{switches}{vv} = "";
$an->data->{switches}{vvv} = "";
$an->data->{switches}{vvvv} = "";
$an->Log->_adjust_log_level;
is($an->Log->level, "0", "Verifying the log level was set to '0' with Log->_adjust_log_leve() with 'V' switch set.");
$an->data->{switches}{V} = "";
$an->data->{switches}{v} = "#!set!#";
$an->Log->_adjust_log_level;
is($an->Log->level, "1", "Verifying the log level was set to '1' with Log->_adjust_log_leve() with 'v' switch set.");
$an->data->{switches}{v} = "";
$an->data->{switches}{vv} = "#!set!#";
$an->Log->_adjust_log_level;
is($an->Log->level, "2", "Verifying the log level was set to '2' with Log->_adjust_log_leve() with 'vv' switch set.");
$an->data->{switches}{vv} = "";
$an->data->{switches}{vvv} = "#!set!#";
$an->Log->_adjust_log_level;
is($an->Log->level, "3", "Verifying the log level was set to '3' with Log->_adjust_log_leve() with 'vvv' switch set.");
$an->data->{switches}{vvv} = "";
$an->data->{switches}{vvvv} = "#!set!#";
$an->Log->_adjust_log_level;
is($an->Log->level, "4", "Verifying the log level was set to '4' with Log->_adjust_log_leve() with 'vvvv' switch set.");
$an->data->{switches}{vvvv} = "";
$an->data->{switches}{v} = "#!set!#";
$an->Log->_adjust_log_level;
is($an->Log->level, "1", "Verifying the log level was set back to '1' with Log->_adjust_log_leve() with 'v' switch set.");
# Test Log->secure
is($an->Log->secure, "0", "Verifying that logging secure messages is disabled by default.");
$an->Log->secure({set => "foo"});
is($an->Log->secure, "0", "Verifying that logging secure messages stayed disabled on bad input.");
$an->Log->secure({set => 1});
is($an->Log->secure, "1", "Verifying that logging secure messages was enabled.");
$an->Log->secure({set => 0});
is($an->Log->secure, "0", "Verifying that logging secure messages was disabled again.");

die;

### AN::Tools::Storage tests
# 

die;

### AN::Tools::System tests
# 

die;

### AN::Tools::Template tests
# 

die;

### AN::Tools::Validate tests
# 

die;

### AN::Tools::Words tests
# 

die;



### AN::Tools::Storage methods
# Search directory tests
my $array1   = $an->Storage->search_directories;
my $a1_count = @{$array1};
cmp_ok($a1_count, '>', 0, "Verifying that Storage->search_directories has at least one entry. Found: [$a1_count] directories.");

$an->Storage->search_directories({directories => "/root,/usr/bin,/some/fake/directory"});
my $array2   = $an->Storage->search_directories;
my $a2_count = @{$array2};
cmp_ok($a2_count, '==', 2, "Verifying that Storage->search_directories now has 2 entries from a passed in CSV, testing that the list changed and a fake directory was dropped.");

$an->Storage->search_directories({directories => ["/usr/bin", "/tmp", "/home"] });
my $array3   = $an->Storage->search_directories;
my $a3_count = @{$array3};
cmp_ok($a3_count, '==', 3, "Verifying that Storage->search_directories now has 3 entries from a passed in array reference, verifying that the list changed again.");

$an->Storage->search_directories({directories => "invalid" });
my $array4   = $an->Storage->search_directories;
my $a4_count = @{$array4};
cmp_ok($a4_count, '==', $a1_count, "Verifying that Storage->search_directories has the original number of directories: [$a4_count] after being called with an invalid 'directories' parameter, showing that it reset properly.");

my $test_path = $an->Storage->find({ file => "AN/Tools.t" });
is($test_path, "/usr/share/perl5/AN/Tools.t", "Verifying that Storage->find successfully found 'AN/Tools.t'.");
my $bad_path  = $an->Storage->find({ file => "AN/wa.t" });
is($bad_path, "#!not_found!#", "Verifying that Storage->find properly returned '#!not_found!#' for a non-existed file.");

# Config file read tests.
$an->data->{foo}{bar}{a} = "test";
is($an->Storage->read_config({ file => "AN/test.conf" }), 0, "Verifying that 'Storage->read_config' successfully found 'AN/test.conf'.");
is($an->Storage->read_config({ file => "" }), 1, "Verifying that 'Storage->read_config' returns '1' when called without a 'file' parameter being set.");
is($an->Storage->read_config({ file => "AN/moo.conf" }), 2, "Verifying that 'Storage->read_config' returns '2' when the non-existent 'AN/moo.conf' is passed.");
cmp_ok($an->data->{foo}{bar}{a}, 'eq', 'I am "a"', "Verifying that 'AN/test.conf's 'foo::bar::a' overwrote an earlier set value.");
cmp_ok($an->data->{foo}{bar}{b}, 'eq', 'I am "b", split with tabs and having trailing spaces.', "Verifying that 'AN/test.conf's 'foo::bar::b' has whitespaces removed as expected.");
cmp_ok($an->data->{foo}{baz}{1}, 'eq', 'This is \'1\' with no spaces', "Verifying that 'AN/test.conf's 'foo::baz::1' parsed without spaces around '='.");
cmp_ok($an->data->{foo}{baz}{2}, 'eq', 'I had a $dollar = sign and split with tabs.', "Verifying that 'AN/test.conf's 'foo::baz::2' had no trouble with a '\$' and '=' characters in the string.");

### AN::Tools::Words methods
# Make sure we can read words files
is($an->Words->read({file => $an->data->{path}{words}{'an-tools.xml'}}), 0, "Verifying that 'Words->read' properly returned '0' when asked to read the AN::Tools's words file.");
is($an->Words->read({file => ''}), 1, "Verifying that 'Words->read' properly returned '1' when asked to read a works file without a file being passed.");
is($an->Words->read({file => '/tmp/dummy.xml'}), 2, "Verifying that 'Words->read' properly returned '2' when asked to read a non-existent file.");
### NOTE: At this time, we don't test for unreadable files (rc = 3) or general read faults as set by XML::Simple (rc = 4).

# Make sure we can read raw strings.
is($an->Words->key({key => 't_0001'}), "Test replace: [#!variable!test!#].", "Verifying that 'Words->key' returned the Canadian English 't_0001' string.");
is($an->Words->key({key => 't_0001', language => 'jp'}), "テスト いれかえる: [#!variable!test!#]。", "Verifying that 'Words->read' returned the Japanese 't_0001' string.");
is($an->Words->key({key => 't_0003', language => 'jp'}), "#!not_found!#", "Verifying that 'Words->read' returned '#!not_found!#' for the missing 't_0003' key.");

# Make sure we can read processed strings.
is($an->Words->string({
	key       => 't_0005',
	variables => {
		test   => "result!",
		first  => "1st",
		second => "2nd",
 	},
}), "
This is a multi-line test string with various items to insert.

It also has some #!invalid!# replacement #!keys!# to test the escaping and restoring.

Here is the default output language: [en_CA]
Here we will inject 't_0000': [Test replace: [result!].] 
Here we will inject 't_0002' with its embedded variables: [Test Out of order: [2nd] replace: [1st].]
Here we will inject 't_0006', which injects 't_0001' which has a variable: [This string embeds 't_0001': [Test replace: [result!].]].
", "Verifying string processing in the default (Canadian English) language.");
is($an->Words->string({
	language  => 'jp',
	key       => 't_0005',
	variables => {
		test   => "result!",
		first  => "1st",
		second => "2nd",
 	},
}), "
これは、挿入するさまざまな項目を含む複数行のテスト文字列です。

#!無効#!な置換!#キー!#を使ってエスケープとリストアをテストすることもできます。

デフォルトの出力言語は次のとおりです：「en_CA」
ここで、「t_0000」を挿入します：[テスト いれかえる: [result!]。]
ここでは、 「t_0002」に埋め込み変数を挿入します：「テスト、 整理: [2nd]/[1st]。」
ここでは変数 「この文字列には「t_0001」が埋め込まれています：「テスト いれかえる: [result!]。」」を持つ 「t_0001」を注入する 「t_0006」を注入します。
", "Verifying string processing in Japanese.");

### Get tests.

### Logging
# TODO: How to check logs in journalctl?

### Template
my $active_skin = $an->Template->skin;

### Validate
is($an->Validate->is_uuid({uuid => $an->Get->host_uuid}), "1", "Verifying that Validate->is_uuid() validates the host UUID.");
is($an->Validate->is_uuid({uuid => uc($an->Get->host_uuid)}), "0", "Verifying that Validate->is_uuid() fails to validates the host UUID in upper case.");
is($an->Validate->is_uuid({uuid => "cfdab37c-5b1a-433d-9285-978e7caa134"}), "0", "Verifying that Validate->is_uuid() fails to validates a UUID missing a letter.");
is($an->Validate->is_uuid({uuid => "cfdab37c5b1a433d9285-978e7caa1342"}), "0", "Verifying that Validate->is_uuid() fails to validate a UUID without hyphens.");

# Tell the user that we're done making noise in their logs
$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0049"});

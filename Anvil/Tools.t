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
use Test::More tests => 200;

# Load my module via 'use_ok' test.
BEGIN
{
	print "Beginning tests of the Anvil::Tools suite of modules.\n";
	use_ok('Anvil::Tools', 3.0.0);
}

### Core tests
my $anvil = Anvil::Tools->new();
like($anvil, qr/^Anvil::Tools=HASH\(0x\w+\)$/, "Verifying that Anvil::Tools object is valid.");
like($anvil->data, qr/^HASH\(0x\w+\)$/, "Verifying that 'data' is a hash reference.");
is($anvil->environment, "cli", "Verifying that environment initially reports 'cli'.");
$anvil->environment('html');
is($anvil->environment, "html", "Verifying that environment was properly set to 'html'.");
$anvil->environment('cli');
is($anvil->environment, "cli", "Verifying that environment was properly reset back to 'cli'.");

# Test handles to child modules.
like($anvil->Alert, qr/^Anvil::Tools::Alert=HASH\(0x\w+\)$/, "Verifying that 'Alert' is a handle to Anvil::Tools::Alert.");
like($anvil->Convert, qr/^Anvil::Tools::Convert=HASH\(0x\w+\)$/, "Verifying that 'Convert' is a handle to Anvil::Tools::Convert.");
like($anvil->Database, qr/^Anvil::Tools::Database=HASH\(0x\w+\)$/, "Verifying that 'Database' is a handle to Anvil::Tools::Database.");
like($anvil->Get, qr/^Anvil::Tools::Get=HASH\(0x\w+\)$/, "Verifying that 'Get' is a handle to Anvil::Tools::Get.");
like($anvil->Log, qr/^Anvil::Tools::Log=HASH\(0x\w+\)$/, "Verifying that 'Log' is a handle to Anvil::Tools::Log.");
like($anvil->Storage, qr/^Anvil::Tools::Storage=HASH\(0x\w+\)$/, "Verifying that 'Storage' is a handle to Anvil::Tools::Storage.");
like($anvil->System, qr/^Anvil::Tools::System=HASH\(0x\w+\)$/, "Verifying that 'System' is a handle to Anvil::Tools::System.");
like($anvil->Template, qr/^Anvil::Tools::Template=HASH\(0x\w+\)$/, "Verifying that 'Template' is a handle to Anvil::Tools::Template.");
like($anvil->Validate, qr/^Anvil::Tools::Validate=HASH\(0x\w+\)$/, "Verifying that 'Validate' is a handle to Anvil::Tools::Validate.");
like($anvil->Words, qr/^Anvil::Tools::Words=HASH\(0x\w+\)$/, "Verifying that 'Words' is a handle to Anvil::Tools::Words.");

### Special
# We log a note telling the user to ignore log entries caused by this test suite. We'll then read it back and
# make sure it logged properly
$anvil->Log->entry({level => 0, priority => "alert", key => "log_0048"});
my $message  = $anvil->Words->string({key => "log_0048"});
my ($last_log, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{journalctl}." -t anvil --lines 1 --full --output cat --no-pager"});
is($last_log, $message, "Verified that we could write a log entry to journalctl by warning the user of incoming warnings and errors.");

### Anvil::Tools::Alert tests
# <none yet>

### Anvil::Tools::Convert tests
# cidr tests
is($anvil->Convert->cidr({cidr => "fake"}), "", "Verifying that Convert->cidr properly returned an empty string for a bad 'cidr' parameter.");
is($anvil->Convert->cidr({cidr => "0"}), "0.0.0.0", "Verifying that Convert->cidr properly returned '0.0.0.0' when given a 'cidr' parameter of '0'.");
is($anvil->Convert->cidr({cidr => "1"}), "128.0.0.0", "Verifying that Convert->cidr properly returned '128.0.0.0' when given a 'cidr' parameter of '1'.");
is($anvil->Convert->cidr({cidr => "2"}), "192.0.0.0", "Verifying that Convert->cidr properly returned '192.0.0.0' when given a 'cidr' parameter of '2'.");
is($anvil->Convert->cidr({cidr => "3"}), "224.0.0.0", "Verifying that Convert->cidr properly returned '224.0.0.0' when given a 'cidr' parameter of '3'.");
is($anvil->Convert->cidr({cidr => "4"}), "240.0.0.0", "Verifying that Convert->cidr properly returned '240.0.0.0' when given a 'cidr' parameter of '4'.");
is($anvil->Convert->cidr({cidr => "5"}), "248.0.0.0", "Verifying that Convert->cidr properly returned '248.0.0.0' when given a 'cidr' parameter of '5'.");
is($anvil->Convert->cidr({cidr => "6"}), "252.0.0.0", "Verifying that Convert->cidr properly returned '252.0.0.0' when given a 'cidr' parameter of '6'.");
is($anvil->Convert->cidr({cidr => "7"}), "254.0.0.0", "Verifying that Convert->cidr properly returned '254.0.0.0' when given a 'cidr' parameter of '7'.");
is($anvil->Convert->cidr({cidr => "8"}), "255.0.0.0", "Verifying that Convert->cidr properly returned '255.0.0.0' when given a 'cidr' parameter of '8'.");
is($anvil->Convert->cidr({cidr => "9"}), "255.128.0.0", "Verifying that Convert->cidr properly returned '255.128.0.0' when given a 'cidr' parameter of '9'.");
is($anvil->Convert->cidr({cidr => "10"}), "255.192.0.0", "Verifying that Convert->cidr properly returned '255.192.0.0' when given a 'cidr' parameter of '10'.");
is($anvil->Convert->cidr({cidr => "11"}), "255.224.0.0", "Verifying that Convert->cidr properly returned '255.224.0.0' when given a 'cidr' parameter of '11'.");
is($anvil->Convert->cidr({cidr => "12"}), "255.240.0.0", "Verifying that Convert->cidr properly returned '255.240.0.0' when given a 'cidr' parameter of '12'.");
is($anvil->Convert->cidr({cidr => "13"}), "255.248.0.0", "Verifying that Convert->cidr properly returned '255.248.0.0' when given a 'cidr' parameter of '13'.");
is($anvil->Convert->cidr({cidr => "14"}), "255.252.0.0", "Verifying that Convert->cidr properly returned '255.252.0.0' when given a 'cidr' parameter of '14'.");
is($anvil->Convert->cidr({cidr => "15"}), "255.254.0.0", "Verifying that Convert->cidr properly returned '255.254.0.0' when given a 'cidr' parameter of '15'.");
is($anvil->Convert->cidr({cidr => "16"}), "255.255.0.0", "Verifying that Convert->cidr properly returned '255.255.0.0' when given a 'cidr' parameter of '16'.");
is($anvil->Convert->cidr({cidr => "17"}), "255.255.128.0", "Verifying that Convert->cidr properly returned '255.255.128.0' when given a 'cidr' parameter of '17'.");
is($anvil->Convert->cidr({cidr => "18"}), "255.255.192.0", "Verifying that Convert->cidr properly returned '255.255.192.0' when given a 'cidr' parameter of '18'.");
is($anvil->Convert->cidr({cidr => "19"}), "255.255.224.0", "Verifying that Convert->cidr properly returned '255.255.224.0' when given a 'cidr' parameter of '19'.");
is($anvil->Convert->cidr({cidr => "20"}), "255.255.240.0", "Verifying that Convert->cidr properly returned '255.255.240.0' when given a 'cidr' parameter of '20'.");
is($anvil->Convert->cidr({cidr => "21"}), "255.255.248.0", "Verifying that Convert->cidr properly returned '255.255.248.0' when given a 'cidr' parameter of '21'.");
is($anvil->Convert->cidr({cidr => "22"}), "255.255.252.0", "Verifying that Convert->cidr properly returned '255.255.252.0' when given a 'cidr' parameter of '22'.");
is($anvil->Convert->cidr({cidr => "23"}), "255.255.254.0", "Verifying that Convert->cidr properly returned '255.255.254.0' when given a 'cidr' parameter of '23'.");
is($anvil->Convert->cidr({cidr => "24"}), "255.255.255.0", "Verifying that Convert->cidr properly returned '255.255.255.0' when given a 'cidr' parameter of '24'.");
is($anvil->Convert->cidr({cidr => "25"}), "255.255.255.128", "Verifying that Convert->cidr properly returned '255.255.255.128' when given a 'cidr' parameter of '25'.");
is($anvil->Convert->cidr({cidr => "26"}), "255.255.255.192", "Verifying that Convert->cidr properly returned '255.255.255.192' when given a 'cidr' parameter of '26'.");
is($anvil->Convert->cidr({cidr => "27"}), "255.255.255.224", "Verifying that Convert->cidr properly returned '255.255.255.224' when given a 'cidr' parameter of '27'.");
is($anvil->Convert->cidr({cidr => "28"}), "255.255.255.240", "Verifying that Convert->cidr properly returned '255.255.255.240' when given a 'cidr' parameter of '28'.");
is($anvil->Convert->cidr({cidr => "29"}), "255.255.255.248", "Verifying that Convert->cidr properly returned '255.255.255.248' when given a 'cidr' parameter of '29'.");
is($anvil->Convert->cidr({cidr => "30"}), "255.255.255.252", "Verifying that Convert->cidr properly returned '255.255.255.252' when given a 'cidr' parameter of '30'.");
is($anvil->Convert->cidr({cidr => "31"}), "255.255.255.254", "Verifying that Convert->cidr properly returned '255.255.255.254' when given a 'cidr' parameter of '31'.");
is($anvil->Convert->cidr({cidr => "32"}), "255.255.255.255", "Verifying that Convert->cidr properly returned '255.255.255.255' when given a 'cidr' parameter of '32'.");
is($anvil->Convert->cidr({subnet_mask => "fake"}), "", "Verifying that Convert->cidr properly returned an empty string for a bad 'subnet' parameter.");
is($anvil->Convert->cidr({subnet_mask => "0.0.0.0"}), "0", "Verifying that Convert->cidr properly returned '0' when given a 'subnet' parameter of '0.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "128.0.0.0"}), "1", "Verifying that Convert->cidr properly returned '1' when given a 'subnet' parameter of '128.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "192.0.0.0"}), "2", "Verifying that Convert->cidr properly returned '2' when given a 'subnet' parameter of '192.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "224.0.0.0"}), "3", "Verifying that Convert->cidr properly returned '3' when given a 'subnet' parameter of '224.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "240.0.0.0"}), "4", "Verifying that Convert->cidr properly returned '4' when given a 'subnet' parameter of '240.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "248.0.0.0"}), "5", "Verifying that Convert->cidr properly returned '5' when given a 'subnet' parameter of '248.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "252.0.0.0"}), "6", "Verifying that Convert->cidr properly returned '6' when given a 'subnet' parameter of '252.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "254.0.0.0"}), "7", "Verifying that Convert->cidr properly returned '7' when given a 'subnet' parameter of '254.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.0.0.0"}), "8", "Verifying that Convert->cidr properly returned '8' when given a 'subnet' parameter of '255.0.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.128.0.0"}), "9", "Verifying that Convert->cidr properly returned '9' when given a 'subnet' parameter of '255.128.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.192.0.0"}), "10", "Verifying that Convert->cidr properly returned '10' when given a 'subnet' parameter of '255.192.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.224.0.0"}), "11", "Verifying that Convert->cidr properly returned '11' when given a 'subnet' parameter of '255.224.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.240.0.0"}), "12", "Verifying that Convert->cidr properly returned '12' when given a 'subnet' parameter of '255.240.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.248.0.0"}), "13", "Verifying that Convert->cidr properly returned '13' when given a 'subnet' parameter of '255.248.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.252.0.0"}), "14", "Verifying that Convert->cidr properly returned '14' when given a 'subnet' parameter of '255.252.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.254.0.0"}), "15", "Verifying that Convert->cidr properly returned '15' when given a 'subnet' parameter of '255.254.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.0.0"}), "16", "Verifying that Convert->cidr properly returned '16' when given a 'subnet' parameter of '255.255.0.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.128.0"}), "17", "Verifying that Convert->cidr properly returned '17' when given a 'subnet' parameter of '255.255.128.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.192.0"}), "18", "Verifying that Convert->cidr properly returned '18' when given a 'subnet' parameter of '255.255.192.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.224.0"}), "19", "Verifying that Convert->cidr properly returned '19' when given a 'subnet' parameter of '255.255.224.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.240.0"}), "20", "Verifying that Convert->cidr properly returned '20' when given a 'subnet' parameter of '255.255.240.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.248.0"}), "21", "Verifying that Convert->cidr properly returned '21' when given a 'subnet' parameter of '255.255.248.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.252.0"}), "22", "Verifying that Convert->cidr properly returned '22' when given a 'subnet' parameter of '255.255.252.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.254.0"}), "23", "Verifying that Convert->cidr properly returned '23' when given a 'subnet' parameter of '255.255.254.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.0"}), "24", "Verifying that Convert->cidr properly returned '24' when given a 'subnet' parameter of '255.255.255.0'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.128"}), "25", "Verifying that Convert->cidr properly returned '25' when given a 'subnet' parameter of '255.255.255.128'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.192"}), "26", "Verifying that Convert->cidr properly returned '26' when given a 'subnet' parameter of '255.255.255.192'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.224"}), "27", "Verifying that Convert->cidr properly returned '27' when given a 'subnet' parameter of '255.255.255.224'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.240"}), "28", "Verifying that Convert->cidr properly returned '28' when given a 'subnet' parameter of '255.255.255.240'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.248"}), "29", "Verifying that Convert->cidr properly returned '29' when given a 'subnet' parameter of '255.255.255.248'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.252"}), "30", "Verifying that Convert->cidr properly returned '30' when given a 'subnet' parameter of '255.255.255.252'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.254"}), "31", "Verifying that Convert->cidr properly returned '31' when given a 'subnet' parameter of '255.255.255.254'.");
is($anvil->Convert->cidr({subnet_mask => "255.255.255.255"}), "32", "Verifying that Convert->cidr properly returned '32' when given a 'subnet' parameter of '255.255.255.255'.");

### Anvil::Tools::Database tests
# <none yet>

### Anvil::Tools::Get tests
# date_and_time
like($anvil->Get->date_and_time(), qr/^\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d$/, "Verifying the current date and time is returned.");
like($anvil->Get->date_and_time({date_only => 1}), qr/^\d\d\d\d\/\d\d\/\d\d$/, "Verifying the current date alone is returned.");
like($anvil->Get->date_and_time({time_only => 1}), qr/^\d\d:\d\d:\d\d$/, "Verifying the current time alone is returned.");
like($anvil->Get->date_and_time({file_name => 1}), qr/^\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d$/, "Verifying the current date and time is returned in a file-friendly format.");
like($anvil->Get->date_and_time({file_name => 1, date_only => 1}), qr/^\d\d\d\d-\d\d-\d\d$/, "Verifying the current date only is returned in a file-friendly format.");
like($anvil->Get->date_and_time({file_name => 1, time_only => 1}), qr/^\d\d-\d\d-\d\d$/, "Verifying the current time only is returned in a file-friendly format.");
# We can't be too specific because the user's TZ will shift the results
like($anvil->Get->date_and_time({use_time => 1234567890}), qr/2009\/02\/1[34] \d\d:\d\d:\d\d$/, "Verified that a specific unixtime returned the expected date.");
like($anvil->Get->date_and_time({use_time => 1234567890, offset => 31536000}), qr/2010\/02\/1[34] \d\d:\d\d:\d\d$/, "Verified that a specific unixtime with a one year in the future offset returned the expected date.");
like($anvil->Get->date_and_time({use_time => 1234567890, offset => -31536000}), qr/2008\/02\/1[34] \d\d:\d\d:\d\d$/, "Verified that a specific unixtime with a one year in the past offset returned the expected date.");
# host_uuid
like($anvil->Get->host_uuid, qr/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/, "Verifying ability to read host uuid.");
### TODO: How to test Get->switches?
# uuid
like($anvil->Get->uuid, qr/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/, "Verifying ability to generate a random uuid.");

### Anvil::Tools::Log tests
# entry is tested at the start of this test suite.
# language
is($anvil->Log->language, "en_CA", "Verifying the default log language is 'en_CA'.");
$anvil->Log->language({set => "jp"});
is($anvil->Log->language, "jp", "Verifying the log language was changed to 'jp'.");
$anvil->Log->language({set => "en_CA"});
is($anvil->Log->language, "en_CA", "Verifying the log language is back to 'en_CA'.");

# log_level
is($anvil->Log->level, "1", "Verifying the default log level is '1'.");
$anvil->Log->level({set => 0});
is($anvil->Log->level, "0", "Verifying the log level changed to '0'.");
$anvil->Log->level({set => 1});
is($anvil->Log->level, "1", "Verifying the log level changed to '1'.");
$anvil->Log->level({set => 2});
is($anvil->Log->level, "2", "Verifying the log level changed to '2'.");
$anvil->Log->level({set => 3});
is($anvil->Log->level, "3", "Verifying the log level changed to '3'.");
$anvil->Log->level({set => 4});
is($anvil->Log->level, "4", "Verifying the log level changed to '4'.");
$anvil->Log->level({set => "foo"});
is($anvil->Log->level, "4", "Verifying the log level stayed at '4' with bad input.");
$anvil->Log->level({set => 1});
is($anvil->Log->level, "1", "Verifying the log level changed back to '1'.");
# secure
is($anvil->Log->secure, "0", "Verifying that logging secure messages is disabled by default.");
$anvil->Log->secure({set => "foo"});
is($anvil->Log->secure, "0", "Verifying that logging secure messages stayed disabled on bad input.");
$anvil->Log->secure({set => 1});
is($anvil->Log->secure, "1", "Verifying that logging secure messages was enabled.");
$anvil->Log->secure({set => 0});
is($anvil->Log->secure, "0", "Verifying that logging secure messages was disabled again.");
# variables
$anvil->Log->variables({level => 0, list => { a => "1" }});
my ($list_a, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{journalctl}." -t anvil --lines 1 --full --output cat --no-pager"});
is($list_a, "a: [1]", "Verified that we could log a list of variables (1 entry).");
$anvil->Log->variables({level => 0, list => { a => "1", b => "2" }});
(my $list_b, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{journalctl}." -t anvil --lines 1 --full --output cat --no-pager"});
is($list_b, "a: [1], b: [2]", "Verified that we could log a list of variables (2 entries).");
$anvil->Log->variables({level => 0, list => { a => "1", b => "2", c => "3" }});
(my $list_c, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{journalctl}." -t anvil --lines 1 --full --output cat --no-pager"});
is($list_c, "a: [1], b: [2], c: [3]", "Verified that we could log a list of variables (3 entries).");
$anvil->Log->variables({level => 0, list => { a => "1", b => "2", c => "3", d => "4" }});
(my $list_d, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{journalctl}." -t anvil --lines 1 --full --output cat --no-pager"});
is($list_d, "a: [1], b: [2], c: [3], d: [4]", "Verified that we could log a list of variables (4 entries).");
$anvil->Log->variables({level => 0, list => { a => "1", b => "2", c => "3", d => "4", e => "5" }});
(my $list_e, $return_code) = $anvil->System->call({shell_call => $anvil->data->{path}{exe}{journalctl}." -t anvil --lines 1 --full --output cat --no-pager"});
my $say_variables = $anvil->Words->key({key => "log_0019"});
my $expect_e = "$say_variables
|- a: [1]
|- b: [2]
|- c: [3]
|- d: [4]
\\- e: [5]";
is($list_e, $expect_e, "Verified that we could log a list of variables (5 entries, line wrapping).");
# _adjust_log_level - We're simulating switches to test Log->_adjust_log_level
$anvil->data->{switches}{V} = "#!set!#";
$anvil->data->{switches}{v} = "";
$anvil->data->{switches}{vv} = "";
$anvil->data->{switches}{vvv} = "";
$anvil->data->{switches}{vvvv} = "";
$anvil->Log->_adjust_log_level;
is($anvil->Log->level, "0", "Verifying the log level was set to '0' with Log->_adjust_log_leve() with 'V' switch set.");
$anvil->data->{switches}{V} = "";
$anvil->data->{switches}{v} = "#!set!#";
$anvil->Log->_adjust_log_level;
is($anvil->Log->level, "1", "Verifying the log level was set to '1' with Log->_adjust_log_leve() with 'v' switch set.");
$anvil->data->{switches}{v} = "";
$anvil->data->{switches}{vv} = "#!set!#";
$anvil->Log->_adjust_log_level;
is($anvil->Log->level, "2", "Verifying the log level was set to '2' with Log->_adjust_log_leve() with 'vv' switch set.");
$anvil->data->{switches}{vv} = "";
$anvil->data->{switches}{vvv} = "#!set!#";
$anvil->Log->_adjust_log_level;
is($anvil->Log->level, "3", "Verifying the log level was set to '3' with Log->_adjust_log_leve() with 'vvv' switch set.");
$anvil->data->{switches}{vvv} = "";
$anvil->data->{switches}{vvvv} = "#!set!#";
$anvil->Log->_adjust_log_level;
is($anvil->Log->level, "4", "Verifying the log level was set to '4' with Log->_adjust_log_leve() with 'vvvv' switch set.");
$anvil->data->{switches}{vvvv} = "";
$anvil->data->{switches}{v} = "#!set!#";
$anvil->Log->_adjust_log_level;
is($anvil->Log->level, "1", "Verifying the log level was set back to '1' with Log->_adjust_log_leve() with 'v' switch set.");

### Anvil::Tools::Storage tests - These happen a little out of order.
# We need to pick a user name and group name to use for these tests. So we'll start by reading in passwd.
my $passwd    = $anvil->Storage->read_file({file => "/etc/passwd"});
my $group     = $anvil->Storage->read_file({file => "/etc/group"});
my $read_ok   = 0;
my $use_user  = "";
my $use_group = "";
foreach my $line (split/\n/, $passwd)
{
	if ($line =~ /^root:/)
	{
		$read_ok = 1;
	}
	elsif ($line =~ /^(\w+):x:\d/)
	{
		$use_user = $1;
		last;
	}
}
foreach my $line (split/\n/, $group)
{
	if ($line =~ /^root:/)
	{
		# skip
	}
	elsif ($line =~ /^(\w+):x:\d/)
	{
		$use_group = $1;
		last;
	}
}
# print "[ Debug ] - Using the user: [$use_user] and the group: [$use_group] for testing.\n";
is($read_ok, "1", "Verified that 'Storage->read_file' could read a file.");
# Write a file /tmp/foo
my $body      = "This is a test file created as part of the Anvil::Tools test suite.\nYou can safely delete it if you wish.\n";
my $test_file = "/tmp/anvil.test";
if (-e $test_file)
{
	# remove the old test file.
	unlink $test_file or die "The test file: [$test_file] exists (from a previous run?) and can't be removed. The error was: $!\n";
}
$anvil->Storage->write_file({body => $body, file => $test_file, group => $use_group, user => $use_user, mode => "0666"});
my $write_ok = 0;
if (-e $test_file)
{
	$write_ok = 1;
}
is($write_ok, "1", "Verifying that 'Storage->write_file' could write a file (tested writing to: [$test_file]).");
my $mode            = $anvil->Storage->read_mode({target => $test_file});
my ($uid, $gid)     = (stat($test_file))[4,5];
my $file_user_name  = getpwuid($uid);
my $file_group_name = getgrgid($gid);
#print "[ Debug ] - test_file: [$test_file], mode: [$mode], owning user: [$file_user_name ($uid)], owning group: [$file_group_name ($gid)]\n";
is($mode, "0666", "Verifying that 'Storage->write_file' set the mode correctly when writing a file.");
is($file_user_name, $use_user, "Verifying that 'Storage->write_file' set the user name properly when the file was written.");
is($file_group_name, $use_group, "Verifying that 'Storage->write_file' set the group name properly when the file was written.");
# change_mode
$anvil->Storage->change_mode({target => $test_file, mode => "4755"});
$mode = $anvil->Storage->read_mode({target => $test_file});
is($mode, "4755", "Verifying that 'Storage->change_mode' was able to change the mode of the test file (including setting the setuid and setgid sticky bits).");
$anvil->Storage->change_mode({target => $test_file, mode => "644"});
$mode = $anvil->Storage->read_mode({target => $test_file});
is($mode, "0644", "Verifying that 'Storage->change_mode' was able to change the mode of the test file using three digits instead of four.");
# change_owner
$anvil->Storage->change_owner({target => $test_file, user => 0});
$file_user_name  = "";
$file_group_name = "";
($uid, $gid)     = (stat($test_file))[4,5];
$file_user_name  = getpwuid($uid);
$file_group_name = getgrgid($gid);
is($file_user_name, "root", "Verifying that 'Storage->change_user', when passed only a user ID, changed the user.");
is($file_group_name, $use_group, "Verifying that 'Storage->change_user', when passed only a user ID, did not change the group.");
$anvil->Storage->change_owner({target => $test_file, user => $use_user});
$file_user_name  = "";
$file_group_name = "";
($uid, $gid)     = (stat($test_file))[4,5];
$file_user_name  = getpwuid($uid);
$file_group_name = getgrgid($gid);
is($file_user_name, $use_user, "Verifying that 'Storage->change_user', when passed only a user name, changed the user.");
is($file_group_name, $use_group, "Verifying that 'Storage->change_user', when passed only a user ID, did not change the group.");
$anvil->Storage->change_owner({target => $test_file, group => 0});
$file_user_name  = "";
$file_group_name = "";
($uid, $gid)     = (stat($test_file))[4,5];
$file_user_name  = getpwuid($uid);
$file_group_name = getgrgid($gid);
is($file_user_name, $use_user, "Verifying that 'Storage->change_user', when passed only a group ID, did not change the user.");
is($file_group_name, "root", "Verifying that 'Storage->change_user', when passed only a group ID, changed the group.");
$anvil->Storage->change_owner({target => $test_file, group => $use_group});
$file_user_name  = "";
$file_group_name = "";
($uid, $gid)     = (stat($test_file))[4,5];
$file_user_name  = getpwuid($uid);
$file_group_name = getgrgid($gid);
is($file_user_name, $use_user, "Verifying that 'Storage->change_user', when passed only a group name, did not change the user.");
is($file_group_name, $use_group, "Verifying that 'Storage->change_user', when passed only a group name, changed the group.");
$anvil->Storage->change_owner({target => $test_file, user => "root", group => "root"});
$file_user_name  = "";
$file_group_name = "";
($uid, $gid)     = (stat($test_file))[4,5];
$file_user_name  = getpwuid($uid);
$file_group_name = getgrgid($gid);
is($file_user_name, "root", "Verifying that 'Storage->change_user', when passed both a user and group name, changed the user.");
is($file_group_name, "root", "Verifying that 'Storage->change_user', when passed both a user and group name, changed the group.");
my $change_owner_rc = $anvil->Storage->change_owner({target => "", user => "root", group => "root"});
is($change_owner_rc, "1", "Verifying that 'Storage->change_user', when passed no target, returned '1'.");
$change_owner_rc = "";
$change_owner_rc = $anvil->Storage->change_owner({target => "/fake/file", user => "root", group => "root"});
is($change_owner_rc, "1", "Verifying that 'Storage->change_user', when passed a bad file, returned '1'.");
# copy_file
my $copy_file = "/tmp/anvil.copy";
my $copied_ok = 0;
if (-e $copy_file)
{
	unlink $copy_file or die "The test copy file: [$copy_file] exists (from a previous run?) and can't be removed. The error was: $!\n";
}
$anvil->Storage->copy_file({source_file => $test_file, target_file => $copy_file});
if (-e $copy_file)
{
	$copied_ok = 1;
}
is($copied_ok, "1", "Verifying that 'Storage->copy_file' was able to copy the test file.");
my $copy_rc = $anvil->Storage->copy_file({target_file => $copy_file});
is($copy_rc, "1", "Verifying that 'Storage->copy_file' returned '1' when no source file was passed.");
$copy_rc = "";
$copy_rc = $anvil->Storage->copy_file({source_file => $test_file});
is($copy_rc, "2", "Verifying that 'Storage->copy_file' returned '2' when no target file was passed.");
$copy_rc = "";
$copy_rc = $anvil->Storage->copy_file({source_file => $test_file, target_file => $copy_file});
is($copy_rc, "3", "Verifying that 'Storage->copy_file' returned '3' when the target file already exists.");
$copy_rc = "";
$copy_rc = $anvil->Storage->copy_file({source_file => $test_file, target_file => $copy_file, overwrite => 1});
is($copy_rc, "0", "Verifying that 'Storage->copy_file' returned '0' when the target file already exists and overwrite was set.");
$copy_rc = "";
$copy_rc = $anvil->Storage->copy_file({source_file => "/fake/file", target_file => $copy_file});
is($copy_rc, "4", "Verifying that 'Storage->copy_file' returned '4' when the target file is passed but doesn't exist.");
# find
my $test_path = $anvil->Storage->find({ file => "Anvil/Tools.t" });
is($test_path, "/usr/share/perl5/Anvil/Tools.t", "Verifying that Storage->find successfully found 'Anvil/Tools.t'.");
my $bad_path  = $anvil->Storage->find({ file => "Anvil/wa.t" });
is($bad_path, "#!not_found!#", "Verifying that Storage->find properly returned '#!not_found!#' for a non-existed file.");
# make_directory
my $test_directory = "/tmp/anvil/test/directory";
if (-d $test_directory)
{
	foreach my $this_directory ("/tmp/anvil/test/directory", "/tmp/anvil/test", "/tmp/anvil")
	{
		rmdir $this_directory or die "Failed to remove the test directory: [$this_directory] (from a previous test?). The error was: $!\n";
	}
}
# This uses an odd mode on purpose
$anvil->Storage->make_directory({directory => $test_directory, group => $use_group, user => $use_user, mode => "0757"});
my $created_directory = 0;
if (-d $test_directory)
{
	$created_directory = 1;
}
is($created_directory, "1", "Verifying that 'Storage->create_directory' created a directory and its parents.");
my $directory_mode       = $anvil->Storage->read_mode({target => $test_directory});
($uid, $gid)             = (stat($test_directory))[4,5];
my $directory_user_name  = getpwuid($uid);
my $directory_group_name = getgrgid($gid);
is($directory_mode, "0757", "Verifying that 'Storage->create_directory' created a directory with the requested mode.");
is($directory_user_name, $use_user, "Verifying that 'Storage->create_directory' created a directory with the requested owner.");
is($directory_group_name, $use_group, "Verifying that 'Storage->create_directory' created a directory with the requested group.");
# read_config
$anvil->data->{foo}{bar}{a} = "test";
is($anvil->Storage->read_config({ file => "Anvil/test.conf" }), 0, "Verifying that 'Storage->read_config' successfully found 'Anvil/test.conf'.");
is($anvil->Storage->read_config({ file => "" }), 1, "Verifying that 'Storage->read_config' returns '1' when called without a 'file' parameter being set.");
is($anvil->Storage->read_config({ file => "Anvil/moo.conf" }), 2, "Verifying that 'Storage->read_config' returns '2' when the non-existent 'Anvil/moo.conf' is passed.");
cmp_ok($anvil->data->{foo}{bar}{a}, 'eq', 'I am "a"', "Verifying that 'Anvil/test.conf's 'foo::bar::a' overwrote an earlier set value.");
cmp_ok($anvil->data->{foo}{bar}{b}, 'eq', 'I am "b", split with tabs and having trailing spaces.', "Verifying that 'Anvil/test.conf's 'foo::bar::b' has whitespaces removed as expected.");
cmp_ok($anvil->data->{foo}{baz}{1}, 'eq', 'This is \'1\' with no spaces', "Verifying that 'Anvil/test.conf's 'foo::baz::1' parsed without spaces around '='.");
cmp_ok($anvil->data->{foo}{baz}{2}, 'eq', 'I had a $dollar = sign and split with tabs.', "Verifying that 'Anvil/test.conf's 'foo::baz::2' had no trouble with a '\$' and '=' characters in the string.");
# read_file was tested earlier.
# read_mode was tested earlier.
# search_directories
my $array1   = $anvil->Storage->search_directories;
my $a1_count = @{$array1};
cmp_ok($a1_count, '>', 0, "Verifying that Storage->search_directories has at least one entry. Found: [$a1_count] directories.");
$anvil->Storage->search_directories({directories => "/root,/usr/bin,/some/fake/directory"});
my $array2   = $anvil->Storage->search_directories;
my $a2_count = @{$array2};
cmp_ok($a2_count, '==', 2, "Verifying that Storage->search_directories now has 2 entries from a passed in CSV, testing that the list changed and a fake directory was dropped.");
$anvil->Storage->search_directories({directories => ["/usr/bin", "/tmp", "/home"] });
my $array3   = $anvil->Storage->search_directories;
my $a3_count = @{$array3};
cmp_ok($a3_count, '==', 3, "Verifying that Storage->search_directories now has 3 entries from a passed in array reference, verifying that the list changed again.");
$anvil->Storage->search_directories({directories => "invalid" });
my $array4   = $anvil->Storage->search_directories;
my $a4_count = @{$array4};
cmp_ok($a4_count, '==', $a1_count, "Verifying that Storage->search_directories has the original number of directories: [$a4_count] after being called with an invalid 'directories' parameter, showing that it reset properly.");
# write_file was tested earlier
# Cleanup.
unlink $test_file;
unlink $copy_file;
foreach my $this_directory ("/tmp/anvil/test/directory", "/tmp/anvil/test", "/tmp/anvil")
{
	rmdir $this_directory or die "Failed to remove the test directory: [$this_directory] (from a previous test?). The error was: $!\n";
}

### Anvil::Tools::System tests
# call was tested during the Log->entry test and will be tested further below.
# Daemon tests require that we create a test daemon and a unit for it...
my $test_daemon_file = "/tmp/anvil-test.daemon";
my $test_daemon_body = q|#!/usr/bin/perl
# This is a test daemon created for the Anvil::Tools test suite. It can safely be deleted.

use strict;
use warnings;
use Anvil::Tools;
my $anvil->= Anvil::Tools->new();
$anvil->Log->entry({level => 1, priority => "info", raw => "Anvil::Tools Test daemon started."});

while(1)
{
	sleep 2;
	$anvil->Log->entry({level => 1, priority => "info", raw => "Anvil::Tools Test daemon looped..."});
}

exit;
|;
$anvil->Storage->write_file({body => $test_daemon_body, file => $test_daemon_file, group => "root", user => "root", mode => "755", overwrite => 1});
my $test_service_name = "anvil-test.service";
my $test_service_file = "/usr/lib/systemd/system/".$test_service_name;
my $test_service_body = "[Unit]
Description=Test daemon used by Anvil::Tools test suite. It can safely be ignored/deleted.

[Service]
Type=simple
ExecStart=$test_daemon_file
ExecStop=/bin/kill -WINCH \${MAINPID}
";
$anvil->Storage->write_file({body => $test_service_body, file => $test_service_file, group => "root", user => "root", mode => "644", overwrite => 1});
$anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." daemon-reload"});
$anvil->System->stop_daemon({daemon => $test_service_name});	# Just in case...
# check_daemon
my $test_daemon_rc = $anvil->System->check_daemon({daemon => $test_service_name});
is($test_daemon_rc, "0", "Verifying that 'System->check_daemon' was able to confirm that the test service: [".$test_service_name."] was stopped.");
$test_daemon_rc = "";
$test_daemon_rc = $anvil->System->start_daemon({daemon => $test_service_name});
is($test_daemon_rc, "0", "Verifying that 'System->start_daemon' was able to start the test service: [".$test_service_name."].");
$test_daemon_rc = "";
$test_daemon_rc = $anvil->System->check_daemon({daemon => $test_service_name});
is($test_daemon_rc, "1", "Verifying that 'System->check_daemon' was able to confirm that the test service: [".$test_service_name."] is now running.");
$test_daemon_rc = "";
$test_daemon_rc = $anvil->System->stop_daemon({daemon => $test_service_name});
is($test_daemon_rc, "0", "Verifying that 'System->stop_daemon' was able to stop the test service: [".$test_service_name."].");
$test_daemon_rc = "";
$test_daemon_rc = $anvil->System->check_daemon({daemon => $test_service_name});
is($test_daemon_rc, "0", "Verifying that 'System->check_daemon' was able to confirm that the test service: [".$test_service_name."] was stopped.");

# Cleanup
unlink $test_service_file;
unlink $test_daemon_file;
$anvil->System->call({shell_call => $anvil->data->{path}{exe}{systemctl}." daemon-reload"});

### Anvil::Tools::Template tests
# We're going to need a fake template file to test.
my $test_template_file = "/tmp/anvil.html";
my $test_template_body = '<!-- start test1 -->
This is test template #1.
<!-- end test1 -->

<!-- start test2 -->
This is test template #2. It has a replacement: [#!variable!test!#].
<!-- end test2 -->
';
$anvil->Storage->write_file({body => $test_template_body, file => $test_template_file, mode => "644", overwrite => 1});
# get

my $test1_template = $anvil->Template->get({file => $test_template_file, name => "test1"});
is($test1_template, "This is test template #1.\n", "Verifying that 'Template->get' was able to read a test template.");
my $test2_template = $anvil->Template->get({file => $test_template_file, name => "test1", show_name => 1});
is($test2_template, "<!-- start: [/tmp/anvil.html] -> [test1] -->\nThis is test template #1.\n<!-- end: [/tmp/anvil.html] -> [test1] -->\n", "Verifying that 'Template->get' was able to read a test template with the source in HTML comments.");
my $test3_template = $anvil->Template->get({file => $test_template_file, name => "test2", variables => { test => "boo!" }});
is($test3_template, "This is test template #2. It has a replacement: [boo!].\n", "Verifying that 'Template->get' was able to read a test template with a variable insertion.");
is($anvil->Template->skin, "alteeve", "Verifying that 'Template->skin' is initially set to 'alteeve'.");
$anvil->Template->skin({fatal => 0, set => "test"});	# We disable fatal because there may be no skin directory yet.
is($anvil->Template->skin, "test", "Verifying that 'Template->skin' was changed to 'test'.");
$anvil->Template->skin({fatal => 0, set => "alteeve"});
is($anvil->Template->skin, "alteeve", "Verifying that 'Template->skin' was changed back to 'alteeve'.");
# Clean up
unlink $test_template_file;

### Anvil::Tools::Validate tests
# is_ipv4
is($anvil->Validate->is_ipv4({ip => "0.0.0.0"}), "1", "Verifying that 'Validate->is_ipv4' recognizes '0.0.0.0' as a valid IP address.");
is($anvil->Validate->is_ipv4({ip => "255.255.255.255"}), "1", "Verifying that 'Validate->is_ipv4' recognizes '255.255.255.255' as a valid IP address.");
is($anvil->Validate->is_ipv4({ip => "256.255.255.255"}), "0", "Verifying that 'Validate->is_ipv4' recognizes '256.255.255.255' as an invalid IP address.");
is($anvil->Validate->is_ipv4({ip => "alteeve.com"}), "0", "Verifying that 'Validate->is_ipv4' recognizes 'alteeve.com' as an invalid IP address.");
is($anvil->Validate->is_ipv4({ip => "::1"}), "0", "Verifying that 'Validate->is_ipv4' recognizes '::1' as an invalid IP address.");
my $test_uuid = $anvil->Get->uuid;
is($anvil->Validate->is_uuid({uuid => $test_uuid}), "1", "Verifying that 'Validate->is_uuid' recognized: [".$test_uuid."] as a valid UUID.");
my $bad_uuid_1 =  $test_uuid;
   $bad_uuid_1 =~ s/-//g;
is($anvil->Validate->is_uuid({uuid => $bad_uuid_1}), "0", "Verifying that 'Validate->is_uuid' recognized: [".$bad_uuid_1."] as an invalid UUID.");
my $bad_uuid_2 = uc($test_uuid);
is($anvil->Validate->is_uuid({uuid => $bad_uuid_2}), "0", "Verifying that 'Validate->is_uuid' recognized: [".$bad_uuid_2."] as an invalid UUID.");
my $bad_uuid_3 = $test_uuid."toolong";
is($anvil->Validate->is_uuid({uuid => $bad_uuid_3}), "0", "Verifying that 'Validate->is_uuid' recognized: [".$bad_uuid_3."] as an invalid UUID.");

### Anvil::Tools::Words tests
# clean_spaces
my $clean_string1 = " A line   with	spaces all over		  	";
my $clean_string2 = "A line with spaces at the end only    	 ";
my $clean_string3 = "    		A line with spaces in the front only";
my $clean_string4 = "A line with spaces 		 in the middle only";
is($anvil->Words->clean_spaces({string => $clean_string1}), "A line with spaces all over", "Verifying that 'Words->clean_spaces' cleaned up a string with random spaces.");
is($anvil->Words->clean_spaces({string => $clean_string2}), "A line with spaces at the end only", "Verifying that 'Words->clean_spaces' cleaned up a string spaces at the end of a string.");
is($anvil->Words->clean_spaces({string => $clean_string3}), "A line with spaces in the front only", "Verifying that 'Words->clean_spaces' cleaned up a string with spaces in the front only.");
is($anvil->Words->clean_spaces({string => $clean_string4}), "A line with spaces in the middle only", "Verifying that 'Words->clean_spaces' cleaned up a string with spaces in the middle only.");
# key
is($anvil->Words->key({key => "t_0001"}), "Test replace: [#!variable!test!#].", "Verifying that 'Words->key' returned the Canadian English 't_0001' string.");
is($anvil->Words->key({key => "t_0001", language => "jp"}), "テスト いれかえる: [#!variable!test!#]。", "Verifying that 'Words->read' returned the Japanese 't_0001' string.");
is($anvil->Words->key({key => "bad_key"}), "#!not_found!#", "Verified that 'Words->key' returns '#!not_found!#' for a bad key.");
is($anvil->Words->key({key => "t_0003", language => "jp"}), "#!not_found!#", "Verifying that 'Words->read' returned '#!not_found!#' for the missing 't_0003' key.");
# language
is($anvil->Words->language, "en_CA", "Verifying the default words language is 'en_CA'.");
$anvil->Words->language({set => "jp"});
is($anvil->Words->language, "jp", "Verifying the words language was changed to 'jp'.");
$anvil->Words->language({set => "en_CA"});
is($anvil->Words->language, "en_CA", "Verifying the words language is back to 'en_CA'.");
# read
### NOTE: At this time, we don't test for unreadable files (rc = 3) or general read faults as set by XML::Simple (rc = 4).

is($anvil->Words->read({file => $anvil->data->{path}{words}{'words.xml'}}), 0, "Verifying that 'Words->read' properly returned '0' when asked to read the Anvil::Tools's words file.");

is($anvil->Words->read({file => ''}), 1, "Verifying that 'Words->read' properly returned '1' when asked to read a works file without a file being passed.");
is($anvil->Words->read({file => '/tmp/dummy.xml'}), 2, "Verifying that 'Words->read' properly returned '2' when asked to read a non-existent file.");
# string
my $test_string1 = $anvil->Words->string({
	key       => "t_0005",
	variables => {
		test   => "result!",
		first  => "1st",
		second => "2nd",
 	},
});
is($test_string1, "
This is a multi-line test string with various items to insert.

It also has some #!invalid!# replacement #!keys!# to test the escaping and restoring.

Here is the default output language: [en_CA]
Here we will inject 't_0000': [Test replace: [result!].] 
Here we will inject 't_0002' with its embedded variables: [Test Out of order: [2nd] replace: [1st].]
Here we will inject 't_0006', which injects 't_0001' which has a variable: [This string embeds 't_0001': [Test replace: [result!].]].
", "Verifying string processing in the default (Canadian English) language.");
my $test_string2 = $anvil->Words->string({
	language  => "jp",
	key       => "t_0005",
	variables => {
		test   => "result!",
		first  => "1st",
		second => "2nd",
 	},
});
is($test_string2, "
これは、挿入するさまざまな項目を含む複数行のテスト文字列です。

#!無効#!な置換!#キー!#を使ってエスケープとリストアをテストすることもできます。

デフォルトの出力言語は次のとおりです：「en_CA」
ここで、「t_0000」を挿入します：[テスト いれかえる: [result!]。]
ここでは、 「t_0002」に埋め込み変数を挿入します：「テスト、 整理: [2nd]/[1st]。」
ここでは変数 「この文字列には「t_0001」が埋め込まれています：「テスト いれかえる: [result!]。」」を持つ 「t_0001」を注入する 「t_0006」を注入します。
", "Verifying string processing in Japanese.");

### DONE!
# Tell the user that we're done making noise in their logs
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0049"});

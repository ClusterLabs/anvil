#!/usr/bin/perl
# 
 
use strict;
use warnings;
use Anvil::Tools;
use Data::Dumper;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

my $anvil = Anvil::Tools->new();
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0115", variables => { program => $THIS_FILE }});

# Read switches (target ([user@]host[:port]) and the file with the target's password.
$anvil->Get->switches;

# Connect to the database(s).
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0132"});

my $key_string = 'scan_drbd_message_0007,!!resource_name!srv00-sql1!!,!!resource_state!#!string!scan_drbd_unit_0004!#!!,!!resource_xml!<resource name="srv00-sql1" conf-file-line="/etc/drbd.d/srv00-sql1.res:2">] from key string: [scan_drbd_message_0007,!!resource_name!srv00-sql1!!,!!resource_state!#!string!scan_drbd_unit_0004!#!!,!!resource_xml!<resource name="srv00-sql1" conf-file-line="/etc/drbd.d/srv00-sql1.res:2">
        <host name="mk-a02n01">
            <volume vnr="0">
                <device minor="0">/dev/drbd_srv00-sql1_0</device>
                <disk>/dev/mk-a02n01_ssd0/srv00-sql1_0</disk>
                <meta-disk>internal</meta-disk>
            </volume>
            <address family="(null)" port="(null)">(null)</address>
        </host>
        <host name="mk-a02n02">
            <volume vnr="0">
                <device minor="0">/dev/drbd_srv00-sql1_0</device>
                <disk>/dev/mk-a02n02_ssd0/srv00-sql1_0</disk>
                <meta-disk>internal</meta-disk>
            </volume>
            <address family="(null)" port="(null)">(null)</address>
        </host>
        <connection>
            <host name="mk-a02n01"><address family="ipv4" port="7788">10.101.12.1</address></host>
            <host name="mk-a02n02"><address family="ipv4" port="7788">10.101.12.2</address></host>
            <section name="net">
                <option name="protocol" value="C"/>
                <option name="fencing" value="resource-and-stonith"/>
            </section>
            <section name="disk">
                <option name="c-max-rate" value="500M"/>
            </section>
        </connection>
    </resource>!!';
my $out_string = $anvil->Words->parse_banged_string({
	debug      => 2, 
	key_string => $key_string, 
});

print "Got:
====
".$out_string."
====
";

$anvil->nice_exit({exit_code => 0});

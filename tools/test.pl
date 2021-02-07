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

my $key_string = 'message_0190
job_0185
job_0186,!!minor!5!!,!!port!7803!!
job_0188,!!job_uuid!12eeded2-c5bb-4295-8c8e-665bd9c9b83a!!,!!peer_name!mk-a02n01.digimer.ca!!
job_0189,!!lv_path!/dev/mk-a02n02_ssd0/srv02-lab02_0!!
job_0218
job_0190,!!resource!srv02-lab02!!
job_0191,!!resource!srv02-lab02!!
job_0192
job_0195
job_0203,!!resource!srv02-lab02!!
job_0199,!!shell_call!/usr/bin/virt-install --connect qemu:///system \
--name srv02-lab02 \
 --os-variant win2k19  \
 --memory 8192 \
 --events on_poweroff=destroy,on_reboot=restart \
 --vcpus 6,sockets=1,cores=6 \
 --cpu host \
 --network bridge=ifn1_bridge1,model=virtio \
 --graphics spice \
 --sound ich9 \
 --clock offset=localtime \
 --boot menu=on \
 --disk path=/dev/drbd/by-res/srv02-lab02/0,target.bus=virtio,driver.io=threads,cache=writeback,driver.discard=unmap,boot.order=1 \
 --disk path=/mnt/shared/files/Windows_Server_2019_eval.iso,device=cdrom,shareable=on,boot.order=2 \
 --disk path=/mnt/shared/files/virtio-win-0.1.185.iso,device=cdrom,shareable=on,boot.order=3 --force \
 --noautoconsole --wait -1 > /var/log/anvil-server_srv02-lab02.log
!!
job_0200';
my ($free_minor, $free_port) = $anvil->Words->parse_banged_string({
	debug      => 2, 
	key_string => $key_string, 
});

$anvil->nice_exit({exit_code => 0});

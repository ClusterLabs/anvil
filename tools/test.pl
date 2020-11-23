#!/usr/bin/perl
# 
 
use warnings;
use strict;
 
my $sysstat_directory   = "/var/log/sa/";
my $hostname            = `hostname | cut -f 1 -d .`;
 
opendir(my $directory_handle, $sysstat_directory) || die "Can't locate ".$sysstat_directory."\n";
 
my @file_list           = grep { /^sa[0-9]./ } readdir($directory_handle);
 
printf "Hostname is ... ".$hostname."\n";
foreach my $filename (sort {$a cmp $b} @file_list)
{
        #printf "Filepath: ....".$sysstat_directory.$filepath."\n"
        my $shell_call  = "sadf -dht ".$sysstat_directory.$filename." -- -S -u -r -p -q -n DEV";
        printf "Shell Call - ...  ".$shell_call."\n";
        open(my $file_handle, "$shell_call 2>&1 |") || die "Failed to parse output of [".$shell_call."].\n";
        while (<$file_handle>)
        {
                chomp;
                my $csv_line            = $_;
 
                if ($csv_line =~ /$hostname/)
                {
                        #printf "CSV Line...  ".$csv_line."\n";
                        printf "Variable Match!\n";
                }
                if ($csv_line =~ 'thinkpad-06HCV0')
                {
                        printf "String Match!\n";
                }
        }
 
}
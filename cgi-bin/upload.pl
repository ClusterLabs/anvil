#!/usr/bin/perl
# 
# This is a special-purpose mini program used to handle upload requests. It has it's own micro-handling of 
# CGI specifically set to grab data when triggered by Striker using the 'jQuery Upload File Plugin' from 
# files.js.
# 
# 

use strict;
use warnings;
use CGI;
use Anvil::Tools;

# Turn off buffering
$| = 1;

my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

my $anvil = Anvil::Tools->new();
$anvil->Log->level({set => 2});

my $cgi = CGI->new; 

print "Content-type: text/html; charset=utf-8\n\n";
print $anvil->Template->get({file => "files.html", name => "upload_header"})."\n";

my $lightweight_fh = $cgi->upload('field_name');
# undef may be returned if it's not a valid file handle
if ($cgi->param())
{
	my $start    = time;
	my $filename = $cgi->upload('upload_file');
	my $out_file = $anvil->data->{path}{directories}{shared}{incoming}."/".$filename;
	if (-e $out_file)
	{
		# Don't overwrite
		$out_file .= "_".$anvil->Get->date_and_time({file_name => 1});
		
		# If this exists (somehow), we'll append a short UUID
		if (-e $out_file)
		{
			$out_file .= "_".$anvil->Get->uuid({short => 1});
		}
	}
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0259", variables => { file => $out_file }});
	my $cgi_file_handle = $cgi->param('upload_file');
	open(my $file_handle, ">$out_file") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => 0, priority => "err", key => "log_0016", variables => { shell_call => $out_file, error => $! }});
	while(<$cgi_file_handle>)
	{
		print $file_handle $_;
	}
	close $file_handle;
	
	### NOTE: The timing is a guide only. The AJAX does a lot of work before this script is invoked. It 
	###       might be better to just remove the timing stuff entirely...
	my $size             = (stat($out_file))[7];
	my $say_size_human   = $anvil->Convert->add_commas({number => $size});
	my $say_size_comma   = $anvil->Convert->bytes_to_human_readable({'bytes' => $size});
	my $took             = time - $start;
	   $took             = 1 if not $took;
	my $say_took         = $anvil->Convert->add_commas({number => $took});
	my $bytes_per_second = $anvil->Convert->round({number => ($size / $took), places => 0});
	my $say_rate          = $anvil->Words->string({key => "suffix_0001", variables => { number => $anvil->Convert->bytes_to_human_readable({'bytes' => $bytes_per_second}) }});
	my $file_sum         = $anvil->Get->md5sum({file => $out_file});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		size             => $size,
		say_size_human   => $say_size_human, 
		say_size_comma   => $say_size_comma, 
		took             => $took, 
		say_took         => $say_took, 
		bytes_per_second => $bytes_per_second, 
		say_rate         => $say_rate, 
		file_sum         => $file_sum, 
	}});
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0260", variables => { 
		file       => $out_file,
		size_human => $say_size_human,
		size_bytes => $say_size_comma, 
		rate       => $say_rate, 
		took       => $say_took,
		md5sum     => $file_sum
	}});
}
else
{
	# Why are we here?
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "warn", key => "log_0261", variables => { file => $THIS_FILE }});
}

exit(0);

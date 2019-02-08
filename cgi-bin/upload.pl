#!/usr/bin/perl

use strict;
use warnings;
use CGI;

my $cgi = CGI->new; 
print q|Content-type: text/html; charset=utf-8

<!DOCTYPE html>
<html lang="en_CA">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	
	<!-- Disable caching during development. -->
	<meta http-equiv="cache-control" content="max-age=0" />
	<meta http-equiv="cache-control" content="no-cache" />
	<meta http-equiv="expires" content="0" />
	<meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
	<meta http-equiv="pragma" content="no-cache" />	<title>Alteeve - Striker</title>
	
	<link rel="stylesheet" href="/skins/alteeve/main.css" media="screen" />
	<script type="text/javascript" src="/jquery-latest.js"></script>
	<script type="text/javascript" src="/skins/alteeve/main.js"></script>
	
	<!-- NOTE: These are for jquery-ui using the 'smoothness' skin. We may want to move this under the skin directory in case other skins want to use different jquery-ui skins someday. -->
	<link rel="stylesheet" href="/jquery-ui-latest/jquery-ui.css">
	<script type="text/javascript" src="/jquery-ui-latest/jquery-ui.js"></script>
	
	<script type="text/javascript" src="/skins/alteeve/files.js"></script>
	<link rel="stylesheet" href="/skins/alteeve/files.css">
|;


my $lightweight_fh  = $cgi->upload('field_name');
# undef may be returned if it's not a valid file handle
if ($cgi->param())
{
	print q|
	<title>Saving File...</title>
</head>
<body>
|;
	my $filename = $cgi->upload('upload_file');
	my $out      = "/mnt/shared/incoming/".$filename;
	print "Saving file: [".$out."]\n";
	my $cgi_file_handle = $cgi->param('upload_file');
	open(my $file_handle, ">$out") or die "failed to write: [$out], error: $!\n";
	while(<$cgi_file_handle>)
	{
		print $file_handle $_;
	}
	close $file_handle;
	print "Done.\n";
}
else
{
	print q|
	<title>Test Upload</title>
</head>
<body>
	<h1>Upload file</h1>
	<form method="post" enctype="multipart/form-data">
		<!-- <input type="file" name="upload_file" value="Choose file"> -->
		<!-- <input type="submit" name="submit" value="Upload"> -->
		Upload
		<div id="fileuploader">Upload</div>
	</form>
|;
}
print "</body>\n";

exit(0);

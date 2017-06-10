package AN::Tools::System;
# 
# This module contains methods used to handle common system tasks.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "System.pm";

### Methods;
# read_file

=pod

=encoding utf8

=head1 NAME

AN::Tools::System

Provides all methods related to storage on a system.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->System->X'. 
 # 
 # Example using 'read_file()';
 my $data = $an->System->read_file({file => "/tmp/foo"});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {};
	
	bless $self, $class;
	
	return ($self);
}

# Get a handle on the AN::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################


=head2 read_file

This reads in a file and returns the contents of the file as a single string variable.

 $an->System->read_file({file => "/tmp/foo"});

If it fails to find the file, or the file is not readable, 'C<< undef >>' is returned.

Parameters;

=head3 file (required)

This is the name of the file to read.

=cut
sub read_file
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $body = "";
	my $file = defined $parameter->{file} ? $parameter->{file} : "";
	
	if (not $file)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020"});
		return(undef);
	}
	elsif (not -e $file)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0021", variables => { file => $file }});
		return(undef);
	}
	elsif (not -r $file)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0022", variables => { file => $file }});
		return(undef);
	}
	
	my $shell_call = $file;
	$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0012", variables => { shell_call => $shell_call }});
	open (my $file_handle, "<", $shell_call) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0015", variables => { shell_call => $shell_call, error => $! }});
	while(<$file_handle>)
	{
		chomp;
		my $line = $_;
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0023", variables => { line => $line }});
		$body .= $line."\n";
	}
	close $file_handle;
	$body =~ s/\n$//s;
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { body => $body }});
	return($body);
}

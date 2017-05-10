package AN::Tools::Words;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use XML::LibXML;
use Encode;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Words.pm";

# Setup for UTF-8 mode.
# use utf8;
# $ENV{'PERL_UNICODE'} = 1;

### Methods;
# read

=pod

=encoding utf8

=head1 NAME

AN::Tools::Words

Provides all methods related to generating translated strings for users.

=head1 SYNOPSIS

 use AN::Tools::Words;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Words->X'. 
 # 
 # Example using 'read()';
 my $foo_path = $an->Words->read({file => $an->data->{path}{words}{'an-tools.xml'}});

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


=head2 read

This reads in a words file containing translated strings used to generated output for the user. 

Example to read 'C<an-tools.xml>';

 my $words_file = $an->data->{path}{words}{'an-words.xml'};
 my $an->Words->read({file => $words_file}) or die "Failed to read: [$words_file]. Does the file exist?\n";

Successful read will return '0'. Non-0 is an error;
0 = OK
1 = Invalid file name or path
2 = File not found
3 = File not readable
4 = File found, but did not contain strings.

NOTE: Read works are stored in 'C<< $an->data->{words}{<file_name>}{language}{<language>}{string} >>'. Metadata, like what languages are provided, are stored under 'C<< $an->data->{words}{<file_name>}{meta}{...} >>'.

Parameters;

=head3 file

This is the file to read.

=cut
sub read
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Setup default values
	my $file        = defined $parameter->{file} ? $parameter->{file} : 0;
	my $return_code = 0;
	
	if (not $file)
	{
		# TODO: Log the problem, do not translate.
		print $THIS_FILE." ".__LINE__."; AN::Tools::Words->read()' called without a file name to read.\n";
		$return_code = 1;
	}
	elsif (not -e $file)
	{
		# TODO: Log the problem, do not translate.
		print $THIS_FILE." ".__LINE__."; AN::Tools::Words->read()' asked to read: [$file] which was not found.\n";
		$return_code = 2;
	}
	elsif (not -r $file)
	{
		# TODO: Log the problem, do not translate.
		print $THIS_FILE." ".__LINE__."; AN::Tools::Words->read()' asked to read: [$file] which was not readable by: [".getpwuid($<)."/".getpwuid($>)."] (uid/euid: [".$<."/".$>."]).\n";
		$return_code = 3;
	}
	else
	{
		# Read the file with XML::LibXML
		my $parser = XML::LibXML->new();
		my $dom    = XML::LibXML->load_xml({location => $file});
		print "===========================================================\n";
		print Dumper $dom;
		print "===========================================================\n";
		
# 		my $data = "";
# 		eval { $data = $xml->XMLin($file, KeyAttr => {node => 'name'}, ForceArray => 1) };
# 		if ($@)
# 		{
# 			chomp $@;
# 			print $THIS_FILE." ".__LINE__."; [ Error ] - The was a problem reading: [$file]. The error was:\n";
# 			print "===========================================================\n";
# 			print $@."\n";
# 			print "===========================================================\n";
# 			$return_code = 4;
# 		}
# 		else
# 		{
# 			print "===========================================================\n";
# 			#print Dumper $data;
# 			print Dumper $data->{language};
# 			print "===========================================================\n";
# 			
# 			# Read the meta data
# 			my $meta_found = 0;
# 			my $version   = $data->{meta}->[0]->{version}->[0];
# 			my $languages = $data->{meta}->[0]->{languages}->[0];
# 			#print $THIS_FILE." ".__LINE__."; [ Debug ] - Version: [$version], languages: [$languages]\n";
# 			
# 			my $this_language = "";
# 			foreach my $hash_ref (@{$data->{language}})
# 			{
# 				   $this_language = $hash_ref->{name};
# 				my $long_name     = $hash_ref->{long_name};
# 				print $THIS_FILE." ".__LINE__."; [ Debug ] - this_language: [$this_language], long_name: [$long_name]\n";
# 			}
# 		}
	}
	
	return($return_code);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

1;

package AN::Tools::Words;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use XML::Simple qw(:strict);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Words.pm";

# Setup for UTF-8 mode.
# use utf8;
# $ENV{'PERL_UNICODE'} = 1;

### Methods;
# key
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

=head2 key

NOTE: This is likely not the method you want. This method does no parsing at all. It returns the raw string from the 'words' file. You probably want C<< $an->Words->string() >> if you want to inject variables and get a string back ready to display to the user.

This returns a string by its key name. Optionally, a language and/or a source file can be specified. When no file is specified, loaded files will be search in alphabetical order (including path) and the first match is returned. 

If the requested string is not found, 'C<< #!not_found!# >>' is returned.

Example to retrieve 'C<< t_0001 >>';

 my $string = $an->Words->key({key => 't_0001'});

Same, but specifying the key from Canadian english;

 my $string = $an->Words->key({
 	key      => 't_0001',
 	language => 'en_CA',
 })

Same, but specifying a source file.

 my $string = $an->Words->key({
 	key      => 't_0001',
 	language => 'en_CA',
 	file     => 'an-tools.xml',
 })

Parameters;

=head3 key (required)

This is the key to return the string for.

=head3 language (optional)

This is the ISO code for the language you wish to read. For example, 'en_CA' to get the Canadian English string, or 'jp' for the Japanese string.

When no language is passed, 'C<< $an->data->{defaults}{languages}{output} >>' is used. 

=head3 file (optional)

This is the specific file to read the string from. It should generally not be needed as string keys should not be reused. However, if it happens, this is a way to specify which file's version you want.

The file can be the file name, or a path. The specified file is search for by matching the the passed in string against the end of the file path. For example, 'C<< file => 'AN/an-tools.xml' >> will match the file 'c<< /usr/share/perl5/AN/an-tools.xml >>'.
 
=cut
sub key
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Setup default values
	my $key      = defined $parameter->{key}      ? $parameter->{key}      : "";
	my $language = defined $parameter->{language} ? $parameter->{language} : $an->data->{defaults}{languages}{output};
	my $file     = defined $parameter->{file}     ? $parameter->{file}     : "";
	my $string   = "#!not_found!#";
	my $error    = 0;
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - key: [$key], language: [$language], file: [$file]\n";

	if (not $key)
	{
		#print $THIS_FILE." ".__LINE__."; AN::Tools::Words->key()' called without a key name to read.\n";
		$error = 1;
	}
	if (not $language)
	{
		#print $THIS_FILE." ".__LINE__."; AN::Tools::Words->key()' called without a language, and 'defaults::languages::output' is not set.\n";
		$error = 2;
	}
	
	if (not $error)
	{
		foreach my $this_file (sort {$a cmp $b} keys %{$an->data->{words}})
		{
			#print $THIS_FILE." ".__LINE__."; [ Debug ] - this_file: [$this_file], file: [$file]\n";
			# If they've specified a file and this doesn't match, skip it.
			next if (($file) && ($this_file !~ /$file$/));
			if (exists $an->data->{words}{$this_file}{language}{$language}{key}{$key}{content})
			{
				$string = $an->data->{words}{$this_file}{language}{$language}{key}{$key}{content};
				#print $THIS_FILE." ".__LINE__."; [ Debug ] - string: [$string]\n";
				last;
			}
		}
	}
	
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - string: [$string]\n";
	return($string);
}

=head2 read

This reads in a words file containing translated strings used to generated output for the user. 

Example to read 'C<< an-tools.xml >>';

 my $words_file = $an->data->{path}{words}{'an-words.xml'};
 my $an->Words->read({file => $words_file}) or die "Failed to read: [$words_file]. Does the file exist?\n";

Successful read will return '0'. Non-0 is an error;
0 = OK
1 = Invalid file name or path
2 = File not found
3 = File not readable
4 = File found, failed to read for another reason. The error details will be printed.

NOTE: Read works are stored in 'C<< $an->data->{words}{<file_name>}{language}{<language>}{string}{content} >>'. Metadata, like what languages are provided, are stored under 'C<< $an->data->{words}{<file_name>}{meta}{...} >>'.

Parameters;

=head3 file (required)

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
		print $THIS_FILE." ".__LINE__."; [ Warning ] - AN::Tools::Words->read()' called without a file name to read.\n";
		$return_code = 1;
	}
	elsif (not -e $file)
	{
		# TODO: Log the problem, do not translate.
		print $THIS_FILE." ".__LINE__."; [ Warning ] - AN::Tools::Words->read()' asked to read: [$file] which was not found.\n";
		$return_code = 2;
	}
	elsif (not -r $file)
	{
		# TODO: Log the problem, do not translate.
		print $THIS_FILE." ".__LINE__."; [ Warning ] - AN::Tools::Words->read()' asked to read: [$file] which was not readable by: [".getpwuid($<)."/".getpwuid($>)."] (uid/euid: [".$<."/".$>."]).\n";
		$return_code = 3;
	}
	else
	{
		# Read the file with XML::Simple
		my $xml  = XML::Simple->new();
		eval { $an->data->{words}{$file} = $xml->XMLin($file, KeyAttr => { language => 'name', key => 'name' }, ForceArray => [ 'language', 'key' ]) };
		if ($@)
		{
			chomp $@;
			print $THIS_FILE." ".__LINE__."; [ Error ] - The was a problem reading: [$file]. The error was:\n";
			print "===========================================================\n";
			print $@."\n";
			print "===========================================================\n";
			$return_code = 4;
		}
		else
		{
			# Successfully read. 
			
			### Some debug stuff
			# Read the meta data
			#my $version    = $an->data->{words}{$file}{meta}{version};
			#my $languages  = $an->data->{words}{$file}{meta}{languages};
			#print $THIS_FILE." ".__LINE__."; [ Debug ] - Version: [$version], languages: [$languages]\n";
			
			#foreach my $this_language (sort {$a cmp $b} keys %{$an->data->{words}{$file}{language}})
			#{
			#	my $long_name = $an->data->{words}{$file}{language}{$this_language}{long_name};
			#	print $THIS_FILE." ".__LINE__."; [ Debug ] - this_language: [$this_language], long_name: [$long_name]\n";
			#	print $THIS_FILE." ".__LINE__."; [ Debug ] - "$this_language:t_0001: [".$an->data->{words}{$file}{language}{$this_language}{key}{t_0001}{content}."]\n";
			#}
		}
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

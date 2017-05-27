package AN::Tools::Storage;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Storage.pm";

### Methods;
# find
# read_config
# search_directories

=pod

=encoding utf8

=head1 NAME

AN::Tools::Storage

Provides all methods related to storage on a system.

=head1 SYNOPSIS

 use AN::Tools::Storage;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Storage->X'. 
 # 
 # Example using 'find()';
 my $foo_path = $an->Storage->find({file => "foo"});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		SEARCH_DIRECTORIES	=>	\@INC,
	};
	
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


=head2 find

This searches for the given file on the system. It will search in the directories returned by C<< $an->Storage->search_directories() >>.

Example to search for 'C<< foo >>';

 $an->Storage->find({file => "foo"});

Same, but error out if the file isn't found.

 $an->Storage->find({
 	file  => "foo",
 	fatal => 1,
 });

If it fails to find the file and C<< fatal >> isn't set to 'C<< 1 >>', 'C<< 0 >>' is returned.

Parameters;

=head3 fatal (optional)

This can be set to 'C<< 1 >>' to tell the method to throw an error and exit if the file is not found. Default is 'C<< 0 >>' which only triggers a warning of the file isn't found.

=head3 file (required)

This is the name of the file to search for.

=cut
sub find
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Setup default values
	my $fatal = defined $parameter->{fatal} ? $parameter->{fatal} : 0;
	my $file  = defined $parameter->{file}  ? $parameter->{file}  : "";
	
	# Each full path and file name will be stored here before the test.
	my $full_path = "#!not_found!#";
	foreach my $directory (@{$an->Storage->search_directories()})
	{
		# If "directory" is ".", expand it.
		if (($directory eq ".") && ($ENV{PWD}))
		{
			$directory = $ENV{PWD};
		}
		
		# Put together the initial path
		my $test_path = $directory."/".$file;

		# Clear double-delimiters.
		$test_path =~ s/\/+/\//g;
		
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - Test path: [$test_path] - ";
		if (-f $test_path)
		{
			# Found it!
			#print "Found!\n";
			$full_path = $test_path;
			last;
		}
		else
		{
			#print "Not found...\n";
		}
	}
	
	# Die if we didn't find the file and fatal is set.
	if ($full_path !~ /^\//)
	{
		if ($fatal)
		{
			### TODO: Make this $an->Alert->error() later
			print $THIS_FILE." ".__LINE__."; [ Error ] - Failed to find: [$file].\n";
		}
		else
		{
			### TODO: Make this $an->Alert->warning() later
			print $THIS_FILE." ".__LINE__."; [ Warning ] - Failed to find: [$file].\n";
		}
		if ($fatal)
		{
			print "Exiting on errors.\n";
			exit(2);
		}
	}
	
	# Return
	return ($full_path);
}

=head2 read_config

This method is used to read 'AN::Tools' style configuration files. These configuration files are in the format:

 # This is a comment for the 'a::b::c' variable
 a::b::c = x

A configuration file can be read in like this;

 $an->Storage->read_config({ file => "test.conf" });

In this example, the file 'C<< test.conf >>' will be searched for in the directories returned by 'C<< $an->Storage->search_directories >>'. 

Any line starting with '#' is a comment and is ignored. Preceding white spaces are allowed and also ignored.

Any line in the format 'x = y' is treated as a variable / value pair, split on the first 'C<< = >>'. Whitespaces on either side of the 'C<< = >>' are removed and ignored. However, anything after the first non-whitespace character is treated as data an unmolested. This includes addition 'C<< = >>' characters, white spaces and so on. The exception is that trailing white spaces are cropped and ignored. If nothing comes after the 'C<< = >>', the variable is set to a blank string.

Successful read will return 'C<< 0 >>'. Non-0 is an error;
C<< 0 >> = OK
C<< 1 >> = Invalid or missing file name
C<< 2 >> = File not found
C<< 3 >> = File not readable

Parameters;

=head3 file (required)

This is the configuration file to read. 

If the 'C<< file >>' parameter starts with 'C<< / >>', the exact path to the file is used. Otherwise, this method will search for the file in the list of directories returned by 'C<< $an->Storage->search_directories >>'. The first match is read in.

All variables are stored in the root of 'C<< $an->data >>', allowing for configuration files to override internally set variables.

For example, if you set:
 
 $an->data->{a}{b}{c} = "1";

Then you read in a config file with:

 a::b::c = x

Then 'C<< $an->data->{a}{b}{c} >>' will now contain 'C<< x >>'.

=cut
sub read_config
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Setup default values
	my $file        = defined $parameter->{file} ? $parameter->{file} : 0;
	my $return_code = 0;
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - file: [$file].\n";
	
	if (not $file)
	{
		# TODO: Log the problem, do not translate.
		print $THIS_FILE." ".__LINE__."; [ Warning ] - AN::Tools::Words->read()' called without a file name to read.\n";
		$return_code = 1;
	}
	
	# If I have a file name that isn't a full path, find it.
	if (($file) && ($file !~ /^\//))
	{
		# Find the file, if possible. If not found, we'll not alter what the user passed in and hope
		# it is relative to where we are.
		my $path = $an->Storage->find({ file => $file });
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - path: [$path].\n";
		if ($path ne "#!not_found!#")
		{
			# Update the file
			$file = $path;
			#print $THIS_FILE." ".__LINE__."; [ Debug ] - file: [$file].\n";
		}
	}
	
	if ($file)
	{
		if (not -e $file)
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
			# Read it in!
			my $count = 0;
			open (my $file_handle, "<$file") or die "Can't read: [$file], error was: $!\n";
			while (<$file_handle>)
			{
				chomp;
				my $line =  $_;
				$line =~ s/^\s+//;
				$line =~ s/\s+$//;
				$count++;
				next if ((not $line) or ($line =~ /^#/));
				next if $line !~ /=/;
				my ($variable, $value) = split/=/, $line, 2;
				$variable =~ s/\s+$//;
				$value    =~ s/^\s+//;
				if (not $variable)
				{
					print $THIS_FILE." ".__LINE__."; [ Warning ] - The config file: [$file] appears to have a malformed line: [$count:$line].\n";
				}
				
				$an->_make_hash_reference($an->data, $variable, $value);
			}
			close $file_handle;
		}
	}
	
	return($return_code);
}

=head2 search_directories

This method returns an array reference of directories to search within for files and directories.

Parameters;

=head3 directories (optional)

This accepts either an array reference of directories to search, or a comma-separated string of directories to search (which will be converted to an array). When passed, this sets the internal list of directories to search. 

By default, it is set to all directories in C<< \@INC >> and the C<< $ENV{'PATH'} >> variables, minus directories that don't actually exist. The returned array is sorted alphabetically.

=cut 
sub search_directories
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Set a default if nothing was passed.
	my $array = defined $parameter->{directories} ? $parameter->{directories} : "";
	
	# If the array is a CSV of directories, convert it now.
	if ($array =~ /,/)
	{
		# CSV, convert to an array.
		my @new_array = split/,/, $array;
		   $array     = \@new_array;
	}
	elsif (($array) && (ref($array) ne "ARRAY"))
	{
		# TODO: Make this a $an->Alert->warning().
		print $THIS_FILE." ".__LINE__."; [ Warning ] - The passed in array: [$array] wasn't actually an array. Using \@INC + \$ENV{'PATH'} for the list of directories to search instead.\n";
		
		# Create a new array containing the '$ENV{'PATH'}' directories and the @INC directories.
		my @new_array = split/:/, $ENV{'PATH'} if $ENV{'PATH'} =~ /:/;
		foreach my $directory (@INC)
		{
			push @new_array, $directory;
		}
		$array = \@new_array;
	}
	
	# Store the new array, if set.
	if (ref($array) eq "ARRAY")
	{
		# Dedupe and sort.
		my $sorted_array     = [];
		my $seen_directories = {};
		foreach my $directory (sort {$a cmp $b} @{$array})
		{
			# Convert '.' to $ENV{PWD}
			if ($directory eq ".")
			{
				$directory = $ENV{PWD};
			}
			
			# Skip duplicates
			next if exists $seen_directories->{$directory};
			
			# Skip non-existent directories
			next if not -d $directory;
			
			# Record this directory.
			$seen_directories->{$directory} = 1;
			push @{$sorted_array}, $directory;
		}
		$array = $sorted_array;
		
		$self->{SEARCH_DIRECTORIES} = $array;
	}
	
	return ($self->{SEARCH_DIRECTORIES});
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

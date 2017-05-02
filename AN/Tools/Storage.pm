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

Methods in the core module;

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

This searches for the given file on the system. It will search in the directories returned by C<$an->Storage->search_directories()>.

Example to search for 'C<foo>';

 $an->Storage->find({file => "foo"});

Same, but error out if the file isn't found.

 $an->Storage->find({
 	file  => "foo",
 	fatal => 1,
 });

If it fails to find the file and C<fatal> isn't set to C<1>, 'C<0>' is returned.

Parameters;

=head3 fatal C<0|1>

This can be set to '1' to tell the method to throw an error and exit if the file is not found. Default is '0' which  only triggers a warning of the file isn't found.

=head3 file

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
	my $full_path = "";
	foreach my $directory (@{$an->Storage->search_directories()})
	{
		# If "directory" is ".", expand it.
		if (($directory eq ".") && ($ENV{PWD}))
		{
			$directory = $ENV{PWD};
		}
		
		# Put together the initial path
		$full_path = $directory."/".$file;

		# Clear double-delimiters.
		$full_path =~ s/\/+/\//g;
		
		if (-f $full_path)
		{
			# Found it, return.
			return ($full_path);
		}
	}
	
	# Die if we didn't find the file and fatal is set.
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
	
	# If I am here, I failed but fatal errors are disabled.
	return (0);
}

=head2 search_directories

This method returns an array reference of directories to search within for files and directories.

Parameters;

=head3 directories

This is either an array reference of directories to search, or a comma-separated string of directories to search. When passed, this sets the internal list of directories to search. By default, it is set to C<\@INC>.

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
		print $THIS_FILE." ".__LINE__."; The passed in array: [$array] wasn't an array. Using \@INC for the list of directories to search instead.\n";
		$array = \@INC;
	}
	
	# Store the new array, if set.
	if (ref($array) eq "ARRAY")
	{
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

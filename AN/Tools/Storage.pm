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
# change_mode
# change_owner
# find
# make_directory
# read_config
# read_file
# search_directories
# write_file

=pod

=encoding utf8

=head1 NAME

AN::Tools::Storage

Provides all methods related to storage on a system.

=head1 SYNOPSIS

 use AN::Tools;

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


=head2 change_mode

This changes the mode of a file or directory.

 $an->Storage->change_mode({target => "/tmp/foo", mode => "0644"});

If it fails to write the file, an alert will be logged.

Parameters;

=head3 target (required)

This is the file or directory to change the mode on.

=head3 mode (required)

This is the numeric mode to set on the file. It expects four digits to cover the sticky bit, but will work with three digits.

=cut
sub change_mode
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $target = defined $parameter->{target} ? $parameter->{target} : "";
	my $mode   = defined $parameter->{mode}   ? $parameter->{mode}   : "";
	
	my $error = 0;
	if (not $target)
	{
		# No target...
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0036"});
		$error = 1;
	}
	if (not $mode)
	{
		# No mode...
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0037"});
		$error = 1;
	}
	elsif (($mode !~ /^\d\d\d$/) && ($mode !~ /^\d\d\d\d$/))
	{
		# Invalid mode
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0038", variables => { mode => $mode }});
		$error = 1;
	}
	
	if (not $error)
	{
		my $shell_call = $an->data->{path}{exe}{'chmod'}." $mode $target";
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0011", variables => { shell_call => $shell_call }});
		open (my $file_handle, $shell_call." 2>&1 |") or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0017", variables => { line => $line }});
		}
		close $file_handle;
	}
	
	return(0);
}

=head2 change_owner

This changes the owner and/or group of a file or directory.

 $an->Storage->change_owner({target => "/tmp/foo", mode => "0644"});

If it fails to write the file, an alert will be logged.

Parameters;

=head3 target (required)

This is the file or directory to change the mode on.

=head3 group (optional)

This is the group name or UID to set the target to.

=head3 user (optional)

This is the user name or UID to set the target to.

=cut
sub change_owner
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $target = defined $parameter->{target} ? $parameter->{target} : "";
	my $group  = defined $parameter->{group}  ? $parameter->{group}  : "";
	my $user   = defined $parameter->{user}   ? $parameter->{user}   : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		target => $target,
		group  => $group,
		user   => $user,
	}});
	
	my $string = "";
	my $error  = 0;
	if (not $target)
	{
		# No target...
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0039"});
		$error = 1;
	}
	
	if ($user)
	{
		$string = $user;
	}
	if ($group)
	{
		$string .= ":".$group;
	}
	
	if ((not $error) && ($string))
	{
		my $shell_call = $an->data->{path}{exe}{'chown'}." $string $target";
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0011", variables => { shell_call => $shell_call }});
		open (my $file_handle, $shell_call." 2>&1 |") or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0017", variables => { line => $line }});
		}
		close $file_handle;
	}
	
	return(0);
}

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

=head3 file (required)

This is the name of the file to search for.

=cut
sub find
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Setup default values
	my $file  = defined $parameter->{file}  ? $parameter->{file}  : "";
	
	# Each full path and file name will be stored here before the test.
	my $full_path = "#!not_found!#";
	if ($file)
	{
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
			
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { test_path => $test_path }});
			if (-f $test_path)
			{
				# Found it!
				$full_path = $test_path;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { full_path => $full_path }});
				last;
			}
		}
		
		# Log if we failed to find the path.
		if ($full_path !~ /^\//)
		{
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0029", variables => { file => $file }});
		}
	}
	else
	{
		# No file name passed in.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0030"});
	}
	
	# Return
	return ($full_path);
}

=head2 make_directory

This creates a directory (and any parent directories).

 $an->Storage->make_directory({directory => "/foo/bar/baz", owner => "me", grou[ => "me", group => 755});

If it fails to create the directory, an alert will be logged.

Parameters;

=head3 directory (required)

This is the name of the directory to create.

=head3 group (optional)

This is the group name or group ID to set the ownership of the directory to.

=head3 mode (optional)

This is the numeric mode to set on the file. It expects four digits to cover the sticky bit, but will work with three digits.

=head3 user (optional)

This is the user name or user ID to set the ownership of the directory to.

=cut
sub make_directory
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $directory = defined $parameter->{directory} ? $parameter->{directory} : "";
	my $group     = defined $parameter->{group}     ? $parameter->{group}     : "";
	my $mode      = defined $parameter->{mode}      ? $parameter->{mode}      : "";
	my $user      = defined $parameter->{user}      ? $parameter->{user}      : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		directory => $directory,
		group     => $group, 
		mode      => $mode,
		user      => $user,
	}});
	
	# Break the directories apart.
	my $working_directory = "";
	foreach my $directory (split, /\//, $directory)
	{
		next if not $directory;
		$working_directory .= "/$directory";
		$working_directory =~ s/\/\//\//g;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { working_directory => $working_directory }});
		if (not -e $working_directory)
		{
			# Directory doesn't exist, so create it.
			my $shell_call = $an->data->{path}{exe}{'mkdir'}." ".$working_directory;
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0011", variables => { shell_call => $shell_call }});
			open (my $file_handle, $shell_call." 2>&1 |") or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
			while(<$file_handle>)
			{
				chomp;
				my $line = $_;
				$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0017", variables => { line => $line }});
			}
			close $file_handle;
			
			if ($mode)
			{
				$an->Storage->change_mode({target => $working_directory, mode => $mode});
			}
			if (($user) or ($group))
			{
				$an->Storage->change_owner({target => $working_directory, user => $user, group => $group});
			}
		}
	}
	
	return(0);
}

=head2 read_config

This method is used to read 'AN::Tools' style configuration files. These configuration files are in the format:

 # This is a comment for the 'a::b::c' variable
 a::b::c = x

A configuration file can be read in like this;

 $an->Storage->read_config({file => "test.conf"});

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
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { file => $file }});
	
	if (not $file)
	{
		# No file to read
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0032"});
		$return_code = 1;
	}
	
	# If I have a file name that isn't a full path, find it.
	if (($file) && ($file !~ /^\//))
	{
		# Find the file, if possible. If not found, we'll not alter what the user passed in and hope
		# it is relative to where we are.
		my $path = $an->Storage->find({ file => $file });
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { path => $path }});
		if ($path ne "#!not_found!#")
		{
			# Update the file
			$file = $path;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { file => $file }});
		}
	}
	
	if ($file)
	{
		if (not -e $file)
		{
			# The file doesn't exist
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0033", variables => { file => $file }});
			$return_code = 2;
		}
		elsif (not -r $file)
		{
			# The file can't be read
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0034", variables => { 
				file => $file,
				user => getpwuid($<),
				uid  => $<,
			}});
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
					$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0035", variables => { 
						file  => $file,
						count => $count,
						line  => $line,
					}});
				}
				
				$an->_make_hash_reference($an->data, $variable, $value);
			}
			close $file_handle;
		}
	}
	
	return($return_code);
}

=head2 read_file

This reads in a file and returns the contents of the file as a single string variable.

 $an->Storage->read_file({file => "/tmp/foo"});

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
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { file => $file }});
	
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
	$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0012", variables => { shell_call => $shell_call }});
	open (my $file_handle, "<", $shell_call) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0015", variables => { shell_call => $shell_call, error => $! }});
	while(<$file_handle>)
	{
		chomp;
		my $line = $_;
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0023", variables => { line => $line }});
		$body .= $line."\n";
	}
	close $file_handle;
	$body =~ s/\n$//s;
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { body => $body }});
	return($body);
}

=head2 search_directories

This method returns an array reference of directories to search within for files and directories.

Parameters;

=head3 directories (optional)

This accepts either an array reference of directories to search, or a comma-separated string of directories to search (which will be converted to an array). When passed, this sets the internal list of directories to search. 

By default, it is set to all directories in C<< @INC >>, 'C<< path::directories::tools >> (our tools) and the C<< $ENV{'PATH'} >> variables, minus directories that don't actually exist. The returned array is sorted alphabetically.

=head3 initialize (optional)

If this is set, the list of directories to search will be set to 'C<< @INC >>' + 'C<< $ENV{'PATH'} >>' + 'C<< path::directories::tools >>'.

NOTE: You don't need to call this manually unless you want to reset the list. Invoking AN::Tools->new() causes this to be called automatically.

=cut 
sub search_directories
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# Set a default if nothing was passed.
	my $array      = defined $parameter->{directories} ? $parameter->{directories} : "";
	my $initialize = defined $parameter->{initialize}  ? $parameter->{initialize}  : "";
	
	# If the array is a CSV of directories, convert it now.
	if ($array =~ /,/)
	{
		# CSV, convert to an array.
		my @new_array = split/,/, $array;
		   $array     = \@new_array;
	}
	elsif (($initialize) or (($array) && (ref($array) ne "ARRAY")))
	{
		if (not $initialize)
		{
			# Not initializing and an array was passed that isn't.
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0031", variables => { array => $array }});
		}
		
		# Create a new array containing the '$ENV{'PATH'}' directories and the @INC directories.
		my @new_array = split/:/, $ENV{'PATH'} if $ENV{'PATH'} =~ /:/;
		foreach my $directory (@INC)
		{
			push @new_array, $directory;
		}
		
		# Add the tools directory
		push @new_array, $an->data->{path}{directories}{tools};
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
			next if not defined $directory;
			
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
	
	# Debug
	foreach my $directory (@{$self->{SEARCH_DIRECTORIES}})
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { directory => $directory }});
	}
	
	return ($self->{SEARCH_DIRECTORIES});
}

=head2 write_file

This writes out a file on the local system. It can optionally set the mode as well.

 $an->Storage->write_file({file => "/tmp/foo", body => "some data", mode => 0644});

If it fails to write the file, an alert will be logged.

Parameters;

=head3 body (optional)

This is the contents of the file. If it is blank, an empty file will be created (similar to using 'C<< touch >>' on the command line).

=head3 file (required)

This is the name of the file to write.

NOTE: The file must include the full directory it will be written into.

=head3 group (optional)

This is the group name or group ID to set the ownership of the file to.

=head3 mode (optional)

This is the numeric mode to set on the file. It expects four digits to cover the sticky bit, but will work with three digits.

=head3 overwrite (optional)

Normally, if the file already exists, it won't be overwritten. Setting this to 'C<< 1 >>' will cause the file to be overwritten.

=head3 user (optional)

This is the user name or user ID to set the ownership of the file to.

=cut
sub write_file
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $body      = defined $parameter->{body}      ? $parameter->{body}      : "";
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $group     = defined $parameter->{group}     ? $parameter->{group}     : "";
	my $mode      = defined $parameter->{mode}      ? $parameter->{mode}      : "";
	my $overwrite = defined $parameter->{overwrite} ? $parameter->{overwrite} : 0;
	my $user      = defined $parameter->{user}      ? $parameter->{user}      : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		body      => $body,
		file      => $file,
		group     => $group, 
		mode      => $mode,
		overwrite => $overwrite,
		user      => $user,
	}});
	
	my $error = 0;
	if ((-e $file) && (not $overwrite))
	{
		# Nope.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0040", variables => { file => $file }});
		$error = 1;
	}
	
	if ($file !~ /^\/\w/)
	{
		# Not a fully defined path, abort.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0041", variables => { file => $file }});
		$error = 1;
	}
	
	if (not $error)
	{
		# Break the directory off the file.
		my ($directory, $file_name) = ($file =~ /^(\/.*)\/(.*)$/);
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
			directory => $directory,
			file_name => $file_name,
		}});
		
		if (not -e $directory)
		{
			# Don't pass the mode as the file's mode is likely not executable.
			$an->Storage->make_directory({
				directory => $directory,
				group     => $group, 
				user      => $user,
			});
		}
		
		# Now write the file.
		my $shell_call = $file;
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0013", variables => { shell_call => $shell_call }});
		open (my $file_handle, ">", $shell_call) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0016", variables => { shell_call => $shell_call, error => $! }});
		print $file_handle $body;
		close $file_handle;
		
		if ($mode)
		{
			$an->Storage->change_mode({target => $file, mode => $mode});
		}
		if (($user) or ($group))
		{
			$an->Storage->change_owner({target => $file, user => $user, group => $group});
		}
	}
	
	return(0);
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

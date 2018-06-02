package Anvil::Tools::Storage;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Storage.pm";

### Methods;
# backup
# change_mode
# change_owner
# check_md5sums
# copy_file
# find
# make_directory
# read_config
# read_file
# read_mode
# record_md5sums
# rsync
# search_directories
# update_config
# write_file
# _create_rsync_wrapper

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Storage

Provides all methods related to storage on a system.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Storage->X'. 
 # 
 # Example using 'find()';
 my $foo_path = $anvil->Storage->find({file => "foo"});

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

# Get a handle on the Anvil::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	# Defend against memory leads. See Scalar::Util'.
	if (not isweak($self->{HANDLE}{TOOLS}))
	{
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 backup

This will create a copy of the file under the C<< path::directories::backups >> directory with the datestamp as a suffix. The path is preserved under the backup directory. The path and file name are returned.

By default, a failure to backup will be fatal with return code C<< 1 >> for safety reasons. If the file is critical, you can set C<< fatal => 0 >> and an empty string will be returned on error.

This method can work on local and remote systems.

If the backup failed, an empty string is returned.

Parameters;

=head3 fatal (optional, default 1)

If set to C<< 0 >>, any problem with the backup will be ignored and an empty string will be returned.

=head3 file (required)

This is the path and file name of the file to be backed up. Fully paths must be used.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 target (optional)

If set, the file will be backed up on the target machine. This must be either an IP address or a resolvable host name. 

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub backup
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 2;
	
	my $fatal       = defined $parameter->{fatal}       ? $parameter->{fatal}       : 1;
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $source_file = defined $parameter->{file}        ? $parameter->{file}        : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		fatal       => $fatal, 
		port        => $port, 
		password    => $anvil->Log->secure ? $password : "--", 
		target      => $target,
		remote_user => $remote_user, 
		source_file => $source_file,
	}});
	
	my $proceed = 0;
	my $target_file = "";
	if (not $source_file)
	{
		# No file passed in
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->backup()", parameter => "target" }});
		if ($fatal) { $anvil->nice_exit({code => 1}); }
	}
	elsif ($source_file !~ /^\//)
	{
		# Isn't a full path
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0150", variables => { source_file => $source_file }});
		if ($fatal) { $anvil->nice_exit({code => 1}); }
	}
	
	if ($target)
	{
		# Make sure the source file exists, is a file and can be read.
		my $shell_call = "
if [ -e '".$source_file."' ]; 
    if [ -f '".$source_file."' ];
    then
        if [ -r '".$source_file."' ];
        then
            ".$anvil->data->{path}{exe}{echo}." 'ok'
        else
            ".$anvil->data->{path}{exe}{echo}." 'not readable'
        fi
    else
        ".$anvil->data->{path}{exe}{echo}." 'not a file'
    fi
else
    ".$anvil->data->{path}{exe}{echo}." 'not found'
fi";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		my ($error, $output) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		if (not $error)
		{
			# No error. Did the file exist?
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'output->[0]' => $output->[0] }});
			if ($output->[0] eq "not found")
			{
				# File doesn't exist.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0151", variables => { source_file => $source_file }});
				if ($fatal) { $anvil->nice_exit({code => 1}); }
			}
			elsif ($output->[0] eq "not a file")
			{
				# Not a file
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0153", variables => { source_file => $source_file }});
				if ($fatal) { $anvil->nice_exit({code => 1}); }
			}
			elsif ($output->[0] eq "not readable")
			{
				# Can't read the file.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0152", variables => { source_file => $source_file }});
				if ($fatal) { $anvil->nice_exit({code => 1}); }
			}
			else
			{
				# We're good.
				$proceed = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { proceed => $proceed }});
			}
		}
		else
		{
			# Didn't connect?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0165", variables => { 
				target      => $target,
				source_file => $source_file,
			}});
			if ($fatal) { $anvil->nice_exit({code => 1}); }
		}
	}
	else
	{
		# Local file
		if (not -e $source_file)
		{
			# File doesn't exist.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0151", variables => { source_file => $source_file }});
			if ($fatal) { $anvil->nice_exit({code => 1}); }
		}
		elsif (not -f $source_file)
		{
			# Not a file
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0153", variables => { source_file => $source_file }});
			if ($fatal) { $anvil->nice_exit({code => 1}); }
		}
		elsif (not -r $source_file)
		{
			# Can't read the file.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0152", variables => { source_file => $source_file }});
			if ($fatal) { $anvil->nice_exit({code => 1}); }
		}
		else
		{
			$proceed = 1;
		}
	}
	
	# Proceed?
	if ($proceed)
	{
		# Proceed with the backup. We'll recreate the path 
		my ($directory, $file) = ($source_file =~ /^(\/.*)\/(.*)$/);
		my $timestamp          = $anvil->Get->date_and_time({file_name => 1});
		my $backup_directory   = $anvil->data->{path}{directories}{backups}.$directory;
		my $backup_target      = $file.".".$timestamp;
		   $target_file        = $backup_directory."/".$backup_target; 
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			directory        => $directory, 
			file             => $file, 
			timestamp        => $timestamp, 
			backup_directory => $backup_directory, 
			backup_target    => $backup_target, 
			target_file      => $target_file, 
		}});
		
		# Backup! It will create the target directory, if needed.
		my $failed = $anvil->Storage->copy_file({
			debug       => $debug,
			source_file => $source_file, 
			target_file => $target_file, 
			password    => $password, 
			target      => $target,
			remote_user => $remote_user, 
			source_file => $source_file,
		});
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
		if (not $failed)
		{
			# Log that the file was backed up.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0154", variables => { source_file => $source_file, target_file => $target_file }});
		}
		else
		{
			die;
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_file => $target_file }});
	return($target_file);
}
=cut

=head2 change_mode

This changes the mode of a file or directory.

 $anvil->Storage->change_mode({target => "/tmp/foo", mode => "0644"});

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
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $target = defined $parameter->{target} ? $parameter->{target} : "";
	my $mode   = defined $parameter->{mode}   ? $parameter->{mode}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target => $target,
		mode   => $mode,
	}});
	
	my $error = 0;
	if (not $target)
	{
		# No target...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->change_mode()", parameter => "target" }});
		$error = 1;
	}
	if (not $mode)
	{
		# No mode...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->change_mode()", parameter => "mode" }});
		$error = 1;
	}
	elsif (($mode !~ /^\d\d\d$/) && ($mode !~ /^\d\d\d\d$/))
	{
		# Invalid mode
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0038", variables => { mode => $mode }});
		$error = 1;
	}
	
	if (not $error)
	{
		my $shell_call = $anvil->data->{path}{exe}{'chmod'}." $mode $target";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0011", variables => { shell_call => $shell_call }});
		open (my $file_handle, $shell_call." 2>&1 |") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0017", variables => { line => $line }});
		}
		close $file_handle;
	}
	
	return(0);
}

=head2 change_owner

This changes the owner and/or group of a file or directory.

 $anvil->Storage->change_owner({target => "/tmp/foo", mode => "0644"});

If it fails to write the file, an alert will be logged and 'C<< 1 >>' will be returned. Otherwise, 'C<< 0 >>' will be returned.

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
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $target = defined $parameter->{target} ? $parameter->{target} : "";
	my $group  = defined $parameter->{group}  ? $parameter->{group}  : "";
	my $user   = defined $parameter->{user}   ? $parameter->{user}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		target => $target,
		group  => $group,
		user   => $user,
	}});
	
	# Make sure the user and group and just one digit or word.
	$user  =~ s/^(\S+)\s.*$/$1/;
	$group =~ s/^(\S+)\s.*$/$1/;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		group => $group, 
		user  => $user,
	}});
	
	my $string = "";
	my $error  = 0;
	if (not $target)
	{
		# No target...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->change_owner()", parameter => "target" }});
		$error = 1;
	}
	if (not -e $target)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0051", variables => {target => $target }});
		$error = 1;
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	if ($user ne "")
	{
		$string = $user;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { group => $group }});
	if ($group ne "")
	{
		$string .= ":".$group;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error, string => $string }});
	if ((not $error) && ($string ne ""))
	{
		my $shell_call = $anvil->data->{path}{exe}{'chown'}." $string $target";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0011", variables => { shell_call => $shell_call }});
		open (my $file_handle, $shell_call." 2>&1 |") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0017", variables => { line => $line }});
		}
		close $file_handle;
	}
	
	return($error);
}

=head2 check_md5sums

This is one half of a tool to let daemons detect when something they use has changed on disk and restart if any changes are found.

This checks the md5sum of the calling application and all perl modules that are loaded and compares them against the sums seem earlier via C<< record_md5sums >>. If any sums don't match, C<< 1 >> is returned. If no changes were seen, C<< 0 >> is returned.

=cut
sub check_md5sums
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# We'll set this if anything has changed.
	my $exit   = 0;
	my $caller = $0;
	
	# Have we changed?
	$anvil->data->{md5sum}{$caller}{now} = $anvil->Get->md5sum({file => $0});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"md5sum::${caller}::start_time" => $anvil->data->{md5sum}{$caller}{start_time},
		"md5sum::${caller}::now"        => $anvil->data->{md5sum}{$caller}{now},
	}});
	
	if ($anvil->data->{md5sum}{$caller}{now} ne $anvil->data->{md5sum}{$caller}{start_time})
	{
		# Exit.
		$exit = 1;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "warn", key => "message_0013", variables => { file => $0 }});
	}
	
	# What about our modules?
	foreach my $module (sort {$a cmp $b} keys %INC)
	{
		my $module_file = $INC{$module};
		my $module_sum  = $anvil->Get->md5sum({file => $module_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			module      => $module,
			module_file => $module_file, 
			module_sum  => $module_sum,
		}});
		
		$anvil->data->{md5sum}{$module_file}{now} = $module_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"md5sum::${module_file}::start_time" => $anvil->data->{md5sum}{$module_file}{start_time},
			"md5sum::${module_file}::now"        => $anvil->data->{md5sum}{$module_file}{now},
		}});
		if ($anvil->data->{md5sum}{$module_file}{start_time} ne $anvil->data->{md5sum}{$module_file}{now})
		{
			# Changed.
			$exit = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "warn", key => "message_0013", variables => { file => $module_file }});
		}
	}
	
	# Record sums for word files.
	foreach my $file (sort {$a cmp $b} keys %{$anvil->data->{words}})
	{
		my $words_sum = $anvil->Get->md5sum({file => $file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file      => $file,
			words_sum => $words_sum, 
		}});
		
		$anvil->data->{md5sum}{$file}{now} = $words_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"md5sum::${file}::start_time" => $anvil->data->{md5sum}{$file}{start_time}, 
			"md5sum::${file}::now"        => $anvil->data->{md5sum}{$file}{now}, 
		}});
		if ($anvil->data->{md5sum}{$file}{start_time} ne $anvil->data->{md5sum}{$file}{now})
		{
			$exit = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "warn", key => "message_0013", variables => { file => $file }});
		}
	}
	
	# Exit?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'exit' => $exit }});
	return($exit);
}

=head2 copy_file

This copies a file, with a few additional checks like creating the target directory if it doesn't exist, aborting if the file has already been backed up before, etc. It can copy files on the local or a remote machine.

 # Example
 $anvil->Storage->copy_file({source_file => "/some/file", target_file => "/another/directory/file"});

Returns C<< 0 >> on success, otherwise C<< 1 >>.

Parameters;

=head3 overwrite (optional)

If this is set to 'C<< 1 >>', and if the target file exists, it will be replaced.

If this is not passed and the target exists, this module will return 'C<< 3 >>'.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 source_file (required)

This is the source file. If it isn't specified, 'C<< 1 >>' will be returned. If it doesn't exist, this method will return 'C<< 4 >>'.

=head3 target (optional)

If set, the file will be copied on the target machine. This must be either an IP address or a resolvable host name. 

=head3 target_file (required)

This is the target B<< file >>, not the directory to put it in. The target file name can be different from the source file name.

if this is not specified, 'C<< 2 >>' will be returned.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub copy_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $overwrite   = defined $parameter->{overwrite}   ? $parameter->{overwrite}   : 0;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $source_file = defined $parameter->{source_file} ? $parameter->{source_file} : "";
	my $target_file = defined $parameter->{target_file} ? $parameter->{target_file} : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		overwrite   => $overwrite,
		password    => $anvil->Log->secure ? $password : "--", 
		remote_user => $remote_user, 
		source_file => $source_file, 
		target_file => $target_file,
		target      => $target,
	}});
	
	if (not $source_file)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->copy_file()", parameter => "source_file" }});
		return(1);
	}
	if (not $target_file)
	{
		# No target passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->copy_file()", parameter => "target_file" }});
		return(2);
	}
	
	my ($directory, $file) = ($target_file =~ /^(.*)\/(.*)$/);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		directory => $directory, 
		file      => $file,
	}});
	
	if ($target)
	{
		# Copying on a remote system.
		my $proceed    = 1;
		my $shell_call = "
if [ -e '".$source_file."' ]; 
    ".$anvil->data->{path}{exe}{echo}." 'source file exists'
else
    ".$anvil->data->{path}{exe}{echo}." 'source file not found'
fi
if [ -d '".$target_file."' ];
    ".$anvil->data->{path}{exe}{echo}." 'target file exists'
elif [ -d '".$directory."' ];
    ".$anvil->data->{path}{exe}{echo}." 'target directory exists'
else
    ".$anvil->data->{path}{exe}{echo}." 'target directory not found'
fi";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		my ($error, $output) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		if ($error)
		{
			# Something went wrong.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0169", variables => { 
				source_file => $source_file, 
				target_file => $target_file, 
				error       => $error,
				output      => $output,
				target      => $target, 
				remote_user => $remote_user, 
			}});
			return(1);
		}
		else
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				'output->[0]' => $output->[0],
				'output->[1]' => $output->[1],
			}});
			if ($output->[0] eq "source file not found")
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0052", variables => { source_file => $source_file }});
				return(1);
			}
			if (($output->[0] eq "source file exists") && (not $overwrite))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0046", variables => {
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
			if ($output->[1] eq "target directory not found")
			{
				my $failed = $anvil->Storage->make_directory({
					debug       => $debug,
					directory   => $directory,
					password    => $password, 
					remote_user => $remote_user, 
					target      => $target,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0170", variables => {
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
		
			# Now backup the file.
			my ($error, $output) = $anvil->Remote->call({
				debug       => $debug, 
				target      => $target,
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
				shell_call  => $anvil->data->{path}{exe}{'cp'}." -af ".$source_file." ".$target_file,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
		}
	}
	else
	{
		# Copying locally
		if (not -e $source_file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0052", variables => { source_file => $source_file }});
			return(1);
		}
		
		# If the target exists, abort
		if ((-e $target_file) && (not $overwrite))
		{
			# This isn't an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0046", variables => {
				source_file => $source_file,
				target_file => $target_file,
			}});
			return(1);
		}
		
		# Make sure the target directory exists and create it, if not.
		if (not -e $directory)
		{
			my $failed = $anvil->Storage->make_directory({
				debug     => $debug,
				directory => $directory,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
			if ($failed)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0170", variables => {
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
		}
		
		# Now backup the file.
		my $output = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'cp'}." -af ".$source_file." ".$target_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
	}
	
	return(0);
}

=head2 find

This searches for the given file on the system. It will search in the directories returned by C<< $anvil->Storage->search_directories() >>.

Example to search for 'C<< foo >>';

 $anvil->Storage->find({file => "foo"});

Same, but error out if the file isn't found.

 $anvil->Storage->find({
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
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 0;
	
	# WARNING: Don't call Log from here! It causes it to abort
	my $file  = defined $parameter->{file}  ? $parameter->{file}  : "";
	print $THIS_FILE." ".__LINE__."; [ Debug] - file: [$file]\n" if $debug;
	
	# Each full path and file name will be stored here before the test.
	my $full_path = "#!not_found!#";
	if ($file)
	{
		foreach my $directory (@{$anvil->Storage->search_directories()})
		{
			# If "directory" is ".", expand it.
			print $THIS_FILE." ".__LINE__."; [ Debug] - >> directory: [$directory]\n" if $debug;
			if (($directory eq ".") && ($ENV{PWD}))
			{
				$directory = $ENV{PWD};
				print $THIS_FILE." ".__LINE__."; [ Debug] - << directory: [$directory]\n" if $debug;
			}
			
			# Put together the initial path
			my $test_path = $directory."/".$file;
			print $THIS_FILE." ".__LINE__."; [ Debug] - >> test_path: [$test_path]\n" if $debug;

			# Clear double-delimiters.
			$test_path =~ s/\/+/\//g;
			print $THIS_FILE." ".__LINE__."; [ Debug] - << test_path: [$test_path]\n" if $debug;
			if (-f $test_path)
			{
				# Found it!
				$full_path = $test_path;
				print $THIS_FILE." ".__LINE__."; [ Debug] - >> full_path: [$full_path]\n" if $debug;
				last;
			}
		}
		print $THIS_FILE." ".__LINE__."; [ Debug] - << full_path: [$full_path]\n" if $debug;
	}
	
	# Return
	print $THIS_FILE." ".__LINE__."; [ Debug] - full_path: [$full_path]\n" if $debug;
	return ($full_path);
}

=head2 make_directory

This creates a directory (and any parent directories).

 $anvil->Storage->make_directory({directory => "/foo/bar/baz", owner => "me", grou[ => "me", group => 755});

If it fails to create the directory, C<< 1 >> will be returned. Otherwise, C<< 0 >> will be returned.

Parameters;

=head3 directory (required)

This is the name of the directory to create.

=head3 group (optional)

This is the group name or group ID to set the ownership of the directory to.

=head3 mode (optional)

This is the numeric mode to set on the file. It expects four digits to cover the sticky bit, but will work with three digits.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 target (optional)

If set, the directory will be created on this machine. This must be an IP address or a (resolvable) host name.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 user (optional)

This is the user name or user ID to set the ownership of the directory to.

=cut
sub make_directory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $directory   = defined $parameter->{directory}   ? $parameter->{directory}   : "";
	my $group       = defined $parameter->{group}       ? $parameter->{group}       : "";
	my $mode        = defined $parameter->{mode}        ? $parameter->{mode}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : "";
	my $failed      = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		directory   => $directory,
		group       => $group, 
		mode        => $mode,
		port        => $port, 
		password    => $anvil->Log->secure ? $password : "--", 
		remote_user => $remote_user, 
		target      => $target,
		user        => $user,
	}});
	
	# Make sure the user and group and just one digit or word.
	$user  =~ s/^(\S+)\s.*$/$1/;
	$group =~ s/^(\S+)\s.*$/$1/;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		group     => $group, 
		user      => $user,
	}});
	
	# Break the directories apart.
	my $working_directory = "";
	foreach my $this_directory (split/\//, $directory)
	{
		next if not $this_directory;
		$working_directory .= "/$this_directory";
		$working_directory =~ s/\/\//\//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { working_directory => $working_directory }});
		
		# Are we working locally or remotely?
		if ($target)
		{
			# Assemble the command
			my $shell_call = "
if [ -d '".$working_directory."' ];
then
   ".$anvil->data->{path}{exe}{echo}." 'exists'
else
   ".$anvil->data->{path}{exe}{'mkdir'}." $working_directory
";
			if ($mode)
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chmod'}." ".$mode."\n";
			}
			if (($user) && ($group))
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chown'}." ".$user.":".$group."\n";
			}
			elsif ($user)
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chown'}." ".$user.":\n";
			}
			elsif ($group)
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chown'}." :".$group."\n";
			}
			$shell_call .= "
    if [ -d '".$working_directory."' ];
    then
        ".$anvil->data->{path}{exe}{echo}." 'created'
    else
        ".$anvil->data->{path}{exe}{echo}." 'failed to create'
    fi;
fi;";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
			my ($error, $output) = $anvil->Remote->call({
				debug       => $debug, 
				target      => $target,
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
				shell_call  => $shell_call,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output, 
			}});
			if ($output->[0] eq "failed to create")
			{
				$failed = 1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0167", variables => { 
					directory   => $working_directory, 
					error       => $error,
					output      => $output,
					target      => $target, 
					remote_user => $remote_user, 
				}});
			}
		}
		else
		{
			# Locally.
			if (not -e $working_directory)
			{
				# Directory doesn't exist, so create it.
				my $error      = "";
				my $shell_call = $anvil->data->{path}{exe}{'mkdir'}." ".$working_directory;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0011", variables => { shell_call => $shell_call }});
				open (my $file_handle, $shell_call." 2>&1 |") or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0014", variables => { shell_call => $shell_call, error => $! }});
				while(<$file_handle>)
				{
					chomp;
					my $line = $_;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0017", variables => { line => $line }});
					$error .= $line."\n";
				}
				close $file_handle;
				
				if ($mode)
				{
					$anvil->Storage->change_mode({target => $working_directory, mode => $mode});
				}
				if (($user) or ($group))
				{
					$anvil->Storage->change_owner({target => $working_directory, user => $user, group => $group});
				}
				
				if (not -e $working_directory)
				{
					$failed = 1;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0168", variables => { 
						directory   => $working_directory, 
						error       => $error,
					}});
				}
			}
		}
		last if $failed;
	}
	
	return($failed);
}

=head2 read_config

This method is used to read 'Anvil::Tools' style configuration files. These configuration files are in the format:

 # This is a comment for the 'a::b::c' variable
 a::b::c = x

A configuration file can be read in like this;

 $anvil->Storage->read_config({file => "test.conf"});

In this example, the file 'C<< test.conf >>' will be searched for in the directories returned by 'C<< $anvil->Storage->search_directories >>'. 

Any line starting with '#' is a comment and is ignored. Preceding white spaces are allowed and also ignored.

Any line in the format 'x = y' is treated as a variable / value pair, split on the first 'C<< = >>'. Whitespaces on either side of the 'C<< = >>' are removed and ignored. However, anything after the first non-whitespace character is treated as data an unmolested. This includes addition 'C<< = >>' characters, white spaces and so on. The exception is that trailing white spaces are cropped and ignored. If nothing comes after the 'C<< = >>', the variable is set to a blank string.

Successful read will return 'C<< 0 >>'. Non-0 is an error;
C<< 0 >> = OK
C<< 1 >> = Invalid or missing file name
C<< 2 >> = File not found
C<< 3 >> = File not readable

Parameters;

=head3 file (optional, default file stored in 'path::configs::anvil.conf')

This is the configuration file to read. 

If the 'C<< file >>' parameter starts with 'C<< / >>', the exact path to the file is used. Otherwise, this method will search for the file in the list of directories returned by 'C<< $anvil->Storage->search_directories >>'. The first match is read in.

All variables are stored in the root of 'C<< $anvil->data >>', allowing for configuration files to override internally set variables.

For example, if you set:
 
 $anvil->data->{a}{b}{c} = "1";

Then you read in a config file with:

 a::b::c = x

Then 'C<< $anvil->data->{a}{b}{c} >>' will now contain 'C<< x >>'.

=cut
sub read_config
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Setup default values
	my $file        = defined $parameter->{file} ? $parameter->{file} : $anvil->data->{path}{configs}{'anvil.conf'};
	my $return_code = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
	
	if (not $file)
	{
		# No file to read
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0164"});
		$return_code = 1;
	}
	
	# If I have a file name that isn't a full path, find it.
	if (($file) && ($file !~ /^\//))
	{
		# Find the file, if possible. If not found, we'll not alter what the user passed in and hope
		# it is relative to where we are.
		my $path = $anvil->Storage->find({ file => $file });
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { path => $path }});
		if ($path ne "#!not_found!#")
		{
			# Update the file
			$file = $path;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
		}
	}
	
	if ($file)
	{
		if (not -e $file)
		{
			# The file doesn't exist
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0033", variables => { file => $file }});
			$return_code = 2;
		}
		elsif (not -r $file)
		{
			# The file can't be read
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0034", variables => { 
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
			my $body  = $anvil->Storage->read_file({file => $file});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
			foreach my $line (split/\n/, $body)
			{
				$line = $anvil->Words->clean_spaces({ string => $line });
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
				$count++;
				
				# Skip empty lines and lines that start with a '#', and lines without an '='.
				next if ((not $line) or ($line =~ /^#/));
				next if $line !~ /=/;
				my ($variable, $value) = split/=/, $line, 2;
				$variable =~ s/\s+$//;
				$value    =~ s/^\s+//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:variable" => $variable,
					"s2:value"    => $value, 
				}});
				if (not $variable)
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0035", variables => { 
						file  => $file,
						count => $count,
						line  => $line,
					}});
				}
				
				$anvil->_make_hash_reference($anvil->data, $variable, $value);
			}
		}
	}
	
	return($return_code);
}

=head2 read_file

This reads in a file and returns the contents of the file as a single string variable.

 my $body = $anvil->Storage->read_file({file => "/tmp/foo"});

If it fails to find the file, or the file is not readable, 'C<< !!error!! >>' is returned.

Parameters;

=head3 cache (optional)

This is an optional parameter that controls whether the file is cached in case something else tries to read the same file later. By default, all read files are cached. Set this to C<< 0 >> to disable caching. This should only be needed when reading large files.

=head3 file (required)

This is the name of the file to read. When reading from a remote machine, it must be a full path and file name.

=head3 force_read (optional)

This is an otpional parameter that, if set, forces the file to be read, bypassing cache if it exists. Set this to C<< 1 >> to bypass the cache.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 secure (optional, default 0)

If set to C<< 1 >>, the body of the read file will be treated as sensitive from a logging perspective.

=head3 target (optional)

If set, the file will be read from the target machine. This must be either an IP address or a resolvable host name. 

The file will be copied to the local system using C<< $anvil->Storage->rsync() >> and stored in C<< /tmp/<file_path_and_name>.<target> >>. if C<< cache >> is set, the file will be preserved locally. Otherwise it will be deleted once it has been read into memory.

B<< Note >>: the temporary file will be prefixed with the path to the file name, with the C<< / >> converted to C<< _ >>.

=cut
sub read_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $body        = "";
	my $cache       = defined $parameter->{cache}       ? $parameter->{cache}       : 1;
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $force_read  = defined $parameter->{force_read}  ? $parameter->{force_read}  : 0;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "";
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : 0;
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		cache       => $cache, 
		file        => $file,
		force_read  => $force_read, 
		port        => $port, 
		password    => $anvil->Log->secure ? $password : "--", 
		remote_user => $remote_user, 
		secure      => $secure, 
		target      => $target,
	}});
	
	if (not $file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->read_file()", parameter => "file" }});
		return("!!error!!");
	}
	
	# Reading locally or remote?
	if ($target)
	{
		# Remote. Make sure the passed file is a full path and file name.
		if ($file !~ /^\/\w/)
		{
			# Not a fully defined path, abort.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0160", variables => { file => $file }});
			return("!!error!!");
		}
		if ($file =~ /\/$/)
		{
			# The file name is missing.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0161", variables => { file => $file }});
			return("!!error!!");
		}
		
		# Setup the temp file name.
		my $temp_file =  $file;
		   $temp_file =~ s/\//_/g;
		   $temp_file =~ s/^_//g;
		   $temp_file =  "/tmp/".$temp_file.".".$target;
		   $temp_file =~ s/\s+/_/g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temp_file => $temp_file }});
		
		# If the temp file exists and 'force_read' is set, remove it.
		if (($force_read) && (-e $temp_file))
		{
			unlink $temp_file;
		}
		
		# Do we have this cached?
		if ((exists $anvil->data->{cache}{file}{$temp_file}) && (not $force_read))
		{
			# Use the cache
			$body = $anvil->data->{cache}{file}{$temp_file};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
		}
		else
		{
			# Read from the target by rsync'ing the file here.
			my $failed = $anvil->Storage->rsync({
				debug       => $debug, 
				destination => $temp_file,
				password    => $password, 
				port        => $port, 
				source      => $remote_user."\@".$target.":".$file,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
			
			if (-e $temp_file)
			{
				# Got it! read it in.
				my $shell_call = $temp_file;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0012", variables => { shell_call => $shell_call }});
				open (my $file_handle, "<", $shell_call) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0015", variables => { shell_call => $shell_call, error => $! }});
				while(<$file_handle>)
				{
					chomp;
					my $line = $_;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0023", variables => { line => $line }});
					$body .= $line."\n";
				}
				close $file_handle;
				$body =~ s/\n$//s;
				
				if ($cache)
				{
					$anvil->data->{cache}{file}{$temp_file} = $body;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::file::${temp_file}" => $anvil->data->{cache}{file}{$temp_file} }});
				}
				
				# Remove the temp file.
				unlink $temp_file;
			}
			else
			{
				# Something went wrong...
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0162", variables => { 
					remote_file => $remote_user."\@".$target.$file,
					local_file  => $temp_file, 
				}});
				return("!!error!!");
			}
		}
	}
	else
	{
		# Local
		if (not -e $file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0021", variables => { file => $file }});
			return("!!error!!");
		}
		elsif (not -r $file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0022", variables => { file => $file }});
			return("!!error!!");
		}
		
		# If I've read this before, don't read it again.
		if ((exists $anvil->data->{cache}{file}{$file}) && (not $force_read))
		{
			# Use the cache
			$body = $anvil->data->{cache}{file}{$file};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
		}
		else
		{
			# Read from disk.
			my $shell_call = $file;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0012", variables => { shell_call => $shell_call }});
			open (my $file_handle, "<", $shell_call) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0015", variables => { shell_call => $shell_call, error => $! }});
			while(<$file_handle>)
			{
				chomp;
				my $line = $_;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0023", variables => { line => $line }});
				$body .= $line."\n";
			}
			close $file_handle;
			$body =~ s/\n$//s;
			
			if ($cache)
			{
				$anvil->data->{cache}{file}{$file} = $body;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::file::${file}" => $anvil->data->{cache}{file}{$file} }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
	return($body);
}

=head2 read_mode

This reads a file or directory's mode (sticky-bit and ownership) and returns the mode as a four-digit string (ie: 'c<< 0644 >>', 'C<< 4755 >>', etc.

 my $mode = $anvil->Storage->read_mode({file => "/tmp/foo"});

If it fails to find the file, or the file is not readable, 'C<< 0 >>' is returned.

Parameters;

=head3 file (required)

This is the name of the file or directory to check the mode of.

=cut
sub read_mode
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 1;
	
	my $target = defined $parameter->{target} ? $parameter->{target} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target => $target }});
	
	if (not $target)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->read_mode()", parameter => "target" }});
		return(1);
	}
	
	# Read the mode and convert it to digits.
	my $mode = (stat($target))[2];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mode => $mode }});
	
	# Return the full mode, unless it is a directory or file. In those cases, return the last four digits.
	my $say_mode = $mode;
	if (-d $target)
	{
		# Directory - five digits
		$say_mode =  sprintf("%04o", $mode);
		$say_mode =~ s/^\d(\d\d\d\d)$/$1/;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_mode => $say_mode }});
	}
	elsif (-f $target)
	{
		# File - six digits
		$say_mode =  sprintf("%04o", $mode);
		$say_mode =~ s/^\d\d(\d\d\d\d)$/$1/;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { say_mode => $say_mode }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mode => $mode, say_mode => $say_mode }});
	return($say_mode);
}

=head2 record_md5sums

This is one half of a tool to let daemons detect when something they use has changed on disk and restart if any changes are found.

This records the md5sum of the calling application and all perl modules that are loaded. The values stored here will be compared against C<< check_md5sums >> later.

=cut
sub record_md5sums
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $caller = $0;
	$anvil->data->{md5sum}{$caller}{start_time} = $anvil->Get->md5sum({file => $0});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "md5sum::${caller}::start_time" => $anvil->data->{md5sum}{$caller}{start_time} }});
	foreach my $module (sort {$a cmp $b} keys %INC)
	{
		my $module_file = $INC{$module};
		my $module_sum  = $anvil->Get->md5sum({file => $module_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			module      => $module,
			module_file => $module_file, 
			module_sum  => $module_sum,
		}});
		
		$anvil->data->{md5sum}{$module_file}{start_time} = $module_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "md5sum::${module_file}::start_time" => $anvil->data->{md5sum}{$module_file}{start_time} }});
	}
	
	# Record sums for word files.
	foreach my $file (sort {$a cmp $b} keys %{$anvil->data->{words}})
	{
		my $words_sum = $anvil->Get->md5sum({file => $file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file      => $file,
			words_sum => $words_sum, 
		}});
		
		$anvil->data->{md5sum}{$file}{start_time} = $words_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "md5sum::${file}::start_time" => $anvil->data->{md5sum}{$file}{start_time} }});
	}
	
	return(0);
}

=head2 rsync

This method copies a file or directory (and its contents) to a remote machine using C<< rsync >> and an C<< expect >> wrapper.

This supports the source B<< or >> the destination being remote, so the C<< source >> or C<< destination >> paramter can be in the format C<< <remote_user>@<target>:/file/path >>. If neither parameter is remove, a local C<< rsync >> operation will be performed.

On success, C<< 0 >> is returned. If a problem arises, C<< 1 >> is returned.

B<< NOTE >>: This method does not take C<< remote_user >> or C<< target >>. These are parsed off the C<< source >> or C<< destination >> parameter.

Parameters;

=head3 destination (required)

This is the source being copied. Be careful with the closing C<< / >>! Generally you will always want to have the destination end in a closing slash, to ensure the files go B<< under >> the estination directory. The same as is the case when using C<< rsync >> directly.

=head3 password (optional)

This is the password used to connect to the target machine (if either the source or target is remote).

=head3 port (optional, default 22)

This is the TCP port used to connect to the target machine.

=head3 source (required)

The source can be a directory, or end in a wildcard (ie: C<< .../* >>) to copy multiple files/directories at the same time.

=head3 switches (optional, default -av)

These are the switches to pass to C<< rsync >>. If you specify this and you still want C<< -avS >>, be sure to include it. This parameter replaces the default.

B<< NOTE >>: If C<< port >> is specified, C<< -e 'ssh -p <port> >> will be appended automatically, so you do not need to specify this.

=head3 try_again (optional, default 1)

If this is set to C<< 1 >>, and if a conflict is found with the SSH RSA key (C<< Offending key in... >> error) when trying the C<< rsync >> call, the offending key will be removed and a second attempt will be made. On the second attempt, this is set to C<< 0 >> to prevent a recursive loop if the removal fails.

B<< NOTE >>: This is the default to better handle a rebuilt node, dashboard or DR machine. Of course, this is a possible security problem so please consider it's use on a case by case basis.

=cut
### TODO: Make is so that if both the source and destination are remote, we setup to copy from the source to 
###       the destination (or ping via us, would be easier but possibly slower if we're remote).
sub rsync
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Check my parameters.
	my $destination = defined $parameter->{destination} ? $parameter->{destination} : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $source      = defined $parameter->{source}      ? $parameter->{source}      : "";
	my $switches    = defined $parameter->{switches}    ? $parameter->{switches}    : "-avS";
	my $try_again   = defined $parameter->{try_again}   ? $parameter->{try_again}   : 1;
	my $remote_user = "";
	my $target      = "";
	my $failed      = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		destination => $destination,
		password    => $anvil->Log->secure ? $password : "--", 
		port        => $port, 
		source      => $source,
		switches    => $switches,
		try_again   => $try_again, 
	}});
	
	# Add an argument for the port if set
	if ($port ne "22")
	{
		$switches .= " -e 'ssh -p $port'";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { switches => $switches }});
	}
	
	# Make sure I have everything I need.
	if (not $source)
	{
		# No source
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->rsync()", parameter => "source" }});
		return(1);
	}
	if (not $destination)
	{
		# No destination
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->rsync()", parameter => "destination" }});
		return(1);
	}
	
	# If either the source or destination is remote, we need to make sure we have the remote machine in
	# the current user's ~/.ssh/known_hosts file.
	if ($source =~ /^(.*?)@(.*?):/)
	{
		$remote_user = $1;
		$target      = $2;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
			remote_user => $remote_user,
			target      => $target, 
		}});
	}
	elsif ($destination =~ /^(.*?)@(.*?):/)
	{
		$remote_user = $1;
		$target      = $2;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
			remote_user => $remote_user,
			target      => $target, 
		}});
	}
	
	# If local, call rsync directly. If remote, setup the rsync wrapper
	my $wrapper_script = "";
	my $shell_call     = $anvil->data->{path}{exe}{rsync}." ".$switches." ".$source." ".$destination;
	if ($target)
	{
		# If we didn't get a port, but the target is pre-configured for a port, use it.
		if ((not $parameter->{port}) && ($anvil->data->{hosts}{$target}{port}))
		{
			$port = $anvil->data->{hosts}{$target}{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { port => $port }});
		}
		
		# Make sure we know the fingerprint of the remote machine
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0158", variables => { target => $target, user => $< }});
		$anvil->Remote->add_target_to_known_hosts({
			debug  => $debug, 
			target => $target, 
			user   => $<,
		});
		
		# Remote target, wrapper needed.
		$wrapper_script = $anvil->Storage->_create_rsync_wrapper({
			target   => $target,
			password => $password, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { wrapper_script => $wrapper_script }});
		
		# And make the shell call
		$shell_call = $wrapper_script." ".$switches." ".$source." ".$destination;
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { shell_call => $shell_call }});
	
	# Now make the call (this exposes the password so 'secure' is set).
	my $conflict = "";
	my $output   = $anvil->System->call({secure => 1, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { output => $output }});
	foreach my $line (split/\n/, $output)
	{
		# This exposes the password on the 'password: ' line.
		my $secure = $line =~ /password/i ? 1 : 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { line => $line }});
		
		if ($line =~ /Offending key in (\/.*\/).ssh\/known_hosts:(\d+)$/)
		{
			### TODO: I'm still mixed on taking this behaviour... a trade off between useability
			###       and security... As of now, the logic for doing it is that the BCN should
			###       be isolated and secured so favour usability.
			# Need to delete the old key or warn the user.
			my $path        = $1;
			my $line_number = $2;
			   $failed      = 1;
			my $source      = $path.".ssh\/known_hosts";
			my $destination = $path."known_hosts.".$anvil->Get->date_and_time({file_name => 1});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				path        => $path, 
				line_number => $line_number, 
				failed      => $failed, 
				source      => $source, 
				destination => $destination, 
			}});
			
			if ($line_number)
			{
				$conflict = $anvil->data->{path}{exe}{cp}." ".$source." ".$destination." && ".$anvil->data->{path}{exe}{sed}." -ie '".$line_number."d' ".$source;
			}
		}
	}
	
	# If there was a conflict, clear it and try again.
	if (($conflict) && ($try_again))
	{
		# Remove the conflicting fingerprint.
		my $output = $anvil->System->call({shell_call => $conflict});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
		foreach my $line (split/\n/, $output)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		}
		
		# Try again.
		$failed = $anvil->Storage->rsync({
			destination => $destination,
			password    => $password, 
			port        => $port, 
			source      => $source,
			switches    => $switches,
			try_again   => 0, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
	}
	
	# Clean up the rsync wrapper, if appropriate.
	if (($wrapper_script) && (-e $wrapper_script))
	{
		unlink $wrapper_script;
	}
	
	return($failed);
}

=head2 search_directories

This method returns an array reference of directories to search within for files and directories.

Parameters;

=head3 directories (optional)

This accepts either an array reference of directories to search, or a comma-separated string of directories to search (which will be converted to an array). When passed, this sets the internal list of directories to search. 

By default, it is set to all directories in C<< @INC >>, 'C<< path::directories::tools >> (our tools) and the C<< $ENV{'PATH'} >> variables, minus directories that don't actually exist. The returned array is sorted alphabetically.

=head3 initialize (optional)

If this is set, the list of directories to search will be set to 'C<< @INC >>' + 'C<< $ENV{'PATH'} >>' + 'C<< path::directories::tools >>'.

NOTE: You don't need to call this manually unless you want to reset the list. Invoking Anvil::Tools->new() causes this to be called automatically.

=cut 
sub search_directories
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
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
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0031", variables => { array => $array }});
		}
		
		# Create a new array containing the '$ENV{'PATH'}' directories and the @INC directories.
		my @new_array = split/:/, $ENV{'PATH'} if $ENV{'PATH'} =~ /:/;
		foreach my $directory (@INC)
		{
			push @new_array, $directory;
		}
		
		# Add the tools directory
		push @new_array, $anvil->data->{path}{directories}{tools};
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
				# When run from systemd, there is no PWD environment variable, so we'll do a system call.
				if ($ENV{PWD})
				{
					$directory = $ENV{PWD};
				}
				else
				{
					# pwd returns '/', which isn't helpful, so we'll skip this.
					next;
				}
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
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { directory => $directory }});
	}
	
	return ($self->{SEARCH_DIRECTORIES});
}

=head2 update_config

This takes a variable name and value and updates the C<< path::configs::anvil.conf >> file. If the given variable is already set to the requested value, nothing further is done.

Returns C<< 0 >> on success, C<< 1 >> on error.

B<< Note >>: If the variable is not found, it is treated like an error and C<< 1 >> is returned.

Parameters;

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 secure (optional)

If set to 'C<< 1 >>', the value is treated as containing secure data for logging purposes.

=head3 target (optional)

If set, the config file will be updated on the target machine. This must be either an IP address or a resolvable host name. 

=head3 variable (required)

This is the C<< a::b::c >> format variable name to update.

=head3 value (optional)

This is the value to set the C<< variable >> to. If this is not passed, the variable will be set to an empty string.

The updated config file will be written locally in C<< /tmp/<file_name> >>, C<< $anvil->Storage->rsync() >> will be used to copy the file, and finally the local temprary copy will be removed.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub update_config
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $variable    = defined $parameter->{variable}    ? $parameter->{variable}    : "";
	my $value       = defined $parameter->{value}       ? $parameter->{value}       : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $seen        = 0;
	my $update      = 0;
	my $new_file    = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		password    => $anvil->Log->secure ? $password : "--", 
		port        => $port, 
		secure      => $secure,
		target      => $target,
		value       => ((not $secure) or ($anvil->Log->secure)) ? $value : "--",
		variable    => $variable, 
		remote_user => $remote_user, 
	}});
	
	if (not $variable)
	{
		# No source
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->update_config()", parameter => "variable" }});
		return(1);
	}
	
	# Read in the config file.
	my $body = $anvil->Storage->read_file({
		debug       => $debug,
		file        => $anvil->data->{path}{configs}{'anvil.conf'}, 
		password    => $password, 
		port        => $port, 
		target      => $target, 
		remote_user => $remote_user, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
	foreach my $line (split/\n/, $body)
	{
		my $original_line =  $line;
		   $line          =~ s/#.*$//;
		   $line          =~ s/^\s+//;
		   
		if ($line =~ /^(.*?)=(.*)$/)
		{
			my $this_variable =  $1;
			my $this_value    =  $2;
			   $this_variable =~ s/\s+$//;
			   $this_value    =~ s/^\s+//;
			my $is_secure     =  $this_variable =~ /passw/i ? 1 : 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
				this_variable => $this_variable,
				this_value    => ((not $is_secure) or ($anvil->Log->secure)) ? $this_value : "--",
			}});
			if ($this_variable eq $variable)
			{
				$seen = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { seen => $seen }});
				if ($this_value ne $value)
				{
					$update =  1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { update => $update }});
					
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { ">> original_line" => $original_line }});
					$original_line =~ s/$this_value/$value/;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { "<< original_line" => $original_line }});
				}
			}
		}
		$new_file .= $original_line."\n";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { new_file => $new_file }});
	
	# Did we see the variable?
	if (not $seen)
	{
		if ($target)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0175", variables => { 
				variable => $variable, 
				file     => $anvil->data->{path}{configs}{'anvil.conf'}, 
				target   => $target,
			}});
			return(1);
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0174", variables => { 
				variable => $variable, 
				file     => $anvil->data->{path}{configs}{'anvil.conf'}, 
			}});
			return(1);
		}
	}
	
	# Do we need to update the file?
	my $error = 0;
	if ($update)
	{
		# Yup!
		$error = $anvil->Storage->write_file({
			body        => $new_file,
			debug       => $debug,
			file        => $anvil->data->{path}{configs}{'anvil.conf'},
			group       => "apache", 
			mode        => "0640",
			overwrite   => 1,
			secure      => 1,
			user        => "apache",
			password    => $password, 
			port        => $port, 
			target      => $target, 
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { error => $error }});
	}
	
	return($error);
}

=head2 write_file

This writes out a file, either locally or on a remote system. It can optionally set the ownership and mode as well.

 $anvil->Storage->write_file({
 	file  => "/tmp/foo", 
 	body  => "some data", 
 	user  => "admin", 
 	group => "admin", 
 	mode  => "0644",
 });

Returns C<< 0 >> on success. C<< 1 >> or an error string will be returned otherwise.

Parameters;

=head3 body (optional)

This is the contents of the file. If it is blank, an empty file will be created (similar to using 'C<< touch >>' on the command line).

=head3 file (required)

This is the name of the file to write.

NOTE: The file must include the full directory it will be written into.

=head3 group (optional)

This is the group name or group ID to set the ownership of the file to.

=head3 mode (optional)

This is the B<< quoted >> numeric mode to set on the file. It expects four digits to cover the sticky bit, but will work with three digits.

=head3 overwrite (optional)

Normally, if the file already exists, it won't be overwritten. Setting this to 'C<< 1 >>' will cause the file to be overwritten.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 secure (optional)

If set to 'C<< 1 >>', the body is treated as containing secure data for logging purposes.

=head3 target (optional)

If set, the file will be written on the target machine. This must be either an IP address or a resolvable host name. 

The file will be written locally in C<< /tmp/<file_name> >>, C<< $anvil->Storage->rsync() >> will be used to copy the file, and finally the local temprary copy will be removed.

=head3 user (optional)

This is the user name or user ID to set the ownership of the file to.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub write_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $body        = defined $parameter->{body}        ? $parameter->{body}        : "";
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $group       = defined $parameter->{group}       ? $parameter->{group}       : "";
	my $mode        = defined $parameter->{mode}        ? $parameter->{mode}        : "";
	my $overwrite   = defined $parameter->{overwrite}   ? $parameter->{overwrite}   : 0;
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : "root";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $error       = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		body        => $body,
		file        => $file,
		group       => $group, 
		mode        => $mode,
		overwrite   => $overwrite,
		port        => $port, 
		password    => $anvil->Log->secure ? $password : "--", 
		secure      => $secure,
		target      => $target,
		user        => $user,
		remote_user => $remote_user, 
	}});
	
	# Make sure the user and group and just one digit or word.
	$user  =~ s/^(\S+)\s.*$/$1/;
	$group =~ s/^(\S+)\s.*$/$1/;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		group     => $group, 
		user      => $user,
	}});
	
	
	# Make sure the passed file is a full path and file name.
	if ($file !~ /^\/\w/)
	{
		# Not a fully defined path, abort.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0041", variables => { file => $file }});
		$error = 1;
	}
	if ($file =~ /\/$/)
	{
		# The file name is missing.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0157", variables => { file => $file }});
		$error = 1;
	}
	
	# Break the directory off the file.
	my ($directory, $file_name) = ($file =~ /^(\/.*)\/(.*)$/);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		directory => $directory,
		file_name => $file_name,
	}});
	
	# Now, are we writing locally or on a remote system?
	if ($target)
	{
		# If we didn't get a port, but the target is pre-configured for a port, use it.
		if ((not $parameter->{port}) && ($anvil->data->{hosts}{$target}{port}))
		{
			$port = $anvil->data->{hosts}{$target}{port};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { port => $port }});
		}
		
		# Remote. See if the file exists on the remote system (and that we can connect to the remote 
		# system).
		my $shell_call = "
if [ -e '".$file."' ]; 
then
    ".$anvil->data->{path}{exe}{echo}." 'exists'; 
else 
    ".$anvil->data->{path}{exe}{echo}." 'not found';
fi";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		($error, my $output) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		if (not $error)
		{
			# No error. Did the file exist?
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'output->[0]' => $output->[0] }});
			if ($output->[0] eq "exists")
			{
				if (not $overwrite)
				{
					# Abort, we're not allowed to overwrite.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0040", variables => { file => $file }});
					$error = 1;
				}
			}
			else
			{
				# Back it up.
				my $backup_file = $anvil->Storage->backup({
					file       => $file,
					debug      => $debug, 
					target     => $target,
					port       => $port, 
					user       => $remote_user, 
					password   => $password,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { backup_file => $backup_file }});
			}
			
			# Make sure the directory exists on the remote machine. In this case, we'll use 'mkdir -p' if it isn't.
			if (not $error)
			{
				my $shell_call = "
if [ -d '".$directory."' ]; 
then
    ".$anvil->data->{path}{exe}{echo}." 'exists'; 
else 
    ".$anvil->data->{path}{exe}{echo}." 'not found';
fi";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
				($error, my $output) = $anvil->Remote->call({
					debug       => $debug, 
					target      => $target,
					user        => $remote_user, 
					password    => $password,
					remote_user => $remote_user, 
					shell_call  => $shell_call,
				});
				
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'output->[0]' => $output->[0] }});
				if ($output->[0] eq "not found")
				{
					# Create the directory
					my $shell_call = $anvil->data->{path}{exe}{'mkdir'}." -p ".$directory;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
					($error, my $output) = $anvil->Remote->call({
						debug       => $debug, 
						target      => $target,
						user        => $remote_user, 
						password    => $password,
						remote_user => $remote_user, 
						shell_call  => $shell_call,
					});
				}
				
				if (not $error)
				{
					# OK, now write the file locally, then we'll rsync it over.
					my $temp_file =  $file;
					   $temp_file =~ s/\//_/g;
					   $temp_file =~ s/^_//g;
					   $temp_file = "/tmp/".$temp_file;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temp_file => $temp_file }});
					$anvil->Storage->write_file({
						body      => $body,
						debug     => $debug,
						file      => $temp_file,
						group     => $group, 
						mode      => $mode,
						overwrite => 1,
						secure    => $secure,
						user      => $user,
					});
					
					# Now rsync it.
					if (-e $temp_file)
					{
						my $failed = $anvil->Storage->rsync({
							debug       => $debug, 
							destination => $remote_user."\@".$target.":".$file,
							password    => $password, 
							port        => $port, 
							source      => $temp_file,
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
						
						# Unlink 
						unlink $temp_file;
					}
					else
					{
						# Something went wrong writing it.
						$error = 1;
					}
				}
			}
		}
	}
	else
	{
		# Local
		if ((-e $file) && (not $overwrite))
		{
			# Nope.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0040", variables => { file => $file }});
			$error = 1;
		}
		
		if (not $error)
		{
			if (not -e $directory)
			{
				# Don't pass the mode as the file's mode is likely not executable.
				$anvil->Storage->make_directory({
					debug     => $debug, 
					directory => $directory,
					group     => $group, 
					user      => $user,
				});
			}
			
			# If 'secure' is set, the file will probably contain sensitive data so touch the file and set
			# the mode before writing it.
			if ($secure)
			{
				my $shell_call = $anvil->data->{path}{exe}{touch}." ".$file;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
				
				$anvil->System->call({shell_call => $shell_call});
				$anvil->Storage->change_mode({target => $file, mode => $mode});
			}
			
			# Now write the file.
			my $shell_call = $file;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, key => "log_0013", variables => { shell_call => $shell_call }});
			open (my $file_handle, ">", $shell_call) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => $secure, priority => "err", key => "log_0016", variables => { shell_call => $shell_call, error => $! }});
			print $file_handle $body;
			close $file_handle;
			
			if ($mode)
			{
				$anvil->Storage->change_mode({target => $file, mode => $mode});
			}
			if (($user) or ($group))
			{
				$anvil->Storage->change_owner({target => $file, user => $user, group => $group});
			}
		}
	}
	
	return($error);
}


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2

This does the actual work of creating the C<< expect >> wrapper script and returns the path to that wrapper for C<< rsync >> calls.

If there is a problem, an empty string will be returned.

Parameters;

=head3 target (required)

This is the IP address or (resolvable) hostname of the remote machine.

=head3 password (required)

This is the password of the user you will be connecting to the remote machine as.

=cut
sub _create_rsync_wrapper
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Check my parameters.
	my $target   = defined $parameter->{target}   ? $parameter->{target}   : "";
	my $password = defined $parameter->{password} ? $parameter->{password} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		password => $anvil->Log->secure ? $password : "--", 
		target   => $target, 
	}});
	
	if (not $target)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->_create_rsync_wrapper()", parameter => "target" }});
		return("");
	}
	if (not $password)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->_create_rsync_wrapper()", parameter => "password" }});
		return("");
	}
	
	### NOTE: The first line needs to be the '#!...' line, hence the odd formatting below.
	my $timeout        = 3600;
	my $wrapper_script = "/tmp/rsync.$target";
	my $wrapper_body   = "#!".$anvil->data->{path}{exe}{expect}."
set timeout ".$timeout."
eval spawn rsync \$argv
expect \"password:\" \{ send \"".$password."\\n\" \}
expect eof
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		wrapper_script => $wrapper_script, 
		wrapper_body   => $wrapper_body, 
	}});
	$anvil->Storage->write_file({
		body      => $wrapper_body,
		debug     => $debug,
		file      => $wrapper_script,
		mode      => "0700",
		overwrite => 1,
		secure    => 1,
	});
	
	if (not -e $wrapper_script)
	{
		# Failed!
		$wrapper_script = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { wrapper_script => $wrapper_script }});
	}
	
	return($wrapper_script);
}

1;

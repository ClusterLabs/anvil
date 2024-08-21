package Anvil::Tools::Storage;
# 
# This module contains methods used to handle storage related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use File::MimeInfo;
use JSON;
use Scalar::Util qw(weaken isweak);
use Text::Diff;
use utf8;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Storage.pm";

### Methods;
# auto_grow_pv
# backup
# change_mode
# change_owner
# check_files
# check_md5sums
# compress
# copy_file
# copy_device
# delete_file
# find
# get_file_stats
# get_size_of_block_device
# get_storage_group_details
# get_storage_group_from_path
# get_vg_name
# make_directory
# manage_lvm_conf
# move_file
# parse_df
# parse_lsblk
# push_file
# read_config
# read_file
# read_mode
# record_md5sums
# rsync
# scan_directory
# search_directories
# update_config
# update_file
# write_file
# _create_rsync_wrapper
# _wait_if_changing

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
		SEARCH_DIRECTORIES => \@INC,
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
		weaken($self->{HANDLE}{TOOLS});
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################


=head2 auto_grow_pv

This looks at LVM PVs on the local host. For each one that is found, C<< parted >> is called to check if there's more that 1 GiB of free space available after it. If so, it will extend the PV partition to use the free space.

This method takes no parameters.

=cut
sub auto_grow_pv
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->_auto_grow_pv()" }});
	
	# Look for disks that has unpartitioned space and grow it if needed.
	my $host_uuid        = $anvil->Get->host_uuid();
	my $short_host_name  = $anvil->Get->short_host_name();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		's1:host_uuid'       => $host_uuid, 
		's2:short_host_name' => $short_host_name, 
	}});
	
	my $shell_call = $anvil->data->{path}{exe}{pvs}." --noheadings --units b -o pv_name,vg_name,pv_size,pv_free --separator ,";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
	my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		output      => $output,
		return_code => $return_code, 
	}});
	if ($return_code)
	{
		# Bad return code.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "warning_0159", variables => { 
			shell_call  => $shell_call,
			return_code => $return_code,
			output      => $output, 
		}});
		next;
	}
	my $pv_found = 0;
	foreach my $line (split/\n/, $output)
	{
		$line = $anvil->Words->clean_spaces({string => $line});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
		my ($pv_name, $used_by_vg, $pv_size, $pv_free) =  (split/,/, $line);
		   $pv_size                                    =~ s/B$//;
		   $pv_free                                    =~ s/B$//;
		my $pv_used                                    =  $pv_size - $pv_free;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			pv_name    => $pv_name,
			used_by_vg => $used_by_vg, 
			pv_size    => $pv_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $pv_size}).")", 
			pv_free    => $pv_free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $pv_free}).")", 
			pv_used    => $pv_used." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $pv_used}).")", 
		}});
		
		# Get the raw backing disk. 
		my $device_path  = "";
		my $pv_partition = 0;
		if ($pv_name =~ /(\/dev\/nvme\d+n\d+)p(\d+)$/)
		{
			$device_path  = $1;
			$pv_partition = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				device_path  => $device_path,
				pv_partition => $pv_partition, 
			}});
		}
		elsif ($pv_name =~ /(\/dev\/\w+)(\d+)$/)
		{
			$device_path  = $1;
			$pv_partition = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				device_path  => $device_path,
				pv_partition => $pv_partition, 
			}});
		}
		else
		{
			# No device found for the PV.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0821", variables => { pv_name => $pv_name }});
			next;
		}
		
		# See how much free space there is on the backing disk.
		my $shell_call = $anvil->data->{path}{exe}{parted}." --align optimal ".$device_path." unit B print free";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
		my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			output      => $output,
			return_code => $return_code, 
		}});
		if ($return_code)
		{
			# Bad return code.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "warning_0159", variables => { 
				shell_call  => $shell_call,
				return_code => $return_code,
				output      => $output, 
			}});
			next;
		}
		my $pv_found = 0;
		foreach my $line (split/\n/, $output)
		{
			$line = $anvil->Words->clean_spaces({string => $line});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
			if ($pv_found)
			{
				#print "Checking if: [".$line."] is free space.\n";
				if ($line =~ /^(\d+)B\s+(\d+)B\s+(\d+)B\s+Free Space/i)
				{
					my $start_byte = $1;
					my $end_byte   = $2;
					my $size       = $3;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
						's1:start_byte' => $start_byte." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $start_byte}).")",
						's2:end_byte'   => $end_byte." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $end_byte}).")",
						's3:size'       => $pv_used." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size}).")",
					}});
					
					# There's free space! If it's greater than 1 GiB, grow it automatically.
					if ($size < 1073741824)
					{
						# Not enough free space
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0823", variables => { 
							free_space   => $anvil->Convert->bytes_to_human_readable({'bytes' => $size}),
							device_path  => $device_path,
							pv_partition => $pv_partition,
						}});
						next;
					}
					else
					{
						# Enough free space, grow!
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0822", variables => { 
							free_space   => $anvil->Convert->bytes_to_human_readable({'bytes' => $size}),
							device_path  => $device_path,
							pv_partition => $pv_partition,
						}});
						
						### Backup the partition table.
						#sfdisk --dump /dev/sda > partition_table_backup_sda
						my $device_name        = ($device_path =~ /^\/dev\/(.*)$/)[0];
						my $partition_backup   = "/tmp/".$device_name.".partition_table_backup";
						my $shell_call         = $anvil->data->{path}{exe}{sfdisk}." --dump ".$device_path." > ".$partition_backup;
						my $restore_shell_call = $anvil->data->{path}{exe}{sfdisk}." ".$device_path." < ".$partition_backup." --force";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
							device_name      => $device_name, 
							partition_backup => $partition_backup, 
							shell_call       => $shell_call,
						}});
						my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
							output      => $output,
							return_code => $return_code, 
						}});
						if ($return_code)
						{
							# Bad return code.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "warning_0159", variables => { 
								shell_call  => $shell_call,
								return_code => $return_code,
								output      => $output, 
							}});
							next;
						}
						else
						{
							# Tell the user about the backup.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "message_0361", variables => { 
								device_path      => $device_path,
								partition_backup => $partition_backup,
								restore_command  => $restore_shell_call, 
							}});
						}
						
						### Grow the partition
						# parted --align optimal /dev/sda ---pretend-input-tty resizepart 2 100% Yes; echo $?
						$shell_call = $anvil->data->{path}{exe}{parted}." --align optimal ".$device_path." ---pretend-input-tty resizepart ".$pv_partition." 100% Yes";
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
						($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
							output      => $output,
							return_code => $return_code, 
						}});
						if ($return_code)
						{
							# Bad return code.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "warning_0159", variables => { 
								shell_call  => $shell_call,
								return_code => $return_code,
								output      => $output, 
							}});
							
							### Restore the partition table 
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 0, priority => "err", key => "error_0467"});
							
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { restore_shell_call => $restore_shell_call }});
							my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $restore_shell_call});
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
								output      => $output,
								return_code => $return_code, 
							}});
							
							# Error out.
							$anvil->nice_exit({exit_code => 1});
						}
						else
						{
							# Looks like it worked. Call print again to log the new value.
							my $shell_call = $anvil->data->{path}{exe}{parted}." --align optimal ".$device_path." unit B print free";
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
							my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0825", variables => { 
								pv_name => $pv_name,
								output  => $output,
							}});
						}
						
						### Resize the PV.
						$shell_call = $anvil->data->{path}{exe}{pvresize}." ".$pv_name;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
						($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
							output      => $output,
							return_code => $return_code, 
						}});
						if ($return_code)
						{
							# Bad return code.
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, priority => "alert", key => "warning_0159", variables => { 
								shell_call  => $shell_call,
								return_code => $return_code,
								output      => $output, 
							}});
							next;
						}
						else
						{
							# Looks like it worked. Call print again to log the new value.
							my $shell_call = $anvil->data->{path}{exe}{pvdisplay}." ".$pv_name;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { shell_call => $shell_call }});
							my ($output, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0826", variables => { 
								pv_name => $pv_name,
								output  => $output,
							}});
						}
						
						# Update LVM data
						$anvil->ScanCore->call_scan_agents({debug => $debug, agent => "scan-lvm"});
						
						# Done. 
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0827", variables => { pv_name => $pv_name }});
					}
				}
				else
				{
					# There's another partition after this PV, do nothing.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0824", variables => { 
						device_path  => $device_path,
						pv_partition => $pv_partition,
					}});
					next;
				}
			}
			elsif ($line =~ /^$pv_partition\s/)
			{
				$pv_found = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { pv_found => $pv_found }});
			}
			else
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					device_path  => $device_path, 
					pv_partition => $pv_partition, 
					pv_found     => $pv_found,
				}});
			}
		}
	}
	
	return(0);
}


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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->backup()" }});
	
	my $fatal       = defined $parameter->{fatal}       ? $parameter->{fatal}       : 1;
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $source_file = defined $parameter->{file}        ? $parameter->{file}        : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		fatal       => $fatal, 
		port        => $port, 
		password    => $anvil->Log->is_secure($password), 
		target      => $target,
		remote_user => $remote_user, 
		source_file => $source_file,
	}});
	
	my $proceed     = 0;
	my $target_file = "";
	if (not $source_file)
	{
		# No file passed in
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->backup()", parameter => "target" }});
		if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
	}
	elsif ($source_file !~ /^\//)
	{
		# Isn't a full path
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0150", variables => { source_file => $source_file }});
		if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
	}
	
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local file
		if (not -e $source_file)
		{
			# File doesn't exist.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0151", variables => { source_file => $source_file }});
			if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
		}
		elsif (not -f $source_file)
		{
			# Not a file
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0153", variables => { source_file => $source_file }});
			if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
		}
		elsif (not -r $source_file)
		{
			# Can't read the file.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0152", variables => { source_file => $source_file }});
			if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
		}
		else
		{
			$proceed = 1;
		}
	}
	else
	{
		# Make sure the source file exists, is a file and can be read.
		my $shell_call = "
if [ -e '".$source_file."' ]; 
then
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
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error  => $error,
			output => $output,
		}});
		if (not $error)
		{
			# No error. Did the file exist?
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output }});
			if ($output eq "not found")
			{
				# File doesn't exist.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0151", variables => { source_file => $source_file }});
				if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
			}
			elsif ($output eq "not a file")
			{
				# Not a file
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0153", variables => { source_file => $source_file }});
				if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
			}
			elsif ($output eq "not readable")
			{
				# Can't read the file.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0152", variables => { source_file => $source_file }});
				if ($fatal) { $anvil->nice_exit({exit_code => 1}); }
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
			if ($fatal)
			{
				$anvil->nice_exit({exit_code => 1});
			}
		}
	}
	
	# Proceed?
	if ($proceed)
	{
		# Proceed with the backup. We'll recreate the path 
		my ($directory, $file) = ($source_file =~ /^(\/.*)\/(.*)$/);
		my $timestamp          = $anvil->Get->date_and_time({file_name => 1});
		my $backup_directory   = $anvil->data->{path}{directories}{backups}.$directory;
		my $backup_target      = $file.".".$timestamp.".".$anvil->Get->uuid({short => 1});
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
			port        => $port, 
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
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0234", variables => { source => $source_file, destination => $target_file }});
			$target_file = "";
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { target_file => $target_file }});
	return($target_file);
}
=cut

=head2 change_mode

This changes the mode of a file or directory.

 $anvil->Storage->change_mode({path => "/tmp/foo", mode => "0644"});

If it fails to write the file, an alert will be logged.

Parameters;

=head3 mode (required)

This is the numeric mode to set on the file. It expects four digits to cover the sticky bit, but will work with three digits. It also supports the C<< + >> and C<< - >> formats, like C<< a+x >> or C<< g-w >>.

=head3 path (required)

This is the file or directory to change the mode on.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 target (optional)

If set, the file will be backed up on the target machine. This must be either an IP address or a resolvable host name. 

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub change_mode
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->change_mode()" }});
	
	my $mode        = defined $parameter->{mode}        ? $parameter->{mode}        : "";
	my $path        = defined $parameter->{path}        ? $parameter->{path}        : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		mode        => $mode,
		path        => $path,
		port        => $port, 
		password    => $anvil->Log->is_secure($password), 
		target      => $target,
		remote_user => $remote_user, 
	}});
	
	# This is often called without a mode, just return if that's the case.
	if (not $mode)
	{
		return(0);
	}
	
	if (not $path)
	{
		# No path...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->change_mode()", parameter => "path" }});
		return('!!error!!');
	}
	if (($mode !~ /^\d\d\d$/) && ($mode !~ /^\d\d\d\d$/) && ($mode !~ /^\w\+\w$/) && ($mode !~ /^\w\-\w$/))
	{
		# Invalid mode
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0038", variables => { mode => $mode }});
		return('!!error!!');
	}
	
	my $shell_call = $anvil->data->{path}{exe}{'chmod'}." ".$mode." ".$path;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0011", variables => { shell_call => $shell_call }});
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local call
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output,
			return_code => $return_code,
		}});
	}
	else
	{
		# Remote call.
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			shell_call  => $shell_call, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error       => $error,
			output      => $output,
			return_code => $return_code,
		}});
	}
	
	return(0);
}

=head2 change_owner

This changes the owner and/or group of a file or directory.

 $anvil->Storage->change_owner({path => "/tmp/foo", user => "striker-ui-api", group => "striker-ui-api" });

If it fails to write the file, an alert will be logged and 'C<< 1 >>' will be returned. Otherwise, 'C<< 0 >>' will be returned.

Parameters;

=head3 group (optional, default is the main group of the user running the program)

This is the group name or UID to set the path to.

=head3 path (required)

This is the file or directory to change the mode on.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 remote_user (optional)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 target (optional)

If set, the file will be backed up on the target machine. This must be either an IP address or a resolvable host name. 

=head3 user (optional, default is the user running the program)

This is the user name or UID to set the path to.

=cut
sub change_owner
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->change_owner()" }});
	
	my $group       = defined $parameter->{group}       ? $parameter->{group}       : getgrgid($();
	my $path        = defined $parameter->{path}        ? $parameter->{path}        : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : getpwuid($<);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		group       => $group,
		path        => $path,
		port        => $port, 
		password    => $anvil->Log->is_secure($password), 
		remote_user => $remote_user, 
		target      => $target,
		user        => $user,
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
	if (not $path)
	{
		# No path...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->change_owner()", parameter => "path" }});
		$error = 1;
	}
	if (not -e $path)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0051", variables => {path => $path }});
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
		my $shell_call = $anvil->data->{path}{exe}{'chown'}." ".$string." ".$path;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0011", variables => { shell_call => $shell_call }});
		if ($anvil->Network->is_local({host => $target}))
		{
			# Local call
			my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				output      => $output,
				return_code => $return_code,
			}});
		}
		else
		{
			# Remote call.
			my ($output, $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call, 
				target      => $target,
				port        => $port, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error       => $error,
				output      => $output,
				return_code => $return_code,
			}});
		}
	}
	
	return($error);
}


=head2 check_files

This method checks the files on the local system. Specifically, it looks in C<< file_locations >> table and then checks if the file is "ready" or not. Depending on the results, C<< file_location_ready >> is updated if needed.

This method takes no parameters.

=cut
sub check_files
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->check_md5sums()" }});
	
	$anvil->Database->get_files({debug => $debug});
	$anvil->Database->get_file_locations({debug => $debug});
	
	# Look for files that should be on this host.
	my $host_uuid = $anvil->Get->host_uuid({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	
	# Make sure all entries in 'files' has a corresponding 'file_locations' entry for this host.
	my $host_type = $anvil->Get->host_type();
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_type => $host_type }});
	
	# Look for files on this computer not yet on the system
	if ($host_type ne "striker")
	{
		my $reload = 0;
		foreach my $file_name (sort {$a cmp $b} keys %{$anvil->data->{files}{file_name}})
		{
			my $file_uuid      = $anvil->data->{files}{file_name}{$file_name}{file_uuid};
			my $file_directory = $anvil->data->{files}{file_name}{$file_name}{file_directory};
			my $file_size      = $anvil->data->{files}{file_name}{$file_name}{file_size};
			my $file_md5sum    = $anvil->data->{files}{file_name}{$file_name}{file_md5sum};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:file_name'      => $file_name, 
				's2:file_uuid'      => $file_uuid, 
				's3:file_directory' => $file_directory, 
				's4:file_size'      => $file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}).")", 
				's5:file_md5sum'    => $file_md5sum, 
			}});
			
			# Is there an entry or this host?
			if (not exists $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_uuid})
			{
				# Nope, add it.
				$reload = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
				
				my $file_ready =  0;
				my $full_path  =  $file_directory."/".$file_name;
				   $full_path  =~ s/\/\//\//g;
				if (-f $full_path)
				{
					# Calculate the md5sum.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0265", variables => { file => $full_path }});
					if ($file_size > (128 * (2 ** 20)))
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0266", variables => { 
							size => $anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}),
						}});
					}
					
					# Update (or get) the md5sum.
					my $local_md5sum = $anvil->Get->md5sum({debug => 2, file => $full_path});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { local_md5sum => $local_md5sum }});
					
					if ($local_md5sum eq $file_md5sum)
					{
						$file_ready = 1;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { file_ready => $file_ready }});
					}
				}
				
				my $file_location_uuid = $anvil->Database->insert_or_update_file_locations({
					debug                   => $debug, 
					file_location_file_uuid => $file_uuid, 
					file_location_host_uuid => $host_uuid, 
					file_location_active    => 1, 
					file_location_ready     => $file_ready,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { file_location_uuid => $file_location_uuid }});
			}
		}
		
		if ($reload)
		{
			$anvil->Database->get_files({debug => $debug});
			$anvil->Database->get_file_locations({debug => $debug});
		}
	}
	
	# Sorting isn't useful really, but it ensures consistent listing run over run).
	foreach my $file_location_file_uuid (sort {$a cmp $b} keys %{$anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}})
	{
		my $file_location_uuid      = $anvil->data->{file_locations}{host_uuid}{$host_uuid}{file_uuid}{$file_location_file_uuid}{file_location_uuid};
		my $file_location_file_uuid = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_file_uuid};
		my $file_location_active    = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_active};
		my $file_location_ready     = $anvil->data->{file_locations}{file_location_uuid}{$file_location_uuid}{file_location_ready};
		my $file_name               = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_name};
		my $file_directory          = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_directory};
		my $file_size               = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_size}; 
		my $file_md5sum             = $anvil->data->{files}{file_uuid}{$file_location_file_uuid}{file_md5sum};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:file_location_file_uuid' => $file_location_file_uuid, 
			's2:file_location_uuid'      => $file_location_uuid, 
			's3:file_location_file_uuid' => $file_location_file_uuid, 
			's4:file_location_active'    => $file_location_active, 
			's5:file_location_ready'     => $file_location_ready, 
			's6:file_name'               => $file_name, 
			's7:file_directory'          => $file_directory, 
			's8:file_size'               => $file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}).")", 
			's9:file_md5sum'             => $file_md5sum, 
		}});
		
		my $full_path =  $file_directory."/".$file_name;
		   $full_path =~ s/\/\//\//g;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { full_path => $full_path }});
		
		# If the file is not active, make sure the active is also false, regardless of anything else.
		if (not $file_location_active)
		{
			if ($file_location_ready)
			{
				$anvil->Database->insert_or_update_file_locations({
					debug                   => $debug, 
					file_location_uuid      => $file_location_uuid, 
					file_location_file_uuid => $file_location_file_uuid, 
					file_location_host_uuid => $host_uuid, 
					file_location_active    => $file_location_active, 
					file_location_ready     => 0,
				});
			}
		}
		elsif (-e $full_path)
		{
			# It exists, what's it's size?
			my $real_size = (stat($full_path))[7];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				real_size => $real_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $real_size}).")", 
			}});
			
			# If the size is the same as recorded, and the file is already 'ready', we're done.
			if ($real_size == $file_size)
			{
				if (not $file_location_ready)
				{
					# Calculate the md5sum and see if it is ready now.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0265", variables => { file => $full_path }});
					if ($real_size > (128 * (2 ** 20)))
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0266", variables => { 
							size => $anvil->Convert->bytes_to_human_readable({'bytes' => $real_size}),
						}});
					}
					
					# Update (or get) the md5sum.
					my $real_md5sum = $anvil->Get->md5sum({debug => 2, file => $full_path});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { real_md5sum => $real_md5sum }});
					
					if ($real_md5sum eq $file_md5sum)
					{
						# It's ready now.
						$anvil->Database->insert_or_update_file_locations({
							debug                   => $debug, 
							file_location_uuid      => $file_location_uuid, 
							file_location_file_uuid => $file_location_file_uuid, 
							file_location_host_uuid => $host_uuid, 
							file_location_active    => $file_location_active, 
							file_location_ready     => 1,
						});
					}
				}
			}
			elsif ($file_location_ready)
			{
				# It's not ready.
				$anvil->Database->insert_or_update_file_locations({
					debug                   => $debug, 
					file_location_uuid      => $file_location_uuid, 
					file_location_file_uuid => $file_location_file_uuid, 
					file_location_host_uuid => $host_uuid, 
					file_location_active    => $file_location_active, 
					file_location_ready     => 0,
				});
			}
		}
		elsif ($file_location_ready)
		{
			# File doesn't exist but is marked as ready, mark it as not ready.
			$anvil->Database->insert_or_update_file_locations({
				debug                   => $debug, 
				file_location_uuid      => $file_location_uuid, 
				file_location_file_uuid => $file_location_file_uuid, 
				file_location_host_uuid => $host_uuid, 
				file_location_active    => $file_location_active, 
				file_location_ready     => 0,
			});
		}
	}
	
	return(0);
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->check_md5sums()" }});
	
	# We'll set this if anything has changed.
	my $exit   = 0;
	my $caller = $0;
	
	# Have we changed?
	$anvil->data->{md5sum}{$caller}{now} = $anvil->Get->md5sum({file => $0});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"md5sum::${caller}::at_start" => $anvil->data->{md5sum}{$caller}{at_start},
		"md5sum::${caller}::now"      => $anvil->data->{md5sum}{$caller}{now},
	}});
	
	if ($anvil->data->{md5sum}{$caller}{at_start} ne $anvil->data->{md5sum}{$caller}{now})
	{
		# Exit.
		$exit = 1;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0250", variables => { 
			file    => $0,
			old_sum => $anvil->data->{md5sum}{$caller}{at_start},
			new_sum => $anvil->data->{md5sum}{$caller}{now},
		}});
	}
	
	### NOTE: Some modules are loaded dynamically, so if there is no old hash, we'll record it now.
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
		
		# Is this the first time I've seen this module?
		if (not defined $anvil->data->{md5sum}{$module_file}{at_start})
		{
			# New one!
			$anvil->data->{md5sum}{$module_file}{at_start} = $module_sum;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"md5sum::${module_file}::at_start" => $anvil->data->{md5sum}{$module_file}{at_start},
			}});
		}
		$anvil->data->{md5sum}{$module_file}{now} = $module_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"md5sum::${module_file}::at_start" => $anvil->data->{md5sum}{$module_file}{at_start},
			"md5sum::${module_file}::now"      => $anvil->data->{md5sum}{$module_file}{now},
		}});
		if ($anvil->data->{md5sum}{$module_file}{at_start} ne $anvil->data->{md5sum}{$module_file}{now})
		{
			# Changed.
			$exit = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0250", variables => { 
				file    => $module_file,
				old_sum => $anvil->data->{md5sum}{$module_file}{at_start},
				new_sum => $anvil->data->{md5sum}{$module_file}{now},
			}});
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
			"md5sum::${file}::at_start" => $anvil->data->{md5sum}{$file}{at_start}, 
			"md5sum::${file}::now"      => $anvil->data->{md5sum}{$file}{now}, 
		}});
		if ($anvil->data->{md5sum}{$file}{at_start} ne $anvil->data->{md5sum}{$file}{now})
		{
			$exit = 1;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0250", variables => { 
				file    => $file,
				old_sum => $anvil->data->{md5sum}{$file}{at_start},
				new_sum => $anvil->data->{md5sum}{$file}{now},
			}});
		}
	}
	
	# Exit?
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'exit' => $exit }});
	return($exit);
}

=head2 compress

This compresses a local or remote file, using bzip2. It returns C<< 0 >> on success, and C<< 1 >> on failure.

B<< NOTE >>: When compressing a remote file, a ten minute (600 second) timeout is used. If you think a compression could take longer, either use the C<< timeout >> parameter below, or call this method on the remote machine, if possible.

Parameters;

=head3 file (required)

This is the full path to the file to compress.

=head3 keep (optional, default 0)

When set to C<< 1 >>, the file being compressed will be kept, and the new compressed version will be saved along side it. When set to C<< 0 >>, the original file is removed, leaving the compressed file.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 target (optional)

If set, the file will be copied on the target machine. This must be either an IP address or a resolvable host name. 

=head3 timeout (optional, default '600')

This is the number of seconds that this method will wait for the compression to complete. If the timeout expires, C<< 1 >> will be returned, though it is possible that the compression may still complete successfully after the connection times out.

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub compress
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->compress()" }});
	
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : 0;
	my $keep        = defined $parameter->{keep}        ? $parameter->{keep}        : 0;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $timeout     = defined $parameter->{timeout}     ? $parameter->{timeout}     : 600;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file        => $file, 
		keep        => $keep,
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target,
		timeout     => $timeout, 
	}});
	
	if (not $file)
	{
		# No file passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->compress()", parameter => "file" }});
		return(1);
	}
	
	# Add 'keep', if needed.
	my $bzip2_call = $anvil->data->{path}{exe}{bzip2}." --compress ";
	if ($keep)
	{
		$bzip2_call .= "--keep ";
	}
	   $bzip2_call .= $file;
	my $out_file   =  $file.".bz2";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		bzip2_call => $bzip2_call,
		out_file   => $out_file, 
	}});
	
	if ($anvil->Network->is_local({host => $target}))
	{
		# Compressing locally
		if (not -e $file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0103", variables => { file => $file }});
			return(1);
		}
		
		# Lets see how much it shrinks. What's the starting size?
		my ($start_size) = (stat($file))[7];
		my $start_time   = time;
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0455", variables => { 
			file => $file,
			size => $anvil->Convert->add_commas({number => $start_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $start_size}).")",
		}});
		
		# Now compress the file
		my ($output, $return_code) = $anvil->System->call({
			debug      => $debug, 
			shell_call => $bzip2_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
		
		if ($return_code)
		{
			# Something went wrong.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0100", variables => { 
				return_code => $return_code,
				output      => $output,
			}});
			return(1);
		}
		elsif (not -e $out_file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0101", variables => { 
				out_file => $out_file,
			}});
			return(1);
		}
		else
		{
			# Success! How big is the output?
			my ($out_size) = (stat($out_file))[7];
			my $took       = time - $start_time;
			my $difference = $start_size - $out_size;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0456", variables => { 
				file       => $out_file,
				size       => $anvil->Convert->add_commas({number => $out_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $out_size}).")",
				difference => $anvil->Convert->add_commas({number => $difference})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $difference}).")",
				took       => $anvil->Convert->time({'time' => $took, long => 1, translate => 1})
			}});
			return(0);
		}
	}
	else
	{
		# Copying on a remote system.
		my $shell_call = "
if [ -e '".$file."' ]; 
then
    ".$anvil->data->{path}{exe}{'stat'}." --format='\%n \%s' ".$file."
else
    ".$anvil->data->{path}{exe}{echo}." 'file not found'
fi
";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error       => $error,
			output      => $output,
			return_code => $return_code, 
		}});
		if ($error)
		{
			# Something went wrong.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0102", variables => { 
				file        => $file, 
				error       => $error,
				output      => $output,
				target      => $target, 
				remote_user => $remote_user, 
			}});
			return(1);
		}
		else
		{
			# Make sure we read the file's size (which also confirms it's existence).
			my $start_size = 0;
			my $file_found = 0;
			foreach my $line (split/\n/, $output)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
				if ($line =~ /^$file (\d+)$/)
				{
					$start_size = $1;
					$file_found = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						start_size => $anvil->Convert->add_commas({number => $start_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $start_size}).")",
						file_found => $file_found, 
					}});
				}
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_found => $file_found }});
			if ($file_found)
			{
				# Compress!
				my $start_time = time;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0455", variables => { 
					file => $file,
					size => $anvil->Convert->add_commas({number => $start_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $start_size}).")",
				}});
				my ($output, $error, $return_code) = $anvil->Remote->call({
					debug       => $debug, 
					target      => $target,
					port        => $port, 
					user        => $remote_user, 
					password    => $password,
					remote_user => $remote_user, 
					shell_call  => $bzip2_call,
					timeout     => $timeout,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					error       => $error,
					output      => $output,
					return_code => $return_code, 
				}});
				if ($return_code)
				{
					# Something went wrong.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0100", variables => { 
						return_code => $return_code,
						output      => $output,
					}});
					return(1);
				}
				else
				{
					# Get the size (and confirm the success) of the compressed file.
					my $out_size   = 0;
					my $file_found = 0;
					my $tries      = 3;
					until ($file_found)
					{
						my $shell_call = "
if [ -e '".$out_file."' ]; 
then
    ".$anvil->data->{path}{exe}{'stat'}." --format='\%n \%s' ".$out_file."
else
    ".$anvil->data->{path}{exe}{echo}." 'file not found'
fi
";
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
						my ($output, $error, $return_code) = $anvil->Remote->call({
							debug       => $debug, 
							target      => $target,
							port        => $port, 
							user        => $remote_user, 
							password    => $password,
							remote_user => $remote_user, 
							shell_call  => $shell_call,
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							error       => $error,
							output      => $output,
							return_code => $return_code, 
						}});
						
						foreach my $line (split/\n/, $output)
						{
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
							if ($line =~ /^$out_file (\d+)$/)
							{
								$out_size   = $1;
								$file_found = 1;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
									out_size => $anvil->Convert->add_commas({number => $out_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $out_size}).")",
									file_found => $file_found, 
								}});
							}
						}
						if ($file_found)
						{
							# Found it.
							last;
						}
						else
						{
							$tries--;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { tries => $tries }});
							if (not $tries)
							{
								# Stop waiting.
								last;
							}
							else
							{
								# Sleep for a second, then check again.
								sleep 1;
							}
						}
					}
					
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file_found => $file_found }});
					if ($file_found)
					{
						my $took       = time - $start_time;
						my $difference = $start_size - $out_size;
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0456", variables => { 
							file       => $out_file,
							size       => $anvil->Convert->add_commas({number => $out_size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $out_size}).")",
							difference => $anvil->Convert->add_commas({number => $difference})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $difference}).")",
							took       => $anvil->Convert->time({'time' => $took, long => 1, translate => 1})
						}});
						return(0);
					}
					else
					{
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0101", variables => { out_file => $out_file }});
						return(1);
					}
				}
			}
			else
			{
				# Not found.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0103", variables => { file => $file }});
				return(1);
			}
		}
	}
	
	# We should never get here, so return 1 as something obviously went wrong.
	return(1);
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->copy_file()" }});
	
	my $overwrite   = defined $parameter->{overwrite}   ? $parameter->{overwrite}   : 0;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $source_file = defined $parameter->{source_file} ? $parameter->{source_file} : "";
	my $target_file = defined $parameter->{target_file} ? $parameter->{target_file} : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		overwrite   => $overwrite,
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
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
	
	if ($anvil->Network->is_local({host => $target}))
	{
		# Copying locally
		if (not -e $source_file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0052", variables => { 
				method      => "copy_file",
				source_file => $source_file,
			}});
			return(1);
		}
		
		# If the target exists, abort
		if ((-e $target_file) && (not $overwrite))
		{
			# This isn't an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0046", variables => {
				method      => "copy_file",
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
					method      => "copy_file",
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
		}
		
		# Now backup the file.
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'cp'}." -af ".$source_file." ".$target_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	}
	else
	{
		# Copying on a remote system.
		my $proceed    = 1;
		my $shell_call = "
if [ -e '".$source_file."' ]; 
then
    ".$anvil->data->{path}{exe}{echo}." 'source file exists'
else
    ".$anvil->data->{path}{exe}{echo}." 'source file not found'
fi
if [ -e '".$target_file."' ];
then
    ".$anvil->data->{path}{exe}{echo}." 'target file exists'
elif [ -d '".$directory."' ];
then
    ".$anvil->data->{path}{exe}{echo}." 'target directory exists'
else
    ".$anvil->data->{path}{exe}{echo}." 'target directory not found'
fi";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error  => $error,
			output => $output,
		}});
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
			my ($line1, $line2) = (split/\n/, $output);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				line1 => $line1,
				line2 => $line2,
			}});
			if ($line1 eq "source file not found")
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0052", variables => { 
					method      => "copy_file",
					source_file => $source_file,
				}});
				return(1);
			}
			if (($line1 eq "target file exists") && (not $overwrite))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0046", variables => {
					method      => "copy_file",
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
			if ($line2 eq "target directory not found")
			{
				my $failed = $anvil->Storage->make_directory({
					debug       => $debug,
					directory   => $directory,
					password    => $password, 
					remote_user => $remote_user, 
					target      => $target,
					port        => $port, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
				if ($failed)
				{
					# Failed to create the directory, abort.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0170", variables => {
						method      => "copy_file",
						source_file => $source_file,
						target_file => $target_file,
					}});
					return(1);
				}
			}
		
			# Now backup the file.
			my ($output, $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				target      => $target,
				port        => $port, 
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
				shell_call  => $anvil->data->{path}{exe}{'cp'}." -af ".$source_file." ".$target_file,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output,
			}});
		}
	}
	
	return(0);
}


=head3 copy_device

This uses the C<< dd >> system call, possibly over ssh, to create a copy of the source on the destination. Being based on C<< dd >>, this works with raw block devices and to or from files.

B<< Warning >>: This must be used carefully! Calling this backwards could destroy data!

B<< Note >>: The caller is responsible for ensuring the data on the soure will not change during the copy. If the source is a server, make sure it's off. If the source is a file system, make sure it's unmounted.

B<< Note >>: If the C<< source >> or C<< destination >> is a remote host, passwordless SSH must be configured for this to work!

Parameters;

=head3 block_size (optional, default '4M')

This is the block size to be used for the copy. Specifically, this transtes into 'read <size> bytes, copy, read <size> bytes, copy'. This should match the size of the logical extents, block size or similar where needed. Most LVM logical extents are 4 MiB, so the default of C<< 4M >> should be fine in most cases. 

B<< Note >>: See C<< man dd >> for valid formatting of this option.

=head3 calculate_sums (Optional, default '0')

If set to C<< 1 >>, the C<< md5sum >> of the source and destination are calculated and returned. If this is not used, the returned sum fields will be an empty string.

B<< Note >>: Calculating sums is highly advised, but can increase the time it takes for the copy to complete!

=head3 destination (required)

This is the full path to the destination (copy to) file or device. If the source is remote, used the format C<< <remote_user>@target:/path/to/file >>.

B<< Note >>: Only the source OR the destination can be remote, not both!

=head3 source (required)

This is the full path to the source (copy from) file or device. If the source is remote, used the format C<< <remote_user>@target:/path/to/file >>.

B<< Note >>: Only the source OR the destination can be remote, not both!

=head3 status_file (required)

This is the path to the status file used to record the progress of the copy. This will contain a parsed version of the C<< dd ... --status=progress >> output. When the copy is done, if C<< calculate_sums >> is set, then the C<< source=<sum> >> and C<< destination=<sum> >> will be recorded, marking the completion of the copy. If not set, those same variables will be written without a value, still marking the end of the copy. If there is a problem, the last line of the file be C<< failed=<reason> >>.

=cut
sub copy_device
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->copy_device()" }});
	
	my $block_size     = defined $parameter->{block_size}     ? $parameter->{block_size}     : "";
	my $calculate_sums = defined $parameter->{calculate_sums} ? $parameter->{calculate_sums} : "";
	my $destination    = defined $parameter->{destination}    ? $parameter->{destination}    : "";
	my $source         = defined $parameter->{source}         ? $parameter->{source}         : "";
	my $status_file    = defined $parameter->{status_file}    ? $parameter->{status_file}    : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		block_size     => $block_size, 
		calculate_sums => $calculate_sums, 
		destination    => $destination, 
		source         => $source, 
		status_file    => $status_file, 
	}});
	
	if (not $source)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->copy_device()", parameter => "source" }});
		return('!!error!!');
	}
	if (not $destination)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->copy_device()", parameter => "destination" }});
		return('!!error!!');
	}
	if (not $block_size)
	{
		$block_size = "4M";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { block_size => $block_size }});
	}
	
	# Verify that the source exists.
	
	
	return("");
}


=head3 delete_file

This deletes a file. Pretty much what it says on the tin. When run locally, it uses C<< unlink >>. When run on a remote machine, it uses C<< rm -f >>. As such, this will not delete directories, nor will it delete recursively.

 # Example
 $anvil->Storage->delete_file({file => "/some/file"});

On success, or if the file is already gone, C<< 0 >> is returned. On failure, C<< 1 >> is returned.

Parameters;

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 file (required)

This is the file to delete.

=head3 target (optional)

If set, the file will be copied on the target machine. This must be either an IP address or a resolvable host name. 

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.
=cut
sub delete_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->delete_file()" }});
	
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file        => $file, 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target,
	}});
	
	if (not $file)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->delete_file()", parameter => "file" }});
		return(1);
	}
	
	
	if ($anvil->Network->is_local({host => $target}))
	{
		# Deleting locally
		if (not -e $file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0615", variables => { file => $file }});
			return(0);
		}
		
		unlink $file;
		if (-e $file)
		{
			# Failed to delete.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0284", variables => { file => $file, error => $! }});
			return(1);
		}
		else
		{
			# Success
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0616", variables => { file => $file }});
		}
	}
	else
	{
		# Deleting on a remote system
		my $proceed    = 1;
		my $shell_call = "
if [ -e '".$file."' ]; 
then
    rm -f ".$file.";
    if [ -e '".$file."' ]; 
    then
        echo 'delete_failed'
    else
        echo 'deleted'
    fi;
else
    echo 'not_found'
fi
";
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { 
			shell_call  => $shell_call, 
			target      => $target, 
			remote_user => $remote_user,
		}});
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error       => $error,
			output      => $output,
			return_code => $return_code, 
		}});
		if ($output eq "deleted")
		{
			# File existed and was deleted.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0618", variables => { 
				file   => $file,
				target => $target, 
			}});
		}
		elsif ($output eq "not_found")
		{
			# File is already gone.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0617", variables => { 
				file   => $file,
				target => $target, 
			}});
		}
		elsif ($output eq "delete_failed")
		{
			# Delete failed.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0285", variables => { 
				file   => $file,
				target => $target, 
			}});
			return(1);
		}
		else
		{
			# Huh? Lost connection?
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0286", variables => { 
				file   => $file,
				target => $target, 
				error  => $error,
				output => $output,
			}});
			return(1);
		}
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

=head2 get_file_stats

This method calls a C<< stat >> (or C<< lstat >> and pulls out the file information. 

If successful, C<< 0 >> is returned. If there was a problem, like the file wasn't found, C<< 1 >> is returned.

Collected information is stored as (see C<< perldoc -f stat >> for details):

 file_stat::<file_path>::device_number
 file_stat::<file_path>::inode_number
 file_stat::<file_path>::mode                  - raw mode information (you probably don't want this)
 file_stat::<file_path>::unix_mode             - decimal mode (bitwise'd 4-digit decimal version of the mode, you probably want this)
 file_stat::<file_path>::number_of_hardlinks
 file_stat::<file_path>::user_id
 file_stat::<file_path>::user_name
 file_stat::<file_path>::group_id
 file_stat::<file_path>::group_name
 file_stat::<file_path>::device_identifier
 file_stat::<file_path>::size
 file_stat::<file_path>::access_time
 file_stat::<file_path>::modified_time
 file_stat::<file_path>::inode_change_time
 file_stat::<file_path>::block_size
 file_stat::<file_path>::blocks
 file_stat::<file_path>::mimetype

Parameters;

=head3 file_path (required)

This is the path to the file (or directory, symlink, etc) to be examined.

=cut
sub get_file_stats
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $test      = defined $parameter->{test}  ? $parameter->{test}  : 0;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->get_file_stats()" }});
	
	my $file_path = defined $parameter->{file_path} ? $parameter->{file_path} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file_path => $file_path,
	}});
	
	if (not $file_path)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->get_file_stats()", parameter => "file_path" }});
		return(1);
	}
	
	if (not -e $file_path)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0159", variables => { file_path => $file_path }});
		return(1);
	}
	
	### Data collected by array position, from 'perldoc -f stat'.
	#  0 dev      device number of filesystem
	#  1 ino      inode number
	#  2 mode     file mode  (type and permissions)
	#  3 nlink    number of (hard) links to the file
	#  4 uid      numeric user ID of file's owner
	#  5 gid      numeric group ID of file's owner
	#  6 rdev     the device identifier (special files only)
	#  7 size     total size of file, in bytes
	#  8 atime    last access time in seconds since the epoch
	#  9 mtime    last modify time in seconds since the epoch
	# 10 ctime    inode change time in seconds since the epoch (*)
	# 11 blksize  preferred I/O size in bytes for interacting with the file (may vary from file to file)
	# 12 blocks   actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)
	my ($device_number, $inode_number, $mode, $number_of_hardlinks, $user_id, $group_id, $device_identifier, $size, $access_time, $modified_time, $inode_change_time, $block_size, $blocks) = "";
	if (-l $file_path)
	{
		# Use lstat
		($device_number, $inode_number, $mode, $number_of_hardlinks, $user_id, $group_id, $device_identifier, $size, $access_time, $modified_time, $inode_change_time, $block_size, $blocks) = lstat($file_path);
	}
	else
	{
		# Use stat
		($device_number, $inode_number, $mode, $number_of_hardlinks, $user_id, $group_id, $device_identifier, $size, $access_time, $modified_time, $inode_change_time, $block_size, $blocks) = stat($file_path);
	}
	
	# A little processing...
	my $user_name  = getpwuid($user_id);
	my $group_name = getgrgid($group_id);
	my $unix_mode  = sprintf("%04s", sprintf("%o", ($mode & 07777)));
	
	$anvil->data->{file_stat}{$file_path}{device_number}       = $device_number;
	$anvil->data->{file_stat}{$file_path}{inode_number}        = $inode_number;
	$anvil->data->{file_stat}{$file_path}{mode}                = $mode;
	$anvil->data->{file_stat}{$file_path}{unix_mode}           = $unix_mode;
	$anvil->data->{file_stat}{$file_path}{number_of_hardlinks} = $number_of_hardlinks;
	$anvil->data->{file_stat}{$file_path}{user_id}             = $user_id;
	$anvil->data->{file_stat}{$file_path}{user_name}           = $user_name;
	$anvil->data->{file_stat}{$file_path}{group_id}            = $group_id;
	$anvil->data->{file_stat}{$file_path}{group_name}          = $group_name;
	$anvil->data->{file_stat}{$file_path}{device_identifier}   = $device_identifier;
	$anvil->data->{file_stat}{$file_path}{size}                = $size;
	$anvil->data->{file_stat}{$file_path}{access_time}         = $access_time;
	$anvil->data->{file_stat}{$file_path}{modified_time}       = $modified_time;
	$anvil->data->{file_stat}{$file_path}{inode_change_time}   = $inode_change_time;
	$anvil->data->{file_stat}{$file_path}{block_size}          = $block_size;
	$anvil->data->{file_stat}{$file_path}{blocks}              = $blocks;
	$anvil->data->{file_stat}{$file_path}{mimetype}            = mimetype($file_path);
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"s1:file_stat::${file_path}::device_number"       => $anvil->data->{file_stat}{$file_path}{device_number}, 
		"s2:file_stat::${file_path}::inode_number"        => $anvil->data->{file_stat}{$file_path}{inode_number},
		"s3:file_stat::${file_path}::mode"                => $anvil->data->{file_stat}{$file_path}{mode}, 
		"s4:file_stat::${file_path}::unix_mode"           => $anvil->data->{file_stat}{$file_path}{unix_mode},
		"s5:file_stat::${file_path}::number_of_hardlinks" => $anvil->data->{file_stat}{$file_path}{number_of_hardlinks}, 
		"s6:file_stat::${file_path}::user_id"             => $anvil->data->{file_stat}{$file_path}{user_id}, 
		"s7:file_stat::${file_path}::user_name"           => $anvil->data->{file_stat}{$file_path}{user_name},
		"s8:file_stat::${file_path}::group_id"            => $anvil->data->{file_stat}{$file_path}{group_id}, 
		"s9:file_stat::${file_path}::group_name"          => $anvil->data->{file_stat}{$file_path}{group_name}, 
		"s10:file_stat::${file_path}::device_identifier"  => $anvil->data->{file_stat}{$file_path}{device_identifier},
		"s11:file_stat::${file_path}::size"               => $anvil->Convert->add_commas({number => $anvil->data->{file_stat}{$file_path}{size}})." (".$anvil->Convert->bytes_to_human_readable({"bytes" => $anvil->data->{file_stat}{$file_path}{size}}).")",
		"s12:file_stat::${file_path}::access_time"        => $anvil->data->{file_stat}{$file_path}{access_time}, 
		"s13:file_stat::${file_path}::modified_time"      => $anvil->data->{file_stat}{$file_path}{modified_time}, 
		"s14:file_stat::${file_path}::inode_change_time"  => $anvil->data->{file_stat}{$file_path}{inode_change_time},
		"s15:file_stat::${file_path}::block_size"         => $anvil->data->{file_stat}{$file_path}{block_size},
		"s16:file_stat::${file_path}::blocks"             => $anvil->data->{file_stat}{$file_path}{blocks},
		"s17:file_stat::${file_path}::mimetype"           => $anvil->data->{file_stat}{$file_path}{mimetype},
	}});

	return(0);
}


=head2 get_size_of_block_device

This takes a block device path (DRBD or LVM LV path) and tries to find the size of the device as it was recorded in the database. If found, the size in bytes is returned. If there is a problem, C<< !!error!! >> is returned. If the device in not found in the database, an empty string is returned.

B<< Note >>: If there are multiple results, the first found will be returned. If the results span multiple Anvil! systems, this could be a problem. If this is a concern, specifify either the C<< host_uuid >> or C<< anvil_uuid >> parameters.

Parameters;

=head3 anvil_uuid (optional)

In the case of an ambiguous path (a path found on multiple Anvil! systems), this can be set to specify which Anvil! we're searching for.

=head3 host_uuid (optional)

In the case of an ambiguous path (a path found on multiple hosts), this can be set to specify which host we're searching for.

=head3 path (required)

This is the full block device path.


=cut
sub get_size_of_block_device
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->get_size_of_block_device()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	my $host_uuid  = defined $parameter->{host_uuid}  ? $parameter->{host_uuid}  : "";
	my $path       = defined $parameter->{path}       ? $parameter->{path}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid, 
		host_uuid  => $host_uuid, 
		path       => $path,
	}});
	
	if (not $path)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->get_size_of_block_device()", parameter => "path" }});
		return('!!error!!');
	}
	
	$anvil->Database->get_anvils({debug => $debug});
	my $node1_host_uuid = "";
	my $node2_host_uuid = "";
	if ($anvil_uuid)
	{
		$node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
		$node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			node1_host_uuid => $node1_host_uuid,
			node1_host_uuid => $node2_host_uuid, 
		}});
	}
	
	# Is this a DRBD path?
	if ($path !~ /drbd/)
	{
		# See if we can find this in LVs
		my $query = "
SELECT 
    scan_lvm_lv_host_uuid, 
    scan_lvm_lv_size 
FROM 
    scan_lvm_lvs 
WHERE 
    scan_lvm_lv_name != 'DELETED' 
AND 
    scan_lvm_lv_path = ".$anvil->Database->quote($path);
		if ($host_uuid)
		{
			$query .= "
AND 
    scan_lvm_lv_host_uuid = ".$anvil->Database->quote($host_uuid);
		}
		elsif ($anvil_uuid)
		{
			$query .= "
AND
    (
        scan_lvm_lv_host_uuid = ".$anvil->Database->quote($node1_host_uuid)."
    OR 
        scan_lvm_lv_host_uuid = ".$anvil->Database->quote($node2_host_uuid)."
    )
LIMIT 1
;";
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# Not found
			return("");
		}
		
		my $scan_lvm_lv_host_uuid = $results->[0]->[0];
		my $scan_lvm_lv_size      = $results->[0]->[1];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_lvm_lv_host_uuid => $scan_lvm_lv_host_uuid, 
			scan_lvm_lv_size      => $scan_lvm_lv_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_lvm_lv_size}).")", 
		}});
		
		return($scan_lvm_lv_size);
	}
	else
	{
		# Looks like it. If the device path is '/dev/drbd/by-res/...' we'll need to pull out the 
		# resource name (server name) and volume number as the path only actually exists when DRBD is
		# up and isn't referenced in the config file.
		my $resource = "";
		my $volume   = "";
		$anvil->DRBD->gather_data({debug => $debug});
		if ($path =~ /\/dev\/drbd\/by-res\/(.*)\/(\d+)$/)
		{
			$resource = $1;
			$volume   = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				resource => $resource, 
				volume   => $volume, 
			}});
		}
		elsif ($path =~ /\/dev\/drbd_(.*)_(\d+)$/)
		{
			$resource = $1;
			$volume   = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				resource => $resource, 
				volume   => $volume, 
			}});
		}
		elsif ($path =~ /\/dev\/drbd(\d+)$/)
		{
			# This is a direct path to a minor device, we'll need to find it in the config.
			my $minor = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { minor => $minor }});
			
			# If we were passed an anvil_uuid but not a host_uuid, don't use this machine's host UUID
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
			
			# These will be set if multiple options are found in the database.
			foreach my $this_resource (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_resource => $this_resource }});
				foreach my $this_host_name (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$this_resource}{host}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_name => $this_host_name }});
					foreach my $this_volume (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$this_resource}{host}{$this_host_name}{volume}})
					{
						my $this_minor = $anvil->data->{new}{resource}{$this_resource}{host}{$this_host_name}{volume}{$this_volume}{device_minor};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							this_volume => $this_volume,
							this_minor  => $this_minor, 
						}});
						next if $this_minor ne $minor;
						
						my $this_host_uuid = $anvil->Get->host_uuid_from_name({host_name => $this_host_name});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_uuid => $this_host_uuid }});
						next if not $this_host_uuid;
						
						# Sorry, this is a bit of a mess. Logic is; If we're given a 
						# host_uuid, and it matches, use it. Otherwise, if an 
						# anvil_uuid is passed, and either node 1 or 2's UUID, or if
						# there is a DR host, if it's host UUID matches, then we can
						# use this.
						if (
						    (
						     ($host_uuid) && ($host_uuid eq $this_host_uuid)
						    ) 
						    or 
						    (
						     ($anvil_uuid) && 
						     (
						      ($this_host_uuid eq $node1_host_uuid) or 
						      ($this_host_uuid eq $node2_host_uuid)
						     )
						    )
						   )
						{
							# This is a node in the requested cluster.
							$resource = $this_resource;
							$volume   = $this_volume;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								resource => $resource, 
								volume   => $volume, 
							}});
							last;
							
							if (not $host_uuid)
							{
								$host_uuid = $this_host_uuid;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
							}
						}
					}
				}
			}
		}
		
		if (not $resource)
		{
			# Not found.
			return("");
		}
		
		# The DRBD query is sorted by size because 'Secondary' resources can't have their size read 
		# and get set to '0'.
		my $query = "
SELECT 
    a.scan_drbd_resource_host_uuid, 
    b.scan_drbd_volume_size 
FROM 
    scan_drbd_resources a, 
    scan_drbd_volumes b 
WHERE 
    a.scan_drbd_resource_uuid = b.scan_drbd_volume_scan_drbd_resource_uuid 
AND 
    a.scan_drbd_resource_xml != 'DELETED' 
AND 
    a.scan_drbd_resource_name = ".$anvil->Database->quote($resource)." 
AND 
    b.scan_drbd_volume_number = ".$anvil->Database->quote($volume);
		if ($host_uuid)
		{
			$query .= "
AND 
    a.scan_drbd_resource_host_uuid = ".$anvil->Database->quote($host_uuid);
		}
		elsif ($anvil_uuid)
		{
			$query .= "
AND
    (
        a.scan_drbd_resource_host_uuid = ".$anvil->Database->quote($node1_host_uuid)."
    OR 
        a.scan_drbd_resource_host_uuid = ".$anvil->Database->quote($node2_host_uuid)."
    )";
		}
		$query .= "
ORDER BY 
    scan_drbd_volume_size DESC 
LIMIT 1;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		if (not $count)
		{
			# Not found
			return("");
		}
		
		my $scan_drbd_resource_host_uuid = $results->[0]->[0];
		my $scan_drbd_volume_size        = $results->[0]->[1];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_drbd_resource_host_uuid => $scan_drbd_resource_host_uuid, 
			scan_drbd_volume_size        => $scan_drbd_volume_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $scan_drbd_volume_size}).")", 
		}});
		
		return($scan_drbd_volume_size);
	}
	
	return("");
}


=head2 get_storage_group_details

This takes a C<< storage_group_uuid >> and loads information about members into the following hash;

 storage_groups::storage_group_uuid::<storage_group_uuid>::storage_group_name
 storage_groups::storage_group_uuid::<storage_group_uuid>::host_uuid::<host_uuid>::vg_internal_uuid
 storage_groups::storage_group_uuid::<storage_group_uuid>::host_uuid::<host_uuid>::vg_name
 storage_groups::storage_group_uuid::<storage_group_uuid>::host_uuid::<host_uuid>::vg_size
 storage_groups::storage_group_uuid::<storage_group_uuid>::host_uuid::<host_uuid>::vg_free

On success, C<< 0 >> is returned. On failure, C<< !!error!! >> is returned.

B<< Note >>: This method is called by C<< Database->get_storage_group_data() >> so generally calling it direcly isn't needed.

Parameters;

=head3 storage_group_uuid (required)

This is the specific C<< storage_groups >> -> C<< storage_group_uuid >> that we're loading data about.

=cut
sub get_storage_group_details
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $test      = defined $parameter->{test}  ? $parameter->{test}  : 0;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->get_storage_group_details()" }});
	
	my $storage_group_uuid = defined $parameter->{storage_group_uuid} ? $parameter->{storage_group_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		storage_group_uuid => $storage_group_uuid,
	}});
	
	if (not $storage_group_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->get_storage_group_details()", parameter => "storage_group_uuid" }});
		return('!!error!!');
	}
	
	my $query = "
SELECT 
    a.storage_group_name, 
    b.storage_group_member_vg_uuid, 
    c.scan_lvm_vg_name, 
    c.scan_lvm_vg_size, 
    c.scan_lvm_vg_free, 
    c.scan_lvm_vg_extent_size, 
    c.scan_lvm_vg_host_uuid 
FROM 
    storage_groups a, 
    storage_group_members b, 
    scan_lvm_vgs c 
WHERE 
    a.storage_group_uuid = b.storage_group_member_storage_group_uuid 
AND 
    b.storage_group_member_vg_uuid = c.scan_lvm_vg_internal_uuid 
AND 
    a.storage_group_uuid = ".$anvil->Database->quote($storage_group_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	
	if (not $count)
	{
		# Group not found.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0199", variables => { storage_group_uuid => $storage_group_uuid }});
		return('!!error!!');
	}
	
	foreach my $row (@{$results})
	{
		my $storage_group_name = $row->[0];
		my $vg_internal_uuid   = $row->[1];
		my $vg_name            = $row->[2];
		my $vg_size            = $row->[3];
		my $vg_free            = $row->[4];
		my $vg_extent_size     = $row->[5];
		my $host_uuid          = $row->[6];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			storage_group_name => $storage_group_name, 
			vg_internal_uuid   => $count, 
			vg_name            => $vg_name, 
			vg_size            => $vg_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $vg_size}).")", 
			vg_free            => $vg_free." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $vg_free}).")", 
			vg_extent_size     => $vg_extent_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $vg_extent_size}).")", 
			host_uuid          => $host_uuid, 
		}});
		
		$anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{storage_group_name}                      = $storage_group_name;
		$anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_internal_uuid} = $vg_internal_uuid;
		$anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_name}          = $vg_name;
		$anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_size}          = $vg_size;
		$anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_free}          = $vg_free;
		$anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_extent_size}   = $vg_extent_size;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"storage_groups::storage_group_uuid::${storage_group_uuid}::storage_group_name"                        => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{storage_group_name}, 
			"storage_groups::storage_group_uuid::${storage_group_uuid}::host_uuid::${host_uuid}::vg_internal_uuid" => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_internal_uuid}, 
			"storage_groups::storage_group_uuid::${storage_group_uuid}::host_uuid::${host_uuid}::vg_name"          => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_name}, 
			"storage_groups::storage_group_uuid::${storage_group_uuid}::host_uuid::${host_uuid}::vg_size"          => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_size}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_size}}).")", 
			"storage_groups::storage_group_uuid::${storage_group_uuid}::host_uuid::${host_uuid}::vg_free"          => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_free}}).")", 
			"storage_groups::storage_group_uuid::${storage_group_uuid}::host_uuid::${host_uuid}::vg_extent_size"   => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_free}." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->data->{storage_groups}{storage_group_uuid}{$storage_group_uuid}{host_uuid}{$host_uuid}{vg_extent_size}}).")", 
		}});
	}
	
	return(0);
}


=head2 get_storage_group_from_path

This method takes a block device path and returns the C<< storage_group_uuid >> is belongs to, if any. On success, C<< storage_group_uuid >> is returned. If the path is not found to exist on any storage group, an empty string is returned. If there is a problem, C<< !!error!! >> is returned.

B<< Note >>: If there are multiple results, the first found will be returned. If the results span multiple Anvil! systems, this could be a problem. If this is a concern, specifify either the C<< host_uuid >> or C<< anvil_uuid >> parameters.

Parameters;

=head3 anvil_uuid (optional)

In the case of an ambiguous path (a path found on multiple Anvil! systems), this can be set to specify which Anvil! we're searching for.

=head3 host_uuid (optional)

In the case of an ambiguous path (a path found on multiple hosts), this can be set to specify which host we're searching for.

=head3 path (required)

This is the full block device path.

=cut
sub get_storage_group_from_path
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->get_storage_group_from_path()" }});
	
	my $anvil_uuid = defined $parameter->{anvil_uuid} ? $parameter->{anvil_uuid} : "";
	my $host_uuid  = defined $parameter->{host_uuid}  ? $parameter->{host_uuid}  : "";
	my $path       = defined $parameter->{path}       ? $parameter->{path}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		anvil_uuid => $anvil_uuid, 
		host_uuid  => $host_uuid, 
		path       => $path,
	}});
	
	if (not $path)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->get_storage_group_from_path()", parameter => "path" }});
		return('!!error!!');
	}
	
	# Is this a DRBD path?
	my $gathered_data  = 0;
	my $logical_volume = "";
	if ($path !~ /drbd/)
	{
		$logical_volume = $path;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { logical_volume => $logical_volume }});
	}
	else
	{
		# Looks like it. If the device path is '/dev/drbd/by-res/...' we'll need to pull out the 
		# resource name (server name) and volume number as the path only actually exists when DRBD is
		# up and isn't referenced in the config file.
		my $resource      = "";
		my $volume        = "";
		   $gathered_data = 1;
		$anvil->DRBD->gather_data({debug => $debug});
		if ($path =~ /\/dev\/drbd\/by-res\/(.*)\/(\d+)$/)
		{
			$resource = $1;
			$volume   = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				resource => $resource, 
				volume   => $volume, 
			}});
		}
		elsif ($path =~ /\/dev\/drbd_(.*)_(\d+)$/)
		{
			$resource = $1;
			$volume   = $2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				resource => $resource, 
				volume   => $volume, 
			}});
		}
		elsif ($path =~ /\/dev\/drbd(\d+)$/)
		{
			# This is a direct path to a minor device, we'll need to find it in the config.
			my $minor = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { minor => $minor }});
			
			$anvil->Database->get_anvils({debug => $debug});
			my $node1_host_uuid = "";
			my $node2_host_uuid = "";
			if ($anvil_uuid)
			{
				$node1_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node1_host_uuid};
				$node2_host_uuid = $anvil->data->{anvils}{anvil_uuid}{$anvil_uuid}{anvil_node2_host_uuid};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					node1_host_uuid => $node1_host_uuid,
					node1_host_uuid => $node2_host_uuid, 
				}});
			}
			
			# If we were passed an anvil_uuid but not a host_uuid, don't use this machine's host UUID
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
			
			# These will be set if multiple options are found in the database.
			foreach my $this_resource (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_resource => $this_resource }});
				foreach my $this_host_name (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$this_resource}{host}})
				{
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_name => $this_host_name }});
					foreach my $this_volume (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$this_resource}{host}{$this_host_name}{volume}})
					{
						my $this_minor = $anvil->data->{new}{resource}{$this_resource}{host}{$this_host_name}{volume}{$this_volume}{device_minor};
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							this_volume => $this_volume,
							this_minor  => $this_minor, 
						}});
						next if $this_minor ne $minor;
						
						my $this_host_uuid = $anvil->Get->host_uuid_from_name({host_name => $this_host_name});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_host_uuid => $this_host_uuid }});
						next if not $this_host_uuid;
						
						# Sorry, this is a bit of a mess. Logic is; If we're given a 
						# host_uuid, and it matches, use it. Otherwise, if an 
						# anvil_uuid is passed, and either node 1 or 2's UUID, or if
						# there is a DR host, if it's host UUID matches, then we can
						# use this.
						if (
						    (
						     ($host_uuid) && ($host_uuid eq $this_host_uuid)
						    ) 
						    or 
						    (
						     ($anvil_uuid) && 
						     (
						      ($this_host_uuid eq $node1_host_uuid) or 
						      ($this_host_uuid eq $node2_host_uuid)
						     )
						    )
						   )
						{
							# This is a node in the requested cluster.
							$resource = $this_resource;
							$volume   = $this_volume;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
								resource => $resource, 
								volume   => $volume, 
							}});
							last;
							
							if (not $host_uuid)
							{
								$host_uuid = $this_host_uuid;
								$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
							}
						}
					}
				}
			}
		}
		
		# Did I find the resource and volume?
		if ($resource)
		{
			my $query = "
SELECT 
    scan_drbd_resource_host_uuid, 
    scan_drbd_resource_xml, 
    modified_date 
FROM 
    scan_drbd_resources 
WHERE 
    scan_drbd_resource_name = ".$anvil->Database->quote($resource);
			if ($host_uuid)
			{
				$query .= "
AND 
    scan_drbd_resource_host_uuid = ".$anvil->Database->quote($host_uuid);
			}
			$query .= "
ORDER BY 
    modified_date DESC
LIMIT 1
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
			
			my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
			my $count   = @{$results};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				results => $results, 
				count   => $count, 
			}});
			
			if (not $count)
			{
				# Group not found.
				return("");
			}
			
			my $scan_drbd_resource_host_uuid = $results->[0]->[0];
			my $scan_drbd_resource_xml       = $results->[0]->[1];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				scan_drbd_resource_host_uuid => $scan_drbd_resource_host_uuid, 
				scan_drbd_resource_xml       => $scan_drbd_resource_xml, 
			}});
			
			if (not $gathered_data)
			{
				$anvil->DRBD->gather_data({
					debug => 3,
					xml   => $scan_drbd_resource_xml,
				});
			}
			
			# Dig out the LV behind the volume.
			foreach my $this_host_name (sort {$a cmp $b} keys %{$anvil->data->{new}{resource}{$resource}{host}})
			{
				my $this_host_uuid = $anvil->Get->host_uuid_from_name({host_name => $this_host_name});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:this_host_name" => $this_host_name, 
					"s2:this_host_uuid" => $this_host_uuid, 
				}});
				next if (($host_uuid) && ($this_host_uuid ne $host_uuid));
				my $device_path  = $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{device_path};
				my $backing_disk = $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{backing_disk};
				my $device_minor = $anvil->data->{new}{resource}{$resource}{host}{$this_host_name}{volume}{$volume}{device_minor};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s3:device_path"    => $device_path,
					"s4:backing_disk"   => $backing_disk,
					"s5:device_minor"   => $device_minor,
				}});
				
				if (not $host_uuid)
				{
					$host_uuid = $scan_drbd_resource_host_uuid;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
				}
				
				$logical_volume = $backing_disk;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { logical_volume => $logical_volume }});
				last;
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { logical_volume => $logical_volume }});
	if ($logical_volume)
	{
		### NOTE: We're pulling more columns than we need to help with logging.
		# Verify this is an LV and, if so, what VG is it on?
		my $query = "
SELECT 
    a.scan_lvm_lv_name, 
    a.scan_lvm_lv_on_vg, 
    b.scan_lvm_vg_internal_uuid 
FROM 
    scan_lvm_lvs a, 
    scan_lvm_vgs b 
WHERE 
    a.scan_lvm_lv_host_uuid = b.scan_lvm_vg_host_uuid 
AND 
    a.scan_lvm_lv_on_vg = b.scan_lvm_vg_name 
AND 
    a.scan_lvm_lv_path = ".$anvil->Database->quote($logical_volume);
		if ($host_uuid)
		{
			$query .= "
AND 
    scan_lvm_lv_host_uuid = ".$anvil->Database->quote($host_uuid);
		}
		$query .= "
LIMIT 1
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		my $count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		if (not $count)
		{
			# LV not found.
			return("");
		}
		
		my $scan_lvm_lv_name          = $results->[0]->[0];
		my $scan_lvm_lv_on_vg         = $results->[0]->[1];
		my $scan_lvm_vg_internal_uuid = $results->[0]->[2];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			scan_lvm_lv_name          => $scan_lvm_lv_name, 
			scan_lvm_lv_on_vg         => $scan_lvm_lv_on_vg, 
			scan_lvm_vg_internal_uuid => $scan_lvm_vg_internal_uuid, 
		}});
		
		$query = "
SELECT 
    a.storage_group_uuid, 
    a.storage_group_name 
FROM 
    storage_groups a, 
    storage_group_members b 
WHERE 
    a.storage_group_uuid = b.storage_group_member_storage_group_uuid 
AND 
    b.storage_group_member_vg_uuid = ".$anvil->Database->quote($scan_lvm_vg_internal_uuid)."
LIMIT 1
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
		
		$results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
		$count   = @{$results};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			results => $results, 
			count   => $count, 
		}});
		
		if (not $count)
		{
			# Storage group not found.
			return("");
		}
		
		my $storage_group_uuid = $results->[0]->[0];
		my $storage_group_name = $results->[0]->[1];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			storage_group_uuid => $storage_group_uuid, 
			storage_group_name => $storage_group_name, 
		}});
		
		# Done!
		return($storage_group_uuid);
	}
	
	return("");
}


=head2 get_vg_name

This method takes a Storage Group UUID and a host UUID, and returns the volume group name associated with those. If there is a problem, C<< !!error!! >> is returned.

 my $vg_name = $anvil->Storage->get_vg_name({
 	host_uuid          => $dr_host_uuid,
 	storage_group_uuid => $storage_group_uuid, 
 });

Parameters;

=head3 host_uuid (optional, default Get->host_uuid)

This is the host's UUID that holds the VG name being searched for.

=head3 storage_group_uuid (required)

This is the Storage Group UUID being searched for.

=cut
sub get_vg_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $test      = defined $parameter->{test}  ? $parameter->{test}  : 0;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->get_vg_name()" }});
	
	my $host_uuid          = defined $parameter->{host_uuid}          ? $parameter->{host_uuid}          : "";
	my $storage_group_uuid = defined $parameter->{storage_group_uuid} ? $parameter->{storage_group_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		host_uuid          => $host_uuid,
		storage_group_uuid => $storage_group_uuid,
	}});
	
	if (not $host_uuid)
	{
		$host_uuid = $anvil->Get->host_uuid();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	}
	if (not $storage_group_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->get_vg_name()", parameter => "storage_group_uuid" }});
		return('!!error!!');
	}
	
	my $query = "
SELECT 
    b.scan_lvm_vg_name 
FROM 
    storage_group_members a, 
    scan_lvm_vgs b 
WHERE 
    a.storage_group_member_vg_uuid = b.scan_lvm_vg_internal_uuid 
AND 
    a.storage_group_member_storage_group_uuid = ".$anvil->Database->quote($storage_group_uuid)." 
AND 
    a.storage_group_member_host_uuid          = ".$anvil->Database->quote($host_uuid)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if (not $count)
	{
		# Not found
		return("");
	}
	
	my $scan_lvm_vg_name = $results->[0]->[0];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { scan_lvm_vg_name => $scan_lvm_vg_name }});
	
	return($scan_lvm_vg_name); 
}


=head2 make_directory

This creates a directory (and any parent directories).

 $anvil->Storage->make_directory({directory => "/foo/bar/baz", owner => "me", group => "me", mode => "0755"});

If it fails to create the directory, C<< 1 >> will be returned. Otherwise, C<< 0 >> will be returned.

Parameters;

=head3 directory (required)

This is the name of the directory to create.

=head3 group (optional, default is the main group of the user running the program)

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

=head3 user (optional, default is the user running the program)

This is the user name or user ID to set the ownership of the directory to.

=cut
sub make_directory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $test      = defined $parameter->{test}  ? $parameter->{test}  : 0;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->make_directory()" }});
	
	my $directory   = defined $parameter->{directory}   ? $parameter->{directory}   : "";
	my $group       = defined $parameter->{group}       ? $parameter->{group}       : getgrgid($();
	my $mode        = defined $parameter->{mode}        ? $parameter->{mode}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : getpwuid($<);
	my $failed      = 0;
	print $THIS_FILE." ".__LINE__."; debug: [".$debug."], directory: [".$directory."], target: [".$target."]\n" if $test;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		test        => $test,
		directory   => $directory,
		group       => $group, 
		mode        => $mode,
		port        => $port, 
		password    => $anvil->Log->is_secure($password), 
		remote_user => $remote_user, 
		target      => $target,
		user        => $user,
	}});
	
	# Make sure the user and group and just one digit or word.
	$user  =~ s/^(\S+)\s.*$/$1/;
	$group =~ s/^(\S+)\s.*$/$1/;
	print $THIS_FILE." ".__LINE__."; user: [".$user."], group: [".$group."]\n" if $test;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		group => $group, 
		user  => $user,
	}});
	
	# Break the directories apart.
	my $working_directory = "";
	foreach my $this_directory (split/\//, $directory)
	{
		next if not $this_directory;
		$working_directory .= "/$this_directory";
		$working_directory =~ s/\/\//\//g;
		print $THIS_FILE." ".__LINE__."; working_directory: [".$working_directory."]\n" if $test;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { working_directory => $working_directory }});
		
		# Are we working locally or remotely?
		if ($anvil->Network->is_local({debug => $debug, host => $target}))
		{
			# Locally.
			if (not -e $working_directory)
			{
				# Directory doesn't exist, so create it.
				my $error      = "";
				my $shell_call = $anvil->data->{path}{exe}{'mkdir'}." ".$working_directory;
				print $THIS_FILE." ".__LINE__."; shell_call: [".$shell_call."]\n" if $test;
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
				
				print $THIS_FILE." ".__LINE__."; mode: [".$mode."]\n" if $test;
				if ($mode)
				{
					$anvil->Storage->change_mode({debug => $debug, path => $working_directory, mode => $mode});
				}
				print $THIS_FILE." ".__LINE__."; user: [".$user."], group: [".$group."]\n" if $test;
				if (($user) or ($group))
				{
					$anvil->Storage->change_owner({debug => $debug, path => $working_directory, user => $user, group => $group});
				}
				
				if (not -e $working_directory)
				{
					$failed = 1;
					print $THIS_FILE." ".__LINE__."; failed: [".$failed."]\n" if $test;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0168", variables => { 
						directory   => $working_directory, 
						error       => $error,
					}});
				}
			}
		}
		else
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
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chmod'}." ".$mode." ".$working_directory."\n";
			}
			if (($user) && ($group))
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chown'}." ".$user.":".$group." ".$working_directory."\n";
			}
			elsif ($user)
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chown'}." ".$user.": ".$working_directory."\n";
			}
			elsif ($group)
			{
				$shell_call .= "    ".$anvil->data->{path}{exe}{'chown'}." :".$group." ".$working_directory."\n";
			}
			$shell_call .= "    if [ -d '".$working_directory."' ];
    then
        ".$anvil->data->{path}{exe}{echo}." 'created'
    else
        ".$anvil->data->{path}{exe}{echo}." 'failed to create'
    fi;
fi;";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
			my ($output, $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				target      => $target,
				port        => $port, 
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
				shell_call  => $shell_call,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output, 
			}});
			if ($output eq "failed to create")
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
		print $THIS_FILE." ".__LINE__."; failed: [".$failed."]\n" if $test;
		last if $failed;
	}
	
	print $THIS_FILE." ".__LINE__."; failed: [".$failed."]\n" if $test;
	return($failed);
}


=head2 manage_lvm_conf

B<< Note >>: This only works on EL8. If used on another distro, this method will return without actually doing anything.

This method configures C<< lvm.conf >> to add the C<< filter = [ ... ] >> to ensure DRBD devices aren't scanned.

If there was a problem, C<< 1 >> is returned. Otherwise, C<< 0 >> is returned.

Parameters;

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 target (optional)

If set, the file will be copied on the target machine. This must be either an IP address or a resolvable host name. 

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=cut
sub manage_lvm_conf
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->manage_lvm_conf()" }});
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target,
	}});
	
	### NOTE: Only add the filter on EL8 machines.
	my ($os_type, $os_arch) = $anvil->Get->os_type({debug => $debug});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		os_type => $os_type, 
		os_arch => $os_arch,
	}});
	if (($os_type ne "rhel8") && ($os_type ne "centos-stream8"))
	{
		# Not EL8, return
		return(0);
	}
	
	my $body = $anvil->Storage->read_file({
		debug       => $debug,
		file        => $anvil->data->{path}{configs}{'lvm.conf'}, 
		password    => $password, 
		port        => $port, 
		target      => $target, 
		remote_user => $remote_user, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
	
	if ($body eq "!!error!!")
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0254"});
		return(1);
	}
	
	my $in_device = 0;
	foreach my $line (split/\n/, $body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		next if $line =~ /^#/ or $line =~ /^\s+#/;
		
		if ($line =~ /^devices \{/)
		{
			$in_device = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_device => $in_device }});
		}
		if ($in_device)
		{
			$line =~ s/^\s+//;
			if ($line =~ /^\}/)
			{
				$in_device = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_device => $in_device }});
				last;
			}
			if ($line =~ /^filter = \[(.*?)\]/)
			{
				# Filter exists, we won't change it.
				my $filter = $1;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 2, key => "log_0594", variables => { filter => $filter }});
				return(0);
			}
		}
	}
	
	# If I made it here, I need to add the filter.
	   $in_device    = 0;
	my $filter_added = 0;
	my $new_body     = "";
	my $filter_line  = 'filter = [ "r|/dev/drbd*|" ]';
	foreach my $line (split/\n/, $body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		
		if ($line =~ /^devices \{/)
		{
			$in_device = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_device => $in_device }});
		}
		if ($in_device)
		{
			if ($line =~ /^\}/)
			{
				$in_device = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_device => $in_device }});
				
				# If we didn't find where to inject the filter, do it now.
				if (not $filter_added)
				{
					$new_body .= "\t".$filter_line."\n";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { filter_line => $filter_line }});
				}
			}
			if (($line =~ /# filter = \[ "a\|\.\*\|" \]/) && (not $filter_added))
			{
				# Add the filter here
				$new_body     .= $line."\n";
				$new_body     .= "\t".$filter_line."\n";
				$filter_added =  1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					filter_added => $filter_added, 
					filter_line  => $filter_line,
				}});
				next;
			}
		}
		$new_body .= $line."\n";
	}
	
	# Write the file out.
	my $error = $anvil->Storage->write_file({
		debug       => $debug,
		body        => $new_body,
		file        => $anvil->data->{path}{configs}{'lvm.conf'},
		group       => "root", 
		mode        => "0644",
		overwrite   => 1,
		backup      => 1,
		user        => "root",
		password    => $password, 
		port        => $port, 
		target      => $target, 
		remote_user => $remote_user, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { error => $error }});
	
	if ($error)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0255"});
		return(1);
	}
	else
	{
		# Record that we updated the lvm.conf.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0595", variables => { filter => $filter_line }});
	}
	
	return(0);
}


=head2 move_file

This moves a file, with a few additional checks like creating the target directory if it doesn't exist, aborting if the file already exists in the target, etc. It can move files on the local or a remote machine.

As with the system copy, the target can be a directory (denoted with an ending c<< / >>), or a it can be renamed in the process (but not ending with C<< / >>).

 # Example moving
 $anvil->Storage->move_file({source_file => "/some/file", target_file => "/another/directory/"});

 # Example moving with a rename at the same time
 $anvil->Storage->move_file({source_file => "/some/file", target_file => "/another/directory/new_name"});

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
sub move_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->move_file()" }});
	
	my $overwrite   = defined $parameter->{overwrite}   ? $parameter->{overwrite}   : 0;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $source_file = defined $parameter->{source_file} ? $parameter->{source_file} : "";
	my $target_file = defined $parameter->{target_file} ? $parameter->{target_file} : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		overwrite   => $overwrite,
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		remote_user => $remote_user, 
		source_file => $source_file, 
		target_file => $target_file,
		target      => $target,
	}});
	
	if (not $source_file)
	{
		# No source passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->move_file()", parameter => "source_file" }});
		return(1);
	}
	if (not $target_file)
	{
		# No target passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->move_file()", parameter => "target_file" }});
		return(2);
	}
	
	# If we have a target directory, pull the file name off the source for the target checks.
	my ($directory, $file) = ($target_file =~ /^(.*)\/(.*?)$/);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		directory => $directory, 
		file      => $file,
	}});
	if (not $file)
	{
		($file)      =  ($source_file =~ /^.*\/(.*?)$/);
		$target_file .= $file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file        => $file,
			target_file => $target_file, 
		}});
	}
	
	if ($anvil->Network->is_local({host => $target}))
	{
		# Copying locally
		if (not -e $source_file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0052", variables => { 
				method      => "move_file",
				source_file => $source_file,
			}});
			return(1);
		}
		
		# If the target exists, abort
		if ((-e $target_file) && (not $overwrite))
		{
			# This isn't an error.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0046", variables => {
				method      => "move_file",
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
					method      => "move_file",
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
		}
		
		# Now backup the file.
		my ($output, $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{'mv'}." -f ".$source_file." ".$target_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
	}
	else
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
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error  => $error,
			output => $output,
		}});
		if ($error)
		{
			# Something went wrong.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0267", variables => { 
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
			my ($line1, $line2) = (split/\n/, $output);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				line1 => $line1,
				line2 => $line2,
			}});
			if ($line1 eq "source file not found")
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0052", variables => { 
					method      => "move_file",
					source_file => $source_file,
				}});
				return(1);
			}
			if (($line1 eq "source file exists") && (not $overwrite))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0046", variables => {
					method      => "move_file",
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
			if ($line2 eq "target directory not found")
			{
				my $failed = $anvil->Storage->make_directory({
					debug       => $debug,
					directory   => $directory,
					password    => $password, 
					remote_user => $remote_user, 
					target      => $target,
					port        => $port, 
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0170", variables => {
					method      => "move_file",
					source_file => $source_file,
					target_file => $target_file,
				}});
				return(1);
			}
		
			# Now backup the file.
			my ($output, $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				target      => $target,
				port        => $port, 
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
				shell_call  => $anvil->data->{path}{exe}{mv}." -f ".$source_file." ".$target_file,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output,
			}});
		}
	}
	
	return(0);
}


=head2 parse_df

This calls C<< df >> and parses the output. Data is stored as:

 * storage::df::<kernel_device_name>::...

This method takes no parameters.

=cut
sub parse_df
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->parse_df()" }});
	
	my $shell_call = $anvil->data->{path}{exe}{df}." --exclude-type=tmpfs --exclude-type=devtmpfs --no-sync --block-size=1 --output=source,fstype,size,used,avail,target";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	if ($return_code)
	{
		# Failed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0079", variables => { 
			return_code => $return_code,
			output      => $output, 
		}});
		return(1);
	}
	
	foreach my $line (split/\n/, $output)
	{
		if ($line =~ /^\/dev\/(.*?)\s+(.*?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\/.*)$/)
		{
			my $kernel_device_name = $1;
			my $filesystem_type    = $2;
			my $size               = $3;
			my $used               = $4; 
			my $free               = $5; 
			my $mount_point        = $6;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:kernel_device_name' => $kernel_device_name,
				's2:mount_point'        => $mount_point, 
				's3:filesystem_type'    => $filesystem_type, 
				's4:size'               => $anvil->Convert->add_commas({number => $size})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $size}).")",
				's5:used'               => $anvil->Convert->add_commas({number => $used})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $used}).")",
				's6:free'               => $anvil->Convert->add_commas({number => $free})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $free}).")",
			}});
			
			# If the line starts with 'mapper', we need to figure out what dm-X device it is.
			if ($kernel_device_name =~ /^mapper\//)
			{
				# Use lstat
				my $device_path   = "/dev/".$kernel_device_name;
				my $device_mapper = readlink($device_path);
				if ($device_mapper =~ /^\.\.\/(.*)$/)
				{
					$kernel_device_name = $1;
				}
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					device_path        => $device_path,
					kernel_device_name => $kernel_device_name, 
				}});
			}
			
			$anvil->{storage}{df}{$kernel_device_name}{filesystem_type} = $filesystem_type;
			$anvil->{storage}{df}{$kernel_device_name}{mount_point}     = $mount_point;
			$anvil->{storage}{df}{$kernel_device_name}{size}            = $size;
			$anvil->{storage}{df}{$kernel_device_name}{used}            = $used;
			$anvil->{storage}{df}{$kernel_device_name}{free}            = $free;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"storage::df::${kernel_device_name}::filesystem_type" => $anvil->{storage}{df}{$kernel_device_name}{filesystem_type},
				"storage::df::${kernel_device_name}::mount_point"     => $anvil->{storage}{df}{$kernel_device_name}{mount_point},
				"storage::df::${kernel_device_name}::size"            => $anvil->Convert->add_commas({number => $anvil->{storage}{df}{$kernel_device_name}{size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->{storage}{df}{$kernel_device_name}{size}}).")",
				"storage::df::${kernel_device_name}::used"            => $anvil->Convert->add_commas({number => $anvil->{storage}{df}{$kernel_device_name}{used}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->{storage}{df}{$kernel_device_name}{used}}).")",
				"storage::df::${kernel_device_name}::free"            => $anvil->Convert->add_commas({number => $anvil->{storage}{df}{$kernel_device_name}{free}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->{storage}{df}{$kernel_device_name}{free}}).")",
			}});
		}
	}
	
	return(0);
}


=head2 parse_lsblk

This calls C<< lsblk >> (in json format) and parses the output. Data is stored as:

 * storage::lsblk::<kernel_device_name>::...

This method takes no parameters.
=cut
sub parse_lsblk
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->parse_lsblk()" }});
	
	my $shell_call = $anvil->data->{path}{exe}{lsblk}." --output KNAME,FSTYPE,MOUNTPOINT,UUID,PARTLABEL,PARTUUID,RO,RM,HOTPLUG,MODEL,SERIAL,SIZE,STATE,ALIGNMENT,PHY-SEC,LOG-SEC,ROTA,SCHED,TYPE,TRAN,VENDOR --bytes --json";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
	
	my ($output, $return_code) = $anvil->System->call({shell_call => $shell_call});
	if ($return_code)
	{
		# Failed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0079", variables => { 
			return_code => $return_code,
			output      => $output, 
		}});
		return(1);
	}
	
	my $json = JSON->new->allow_nonref;
	my $data = $json->decode($output);
	
	foreach my $hash_ref (@{$data->{blockdevices}})
	{
		my $kernel_device_name = $hash_ref->{kname};
		#next if $kernel_device_name =~ /^dm-/;
		#next if $kernel_device_name =~ /^mmcblk/;	# Add support for this later when 'System->parse_lshw' is done
		$anvil->{storage}{lsblk}{$kernel_device_name}{alignment_offset}         = defined $hash_ref->{alignment}  ? $hash_ref->{alignment}  : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{device_type}              = defined $hash_ref->{type}       ? $hash_ref->{type}       : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_type}          = defined $hash_ref->{fstype}     ? $hash_ref->{fstype}     : "";
		# This is the LVM formatted UUID, when it's an 'LVM2_member', so it should be easy to cross 
		# reference with: scan_lvm_lvs -> scan_lvm_lv_internal_uuid to map the LVs to a PV
		$anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_internal_uuid} = defined $hash_ref->{uuid}       ? $hash_ref->{uuid}       : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{hot_plug}                 = defined $hash_ref->{hotplug}    ? $hash_ref->{hotplug}    : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{logical_sector_size}      = defined $hash_ref->{'log-sec'}  ? $hash_ref->{'log-sec'}  : 0;
		$anvil->{storage}{lsblk}{$kernel_device_name}{model}                    = defined $hash_ref->{model}      ? $hash_ref->{model}      : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{model}                    = $anvil->Words->clean_spaces({string => $anvil->{storage}{lsblk}{$kernel_device_name}{model}});
		$anvil->{storage}{lsblk}{$kernel_device_name}{mount_point}              = defined $hash_ref->{mountpoint} ? $hash_ref->{mountpoint} : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{partition_label}          = defined $hash_ref->{partlabel}  ? $hash_ref->{partlabel}  : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{partition_uuid}           = defined $hash_ref->{partuuid}   ? $hash_ref->{partuuid}   : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{physical_sector_size}     = defined $hash_ref->{'phy-sec'}  ? $hash_ref->{'phy-sec'}  : 0;
		$anvil->{storage}{lsblk}{$kernel_device_name}{read_only}                = defined $hash_ref->{ro}         ? $hash_ref->{ro}         : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{removable}                = defined $hash_ref->{rm}         ? $hash_ref->{rm}         : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{rotating_drive}           = defined $hash_ref->{rota}       ? $hash_ref->{rota}       : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{serial_number}            = defined $hash_ref->{serial}     ? $hash_ref->{serial}     : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{serial_number}            = $anvil->Words->clean_spaces({string => $anvil->{storage}{lsblk}{$kernel_device_name}{serial_number}});
		$anvil->{storage}{lsblk}{$kernel_device_name}{scheduler}                = defined $hash_ref->{sched}      ? $hash_ref->{sched} : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{size}                     = defined $hash_ref->{size}       ? $hash_ref->{size}       : 0;
		$anvil->{storage}{lsblk}{$kernel_device_name}{'state'}                  = defined $hash_ref->{'state'}    ? $hash_ref->{'state'}    : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{transport}                = defined $hash_ref->{tran}       ? $hash_ref->{tran}       : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{type}                     = $anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_internal_uuid} ? "partition" : "drive";
		$anvil->{storage}{lsblk}{$kernel_device_name}{vendor}                   = defined $hash_ref->{vendor}     ? $hash_ref->{vendor}     : "";
		$anvil->{storage}{lsblk}{$kernel_device_name}{vendor}                   = $anvil->Words->clean_spaces({string => $anvil->{storage}{lsblk}{$kernel_device_name}{vendor}});
		
		# Standardize the 'swap' partitions to '<swap>'
		if (($anvil->{storage}{lsblk}{$kernel_device_name}{mount_point} eq "[SWAP]") or ((defined $hash_ref->{fstype}) && ($hash_ref->{fstype} eq "swap")))
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{mount_point} = "<swap>";
		}
		
		# There's precious little data that comes from SD cards.
		if ($kernel_device_name =~ /^mmcblk/)
		{
			if ($kernel_device_name =~ /^mmcblk\d+p\d+/)
			{
				# This is a partition
				$anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_type} = "partition";
				$anvil->{storage}{lsblk}{$kernel_device_name}{model}           = "SD Card"   if not $anvil->{storage}{lsblk}{$kernel_device_name}{model};
				$anvil->{storage}{lsblk}{$kernel_device_name}{transport}       = "pci"       if not $anvil->{storage}{lsblk}{$kernel_device_name}{transport};
				$anvil->{storage}{lsblk}{$kernel_device_name}{type}            = "ssd"       if not $anvil->{storage}{lsblk}{$kernel_device_name}{type};
				$anvil->{storage}{lsblk}{$kernel_device_name}{vendor}          = "unknown"   if not $anvil->{storage}{lsblk}{$kernel_device_name}{vendor};
			}
			else
			{
				# It's the drive
				$anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_type} = "drive";
			}
		}
		# Later, we'll want to trace device mapper devices back to the real device behind them (being
		# LVM, crypt, etc). For now, this works.
		if ($kernel_device_name =~ /^dm-/)
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_type} = "partition";
			$anvil->{storage}{lsblk}{$kernel_device_name}{model}           = "Device Mapper" if not $anvil->{storage}{lsblk}{$kernel_device_name}{model};
			$anvil->{storage}{lsblk}{$kernel_device_name}{transport}       = "virtual"       if not $anvil->{storage}{lsblk}{$kernel_device_name}{transport};
			$anvil->{storage}{lsblk}{$kernel_device_name}{type}            = "virtual"       if not $anvil->{storage}{lsblk}{$kernel_device_name}{type};
			$anvil->{storage}{lsblk}{$kernel_device_name}{vendor}          = "Linux"         if not $anvil->{storage}{lsblk}{$kernel_device_name}{vendor};
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"storage::lsblk::${kernel_device_name}::alignment_offset"         => $anvil->{storage}{lsblk}{$kernel_device_name}{alignment_offset},
			"storage::lsblk::${kernel_device_name}::device_type"              => $anvil->{storage}{lsblk}{$kernel_device_name}{device_type},
			"storage::lsblk::${kernel_device_name}::filesystem_type"          => $anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_type},
			"storage::lsblk::${kernel_device_name}::filesystem_internal_uuid" => $anvil->{storage}{lsblk}{$kernel_device_name}{filesystem_internal_uuid},
			"storage::lsblk::${kernel_device_name}::hot_plug"                 => $anvil->{storage}{lsblk}{$kernel_device_name}{hot_plug},
			"storage::lsblk::${kernel_device_name}::logical_sector_size"      => $anvil->{storage}{lsblk}{$kernel_device_name}{logical_sector_size},
			"storage::lsblk::${kernel_device_name}::model"                    => $anvil->{storage}{lsblk}{$kernel_device_name}{model},
			"storage::lsblk::${kernel_device_name}::mount_point"              => $anvil->{storage}{lsblk}{$kernel_device_name}{mount_point},
			"storage::lsblk::${kernel_device_name}::partition_label"          => $anvil->{storage}{lsblk}{$kernel_device_name}{partition_label},
			"storage::lsblk::${kernel_device_name}::partition_uuid"           => $anvil->{storage}{lsblk}{$kernel_device_name}{partition_uuid},
			"storage::lsblk::${kernel_device_name}::physical_sector_size"     => $anvil->{storage}{lsblk}{$kernel_device_name}{physical_sector_size},
			"storage::lsblk::${kernel_device_name}::read_only"                => $anvil->{storage}{lsblk}{$kernel_device_name}{read_only},
			"storage::lsblk::${kernel_device_name}::removable"                => $anvil->{storage}{lsblk}{$kernel_device_name}{removable},
			"storage::lsblk::${kernel_device_name}::rotating_drive"           => $anvil->{storage}{lsblk}{$kernel_device_name}{rotating_drive},
			"storage::lsblk::${kernel_device_name}::serial_number"            => $anvil->{storage}{lsblk}{$kernel_device_name}{serial_number},
			"storage::lsblk::${kernel_device_name}::scheduler"                => $anvil->{storage}{lsblk}{$kernel_device_name}{scheduler},
			"storage::lsblk::${kernel_device_name}::size"                     => $anvil->Convert->add_commas({number => $anvil->{storage}{lsblk}{$kernel_device_name}{size}})." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $anvil->{storage}{lsblk}{$kernel_device_name}{size}}).")",
			"storage::lsblk::${kernel_device_name}::state"                    => $anvil->{storage}{lsblk}{$kernel_device_name}{'state'},
			"storage::lsblk::${kernel_device_name}::type"                     => $anvil->{storage}{lsblk}{$kernel_device_name}{type},
			"storage::lsblk::${kernel_device_name}::transport"                => $anvil->{storage}{lsblk}{$kernel_device_name}{transport},
			"storage::lsblk::${kernel_device_name}::vendor"                   => $anvil->{storage}{lsblk}{$kernel_device_name}{vendor},
		}});
	}
	
	# Now loop through devices and pass parent information (like transport, model, etc) from devices down to partitions.
	my $parent_device = "";
	foreach my $kernel_device_name (sort {$a cmp $b} keys %{$anvil->{storage}{lsblk}})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { kernel_device_name => $kernel_device_name }});
		
		if ($anvil->{storage}{lsblk}{$kernel_device_name}{type} eq "drive")
		{
			$parent_device = $kernel_device_name;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { parent_device => $parent_device }});
			next;
		}
		
		if (($parent_device) && (not $anvil->{storage}{lsblk}{$kernel_device_name}{model}))
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{model} = $anvil->{storage}{lsblk}{$parent_device}{model};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"storage::lsblk::${kernel_device_name}::model" => $anvil->{storage}{lsblk}{$kernel_device_name}{model},
			}});
		}
		if (($parent_device) && (not $anvil->{storage}{lsblk}{$kernel_device_name}{serial_number}))
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{serial_number} = $anvil->{storage}{lsblk}{$parent_device}{serial_number};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"storage::lsblk::${kernel_device_name}::serial_number" => $anvil->{storage}{lsblk}{$kernel_device_name}{serial_number},
			}});
		}
		if (($parent_device) && (not $anvil->{storage}{lsblk}{$kernel_device_name}{vendor}))
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{vendor} = $anvil->{storage}{lsblk}{$parent_device}{vendor};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"storage::lsblk::${kernel_device_name}::vendor" => $anvil->{storage}{lsblk}{$kernel_device_name}{vendor},
			}});
		}
		if (($parent_device) && (not $anvil->{storage}{lsblk}{$kernel_device_name}{transport}))
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{transport} = $anvil->{storage}{lsblk}{$parent_device}{transport};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"storage::lsblk::${kernel_device_name}::transport" => $anvil->{storage}{lsblk}{$kernel_device_name}{transport},
			}});
		}
		if (($parent_device) && (not $anvil->{storage}{lsblk}{$kernel_device_name}{'state'}))
		{
			$anvil->{storage}{lsblk}{$kernel_device_name}{'state'} = $anvil->{storage}{lsblk}{$parent_device}{'state'};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"storage::lsblk::${kernel_device_name}::state" => $anvil->{storage}{lsblk}{$kernel_device_name}{'state'},
			}});
		}
	}

	return(0);
}


=head2 push_file

This takes a file and pushes it to all other machines in the cluster, serially. For machines that can't be accessed, a job is registered to pull the file.

If C<< switches::job-uuid >> is set, the corresponding job will be updated. The progress assumes that C<< sys::progress >> is set.

Parameters;

=head3 file (required)

This is the source file to copy from locally and push it to all peers' C<< /mnt/shared/files/ >> directory.

=cut
sub push_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->push_file()" }});
	
	# Setup default values
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $file_uuid = defined $parameter->{file_uuid} ? $parameter->{file_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file      => $file,
		file_uuid => $file_uuid,
	}});
	
	if (not $file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->push_file()", parameter => "file" }});
		return("!!error!!");
	}
	if (not -f $file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0105", variables => { file => $file }});
		return("!!error!!");
	}
	
	$anvil->Database->get_files({debug => $debug});
	my $file_size                    =  0;
	my ($file_directory, $file_name) =  ($file =~ /^(.*)\/(.*?)$/);
	   $file_directory               =~ s/\/$//g;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		's1:file_directory' => $file_directory, 
		's2:file_name'      => $file_name,
	}});
	if (not $file_uuid)
	{
		# Can we find the file?
		foreach my $this_file_uuid (keys %{$anvil->data->{files}{file_uuid}})
		{
			my $this_file_name      =  $anvil->data->{files}{file_uuid}{$this_file_uuid}{file_name};
			my $this_file_directory =  $anvil->data->{files}{file_uuid}{$this_file_uuid}{file_directory};
			   $this_file_directory =~ s/\/$//g;
			my $this_file_size      =  $anvil->data->{files}{file_uuid}{$this_file_uuid}{file_size};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				this_file_uuid      => $this_file_uuid, 
				this_file_directory => $this_file_directory, 
				this_file_name      => $this_file_name,
				this_file_size      => $this_file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $this_file_size}).")", 
			}});
			
			if (($file_name      eq $this_file_name) && 
			    ($file_directory eq $this_file_directory))
			{
				# Found it.
				$file_uuid = $this_file_uuid;
				$file_size = $this_file_size;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					file_uuid => $file_uuid, 
					file_size => $file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}).")", 
				}});
				last;
			}
		}
	}
	
	if ((not $file_uuid) or (not $file_size))
	{
		$file_size = (stat($file))[7];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file_size => $file_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $file_size}).")", 
		}});
	}
	
	# Now copy this to our peers. We're going to do this serially so that we don't overwhelm the system,
	# Any hosts not currently online will have a job registered.
	$anvil->Database->get_hosts;
	my $host_uuid        = $anvil->Get->host_uuid();
	my $host_name        = $anvil->data->{hosts}{host_uuid}{$host_uuid}{host_name};
	my $target_directory = $anvil->data->{path}{directories}{shared}{files}."/";
	foreach my $do_host_type ("striker", "node", "dr")
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { do_host_type => $do_host_type }});
		foreach my $target_host_name (sort {$a cmp $b} keys %{$anvil->data->{sys}{hosts}{by_name}})
		{
			my $target_host_uuid       = $anvil->data->{sys}{hosts}{by_name}{$target_host_name};
			my $target_host_type       = $anvil->data->{hosts}{host_uuid}{$target_host_uuid}{host_type};
			my $target_short_host_name = $anvil->data->{hosts}{host_uuid}{$target_host_uuid}{short_host_name};
			next if $target_host_uuid eq $host_uuid;
			next if $target_host_type ne $do_host_type;
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				's1:target_host_name'       => $target_host_name, 
				's2:target_host_uuid'       => $target_host_uuid,
				's3:target_host_type'       => $target_host_type,
				's4:target_short_host_name' => $target_short_host_name, 
			}});
			
			my $matches = $anvil->Network->find_access({
				debug  => 2,
				target => $target_short_host_name, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { matches => $matches }});
			next if not $matches;
			next if $matches =~ /\D/;
			
			# Find a matching IP.
			# We prefer to use least to most used networks, with the IFN being the last choice.
			my $copied = 0;
			foreach my $network ("mn", "bcn", "sn", "ifn")
			{
				next if $copied;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { network => $network }});
				foreach my $network_name (sort {$a cmp $b} keys %{$anvil->data->{network_access}})
				{
					next if $copied;
					next if $network_name !~ /^$network/i;
					my $local_interface    = $anvil->data->{network_access}{$network_name}{local_interface};
					my $local_speed        = $anvil->data->{network_access}{$network_name}{local_speed};
					my $local_ip_address   = $anvil->data->{network_access}{$network_name}{local_ip_address};
					my $local_subnet_mask  = $anvil->data->{network_access}{$network_name}{local_subnet_mask};
					my $target_interface   = $anvil->data->{network_access}{$network_name}{target_interface};
					my $target_speed       = $anvil->data->{network_access}{$network_name}{target_speed};
					my $target_ip_address  = $anvil->data->{network_access}{$network_name}{target_ip_address};
					my $target_subnet_mask = $anvil->data->{network_access}{$network_name}{target_subnet_mask};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
						's1:local_interface'    => $local_interface, 
						's2:local_speed'        => $local_speed, 
						's3:local_ip_address'   => $local_ip_address,
						's4:local_subnet_mask'  => $local_subnet_mask, 
						's5:target_interface'   => $target_interface, 
						's6:target_speed'       => $target_speed, 
						's7:target_ip_address'  => $target_ip_address,
						's8:target_subnet_mask' => $target_subnet_mask, 
					}});
					
					my $access = $anvil->Remote->test_access({target => $target_ip_address});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { access => $access }});
					
					if ($access)
					{
						### Rsync!
						# Estimate how long this will take. First, get the speed in 
						# Mbps and turn it into bytes per second, then into bytes per
						# second. We'll take 10% off, then calculate how many seconds
						# the copy will take.
						my $link_mbps           = $target_speed > $local_speed ? $target_speed : $local_speed;
						my $link_bps            = $link_mbps * 1000000;
						my $link_bytes_sec      = int($link_bps / 8);
						my $adjusted_byptes_sec = int($link_bytes_sec * 0.9);
						my $copy_seconds        = int($file_size / $adjusted_byptes_sec);
						my $say_copy_time       = $anvil->Convert->time({'time' => $copy_seconds, translate => 1});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
							's1:link_mbps'           => $anvil->Convert->add_commas({number => $link_mbps})." ".$anvil->Words->string({string => "#!string!suffix_0050!#"}),
							's2:link_bps'            => $anvil->Convert->add_commas({number => $link_bps})." ".$anvil->Words->string({string => "#!string!suffix_0048!#"}),
							's3:link_bytes_sec'      => $anvil->Convert->add_commas({number => $link_bytes_sec})." ".$anvil->Words->string({string => "#!string!suffix_0060!#"}),
							's4:adjusted_byptes_sec' => $anvil->Convert->add_commas({number => $adjusted_byptes_sec})." ".$anvil->Words->string({string => "#!string!suffix_0060!#"}),
							's5:copy_seconds'        => $anvil->Convert->add_commas({number => $copy_seconds})." ".$anvil->Words->string({string => "#!string!suffix_0007!#"}),
							's6:say_copy_time'       => $say_copy_time, 
							's7:file_size'           => $anvil->Convert->bytes_to_human_readable({"bytes" => $file_size}),
						}});
						
						my $variables = {
							host             => $target_short_host_name,
							network          => $network_name, 
							ip_address       => $target_ip_address, 
							source_file      => $file,
							target_directory => $target_directory, 
							size             => $anvil->Convert->bytes_to_human_readable({"bytes" => $file_size}),
							link_speed       => $anvil->Convert->add_commas({number => $link_mbps})." ".$anvil->Words->string({string => "#!string!suffix_0050!#"}), 
							eta_copy_time    => $say_copy_time, 
						};
						$anvil->data->{sys}{progress} += 2;
						$anvil->data->{sys}{progress} = 90 if $anvil->data->{sys}{progress} > 90;
						$anvil->Job->update_progress({
							progress  => $anvil->data->{sys}{progress}, 
							message   => "message_0195", 
				   			variables => $variables,
						});
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0195", variables => $variables});
						my $problem = $anvil->Storage->rsync({
							debug       => 2, 
							source      => $file, 
							destination => "root\@".$target_ip_address.":".$target_directory, 
							try_again   => 1, 
						});
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { problem => $problem }});
						if (not $problem)
						{
							$copied = 1;
							$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { copied => $copied }});
							
							$anvil->data->{sys}{progress} += 5;
							$anvil->data->{sys}{progress} = 90 if $anvil->data->{sys}{progress} > 90;
							$anvil->Job->update_progress({
								progress => $anvil->data->{sys}{progress}, 
								message  => "message_0310", 
							});
							$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0310"});
						}
					}
				}
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { file_uuid => $file_uuid }});
			if ($file_uuid)
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { copied => $copied }});
				if (not $copied)
				{
					# Failed to connect, register a job instead.
					my $variables = { host => $target_host_name };
					$anvil->data->{sys}{progress} += 5;
					$anvil->data->{sys}{progress} = 90 if $anvil->data->{sys}{progress} > 90;
					$anvil->Job->update_progress({
						progress  => $anvil->data->{sys}{progress}, 
						message   => "message_0196", 
						variables => $variables, 
					});
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0196", variables => $variables});
					my ($job_uuid) = $anvil->Database->insert_or_update_jobs({
						file            => $THIS_FILE, 
						line            => __LINE__, 
						job_command     => $anvil->data->{path}{exe}{'anvil-sync-shared'}.$anvil->Log->switches, 
						job_data        => "file_uuid=".$file_uuid, 
						job_name        => "storage::pull_file", 
						job_title       => "job_0132", 
						job_description => "job_0133", 
						job_progress    => 0,
						job_host_uuid   => $target_host_uuid,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { job_uuid => $job_uuid }});
				}
				
				# Mark the file as being on this host
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { do_host_type => $do_host_type }});
				if ($do_host_type ne "striker")
				{
					my $file_location_uuid = $anvil->Database->insert_or_update_file_locations({
						debug                   => 2, 
						file_location_file_uuid => $file_uuid, 
						file_location_host_uuid => $target_host_uuid, 
						file_location_active    => 1, 
						file_location_ready     => "same", 
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { file_location_uuid => $file_location_uuid }});
				}
			}
		}
	}
	
	return(0);
}


=head2 read_config

This method is used to read C<< Anvil::Tools >> style configuration files. These configuration files are in the format:

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->read_config()" }});
	
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
		my $path = $anvil->Storage->find({debug => $debug, file => $file});
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
			# Read it in! And force the issue so we don't use a cached version in case it's 
			# changed on disk.
			my $count = 0;
			my $body  = $anvil->Storage->read_file({cache => 0, force_read => 1, debug => $debug, file => $file});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
			foreach my $line (split/\n/, $body)
			{
				$line = $anvil->Words->clean_spaces({string => $line});
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

=head3 force_read (optional, default '1')

This is an optional parameter that, if set to C<< 0 >>, will allow an existing cached copy of the file to be used instead of actually reading the file from disk (again).

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->read_file()" }});
	
	my $body        = "";
	my $cache       = defined $parameter->{cache}       ? $parameter->{cache}       : 1;
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $force_read  = defined $parameter->{force_read}  ? $parameter->{force_read}  : 1;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : 0;
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		cache       => $cache, 
		file        => $file,
		force_read  => $force_read, 
		port        => $port, 
		password    => $anvil->Log->is_secure($password), 
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
	if ($anvil->Network->is_local({host => $target}))
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
			# Read from storage.
			my $shell_call = $file;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0012", variables => { shell_call => $shell_call }});
			open (my $file_handle, "<", $shell_call) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0015", variables => { shell_call => $shell_call, error => $! }});
			while(<$file_handle>)
			{
				### NOTE: Don't chop this, we want to record exactly what we read
				my $line = $_;
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0023", variables => { line => $line }});
				$body .= $line;
			}
			close $file_handle;
			
			if ($cache)
			{
				$anvil->data->{cache}{file}{$file} = $body;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cache::file::${file}" => $anvil->data->{cache}{file}{$file} }});
			}
		}
	}
	else
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
		
		### TODO: The '$file' should be bash-escaped.
		# See if the file even exists on the target.
		my $shell_call = $anvil->data->{path}{exe}{ls}." '".$file."'";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		my ($output, $error, $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error       => $error,
			output      => $output,
			return_code => $return_code, 
		}});
		if ($return_code)
		{
			# The file doesn't exist, so we can't copy it.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0465", variables => { 
				file   => $file,
				target => $target,
			}});
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
					### NOTE: Don't chop this, we want to record exactly what we read
					my $line = $_;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0023", variables => { line => $line }});
					$body .= $line;
				}
				close $file_handle;
				
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
					remote_file => $remote_user."\@".$target.":".$file,
					local_file  => $temp_file, 
				}});
				return("!!error!!");
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->read_mode()" }});
	
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->record_md5sums()" }});
	
	# Record the caller's MD5 sum
	my $caller                                   = $0;
	   $anvil->data->{md5sum}{$caller}{at_start} = $anvil->Get->md5sum({file => $0});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "md5sum::${caller}::at_start" => $anvil->data->{md5sum}{$caller}{at_start} }});
	
	# Record the sums of our perl modules.
	foreach my $module (sort {$a cmp $b} keys %INC)
	{
		my $module_file = $INC{$module};
		my $module_sum  = $anvil->Get->md5sum({file => $module_file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			module      => $module,
			module_file => $module_file, 
			module_sum  => $module_sum,
		}});
		
		$anvil->data->{md5sum}{$module_file}{at_start} = $module_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "md5sum::${module_file}::at_start" => $anvil->data->{md5sum}{$module_file}{at_start} }});
	}
	
	# Record sum(s) for the words file(s).
	foreach my $file (sort {$a cmp $b} keys %{$anvil->data->{words}})
	{
		my $words_sum = $anvil->Get->md5sum({file => $file});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			file      => $file,
			words_sum => $words_sum, 
		}});
		
		$anvil->data->{md5sum}{$file}{at_start} = $words_sum;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "md5sum::${file}::at_start" => $anvil->data->{md5sum}{$file}{at_start} }});
	}
	
	return(0);
}

=head2 rsync

This method copies a file or directory (and its contents) to or from a remote machine using C<< rsync >> and an C<< expect >> wrapper.

This supports the source B<< or >> the destination being remote, so the C<< source >> or C<< destination >> paramter can be in the format C<< <remote_user>@<target>:/file/path >>. If neither parameter is remove, a local C<< rsync >> operation will be performed.

On success, C<< 0 >> is returned. If a problem arises, C<< 1 >> is returned.

B<< NOTE >>: This method does not take C<< remote_user >> or C<< target >>. These are parsed off the C<< source >> or C<< destination >> parameter.

Parameters;

=head3 destination (required)

This is the destination being copied to. Be careful with the closing C<< / >>! Generally you will always want to have the destination end in a closing slash, to ensure the files go B<< under >> the estination directory. The same as is the case when using C<< rsync >> directly.

=head3 password (optional)

This is the password used to connect to the target machine (if either the source or target is remote).

=head3 port (optional, default 22)

This is the TCP port used to connect to the target machine.

=head3 source (required)

This is the file to copy via rsync.
	
The source can be a directory, or end in a wildcard (ie: C<< .../* >>) to copy multiple files/directories at the same time.

=head3 switches (optional, default -avS)

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->rsync()" }});
	
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
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		source      => $source,
		switches    => $switches,
		try_again   => $try_again, 
	}});
	
	# Make sure the port is sane;
	if ((not $port) or ($port =~ /\D/) or ($port < 0) or ($port > 65535))
	{
		$port = 22;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { port => $port }});
	}
	
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
	
	# If local, call rsync directly. If remote, and if we've got a password, setup the rsync wrapper
	my $wrapper_script = "";
	my $shell_call     = $anvil->data->{path}{exe}{rsync}." ".$switches." ".$source." ".$destination;
	if (not $anvil->Network->is_local({host => $target}))
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
			debug  => 2, 
			target => $target, 
			user   => $<,
		});
		
		# Do we have a password? If so, create a wrapper.
		if ($password)
		{
			# Remote target, wrapper needed.
			$wrapper_script = $anvil->Storage->_create_rsync_wrapper({
				debug    => $debug,
				target   => $target,
				password => $password, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { wrapper_script => $wrapper_script }});
			
			# And make the shell call
			$shell_call = $wrapper_script." ".$switches." ".$source." ".$destination;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		}
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { shell_call => $shell_call }});
	
	# Now make the call (this exposes the password so 'secure' is set).
	my $conflict               = "";
	my ($output, $return_code) = $anvil->System->call({secure => 1, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { output => $output, return_code => $return_code }});
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
				path        => $path, 
				line_number => $line_number, 
				failed      => $failed, 
				source      => $source, 
				destination => $destination, 
			}});
			
			if ($line_number)
			{
				$conflict = $anvil->data->{path}{exe}{cp}." ".$source." ".$destination." && ".$anvil->data->{path}{exe}{sed}." -ie '".$line_number."d' ".$source;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { conflict => $conflict }});
			}
		}
	}
	
	# If there was a conflict, clear it and try again.
	if (($conflict) && ($try_again))
	{
		# Remove the conflicting fingerprint.
		my ($output, $return_code) = $anvil->System->call({shell_call => $conflict});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { output => $output, return_code => $return_code }});
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

=head2 scan_directory

This takes a directory and scan its contents. What is found is stored in the following hashes;

 scan::directories::<parent_directory>::directory = <parent directory>
 scan::directories::<parent_directory>::name      = <file or directory name>
 scan::directories::<parent_directory>::type      = 'file', 'directory' or 'symlink' (other special types are ignored entirely)

If the fule is a directory, this is also set;

 scan::directories::<parent_directory>::mode = <the mode of the directory, already masked>

If the file is a symlink, this is also set;

 scan::directories::<parent_directory>::target = <target file>

If the file is an actual file, the following information is set;

 scan::directories::<parent_directory>::mode       = <the mode of the file, already masked>
 scan::directories::<parent_directory>::user_id    = <numeric user ID of the owner>
 scan::directories::<parent_directory>::group_id   = <numeric group ID of the owner>
 scan::directories::<parent_directory>::size       = <size in bytes>
 scan::directories::<parent_directory>::mtime      = <last modification time, in unixtime>
 scan::directories::<parent_directory>::mimetype   = <mimetype, as returned by File::MimeInfo->mimetype>
 scan::directories::<parent_directory>::executable = '0' or '1'

B<< Note >>: If the directory being scanned in the scan agent directory, and the file is executable and starts with c<< scan- >>, the file will be treated as a scan agent and stored in the special hash:

* scancore::agent::<file> = <full_path>

Parameters;

=head3 directory (required)

This is the full path to the directory to scan. 

=head4 no_files (optional, default 0)

If set to C<< 1 >>, this scans directories only, ignoring files and symlinks.

=head3 recursive (optional, default '0')

If set to C<< 1 >>, any directories found will be scanned as well.

B<< NOTE >>: Symlinks that point to directories will B<< NOT >> be scanned.

=head3 search_for (optional)

If set, the string will be searched for. If it is found, the B<< directory it is in >> will be stored in C<< scan::searched >>. The scan will end at this point, even if C<< recursive >> is set.

=cut
### TODO: Make this work on remote systems
sub scan_directory
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->scan_directory()" }});
	
	# Set a default if nothing was passed.
	my $directory  = defined $parameter->{directory}  ? $parameter->{directory}  : "";
	my $no_files   = defined $parameter->{no_files}   ? $parameter->{no_files}   : 0;
	my $recursive  = defined $parameter->{recursive}  ? $parameter->{recursive}  : 0;
	my $search_for = defined $parameter->{search_for} ? $parameter->{search_for} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		directory  => $directory,
		no_files   => $no_files, 
		recursive  => $recursive, 
		search_for => $search_for, 
	}});
	
	# This is used for storing scan agents we've found, when appropriate.
	my $scan_agent_directory = $anvil->data->{path}{directories}{scan_agents};
	
	# Setup the search variable, if needed.
	$anvil->data->{scan}{searched} = "" if not exists $anvil->data->{scan}{searched};
	
	# Does this directory exist?
	if (not $directory)
	{
		# Not even passed in
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->rsync()", parameter => "scan_directory" }});
		return(1);
	}
	if ((not -e $directory) or (not -d $directory))
	{
		# Nope.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0262", variables => { directory => $directory }});
		return(1);
	}
	
	# Results will be stored in this hash.
	$anvil->data->{scan}{directories}{$directory}{type} = "directory";
	
	# Now lets scan
	local(*DIRECTORY);
	opendir(DIRECTORY, $directory);
	while(my $file = readdir(DIRECTORY))
	{
		next if $file eq ".";
		next if $file eq "..";
		my $full_path                                            =  $directory."/".$file;
		   $full_path                                            =~ s/\/\//\//g; 
		$anvil->data->{scan}{directories}{$full_path}{directory} =  $directory;
		$anvil->data->{scan}{directories}{$full_path}{name}      =  $file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"scan::directories::${full_path}::directory" => $anvil->data->{scan}{directories}{$full_path}{directory}, 
			"scan::directories::${full_path}::name"      => $anvil->data->{scan}{directories}{$full_path}{name}, 
			full_path                                    => $full_path,
		}});
		
		if (($search_for) && ($file eq $search_for))
		{
			# Found what we're looking for, we're done.
			$anvil->data->{scan}{searched} = $directory;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scan::searched" => $anvil->data->{scan}{searched}, 
			}});
			return(0);
		}
		if (-d $full_path)
		{
			# This is a directory, dive into it is asked.
			my @details = stat($full_path);
			$anvil->data->{scan}{directories}{$full_path}{type} = "directory";
			$anvil->data->{scan}{directories}{$full_path}{mode} = sprintf("04%o", $details[2] & 07777);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scan::directories::${full_path}::type" => $anvil->data->{scan}{directories}{$full_path}{type}, 
				"scan::directories::${full_path}::mode" => $anvil->data->{scan}{directories}{$full_path}{mode}, 
			}});
			if (($recursive) && (not $anvil->data->{scan}{searched}))
			{
				$anvil->Storage->scan_directory({
					debug      => $debug, 
					directory  => $full_path, 
					recursive  => $recursive,
					no_files   => $no_files,
					search_for => $search_for,
				});
			}
		}
		elsif ((-l $full_path) && (not $no_files))
		{
			# Symlink
			$anvil->data->{scan}{directories}{$full_path}{type}   = "symlink";
			$anvil->data->{scan}{directories}{$full_path}{target} = readlink($full_path);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scan::directories::${full_path}::type"    => $anvil->data->{scan}{directories}{$full_path}{type}, 
				"scan::directories::${full_path}::taarget" => $anvil->data->{scan}{directories}{$full_path}{taarget}, 
			}});
		}
		elsif ((-f $full_path) && (not $no_files))
		{
			# Normal file.
			my @details = stat($full_path);
			$anvil->data->{scan}{directories}{$full_path}{type}       = "file";
			$anvil->data->{scan}{directories}{$full_path}{mode}       = sprintf("04%o", $details[2] & 07777);
			$anvil->data->{scan}{directories}{$full_path}{user_id}    = $details[4];
			$anvil->data->{scan}{directories}{$full_path}{group_id}   = $details[5];
			$anvil->data->{scan}{directories}{$full_path}{size}       = $details[7];
			$anvil->data->{scan}{directories}{$full_path}{mtime}      = $details[9];
			$anvil->data->{scan}{directories}{$full_path}{mimetype}   = mimetype($full_path);
			$anvil->data->{scan}{directories}{$full_path}{executable} = -x $full_path ? 1 : 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"scan::directories::${full_path}::type"       => $anvil->data->{scan}{directories}{$full_path}{type}, 
				"scan::directories::${full_path}::mode"       => $anvil->data->{scan}{directories}{$full_path}{mode}, 
				"scan::directories::${full_path}::user_id"    => $anvil->data->{scan}{directories}{$full_path}{user_id}, 
				"scan::directories::${full_path}::group_id"   => $anvil->data->{scan}{directories}{$full_path}{group_id}, 
				"scan::directories::${full_path}::size"       => $anvil->data->{scan}{directories}{$full_path}{size}, 
				"scan::directories::${full_path}::mtime"      => $anvil->data->{scan}{directories}{$full_path}{mtime}, 
				"scan::directories::${full_path}::mimetype"   => $anvil->data->{scan}{directories}{$full_path}{mimetype}, 
				"scan::directories::${full_path}::executable" => $anvil->data->{scan}{directories}{$full_path}{executable}, 
			}});
			
			# If this is a scan agent, we'll store info about it in a special hash.
			if ((-x $full_path) && ($file =~ /^scan-/) && ($full_path =~ /^$scan_agent_directory/))
			{
				# Found a scan agent.
				$anvil->data->{scancore}{agent}{$file} = $full_path;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"scancore::agent::${file}" => $anvil->data->{scancore}{agent}{$file}, 
				}});
			}
		}
	}
	closedir(DIRECTORY);
	
	return(0);
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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->search_directories()" }});
	
	# Set a default if nothing was passed.
	my $array      = defined $parameter->{directories} ? $parameter->{directories} : "";
	my $initialize = defined $parameter->{initialize}  ? $parameter->{initialize}  : "";

	# If PATH isn't set, set it (could have been scrubbed by a caller).
	if (not $ENV{PATH})
	{
		$ENV{PATH} = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin";
	}

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

=head3 append (optional, default 0)

If set to C<< 1 >>, and if the variable is not found, it will be appended to the end of the config file.

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->update_config()" }});
	
	my $append      = defined $parameter->{append}      ? $parameter->{append}      : 0;
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
		append      => $append, 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		secure      => $secure,
		target      => $target,
		value       => (not $secure) ? $value : $anvil->Log->is_secure($value),
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
				this_value    => not $is_secure ? $this_value : $anvil->Log->is_secure($this_value),
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
		if ($append)
		{
			# Add the variable to the config file.
			$new_file .= $variable."\t=\t".$value."\n";
			$update   =  1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
				new_file => $new_file,
				update   => $update, 
			}});
		}
		else
		{
			if ($anvil->Network->is_local({host => $target}))
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0174", variables => { 
					variable => $variable, 
					file     => $anvil->data->{path}{configs}{'anvil.conf'}, 
				}});
				return(1);
			}
			else
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0175", variables => { 
					variable => $variable, 
					file     => $anvil->data->{path}{configs}{'anvil.conf'}, 
					target   => $target,
				}});
				return(1);
			}
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
			group       => "striker-ui-api", 
			mode        => "0640",
			overwrite   => 1,
			secure      => 1,
			user        => "striker-ui-api",
			password    => $password, 
			port        => $port, 
			target      => $target, 
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { error => $error }});
	}
	
	return($error);
}

=head2 update_file

This reads in a file (if it already exists), compares it against a new body and updates it if there is a difference. This can work on remote files as well as local ones.

The return code indicates success; C<< 0 >> is returns if anything goes wrong. C<< 1 >> is returned if the file was updated and C<< 2 >> is returned if the file did not need to be updated.

Parameters;

=head3 backup (optional, default '1')

If the file needs to be updated, and if this is set to C<< 1 >>, a backup will be make before the file is updated.

=head3 body (optional)

This is the new body of the file. It should always be set, of course, but it is optional in case the new file is supposed to be empty.

=head3 file (required) 

This is the full path and file name of the file being updated.

=head3 port (optional, default 22)

If C<< target >> is set, this is the TCP port number used to connect to the remote machine.

=head3 password (optional)

If C<< target >> is set, this is the password used to log into the remote system as the C<< remote_user >>. If it is not set, an attempt to connect without a password will be made (though this will usually fail).

=head3 remote_user (optional, default root)

If C<< target >> is set, this is the user account that will be used when connecting to the remote system.

=head3 secure (optional)

If set to 'C<< 1 >>', the C<< body >> is treated as containing secure data for logging purposes.

=head3 target (optional)

If set, the config file will be updated on the target machine. This must be either an IP address or a resolvable host name. 

=cut
sub update_file
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->update_file()" }});
	
	my $backup      = defined $parameter->{backup}      ? $parameter->{backup}      : 1;
	my $body        = defined $parameter->{body}        ? $parameter->{body}        : "";
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : "";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $update      = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		backup      => $backup,
		body        => (not $body) ? $body : $anvil->Log->is_secure($body),
		file        => $file, 
		password    => $anvil->Log->is_secure($password), 
		port        => $port, 
		secure      => $secure,
		target      => $target,
		remote_user => $remote_user, 
	}});
	
	if (not $file)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Storage->update_file()", parameter => "file" }});
		return(1);
	}
	
	# Read the old file...
	my $old_body = $anvil->Storage->read_file({
		debug       => $debug,
		file        => $file, 
		password    => $password, 
		port        => $port, 
		target      => $target, 
		remote_user => $remote_user, 
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => $secure, list => { old_body => $old_body }});
	
	if ($old_body eq "!!error!!")
	{
		# File doesn't exist? Lets try writing it.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0228", variables => { file => $file }});
		$update = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { update => $update }});
	}
	elsif ($old_body ne $body)
	{
		# Something has changed. If we can get a reasonable diff, we'll show it.
		# Credit: https://stackoverflow.com/questions/2047996/how-can-i-guess-if-a-string-has-text-or-binary-data-in-perl
		my $is_utf8 = utf8::is_utf8($old_body);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { is_utf8 => $is_utf8 }});
		if (($is_utf8) or ($old_body =~ m/\A [[:ascii:]]* \Z/xms))
		{
			# $old_body is a text, so we're likely looking at a text file and can Diff it.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0230", variables => { 
				file => $file,
				diff => diff \$old_body, \$body, { STYLE => 'Unified' },
			}});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0229", variables => { file => $file }});
		}
		$update = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { update => $update }});
		
		if ($backup)
		{
			# Backup the file now.
			my $backup_file = $anvil->Storage->backup({
				file        => $file,
				debug       => $debug, 
				target      => $target,
				port        => $port, 
				user        => $remote_user, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { backup_file => $backup_file }});
		}
	}
	else
	{
		# Update not needed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0231", variables => { file => $file }});
		return(2);
	}
	
	# Update/write?
	if ($update)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0232", variables => { file => $file }});
		
		my $return = $anvil->Storage->write_file({
			body        => $body,
			debug       => $debug,
			file        => $file,
			overwrite   => 1,
			secure      => $secure,
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return }});
		
		if ($return)
		{
			# Something went wrong.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0233", variables => { file => $file, 'return' => $return }});
			return(0);
		}
		return(1);
	}
	
	return(2);
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

=head3 backup (optional, default '1')

When writing to a file that already exists, and C<< overwrite >> is true, the existing backup will be backed up prior to being rewritten.

=head3 binary (optional, default '0')

When set to '1', this indicates that the body is binary data, which prevents logging of the file body.

=head3 body (optional)

This is the contents of the file. If it is blank, an empty file will be created (similar to using 'C<< touch >>' on the command line).

=head3 file (required)

This is the name of the file to write.

NOTE: The file must include the full directory it will be written into.

=head3 group (optional, default is the main group of the user running the program)

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

=head3 user (optional, default is the user running the program)

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
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->write_file()" }});
	
	my $backup      = defined $parameter->{backup}      ? $parameter->{backup}      : 1;
	my $binary      = defined $parameter->{binary}      ? $parameter->{binary}      : 0;
	my $body        = defined $parameter->{body}        ? $parameter->{body}        : "";
	my $file        = defined $parameter->{file}        ? $parameter->{file}        : "";
	my $group       = defined $parameter->{group}       ? $parameter->{group}       : getgrgid($();
	my $mode        = defined $parameter->{mode}        ? $parameter->{mode}        : "";
	my $overwrite   = defined $parameter->{overwrite}   ? $parameter->{overwrite}   : 0;
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : 22;
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $secure      = defined $parameter->{secure}      ? $parameter->{secure}      : 0;
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $user        = defined $parameter->{user}        ? $parameter->{user}        : getpwuid($<);
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $error       = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
		backup      => $backup, 
		binary      => $binary, 
		file        => $file,
		group       => $group, 
		mode        => $mode,
		overwrite   => $overwrite,
		port        => $port, 
		password    => $anvil->Log->is_secure($password), 
		secure      => $secure,
		target      => $target,
		user        => $user,
		remote_user => $remote_user, 
	}});
	if (not $binary)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, list => { 
			body => (not $secure) ? $body : $anvil->Log->is_secure($body),
		}});
	}
	
	# Make sure the user and group and just one digit or word.
	$user  =~ s/^(\S+)\s.*$/$1/;
	$group =~ s/^(\S+)\s.*$/$1/;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		group => $group, 
		user  => $user,
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
	
	my $is_local = $anvil->Network->is_local({host => $target});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { is_local => $is_local }});
	
	# Now, are we writing locally or on a remote system?
	if ($is_local)
	{
		# Local
		if (-e $file)
		{
			if (not $overwrite)
			{
				# Nope.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0040", variables => { file => $file }});
				$error = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
			}
			
			if ($backup)
			{
				# Back it up.
				my $backup_file = $anvil->Storage->backup({
					debug => $debug, 
					file  => $file,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { backup_file => $backup_file }});
			}
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
		if (not $error)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { directory => $directory }});
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
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { secure => $secure }});
			if ($secure)
			{
				$anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{touch}." ".$file});
				$anvil->Storage->change_mode({debug => $debug, path => $file, mode => $mode});
			}
			
			# Now write the file.
			my $shell_call = $file;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 0, key => "log_0013", variables => { shell_call => $shell_call }});
			#open (my $file_handle, ">", $shell_call) or $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, secure => $secure, priority => "err", key => "log_0016", variables => { shell_call => $shell_call, error => $! }});
			open (my $file_handle, ">", $shell_call) or die "Failed to write: [$shell_call], error was: [".$!."]\n";;
			print $file_handle $body;
			close $file_handle;
			
			# Read back the file and see that it's accurate.
			my $new_body = $anvil->Storage->read_file({
				debug      => $debug,
				file       => $file, 
				force_read => 1, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_body => $new_body }});
			
			my $difference = diff \$body, \$new_body, { STYLE => 'Unified' };
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { difference => $difference }});
			
			if ($difference)
			{
				# Failed!
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "warning_0002", variables => { 
					file       => $file,
					difference => $difference, 
				}});
				return(1);
			}
			
			# Delete the cache for this file, if it exists.
			if (exists $anvil->data->{cache}{file}{$file})
			{
				delete $anvil->data->{cache}{file}{$file};
			}
			
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mode => $mode }});
			if ($mode)
			{
				$anvil->Storage->change_mode({debug => $debug, path => $file, mode => $mode});
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				user  => $user,
				group => $group, 
			}});
			if (($user) or ($group))
			{
				$anvil->Storage->change_owner({debug => $debug, path => $file, user => $user, group => $group});
			}
		}
	}
	else
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
		(my $output, $error, my $return_code) = $anvil->Remote->call({
			debug       => $debug, 
			target      => $target,
			port        => $port, 
			user        => $remote_user, 
			password    => $password,
			remote_user => $remote_user, 
			shell_call  => $shell_call,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			error  => $error,
			output => $output,
		}});
		if (not $error)
		{
			# No error. Did the file exist?
			if ($output eq "exists")
			{
				if (not $overwrite)
				{
					# Abort, we're not allowed to overwrite.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0040", variables => { file => $file }});
					$error = 1;
				}
				
				if ($backup)
				{
					# Back it up.
					my $backup_file = $anvil->Storage->backup({
						debug    => $debug, 
						file     => $file,
						target   => $target,
						port     => $port, 
						user     => $remote_user, 
						password => $password,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { backup_file => $backup_file }});
				}
			}
			
			# Make sure the directory exists on the remote machine. In this case, we'll use 'mkdir -p' if it isn't.
			if (not $error)
			{
				my $shell_call = "
if [ -d '".$directory."' ]; 
then
    echo 'exists'; 
else 
    echo 'not found';
fi";
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
				(my $output, $error, my $return_code) = $anvil->Remote->call({
					debug       => $debug, 
					target      => $target,
					port        => $port, 
					user        => $remote_user, 
					password    => $password,
					remote_user => $remote_user, 
					shell_call  => $shell_call,
				});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					error  => $error,
					output => $output,
				}});
				if ($output eq "not found")
				{
					# Create the directory
					my $shell_call = $anvil->data->{path}{exe}{'mkdir'}." -p ".$directory;
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
					(my $output, $error, my $return_code) = $anvil->Remote->call({
						debug       => $debug, 
						target      => $target,
						port        => $port, 
						user        => $remote_user, 
						password    => $password,
						remote_user => $remote_user, 
						shell_call  => $shell_call,
					});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						error  => $error,
						output => $output,
					}});
				}
				
				if (not $error)
				{
					# OK, now write the file locally, then we'll rsync it over.
					my $temp_file =  $file;
					   $temp_file =~ s/\//_/g;
					   $temp_file =~ s/^_//g;
					   $temp_file =  "/tmp/".$temp_file;
					   $temp_file .= ".".$anvil->Get->uuid({debug => $debug, short => 1});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { temp_file => $temp_file }});
					$anvil->Storage->write_file({
						binary    => $binary,
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
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
						$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "warning_0081", variables => { 
							temp_file => $temp_file, 
							target    => $remote_user."\@".$target.":".$file,
						}});
					}
				}
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { error => $error }});
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


=head2 _create_rsync_wrapper

This does the actual work of creating the C<< expect >> wrapper script and returns the path to that wrapper for C<< rsync >> calls.

If there is a problem, an empty string will be returned.

Parameters;

=head3 target (required)

This is the IP address or (resolvable) host name of the remote machine.

=head3 password (required)

This is the password of the user you will be connecting to the remote machine as.

=cut
sub _create_rsync_wrapper
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->_create_rsync_wrapper()" }});
	
	# Check my parameters.
	my $target   = defined $parameter->{target}   ? $parameter->{target}   : "";
	my $password = defined $parameter->{password} ? $parameter->{password} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password => $anvil->Log->is_secure($password), 
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
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		wrapper_script => $wrapper_script, 
		wrapper_body   => $wrapper_body, 
	}});
	$anvil->Storage->write_file({
		debug     => $debug,
		body      => $wrapper_body,
		file      => $wrapper_script,
		mode      => "0700",
		overwrite => 1,
		secure    => 1,
	});
	
	if (not -e $wrapper_script)
	{
		# Failed!
		$wrapper_script = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 0, list => { wrapper_script => $wrapper_script }});
	}
	
	return($wrapper_script);
}


=head3 _wait_if_changing

This takes a full path to a file, and watches it for at specified number of seconds to see if the size is changing. If it is, this method waits until the file size stops changing. 

Parameters;

=head3 file (required)

This is the full path to the file. If the file is not found, C<< !!error!! >> is returned.

=head3 delay (optional, default '10')

This is how long to wait before checking to see if the file has changed.

=head3 last_size (optional)

If this is set, it's the first size we compare against. If not passed, the size will be checked.

=cut
sub _wait_if_changing
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Storage->_create_rsync_wrapper()" }});
	
	# Check my parameters.
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $delay     = defined $parameter->{delay}     ? $parameter->{delay}     : "";
	my $last_size = defined $parameter->{last_size} ? $parameter->{last_size} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file      => $file, 
		delay     => $delay, 
		last_size => $last_size, 
	}});
	
	if (not $delay)
	{
		$delay = 10;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
	}
	elsif (($delay =~ /\D/) or ($delay == 0))
	{
		$delay = 10;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { delay => $delay }});
	}
	
	if (not -e $file)
	{
		return("!!error!!");
	}
	
	if (not $last_size)
	{
		$last_size = (stat($file))[7];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			last_size => $last_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $last_size}).")", 
		}});
	}
	
	my $waiting = 1;
	while ($waiting)
	{
		sleep $delay;
		my $new_size = (stat($file))[7];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
			's1:file'      => $file,
			's2:new_size'  => $new_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $new_size}).")", 
			's3:last_size' => $last_size." (".$anvil->Convert->bytes_to_human_readable({'bytes' => $last_size}).")", 
		}});
		if ($new_size == $last_size)
		{
			# Size seems stable
			$waiting = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { waiting => $waiting }});
		}
		else
		{
			# Might still be updating, wait.
			my $difference = $new_size - $last_size;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { difference => $difference }});
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 1, key => "log_0724", variables => { 
				file             => $file,
				old_size_bytes   => $anvil->Convert->add_commas({number => $last_size}),
				old_size_hr      => $anvil->Convert->bytes_to_human_readable({'bytes' => $last_size}),
				new_size_bytes   => $anvil->Convert->add_commas({number => $new_size}),
				new_size_hr      => $anvil->Convert->bytes_to_human_readable({'bytes' => $new_size}),
				difference_bytes => $anvil->Convert->add_commas({number => $difference}),
				difference_hr    => $anvil->Convert->bytes_to_human_readable({'bytes' => $difference}),
			}});
			
			$last_size = $new_size;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { last_size => $last_size }});
		}
	}
	
	return(0);
}

1;

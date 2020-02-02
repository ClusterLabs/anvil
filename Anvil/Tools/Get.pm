package Anvil::Tools::Get;
# 
# This module contains methods used to handle access to frequently used data.
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Encode;
use UUID::Tiny qw(:std);
use Net::Netmask;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Get.pm";

### Methods;
# anvil_version
# cgi
# date_and_time
# host_uuid
# md5sum
# switches
# users_home
# uuid
# _salt
# _wrap_to

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Get

Provides all methods related to getting access to frequently used data.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Get->X'. 
 # 
 # Example using 'date_and_time()';
 my $date = $anvil->Get->date_and_time({...});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		HOST	=>	{
			UUID	=>	"",
		},
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

=head2 anvil_version

This reads to C<< VERSION >> file of a local or remote machine. If the version file isn't found, C<< 0 >> is returned. 

Parameters;

=head3 password (optional)

This is the password to use when connecting to a remote machine. If not set, but C<< target >> is, an attempt to connect without a password will be made.

=head3 port (optional)

This is the TCP port to use when connecting to a remote machine. If not set, but C<< target >> is, C<< 22 >> will be used.

=head3 remote_user (optional, default root)

If C<< target >> is set, this will be the user we connect to the remote machine as.

=head3 target (optional)

This is the IP or host name of the machine to read the version of. If this is not set, the local system's version is checked.

=cut
# NOTE: the version is set in anvil.spec by sed'ing the release and arch onto anvil.version in anvil-core's %post
sub anvil_version
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password    = defined $parameter->{password}    ? $parameter->{password}    : "";
	my $port        = defined $parameter->{port}        ? $parameter->{port}        : "";
	my $remote_user = defined $parameter->{remote_user} ? $parameter->{remote_user} : "root";
	my $target      = defined $parameter->{target}      ? $parameter->{target}      : "";
	my $version     = 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password    => $anvil->Log->is_secure($password),
		port        => $port, 
		remote_user => $remote_user, 
		target      => $target, 
	}});
	
	# Is this a local call or a remote call?
	if ($anvil->Network->is_local({host => $target}))
	{
		# Local.
		$version = $anvil->Storage->read_file({file => $anvil->data->{path}{configs}{'anvil.version'}});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { version => $version }});
		
		# Did we actually read a version?
		if ($version eq "!!error!!")
		{
			$version = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { version => $version }});
		}
	}
	else
	{
		# Remote call. If we're running as the apache user, we need to read the cached version for 
		# the peer. otherwise, after we read the version, will write the cached version.
		my $user       = getpwuid($<);
		my $cache_file = $anvil->data->{path}{directories}{anvil}."/anvil.".$target.".version";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			cache_file => $cache_file, 
			user       => $user,
		}});
		if ($user eq "apache")
		{
			# Try to read the local cached version.
			if (-e $cache_file)
			{
				# Read it in.
				$version = $anvil->Storage->read_file({file => $cache_file});
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { version => $version }});
			}
		}
		else
		{
			my $shell_call = "
if [ -e ".$anvil->data->{path}{configs}{'anvil.version'}." ];
then
    cat ".$anvil->data->{path}{configs}{'anvil.version'}.";
else
   echo 0;
fi;
";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0166", variables => { shell_call => $shell_call, target => $target, remote_user => $remote_user }});
			my ($output, $error, $return_code) = $anvil->Remote->call({
				debug       => $debug, 
				shell_call  => $shell_call, 
				target      => $target,
				port        => $port, 
				password    => $password,
				remote_user => $remote_user, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				error  => $error,
				output => $output,
			}});
			
			$version = defined $output ? $output : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { version => $version }});
			
			# Create/Update the cache file.
			if ($version)
			{
				my $update_cache = 1;
				my $old_version  = "";
				if (-e $cache_file)
				{
					$old_version = $anvil->Storage->read_file({file => $cache_file});
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_version => $old_version }});
					if ($old_version eq $version)
					{
						# No need to update
						$update_cache = 0;
					}
					else
					{
						
					}
				}
				
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { update_cache => $update_cache }});
				if ($update_cache)
				{
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0437", variables => { 
						target => $target, 
						file   => $cache_file, 
					}});
					$anvil->Storage->write_file({
						debug     => $debug, 
						file      => $cache_file, 
						body      => $version,
						mode      => "0666",
						overwrite => 1,
					});
				}
			}
		}
	}
	
	# Clear off any newline.
	$version =~ s/\n//gs;
	
	return($version);
}

=head2 cgi

This reads in the CGI variables passed in by a form or URL.

This method takes no parameters.

=cut
sub cgi
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# This will store all of the CGI variables.
	$anvil->data->{sys}{cgi_string} = "?";
	
	# Needed to read in passed CGI variables
	my $cgi = CGI->new();
	
	my $cgis      = [];
	my $cgi_count = 0;
	# Get the list of parameters coming in, if possible, 
	if (exists $cgi->{param})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'cgi->{param}' => $cgi->{param} }});
		foreach my $variable (sort {$a cmp $b} keys %{$cgi->{param}})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable => $variable }});
			push @{$cgis}, $variable;
		}
	}
	
	$cgi_count = @{$cgis};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { cgi_count => $cgi_count }});
	
	# If we don't have at least one variable, we're done.
	if ($cgi_count < 1)
	{
		return(0);
	}
	
	# NOTE: Later, we will have another array for handling file uploads.
	# Now read in the variables.
	foreach my $variable (sort {$a cmp $b} @{$cgis})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable => $variable }});
		
		$anvil->data->{cgi}{$variable}{value}       = "";
		$anvil->data->{cgi}{$variable}{mime_type}   = "string";
		$anvil->data->{cgi}{$variable}{file_handle} = "";
		$anvil->data->{cgi}{$variable}{file_name}   = "";
		$anvil->data->{cgi}{$variable}{alert}       = 0;	# This is set if a sanity check fails
		
		# This is a special CGI key for download files (upload from the user's perspective)
		if ($variable eq "upload_file")
		{
			if (not $cgi->upload('upload_file'))
			{
				# Empty file passed, looks like the user forgot to select a file to upload.
				$anvil->Log->entry({log_level => 2, message_key => "log_0242", file => $THIS_FILE, line => __LINE__});
			}
			else
			{
				   $anvil->data->{cgi}{upload_file}{file_handle} = $cgi->upload('upload_file');
				my $file                                         = $anvil->data->{cgi}{upload_file}{file_handle};
				   $anvil->data->{cgi}{upload_file}{file_name}   = $file;
				   $anvil->data->{cgi}{upload_file}{mime_type}   = $cgi->uploadInfo($file)->{'Content-Type'};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					variable                                => 'upload_file',
					"cgi::${variable}::file_handle"         => $anvil->data->{cgi}{upload_file}{file_handle},
					"cgi::${variable}::file_handle->handle" => $anvil->data->{cgi}{upload_file}{file_handle}->handle,
					"cgi::${variable}::file_name"           => $anvil->data->{cgi}{upload_file}{file_name},
					"cgi::${variable}::mime_type"           => $anvil->data->{cgi}{upload_file}{mime_type},
					"cgi->upload('upload_file')"            => $cgi->upload('upload_file'),
					"cgi->upload('upload_file')->handle"    => $cgi->upload('upload_file')->handle,
				}});
			}
		}
		
		if (defined $cgi->param($variable))
		{
			# Make this UTF8 if it isn't already.
			if (Encode::is_utf8($cgi->param($variable)))
			{
				$anvil->data->{cgi}{$variable}{value} = $cgi->param($variable);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cgi::${variable}::value" => $anvil->data->{cgi}{$variable}{value} }});
			}
			else
			{
				$anvil->data->{cgi}{$variable}{value} = Encode::decode_utf8($cgi->param($variable));
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cgi::${variable}::value" => $anvil->data->{cgi}{$variable}{value} }});
			}
			
			# Append to 'sys::cgi_string', so long as the variable doesn't have 'passwd' or 'password' in it.
			if (($variable !~ /password/) && ($variable !~ /passwd/))
			{
				$anvil->data->{sys}{cgi_string} .= "$variable=".$anvil->data->{cgi}{$variable}{value}."&";
			}
		}
	}
	
	# This is a pretty way of displaying the passed-in CGI variables. It loops through all we've got and
	# sorts out the longest variable name. Then it loops again, appending '.' to shorter ones so that 
	# everything is lined up in the logs. This almost always prints, save for log level 0.
	if ($anvil->Log->level >= 1)
	{
		my $longest_variable = 0;
		foreach my $variable (sort {$a cmp $b} keys %{$anvil->data->{cgi}})
		{
			next if $anvil->data->{cgi}{$variable} eq "";
			if (length($variable) > $longest_variable)
			{
				$longest_variable = length($variable);
			}
		}
		
		# Now loop again.
		foreach my $variable (@{$cgis})
		{
			next if $anvil->data->{cgi}{$variable} eq "";
			my $difference   = $longest_variable - length($variable);
			my $say_value    = "value";
			if ($difference == 0)
			{
				# Do nothing
			}
			elsif ($difference == 1) 
			{
				$say_value .= " ";
			}
			elsif ($difference == 2) 
			{
				$say_value .= "  ";
			}
			else
			{
				my $dots      =  $difference - 2;
				   $say_value .= " ";
				for (1 .. $dots)
				{
					$say_value .= ".";
				}
				$say_value .= " ";
			}
			# This is always '1' as the passed-in variables are what we want to see.
			my $censored_value = $anvil->data->{cgi}{$variable}{value};
			if ((($variable =~ /passwd/) or ($variable =~ /password/)) && (not $anvil->Log->secure))
			{
				# This is a password and we're not logging sensitive data, obfuscate it.
				$censored_value = $anvil->Words->string({key => "log_0186"});
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { 
				"cgi::${variable}::$say_value" => $censored_value,
			}});
		}
	}
	
	# Clear the last &
	$anvil->data->{sys}{cgi_string} =~ s/&$//;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::cgi_string" => $anvil->data->{sys}{cgi_string} }});
	
	return(0);
}

=head2 date_and_time

This method returns the date and/or time using either the current time, or a specified unix time.

NOTE: This only returns times in 24-hour notation.

=head2 Parameters;

=head3 date_only (optional)

If set, only the date will be returned (in C<< yyyy/mm/dd >> format).

=head3 file_name (optional)

When set, the date and/or time returned in a string more useful in file names. Specifically, it will replace spaces with 'C<< _ >>' and 'C<< : >>' and 'C<< / >>' for 'C<< - >>'. This will result in a string in the format like 'C<< yyyy-mm-dd_hh-mm-ss >>'.

=head3 offset (optional)

If set to a signed number, it will add or subtract the number of seconds from the 'C<< use_time >>' before processing.

=head3 use_time (optional)

This can be set to a unix timestamp. If it is not set, the current time is used.

=head3 time_only (optional)

If set, only the time will be returned (in C<< hh:mm:ss >> format).

=head3 use_utc (optional)

If set, C<< gmtime >> is used instead of C<< localtime >>. The effect of this is that GMTime (greenwhich mean time, UTC-0) is used instead of the local system's time zone.

=cut
sub date_and_time
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $offset    = defined $parameter->{offset}    ? $parameter->{offset}    : 0;
	my $use_time  = defined $parameter->{use_time}  ? $parameter->{use_time}  : time;
	my $use_utc   = defined $parameter->{use_utc}   ? $parameter->{use_utc}   : 0;
	my $file_name = defined $parameter->{file_name} ? $parameter->{file_name} : 0;
	my $time_only = defined $parameter->{time_only} ? $parameter->{time_only} : 0;
	my $date_only = defined $parameter->{date_only} ? $parameter->{date_only} : 0;
	
	### NOTE: This is used too early for normal error handling.
	# Are things sane?
	if ($use_time =~ /D/)
	{
		die "Get->date_and_time() was called with 'use_time' set to: [$use_time]. Only a unix timestamp is allowed.\n";
	}
	if ($offset =~ /D/)
	{
		die "Get->date_and_time() was called with 'offset' set to: [$offset]. Only real number is allowed.\n";
	}
	
	# Do my initial calculation.
	my $return_string = "";
	my $time          = {};
	my $adjusted_time = $use_time + $offset;
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - adjusted_time: [$adjusted_time]\n";
	
	# Get the date and time pieces
	if ($use_utc)
	{
		($time->{sec}, $time->{min}, $time->{hour}, $time->{mday}, $time->{mon}, $time->{year}, $time->{wday}, $time->{yday}, $time->{isdst}) = gmtime($adjusted_time);
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{sec}: [".$time->{sec}."], time->{min}: [".$time->{min}."], time->{hour}: [".$time->{hour}."], time->{mday}: [".$time->{mday}."], time->{mon}: [".$time->{mon}."], time->{year}: [".$time->{year}."], time->{wday}: [".$time->{wday}."], time->{yday}: [".$time->{yday}."], time->{isdst}: [".$time->{isdst}."]\n";
	}
	else
	{
		($time->{sec}, $time->{min}, $time->{hour}, $time->{mday}, $time->{mon}, $time->{year}, $time->{wday}, $time->{yday}, $time->{isdst}) = localtime($adjusted_time);
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{sec}: [".$time->{sec}."], time->{min}: [".$time->{min}."], time->{hour}: [".$time->{hour}."], time->{mday}: [".$time->{mday}."], time->{mon}: [".$time->{mon}."], time->{year}: [".$time->{year}."], time->{wday}: [".$time->{wday}."], time->{yday}: [".$time->{yday}."], time->{isdst}: [".$time->{isdst}."]\n";
	}
	
	# Process the raw data
	$time->{pad_hour} = sprintf("%02d", $time->{hour});
	$time->{mon}++;
	$time->{pad_min}  = sprintf("%02d", $time->{min});
	$time->{pad_sec}  = sprintf("%02d", $time->{sec});
	$time->{year}     = ($time->{year} + 1900);
	$time->{pad_mon}  = sprintf("%02d", $time->{mon});
	$time->{pad_mday} = sprintf("%02d", $time->{mday});
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{pad_hour}: [".$time->{pad_hour}."], time->{pad_min}: [".$time->{pad_min}."], time->{pad_sec}: [".$time->{pad_sec}."], time->{year}: [".$time->{year}."], time->{pad_mon}: [".$time->{pad_mon}."], time->{pad_mday}: [".$time->{pad_mday}."], time->{mon}: [".$time->{mon}."]\n";
	
	# Now, the date and time separator depends on if 'file_name' is set.
	my $date_separator  = $file_name ? "-" : "/";
	my $time_separator  = $file_name ? "-" : ":";
	my $space_separator = $file_name ? "_" : " ";
	if ($time_only)
	{
		$return_string = $time->{pad_hour}.$time_separator.$time->{pad_min}.$time_separator.$time->{pad_sec};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	elsif ($date_only)
	{
		$return_string = $time->{year}.$date_separator.$time->{pad_mon}.$date_separator.$time->{pad_mday};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	else
	{
		$return_string = $time->{year}.$date_separator.$time->{pad_mon}.$date_separator.$time->{pad_mday}.$space_separator.$time->{pad_hour}.$time_separator.$time->{pad_min}.$time_separator.$time->{pad_sec};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	
	return($return_string);
}

=head2 host_name

This takes a host UUID and returns the host name (as recorded in the C<< hosts >> table). If the entry is not found, an empty string is returned.

Parameters;

=head3 host_uuid (required)

This is the C<< host_uuid >> to translate into a host name.

=cut
sub host_name
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $host_name = "";
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	
	my $query = "
SELECT 
    host_name 
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->Database->quote($host_uuid).";
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if ($count == 1)
	{
		# Found it
		$host_name = defined $results->[0]->[0] ? $results->[0]->[0] : "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_name => $host_name }});
	return($host_name);
}

=head2 host_uuid

This returns the local host's system UUID (as reported by 'dmidecode'). If the host UUID isn't available, and the program is not running with root priviledges, C<< #!error!# >> is returned.

 print "This host's UUID: [".$anvil->Get->host_uuid."]\n";

It is possible to override the local UUID, though it is not recommended.

 $anvil->Get->host_uuid({set => "720a0509-533d-406b-8fc1-03aca3e75fa7"})

=cut
sub host_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		set          => $set,
		'HOST::UUID' => $anvil->{HOST}{UUID}, 
	}});
	
	if ($set)
	{
		$anvil->{HOST}{UUID} = $set;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "HOST::UUID" => $anvil->{HOST}{UUID} }});
	}
	elsif (not $anvil->{HOST}{UUID})
	{
		# Read /etc/anvil/host.uuid if it exists. If not, and if we're root, we'll create that file 
		# using the UUID from dmidecode.
		my $uuid = "";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			'$<'                    => $<, 
			'$>'                    => $>,
			'path::data::host_uuid' => $anvil->data->{path}{data}{host_uuid}, 
		}});
		if (-e $anvil->data->{path}{data}{host_uuid})
		{
			# Read the UUID in
			$uuid = $anvil->Storage->read_file({debug => $debug, file => $anvil->data->{path}{data}{host_uuid}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
		}
		elsif (($< == 0) or ($> == 0))
		{
			# Create the UUID file.
			($uuid, my $return_code) = $anvil->System->call({debug => $debug, shell_call => $anvil->data->{path}{exe}{dmidecode}." --string system-uuid"});
			$uuid = lc($uuid);
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				uuid        => $uuid, 
				return_code => $return_code,
			}});
		}
		else
		{
			# Host UUID file doesn't exist and I'm Not running as root, I'm done.
			# We're done.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0187"});
			return("#!error!#");
		}
		
		if ($anvil->Validate->is_uuid({uuid => $uuid}))
		{
			$anvil->{HOST}{UUID} = $uuid;
			if (not -e $anvil->data->{path}{data}{host_uuid})
			{
				### TODO: This will need to set the proper SELinux context.
				# Apache run scripts can't call the system UUID, so we'll write it to a text
				# file.
				$anvil->Storage->write_file({
					debug     => $debug, 
					file      => $anvil->data->{path}{data}{host_uuid}, 
					body      => $uuid,
					user      => "apache", 
					group     => "apache",
					mode      => "0666",
					overwrite => 0,
				});
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "message_0011", variables => { file => $anvil->data->{path}{configs}{'postgresql.conf'} }});
			}
		}
		else
		{
			# Bad UUID.
			$anvil->{HOST}{UUID} = "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "HOST::UUID" => $anvil->{HOST}{UUID} }});
			
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0134", variables => { uuid => $uuid }});
			return("#!error!#");
		}
	}
	
	# We'll also store the host UUID in a variable.
	if ((not $anvil->data->{sys}{host_uuid}) && ($anvil->{HOST}{UUID}))
	{
		$anvil->data->{sys}{host_uuid} = $anvil->{HOST}{UUID};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "sys::host_uuid" => $anvil->data->{sys}{host_uuid} }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "HOST::UUID" => $anvil->{HOST}{UUID} }});
	return($anvil->{HOST}{UUID});
}

=head2 md5sum

This returns the C<< md5sum >> of a given file.

Parameters;

=head3 file

This is the full or relative path to the file. If the file doesn't exist, an empty string is returned.

=cut
sub md5sum
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $sum = "";
	my $file = defined $parameter->{file} ? $parameter->{file} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
	
	if (-e $file)
	{
		my $shell_call = $anvil->data->{path}{exe}{md5sum}." ".$file;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { shell_call => $shell_call }});
		
		my ($return, $return_code) = $anvil->System->call({debug => $debug, shell_call => $shell_call});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'return' => $return, return_code => $return_code }});
		
		# split the sum off.
		$sum = ($return =~ /^(.*?)\s+$file$/)[0];
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sum => $sum }});
	}
	
	return($sum);
}

=head2 switches

This reads in the command line switches used to invoke the parent program. 

It takes no arguments, and data is stored in 'C<< $anvil->data->{switches}{x} >>', where 'x' is the switch used.

Switches in the form 'C<< -x >>' and 'C<< --x >>' are treated the same and the corresponding 'C<< $anvil->data->{switches}{x} >>' will contain '#!set!#'. 

Switches in the form 'C<< -x foo >>', 'C<< --x foo >>', 'C<< -x=foo >>' and 'C<< --x=foo >>' are treated the same and the corresponding 'C<< $anvil->data->{switches}{x} >>' will contain 'foo'. 

The switches 'C<< -v >>', 'C<< -vv >>', 'C<< -vvv >>' and 'C<< -vvvv >>' will cause the active log level to automatically change to 1, 2, 3 or 4 respectively. Passing 'C<< -V >>' will set the log level to '0'.

Anything after 'C<< -- >>' is treated as a raw string and is not processed. 

=cut
sub switches
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $last_argument = "";
	foreach my $argument (@ARGV)
	{
		if ($last_argument eq "raw")
		{
			# Don't process anything.
			$anvil->data->{switches}{raw} .= " $argument";
		}
		elsif ($argument =~ /^-/)
		{
			# If the argument is just '--', appeand everything after it to 'raw'.
			if ($argument eq "--")
			{
				$last_argument         = "raw";
				$anvil->data->{switches}{raw} = "";
			}
			else
			{
				($last_argument) = ($argument =~ /^-{1,2}(.*)/)[0];
				if ($last_argument =~ /=/)
				{
					# Break up the variable/value.
					($last_argument, my $value) = (split /=/, $last_argument, 2);
					$anvil->data->{switches}{$last_argument} = $value;
				}
				else
				{
					$anvil->data->{switches}{$last_argument} = "#!SET!#";
				}
			}
		}
		else
		{
			if ($last_argument)
			{
				$anvil->data->{switches}{$last_argument} = $argument;
				$last_argument                        = "";
			}
			else
			{
				# Got a value without an argument, so just record it as '#!SET!#'.
				$anvil->data->{switches}{$argument} = "#!SET!#";
			}
		}
	}
	
	# Clean up the initial space added to 'raw'.
	if ($anvil->data->{switches}{raw})
	{
		$anvil->data->{switches}{raw} =~ s/^ //;
	}
	
	# Adjust the log level if requested.
	$anvil->Log->_adjust_log_level();
	
	return(0);
}

=head2 users_home

This method takes a user's name and returns the user's home directory. If the home directory isn't found, C<< 0 >> is returned.

Parameters;

=head3 user (optional, default is the user name of the real UID (as stored in '$<'))

This is the user whose home directory you are looking for.

=cut
sub users_home
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $home_directory = 0;
	
	my $user = defined $parameter->{user} ? $parameter->{user} : getpwuid($<);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	
	# Make sure the user is only one digit. Sometimes $< (and others) will return multiple IDs.
	if ($user =~ /^\d+ \d$/)
	{
		$user =~ s/^(\d+)\s.*$/$1/;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	}
	
	# If the user is numerical, convert it to a name.
	if ($user =~ /^\d+$/)
	{
		$user = getpwuid($user);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user => $user }});
	}
	
	# Still don't have a name? fail...
	if ($user eq "")
	{
		# No user? No bueno...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->users_home()", parameter => "user" }});
		return($home_directory);
	}
	
	my $body = $anvil->Storage->read_file({file => $anvil->data->{path}{data}{passwd}});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { body => $body }});
	foreach my $line (split /\n/, $body)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^$user:/)
		{
			$home_directory = (split/:/, $line)[5];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { home_directory => $home_directory }});
			last;
		}
	}
	
	# Do I have the a user's $HOME now?
	if (not $home_directory)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0061", variables => { user => $user }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { home_directory => $home_directory }});
	return($home_directory);
}

=head2 uuid

This method returns a new v4 UUID (using 'UUID::Tiny').

Parameters;

=head3 short (optional, default '0')

This returns just the first 8 bytes of the uuid. For example, if the generated UUID is C<< 9e4b3f7c-5a98-40b6-9c34-84fdb24ddd30 >>, only C<< 9e4b3f7c >> is returned.

=cut
sub uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $short = defined $parameter->{short} ? $parameter->{short} : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		short => $short,
	}});
	
	my $uuid = create_uuid_as_string(UUID_RANDOM);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { uuid => $uuid }});
	
	if ($short)
	{
		$uuid =~ s/^(\w+?)-.*$/$1/;
	}
	
	return($uuid);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2 _salt

This generates a random salt string for use with internal Striker passwords.

=cut
sub _salt
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;

	my $salt        = "";
	my $salt_length = $anvil->data->{sys}{password}{salt_length} =~ /^\d+$/ ? $anvil->data->{sys}{password}{salt_length} : 16;
	my @seed        = (" ", "~", "`", "!", "#", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "[", "}", "]", "|", ":", ";", "'", ",", "<", ".", ">", "/");
	my @alpha       = ("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");
	my $seed_count  = @seed;
	my $alpha_count = @alpha;

	my $skip_count = 0;
	for (1..$salt_length)
	{
		# We want to have a little randomness in the salt length, but not skip tooooo many times.
		if ((int(rand(20)) == 2) && ($skip_count <= 3))
		{
			$skip_count++;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { skip_count => $skip_count }});
			next;
		}
		
		# What character will this string be?
		my $this_integer = int(rand(3));
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_integer => $this_integer }});
		if ($this_integer == 0)
		{
			# Inject a random digit
			$salt .= int(rand(10));
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
		}
		elsif ($this_integer == 1)
		{
			# Inject a random letter
			$salt .= $alpha[int(rand($alpha_count))];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
		}
		else
		{
			# Inject a random character
			$salt .= $seed[int(rand($seed_count))];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
		}
	}

	return($salt);
}


=head2 _wrap_to

This determines how wide the user's terminal currently is and returns that width, as well as store it in C<< sys::terminal::columns >>.

This takes no parameters. If there is a problem reading the column width, C<< 0 >> will be returned.

=cut
sub _wrap_to
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	# Get the column width
	my ($columns, $return_code) = $anvil->System->call({debug => $debug, redirect_stderr => 0, shell_call => $anvil->data->{path}{exe}{tput}." cols" });
	if ((not defined $columns) or ($columns !~ /^\d+$/))
	{
		# Set 0.
		$columns = 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { columns => $columns }});
	}
	else
	{
		# Got a good value
		$anvil->data->{sys}{terminal}{columns} = $columns;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::terminal::columns' => $anvil->data->{sys}{terminal}{columns} }});
	}

	return($columns);
}

1;

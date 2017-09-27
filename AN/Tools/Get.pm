package AN::Tools::Get;
# 
# This module contains methods used to handle access to frequently used data.
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
use Encode;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Get.pm";

### Methods;
# cgi
# date_and_time
# host_uuid
# network_details
# switches
# users_home
# uuid

=pod

=encoding utf8

=head1 NAME

AN::Tools::Get

Provides all methods related to getting access to frequently used data.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Get->X'. 
 # 
 # Example using 'date_and_time()';
 my $foo_path = $an->Get->date_and_time({...});

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

# Get a handle on the AN::Tools object. I know that technically that is a sibling module, but it makes more 
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

=head2 cgi

This reads in the CGI variables passed in by a form or URL.

This will read the 'cgi_list' CGI variable for a comma-separated list of CGI variables to read in. So your form must set this in order for this method to work.

If the variable 'file' is passed, it will be treated as a binary stream containing an uploaded file.

=cut
sub cgi
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	# This will store all of the CGI variables.
	$an->data->{sys}{cgi_string} = "?";
	
	# Needed to read in passed CGI variables
	my $cgi = CGI->new();
	
	# The list of CGI variables to try and read will always be in 'cgi_list'.
	my $cgis      = [];
	my $cgi_count = 0;
	if (defined $cgi->param("cgi_list"))
	{
		my $cgi_list = $cgi->param("cgi_list");
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { cgi_list => $cgi_list }});
		
		foreach my $variable (split/,/, $cgi_list)
		{
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { variable => $variable }});
			push @{$cgis}, $variable;
		}
		
		$cgi_count = @{$cgis};
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { cgi_count => $cgi_count }});
	}
	
	# If we don't have at least one variable, we're done.
	if ($cgi_count < 1)
	{
		return(0);
	}
	
	# NOTE: Later, we will have another array for handling file uploads.
	# Now read in the variables.
	foreach my $variable (sort {$a cmp $b} @{$cgis})
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { variable => $variable }});
		
		$an->data->{cgi}{$variable}{value}      = "";
		$an->data->{cgi}{$variable}{mimetype}   = "string";
		$an->data->{cgi}{$variable}{filehandle} = "";
		$an->data->{cgi}{$variable}{alert}      = 0;	# This is set if a sanity check fails
		
		if ($variable eq "file")
		{
			if (not $cgi->upload($variable))
			{
				# Empty file passed, looks like the user forgot to select a file to upload.
				#$an->Log->entry({log_level => 3, message_key => "log_0016", file => $THIS_FILE, line => __LINE__});
			}
			else
			{
				   $an->data->{cgi}{$variable}{filehandle} = $cgi->upload($variable);
				my $file                                   = $an->data->{cgi}{$variable}{filehandle};
				   $an->data->{cgi}{$variable}{mimetype}   = $cgi->uploadInfo($file)->{'Content-Type'};
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
					variable                       => $variable,
					"cgi::${variable}::filehandle" => $an->data->{cgi}{$variable}{filehandle},
					"cgi::${variable}::mimetype"   => $an->data->{cgi}{$variable}{mimetype},
				}});
			}
		}
		
		if (defined $cgi->param($variable))
		{
			# Make this UTF8 if it isn't already.
			if (Encode::is_utf8($cgi->param($variable)))
			{
				$an->data->{cgi}{$variable}{value} = $cgi->param($variable);
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { "cgi::${variable}::value" => $an->data->{cgi}{$variable}{value} }});
			}
			else
			{
				$an->data->{cgi}{$variable}{value} = Encode::decode_utf8($cgi->param($variable));
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { "cgi::${variable}::value" => $an->data->{cgi}{$variable}{value} }});
			}
			
			# Append to 'sys::cgi_string'
			$an->data->{sys}{cgi_string} .= "$variable=".$an->data->{cgi}{$variable}{value}."&";
		}
	}
	
	# This is a pretty way of displaying the passed-in CGI variables. It loops through all we've got and
	# sorts out the longest variable name. Then it loops again, appending '.' to shorter ones so that 
	# everything is lined up in the logs.
	my $debug = 2;
	if ($an->Log->level >= $debug)
	{
		my $longest_variable = 0;
		foreach my $variable (sort {$a cmp $b} keys %{$an->data->{cgi}})
		{
			next if $an->data->{cgi}{$variable} eq "";
			if (length($variable) > $longest_variable)
			{
				$longest_variable = length($variable);
			}
		}
		
		# Now loop again in the order that the variables were passed is 'cgi_list'.
		foreach my $variable (@{$cgis})
		{
			next if $an->data->{cgi}{$variable} eq "";
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
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"cgi::${variable}::$say_value" => $an->data->{cgi}{$variable}{value},
			}});
		}
	}
	
	# Clear the last &
	$an->data->{sys}{cgi_string} =~ s/&$//;
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { "sys::cgi_string" => $an->data->{sys}{cgi_string} }});
	
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

=cut
sub date_and_time
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $offset    = defined $parameter->{offset}    ? $parameter->{offset}    : 0;
	my $use_time  = defined $parameter->{use_time}  ? $parameter->{use_time}  : time;
	my $file_name = defined $parameter->{file_name} ? $parameter->{file_name} : 0;
	my $time_only = defined $parameter->{time_only} ? $parameter->{time_only} : 0;
	my $date_only = defined $parameter->{date_only} ? $parameter->{date_only} : 0;
	
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
	($time->{sec}, $time->{min}, $time->{hour}, $time->{mday}, $time->{mon}, $time->{year}, $time->{wday}, $time->{yday}, $time->{isdst}) = localtime($adjusted_time);
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{sec}: [".$time->{sec}."], time->{min}: [".$time->{min}."], time->{hour}: [".$time->{hour}."], time->{mday}: [".$time->{mday}."], time->{mon}: [".$time->{mon}."], time->{year}: [".$time->{year}."], time->{wday}: [".$time->{wday}."], time->{yday}: [".$time->{yday}."], time->{isdst}: [".$time->{isdst}."]\n";
	
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

=head2 host_uuid

This returns the local host's system UUID (as reported by 'dmidecode'). 

 print "This host's UUID: [".$an->Get->host_uuid."]\n";

It is possible to override the local UUID, though it is not recommended.

 $an->Get->host_uuid({set => "720a0509-533d-406b-8fc1-03aca3e75fa7"})

=cut
sub host_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	
	if ($set)
	{
		$an->data->{HOST}{UUID} = $set;
	}
	elsif (not $an->data->{HOST}{UUID})
	{
		# Read dmidecode if I am root, and the cache if not.
		my $uuid = "";
		if (($< == 0) or ($> == 0))
		{
			my $shell_call = $an->data->{path}{exe}{dmidecode}." --string system-uuid";
			#print $THIS_FILE." ".__LINE__."; [ Debug ] - shell_call: [$shell_call]\n";
			open(my $file_handle, $shell_call." 2>&1 |") or warn $THIS_FILE." ".__LINE__."; [ Warning ] - Failed to call: [".$shell_call."], the error was: $!\n";
			while(<$file_handle>)
			{
				# This should never be hit...
				chomp;
				$uuid = lc($_);
			}
			close $file_handle;
		}
		else
		{
			# Not running as root, so I have to rely on the cache file, or die if it doesn't 
			# exist.
			if (not -e $an->data->{path}{data}{host_uuid})
			{
				# We're done.
			}
			else
			{
				$uuid = $an->Storage->read_file({ file => $an->data->{path}{data}{host_uuid} });
			}
		}
		
		if ($an->Validate->is_uuid({uuid => $uuid}))
		{
			$an->data->{HOST}{UUID} = $uuid;
		}
		else
		{
			# Bad UUID.
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0134", variables => { uuid => $uuid }});
			$an->data->{HOST}{UUID} = "";
		}
	}
	
	return($an->data->{HOST}{UUID});
}

=head2 network_details

This method returns the local hostname and IP addresses.

It returns a hash reference containing data in the following keys:

C<< hostname >> = <name>
C<< interface::<interface>::ip >> = <ip_address>
C<< interface::<interface>::netmask >> = <dotted_decimal_subnet>

=cut
sub network_details
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $network      = {};
	my $hostname     = $an->System->call({shell_call => $an->data->{path}{exe}{hostname}});
	my $ip_addr_list = $an->System->call({shell_call => $an->data->{path}{exe}{ip}." addr list"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		hostname     => $hostname, 
		ip_addr_list => $ip_addr_list,
	}});
	$network->{hostname} = $hostname;
	
	my $in_interface = "";
	my $ip_address   = "";
	my $subnet_mask  = "";
	foreach my $line (split/\n/, $ip_addr_list)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { line => $line }});
		if ($line =~ /^\d+: (.*?):/)
		{
			$in_interface = $1;
			$ip_address   = "";
			$subnet_mask  = "";
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { in_interface => $in_interface }});
			next if $in_interface eq "lo";
			$network->{interface}{$in_interface}{ip}      = "--";
			$network->{interface}{$in_interface}{netmask} = "--";
		}
		if ($in_interface)
		{
			next if $in_interface eq "lo";
			if ($line =~ /inet (.*?)\/(.*?) /)
			{
				$ip_address   = $1;
				$subnet_mask  = $2;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
					ip_address  => $ip_address,
					subnet_mask => $subnet_mask, 
				}});
				
				if ((($subnet_mask =~ /^\d$/) or ($subnet_mask =~ /^\d\d$/)) && ($subnet_mask < 25))
				{
					$subnet_mask = $an->Convert->cidr({cidr => $subnet_mask});
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { subnet_mask => $subnet_mask }});
				}
				$network->{interface}{$in_interface}{ip}      = $ip_address;
				$network->{interface}{$in_interface}{netmask} = $subnet_mask;
			}
		}
	}
	
	return($network);
}

=head2 switches

This reads in the command line switches used to invoke the parent program. 

It takes no arguments, and data is stored in 'C<< $an->data->{switches}{x} >>', where 'x' is the switch used.

Switches in the form 'C<< -x >>' and 'C<< --x >>' are treated the same and the corresponding 'C<< $an->data->{switches}{x} >>' will contain '#!set!#'. 

Switches in the form 'C<< -x foo >>', 'C<< --x foo >>', 'C<< -x=foo >>' and 'C<< --x=foo >>' are treated the same and the corresponding 'C<< $an->data->{switches}{x} >>' will contain 'foo'. 

The switches 'C<< -v >>', 'C<< -vv >>', 'C<< -vvv >>' and 'C<< -vvvv >>' will cause the active log level to automatically change to 1, 2, 3 or 4 respectively. Passing 'C<< -V >>' will set the log level to '0'.

Anything after 'C<< -- >>' is treated as a raw string and is not processed. 

=cut
sub switches
{
	my $self = shift;
	my $an   = $self->parent;
	
	my $last_argument = "";
	foreach my $argument (@ARGV)
	{
		if ($last_argument eq "raw")
		{
			# Don't process anything.
			$an->data->{switches}{raw} .= " $argument";
		}
		elsif ($argument =~ /^-/)
		{
			# If the argument is just '--', appeand everything after it to 'raw'.
			if ($argument eq "--")
			{
				$last_argument         = "raw";
				$an->data->{switches}{raw} = "";
			}
			else
			{
				($last_argument) = ($argument =~ /^-{1,2}(.*)/)[0];
				if ($last_argument =~ /=/)
				{
					# Break up the variable/value.
					($last_argument, my $value) = (split /=/, $last_argument, 2);
					$an->data->{switches}{$last_argument} = $value;
				}
				else
				{
					$an->data->{switches}{$last_argument} = "#!SET!#";
				}
			}
		}
		else
		{
			if ($last_argument)
			{
				$an->data->{switches}{$last_argument} = $argument;
				$last_argument                        = "";
			}
			else
			{
				# Got a value without an argument.
				$an->data->{switches}{error} = 1;
			}
		}
	}
	# Clean up the initial space added to 'raw'.
	if ($an->data->{switches}{raw})
	{
		$an->data->{switches}{raw} =~ s/^ //;
	}
	
	# Adjust the log level if requested.
	$an->Log->_adjust_log_level();
	
	return(0);
}

=head2 users_home

This method takes a user's name and returns the user's home directory. If the home directory isn't found, C<< 0 >> is returned.

Parameters;

=head3 user (required)

This is the user whose home directory you are looking for.

=cut
sub users_home
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $home_directory = 0;
	
	my $user = $parameter->{user} ? $parameter->{user} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { user => $user }});
	
	# Make sure the user is only one digit. Sometimes $< (and others) will return multiple IDs.
	if ($user =~ /^\d+ \d$/)
	{
		$user =~ s/^(\d+)\s.*$/$1/;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { user => $user }});
	}
	
	# If the user is numerical, convert it to a name.
	if ($user =~ /^\d+$/)
	{
		$user = getpwuid($user);
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { user => $user }});
	}
	
	# Still don't have a name? fail...
	if ($user eq "")
	{
		# No user? No bueno...
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Get->users_home()", parameter => "user" }});
		return($home_directory);
	}
	
	my $body = $an->Storage->read_file({file => $an->data->{path}{data}{passwd}});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { body => $body }});
	foreach my $line (split /\n/, $body)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { line => $line }});
		if ($line =~ /^$user:/)
		{
			$home_directory = (split/:/, $line)[5];
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { home_directory => $home_directory }});
			last;
		}
	}
	
	# Do I have the a user's $HOME now?
	if (not $home_directory)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0061", variables => { user => $user }});
	}
	
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { home_directory => $home_directory }});
	return($home_directory);
}

=head2 uuid

This method returns a new UUID (using 'uuidgen' from the system). It takes no parameters.

=cut
sub uuid
{
	my $self = shift;
	my $an   = $self->parent;
	
	my $uuid = $an->System->call({shell_call => $an->data->{path}{exe}{uuidgen}." --random"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 1, list => { uuid => $uuid }});
	
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

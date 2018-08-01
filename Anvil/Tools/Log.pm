package Anvil::Tools::Log;
# 
# This module contains methods used to handle logging related tasks
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);
use Log::Journald;
use Sys::Syslog qw/:macros/;


our $VERSION  = "3.0.0";
my $THIS_FILE = "Log.pm";

### Methods;
# entry
# language
# level
# secure
# variables
# _adjust_log_level

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Log

Provides all methods related to logging.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Log->X'. 
 # 
 # Example using 'entry()';
 my $foo_path = $anvil->Log->entry({...});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		LOG	=>	{
			LANGUAGE	=>	"",
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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 entry

This method writes an entry to the journald logs, provided the log entry's level is equal to or higher than the active log level. The exception is if the log entry contains sensitive data, like a password, and 'C<< log::secure >> is set to 'C<< 0 >>' (the default).

Here is a simple example of writing a simple log entry at log log level 1.

 $anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0001"});

In the example above, the string will be written to the log file if the active log level is 'C<< 1 >>' or higher and it will use the 'C<< log::language >>' language to translate the string key.

Now a more complex example;

 $anvil->Log->entry({
 	source    => $THIS_FILE, 
 	line      => __LINE__, 
 	level     => 2,
 	secure    => 1,
 	language  => "jp",
 	key       => "log_0002",
 	variables => {
 		password => "foo",
 	},
 });

In the above example, the log level is set to 'C<< 2 >>' and the 'C<< secure >>' flag is set. We're also logging in Japanese and we are passing a variable into the string key. With the secure flag set, even if the user's log level is 2 or higher, the log entry will only be recorded if the user has set 'C<< log::secure >>' to '1'.

Finally, it is possible to log pre-processed strings (as is done in 'Alert->warning()' and 'Alert->error()'). In this case, the 'C<< raw >>' parameter is used and it contains the processed string. Note that the source file and line number are still pre-pended to the raw message.

 $anvil->Log->entry({
 	source    => $THIS_FILE, 
 	line      => __LINE__, 
 	level     => 2,
 	raw       => "This error can't be translated",
 });

The above should be used very sparingly, and generally only in places where string processing itself is being logged.

Parameters;

=head3 facility (optional)

This is an optional log facility to log the message with. By default, 'C<< local0 >>' is used.

If the 'C<< secure >>' flag is set, the facility is changed to 'C<< authpriv >>' and this is ignored.

See 'C<< man logger >>' for a full list of valid priorities.

=head3 key (required)

NOTE: This is not required *if* 'C<< raw >>' is used instead.

This is the string key to use for the log entry. By default, it will be translated into the 'C<< log::language >> language. If the string contains replacement variables, be sure to also use 'C<< variables >>'.

=head3 language (optional)

This is the ISO code for the language you wish to use for the log message. For example, 'en_CA' to get the Canadian English string, or 'jp' for the Japanese string.

When no language is passed, 'C<< defaults::log::languages >>' is used. 

=head3 level (required)

This is the numeric log level of this log entry. It determines if the message is of interest to the user. An entry is only recorded if the user's 'C<< log::level >>' is equal to or higher than this number. This is required, but if it is not passed, 'C<< 2 >>' will be used.

NOTE: The 'C<< log::level >>' might be changed inside certain programs. For example, in ScanCore, the user may set 'C<< scancore::log::level >>' and that will be used to set 'C<< log::level >>'.

Log levels are:

=head4 C<< 0 >>

Critical messages. These will always be logged, and so this log level should very rarely be used. Generally it will be used only by Alert->warning() and Alert->error().

=head4 C<< 1 >>

Important messages. The default log level is 'C<< 1 >>', so anything at this log level will usually be logged under normal conditions.

=head4 C<< 2 >>

This is the 'debug' log level. It is used by developers while working on a section of code, or in places where the log entries can help in general debugging.

=head4 C<< 3 >>

This is the 'verbose' log level. It will generally generate a significant amount of output and is generally used for most logging. A user will generally only set this log level when trying to debug a problem with an unknown source.

=head4 C<< 4 >>

This is the highest log level, and it will generate a tremendous amount of log entries. This is generally used is loops or recursive functions where the output is significant, but the usefulness of the output is not.

=head3 line (optional)

When set, the string is prepended to the log entry, after 'C<< file >> if set, and should be set to C<< __LINE__ >>. It is used to show where in 'C<< file >>' the log entry was made and can assist with debugging.

=head3 priority (optional)

This is an optional log priority (level) name. By default, the following priorities will be used based on the log level of the message.

* 0 = notice
* 1 = info
* 2 = info
* 3 = debug
* 4 = debug

See 'C<< man logger >>' for a full list of valid priorities. Most notably, setting 'C<< crit >>' for critical events, 'C<< err >>' for errors, 'C<< alert >>' for alerts and 'C<< emerg >>' for emergencies are used.

WARNING: Using 'C<< emerg >>' will spam all terminals. Only use it in true emergencies, like when about to shut down.

=head3 raw (optional)

NOTE: This *or* C<< key >> must be passed.

This can contain a string to record to the log file. It is treated as a raw string and is not translated, altered or processed in any way. It will be recorded exactly as-is, provided the log level and secure settings allow for it.

=head3 secure (optional)

When set, this indicates that the log entry might contain sensitive data, like a password. When set, the log entry will only be recorded if 'C<< log::secure >>' is set to '1' *and* the log level is equal to or higher than 'C<< log::level >>'.

=head3 server (optional)

This controls which log server the log entries are recorded. By default, this is blank (and logs are recorded locally).

=head3 source (optional)

When set, the string is pre-pended to the log entry. This is generally set to 'C<< $THIS_FILE >>', which itself should contain the file name requesting the log entry.

=head3 tag (optional)

This is the tag given to the log entry. By default, it will be 'C<< anvil >>'.

=head3 variables (optional)

This is a hash reference containing replacement variables to inject into the 'C<< key >>' string.

=cut
sub entry
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $key       = defined $parameter->{key}       ? $parameter->{key}       : "";
	my $language  = defined $parameter->{language}  ? $parameter->{language}  : $anvil->Log->language;
	my $level     = defined $parameter->{level}     ? $parameter->{level}     : 2;
	my $line      = defined $parameter->{line}      ? $parameter->{line}      : "";
	my $facility  = defined $parameter->{facility}  ? $parameter->{facility}  : $anvil->data->{defaults}{'log'}{facility};
	my $priority  = defined $parameter->{priority}  ? $parameter->{priority}  : "";
	my $raw       = defined $parameter->{raw}       ? $parameter->{raw}       : "";
	my $secure    = defined $parameter->{secure}    ? $parameter->{secure}    : 0;
	my $server    = defined $parameter->{server}    ? $parameter->{server}    : $anvil->data->{defaults}{'log'}{server};
	my $source    = defined $parameter->{source}    ? $parameter->{source}    : "";
	my $tag       = defined $parameter->{tag}       ? $parameter->{tag}       : $anvil->data->{defaults}{'log'}{tag};
	my $variables = defined $parameter->{variables} ? $parameter->{variables} : "";
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - level: [$level], defaults::log::level: [".$anvil->Log->{defaults}{'log'}{level}."], logging secure? [".$anvil->Log->secure."]\n";
	
	# Exit immediately if this isn't going to be logged
	if ($level > $anvil->Log->level)
	{
		return(1);
	}
	if (($secure) && (not $anvil->Log->secure))
	{
		return(2);
	}
	
	# Build the priority, if not set by the user.
	my $priority_string = $secure ? "authpriv" : $facility;
	if ($priority)
	{
		$priority_string .= ".$priority";
	}
	elsif ($level eq "0")
	{
		$priority_string .= ".notice";
	}
	elsif (($level eq "1") or ($level eq "2"))
	{
		$priority_string .= ".info";
	}
	else
	{
		$priority_string .= ".debug";
	}
	
	# Log the file and line, if passed.
	my $string = "";
	if (($source) && ($line))
	{
		$string .= "$source:$line; ";
	}
	elsif ($source)
	{
		$string .= "$source; ";
	}
	elsif ($line)
	{
		$string .= "$line; ";
	}
	
	# If I have a raw string, do no more processing.
	if ($raw)
	{
		$string .= $raw;
	}
	elsif ($key)
	{
		# Build the string from the key/variables.
		my $message .= $anvil->Words->string({	
			language  => $language,
			key       => $key,
			variables => $variables,
		});
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - message: [$message]\n";
		$string .= $message;
	}
	
	# If the user set a log file, log to that. Otherwise, log via Log::Journald.
	if ($anvil->data->{sys}{log_file})
	{
		# TODO: Switch back to journald later, using a file for testing for now
		if ($string !~ /\n$/)
		{
			$string .= "\n";
		}
		
		# Open the file?
		if (not $anvil->{HANDLE}{log_file})
		{
			# If the file doesn't start with a '/', we'll put it under /var/log.
			my $log_file           = $anvil->data->{sys}{log_file} =~ /^\// ? $anvil->data->{sys}{log_file} : "/var/log/".$anvil->data->{sys}{log_file};
			my ($directory, $file) = ($log_file =~ /^(\/.*)\/(.*)$/);
			
			### WARNING: We MUST set the debug level really high, or else we'll go into a deep 
			###          recursion!
			# Make sure the log directory exists.
			$anvil->Storage->make_directory({debug => 99, directory => $directory, mode => 755});
			
			# Now open the log
			my $shell_call = $log_file;
			# NOTE: Don't call '$anvil->Log->entry()' here, it will cause a loop!
			open (my $file_handle, ">>", $shell_call) or die "Failed to open: [$shell_call] for writing. The error was: $!\n";
			$file_handle->autoflush(1);
			$anvil->{HANDLE}{log_file} = $file_handle;
			
			# Make sure it can be written to by apache.
			$anvil->Storage->change_mode({target => $log_file, mode => "0666"});
		}
		
		if (not $anvil->{HANDLE}{log_file})
		{
			# NOTE: This can't be a normal error because we can't write to the logs.
			die $THIS_FILE." ".__LINE__."; log file handle doesn't exist, but it should by now.\n";
		}
		
		# The handle has to be wrapped in a block to make 'print' happy as it doesn't like non-scalars for file handles
		print { $anvil->{HANDLE}{log_file} } $string;
	}
	else
	{
		Log::Journald::send(
			PRIORITY          => $priority, 
			MESSAGE           => $string, 
			CODE_FILE         => $source, 
			CODE_LINE         => $line, 
			SYSLOG_FACILITY   => $secure ? "authpriv" : $facility,
			SYSLOG_IDENTIFIER => $tag,
		);
	}
	
	return(0);
}

=head2 language

This sets or returns the log language ISO code.

Get the current log language;

 my $language = $anvil->Log->language;
 
Set the log langauge to Japanese;

 $anvil->Log->language({set => "jp"});

=cut
sub language
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 0;
	
	my $set   = defined $parameter->{set} ? $parameter->{set} : "";
	print $THIS_FILE." ".__LINE__."; set: [$set]\n" if $debug;
	
	if ($set)
	{
		$self->{LOG}{LANGUAGE} = $set;
		print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."]\n" if $debug;
	}
	
	print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."], defaults::log::language: [".$anvil->data->{defaults}{'log'}{language}."]\n" if $debug;
	if (not $self->{LOG}{LANGUAGE})
	{
		$self->{LOG}{LANGUAGE} = $anvil->data->{defaults}{'log'}{language};
		print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."]\n" if $debug;
	}
	
	print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."]\n" if $debug;
	return($self->{LOG}{LANGUAGE});
}

=head2 level

This sets or returns the active log level. Valid values are 0 to 4. See the 'entry()' method docs for more details.

Check the current log level:

 print "Current log level: [".$anvil->Log->level."]\n";
 
Change the current log level to 'C<< 2 >>';

 $anvil->Log->level({set => 2});

=cut
sub level
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 0;
	
	my $set   = defined $parameter->{set} ? $parameter->{set} : "";
	print $THIS_FILE." ".__LINE__."; set: [".$set."]\n" if $debug;
	
	if (($set =~ /^\d$/) && ($set >= 0) && ($set <= 4))
	{
		if ($set == 0)
		{
			$anvil->data->{defaults}{'log'}{level} = 0;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 1)
		{
			$anvil->data->{defaults}{'log'}{level} = 1;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 2)
		{
			$anvil->data->{defaults}{'log'}{level} = 2;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 3)
		{
			$anvil->data->{defaults}{'log'}{level} = 3;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 4)
		{
			$anvil->data->{defaults}{'log'}{level} = 4;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
	}
	elsif ($set ne "")
	{
		# Invalid value passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0047", variables => { set => $set }});
	}

	if ((not defined $anvil->data->{defaults}{'log'}{level}) or ($anvil->data->{defaults}{'log'}{level} !~ /^\d$/) or ($anvil->data->{defaults}{'log'}{level} < 0) or ($anvil->data->{defaults}{'log'}{level} > 4))
	{
		$anvil->data->{defaults}{'log'}{level} = 1;
		print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
	}
	
	print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$anvil->data->{defaults}{'log'}{level}."]\n" if $debug;
	return($anvil->data->{defaults}{'log'}{level});
}

=head2 secure

This sets or returns whether logging of sensitive log strings is enabled. 

It returns 'C<< 0 >>' if sensitive entries are *not* being logged (default). It returns 'C<< 1 >>' if they are.

Passing 'C<< 0 >>' disables recording sensitive logs. Passing 'C<< 1 >>' enables logging sensitive entries.
 
Enable logging of secure data;

 $anvil->Log->secure({set => 1});
 
 if ($anvil->Log->secure)
 {
	# Sensitive data logging is enabled.
 }
 
Disable sensitive log entry recording.

 $anvil->Log->secure({set => 0});

=cut
sub secure
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 0;
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	
	if (defined $set)
	{
		if ($set eq "0")
		{
			$anvil->data->{defaults}{'log'}{secure} = 0;
		}
		elsif ($set eq "1")
		{
			$anvil->data->{defaults}{'log'}{secure} = 1;
		}
	}
	
	return($anvil->data->{defaults}{'log'}{secure});
}

=head2 variables

This is a special method used in testing and debugging for logging a certain number of variables. It takes a hash reference via the 'C<< variables >>' parameter and creates a raw log entry showing the variables as 'C<< variable: [value] >>' pairs.

parameters;

NOTE: It takes all of the same parameters as 'C<< Log->entry >>', minus 'C<< raw >>', 'C<< key >>' and 'C<< variables >>':

head3 list (required)

This is a hash reference containing the variables to record.

If the passed in number of entries is 5 or less, the output will all be on one line. If more entries are passed, the variable/value pairs will be presented as one entry per line.

To allow for sorting, if the key starts with 's#:', that part of the key will be removed in the log. For example;

 $anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
 	"s1:i"            => $i,
 	"s2:column_name"  => $column_name, 
 	"s3:column_value" => $column_value,
 	"s4:not_null"     => $not_null,
 	"s5:data_type"    => $data_type, 
 }});
 
Would generate a sorted log entry that looks like:
 
 Aug 20 13:10:28 m3-striker01.alteeve.com anvil[9445]: Database.pm:2604; Variables:
                                                       |- i: [0]
                                                       |- column_name: [host_name]
                                                       |- column_value: [m3-striker01.alteeve.com]
                                                       |- not_null: [1]
                                                       \- data_type: [text]

All other key names are left alone and output is sorted alphabetically.

=cut
sub variables
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $language  = defined $parameter->{language}  ? $parameter->{language}  : $anvil->data->{defaults}{'log'}{language};
	my $level     = defined $parameter->{level}     ? $parameter->{level}     : 2;
	my $line      = defined $parameter->{line}      ? $parameter->{line}      : "";
	my $list      = defined $parameter->{list}      ? $parameter->{list}      : {};
	my $facility  = defined $parameter->{facility}  ? $parameter->{facility}  : $anvil->data->{defaults}{'log'}{facility};
	my $priority  = defined $parameter->{priority}  ? $parameter->{priority}  : "";
	my $secure    = defined $parameter->{secure}    ? $parameter->{secure}    : 0;
	my $server    = defined $parameter->{server}    ? $parameter->{server}    : $anvil->data->{defaults}{'log'}{server};
	my $source    = defined $parameter->{source}    ? $parameter->{source}    : "";
	my $tag       = defined $parameter->{tag}       ? $parameter->{tag}       : $anvil->data->{defaults}{'log'}{tag};
	
	# Exit immediately if this isn't going to be logged
	if (not defined $level)
	{
		die $THIS_FILE." ".__LINE__."; Log->variables() called without 'level': [".$level."] defined from: [$source : $line]\n";
	}
	elsif (not defined $anvil->Log->level)
	{
		die $THIS_FILE." ".__LINE__."; Log->variables() called without Log->level: [".$anvil->Log->level."] defined from: [$source : $line]\n";
	}
	#print "level: [$level], logging: [".$anvil->Log->level."], secure: [$secure], logging secure: [".$anvil->Log->secure."]\n";
	if ($level > $anvil->Log->level)
	{
		return(1);
	}
	if (($secure) && (not $anvil->Log->secure))
	{
		return(2);
	}
	
	# If I don't have a list, or the list is empty, return.
	my $entry   = 1;
	my $entries = keys %{$list};
	if ($entries)
	{
		# If the key points to an undefined value, convert it to '!!undef!!' so that we don't scare
		# the user with 'undefined variable' warnings.
		foreach my $key (sort {$a cmp $b} keys %{$list})
		{
			if (not defined $list->{$key})
			{
				$list->{$key} = "!!undef!!";
			}
		}
		my $raw = "";
		# NOTE: If you change this, be sure to update Tools.t
		if ($entries <= 4)
		{
			# Put all the entries on one line.
			foreach my $key (sort {$a cmp $b} keys %{$list})
			{
				# Strip a leading 'sX:' in case the user is sorting the output.
				my $say_key =  $key;
				   $say_key =~ s/^s(\d+)://;
				$raw .= "$say_key: [".$list->{$key}."], ";
			}
			$raw =~ s/, $//;
		}
		else
		{
			# Put all the entries on their own line. We'll loop twice; the first time to get the 
			# longest variable, and the second loop to print them (with dots to make the values 
			# all line up).
			my $length = 0;
			foreach my $key (sort {$a cmp $b} keys %{$list})
			{
				if (length($key) > $length)
				{
					$length = length($key);
				}
			}
			# We add '1' to account for the colon we append.
			$length++;
			
			$raw .= $anvil->Words->string({key => "log_0019"})."\n";
			foreach my $key (sort {$a cmp $b} keys %{$list})
			{
				# Strip a leading 'sX:' in case the user is sorting the output.
				my $say_key =  $key;
				   $say_key =~ s/^s(\d+)://;
				   $say_key .= ":";
				my $difference = $length - length($say_key);
				if ($difference)
				{
					$say_key .= " ";
					for (2..$difference)
					{
						$say_key .= ".";
					}
				}
				if ($entry ne $entries)
				{
					$raw .= "|- $say_key [".$list->{$key}."]\n";
				}
				else
				{
					$raw .= "\\- $say_key [".$list->{$key}."]\n";
				}
				$entry++;
			}
		}
		
		# Do the raw log entry.
		$anvil->Log->entry({
			language => $language,
			level    => $level,
			line     => $line,
			facility => $facility,
			priority => $priority,
			raw      => $raw,
			secure   => $secure,
			server   => $server,
			source   => $source,
			tag      => $tag,
		})
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

=head2 _adjust_log_level

This is a private method used by 'C<< $anvil->Get->switches >>' that automatically adjusts the active log level to 0 ~ 4. See 'C<< perldoc Anvil::Tools::Get >>' for more information.

=cut 
sub _adjust_log_level
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	if ($anvil->data->{switches}{V})
	{
		$anvil->Log->level({set => 0});
	}
	elsif ($anvil->data->{switches}{v})
	{
		$anvil->Log->level({set => 1});
	}
	elsif ($anvil->data->{switches}{vv})
	{
		$anvil->Log->level({set => 2});
	}
	elsif ($anvil->data->{switches}{vvv})
	{
		$anvil->Log->level({set => 3});
	}
	elsif ($anvil->data->{switches}{vvvv})
	{
		$anvil->Log->level({set => 4});
	}
	
	return(0);
}

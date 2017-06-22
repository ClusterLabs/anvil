package AN::Tools::Log;
# 
# This module contains methods used to handle logging related tasks
# 

use strict;
use warnings;
use Data::Dumper;

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

AN::Tools::Log

Provides all methods related to logging.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Log->X'. 
 # 
 # Example using 'entry()';
 my $foo_path = $an->Log->entry({...});

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

=head2 entry

This method writes an entry to the journald logs, provided the log entry's level is equal to or higher than the active log level. The exception is if the log entry contains sensitive data, like a password, and 'C<< log::secure >> is set to 'C<< 0 >>' (the default).

Here is a simple example of writing a simple log entry at log log level 1.

 $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0001"});

In the example above, the string will be written to the log file if the active log level is 'C<< 1 >>' or higher and it will use the 'C<< log::language >>' language to translate the string key.

Now a more complex example;

 $an->Log->entry({
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

 $an->Log->entry({
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

This is the tag given to the log entry. By default, it will be 'C<< an-tools >>'.

=head3 variables (optional)

This is a hash reference containing replacement variables to inject into the 'C<< key >>' string.

=cut
sub entry
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $key       = defined $parameter->{key}       ? $parameter->{key}       : "";
	my $language  = defined $parameter->{language}  ? $parameter->{language}  : $an->Log->language;
	my $level     = defined $parameter->{level}     ? $parameter->{level}     : 2;
	my $line      = defined $parameter->{line}      ? $parameter->{line}      : "";
	my $facility  = defined $parameter->{facility}  ? $parameter->{facility}  : $an->data->{defaults}{'log'}{facility};
	my $priority  = defined $parameter->{priority}  ? $parameter->{priority}  : "";
	my $raw       = defined $parameter->{raw}       ? $parameter->{raw}       : "";
	my $secure    = defined $parameter->{secure}    ? $parameter->{secure}    : 0;
	my $server    = defined $parameter->{server}    ? $parameter->{server}    : $an->data->{defaults}{'log'}{server};
	my $source    = defined $parameter->{source}    ? $parameter->{source}    : "";
	my $tag       = defined $parameter->{tag}       ? $parameter->{tag}       : $an->data->{defaults}{'log'}{tag};
	my $variables = defined $parameter->{variables} ? $parameter->{variables} : "";
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - level: [$level], defaults::log::level: [".$an->Log->{defaults}{'log'}{level}."], logging secure? [".$an->Log->secure."]\n";
	
	# Exit immediately if this isn't going to be logged
	if ($level > $an->Log->level)
	{
		return(1);
	}
	if (($secure) && (not $an->Log->secure))
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
		my $message .= $an->Words->string({	
			language  => $language,
			key       => $key,
			variables => $variables,
		});
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - message: [$message]\n";
		$string .= $message;
	}
	
	# Clean up the string for bash
	$string =~ s/"/\\\"/gs;		# Single-escape "   -> \\"
	$string =~ s/\\\\"/\\\\\\"/gs;	# triple-escape \\" -> \\\"
	#$string =~ s/\(/\\\(/gs;
	
	# NOTE: This might become too expensive, in which case we may need to create a connection to journald
	#       that we can leave open during a run.
	if ((not defined $tag) or (not defined $priority_string) or (not defined $an->data->{path}{exe}{logger}))
	{
		die $THIS_FILE." ".__LINE__."; Something not defined in Log->entry; path::exe::logger: [".$an->data->{path}{exe}{logger}."], tag: [".$tag."], 'defaults::log::tag': [".$an->data->{defaults}{'log'}{tag}."], priority_string: [".$priority_string."]\n";
	}
	my $shell_call = $an->data->{path}{exe}{logger}." --id --tag ".$tag." --priority ".$priority_string;
	if ($server)
	{
		$shell_call .= " --server ".$server;
	}
	$shell_call .= " -- \"".$string."\"";
	
	# Record it!
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - shell_call: [$shell_call]\n";
	open(my $file_handle, $shell_call." 2>&1 |") or warn $THIS_FILE." ".__LINE__."; [ Warning ] - Failed to call: [".$shell_call."], the error was: $!\n";
	while(<$file_handle>)
	{
		# This should never be hit...
		chomp;
		warn $THIS_FILE." ".__LINE__."; [ Warning ] - Unexpected output from: [".$shell_call."] -> [".$_."]\n";
	}
	close $file_handle;
	
	return(0);
}

=head2 language

This sets or returns the log language ISO code.

Get the current log language;

 my $language = $an->Log->language;
 
Set the log langauge to Japanese;

 $an->Log->language({set => "jp"});

=cut
sub language
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set   = defined $parameter->{set} ? $parameter->{set} : "";
	my $debug = 0;
	print $THIS_FILE." ".__LINE__."; set: [$set]\n" if $debug;
	
	if ($set)
	{
		$self->{LOG}{LANGUAGE} = $set;
		print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."]\n" if $debug;
	}
	
	print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."], defaults::log::language: [".$an->data->{defaults}{'log'}{language}."]\n" if $debug;
	if (not $self->{LOG}{LANGUAGE})
	{
		$self->{LOG}{LANGUAGE} = $an->data->{defaults}{'log'}{language};
		print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."]\n" if $debug;
	}
	
	print $THIS_FILE." ".__LINE__."; LOG::LANGUAGE: [".$self->{LOG}{LANGUAGE}."]\n" if $debug;
	return($self->{LOG}{LANGUAGE});
}

=head2 level

This sets or returns the active log level. Valid values are 0 to 4. See the 'entry()' method docs for more details.

Check the current log level:

 print "Current log level: [".$an->Log->level."]\n";
 
Change the current log level to 'C<< 2 >>';

 $an->Log->level({set => 2});

=cut
sub level
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set   = defined $parameter->{set} ? $parameter->{set} : "";
	my $debug = 0;
	print $THIS_FILE." ".__LINE__."; set: [".$set."]\n" if $debug;
	
	if (($set =~ /^\d$/) && ($set >= 0) && ($set <= 4))
	{
		if ($set == 0)
		{
			$an->data->{defaults}{'log'}{level} = 0;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 1)
		{
			$an->data->{defaults}{'log'}{level} = 1;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 2)
		{
			$an->data->{defaults}{'log'}{level} = 2;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 3)
		{
			$an->data->{defaults}{'log'}{level} = 3;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
		elsif ($set == 4)
		{
			$an->data->{defaults}{'log'}{level} = 4;
			print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
		}
	}
	elsif ($set ne "")
	{
		# Invalid value passed.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0047", variables => { set => $set }});
	}

	if ((not defined $an->data->{defaults}{'log'}{level}) or ($an->data->{defaults}{'log'}{level} !~ /^\d$/) or ($an->data->{defaults}{'log'}{level} < 0) or ($an->data->{defaults}{'log'}{level} > 4))
	{
		$an->data->{defaults}{'log'}{level} = 1;
		print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
	}
	
	print $THIS_FILE." ".__LINE__."; defaults::log::level: [".$an->data->{defaults}{'log'}{level}."]\n" if $debug;
	return($an->data->{defaults}{'log'}{level});
}

=head2 secure

This sets or returns whether logging of sensitive log strings is enabled. 

It returns 'C<< 0 >>' if sensitive entries are *not* being logged (default). It returns 'C<< 1 >>' if they are.

Passing 'C<< 0 >>' disables recording sensitive logs. Passing 'C<< 1 >>' enables logging sensitive entries.
 
Enable logging of secure data;

 $an->Log->secure({set => 1});
 
 if ($an->Log->secure)
 {
	# Sensitive data logging is enabled.
 }
 
Disable sensitive log entry recording.

 $an->Log->secure({set => 0});

=cut
sub secure
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set   = defined $parameter->{set} ? $parameter->{set} : "";
	my $debug = 0;
	
	if (defined $set)
	{
		if ($set eq "0")
		{
			$an->data->{defaults}{'log'}{secure} = 0;
		}
		elsif ($set eq "1")
		{
			$an->data->{defaults}{'log'}{secure} = 1;
		}
	}
	
	return($an->data->{defaults}{'log'}{secure});
}

=head2 variables

This is a special method used in testing and debugging for logging a certain number of variables. It takes a hash reference via the 'C<< variables >>' parameter and creates a raw log entry showing the variables as 'C<< variable: [value] >>' pairs.

parameters;

NOTE: It takes all of the same parameters as 'C<< Log->entry >>', minus 'C<< raw >>', 'C<< key >>' and 'C<< variables >>':

head3 list (required)

This is a hash reference containing the variables to record.

=cut
sub variables
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $language  = defined $parameter->{language}  ? $parameter->{language}  : $an->data->{defaults}{'log'}{language};
	my $level     = defined $parameter->{level}     ? $parameter->{level}     : 2;
	my $line      = defined $parameter->{line}      ? $parameter->{line}      : "";
	my $list      = defined $parameter->{list}      ? $parameter->{list}      : {};
	my $facility  = defined $parameter->{facility}  ? $parameter->{facility}  : $an->data->{defaults}{'log'}{facility};
	my $priority  = defined $parameter->{priority}  ? $parameter->{priority}  : "";
	my $secure    = defined $parameter->{secure}    ? $parameter->{secure}    : 0;
	my $server    = defined $parameter->{server}    ? $parameter->{server}    : $an->data->{defaults}{'log'}{server};
	my $source    = defined $parameter->{source}    ? $parameter->{source}    : "";
	my $tag       = defined $parameter->{tag}       ? $parameter->{tag}       : $an->data->{defaults}{'log'}{tag};
	
	# Exit immediately if this isn't going to be logged
	if (not defined $level)
	{
		die $THIS_FILE." ".__LINE__."; Log->variables() called without 'level': [".$level."] defined from: [$source : $line]\n";
	}
	elsif (not defined $an->Log->level)
	{
		die $THIS_FILE." ".__LINE__."; Log->variables() called without Log->level: [".$an->Log->level."] defined from: [$source : $line]\n";
	}
	if ($level > $an->Log->level)
	{
		return(1);
	}
	if (($secure) && (not $an->Log->secure))
	{
		return(2);
	}
	
	# If I don't have a list, or the list is empty, return.
	my $entry   = 1;
	my $entries = keys %{$list};
	if ($entries)
	{
		my $raw = "";
		if ($entries < 5)
		{
			# Put all the entries on one line.
			foreach my $key (sort {$a cmp $b} keys %{$list})
			{
				$raw .= "$key: [".$list->{$key}."], ";
			}
			$raw =~ s/, $//;
		}
		else
		{
			# Put all the entries on their own line.
			$raw .= $an->Words->string({key => "log_0019"})."\n";
			foreach my $key (sort {$a cmp $b} keys %{$list})
			{
				if ($entry ne $entries)
				{
					$raw .= "|- $key: [".$list->{$key}."]\n";
				}
				else
				{
					$raw .= "\\- $key: [".$list->{$key}."]\n";
				}
				$entry++;
			}
		}
		
		# Do the raw log entry.
		$an->Log->entry({
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

This is a private method used by 'C<< $an->Get->switches >>' that automatically adjusts the active log level to 0 ~ 4. See 'C<< perldoc AN::Tools::Get >>' for more information.

=cut 
sub _adjust_log_level
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	if ($an->data->{switches}{V})
	{
		$an->Log->level({set => 0});
	}
	elsif ($an->data->{switches}{v})
	{
		$an->Log->level({set => 1});
	}
	elsif ($an->data->{switches}{vv})
	{
		$an->Log->level({set => 2});
	}
	elsif ($an->data->{switches}{vvv})
	{
		$an->Log->level({set => 3});
	}
	elsif ($an->data->{switches}{vvvv})
	{
		$an->Log->level({set => 4});
	}
	
	return(0);
}

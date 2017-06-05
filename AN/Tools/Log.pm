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

=head2 entry

This method writes an entry to the log file, provided the log file is equal to or higher than the active log level. The exception is if the log entry contains sensitive data, like a password, and 'C<< log::secure >> is set to 'C<< 0 >>' (the default).

Here is a simple example of writing a simple log entry at log log level 1.

 $an->Log->entry({file => $THIS_FILE, line => __LINE__, level => 1, key => "log_0001"});

In the example above, the string will be written to the log file if the active log level is 'C<< 1 >>' or higher and it will use the 'C<< log::language >>' language to translate the string key.

Now a more complex example;

 $an->Log->entry({
 	file      => $THIS_FILE, 
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
 	file      => $THIS_FILE, 
 	line      => __LINE__, 
 	level     => 2,
 	raw       => "This error can't be translated",
 });

The above should be used very sparingly, and generally only in places where string processing itself is being logged.

Parameters;

=head3 file (optional)

When set, the string is pre-pended to the log entry. This is generally set to 'C<< $THIS_FILE >>', which itself should contain the file name requesting the log entry.

=head3 key (required)

NOTE: This is not required *if* 'C<< raw >>' is used instead.

This is the string key to use for the log entry. By default, it will be translated into the 'C<< log::language >> language. If the string contains replacement variables, be sure to also use 'C<< variables >>'.

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

=head3 raw (optional)

NOTE: This *or* C<< key >> must be passed.

This can contain a string to record to the log file. It is treated as a raw string and is not translated, altered or processed in any way. It will be recorded exactly as-is, provided the log level and secure settings allow for it.

=head3 secure (optional)

When set, this indicates that the log entry might contain sensitive data, like a password. When set, the log entry will only be recorded if 'C<< log::secure >>' is set to '1' *and* the log level is equal to or higher than 'C<< log::level >>'.

=head3 variables (optional)

This is a hash reference containing replacement variables to inject into the 'C<< key >>' string.

=cut
sub entry
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $key       = defined $parameter->{key}       ? $parameter->{key}       : "";
	my $level     = defined $parameter->{level}     ? $parameter->{level}     : 2;
	my $line      = defined $parameter->{line}      ? $parameter->{line}      : "";
	my $raw       = defined $parameter->{raw}       ? $parameter->{raw}       : "";
	my $secure    = defined $parameter->{secure}    ? $parameter->{secure}    : 0;
	my $variables = defined $parameter->{variables} ? $parameter->{variables} : "";
	
	if ($level > $an->data->{'log'}{level})
	{
		return(1);
	}
	
	
	return(0);
}

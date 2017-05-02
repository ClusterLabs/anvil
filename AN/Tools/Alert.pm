package AN::Tools::Alert;
# 
# This module contains methods used to handle alerts and errors.
# 

use strict;
use warnings;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Alert.pm";

### Methods;
# error

=pod

=encoding utf8

=head1 NAME

AN::Tools::Alert

Provides all methods related warnings and alerts.

=head1 SYNOPSIS

 use AN::Tools::Alert;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Alert->X'. Example using 'find';
 my $foo_path = $an->Storage->find({file => "foo"});

=head1 METHODS

Methods in the core module;

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


=head2 error

=cut

# Later, this will support all the translation and logging methods. For now, just print the error and exit.
sub error
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
# 	$an->Log->entry({log_level => 2, title_key => "tools_log_0001", title_variables => { function => "error" }, message_key => "tools_log_0002", file => $THIS_FILE, line => __LINE__});
# 	
# 	# Setup default values
# 	my $title_key         = $parameter->{title_key}         ? $parameter->{title_key}         : $an->String->get({key => "an_0004"});
# 	my $title_variables   = $parameter->{title_variables}   ? $parameter->{title_variables}   : "";
# 	my $message_key       = $parameter->{message_key}       ? $parameter->{message_key}       : $an->String->get({key => "an_0005"});
# 	my $message_variables = $parameter->{message_variables} ? $parameter->{message_variables} : "";
# 	my $code              = $parameter->{code}              ? $parameter->{code}              : 1;
# 	my $file              = $parameter->{file}              ? $parameter->{file}              : $an->String->get({key => "an_0006"});
# 	my $line              = $parameter->{line}              ? $parameter->{line}              : "";
# 	#print "$THIS_FILE ".__LINE__."; title_key: [$title_key], title_variables: [$title_variables], message_key: [$message_key], message_variables: [$message_variables], code: [$code], file: [$file], line: [$line]\n";
# 	
# 	# It is possible for this to become a run-away call, so this helps
# 	# catch when that happens.
# 	$an->_error_count($an->_error_count + 1);
# 	if ($an->_error_count > $an->_error_limit)
# 	{
# 		print "Infinite loop detected while trying to print an error:\n";
# 		print "- title_key:         [$title_key]\n";
# 		print "- title_variables:   [$title_variables]\n";
# 		print "- message_key:       [$message_key]\n";
# 		print "- message_variables: [$title_variables]\n";
# 		print "- code:              [$code]\n";
# 		print "- file:              [$file]\n";
# 		print "- line:              [$line]\n";
# 		die "Infinite loop detected while trying to print an error, exiting.\n";
# 	}
# 	
# 	# If the 'code' is empty and 'message' is "error_\d+", strip that code
# 	# off and use it as the error code.
# 	#print "$THIS_FILE ".__LINE__."; code: [$code], message_key: [$message_key]\n";
# 	if ((not $code) && ($message_key =~ /error_(\d+)/))
# 	{
# 		$code = $1;
# 		#print "$THIS_FILE ".__LINE__."; code: [$code], message_key: [$message_key]\n";
# 	}
# 	
# 	# If the title is a key, translate it.
# 	#print "$THIS_FILE ".__LINE__."; title_key: [$title_key]\n";
# 	if ($title_key =~ /\w+_\d+$/)
# 	{
# 		$title_key = $an->String->get({
# 			key		=>	$title_key,
# 			variables	=>	$title_variables,
# 		});
# 		#print "$THIS_FILE ".__LINE__."; title_key: [$title_key]\n";
# 	}
# 	
# 	# If the message is a key, translate it.
# 	#print "$THIS_FILE ".__LINE__."; message_key: [$message_key]\n";
# 	if ($message_key =~ /\w+_\d+$/)
# 	{
# 		$message_key = $an->String->get({
# 			key		=>	$message_key,
# 			variables	=>	$message_variables,
# 		});
# 		#print "$THIS_FILE ".__LINE__."; message_key: [$message_key]\n";
# 	}
# 	
# 	# Set my error string
# 	my $fatal_heading = $an->String->get({key => "an_0002"});
# 	#print "$THIS_FILE ".__LINE__."; fatal_heading: [$fatal_heading]\n";
# 	
# 	my $readable_line = $an->Readable->comma($line);
# 	#print "$THIS_FILE ".__LINE__."; readable_line: [$readable_line]\n";
# 	
# 	### TODO: Copy this to 'warning'.
# 	# At this point, the title and message keys are the actual messages.
# 	my $error = "\n".$an->String->get({
# 		key		=>	"an_0007",
# 		variables	=>	{
# 			code		=>	$code,
# 			heading		=>	$fatal_heading,
# 			file		=>	$file,
# 			line		=>	$readable_line,
# 			title		=>	$title_key,
# 			message		=>	$message_key,
# 		},
# 	})."\n\n";
# 	#print "$THIS_FILE ".__LINE__."; error: [$error]\n";
# 	
# 	# Set the internal error flags
# 	$an->Alert->_set_error($error);
# 	$an->Alert->_set_error_code($code);
# 	
# 	# Append "exiting" to the error string if it is fatal.
# 	$error .= $an->String->get({key => "an_0008"})."\n";
# 	
# 	# Write a copy of the error to the log.
# 	$an->Log->entry({file => $THIS_FILE, level => 0, raw => $error});
# 	
# 	# If this is a browser calling us, print the footer so that the loading pinwheel goes away.
# 	if ($ENV{'HTTP_REFERER'})
# 	{
# 		$an->Striker->_footer();
# 	}
# 	
# 	# Don't actually die, but do print the error, if fatal errors have been globally disabled (as is done
# 	# in the tests).
# 	if (not $an->Alert->no_fatal_errors)
# 	{
# 		if ($ENV{'HTTP_REFERER'})
# 		{
# 			print "<pre>\n";
# 			print "$error\n" if not $an->Alert->no_fatal_errors;
# 			print "</pre>\n";
# 		}
# 		else
# 		{
# 			print "$error\n" if not $an->Alert->no_fatal_errors;
# 		}
# 		$an->data->{sys}{footer_printed} = 1;
# 		$an->nice_exit({exit_code => $code});
# 	}
# 	
# 	return ($code);
}

1;

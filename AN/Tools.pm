package AN::Tools;
# 
# This is the "root" package that manages the sub modules and controls access to their methods.
# 

BEGIN
{
	our $VERSION = "0.1.001";
	# This suppresses the 'could not find ParserDetails.ini in /PerlApp/XML/SAX' warning message in 
	# XML::Simple calls.
	$ENV{HARNESS_ACTIVE} = 1;
}

use strict;
use warnings;
use IO::Handle;
use XML::Simple;
my $THIS_FILE = "Tools.pm";

# Setup for UTF-8 mode.
use utf8;
$ENV{'PERL_UNICODE'} = 1;

=pod

=encoding utf8

=head1 NAME

AN::Tools

Provides a common oject handle to all AN::Tools::* module methods and handles invocation configuration. 

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools::* modules.
 my $an = AN::Tools->new();
  
 # Again, but this time sets some initial values in the '$an->data' hash.
 my $an = AN::Tools->new(
 {
 	data		=>	{
 		foo		=>	"",
 		bar		=>	[],
 		baz		=>	{},
 	},
 });
 
 # This example gets the handle and also sets the default user and log 
 # languages as Japanese, sets a custom log file and sets the log level to 
 # '2'.
 my $an = AN::Tools->new(
 {
 	'Log'		=>	{
 	  	user_language	=>	"jp",
 		log_language	=>	"jp"
 		level		=>	2,
 	  },
 });

=head1 DESCRIPTION

The AN::Tools module and all sub-modules are designed for use by Alteeve-based applications. It can be used as a general framework by anyone interested.

Core features are;

* Supports per user, per logging language selection where translations from from XML-formatted "String" files that support UTF8 and variable substitutions.
* Support for command-line and HTML output. Skinning support for HTML-based user interfaces.
* Redundant database access, resynchronization and archiving.
* Highly-native with minimal use of external perl modules and compiled code.

Methods in the core module;

=cut

# The constructor through which all other module's methods will be accessed.
sub new
{
	my $class     = shift;
	my $parameter = shift;
	my $self      = {
		HANDLE				=>	{
		},
		DATA				=>	{},
		ERROR_COUNT			=>	0,
		ERROR_LIMIT			=>	10000,
		DEFAULT				=>	{
			STRINGS				=>	'AN/strings.xml',
			LANGUAGE			=>	'en_CA',
			LOG_FILE			=>	'/var/log/an.log',
			SEARCH_DIR			=>	\@INC,
		},
		ENV_VALUES			=>	{
			ENVIRONMENT			=>	'cli',
		},
	};

	# Bless you!
	bless $self, $class;

	# This isn't needed, but it makes the code below more consistent with and portable to other modules.
	my $an = $self;

	# Set some system paths and system default variables
	$an->_set_paths;
	$an->_set_defaults;

	# Check the operating system and set any OS-specific values.
	$an->Check->_os;

	# This checks the environment this program is running in.
	$an->Check->_environment;

	# Setup my '$an->data' hash right away so that I have a place to store the strings hash.
	$an->data($parameter->{data}) if $parameter->{data};

	# I need to read the initial words early.
	$self->{DEFAULT}{STRINGS} = $an->Storage->find({file => $self->{DEFAULT}{STRINGS}, fatal => 1});
	$an->Storage->read_words({file  => $self->{DEFAULT}{STRINGS}});

	# Set the directory delimiter
	my $directory_delimiter = $an->_directory_delimiter();

	# Set passed parameters if needed.
	if (ref($parameter) eq "HASH")
	{
		### Local parameters
		# Reset the paths
		$an->_set_paths;

		### AN::Tools::Log parameters
		# Set the default languages.
		$an->default_language		($parameter->{'Log'}{user_language}) 	if         $parameter->{'Log'}{user_language};
		$an->default_log_language	($parameter->{'Log'}{log_language}) 	if         $parameter->{'Log'}{log_language};
		
		# Set the log file.
		$an->Log->level			($parameter->{'Log'}{level}) 		if defined $parameter->{'Log'}{level};
		$an->Log->db_transactions	($parameter->{'Log'}{db_transactions}) 	if defined $parameter->{'Log'}{db_transactions};

		### AN::Tools::Readable parameters
		# Readable needs to be set before Log so that changes to 'base2' are made before the default
		# log cycle size is interpreted.
		$an->Readable->base2		($parameter->{Readable}{base2}) 	if defined $parameter->{Readable}{base2};

		### AN::Tools::String parameters
		# Force UTF-8.
		$an->String->force_utf8		($parameter->{String}{force_utf8}) 	if defined $parameter->{String}{force_utf8};

		# Read in the user's words.
		$an->Storage->read_words({file => $parameter->{String}{file}})          if defined $parameter->{String}{file};

		### AN::Tools::Get parameters
		$an->Get->use_24h		($parameter->{'Get'}{use_24h})		if defined $parameter->{'Get'}{use_24h};
	}

	# Call methods that need to be loaded at invocation of the module.
	if (($an->{DEFAULT}{STRINGS} =~ /^\.\//) && (not -e $an->{DEFAULT}{STRINGS}))
	{
		# Try to find the location of this module (I can't use Dir::Self' because it is not provided
		# by RHEL 6)
		my $root = ($INC{'AN/Tools.pm'} =~ /^(.*?)\/AN\/Tools.pm/)[0];
		my $file = ($an->{DEFAULT}{STRINGS} =~ /^\.\/(.*)/)[0];
		my $path = "$root/$file";
		if (-e $path)
		{
			# Found the words file.
			$an->{DEFAULT}{STRINGS} = $path;
		}
	}
	if (not -e $an->{DEFAULT}{STRINGS})
	{
		print "Failed to read the core words file: [".$an->{DEFAULT}{STRINGS}."]\n";
		$an->nice_exit({exit_code => 255});
	}
	$an->Storage->read_words({file => $an->{DEFAULT}{STRINGS}});

	return ($self);
}

=head2 data

This is the method used to access the main hash reference that all user-accessible values are stored in. This includes words, configuration file variables and so forth.

When called without an argument, it returns the existing '$an->data' hash reference.

 my $an = $an->data();

When called with a hash reference as the argument, it sets '$an->data' to the new hash.

 my $some_hash = {};
 my $an        = $an->data($some_hash);

Data can be entered into or access by treating '$an->data' as a normal hash reference.

 my $an = AN::Tools->new(
 {
 	data		=>	{
 		foo		=>	"",
 		bar		=>	[6, 4, 12],
 		baz		=>	{
			animal		=>	"Cat",
			thing		=>	"Boat",
		},
 	},
 });
 
 # Copy the 'Cat' value into the $animal variable.
 my $animal = $an->data->{baz}{animal};
 
 # Set 'A thing' in 'foo'.
 $an->data->{foo} = "A thing";

The C<$an> variable is set inside all modules and acts as shared storage for variables, values and references in all modules. It acts as the core storage for most applications using AN::Tools.

=cut
sub data
{
	my ($self) = shift;
	
	# Pick up the passed in hash, if any.
	$self->{DATA} = shift if $_[0];
	
	return ($self->{DATA});
}

=head2 environment

This is the method used to check or set whether the program is outputting to command line or a browser.

When called without an argument, it returns the current environment.

 if ($an->environment() eq "cli")
 {
 	# format for STDOUT
 }
 elsif ($an->environment() eq "html")
 {
 	# Use the template system to output HTML
 }

When called with a string as the argument, that string will be set as the environment string.

 $an->environment("cli");

Technically, any string can be used, however only 'cli' or 'html' are used by convention.

=cut
sub environment
{
	my ($self) = shift;
	
	# Pick up the passed in delimiter, if any.
	$self->{ENV_VALUES}{ENVIRONMENT} = shift if $_[0];
	
	return ($self->{ENV_VALUES}{ENVIRONMENT});
}

package AN::Tools;
# 
# This is the "root" package that manages the sub modules and controls access to their methods.
# 

BEGIN
{
	our $VERSION = "3.0.000";
	# This suppresses the 'could not find ParserDetails.ini in /PerlApp/XML/SAX' warning message in 
	# XML::Simple calls.
	$ENV{HARNESS_ACTIVE} = 1;
}

use strict;
use warnings;
use IO::Handle;
use XML::Simple;
use Data::Dumper;
my $THIS_FILE = "Tools.pm";

# Setup for UTF-8 mode.
use utf8;
$ENV{'PERL_UNICODE'} = 1;

# I intentionally don't use EXPORT, @ISA and the like because I want my "subclass"es to be accessed in a
# somewhat more OO style. I know some may wish to strike me down for this, but I like the idea of accessing
# methods via their containing module's name. (A La: $an->Module->method rather than $an->method).
use AN::Tools::Alert;
use AN::Tools::Storage;

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

=head1 METHODS

Methods in the core module;

=cut

# The constructor through which all other module's methods will be accessed.
sub new
{
	my $class     = shift;
	my $parameter = shift;
	my $self      = {
		HANDLE				=>	{
			ALERT				=>	AN::Tools::Alert->new(),
			STORAGE				=>	AN::Tools::Storage->new(),
		},
		DATA				=>	{},
		ERROR_COUNT			=>	0,
		ERROR_LIMIT			=>	10000,
		DEFAULT				=>	{
			LANGUAGE			=>	'en_CA',
			LOG_FILE			=>	'/var/log/an.log',
			STRINGS				=>	'AN/strings.xml',
		},
		ENV_VALUES			=>	{
			ENVIRONMENT			=>	'cli',
		},
	};

	# Bless you!
	bless $self, $class;

	# This isn't needed, but it makes the code below more consistent with and portable to other modules.
	my $an = $self;
	
	# Get a handle on the various submodules
	$an->Alert->parent($an);
	$an->Storage->parent($an);

	# Set some system paths and system default variables
	$an->_add_environment_path_to_search_directories;
	$an->_set_paths;
# 	$an->_set_defaults;

	# This checks the environment this program is running in.
	$an->environment;

	# Setup my '$an->data' hash right away so that I have a place to store the strings hash.
	$an->data($parameter->{data}) if $parameter->{data};

	# I need to read the initial words early.
# 	$self->{DEFAULT}{STRINGS} = $an->Storage->find({file => $self->{DEFAULT}{STRINGS}, fatal => 1});
# 	$an->Storage->read_words({file  => $self->{DEFAULT}{STRINGS}});

	# Set passed parameters if needed.
	if (ref($parameter) eq "HASH")
	{
		### Local parameters
		# Reset the paths
# 		$an->_set_paths;
# 
# 		### AN::Tools::Log parameters
# 		# Set the default languages.
# 		$an->default_language		($parameter->{'Log'}{user_language}) 	if         $parameter->{'Log'}{user_language};
# 		$an->default_log_language	($parameter->{'Log'}{log_language}) 	if         $parameter->{'Log'}{log_language};
# 		
# 		# Set the log file.
# 		$an->Log->level			($parameter->{'Log'}{level}) 		if defined $parameter->{'Log'}{level};
# 		$an->Log->db_transactions	($parameter->{'Log'}{db_transactions}) 	if defined $parameter->{'Log'}{db_transactions};
# 
# 		### AN::Tools::Readable parameters
# 		# Readable needs to be set before Log so that changes to 'base2' are made before the default
# 		# log cycle size is interpreted.
# 		$an->Readable->base2		($parameter->{Readable}{base2}) 	if defined $parameter->{Readable}{base2};
# 
# 		### AN::Tools::String parameters
# 		# Force UTF-8.
# 		$an->String->force_utf8		($parameter->{String}{force_utf8}) 	if defined $parameter->{String}{force_utf8};
# 
# 		# Read in the user's words.
# 		$an->Storage->read_words({file => $parameter->{String}{file}})          if defined $parameter->{String}{file};
# 
# 		### AN::Tools::Get parameters
# 		$an->Get->use_24h		($parameter->{'Get'}{use_24h})		if defined $parameter->{'Get'}{use_24h};
	}
	elsif($parameter)
	{
		# Um...
		print $THIS_FILE." ".__LINE__."; AN::Tools->new() invoked with an invalid parameter. Expected a hash reference, but got: [$parameter]\n";
		exit(1);
	}

	# Call methods that need to be loaded at invocation of the module.
# 	if (($an->{DEFAULT}{STRINGS} =~ /^\.\//) && (not -e $an->{DEFAULT}{STRINGS}))
# 	{
# 		# Try to find the location of this module (I can't use Dir::Self' because it is not provided
# 		# by RHEL 6)
# 		my $root = ($INC{'AN/Tools.pm'} =~ /^(.*?)\/AN\/Tools.pm/)[0];
# 		my $file = ($an->{DEFAULT}{STRINGS} =~ /^\.\/(.*)/)[0];
# 		my $path = "$root/$file";
# 		if (-e $path)
# 		{
# 			# Found the words file.
# 			$an->{DEFAULT}{STRINGS} = $path;
# 		}
# 	}
# 	if (not -e $an->{DEFAULT}{STRINGS})
# 	{
# 		print "Failed to read the core words file: [".$an->{DEFAULT}{STRINGS}."]\n";
# 		$an->nice_exit({exit_code => 255});
# 	}
# 	$an->Storage->read_words({file => $an->{DEFAULT}{STRINGS}});

	return ($self);
}

#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################


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
	my ($an) = shift;
	
	# Pick up the passed in hash, if any.
	$an->{DATA} = shift if $_[0];
	
	return ($an->{DATA});
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
	my ($an) = shift;
	
	# Pick up the passed in delimiter, if any.
	$an->{ENV_VALUES}{ENVIRONMENT} = shift if $_[0];
	
	return ($an->{ENV_VALUES}{ENVIRONMENT});
}

#############################################################################################################
# Public methods used to access sub modules.                                                                #
#############################################################################################################

=head1 Submodule Access Methods

The methods below are used to access methods of submodules using 'C<$an->Module->method()>'.

=cut

=head2 Alert

Access the C<Alert.pm> methods via 'C<$an->Alert->method>'.

=cut

# Makes my handle to AN::Tools::Storage clearer when using this module to access its methods.
sub Alert
{
	my $self = shift;
	
	return ($self->{HANDLE}{ALERT});
}

=head2 Storage

Access the C<Storage.pm> methods via 'C<$an->Storage->method>'.

=cut

# Makes my handle to AN::Tools::Storage clearer when using this module to access its methods.
sub Storage
{
	my $self = shift;
	
	return ($self->{HANDLE}{STORAGE});
}


=head1 Private Functions;

These methods generally should never be called from a program using AN::Tools. However, we are not your boss.

=cut

#############################################################################################################
# Private methods                                                                                           #
#############################################################################################################

=head2 _add_environment_path_to_search_directories

This method merges @INC and $ENV{'PATH'} into a single array and uses the result to set C<$an->Storage->search_directories>.

=cut
sub _add_environment_path_to_search_directories
{
	my ($an) = shift;
	
	# If I have $ENV{'PATH'}, use it to add to $an->Storage->search_directories().
	if (($ENV{'PATH'}) && ($ENV{'PATH'} =~ /:/))
	{
		my $new_hash       = [];
		my $last_directory = "";
		foreach my $directory (sort {$a cmp $b} @INC, (split/:/, $ENV{'PATH'}))
		{
			if (($directory eq ".") && ($ENV{PWD}))
			{
				$directory = $ENV{PWD};
			}
			next if $directory eq $last_directory;
			push @{$new_hash}, $directory;
		}
		
		if (@{$new_hash} > 1)
		{
			$an->Storage->search_directories({directories => $new_hash});
		}
	}
	
	return(0);
}

=head2 _set_paths

This sets default paths to many system commands, checking to make sure the binary exists at the path and, if not, try to find it.

=cut
sub _set_paths
{
	my ($an) = shift;
	
	# Executables
	$an->data->{path}{exe} = {
		gethostip		=>	"/usr/bin/gethostip",
		hostname		=>	"/bin/hostname",
	};
	
	# Make sure we actually have each executable
	foreach my $program (sort {$a cmp $b} keys %{$an->data->{path}{exe}})
	{
		if (not -e $an->data->{path}{exe}{$program})
		{
			my $full_path = $an->Storage->find({file => $program});
			if ($full_path)
			{
				$an->data->{path}{exe}{$program} = $full_path;
			}
		}
	}
	
	return(0);
}

=head1 Exit Codes

=head2 C<1>

AN::Tools->new() passed something other than a hash reference.

=head2 C<2>

Failed to find the requested file in C<AN::Tools::Storage->find> and 'fatal' was set.

=head1 Requirements

The following packages are required on EL7.

* C<expect>
* C<httpd>
* C<mailx>
* C<perl-Test-Simple>
* C<policycoreutils-python>
* C<postgresql>
* C<syslinux>

=head1 Recommended Packages

The following packages provide non-critical functionality. 

* C<subscription-manager>

=cut

1;

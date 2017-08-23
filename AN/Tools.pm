package AN::Tools;
# 
# This is the "root" package that manages the sub modules and controls access to their methods.
# 

BEGIN
{
	our $VERSION = "3.0.0";
	# This suppresses the 'could not find ParserDetails.ini in /PerlApp/XML/SAX' warning message in 
	# XML::Simple calls.
	#$ENV{HARNESS_ACTIVE} = 1;
}

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Data::Dumper;
my $THIS_FILE = "Tools.pm";

### Methods;
# data
# environment
# nice_exit
# _add_hash_reference
# _hostname
# _make_hash_reference
# _set_defaults
# _set_paths
# _short_hostname

use utf8;
binmode(STDERR, ':encoding(utf-8)');
binmode(STDOUT, ':encoding(utf-8)');

# I intentionally don't use EXPORT, @ISA and the like because I want my "subclass"es to be accessed in a
# somewhat more OO style. I know some may wish to strike me down for this, but I like the idea of accessing
# methods via their containing module's name. (A La: C<< $an->Module->method >> rather than C<< $an->method >>).
use AN::Tools::Alert;
use AN::Tools::Database;
use AN::Tools::Convert;
use AN::Tools::Get;
use AN::Tools::Log;
use AN::Tools::Storage;
use AN::Tools::System;
use AN::Tools::Template;
use AN::Tools::Words;
use AN::Tools::Validate;

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
			DATABASE			=>	AN::Tools::Database->new(),
			CONVERT				=>	AN::Tools::Convert->new(),
			GET				=>	AN::Tools::Get->new(),
			LOG				=>	AN::Tools::Log->new(),
			STORAGE				=>	AN::Tools::Storage->new(),
			SYSTEM				=>	AN::Tools::System->new(),
			TEMPLATE			=>	AN::Tools::Template->new(),
			WORDS				=>	AN::Tools::Words->new(),
			VALIDATE			=>	AN::Tools::Validate->new(),
		},
		DATA				=>	{},
		ENV_VALUES			=>	{
			ENVIRONMENT			=>	'cli',
		},
		HOST				=>	{
			# This is the host's UUID. It should never be manually set.
			UUID			=>	"",
		},
	};
	
	# Bless you!
	bless $self, $class;
	
	# This isn't needed, but it makes the code below more consistent with and portable to other modules.
	my $an = $self; 
	weaken($an);	# Helps avoid memory leaks. See Scalar::Utils
	
	# Get a handle on the various submodules
	$an->Alert->parent($an);
	$an->Database->parent($an);
	$an->Convert->parent($an);
	$an->Get->parent($an);
	$an->Log->parent($an);
	$an->Storage->parent($an);
	$an->System->parent($an);
	$an->Template->parent($an);
	$an->Words->parent($an);
	$an->Validate->parent($an);
	
	# Set some system paths and system default variables
	$an->_set_paths;
	$an->_set_defaults;
	
	# This will help clean up if we catch a signal.
	$SIG{INT}  = sub { $an->catch_sig({signal => "INT"});  };
	$SIG{TERM} = sub { $an->catch_sig({signal => "TERM"}); };
	
	# This sets the environment this program is running in.
	if ($ENV{SERVER_NAME})
	{
		$an->environment("html");
		
		# There is no PWD environment variable, so we'll use 'DOCUMENT_ROOT' as 'PWD'
		$ENV{PWD} = $ENV{DOCUMENT_ROOT};
	}
	else
	{
		$an->environment("cli");
	}
	
	# Setup my '$an->data' hash right away so that I have a place to store the strings hash.
	$an->data($parameter->{data}) if $parameter->{data};
	
	# Initialize the list of directories to seach.
	$an->Storage->search_directories({initialize => 1});
	
	# I need to read the initial words early.
	$an->Words->read({file  => $an->data->{path}{words}{'an-tools.xml'}});
	
	# If the local './tools.conf' file exists, read it in.
	if (-r "./tools.conf")
	{
		$an->Storage->read_config({file => "./tools.conf"});
	}
	
	# Read in any command line switches.
	$an->Get->switches;
	
	# Set passed parameters if needed.
	if (ref($parameter) eq "HASH")
	{
		### TODO: Calls to allow the user to override defaults...
		# Local parameters...
	}
	elsif($parameter)
	{
		# Um...
		print $THIS_FILE." ".__LINE__."; AN::Tools->new() invoked with an invalid parameter. Expected a hash reference, but got: [$parameter]\n";
		exit(1);
	}
	
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
	weaken($an);
	
	
	# Pick up the passed in delimiter, if any.
	$an->{ENV_VALUES}{ENVIRONMENT} = shift if $_[0];
	
	return ($an->{ENV_VALUES}{ENVIRONMENT});
}

=head2 nice_exit

This is a simple method to exit cleanly, closing database connections and exiting with the set exit code.

Parameters;

=head3 exit_code (optional)

If set, this will be the exit code. The default is to exit with code C<< 0 >>.

=cut
sub nice_exit
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self;
	
	my $exit_code = defined $parameter->{exit_code} ? $parameter->{exit_code} : 0;
	
	# Close database connections (if any).
	$an->Database->disconnect();
	
	exit($exit_code);
}


#############################################################################################################
# Public methods used to access sub modules.                                                                #
#############################################################################################################

=head1 Submodule Access Methods

The methods below are used to access methods of submodules using 'C<< $an->Module->method() >>'.

=cut

=head2 Alert

Access the C<Alert.pm> methods via 'C<< $an->Alert->method >>'.

=cut
sub Alert
{
	my $self = shift;
	
	return ($self->{HANDLE}{ALERT});
}

=head2 Database

Access the C<Database.pm> methods via 'C<< $an->Database->method >>'.

=cut
sub Database
{
	my $self = shift;
	
	return ($self->{HANDLE}{DATABASE});
}

=head2 Convert

Access the C<Convert.pm> methods via 'C<< $an->Convert->method >>'.

=cut
sub Convert
{
	my $self = shift;
	
	return ($self->{HANDLE}{CONVERT});
}

=head2 Get

Access the C<Get.pm> methods via 'C<< $an->Get->method >>'.

=cut
sub Get
{
	my $self = shift;
	
	return ($self->{HANDLE}{GET});
}

=head2 Log

Access the C<Log.pm> methods via 'C<< $an->Log->method >>'.

=cut
sub Log
{
	my $self = shift;
	
	return ($self->{HANDLE}{LOG});
}

=head2 Storage

Access the C<Storage.pm> methods via 'C<< $an->Storage->method >>'.

=cut
sub Storage
{
	my $self = shift;
	
	return ($self->{HANDLE}{STORAGE});
}

=head2 System

Access the C<System.pm> methods via 'C<< $an->System->method >>'.

=cut
sub System
{
	my $self = shift;
	
	return ($self->{HANDLE}{SYSTEM});
}

=head2 Template

Access the C<Template.pm> methods via 'C<< $an->Template->method >>'.

=cut
sub Template
{
	my $self = shift;
	
	return ($self->{HANDLE}{TEMPLATE});
}

=head2 Words

Access the C<Words.pm> methods via 'C<< $an->Words->method >>'.

=cut
sub Words
{
	my $self = shift;
	
	return ($self->{HANDLE}{WORDS});
}

=head2 Validate

Access the C<Validate.pm> methods via 'C<< $an->Validate->method >>'.

=cut
sub Validate
{
	my $self = shift;
	
	return ($self->{HANDLE}{VALIDATE});
}


=head1 Private Functions;

These methods generally should never be called from a program using AN::Tools. However, we are not your boss.

=cut

#############################################################################################################
# Private methods                                                                                           #
#############################################################################################################

=head2 _add_hash_reference

This is a helper to the '$an->_make_hash_reference' method. It is called each time a new string is to be created as a new hash key in the passed hash reference.

NOTE: Contributed by Shaun Fryer and Viktor Pavlenko by way of Toronto Perl Mongers.

=cut
sub _add_hash_reference
{
	my $self  = shift;
	my $href1 = shift;
	my $href2 = shift;
	
	for my $key (keys %$href2)
	{
		if (ref $href1->{$key} eq 'HASH')
		{
			$self->_add_hash_reference( $href1->{$key}, $href2->{$key} );
		}
		else
		{
			$href1->{$key} = $href2->{$key};
		}
	}
}

=head2 _hostname

This returns the (full) hostname for the machine this is running on.

=cut
sub _hostname
{
	my $self = shift;
	my $an   = $self;
	
	my $hostname = "";
	if ($ENV{HOSTNAME})
	{
		# We have an environment variable, so use it.
		$hostname = $ENV{HOSTNAME};
	}
	else
	{
		# The environment variable isn't set. Call 'hostname' on the command line.
		$hostname = $an->System->call({shell_call => $an->data->{path}{exe}{hostname}});
	}
	
	return($hostname);
}

=head2 _get_hash_reference

This is called when we need to parse a double-colon separated string into two or more elements which represent keys in the 'C<< $an->data >>' hash. Once suitably split up, the value is read and returned.

For example;

 $an->data->{foo}{bar} = "baz";
 my $value = $an->_get_hash_reference({ key => "foo::bar" });

The 'C<< $value >>' now contains "C<< baz >>".

NOTE: If the key is not found, 'C<< undef >>' is returned.

Parameters;

=head3 key (required)

This is the key to return the value for. If it is not passed, or if it does not have 'C<< :: >>' in it, 'C<< undef >>' will be returned.

=cut
sub _get_hash_reference
{
	# 'href' is the hash reference I am working on.
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self;
	
	#print "$THIS_FILE ".__LINE__."; hash: [".$an."], key: [$parameter->{key}]\n";
	die "$THIS_FILE ".__LINE__."; The hash key string: [$parameter->{key}] doesn't seem to be valid. It should be a string in the format 'foo::bar::baz'.\n" if $parameter->{key} !~ /::/;
	
	# Split up the keys.
	my $key   = $parameter->{key} ? $parameter->{key} : "";
	my $value = undef;	# We return 'undef' so that the caller can tell the difference between an empty string versus nothing found.
	if ($key =~ /::/)
	{
		my @keys     = split /::/, $key;
		my $last_key = pop @keys;
		
		# Re-order the array.
		my $current_hash_ref = $an->data;
		foreach my $key (@keys)
		{
			$current_hash_ref = $current_hash_ref->{$key};
		}
		
		$value = $current_hash_ref->{$last_key};
	}
	
	return ($value);
}

=head2 _make_hash_reference

This takes a string with double-colon seperators and divides on those double-colons to create a hash reference where each element is a hash key.

NOTE: Contributed by Shaun Fryer and Viktor Pavlenko by way of Toronto Perl Mongers.

=cut
sub _make_hash_reference
{
	my $self       = shift;
	my $href       = shift;
	my $key_string = shift;
	my $value      = shift;
	
	my @keys            = split /::/, $key_string;
	my $last_key        = pop @keys;
	my $_href           = {};
	$_href->{$last_key} = $value;
	while (my $key = pop @keys)
	{
		my $elem      = {};
		$elem->{$key} = $_href;
		$_href        = $elem;
	}
	$self->_add_hash_reference($href, $_href);
}

=head2 _set_defaults

This sets default variable values for the program.

=cut
sub _set_defaults
{
	my ($an) = shift;
	
	$an->data->{sys}      = {
		daemons				=>	{
			restart_firewalld		=>	1,
		},
		database			=>	{
			archive				=>	{
				compress			=>	1,
				count				=>	50000,
				directory			=>	"/usr/local/an-tools/archives/",
				division			=>	6000,
				trigger				=>	100000,
			},
			core_tables			=>	[
									"hosts", 
									"host_variable",
									"alerts",
									"variables",
									"alert_sent",
									"states",
									"updated",
								],
			local_lock_active		=>	0,
			locking_reap_age		=>	300,
			log_transactions		=>	0,
			maximum_batch_size		=>	25000,
		},
		host_type			=>	"",
		use_base2			=>	1,
	};
	$an->data->{defaults} = {
		database	=>	{
			locking		=>	{
				reap_age	=>	300,
			}
		},
		language	=>	{
			# Default language for all output shown to a user.
			output		=>	'en_CA',
		},
		limits		=>	{
			# This is the maximum number of times we're allow to loop when injecting variables 
			# into a string being processed in AN::Tools::Words->string();
			string_loops	=>	1000,
		},
		'log'		=>	{
			db_transactions	=>	0,
			facility	=>	"local0",
			language	=>	"en_CA",
			level		=>	1,
			secure		=>	0,
			server		=>	"",
			tag		=>	"an-tools",
		},
		sql		=>	{
			test_table	=>	"hosts",
		},
		template	=>	{
			html		=>	"alteeve",
		},
	};
	
	return(0);
}

=head2 _set_paths

This sets default paths to many system commands, checking to make sure the binary exists at the path and, if not, try to find it.

=cut
sub _set_paths
{
	my ($an) = shift;
	
	# Executables
	$an->data->{path} = {
			configs			=>	{
				'firewalld.conf'	=>	"/etc/firewalld/firewalld.conf",
				'pg_hba.conf'		=>	"/var/lib/pgsql/data/pg_hba.conf",
				'postgresql.conf'	=>	"/var/lib/pgsql/data/postgresql.conf",
				ssh_config		=>	"/etc/ssh/ssh_config",
				'striker.conf'		=>	"/etc/striker/striker.conf",
			},
			data			=>	{
				passwd			=>	"/etc/passwd",
			},
			directories		=>	{
				backups			=>	"/usr/sbin/striker/backups",
				'cgi-bin'		=>	"/var/www/cgi-bin",
				firewalld_services	=>	"/usr/lib/firewalld/services",
				firewalld_zones		=>	"/etc/firewalld/zones",
				html			=>	"/var/www/html",
				skins			=>	"/var/www/html/skins",
				tools			=>	"/usr/sbin/striker",
				units			=>	"/usr/lib/systemd/system",
			},
			exe			=>	{
				'an-report-memory'	=>	"/usr/sbin/an-report-memory",
				'chmod'			=>	"/usr/bin/chmod",
				'chown'			=>	"/usr/bin/chown",
				cp			=>	"/usr/bin/cp",
				createdb		=>	"/usr/bin/createdb",
				createuser		=>	"/usr/bin/createuser",
				dmidecode		=>	"/usr/sbin/dmidecode",
				echo			=>	"/usr/bin/echo",
				'firewall-cmd'		=>	"/usr/bin/firewall-cmd",
				gethostip		=>	"/usr/bin/gethostip",
				hostname		=>	"/usr/bin/hostname",
				ip			=>	"/usr/sbin/ip",
				'iptables-save'		=>	"/usr/sbin/iptables-save",
				journalctl		=>	"/usr/bin/journalctl",
				logger			=>	"/usr/bin/logger",
				'mkdir'			=>	"/usr/bin/mkdir",
				ping			=>	"/usr/bin/ping",
				pgrep			=>	"/usr/bin/pgrep",
				psql			=>	"/usr/bin/psql",
				'postgresql-setup'	=>	"/usr/bin/postgresql-setup",
				su			=>	"/usr/bin/su",
				systemctl		=>	"/usr/bin/systemctl",
				touch			=>	"/usr/bin/touch",
				timeout			=>	"/usr/bin/timeout",
				uuidgen			=>	"/usr/bin/uuidgen",
			},
			'lock'			=>	{
				database		=>	"/tmp/an-tools.database.lock",
			},
			secure			=>	{
				postgres_pgpass		=>	"/var/lib/pgsql/.pgpass",
			},
			sysfs			=>	{
				network_interfaces	=>	"/sys/class/net",
			},
			sql			=>	{
				'Tools.sql'		=>	"/usr/share/perl5/AN/Tools.sql",
			},
			urls		=>	{
				skins			=>	"/skins",
			},
			words		=>	{
				'an-tools.xml'		=>	"/usr/share/perl5/AN/an-tools.xml",
			},
	};
	
	# Make sure we actually have the requested files.
	foreach my $type (sort {$a cmp $b} keys %{$an->data->{path}})
	{
		# We don't look for urls because they're relative to the domain.
		next if $type eq "urls";
		foreach my $file (sort {$a cmp $b} keys %{$an->data->{path}{$type}})
		{
			if (not -e $an->data->{path}{$type}{$file})
			{
				my $full_path = $an->Storage->find({file => $file});
				if (($full_path) && ($full_path ne "#!not_found!#"))
				{
					$an->data->{path}{$type}{$file} = $full_path;
				}
			}
		}
	};
	
	return(0);
}

=head3 _short_hostname

This returns the short hostname for the machine this is running on. That is to say, the hostname up to the first '.'.

=cut
sub _short_hostname
{
	my $self = shift;
	my $an   =  $self;
	
	my $short_host_name =  $an->_hostname;
	   $short_host_name =~ s/\..*$//;
	
	return($short_host_name);
}

=head1 Exit Codes

=head2 C<1>

AN::Tools->new() passed something other than a hash reference.

=head2 C<2>

Failed to find the requested file in C<< AN::Tools::Storage->find >> and 'fatal' was set.

=head1 Requirements

The following packages are required on EL7.

* C<expect>
* C<httpd>
* C<mailx>
* C<perl-Test-Simple>
* C<policycoreutils-python>
* C<postgresql>
* C<syslinux>
* C<perl-XML-Simple>

=head1 Recommended Packages

The following packages provide non-critical functionality. 

* C<subscription-manager>

=cut


# This catches SIGINT and SIGTERM and fires out an email before shutting down.
sub catch_sig
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self;
	my $signal    = $parameter->{signal} ? $parameter->{signal} : "";
	
	if ($signal)
	{
		print "Process with PID: [$$] exiting on SIG".$signal.".\n";
	}
	$an->nice_exit({code => 255});
}


1;

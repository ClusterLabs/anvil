package AN::Tools::Template;
# 
# This module contains methods used to handle templates.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Template.pm";

### Methods;
# get

=pod

=encoding utf8

=head1 NAME

AN::Tools::Template

Provides all methods related to template handling.

=head1 SYNOPSIS

 use AN::Tools;

 # Template a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Template->X'. 
 # 
 # Example using '()';
 

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		SKIN	=>	{
			HTML	=>	"",
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

=head2 get

This method takes a template file name and a template section name and returns that body template.

 my $body = $an->Template->get({file => "foo.html", name => "bar"}))

=head2 Parameters;

=head3 file (required)

This is the name of the template file containing the template section you want to read.

=head3 name (required)

This is the name of the template section, bounded by 'C<< <!-- start foo --> >>' and 'C<< <!-- end food --> >>' to read in from the file.

=head3 skin (optional)

By default, the 

=cut
sub get
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $file     = defined $parameter->{file} ? $parameter->{file} : "";
	my $name     = defined $parameter->{name} ? $parameter->{name} : "";
	my $skin     = defined $parameter->{skin} ? $parameter->{skin} : "";
	my $template = "";
	my $source   = "";
	
	my $error = 0;
	if (not $file)
	{
		print $THIS_FILE." ".__LINE__."; [ Error ] - No template file passed to Template->get().\n";
		$error = 1;
	}
	else
	{
		# Make sure the file exists.
		if ($skin)
		{
			$source = $an->data->{path}{directories}{skins}."/".$skin."/".$file;
			print $THIS_FILE." ".__LINE__."; [ Debug ] - source: [$source]\n";
		}
		else
		{
			$source = $an->Template->skin."/".$file;
			print $THIS_FILE." ".__LINE__."; [ Debug ] - source: [$source]\n";
		}
		if (not -e $source)
		{
			print $THIS_FILE." ".__LINE__."; [ Error ] - No requested template file: [".$source."] does not exist. Is it missing in the active skin?\n";
			$error = 1;
		}
		elsif (not -r $source)
		{
			my $user_name = getpwuid($<);
			   $user_name = $< if not $user_name;
			print $THIS_FILE." ".__LINE__."; [ Error ] - The requested template file: [".$source."] is not readable. Please check that it is readable by the webserver user: [$user_name]\n";
			$error = 1;
		}
	}
	if (not $name)
	{
		print $THIS_FILE." ".__LINE__."; [ Error ] - No template file passed to Template->get().\n";
		$error = 1;
	}
	
	if (not $error)
	{
		my $in_template = 0;
		my $shell_call  = $source;
		open(my $file_handle, "<$shell_call") or warn $THIS_FILE." ".__LINE__."; Failed to read: [$shell_call], error was: $!\n";
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			if ($line =~ /^<!-- start $name -->/)
			{
				$in_template = 1;
			}
			if ($in_template)
			{
				if ($line =~ /^<!-- end $name -->/)
				{
					$in_template = 0;
					last;
				}
				else
				{
					$template .= $line."\n";
				}
			}
		}
		close $file_handle;
	}
	
	return($template);
}


=head2 skin

This sets or returns the active skin used when rendering web output.

The default skin is set via 'C<< defaults::template::html >>' and it must be the same as the directory name under 'C<< /var/www/html/skins/ >>'.

Get the active skin;

 my $skin = $an->Template->skin;
 
Set the active skin to 'C<< foo >>'.

 $an->Template->skin({set => "foo"});

Disable sensitive log entry recording.

 $an->Log->secure(0);

=cut
sub skin
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set = defined $parameter->{skin} ? $parameter->{skin} : "";
	
	if ($set)
	{
		my $skin_directory = $an->data->{path}{directories}{skins}."/".$set;
		if (-d $skin_directory)
		{
			$self->{SKIN}{HTML} = $skin_directory
		}
		else
		{
			print $THIS_FILE." ".__LINE__."; [ Warning ] - Asked to set the skin: [$set], but the source directory: [$skin_directory] doesn't exist. Ignoring.\n";
		}
	}
	
	if (not $self->{SKIN}{HTML})
	{
		$self->{SKIN}{HTML} = $an->data->{path}{directories}{skins}."/".$an->data->{defaults}{template}{html};
	}
	
	return($self->{SKIN}{HTML});
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

1;

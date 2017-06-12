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
# skin

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

=head3 language (optional)

This is the language (iso code) to use when inserting strings into the template. When not specified, 'C<< Words->language >>' is used.

=head3 name (required)

This is the name of the template section, bounded by 'C<< <!-- start foo --> >>' and 'C<< <!-- end food --> >>' to read in from the file.

=head3 skin (optional)

By default, the active skin is set by 'C<< defaults::template::html >>' ('C<< alteeve >>' by default). This can be checked or set using 'C<< Template->skin >>'.

This parameter allows for an override to use another skin.

=head3 variables (optional)

If there are variables to inject into the template, pass them as a hash referencce using this paramter. 

=cut
sub get
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $language  = defined $parameter->{language}  ? $parameter->{language}  : $an->Words->language;
	my $name      = defined $parameter->{name}      ? $parameter->{name}      : "";
	my $skin      = defined $parameter->{skin}      ? $parameter->{skin}      : "";
	my $variables = defined $parameter->{variables} ? $parameter->{variables} : "";
	my $template  = "";
	my $source    = "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		file     => $file,
		language => $language,
		name     => $name, 
		skin     => $skin, 
	}});
	
	# If the user passed the skin, prepend the skins directory. Otherwise use the active skin.
	if (not $skin)
	{
		$skin = $an->data->{path}{directories}{skins}."/".$an->Template->skin;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { skin => $skin }});
	}
	else
	{
		$skin = $an->data->{path}{directories}{skins}."/".$skin;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { skin => $skin }});
	}
	
	my $error = 0;
	if (not $file)
	{
		# No file passed.
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0024"});
		$error = 1;
	}
	else
	{
		# Make sure the file exists.
		$source = $skin."/".$file;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { source => $source }});
		
		if (not -e $source)
		{
			# Source doesn't exist
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0025", variables => { source => $source }});
			$error = 1;
		}
		elsif (not -r $source)
		{
			# Source isn't readable.
			my $user_name = getpwuid($<);
			   $user_name = $< if not $user_name;
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0026", variables => { source => $source, user_name => $user_name }});
			$error = 1;
		}
	}
	if (not $name)
	{
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0027"});
		$error = 1;
	}
	
	if (not $error)
	{
		my $in_template = 0;
		my $shell_call = $source;
		$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0012", variables => { shell_call => $shell_call }});
		open (my $file_handle, "<", $shell_call) or $an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0015", variables => { shell_call => $shell_call, error => $! }});
		while(<$file_handle>)
		{
			chomp;
			my $line = $_;
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 3, key => "log_0023", variables => { line => $line }});
			if ($line =~ /^<!-- start $name -->/)
			{
				$in_template = 1;
				next;
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
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { source => $source }});
		
		# Now that I have the skin, inject my variables. We'll use Words->string() to do this for us.
		$template = $an->Words->string({
			string    => $template,
			variables => $variables,
		});
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { source => $source }});
	}
	
	return($template);
}

=head2 skin

This sets or returns the active skin used when rendering web output.

The default skin is set via 'C<< defaults::template::html >>' and it must be the same as the directory name under 'C<< /var/www/html/skins/ >>'.

Get the active skin directory;

 my $skin = $an->Template->skin;
 
Set the active skin to 'C<< foo >>'. Only pass the skin name, not the full path.

 $an->Template->skin({set => "foo"});

=cut
sub skin
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set = defined $parameter->{skin} ? $parameter->{skin} : "";
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { file => $set }});
	
	if ($set)
	{
		my $skin_directory = $an->data->{path}{directories}{skins}."/".$set;
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { skin_directory => $skin_directory }});
		if (-d $skin_directory)
		{
			$self->{SKIN}{HTML} = $set;
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 'SKIN::HTML' => $self->{SKIN}{HTML} }});
		}
		else
		{
			$an->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0031", variables => { set => $set, skin_directory => $skin_directory }});
		}
	}
	
	if (not $self->{SKIN}{HTML})
	{
		$self->{SKIN}{HTML} = $an->data->{defaults}{template}{html};
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

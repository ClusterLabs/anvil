package Anvil::Tools::Template;
# 
# This module contains methods used to handle templates.
# 

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Template.pm";

### Methods;
# get
# select_form
# skin

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Template

Provides all methods related to template handling.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Template a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Template->X'. 
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
		weaken($self->{HANDLE}{TOOLS});
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 get

This method takes a template file name and a template section name and returns that body template.

 my $body = $anvil->Template->get({file => "foo.html", name => "bar"}))

=head2 Parameters;

=head3 file (required)

This is the name of the template file containing the template section you want to read.

=head3 language (optional)

This is the language (iso code) to use when inserting strings into the template. When not specified, 'C<< Words->language >>' is used.

=head3 name (required)

This is the name of the template section, bounded by 'C<< <!-- start foo --> >>' and 'C<< <!-- end food --> >>' to read in from the file.

=head3 show_name (optional)

If set the C<< 1 >>, the HTML will have comments shows which parts came from what file. By default, this is disabled.

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
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Template->get()" }});
	
	my $file      = defined $parameter->{file}      ? $parameter->{file}      : "";
	my $language  = defined $parameter->{language}  ? $parameter->{language}  : $anvil->Words->language({debug => $debug});
	my $name      = defined $parameter->{name}      ? $parameter->{name}      : "";
	my $show_name = defined $parameter->{show_name} ? $parameter->{show_name} : 1;
	my $skin      = defined $parameter->{skin}      ? $parameter->{skin}      : $anvil->Template->skin({debug => $debug});
	my $variables = defined $parameter->{variables} ? $parameter->{variables} : "";
	   $skin      = $anvil->data->{path}{directories}{skins}."/".$skin;
	my $template  = "";
	my $source    = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		file      => $file,
		language  => $language,
		name      => $name, 
		skin      => $skin, 
		variables => ref($variables) ? ref($variables) : $variables,
	}});
	if (($anvil->Log->level >= $debug) && (ref($variables) eq "HASH"))
	{
		foreach my $key (sort {$a cmp $b} keys %{$variables})
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "variables->{$key}" => $variables->{$key} }});
		}
	}
	
	# The 'http_headers' template can never show the name
	$show_name = 0 if $name eq "http_headers";
	$show_name = 0 if $name eq "json_headers";
	
	my $error = 0;
	if (not $file)
	{
		# No file passed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0024"});
		$error = 1;
	}
	else
	{
		# Make sure the file exists.
		if ($file =~ /^\//)
		{
			# Fully defined path, don't alter it.
			$source = $file;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source => $source }});
		}
		else
		{
			# Just a file name, prepend the skin path.
			$source = $skin."/".$file;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source => $source }});
		}
		
		if (not -e $source)
		{
			# See if it's a special one in the /sbin/ directory.
			if ($file !~ /^\//)
			{
				$source = "/usr/sbin/".$file;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source => $source }});
			}
			
			# If I still don't have it, we're out.
			if (not -e $source)
			{
				# Source doesn't exist
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0025", variables => { source => $source }});
				$error = 1;
			}
		}
		elsif (not -r $source)
		{
			# Source isn't readable.
			my $user_name = getpwuid($<);
			   $user_name = $< if not $user_name;
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0026", variables => { source => $source, user_name => $user_name }});
			$error = 1;
		}
	}
	if (not $name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0027"});
		$error = 1;
	}
	
	if (not $error)
	{
		my $template_found = 0;
		my $in_template    = 0;
		my $template_file  = $anvil->Storage->read_file({debug => $debug, file => $source});
		foreach my $line (split/\n/, $template_file)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0023", variables => { line => $line }});
			if ($line =~ /^<!-- start $name -->/)
			{
				$in_template = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { in_template => $in_template }});
				if ($show_name)
				{
					$template .= "<!-- start: [$source] -> [$name] -->\n";
				}
				next;
			}
			if ($in_template)
			{
				if ($line =~ /^<!-- end $name -->/)
				{
					$in_template    = 0;
					$template_found = 1;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						in_template    => $in_template,
						template_found => $template_found, 
					}});
					if ($show_name)
					{
						$template .= "<!-- end: [$source] -> [$name] -->\n";
					}
					last;
				}
				else
				{
					$template .= $line."\n";
				}
			}
		}
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { template => $template }});
		
		# Insert variables if I found something.
		# Now that I have the skin, inject my variables. We'll use Words->string() to do this for us.
		if (($template_found) && ($template))
		{
			$template = $anvil->Words->string({
				string    => $template,
				variables => $variables,
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { template => $template }});
		}
		
		# If we failed to read the template, then load an error message.
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			template_found => $template_found, 
			template       => $template,
		}});
		if ((not $template_found) or ($template eq "#!not_found!#"))
		{
			# Woops!
			$template = $anvil->Words->string({key => "error_0029", variables => {
				template => $name,
				file     => $source,
			}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { template => $template }});
		}
		
		# If there was a problem processing the template, it will be '#!error!#'.
		if ($template eq "#!error!#")
		{
			$template = $anvil->Words->string({key => "error_0030", variables => {
				template => $name,
				file     => $source,
			}});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { template => $template }});
	return($template);
}

=head2 select_form

This builds a <select/> form field for use when building forms in templates.

Parameters;

=head3 blank (optional, default C<< 0 >>)

By default, only the options passed are available in the select menu. If this is set to C<< 1 >>, then a blank entry will be inserted to the top of the select list.

=head3 class (optional)

This allows a custom CSS class to be used.

=head3 id (optional)

This is the ID to set. If this is not passed, the C<< name >> is used for the ID.

=head3 name (required)

This is the name of the select box.

=head3 options (required)

This is an array reference of options to put into the select box.

B<NOTE>: The special value C<< subnet >> is allowed. When C<< options >> is C<< subnet >>, a list of valid subnets with CIDR notaion is returned. The common values C<< 255.255.255.0 >>, C<< 255.255.0.0 >> and C<< 255.0.0.0 >> are the first three options and the rest of the useful values (C<< 128.0.0.0 (/1)>> through to C<< 255.255.255.248 (/29) >>) follow. When used, C<< select >> can be set to the dotted-decimal (ie: C<< 255.255.0.0 >>) to select an entry.

Example;

 my $options = ["a", "b", "c"];

If you wanted to have a separate value passed to the form versus what is shown to the user, you can do so by using c<< <value>#!#<string> >>. In the case, C<< <string >> is what the user sees but C<< <value> >> is what is returned if that option is selected.

Example

 my $options = ["MiB#!#Mibibyte", "GiB#!#Gibibyte"];

Would create a list where the user can choose between C<< Mibibyte >> or C<< Gibibyte >>, and the form would return C<< MiB >> or C<< GiB >>, respectively.

=head3 say_blank (optional)

If C<< blank >> is set, this can be a string to show in the place of the empty entry. This entry will use the C<< subtle_text >> CSS class and if it is selected, nothing is returned when the form is submitted.

=head3 selected (optional)

If this is set and if it matches one of the C<< options >> array values, then that option will be selected when the form is loaded.

=head3 sort (optional, default C<< 1 >>)

By default, the options array will be sorted alphabetically. If this is set to C<< 0 >>, then the order the options were entered into the array is used.

=head3 style (optional)

If desired, this can be set to assign a CSS style to the selection box.

=cut
sub select_form
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Template->select_form()" }});
	
	my $name      = defined $parameter->{name}      ? $parameter->{name}      : "";
	my $blank     = defined $parameter->{blank}     ? $parameter->{blank}     : 0;	# Add a blank/null entry?
	my $class     = defined $parameter->{class}     ? $parameter->{class}     : "";
	my $id        = defined $parameter->{id}        ? $parameter->{id}        : $name;
	my $options   = defined $parameter->{options}   ? $parameter->{options}   : "";
	my $say_blank = defined $parameter->{say_blank} ? $parameter->{say_blank} : "";	# An optional, grayed-out string in the place of the "blank" option
	my $selected  = defined $parameter->{selected}  ? $parameter->{selected}  : "";	# Pre-select an option?
	my $sort      = defined $parameter->{'sort'}    ? $parameter->{'sort'}    : 1;	# Sort the entries?
	my $style     = defined $parameter->{style}     ? $parameter->{style}     : "";	# CSS style attribute
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		blank     => $blank, 
		class     => $class, 
		id        => $id,
		name      => $name, 
		options   => $options, 
		say_blank => $say_blank, 
		selected  => $selected, 
		'sort'    => $sort, 
		style     => $style, 
	}});
	
	# Lets start!
	my $select = "<select name=\"$name\" id=\"$id\">\n";
	if (($class) && ($style))
	{
		$select = "<select name=\"$name\" id=\"$id\" class=\"$class\" style=\"$style\">\n";
	}
	elsif ($class)
	{
		$select = "<select name=\"$name\" id=\"$id\" class=\"$class\">\n";
	}
	elsif ($style)
	{
		$select = "<select name=\"$name\" id=\"$id\" style=\"$style\">\n";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
	
	# Insert a blank line.
	if ($blank)
	{
		# If 'say_blank' is a string key, use it.
		my $blank_string = "";
		my $blank_class  = "";
		if ($say_blank)
		{
			$blank_string = $say_blank;
			$blank_class  = "class=\"subtle_text\"";
		}
		if ($selected eq "new")
		{
			$selected =  "";
			$select   .= "<option value=\"\" $blank_class selected>$blank_string</option>\n";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
		}
		else
		{
			$select .= "<option value=\"\" $blank_class>$blank_string</option>\n";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
		}
	}
	
	# If 'options' is 'subnet', set ours;
	if ($options eq "subnet")
	{
=cut
CIDR        Total number    Network             Description:
Notation:   of addresses:   Mask:
--------------------------------------------------------------
/0          4,294,967,296   0.0.0.0             Every Address
/1          2,147,483,648   128.0.0.0           128 /8 nets
/2          1,073,741,824   192.0.0.0           64 /8 nets
/3          536,870,912     224.0.0.0           32 /8 nets
/4          268,435,456     240.0.0.0           16 /8 nets
/5          134,217,728     248.0.0.0           8 /8 nets
/6          67,108,864      252.0.0.0           4 /8 nets
/7          33,554,432      254.0.0.0           2 /8 nets
/8          16,777,214      255.0.0.0           1 /8 net
--------------------------------------------------------------
/9          8,388,608       255.128.0.0         128 /16 nets
/10         4,194,304       255.192.0.0         64 /16 nets
/11         2,097,152       255.224.0.0         32 /16 nets
/12         1,048,576       255.240.0.0         16 /16 nets
/13         524,288         255.248.0.0         8 /16 nets
/14         262,144         255.252.0.0         4 /16 nets
/15         131.072         255.254.0.0         2 /16 nets
/16         65,536          255.255.0.0         1 /16
--------------------------------------------------------------
/17         32,768          255.255.128.0       128 /24 nets
/18         16,384          255.255.192.0       64 /24 nets
/19         8,192           255.255.224.0       32 /24 nets
/20         4,096           255.255.240.0       16 /24 nets
/21         2,048           255.255.248.0       8 /24 nets
/22         1,024           255.255.252.0       4 /24 nets
/23         512             255.255.254.0       2 /24 nets
/24         256             255.255.255.0       1 /24
--------------------------------------------------------------
/25         128             255.255.255.128     Half of a /24
/26         64              255.255.255.192     Fourth of a /24
/27         32              255.255.255.224     Eighth of a /24
/28         16              255.255.255.240     1/16th of a /24
/29         8               255.255.255.248     5 Usable addresses
/30         4               255.255.255.252     1 Usable address
/31         2               255.255.255.254     Unusable
/32         1               255.255.255.255     Single host
--------------------------------------------------------------
=cut
		$sort    = 0;
		$options = [
			"255.255.255.0#!#255.255.255.0   (/24)",
			"255.255.0.0#!#255.255.0.0     (/16)",
			"255.0.0.0#!#255.0.0.0        (/8)",
			"255.255.255.248#!#255.255.255.248 (/29)",
			"255.255.255.240#!#255.255.255.240 (/28)",
			"255.255.255.224#!#255.255.255.224 (/27)",
			"255.255.255.192#!#255.255.255.192 (/26)",
			"255.255.255.128#!#255.255.255.128 (/25)",
			"255.255.254.0#!#255.255.254.0   (/23)",
			"255.255.252.0#!#255.255.252.0   (/22)",
			"255.255.248.0#!#255.255.248.0   (/21)",
			"255.255.240.0#!#255.255.240.0   (/20)",
			"255.255.224.0#!#255.255.224.0   (/19)",
			"255.255.192.0#!#255.255.192.0   (/18)",
			"255.255.128.0#!#255.255.128.0   (/17)",
			"255.254.0.0#!#255.254.0.0     (/15)", 
			"255.252.0.0#!#255.252.0.0     (/14)",
			"255.248.0.0#!#255.248.0.0     (/13)",
			"255.240.0.0#!#255.240.0.0     (/12)",
			"255.224.0.0#!#255.224.0.0     (/11)",
			"255.192.0.0#!#255.192.0.0     (/10)",
			"255.128.0.0#!#255.128.0.0      (/9)",
			"254.0.0.0#!#254.0.0.0        (/7)",
			"252.0.0.0#!#252.0.0.0        (/6)",
			"248.0.0.0#!#248.0.0.0        (/5)",
			"240.0.0.0#!#240.0.0.0        (/4)", 
			"224.0.0.0#!#224.0.0.0        (/3)",
			"192.0.0.0#!#192.0.0.0        (/2)",
			"128.0.0.0#!#128.0.0.0        (/1)",
		];
	}
	
	# TODO: This needs to be smarter... I shouldn't need two loops for sorted/not sorted.
	if ($sort)
	{
		foreach my $entry (sort {$a cmp $b} @{$options})
		{
			next if not $entry;
			if ($entry =~ /^(.*?)#!#(.*)$/)
			{
				my $value       =  $1;
				my $description =  $2;
				   $select      .= "<option value=\"$value\">$description</option>\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
			}
			else
			{
				$select .= "<option value=\"$entry\">$entry</option>\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
			}
		}
	}
	else
	{
		foreach my $entry (@{$options})
		{
			next if not $entry;
			if ($entry =~ /^(.*?)#!#(.*)$/)
			{
				my $value       =  $1;
				my $description =  $2;
				   $select      .= "<option value=\"$value\">$description</option>\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
			}
			else
			{
				$select .= "<option value=\"$entry\">$entry</option>\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
			}
		}
	}
	
	# Was an entry selected?
	if ($selected)
	{
		$select =~ s/value=\"$selected\">/value=\"$selected\" selected>/m;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
	}
	
	# Done!
	$select .= "</select>\n";
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'select' => $select }});
	return($select);
}

=head2 skin

This sets or returns the active skin used when rendering web output.

The default skin is set via 'C<< defaults::template::html >>' and it must be the same as the directory name under 'C<< /var/www/html/skins/ >>'.

Get the active skin directory;

 my $skin = $anvil->Template->skin;
 
Set the active skin to 'C<< foo >>'. Only pass the skin name, not the full path.

 $anvil->Template->skin({set => "foo"});

Parameters;

=head3 fatal (optional)

If passed along with C<< set >>, the skin will be set even if the skin directory does not exit.

=head3 set (optional)

If passed a string, that will become the new active skin. If the skin directory does not exist, however, and C<< fatal >> is not set, the request will be ignored.
 
=cut
sub skin
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Template->skin()" }});
	
	my $fatal = defined $parameter->{fatal} ? $parameter->{fatal} : 1;
	my $set   = defined $parameter->{set}   ? $parameter->{set}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { fatal => $fatal, set => $set }});
	
	if ($set)
	{
		my $skin_directory = $anvil->data->{path}{directories}{skins}."/".$set;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { skin_directory => $skin_directory }});
		if ((-d $skin_directory) or (not $fatal))
		{
			$self->{SKIN}{HTML} = $set;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'SKIN::HTML' => $self->{SKIN}{HTML} }});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0031", variables => { set => $set, skin_directory => $skin_directory }});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'SKIN::HTML' => $self->{SKIN}{HTML} }});
	if (not $self->{SKIN}{HTML})
	{
		$self->{SKIN}{HTML} = $anvil->data->{defaults}{template}{html};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'SKIN::HTML' => $self->{SKIN}{HTML}, 'defaults::template::html' => $anvil->data->{defaults}{template}{html} }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'SKIN::HTML' => $self->{SKIN}{HTML} }});
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

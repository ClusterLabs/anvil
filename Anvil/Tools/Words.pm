package Anvil::Tools::Words;
# 
# This module contains methods used to handle message processing related to support of multi-lingual use.
# 

use strict;
use warnings;
use Data::Dumper;
use XML::Simple qw(:strict);
use Scalar::Util qw(weaken isweak);
use JSON;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Words.pm";

# Setup for UTF-8 mode.
# use utf8;
# $ENV{'PERL_UNICODE'} = 1;

### Methods;
# center_text
# clean_spaces
# escape_xml
# key
# language
# language_list
# load_agent_strings
# parse_banged_string
# read
# shorten_string
# string
# _wrap_string

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Words

Provides all methods related to generating translated strings for users.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Words->X'. 
 # 
 # Example using 'read()';
 my $foo_path = $anvil->Words->read({file => $anvil->data->{path}{words}{'anvil.xml'}});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		WORDS	=>	{
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
		weaken($self->{HANDLE}{TOOLS});
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################


=head2 center_text

This takes a string and an integer and pads the string with spaces on either side until the length is that of the integer. For uneven splits, the smaller number of spaces will be on the left.

Paramters;

=head3 string

This is the string being centered. If not given, and empty string is returned.

B<< Note >>: This can be C<< #!string!x!# >>. If this is passed, the string will be translated before being centered.

=head3 width

This is an integer of how width the centered string should be. 

=cut
sub center_text
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->center_text()" }});
	
	# Pick up the parameters.
	my $string = defined $parameter->{string} ? $parameter->{string} : "";
	my $width  = defined $parameter->{width}  ? $parameter->{width}  : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		string => $string, 
		width  => $width,
	}});
	
	return($string) if $width  eq "";
	return("")      if $string eq "";
	
	### NOTE: If a '#!string!x!#' is passed, the Log->entry method will translate it in the log itself,
	###       so you won't see that string.
	if ($string =~ /#!string!(.*?)!#/)
	{
		$string = $anvil->Words->string({key => $1});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	}
	
	my $current_length = length($string);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { current_length => $current_length }});
	if ($current_length < $width)
	{
		my $difference = $width - $current_length;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { difference => $difference }});
		if ($difference == 1)
		{
			$string .= " ";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
		}
		else
		{
			my $remainder  =  $difference % 2;
			   $difference -= $remainder;
			my $spaces     =  $difference / 2;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				remainder => $remainder,
				spaces    => $spaces, 
			}});
			for (1..$spaces)
			{
				$string = " ".$string." ";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
			}
			if ($remainder)
			{
				$string .= " ";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
			}
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		string   => $string,
		'length' => length($string),
	}});
	return($string);
}


=head2 clean_spaces

This methid takes a string via a 'C<< line >>' parameter and strips leading and trailing spaces, plus compresses multiple spaces into single spaces. It is designed primarily for use by code parsing text coming in from a shell command.

 my $line = $anvil->Words->clean_spaces({ string => $_ });

Parameters;

=head3 string (required)

This sets the string to be cleaned. If it is not passed in, or if the string is empty, then an empty string will be returned without error.

=head3 merge_spaces (optional)

This is a boolean value (0 or 1) that, if set, will merge multiple spaces into a single space. If not set, multiple spaces will be left as is. The default is '1'.

=cut
sub clean_spaces
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->clean_spaces()" }});
	
	# Setup default values
	my $string       = defined $parameter->{string}       ? $parameter->{string}       : "";
	my $merge_spaces = defined $parameter->{merge_spaces} ? $parameter->{merge_spaces} : 1;

	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	$string =~ s/\r//g;
	$string =~ s/\s+/ /g if $merge_spaces;
	
	return($string);
}


=head2 escape_xml

This takes a string and escapes any needed characters so that the string can be used as an attribute value.

Parameters;

=head3 string (optional)

This is the string to escape. If this is empty, and empty string is returned.

=cut
sub escape_xml
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->escape_xml()" }});
	
	# Setup default values
	my $string = defined $parameter->{string} ? $parameter->{string} : "";
	
	$string =~ s/&/&amp;/gs;
	$string =~ s/"/&quot;/gs;
	$string =~ s/'/&apos;/gs;
	$string =~ s/</&lt;/gs;
	$string =~ s/>/&gt;/gs;
	
	return($string);
}


=head2 key

NOTE: This is likely not the method you want. This method does no parsing at all. It returns the raw string from the 'words' file. You probably want C<< $anvil->Words->string() >> if you want to inject variables and get a string back ready to display to the user.

This returns a string by its key name. Optionally, a language and/or a source file can be specified. When no file is specified, loaded files will be search in alphabetical order (including path) and the first match is returned. 

If the requested string is not found, 'C<< #!not_found - <bad_key>!# >>' is returned.

Example to retrieve 'C<< t_0001 >>';

 my $string = $anvil->Words->key({key => 't_0001'});

Same, but specifying the key from Canadian english;

 my $string = $anvil->Words->key({
 	key      => 't_0001',
 	language => 'en_CA',
 });

Same, but specifying a source file.

 my $string = $anvil->Words->key({
 	key      => 't_0001',
 	language => 'en_CA',
 	file     => 'anvil.xml',
 });

Parameters;

=head3 file (optional)

This is the specific file to read the string from. It should generally not be needed as string keys should not be reused. However, if it happens, this is a way to specify which file's version you want.

The file can be the file name, or a path. The specified file is search for by matching the the passed in string against the end of the file path. For example, 'C<< file => 'AN/anvil.xml' >> will match the file 'c<< /usr/share/perl5/AN/anvil.xml >>'.

=head3 key (required)

This is the key to return the string for.

=head3 language (optional)

This is the ISO code for the language you wish to read. For example, 'en_CA' to get the Canadian English string, or 'jp' for the Japanese string.

When no language is passed, 'C<< Words->language >>' is used. 
 
=cut
sub key
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $test      = defined $parameter->{test}  ? $parameter->{test}  : 0;
	
	# Setup default values
	my $key      = defined $parameter->{key}      ? $parameter->{key}      : "";
	my $language = defined $parameter->{language} ? $parameter->{language} : $anvil->Words->language;
	my $file     = defined $parameter->{file}     ? $parameter->{file}     : "";
	my $string   = "#!not_found - ".$key."!#";
	my $error    = 0;
	### NOTE: Don't call Log->entry or Log->variable in here, it'll cause a recursive loop! Use 'test' when needed
	print $THIS_FILE." ".__LINE__."; [ Debug ] - key: [$key], language: [$language], file: [$file]\n" if $test;

	if (not $key)
	{
		print $THIS_FILE." ".__LINE__."; [ Error ] - Anvil::Tools::Words->key()' called without a key name to read.\n" if $test;
		$error = 1;
	}
	if (not $language)
	{
		print $THIS_FILE." ".__LINE__."; [ Error ] - Anvil::Tools::Words->key()' called without a language, and 'defaults::languages::output' is not set.\n" if $test;
		$error = 2;
	}
	
	if (not $error)
	{
		foreach my $this_file (sort {$a cmp $b} keys %{$anvil->data->{words}})
		{
			print $THIS_FILE." ".__LINE__."; [ Debug ] - this_file: [$this_file], file: [$file]\n" if $test;
			# If they've specified a file and this doesn't match, skip it.
			next if (($file) && ($this_file !~ /$file$/));
			if (exists $anvil->data->{words}{$this_file}{language}{$language}{key}{$key}{content})
			{
				$string = $anvil->data->{words}{$this_file}{language}{$language}{key}{$key}{content};
				print $THIS_FILE." ".__LINE__."; [ Debug ] - string: [$string]\n" if $test;
				last;
			}
		}
	}
	
	if ($string eq "#!not_found!#")
	{
		print $THIS_FILE." ".__LINE__."; [ Error ] - Failed to find the string key: [".$key."]!!\n" if $test;
	}
	
	print $THIS_FILE." ".__LINE__."; [ Debug ] - string: [$string]\n" if $test;
	return($string);
}

=head2 language

This sets or returns the output language ISO code.

Get the current active language;

 my $language = $anvil->Words->language;
 
Set the output langauge to Japanese;

 $anvil->Words->language({set => "jp"});

Parameters;

=head3 iso (optional, default is active language)

If C<< long >> is set, this can be used to query the long language name of the ISO code set here. If C<< long >> isn't set, this is ignored.

=head3 long (optional, default '0')

If set to an ISO code, the active default language is changed to the given language. If the long language name is not found, an empty string is returned.

=head3 set (optional)

If set to C<< 1 >>, the long version of the active language is returned. 
 
=cut
sub language
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $iso  = defined $parameter->{iso}  ? $parameter->{iso}  : "";
	my $long = defined $parameter->{long} ? $parameter->{long} : "";
	my $set  = defined $parameter->{set}  ? $parameter->{set}  : "";
	
	if ($set)
	{
		$self->{WORDS}{LANGUAGE} = $set;
	}
	
	if (not $self->{WORDS}{LANGUAGE})
	{
		$self->{WORDS}{LANGUAGE} = $anvil->data->{defaults}{language}{output};
	}
	
	my $return = $self->{WORDS}{LANGUAGE};
	if ($long)
	{
		my $name = "";
		   $iso  = $self->{WORDS}{LANGUAGE} if not $iso;
		foreach my $this_file (sort {$a cmp $b} keys %{$anvil->data->{words}})
		{
			if ((exists $anvil->data->{words}{$this_file}{language}{$iso}{long_name}) && ($anvil->data->{words}{$this_file}{language}{$iso}{long_name}))
			{
				$name = $anvil->data->{words}{$this_file}{language}{$iso}{long_name};
				last;
			}
		}
		return($name);
	}
	
	return($return);
}

=head2 language_list

This creates a hashed list if languages available on the system. The list is stored as C<< sys::languages::<ISO> = <long_name> >>.

=cut
sub language_list
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	foreach my $this_file (sort {$a cmp $b} keys %{$anvil->data->{words}})
	{
		foreach my $iso (sort {$a cmp $b} keys %{$anvil->data->{words}{$this_file}{language}})
		{
			if ((exists $anvil->data->{words}{$this_file}{language}{$iso}{long_name}) && ($anvil->data->{words}{$this_file}{language}{$iso}{long_name}))
			{
				$anvil->data->{sys}{languages}{$iso} = $anvil->data->{words}{$this_file}{language}{$iso}{long_name};
			}
		}
	}
	
	return(0);
}

=head2 load_agent_strings

This loads the strings from all the ScanCore scan agents on this system.

The method takes no parameters.

=cut
sub load_agent_strings
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => 2, list => { 
		"path::directories::scan_agents" => $anvil->data->{path}{directories}{scan_agents},
	}});
	$anvil->Storage->scan_directory({
		debug     => $debug, 
		directory => $anvil->data->{path}{directories}{scan_agents},
		recursive => 1,
	});
	
	# Now loop through the agents I found and call them.
	foreach my $agent_name (sort {$a cmp $b} keys %{$anvil->data->{scancore}{agent}})
	{
		my $agent_words = $anvil->data->{scancore}{agent}{$agent_name}.".xml";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { agent_words => $agent_words }});
		
		if ((-e $agent_words) && (-r $agent_words))
		{
			# Read the words file.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0251", variables => {
				agent_name => $agent_name,
				file       => $agent_words,
			}});
			$anvil->Words->read({
				debug => $debug, 
				file  => $agent_words,
			});
		}
	}
	
	return(0);
}


=head2 parse_banged_string

This takes a string (usually from a DB record) in the format C<< <string_key>[,!!var1!value1!!,!!var2!value2!!,...,!!varN!valueN!! >> and converts it into an actual string.

If there is a problem processing the string, C<< !!error!! >> is returned.

Parameters;

=head3 key_string (required)

This is the double-banged string to process. It can take and process multiple lines at once, so long as each line is in the above format, broken by a simple new line (C<< \n >>).

=cut
sub parse_banged_string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->parse_banged_string()" }});
	
	# Setup default values
	my $out_string = "";
	my $key_string = defined $parameter->{key_string} ? $parameter->{key_string} : 0;
	my $language   = defined $parameter->{language}   ? $parameter->{language}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		key_string => $key_string,
		language   => $language, 
	}});
	
	if (not $language)
	{
		$language = $anvil->Words->language();
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { language => $language }});
	}
	
	# Some variable values will be multi-line strings. We need to replace the new-lines in those 
	# multi-line values into '##br##' so that we can do a proper variable insertion. We can't simply 
	# replace all new-lines, however, as it's normal to have multiple keys, each on their own line.
	my $new_string = "";
	if ($key_string =~ /\n/gs)
	{
		my $in_value   = 0;
		foreach my $line (split/\n/, $key_string)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
			if (($line =~ /^\w.*?,!!/) && ($line !~ /!!$/))
			{
				$in_value   =  1;
				$new_string .= $line."##br##";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					in_value   => $in_value, 
					new_string => $new_string,
				}});
			}
			elsif ($in_value)
			{
				if ($line =~ /!!$/)
				{
					$in_value   =  0;
					$new_string .= $line."\n";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						in_value   => $in_value, 
						new_string => $new_string,
					}});
				}
				else
				{
					$new_string .= $line."##br##";
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						in_value   => $in_value, 
						new_string => $new_string,
					}});
				}
			}
			else
			{
				$new_string .= $line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					in_value   => $in_value, 
					new_string => $new_string,
				}});
			}
		}
		$new_string =~ s/\n$//;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_string => $new_string }});
	}
	else
	{
		# If a string doesn't have a new-line, then copy the key string directly.
		$new_string = $key_string;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { new_string => $new_string }});
	}
	
	# There might be multiple keys, split by newlines.
	foreach my $message (split/\n/, $new_string)
	{
		# If we've looped, there will be data in 'out_string" already so append a newline to separate
		# this key from the previous one.
		if ($out_string)
		{
			# Already processed a line, so prepend a newline.
			$out_string .= "\n";
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { message => $message }});
		if ($message =~ /^(.*?),(.*)$/)
		{
			# This key has insertion variables.
			my $key             = $1;
			my $variable_string = $2;
			my $variables       = {};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				key             => $key,
				variable_string => $variable_string, 
			}});
			my $loop = 0;
			while ($variable_string)
			{
				my $pair = ($variable_string =~ /^(!!.*?!.*?!!).*$/)[0];
				if (not defined $pair)
				{
					# If we're in a web environment, print the HTML header.
					if ($anvil->environment eq "html")
					{
						print "Content-type: text/html; charset=utf-8\n\n";
					}
					print $THIS_FILE." ".__LINE__."; Failed to parse the pair from: [".$variable_string."]\n";
					print $THIS_FILE." ".__LINE__."; Was parsing message: [".$message."] from key string: [".$key_string."]\n";
					$anvil->nice_exit({exit_code => 1});
				}
				my ($variable, $value) = ($pair =~ /^!!(.*?)!(.*?)!!$/);
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					"s1:pair"     => $pair,
					"s2:variable" => $variable,
					"s3:value"    => $value, 
				}});
				
				# We've built things to support unit translation, though it's not implemented
				# (yet). This clears those up.
				if ($value =~ /^name=(.*?):units=(.*)$/)
				{
					my $name = $1;
					my $unit = $2; 
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
						"s1:name" => $name,
						"s2:unit" => $unit, 
					}});
					
					$value = $name;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
				}
				
				# Remove this pair
				$variable_string =~ s/^\Q$pair//;
				$variable_string =~ s/^,//;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_string => $variable_string }});
				
				if (not $variable)
				{
					# Variable missing, nothing we can do with this.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0206", variables => { message => $message }});
				}
				else
				{
					### TODO: If we ever decide to support imperial measurements or other
					###       forms of hyrogliphics, here's where we'll do it.
					# Some variables are encoded with 'value=X:units=Y'. In those cases, 
					if ($value =~ /value=(.*?):units=(.*)$/)
					{
						my $this_value = $1;
						my $this_unit  = $2;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
							this_value => $this_value,
							this_unit  => $this_unit, 
						}});
						
						if    ((uc($this_unit) eq "V") or ($this_unit =~ /Volt/i)) { $value = $this_value." #!string!unit_0033!#"; }
						elsif ((uc($this_unit) eq "W") or ($this_unit =~ /Watt/i)) { $value = $this_value." #!string!unit_0034!#"; }
						elsif  (uc($this_unit) eq "RPM")                           { $value = $this_value." #!string!unit_0035!#"; }
						elsif  (uc($this_unit) eq "C")                             { $value = $this_value." #!string!unit_0036!#"; }
						elsif  (uc($this_unit) eq "F")                             { $value = $this_value." #!string!unit_0037!#"; }
						elsif  ($this_unit eq "%")                                 { $value = $this_value." #!string!unit_0038!#"; }
						elsif ((uc($this_unit) eq "A") or ($this_unit =~ /Amp/i))  { $value = $this_value." #!string!unit_0039!#"; }
						else                                                       { $value = $this_value." ".$this_unit; }
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { value => $value }});
					}
					
					# Record the variable/value pair
					$variables->{$variable} = $value;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "variables->$variable" => $variables->{$variable} }});
				}
				
				$loop++;
				if ($loop > 10000)
				{
					# Stuck in an infinite loop.
					$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0037", variables => { message => $message }});
					return("!!error!!");
				}
			}
			
			# Parse the line now.
			$out_string .= $anvil->Words->string({
				test      => 0, 
				key       => $key, 
				variables => $variables,
				language  => $language, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { out_string => $out_string }});
		}
		else
		{
			# This key is just a key, no variables.
			$out_string .= $anvil->Words->string({
				test     => 0, 
				key      => $message,
				language => $language, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { out_string => $out_string }});
		}
	}
	
	# Switch the breaks back to new-lines
	$out_string =~ s/##br##/\n/gs;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { key_string => $key_string }});
	return($out_string);
}

=head2 read

This reads in a words file containing translated strings used to generated output for the user. 

Example to read 'C<< anvil.xml >>';

 my $words_file = $anvil->data->{path}{words}{'words.xml'};
 my $anvil->Words->read({file => $words_file}) or die "Failed to read: [$words_file]. Does the file exist?\n";

Successful read will return '0'. Non-0 is an error;
0 = OK
1 = Invalid file name or path
2 = File not found
3 = File not readable
4 = File found, failed to read for another reason. The error details will be printed.

NOTE: Read works are stored in 'C<< $anvil->data->{words}{<file_name>}{language}{<language>}{string}{content} >>'. Metadata, like what languages are provided, are stored under 'C<< $anvil->data->{words}{<file_name>}{meta}{...} >>'.

Parameters;

=head3 file (optional, default 'path::words::words.xml')

This is the XML "words" file to read.

NOTE: When reading the default words file, all existing words are cleared from memory to avoid stale strings hanging around.

=cut
sub read
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->read()" }});
	
	# Setup default values
	my $return_code = 0;
	my $file        = defined $parameter->{file} ? $parameter->{file} : $anvil->data->{path}{words}{'words.xml'};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { file => $file }});
	
	if (not $file)
	{
		# NOTE: Log the problem, do not translate.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => "[ Error ] - Words->read()' called without a file name to read."});
		$return_code = 1;
	}
	elsif (not -e $file)
	{
		# NOTE: Log the problem, do not translate.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => "[ Error ] - Words->read()' asked to read: [$file] which was not found."});
		$return_code = 2;
	}
	elsif (not -r $file)
	{
		# NOTE: Log the problem, do not translate.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => "[ Error ] - Words->read()' asked to read: [$file] which was not readable by: [".getpwuid($<)."] (uid/euid: [".$<."])."});
		$return_code = 3;
	}
	else
	{
		# If we've read this file before, delete what we had loaded so that no stale keys remain.
		if (exists $anvil->data->{words}{$file})
		{
			delete $anvil->data->{words}{$file};
		}
			
		# Read the file with XML::Simple
		local $@;
		my $xml = XML::Simple->new();
		eval { $anvil->data->{words}{$file} = $xml->XMLin($file, KeyAttr => { language => 'name', key => 'name' }, ForceArray => [ 'language', 'key' ]) };
		if ($@)
		{
			chomp $@;
			my $error =  "[ Error ] - The was a problem reading: [$file]. The error was:\n";
			   $error .= "===========================================================\n";
			   $error .= $@."\n";
			   $error .= "===========================================================\n";
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", raw => $error});
			$anvil->nice_exit({exit_code => 4});
		}
		else
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0028", variables => { file => $file }});
		}
	}
	
	return($return_code);
}

=head2 shorten_string

This takes a string and shortens it to a specific number of bytes (not characters). The returned string will be equal to or lass than the set byte limit. If the last character is a space, it will be removed as well.

If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 length (required)

This is a real number that the string will be truncated to. If necessary, the resulting string may be equal to, or less than this value.

=head3 secure (optional, default '0')

If this is set to C<< 1 >>, the string will be treated as a password in loggin.

=head3 string (required)

This is the string to truncate. 

=cut
sub shorten_string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->shorten_string()" }});
	
	# Setup default values
	my $short_string = "";
	my $test_string  = "";
	my $length       = defined $parameter->{'length'} ? $parameter->{'length'} : "";
	my $secure       = defined $parameter->{secure}   ? $parameter->{secure}   : 0;
	my $string       = defined $parameter->{string}   ? $parameter->{string}   : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		string   => $secure ? $anvil->Log->is_secure($string) : $string,
		'length' => $length, 
		secure   => $secure, 
	}});
	
	if (not $string)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Words->shorten_string()", parameter => "string" }});
		return('!!error!!');
	}
	if (not $length)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Words->shorten_string()", parameter => "length" }});
		return('!!error!!');
	}
	
	foreach my $character (split//, $string)
	{
		   $test_string .= $character;
		my $test_length =  length(Encode::encode('UTF-8', $test_string));
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			test_string => $secure ? $anvil->Log->is_secure($test_string) : $test_string,
			test_length => $test_length, 
		}});
		if ($test_length <= $length)
		{
			# Within spec.
			$short_string .= $character;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				short_string => $secure ? $anvil->Log->is_secure($short_string) : $short_string,
			}});
		}
		else
		{
			# We've reach the length.
			last;
		}
	}
	$short_string =~ s/\s+$//;
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		short_string => $secure ? $anvil->Log->is_secure($short_string) : $short_string,
	}});
	return($short_string);
}

=head2 string

This method takes a string key and returns the string in the requested language. If no key is passed, the language key in 'defaults::languages::output' is used. A hash reference containing variables can be provided to inject values into a string.

If the requested string is not found, 'C<< #!not_found!# >>' is returned.

Example to retrieve 'C<< t_0001 >>';

 my $string = $anvil->Words->string({key => 't_0001'});

This time, requesting 'C<< t_0002 >>' and passing in two variables. Note that 'C<< t_0002 >>' in Canadian English is;

 Test Out of order: [#!variable!second!#] replace: [#!variable!first!#].

So to request this string in Canadian English is the two variables inserted, we would call:

 my $string = $anvil->Words->string({
 	language  => 'en_CA',
 	key       => 't_0002',
 	variables => {
 		first  => "foo",
 		second => "bar",
 	},
 });

This would return;

 Test Out of order: [bar] replace: [foo].

Normally, there should never be a key collision. However, just in case you find yourself needing to request the string from a specific file, you can do the same call with a file specified.

 my $string = $anvil->Words->string({
 	language  => 'en_CA',
 	file      => 'anvil.xml',
 	key       => 't_0002',
 	variables => {
		first  => "foo",
		second => "bar",
 	},
 });

If the passed in key isn't found (at all, or for the given language or file if specified), then 'C<< #!not_found!# >>' will be returned.

Parameters;

=head3 file (optional)

This is the specific file to read the string from. It should generally not be needed as string keys should not be reused. However, if it happens, this is a way to specify which file's version you want.

=head3 key (optional, required without 'string' set)

This is the key to return the string for.

NOTE: This is ignored when 'C<< string >>' is used.

=head3 language (optional)

This is the ISO code for the language you wish to read the string from. For example, 'en_CA' to get the Canadian English string, or 'jp' for the Japanese string.

When no language is passed, 'C<< defaults::languages::output >>' is used. 

=head3 string (optional, required if no 'key')

If this is passed, it is treated as a raw string that needs variables inserted. When this is used, the 'C<< key >>' parameter is ignored.

=head3 variables (depends)

If the string being requested has one or more 'C<< #!variable!x!# >>' replacement keys, then you must pass a hash reference containing the keys / value pairs where the key matches the replacement string. 

=cut
sub string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $test      = defined $parameter->{test}  ? $parameter->{test}  : 0;
	
	# Setup default values
	my $key       = defined $parameter->{key}       ? $parameter->{key}       : "";
	my $language  =         $parameter->{language}  ? $parameter->{language}  : $anvil->Words->language;
	my $file      =         $parameter->{file}      ? $parameter->{file}      : "";
	my $string    = defined $parameter->{string}    ? $parameter->{string}    : "";
	my $variables = defined $parameter->{variables} ? $parameter->{variables} : "";
	### NOTE: Don't call Log->entry here, or we'll get a recursive loop! Use 'test' to debug.
	print $THIS_FILE." ".__LINE__."; key: [".$key."], language: [$language], file: [$file], string: [$string], variables: [$variables]\n" if $test;
	
	# If we weren't passed a raw string, we'll get the string from our ->key() method, then inject any 
	# variables, if needed. This also handles the initial sanity checks. If we get back '#!not_found!#',
	# we'll exit.
	if (not $string)
	{
		$string = $anvil->Words->key({
			test     => $test, 
			debug    => $debug,
			key      => $key,
			language => $language,
			file     => $file,
		});
		print $THIS_FILE." ".__LINE__."; [ Debug ] - string: [$string]\n" if $test;
	}
	
	print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
	if (($string ne "#!not_found!#") && ($string =~ /#!([^\s]+?)!#/))
	{
		# We've got a string and variables from the caller, so inject them as needed.
		my $loops = 0;
		my $limit = $anvil->data->{defaults}{limits}{string_loops} =~ /^\d+$/ ? $anvil->data->{defaults}{limits}{string_loops} : 1000;
		print $THIS_FILE." ".__LINE__."; limit: [".$limit."]\n" if $test;
		
		# If the user didn't pass in any variables, then we're in trouble.
		if (($string =~ /#!variable!(.+?)!#/s) && ((not $variables) or (ref($variables) ne "HASH")))
		{
			# Escape the variables before the sending the error 
			while ($string =~ /#!variable!(.+?)!#/s)
			{
				$string =~ s/#!variable!(.*?)!#/!!variable!$1!!/s;
				print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
				
				# Die if I've looped too many times.
				$loops++;
				print $THIS_FILE." ".__LINE__."; loops: [".$loops."]\n" if $test;
				if ($loops > $limit)
				{
					# If we're in a web environment, print the HTML header.
					print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
					if ($anvil->environment eq "html")
					{
						print "Content-type: text/html; charset=utf-8\n\n";
					}
					print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language], exiting.\n";
					$anvil->nice_exit({exit_code => 1});
				}
			}
			my $error = "[ Error ] - The method Words->string() was asked to process the string: [".$string."] which has insertion variables, but nothing was passed to the 'variables' parameter.";
			print $THIS_FILE." ".__LINE__."; $error\n" if $test;
			return($error);
		}
		
		# We set the 'loop' variable to '1' and check it at the end of each pass. This is done 
		# because we might inject a string near the end that adds a replacement key to an 
		# otherwise-processed string and we don't want to miss that.
		my $loop = 1;
		while ($loop)
		{
			# First, look for any '#!...!#' keys that we don't recognize and protect them. We'll
			# restore them once we're out of this loop.
			foreach my $check ($string =~ /#!([^\s]+?)!#/)
			{
				print $THIS_FILE." ".__LINE__."; check: [".$check."]\n" if $test;
				if (($check !~ /^data/)    &&
				    ($check !~ /^string/)  &&
				    ($check !~ /^variable/))
				{
					# Simply invert the '#!...!#' to '!#...#!'.
					$string =~ s/#!($check)!#/!#$1#!/g;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
				}
				
				# Die if I've looped too many times.
				$loops++;
				print $THIS_FILE." ".__LINE__."; loops: [".$loops."], limit: [".$limit."]\n" if $test;
				if ($loops > $limit)
				{
					# If we're in a web environment, print the HTML header.
					print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
					if ($anvil->environment eq "html")
					{
						print "Content-type: text/html; charset=utf-8\n\n";
					}
					print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language]. Is there a bad '#!<variable>!<value>!# replacement key? Exiting.\n";
					$anvil->nice_exit({exit_code => 1});
				}
			}
			
			# Now, look for any '#!string!x!#' embedded strings.
			while ($string =~ /#!string!(.+?)!#/)
			{
				my $key         = $1;
				my $this_string = $anvil->Words->key({
					key      => $key,
					language => $language,
					file     => $file,
				});
				print $THIS_FILE." ".__LINE__."; string: [".$string."], key: [".$key."], this_string: [".$this_string."]\n" if $test;
				if ($this_string eq "#!not_found!#")
				{
					# The key was bad...
					$string =~ s/#!string!$key!#/!!e[$key]!!/;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
				}
				else
				{
					$string =~ s/#!string!$key!#/$this_string/;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
				}
				
				# Die if I've looped too many times.
				$loops++;
				print $THIS_FILE." ".__LINE__."; loops: [".$loops."], limit: [".$limit."]\n" if $test;
				if ($loops > $limit)
				{
					# If we're in a web environment, print the HTML header.
					print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
					if ($anvil->environment eq "html")
					{
						print "Content-type: text/html; charset=utf-8\n\n";
					}
					print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language], exiting.\n";
					$anvil->nice_exit({exit_code => 1});
				}
			}
			
			# Now insert variables in the strings.
			while ($string =~ /#!variable!(.+?)!#/s)
			{
				my $variable = $1;
				print $THIS_FILE." ".__LINE__."; string: [".$string."], variable: [".$variable."]\n" if $test;
				
				# Sometimes, #!variable!*!# is used in explaining things to users. So we need
				# to escape it. It will be restored later in '_restore_protected()'.
				if ($variable eq "*")
				{
					$string =~ s/#!variable!\*!#/!#variable!*#!/;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
					next;
				}
				if ($variable eq "")
				{
					$string =~ s/#!variable!\*!#/!#variable!#!/;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
					next;
				}
				
				if (not defined $variables->{$variable})
				{
					# I can't expect there to always be a defined value in the variables
					# array at any given position so if it is blank qw blank the key.
					$string =~ s/#!variable!$variable!#//;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
				}
				else
				{
					my $value = $variables->{$variable};
					chomp $value;
					$string =~ s/#!variable!$variable!#/$value/;
					print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
				}
				
				# Die if I've looped too many times.
				$loops++;
				print $THIS_FILE." ".__LINE__."; loops: [".$loops."], limit: [".$limit."]\n" if $test;
				if ($loops > $limit)
				{
					# If we're in a web environment, print the HTML header.
					print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
					if ($anvil->environment eq "html")
					{
						print "Content-type: text/html; charset=utf-8\n\n";
					}
					print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language], exiting.\n";
					$anvil->nice_exit({exit_code => 1});
				}
			}
			
			# Next, convert '#!data!x!#' to the value in '$anvil->data->{x}'.
			while ($string =~ /#!data!(.+?)!#/)
			{
				my $id = $1;
				print $THIS_FILE." ".__LINE__."; string: [".$string."], id: [".$id."]\n" if $test;
				if ($id =~ /::/)
				{
					# Multi-dimensional hash.
					print $THIS_FILE." ".__LINE__."; multi-dimensional\n" if $test;
					my $value = $anvil->_get_hash_reference({ key => $id });
					print $THIS_FILE." ".__LINE__."; value: [".$value."]\n" if $test;
					if (not defined $value)
					{
						$string =~ s/#!data!$id!#/!!a[$id]!!/;
						print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
					}
					else
					{
						$string =~ s/#!data!$id!#/$value/;
						print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
					}
				}
				else
				{
					# One dimension
					print $THIS_FILE." ".__LINE__."; one dimension\n" if $test;
					if (not defined $anvil->data->{$id})
					{
						$string =~ s/#!data!$id!#/!!b[$id]!!/;
						print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
					}
					else
					{
						my $value  =  $anvil->data->{$id};
						   $string =~ s/#!data!$id!#/$value/;
						print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
					}
				}
				
				# Die if I've looped too many times.
				$loops++;
				print $THIS_FILE." ".__LINE__."; loops: [".$loops."], limit: [".$limit."]\n" if $test;
				if ($loops > $limit)
				{
					# If we're in a web environment, print the HTML header.
					print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
					if ($anvil->environment eq "html")
					{
						print "Content-type: text/html; charset=utf-8\n\n";
					}
					print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language], exiting.\n";
					$anvil->nice_exit({exit_code => 1});
				}
			}
			
			$loops++;
			print $THIS_FILE." ".__LINE__."; loops: [".$loops."], limit: [".$limit."]\n" if $test;
			if ($loops > $limit)
			{
				# If we're in a web environment, print the HTML header.
				print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
				if ($anvil->environment eq "html")
				{
					print "Content-type: text/html; charset=utf-8\n\n";
				}
				print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language], exiting.\n";
				$anvil->nice_exit({exit_code => 1});
			}
			
			# If there are no replacement keys left, exit the loop.
			print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
			if ($string !~ /#!([^\s]+?)!#/)
			{
				$loop = 0;
				print $THIS_FILE." ".__LINE__."; loop: [".$loop."]\n" if $test;
			}
		}
		
		# Restore any protected keys. Reset the loop counter, too.
		$loops = 0;
		$loop  = 1;
		while ($loop)
		{
			$string =~ s/!#([^\s]+?)#!/#!$1!#/g;
			print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
			
			$loops++;
			print $THIS_FILE." ".__LINE__."; loops: [".$loops."], limit: [".$limit."]\n" if $test;
			if ($loops > $limit)
			{
				# If we're in a web environment, print the HTML header.
				print $THIS_FILE." ".__LINE__."; environment: [".$anvil->environment."]\n" if $test;
				if ($anvil->environment eq "html")
				{
					print "Content-type: text/html; charset=utf-8\n\n";
				}
				print "$THIS_FILE ".__LINE__."; Infinite loop detected while processing the string: [".$string."] from the key: [$key] in language: [$language], exiting.\n";
				$anvil->nice_exit({exit_code => 1});
			}
			
			print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
			if ($string !~ /!#[^\s]+?#!/)
			{
				$loop = 0;
				print $THIS_FILE." ".__LINE__."; loop: [".$loop."]\n" if $test;
			}
		}
	}
	
	# In some multi-line strings, the last line will be '\t\t</key>'. We clean this up.
	$string =~ s/\t\t$//;
	print $THIS_FILE." ".__LINE__."; string: [".$string."]\n" if $test;
	
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - string: [$string]\n";
	return($string);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2 _wrap_string

When printing strings to the console, this will wrap the string based on the current output of C<< $anvil->Get->_wrap_to >> (which itself updates C<< sys::terminal::columns >>).

This method looks for a string that starts with spaces or C<< [ foo ] - >> type leader and preserves the spacing when wrapping lines.

This returns the wrapped string as a simple string variable.

Parameters;

=head3 string

This is the string to wrap. If no string is passed in, a blank string will be returned.

=cut
sub _wrap_string
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Words->_wrap_string()" }});
	
	# Get the string to wrap.
	my $string = defined $parameter->{string} ? $parameter->{string} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { string => $string }});
	
	# Update the wrap length
	$anvil->Get->_wrap_to;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::terminal::columns' => $anvil->data->{sys}{terminal}{columns} }});
	
	# If the given line starts with tabs, convert them to 8 spaces.
	my $start_spaces = "";
	if ($string =~ /^(\s+)/)
	{
		$start_spaces = $1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { start_spaces => $start_spaces }});
		
		# Now strip the leading space, convert any tabs to spaces and then bolt the new spacing back 
		# on.
		$string       =~ s/^\s+//;
		$start_spaces =~ s/\t/        /g;
		$string       =  $start_spaces.$string;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			start_spaces => $start_spaces,
			string       => $string, 
		}});
	}
	
	# This will contain the wrapped string
	my $wrapped_string = "";
	if ($string)
	{
		# Create the space prefix for wrapped lines.
		my $prefix_spaces = "";
		if ($string =~ /^\[ (.*?) \] - /)
		{
			my $prefix      = "[ $1 ] - ";
			my $wrap_spaces = length($prefix);
			for (1..$wrap_spaces)
			{
				$prefix_spaces .= " ";
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				prefix        => $prefix,
				wrap_spaces   => $wrap_spaces, 
				prefix_spaces => $prefix_spaces, 
			}});
		}
		elsif ($string =~/^(\s+)/)
		{
			# We have some number of white spaces.
			my $prefix      =  $1;
			my $say_prefix  =  $prefix;
			my $wrap_spaces =  length($say_prefix);
			for (1..$wrap_spaces)
			{
				$prefix_spaces .= " ";
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				prefix        => $prefix,
				wrap_spaces   => $wrap_spaces, 
				say_prefix    => $say_prefix, 
				prefix_spaces => $prefix_spaces, 
			}});
		}
		
		my $this_line =  $prefix_spaces;
		   $string    =~ s/^\s+//;
		foreach my $word (split/ /, $string)
		{
			# Store the line as it was before in case the next word pushes line line past the 
			# 'wrap_to' value. Then append this word and see if we're over the width of the 
			# terminal. If we are, we'll use 'last_line' to append to 'wrapped_string' and use
			# this word to start the next line.
			my $last_line   =  $this_line;
			   $this_line   .= $word;
			my $line_length =  length($this_line); 
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:last_line' => $last_line, 
				's2:word'      => $word,
			}});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:line_length' => $line_length, 
				's2:this_line'   => $this_line, 
			}});
			
			if ((not $last_line) && ($line_length >= $anvil->data->{sys}{terminal}{columns}))
			{
				# This one word goes over the length of the column, so we have to store it as
				# it's own line.
				$wrapped_string .= $word."\n";
				$this_line      =  $prefix_spaces;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					this_line      => $this_line, 
					wrapped_string => $wrapped_string,
				}});
			}
			elsif ($line_length > $anvil->data->{sys}{terminal}{columns})
			{
				# This word appended to the line pushes over the terminal width, so store the
				# 'last_line' and use this word to start the next line.
				$last_line      =~ s/\s+$//;
				$wrapped_string .= $last_line."\n";
				$this_line      =  $prefix_spaces.$word." ";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					this_line      => $this_line, 
					wrapped_string => $wrapped_string,
				}});
			}
			else
			{
				# Just add a space after this word, we're not at the edge yet.
				$this_line .= " ";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_line => $this_line }});
			}
		}
		
		# We're out of the loop, so store the 'last_line' and remove the last space.
		$this_line      =~ s/\s+$//;
		$wrapped_string .= $this_line;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wrapped_string => $wrapped_string }});
	}

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { wrapped_string => $wrapped_string }});
	return($wrapped_string);
}

1;

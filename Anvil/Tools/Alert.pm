package Anvil::Tools::Alert;
# 
# This module contains methods used to handle alerts and errors.
# 

use strict;
use warnings;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Alert.pm";

### Methods;
# check_alert_sent
# check_condition_age
# error
# register

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Alert

Provides all methods related to warnings and alerts.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Alert->X'. Example using 'find';
 my $foo_path = $anvil->Storage->find({file => "foo"});

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


=head2 check_alert_sent

This method is used to see if an event that might last some time has had an alert send already to recipients. 

This is used by programs, usually scancore scan agents, that need to track whether an alert was sent when a sensor dropped below/rose above a set alert threshold. For example, if a sensor alerts at 20°C and clears at 25°C, this will be called when either value is passed. When passing the warning threshold, the alert is registered and sent to the user. Once set, no further warning alerts are sent. When the value passes over the clear threshold, this is checked and if an alert was previously registered, it is removed and an "all clear" message is sent. In this way, multiple alerts will not go out if a sensor floats around the warning threshold and a "cleared" message won't be sent unless a "warning" message was previously sent.

If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 record_locator

This is a record locator, which generally allows a given alert to be tied to a given source. For example, an alert related to a temperature might use C<< an-a01n01.alteeve.com:cpu1_temperature >>.

=head3 set_by (required)

This is a string, usually the name of the program, that set the alert. Usuall this is simple C<< $THIS_FILE >> or C<< $0 >>.

=head3 clear (optional, default '0')

If set to C<< 0 >> (set the alert), C<< 1 >> will be returned if this is the first time we've tried to set this alert. If the alert was set before, C<< 0 >> is returned.

If set to C<< 1 >> (clear the alert), C<< 1 >> will be returned if this is the alert existed and was cleared. If the alert didn't exist (and thus didn't need to be cleared), C<< 0 >> is returned.

=cut
sub check_alert_sent
{
	my $self      = shift;
	my $parameter = shift;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $anvil     = $self->parent;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Alert->check_alert_sent()" }});
	
	my $record_locator = defined $parameter->{record_locator} ? $parameter->{record_locator} : "";
	my $set_by         = defined $parameter->{set_by}         ? $parameter->{set_by}         : "";
	my $clear          = defined $parameter->{clear}          ? $parameter->{clear}          : 0;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		record_locator => $record_locator, 
		set_by         => $set_by, 
		clear          => $clear, 
	}});
	
	# Do we have an record locator?
	if (not $record_locator)
	{
		# Nope
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Alert->check_alert_sent()", parameter => "record_locator" }});
		return("!!error!!");
	}
	
	# Do we know who is setting this??
	if (not $set_by)
	{
		# Nope
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Alert->check_alert_sent()", parameter => "set_by" }});
		return("!!error!!");
	}
	
	# This will get set to '1' if an alert is added or removed.
	my $changed = 0;
	
	my $query = "
SELECT 
    alert_sent_uuid 
FROM 
    alert_sent 
WHERE 
    alert_sent_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)." 
AND 
    alert_set_by         = ".$anvil->Database->quote($set_by)." 
AND 
    alert_record_locator = ".$anvil->Database->quote($record_locator)." 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	# Now, if this is clear = 0, register the alert if it doesn't exist. If it is clear = 1, remove the 
	# alert if it exists.
	my $alert_sent_uuid = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	   $alert_sent_uuid = "" if not defined $alert_sent_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		clear           => $clear,
		alert_sent_uuid => $alert_sent_uuid,
	}});
	if ((not $clear) && (not $alert_sent_uuid))
	{
		### New alert
		# Make sure this host is in the database... It might not be on the very first run of ScanCore
		# before the peer exists (tried to connect to the peer, fails, tries to send an alert, but
		# this host hasn't been added because it is the very first attempt to connect...)
		if (not $anvil->data->{sys}{host_is_in_db})
		{
			my $query = "
SELECT 
    COUNT(*)
FROM 
    hosts 
WHERE 
    host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});

			my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
			
			if (not $count)
			{
				# Too early, we can't set an alert.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0098", variables => {
					clear          => $clear, 
					set_by         => $set_by, 
					record_locator => $record_locator, 
				}});
				return("!!error!!");
			}
			else
			{
				$anvil->data->{sys}{host_is_in_db} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::host_is_in_db' => $anvil->data->{sys}{host_is_in_db} }});
			}
		}
		
		   $changed = 1;
		my $query   = "
INSERT INTO 
    alert_sent 
(
    alert_sent_uuid, 
    alert_sent_host_uuid, 
    alert_set_by, 
    alert_record_locator, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($anvil->Get->uuid).", 
    ".$anvil->Database->quote($anvil->Get->host_uuid).", 
    ".$anvil->Database->quote($set_by).", 
    ".$anvil->Database->quote($record_locator).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			query   => $query,
			changed => $changed, 
		}});
		$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	}
	elsif (($clear) && ($alert_sent_uuid))
	{
		# Alert previously existed, clear it.
		   $changed = 1;
		my $query   = "
DELETE FROM 
    alert_sent 
WHERE 
    alert_sent_uuid = ".$anvil->Database->quote($alert_sent_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			query   => $query,
			changed => $changed, 
		}});
		$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { changed => $changed }});
	return($changed);
}


=head2 check_condition_age

This checks to see how long ago a given condition (variable, really) has been set. This is generally used when a program, often a scan agent, wants to wait to see if a given state persists before sending an alert and/or taking an action.

A common example is seeing how long power has been lost, if a lost sensor is going to return, etc.

The age of the condition is returned, in seconds. If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 clear (optional)

When set to C<< 1 >>, if the condition exists, it is cleared. If the condition does not exist, nothing happens.

=head3 name (required)

This is the name of the condition being set. It's a free-form string, but generally in a format like C<< <scan_agent_name>::<condition_name> >>.

=head3 host_uuid (optional)

If a condition is host-specific, this can be set to the caller's C<< host_uuid >>. Generally this is needed, save for conditions related to hosted servers that are not host-bound.

=cut
sub check_condition_age
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Database->check_condition_age()" }});
	
	my $clear     = defined $parameter->{clear}     ? $parameter->{clear}     : 0;
	my $name      = defined $parameter->{name}      ? $parameter->{name}      : "";
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "NULL";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		clear     => $clear, 
		name      => $name, 
		host_uuid => $host_uuid, 
	}});

	if (not $name)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Database->check_condition_age()", parameter => "name" }});
		return("!!error!!");
	}
	
	my $age          = 0;
	my $source_table = $host_uuid ? "hosts" : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { source_table => $source_table }});
	
	# See if this variable has been set yet.
	my ($variable_value, $variable_uuid, $epoch_modified_date, $modified_date) = $anvil->Database->read_variable({
		variable_name         => $name, 
		variable_source_table => $source_table, 
		variable_source_uuid  => $host_uuid,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		variable_value      => $variable_value, 
		variable_uuid       => $variable_uuid, 
		epoch_modified_date => $epoch_modified_date, 
		modified_date       => $modified_date, 
	}});
	if ($variable_uuid)
	{
		# Are we clearing?
		if ($clear)
		{
			# Yup
			$variable_uuid = $anvil->Database->insert_or_update_variables({
				debug             => $debug,
				variable_uuid     => $variable_uuid,
				variable_value    => "clear",
				update_value_only => 1,
			});
		}
		
		# if the value was 'clear', change it to 'set'.
		if ($variable_value eq "clear")
		{
			# Set it.
			$variable_uuid = $anvil->Database->insert_or_update_variables({
				debug             => $debug,
				variable_uuid     => $variable_uuid,
				variable_value    => "set",
				update_value_only => 1,
			});
		}
		else
		{
			# How old is it?
			$age = time - $epoch_modified_date;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { age => $age }});
			return($age);
		}
	}
	elsif (not $clear)
	{
		# New, set it.
		my $variable_uuid = $anvil->Database->insert_or_update_variables({
			debug                 => $debug, 
			variable_name         => $name, 
			variable_value        => "set",
			variable_default      => "set", 
			variable_description  => "striker_0278", 
			variable_section      => "conditions", 
			variable_source_uuid  => $host_uuid, 
			variable_source_table => $source_table, 
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
	}
	
	return($age);
}


=head2 register

This registers an alert to be sent later by C<< Email->send_alerts >>. 

The C<< alert_uuid >> is returned on success. If anything goes wrong, C<< !!error!! >> is returned. If there are no recipients who would receive the alert, it will not be recorded and an empty string is returned.

Parameters;

=head3 alert_level (required)

This assigns an severity level to the alert. Any recipient listening to this level or higher will receive this alert. This value can be set as a numeric value or as a string.

=head4 1 / critical

Alerts at this level will go to all recipients, except for those ignoring the source system entirely.

This is reserved for alerts that could lead to imminent service interruption or unexpected loss of redundancy.

Alerts at this level should trigger alarm systems for all administrators as well as management who may be impacted by service interruptions.

=head4 2 / warning

This is used for alerts that require attention from administrators. Examples include intentional loss of redundancy caused by load shedding, hardware in pre-failure, loss of input power, temperature anomalies, etc.

Alerts at this level should trigger alarm systems for administrative staff.

=head4 3 / notice

This is used for alerts that are generally safe to ignore, but might provide early warnings of developing issues or insight into system behaviour. 

Alerts at this level should not trigger alarm systems. Periodic review is sufficient.

=head4 4 / info

This is used for alerts that are almost always safe to ignore, but may be useful in testing and debugging. 

=head3 clear_alert (optional, default '0')

If set, this indicate that the alert has returned to an OK state. Alert level is still honoured for notification target delivery decisions, but some internal values are adjusted.

=head3 message (required)

This is the message body of the alert. It is expected to be in the format C<< <string_key> >>. If variables are to be injected into the C<< string_key >>, a comma-separated list in the format C<< !!variable_name1!value1!![,!!variable_nameN!valueN!!] >> is used.

Example with a message alone; C<< foo_0001 >>.
Example with two variables; C<< foo_0002,!!bar!abc!!,!!baz!123!! >>.

B<< Note >>: See C<< variables >> for an alternate method of passing variables

=head3 set_by (required)

This is the name of the program that registered this alert. Usually this is simply the caller's C<< $THIS_FILE >> or C<< $0 >> variable.

=head3 show_header (optional, default '1')

When set to C<< 0 >>, only the alert message body is shown, and the title is omitted. This can be useful when a set of alerts are sorted under a common title.

=head3 sort_position (optional, default '9999')

This is used to keep a set of alerts in a certain order when converted to an message body. By default, all alerts have a default value of '9999', so they will be sorted using their severity level, and then the time they were entered into the system. If this is set to a number lower than this, then the value here will sort/prioritize messages over the severity/time values. If two or more alerts have the same sort position, then severity and then time stamps will be used.

In brief; alert messages are sorted in this order;

1. C<< sort_position >>
2. c<< alert_level >>
3. C<< timestamp >>

NOTE: All C<< sort_position >> values are automatically zero-padded (ie: C<< 12 >> -> C<< 0012 >>) to ensure accurate sorting. If you plan to use values greater than C<< 9999 >>, be sure to manually zero-pad your numbers. (Or, better, find a way to make shorter alerts... ).

NOTE: The timestamp is generally set for a given program or agent run (set when connecting to the database), NOT by the real time of the database insert. For this reason, relying on the timestamp alone will not generally give the desired results, and why C<< sort_position >> exists.

=head3 title (optional)

NOTE: If not set and C<< show_header >> is set to C<< 1 >>, a generic title will be added based on the C<< alert_level >> and if C<< clear_alert >> is set or not.

This is the title of the alert. It is expected to be in the format C<< <string_key> >>. If variables are to be injected into the C<< string_key >>, a comma-separated list in the format C<< !!variable_name1!value1!![,!!variable_nameN!valueN!!] >> is used.

Example with a message alone; C<< foo_0001 >>.
Example with two variables; C<< foo_0002,!!bar!abc!!,!!baz!123!! >>.

=head3 variables (optional)

This can be set as a hash reference containing key / variable pairs to inject into the message key. the C<< variable => value >> pairs will be appended to the C<< message >> key automatically. This is meant to simplify when an alert is also being longed, or when a large number of variables are being injected into the string.

=cut
sub register
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Alert->register()" }});
	
	my $alert_level   = defined $parameter->{alert_level}   ? $parameter->{alert_level}   : 0;
	my $clear_alert   = defined $parameter->{clear_alert}   ? $parameter->{clear_alert}   : 0;
	my $message       = defined $parameter->{message}       ? $parameter->{message}       : "";
	my $set_by        = defined $parameter->{set_by}        ? $parameter->{set_by}        : "";
	my $show_header   = defined $parameter->{show_header}   ? $parameter->{show_header}   : 1;
	my $sort_position = defined $parameter->{sort_position} ? $parameter->{sort_position} : 9999;
	my $title         = defined $parameter->{title}         ? $parameter->{title}         : "";
	my $variables     = defined $parameter->{variables}     ? $parameter->{variables}     : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		show_header   => $show_header,
		clear_alert   => $clear_alert, 
		alert_level   => $alert_level, 
		message       => $message, 
		set_by        => $set_by,
		sort_position => $sort_position, 
		title         => $title, 
		variables     => ref($variables), 
	}});
	
	# Missing parameters?
	if (not $alert_level)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Alert->register()", parameter => "alert_level" }});
		return("!!error!!");
	}
	if (not $set_by)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Alert->register()", parameter => "set_by" }});
		return("!!error!!");
	}
	if (not $message)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Alert->register()", parameter => "message" }});
		return("!!error!!");
	}
	
	if (ref($variables) eq "HASH")
	{
		foreach my $variable (sort {$a cmp $b} keys %{$variables})
		{
			my $value   =  defined $variables->{$variable} ? $variables->{$variable} : "undefined:".$variable;
			   $message .= ",!!".$variable."!".$value."!!";
		}
	}
	
	# If the alert level was a string, convert it to the numerical version. Also check that we've got a 
	# sane alert level at all.
	if (lc($alert_level) eq "critical")
	{
		$alert_level = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_level => $alert_level }});
	}
	elsif (lc($alert_level) eq "warning")
	{
		$alert_level = 2;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_level => $alert_level }});
	}
	elsif (lc($alert_level) eq "notice")
	{
		$alert_level = 3;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_level => $alert_level }});
	}
	elsif (lc($alert_level) eq "info")
	{
		$alert_level = 4;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_level => $alert_level }});
	}
	elsif (($alert_level =~ /\D/) or ($alert_level < 1) or ($alert_level > 4))
	{
		# Invalid
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0142", variables => { alert_level => $alert_level }});
		return("!!error!!");
	}
	
	# Do we need to generate a header?
	if (($show_header) && (not $title))
	{
		# Set it based on the alert_level.
		if    ($alert_level == 1) { $title = $clear_alert ? "title_0005" : "title_0001"; } # Critical (or Critical Cleared)
		elsif ($alert_level == 2) { $title = $clear_alert ? "title_0006" : "title_0002"; } # Warning (or Warning Cleared)
		elsif ($alert_level == 3) { $title = $clear_alert ? "title_0007" : "title_0003"; } # Notice (or Notice Cleared)
		elsif ($alert_level == 4) { $title = $clear_alert ? "title_0008" : "title_0004"; } # Info (or Info Cleared)
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { title => $title }});
	}
	
	# zero-pad sort numbers so that they sort properly.
	$sort_position = sprintf("%04d", $sort_position);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sort_position => $sort_position }});
	
	# Before we actually record the alert, see if there are any recipients listening. For example, very
	# rarely is anyone listening to alert level 4 (info), so skipping recording it saves unnecessary 
	# growth of the history.alerts table.
	my $proceed = 0;
	$anvil->Database->get_recipients({debug => $debug});
	foreach my $recipient_uuid (keys %{$anvil->data->{recipients}{recipient_uuid}})
	{
		my $recipient_email = $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{recipient_email};
		my $recipient_level = $anvil->data->{recipients}{recipient_uuid}{$recipient_uuid}{level_on_host};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:recipient_uuid'  => $recipient_uuid,
			's2:recipient_level' => $recipient_level, 
			's3:recipient_email' => $recipient_email,
		}});
		
		if ($recipient_level >= $alert_level)
		{
			# Someone wants to hear about this.
			$proceed = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { proceed => $proceed }});
			last;
		}
	}
	
	if (not $proceed)
	{
		# No one is listening, ignore.
		return("");
	}
	
	# Always INSERT. ScanCore removes them as they're acted on (copy is left in history.alerts).
	my $alert_uuid = $anvil->Get->uuid();
	my $query = "
INSERT INTO 
    alerts
(
    alert_uuid, 
    alert_host_uuid, 
    alert_set_by, 
    alert_level, 
    alert_title, 
    alert_message, 
    alert_sort_position, 
    alert_show_header, 
    modified_date
) VALUES (
    ".$anvil->Database->quote($alert_uuid).", 
    ".$anvil->Database->quote($anvil->Get->host_uuid()).", 
    ".$anvil->Database->quote($set_by).", 
    ".$anvil->Database->quote($alert_level).", 
    ".$anvil->Database->quote($title).", 
    ".$anvil->Database->quote($message).", 
    ".$anvil->Database->quote($sort_position).", 
    ".$anvil->Database->quote($show_header).", 
    ".$anvil->Database->quote($anvil->Database->refresh_timestamp)."
);
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	
	### TODO: Add an optional 'send_now' parameter to causes us to call 'Email->send_alerts'
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { alert_uuid => $alert_uuid }});
	return($alert_uuid);
}


### TODO: Write this, maybe? Or remove it and ->warning()?
=head2 error

=cut

# Later, this will support all the translation and logging methods. For now, just print the error and exit.
sub error
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Alert->error()" }});
	
	
}

1;

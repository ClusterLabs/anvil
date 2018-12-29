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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################


=head2 check_alert_sent

This is used by scan agents that need to track whether an alert was sent when a sensor dropped below/rose above a set alert threshold. For example, if a sensor alerts at 20°C and clears at 25°C, this will be called when either value is passed. When passing the warning threshold, the alert is registered and sent to the user. Once set, no further warning alerts are sent. When the value passes over the clear threshold, this is checked and if an alert was previously registered, it is removed and an "all clear" message is sent. In this way, multiple alerts will not go out if a sensor floats around the warning threshold and a "cleared" message won't be sent unless a "warning" message was previously sent.

If there is a problem, C<< !!error!! >> is returned.

Parameters;

=head3 modified_date (optional)

By default, this is set to C<< sys::database::timestamp >>. If you want to force a different timestamp, you can do so with this parameter.

=head3 name (required)

This is the name of the alert. So for an alert related to a critically high temperature, this might get set to C<< temperature_high_critical >>. It is meant to compliment the C<< record_locator >> parameter.

=head3 record_locator

This is a record locator, which generally allows a given alert to be tied to a given source. For example, an alert related to a temperature might use C<< an-a01n01.alteeve.com:cpu1_temperature >>.

=head3 set_by (required)

This is a string, usually the name of the program, that set the alert. Usuall this is simple C<< $THIS_FILE >> or C<< $0 >>.

=head3 type (required)

This is set to C<< set >> or C<< clear >>.

If set to C<< set >>, C<< 1 >> will be returned if this is the first time we've tried to set this alert. If the alert was set before, C<< 0 >> is returned.

If set to C<< clear >>, C<< 1 >> will be returned if this is the alert existed and was cleared. If the alert didn't exist (and thus didn't need to be cleared), C<< 0 >> is returned.

=cut
sub check_alert_sent
{
	my $self      = shift;
	my $parameter = shift;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $anvil     = $self->parent;
	
	my $modified_date  = defined $parameter->{modified_date}  ? $parameter->{modified_date}  : $anvil->data->{sys}{database}{timestamp};
	my $name           = defined $parameter->{name}           ? $parameter->{name}           : "";
	my $record_locator = defined $parameter->{record_locator} ? $parameter->{record_locator} : "";
	my $set_by         = defined $parameter->{set_by}         ? $parameter->{set_by}         : "";
	my $type           = defined $parameter->{type}           ? $parameter->{type}           : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		modified_date  => $modified_date, 
		name           => $name, 
		record_locator => $record_locator, 
		set_by         => $set_by, 
		type           => $type, 
	}});
	
	# Do we have a timestamp?
	if (not $modified_date)
	{
		# Nope
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0093"});
		return("!!error!!");
	}
	
	# Do we have an alert name?
	if (not $name)
	{
		# Nope
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Alert->check_alert_sent()", parameter => "name" }});
		return("!!error!!");
	}
	
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
	
	# Are we setting or clearing?
	if (not $type)
	{
		# Neither...
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0097"});
		return("!!error!!");
	}
	
	# This will get set to '1' if an alert is added or removed.
	my $set = 0;
	
	my $query = "
SELECT 
    alert_sent_uuid 
FROM 
    alert_sent 
WHERE 
    alert_sent_host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid})." 
AND 
    alert_set_by         = ".$anvil->data->{sys}{database}{use_handle}->quote($set_by)." 
AND 
    alert_record_locator = ".$anvil->data->{sys}{database}{use_handle}->quote($record_locator)." 
AND 
    alert_name           = ".$anvil->data->{sys}{database}{use_handle}->quote($name)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	# Now, if this is type=set, register the alert if it doesn't exist. If it is type=clear, remove the 
	# alert if it exists.
	my $alert_sent_uuid = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
	   $alert_sent_uuid = "" if not defined $alert_sent_uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		type            => $type,
		alert_sent_uuid => $alert_sent_uuid,
	}});
	if (($type eq "set") && (not $alert_sent_uuid))
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
    host_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid})."
;";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});

			my $count = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__})->[0]->[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { count => $count }});
			
			if (not $count)
			{
				# Too early, we can't set an alert.
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "alert", key => "log_0098", variables => {
					type           => $type, 
					set_by         => $set_by, 
					record_locator => $record_locator, 
					name           => $name, 
					modified_date  => $modified_date,
				}});
				return("!!error!!");
			}
			else
			{
				$anvil->data->{sys}{host_is_in_db} = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 'sys::host_is_in_db' => $anvil->data->{sys}{host_is_in_db} }});
			}
		}
		
		   $set   = 1;
		my $query = "
INSERT INTO 
    alert_sent 
(
    alert_sent_uuid, 
    alert_sent_host_uuid, 
    alert_set_by, 
    alert_record_locator, 
    alert_name, 
    modified_date
) VALUES (
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->Get->uuid).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid}).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($set_by).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($record_locator).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($name).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			query => $query,
			set   => $set, 
		}});
		$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	}
	elsif (($type eq "clear") && ($alert_sent_uuid))
	{
		# Alert previously existed, clear it.
		   $set   = 1;
		my $query = "
DELETE FROM 
    alert_sent 
WHERE 
    alert_sent_uuid = ".$anvil->data->{sys}{database}{use_handle}->quote($alert_sent_uuid)." 
;";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			query => $query,
			set   => $set, 
		}});
		$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { set => $set }});
	return($set);
}

=head2 register

This registers an alert to be sent later.

The C<< alert_uuid >> is returned on success. If anything goes wrong, C<< !!error!! >> will be returned.

Parameters;

=head3 alert_level (required)

This assigns an severity level to the alert. Any recipient listening to this level or higher will receive this alert.

=head4 1 (critical)

Alerts at this level will go to all recipients, except for those ignoring the source system entirely.

This is reserved for alerts that could lead to imminent service interruption or unexpected loss of redundancy.

Alerts at this level should trigger alarm systems for all administrators as well as management who may be impacted by service interruptions.

=head4 2 (warning)

This is used for alerts that require attention from administrators. Examples include intentional loss of redundancy caused by load shedding, hardware in pre-failure, loss of input power, temperature anomalies, etc.

Alerts at this level should trigger alarm systems for administrative staff.

=head4 3 (notice)

This is used for alerts that are generally safe to ignore, but might provide early warnings of developing issues or insight into system behaviour. 

Alerts at this level should not trigger alarm systems. Periodic review is sufficient.

=head4 4 (info)

This is used for alerts that are almost always safe to ignore, but may be useful in testing and debugging. 

=head3 clear_alert (optional, default '0')

If set, this indicate that the alert has returned to an OK state. Alert level is still honoured for notification target delivery decisions, but some internal values are adjusted.

=head3 message (required)

This is the message body of the alert. It is expected to be in the format C<< <string_key> >>. If variables are to be injected into the C<< string_key >>, a comma-separated list in the format C<< !!variable_name1!value1!![,!!variable_nameN!valueN!!] >> is used.

Example with a message alone; C<< foo_0001 >>.
Example with two variables; C<< foo_0002,!!bar!abc!!,!!baz!123!! >>.

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

NOTE: The timestamp is generally set for a given program or agent run (set when connecting to the database), NOT by the real time of the database insert. For this reason, relying on the timestamp alone will not generally give the desired results, and why C<< sort_position >> exists.

=head3 title (optional)

NOTE: This is required if C<< show_header >> is set! 

This is the title of the alert. It is expected to be in the format C<< <string_key> >>. If variables are to be injected into the C<< string_key >>, a comma-separated list in the format C<< !!variable_name1!value1!![,!!variable_nameN!valueN!!] >> is used.

Example with a message alone; C<< foo_0001 >>.
Example with two variables; C<< foo_0002,!!bar!abc!!,!!baz!123!! >>.

=cut
sub register
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $alert_level   = defined $parameter->{alert_level}   ? $parameter->{alert_level}   : 0;
	my $clear_alert   = defined $parameter->{clear_alert}   ? $parameter->{clear_alert}   : 0;
	my $message       = defined $parameter->{message}       ? $parameter->{message}       : "";
	my $set_by        = defined $parameter->{set_by}        ? $parameter->{set_by}        : "";
	my $show_header   = defined $parameter->{show_header}   ? $parameter->{show_header}   : 1;
	my $sort_position = defined $parameter->{sort_position} ? $parameter->{sort_position} : 9999;
	my $title         = defined $parameter->{title}         ? $parameter->{title}         : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		show_header   => $show_header,
		clear_alert   => $clear_alert, 
		alert_level   => $alert_level, 
		message       => $message, 
		set_by        => $set_by,
		sort_position => $sort_position, 
		title         => $title, 
	}});
	
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
	if (($show_header) && (not $title))
	{
		# Set it based on the alert_level.
		if    ($alert_level eq "1") { $title = $clear_alert ? "alert_title_0005" : "alert_title_0001"; } # Critical (or Critical Cleared)
		elsif ($alert_level eq "2") { $title = $clear_alert ? "alert_title_0006" : "alert_title_0002"; } # Warning (or Warning Cleared)
		elsif ($alert_level eq "3") { $title = $clear_alert ? "alert_title_0007" : "alert_title_0003"; } # Notice (or Notice Cleared)
		elsif ($alert_level eq "4") { $title = $clear_alert ? "alert_title_0008" : "alert_title_0004"; } # Info (or Info Cleared)
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { title => $title }});
	}
	
	# zero-pad sort numbers so that they sort properly.
	$sort_position = sprintf("%04d", $sort_position);
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { sort_position => $sort_position }});
	
	
	
	
	
=cut
	# In most cases, no one is listening to 'debug' or 'info' level alerts. If that is the case here, 
	# don't record the alert because it can cause the history.alerts table to grow needlessly. So find
	# the lowest level log level actually being listened to and simply skip anything lower than that.
	# 5 == debug
	# 1 == critical
	my $lowest_log_level = 5;
	foreach my $integer (sort {$a cmp $b} keys %{$anvil->data->{alerts}{recipient}})
	{
		# We want to know the alert level, regardless of whether the recipient is an email of file 
		# target.
		my $this_level;
		if ($anvil->data->{alerts}{recipient}{$integer}{email})
		{
			# Email recipient
			$this_level = ($anvil->data->{alerts}{recipient}{$integer}{email} =~ /level="(.*?)"/)[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_level => $this_level }});
		}
		elsif ($anvil->data->{alerts}{recipient}{$integer}{file})
		{
			# File target
			$this_level = ($anvil->data->{alerts}{recipient}{$integer}{file} =~ /level="(.*?)"/)[0];
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_level => $this_level }});
		}
		
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { this_level => $this_level }});
		if ($this_level)
		{
			$this_level = $anvil->Alert->convert_level_name_to_number({level => $this_level});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				this_level       => $this_level,
				lowest_log_level => $lowest_log_level,
			}});
			if ($this_level < $lowest_log_level)
			{
				$lowest_log_level = $this_level;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { lowest_log_level => $lowest_log_level }});
			}
		}
	}
	
	# Now get the numeric value of this alert and return if it is higher.
	my $this_level = $anvil->Alert->convert_level_name_to_number({level => $level});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		alert_level      => $level,
		this_level       => $this_level,
		lowest_log_level => $lowest_log_level,
	}});
	if ($this_level > $lowest_log_level)
	{
		# Return.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0102", variables => { message => $message }});
		return(0);
	}
	
	# Always INSERT. ScanCore removes them as they're acted on (copy is left in history.alerts).
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
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->Get->uuid()).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{host_uuid}).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($set_by).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($level).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($title).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($message).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($sort_position).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($show_header).", 
    ".$anvil->data->{sys}{database}{use_handle}->quote($anvil->data->{sys}{database}{timestamp})."
);
";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	$anvil->Database->write({query => $query, source => $THIS_FILE, line => __LINE__});
=cut
	
	return(0);
}

=head2 error

=cut

# Later, this will support all the translation and logging methods. For now, just print the error and exit.
sub error
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
}

1;

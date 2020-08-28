package Anvil::Tools::Email;
# 
# This module contains methods used to manage the local postfix server and handle and dispatch email via 
# mailx.
# 

### TODO: By default, a recipient receives all alerts at their default level. Later, we'll add an 
###       override table to allow a user to ignore a given striker or Anvil! node / dr host set. So
###       creating this list is no longer needed.

use strict;
use warnings;
use Data::Dumper;
use JSON;
use Scalar::Util qw(weaken isweak);
use Text::Diff;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Email.pm";

### Methods;
# check_queue
# check_config
# 

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Email

Provides all methods used to manage the local C<< postfix >> server and handle and dispatch email via C<< mailx >>

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Email->X'. 
 # 
 # 

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
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


=head2 check_config

This method checks the current postfix server configuration to see if it needs to be updated, then checks to see if the local C<< postfix >> daemin is enabled and started.

If any problem is encountered, C<< 1 >> is returned. Otherwise, if all is well, C<< 0 >> is returned.

This method takes no parameters.

=cut
sub check_config
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Email->check_config()" }});
	
	my $problem = 0;
	
	# We check to see if there are any emails in the queue. If we see queued emails for more than five 
	# minutes, and a second mail server is configured, we'll automatically reconfigure for the next 
	# known server.
	$anvil->Database->get_mail_servers({debug => $debug});
	my ($oldest_message) = $anvil->Email->check_queue({debug => $debug});
	if ($oldest_message > 600)
	{
		# Switch out mail servers. If there's only one mail server, this just checks the existing 
		# config.
		my $mail_server_uuid = $anvil->Email->get_next_server({debug => $debug});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mail_server_uuid => $mail_server_uuid }});
		
		$anvil->Email->_configure_for_server({
			debug            => $debug,
			mail_server_uuid => $mail_server_uuid, 
		});
		
		return($problem);
	}
	
	# If not configured look in variables for 'mail_server::last_used::<mail_server_uuid>'. The first one
	# that doesn't have an existing variable will be used. If all known mail servers have variables, the
	# oldest is used. 
	# 
	# In any case where the mail server is configured, the server that is used has their 
	# 'mail_server::last_used::<mail_server_uuid>' variable set to the current time stamp.
	
	# Get the list of mail servers.
	my $reconfigure = 1;
	
	# What, if anything, is the current mail server?
	my $current_mail_server = "";
	my $postfix_main        = $anvil->Storage->read_file({
		debug => $debug,
		file  => $anvil->data->{path}{configs}{postfix_main},
	});
	foreach my $line (split/\n/, $postfix_main)
	{
		if (($line =~ /relayhost = \[(.*?)\]:/) or ($line =~ /relayhost = (.*?):/))
		{
			$current_mail_server = $1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { current_mail_server => $current_mail_server }});
			
			# What is the UUID for this mail server?
			my $mail_server_uuid = $anvil->data->{mail_servers}{address_to_uuid}{$current_mail_server} ? $anvil->data->{mail_servers}{address_to_uuid}{$current_mail_server} : "";
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mail_server_uuid => $mail_server_uuid }});
			
			if ($mail_server_uuid)
			{
				# Looks OK, so run the configure (it'll do nothing if there are no changes).
				$reconfigure = 0;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reconfigure => $reconfigure }});
			
				$anvil->Email->_configure_for_server({
					debug            => $debug,
					mail_server_uuid => $mail_server_uuid, 
				});
			}
		}
	}
	
	if ($reconfigure)
	{
		my $used_mail_server_count = exists $anvil->data->{mail_servers}{use_order} ? keys %{$anvil->data->{mail_servers}{use_order}} : 0;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { used_mail_server_count => $used_mail_server_count }});
		if (not $used_mail_server_count)
		{
			# Just pick the first one.
			foreach my $mail_server_uuid (keys %{$anvil->data->{mail_servers}{mail_server}})
			{
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { mail_server_uuid => $mail_server_uuid }});
				$anvil->Email->_configure_for_server({
					debug            => $debug,
					mail_server_uuid => $mail_server_uuid, 
				});
			}
		}
	}
	
	return($problem);
}


=head2 check_queue

This method looks to see how many email messages are in the send queue and how long they've been there. The age of the older queued message is returned (in seconds).

This method takes no parameters.

=cut
sub check_queue
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Email->check_queue()" }});
	
	my $oldest_message        = 0;
	my ($queue, $return_code) = $anvil->System->call({debug => 2, shell_call => $anvil->data->{path}{exe}{postqueue}." -j"});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		queue       => $queue,
		return_code => $return_code,
	}});
	
	# This is empty if there is nothing in the queue.
	foreach my $email (split/\n/, $queue)
	{
		my $json       = JSON->new->allow_nonref;
		my $postqueueu = $json->decode($email);
		my $queue_id   = $postqueueu->{queue_id};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { queue_id => $queue_id }});
		
		$anvil->data->{mail}{queue}{$queue_id}{sender}       = $postqueueu->{sender};
		$anvil->data->{mail}{queue}{$queue_id}{queue_name}   = $postqueueu->{queue_name};
		$anvil->data->{mail}{queue}{$queue_id}{arrival_time} = $postqueueu->{arrival_time};
		$anvil->data->{mail}{queue}{$queue_id}{message_age}  = time - $postqueueu->{arrival_time};
		$anvil->data->{mail}{queue}{$queue_id}{message_size} = $postqueueu->{message_size};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			"mail::queue::${queue_id}::sender"       => $anvil->data->{mail}{queue}{$queue_id}{sender},
			"mail::queue::${queue_id}::queue_name"   => $anvil->data->{mail}{queue}{$queue_id}{queue_name},
			"mail::queue::${queue_id}::arrival_time" => $anvil->data->{mail}{queue}{$queue_id}{arrival_time},
			"mail::queue::${queue_id}::message_age"  => $anvil->data->{mail}{queue}{$queue_id}{message_age},
			"mail::queue::${queue_id}::message_size" => $anvil->data->{mail}{queue}{$queue_id}{message_size},
		}});
		foreach my $recipient_hash (@{$postqueueu->{recipients}})
		{
			my $address = $recipient_hash->{address};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { queue_id => $queue_id }});
			
			$anvil->data->{mail}{queue}{$queue_id}{recipient}{$address}{delay_reason} = $recipient_hash->{delay_reason};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				"mail::queue::${queue_id}::recipient::${address}::delay_reason" => $anvil->data->{mail}{queue}{$queue_id}{recipient}{$address}{delay_reason},
			}});
		}
		
		if ($anvil->data->{mail}{queue}{$queue_id}{message_age} > $oldest_message)
		{
			$oldest_message = $anvil->data->{mail}{queue}{$queue_id}{message_age};
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { oldest_message => $oldest_message }});
		}
        };

	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { oldest_message => $oldest_message }});
	return($oldest_message);
}

=head2 get_next_server

When two or more mail servers are configured, this will return the C<< mail_server_uuid >> of the mail server used in the most distant past. If two or more mail servers have never been used before, a random unused server is returned.

If only one mail servers exists, its UUID is returned, making this method safe to call without concern for configured mail server count.

This method takes no parameters.

=cut
sub get_next_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Email->check_queue()" }});
	
	
	# If configured/running, the number of messages in queue is checked. If '0', 
	# 'mail_server::queue_empty' is updated with the current time. If 1 or more, the time since the queue
	# was last 0 is checked. If > 300, the mail server is reconfigured to use the mail server with the
	# oldest 'mail_server::last_used::<mail_server_uuid>' time.
	my $oldest_mail_server_time = time;
	my $oldest_mail_server_uuid = "";
	foreach my $mail_server_uuid (keys %{$anvil->data->{mail_servers}{mail_server}})
	{
		my $last_used = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{last_used};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			mail_server_uuid => $mail_server_uuid,
			last_used        => $last_used, 
		}});
		
		if ($last_used < $oldest_mail_server_time)
		{
			$oldest_mail_server_time = $last_used;
			$oldest_mail_server_uuid = $mail_server_uuid;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				oldest_mail_server_time => $oldest_mail_server_time,
				oldest_mail_server_uuid => $oldest_mail_server_uuid, 
			}});
		}
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { oldest_mail_server_uuid => $oldest_mail_server_uuid }});
	return($oldest_mail_server_uuid);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

# This does the actual work of configuring postfix for a give mail server. Returns '1' if reconfigured, 
# returns '0' if not.
sub _configure_for_server
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Email->_configure_for_server()" }});
	
	my $reload           = 0;
	my $mail_server_uuid = defined $parameter->{mail_server_uuid} ? $parameter->{mail_server_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		mail_server_uuid => $mail_server_uuid, 
	}});
	
	if (not $mail_server_uuid)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Email->register()", parameter => "_configure_for_server" }});
		return($reload);
	}
	
	if (not exists $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid})
	{
		# Try loading the mail server data.
		$anvil->Database->get_mail_servers({debug => $debug});
		
		if (not exists $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid})
		{
			# Invalid UUID / mail server
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "error_0141", variables => { uuid => $mail_server_uuid }});
			return($reload);
		}
	}
	
	### Check / update / create relay_password
	my $mail_server_address        = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_address};
	my $mail_server_port           = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_port};
	my $mail_server_username       = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_username};
	my $mail_server_password       = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_password};
	my $mail_server_security       = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_security};
	my $mail_server_authentication = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_authentication};
	my $mail_server_helo_domain    = $anvil->data->{mail_servers}{mail_server}{$mail_server_uuid}{mail_server_helo_domain};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		mail_server_address        => $mail_server_address, 
		mail_server_port           => $mail_server_port, 
		mail_server_username       => $mail_server_username, 
		mail_server_password       => $mail_server_password, 
		mail_server_security       => $mail_server_security,  
		mail_server_authentication => $mail_server_authentication, 
		mail_server_helo_domain    => $mail_server_helo_domain,
	}});
	
	my $old_postfix_relay_file = "";
	if (-e $anvil->data->{path}{configs}{postfix_relay_password})
	{
		$old_postfix_relay_file = $anvil->Storage->read_file({
			debug  => $debug,
			secure => 1,
			file   => $anvil->data->{path}{configs}{postfix_relay_password},
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { 
			old_postfix_relay_file => $old_postfix_relay_file,
		}});
	}
	
	my $new_postfix_relay_file = "[".$mail_server_address."]:".$mail_server_port." ".$mail_server_username.":".$mail_server_password."\n";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, secure => 1, list => { new_postfix_relay_file => $new_postfix_relay_file }});
	
	if ($new_postfix_relay_file ne $old_postfix_relay_file)
	{
		# Create the new relay file.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0530"});
		   $reload = 1;
		my $error  = $anvil->Storage->write_file({
			backup    => 0,
			debug     => $debug,
			body      => $new_postfix_relay_file,
			file      => $anvil->data->{path}{configs}{postfix_relay_password},
			mode      => "0644",
			user      => "root",
			group     => "root",
			overwrite => 1,
			secure    => 1,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			reload => $reload,
			error  => $error, 
		}});
		
		# Generate the binary version.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0531"});
		my ($output, $return_code) = $anvil->System->call({ debug => $debug, shell_call => $anvil->data->{path}{exe}{postmap}." ".$anvil->data->{path}{configs}{postfix_relay_password} });
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			output      => $output, 
			return_code => $return_code,
		}});
	}
	
	### Check / update main.cf
	my $new_postfix_main = "";
	my $old_postfix_main = $anvil->Storage->read_file({
		debug => $debug,
		file  => $anvil->data->{path}{configs}{postfix_main},
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { old_postfix_relay_file => $old_postfix_relay_file }});
	
	my $last_line                       = "";
	my $relayhost_seen                  = 0;
	my $relayhost_line                  = "relayhost = [".$mail_server_address."]:".$mail_server_port;
	my $smtp_helo_name_seen             = 0;
	my $smtp_helo_name_line             = "smtp_helo_name = ".$anvil->_domain_name();
	my $smtp_use_tls_seen               = 0;
	my $smtp_use_tls_line               = "smtp_use_tls = yes";
	my $smtp_sasl_auth_enable_seen      = 0;
	my $smtp_sasl_auth_enable_line      = "smtp_sasl_auth_enable = yes";
	my $smtp_sasl_password_maps_seen    = 0;
	my $smtp_sasl_password_maps_line    = "smtp_sasl_password_maps = hash:".$anvil->data->{path}{configs}{postfix_relay_password};
	my $smtp_sasl_security_options_seen = 0;
	my $smtp_sasl_security_options_line = "smtp_sasl_security_options =";
	my $smtp_tls_CAfile_seen            = 0;
	my $smtp_tls_CAfile_line            = "smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		relayhost_line                  => $relayhost_line,
		smtp_helo_name_line             => $smtp_helo_name_line, 
		smtp_use_tls_line               => $smtp_use_tls_line, 
		smtp_sasl_auth_enable_line      => $smtp_sasl_auth_enable_line, 
		smtp_sasl_password_maps_line    => $smtp_sasl_password_maps_line, 
		smtp_sasl_security_options_line => $smtp_sasl_security_options_line, 
		smtp_tls_CAfile_line            => $smtp_tls_CAfile_line,
	}});
	
	# Before we start, we'll see if our variables have been seen. If not, we'll inject the below the 
	# 'relay_host' section.
	foreach my $line (split/\n/, $old_postfix_main)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^relayhost = /)
		{
			$relayhost_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { relayhost_seen => $relayhost_seen }});
		}
		if ($line =~ /^smtp_helo_name =/)
		{
			$smtp_helo_name_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { smtp_helo_name_seen => $smtp_helo_name_seen }});
		}
		if ($line =~ /^smtp_use_tls =/)
		{
			$smtp_use_tls_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { smtp_use_tls_seen => $smtp_use_tls_seen }});
		}
		if ($line =~ /^smtp_sasl_auth_enable =/)
		{
			$smtp_sasl_auth_enable_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { smtp_sasl_auth_enable_seen => $smtp_sasl_auth_enable_seen }});
		}
		if ($line =~ /^smtp_sasl_password_maps =/)
		{
			$smtp_sasl_password_maps_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { smtp_sasl_password_maps_seen => $smtp_sasl_password_maps_seen }});
		}
		if ($line =~ /^smtp_sasl_security_options =/)
		{
			$smtp_sasl_security_options_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { smtp_sasl_security_options_seen => $smtp_sasl_security_options_seen }});
		}
		if ($line =~ /^smtp_tls_CAfile =/)
		{
			$smtp_tls_CAfile_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { smtp_tls_CAfile_seen => $smtp_tls_CAfile_seen }});
		}
	}
	
	foreach my $line (split/\n/, $old_postfix_main)
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { line => $line }});
		if ($line =~ /^relayhost = /)
		{
			$relayhost_seen = 1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { relayhost_seen => $relayhost_seen }});
			
			if ($line ne $relayhost_line)
			{
				# Rewrite the line.
				$line   = $relayhost_line;
				$reload = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'   => $line,
					's2:reload' => $reload, 
				}});
			}
		}
		if (($last_line eq "#relayhost = [an.ip.add.ress]") && ($line eq "") && (not $relayhost_seen))
		{
			# Never configured before, inject our line.
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0532"});
			$new_postfix_main .= $relayhost_line."\n";
			$relayhost_seen   =  1;
			$reload           =  1;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				's1:relayhost_line' => $relayhost_line,
				's2:relayhost_seen' => $relayhost_seen, 
				's3:reload'         => $reload, 
			}});
			
			# Inject any other variables we've not seen yet.
			if (not $smtp_helo_name_seen)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_helo_name_line }});
				$reload              =  1;
				$smtp_helo_name_seen =  1;
				$new_postfix_main    .= $smtp_helo_name_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:smtp_helo_name_line' => $smtp_helo_name_line,
					's2:smtp_helo_name_seen' => $smtp_helo_name_seen, 
					's3:reload'              => $reload, 
				}});
			}
			if (not $smtp_use_tls_seen)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_use_tls_line }});
				$reload            =  1;
				$smtp_use_tls_seen =  1;
				$new_postfix_main  .= $smtp_use_tls_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:smtp_use_tls_line' => $smtp_use_tls_line,
					's2:smtp_use_tls_seen' => $smtp_use_tls_seen, 
					's3:reload'            => $reload, 
				}});
			}
			if (not $smtp_sasl_auth_enable_seen)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_sasl_auth_enable_line }});
				$reload                     =  1;
				$smtp_sasl_auth_enable_seen =  1;
				$new_postfix_main           .= $smtp_sasl_auth_enable_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:smtp_sasl_auth_enable_line' => $smtp_sasl_auth_enable_line,
					's2:smtp_sasl_auth_enable_seen' => $smtp_sasl_auth_enable_seen, 
					's3:reload'                     => $reload, 
				}});
			}
			if (not $smtp_sasl_password_maps_seen)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_sasl_password_maps_line }});
				$reload                       =  1;
				$smtp_sasl_password_maps_seen =  1;
				$new_postfix_main             .= $smtp_sasl_password_maps_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:smtp_sasl_password_maps_line' => $smtp_sasl_password_maps_line,
					's2:smtp_sasl_password_maps_seen' => $smtp_sasl_password_maps_seen, 
					's3:reload'                       => $reload, 
				}});
			}
			if (not $smtp_sasl_security_options_seen)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_sasl_security_options_line }});
				$reload                          =  1;
				$smtp_sasl_security_options_seen =  1;
				$new_postfix_main                .= $smtp_sasl_security_options_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:smtp_sasl_security_options_line' => $smtp_sasl_security_options_line,
					's2:smtp_sasl_security_options_seen' => $smtp_sasl_security_options_seen, 
					's3:reload'                          => $reload, 
				}});
			}
			if (not $smtp_tls_CAfile_seen)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_tls_CAfile_line }});
				$reload               =  1;
				$smtp_tls_CAfile_seen =  1;
				$new_postfix_main     .= $smtp_tls_CAfile_line."\n";
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:smtp_tls_CAfile_line' => $smtp_tls_CAfile_line,
					's2:smtp_tls_CAfile_seen' => $smtp_tls_CAfile_seen, 
					's3:reload'               => $reload, 
				}});
			}
		}
		
		# Any other existing config lines 
		if ($line =~ /^smtp_helo_name =/)
		{
			if ($line ne $smtp_helo_name_line)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0534", variables => { 
					old_line => $line, 
					new_line => $smtp_tls_CAfile_line,
				}});
				$line                = $smtp_helo_name_line;
				$smtp_helo_name_seen = 1;
				$reload              = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'                => $line,
					's2:smtp_helo_name_seen' => $smtp_helo_name_seen, 
					's2:reload'              => $reload, 
				}});
			}
		}
		if ($line =~ /^smtp_use_tls =/)
		{
			if ($line ne $smtp_use_tls_line)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0534", variables => { 
					old_line => $line, 
					new_line => $smtp_use_tls_line,
				}});
				$line              = $smtp_use_tls_line;
				$smtp_use_tls_seen = 1;
				$reload            = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'              => $line,
					's2:smtp_use_tls_seen' => $smtp_use_tls_seen, 
					's2:reload'            => $reload, 
				}});
			}
		}
		if ($line =~ /^smtp_sasl_auth_enable =/)
		{
			if ($line ne $smtp_sasl_auth_enable_line)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0534", variables => { 
					old_line => $line, 
					new_line => $smtp_sasl_auth_enable_line,
				}});
				$line                       = $smtp_sasl_auth_enable_line;
				$smtp_sasl_auth_enable_seen = 1;
				$reload                     = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'                       => $line,
					's2:smtp_sasl_auth_enable_seen' => $smtp_sasl_auth_enable_seen, 
					's2:reload'                     => $reload, 
				}});
			}
		}
		if ($line =~ /^smtp_sasl_password_maps =/)
		{
			if ($line ne $smtp_sasl_password_maps_line)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0534", variables => { 
					old_line => $line, 
					new_line => $smtp_sasl_password_maps_line,
				}});
				$line                         = $smtp_sasl_password_maps_line;
				$smtp_sasl_password_maps_seen = 1;
				$reload                       = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'                         => $line,
					's2:smtp_sasl_password_maps_seen' => $smtp_sasl_password_maps_seen, 
					's2:reload'                       => $reload, 
				}});
			}
		}
		if ($line =~ /^smtp_sasl_security_options =/)
		{
			if ($line ne $smtp_sasl_security_options_line)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0534", variables => { 
					old_line => $line, 
					new_line => $smtp_sasl_security_options_line,
				}});
				$line                            = $smtp_sasl_security_options_line;
				$smtp_sasl_security_options_seen = 1;
				$reload                          = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'                            => $line,
					's2:smtp_sasl_security_options_seen' => $smtp_sasl_security_options_seen, 
					's2:reload'                          => $reload, 
				}});
			}
		}
		if ($line =~ /^smtp_tls_CAfile =/)
		{
			if ($line ne $smtp_tls_CAfile_line)
			{
				$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0534", variables => { 
					old_line => $line, 
					new_line => $smtp_tls_CAfile_line,
				}});
				$line                 = $smtp_tls_CAfile_line;
				$smtp_tls_CAfile_seen = 1;
				$reload               = 1;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
					's1:line'                 => $line,
					's2:smtp_tls_CAfile_seen' => $smtp_tls_CAfile_seen, 
					's2:reload'               => $reload, 
				}});
			}
		}
		
		$new_postfix_main .= $line."\n";
		$last_line        =  $line;
	}
	if (not $relayhost_seen)
	{
		# We apparently missed our injection point, append it to the end of the file.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $relayhost_line }});
		$new_postfix_main .= $relayhost_line."\n";
		$reload           =  1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:relayhost_line' => $relayhost_line,
			's2:reload'             => $reload, 
		}});
	}
	if (not $smtp_helo_name_seen)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_helo_name_line }});
		$reload           =  1;
		$new_postfix_main .= $smtp_helo_name_line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:smtp_helo_name_line' => $smtp_helo_name_line,
			's2:reload'              => $reload, 
		}});
	}
	if (not $smtp_use_tls_seen)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_use_tls_line }});
		$reload           =  1;
		$new_postfix_main .= $smtp_use_tls_line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:smtp_use_tls_line' => $smtp_use_tls_line,
			's2:reload'            => $reload, 
		}});
	}
	if (not $smtp_sasl_auth_enable_seen)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_sasl_auth_enable_line }});
		$reload           =  1;
		$new_postfix_main .= $smtp_sasl_auth_enable_line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:smtp_sasl_auth_enable_line' => $smtp_sasl_auth_enable_line,
			's2:reload'                     => $reload, 
		}});
	}
	if (not $smtp_sasl_password_maps_seen)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_sasl_password_maps_line }});
		$reload           =  1;
		$new_postfix_main .= $smtp_sasl_password_maps_line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:smtp_sasl_password_maps_line' => $smtp_sasl_password_maps_line,
			's2:reload'                       => $reload, 
		}});
	}
	if (not $smtp_sasl_security_options_seen)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_sasl_security_options_line }});
		$reload           =  1;
		$new_postfix_main .= $smtp_sasl_security_options_line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:smtp_sasl_security_options_line' => $smtp_sasl_security_options_line,
			's2:reload'                          => $reload, 
		}});
	}
	if (not $smtp_tls_CAfile_seen)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0533", variables => { line => $smtp_tls_CAfile_line }});
		$reload           =  1;
		$new_postfix_main .= $smtp_tls_CAfile_line."\n";
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			's1:smtp_tls_CAfile_line' => $smtp_tls_CAfile_line,
			's2:reload'               => $reload, 
		}});
	}
	
	# Write out the file, if needed.
	if ($old_postfix_main ne $new_postfix_main)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0517", variables => { 
			file => $anvil->data->{path}{configs}{postfix_main},
			diff => diff \$old_postfix_main, \$new_postfix_main, { STYLE => 'Unified' }, 
		}});
		# Create the new relay file.
		   $reload = 1;
		my $error  = $anvil->Storage->write_file({
			debug     => $debug,
			backup    => 1,
			body      => $new_postfix_main,
			file      => $anvil->data->{path}{configs}{postfix_main},
			mode      => "0644",
			user      => "root",
			group     => "root",
			overwrite => 1,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			reload => $reload,
			error  => $error, 
		}});
	}
	
	# Make sure the postfix daemon is running and enabled.
	my $postfix_started = 0;
	
	# Is the postfix daemon running?
	my $postfix_running = $anvil->System->check_daemon({daemon => "postfix.service"});
	if (not $postfix_running)
	{
		# Start it.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0535", variables => { daemon => "postfix.service" }});
		my $start_return_code  = $anvil->System->start_daemon({daemon => "postfix.service"});
		my $enable_return_code = $anvil->System->enable_daemon({daemon => "postfix.service"});
		   $postfix_started    = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			start_return_code  => $start_return_code,
			enable_return_code => $enable_return_code, 
			postfix_started    => $postfix_started,
		}});
	}
	
	if ($reload)
	{
		# Record that we've switched to this mail server.
		my $variable_uuid = $anvil->Database->insert_or_update_variables({
			variable_name         => "mail_server::last_used::${mail_server_uuid}",
			variable_value        => time,
			variable_source_table => "hosts",
			variable_source_uuid  => $anvil->Get->host_uuid,
			variable_section      => "email::servers",
			variable_description  => "striker_0276",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { variable_uuid => $variable_uuid }});
		
		# Start the daemon
		if (not $postfix_started)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "job_0091", variables => { daemon => "postfix.service" }});
			my $restart_return_code = $anvil->System->restart_daemon({daemon => "postfix.service"});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { restart_return_code => $restart_return_code }});
		}
	}
	
	# Lastly, make sure the alert email directory exists.
	if (not -d $anvil->data->{path}{directories}{alert_emails})
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0536"});
		my $failed = $anvil->Storage->make_directory({
			debug     => $debug,
			directory => $anvil->data->{path}{directories}{alert_emails},
			mode      => "0775",
			user      => "root",
			group     => "root",
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { failed => $failed }});
	}
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { reload => $reload }});
	return($reload);
}

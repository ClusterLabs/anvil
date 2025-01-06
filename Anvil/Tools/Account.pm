package Anvil::Tools::Account;
# 
# This module contains methods used to handle user accounts, logging in and out.
# 

use strict;
use warnings;
use Digest::SHA qw(sha256_base64 sha384_base64 sha512_base64);
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Account.pm";

### Methods;
# encrypt_password
# login
# logout
# read_cookies
# read_details
# validate_password
# _build_cookie_hash
# _write_cookies


=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Account

Provides all methods related to user management and log in/out features.

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Account->X'. 

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

=head2 encrypt_password

This takes a string (a new password from a user), generates a salt, appends the salt to the string and hashes that using C<< sys::password::algorithm >>, the re-hashes the string C<< sys::password::hash_count >> times. The default algorithm is 'sha512' and the default rehashing count is '500,000' times. 

This method returns a hash reference with the following keys;

* user_password_hash: The final encrypted hash.
* user_salt:          The salt created (or used) to generate the hash.
* user_algorithm:     The algorithm used to compute the hash.
* user_hash_count:    The number of re-encryptions of the initial hash.

If anything goes wrong, all four keys will have empty strings.

Parameters

=head3 algorithm (optional)

If set, the password will be encrypted using the given algoritm. Otherwise, c<< sys::password::algorithm >> is used. If that is not set, C<< sha256 >> is used.

=head3 hash_count (Optional, default 500000)

This controls how many times we re-encrypt the password hash. This is designed to slow down how quickly a brute-force attacker can test hashes. This should be a high enough number to take some time (~0.5 seconds) on a modern machine, but not so high that it noticeably slows down user login attempts.

If set to C<< 0 >>, no re-hashing will occur, but the initial hash still will.

=head3 password (required)

This is the password (string) to encrypt.

=head3 salt (optional)

This is the salt to use when hashing the password. If this is not passed, a new salt will be generated.

=cut
sub encrypt_password
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->encrypt_password()" }});
	
	my $algorithm  = defined $parameter->{algorithm}  ? $parameter->{algorithm}  : "";
	my $hash_count = defined $parameter->{hash_count} ? $parameter->{hash_count} : "";
	my $password   = defined $parameter->{password}   ? $parameter->{password}   : "";
	my $salt       = defined $parameter->{salt}       ? $parameter->{salt}       : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		algorithm  => $algorithm, 
		hash_count => $hash_count, 
		password   => $anvil->Log->is_secure($password),
		salt       => $salt,
	}});
	
	# We'll fill these out below if we succeed.
	my $answer = {
		user_password_hash => "",
		user_salt          => "",
		user_hash_count    => "",
		user_algorithm     => "",
	};
	
	# Make sure we got a string
	if (not $password)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Account->encrypt_password()", parameter => "password" }});
		return($answer);
	}
	my $user_password_hash = $password;

	# Set the re-hash count, if not already set.
	my $user_hash_count = $hash_count;
	if ($user_hash_count eq "")
	{
		$user_hash_count = $anvil->data->{sys}{password}{hash_count} =~ /^\d+$/ ? $anvil->data->{sys}{password}{hash_count} : 500000;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
	}
	
	# Generate a salt.
	my $user_salt = $salt;
	if (not $user_salt)
	{
		$user_salt = $anvil->Get->_salt;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_salt => $user_salt }});
	}
	
	### TODO: Look at using/support bcrypt as the default algorithm. Needed RPMs are already in the el7 AN!Repo.
	# We support sha256, sha384 and sha512, possible new ones later.
	my $user_algorithm = $algorithm;
	if (not $algorithm)
	{
		$user_algorithm = $anvil->data->{sys}{password}{algorithm} ? $anvil->data->{sys}{password}{algorithm} : "sha512";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_algorithm => $user_algorithm }});
	if ($user_algorithm eq "sha256" )
	{
		$user_password_hash = sha256_base64($user_password_hash.$user_salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_password_hash => $user_password_hash }});
		
		if ($user_hash_count > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
			for (1..$user_hash_count)
			{
				$user_password_hash = sha256_base64($user_password_hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_password_hash => $user_password_hash }});
		}
	}
	elsif ($user_algorithm eq "sha384" )
	{
		$user_password_hash = sha384_base64($user_password_hash.$user_salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_password_hash => $user_password_hash }});
		
		if ($user_hash_count > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
			for (1..$user_hash_count)
			{
				$user_password_hash = sha384_base64($user_password_hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_password_hash => $user_password_hash }});
		}
	}
	elsif ($user_algorithm eq "sha512" )
	{
		$user_password_hash = sha512_base64($user_password_hash.$user_salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_password_hash => $user_password_hash }});
		
		if ($user_hash_count > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
			for (1..$user_hash_count)
			{
				$user_password_hash = sha512_base64($user_password_hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_password_hash => $user_password_hash }});
		}
	}
	else
	{
		# Bash algorith. 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0171", variables => { user_algorithm => $user_algorithm }});
		return($answer);
	}
	
	$answer = {
		user_password_hash => $user_password_hash,
		user_salt          => $user_salt,
		user_hash_count    => $user_hash_count,
		user_algorithm     => $user_algorithm,
	};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'answer->user_password_hash' => $answer->{user_password_hash}, 
		'answer->user_salt'          => $answer->{user_salt}, 
		'answer->user_hash_count'    => $answer->{user_hash_count}, 
		'answer->user_algorithm'     => $answer->{user_algorithm}, 
	}});
	
	return($answer);
}

=head2 login

This checks to see if the CGI C<< username >> and C<< password >> passed in are for a valid user or not. If so, their details are loaded and C<< 0 >> is returned. If not, C<< 1 >> is returned.

This method takes no parameters.

=cut
sub login
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;

	my $debug    = defined $parameter->{debug} ? $parameter->{debug} : 3;
	my $password = $parameter->{password} // $anvil->data->{cgi}{password}{value};
	my $username = $parameter->{username} // $anvil->data->{cgi}{username}{value};

	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->login()" }});
	
	if ((not $username) or (not $password))
	{
		# The user forgot something...
		$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0027"}) }});
		return(1);
	}
	
	my $query = "
SELECT 
    user_uuid, 
    user_password_hash, 
    user_salt, 
    user_algorithm, 
    user_hash_count 
FROM 
    users 
WHERE 
    user_algorithm != 'DELETED' 
AND 
    user_name = ".$anvil->Database->quote($username)."
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	
	if (not $count)
	{
		# User not found.
		$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0027"}) }});
		return(1);
	}
	
	my $user_uuid          = $results->[0]->[0];
	my $user_password_hash = $results->[0]->[1];
	my $user_salt          = $results->[0]->[2];
	my $user_algorithm     = $results->[0]->[3];
	my $user_hash_count    = $results->[0]->[4];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		user_uuid          => $user_uuid,
		user_password_hash => $user_password_hash,
		user_salt          => $user_salt,
		user_algorithm     => $user_algorithm,
		user_hash_count    => $user_hash_count,
	}});
	
	# Test the passed-in password.
	my $test_password_answer = $anvil->Account->encrypt_password({
		debug      => 2,
		password   => $password,
		salt       => $user_salt, 
		algorithm  => $user_algorithm, 
		hash_count => $user_hash_count,
	});
	my $test_password_hash = $test_password_answer->{user_password_hash};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { test_password_hash => $test_password_hash }});
	
	if ($test_password_hash eq $user_password_hash)
	{
		# User passed a valid username/password. Create a session hash.
		my ($session_hash, $session_salt) = $anvil->Account->_build_cookie_hash({
			debug  => $debug,
			uuid   => $user_uuid, 
			offset => 0,
		});
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
			session_hash => $session_hash,
			session_salt => $session_salt, 
		}});
		
		if (not $session_hash)
		{
			# Something went wrong generating the session cookie, login failed.
			$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0028"}) }});
			return(1);
		}
		else
		{
			my $session_uuid = $anvil->Database->insert_or_update_sessions({
				debug             => $debug,
				session_user_uuid => $user_uuid, 
				session_salt      => $session_salt, 
			});
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { session_uuid => $session_uuid }});

			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0183", variables => { user => $username }});
			$anvil->Account->_write_cookies({
				debug => $debug, 
				hash  => $session_hash, 
				uuid  => $user_uuid,
			});
		}
	}
	else
	{
		# User DID NOT pass a valid username/password.
		$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0027"}) }});
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0184", variables => { 
			user_agent => $ENV{HTTP_USER_AGENT} ? $ENV{HTTP_USER_AGENT} : "#!string!log_0185!#", 
			source_ip  => $ENV{REMOTE_ADDR}     ? $ENV{REMOTE_ADDR}     : "#!string!log_0185!#",
			user       => $username,
		}});
		
		# Slow them down a bit...
		sleep 5;

		return(1);
	}
	
	return(0);
}

=head2 logout

This deletes the user's UUID and hash cookies, which effectively logs them out.

If there is no C<< user_uuid >>, this will return C<< 1 >>. Otherwise, C<< 0 >> is returned.

Parameters;

=head3 user_uuid (optional, default 'cookie::anvil_user_uuid')

This is the user to log out.

=head3 host_uuid (optional, default 'Get->host_uuid')

This is the host to log out of. This takes the special C<< all >> value which logs the user out of all hosts sessions.

=cut
sub logout
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->logout()" }});
	
	# NOTE: This no longer works.
	return(0);
	
	# Delete the user's cookie data. Sending nothing to '_write_cookies' does this.
	$anvil->Account->_write_cookies({debug => $debug});
	
	my $user_uuid = defined $parameter->{user_uuid} ? $parameter->{user_uuid} : "";
	my $host_uuid = defined $parameter->{host_uuid} ? $parameter->{host_uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		user_uuid => $user_uuid, 
		host_uuid => $host_uuid, 
	}});
	
	if (not $host_uuid)
	{
		$host_uuid = $anvil->Get->host_uuid;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { host_uuid => $host_uuid }});
	}
	
	if (($anvil->data->{cookie}{anvil_user_uuid}) && (not $user_uuid))
	{
		$user_uuid = $anvil->data->{cookie}{anvil_user_uuid};
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_uuid => $user_uuid }});
	}
	
	# If I don't have a user UUID, we can't proceed.
	if (not $user_uuid)
	{
		# User not found.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0040"});
		$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0040"}) }});
		return(1);
	}
	
	# If the host_uuid is 'all', we're logging out all sessions.
	
	# Delete the user's session salt. We don't use Database->insert_or_update_sessions() to not 
	# complicate handling 'all' hosts.
	my $query = "
UPDATE 
    sessions 
SET 
    session_salt      = '', 
    modified_date     = ".$anvil->Database->quote($anvil->Database->refresh_timestamp)." 
WHERE 
    session_user_uuid = ".$anvil->Database->quote($user_uuid)." ";
	if ($host_uuid ne "all")
	{
		$query .= "
AND 
    session_host_uuid = ".$anvil->Database->quote($host_uuid)." ";
	}
	$query .= "
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	$anvil->Database->write({debug => $debug, query => $query, source => $THIS_FILE, line => __LINE__});

	my $user = $anvil->data->{cgi}{username}{value} ? $anvil->data->{cgi}{username}{value} : "--";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0198", variables => { user => $user }});
	
	# Log that they're out
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0179"});
	
	return(0);
}

=head2 read_cookies

This method (tries to) read the user's cookies to see if their session is valid. If so, it will read in their account details.

This method takes no parameters.

Return codes;

=head3 0

The cookies were read, the account was validated and the user's details were loaded.

=head3 1

No cookie was found or read. The user needs to log in

=head3 2

There was a problem reading the user's UUID (it wasn't found in the database), so the cookies were deleted (via C<< Account->logout() >>. The user needs to log back in.

=head3 3

There user's hash is invalid, it is probably expired. The user has been logged out and needs to log back in.

=cut
sub read_cookies
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->read_cookies()" }});
	
	# Read in any cookies
	if (defined $ENV{HTTP_COOKIE})
	{
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "ENV{HTTP_COOKIE}" => $ENV{HTTP_COOKIE} }});
		my @data = (split /; /, $ENV{HTTP_COOKIE});
		foreach my $pair (@data)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { pair => $pair }});
			
			my ($key, $value) = split/=/, $pair;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
				key   => $key, 
				value => $value, 
			}});
			
			next if ((not defined $value) or ($value eq ""));
			if ($key =~ /^anvil_/)
			{
				$anvil->data->{cookie}{$key} = $value;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { "cookie::${key}" => $anvil->data->{cookie}{$key} }});
			}
		}
	}
	
	# Did we read a cookie?
	if ((not defined $anvil->data->{cookie}{anvil_user_uuid}) or (not $anvil->data->{cookie}{anvil_user_uuid}))
	{
		# No cookie read.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0177"});
		return(1);
	}
	elsif (not defined $anvil->data->{cookie}{anvil_user_hash})
	{
		$anvil->data->{cookie}{anvil_user_hash} = "";
	}
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"cookie::anvil_user_uuid" => $anvil->data->{cookie}{anvil_user_uuid},
		"cookie::anvil_user_hash" => $anvil->data->{cookie}{anvil_user_hash},
	}});
	
	# Validate the cookie if there is a User UUID. Pick the random number up from the database.
	my $query = "
SELECT 
    a.user_name, 
    b.session_salt 
FROM 
    users a, 
    sessions b 
WHERE 
    a.user_uuid = b.session_user_uuid 
AND 
    b.session_user_uuid = ".$anvil->Database->quote($anvil->data->{cookie}{anvil_user_uuid})."
AND 
    b.session_host_uuid = ".$anvil->Database->quote($anvil->Get->host_uuid)."
;";
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0124", variables => { query => $query }});
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count,
	}});
	
	if ($count < 1)
	{
		# The user in the cookie isn't in the database. The user was deleted?
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0215"});
		$anvil->Account->logout();
		
		# Record the error message for the user.
		$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0023"}) }});
		
		# We're done.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0178", variables => { uuid => $anvil->data->{cookie}{anvil_user_uuid} }});
		return(2);
	}
	
	# Read in their "rand" value
	$anvil->data->{sys}{users}{user_name}  = $results->[0]->[0];
	$anvil->data->{sessions}{session_salt} = $results->[0]->[1];
	$anvil->data->{sessions}{session_salt} = "" if not defined $anvil->data->{sessions}{session_salt};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"sys::users::user_name"  => $anvil->data->{sys}{users}{user_name}, 
		"sessions::session_salt" => $anvil->data->{sessions}{session_salt},
	}});
	
	# Generate a hash using today and yesterday's date.
	my ($today_hash) = $anvil->Account->_build_cookie_hash({
		debug  => $debug, 
		uuid   => $anvil->data->{cookie}{anvil_user_uuid}, 
		salt   => $anvil->data->{sessions}{session_salt}, 
		offset => 0,
	});
	my ($yesterday_hash) = $anvil->Account->_build_cookie_hash({
		debug  => $debug,
		uuid   => $anvil->data->{cookie}{anvil_user_uuid}, 
		salt   => $anvil->data->{sessions}{session_salt}, 
		offset => -86400,
	});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		"s1:cookie::anvil_user_hash" => $anvil->data->{cookie}{anvil_user_hash}, 
		"s2:today_hash"              => $today_hash,
		"s3:yesterday_hash"          => $yesterday_hash, 
	}});
	
	# See if either hash matches what the user has stored.
	if ($anvil->data->{cookie}{anvil_user_hash} eq $today_hash)
	{
		# Valid hash, user can proceed.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0180"});
		
		# Load the account details
		$anvil->Account->read_details({debug => $debug});
	}
	elsif ($anvil->data->{cookie}{anvil_user_hash} eq $yesterday_hash)
	{
		# The hash was valid yesterday, so we'll update the cookie with today's hash and proceed 
		# (which also loads the user's details).
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0181"});
		$anvil->Account->_write_cookies({
			debug => $debug, 
			hash  => $today_hash, 
			uuid  => $anvil->data->{cookie}{anvil_user_uuid},
		});
	}
	else
	{
		# The user's cookie is invalid, log the user out.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0215"});
		$anvil->Account->logout();
		
		# Record the error message for the user.
		$anvil->data->{form}{error_massage} = $anvil->Template->get({file => "main.html", name => "error_message", variables => { error_message => $anvil->Words->string({key => "error_0024"}) }});
		
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "log_0182"});
		return(3);
	}
	
	return(0);
}

=head2 read_details

This method takes a user uuid and, if the user is found, reads in the details and sets C<< sys::users::<column names> >>. If the user is found, C<< 1 >> is returned. If not, C<< 0 >> is returned.

Parameters;

=head3 user_uuid (optional)

This is the user UUID being searched for. If it is not set, C<< cookie::anvil_user_uuid >>

=cut
sub read_details
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->read_details()" }});
	
	my $user_uuid = defined $parameter->{user_uuid} ? $parameter->{user_uuid} : $anvil->data->{cookie}{anvil_user_uuid};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_uuid => $user_uuid }});
	
	if (not $anvil->Validate->uuid({uuid => $user_uuid}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0025", variables => { uuid => $user_uuid }});
		return(0);
	}
	
	my $query = "
SELECT 
    user_name,
    user_password_hash, 
    user_salt, 
    user_algorithm, 
    user_hash_count, 
    user_language, 
    user_is_admin, 
    user_is_experienced, 
    user_is_trusted 
FROM 
    users 
WHERE 
    user_uuid = ".$anvil->Database->quote($user_uuid)." 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	if (not $count)
	{
		# User doesn't exist.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 1, key => "error_0026", variables => { uuid => $user_uuid }});
		return(0);
	}
	my $user_name           = $results->[0]->[0];
	my $user_password_hash  = $results->[0]->[1];
	my $user_salt           = $results->[0]->[2];
	my $user_algorithm      = $results->[0]->[3];
	my $user_hash_count     = $results->[0]->[4];
	my $user_language       = $results->[0]->[5];
	my $user_is_admin       = $results->[0]->[6];
	my $user_is_experienced = $results->[0]->[7];
	my $user_is_trusted     = $results->[0]->[8];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		user_name           => $user_name, 
		user_password_hash  => $user_password_hash,
		user_salt           => $user_salt,
		user_algorithm      => $user_algorithm,
		user_hash_count     => $user_hash_count,
		user_language       => $user_language,
		user_is_admin       => $user_is_admin,
		user_is_experienced => $user_is_experienced,
		user_is_trusted     => $user_is_trusted,
	}});
	
	$anvil->data->{sys}{users}{user_name}           = $user_name;
	$anvil->data->{sys}{users}{user_uuid}           = $user_uuid;
	$anvil->data->{sys}{users}{user_password_hash}  = $user_password_hash,
	$anvil->data->{sys}{users}{user_salt}           = $user_salt,
	$anvil->data->{sys}{users}{user_algorithm}      = $user_algorithm,
	$anvil->data->{sys}{users}{user_hash_count}     = $user_hash_count,
	$anvil->data->{sys}{users}{user_language}       = $user_language,
	$anvil->data->{sys}{users}{user_is_admin}       = $user_is_admin,
	$anvil->data->{sys}{users}{user_is_experienced} = $user_is_experienced,
	$anvil->data->{sys}{users}{user_is_trusted}     = $user_is_trusted,
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'sys::users::user_name'           => $anvil->data->{sys}{users}{user_name}, 
		'sys::users::user_uuid'           => $anvil->data->{sys}{users}{user_uuid}, 
		'sys::users::user_password_hash'  => $anvil->data->{sys}{users}{user_password_hash}, 
		'sys::users::user_salt'           => $anvil->data->{sys}{users}{user_salt}, 
		'sys::users::user_algorithm'      => $anvil->data->{sys}{users}{user_algorithm}, 
		'sys::users::user_hash_count'     => $anvil->data->{sys}{users}{user_hash_count}, 
		'sys::users::user_language'       => $anvil->data->{sys}{users}{user_language}, 
		'sys::users::user_is_admin'       => $anvil->data->{sys}{users}{user_is_admin}, 
		'sys::users::user_is_experienced' => $anvil->data->{sys}{users}{user_is_experienced}, 
		'sys::users::user_is_trusted'     => $anvil->data->{sys}{users}{user_is_trusted}, 
	}});
	
	# Change the active language, if needed
	if ($anvil->data->{sys}{users}{user_language})
	{
		# Switch to the user's language
		$anvil->Words->language({set => $anvil->data->{sys}{users}{user_language}});
	}
	
	return(1);
}

=head2 validate_password

This method takes a user name and password and checks to see if the password matches.

If the password is wrong, or if the user isn't found, C<< 0 >> is returned. If the password matches, C<< 1 >> is returned.

Parameters;

=head3 password (required)

This is the password to test.

=head3 user (required)

This is the user whose password we're testing.

=cut
sub validate_password
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->validate_password()" }});
	
	my $password  = defined $parameter->{password} ? $parameter->{password} : "";
	my $user      = defined $parameter->{user}     ? $parameter->{user}     : "";
	my $valid     = 0;
	my $hash      = "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password => $anvil->Log->is_secure($password),
		user     => $user, 
	}});
	
	if (not $password)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Account->validate_password()", parameter => "password" }});
		return($valid);
	}
	if (not $user)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Account->validate_password()", parameter => "user" }});
		return($valid);
	}
	
	my $query = "
SELECT 
    user_password_hash, 
    user_salt, 
    user_algorithm, 
    user_hash_count 
FROM 
    users 
WHERE 
    user_name = ".$anvil->Database->quote($user)." 
;";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { query => $query }});
	
	my $results = $anvil->Database->query({query => $query, source => $THIS_FILE, line => __LINE__});
	my $count   = @{$results};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		results => $results, 
		count   => $count, 
	}});
	
	if (not $count)
	{
		# User not found.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0172", variables => { user => $user }});
		return($valid);
	}
	
	my $user_password_hash = $results->[0]->[0];
	my $user_salt          = $results->[0]->[1];
	my $user_algorithm     = $results->[0]->[2];
	my $user_hash_count    = $results->[0]->[3];
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		user_password_hash => $user_password_hash,
		user_salt          => $user_salt,
		user_algorithm     => $user_algorithm,
		user_hash_count    => $user_hash_count,
	}});
	
	if ($user_algorithm eq "sha256" )
	{
		$hash = sha256_base64($password.$user_salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		
		if ($user_hash_count > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
			for (1..$user_hash_count)
			{
				$hash = sha256_base64($hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		}
	}
	elsif ($user_algorithm eq "sha384" )
	{
		$hash = sha384_base64($password.$user_salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		
		if ($user_hash_count > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
			for (1..$user_hash_count)
			{
				$hash = sha384_base64($hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		}
	}
	elsif ($user_algorithm eq "sha512" )
	{
		$hash = sha512_base64($password.$user_salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		
		if ($user_hash_count > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { user_hash_count => $user_hash_count }});
			for (1..$user_hash_count)
			{
				$hash = sha512_base64($hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		}
	}
	else
	{
		# Bad algorith. 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0173", variables => { user_algorithm => $user_algorithm }});
		return($valid);
	}
	
	# Test.
	if ($hash eq $user_password_hash)
	{
		# Good password.
		$valid = 1;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { valid => $valid }});
	}
	
	return($valid);
}


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################

=head2 _build_cookie_hash

This takes a (user) UUID and offset (stated as seconds) and builds a hash approporiate for use in cookies (or a test hash to validate a read cookie hash). The resulting hash and the salt used to generate the hash are returned.

If there is a problem, C<< 0 >> will be returned for both the hash and salt.

Parameters;

=head3 offset (optional, default '0')

This is used to offset the date when generating the date part of the string to hash. It is passed as-is directly to C<< Get->date_and_time >>.

=head3 user_agent (optional, default 'HTTP_USER_AGENT' environment variable)

This is the user agent to use when generating the string to hash.

=head3 uuid (optional, default 'cookie::anvil_user_uuid')

This is the UUID to use when generating the string to hash. Generally it is the user's UUID.

=cut
sub _build_cookie_hash
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->_build_cookie_hash()" }});
	
	my $offset     = defined $parameter->{offset}     ? $parameter->{offset}     : 0;
	my $user_agent = defined $parameter->{user_agent} ? $parameter->{user_agent} : $ENV{HTTP_USER_AGENT};
	my $salt       = defined $parameter->{salt}       ? $parameter->{salt}       : "";
	my $uuid       = defined $parameter->{uuid}       ? $parameter->{uuid}       : $anvil->data->{cookie}{anvil_user_uuid};
	# I know I could do chained conditionals, but it gets hard to read.
	$user_agent = "" if not defined $user_agent; 
	$uuid       = "" if not defined $uuid;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		offset     => $offset, 
		user_agent => $user_agent, 
		salt       => $salt, 
		uuid       => $uuid, 
	}});
	
	if (not $anvil->Validate->uuid({uuid => $uuid}))
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Account->_build_cookie_hash()", parameter => "uuid" }});
		return(0, 0);
	}
	if (not $user_agent)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Account->_build_cookie_hash()", parameter => "user_agent" }});
		return(0, 0);
	}
	
	my $date = $anvil->Get->date_and_time({date_only => 1, offset => $offset});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { date => $date }});

	my $session_string = $uuid.":".$date.":".$user_agent;
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { session_string => $session_string }});
	
	if (not $salt)
	{
		$salt = $anvil->Get->_salt;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
	}
	
	# Generate a hash, but unike normal passwords, we won't re-encrypt it.
	my $answer = $anvil->Account->encrypt_password({
		debug      => $debug, 
		hash_count => 0,
		password   => $session_string, 
		salt       => $salt, 
	});
	
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		hash => $answer->{user_password_hash},
		salt => $answer->{user_salt}, 
	}});
	
	return($answer->{user_password_hash}, $answer->{user_salt});
}

=head2 _write_cookies

This sets (or clears) the user's cookies.

Parameters;

=head3 hash (optional)

This is the hash to use for the session. If it is blank, it will log the user out.

=head3 uuid (optional)

This is the UUID of the user. If it is blank, it will log the user out.

=cut
sub _write_cookies
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Account->_write_cookies()" }});
	
	my $hash = defined $parameter->{hash} ? $parameter->{hash} : "";
	my $uuid = defined $parameter->{uuid} ? $parameter->{uuid} : "";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		hash => $hash,
		uuid => $uuid, 
	}});
	
	# If we have a users ID, load the user details
	if (($hash) && ($uuid))
	{
		# Write the cookies
		print "Set-Cookie:anvil_user_uuid=".$uuid.";\n";
		print "Set-Cookie:anvil_user_hash=".$hash.";\n";
		
		# Load the user's details
		$anvil->Account->read_details({
			debug     => $debug, 
			user_uuid => $uuid});
		
		# Update the active language, if needed.
		if ($anvil->data->{sys}{users}{user_language})
		{
			# Switch to the user's language
			$anvil->Words->language({set => $anvil->data->{sys}{users}{user_language}});
		}
	}
	else
	{
		print "Set-Cookie:anvil_user_uuid=; expires=-1d;\n";
		print "Set-Cookie:anvil_user_hash=; expires=-1d;\n";
	}
	
	return(0);
}

1;

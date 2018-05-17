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
# 


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
		weaken($self->{HANDLE}{TOOLS});;
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 encrypt_password

This takes a string (a new password from a user), generates a salt, appends the salt to the string and hashes that using C<< sys::password::algorithm >>, the re-hashes the string C<< sys::password::hash_count >> times. The default algorithm is 'sha512' and the default rehashing count is '500,000' times. 

This method returns a hash reference with the following keys;

* hash:      The final encrypted hash.
* salt:      The salt created (or used) to generate the hash.
* algorithm: The algorithm used to compute the hash.
* loops:     The number of re-encryptions of the initial hash.

If anything goes wrong, all four keys will have empty strings.

Parameters

=head3 password (required)

This is the password (string) to encrypt.

=head3 salt (optional)

If passed, this string will be appended to the password to salt the string. If this is not passed, a random, new hash 

=cut
sub encrypt_password
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	
	my $password  = defined $parameter->{password} ? $parameter->{password} : "";
	my $salt      = defined $parameter->{salt}     ? $parameter->{target}   : "";
	my $hash      = "";
	my $loops     = $anvil->data->{sys}{password}{hash_count} =~ /^\d+$/ ? $anvil->data->{sys}{password}{hash_count} : 500000;
	my $algorithm = $anvil->data->{sys}{password}{algorithm}             ? $anvil->data->{sys}{password}{algorithm}  : "sha512";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		password => $anvil->Log->secure ? $password : "--",
		salt     => $salt, 
	}});
	
	# We'll fill these out below if we succeed.
	my $answer = {
		hash      => "",
		salt      => "",
		loops     => "",
		algorithm => "",
	};
	
	# Make sure we got a string
	if (not $password)
	{
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0020", variables => { method => "Account->encrypt_password()", parameter => "password" }});
		return($answer);
	}
	
	# If we weren't passed a salt, generate one node.
	if (not $salt)
	{
		$salt = $anvil->Get->_salt;
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { salt => $salt }});
	}
	
	### TODO: Look at using/support bcrypt as the default algorithm. Needed RPMs are already in the el7 AN!Repo.
	# We support sha256, sha384 and sha512, possible new ones later.
	if ($algorithm eq "sha256" )
	{
		$hash = sha256_base64($password.$salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		
		if ($loops > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { loops => $loops }});
			for (1..$loops)
			{
				$hash = sha256_base64($hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		}
	}
	elsif ($algorithm eq "sha384" )
	{
		$hash = sha384_base64($password.$salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		
		if ($loops > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { loops => $loops }});
			for (1..$loops)
			{
				$hash = sha384_base64($hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		}
	}
	elsif ($algorithm eq "sha512" )
	{
		$hash = sha512_base64($password.$salt);
		$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		
		if ($loops > 0)
		{
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { loops => $loops }});
			for (1..$loops)
			{
				$hash = sha512_base64($hash);
			}
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { hash => $hash }});
		}
	}
	else
	{
		# Bash algorith. 
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => 0, priority => "err", key => "log_0171", variables => { algorithm => $algorithm }});
		return($answer);
	}
	
	$answer = {
		hash      => $hash,
		salt      => $salt,
		loops     => $loops,
		algorithm => $algorithm,
	};
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level => $debug, list => { 
		'answer->hash'      => $answer->{hash}, 
		'answer->salt'      => $answer->{salt}, 
		'answer->loops'     => $answer->{loops}, 
		'answer->algorithm' => $answer->{algorithm}, 
		
	}});
	
	return($answer);
}

1;

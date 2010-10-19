# Save/reload emails from 'stashes' (dirs containing sets of emails). 
# 
# Rob Ramsay 01:42  8 Sep 2010 
 
use strict;
 
require 'stash/misc_stash.pl'; 


{package stash; 
	use constant ERROR_STASH_DIR => 	"../logs/erroneous_emails"; 
	use constant FAILED_HTTP_STASH_DIR => 	"../logs/failed_sends"; 
	use constant FAILED_SEND_STASH_DIR => 	"../logs/failed_https"; 
}
 
 
sub stash::stash_erroneous_email($) 
{ 
	my $eml_text = $_[0]; 
 
 
	my $filename = &stash::unique_names(stash::ERROR_STASH_DIR); 
	 
	if ($filename) 
	{ 
		open FILE, ">", "$filename" 
				or warn "Couldn't open $filename for writing: $!" 
				and return undef; 
		print FILE $eml_text;
		close FILE;
		
		return $filename;
	}
	else
	{
		return undef;
	}
}


sub stash::stash_failed_http_request($) 
{ 
	my $eml_text = $_[0]; 
	my $http_text = $_[0]; 
 
 
	my $email_file = &stash::unique_names(stash::FAILED_HTTP_STASH_DIR); 
	my $http_file = "$email_file.http.txt";
	 
	if ($email_file) 
	{ 
		open FILE, ">", "$email_file" 
				or warn "Couldn't open $email_file for writing: $!"
				and return undef; 
		print FILE $eml_text;
		close FILE;
	
		open FILE, ">", "$http_file" 
				or warn "Couldn't open $http_file for writing: $!"
				and return undef; 
		print FILE $http_text;
		close FILE;
		
		return ($email_file, $http_file);
	}
	else
	{
		return (undef, undef);
	}
}


sub stash::stash_failed_send($) 
{ 
	my $eml_text = $_[0]; 
 
 
	my $filename = &stash::unique_names(stash::FAILED_SEND_STASH_DIR); 
	 
	if ($filename) 
	{ 
		open FILE, ">", "$filename" 
				or warn "Couldn't open $filename for writing: $!"
				and return undef; 
		print FILE $eml_text;
		close FILE;
		
		return $filename;
	}
	else
	{
		return undef;
	}
}


1;

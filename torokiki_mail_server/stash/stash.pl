# Save/reload emails from 'stashes' (dirs containing sets of emails). 
# 
# Rob Ramsay 01:42  8 Sep 2010 
 
use strict;
 
require 'stash/misc_stash.pl'; 


{package stash; 
	use constant ERROR_STASH_DIR => "../email_stash/erroneous_emails"; 
	use constant FALIED_SEND_STASH_DIR => "../email_stash/failed_sends"; 
}
 
 
sub stash::stash_erroneous_email($) 
{ 
	my $eml_text = $_[0]; 
 
 
	my $filename = &stash::unique_names(stash::ERROR_DIR); 
	 
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


sub stash::stash_failed_send($) 
{ 
	my $eml_text = $_[0]; 
 
 
	my $filename = &stash::unique_names(stash::FALIED_SEND_STASH_DIR); 
	 
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


}


1;

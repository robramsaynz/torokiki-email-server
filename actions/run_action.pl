# Run an action (assumes the email has been confirmed as valid torokiki one).
#
# Rob Ramsay 22:27 29 Aug 2010

require 'create_response_to.pl';
require 'get.pl';
require 'help.pl';
require '../incoming_mail_checks/parse_email.pl';


sub run_action($)
{
	my $eml_mime = $[0];


	# The help message has different syntax to the rest of the system
	if ( &is_help_message($eml_mime) )
	{ 
		return &run_help_cmd($eml_mime);
	}


    my $_ = $eml_mime->header("Subject");

	if ( /^get:/ )
	{ 
		return &run_get_cmd($eml_mime);
	}
	elsif ( /^create-response-to:/ )
	{ 
		return &run_create_response_to_cmd($eml_mime);
	}
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 

}


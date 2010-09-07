# Run an action (assumes the email has been confirmed as valid torokiki one).
#
# Rob Ramsay 22:27 29 Aug 2010

require 'create_response_to.pl';
require 'get.pl';
require 'help.pl';
require '../incoming_mail_checks/parse_email.pl';


sub actions::run_action($)
{
	my $eml_mime = $_[0];


	# The help message has different syntax to the rest of the system
	if ( &is_help_message($eml_mime) )
	{ 
		return &send_help($eml_mime);
	}


    $_ = $eml_mime->header("Subject");

	if ( /^get:/i )
	{ 
		return &get_content($eml_mime);
	}
	elsif ( /^create-response-to:/i )
	{ 
		return &create_response_to_content($eml_mime);
	}
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 

}


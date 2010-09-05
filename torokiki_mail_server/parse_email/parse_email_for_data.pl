#
# Rob Ramsay 00:42  3 Sep 2010

require 'parse_api_object.pl';
require '../incoming_mail_checks/parse_email.pl';


sub parse_email::parse_email_for_data($)
{
    my $eml_mime = $_[0];


    # The help message has different syntax to the rest of the system,
	# and are ignored.
    if ( &is_help_message($eml_mime) )
        { return undef; }


	# Munge any data that an action requires.
	$eml_mime->header("Subject");
	my $api_obj;

#	if ( /^get:/i )
	if ( /^create-response-to:/i )
	{ 
		$api_obj = &get_api_obj_from_email($eml_mime);
		return $api_obj;
	}
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 

	return undef;
}

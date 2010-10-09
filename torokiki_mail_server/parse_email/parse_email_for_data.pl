#
# Rob Ramsay 00:42  3 Sep 2010

use strict;

require 'parse_email/parse_api_object.pl';
require 'parse_email/misc_parsing.pl';


sub parse_email::parse_email_for_data($)
{
    my $eml_mime = $_[0];

	my %eml_data; 


    # The help message has different syntax to the rest of the system,
	# and are ignored.
    if ( &parse_email::is_help_message($eml_mime) )
    { 
    	$eml_data{eml_mime} = $eml_mime;
		return \%eml_data;
	}


	# Munge any data that an action requires.
	$eml_mime->header("Subject");
	my $api_obj;

	if ( /^get:/i )
	{
    	$eml_data{eml_mime} = $eml_mime;

    	$eml_mime->header("Subject") =~ m/^[\w-]+:\s*'(\S+)'\s*$/;
    	$eml_data{get_url} = $1;

		return \%eml_data;
	}
	elsif ( /^create-response-to:/i )
	{ 
		$api_obj = &parse_email::get_api_obj_from_email($eml_mime);

    	$eml_data{eml_mime} = $eml_mime;
    	$eml_data{api_obj} = $api_obj;

		return \%eml_data;
	}
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 

	return undef;	# Should never be reached.
}


1;

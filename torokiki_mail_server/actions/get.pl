# Retrieve some content from the torokiki website.
#
# Rob Ramsay 17:56  7 Sep 2010

use strict;

require 'comms/http_torokiki_api.pl';
require 'send/send_emails.pl';


sub actions::get_content($)
{
	my $eml_data = $_[0];


	unless ( $eml_data->{get_url} )
	{
		return (undef, "\$eml_data->{get_url} not filled out.");
	}


	my ($err, $rtn) = &comms::get_content_from_torokiki_server($eml_data);
	
	if ($err) 
	{
		my $api_obj = &parse_email::get_api_obj_from_string($rtn);

		&send::send_get_succeeded_reply($eml_data, $api_obj);
		return 1;
	}
	else
	{ 
		&send::send_get_failed_reply($eml_data);
		return (undef, "$rtn"); 
	}
}


1;

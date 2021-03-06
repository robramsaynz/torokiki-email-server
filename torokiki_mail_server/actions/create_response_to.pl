# Submitt some content to the torokiki website, in response
# to a piece of existing content.
#
# Rob Ramsay 17:56  7 Sep 2010

use strict;

use Email::MIME;

require 'comms/http_torokiki_api.pl';
require 'send/send_emails.pl';


sub actions::create_response_to_content($)
{
	my $eml_data = $_[0];

	
	unless ( $eml_data->{api_obj} )
	{
		return (undef, "\$eml_data->{api_obj} not filled out.");
	}


	my ($err, $rtn) = &comms::send_api_obj_to_torokiki_server($eml_data);

	if ($err)
	{
		&send::send_create_response_to_succeeded_reply($eml_data);
		return (1, "");
	}
	else
	{
		&send::send_create_response_to_failed_reply($eml_data);
		return (undef, "$rtn");
	}
}


1;

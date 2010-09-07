# Submitt some content to the torokiki website, in response
# to a piece of existing content.
#
# Rob Ramsay 17:56  7 Sep 2010


use comms::http_torokiki_api;

sub actions::create_response_to_content($)
{
	$eml_mime = $_[0];
	$eml_mime = $_[0];


	&comms::send_mailserv_obj_to_torokiki_server($);

	return -1;
}


1;

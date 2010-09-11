# Submitt some content to the torokiki website, in response
# to a piece of existing content.
#
# Rob Ramsay 17:56  7 Sep 2010


#use comms::http_torokiki_api;
require 'comms/http_torokiki_api.pl';

sub actions::create_response_to_content($)
{
	$eml_data = $_[0];

	
	if ( $eml_data{api_obj} )
	{
		return &comms::send_mailserv_obj_to_torokiki_server( $eml_data{api_obj} );
	}
	else
	{
		return (undef, "\$eml_data{api_obj} not filled out.");
	}
}


1;

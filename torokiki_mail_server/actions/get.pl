# Retrieve some content from the torokiki website.
#
# Rob Ramsay 17:56  7 Sep 2010

use strict;

require 'send/send_email.pl';


sub actions::get_content($)
{
	my $eml_data = $_[0];


	unless ( $eml_data->{get_url} )
	{
		return (undef, "\$eml_data->{get_url} not filled out.");
	}


	my ($err, $rtn) = &comms::get_content_from_torokiki_server( $eml_data->{get_url} );
	
	if ($err) 
	{
		&send::send_get_succeeded_reply($eml_data);
		return 1;
	}
	else
	{ 
		&send::send_get_failed_reply($eml_data);
		return (undef, "$rtn"); 
	}
}


1;

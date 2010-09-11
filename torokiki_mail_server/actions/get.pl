# Retrieve some content from the torokiki website.
#
# Rob Ramsay 17:56  7 Sep 2010

use strict;


sub actions::get_content($)
{
	my $eml_data = $_[0];


	if ( $eml_data->{get_url} )
	{
		return &comms::get_content_from_torokiki_server( $eml_data->{get_url} );
	}
	else
	{
		return (undef, "\$eml_data->{get_url} not filled out.");
	}
}


1;

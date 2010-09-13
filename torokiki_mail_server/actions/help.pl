#
#
#

use strict;


sub actions::send_help($)
{
	my $eml_data = $_[0];


	&comms::send_help_reply($eml_data);
	return 1;
}


1;

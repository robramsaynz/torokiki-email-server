#
#
#

use strict;

require 'send/send_emails.pl';


sub actions::send_help($)
{
	my $eml_data = $_[0];


	&send::send_help_reply($eml_data);
	return 1;
}


1;

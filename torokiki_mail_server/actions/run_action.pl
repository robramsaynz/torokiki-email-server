# Run an action (assumes the email has been confirmed as valid torokiki one).
#
# Rob Ramsay 22:27 29 Aug 2010

use strict;

require 'actions/create_response_to.pl';
require 'actions/get.pl';
require 'actions/help.pl';
require 'parse_email/misc_parsing.pl';


sub actions::run_action($)
{
	my $eml_data = $_[0];


	# The help message has different syntax to the rest of the system
	if ( &parse_email::is_help_message($eml_data->{eml_mime}) )
	{ 
		return &actions::send_help($eml_data);
	}


    $_ = $eml_data->{eml_mime}->header("Subject");

	if ( /^get:/i )
	{ 
		my ($rtn, $msg) = &actions::get_content($eml_data);

		unless ($rtn)
		{
			warn "Error running 'get' action: $msg\n";
			return undef;
		}

		return 1;
	}
	elsif ( /^create-response-to:/i )
	{ 
		my ($rtn, $msg) = &actions::create_response_to_content($eml_data);

		unless ($rtn)
		{
			warn "Error running 'create-response-to' action: $msg\n";
			return undef;
		}

		return 1;
	}
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 

}


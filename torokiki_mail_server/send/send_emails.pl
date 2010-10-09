# 
# Functions that send emails of different kinds # (text/html/attachement/...)
#
# Rob Ramsay 13:36  9 Oct 2010

use strict;

use Email::MIME;

require 'send/create_response_to_reply.pl';
require 'send/get_reply.pl';
require 'send/help_reply.pl';
require 'send/invalid_mail_reply.pl';
require 'send/generate_emails.pl';


sub send::send_text_email($$$)
{
 	my $eml_mime = &send::create_text_email(@_);

	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_text_and_file_attach_email($$$$)
{
    my $eml_attach  = &send::create_text_and_file_attach_email(@_);

	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_text_and_base64_attach_email($$$$)
{
	my $eml_mime = &send::create_text_and_base64_attach_email(@_);
	
	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_html_email($$$)
{
	my $eml_mime = &send::create_html_email(@_);

	return &send::send_email_mime_obj($eml_mime);
}



sub send::send_email_mime_obj($)
{
    my $eml_mime = $_[0];	# shoud be a ref to an Email::MIME object.


	my $rtn;

	$rtn = open MSMTP, "| msmtp --read-recipients -C send/msmtp.torokiki.conf";
	unless ($rtn)
	{ 
		warn "Error. Can't fork msmtp: $!\n"; 
		return undef;
	}

	print MSMTP $eml_mime->as_string;

	$rtn = close MSMTP;
	unless ($rtn)
	{ 
		warn "Error closing msmtp pipe: $!\n";
		if ($? & 128)
		{
			 warn "msmtp exited with signal: ".($? & 127)."\n";
		}
		warn "msmtp returned: ".($? >> 8).">\n";

		# Keep a record of fails, just in case. 
		&stash::stash_failed_send($eml_mime->as_string);

		return undef;
	}

	return 1;
}


1;

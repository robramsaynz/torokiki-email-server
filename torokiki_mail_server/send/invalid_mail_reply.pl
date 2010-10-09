
use IO::All;


# Note that this takes eml_mime, whereas the other similar fn's take eml_data.
sub send::send_invalid_mail_reply($)
{
	my $eml_mime = $_[0];


	my $filename = "send/email_reply_text/invalid_mail_reply.txt";
	my $file_text = io($filename)->all;

	unless (defined $file_text)
	{ 
		warn "send::send_invalid_mail_reply(): Couldn't read reply template. Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_email(
					$eml_mime->header(From),
					"error: 'Invalid email format'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_invalid_mail_reply(): Email send failed.\n";
		return undef;
	}

	return $rtn;
}


1;


use IO::All;


sub send::send_help_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "send/email_reply_text/help_reply.html";
	my $file_text = io($filename)->all;

	unless (defined $file_text)
	{ 
		warn "send::send_help_reply(): Couldn't read reply template. Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_html_email(
					$eml_mime->header(From),
					"msg: 'Torokiki Email Gateway Help'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_help_reply(): Email send failed.\n";
		return undef;
	}

	return $rtn;
}


1;


use IO::All;


sub send::send_get_succeeded_reply($$)
{
	my $eml_data = $_[0];
	my $api_obj = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "send/email_reply_text/get_succeeded_reply.txt";
	my $file_text = io($filename)->all;

	unless (defined $file_text)
	{ 
		warn "send::send_get_succeeded_reply(): Couldn't read reply template. Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_and_base64_attach_email(
					$eml_mime->header(From),
					"msg: 'get succeeded'",
					$file_text,
					$api_obj->{Attachment}->{name},
					$api_obj->{Attachment}->{data},
				);

	unless ($rtn)
	{ 
		warn "send::send_get_succeeded_reply(): Email send failed.\n";
		return undef;
	}

	return $rtn;
}


sub send::send_get_failed_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "send/email_reply_text/get_failed_reply.txt";
	my $file_text = io($filename)->all;

	unless (defined $file_text)
	{ 
		warn "send::send_get_failed_reply(): Couldn't read reply template. Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_email(	
					$eml_mime->header(From),
					"error: 'get failed'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_get_failed_reply(): Email send failed.\n";
		return undef;
	}

	return $rtn;
}


1;

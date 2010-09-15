

sub send::send_create_response_to_succeeded_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "send/email_reply_text/create_response_to_succeeded_reply.txt";
	my $file_text = &send::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "send::send_create_response_to_succeeded_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_email(
					$eml_mime->header(From),
					"msg: 'create-response-to succeeded'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_create_response_to_succeeded_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}


sub send::send_create_response_to_falied_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "send/email_reply_text/create_response_to_failed_reply.txt";
	my $file_text = &send::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "send::send_create_response_to_falied_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_email(
					$eml_mime->header(From),
					"error: 'create-response-to failed'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_create_response_to_falied_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}


1;

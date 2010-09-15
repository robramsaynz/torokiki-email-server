

sub send::send_get_succeeded_reply($$)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "send/email_reply_text/get_succeeded_reply.txt";
	my $file_text = &send::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "send::send_get_succeeded_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_email(
					$eml_mime->header(From),
					"msg: 'get succeeded'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_get_succeeded_reply(): Email not sent.\n";
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
	my $file_text = &send::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "send::send_get_failed_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&send::send_text_email(	
					$eml_mime->header(From),
					"error: 'get failed'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "send::send_get_failed_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}


1;

#
#
#

use Email::MIME::Creator;


# Note that this takes eml_mime, whereas the the other fn's tak eml_data.
sub comms::send_invalid_mail_reply($)
{
	my $eml_mime = $_[0];


	my $filename = "comms/email_reply_text/invalid_mail_reply.txt";
	my $file_text = &comms::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "comms::send_invalid_mail_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&comms::send_text_email(
					$eml_mime->header(From),
					"error: 'Invalid email format'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "comms::send_invalid_mail_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}


sub comms::send_help_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "comms/email_reply_text/help_reply.txt";
	my $file_text = &comms::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "comms::send_help_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&comms::send_text_email(
					$eml_mime->header(From),
					"msg: 'Torokiki Email Gateway Help'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "comms::send_help_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}


sub comms::send_get_succeeded_reply($$)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "comms/email_reply_text/get_succeeded_reply.txt";
	my $file_text = &comms::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "comms::send_get_succeeded_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&comms::send_text_email(
					$eml_mime->header(From),
					"msg: 'get succeeded'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "comms::send_get_succeeded_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}

sub comms::send_get_failed_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "comms/email_reply_text/get_failed_reply.txt";
	my $file_text = &comms::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "comms::send_get_failed_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&comms::send_text_email(	
					$eml_mime->header(From),
					"error: 'get failed'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "comms::send_get_failed_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}

sub comms::send_create_response_to_succeeded_reply($$)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "comms/email_reply_text/create_response_to_succeeded_reply.txt";
	my $file_text = &comms::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "comms::send_create_response_to_succeeded_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&comms::send_text_email(
					$eml_mime->header(From),
					"msg: 'create-response-to succeeded'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "comms::send_create_response_to_succeeded_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}

sub comms::send_create_response_to_falied_reply($)
{
	my $eml_data = $_[0];
	my $eml_mime = $eml_data->{eml_mime};
	my $get_url = $eml_data->{get_url};


	my $filename = "comms/email_reply_text/create_response_to_failed_reply.txt";
	my $file_text = &comms::slurp_file($filename);

	unless ($file_text)
	{ 
		warn "comms::send_create_response_to_falied_reply(): Email not sent.\n";
		return undef;
	 }

	my $rtn = 	&comms::send_text_email(
					$eml_mime->header(From),
					"error: 'create-response-to failed'",
					$file_text
				);

	unless ($rtn)
	{ 
		warn "comms::send_create_response_to_falied_reply(): Email not sent.\n";
		return undef;
	}

	return $rtn;
}


sub comms::slurp_file($)
{
	my $filename = $_[0];

	my $file_text;


	open FILE, "<", $filename 
			or warn "Error. Couldn't open $fil_name.\n"
			and return undef;
	{
	local $/ = undef;   # read all of file
	$file_text = <FILE>;
	}
	close FILE;

	return $file_text;
}


sub comms::send_text_email()
{
	my $to		= $_[0];
	my $subj	= $_[1];
	my $text	= $_[2];


    my $eml_mime = Email::MIME->create(
        header => [ 
#				From => 'casey@geeknest.com',
				To => $to,
				Subject => $subj,
		],
		body => $text,
	);

	return &comm::send_email_mime_obj($eml_mime);
}




sub comm::send_email_mime_obj($)
{
    my $eml_mime = $_[0];	# shoud be a ref to an Email::MIME object.

# --------------------------------
warn "---- Sending reply emails disabled. ----\n";
warn "---- email: ----\n";
warn $eml_mime->as_string;
warn "--------------------------------\n";

return 1;

if (undef){
# --------------------------------
	my $rtn;

	$rtn = open MSMTP, "| msmtp --read-recipients -C msmtp.torokiki.conf";
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
# --------------------------------
}
# --------------------------------

	return 1;
}


1;

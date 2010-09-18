#
#
#

use Email::MIME::Creator;

require 'send/create_response_to_reply.pl';
require 'send/get_reply.pl';
require 'send/help_reply.pl';
require 'send/invalid_mail_reply.pl';


sub send::slurp_file($)
{
	my $filename = $_[0];

	my $file_text;


	open FILE, "<", $filename 
			or warn "Error. Couldn't open $filename.\n"
			and return undef;
	{
	local $/ = undef;   # read all of file
	$file_text = <FILE>;
	}
	close FILE;

	return $file_text;
}


sub send::send_text_email($$$)
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

	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_text_and_attach_email($$$$)
{
	my $to		= $_[0];
	my $subj	= $_[1];
	my $text	= $_[2];
	my $attach	= $_[3];


    my $eml_text = Email::MIME->create(
		body => $text,
	);

    my $eml_attach = Email::MIME->create(
		body => $text,
	);

    my $eml_mime = Email::MIME->create(
        header => [ 
#				From => 'casey@geeknest.com',
				To => $to,
				Subject => $subj,
		],
		parts => ( $eml_text, $eml_attach )
	);

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

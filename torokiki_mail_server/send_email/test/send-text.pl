#!/usr/bin/perl
#
# Test sending of text using Email::MIME.
#
# Doesn't actually test torokiki server code.
#
# Rob Ramsay 13:33  9 Oct 2010

use Email::MIME;
use IO::All;


&main();

sub main()
{

    my $email = Email::MIME->create(
        header => [ 
#				From => 'casey@geeknest.com',
				To => 'robert.ramsay.nz@gmail.com',
				Subject => 'test text', 
		],
        body  => "Wa gwan?"
    );

#	open MSMTP, "| cat -" or die "can't fork msmtp: $!";
	my $rtn;
	$rtn = open MSMTP, "| msmtp --read-recipients -C msmtp.torokiki.conf";
	unless ($rtn)
		{ die "can't fork msmtp: $!\n"; }

	print MSMTP $email->as_string;

	$rtn = close MSMTP;
	unless ($rtn)
		{ warn "error closing msmtp pipe: <$!> <$?>\n";}


#	my $msmtp_file = "tmp_email.eml";
#	open MSMTP, ">", $msmtp_file or die "can't open tmp file for outgoing email: $!";
#	print MSMTP $email->as_string;
#	close MSMTP or die "error closing tmp file for outgoing email: $! $?";

#	system "cat $msmtp_file | msmtp --read-recipients -C msmtp.torokiki.conf";

#	unlink $msmtp_file;

	return 0;
}


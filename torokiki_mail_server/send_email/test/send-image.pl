#!/usr/bin/perl
#
# Test sending of attachements using Email::MIME.
#
# Doesn't actually test torokiki server code.
#
# Rob Ramsay 13:33  9 Oct 2010

use Email::MIME;
use IO::All;


&main();

sub main()
{

	 # multipart message
	 my @parts = (
		 Email::MIME->create(
			 attributes => {
				 filename     => "1.jpeg",
				 content_type => "image/jpeg",
				 encoding     => "quoted-printable",
				 name         => "1.jpeg",
			 },
			 body => io( "1.jpeg" )->all,
		 ),
		 Email::MIME->create(
			 attributes => {
				 content_type => "text/plain",
				 disposition  => "attachment",
				 charset      => "utf8",
			 },
			 body => "Here's your image",
		 ),
	 );


    my $email = Email::MIME->create(
        header => [ 
#				From => 'casey@geeknest.com',
				To => 'Robert Ramsay <robert.ramsay.nz@gmail.com>',
				Subject => 'test image',
		],
        parts  => [ @parts ],
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

	
	return 0;
}



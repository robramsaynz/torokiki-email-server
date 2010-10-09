#!/usr/bin/perl
#
# Test by  sending of base64 strings by sending a pre-encoded base64 image.

use strict;

use IO::All;
use MIME::Base64;
use Email::MIME;

require 'send/send_email.pl';


sub main()
{

	my ($filename, $base64_txt) = &return_vars();

	my $mime_obj = &send::send_text_and_base64_attach_email(
						'hello@world',
						'wa gwan',
						"I have text",
						$filename, 
						$base64_txt
					);

	print STDERR "\n";
	print STDERR "Note: 'Subroutine main::io redefined'\n";
	print STDERR "This warning isn't really a error and can be ignored.it's because \n";
	print STDERR "'use IO::All' is being called twice (via require).\n";
	print STDERR "In theory this shouldn't happen.\n";
	print STDERR "\n";

	print $mime_obj->as_string();

	return 0;
}


sub return_vars()
{
	my $file_name = "send/test/1.jpeg";


	my $file_txt = io( $file_name )->all;
	my $b64_txt = MIME::Base64::encode($file_txt);

	return ($file_name, $b64_txt);
}


&main();

#!/usr/bin/perl
#
# Test that send/generate_emails.pl sends base64 strings.
# Creates an image/text email and prints results.
#
# Rob Ramsay 13:33  9 Oct 2010

use strict;

use IO::All;
use MIME::Base64;
use Email::MIME;

require 'send/generate_emails.pl';


sub main()
{

	my ($filename, $base64_txt) = &return_vars();

	my $mime_obj = &send::create_text_and_base64_attach_email(
						'hello@world',
						'wa gwan',
						"I have text",
						$filename, 
						$base64_txt
					);


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

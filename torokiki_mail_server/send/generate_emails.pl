#
# Functions that generate mime objects of different types 
# (text/html/attachement/...) suitable for sending as emails 
#
# Rob Ramsay 13:36  9 Oct 2010

use strict;

use Email::MIME;
use MIME::Types;
use File::Spec;
use IO::All;

require 'send/misc_generate_mime.pl';


sub send::create_text_email($$$)
{
	my $to		= $_[0];
	my $subj	= $_[1];
	my $text	= $_[2];


    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						attributes => {
							disposition  => "inline"
						},
						body => $text,
					);

	return $eml_mime;
}


sub send::create_text_and_file_attach_email($$$$)
{
	my $to			= $_[0];
	my $subj		= $_[1];
	my $text		= $_[2];
	my $fileloc		= $_[3];


    my $eml_text =	Email::MIME->create(
						attributes => {
							disposition  => "inline"
						},
						body => $text
					);

    my $eml_attach = &send::mime_from_file($fileloc);


    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						attributes => {
							disposition  => "inline"
						},
						parts => [ 
							$eml_text, 
							$eml_attach 
						],
					);

	return $eml_mime;
}


sub send::create_text_and_base64_attach_email($$$$)
{

	my $to			= $_[0];
	my $subj		= $_[1];
	my $text		= $_[2];
	my $filename	= $_[3];
	my $file_data	= $_[4];


    my $eml_text =	Email::MIME->create(
						attributes => {
							disposition  => "inline"
						},
						body => $text
					);

    my $eml_attach = &send::mime_from_base64_string($filename, $file_data);


    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						attributes => {
							disposition  => "inline"
						},
						parts => [
							$eml_text, 
							$eml_attach,
						],
					);

	return $eml_mime;
}


sub send::create_html_email($$$)
{
	my $to			= $_[0];
	my $subj		= $_[1];
	my $html_text	= $_[2];


    my $html_part =	Email::MIME->create(
						attributes => {
							content_type => "text/html",
							disposition  => "inline",
							charset	  => "utf8",
							#encoding	 => "quoted-printable",
						},
						body => $html_text,
					);

    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						attributes => {
							disposition  => "inline"
						},
						parts => [ $html_part ],
					);

	return $eml_mime;
}


1;

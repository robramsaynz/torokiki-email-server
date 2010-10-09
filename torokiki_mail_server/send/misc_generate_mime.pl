#
#
#

use strict;

use Email::MIME::Creator;
use MIME::Types;
use File::Spec;
use IO::All;


sub send::mime_from_base64_string()
{
	my $filename = $_[0];
	my $base64_txt = $_[1];


	# Lookup filename from filename extension.
	my ($mime_type, $encoding) = MIME::Types::by_suffix($filename);

	my $eml_attach =	Email::MIME->create(
							attributes => {
								filename     => $filename,
								name         => $filename,
								content_type => $mime_type,
								disposition  => "attachment",
								#charset      => "utf8"
								#encoding     => "base64",
								encoding     => $encoding,
							},
							body => MIME::Base64::decode($base64_txt),
						);

	return $eml_attach;
}



sub send::mime_from_file()
{
	my $fileloc = $_[0];

	my (undef, $dirname, $filename) = File::Spec->splitpath($fileloc);


	# ??Should check filename exists here.
	my $content_type = `file -bi "$dirname/$filename"`;

	my $eml_attach = 	Email::MIME->create(
							attributes => {
								filename     => $filename,
								#name         => $filename,
								content_type => $content_type,
								disposition  => "attachment",
								#charset      => "US-ASCII"
								encoding     => "base64",
							},
							body => io( $filename )->all,
						);

	return $eml_attach;
}


1;

#
#
#

use strict;

use Email::MIME::Creator;
use MIME::Types;
use File::Spec;
use IO::All;

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


    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						body => $text,
					);

	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_text_and_file_attach_email($$$$)
{
	my $to			= $_[0];
	my $subj		= $_[1];
	my $text		= $_[2];
	my $fileloc		= $_[3];


    my $eml_text =	Email::MIME->create(
						attributes => {
							disposition  => "inline"
						},
						body => $text,
					);

    my $eml_attach = &send::mime_from_file($fileloc);


    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						parts => [ 
							$eml_text, 
							$eml_attach,
						],
					);

	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_text_and_base64_attach_email($$$$)
{

	my $to			= $_[0];
	my $subj		= $_[1];
	my $text		= $_[2];
	my $filename	= $_[3];
	my $file_data	= $_[4];


    my $eml_text =	Email::MIME->create(body => $text);

    my $eml_attach = &send::mime_from_base64_string($filename, $file_data);


    my $eml_mime =	Email::MIME->create(
						header => [ 
								#From => 'casey@geeknest.com',
								To => $to,
								Subject => $subj,
						],
						parts => [
							$eml_text, 
							$eml_attach,
						],
					);

	return $eml_mime;
#	return &send::send_email_mime_obj($eml_mime);
}


sub send::send_html_email($$$)
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
						parts => [ $html_part ],
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


#use MIME::Base64;
#use Cwd;
#sub send::mime_from_base64_string()
#{
#	my $base64_txt = $_[0];
#	my $filename = $_[1];
#
#
#	my $email_attach;
#
#	my $orig_dir = getcwd();
#	my $tmp_dir = "/tmp/$PID.sem_email.pl/";
#
#	mkdir $tmp_dir;
#	chdir $tmp_dir;
#
#	open FILE, ">", $filename
#	or warn "Error. Couldn't open $filename.\n"
#	and return undef;
#	print FILE MIME::Base64::decode($base64_txt);
#	close FILE;
#
#	$email_attach = &send::mime_from_file($filename);
#
#	chdir $orig_dir;
#
#	unlink "$tmp_dir/$filename";
#	rmdir $tmp_dir;
#
#	return $email_attach;
#}


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

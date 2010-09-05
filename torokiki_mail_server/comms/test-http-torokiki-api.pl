#!/usr/bin/perl
#
# Test com/http-torokiki-api.pm by creating an mailserv_obj
# and trying to send this to the torokiki server with 
# 
# Rob Ramsay 14:23 20 Jul 2010


use comms::http_torokiki_api;


&main();

sub return_regular_stash_object()
{

	# Data pulled from stash/00000004.meta
	my $obj = 
	{
	   "header_info" => {
		  "Subject" => "image 5",
		  "Message-ID" => "<20100511042738.GE11461@stimpy>",
		  "To" => "time.capsule.testing@gmail.com",
		  "Date" => "Tue, 11 May 2010 16:27:38 +1200",
		  "From" => "robert.ramsay.nz@gmail.com"
	   },
	   "mime_info_ref" => {
		  "splitup" => {
			 "filename" => "5.jpeg",
			 "Content-Type" => "image/jpeg",
			 "Content-Disposition" => "attachment",
			 "Content-Transfer-Encoding" => "base64"
		  },
		  "full" => {
			 "Content-Type" => "image/jpeg",
			 "Content-Disposition" => "attachment; filename=\"5.jpeg\"",
			 "Content-Transfer-Encoding" => "base64"
		  }
	   },
	   "db_info" => {
		  "data_file" => "./stash/00000004.dat",
		  "meta_file" => "./stash/00000004.meta",
		  "unique_id" => "00000004"
	   },
	   "tag_info" => {
		  "action" => "add-content",
		  "type" => "image",
		  "tag" => "testing",
		  "description" => "test image 5"
	   }
	};

	return $obj;
}


sub main()
{

	$mailserv_obj = &return_regular_stash_object();

	# !! dirty hack caused by mailserv_obj and api_obj being too 
	# !! different.
	# !! This should be replaced when I fix up my mailserv_obj to reflect the torokiki api.
	$mailserv_obj->{tag_info}->{InspiredBy} = "http://torokiki.net/image/123/response/456";

	my ($err, $val) = &send_mailserv_obj_to_torokiki_server($mailserv_obj);

	if ($err) 
	{
		print "Success!\n";
		print "New location: $val\n";
	}
	else 
	{
		print "Failure!\n";
	}

	return 0;
}

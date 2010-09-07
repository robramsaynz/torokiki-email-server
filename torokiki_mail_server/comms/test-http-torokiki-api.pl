#!/usr/bin/perl
#
# Test com/http-torokiki-api.pm by creating an mailserv_obj
# and trying to send this to the torokiki server with 
# 
# Rob Ramsay 14:23 20 Jul 2010


use comms::http_torokiki_api;


&main();

sub return_api_object()
{

	my $api_obj = {
			'Submitter' => 'sam@silverstripe.com',
			'Text' => 'This is a text response',
			'Tags' => [ 'fart', 'bums', 'old-things' ],
			'InspiredBy' => 'http://torokiki.net/image/123/response/456',
			'Objective'=> 'What do people wear?',
			'Location' => '123 Some Street, Suburb',
			'Attachment' => {
				'name' => 'my-file.png',
				'data' => 'AJKAHLKUSHDJKLFHJKDLSHFGKJSDLKSFHSDFKLJSDHKFLHDJKSLFHKSDLFSD',
			},
			'APICaller' => {
				'service' => 'Robs email thing',
				'id' => '00000A',
			}
		};

	return $api_obj;
}


sub main()
{

	my $mailserv_obj = &return_api_object();

	my ($err, $val) = &comms::send_api_obj_to_torokiki_server($mailserv_obj);

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

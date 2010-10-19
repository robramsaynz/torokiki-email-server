# Creates an api-data-struct from the email.
# The format of this struct is specified at: 
#   http://torokiki.net/docs/api.md
#
# Rob Ramsay 00:33  3 Sep 2010


use strict;

use JSON::PP;
use MIME::Base64;

#require 'parse_email/mime_walking.pl';

#{
#    'Submitter' : 'sam@silverstripe.com',
#    'Text' : 'This is a text response',
#    'Tags' : [ 'fart', 'bums', 'old-things' ],
#    'InspiredBy' : 'http://torokiki.net/image/123/response/456',
#    'Objective': 'What do people wear?',
#    'Location' : '123 Some Street, Suburb',
#    'Attachment': {
#        'name' : 'my-file.png',
#        'data' : 'AJKAHLKUSHDJKLFHJKDLSHFGKJSDLKSFHSDFKLJSDHKFLHDJKSLFHKSDLFSD',
#    },
#    'APICaller' : {
#        'service' : 'Robs email thing',
#        'id' : '00000A',
#    }
#}


sub parse_email::get_api_obj_from_email($)
{
    my $eml_mime = $_[0];

	my $api_obj = {};


	my $text = &parse_email::get_email_txt($eml_mime);
	my $tags = &parse_email::tag_value_pairs_to_hash($text);


	# ??: Should check for and remove: remove me <save@me>
	$api_obj->{Submitter} = $eml_mime->header("From");

    $eml_mime->header("Subject") =~ m/^[\w-]+:\s*'(\S+)'\s*$/;
	$api_obj->{InspiredBy} = $1;


	# Save data from (case insensitive) tags.
	for (keys %$tags)
	{
		if (/tags/i)
			{ $api_obj->{Tags} = $tags->{$_}; }
		elsif (/objective/i)
			{ $api_obj->{Objective} = $tags->{$_}; }
		elsif (/location/i)
			{ $api_obj->{Location} = $tags->{$_}; }
		elsif (/text/i)
			{ $api_obj->{Text} = $tags->{$_}; }
	}

	
	# Get the first attachment.	
	my $mime_obj = &parse_email::return_mime_attach_num($eml_mime, 1);

	my $attach_name = $mime_obj->filename();	
	# Note that this will create an imaginary  name for the file 
	# if one isn't supplied

	my $attach_bin_data = $mime_obj->body();
	my $attach_b64_data = MIME::Base64::encode($attach_bin_data);
	$attach_b64_data =~ s/\n//g;

	$api_obj->{Attachment}->{name} = $attach_name;
    $api_obj->{Attachment}->{data} = $attach_b64_data;


	# Identify yourself
    $api_obj->{APICaller}->{service} = "Torokiki Mailserver ".TOROKIKI_SERVER_VERS;
	# ??: Not filled out at the moment (may need to be in the future): 
    $api_obj->{APICaller}->{id} = "00000A";


	return $api_obj;
}


sub parse_email::get_api_obj_from_string($)
{
	my $string = $_[0];


	my $api_obj = JSON::PP->new->utf8->decode($string);

	return $api_obj;
}


1;

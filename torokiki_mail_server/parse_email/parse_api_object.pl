# Creates an api-data-struct from the email.
# The format of this struct is specified at: 
#   http://torokiki.net/docs/api.md
#
# Rob Ramsay 00:33  3 Sep 2010


# !! this const is also declared in other files (ie data-dupl.)
use constant TOROKIKI_SERVER_VERS => "0.1";

#{
#    'Submitter' : 'sam@silverstripe.com',
#    'Text' : 'This is a text response',
#    'Tags' : [ 'fart', 'bums', 'old-things' ],
#    'InspiredBy' : 'http://torokiki.net/image/123/response/456',
#    'Objective: 'What do people wear?',
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


	my $text = &get_email_txt($eml_mime);
	my %tags = &tag_value_pairs_to_hash($text);

	# ??: Should check for and remove: remove me <save@me>
	$api_obj->{Submitter} = $tags->header("From");

    $eml_mime->header("Subject") =~ m/^[\w-]+:\s*'(\S+)'\s*$/;
	$api_obj->{InspiredBy} = $1;

	# Save data from (case insensitive) tags.
	for (keys %tags)
	{
		if (/tags/i)
			{ $api_obj->{Tags} = $tags{$_}; }
		elsif (/objective/i)
			{ $api_obj->{Objective} = $tags{$_}; }
		elsif (/location/i)
			{ $api_obj->{Location} = $tags{$_}; }
		elsif (/text/i)
			{ $api_obj->{Text} = $tags{$_}; }
	}
	
	# Get the first attachment.	
	my $mime_obj = &return_mime_attach_num($eml_mime, 1);
#   $api_obj->{Attachment}->{name} = $mime_obj->header("name") || my $mime_obj->header("name")
    $api_obj->{Attachment}->{data} = $mime_obj->body();

    $api_obj->{APICaller}->{service} = "Torokiki Mailserver ".TOROKIKI_SERVER_VERS;
	# ??: Not filled out at the moment (may need to be in the future): 
    $api_obj->{APICaller}->{id} = undef;

	return $api_obj;
}


1;
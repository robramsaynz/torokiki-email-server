# Functions to check for valid Torokiki content URLs. 
# These don't check whether the content exists, just that the location string 
# (roughly) make sense.
#
# Rob Ramsay 21:02  7 Sep 2010


#
# Content url's are the links to images/text/... on the Torokiki server that 
# this sever is manipulating.
#
#
# This checks the validity of locations such as,
#
#	http://torokiki.net/image/123/response
# 	http://torokiki.net/image/123/response/456/
#
# Note that a trailing '/' is optional.
#
#
# Seed-content is curated images/content added by the Torokiki 
# website currators. This can then be responded to by users, creating 
# response-content. 
#
#	http://torokiki.net/image/123/response
#
# Response-content can then be responded to with,
#
# 	http://torokiki.net/image/123/response/456
#
# and so on.  
#
# Thus the response-content part (/456) is optional.


sub validate_email::check_torokiki_object_locations($)
{
	my $content_url = $_[0];	# A URL string.


	# ie http://(torokiki.net(/image/123/response/456)/?
	# note:
	#	- any "www." supplied is removed.
	# 	- any trailing '/' is trimmed.
	$content_url =~ m{http://(www.)?([^/]+)(.+)/?};
	my $server = "http://$2"; 	
	my $content_location = $3; 	

	if ($server ne "http://torokiki.net")
	{
		warn	"Error checking content-url: $content_url\n".
				"Invalid server: $server\n";
		return undef;
	}

	# ie /(image)/(123)/(response)(/456)?
	# note: the response-content (456) is optional.
	$content_location =~ m{/([^/]+)/([^/]+)/([^/]+)(/[^/]+)?};
	my $seed_cont_type = $1;
	my $seed_cont_id = $2;
	my $response = $3;
	my $response_cont_id = $4;


	# ie image
	# Note we only take image content types at this stage.
	if ($seed_cont_type ne "image")
	{
		warn	"Error checking content-url: $content_url\n".
				"Invalid seed content type: $seed_cont_type\n";
		return undef;
	}

#	# ie 123
#	if ($seed_cont_id ne "NOTCHECKED")
#	{
#		warn	"Error checking content-url: $content_url\n".
#				"Invalid seed_cont_id: $seed_cont_id\n";
#		return undef;
#	}

	# ie response
	if ($response ne "response")
	{
		warn	"Error checking content-url: $content_url\n".
				"this should be 'response': $response\n";
		return undef;
	}

#	# ie 456
#	if ($response_cont_id ne undef and $response_cont_id ne "NOTCHECKED")
#	{
#		warn	"Error checking content-url: $content_url\n".
#				"Invalid response content id: $response_cont_id\n";
#		return undef;
#	}

	return 1;
}



1;

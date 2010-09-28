# comms/http_torokiki_api.pl
#
# Talks to a torokiki server using the api specified at 
# http://torokiki.net/docs/api.md
#
# api_obj:	the format of the JSON hierarch specified by 
#			the api (not as a string).
#
# Rob Ramsay 14:02 20 Jul 2010

use strict;

use LWP::UserAgent;
#use HTTP::Request;
use HTTP::Request::Common;
#use HTTP::Response;
use JSON::PP;
use MIME::Base64;
#use MIME::Base65[]()::Per; # (Pure Perl version)



sub comms::send_api_obj_to_torokiki_server($)
{
	my $api_obj = $_[0];


	# For more info on what is being extracted here, read the file:
	# 	validate_email/check_content_location.pl
	my $content_url = $api_obj->{InspiredBy}; 

	# ie (http://torokiki.net)(/image/123/response/456)/?
	$content_url =~ m{http://(www.)?([^/]+)(.+)/?};
	my $server = "http://$2";
	my $content_location = $3;

	# ie (/image/123/response)(/456)?
	$content_location =~ m{(/[^/]+/[^/]+/[^/]+)(/[^/]+)?/?};
	my $seed_content = $1;
	#my $opt_response_content = $2;


	# Key to let this access the torokiki website.
	my $x_api_key = "48d24e623c6dbbcd1175508727465a8c";



	# Send to server via http.
	#use HTTP::Request::Common;
	# !! would there be advantages to moving the object decl
	# !! to a setup fn?
	my $user_agent = LWP::UserAgent->new();

# --------------------------------
warn "---- Actual content setting disabled. ----\n";
	# Convert to a JSON string.
	my $api_obj_as_txt = JSON::PP->new->allow_nonref->utf8->pretty->encode($api_obj);
warn "---- \$api_obj_as_txt ----\n";
warn "$api_obj_as_txt\n";
warn "--------------------------------\n";

my $response;
return ( 1, "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" );

if (undef){
# --------------------------------

 	my $request = HTTP::Request->new(POST => "$server$seed_content");
	#$request->header("Host" => "torokiki.net");
	$request->header("Content-type" => "application/json");
	$request->header("X-API-Key" => "$x_api_key");
	$request->content($api_obj_as_txt);

#	print $request->as_string() . "\n";

	my $response = $user_agent->request($request);
# --------------------------------
}
# --------------------------------

	my $code = $response->code();
	if ($code =~ /301/)
	{
		return ( 1, $response->header("Location") );
	}
	elsif ($code =~ /5../ or $code =~ /4../)
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http POST request to $server$content_location\n".
				"Server returned error: ".$response->status_line()."\n";
		return (undef, "http error");
	}
	else
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http POST request to $server$content_location\n".
				"Server returned error: ".$response->status_line()."\n" .
				"In theory only 301/4xx/5xx errors should be returned by a torokiki server!\n";
		return (undef, "unknown http error");
	}
}


# Returns api_object.
sub comms::get_content_from_torokiki_server()
{
	# ie http://torokiki.net/image/123/response/456
	my $content_url = $_[0];


	# ie (http://torokiki.net)(/image/123/response/456)/?
	$content_url =~ m{http://(www.)?([^/]+)(.+)/?};
	my $server = "http://$2";
	my $content_location = $3;

	# Get object from server via http.
	#use HTTP::Request::Common;
	# !! would there be advantages to moving the object decl
	# !! to a setup fn?
	my $user_agent = LWP::UserAgent->new();

# --------------------------------
warn "---- Actual content getting disabled. ----\n";
warn "---- \$conent_url ----\n";
warn "$content_url\n";
warn "--------------------------------\n";

my $response;
return ( 1, "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" );

if (undef){
# --------------------------------
 	my $request = HTTP::Request->new(GET => "$content_url");
	$request->header("Accept" => "application/json");

#	print $request->as_string() . "\n";

	my $response = $user_agent->request($request);
# --------------------------------
}
# --------------------------------

	my $code = $response->code();
	if ($code =~ /200/)
	{
		return ( 1, $response->content() );
	}
	else
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http GET request to $server$content_location\n".
				"Expecting 200. Server returned error: ".$response->status_line();
		return (undef, "http error");
	}
}


1;

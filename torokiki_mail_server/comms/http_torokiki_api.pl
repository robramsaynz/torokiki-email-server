# comms/http_torokiki_api.pm 
#
# Talks to a torokiki server using the api specified at 
# http://torokiki.net/docs/api.md
#
# api_obj:	the format of the JSON hierarch specified by 
#			the api (not as a string).
#
# Rob Ramsay 14:02 20 Jul 2010


use LWP::UserAgent;
#use HTTP::Request;
use HTTP::Request::Common;
#use HTTP::Response;
use JSON::PP;
use MIME::Base64;
#use MIME::Base64::Per; # (Pure Perl version)


# !! this const is also declared in other files (ie data-dupl.)
use constant TOROKIKI_SERVER_VERS => "0.1";


sub comms::send_api_obj_to_torokiki_server($)
{
	my $api_obj = $_[0];


	# For more info on what is being extracted here, read the file:
	# 	validate_email/check_content_location.pl
	my $content_url = $api_obj->{InspiredBy}; 

	# ie (http://torokiki.net)(/image/123/response/456)/?
	$content_url =~ m{http://(www.)?([^/]+)(.+)/?};
	my $server = "http://$1";
	my $content_location = $2;

	# ie (/image/123/response)(/456)?
	$content_location =~ m{(/[^/]+/[^/]+/[^/]+)(/[^/]+)?/?};
	my $seed_content = $1;
	#my $opt_response_content = $2;


	# Key to let this access the torokiki website.
	my $x_api_key = "arandomX-API-Key";


warn ">1\n";
	# Convert to a JSON string.
	my $api_obj_as_txt = JSON::PP->new->allow_nonref->utf8->pretty->encode($api_obj);
warn "---- \$api_obj_as_txt ----\n";
warn "$api_obj_as_txt\n";
warn "--------------------------------\n";

	# Send to server via http.
	#use HTTP::Request::Common;
	# !! would there be advantages to moving the object decl
	# !! to a setup fn?
	$user_agent = LWP::UserAgent->new();
if (undef){
warn ">2\n";
	$response = $user_agent->request(
					POST "$server$seed_content",
					[
						#"POST /image/123/response HTTP/1.1"
						#"Host" => "torokiki.net"
						"Content-type" => "application/json",
						"X-API-Key" => "$x_api_key",
						Content => $api_obj_as_txt
					]
				);
}
warn ">3\n";
	my $code = $response->code();
	if ($code =~ /301/)
	{
		return ( 1, $response->header("Location") );
	}
	elsif ($code =~ /5??/ && $code =~ /4??/)
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http push request to $server$content_location\n".
				"Server returned error: ".$reponse->status_line()."\n";
		return (undef, "http error");
	}
	else
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http push request to $server$content_location\n".
				"Server returned error: ".$reponse->status_line()."\n" .
				"In theory only 301/4xx/5xx errors should be returned by a torokiki server!";
		return (undef, "unknown http error");
	}
}


# Returns api_object.
sub comms::get_content_from_torokiki_server()
{
	# ie http://torokiki.net/image/123/response/456
	my $content_url = $_[0];


	# Get object from server via http.
	#use HTTP::Request::Common;
	# !! would there be advantages to moving the object decl
	# !! to a setup fn?
	$user_agent = LWP::UserAgent->new();
if (undef){
	$response = $user_agent->request(
					GET "$content_url",
					[
						# GET http://torokiki.net/image/123/response/456 HTTP/1.1
						"Accept" => "application/json",
					]
				);
}

	my $code = $response->code();
	if ($code =~ /200/)
	{
		return ( 1, $response->content() );
	}
	else
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http get request to $server$content_location\n".
				"Expecting 200. Server returned error: ".$reponse->status_line();
		return (undef, "http error");
	}
}


1;

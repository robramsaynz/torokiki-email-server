# comms/http_torokiki_api.pm 
#
# Talks to a torokiki server using the api specified at 
# http://torokiki.net/docs/api.md
#
# api_obj:	the format of the JSON hierarch specified by 
#			the api (not as a string).
#
# mailserv_obj:	the internal format the email server uses
#				to store objects recieved via email.
#
# Rob Ramsay 14:02 20 Jul 2010


# ==== Package setup. ====

package comms::http_torokiki_api;

#use strict;
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK	= qw(
	send_mailserv_obj_to_torokiki_server
);

our @EXPORT		= qw(
	send_mailserv_obj_to_torokiki_server
	send_api_obj_to_torokiki_server
	get_content_from_torokiki_server

	convert_mailserv_obj_to_api_obj
);

our $VERSION=0.10;



# ==== Module starts here. ====

use LWP::UserAgent;
#use HTTP::Request;
use HTTP::Request::Common;
#use HTTP::Response;
use JSON::PP;
use MIME::Base64;
#use MIME::Base64::Per; # (Pure Perl version)


# !! this const is also declared in other files (ie data-dupl.)
use constant TOROKIKI_SERVER_VERS => "0.1";


sub send_mailserv_obj_to_torokiki_server($)
{
	my $mailserv_obj = $_[0];
print "I'm alive\n";

	my $api_obj = &convert_mailserv_obj_to_api_obj($mailserv_obj);
	return &send_api_obj_to_torokiki_server($api_obj);
}


sub convert_mailserv_obj_to_api_obj
{
	my $mailserv_obj = $_[0];


#{
#    'Submitter' : 'sam@silverstripe.com',
#    'Text' : 'This is a text response',
#    'Tags' : [ 'fart', 'bums', 'old-things' ],
#    'InspiredBy' : 'http://torokiki.net/image/123/response/456',
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


#	# Data pulled from stash/00000004.meta
#	my $obj = 
#	{
#	   "header_info" => {
#		  "Subject" => "image 5",
#		  "Message-ID" => "<20100511042738.GE11461@stimpy>",
#		  "To" => "time.capsule.testing@gmail.com",
#		  "Date" => "Tue, 11 May 2010 16:27:38 +1200",
#		  "From" => "robert.ramsay.nz@gmail.com"
#	   },
#	   "mime_info_ref" => {
#		  "splitup" => {
#			 "filename" => "\"5.jpeg\"",
#			 "Content-Type" => "image/jpeg",
#			 "Content-Disposition" => "attachment",
#			 "Content-Transfer-Encoding" => "base64"
#		  },
#		  "full" => {
#			 "Content-Type" => "image/jpeg",
#			 "Content-Disposition" => "attachment; filename=\"5.jpeg\"",
#			 "Content-Transfer-Encoding" => "base64"
#		  }
#	   },
#	   "db_info" => {
#		  "data_file" => "./stash/00000004.dat",
#		  "meta_file" => "./stash/00000004.meta",
#		  "unique_id" => "00000004"
#	   },
#	   "tag_info" => {
#		  "action" => "add-content",
#		  "type" => "image",
#		  "tag" => "testing",
#		  "description" => "test image 5"
#	   }
#	};


   	if ($mailserv_obj{tag_info}{type} ne "image" && $mailserv_obj{tag_info}{type} ne "Image")
	{
		return (undef, "I only save image objects and <$mailserv_obj{tag_info}{type}> was supplied");
	}

   	if ($mailserv_obj{tag_info}{InspiredBy} ne "image" && $mailserv_obj{tag_info}{inspiredby} ne "Image")
	{
		return (undef, "No InspiredBy tag! A torokiki object must be in response to an image."); 
	}
	
	# !! There should prob be more formalised checking for valid syntax, such as 
	# !! valid location, and valid InspiredBy.

	my $api_obj = 
	{
		'Submitter' 	=> $mailserv_obj{header_info}{From},
		'Text'			=> $mailserv_obj{tag_info}{description},
#    	'Tags' 			: [ 'fart', 'bums', 'old-things' ],
		'InspiredBy'	=> $mailserv_obj{tag_info}{InspiredBy} || $mailserv_obj{tag_info}{inspiredby};
						# ie 'http://torokiki.net/image/123/response/456',
		'Location'		=> $mailserv_obj{tag_info}{Location} || $mailserv_obj{tag_info}{location} || "";
						# ie '123 Some Street, Suburb',

		'Attachment' => {
			'name' => $mailserv_obj{mime_info_ref}{splitup}{filename},
#			'data' => 'AJKAHLKUSHDJKLFHJKDLSHFGKJSDLKSFHSDFKLJSDHKFLHDJKSLFHKSDLFSD',
		},
		'APICaller' => {
			'service'	=> "Torokiki Mailserver ".TOROKIKI_SERVER_VERS,
			'id' 		=> $mailserv_obj{db_info}{unique_id},
	};


	# Convert "fart bums old-things" to [ 'fart', 'bums', 'old-things' ]
	my $tags = $mailserv_obj{tag_info}{Tags} || $mailserv_obj{tag_info}{tags} || "";
	my @tags = split(/\s+/, $tags);
	$api_obj->{Tags} = \@tags;


	# Slurp the file
	my $file_txt;
	my $file_name = $mailserv_obj{db_info}{data_file};
	open FILE, "<", $file_name;
    {
    local $/ = undef;   # read all of file
    $file_txt = <FILE>;
    }
    close FILE;

	# Read data file into as base64 string.
	$api_obj->{Attachment}->{data} = encode_base64($file_txt);


	return (1 , $api_obj);
}


sub send_api_obj_to_torokiki_server($)
{
	my $api_obj = $_[0];

	# Settingsserver were connecting to 
	my %serv_sett; 

	# ie http://torokiki.net/image/123/response
	$serv_sett{server} = "http://torokiki.net";
	$serv_sett{cont_loc} = "/image/123/response";
	$serv_sett{x_api_key} = "arandomX-API-Key";


warn ">1\n";
	# Convert to a JSON string.
	my $api_obj_as_txt = JSON::PP->new->utf8->pretty->encode($api_obj);

	# Send to server via http.
	#use HTTP::Request::Common;
	# !! would there be advantages to moving the object decl
	# !! to a setup fn?
	$user_agent = LWP::UserAgent->new();
if (undef){
warn ">2\n";
	$response = $user_agent->request(
					POST "$serv_sett{server}$serv_sett{cont_loc}",
					[
						#"POST /image/123/response HTTP/1.1"
						#"Host" => "torokiki.net"
						"Content-type" => "application/json",
						"X-API-Key" => "$serv_sett{x_api_key}",
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
		warn	"Error on http push request to $serv_sett{server}$serv_sett{cont_loc}\n";
				"Server returned error: ".$reponse->status_line()."\n";
		return (undef, "http error");
	}
	else
	{
		# !! Check how errors are raised elsewhere. is this consistent?
		warn	"Error on http push request to $serv_sett{server}$serv_sett{cont_loc}\n";
				"Server returned error: ".$reponse->status_line()."\n" .
				"In theory only 301/4xx/5xx errors should be returned by a torokiki server!\n";
		return (undef, "unknown http error");
	}
}


# Returns api_object.
sub get_content_from_torokiki_server()
{
	my $api_obj;

	
	# Settingsserver were connecting to 
	my %serv_sett; 
	$serv_sett{server} = "http://torokiki.net";
	$serv_sett{cont_loc} = "/image/123/response/456";


	# Get object from server via http.
	#use HTTP::Request::Common;
	# !! would there be advantages to moving the object decl
	# !! to a setup fn?
	$user_agent = LWP::UserAgent->new();
if (undef){
	$response = $user_agent->request(
					GET "$serv_sett{server}$serv_sett{cont_loc}",
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
		warn	"Error on http get request to $serv_sett{server}$serv_sett{cont_loc}\n";
				"Expecting 200. Server returned error: ".$reponse->status_line()."\n" .
		return (-2, "http error");
	}
}


## !! This is not not finished functional, and probably can't be
## !! untill the mailserve-object format is update to properly 
## !! match the api-object.
## !! 
## !! Note the use of the an new field in the mailserv-objects:
## !! 	$api_obj->{db_info}->{created_by}
#sub convert_api_obj_to_mailserv_obj($)
#{
#	my $api_obj = $_[0];
#    my @local_data = @{$_[1]};
#
#
#	my $mailserv_obj = undef;
#
#	if ($api_obj->{APICaller}->{service} eq 'Robs email thing')
#	{
#		# Search for a copy of the object in the local cache.
#		for (@local_data)
#		{
#			if ($_->{db_info}->{unique_id} eq $api_obj->{APICaller}->{id}) 
#			{ 
#				$mailserv_obj = $_;
#				last; 
#			}
#		}
#
#		if ($mailserv_obj)
#		{
#			$api_obj->{db_info}->{created_by} = "updated from api-object";
#
#			$mailserv_obj->{tag_info}->{action} = 
#			$mailserv_obj->{tag_info}->{type} = 
#			$mailserv_obj->{tag_info}->{tags} = 
#			$mailserv_obj->{tag_info}->{description} = 
#
#			return (1 , $mailserv_obj);
#		}
#		else
#		{
#			return (undef , "updating non-existnent mailserver-object from api-object. ");
#		}	
#	}
#	else
#	{
#		return (undef , "can't create new mailserver-object from api-object ");
#		$api_obj->{db_info}->{created_by} = "created from api-object";
#	};
#
#}


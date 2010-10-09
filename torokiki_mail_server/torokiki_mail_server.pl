#!/usr/bin/perl -w
# ??: not checked for Unicode indepandance/flexibility.
# ??: how does multipart/mixed differ from multipart/alternative
# ??:
# ??: !! + CJs image email has multipart/mixed with text/image/text.
# ??: !! this throws off the parser which only picks up the first
# ??: !! text/plain. The logical solution is to check for 
# ??: !! multipart/mixed  message and then concatinate text/plain as
# ??: !! one text/plain obj., and all text/html as one text/html obj.
# ??: !! It would also be good to consider how multipart/related should 
# ??: !! be read. ie how do you process this:
# ??: !! + multipart/alternative; boundary=Apple-Mail-45-1045731686
# ??: !!    + text/plain; charset=us-ascii; format=flowed
# ??: !!    + multipart/related; boundary=Apple-Mail-46-1045731688; type="text/html"
# ??: !!         + text/html; charset=utf-8
# ??: !!         + image/jpeg; name=IMG_2004.JPG
# ??: !! 
# ??: !! + There should be reference to the unique number in the hash.
# ??: !! this will probably require adjusting the program flow 
# ??: !! unfortunately.
# ??: !! 
# ??: !! + I'm stashing the data_file and meta_file, which are already 
# ??: !! implied by file names (ie data duplication).
# ??: !! 
# ??: !! + The program fails when ./stash doesn't exist. It should 
# ??: !! probably silently create the dir.
# ??: !! 
# ??: !! + Consider creating one encode/decode json object for speed.
# ??: !! 
# ??: !! + I need to consider exactly what text format the user can input.
# ??: !! arrays? json vs custom markup? ...
# ??: !! and then create parsers to just check that there isn't anything 
# ??: !! that will be interpreted by the JSON parsers or other internal 
# ??: !! functions, in the tags/values submitted by users.
# ??: !! 
# ??: !! + Add extra printing information as part of the stash/retrieve/...
# ??: !! process so that an admin can see what's going on. 
# ??: !! This should include the extra notes on this scattered around my 
# ??: !! code. As well as:
# ??: !!    - print "action: ..."
# ??: !!    - print email-address
# ??: !!    - print stash-id on storage (and other actions too prob).
# ??: !! 

use strict;

use Email::MIME;
#use Encode;
use JSON::PP;
use IO::All;
use File::Copy;
use File::Basename;

require 'validate_email/check_email.pl';
require 'parse_email/parse_email_for_data.pl';
#require 'comms/http_torokiki_api.pl';
require 'send/send_emails.pl';
require 'actions/run_action.pl';
require 'stash/stash.pl';



# ---------------- Globals ---------------- 

my $stash_dir = "./stash";
use constant TOROKIKI_SERVER_VERS => "0.1";


# ---------------- Execution starts here ---------------- 

&main;


# ---------------- Functions ---------------- 

sub main()
{
    my @files;


#    # Extract the first command line options, then remove it.
#    foreach(@ARGV)
#    {
#        # Help message prints the script description 
#       if ($_ eq "--help" or $_ eq "-h")
#            { print `scriptdescr $0`; exit 0; }
##       elsif ($_ eq "-o")
##           { $open_in_browser = 1}
#        else
#            { push @files, $_; }
#        #-*)         echo "  Unknown argument:   $1" 1>&2; exit 1 ;;
#    }

    @files = @ARGV;

    foreach (@files)
    {
        &process_email($_); 
    }

    # In case the last print didn't include a \n.
    print "\n";
}

sub process_email($)
{
	# Files
    my $file_name = $_[0];

	
	# Read
    open FILE, "<", $file_name or die "Exiting! Couldn't open $file_name.\n";
	my $eml_txt;
    {
    local $/ = undef;   # read all of file
    $eml_txt = <FILE>;
    }
    close FILE;

    my $eml_mime = Email::MIME->new($eml_txt);

	# Print from header.
    print "Processing mail\n";
	print "  |-> ". gmtime() ."\n"; 
	print "  |-> ". $eml_mime->header("From") ."\n";
    print "  +-> ". $eml_mime->header("Subject") ."\n";

	# Validate
	if (! &validate_email::is_valid_email($eml_mime) )
		{ &exit_on_invalid_email($eml_mime, $eml_txt); }

	# Munge
	my $eml_data = &parse_email::parse_email_for_data($eml_mime);

	# Process
	&actions::run_action($eml_data);
}


sub exit_on_invalid_email($$)
{
	my $eml_mime = $_[0];
	my $eml_txt = $_[1];


	my $filename = &stash::stash_erroneous_email($eml_txt);
	warn "Invalid email! Ignored and saved as $filename\n";

	&send::send_invalid_mail_reply($eml_mime);
	
	exit -1;
}


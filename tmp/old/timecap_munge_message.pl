#!/usr/bin/perl -w
# ??: not checked for Unicode indepandance/flexibility.
# ??: how does multipart/mixed differ from multipart/alternative
# ??:
# ??: !! CJs image email has multipart/mixed with text/image/text.
# ??: !! this throws off the parser which only picks up the first
# ??: !! text/plain. The logical solution is to check for 
# ??: !! multipart/mixed  message and then concatinate text/plain
# ??: !! and/or text/html fields.
# ??: !! 
# ??: !! There should be reference to the unique number in the hash.
# ??: !! this will probably require adjusting the program flow 
# ??: !! unfortunately.

use Email::MIME;
#use Encode;
use JSON::PP;

# Needed to have c-style function-local vars with state.
use feature 'state';	


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

    foreach (@ARGV)
    {
        push @files, $_; 
    }

    foreach (@files)
    {
        &process_email($_);
    }


}


sub process_email($)
{
    # Files
    my $file_name = $_[0];
    my $file_txt;

    # Email::MIME object.
    my $email;

    # Email parts.
    my $header;
    my $email_txt;
    my $email_attachm;

    my $mime_info_ref;
    my $tag_info_ref;
    my $header_info_ref;
    my $bin_data;


    open FILE, "<", $file_name;
    {
    local $/ = undef;   # read all of file
    $file_txt = <FILE>;
    }
    close FILE;

    $email = Email::MIME->new($file_txt);
    $header = $email->header_obj();

    $email_txt = &get_email_txt($email);

    unless ($email_txt)
    {
        &mail_back_no_txt($email);
        return undef;
    }


    $email_attachm = &get_email_attachment($email);

    if ($email_attachm == -2)
    {
        # returns -2 for more than one attachment, 
        &mail_back_too_many_attachments($email);
        return undef;
    }

	# ??: very hacky.
    if ($email_attachm == -1)
	{
		$email_attachm = undef;
	}

#	# ??: something like this should exist in the final version
#    if ($email_attachm == -1)
#    {
#        #-1 for not attachments, 
#        &mail_back_no_attachments($email);
#        return undef;
#    }

    # ??: is this legal: \%mime_info = ...

    $tag_info_ref = &parse_txt_for_meta_data($email_txt);

	# ??: this should be turned on after alpha stage.
    if (!$tag_info_ref)
	{
		print "Error parsing file txt.\n";
		return undef;
	}

    ($mime_info_ref, $bin_data) = &parse_mime_attachment($email_attachm);
    
    # ??: Maybe this should save the entire header, including optional fields.
    $header_info_ref{From} = $email->header("From");
    $header_info_ref{To} = $email->header("To");
    $header_info_ref{Subject} = $email->header("Subject");
    $header_info_ref{Date} = $email->header("Date");
    $header_info_ref{"Message-ID"} = $email->header("Message-ID");


    # ??: header info shouldn't be needed. this could be confusing
    # ??: when a file has been adjusted multiple times.
    my %wrapper_hash = (
        tag_info        => $tag_info_ref,
        mime_info_ref   => $mime_info_ref,
        header_info     => \%header_info_ref
    );

    &save_hash_and_data(\%wrapper_hash, $bin_data);
}


# Extract email txt from the email assuming 
# Takes a pointer to the main Email::MIME node.
sub get_email_txt($)
{
    my $email = $_[0];


    # Look in main mime-object for text.

    if ($email->content_type =~ m{text/plain})
    {
        return &convert_html_email_to_txt($email);
    }   
    elsif ($email->content_type =~ m{text/html})
    {
        return $email->body();
    }


    # If not then look in sub-objects.
    if ($email->content_type =~ m{multipart/})
    {
        # Walk parts once looking for text/plain MIME part.
        for ( $email->subparts() )
        {
            if ($_->content_type =~ m{text/plain})
            {
                return $_->body();
            }
        }

        # then again for a text/html if no text/plain was found.
        for ( $email->subparts() )
        {
            if ($_->content_type =~ m{text/html})
            {
                return &convert_html_email_to_txt($_);
            }
        }
    }

    # If nothing textual was found return,
    return undef;
}


sub convert_html_email_to_txt($)
{
    $email = $_[0];

    # ??: Needs replacing with something proper.
    my $filename = "grock.pl.tmp";

    open FILE, ">", "$filename" || die "Couldn't open grock.pl.tmp\n";
    print FILE $email->body();
    close FILE;

    my $txt = `cat \"$filename\" | lynx -dump -stdin`;

    unlink $filename;
    return $txt;
}


# Looks for the *single* attached file. 
# Fails if there is more than one attachement, or no attachment at all.
# Attachments are classified as any mime type not:
#   text/html
#   text/plain
#   multipart/.+
#
# Takes a pointer to the main Email::MIME node.
#
# returns -3 on general error, -2 for more than one attachment, 
# -1 for not attachments, and the Email::MIME object on success.
sub get_email_attachment($)
{
    my $email = $_[0];
    my $attachment = undef;


    # This shouldn't be necessary.
    unless ($email->content_type =~ m{multipart/.+})
    {
        return -3;
    }

    for ( $email->subparts() )
    {
        unless (    $_->content_type =~ m{text/plain} ||
                    $_->content_type =~ m{text/html} ||
                    $_->content_type =~ m{multipart/.+} )
        {
            if ($attachment)
            {
                return -2; 
            }
            else
            {
                $attachment = $_; 
            }

        }
    }

    if ($attachment)
    {
        return $attachment;
    }
    else
    {
        return -1;
    }
}


# Returns a reference to a hash with the values in it,
# or undef if there was an error parsing the text. Possible 
# errors such as malformed tags, no tags at all, empty file
#
# ??: the return on error should probably have different 
# ??: return values for empty file, vs actual parsing error.
#
# ??: this fn is a bit bloated and should prob be split up.
sub parse_txt_for_meta_data($)
{
    my $email_txt = $_[0];

    my $tag;
    my $value;

    my %hash;


	# Empty file.
	if ($email_txt =~ /^\s*$/)
	{
		return undef;
	}

	# Has text but no tags.
	unless ($email_txt =~ /"/ and  $email_txt =~ /:/)
	{
		return undef;
	}

	# Search for tags, checking they're properly formed.

    # Split the string on a " separator.
    @split_txt  = split('"', $email_txt, -1);

    # There's a possibility the last text chunk is all white-space.
    # This causes problems for the parser, so remove this string type.
    if (@split_txt[@split_txt-1] =~ /^\s*$/)
    {
        splice(@split_txt, @split_txt-1, 1);
    }

    # Use the split strings to extract tag: "value" pairs.
    for (@split_txt)
    {
        if (!$tag)
        {
            # Check the tag is valid.
            # valid tag chars chars =  A-z 0-9 _ -
            # tag must have trailing : 
            # space before and after tag: is ignored.
            #   ie. "Tag_9_for-something: \t" 
            if (/\s*([\w-]+):\s*/)
            { 
                $tag = $1;
            }
            else
            {
                # ??: should be debug printf here.
                return undef; 
            }
 
        }
        else 
        {
            # Check for an escaped-" (\"), meaining that a " should
            # be inserted and the next $_ is also part of the value.
            if (/\\$/)
            { 
                $value .= $_."\"";
            }
            else
            {
                $hash{$tag} =  $value . $_;

                $value = undef;
                $tag = undef;
            }
        }   
    }

    # last $_ was tag not a value.
    if ($tag)
    {
        # ??: should be debug printf here.
        return undef;
    }

    return \%hash;
}


sub print_meta_data($)
{
    my %hash = %{$_[0]};

    for (keys %hash)
    {
        print "\n";
        print "-------- $_ --------\n";
        print "$hash{$_}\n";
        print "--------------------------------\n";
    }
}


sub mail_back_no_txt($)
{
    my $email = $_[0];

    # ??: Needs replacing with something proper.
    printf STDERR "no text MIME type in email\n";
}


sub mail_back_no_attachments($)
{
    my $email = $_[0];

    # ??: Needs replacing with something proper.
    printf STDERR "no attachent in email\n";
}


sub mail_back_too_many_attachments($)
{
    my $email = $_[0];

    # ??: Needs replacing with something proper.
    printf STDERR "more than one attachent in email\n";
}


# Parse a mime attachement and return the file as binary data,
# and a hash of the files 
# ??: There is so much wrong with this module.
# ??:
# ??: The w="x" syntax is different from  the Y: Z syntax and should 
# ??: maybe be stuffed into the hash in a different way.
# ??: I don't know if i need to check for escaping (ie \) for ; = "  ; chars.
# ??:
# ??: this fn is a bit bloated and should prob be split up.
sub parse_mime_attachment($)
{
    my $mime_obj = $_[0];

	# ??: I think the fact that i'm storing a ref to something 
	# ??: created with "my" might cause problems (like it's overwritten, 
	# ??: or disappears when the function is called again). Can't 
	# ??: remember though.
	# ??: 
	# ??: Data duplication: $hash{full}, $hash{splitup} have same basic data.
	# ??: data. in a final version you should find a single way of 
	# ??: accessing/saving data in one place.
    my %hash;

 	my %full_pairs;
	my %splitup_pairs;
    $hash{full} = \%full_pairs;
    $hash{splitup} = \%splitup_pairs;

    my $data;

    for ($mime_obj->header_obj->header_names() )
    {
		my $tag = $_;
        my $value = $mime_obj->header($tag);

		# Stash the Mime-field.
		$hash{full}{$tag} = $value;


		# Split the Mime-field into

        # Simple form (no ;'s in string)
        if ($value =~ /^[^;]*$/)
        {
			$hash{splitup}{$tag} = $value;
        }
        # complex form A: B; c=d; e="f"
        else
        {
			@chunks = split(";", $value, -1);

			# Store and remove the first attribute.
			$hash{splitup}{$tag} = $chunks[0];
        	splice(@chunks, 0, 1);

			# Process the remainging a=b chunks.
			for (@chunks)
			{
				# ??: there should be notes on these regexs.
				if ( /^\s*(.+)=(.+)\s*$/ )
				{
					$hash{splitup}{$1} = $2;
				}
				elsif ( /^\s*(.+)="(.+)"\s*$/ )
				{
					$hash{splitup}{$1} = $2;
				}
				else
				{
					print STDERR "invalid mime chunk: $_\n";
					return undef;
				}
			}
        }
    }

    # ??: this should really check for valid encoding types (such as base64) 
    # ??: rather than trusting the mime header.
	# ??:
	# ??: It also needs re-reading to consider whether there  should be checking
	# ??: to see if the attachment is binary txt or readable txt (which should
	# ??: adjust internal flags for the scalar).
#    my $enc = $mime_obj->header("Content-Transfer-Encoding");
#   $data = decode($enc, $mime_obj->body() );
    $data = $mime_obj->body();

    return (\%hash, $data);
}



sub save_hash_and_data($$)
{
#	my \%wrapper_hash;
	my $wrapper_hash = $_[0];
	my $bin_data = $_[1];

	my $metafile_name;
	my $datfile_name;
	

	($metafile_name, $datfile_name) = &unique_names();
	print "Stashing email in: $metafile_name - $datfile_name\n";

	$json_txt = JSON::PP->new->utf8->pretty->encode($wrapper_hash);
	print "------------------------------------------------------------\n";
	print $json_txt ;
	print "------------------------------------------------------------\n";


	# Write the results out
	open METAFILE, ">", "$metafile_name" or die "Couldn't open $metafile_name: $!";
	print METAFILE $json_txt;
	close METAFILE;
	
	open DATFILE, ">", "$datfile_name" or die "Couldn't open $datfile_name: $!";
	print DATFILE $bin_data;
	close DATFILE;


}



# ??: obviously this is a point of failure. and needs re-reading.
sub unique_names()
{
	state $current_number = 0;

	my $datfile_name;
	my $metafile_name;


	# ??: there is no checking 
	# ??: ie a 32 bit number.
	while (1)
	{
		# ??: there is no checking for an overflow at FFFF,FFFF
		# ??: ie a 32 bit number.
		my $txt_number = sprintf("%08X", $current_number);
		$current_number++;

		$metafile_name = "stash/$txt_number.meta";
		$datfile_name = "stash/$txt_number.dat";

		# ??: this should be checked so that it finishes if it reaches 
		# ??: some reasonable point.
		unless (-e $metafile_name or -e $datfile_name)
		{
			return ($metafile_name, $datfile_name);
		}
	}
	
	# This should probably never be reached.
	return (undef, undef);
	
}

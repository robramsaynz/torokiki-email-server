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
# ??: !!   	+ text/plain; charset=us-ascii; format=flowed
# ??: !!    + multipart/related; boundary=Apple-Mail-46-1045731688; type="text/html"
# ??: !!         + text/html; charset=utf-8
# ??: !!         + image/jpeg; name=IMG_2004.JPG
# ??: !! 
# ??: !! + There should be reference to the unique number in the hash.
# ??: !! this will probably require adjusting the program flow 
# ??: !! unfortunately.
# ??: !! 
# ??: !! + I forgot to die/croak on the file open calls.
# ??: !! 
# ??: !! + I'm stashing the data_file and meta_file, which are already 
# ??: !! implied by file names (ie data duplication).
# ??: !! 
# ??: !! + The program fails when ./stash doesn't exist. It should 
# ??: !! probably silently create the dir.
# ??: !! 
# ??: !! + Consider creating one encode/decode json object for speed.
# ??: !! 


#	-------- Data strucutres --------
#
#	@local_data 
#   	- %entry
#		|	|-db_info: %db_info
#		|	|			|-unique_id: "00001"
#		|	|			|-data_file: "stash/00001.dat
#		|	|			|-meta_file: "stash/00001.meta
#		|	|
#		|	|-mime_info_ref: \%mine_info_ref
#		|	|	|-full: \%full
#		|	|	|		|-ie-Content-Disposition : "attachment; filename=\"CV - Nacky Latorre.pdf\""
#		|	|	|		...
#		|	|	|-splitup: \%splitup
#		|	|				|-ie-filename: "\"CV - Nacky Latorre.pdf\""
#		|	|				|-ie-Content-Disposition: "attachment"
#		|	|				...
#		|	|-header_info: \%header_info
#		|	|				|-ie-Subject: "Re: C.V.",
#		|	|				...
#		|	|-tag_info: \%tag_info
#		|				|-ie-action: "save doc"
#		|				...
#		|- %entry
#		...



use Email::MIME;
#use Encode;
use JSON::PP;
use IO::All;

# Needed to have c-style function-local vars with state.
use feature 'state';	


# ---------------- Globals ---------------- 

my $stash_dir = "./stash";
use constant TIMECAPSULE_SERVER_VERS => "0.1";


# ---------------- Execution starts here ---------------- 

&main;


# ---------------- Functions ---------------- 

sub main()
{
    my @files;

	# ??: needs better description.
	my @local_data;		# Contains all hashes and all other info
						# stored in the system.

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


	print "Parsing metafile/datafile stash.\n";
    @local_data = &read_stash();
	&print_local_data_short(\@local_data);
#	&print_local_data_long(\@local_data);

    foreach (@files)
    {
        &process_email($_, \@local_data);
    }

}

sub process_email($)
{
    # Files
    my $file_name = $_[0];
    my @local_data = @{$_[1]};

	my $wrapper_h = &read_email_meta($file_name);

	if ($wrapper_h == -1)
	{
#       &mail_back_no_txt($email);
		warn "Error: Couldn't find any text in the email.\n";
	   return;
    }
	elsif ($wrapper_h == -2)
	{
		warn "Error: No timecapsule markup in email.\n";
		return;
	}
	elsif ($wrapper_h == -3)
	{
		warn "Error: Errors parsing timecapsule markup in email txt.\n";
		return;
	}

#print "================\n";
#print "$email_txt\n";
#print "----------------\n";

	my $tmp;
##	$tmp = JSON::PP->new->utf8->encode($wrapper_h);
#	print keys %{$wrapper_h} ."\n";
#	print "> ". $wrapper_h ."\n";
##	$tmp = JSON::PP->new->utf8->allow_nonref->pretty->encode(\%{$wrapper_h});
#	%wrapper = %{$wrapper_h};
#	$tmp = JSON::PP->new->utf8->allow_nonref->pretty->encode(\%wrapper);
#	print "++ $tmp\n";
	my %wrapper_hash = %{$wrapper_h};


	if ($wrapper_hash{tag_info}{action})
	{
		if ($wrapper_hash{tag_info}{action} eq "add-content")
		{
			&stash_email($file_name, \%wrapper_hash, \@local_data);
		}
		elsif ($wrapper_hash{tag_info}{action} eq "get-content")
		{
			if ($wrapper_hash{tag_info}{id})
			{
				my $entry_id = $wrapper_hash{tag_info}{id};
				$entry_to_send = &get_entry(\@local_data, $entry_id);

				my $recipient_email = $wrapper_hash{header_info}{From};

				unless ($entry_to_send)
				{
					warn "process_email() error: ".
					"attempt to retrive nonexistant entry_id: $entry_id, by $recipient_email\n";
					return undef;
				}

				my $email_txt = &create_meta_and_attach_email($recipient_email, $entry_to_send);
#				my $email_txt = &create_meta_email($recipient_email, $entry_to_send);
#				my $email_txt = &create_attach_email($recipient_email, $entry_to_send);

				&send_email($email_txt);
			}
		}
	}
	else
	{
		warn "Warning: No valid action found in email. Ignoring.\n";
	}	

	return 1;
}

# Returns a entry for @local_data, or undef if there was problems 
# parsing the email.
#
# returns:	\%wrapper_hash 
#  			-1: Couldn't find any text in the email.
#			-2: No timecapsule markup in email txt.
#			-3: Errors parsing timecapsule markup in email txt.
sub read_email_meta($)
{
    # Files
    my $file_name = $_[0];

    my $file_txt;
    my %wrapper_hash;

    # Email::MIME object.
    my $email;

    # Email parts.
    my $header;
    my $email_txt;
    my $email_attachm;

    my $tag_info_ref;
    my $header_info_ref;


    open FILE, "<", $file_name;
    {
    local $/ = undef;   # read all of file
    $file_txt = <FILE>;
    }
    close FILE;

    $email = Email::MIME->new($file_txt);
print "================\n";
print $email->debug_structure() . "\n";
print "----------------\n";
    $header = $email->header_obj();


    $email_txt = &get_email_txt($email);
    unless ($email_txt)
    	{ return -1; }


    $tag_info_ref = &parse_txt_for_meta_data($email_txt);

	# Pass on any errors.
    if (!$tag_info_ref)
    { 
    	if ($tag_info_ref == -1)
			{ return $tag_info_ref; }
    	elsif ($tag_info_ref == -2)
			{ return $tag_info_ref; }
		else
			{ return -3; }
	}
 
    # ??: Maybe this should save the entire header, including optional fields.
    $header_info_ref{From} = $email->header("From");
    $header_info_ref{To} = $email->header("To");
    $header_info_ref{Subject} = $email->header("Subject");
    $header_info_ref{Date} = $email->header("Date");
    $header_info_ref{"Message-ID"} = $email->header("Message-ID");

    # ??: header info shouldn't be needed. this could be confusing
    # ??: when a file has been adjusted multiple times.
    $wrapper_hash{tag_info} = $tag_info_ref;
	$wrapper_hash{header_info} = \%header_info_ref;

	return \%wrapper_hash;
}

sub stash_email($)
{
    my $file_name = $_[0];
    my %wrapper_hash = %{$_[1]};
    my @local_data = @{$_[2]};

    my $mime_info_ref;
    my $bin_data;

	# ??: !! Duplication of previous code. Bad+slow.
	my $file_txt;
    open FILE, "<", $file_name;
    {
    local $/ = undef;   # read all of file
    $file_txt = <FILE>;
    }
    close FILE;

    my $email = Email::MIME->new($file_txt);
    $email_attachm = &get_email_attachment($email);

    # ??: is this legal: \%mime_info_ref = ...

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

    ($mime_info_ref, $bin_data) = &parse_mime_attachment($email_attachm);

    $wrapper_hash{mime_info_ref} = $mime_info_ref;
    
    &save_hash_and_data_to_file(\%wrapper_hash, $bin_data);
	&save_hash_to_local_vars(\%wrapper_hash, \@local_data);
}

# ================================================================

sub read_stash()
{
	my @local_data;		# Contains all hashes and all other info
						# stored in the system.


	my @dats = glob "$stash_dir/*.dat";

	for (@dats)
	{
		/(.+)\.dat/;
		if (! -e "$1.meta")
		{
			print "Matching \"$1.meta\" does not exist for \"$1.dat\"\n"; 
			print "skipping\n"; 
		}
	}

	my @metas = glob "$stash_dir/*.meta";

	# ??: should this check for missing .dat files (this would 
	# ??: involve looking inside the extracted data structures) 
	for (@metas)
	{
		# slurp.	
		open FILE, "<", $_;
		{
		local $/ = undef;   # read all of file
		$file_txt = <FILE>;
		}
		close FILE;

		# ??: in any final version this setup code should happen just once.
		# Apparently this croaks on error, so i can't error check and skip over files.
		my $wrapper_hash = JSON::PP->new->utf8->decode($file_txt);

		push @local_data, $wrapper_hash;
	}

	return @local_data;
}


sub print_local_data_short($)
{
	my @local_data = @{$_[0]};
	

	print "\n";
	print "entries: \n"; 
	for (@local_data)
		{ print "    unique_id: ". $$_{db_info}{unique_id} ."\n"; }
	print "\n";
	print "number of local_data entries: ". @local_data. "\n";
	print "\n";
}


sub print_local_data_long($)
{
	my @local_data = @{$_[0]};
	

	my $json_txt = JSON::PP->new->utf8->pretty->encode(\@local_data);
	print "----------------------------------------------------------------\n";
	print $json_txt."\n";
	print "----------------------------------------------------------------\n";
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
#
# ??: this needs to be rewritten after reading up on the mime 
# ??: structure.
# ??: For instance i'm assuming it's legal to have multiple 
# ??: multipart/related objects nested. This parser will only find 
# ??: a multipart/related object at the first multipart/related 
# ??: level.
sub get_email_attachment($)
{
    my $email = $_[0];
    my $attachment = undef;


    # This shouldn't be necessary.
    unless ($email->content_type =~ m{multipart/.+})
    {
        return -3;
    }

	# Check for multipart/alternative, and multipart/mixed objects
	# (which will be inlined at the top MIME level).
    for ( $email->subparts() )
    {
		# Is it an attachement?
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

	# Check for multipart/related objects and then check these for attachaments, 
	# (which will be one level down in the MIME tree).
	# ??: this has too many if/for levels. it should probably have some code 
	# ??: shifted to a function.
    for ( $email->subparts() )
    {
		if ($_->content_type =~ m{multipart/related} )
		{
			my $mime_multi_related = $_;

			# Look for attachements.
			for ( $mime_multi_related->subparts() )
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


# ================================================================


# Returns a reference to a hash with the values in it,
# or undef if there was an error parsing the text. Possible 
# errors such as malformed tags, no tags at all, empty file
#
# ??: the return on error should probably have different 
# ??: return values for empty file, vs actual parsing error.
#
# ??: this fn is a bit bloated and should prob be split up.
#
# ??: Consider replacing this perl-fn version with a char by char version.
# ??: this would be easier to read and modify, and would work by reading a 
# ??: char at a time, looking for :/\s/"/\/... flags.
#
# Returns:	\%hash
# or 		-1:	there was text in the email but it was empty.
#			-2:	there was text in the email but it doesn't have any <tag: "value"> 
#			    pairs in it.
#			-3:	got something not a tag (ie name:) while expecting a tag.
#			-4:	last <tag: "value"> pair missing <"value">
sub parse_txt_for_meta_data($)
{
    my $email_txt = $_[0];

    my $tag = undef;
    my $value = "";

    my %hash;


	# Empty file.
	if ($email_txt =~ /^\s*$/)
		{ return -1; }

	# Has text but no tags.
	unless ($email_txt =~ /"/ and  $email_txt =~ /:/)
		{ return -2; }

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
            if (/\s*([\w-]+)\s*:\s*/)
            { 
                $tag = $1;
            }
            else
            {
                # ??: should be debug printf here.
				warn "Error: Expecting tag looking like <name:>. Got <$_>\n"; 
                return -3; 
            }
 
        }
        else 
        {
            # Check for an escaped-" (\"), meaining that a " should
            # be inserted and the next $_ is also part of the value.
            if (/\\$/)
            { 
                $value = $value . $_. "\"" ;
            }
            else
            {
                $hash{$tag} =  $value . $_;

                $tag = undef;
                $value = "";
            }
        }   
    }

    # last $_ was tag not a value.
    if ($tag)
    {
        # ??: should be debug printf here.
		warn "Error: last <tag: \"value\"> pair missing <\"value\">.\n";
        return -4;
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
    warn "no text MIME type in email\n";
}


sub mail_back_no_attachments($)
{
    my $email = $_[0];

    # ??: Needs replacing with something proper.
    warn "no attachent in email\n";
}


sub mail_back_too_many_attachments($)
{
    my $email = $_[0];

    # ??: Needs replacing with something proper.
    warn "more than one attachent in email\n";
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
					warn "invalid mime chunk: $_\n";
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


# ================================================================


sub save_hash_and_data_to_file($$)
{
#	my \%wrapper_hash;
	my $wrapper_hash = $_[0];
	my $bin_data = $_[1];

	my $metafile_name;
	my $datfile_name;
	my $unique_number;
	

	($unique_number, $metafile_name, $datfile_name, ) = &unique_names();
	print "Stashing email in: $metafile_name - $datfile_name\n";

	# Save the file info for later use.
	$$wrapper_hash{db_info} = {
		unique_id => $unique_number,
		data_file => $datfile_name,
		meta_file => $metafile_name,
	};

	# Save the file
	$json_txt = JSON::PP->new->utf8->pretty->encode($wrapper_hash);

#	print "------------------------------------------------------------\n";
#	print $json_txt ;
#	print "------------------------------------------------------------\n";


	# Write the results out
	open METAFILE, ">", "$metafile_name" or die "Couldn't open $metafile_name: $!";
	print METAFILE $json_txt;
	close METAFILE;
	
	open DATFILE, ">", "$datfile_name" or die "Couldn't open $datfile_name: $!";
	print DATFILE $bin_data;
	close DATFILE;


}


sub save_hash_to_local_vars($$)
{
	my %new_hash = %{$_[0]};
	my @local_data = @{$_[1]};


	# Quickly check that the number is indeed unique.
	for (@local_data)
	{
		if ($$_{db_info}{unique_id} eq $new_hash{db_info}{unique_id})
		{
			warn "save_hash_to_local_vars() error:" 
				."entry %s already exits in \@local_data\n", $new_hash{db_info}{unique_id};
			return
		}
	}

	# Cool, now save it.
	push @local_data, \%new_hash;
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

		$metafile_name = "$stash_dir/$txt_number.meta";
		$datfile_name = "$stash_dir/$txt_number.dat";

		# ??: this should be checked so that it finishes if it reaches 
		# ??: some reasonable point.
		unless (-e $metafile_name or -e $datfile_name)
		{
			return ($txt_number, $metafile_name, $datfile_name);
		}

		$current_number++;
	}
	
	# This should probably never be reached.
	return (undef, undef);
	
}


# ================================================================

# Takes the a ref to @local_data, and a unique-id string to 
# find in that array. 
# Returns a ref to the entry on success otherwise, undef.
sub get_entry($$)
{
	my @local_data = @{$_[0]};
	my $entry_name = $_[1];

	


	# Quickly check that the number is indeed unique.
	for (@local_data)
	{
		my %entry = %{$_};

		if ($entry{db_info}{unique_id} eq $entry_name)
		{
			return \%entry;
		}
	}

	warn "get_entry() error: couldn't find $entry_name in the \@local_data.\n";
	return undef;
}


# ================================================================

# ??: !! should txt be sent as attach+txt1+meta-txt or attach+txt1-and-meta-txt
# ??: !! seeing as we've already set a preference for readin only *one* txt file
# ??: !! from incoming messages.
sub create_meta_and_attach_email($$)
{
	my $recipient_email = $_[0];
	my %entry_to_send = %{$_[1]};
#   	- %entry
#		|	|-db_info: %db_info
#		|	|			|-unique_id: "00001"
#		|	|			|-data_file: "stash/00001.dat
#		|	|			|-meta_file: "stash/00001.meta
#		|	|
#		|	|-mime_info_ref: \%mine_info_ref
#		|	|	|-full: \%full
#		|	|	|		|-ie-Content-Disposition : "attachment; filename=\"CV - Nacky Latorre.pdf\""
#		|	|	|		...
#		|	|	|-splitup: \%splitup
#		|	|				|-ie-filename: "\"CV - Nacky Latorre.pdf\""
#		|	|				|-ie-Content-Disposition: "attachment"
#		|	|				...
#		|	|-header_info: \%header_info
#		|	|				|-ie-Subject: "Re: C.V.",
#		|	|				...
#		|	|-tag_info: \%tag_info
#		|				|-ie-action: "save-doc"
#		|				...
#		|- %entry
#		...


	# Slurp, the attachment file.
	my $attach_txt;
	open FILE, "<", $entry_to_send{db_info}{data_file};
	{
	local $/ = undef;   # read all of file
	$attach_txt = <FILE>;
	}
	close FILE;
	$attach_txt = io( $entry_to_send{db_info}{data_file} )->all;

	# Grab it's original flags, but make sure it's an attachment
	#my %full_mime = $entry_to_send{mime_info_ref}{full};
	#my %full_mime = $entry_to_send{mime_info_ref}{full};
	# ??: I should probably worry about attachment vs inline at some point.
#	$full_mime{Content-Disposition} = "attachment";

	my %split_mime = %{$entry_to_send{mime_info_ref}{splitup}};

	# multipart message
	my $part1 = Email::MIME->create();
#	my $part1 = Email::MIME->create(
#			attributes => {
#				if 
#				filename     => "report.pdf",
#				content_type => "application/pdf",
#				encoding     => "quoted-printable",
#				name         => "2004-financials.pdf",
#			},
#			body => io( "2004-financials.pdf" )->all,
#		);


	# ??: uuuuugh ugly.
	my $mime_value;
	$mime_value = $split_mime{"Content-Transfer-Encoding"};
    $part1->encoding_set($mime_value) if $mime_value;

	$mime_value = $split_mime{"Content-Disposition"};
    $part1->disposition_set($mime_value) if $mime_value;
	$mime_value = $split_mime{"filename"};
    $part1->filename_set($mime_value) if $mime_value;

	$mime_value = $split_mime{"Content-Type"};
    $part1->content_type_set($mime_value) if $mime_value;
	$mime_value = $split_mime{"charset"};
    $part1->charset_set($mime_value) if $mime_value;
	$mime_value = $split_mime{"format"};
    $part1->format_set($mime_value) if $mime_value;
	$mime_value = $split_mime{"name"};
    $part1->name_set($mime_value) if $mime_value;
	$mime_value = $split_mime{"boundry"};	# I think for multipart/*.
    $part1->boundary_set($mime_value) if $mime_value;

# maybe MIME set:
#    * body_set
#    * body_str_set
#    * parts_set
#    * parts_add
#    * header_str_set

	$part1->body_set($attach_txt);
#	$part1->body_str_set($attach_txt);


	my $part2 = Email::MIME->create(
		attributes => {
			content_type => "text/plain",
			#encoding     => "utf-8",
			encoding     => "7bit",
			charset      => "us-ascii",
			# disposition  => "flowed",
			# ??: disposition  => "inline",
			# ??: disposition  => "attachment",
		},
	);

	my $body_txt;
	$body_txt =  "-- This is an auto generated message from the time capsule server --\n";
#	$body_txt .= "-- for helpe send a message to time.capsule.testin\@gmail.com     --\n";
#	$body_txt .= "-- with this in the message body. action: \"help\"                --\n";

	my $tag_info = $entry_to_send{tag_info};	# Ref to %tag_info.
	$body_txt .= JSON::PP->new->utf8->pretty->encode($tag_info);

	$part2->body_set($body_txt );
#	$part1->body_str_set($body_txt );


	my @parts = (
		$part1,
		$part2,
	);

	my $email = Email::MIME->create(
		header => [ 
			To => $recipient_email,
			From => "time.capsule.testing\@gmail.com",
			Subject => 'Timecapsule_reply'
#			# custom timecapsule header (prob best avoided).
#			'TCNOTE' => 	"Auto generated by the timescapsule ".
#					"server vers: TIMECAPSULE_SERVER_VERS,
		],
		parts  => [ @parts ],
	);
	
	return $email->as_string();
}


# ??: !! See &create_meta_and_attach_email() for errors this inherits.
sub send_meta($$)
{
	my $recipient_email = $_[0];
	my %entry_to_send = {$_[1]};


	my $body_txt;
	$body_txt =  "-- This is an auto generated message from the time capsule server --\n";
	$body_txt .= "-- for helpe send a message to time.capsule.testing\@gmail.com     --\n";
	$body_txt .= "-- with this in the message body. cmd: \"help\"                   --\n";

	$body_txt .= JSON::PP->new->utf8->pretty->encode(\%entry_to_send);


	my $email = Email::MIME->create(
		header => [ 
			To => $recipient_email,
			From => 'time.capsule.testing\@gmail.com',
			Subject => 'Timecapsule_reply'
#			# custom timecapsule header (prob best avoided).
#			'TCNOTE' => 	"Auto generated by the timescapsule ".
#					"server vers: TIMECAPSULE_SERVER_VERS,
		],
		attributes => {
			content_type => "text/plain",
			encoding     => "utf8",
			charset      => "us-ascii",
			# disposition  => "flowed",
			# ??: disposition  => "inline",
			# ??: disposition  => "attachment",
		},
		body => $body_txt,
	);

	return $email->as_string();
}



#sub send_attach()
#{
#}



# Send the email using msmtp (similar to sendmail).
sub send_email($)
{
	my $email_txt = $_[0];


	# Slurp, the attachment file.
	open FILE, ">", "email_file.tmp";
	print FILE $email_txt;
	close FILE;

	# ??: Should from address be groked from the email with --read-envelope-from?
	system("cat email_file.tmp | msmtp --file=msmtp.timecap.conf --read-recipients");
	system("rm -f email_file.tmp ");

}

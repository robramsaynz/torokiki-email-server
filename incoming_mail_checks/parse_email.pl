# Functions for reading and converting emails.
#
# Rob Ramsay 18:56 29 Aug 2010


# See http://torokiki.net/docs/mailserver-command-spec.md for a description 
# of what a help message looks like.
sub is_help_message($)
{
	my $eml_mime = $[0];


    my $subj = $eml_mime->header("Subject");

	if ($subj =~ m/^\s*help\s*$/)
	{ 
		return 1; 
	}
	elsif ($subj =~ m/^\s*$/)
	{ 		
		my $text = &get_email_txt($eml_mime);
		unless ($text)
			{ return undef; }

		if ($text =~ m/^\s*help\s*$/)
			{return 1; }
		else
			{ return undef; }
	}
	else
	{
		return undef;
	}
}


# Extract email txt from the email assuming 
# Takes a pointer to the main Email::MIME node.
sub get_email_txt($)
{
    my $eml_mime = $_[0];


    # Look in main mime-object for text.
    if ($eml_mime->content_type =~ m{text/plain})
    {
        return &convert_html_email_to_txt($eml_mime);
    }   
    elsif ($eml_mime->content_type =~ m{text/html})
    {
        return $eml_mime->body();
    }


    # If not then look in sub-objects.
    if ($eml_mime->content_type =~ m{multipart/})
    {
        # Walk parts once looking for text/plain MIME part.
        for ( $eml_mime->subparts() )
        {
            if ($_->content_type =~ m{text/plain})
            {
                return $_->body();
            }
        }

        # then again for a text/html if no text/plain was found.
        for ( $eml_mime->subparts() )
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
    $eml_mime = $_[0];

    # ??: Needs replacing with something proper.
    my $filename = "grock.pl.tmp";

    open FILE, ">", "$filename" || die "Couldn't open grock.pl.tmp\n";
    print FILE $eml_mime->body();
    close FILE;

    my $txt = `cat \"$filename\" | lynx -dump -stdin`;

    unlink $filename;
    return $txt;
}


# Take a tag/value string (tag: "..." tag: "...") and convert it to a hash. 
#
# ??: Consider replacing this perl-fn version with a char by char version.
# ??: this would be easier to read and modify, and would work by reading a 
# ??: char at a time, looking for :/\s/"/\/... flags.
#
# Returns:  \%hash
#           -1: got something not a tag (ie name:) while expecting a tag.
#           -2: last <tag: "value"> pair missing <"value">
sub tag_value_pairs_to_hash($)
{
    my $email_txt = $_[0];

    my $tag = undef;
    my $value = "";

    my %hash;


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
                return -1; 
            }
 
        }
        else 
        {
            # Check for an escaped-" (\"), meaining that a " should
            # be inserted and the next $_ is also part of the value.
            if (/\\$/)
            { 
                $value = $value . $_ . "\"" ;
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
        return -2;
    }

    return \%hash;
}



# validate_email/parse_email.pl
#
# Rob Ramsay 21:40 17 Aug 2010

require 'parse_email.pl';
require 'mime_walking.pl';
require 'check_content_locations.pl';


sub validate_email::is_valid_email($)
{
	my $eml_mime = $_[0];


	# The help message has different syntax to the rest of the system
	if ( &validate_email::is_help_message($eml_mime) )
		{ return 1; }


	# ?? Convert all of these functions into ( $err, $msg ) returns.

	&validate_email::is_subject_syntax_valid($eml_mime) || return undef;

	&validate_email::is_action_allowed($eml_mime) || return undef;

	&validate_email::is_action_valid($eml_mime) || return undef;

	# Yay no errors.
	return 1;
}



sub validate_email::is_subject_syntax_valid()
{
	my $eml_mime = $_[0];


    $_ = $eml_mime->header("Subject");

	# i.e. create-response-to: 'http://torokiki.net/image/123/response/456'
	if (m/^[\w-]+:\s*'(\S+)'\s*$/)
	{ 
		# Check 'http://torokiki.net/image/123/response/456' syntax is valid.
		return &validate_email::check_torokiki_object_locations($1);
	}
	else 
	{ 
		return undef;
	}
}


#    0: Email has valid "value: 'tag'" syntax.
#   -1: there was text in the email but it was empty.
#   -2: there was text in the e[]()mail but it doesn't have any <tag: "value"> 
#       pairs in it.
#   -3: got something not a tag (ie name:) while expecting a tag.
#   -4: last <tag: "value"> pair missing <"value">
sub validate_email::is_text_syntax_valid($)
{
	my $eml_text = $_[0];


    # Empty file.
    if ($eml_txt =~ /^\s*$/)
	{
        warn "Error: Couldn't find any text in the email.\n";
        return -1;
	}

    # Has text but no tags.
    unless ($eml_txt =~ /"/ and  $eml_txt =~ /:/)
    {
        warn "Error: No Torokiki Mailserver markup in email.\n";
		return -2; 
	}

	# ??: We do this function again later, which will slow the system down.
	my $rtn = &tag_value_pairs_to_hash($eml_txt);

	if ($rtn == -1)
	{
        warn "Error: Errors parsing Torokiki Mailserver markup in email txt.\n";
		return -3;
	}
	elsif ($rtn == -2)
	{
        warn "Error: Errors parsing Torokiki Mailserver markup in email txt.\n";
		return -4;
	}
	else
	{
		return 0;
	}
}


sub validate_email::is_action_allowed($)
{
	my $eml_mime = $_[0];


    $_ = $eml_mime->header("Subject");

	if ( /^get:/i )
		{ return 1; }
	elsif ( /^create-response-to:/i )
		{ return 1; }
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 
	else
		{ return undef; }

}


sub validate_email::is_action_valid($)
{
	my $eml_mime = $_[0];


    $_ = $eml_mime->header("Subject");

	if ( /^get:/i )
	{ 
		unless ( &is_valid_get_cmd($eml_mime) )
			{ return undef; }
	}
	elsif ( /^create-response-to:/i )
	{ 
		unless ( &is_valid_create_response_to_cmd($eml_mime) )
			{ return undef; }
	}
#	create-response-to:
#	set-meta-data-for
#	get-meta-data-for 
	else
	{
		return undef; 
	}
}


sub validate_email::is_valid_get_cmd($)
{
	my $eml_mime = $_[0];

	
	if (&count_mime_attach_recurs($eml_mime) != 0)
	{ 
		warn "'get' email commands must have no attachments.";
		return undef; 
	}


	my $text = &get_email_txt($eml_mime);

	my %tags = &tag_value_pairs_to_hash($text);

	## Check for required tags.
	#if ($tags{something} eq undef)
	#{
	#	warn "'create-response-to' missing required tag: $tags{$_}"
	#	return undef;
	#}

	# Check for invalid tags.
	for (keys %tags)
	{
		warn "'get' doesn't take tags (ie $tags{$_}).";
		return undef;
	}

	# Note that this ignores any text, and whether or not
	# text is supplied.

	return 1;
}


sub validate_email::is_valid_create_response_to_cmd($)
{
	my $eml_mime = $_[0];


	# ??: at the moment, we require an image, but in the future this may 
	# ??: accept be text responses (which would mean 0 attachments).
	if (&count_mime_attach_recurs($eml_mime) != 1)
	{
		warn "'create-response-to' email commands must have one attachment.";
		return undef; 
	}


    my $eml_txt = &get_email_txt($eml_mime);
	unless ($eml_txt)
	{
		warn "'create-response-to' email commands must have text.";
		return undef; 
	}

	# ?? Convert into ( $err, $msg ) returns.
	my $rtn = &is_text_syntax_valid($eml_mime);
	if ($rtn != 0)
		{ return $rtn; }


	%tags = &tag_value_pairs_to_hash($eml_txt);

	## Check for required tags.
	#if ($tags{something} eq undef)
	#{
	#	warn "'create-response-to' missing required tag: $tags{$_}";
	#	return undef;
	#}

	# Check for invalid tags.
	for (keys %tags)
	{
		$_ = $tags{$_};

		#if ( /tags/i || /objective/i|| /location/i || /text/i )
		unless ( /tags/i || /objective/i || /location/i )
		{
			warn "'create-response-to' invalid tag: $_";
			return undef;
		}
	}

	return 1;
}



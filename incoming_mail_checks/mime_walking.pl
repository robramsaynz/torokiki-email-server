# Functions for walking the tree of mime elements, to do things like cound 
# elements or find certain kinds.
#
# Rob Ramsay 18:56 29 Aug 2010


# Takes a mime object and a number, and returns number'th 
# attachment from the mime tree (or undef).
sub incoming_mail_checks::return_mime_attach_num($$)
{
	my $eml_mime = $_[0];
	my $att_to_get = $_[1];


	# Invalid number.
	if ( $att_to_get < 1 )
		{ return undef; }

	$num_attach = 0;
	return &return_mime_attach_num_recurs($eml_mime, $att_to_get, \$num_attach);
}


# Internal version which also passes num-attachements variable a down the 
# recursive chain.
sub incoming_mail_checks::return_mime_attach_num_recurs($$$)
{
	my $eml_mime = $_[0];			# MIME object/tree to search.
	my $att_to_get = $_[1];			# numeric number of attachment to get.
	my $num_attach_ref = $_[2];		# pointer to number of attachments.


	if ( &is_mime_obj_attach($_) )
	# it's an attachement.
	{ 
		$$num_attachs_ref++;

		if ($att_to_get == $$num_attach_ref)
			{ return $_; }
		else
			{ return undef; }
	}
    elsif (! $eml_mime->content_type =~ m{multipart/.+} )
	# it isn't an attachement.
	{ 
		return undef; 
	}
	else
	# it must be a mime tree.
	{
		for ( $eml_mime->subparts() )
		{
#			if ($_->content_type =~ m{multipart/related} )	# ??: removable
			if ($_->content_type =~ m{multipart/.+} )
			{
				my $obj = &return_mime_attach_num_recurs($_, $att_to_get, $num_attach_ref);

				if ($obj)
					{ return $_; }
			}
			elsif ( &is_mime_obj_attach($_) )
			{
				$$num_attachs_ref++;

				# If this is the attachment we're after return it.
				if ($$num_attachs_ref == $att_to_get)
					{ return $_; }
			}
		}

		# If this is reached, $att_to_get is larger than the number of 
		# attachments in this tree.
		return undef;
	}
}


sub incoming_mail_checks::count_mime_attach_recurs($)
{
	my $eml_mime = $_[0];


	if ( &is_mime_obj_attach($_) )
	# it's an attachement.
	{ 
		return 1; 
	}
    elsif (! $eml_mime->content_type =~ m{multipart/.+} )
	# it isn't an attachement.
	{ 
		return 0; 
	}
	else
	# it must be a mime tree.
	{
		my $num_attachs = 0;

		for ( $eml_mime->subparts() )
		{
#			if ($_->content_type =~ m{multipart/related} )	# ??: removable
			if ($_->content_type =~ m{multipart/.+} )
			{
				$num_attachs +=	&count_mime_attach_recurs($_);
			}
			elsif ( &is_mime_obj_attach($_) )
			{
				$num_attachs++;
			}
		}

		return $num_attachs;
	}
}


sub incoming_mail_checks::is_mime_obj_attach($)
{
	my $eml_mime = $_[0];


	# ??: !! Attachements are non-text non mime-hierarchy, and 
	# ??: !! this list is very incomplete, and needs updating.
	if ($_->content_type =~ m{text/plain})
		{ return undef; }
	elsif ($_->content_type =~ m{text/html})
		{ return undef; }
	elsif ($_->content_type =~ m{multipart/.+})
		{ return undef; }
	else
		{ return 1; }
}


sub incoming_mail_checks::is_mime_obj_text($)
{
	my $eml_mime = $_[0];


	# ??: Are there other textual MIME objs?
#	if ($_->content_type =~ m{text/plain})		# ??: removable
	if ($_->content_type eq m{text/plain})
		{ return 1; }
#	elsif ($_->content_type =~ m{text/html})	# ??: removable
	elsif ($_->content_type =~ m{text/html})
		{ return 1; }
	else
		{ return undef; }
}


1;

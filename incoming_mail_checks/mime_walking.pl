# Functions for walking the tree of mime elements, to do things like cound 
# elements or find certain kinds.
#
# Rob Ramsay 18:56 29 Aug 2010


sub count_mime_attach_recurs($)
{
	my $eml_mime = $_[0];


	# Is an attachement.
	if (is_mime_obj_attach($_) )
		{ return 1; }

	# Isn't an attachement.
    if (! $eml_mime->content_type =~ m{multipart/.+} )
		{ return 0; }

	# It must be a mime tree.
	my $num_attachs = 0;

    for ( $eml_mime->subparts() )
	{
#		if ($_->content_type =~ m{multipart/related} )	# ??: removable
		if ($_->content_type =~ m{multipart/.+} )
        {
			$num_attachs +=	&count_mime_attach_recurs($_);
		}
		elsif (is_mime_obj_attach($_) )
		{
			$num_attachs++;
		}
	}

	return $num_attachs;
}


sub is_mime_obj_attach($)
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


sub is_mime_obj_text($)
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



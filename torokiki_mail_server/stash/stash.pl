# Save/reload emails from 'stashes' (dirs containing sets of emails).
#
# Rob Ramsay 01:42  8 Sep 2010


my $stash::error_dir = "./erroneous_emails";


sub stash::stash_erroneous_email($)
{
	my $eml_text = $_[0];


	my $filename = &stash::unique_names($stash::error_dir);
	
	if ($filename)
	{
		$filename = $stash::error_dir . "/$filename";

		open FILE, ">", "$filename" or die "Couldn't open $filename for writing: $!";
		print FILE $eml_text;
		close FILE;
		
		return $filename;
	}
	else
	{
		return undef;
	}
}



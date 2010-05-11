#!/usr/bin/perl
# ??: not checked for Unicode indepandance.


# ---------------- Execution starts here ---------------- 

&main;


# ---------------- Functions ---------------- 

sub main()
{
    my @files;

    foreach (@ARGV)
    {
        push @files, $_; 
    }

    foreach (@files)
    {
        &process_file($_);
    }


}


sub process_file($)
{
    # Files
    my $file_name = $_[0];
    my $file_txt;

    open FILE, "<", $file_name;
    {
    local $/ = undef;   # read all of file
    $file_txt = <FILE>;
    }
    close FILE;

    $hash_ref = &parse_txt_for_meta_data($file_txt);
    die "invalid file_txt\n" unless $hash_ref;
    &print_meta_data($hash_ref);
}


# Returns a reference to a hash with the values in it,
# or undef if there was an error parsing the text.
sub parse_txt_for_meta_data($)
{
    my $email_txt = $_[0];

    my $tag;
    my $value;

    my %hash;


    # Split the string on a " separator.
    @split_txt  = split '"', $email_txt, -1;

	# There's a possibility the last text chunk is all white-space.
	# This causes problems for the parser, so remove this string type.
	if (@split_txt[@split_txt-1] =~ /^\s*$/)
	{
		splice @split_txt, @split_txt-1, 1;
	}

    # Use the split strings to extract tag: "value" pairs.
    for (@split_txt)
    {
        if ($tag eq undef)
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



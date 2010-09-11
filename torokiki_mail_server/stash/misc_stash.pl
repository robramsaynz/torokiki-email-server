# Functions to help saving emails to 'stashes'.
#
# Rob Ramsay 01:42  8 Sep 2010

use strict;


# Needed to have c-style function-local vars with state.
use feature 'state';    


# ??: obviously this is a point of failure. and needs re-reading.
sub stash::unique_names($)
{
	my $stash_dir = $_[0];


    state $current_number = 0;


    # ??: there is no checking 
    # ??: ie a 32 bit number.
    while (1)
    {
        # ??: there is no checking for an overflow at FFFF,FFFF
        # ??: ie a 32 bit number.
        my $txt_number = sprintf("%08X", $current_number);

        my $file = "$stash_dir/$txt_number.eml";

        # ??: this should be checked so that it finishes if it reaches 
        # ??: some reasonable point.
        return $file if (! -e $file);

        $current_number++;
    }
    
    # This should probably never be reached.
    return undef;
}


1;

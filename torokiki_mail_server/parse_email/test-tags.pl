#!/usr/bin/perl

require 'misc_parsing.pl';

my $msg_w_err = "
tag: this-gets-ignored-and-gobbles-up-the-text-tag 
text : 'This is a text response' 
tags : 'fart bums old-things'
location : '123 Some Street, Suburb'
hello: 'world'
";


my $msg = "
# This is a comment
text : 'This is a text response' # So is this 
tags : 'fart bums old-things'
location : '123 Some Street, Suburb'
	# and another comment
hello: 'world'
";

print "\n";
print "msg_w_err:\n";
my $tags = &parse_email::tag_value_pairs_to_hash($msg_w_err);

for (keys %{$tags})
{
	print  "\$tags{$_} => $$tags{$_}\n";
}




print "\n";
print "msg:\n";
my $tags = &parse_email::tag_value_pairs_to_hash($msg);

for (keys %{$tags})
{
	print  "\$tags{$_} => $$tags{$_}\n";
}




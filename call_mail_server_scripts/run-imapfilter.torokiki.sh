#!/bin/sh
#
#	Coding Notes:
#
#		- for the production environment also consider having 
#		  a script checking that the server is working, and have 
#		  it contact you when there is an error. ie check that 
#		  imapfilter is still looping correctly, and that perl 
#		  scripts are giving reasonable output.
#

while (true)
do
	imapfilter -c imapfilter.torokiki.conf
	sleep 10
done

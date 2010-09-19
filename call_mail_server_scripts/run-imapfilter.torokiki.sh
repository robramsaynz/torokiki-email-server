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

# Setup env-vars for the tk.gamedesigneresource.com server with has
# some componenets manually installed into the file-system.
cd ../../missing-components/
. setup.s
cd $OLDPWD


# Clear log
logfile=../logs/mail-server-runscript.log
if [ -e "$logfile" ]; then
	rm -f $logfile.old 
	mv $logfile $logfile.old
fi
>$logfile


# Run on a loop saving all output to log.
while (true)
do
	cd ../torokiki_mail_server
	imapfilter -c ../call_mail_server_scripts/imapfilter.torokiki.conf 
#	imapfilter -c ../call_mail_server_scripts/imapfilter.torokiki.conf 1>>$logfile 2>&1
	sleep 10
done

#!/bin/sh

while (true)
do
	imapfilter -c imapfilter.timecap.conf
	sleep 10
done

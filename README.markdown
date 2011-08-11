# Torokiki Email Server #

An email server coded in Perl for Torokiki, an ethnographic role-playing website.

- [Torokiki Overview]
- [Torokiki Website]

[Torokiki Overview]: http://collectivenoun.net/torokiki-overview/
[Torokiki Website]:  http://torokiki.net/


## Description

This is in an email gateway server written in Perl, designed to allow users to
submit content (videos/images/text) via email to the [Torokiki Website].  The
idea is that the server auto generates email responses, via `mailto:` URLs,
and that users click on these links to send them to this server. 

This email-server is called via the scripts in `call_mail_server_scripts/`.
These use the `imapfilter` command to check an email address, and then call the
email-server to process the emails received.

The server parses these emails to make sure they are valid, and then executes
the actions triggered by the emails. Usually this involves making a HTTP
connection to the Torokiki website, and either saving new content submitted in the
email, or retrieving existing content from the website. 

Email replies are then sent to the users to let them know if their content has
been saved, or whether there was a problem parsing their emails.

Any emails that are erroneous or that the server can't understand are saved to a
`logs/` dir. The idea is that an admin can periodically check this dir, to find
out if users are struggling to use the system, or if there's malicious activity.


## Code State

This is very much a work in progress. The code does work, but was never tested
in a production environment, and would probably need a lot of issues ironed out
of it, if it were.  

The `# ??` and `# !!` comments indicate a possible problem, that should be
evaluated or fixed. Generally these are not a faults, but a possibly point of
failure not worth the time required to address them when they were coded.


The main email-server is called via the
`torokiki_mail_server/torokiki_mail_server.pl` Perl file.  This then calls
files in the `actions`/`comms`/`parse_email`/... dirs, to perform actions such
as checking the validity of incoming emails, or sending out replies to users .
The code is generally a nested tree of Perl files (three files deep in most dirs). 


## Perl Modules Requirements

This code requires the following Perl modules to run:

- `Email::MIME`
- `MIME::Base64`
- `MIME::Types`
- `LWP::UserAgent`
- `HTTP::Request::Common`
- `JSON::PP`
- `IO::All`
- `File::Basename`
- `File::Copy`
- `File::Spec`


## External Programs Requirements

The scripts used as part of the system require the following programs installed:

- `msmtp`
- `imapfilter`





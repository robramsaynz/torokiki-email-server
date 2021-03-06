# Torokiki Mailserver Help #

This mail is from the [Torokiki website](http://tk.gamedesignresource.com) email-gateway. The Torokiki website is an online community of users who view historical images of Wellington city, and create presonalised responses to these images. 

You can use this email-gateway to access content stored on the website, or submit responses to that content. For help on specific commands see:

+ [get Command](#get-command) 
+ [create-response-to Command](#create-response-to-command)
+ [help Command](#help-command)
 
The basic syntax of Mailserver emails has a 'command:', and then the URL of any content being accessed, on the subject line.  Other information is conveyed as tag/values pairs in the email's body. Binary content may be added as an attachment to the email.

	--------------------------------
	to: this@email.address
	subject: command: http://tk.gamedesignresource.com/content/url
	--------------------------------
	tag1: 'tag1 value'
	tag2: 'tag1 value'
	--------------------------------
	mime-attachment
	--------------------------------


## 'get' Command

This command lets you retrieve a piece of content off the website, (which will be sent to you in a reply email). In most cases it will be easier to go to the content's URL on the torokiki website.

Here's an example

	--------------------------------
	to: this@email.address
	subject: get: http://tk.gamedesignresource.com/123/resourse/456
	--------------------------------
	tag1: 'tag1 value'
	tag2: 'tag1 value'
	--------------------------------
	mime-attachment
	--------------------------------

In this case you could have just entered 'http://tk.gamedesignresource.com/image/123/response/456' in your browser, to view the content.


## 'create-response-to' Command

You can respond to Torokiki content using images, text, audio, video, or any other media type you like. You can also create tags for your content to group and organise it ('tags: lambtonquay trams' for instance).

To create a png response to 'www.torokiki.net/image/123/response/456' you woud send something like,

	--------------------------------
	to: this@email.address
	Subject: create-response-to: 'http://torokiki.net/image/123/response/456'
	---- Body ----------------------
	tags : 'lambtonquay transport bus'
	location : '123 Lambton quay'
	---- Attachment ----------------
	wellington-bus.png
	--------------------------------


To create a text response to 'www.torokiki.net/image/123/response/456' you woud send something like,

	================================
	to: this@email.address
	subject: create-response-to: 'http://torokiki.net/image/123/response/456'
	==== Body ======================
	text : 'These routes are now plied by a petrol based bus service.'
	tags : 'lambtonquay transport bus'
	================================


## 'help' Command

If you send an email with nothing by the word 'help' in it's body, or it's header, then you'll get this email back in reply. i.e.

	--------------------------------
	To: time.capsule.testing@gmail.com
	Subject: help
	---- Body ----------------------
	--------------------------------

	--------------------------------
	To: time.capsule.testing@gmail.com
	Subject: 
	---- Body ----------------------
	help 
	--------------------------------


## Further help

If you have any further questions see the [Torokiki Mailserver Spec](http://torokiki.net/docs/mailserver-command-spec.md).



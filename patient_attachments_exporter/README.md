Patient Attachments Exporter
============================

Exports all of a patient's attachments.

Motivation
----------

The patient chart export function is kaput in Aprima. Accordingly, I wrote this handy-dandy Perl script to export all of the files attached to the specified patient.

Setup
-----

Before compiling the script, you want to make sure that you have everything ready for it to run properly.

1.	Make sure that the attached BCP format file is placed on the MSS drive somewhere, something like this:

		D:\data_transfer\working_blob_export.fmt

2.	Open *patient_attachment_exporter.pl* with your favorite text editor, and change the value of $fmt to wherever you have *working_blob_export.fmt*. E.G.

		my $fmt = "D:\\data_transfer\\working_blob_export.fmt";

	Save & exit.

3.	Be sure that you have DBI set up properly. Unfortunately, doing so can be tricky. It certainly was for me. Doing this, though, goes beyond the scope of the README. I used the following online tutorials to get it set up on Ubuntu, and the best I can do is direct you their way for help:

	[UnixODBC & FreeTDS](http://www.unixodbc.org/doc/FreeTDS.html)

	(Installing Perl Modules](http://www.cyberciti.biz/faq/how-do-i-install-a-perl-module/) (You might need to install with admin privileges depending on your setup.)

	[DBI](http://search.cpan.org/~timb/DBI/DBI.pm)

	[DBI Drivers Install](http://www.easysoft.com/developer/languages/perl/dbd_odbc_tutorial_part_1.html)

	I know that this can be quite the headache. I'm so sorry...

Usage
-----

1.	Make sure that the server running Microsoft SQL Server has a directory on the same drive as MSS, and that it is named after the patient's last name and first name. This needs to match what the name looks like in Aprima. So, if MSS is running on \<D:\\>, and the patient's name is John Madden, then make sure that there is something like the following:

		D:\data_transfer\single_patient_export\Madden_John\

2.	Create two sub-directories in the \<Madden_John\> directory:

	a)	\<Madden_John\compressed\>

	b)	\<Madden_John\uncompressed\>

3.	Compile the script.

		perl patient_attachments_exporter.pl

4.	You will be prompted for the following:

	a)	Your data source.

	b)	Your user name for MSS.

	c)	Your password for MSS.

	d)	The patient's first name.

	e)	The patient's last name.

5.	Then, if everything is copacetic, you will be presented with a text menu. Enter the row number of the patient whose files you want to export.

6.	Following this, you will be prompted to enter the full directory path for the folder you created in (1). That is,

		D:\data_transfer\single_patient_export\Madden_John\

7.	Once you hit *ENTER*, the script will hopefully execute properly. If there are no errors, it most likely did. Confirm by opening up \<patient_file_notes\> (the files here are collations of all of the notes in Aprima associated with the exported files), then by opening up the target directory in Windows. In the former, you should see a file in the form of *Lastname_Firstname.txt*, and in the latter you should have a bunch of files in either \<compressed\> or \<uncompressed\> (or both).

8.	Uncompress, inflate, zip, etc. these files with another handy script I wrote called (inflator)[https://github.com/DeadDork/aprima-scripts/tree/master/inflator].

And you're done!

Nota Bene's
-----------

N.B. since this export utility is meant to be used on one patient at a time, much less care went into keeping records of what was exported, etc., than were I exporting all of the attachments in the DBMS at once.

N.B. I have only tested this script on Ubuntu 12.04. If it doesn't work on your system...

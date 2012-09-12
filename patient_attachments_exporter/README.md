Patient Attachments Exporter
============================

Exports all of a patient's attachments.

Motivation
----------

The patient chart export function is still kaput in Aprima. Accordingly, I wrote this handy-dandy Perl script to export (and decompress if needed) all of the files attached to the specified patient.

It's not pretty, but it works, and it works quickly.

Note that since this export utility is meant to be used on one patient at a time, much less care went into keeping records of what was exported, etc., than were I exporting all of the attachments in the DBMS at once.

General Program Outline
-----------------------

There are essentially three steps in the export process:

1)	Individuate the patient in the DBMS.

2)	Export all of the patient's files.

3)	Decompress these files as needed.

To accomplish (1):
a.	Prompt the user for the patient's first and last name, and attempt to individuate based on this data via DBI.
b.	If more than one patient has the same first & last names, then prompt the user to select a single patient from a menu with much more PHI (DOB, Address, etc.).

To accomplish (2) and (3):
a.	With a PersonUid in hand, get all of the AttachmentUid's for that patient.
b.	Check if a particular attachment is compressed.
c.	Export to a local directory (how? bsqldb?), naming all files per the Name, but decompressing using Uncompress::AnyUncompress.

Nota Bene's
-----------

I use the DBI module, which is a bit of a pain in the butt to set up. In the past year, I've tried and given up 2 times, finally succeeding on the 3rd. Be sure that you've got it set up, and that the included connection_test.pl script runs before going any further!

Usage
-----

(I'll put this in later, once the friggin' program is done!)

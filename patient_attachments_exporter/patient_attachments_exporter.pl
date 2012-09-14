use strict;
use warnings;

# A module that lets the user interact with Microsoft SQL Server.
use DBI;

# A module that turns off printing of STDIN, e.g. when entering a password.
use Term::ReadPassword;

#
# Main variable declarations.
#

my $PatientCount = 0; # The number of patients in the DB that match the first & last names.
my $FirstName; # The patient's first name.
my $LastName; # The patient's last name.
my @PHI; # The patient's fuller Protected Health Information.
my $PUid; # The patient's unique identifier.
my @AttachData; # An Array of Arrays that holds the attachment data, e.g. file name, file extension, etc.
my $AttachPath; # The destination directory's full path.
my $fmt = "D:\\data_transfer\\working_blob_export.fmt"; # The BCP format file path & name.

#
#Initial connection information.
#

# The data source.
print "Enter the data source name (check in </etc/odbc.ini>, e.g. 'TNH_TEST_MSS)': "
chomp(my $data_source = <>);

# The user name for the DBMS.
print "Enter the DBMS user name (check in Microsoft SQL Server, under <SERVER.SECURIT.LOGINS>, e.g. 'nimrod'): ";
chomp(my $user_name = <>);

# The password for the DBMS.
my $password = read_password("Enter the DBMS user name's password: ");

# Sets up the connection to the DBMS.
my $dbh = DBI -> connect("dbi:ODBC:DSN=$data_source; UID=$user_name; PWD=$password")
	or die "CONNECT ERROR! :: $DBI::err $DBI::errstr $DBI::state $!\n";

# Sets the maximum column width to 2 KB.
$dbh -> {LongReadLen} = 2 * 1024;

# Truncates any excess.
$dbh -> {LongTruncOk} = 1;

if ($dbh) {

	#
	# Individuate the patient, i.e. get a PersonUid.
	#

	# Prompt for good matches.
	until ($PatientCount > 0) {

		#
		# Collect basic patient personal information for individuation.
		#

		# First name.
		print "Enter the patient's first name: ";
		chomp($FirstName = <>);

		# Last name.
		print "Enter the patient's last name: ";
		chomp($LastName = <>);

		# SQL query to get the count of patient/s matching the first name & last name.
		my $sql = "
			select
					count(*)
				from
					prm.dbo.person
				where
						Firstname = '$FirstName'
					and
						LastName = '$LastName'";

		# Execute query.
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();

		# Store result.
		while (my @row = $sth -> fetchrow_array) {
			$PatientCount = "@row";
		}

		print "First Name = $FirstName & Last Name = $LastName could not be matched. Try again.\n" unless $PatientCount > 0;
	}

	# If there are one or more matches.
	if ($PatientCount >= 1) {

		# SQL query that will allow the user to select from a number of PHI columns that will individuate the patient.
		my $sql = "
			select
					FirstName,
					MiddleName,
					LastName,
					cast(BirthDate as date),
					SocialSecurityNumber,
					cast(PersonUid as varchar(max))
				from
					prm.dbo.person
				where
						FirstName = '$FirstName'
					and
						LastName = '$LastName'
					and
						PersonUid is not null";

		# Execute SQL query.
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();

		# Store in an array of arrays the query return.
		while (my @row = $sth -> fetchrow_array) {
			no warnings; # The select doesn't always populate every field, which yields an empty $_, which sets off warnings--which annoys me...
			push @PHI, [ @row ];
		}

		# Use a menu to determine the PersonUid.
		my $selector = -1; # Variable of the user selection input. Setting it to something that will fail the test.
		until (($selector =~ /^[0-9]+$/) and ($selector >= 0) and ($selector <= $#PHI)) {
			no warnings;
			print join("|", "Row", "First Name", "Middle Name", "Last Name", "DOB", "SSN"), "\n";
			for (0 .. $#PHI) {
				print join("|", $_, $PHI[$_][0], $PHI[$_][1], $PHI[$_][2], $PHI[$_][3], $PHI[$_][4]), "\n";
			}
			print "Select the ROW number of the patient you want: ";
			chomp($selector = <>);
			print "Bad entry: $selector.\n" unless (($selector =~ /^[0-9]$/) and ($selector >= 0) and ($selector <= $#PHI));
		}
		$PUid = $PHI[$selector][5];
	}

	#
	# Export files to a Windows directory.
	#

	# Get the export directory path.
	print 'Enter the full directory path you want the attachments exported to. Note, the path will most likely have to be on the same drive as the DBMS. Be sure that the directory exists--AND THAT IT HAS THE TWO SUBDIRECTORIES <compressed> AND <uncompressed>!!! E.G. <D:\\nimi_test\\data_transfer\\single_patient_file_export\\Doe_John\\>: ';
	chomp($AttachPath = <>); 

	# Get the necessary data to export the patient's BLOBs.
	my $sql = "
		select
				cast(a.AttachmentUid as varchar(max)),
				replace(replace(cast(AG.name as varchar(max)), char(13), ' '), char(10), ' '),
				replace(replace(cast(AG.notes as varchar(max)), char(13), ' '), char(10), ' '),
				a.FileExtension,
				case
					when
							a.CompressionUid is not null
						then
							'compressed\\'
						else
							'uncompressed\\'
				end
			from
				prm.dbo.RelAttachmentGroup as RAG 
			inner join
					prm.dbo.AttachmentGroup as AG 
				on
					RAG.AttachmentGroupUid = AG.AttachmentGroupUid
			inner join
					prm.dbo.attachment as a 
				on
					AG.AttachmentGroupUid = a.AttachmentGroupUid
			inner join
					prm_attachment.dbo.RawAttachment as RA 
				on
					a.AttachmentUid = RA.AttachmentUid
			where
					RAG.PersonUid = '$PUid' 
				and
					RA.AttachmentContent is not null 
				and
					AG.Name is not null";
	
	# Execute query.
	my $sth = $dbh -> prepare($sql);
	$sth -> execute();

	# Store result.
	while (my @row = $sth -> fetchrow_array) {
		no warnings;
		push @AttachData, [ @row ];
	}

	# Create the <notes> file handle to print the notes to.
	open(my $notes, ">>", "patient_file_notes/${LastName}_${FirstName}.txt") or die "Can't open ${LastName}_${FirstName}_file_notes.txt: $!\n"; 

	# Loop through all of the attachment data.
	for (0 .. $#AttachData) {

		# Fix any DB stupidity.
		$AttachData[$_][1] =~ s/\W+/_/g; # Replaces obnoxious characters with an underscore (e.g. white spaces, /'s, etc.).
		$AttachData[$_][1] =~ s/[[:alpha:]](\d{8})/$1/; # Dr. Sultana wanted the designating prefix removed from the file names. E.G. L20110924 --> 20110924.
		$AttachData[$_][3] =~ s/^([^\.])/.$1/; # Makes sure the file extension suffix has a '.' in it.

		# The file export query.
		my $sql = "
			declare \@sql varchar(1000)
			set \@sql = 'BCP ' +
				'\"select ' +
						'AttachmentContent ' +
					'from ' +
						'prm_attachment.dbo.RawAttachment ' +
					'where ' +
							'AttachmentUid = ''$AttachData[$_][0]''\" ' +
				'QueryOut ' +
					'$AttachPath' +
					'$AttachData[$_][4]' +
					'$AttachData[$_][1]' +
					'$AttachData[$_][3] ' +
				'-T ' +
				'-f ' +
					'$fmt ' +
				'-S ' +
					\@\@ServerName
			exec master.dbo.xp_CmdShell \@sql";

		# Execute query.
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();

		# Now to export the notes associated with each file, if any, into one single file.

		# Now to just print to that file!
		no warnings;
		print $notes "---------------$AttachData[$_][1]---------------\n";
		print $notes "$AttachData[$_][2]\n";

	}

	# Close the 'notes' file handle.
	close $notes;

	#
	# Disconnect from the DBMS.
	#

	$dbh -> disconnect;
}

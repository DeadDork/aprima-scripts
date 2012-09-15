use warnings;
use strict;

# This module checks for common compression algorithms, and decompresses accordingly.
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);

# The directory where the compressed files (might) be.
print "Enter the patient directory (N.B. don't specify to the further layers of <compressed> or <decompressed>!!!), e.g. </home/work_two/samba/share/TNH/projects/data_transfer/single_patient_file_export/patients/LASTNAME_FIRSTNAME/>: ";
chomp(my $export_dir = <>);

# The compressed file directory.
my $input = $export_dir . "compressed/";

# The uncompressed file directory.
my $output = $export_dir . "uncompressed/";

# Opens the compressed directory & decompresses any files it finds in it into the the <uncompressed> directory.
opendir(my $dir_handle, $input) or die "Couldn't open $input: $!\n";
while(readdir $dir_handle) {
	my $input = $input . $_;
	my $output = $output . $_;
	unless ($_ =~ /^\.+$/) {
		anyuncompress $input => $output or die "anyuncompress failed: $AnyUncompressError\n";
	}
}
closedir $dir_handle;

use warnings;
use strict;

# This module checks for common compression algorithms, and decompresses accordingly.
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);

# The directory where the compressed files (might) be.
print "Enter the patient directory (N.B. don't specify to the further layers of <compressed> or <decompressed>!!! Just to the directory above them, e.g. </home/work_two/samba/share/TNH/projects/data_transfer/single_patient_file_export/patients/LASTNAME_FIRSTNAME/>: ";
chomp(my $top_level_dir = <>);

# The compressed file directory.
my $compressed_dir = $top_level_dir . "compressed/";

# The uncompressed file directory.
my $uncompressed_dir = $top_level_dir . "uncompressed/";

# Opens the compressed directory & decompresses any files it finds in it into the the <uncompressed> directory.
opendir(my $dir_handle, $compressed_dir) or die "Couldn't open $input: $!\n";
while(readdir $dir_handle) {

	# The compressed file.
	my $compressed_file = $compressed_dir . $_;

	# The uncompressed file.
	my $uncompressed_file = $uncompressed_dir . $_;

	unless ($_ =~ /^\.+$/) {
		anyuncompress $compressed_file => $uncompressed_file or die "anyuncompress failed: $AnyUncompressError\n";
	}
}
closedir $dir_handle;

package App::PrettyDamQuick;

use Modern::Perl;
use Text::CSV::Slurp;
use 5.016;
our $VERSION = '0.01';
my $config_file_name = '.pdq';

=head1 NAME

App::PrettyDamQuick - Pretty Damn Quick (aka pdq) is a program to automate digital image ingestion 
from cameras and facilitate production workflows activities within a digital studio.

=head1 SYNOPSIS

#Installation
./go
pdq help

=head1 AUTHOR

Chris Alef, C<< <chris at crickertech.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Chris Alef.

This program is distributed under the CC0 1.0 Universal License:
L<http://creativecommons.org/publicdomain/zero/1.0/>

The person who associated a work with this deed has dedicated the work
to the public domain by waiving all of his or her rights to the work
worldwide under copyright law, including all related and neighboring
rights, to the extent allowed by law.

You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission. See Other
Information below.

Other Information:

* In no way are the patent or trademark rights of any person affected
by CC0, nor are the rights that other persons may have in the work or
in how the work is used, such as publicity or privacy rights. 

* Unless expressly stated otherwise, the person who associated a work
with this deed makes no warranties about the work, and disclaims
liability for all uses of the work, to the fullest extent permitted
by applicable law. 

* When using or citing the work, you should not imply endorsement by
the author or the affirmer.

=head1 METHODS
=head2 help
Displays version and usage information.
=cut

sub help {
    say(
        "Version: $VERSION

# Create a session
pdq new_session SessionName
cd SessionName

# Shoot images tethered to the system, ideally into a created session
pdq shoot optional_filename_prefix

# Rename the files matching the pattern in the \"shootname\" column to the pattern in the \"filename\" column
pdq rename filename.csv

# duplicate the image folder to a new location
pdq dupe /Volumes/ExternalDrive 

# build the XMP keyword sidecar files for all images matching the filename_prefix
# from a csv with a filename_prefix followed by columns of keywords
pdq generate_xmp /path/to/image-keyword-manifest.csv

# list what image prefixes are missing
pdq check_manifest /path/to/image-keyword-manifest.csv"
    );
}

=head2 new_session
Create a new session given a directory path.
Session name argument is required.
=cut

sub new_session {
    my $self         = shift;
    my $session_name = shift;
    unless ($session_name) {
        die 'Please provide a session name argument';
    }
    `mkdir $session_name`;
    `touch $session_name/$config_file_name`;
}

sub _check_session_directory {
    unless ( -e $config_file_name ) {
        die "You must change (cd) into a valid pdq session directory";
    }
}

=head2 shoot
Shoots some pictures tethered to the camera.
Filename prefix is optional.
=cut

sub shoot {
    my $self = shift;
    my $filename_prefix = shift || '';
    $self->_check_session_directory;

    #free up the usb port: http://tinyurl.com/hchdopy
    system "killall -SIGINT PTPCamera";

    # Shoot tethered photos using the optionally provided filename_prefix.
    say(`gphoto2 --capture-tethered --filename=$filename_prefix%03n.%C`);
}

=head2 rename
Renames filenames matching the filename prefix in the first column of a csv to the second column.
CSV filename is required.
=cut

sub rename {
    my $self = shift;
    $self->_check_session_directory;
    my $csv_filename = shift || '';
    unless ($csv_filename) {
        die "You must provide the path to a csv file.";
    }
    unless ( -e $csv_filename ) {
        die "Could not file file $csv_filename";
    }

    #open CSV
    my $data = Text::CSV::Slurp->load( file => $csv_filename )
      || die "Could not open $csv_filename";

    #for each line in the csv
    for my $line (@$data) {
        my $from_filename_pattern = $line->{'shootname'}
          || die "Could not find column \"shootname\" to rename from";
        my $to_filename_pattern = $line->{'filename'}
          || die "Could not find column \"filename\" to rename to";
        print "rename $from_filename_pattern to $to_filename_pattern\n";
        my $matching_filenames = `ls $from_filename_pattern*`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            print "  $from_filename_pattern matches 0 files\n";
            next;
        }

        #for each file matching the first column
        for my $filename (@filenames) {
            my $new_filename = $filename;
            $new_filename =~ s/$from_filename_pattern/$to_filename_pattern/g;
            `mv $filename $new_filename`;
            print "  Moved $filename to $new_filename\n";
        }
    }
}

=head2 dupe
Duplicates the files from the current session to a new location/session.
=cut

sub dupe {
    my $self                       = shift;
    my $destination_directory_path = shift;
    $self->_check_session_directory;
    say(`rsync -avhz . $destination_directory_path`);
}

=head2 generate_xmp
Creates xmp sidecar files for all files matching the prefixes in the first 
column of the provided csv, adding keywords for every subsequent column.
=cut

sub generate_xmp {
    my $self              = shift;
    my $manifest_filename = shift;
    $self->_check_session_directory;
    unless ($manifest_filename) {
        die 'You must provide the path to a csv containing'
          . ' the filename prefix pattern followed by keywords';
    }
    die 'generate_xmp not yet implemented';
}

=head2 check_manifest
=cut

sub check_manifest {
    my $self              = shift;
    my $manifest_filename = shift;
    $self->_check_session_directory;
    unless ($manifest_filename) {
        die 'You must provide the path to a csv containing'
          . ' the filename prefix pattern';
    }
    die 'check_manifest not yet implemented';
}

1;    # End of App::PrettyDamQuick

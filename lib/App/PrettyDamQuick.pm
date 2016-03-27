package App::PrettyDamQuick;

use Modern::Perl;
use Text::CSV::Slurp;
use 5.016;
our $VERSION = '0.01';
my $config_file_name = '.pdq';
my $csv_filename     = 'manifest.csv';

sub _check_session_directory {
    unless ( -e $config_file_name ) {
        die "You must change (cd) into a valid pdq session directory";
    }
}

=head1 NAME

App::PrettyDamQuick - Pretty Damn Quick (aka pdq) is a program to automate digital image ingestion 
from cameras and facilitate production workflows activities within a digital studio.

=head1 METHODS

=head2 new_session

Create a new session with the provided name.  Example:

  pdq new_session NewSession
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

=head2 shoot

Shoots some pictures tethered to the camera.  Example:

  pdq shoot my_file_name_prefix_
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

Renames filenames matching the shootname column to the filename column of manifest.csv. Example:

  pdq rename
=cut

sub rename {
    my $self = shift;
    $self->_check_session_directory;
    unless ( -e $csv_filename ) {
        die "Could not file file $csv_filename";
    }

    #open CSV
    my $data = Text::CSV::Slurp->load( file => $csv_filename )
      || die "Could not open $csv_filename";

    #for each line in the csv
    for my $line (@$data) {
        my $from_filename_pattern = $line->{'shootname'}
          || die
"Could not find column \"shootname\" to rename from or shootname is blank";
        my $to_filename_pattern = $line->{'filename'}
          || die
"Could not find column \"filename\" to rename to or shootname is blank";
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

Duplicates the files from the current session to a new location/session.  Example:

  pdq dupe /Volume/DriveName
=cut

sub dupe {
    my $self                       = shift;
    my $destination_directory_path = shift;
    $self->_check_session_directory;
    say(`rsync -avhz . $destination_directory_path`);
}

=head2 update_xmp

Updates xmp sidecar files with the keywords from manifest.csv. Example:

  pdq update_xmp
=cut

sub update_xmp {
    my $self = shift;
    $self->_check_session_directory;
    my $data = Text::CSV::Slurp->load( file => $csv_filename )
      || die "Could not open $csv_filename";
    for my $line (@$data) {
        my $to_filename_pattern = $line->{'filename'}
          || die "Could not find column \"filename\" to apply keywords to";
        my $keywords = $line->{'keywords'}
          || die
          "Could not find column \"keywords\" containing keywords to apply";
        my @keywords = split ',', $keywords;
        if ( scalar @keywords < 1 ) {
            print "  no keywords to apply\n";
            next;
        }
        print "updating xmps for $to_filename_pattern\n";
        my $matching_filenames = `ls $to_filename_pattern*.xmp 2>/dev/null`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            print "  $to_filename_pattern is missing\n";
            next;
        }
        for my $filename (@filenames) {
            print "  applying keywords $keywords to $filename\n";
            my $subject_string = join '" -Subject="', @keywords;
            print "  exiftool -Subject=\"$subject_string\" $filename\n";
            `exiftool -Subject="$subject_string" $filename`;
            `rm *.xmp_original`;
        }
    }
}

=head2 check_manifest

Verifies that the session directory contains all of the filename patterns in the manifest and lists the missing files. Example:

  pdq check_manifest
=cut

sub check_manifest {
    my $self = shift;
    $self->_check_session_directory;
    my $data = Text::CSV::Slurp->load( file => $csv_filename )
      || die "Could not open $csv_filename";
    for my $line (@$data) {
        my $to_filename_pattern = $line->{'filename'}
          || die "Could not find column \"filename\" to apply keywords to";
        my $matching_filenames = `ls $to_filename_pattern*.xmp 2>/dev/null`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            print "$to_filename_pattern is missing\n";
            next;
        }
    }
}

=head2 help

Displays version and usage information.  Example:

  pdq help
=cut

sub help {
    say("Version: $VERSION");
	`perldoc App::PrettyDamQuick`;
}

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
=cut

1;    # End of App::PrettyDamQuick

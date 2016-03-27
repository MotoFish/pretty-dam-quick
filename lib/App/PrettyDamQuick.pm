package App::PrettyDamQuick;

use 5.016;
use Modern::Perl;
use Text::CSV::Slurp;
our $VERSION = '0.02';
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
        say("rename $from_filename_pattern to $to_filename_pattern");
        my $matching_filenames = `ls $from_filename_pattern* 2>/dev/null`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            say("  $from_filename_pattern matches 0 files");
            next;
        }

        #for each file matching the first column
        for my $filename (@filenames) {
            my $new_filename = $filename;
            $new_filename =~ s/$from_filename_pattern/$to_filename_pattern/g;
            `mv $filename $new_filename`;
            say("  Moved $filename to $new_filename");
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
            say("  no keywords to apply");
            next;
        }
        say("updating xmps for $to_filename_pattern");
        my $matching_filenames = `ls $to_filename_pattern*.xmp 2>/dev/null`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            next;
        }
        for my $filename (@filenames) {
            say("  $filename: applying keywords $keywords");
            my $subject_string = join '" -Subject="', @keywords;
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
    my %extra_filenames = map { $_ => 1 } split /\n/, `ls`;
    say("Missing files:");

    #display the missing filenames
    for my $line (@$data) {
        my $to_filename_pattern = $line->{'filename'}
          || die "Could not find column \"filename\" to apply keywords to";

        #find filenames matching the line of the manifest
        my $matching_filenames = `ls $to_filename_pattern*.xmp 2>/dev/null`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            say("  $to_filename_pattern");
            next;
        }

        #remove extra filenames that match names in the manifest
        for my $filename ( keys %extra_filenames ) {
            if ( $filename =~ /^$to_filename_pattern/ ) {
                delete $extra_filenames{$filename};
            }
        }
    }

    #display the extra filenames
    if ( scalar keys %extra_filenames > 0 ) {
        say("Extra files:");
        for my $filename ( keys %extra_filenames ) {
            say("  $filename");
        }
    }
}

=head2 help

Displays version and usage information.  Example:

  pdq help
=cut

sub help {
    say("Version: $VERSION");
    say(`perldoc App::PrettyDamQuick`);
}

1;    # End of App::PrettyDamQuick

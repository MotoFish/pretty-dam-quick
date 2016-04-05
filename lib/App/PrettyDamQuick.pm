package App::PrettyDamQuick;

use strict;
use Modern::Perl 1.20150127;
use Text::CSV::Slurp 1.03;
my $config_file_name = '.pdq';
my $csv_filename     = 'manifest.csv';

sub _check_session_directory {
    unless ( -e $config_file_name ) {
        die "You must change (cd) into a valid pdq session directory";
    }
}

# ABSTRACT: Pretty Damn Quick (aka pdq) is a program to automate digital image ingestion from cameras and facilitate production workflows activities within a digital studio.

=head1 NAME
App::PrettyDamQuick

=head1 METHODS

=method new_session

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

=method init

Initializes the current directory for use with pdq.
=cut

sub init {
    my $self = shift;
    my $pwd  = `pwd`;
    say("Initializing directory $pwd for use with pdq.");
    `touch $config_file_name`;
}

=method shoot

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

=method rename

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
"Could not find column \"shootname\" in manifest.csv or shootname is blank";
        my $to_filename_pattern = $line->{'filename'}
          || die
"Could not find column \"filename\" in manifest.csv or shootname is blank";
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

=method dupe

Duplicates the files from the current session to a new location/session.  Example:

  pdq dupe /Volume/DriveName
=cut

sub dupe {
    my $self                       = shift;
    my $destination_directory_path = shift;
    $self->_check_session_directory;
    say(`rsync -avhz . $destination_directory_path`);
}

=method update_xmp

Updates xmp sidecar files with the keywords and description from manifest.csv. Example:

  pdq update_xmp
=cut

sub update_xmp {
    my $self = shift;
    $self->_check_session_directory;
    my $data = Text::CSV::Slurp->load( file => $csv_filename )
      || die "Could not open $csv_filename";
    for my $line (@$data) {
        my $to_filename_pattern = $line->{'filename'}
          || die "Could not find column \"filename\" in manifest.csv";
        my $keywords = $line->{'keywords'}
          || die "Could not find column \"keywords\" in manifest.csv";
        my @keywords = split ',', $keywords;
        if ( scalar @keywords < 1 ) {
            say("  no keywords to apply");
            next;
        }
        my $matching_filenames = `ls $to_filename_pattern*.xmp 2>/dev/null`;
        my @filenames = split /\n/, $matching_filenames;
        if ( scalar @filenames < 1 ) {
            next;
        }
        say("updating xmps for $to_filename_pattern");
        for my $filename (@filenames) {
            say("  $filename: applying keywords $keywords");
            my $subject_string = join '" -Subject="', @keywords;
            if ( my $description = $line->{'description'} ) {
                $description =~ s/\"//g;
                say("  $filename: applying Description $description");
                $subject_string =
                  "$subject_string\" -Description=\"$description";
            }
            `exiftool -Subject="$subject_string" $filename`;
            `rm *.xmp_original`;
        }
    }
}

=method check_manifest

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
        my $matching_filenames = `ls $to_filename_pattern*.* 2>/dev/null`;
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

=method help

Displays version and usage information.  Example:

  pdq help
=cut

sub help {
    say(`perldoc App::PrettyDamQuick`);
}

1;

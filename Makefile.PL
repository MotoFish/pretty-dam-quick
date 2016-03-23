use strict;
use 5.016;
use inc::Module::Install;

name 'App-PrettyDamQuick';
all_from 'lib/App/PrettyDamQuick.pm';
author q{Chris Alef <chris@crickertech.com>};
license 'cc0';

perl_version 5.016;

tests_recursive('t');

resources(
    homepage   => 'https://github.com/MotoFish/pretty-dam-quick',
    license    => 'http://creativecommons.org/publicdomain/zero/1.0/',
    repository => 'https://github.com/MotoFish/pretty-dam-quick',
    bugtracker => 'https://github.com/MotoFish/pretty-dam-quick/issues',
);

configure_requires( 'Module::Install' => 0, );

build_requires(
    'Test::More'          => 0,
    'Test::Pod::Coverage' => 1.10,
    'Test::CheckManifest' => 1.29,
);

requires(
    'Image::ExifTool' => 10.10,
    'Modern::Perl'    => 1.20150127,
    'Try::Tiny'       => 0.24
);

#its hacky, but this whole package is little more than some conveniences around other tools
#this could be moved to perl, but portability isn't really an objective (yet)
requires_external_bin 'cowsay';
requires_external_bin 'gphoto2';
requires_external_bin 'killall';
requires_external_bin 'mkdir';
requires_external_bin 'rsync';
requires_external_bin 'touch';

install_script( 'script/pdq', );

install_as_cpan;
auto_install;
WriteAll;

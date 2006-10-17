use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc','lib','../lib';
use ExtUtils::MY_Metafile qw(my_metafile);

my_metafile {
  no_index => {
    directory => [ qw(sample t inc), ],
  },
  license  => 'perl',
};

WriteMakefile(
  NAME                => 'YourModule',
  AUTHOR              => 'module author <   @cpan.org>',
  VERSION_FROM        => 'YourModule.pm',
  ABSTRACT_FROM       => 'YourModule.pm',
  PL_FILES            => {},
  PREREQ_PM => {
      'Test::More' => 0,
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'ExtUtils-MY_Metafile-*' },
);

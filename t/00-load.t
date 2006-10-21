#! perl -T

use Test::More tests => 1;

BEGIN {
	$ExtUtils::MY_Metafile::DIAG_VERSION = 1;
	use_ok( 'ExtUtils::MY_Metafile' );
}

diag( "Testing ExtUtils::MY_Metafile $ExtUtils::MY_Metafile::VERSION, Perl $], $^X" );

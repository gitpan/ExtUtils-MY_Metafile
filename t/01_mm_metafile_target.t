#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01_mm_metafile_target.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use Test::Exception;

BEGIN{ use_ok('ExtUtils::MY_Metafile'); }
require ExtUtils::MakeMaker;

&test_01_basic;

# -----------------------------------------------------------------------------
# test_01_basic.
#
sub test_01_basic
{
	lives_and(sub{
		my_metafile(); # set MM::metafile_target.
		my $dummy_mm = _dummy_mm({ DISTNAME => 'DUMMY' });
		my $maketext = $dummy_mm->MM::metafile_target();
		ok($maketext, '[basic] MM::metafile_target() returns something.');
	}, "[basic] (execution)");
	1;
}


# -----------------------------------------------------------------------------
# dummy stub for ExtUtils::MakeMaker.
#
sub _dummy_mm
{
	@MM::Dummy::ISA = qw(MM);
	bless shift, "MM::Dummy";
}
sub MM::Dummy::echo
{
	my $this = shift;
	my $text = shift;
	my $out  = shift;
	my @lines = map{ qq{\$(NOECHO) \$(ECHO) "$_"} } split(/\n/, $text);
	$lines[0] .= " > $out";
	foreach my $line (@lines[1..$#lines])
	{
		$line .= " >> $out";
	}
	@lines;
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

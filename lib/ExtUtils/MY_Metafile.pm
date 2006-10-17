## ----------------------------------------------------------------------------
#  ExtUtils::MY_Metafile
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package ExtUtils::MY_Metafile;
use strict;
use warnings;

our $VERSION = '0.02';
our @EXPORT = qw(my_metafile);

1;

# -----------------------------------------------------------------------------
# for: use inc::ExtUtils::MY_Metafile;
#
sub inc::ExtUtils::MY_Metafile::import
{
	push(@inc::ExtUtils::MY_Metafile::ISA, __PACKAGE__);
	goto &import;
}

# -----------------------------------------------------------------------------
# import.
#
sub import
{
	my $pkg = shift;
	my @syms = (!@_ || grep{/^:all$/}@_) ? @EXPORT : @_;
	my $callerpkg = caller;
	
	foreach my $name (@syms)
	{
		my $sub = $pkg->can($name);
		$sub or die "no such export tag: $name";
		no strict 'refs';
		*{$callerpkg.'::'.$name} = $sub;
	}
}

# -----------------------------------------------------------------------------
# my_metafile({...});
#
sub my_metafile
{
	my $meta = shift;
	
	# override.
	*MM::metafile_target = sub{
		_mm_metafile(shift, $meta);
	};
}

# -----------------------------------------------------------------------------
# _mm_metafile($MM, {...});
#
sub _mm_metafile
{
    # from MakeMaker-6.30.
    my $self = shift;
    my $param = shift;
    
    return <<'MAKE_FRAG' if $self->{NO_META};
metafile:
	$(NOECHO) $(NOOP)
MAKE_FRAG

    my $requires = $param->{requires} || $self->{PREREQ_PM};
    my $prereq_pm = '';
    foreach my $mod ( sort { lc $a cmp lc $b } keys %$requires ) {
        my $ver = $self->{PREREQ_PM}{$mod};
        $prereq_pm .= sprintf "    %-30s %s\n", "$mod:", $ver;
    }
    chomp $prereq_pm;
    $prereq_pm and $prereq_pm = "requires:\n".$prereq_pm;

    my $no_index = $param->{no_index};
    if( !$no_index )
    {
      my @dirs = grep{-d $_} (qw(example examples inc t));
      $no_index = @dirs && +{ directory => \@dirs };
    }
    $no_index = $no_index ? _yaml_out({no_index=>$no_index}) : '';
    chomp $no_index;
    if( $param->{no_index} && !$ENV{NO_NO_INDEX_CHECK} )
    {
      foreach my $key (keys %{$param->{no_index}})
      {
        # dir is in spec-v1.2, directory is from spec-v1.3? (blead).
        $key =~ /^(file|dir|directory|package|namespace)$/ and next;
        warn "$key is invalid field for no_index.\n";
      }
    }

    my $abstract = '';
    if( $self->{ABSTRACT} )
    {
      $abstract = _yaml_out({abstract => $self->{ABSTRACT}});
    }elsif( $self->{ABSTRACT_FROM} && open(my$fh, "< $self->{ABSTRACT_FROM}") )
    {
      while(<$fh>)
      {
        /^=head1 NAME$/ or next;
        (my $pkg = $self->{DISTNAME}) =~ s/-/::/g;
        while(<$fh>)
        {
          /^=/ and last;
          /^(\Q$pkg\E\s+-+\s+)(.*)/ or next;
          $abstract = $2;
          last;
        }
        last;
      }
      $abstract = $abstract ? _yaml_out({abstract=>$abstract}) : '';
    }
    chomp $abstract;

    my $yaml = {};
    $yaml->{name}         = $self->{DISTNAME};
    $yaml->{version}      = $self->{VERSION};
    $yaml->{version_from} = $self->{VERSION_FROM};
    $yaml->{installdirs}  = $self->{INSTALLDIRS};
    $yaml->{author}       = $self->{AUTHOR};
    foreach my $key (keys %$yaml)
    {
      if( $yaml->{$key} )
      {
        my $pad = ' 'x(12-length($key));
        $yaml->{$key} = sprintf('%s:%s %s', $key, $pad, $yaml->{$key});
      }else
      {
        $yaml->{$key} = "#$key:";
      }
    }
    $yaml->{abstract} = $abstract  || "#abstract:";
    $yaml->{requires} = $prereq_pm || "#requires:";
    $yaml->{no_index} = $no_index;
    
    $yaml->{distribution_type} = 'distribution_type: module';
    $yaml->{generated_by} = "generated_by: ExtUtils::MY_Metafile version $VERSION";
    $yaml->{'meta-spec'}  = "meta-spec:\n";
    $yaml->{'meta-spec'} .= "  version: 1.2\n";
    $yaml->{'meta-spec'} .= "  url: http://module-build.sourceforge.net/META-spec-v1.2.html\n";
    
    # customize yaml.
    my $extra = '';
    foreach my $key (sort keys %$param)
    {
      $key eq 'no_index' and next;
      my $line = _yaml_out->({$key=>$param->{$key}});
      if( $yaml->{$key} )
      {
        chomp $line;
        $yaml->{$key} = $line;
      }else
      {
        $extra .= $line;
      }
    }
    $yaml->{extra}    = $extra;
    
    my $meta = <<YAML;
# http://module-build.sourceforge.net/META-spec.html
#XXXXXXX This is a prototype!!!  It will change in the future!!! XXXXX#
$yaml->{name}
$yaml->{version}
$yaml->{version_from}
$yaml->{installdirs}
$yaml->{author}
$yaml->{abstract}
$yaml->{requires}
$yaml->{no_index}
$yaml->{extra}
$yaml->{distribution_type}
$yaml->{generated_by}
$yaml->{'meta-spec'}
YAML
    #print "$meta";

    my @write_meta = $self->echo($meta, 'META_new.yml');

    my $format;
    if( $ExtUtils::MakeMaker::VERSION >= 6.30 )
    {
        $format = <<'MAKE_FRAG';
# MM 6.30 or later.
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	%s
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
MAKE_FRAG
    }else
    {
        $format = <<'MAKE_FRAG';
# MM 6.25 or earlier.
metafile :
	$(NOECHO) $(ECHO) Generating META.yml
	%s
	-$(NOECHO) $(MV) META_new.yml META.yml
MAKE_FRAG
    }
    sprintf $format, join("\n\t", @write_meta);
}

# -----------------------------------------------------------------------------
# generate simple yaml.
#
sub _yaml_out
{
	my $obj   = shift;
	
	my $depth = shift || 0;
	my $out   = '';
	
	if( !defined($obj) )
	{
		$out = "  "x$depth."~\n";
	}elsif( !ref($obj) )
	{
		$out = "  "x$depth.$obj."\n";
	}elsif( ref($obj)eq'ARRAY' )
	{
		my @e = map{_yaml_out->($_, $depth+1)} @$obj;
		@e = map{ "  "x$depth."- ".substr($_, ($depth+1)*2)} @e;
		$out = join('', @e);
		$out ||= "  "x$depth."[]";
	}elsif( ref($obj)eq'HASH' )
	{
		foreach my $k (sort keys %$obj)
		{
			$out .= "  "x$depth."$k:";
			$out .= ref($obj->{$k}) ? "\n"._yaml_out($obj->{$k}, $depth+1) : " $obj->{$k}\n";
		}
		$out ||= "  "x$depth."{}";
	}else
	{
		die "not supported: $obj";
	}
	$out;
}

# -----------------------------------------------------------------------------
# End of Code.
# -----------------------------------------------------------------------------
__END__

=head1 NAME

ExtUtils::MY_Metafile - META.yml customize with ExtUtil::MakeMaker

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  # in your Makefile.PL
  use ExtUtils::MakeMaker;
  use inc::ExtUtils::MY_Metafile;
  
  my_metafile {
    no_index => {
      directory => [ qw(inc example t), ],
    },
    license  => 'perl',
  };
  
  WriteMakefile(
    ...
  );

=head1 EXPORT

This module exports one function.

=head1 FUNCTIONS

=head2 my_metafile {meta-param...};

Takes one hash-reference.

  my_metafile {
    no_index => {
      directory => [ qw(inc example t), ],
    },
    license  => 'perl',
  };

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-extutils-my_metafile at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-MY_Metafile>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtUtils::MY_Metafile

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtUtils-MY_Metafile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-MY_Metafile>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MY_Metafile>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtUtils-MY_Metafile>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

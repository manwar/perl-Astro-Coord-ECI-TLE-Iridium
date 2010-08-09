package Astro::Coord::ECI::Build;

use strict;
use warnings;

use base qw{ Module::Build };

use Carp;
use File::Spec;

my @generated_dir = qw{ xt author generated };
my @hide = qw{ Date::Manip Time::y2038 };

{
    my $done;
    my $hider;

    sub _get_hider {
	$done and return $hider;
	$done = 1;
	foreach my $module ( qw{
		Test::Without::Module
		Devel::Hide
	    } ) {
	    eval "require $module; 1"
		and return ( $hider = $module );
	}
	return $hider;
    }
}

sub _get_tests_without_optional_modules {
    my @args = @_;
    _get_hider() or return;
    my @cleanup;
    @args or @args = _get_general_tests();
    foreach my $path ( @args ) {
	push @cleanup, File::Spec->catfile( @generated_dir,
	    ( File::Spec->splitpath( $path ) )[2] );
    }
    return @cleanup;
}

{

    my @general_tests;

    sub _get_general_tests {
	@general_tests and return @general_tests;
	my $th;
	opendir $th, 't'
	    or die "Unable to open directory t: $!\n";
	while ( defined( my $fn = readdir $th ) ) {
	    '.' eq substr $fn, 0, 1 and next;
	    my $path = File::Spec->catfile( 't', $fn );
	    -f $path or next;
	    push @general_tests, $path;
	}
	closedir $th;
	return @general_tests;
    }
}


sub ACTION_make_optional_modules_tests {
    my ( $self, @args ) = @_;

    my $hider = _get_hider() or do {
#	warn "Neither Devel::Hide nor Test::Without::Module available\n";
	return;
    };

    my $gendir = File::Spec->catdir( @generated_dir );

    -d $gendir
	or mkdir $gendir
	or die "Unable to create $gendir: $!\n";

    foreach my $ip ( _get_general_tests() ) {
	my ( $op ) = _get_tests_without_optional_modules( $ip );
	-f $op and next;
	local $/ = undef;
	open my $ih, '<', $ip or die "Unable to open $ip: $!\n";
	my $content = <$ih>;
	close $ih;
	print "Creating $op\n";
	open my $oh, '>', $op or die "Unable to open $op: $!\n";
	print { $oh } <<EOD;
package main;

use strict;
use warnings;

use $hider qw{ @hide };

require '$ip';
EOD
	close $oh;
    }
}

sub ACTION_authortest {
    my ( $self, @args ) = @_;

    my @depends_on = ( qw{ build make_optional_modules_tests } );
    -e 'META.yml' or push @depends_on, 'distmeta';
    $self->depends_on( @depends_on );
    my @test_files = qw{ t xt/author };
    my $gendir = File::Spec->catdir( @generated_dir );
    -d $gendir and push @test_files, $gendir;
    $self->test_files( @test_files );
    $self->depends_on( 'test' );

    return;
}

1;

__END__

=head1 NAME

Astro::Coord::ECI::Build - Extend Module::Build for Astro::Coord::ECI

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build authortest # supplied by this module
 ./Build install

=head1 DESCRIPTION

This extension of L<Module::Build|Module::Build> adds the following
action to those provided by L<Module::Build|Module::Build>:

  authortest

=head1 ACTIONS

This module provides the following action:

=over

=item authortest

This action runs not only those tests which appear in the F<t>
directory, but those that appear in the F<xt/author> directory. The
F<xt/author> tests are provided for information only, since some of them
(notably F<xt/author/critic.t> and F<xt/author/pod_spelling.t>) are very
sensitive to the configuration under which they run.

Some of the F<xt/author> tests require modules that are not named as
requirements. These should disable themselves if the required modules
are not present.

This test is sensitive to the C<verbose=1> argument, but not to the
C<--test_files> argument.

=item make_optional_modules_tests

This action creates the tests in the F<xt/author/generated> directory.
These generally duplicate the tests in the F<t> directory, but the
optional modules are made unavailable using either
L<Test::Without::Module|Test::Without::Module> or
L<Devel::Hide|Devel::Hide>, in that order. If neither of these modules
is available, nothing is done.

There should be no need to invoke this action directly, since the
C<authortest> action depends on it.

=back

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010, Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

package Nephia::Setup;
use strict;
use warnings;
use File::Spec;
use Path::Class;
use Cwd;
use String::CamelCase qw( decamelize );

sub create {
    my ( $class ) = @_;

    my $approot = approot( $class );
    $approot->mkpath( 1, 0755 );
    map {
        $approot->subdir($_)->mkpath( 1, 0755 );
    } qw( lib etc view root root/static t );

    $approot->file('app.psgi')->spew(
        psgi_file( $class )
    );

    my @classpath = split(/::/, $class. '.pm');
    my $classfile = pop( @classpath );

    $approot->subdir('lib', @classpath)->mkpath( 1, 0755 ) if @classpath;
    push @classpath, $classfile;

    $approot->file('lib', @classpath)->spew(
        app_class_file( $class )
    );

    $approot->file('view', 'index.tx')->spew(
        index_template_file( $class )
    );

    $approot->file('Makefile.PL')->spew(
        makefile( $class )
    );

    $approot->file('t','001_basic.t')->spew(
        basic_test_file( $class )
    );
}

sub approot {
    my ( $class ) = @_;
    $class =~ s/::/-/g;
    return dir(
        File::Spec->catfile( 
            getcwd(),
            decamelize($class), 
        )
    );
}

sub psgi_file {
    my $class = shift;
    return <<EOF;
use strict;
use warnings;
use FindBin;

use lib ("\$FindBin::Bin/lib", "\$FindBin::Bin/extlib/lib/perl5");
use $class;
$class->run();
EOF
}

sub app_class_file {
    my $class = shift;
    my $classname = $class; $classname =~ s/::/-/g;
    return <<EOF;
package $class;
use strict;
use warnings;
use Nephia;

our \$VERSION = 0.01;

path '/' => sub {
    my \$req = shift;
    return {
        template => 'index.tx',
        title => '$class',
    };
};

1;
__END__

=head1 NAME

$classname - Web Application

=head1 SYNOPSIS

  \$ plackup

=head1 DESCRIPTION

$class is web application based Nephia.

=head1 AUTHOR

clever guy

=head1 SEE ALSO

Nephia

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
EOF
}

sub index_template_file {
    return <<EOF;
<html>
<head>
  <link rel="shortcut icon" href="/static/favicon.ico" />
  <title><: \$title :> - powerd by Nephia</title>
</head>
<body>
  <h1><: \$title :></h1>
  <p>Generated by Nephia</p>
</body>
</html>
EOF
}

sub makefile {
    my $class = shift;
    my $classpath = File::Spec->catfile( 'lib', split(/::/, $class. '.pm') );
    return <<EOF;
use inc::Module::Install;
all_from '$classpath';

requires 'Nephia' => 0.01;

tests 't/*.t';

test_requires 'Test::More';

WriteAll;
EOF
}

sub basic_test_file {
    my $class = shift;
    return <<EOF;
use strict;
use warnings;
use Test::More;
BEGIN {
    use_ok( '$class' );
}
done_testing;
EOF
}

1;

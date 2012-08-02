package Nephia;
use strict;
use warnings;

use Exporter 'import';
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use Plack::App::URLMap;
use Nephia::View;
use JSON ();
use FindBin;
use Data::Validator;

our $VERSION = '0.01';
our @EXPORT = qw( path req res run validate );
our $MAPPER = Plack::App::URLMap->new;
our $VIEW;

sub path ($&) {
    my ( $path, $code ) = @_;

    my $caller = caller();
    $MAPPER->map( $path => sub {
        my $env = shift;
        my $req = Plack::Request->new( $env );
        no strict qw/ refs subs /;
        no warnings qw/ redefine /;
        local *{$caller."::req"} = sub{ $req };
        my $res = $code->( $req );
        if ( ref $res eq 'HASH' ) {
            return eval { $res->{template} } ? 
                render( $res ) : 
                json_res( $res )
            ;
        }
        elsif ( ref $res eq 'Plack::Response' ) {
            $res->content_length( length( $res->content ) );
            return $res->finalize;
        }
        else {
            return $res;
        }
    } );
}

sub res (&) {
    my $code = shift;
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    {
        no strict qw( refs subs );
        no warnings qw( redefine );
        my $caller = caller();
        map { 
            my $method = $_;
            *{$caller.'::'.$method} = sub (@) { 
                return $res->$method( @_ );
            };
        } qw( 
            status headers body header
            content_type content_length
            content_encoding redirect cookies
        );
        $code->();
    }
    return $res;
}

sub run {
    my ( $class, %options ) = @_;
    $VIEW = Nephia::View->new( %{$options{view}} );
    return builder { 
        enable "Static", root => "$FindBin::Bin/root/", path => qr{^/static/};
        $MAPPER->to_app;
    };
}

sub json_res {
    my $res = shift;
    my $body = JSON->new->utf8->encode( $res );
    return [ 200, 
        [ 'Content-type' => 'application/json', 
          'Content-length' => length $body 
        ],
        [ $body ]
    ];
}

sub render {
    my $res = shift;
    my $body = $VIEW->render( $res->{template}, $res );
    return [ 200,
        [ 'Content-type' => 'text/html; charset=UTF-8',
          'Content-length' => length $body
        ],
        [ $body ]
    ];
}

use Data::Dumper;

sub validate (%) {
    my $caller = caller();
    no strict qw/ refs subs /;
    no warnings qw/ redefine /;
    my $req = *{$caller.'::req'};
    my $validator = Data::Validator->new(@_);
    return $validator->validate( $req->()->parameters->as_hashref_mixed );
}

1;
__END__

=head1 NAME

Nephia - Mini WAF

=head1 SYNOPSIS

  ### Get started the Nephia!
  $ nephia-setup MyApp
  
  ### And, plackup it!
  $ cd myapp
  $ plackup

=head1 DESCRIPTION

Nephia is a mini web-application framework.

=head1 MOUNT A CONTROLLER

Use "path" function as following in lib/MyApp.pm . 

First argument is path for mount a controller. This must be string.

Second argument is controller-logic. This must be code-reference.

In controller-logic, you may get Plack::Request object as first-argument, 
and controller-logic must return response-value as hash-reference or Plack::Response object.

=head2 Basic controller - Makes JSON response

Look this examples.

  path '/foobar' => sub {
      my ( $req ) = @_;
      # Yet another syntax is following.
      # my $req = req;
  
      return {
          name => 'MyApp',
          query => $req->param('q'),
      };
  };

This controller outputs response-value as JSON, and will be mounted on "/foobar".

=head2 Use templates - Render with Xslate (Kolon-syntax)

  path '/' => sub {
      return {
          template => 'index.tx',
          title => 'Welcome to my homepage!',
      };
  };

Attention to "template" attribute. 
If you specified it, controller searches template file from view-directory and render it.

=head2 Makes any response - Using "res" function

  path '/my-javascript' => sub {
      return res {
          content_type( 'text/javascript' );
          body( 'alert("Oreore!");' );
      };
  };

"res" function returns Plack::Response object with customisable DSL-like syntax.

=head1 STATIC CONTENTS ( like as images, javascripts... )

You can look static-files that is into root directory via HTTP.

=head1 VALIDATE PARAMETERS

You may use validator with validate function.

  path '/some/path' => sub {
      my $params = validate
          name => { isa => 'Str', default => 'Nameless John' },
          age => { isa => 'Int' }
      ;
  };

See documentation of validate method and Data::Validator.

=head1 FUNCTIONS

=head2 path $path, $coderef_as_controller;

Mount controller on specified path.

=head2 req

Return Plack::Request object. You can call this function in coderef that is argument of path().

=head2 res $coderef

Return Plack::Response object with customisable DSL-like syntax.

=head2 validate %validation_rules

Return validated parameters as hashref. You have to set validation rule as like as Data::Validator's instantiate arguments.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

Plack::Request

Plack::Response

Plack::Builder

Text::Xslate

Text::Xslate::Syntax::Kolon

JSON

Data::Validator

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

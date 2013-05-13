package HTTP::Parser::Joyent;
our $VERSION = '0.01';
use 5.10.1;
use strict;
use warnings;
use Carp();
use English qw(-no_match_vars);
use Data::Dumper;
use constant HTTP_REQUEST  => 0;
use constant HTTP_RESPONSE => 1;
use constant HTTP_BOTH     => 2;
use Devel::Peek qw(Dump);
use Sub::Exporter(
	'-setup' => {
		exports => [
			'new', 'parse', 'DESTROY',
			'HTTP_REQUEST', 'HTTP_RESPONSE', 'HTTP_BOTH',
#			'print_parser_data', 'get_self_from_parser',
			'http_method', 'http_version', 'should_keep_alive',
		],
		groups => {
			typical => [ qw(new parse DESTROY http_method http_version should_keep_alive) ],
		},
	},
);

require XSLoader;
XSLoader::load( 'HTTP::Parser::Joyent', $VERSION );

sub on_message_begin { 0; }    # http_cb
sub on_url { 0; }              # http_data_cb
sub on_status_complete { 0; }  # http_cb
sub on_header_field { 0; }     # http_data_cb
sub on_header_value { 0; }     # http_data_cb
sub on_headers_complete { 0; } # http_cb
sub on_body { 0; }             # http_data_cb
sub on_message_complete { 0; } # http_cb

sub new {
	my( $class, %args ) = @ARG;
	$args{type} //= HTTP_REQUEST;
	my $self = bless { %args }, $class;
	$self->{parser} = HTTP_REQUEST == $self->{type} ? $self->HTTP::Parser::Joyent::_new_request_http_parser : $self->HTTP::Parser::Joyent::_new_response_http_parser;
	return $self;
}

sub DESTROY {
	my( $self ) = @ARG;
	HTTP::Parser::Joyent::_free_parser( $self->{parser} );
	return;
}

1;

__END__

=head1 NAME

HTTP::Parser::Joyent - an HTTP request parser

=head1 SYNOPSIS

  use HTTP::Parser::Joyent qw(:typical);

=head1 DESCRIPTION

HTTP::Parser::Joyent is a HTTP parser based on ry's http-parser that can be used either for writing a synchronous HTTP server or an event-driven server.

=head1 EXPORTS

With :typical the following methods are imported:

  new
  parse
  http_method
  http_version
  should_keep_alive
  DESTROY
  HTTP_REQUEST
  HTTP_RESPONSE
  HTTP_BOTH

=head1 METHODS

=head2 new( type => $type )

=head3 type => 0

HTTP_REQUEST

=head3 type => 1

HTTP_RESPONSE

=head3 type => 2

HTTP_BOTH

=head2 parse

Tries to parse given request string. Returns the number of bytes parsed.

=head2 http_method

=head2 http_version

=head2 should_keep_alive

=head2 DESTROY


=head2 get_env

For the name of the variables inserted, please refer to the PSGI specification.

=head1 CONSTANTS

=head2 HTTP_REQUEST

=head2 HTTP_RESPONSE

=head2 HTTP_BOTH

=head1 ABSTRACT METHODS

See also, the available callbacks in http-parser.

These should return zero on success, non-zero otherwise.

Non-zero return will abort parsing.

=head2 on_message_begin( )

=head2 on_url( $buffer, $length )

=head2 on_status_complete( )

=head2 on_header_field( $buffer, $length )

=head2 on_header_value( $buffer, $length )

=head2 on_headers_complete( )

=head2 on_body( $buffer, $length )

=head2 on_message_complete( )

=head1 SEE ALSO

  HTTP::Parser::Joyent::Reference
  http-parser/README

=CAVEAT

Very alpha.

Interface probably needs some help. 

Not sure if it's OK to have Joyent in the name. Need better/different name? Please don't sue me.

Please, feel free to fork and make it better! It's a pretty simple concept,
a library to write the http-parser callbacks in perl, but I failed to find any
other implementiaions so I put this together. It's not meant to be super
complete but rather to evolve into something good, or not, if it doesn't prove
to be useful...

=head1 AUTHOR

Ben B.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


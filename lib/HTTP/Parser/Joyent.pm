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
			'new',  'parse', 'DESTROY',
#			'on_message_begin',
			'HTTP_REQUEST', 'HTTP_RESPONSE',
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

  use HTTP::Parser::Joyent qw(:all);

=head1 DESCRIPTION

HTTP::Parser::Joyent is a HTTP parser based on ry's http-parser that can be used either for writing a synchronous HTTP server or an event-driven server.

=head1 METHODS

=head2 new

=head3 type => 0

HTTP_REQUEST

=head3 type => 1

HTTP_RESPONSE

=head3 type => 2

HTTP_BOTH

=head1 parse

Tries to parse given request string. The return values are:

=head3 -1

given request is corrupt

=head3 -2

given request is incomplete

=head1 get_env

For the name of the variables inserted, please refer to the PSGI specification.

=head1 AUTHOR

Ben B.

=head1 SEE ALSO

L<HTTP::Parser>
L<HTTP::Parser::XS>
L<HTTP::HeaderParser::XS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut



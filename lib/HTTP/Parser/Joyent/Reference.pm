package HTTP::Parser::Joyent::Reference;
our $VERSION = '0.01';
use 5.10.1;
use strict;
use warnings;
use Carp();
use English qw(-no_match_vars);
use IO::Handle();
use HTTP::Parser::Joyent qw(:typical);

## http_cb
sub on_message_begin { 0; }

# http_data_cb
sub on_url {
	my( $self, $buffer, $length ) = @ARG;
	$self->{url} .= $buffer;
	return 0;
}

# http_cb
sub on_status_complete { 0; }

# http_data_cb
sub on_header_field {
	my( $self, $buffer, $length ) = @ARG;
	$self->{temp_header_field} .= $buffer;
	return 0;
}

# http_data_cb
sub on_header_value {
	my( $self, $buffer, $length ) = @ARG;
	if( $self->{temp_header_field} ) {
		$self->{currenct_header_field} = delete $self->{temp_header_field};
		if( exists $self->{headers} ) {
			$self->{headers}{ uc $self->{currenct_header_field} } .= q(,);
		}
	}
	$self->{headers}{ uc $self->{currenct_header_field} } .= $buffer;
	return 0;
}

# http_cb
sub on_headers_complete { 0; }

# http_data_cb
sub on_body { 
	my( $self, $buffer, $length ) = @ARG;
	$self->{body} .= $buffer;
	return 0;
}

# http_cb
sub on_message_complete {
	my( $self ) = @ARG;
	$self->{message_complete} = 1;
	return 0;
}

sub message_complete {
	return $ARG[ 0 ]{message_complete};
}

sub get_env {
	my( $self ) = @ARG;
	if( not $self->{message_complete} ) {
		warn 'not message_complete ?';
		return;
	}
	my $url = $self->{url};
	my( $script_name, $query_string ) = split /\?/, $url, 2;
	my %env = ( 
		REQUEST_METHOD    => $self->http_method,
		SCRIPT_NAME       => $script_name,
		REQUEST_URI       => $url,
		QUERY_STRING      => $query_string,
		SERVER_PROTOCOL   => $self->http_version,
		CONTENT_LENGTH    => delete $self->{headers}{ 'CONTENT-LENGTH' } // 0,
		CONTENT_TYPE      => delete $self->{headers}{ 'CONTENT-TYPE' } // '',
	);
	while( my( $header_field, $header_value ) = each %{ $self->{headers} } ) {
		$header_field =~ tr/-/_/;
		$env{ sprintf 'HTTP_%s', $header_field } = $header_value;
	}
	if( $self->{body} ) {
		open my $fh, '<:scalar',  \$self->{body} or die sprintf 'Error with opening scalar for reading - %s', $OS_ERROR;
		$env{ 'psgi.input' } = IO::Handle->new_from_fd( $fh, 'r' );
	}
	return \%env;
}

1;

__END__

=head1 NAME

HTTP::Parser::Joyent::Reference - an HTTP request parser

=head1 SYNOPSIS

  use HTTP::Parser::Joyent;
  my $parser = HTTP::Parser::Joyent::Reference->new;
  my $request = "GET / HTTP/1.0\r\nHost: ...\r\n\r\n";
  my $nparsed = $parser->parse( $request, );
  if( $nparsed != length $request ) {
      # request is broken
      ...
  }
  elsif( $parser->message_complete ) {
    my $env = $parser->get_env;
  }

=head1 DESCRIPTION

Reference implementation of the abstrace HTTP::Parser::Joyent class.

=head1 AUTHOR

Ben B.

=head1 SEE ALSO

L<HTTP::Parser::Joyent>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


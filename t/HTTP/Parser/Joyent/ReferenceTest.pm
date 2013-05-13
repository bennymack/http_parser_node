package HTTP::Parser::Joyent::ReferenceTest;
use strict;
use warnings;
use English qw(-no_match_vars);
use base qw(Test::Class);
use Test::More;
use Test::Exception;
use constant TEST_PACKAGE => substr __PACKAGE__, 0, -4;
warn 'TEST_PACKAGE = ', TEST_PACKAGE;

__PACKAGE__->new->runtests if not caller;

sub test_1 : Test(startup => 3) {
	my( $self ) = @ARG;
	use_ok( $self->TEST_PACKAGE );
	can_ok( $self->TEST_PACKAGE, qw(new parse DESTROY http_method) );
	lives_ok { $self->TEST_PACKAGE->new; } sprintf '%s->new lives_ok', $self->TEST_PACKAGE;
}

sub test_2 : Tests {
	my( $self ) = @ARG;

	do {
		my $hpjr = $self->TEST_PACKAGE->new;
		is( $hpjr->parse( "GET / HTTP/1.0\r\n\r\n" ), 18  );
		is( $hpjr->http_method, 'GET' );
		is( $hpjr->http_version, 'HTTP/1.0' );
		is( $hpjr->should_keep_alive, 0 );
	};

	do {
		my $hpjr = $self->TEST_PACKAGE->new;
		is( $hpjr->parse( "GET / HTTP/1.1\r\n\r\n" ), 18  );
		is( $hpjr->http_method, 'GET' );
		is( $hpjr->http_version, 'HTTP/1.1' );
		is( $hpjr->should_keep_alive, 1 );
	};

	do {
		my $hpjr = $self->TEST_PACKAGE->new;
		is( $hpjr->parse( "GET /asdf?foo=bar HTTP/1.0\r\nConnection: Keep-Alive\r\nContent-Length: 4\r\nContent-Type: text/plain\r\nHost:foo.bar.com\r\n\r\n1234" ), 121 );
		is( $hpjr->http_method, 'GET' );
		is( $hpjr->http_version, 'HTTP/1.0' );
		is( $hpjr->should_keep_alive, 1 );
	};

	do {
		my $hpjr = $self->TEST_PACKAGE->new;
		my $message = "GET /asdf?foo=bar HTTP/1.0\r\nConnection: Keep-Alive\r\nContent-Length: 4\r\nContent-Type: text/plain\r\nHost:foo.bar.com\r\n\r\n1234";
		for( my $i = 1 ; $i <= length $message ; $i++ ) {
			if( 1 != ( my $status = $hpjr->parse( substr $message, $i - 1, 1 ) ) ) {
				fail( sprintf '$status( %d ) != 1 at %d', $status, __LINE__ );
			}
#			warn sprintf '$i = %d, length $message = %d, message_complete = %s', $i, length $message, $self->{message_complete} // 'undef';
			if( $i == length $message ) {
				if( not $hpjr->message_complete ) {
					fail( sprintf 'not message_complete, length $message = %d, $i = %d at %d', length $message, $i, __LINE__ );
				}
			}
			else {
				if( $hpjr->message_complete ) {
					fail( sprintf 'yes message_complete, length $message = %d, $i = %d at %d', length $message, $i, __LINE__ );
				}
			}
		}
		is( $hpjr->http_method, 'GET' );
		is( $hpjr->http_version, 'HTTP/1.0' );
		is( $hpjr->should_keep_alive, 1 );
	};

	do {
		my $hpjr = $self->TEST_PACKAGE->new;
		is( $hpjr->parse( "GET / HTTP/1.0\r\nFoo: 1\r\nFoo: 2\r\n\r\n" ), 34 );
		is( $hpjr->http_method, 'GET' );
		is( $hpjr->http_version, 'HTTP/1.0' );
		is( $hpjr->should_keep_alive, 0 );
		is_deeply( $hpjr->{headers}, { FOO => '1,2' } );
	};

	do {
		my $hpjr = $self->TEST_PACKAGE->new;
		is( $hpjr->parse( "GET / HTTP/1.0\r\nContent-Length: 4\r\nContent-Type: text/plain\r\n\r\n1234" ), 67 );
		my $env = $hpjr->get_env;
		my $input = $env->{ 'psgi.input' };
		$input->read( my $buf1, 2 );
		is( $buf1, '12' );
		$input->read( my $buf2, 2 );
		is( $buf2, '34' );
	};

}

1;

